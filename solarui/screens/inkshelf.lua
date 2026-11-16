-- The notebook shelf: Ink Away's notebooks and drawings standing on shelves,
-- in two tabs (Notebooks first). Each notebook wears one of ten covers and
-- each drawing hangs in one of eight frames (data/inkshelf.lua deals them and
-- draws each once, in the background); a tap opens it in Ink Away on the page
-- it was left, a long press chooses its cover or frame. Without Ink Away the
-- shelf says how to get it.

local Addons = require("solarui/apps/addons")
local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Controls = require("solarui/ui/controls")
local EmptyState = require("solarui/ui/emptystate")
local Frame = require("solarui/screens/frame")
local Grid = require("solarui/ui/grid")
local InkAway = require("solarui/apps/inkaway")
local InkCover = require("solarui/ui/inkcover")
local InkShelf = require("solarui/data/inkshelf")
local Layout = require("solarui/ui/layout")
local Screen = require("solarui/screens/screen")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local InkShelfScreen = Screen:extend()

-- Notebooks first, on the first page. params: { kind }.
function InkShelfScreen:init(params)
    self.kind = params.kind == InkShelf.DRAWINGS and InkShelf.DRAWINGS or InkShelf.NOTEBOOKS
    self.page = 1
end

-- Covers landed: show them, if the shelf is still in front.
function InkShelfScreen:coversLanded()
    if App.current() == self then App.update() end
end

-- One document on the shelf: its cover; a tap opens it, a long press picks its look.
function InkShelfScreen:tile(doc)
    local kind = self.kind
    return InkCover:new({ file = doc.cover, name = doc.name,
        on_tap = function()
            if not InkShelf.open(kind, doc.path) then App.toast(_("Ink Away is not running")) end
        end,
        on_hold = function() App.push("inkpick", { kind = kind, path = doc.path, name = doc.name, current = doc.look and doc.look.id }) end,
    })
end

-- The body for the tab shown: the shelves, or why there is nothing on them.
function InkShelfScreen:shelves()
    if not InkShelf.available() then
        return EmptyState.build({ plant = "library", title = _("Ink Away is not installed"),
            text = _("Ink Away keeps your notebooks and drawings. Once it is here, they stand on these shelves."),
            action = Button:new({ label = _("Get Ink Away"), variant = "primary", on_tap = function() Addons.launch(InkAway) end }) })
    end
    local docs = InkShelf.list(self.kind, function() self:coversLanded() end) or {}
    if #docs == 0 then
        local drawings = self.kind == InkShelf.DRAWINGS
        return EmptyState.build({ plant = "library", title = drawings and _("No drawings yet") or _("No notebooks yet"),
            text = drawings and _("Drawings you make in Ink Away hang here, each in a frame of its own.")
                or _("Notebooks you make in Ink Away stand here, each in a cover of its own."),
            action = Button:new({ label = _("Open Ink Away"), variant = "primary", on_tap = function() Addons.launch(InkAway) end }) })
    end
    return Grid:new({
        grow = true, items = docs, page = self.page, fit = true, rails = true,
        min_cell_w = Theme.px(self.kind == InkShelf.DRAWINGS and 150 or 130), ratio = self.kind == InkShelf.DRAWINGS and 1.15 or 1.5,
        gap = Theme.get().space.m, row_gap = Theme.get().space.l,
        make = function(doc) return self:tile(doc) end,
        on_layout = function(_cap, pages, page) self.pages, self.page = pages, page end,
    })
end

-- Build the screen.
function InkShelfScreen:build()
    local th = Theme.get()
    local switch = Controls.Segmented({ value = self.kind, options = { { _("Notebooks"), InkShelf.NOTEBOOKS }, { _("Drawings"), InkShelf.DRAWINGS } },
        on_change = function(kind) self.kind, self.page = kind, 1; App.update() end })
    return Frame.page({
        screen = self, title = self.kind == InkShelf.DRAWINGS and _("Drawings") or _("Notebooks"), tab = "home", plant = "library",
        body = Layout.Column:new({ gap = th.space.l, children = { switch, self:shelves(), Frame.pager(self, _("Page"), function(p) self:setPage(p) end) } }),
    })
end

return InkShelfScreen
