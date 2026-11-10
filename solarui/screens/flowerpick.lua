-- Choosing the flower a launcher button grows as: every flower of the garden
-- drawn on its own tile in a paged grid. Each is one kept drawing, so the
-- page costs a handful of sprites.

local App = require("solarui/app")
local ArtView = require("solarui/ui/artview")
local Frame = require("solarui/screens/frame")
local Grid = require("solarui/ui/grid")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local LauncherUI = require("solarui/ui/launcher")
local Panel = require("solarui/ui/panel")
local Screen = require("solarui/screens/screen")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local FlowerPick = Screen:extend()

-- Start on the first page; params: { current (a drawing name), on_pick(name) }.
function FlowerPick:init() self.page = 1 end

-- One flower: its drawing over its name, framed twice when it is the current one.
local function tile(self, item, w, h)
    local th = Theme.get()
    local params = self.params
    return Panel:new({ shape = "frame", double = item.dock == params.current, pad = th.space.xs, width = w, height = h,
        on_tap = function() App.pop(); params.on_pick(item.dock) end,
        child = Layout.Column:new({ gap = 0, align = "center", children = {
            ArtView:new({ name = item.dock, width = Theme.px(96), height = Theme.px(83) }),
            Label:new({ text = item.en, kind = "small", align = "center", lines = 2 }),
            Label:new({ text = item.latin, kind = "small", color = "muted", align = "center", lines = 2 }),
        } }) })
end

-- Build the grid.
function FlowerPick:build()
    local th = Theme.get()
    local grid = Grid:new({
        grow = true, items = LauncherUI.PLANTS, page = self.page, min_cell_w = Theme.px(120), cell_h = Theme.px(170), row_gap = th.space.s, gap = th.space.s,
        make = function(item, w, h) return tile(self, item, w, h) end,
        on_layout = function(_cap, pages, page) self.pages, self.page = pages, page end,
    })
    return Frame.page({ screen = self, title = _("Flower"), tab = "settings", plant = "settings",
        body = Layout.Column:new({ gap = th.space.m, children = { grid, Frame.pager(self, _("Page"), function(p) self:setPage(p) end) } }) })
end

return FlowerPick
