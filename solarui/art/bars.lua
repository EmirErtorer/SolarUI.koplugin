-- The flowers of the bar charts: one plant per bar, as tall as the bar is high.
-- bar_flower(c, vw, vh, param) draws on a canvas as wide as one bar and as
-- tall as the chart above its baseline; param is "<height percent>:<chosen>",
-- height 0 meaning nothing was read (a sprout) and chosen 1 for the bar picked.

local Svg = require("solarui/art/svg")

local n = Svg.n

local Bars = {}

-- A plain first flower (to be redrawn).
function Bars.bar_flower(c, vw, vh, param)
    local pct, chosen = tostring(param or "0:0"):match("^(%d+):(%d)$")
    pct = tonumber(pct) or 0
    local top = vh - math.max(vw * .5, (vh - vw * .5) * pct / 100)
    return Svg.line(string.format("M%s %s L%s %s", n(vw / 2), n(vh), n(vw / 2), n(top)), c.stem, 3)
        .. Svg.circle(vw / 2, top, vw * .22, chosen == "1" and c.bloom or c.bloom2)
end

return Bars
