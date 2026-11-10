-- A drawing shown in a box: the artwork `name` at the box's size, blended in
-- on every paint from its kept sprite. `param` picks its state (how far a
-- flower has filled); `param_fn`, when set, reads the state anew each paint.
-- `unit` is how many pixels one unit of the drawing's own canvas takes.
-- `fill` names a colour role painted behind it (for a drawing that lies over
-- another page, as on the edge of a drop-down).

local Art = require("solarui/gfx/art")
local Element = require("solarui/ui/element")
local Paint = require("solarui/gfx/paint")
local Theme = require("solarui/theme")

local ArtView = Element:extend({})

-- Pixels per canvas unit: the scene's, or the theme's for a view outside one.
function ArtView:scale()
    return self.unit or (Theme.px(100) / 178)
end

-- The height the drawing was made for, at the box's scale.
function ArtView:naturalHeight()
    return self.height or math.floor((self.vh or 24) * self:scale() + 0.5)
end

-- Draw the artwork across the box.
function ArtView:draw(bb, x, y)
    if self.w < 2 or self.h < 2 then return end
    if self.fill then Paint.fill(bb, x, y, self.w, self.h, Theme.color(self.fill)) end
    local k = self:scale()
    local param = self.param_fn and self.param_fn() or self.param
    Art.draw(bb, self.name, x, y, self.w, self.h, math.floor(self.w / k + 0.5), math.floor(self.h / k + 0.5), param)
end

return ArtView
