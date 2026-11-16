-- KOReader's drop-down menu in SolarUI's style: a leaf-edged panel that drops
-- from the top edge under a page header with a plant, sized to its items
-- between 30% and 80% of the screen height (paged beyond that); a tap below
-- it closes it. It works over SolarUI home
-- and inside books, and shows the same tabs and items as KOReader's own
-- (every setting and every plugin's entries, read live from its menu tree,
-- never copied), with the same behaviour: checkmarks, greyed out items,
-- submenus, long-press help, and menus that stay open or close.
--
-- Tabs other plugins draw themselves (ZenOS's Controls and Launcher) are
-- built off-screen with a stand-in menu to learn their buttons and actions,
-- then shown as SolarUI buttons that run those same actions, so ZenOS keeps
-- working and is never replaced. SolarUI's own Quick tab (frontlight and
-- warmth, Wi-Fi, night mode, rotation, restart and exit, with the device at
-- a glance) comes first, or right after ZenOS's Controls and Launcher when
-- ZenOS is running.

local Device = require("device")
local Event = require("ui/event")
local UIManager = require("ui/uimanager")
local App = require("solarui/app")
local Button = require("solarui/ui/button")
local ArtView = require("solarui/ui/artview")
local Deco = require("solarui/ui/deco")
local DeviceInfo = require("solarui/data/device")
local Frame = require("solarui/screens/frame")
local Grid = require("solarui/ui/grid")
local Header = require("solarui/ui/header")
local Icon = require("solarui/ui/icon")
local Slider = require("solarui/ui/slider")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Panel = require("solarui/ui/panel")
local Settings = require("solarui/settings")
local TabFlower = require("solarui/ui/tabflower")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local Screen = Device.screen

local Menu = {}
Menu.__index = Menu

-- The panel's height as a share of the screen.
local MIN_H = 0.3
local DEFAULT_H = 0.8   -- how much of the screen a list may take (System > Home > Menu height)
local DECK_H = 0.7   -- the Quick tab holds sliders and tiles, which need more than a list does
local PICK_H = 0.9   -- a picker lists long things (every KOReader action), so it takes more room

-- KOReader's (and ZenOS's) tab icons as SolarUI icons and names; tabs other
-- plugins add with their own icons show as EXTRA.
local TABS = {
    ["appbar.filebrowser"] = { "folder", _("Files"), "library", 2 },
    ["appbar.settings"] = { "settings", _("Settings"), "settings", 3 },
    ["appbar.tools"] = { "tools", _("Tools"), "sprout", 4 },
    ["appbar.search"] = { "search", _("Search"), "search", 5 },
    ["appbar.menu"] = { "menu", _("Main"), "collections", 8 },
    ["appbar.navigation"] = { "book", _("Navigation"), "details", 9 },
    ["appbar.typeset"] = { "notes", _("Typeset"), "notes", 10 },
    ["appbar.pageview"] = { "eye", _("View"), "bookmarks", 11 },
    ["appbar.textsize"] = { "notes", _("Typeset"), "notes", 10 },
    ["appbar.contrast"] = { "eye", _("View"), "bookmarks", 11 },
    quicksettings = { "controls", _("Controls"), "history", 12 },
    app_launcher = { "grid", _("Launcher"), "bookmarks", 6 },
    solarui_deck = { "quick", _("Quick"), "highlights", 1 },
    ["inkaway.tab"] = { "quill", _("Ink Away"), "history", 7 },
}
local EXTRA = { "plugin", _("Plugin"), "bookmarks", 6 }

-- A tab's icon and name, by its id first, then its icon.
local function tabLook(tab)
    if tab.id == "zen_library_home" then return { "home", _("Home"), "library" } end
    if tab.id == "zen_ui" then
        local zen = require("solarui/apps/addons").pluginsDir() .. "/zenos.koplugin/icons/zen_ui.svg"
        return { zen, _("ZenOS"), "settings" }
    end
    return TABS[tab.id] or TABS[tab.icon] or EXTRA
end

local showing   -- the open menu

-- An item's text now.
local function textOf(item)
    local t = item.text_func and item.text_func() or item.text
    return t and tostring(t) or ""
end

-- Is an item usable now?
local function enabled(item)
    if item.enabled_func then return item.enabled_func() ~= false end
    return item.enabled ~= false
end

-- An item's submenu now, or nil.
local function submenu(item)
    return item.sub_item_table_func and item.sub_item_table_func() or item.sub_item_table
end

-- The file browser's menu with the most entries (Project: Title adds an empty one).
function Menu.fileManagerMenu()
    local fm = require("apps/filemanager/filemanager").instance
    if not fm then return nil end
    local function entries(m) return m and m.registered_widgets and #m.registered_widgets or 0 end
    local best = fm.menu
    for _i, module in ipairs(fm) do
        if module.name == "filemanagermenu" and entries(module) > entries(best) then best = module end
    end
    return best
end

-- The file browser's menu, its item tree built if needed.
local function fmMenu()
    local m = Menu.fileManagerMenu()
    if m and not m.tab_item_table then m:setUpdateItemTable() end
    return m
end

-- Is ZenOS running? KOReader keeps each loaded plugin under its name, so an
-- installed but switched off ZenOS is not there.
function Menu.zenosRunning()
    local ui = require("apps/filemanager/filemanager").instance or require("apps/reader/readerui").instance
    return ui ~= nil and ui.zenos ~= nil
end

-- Can the styled menu be shown over home now?
function Menu.available()
    local m = fmMenu()
    return m ~= nil and m.tab_item_table ~= nil and #m.tab_item_table > 0
end

-- The open menu, or nil (it may have been closed by a tap outside it).
function Menu.current()
    if showing and showing:isOpen() then return showing end
    return nil
end

-- The stable name of a tab: its id, else its icon, else its place.
local function tabKey(tab, i)
    return tab.id or tab.icon or tostring(i)
end

Menu.tabKey = tabKey

-- Drop the menu down. opts: { km = KOReader's menu object, reader = true
-- inside a book (the Quick tab is there too), pick = function(target, item) to choose an entry instead of
-- running it, pickable = function(item) to say which entries may be chosen,
-- title = the name shown for the list, quiet = true to draw nothing until `m.quiet` is cleared and `m:show()` runs }.
function Menu.open(opts)
    opts = opts or {}
    local km = opts.km or fmMenu()
    if not km.tab_item_table then km:setUpdateItemTable() end
    -- SolarUI's Quick tab comes first, or with ZenOS right after its Controls and
    -- Launcher (installed but switched off counts as not running)
    local want_deck = not opts.pick
    local deck_at
    if want_deck then
        deck_at = 1
        if Menu.zenosRunning() then
            for i, t in ipairs(km.tab_item_table) do
                if t.id == "quicksettings" or t.id == "app_launcher" then deck_at = i + 1 end
            end
        end
    end
    local tabs = {}
    for i, t in ipairs(km.tab_item_table) do
        if i == deck_at then tabs[#tabs + 1] = { id = "solarui_deck", deck = true } end
        tabs[#tabs + 1] = t
    end
    if deck_at and deck_at > #km.tab_item_table then tabs[#tabs + 1] = { id = "solarui_deck", deck = true } end
    local m = setmetatable({ km = km, reader = opts.reader, pick = opts.pick, pickable = opts.pickable, title = opts.title, tabs = tabs, deck_at = deck_at, stack = {}, trail = {}, page = 1 }, Menu)
    m.tab_key = opts.reader and "readermenu_tab_index" or "filemanagermenu_tab_index"
    local last = opts.pick and 1 or opts.reader and km.last_tab_index or G_reader_settings:readSetting(m.tab_key)
    last = last or 1
    if deck_at and last >= deck_at then last = last + 1 end   -- KOReader's numbering skips the Quick tab
    m.tab = math.max(1, math.min(last, #tabs))
    m.items = tabs[m.tab]
    -- what item actions call on "the menu"
    m.shim = {
        item_table = m.items,
        item_width = Screen:getWidth(),
        updateItems = function() if Menu.current() == m then m:show() end end,
        closeMenu = function() m:close() end,
        backToUpperMenu = function() m:up() end,
        onClose = function() m:close() end,
    }
    showing = m
    m.quiet = opts.quiet
    m:show()
    return m
end

-- Repaint one element of the open menu (a slider being dragged) without rebuilding it.
function Menu:repaint(el)
    if not self.reader then return App.repaint(el) end
    if self.popup and self.popup_open then
        UIManager:setDirty(self.popup, Theme.isDark() and "ui" or "fast", require("solarui/host").box(el))
    end
end

-- Is this menu still showing?
function Menu:isOpen()
    if self.reader then return self.popup_open == true or self.aside == true end
    return self.panel ~= nil and App.overlay() == self.panel
end

-- Draw (or redraw) the panel: over home in SolarUI's window, over a book in
-- a popup of its own.
function Menu:show()
    if self.quiet then return end
    if not self.reader then
        App.dialog(function(close, w) return self:build(close, w) end)
        return
    end
    local panel = self:build(nil, Screen:getWidth())
    if self.popup and self.popup_open then
        self.popup:redraw(panel)
    else
        local Popup = require("solarui/popup")
        self.popup = Popup:new({ element = panel, on_outside = function() self:close() end,
            on_back = function() return self:up() end })
        self.popup_open = true
        self.popup:open()
    end
end

-- Close the menu if it is still open.
function Menu:close()
    self.aside = false
    if self.reader then
        if self.popup and self.popup_open then
            self.popup_open = false
            self.popup:close()
        end
    elseif Menu.current() == self then
        App.closeDialog()
    end
    if showing == self then showing = nil end
end

-- Show another tab.
function Menu:switchTab(i)
    local tab = self.tabs[i]
    -- ZenOS's Home tab opens ZenOS's own library, which would cover SolarUI: when
    -- SolarUI is the home screen it goes to SolarUI's home instead
    if tab.id == "zen_library_home" and (App.isHome() or G_reader_settings:readSetting("start_with") == "solarui") then
        self:close()
        local reader = self.reader and require("apps/reader/readerui").instance
        if reader and reader.document then App.homeFromBook(reader) end
        return
    end
    if tab.icon == "inkaway.tab" then
        -- Ink Away's quick menu, drawn in SolarUI's style (its own sheet when it can't be)
        self:close()
        if not require("solarui/apps/inkaway").quickMenu(self.km.ui, self.reader) and tab.callback then tab.callback() end
        return
    end
    if tab.id == "zen_library_home" or (tab.callback and #tab == 0 and not tab.panel) then
        -- a tab that is an action (ZenOS's home, its settings page)
        self:close()
        if tab.callback then tab.callback() end
        return
    end
    if tab.callback then tab.callback() end
    self.tab, self.items, self.stack, self.trail, self.page = i, tab, {}, {}, 1
    self.shim.item_table = tab
    if tab.remember ~= false and not tab.deck and not self.pick then
        -- KOReader's own numbering, without the Quick tab
        local own = (self.deck_at and i > self.deck_at) and i - 1 or i
        if self.reader then self.km.last_tab_index = own else G_reader_settings:saveSetting(self.tab_key, own) end
    end
    self:show()
end

-- Go into a submenu.
function Menu:down(items, title)
    self.stack[#self.stack + 1] = { items = self.items, page = self.page }
    self.trail[#self.trail + 1] = title
    self.items, self.page = items, 1
    self.shim.item_table = items
    self:show()
end

-- Back to the menu above; false at the top.
function Menu:up()
    local top = table.remove(self.stack)
    if not top then return false end
    table.remove(self.trail)
    self.items, self.page = top.items, top.page
    self.shim.item_table = top.items
    self:show()
    return true
end

-- Ask for text for an item that wants input: SolarUI's keyboard over home,
-- KOReader's inside a book.
function Menu:askInput(input)
    local value = input.input_func and input.input_func() or input.input or ""
    if not self.reader then
        App.input(input.title or "", value, function(text)
            if input.allow_blank_input or (text and text ~= "") then input.callback(text) end
        end, input.ok_text or _("OK"), { placeholder = input.hint_func and input.hint_func() or input.hint })
        return
    end
    local InputContainer = require("ui/widget/container/inputcontainer")
    InputContainer:new({}):onInput(input)
end

-- Show a short text (an item's help).
function Menu:info(title, text)
    if not self.reader then
        local back = function() if showing == self then self:show() end end
        App.confirm({ title = title, text = text, ok = _("OK"), on_ok = back, on_cancel = back })
        return
    end
    local InfoMessage = require("ui/widget/infomessage")
    UIManager:show(InfoMessage:new({ text = text }))
end

-- Where an item is in the tree, as { tab, trail, text } (what a launcher
-- button keeps to open it again).
function Menu:target(item)
    local trail = {}
    for i, t in ipairs(self.trail) do trail[i] = t end
    return { tab = tabKey(self.tabs[self.tab], self.tab), trail = trail, text = textOf(item) }
end

-- The index of the tab with this stable name, or nil.
function Menu:tabIndex(key)
    for i, t in ipairs(self.tabs) do
        if tabKey(t, i) == key then return i end
    end
    return nil
end

-- The shown item with this text, or nil.
function Menu:find(text)
    for _i, item in ipairs(self:visible()) do
        if textOf(item) == text then return item end
    end
    return nil
end

-- Choose the item for a picker instead of running it (unless the picker
-- says that kind of entry cannot be used).
function Menu:choose(item)
    if self.pickable and not self.pickable(item) then return App.toast(_("That one cannot be used")) end
    self:close()
    self.pick(self:target(item), item)
end

-- A tap on an item, as KOReader's menu handles it.
function Menu:select(item)
    if self.pick and not submenu(item) then return self:choose(item) end
    if item.tap_input or item.tap_input_func then
        self:close()
        return self:askInput(item.tap_input or item.tap_input_func())
    end
    local sub = submenu(item)
    if sub then
        if #sub > 0 then self:down(sub, textOf(item)) end
        return
    end
    local callback = item.callback_func and item.callback_func() or item.callback
    if not callback then return end
    callback(self.shim)
    if self.reader and item.keep_menu_open then
        -- a dialog may come at once or a moment later
        UIManager:nextTick(function() self:stepAside() end)
        UIManager:scheduleIn(0.4, function() self:stepAside() end)
    end
    if item.checked ~= nil or item.checked_func then
        if not (item.check_callback_updates_menu or item.check_callback_closes_menu) then self.shim.updateItems() end
    elseif not item.keep_menu_open then
        self:close()
    end
end

-- The windows above the reader (not the menu's own popup), bottom first.
function Menu:windowsAbove()
    local reader = require("apps/reader/readerui").instance
    local above, seen = {}, false
    for _i, win in ipairs(UIManager._window_stack) do
        if seen and win.widget ~= self.popup then above[#above + 1] = win.widget end
        if win.widget == reader then seen = true end
    end
    return above
end

-- An item that keeps the menu open may show a window of its own (a plugin's
-- settings dialog): the drop-down would sit over it, so it steps aside and
-- comes back when the window has gone.
function Menu:stepAside()
    if not (self.reader and self.popup_open) then return end
    local above = self:windowsAbove()
    if #above == 0 then return end
    self.popup_open = false
    self.popup:close()
    self.aside = true
    self:watch(above[#above])
end

-- Come back when `widget` closes, unless another window is still up (then wait for that one).
function Menu:watch(widget)
    local closed = widget.onCloseWidget
    widget.onCloseWidget = function(w, ...)
        widget.onCloseWidget = closed
        local r = closed and closed(w, ...)
        UIManager:nextTick(function()
            if not (self.aside and showing == self) then return end
            local above = self:windowsAbove()
            if #above > 0 then return self:watch(above[#above]) end
            self.aside = false
            self.popup = nil
            self:show()
        end)
        return r
    end
end

-- A long press on an item: its own action, else its help.
function Menu:hold(item)
    if self.pick then return self:choose(item) end
    if item.hold_input or item.hold_input_func then
        self:close()
        return self:askInput(item.hold_input or item.hold_input_func())
    end
    local hold = item.hold_callback_func and item.hold_callback_func() or item.hold_callback
    if hold then
        if item.hold_keep_menu_open == false then self:close() end
        return hold(self.shim, item)
    end
    local help = item.help_text_func and item.help_text_func(self.shim) or item.help_text
    self:info(textOf(item), help or textOf(item))
end

-- One item: a checkbox when it has one, its text, and a chevron for submenus.
function Menu:row(item, w, h)
    local th = Theme.get()
    local on = enabled(item)
    local kids = {}
    if item.checked_func or item.checked ~= nil then
        local checked = item.checked_func and item.checked_func() or item.checked
        -- a flower in bloom for what is on, an empty ring for what is off
        kids[#kids + 1] = Layout.Row:new({ width = Theme.px(30), height = Theme.px(30), valign = "center", children = {
            checked and ArtView:new({ name = "bloom", param = "daisy", width = Theme.px(30), height = Theme.px(30) })
                or Panel:new({ shape = "frame", radius = Theme.px(13), width = Theme.px(26), height = Theme.px(26), child = Layout.Spacer:new({}) }),
        } })
    end
    kids[#kids + 1] = Label:new({ text = textOf(item), kind = "label", color = on and "ink" or "muted", grow = true })
    if item.sub_item_table or item.sub_item_table_func then
        kids[#kids + 1] = Icon:new({ name = "forward", size = 18, color = on and "ink" or "muted" })
    end
    return Layout.Column:new({ width = w, height = h, children = {
        Panel:new({ shape = "none", grow = true, pad = { 0, th.space.s },
            on_tap = on and function() self:select(item) end or nil,
            on_hold = function() self:hold(item) end,
            child = Layout.Row:new({ gap = th.space.m, children = kids }) }),
        item.separator and Deco.Divider:new({ height = Theme.px(3) }) or Deco.RowRule:new({}),
    } })
end

-- The items to list (hidden ones left out).
function Menu:visible()
    local out = {}
    for _i, item in ipairs(self.items) do
        if not item.hidden_func or not item.hidden_func() then out[#out + 1] = item end
    end
    return out
end

---------------------------------------------------------------- panel tabs

-- The first text found in a widget tree (a button's label), or nil.
local function textIn(w, depth)
    depth = depth or 0
    if type(w) ~= "table" or depth > 12 then return nil end
    if type(w.text) == "string" and w.text ~= "" then return w.text end
    for _i, child in ipairs(w) do
        local t = textIn(child, depth + 1)
        if t then return t end
    end
    for _i, k in ipairs({ "widget", "label_widget", "label" }) do
        local t = type(w[k]) == "table" and textIn(w[k], depth + 1)
        if t then return t end
    end
    return nil
end

-- A SolarUI icon for a ZenOS control, by words in its id or label.
local CONTROL_ICONS = {
    { "wifi", "network" }, { "night", "moon" }, { "rotat", "rotate" }, { "light", "light" },
    { "bright", "light" }, { "screenshot", "eye" }, { "restart", "restart" }, { "exit", "exit" },
    { "sleep", "power" }, { "power", "power" }, { "search", "search" }, { "usb", "move" },
    { "bluetooth", "network" }, { "file", "files" }, { "stat", "stats" }, { "zen", "settings" },
}
local function controlIcon(id, label)
    local key = ((id or "") .. " " .. (label or "")):lower()
    for _i, m in ipairs(CONTROL_ICONS) do
        if key:find(m[1], 1, true) then return m[2] end
    end
    return nil
end

-- The buttons of a tab another plugin draws itself: its panel is built
-- off-screen with the stand-in menu, which it leaves its buttons on.
function Menu:panelButtons(tab)
    local shim = self.shim
    shim._zen_panel_refs = nil
    local ok, panel = pcall(tab.panel, shim)
    if ok and type(panel) == "table" and panel.free then pcall(panel.free, panel) end
    local refs = shim._zen_panel_refs
    local api = rawget(_G, "__ZEN_UI_QUICK_SETTINGS")
    local labels = {}
    if api and api.getItems then
        for _i, it in ipairs(api.getItems() or {}) do labels[it.id] = it.label end
    end
    local out = {}
    for i, ref in ipairs(refs and refs.buttons or {}) do
        local label = (ref.id and labels[ref.id]) or textIn(ref.widget) or string.format(_("Button %d"), i)
        out[#out + 1] = {
            label = label, icon = controlIcon(ref.id, label), callback = ref.callback, hold = ref.hold_callback,
            active = ref.id and api and api.isActive and api.isActive(ref.id) or false,
        }
    end
    return out
end

---------------------------------------------------------------- quick tab

-- The frontlight (and warmth) slider rows, when the device has them.
local function lightRows()
    local rows = {}
    if not Device:hasFrontlight() then return rows end
    local pd = Device:getPowerDevice()
    local function lightRow(label, get, set, min, max)
        local slider = Slider:new({ min = min, max = max, value = get() or min, grow = true, on_change = set,
            on_redraw = function(el) if showing then showing:repaint(el) end end })
        return Layout.Row:new({ gap = Theme.get().space.s, children = {
            Icon:new({ name = "light", size = 20 }),
            Label:new({ text = label, kind = "label", width = Theme.px(76) }),
            slider,
        } })
    end
    rows[#rows + 1] = lightRow(_("Light"), function() return pd:frontlightIntensity() end,
        function(v) pd:setIntensity(v) end, pd.fl_min or 0, pd.fl_max or 24)
    if Device:hasNaturalLight() then
        rows[#rows + 1] = lightRow(_("Warmth"), function() return pd:frontlightWarmth() end,
            function(v) pd:setWarmth(v) end, 0, 100)  -- setWarmth takes KOReader's 0-100 scale, not the native one
    end
    return rows
end

-- Send an event to the file browser's modules (night mode, rotation).
local function fmEvent(name, ...)
    local fm = require("apps/filemanager/filemanager").instance
    if fm then fm:handleEvent(Event:new(name, ...)) else UIManager:broadcastEvent(Event:new(name, ...)) end
end

-- SolarUI's own quick controls as tiles.
function Menu:deckButtons()
    local NetworkMgr = require("ui/network/manager")
    local wifi = DeviceInfo.wifi()
    local out = {
        { label = wifi and _("Wi-Fi on") or _("Wi-Fi off"), icon = "network", active = wifi, callback = function()
            if wifi then NetworkMgr:toggleWifiOff() else NetworkMgr:toggleWifiOn() end
            UIManager:scheduleIn(1, function() if showing == self then self:show() end end)
        end },
        { label = _("Night mode"), icon = "moon", active = Theme.nightMode(), callback = function()
            fmEvent("ToggleNightMode")
        end },
        { label = _("Rotate"), icon = "rotate", callback = function()
            self:close()
            fmEvent("IterateRotation")
        end },
    }
    -- hand over to the twin UI (or get it)
    out[#out + 1] = { label = require("solarui/twin").OTHER.name, icon = "home", callback = function()
        self:close()
        require("solarui/twin").switch()
    end }
    -- Ink Away's annotation mode on the book being read, when Ink Away is installed
    local InkAway = require("solarui/apps/inkaway")
    if require("solarui/apps/addons").status(InkAway) ~= "missing" then
        out[#out + 1] = { label = _("Annotate"), icon = InkAway.icon, callback = function()
            self:close()
            InkAway.annotate()
        end }
    end
    if Device:canRestart() then
        out[#out + 1] = { label = _("Restart"), icon = "restart", callback = function()
            self:close()
            App.confirm({ title = _("Restart KOReader?"), ok = _("Restart"), on_ok = function()
                UIManager:broadcastEvent(Event:new("Restart")) end })
        end }
    end
    out[#out + 1] = { label = _("Exit"), icon = "exit", callback = function()
        self:close()
        App.confirm({ title = _("Exit KOReader?"), ok = _("Exit"), on_ok = function()
            UIManager:broadcastEvent(Event:new("Exit")) end })
    end }
    return out
end

-- The device at a glance, two quiet lines.
local function glance()
    local Sysinfo = require("solarui/data/sysinfo")
    local pct = DeviceInfo.battery()
    local first = { DeviceInfo.clock(), pct and (string.format(DeviceInfo.charging() and _("Charging %d%%") or _("Battery %d%%"), pct)) or nil,
        DeviceInfo.wifi() and _("Wi-Fi on") or _("Wi-Fi off") }
    local drives = Sysinfo.storage()
    local d = drives[1]
    local used, total = Sysinfo.memory()
    local up = Sysinfo.uptime().total
    local second = { d and string.format(_("Storage %d%% full"), math.floor(d.used / d.total * 100 + 0.5)) or nil,
        used and string.format(_("Memory %d%%"), math.floor(used / total * 100 + 0.5)) or nil,
        up and string.format(_("Up %dh %02dm"), math.floor(up / 3600), math.floor(up % 3600 / 60)) or nil }
    local function join(t)
        local o = {}
        for i = 1, 3 do if t[i] then o[#o + 1] = t[i] end end
        return table.concat(o, "  \u{B7}  ")
    end
    return Layout.Column:new({ children = {
        Label:new({ text = join(first), kind = "body", color = "ink" }),
        Label:new({ text = join(second), kind = "small", color = "muted" }),
    } })
end

-- Tiles in rows of three for a tab of buttons.
function Menu:tiles(buttons)
    local th = Theme.get()
    local rows = {}
    for i = 1, #buttons, 3 do
        local row = {}
        for j = i, math.min(#buttons, i + 2) do
            local b = buttons[j]
            row[#row + 1] = Button:new({ icon = b.icon, label = b.label, align = "left", grow = true, height = Theme.px(48),
                variant = b.active and "chip_on" or "chip",
                on_tap = b.callback and function()
                    b.callback()
                    if showing == self then self:show() end
                end or nil,
                on_hold = b.hold and function() b.hold() end or nil })
        end
        while #row < 3 do row[#row + 1] = Layout.Spacer:new({ grow = true }) end
        rows[#rows + 1] = Layout.Row:new({ gap = th.space.s, children = row })
    end
    return rows
end

---------------------------------------------------------------- build

-- Build the panel: a page header with the tab's plant and the path, the tab
-- strip, then the tab's content, closed by a whiplash rule.
function Menu:build(_close, screen_w)
    local th = Theme.get()
    local screen_h = Screen:getHeight()
    local row_h, tabs_h = Theme.px(50), Theme.px(76)
    local header_h = Theme.px(74)
    local gap, pad = th.space.s, th.space.m
    local tab = self.tabs[self.tab]
    local look = tabLook(tab)
    if self.title then look = { look[1], self.title, look[3] } end

    local tab_buttons = {}
    for i, t in ipairs(self.tabs) do
        -- each tab is an icon that says what it holds (a plugin's own icon file stays as it is);
        -- the header names the tab shown, with its plant
        tab_buttons[i] = TabFlower:new({ icon = tabLook(t)[1], kind = tabLook(t)[4] or (i - 1) % 12 + 1, chosen = i == self.tab, grow = true,
            height = tabs_h, on_tap = function() self:switchTab(i) end })
    end
    local path = self.pick and _("Pick an entry") or "KOReader"
    for _i, t in ipairs(self.trail) do path = path .. "  \u{B7}  " .. t end
    local title = #self.trail > 0 and self.trail[#self.trail] or look[2]
    local kids = {
        Header.build({ title = title, plant = look[3], path = path, on_back = #self.trail > 0 and function() self:up() end or nil,
            actions = { Button:new({ icon = "close", variant = "icon", width = th.size.touch, on_tap = function() self:close() end }) } }),
    }
    -- a picker with one list needs no tab strip
    local strip = not (self.pick and #self.tabs == 1)
    if strip then kids[#kids + 1] = Layout.Row:new({ gap = gap, children = tab_buttons }) end
    local fixed = header_h + (strip and tabs_h or 0) + 2 * gap + 2 * pad + Theme.px(24)
    if self.pick then
        kids[#kids + 1] = Label:new({ text = _("Tap an entry to use it. Hold a submenu to use the menu itself."), kind = "micro", color = "muted", lines = 2 })
        fixed = fixed + Theme.px(30)
    end
    local want
    if tab.deck or tab.panel then
        -- a tab of controls: tiles (and for the Quick tab, the glance and the light too)
        local buttons = tab.deck and self:deckButtons() or self:panelButtons(tab)
        local inner = {}
        if tab.deck then inner[#inner + 1] = glance() end
        if tab.deck or tab.id == "quicksettings" then
            for _i, r in ipairs(lightRows()) do inner[#inner + 1] = r end
        end
        for _i, r in ipairs(self:tiles(buttons)) do inner[#inner + 1] = r end
        if #buttons == 0 and not tab.deck then
            inner[#inner + 1] = Label:new({ text = _("Nothing to show here yet."), kind = "body", color = "muted" })
        end
        local content = Layout.Column:new({ gap = gap, children = inner })
        content:layout(screen_w - 2 * th.space.xl, nil)
        want = fixed + content.h + gap
        kids[#kids + 1] = content
    else
        local items = self:visible()
        want = fixed + #items * row_h
        kids[#kids + 1] = Grid:new({ grow = true, items = items, page = self.page, cols = 1, cell_h = row_h, row_gap = 0,
            make = function(item, w, ch) return self:row(item, w, ch) end,
            on_layout = function(_c, pages, page) self.pages, self.page = pages, page end })
    end
    local h = math.floor(math.max(screen_h * MIN_H, math.min(screen_h * (self.pick and PICK_H or tab.deck and DECK_H or Settings.get("menu_height", DEFAULT_H)), want)))
    if want > h and not (tab.deck or tab.panel) then
        kids[#kids + 1] = Frame.pager(self, _("Page"), function(p)
            self.page = math.max(1, math.min(p, self.pages or 1))
            self:show()
        end)
    end
    -- a leaf-edged card hanging from the top edge, ruled twice, a tendril curling in each corner
    local panel = Panel:new({ shape = "chamfer", corners = "bl", fill = "bg", double = true, curls = true, width = screen_w, height = h,
        pad = { pad, th.space.xl, th.space.m, th.space.xl }, child = Layout.Column:new({ gap = gap, children = kids }) })
    panel.dock = "top"
    panel.on_back = function() return self:up() end
    panel.on_page = function(delta)
        if (self.pages or 1) < 2 then return false end
        self.page = math.max(1, math.min(self.page + delta, self.pages))
        self:show()
        return true
    end
    self.panel = panel
    return panel
end

return Menu
