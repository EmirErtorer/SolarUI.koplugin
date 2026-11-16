-- Choosing the look of a notebook (one of ten covers) or a drawing (one of
-- eight frames) on the notebook shelf: every look drawn on its own tile, the
-- current one framed twice. params: { kind, path, name, current }.

local App = require("solarui/app")
local ArtView = require("solarui/ui/artview")
local Frame = require("solarui/screens/frame")
local Grid = require("solarui/ui/grid")
local InkCovers = require("solarui/art/inkcovers")
local InkFrames = require("solarui/art/inkframes")
local InkShelf = require("solarui/data/inkshelf")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Panel = require("solarui/ui/panel")
local Screen = require("solarui/screens/screen")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local InkPick = Screen:extend()

-- Start on the first page.
function InkPick:init() self.page = 1 end

-- The looks of the kind being chosen, with their names in the reader's language.
local NAMES = {
    verdure = _("Verdure"), tooled = _("Tooled leather"), nasturtium = _("Nasturtium"), peacock = _("Peacock"), iris = _("Iris"), poppy = _("Poppy"),
    dragonfly = _("Dragonfly"), ginkgo = _("Ginkgo"), page = _("First page"), mount = _("First page, mounted"),
    gilt = _("Gilt"), oak = _("Carved oak"), iron = _("Iron and mat"), halo = _("Halo"), lily = _("Lily"), copper = _("Copper"), pearl = _("Pearl"),
}

-- One look: its drawing over its name, framed twice when it is the current one.
local function tile(self, look, w, h)
    local th = Theme.get()
    local p = self.params
    local drawings = p.kind == InkShelf.DRAWINGS
    local aw = math.min(w - 2 * th.space.s, math.floor((h - Theme.text("small").height * 2 - th.space.m) * 2 / 3))
    local ah = drawings and math.floor(aw * 1.2) or math.floor(aw * 1.5)
    return Panel:new({ shape = "frame", double = look.id == p.current, pad = th.space.xs, width = w, height = h,
        on_tap = function()
            App.pop()
            InkShelf.setLook(p.kind, p.path, look.id)
            App.update()
        end,
        child = Layout.Column:new({ gap = th.space.xs, align = "center", children = {
            ArtView:new({ name = (drawings and "inkframe_" or "inkcover_") .. look.id, width = aw, height = ah }),
            Label:new({ text = NAMES[look.id] or look.name, kind = "small", align = "center", lines = 2 }),
        } }) })
end

-- Build the grid.
function InkPick:build()
    local th = Theme.get()
    local p = self.params
    local looks = p.kind == InkShelf.DRAWINGS and InkFrames.LOOKS or InkCovers.LOOKS
    local grid = Grid:new({
        grow = true, items = looks, page = self.page, min_cell_w = Theme.px(130), ratio = 1.75, fit = true, row_gap = th.space.s, gap = th.space.s,
        make = function(look, w, h) return tile(self, look, w, h) end,
        on_layout = function(_cap, pages, page) self.pages, self.page = pages, page end,
    })
    return Frame.page({ screen = self, title = p.kind == InkShelf.DRAWINGS and _("Frame") or _("Cover"), path = p.name, tab = "home", plant = "library",
        body = Layout.Column:new({ gap = th.space.m, children = { grid, Frame.pager(self, _("Page"), function(pg) self:setPage(pg) end) } }) })
end

return InkPick
