-- The flowers of the bar charts: one plant per bar, as tall as the bar is high.
-- bar_flower(c, vw, vh, param) draws on a canvas as wide as one bar and as
-- tall as the chart above its baseline; param is "<height percent>:<chosen>",
-- height 0 meaning nothing was read (a sprout) and chosen 1 for the bar picked.
-- Every plant grows out of the middle of the canvas's foot and keeps clear of
-- its sides, so neighbours never touch.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local Bars = {}

-- The stem as points from the foot of the canvas up to (m, top), swaying
-- once to each side by `sway`.
local function stemWay(m, foot, top, sway)
    local h = foot - top
    return Svg.spline({ { m, foot }, { m - sway, foot - h * .3 }, { m + sway * .8, foot - h * .68 }, { m, top } }, 10)
end

-- A day without reading: a seedling in the middle of the canvas's foot,
-- lower than the youngest flower; the chosen one is larger, its husk in
-- the colour of the chosen flower.
local function sprout(c, vw, vh, chosen)
    local s = math.min(vw * .3, vh * .05)
    return Blooms.seedling(c, vw / 2, vh, chosen and s * 1.3 or s, chosen and c.bloom or nil)
end

-- Leaves by turns left and right up the stem `pts`, `count` of them, the
-- lowest the largest; none is longer than `reach`.
local function leaves(c, pts, count, reach)
    local len, out = Svg.length(pts), {}
    for i = 1, count do
        local f = count == 2 and (.04 + .1 * i) or (.14 + .5 * (i - 1) / (count - 1))
        local x, y = Svg.along(pts, len * f)
        local L = reach * (1 - .28 * (i - 1) / (count - 1))
        local lift = count == 2 and 22 or 32
        out[#out + 1] = Flora.leaf(c, x, y, i % 2 == 1 and lift - 180 or -lift, L, L * .34, i % 2 == 1 and c.leaf or c.sage, L < 30)
    end
    return table.concat(out)
end

-- A day's reading as a flower as tall as its bar: a bar too short for a full
-- flower holds the same flower grown smaller, so a little reading looks like
-- a little and a lot like a lot; a tall one carries more leaves. The chosen
-- one is larger, deeper in colour and has a second ring of petals.
local function flower(c, vw, vh, pct, chosen)
    local m = vw / 2
    local full = math.min(vw * .42, math.max(vh * .12, math.min(vh * .2, 16)))
    local R_full = full * (chosen and 1 or .84)
    local smallest = 2 * R_full + full          -- the height of the smallest full-size flower
    -- (a day read is never lower than a small flower, so it stands above a day not read)
    local height = math.max(vh * .97 * pct / 100, vh * .09)
    -- below that height the whole flower shrinks with the bar (never to nothing)
    local scale = math.min(1, height / smallest)
    local R, size = R_full * scale, full * scale
    local top = vh - math.max(height, 2 * R + size)
    local cy = top + R
    local stalk = vh - cy
    local sway = math.min(vw * .07, stalk * .07)
    local pts = stemWay(m, vh, cy, sway)
    local reach = math.min(vw * .42 - sway, size * 1.25, stalk * .9)
    local count = math.max(2, math.min(5, math.floor(stalk / (size * 1.5))))
    return Svg.line(Svg.poly(pts), c.stem, math.max(1.4, size * .1))
        .. leaves(c, pts, count, reach)
        .. Blooms.blossom(c, m, cy, R, chosen and c.bloom or c.bloom2, chosen and c.gold or nil, chosen and 0 or (pct * 7) % 72 - 36)
end

-- One bar of a chart: a sprout for nothing, otherwise a flower.
function Bars.bar_flower(c, vw, vh, param)
    local pct, chosen = tostring(param or "0:0"):match("^(%d+):(%d)$")
    pct = math.min(100, tonumber(pct) or 0)
    if pct <= 0 then return sprout(c, vw, vh, chosen == "1") end
    return flower(c, vw, vh, pct, chosen == "1")
end

return Bars
