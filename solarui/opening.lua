-- The opening card: what the screen shows while a book opens, in place of the
-- small "Opening file" message KOReader would draw. The book stands in home's
-- golden halo, the peacock fan behind it, roses at its foot, on an Opening
-- plaque; under it the title, where reading resumes and a line from the
-- garden companion. The load blocks, so the card is painted once, just before it
-- starts, and costs one small paint; nothing on it moves.

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

-- The last line: who keeps the garden while the book is read.
local function gardenLine()
    local ok, item = pcall(function() return require("solarui/ui/homecompanion").pick() end)
    if not (ok and item) then return _("The garden will be here when you come back.") end
    return string.format(_("%s keeps the garden while you read."), require("solarui/garden/state").name(item.id))
end

-- The card for the book at `path`, on a screen `w` wide.
function Opening.card(path, w)
    local Books = require("solarui/data/books")
    local Cover = require("solarui/ui/cover")
    local Dialog = require("solarui/ui/dialog")
    local Label = require("solarui/ui/label")
    local Scene = require("solarui/ui/scene")
    local info, st = Books.info(path), Books.state(path)
    -- (a small card in the middle of the screen, not a whole page)
    w = math.floor(w * 0.62)
    local inner = Dialog.inner(w)
    local VH = 640
    local scene = Scene.make("opening", inner, math.floor(inner * VH / Scene.design_w), VH)
    -- home's hero, centred: the fan, the sprig, the halo, the cover and the roses
    scene:backdrop("peacock_fan", 236, -40, 600, 600)
    scene:backdrop("sprig", 702, 34, 120, 138)
    scene:backdrop("halo", 301, 24, 470, 470)
    scene:place(Cover:new({ path = path }), 388, 142, 296, 444)
    scene:sprite("rose_cluster", 244, 342, 200, 300)
    scene:sprite("plaque", 361, 548, 350, 84)
    scene:place(Label:new({ text = _("Opening"), kind = "label", color = "on_accent", align = "center" }), 391, 548, 290, 84)
    local resume = st.percent > 0 and string.format(_("Back at %d%%."), math.floor(st.percent * 100 + 0.5)) or _("A first opening.")
    local card = Dialog.card({ top = scene, title = info.title, detail = info.author ~= "" and info.author or nil,
        text = resume .. "\n" .. gardenLine(), lines = 3 }, w) -- i18n: keep
    return card
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
