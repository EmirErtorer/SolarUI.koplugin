-- SolarUI plugin entry: adds "SolarUI" to KOReader's Start with choices,
-- opens SolarUI at boot when chosen, brings it back when a book closes, and
-- offers menu entries and a gesture action to open it.

local Dispatcher = require("dispatcher")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("solarui/gettext")
local T = require("ffi/util").template

local START_WITH = "solarui"

local SolarUI = WidgetContainer:extend({
    name = "SolarUI",
    is_doc_only = false,
})

local booted = false        -- the boot takeover runs once per session
local book_closed = false   -- a book closed since the file browser was last shown

-- SolarUI's own modules are required inside the handlers, not at the top, so
-- KOReader's start loads none of them unless SolarUI is actually used.

-- Add "SolarUI" to the Start with menu (once, on KOReader's own class).
local function registerStartWith()
    local ok, FMMenu = pcall(require, "apps/filemanager/filemanagermenu")
    if not ok or FMMenu._solarui_start_with or type(FMMenu.getStartWithMenuTable) ~= "function" then return end
    FMMenu._solarui_start_with = true
    local orig = FMMenu.getStartWithMenuTable
    FMMenu.getStartWithMenuTable = function(menu)
        local t = orig(menu)
        if type(t) ~= "table" or type(t.sub_item_table) ~= "table" then return t end
        table.insert(t.sub_item_table, {
            text = _("SolarUI"),
            radio = true,
            checked_func = function() return G_reader_settings:readSetting("start_with") == START_WITH end,
            callback = function()
                G_reader_settings:saveSetting("start_with", START_WITH)
                require("solarui/twin").claim()   -- (with its twin installed too, this one is in charge)
            end,
        })
        local orig_text = t.text_func
        t.text_func = function()
            if G_reader_settings:readSetting("start_with") == START_WITH then return T(_("Start with: %1"), _("SolarUI")) end
            return orig_text and orig_text() or ""
        end
        return t
    end
end

-- Is SolarUI the chosen home screen?
function SolarUI.isHome()
    return G_reader_settings:readSetting("start_with") == START_WITH
end

-- Hook into KOReader when the file browser or the reader starts.
function SolarUI:init()
    registerStartWith()
    self.ui.menu:registerToMainMenu(self)
    self:onDispatcherRegisterActions()
    -- KOReader's own windows in SolarUI's style (each kind has a switch in Settings)
    local ok, err = pcall(function() require("solarui/skin/all").install() end)
    if not ok then require("logger").warn("SolarUI skins:", err) end
    if self.ui.document then self:styleReaderMenu() end
end

-- Inside a book, the drop-down menu is SolarUI's too (unless the reader chose
-- KOReader's own in Settings). Only this reader's own menu object is wrapped,
-- never KOReader's class, and any failure shows KOReader's menu as built, so
-- other plugins (ZenOS among them) are left as they are.
function SolarUI:styleReaderMenu()
    local km = self.ui.menu
    local show = km.onShowMenu
    km.onShowMenu = function(menu, tab_index, do_not_show)
        if do_not_show or not require("solarui/settings").get("styled_menu", true) or not require("solarui/twin").mine() then
            return show(menu, tab_index, do_not_show)
        end
        local Menu = require("solarui/menu")
        local ok, err = pcall(function() if not Menu.current() then Menu.open({ km = menu, reader = true }) end end)
        if not ok then
            require("logger").warn("SolarUI menu:", err)
            return show(menu, tab_index, do_not_show)
        end
        return true
    end
end

-- The gesture and hotkey action "SolarUI home".
function SolarUI:onDispatcherRegisterActions()
    Dispatcher:registerAction("solarui_home", {
        category = "none", event = "SolarUIHome", title = _("SolarUI home"), general = true,
    })
end

-- The file browser is being shown. After a book closes, SolarUI comes back
-- when it is the reader's home; at a fresh start it opens when it is the
-- chosen start screen.
function SolarUI:onShow()
    if self.ui.document then return end
    local App = require("solarui/app")
    local from_book = book_closed
    book_closed = false
    local first = not booted
    booted = true
    -- (with its twin installed too, only the one in charge comes back or starts)
    if not require("solarui/twin").mine() then return end
    if from_book then
        if App.isOpen() or App.isHome() or SolarUI.isHome() then App.raise() end
    elseif first and SolarUI.isHome() then
        App.open()
        require("solarui/twin").announceSoon()
    end
end

-- The book is ready: hide SolarUI's window under it (without loading SolarUI
-- when it is unused).
function SolarUI:onReaderReady()
    local App = _G.package.loaded["solarui/app"]
    if App then App.bookOpened() end
end

-- A book was closed in the reader: its details changed, and the next file
-- browser shown is a return from it.
function SolarUI:onCloseDocument()
    book_closed = true
    local doc = self.ui and self.ui.document
    require("solarui/app").bookClosed(doc and doc.file)
end

-- Close SolarUI on Exit too, or a window is left and KOReader never quits.
function SolarUI:onExit()
    require("solarui/app").close()
    require("solarui/settings").flush()
end

-- Settings are written a moment after they change; KOReader says when the
-- moment must not wait (going to sleep, restarting).
function SolarUI:onFlushSettings()
    require("solarui/settings").flush()
end

function SolarUI:onSuspend()
    require("solarui/settings").flush()
end

-- Open SolarUI; from the reader, home shows at once and the book closes
-- just after.
function SolarUI:onSolarUIHome()
    require("logger").info("SolarUI: home action", self.ui.document and "from a book" or "from the file browser")
    local App = require("solarui/app")
    if self.ui.document then
        App.homeFromBook(self.ui)
    else
        App.open()
        require("solarui/twin").announceSoon()
    end
    return true
end

-- KOReader's own Home action in the reader takes the same fast way when
-- SolarUI is the reader's home (plugins hear it before the reader does).
function SolarUI:onHome()
    if not self.ui.document then return false end
    if not require("solarui/twin").mine() then return false end
    local App = require("solarui/app")
    if not (App.isHome() or SolarUI.isHome()) then return false end
    App.homeFromBook(self.ui)
    return true
end

-- Menu entries in the file browser and the reader.
function SolarUI:addToMainMenu(menu_items)
    menu_items.solarui = {
        text = self.ui.document and _("SolarUI home") or _("SolarUI"),
        sorting_hint = "tools",
        callback = function() self:onSolarUIHome() end,
    }
    -- in a book, Ink Away's annotation mode is one tap away (when it is running)
    if self.ui.document and require("solarui/apps/addons").loadedIn(self.ui, require("solarui/apps/inkaway")) then
        menu_items.solarui_annotate = {
            text = _("Annotate this book"),
            sorting_hint = "tools",
            callback = function() self.ui:handleEvent(require("ui/event"):new("InkAwayAnnotate")) end,
        }
    end
end

return SolarUI
