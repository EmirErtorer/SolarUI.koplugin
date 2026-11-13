-- SolarUI's controller: opens, raises and closes the window, keeps the stack
-- of screens, rebuilds the current one when its data changes, shows dialogs
-- and toasts, ticks the clock, and hands books to the reader and back.

local Device = require("device")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")
local Books = require("solarui/data/books")
local Covers = require("solarui/data/covers")
local Host = require("solarui/host")
local Library = require("solarui/data/library")
local Perf = require("solarui/perf")
local Settings = require("solarui/settings")
local Stats = require("solarui/data/stats")
local Theme = require("solarui/theme")
local Dialog = require("solarui/ui/dialog")
local TextInput = require("solarui/ui/textinput")
local StatusBar = require("solarui/ui/statusbar")
local _ = require("solarui/gettext")

local Screen = Device.screen

local App = {}

-- The sections in the tab bar, in order.
App.TABS = {
    { id = "home", label = _("Home"), icon = "home" },
    { id = "library", label = _("Library"), icon = "library" },
    { id = "collections", label = _("Collections"), icon = "collections" },
    { id = "history", label = _("History"), icon = "history" },
    { id = "settings", label = _("Settings"), icon = "settings" },
}

local host        -- the window, kept while SolarUI is home (also under the reader)
local stack = {}  -- screen instances, the current one last
local views = 0   -- screens shown since the last full refresh
local prepainted = false   -- home shown before the book it left closed
local prewarmed = false    -- the reader's code is loaded
local listening = false   -- is App watching for books read in the background?
local update_started = false  -- the daily update check was set off this session
local clock_timer
local toast_timer

-- Is the window on the screen stack?
function App.isOpen()
    return host ~= nil and UIManager:isWidgetShown(host)
end

-- Is SolarUI's window the top one (nothing over it)?
local function onTop()
    local top = UIManager:getTopmostVisibleWidget()
    return host ~= nil and top == host
end
App.onTop = onTop

-- Make a screen instance from its module.
local function make(id, params)
    local Screen_ = require("solarui/screens/" .. id)
    local s = Screen_:new(params or {})
    s.id = id
    return s
end

-- The screen being shown.
function App.current()
    return stack[#stack]
end

-- Build the current screen's elements into the window.
local function build()
    local s = App.current()
    if not (host and s) then return end
    Perf.measure("build", function()
        host:setRoot(s:build({ w = Screen:getWidth(), h = Screen:getHeight() }))
    end)
end

-- Refresh kind for a new screen: a full flash every few screens clears
-- ghosting; more often on a dark screen, where e-ink ghosts the most.
local function viewRefresh()
    views = views + 1
    local every = Theme.isDark() and Settings.get("dark_full_refresh_every", 2) or Settings.get("full_refresh_every", 6)
    if every > 0 and views >= every then
        views = 0
        return "full"
    end
    return "ui"
end

-- Rebuild and repaint the whole current screen.
function App.render(refresh)
    if not host then return end
    build()
    host:markRepainted()
    UIManager:setDirty(host, refresh or viewRefresh())
end

-- Rebuild the current screen but refresh only `region` (a Geom). Without
-- one, the whole screen, or only what is above a docked keyboard.
function App.update(region)
    if not host then return end
    build()
    host:markRepainted()
    local o = host.overlay
    if not region and o and o.dock == "bottom" and o.h then
        region = Geom:new({ x = 0, y = 0, w = host.dimen.w, h = host.dimen.h - o.h })
    end
    UIManager:setDirty(host, "ui", region or host.dimen)
end

-- Repaint one element in place after changing it (no rebuild).
function App.repaint(el, mode)
    if not (host and el.x) then return end
    -- the quickest refresh leaves traces on a dark screen
    UIManager:setDirty(host, mode or (Theme.isDark() and "ui" or "fast"), Host.box(el))
end

-- Move an element `dx`, `dy` pixels (it must have been painted) and repaint the
-- place it left and the place it went to, and nothing else.
function App.repaintMoved(el, dx, dy, mode)
    if not (host and el.x) then return end
    local old = Host.box(el)
    el.sx, el.sy = el.sx + dx, el.sy + dy
    local new = Geom:new({ x = old.x + dx, y = old.y + dy, w = old.w, h = old.h })
    UIManager:setDirty(host, mode or "fast", old:combine(new))
end

-- Show the clock change once a minute while SolarUI is on top.
local function scheduleClock()
    if clock_timer then UIManager:unschedule(clock_timer) end
    clock_timer = function()
        clock_timer = nil
        if not host then return end
        local s = App.current()
        if onTop() and s and s.clock and StatusBar.tick(s.clock) then
            App.repaint(s.clock)
        end
        scheduleClock()
    end
    UIManager:scheduleIn(60 - os.date("*t").sec + 0.2, clock_timer)
end

-- Wire the window's callbacks to the app.
local function newHost()
    local h = Host:new({})
    h.on_swipe = function(dir, pos) App.swipe(dir, pos) end
    h.on_back = function() App.back() end
    h.on_page = function(delta) App.page(delta) end
    h.on_outside = function() App.closeDialog() end
    h.on_resize = function() build() end
    h.on_error = function() App.toast(_("Something went wrong; see crash.log")) end
    return h
end

-- Is SolarUI the reader's home right now? Opening it makes it so, leaving for
-- KOReader's file browser stops it; saved, so a closed book (even after a
-- restart) goes back to where the reader chose to be.
function App.isHome()
    return Settings.get("home_active", false)
end

-- Make SolarUI the place closed books return to, or stop that.
function App.setHome(on)
    if App.isHome() ~= on then Settings.save("home_active", on) end
end

-- Open SolarUI at a screen (home by default), on top of everything.
function App.open(id, params)
    App.setHome(true)
    if not host then
        host = newHost()
        stack = { make(id or "home", params) }
        build()
        UIManager:show(host, "ui")
        host:markRepainted()
        scheduleClock()
        App.afterShow()
    else
        stack = { make(id or "home", params) }
        App.raise()
    end
end

-- A book is open over the window: hide it, so a book reload cannot flash home.
function App.bookOpened()
    if host then host.invisible = true end
end

-- Show the hidden window again if no book or file browser follows a closed book.
local function revealIfLeft()
    UIManager:scheduleIn(1, function()
        if not (host and host.invisible and UIManager:isWidgetShown(host)) then return end
        if require("apps/reader/readerui").instance then return end
        if require("apps/filemanager/filemanager").instance then return end
        local ws = UIManager._window_stack
        if ws[#ws].widget ~= host then return revealIfLeft() end
        App.raise()
    end)
end

-- Bring the window back to the top with fresh data (after a book closes).
function App.raise()
    if not host then return App.open() end
    host.invisible = false
    if prepainted then
        -- home was painted before the book closed: put it back on top of the
        -- file browser KOReader just built, without painting it again
        prepainted = false
        local ws = UIManager._window_stack
        for i, entry in ipairs(ws) do
            if entry.widget == host then
                if i ~= #ws then table.insert(ws, table.remove(ws, i)) end
                break
            end
        end
        local s = App.current()
        if s and s.onBookClosed then s:onBookClosed() end
        scheduleClock()
        App.afterShow()
        return
    end
    if not UIManager:isWidgetShown(host) then
        UIManager:show(host, "ui")
    else
        local ws = UIManager._window_stack
        for i, entry in ipairs(ws) do
            if entry.widget == host then
                if i ~= #ws then table.insert(ws, table.remove(ws, i)) end
                break
            end
        end
    end
    local s = App.current()
    if s and s.onRaise then s:onRaise() end
    App.render("ui")
    scheduleClock()
    App.afterShow()
end

-- Close the book for real and let KOReader rebuild its file browser under
-- home, which stays on top and is not painted again. Touches made while that
-- blocks are not meant for home, so they are dropped.
function App.realClose(ui, file)
    prepainted = true
    ui:onClose(false)
    ui:showFileManager(file)
    -- the file browser turned the screen back upright (a book read sideways):
    -- home was painted in the old shape, so lay it out and paint it again
    if host and (host.laid_w ~= Screen:getWidth() or host.laid_h ~= Screen:getHeight()) then
        prepainted = false
        App.raise()
    end
    local ok, now = pcall(function() return require("ui/time").now() end)
    if ok and host then host.ignore_before = now end
end

-- Leave the open book for home at once: progress is saved and home painted
-- first. Then KOReader closes the book and rebuilds its file browser under
-- home (without a full-screen flash), so going home takes one paint; with
-- parking on, the book is only put away and stays open until it is needed.
function App.homeFromBook(ui)
    -- (newer KOReader only: 2026.07.1 does not have it)
    if UIManager.setSuspendRepaints then UIManager:setSuspendRepaints(false) end
    local file = ui.document and ui.document.file
    local Park = require("solarui/park")
    local parked = Park.park(ui)
    if not parked then ui:saveSettings() end
    App.bookClosed(file)
    App.setHome(true)
    App.raise()
    UIManager:forceRePaint()
    if parked then return end
    prepainted = true
    UIManager:nextTick(function() App.realClose(ui, file) end)
end

-- Load the reader's code once, while home sits idle, so even the first book
-- of a session only pays for opening the book itself.
local function prewarm()
    if prewarmed then return end
    prewarmed = true
    UIManager:scheduleIn(3, function()
        if not onTop() then return end
        pcall(function()
            require("apps/reader/readerui")
            local CreDocument = require("document/credocument")
            if CreDocument.engineInit then CreDocument:engineInit() end
        end)
    end)
end

-- Draw the garden's backdrop while home sits idle, a drawing at a time, so
-- opening the garden is a copy. It waits while anything else is on the screen.
local warming = false
function App.warmGarden()
    if warming then return end
    local Scene = require("solarui/ui/scene")
    local time = require("ui/time")
    local ok, scene, root = pcall(function()
        return require("solarui/screens/garden").warmScene({ w = Screen:getWidth(), h = Screen:getHeight() })
    end)
    if not ok or not scene then return end
    warming = true
    local Art = require("solarui/gfx/art")
    local jobs = {}
    for _i, it in ipairs(Art.pending(scene.items)) do jobs[#jobs + 1] = function() Art.draw_piece(it) end end
    for _i, job in ipairs(Scene.spriteJobs(root)) do jobs[#jobs + 1] = job end
    local function step()
        if not onTop() then
            -- a book or a dialog is over home: try again in a while
            warming = false
            return UIManager:scheduleIn(20, function() App.warmGarden() end)
        end
        -- as many drawings as fit in a short slice, then back to the touch screen for a moment
        local t0 = time.now()
        local ran = false
        while #jobs > 0 and time.to_ms(time.since(t0)) < 60 do
            table.remove(jobs, 1)()
            ran = true
        end
        if ran or #jobs > 0 then return UIManager:scheduleIn(.1, step) end
        scene:prepare(Screen.bb:getType())
        warming = false
    end
    UIManager:scheduleIn(.15, step)
end

-- The companion has noticed the reading done since SolarUI was last open (a
-- finished book, a streak, a memory): say so on whatever screen is showing
-- (the home screen tells it itself).
function App.companionNews()
    local Pet = require("solarui/garden/pet")
    if not (App.isOpen() and Pet.get()) then return end
    local before = Pet.waiting()
    Pet.refresh(require("solarui/garden/voice").beats(Pet.get().id))
    if Pet.waiting() <= before then return end
    local s = App.current()
    if s and s.id ~= "home" then
        App.toast(string.format(_("%s has something to tell you."), require("solarui/garden/state").name(Pet.get().id)))
    end
    App.update()
end

-- Work done once the screen is up, so it never delays the first paint.
function App.afterShow()
    prewarm()
    UIManager:scheduleIn(1, function() App.companionNews() end)
    UIManager:scheduleIn(5, function() if onTop() then App.warmGarden() end end)
    if not update_started then
        -- once a session: tidy up after an update, and the daily check
        update_started = true
        UIManager:scheduleIn(2, function()
            local Updater = require("solarui/update/updater")
            Updater.cleanup()
            Updater.autoCheck(function() if App.isOpen() then App.update() end end)
        end)
    end
    UIManager:nextTick(function()
        if Library.stale() then
            Library.all()
            local s = App.current()
            if s and s.onIndexed then s:onIndexed() end
        end
        if not listening then
            listening = true
            Books.listen(function(paths)
                for _i, p in ipairs(paths) do Covers.forget(p) end
                if App.isOpen() then App.update() end
            end)
        end
    end)
end

-- Close SolarUI and show what is under it (the file browser).
function App.close()
    if not host then return end
    if clock_timer then UIManager:unschedule(clock_timer); clock_timer = nil end
    UIManager:close(host, "ui")
    host, stack = nil, {}
    Covers.forget()
end

-- Go to a section of the tab bar (its screen sits right above home).
function App.go(id, params)
    if id == "home" then stack = { stack[1].id == "home" and stack[1] or make("home") }
    else stack = { stack[1].id == "home" and stack[1] or make("home"), make(id, params) } end
    App.render()
end

-- Open a screen on top of the current one.
function App.push(id, params)
    stack[#stack + 1] = make(id, params)
    App.render()
end

-- Leave the current screen for the one under it (whatever it shows inside).
function App.pop()
    if #stack > 1 then
        stack[#stack] = nil
        local s = App.current()
        if s.onRaise then s:onRaise() end
        App.render()
    end
end

-- Back one screen; at home nothing happens.
function App.back()
    if host and host.overlay then
        if host.overlay.on_back and host.overlay.on_back() then return end
        return App.closeDialog()
    end
    local cur = App.current()
    if cur and cur:onBack() then return end
    App.pop()
end

-- The page turn keys: page the open dialog, else the screen. True when used.
function App.page(delta)
    if host and host.overlay then
        local o = host.overlay
        return o.on_page ~= nil and o.on_page(delta) == true
    end
    local s = App.current()
    return (s and s.onSwipe and s:onSwipe(delta > 0 and "west" or "east")) == true
end

-- Swipes: down from the top edge opens KOReader's menu, a paging screen
-- pages left and right. Returns true when the swipe was used.
function App.swipe(dir, pos)
    if dir == "south" and pos.y < Screen:getHeight() / 8 then
        App.koreaderMenu()
        return true
    end
    local s = App.current()
    return (s and s.onSwipe and s:onSwipe(dir)) == true
end

-- Show a dialog built by builder(close, screen_w) over the screen.
function App.dialog(builder)
    if not host then return end
    local before = host:overlayBox()
    host.overlay = builder(App.closeDialog, Screen:getWidth())
    host:relayout()
    host:markRepainted()
    -- refresh only what the old and new dialog cover
    local box = host:overlayBox()
    UIManager:setDirty(host, "ui", before and box:combine(before) or box)
end

-- The dialog showing, or nil.
function App.overlay()
    return host and host.overlay
end

-- Close the dialog and repaint what it covered (the dialog's `on_closed`, when
-- it has one, runs after).
function App.closeDialog()
    if not (host and host.overlay) then return end
    local box, closed = host:overlayBox(), host.overlay
    host.overlay = nil
    host:markRepainted()
    UIManager:setDirty(host, "ui", box)
    if closed.on_closed then closed.on_closed() end
end

-- Ask before doing something (see Dialog.confirm for the fields).
function App.confirm(o)
    App.dialog(function(close, w) return Dialog.confirm(o, close, w) end)
end

-- Offer a set of actions as tiles (see Dialog.sheet).
function App.sheet(o)
    App.dialog(function(close, w) return Dialog.sheet(o, close, w) end)
end

-- Let the reader pick from options (see Dialog.choose).
function App.choose(o)
    o.show = function(page) o.page = page; App.choose(o) end
    App.dialog(function(close, w) return Dialog.choose(o, close, w, Screen:getHeight()) end)
end

-- A short notice near the bottom for two seconds.
function App.toast(text)
    if not host then return end
    host.toast = Dialog.toast(text)
    host:relayout()
    UIManager:setDirty(host, "ui")
    if toast_timer then UIManager:unschedule(toast_timer) end
    toast_timer = function()
        toast_timer = nil
        if host and host.toast then
            host.toast = nil
            UIManager:setDirty(host, "ui")
        end
    end
    UIManager:scheduleIn(2, toast_timer)
end

-- Ask for a line of text with SolarUI's keyboard; on_done(text) on confirm.
-- opts: { placeholder, live = fn(text) called after every change }.
function App.input(title, value, on_done, ok_label, opts)
    opts = opts or {}
    local state = { text = value or "", layer = "abc", shift = false }
    local field
    local show
    -- The text changed: redraw the field alone, and tell a live caller once
    -- typing pauses (each update refreshes the screen above the keyboard).
    local live_task = function() if opts.live then opts.live(state.text) end end
    local function changed()
        App.repaint(field)
        if opts.live then
            UIManager:unschedule(live_task)
            UIManager:scheduleIn(0.4, live_task)
        end
    end
    show = function()
        App.dialog(function(close, screen_w)
            local panel
            panel, field = TextInput.build({
                title = title, placeholder = opts.placeholder, ok_label = ok_label, state = state, screen_w = screen_w,
                on_char = function(c)
                    state.text = state.text .. c
                    if state.shift == true or state.shift == "once" then state.shift = false; show() end
                    changed()
                end,
                on_back = function()
                    state.text = state.text:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
                    changed()
                end,
                on_enter = function() UIManager:unschedule(live_task); close(); on_done(state.text) end,
                on_cancel = function() UIManager:unschedule(live_task); close() end,
                on_collapse = function() state.collapsed = true; show() end,
                on_expand = function() state.collapsed = nil; show() end,
                on_layer = function(layer) state.layer, state.shift = layer, (state.shift == "lock" and "lock" or false); show() end,
                on_shift = function() state.shift = TextInput.nextShift(state.shift); show() end,
            })
            -- a tap beside the keyboard puts it away (the text stays); a tap beside the bare field leaves
            panel.on_outside = function()
                if state.collapsed then UIManager:unschedule(live_task); close() else state.collapsed = true; show() end
            end
            return panel
        end)
    end
    show()
end

-- Open a book in the reader; SolarUI stays underneath to come back to.
function App.openBook(path, after_open)
    if clock_timer then UIManager:unschedule(clock_timer); clock_timer = nil end
    local ReaderUI = require("apps/reader/readerui")
    local Park = require("solarui/park")
    -- the book put away under home: bring it back, nothing to load
    if Park.unpark(path, after_open) then
        App.bookOpened()   -- the book is over the window again, with no ReaderReady to say so
        return
    end
    Park.noteOpen()
    ReaderUI:showReader(path, nil, nil, nil, after_open)
end

-- A book was closed: what SolarUI knows about it is stale.
function App.bookClosed(path)
    if path then
        Books.forget(path)
        Covers.forget(path)
    end
    Stats.invalidate()
    if host and host.invisible then revealIfLeft() end
end

-- Open KOReader's drop-down menu (the file browser's) over home.
function App.koreaderMenu()
    require("solarui/park").finish()   -- the menu belongs to the file browser, which a parked book replaces
    local Menu = require("solarui/menu")
    -- in SolarUI's style unless the reader chose KOReader's own or its menu cannot be read
    if Settings.get("styled_menu", true) and Menu.available() then
        local ok, err = pcall(function() if not Menu.current() then Menu.open() end end)
        if ok then return end
        require("logger").warn("SolarUI menu:", err)
    end
    local fm_menu = Menu.fileManagerMenu()
    if fm_menu then fm_menu:onShowMenu() end
end

-- Leave SolarUI for the file browser (and stay there after reading).
function App.fileBrowser()
    require("solarui/park").finish()
    App.setHome(false)
    App.close()
end

-- The theme changed: everything is rebuilt in the new look.
Theme.onChange(function()
    if host then App.render("full") end
end)

return App
