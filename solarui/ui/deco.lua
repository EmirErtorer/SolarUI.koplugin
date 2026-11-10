-- Small decorative elements of the style: a divider line, the budded rule
-- under a row and a hatched box.

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

-- The rule under a row of a list: a hairline growing out of a small bud at
-- its left end. Drawn with plain fills, so a long list costs nothing more.
Deco.RowRule = Element:extend({ color = "line", bud = "leaf" })
function Deco.RowRule:naturalHeight()
    return Theme.px(5)
end
function Deco.RowRule:draw(bb, x, y)
    local d = self.h
    local hair = Theme.get().size.hair
    Paint.disc(bb, x, y, d, Theme.color(self.bud))
    Paint.fill(bb, x + d + Theme.px(3), y + math.floor((d - hair) / 2), self.w - d - Theme.px(3), hair, Theme.color(self.color))
end

-- A box filled with stripes ("h", "v", "d", "b"), like a print's hatching.
Deco.Stripes = Element:extend({ color = "line", dir = "h", period = 6, thick = 2 })
function Deco.Stripes:naturalHeight() return self.height or Theme.px(16) end
function Deco.Stripes:draw(bb, x, y)
    Paint.stripes(bb, x, y, self.w, self.h, self.dir, Theme.px(self.period), Theme.px(self.thick), Theme.color(self.color))
end

return Deco
