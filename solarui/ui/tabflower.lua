-- A tab of the drop-down menu as a small flower: the flower is drawn by
-- art/tabflowers.lua and the tab's icon, which says what the tab holds, sits
-- in its heart. The chosen tab is in fuller colour. A tap chooses the tab.

local Art = require("solarui/gfx/art")
local Element = require("solarui/ui/element")
local Icons = require("solarui/gfx/icons")
local Tabflowers = require("solarui/art/tabflowers")
local Theme = require("solarui/theme")

local TabFlower = Element:extend({ kind = 1 })

-- Draw the flower, then the icon over its heart.
function TabFlower:draw(bb, x, y)
    local k = Theme.px(100) / 178
    local flower_w = math.min(self.w, math.floor(self.h * .9))
    local fx = x + math.floor((self.w - flower_w) / 2)
    Art.draw(bb, "tab_flower", fx, y, flower_w, self.h, flower_w / k, self.h / k, self.kind .. ":" .. (self.chosen and 1 or 0))
    local R = math.min(flower_w * .46, self.h * .36)
    local size = math.floor(R * Tabflowers.HEART * 2 * .82)
    local th = Theme.get()
    Icons.draw(bb, self.icon, fx + math.floor(flower_w / 2 - size / 2), y + math.floor(self.h * .4 - size / 2), size, th.c.ink, th.c.accent)
end

return TabFlower
