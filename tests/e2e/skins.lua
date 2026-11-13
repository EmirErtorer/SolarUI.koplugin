-- KOReader's own windows with SolarUI's styles off and on: each kind is shown
-- twice and saved as <name>-before.png and <name>-after.png, for a side by
-- side look (tools/skin-compare.sh puts them together).
-- SKIN_CASES (comma separated names) limits which are run.
local H = ...
local UIManager = require("ui/uimanager")
local Settings = require("solarui/settings")
local Screen = require("device").screen
local only = {}
for name in (os.getenv("SKIN_CASES") or ""):gmatch("[^,]+") do only[name] = true end

local function nothing() end

-- the emulator reports a physical keyboard, which hides the on-screen one: pretend there is none
local Device = require("device")
Device.hasKeyboard = function() return false end
Device.hasDPad = function() return false end

-- The windows to show, by name: a function that builds and shows one.
local CASES = {
    { "notice", function()
        return UIManager:show(require("ui/widget/infomessage"):new({ text = "The book was added to your library." }))
    end },
    { "confirm", function()
        return UIManager:show(require("ui/widget/confirmbox"):new({ text = "Remove this book from the library? Its notes stay.", ok_text = "Remove", cancel_text = "Keep" }))
    end },
    { "warning", function()
        return UIManager:show(require("ui/widget/confirmbox"):new({ icon = "notice-warning", text = "This deletes every highlight in the book.", ok_text = "Delete" }))
    end },
    { "toast", function()
        return UIManager:show(require("ui/widget/notification"):new({ text = "Saved to your collection." }))
    end },
    { "buttons", function()
        return UIManager:show(require("ui/widget/buttondialog"):new({ title = "Book actions", buttons = {
            { { text = "Open", callback = nothing }, { text = "Details", callback = nothing } },
            { { text = "Add to a collection", callback = nothing } },
            { { text = "Mark as finished", callback = nothing }, { text = "Delete", callback = nothing } },
        } }))
    end },
    { "input", function()
        local d = require("ui/widget/inputdialog"):new({ title = "Rename the book", input = "Black Sheep", input_hint = "Title",
            buttons = { { { text = "Cancel", id = "close", callback = nothing }, { text = "Rename", is_enter_default = true, callback = nothing } } } })
        UIManager:show(d)
        d:onShowKeyboard()
        return d
    end },
    { "list", function()
        local items = {}
        for i, t in ipairs({ "Cover", "Part One: The Valley", "Part Two: The River", "Chapter 7", "Epilogue", "Notes" }) do
            items[i] = { text = t, mandatory = tostring(i * 24), callback = nothing }
        end
        return UIManager:show(require("ui/widget/menu"):new({ title = "Table of contents", item_table = items, is_borderless = true, is_popout = false,
            title_bar_fm_style = true, width = Screen:getWidth(), height = Screen:getHeight(), covers_fullscreen = true, close_callback = nothing }))
    end },
    { "details", function()
        return UIManager:show(require("ui/widget/keyvaluepage"):new({ title = "Book information", kv_pairs = {
            { "Title", "Black Sheep" }, { "Author", "Georgette Heyer" }, { "Language", "English" }, { "Pages", "412" },
            { "File", "/books/black-sheep.epub" }, { "Format", "EPUB" } } }))
    end },
    { "text", function()
        return UIManager:show(require("ui/widget/textviewer"):new({ title = "Reading notes", text = "A page of text to read, such as the notes of a book or a licence.\n\n"
            .. string.rep("The garden was quiet and the paths were soft after the rain. ", 14) }))
    end },
    { "number", function()
        return UIManager:show(require("ui/widget/spinwidget"):new({ title_text = "Font size", value = 22, value_min = 8, value_max = 72, ok_text = "Set" }))
    end },
    { "date", function()
        return UIManager:show(require("ui/widget/datetimewidget"):new({ title_text = "Set the date", year = 2026, month = 11, day = 13, ok_text = "Set" }))
    end },
    { "choice", function()
        return UIManager:show(require("ui/widget/radiobuttonwidget"):new({ title_text = "Screen rotation", ok_text = "Apply", radio_buttons = {
            { { text = "Portrait", checked = true, provider = 1 } }, { { text = "Landscape", provider = 2 } },
            { { text = "Upside down", provider = 3 } } } }))
    end },
    { "qr", function()
        return UIManager:show(require("ui/widget/qrmessage"):new({ text = "http://192.168.1.20:8080", width = Screen:getWidth() * .6, height = Screen:getWidth() * .6 }))
    end },
    { "progress", function()
        local d = require("ui/widget/progressbardialog"):new({ title = "Downloading the update", subtitle = "File 2 of 5", progress_max = 100 })
        UIManager:show(d)
        d:reportProgress(40)
        return d
    end },
    { "wifi", function()
        return UIManager:show(require("ui/widget/networksetting"):new({ network_list = {
            { ssid = "Garden House", signal_level = -50, signal_quality = 80, flags = "[WPA2-PSK]" },
            { ssid = "Library", signal_level = -60, signal_quality = 62, flags = "[WPA2-PSK]" },
            { ssid = "Guest", signal_level = -80, signal_quality = 30, flags = "" } },
            connect_callback = nothing }))
    end },
    { "light", function()
        local ok, w = pcall(function() return require("ui/widget/frontlightwidget"):new({}) end)
        return ok and UIManager:show(w) or nil
    end },
}

-- Windows of a book being read (shown once a book is open).
local function reader() return require("apps/reader/readerui").instance end
local READER_CASES = {
    { "settings-panel", function()
        reader().config:onShowConfigMenu()
    end },
    { "selection", function()
        -- hold on a word of the page, as a finger would, with the menu asked for (not a lookup)
        G_reader_settings:saveSetting("highlight_action_on_single_word", true)
        H.holdAt(Screen:getWidth() * .5, Screen:getHeight() * .4)
    end },
    { "lookup", function()
        -- the same hold with the lookup KOReader does by default
        G_reader_settings:saveSetting("highlight_action_on_single_word", false)
        H.holdAt(Screen:getWidth() * .5, Screen:getHeight() * .5)
    end },
    { "edit-highlight", function()
        -- a tap on the highlight made before
        H.tapAt(Screen:getWidth() * .5, Screen:getHeight() * .4)
    end, function()
        -- first make a highlight: hold on a word, then save it from the selection
        G_reader_settings:saveSetting("highlight_action_on_single_word", true)
        H.holdAt(Screen:getWidth() * .5, Screen:getHeight() * .4)
        require("ui/uimanager"):scheduleIn(.8, function()
            pcall(function() reader().highlight:saveHighlight() end)
            pcall(function() reader().highlight:clear() end)
            for _n = 1, 4 do
                local stack = UIManager._window_stack
                local top = stack[#stack] and stack[#stack].widget
                if not top or top.name == "ReaderUI" then break end
                pcall(function() UIManager:close(top) end)
            end
        end)
    end },
    { "book-status", function()
        reader().status:onShowBookStatus()
    end },
    { "bookmarks", function()
        reader().bookmark:onShowBookmark()
    end },
    { "dictionary", function()
        local DictQuickLookup = require("ui/widget/dictquicklookup")
        return UIManager:show(DictQuickLookup:new({ window_list = {}, results = { { dict = "Garden dictionary", word = "garden",
            definition = "<b>garden</b> (noun): a plot of ground where flowers, fruit or vegetables are grown.\n\n1. A piece of ground kept for plants.\n2. A place of pleasure, as in a public garden.",
            lookupword = "garden" } }, dictionary = "Garden dictionary", word = "garden", lookupword = "garden", ui = reader() }))
    end },
}

local to_run = {}
for _i, c in ipairs(CASES) do
    if next(only) == nil or only[c[1]] then to_run[#to_run + 1] = c end
end
local reader_run = {}
for _i, c in ipairs(READER_CASES) do
    if next(only) == nil or only[c[1]] then reader_run[#reader_run + 1] = c end
end

-- Show a case in one mode, save it and take it away.
local function take(case, styled, suffix)
    if case[3] and suffix == "before" then
        H.step(.4, case[3])
        H.step(1.4, function() end)
    end
    H.step(.6, function()
        Settings.save("styled_widgets", styled)
        local ok, w = pcall(case[2])
        H.say(case[1], suffix, ok and "shown" or ("ERROR " .. tostring(w)))
        UIManager:forceRePaint()
    end)
    H.step(1.2, function()
        UIManager:forceRePaint()
        H.shot(case[1] .. "-" .. suffix)
    end)
    H.step(.5, function()
        -- take away whatever KOReader window is on top, until only SolarUI's window is left
        for _n = 1, 6 do
            local stack = UIManager._window_stack
            local top = stack[#stack] and stack[#stack].widget
            if not top or top.name == "solarui" or top.name == "FileManager" or top.name == "ReaderUI" then break end
            if top.name == "solarui_popup" then pcall(function() top:close() end) else pcall(function() UIManager:close(top) end) end
        end
    end)
end

for _i, case in ipairs(to_run) do
    take(case, false, "before")
    take(case, true, "after")
end
if #reader_run > 0 then
    H.step(.5, function()
        Settings.save("styled_widgets", true)
        H.app().openBook(require("solarui/data/library").all()[1])
    end)
    H.step(3.5, function()
        H.say("book open", tostring(reader() ~= nil))
        -- a page of text, not the cover
        reader():handleEvent(require("ui/event"):new("GotoPage", 24))
    end)
    H.step(1.5, function() end)
    for _i, case in ipairs(reader_run) do
        take(case, false, "before")
        take(case, true, "after")
    end
end
H.step(.3, function() Settings.save("styled_widgets", true) end)
