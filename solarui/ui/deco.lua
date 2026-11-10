-- Small decorative elements of the style: a divider line and a hatched box.

local Element = require("solarui/ui/element")
local Paint = require("solarui/gfx/paint")
local Theme = require("solarui/theme")

local Deco = {}

-- A horizontal line (as tall as its `thick`, or its `height`).
Deco.Divider = Element:extend({ color = "line", thick = "hair" })
function Deco.Divider:naturalHeight()
    return self.height or Theme.get().size[self.thick]
end
function Deco.Divider:draw(bb, x, y)
    Paint.fill(bb, x, y, self.w, self.h, Theme.color(self.color))
end

-- A box filled with stripes ("h", "v", "d", "b"), like a print's hatching.
Deco.Stripes = Element:extend({ color = "line", dir = "h", period = 6, thick = 2 })
function Deco.Stripes:naturalHeight() return self.height or Theme.px(16) end
function Deco.Stripes:draw(bb, x, y)
    Paint.stripes(bb, x, y, self.w, self.h, self.dir, Theme.px(self.period), Theme.px(self.thick), Theme.color(self.color))
end

return Deco
