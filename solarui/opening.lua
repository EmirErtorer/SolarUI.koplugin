-- The opening card: what the screen shows while a book opens, in place of the
-- small "Opening file" message KOReader would draw. A slim card with a pressed
-- sprig: where reading resumes and how long is left, and a line the reader once
-- marked in the book, brought back as the book opens. The load blocks, so the
-- card is painted once, just before it starts; nothing on it moves.

local Settings = require("solarui/settings")
local UIManager = require("ui/uimanager")
local filemanagerutil = require("apps/filemanager/filemanagerutil")
local lfs = require("libs/libkoreader-lfs")
local _ = require("solarui/gettext")

local Opening = {}

-- Is the card on, and is there a file to open?
function Opening.wanted(path)
    return Settings.get("opening_card", true) and lfs.attributes(path, "mode") == "file"
end

-- A line the reader marked in this book, at random, or nil.
local function marked(path)
    local ok, kinds = pcall(function() return require("solarui/data/annotations").kinds(path) end)
    local list = {}
    for _i, a in ipairs(ok and kinds.highlights or {}) do
        local letters = select(2, a.text:gsub("[^\128-\191]", ""))
        if letters >= 20 and letters <= 160 and require("solarui/garden/plaque").readable(a.text) then list[#list + 1] = a.text end
    end
    return #list > 0 and list[math.random(#list)] or nil
end

-- Who keeps the garden while the book is read, as a line.
local function gardenLine()
    local ok, item = pcall(function() return require("solarui/ui/homecompanion").pick() end)
    if not (ok and item) then return _("The garden will be here when you come back.") end
    return string.format(_("%s keeps the garden while you read."), require("solarui/garden/state").name(item.id))
end

-- Where reading resumes and how long is left at the reader's pace, as a line.
local function resumeLine(path)
    local Books, Format = require("solarui/data/books"), require("solarui/format")
    local st = Books.state(path)
    if st.percent <= 0 then return _("A first opening.") end
    local back = string.format(_("Back at %d%%."), math.floor(st.percent * 100 + 0.5))
    local ok, t = pcall(function() return require("solarui/data/insights").book(path) end)
    if ok and t and t.per_page and t.total_pages and t.pages and t.per_page > 0 then
        local left = math.max(0, t.total_pages - t.pages) * t.per_page
        if left > 60 then return string.format(_("%s %s left."), back, Format.duration(left)) end
    end
    return back
end

-- The card for the book at `path`, on a screen `w` wide: a slim card with a
-- pressed sprig, where reading resumes, and a line the reader once marked in
-- this book (or, with none, who keeps the garden meanwhile).
function Opening.card(path, w)
    local ArtView = require("solarui/ui/artview")
    local Dialog = require("solarui/ui/dialog")
    local Label = require("solarui/ui/label")
    local Layout = require("solarui/ui/layout")
    local Theme = require("solarui/theme")
    local th = Theme.get()
    w = math.floor(w * 0.72)
    local line = marked(path)
    local text = line and string.format("\u{201C}%s\u{201D}", line) or gardenLine() -- i18n: keep
    local row = Layout.Row:new({ gap = th.space.m, valign = "center", children = {
        ArtView:new({ name = "sprig", width = Theme.px(46), height = Theme.px(54) }),
        Layout.Column:new({ grow = true, gap = th.space.xs, children = {
            Label:new({ text = resumeLine(path), kind = "heading", lines = 2 }),
            Label:new({ text = text, kind = "small", color = "muted", lines = 3 }),
        } }),
    } })
    return Dialog.card({ rows = { row } }, w)
end

-- Run show() (the call that opens the book) with KOReader's own "Opening file"
-- message kept off the screen, so the card stays alone. Anything else shown on
-- the way (a question about restoring the book's notes) is let through.
function Opening.silenced(path, show)
    local abbreviated = filemanagerutil.abbreviate(path)
    local original = UIManager.show
    local function quiet(self, widget, ...)
        if widget and widget.timeout == 0 and type(widget.text) == "string" and widget.text:find(abbreviated, 1, true) then
            return
        end
        return original(self, widget, ...)
    end
    UIManager.show = quiet
    local ok, err = pcall(show)
    if UIManager.show == quiet then UIManager.show = original end
    if not ok then error(err, 0) end
end

return Opening
