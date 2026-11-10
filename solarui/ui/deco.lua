-- Small decorative elements of the style: a divider line, the budded rule
-- under a row and a hatched box.

local Art = require("solarui/gfx/art")
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

-- The rule under a row of a list: a bud between two leaves on a stalk at its
-- left end, a hairline, and a small curl at its right end. The two ends are
-- kept drawings, so a long list costs two blits a row.
Deco.RowRule = Element:extend({ color = "line" })
function Deco.RowRule:naturalHeight()
    return Theme.px(9)
end
function Deco.RowRule:draw(bb, x, y)
    local k = Theme.px(100) / 178
    local bw, cw = Theme.px(26), Theme.px(16)
    Art.draw(bb, "row_bud", x, y, bw, self.h, bw / k, self.h / k)
    Art.draw(bb, "row_curl", x + self.w - cw, y, cw, self.h, cw / k, self.h / k)
    local hair = Theme.get().size.hair
    Paint.fill(bb, x + bw, y + math.floor(self.h * .6) - math.floor(hair / 2), self.w - bw - cw, hair, Theme.color(self.color))
end

-- A box filled with stripes ("h", "v", "d", "b"), like a print's hatching.
Deco.Stripes = Element:extend({ color = "line", dir = "h", period = 6, thick = 2 })
function Deco.Stripes:naturalHeight() return self.height or Theme.px(16) end
function Deco.Stripes:draw(bb, x, y)
    Paint.stripes(bb, x, y, self.w, self.h, self.dir, Theme.px(self.period), Theme.px(self.thick), Theme.color(self.color))
end

return Deco
