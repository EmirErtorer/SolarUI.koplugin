-- The season wheel, twice. garden_season_wheel is the big round the reader
-- picks a season on, in the manner of the clock's face: a gold rim with a
-- band of two vines woven round it, four quarters in the soft colours of
-- the seasons (spring top right, summer bottom right, autumn bottom left,
-- winter top left), parted by stems, each with a medallion near the hub:
-- a crocus, a sunflower, a maple leaf and a snow crystal. The season in
-- the param (its name) has a gold ring round its medallion and a gold arc
-- along its quarter. The screen writes the names on the quarters at 0.28
-- and 0.72 across and 0.30 and 0.70 down, so those places are left plain.
-- garden_season_icon is the small round for the top bar's button: the
-- quarter of the season in the param lit in its colour with its motif.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")
local Weave = require("solarui/art/weave")

local n, group, path, line, circle = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle
local mix = Wash.mix

local Seasons = {}

-- The angle (from the top, clockwise) where each season's quarter starts.
local QUARTER = { spring = 0, summer = 90, autumn = 180, winter = 270 }
local ORDER = { "spring", "summer", "autumn", "winter" }

-- The colour of a season: { the quarter's soft tone, the medallion's ground, the full colour }.
local function tone(c, season)
    if season == "spring" then return { mix(c.leaf, c.cream, .74), mix(c.leaf, c.cream, .4), c.leaf } end
    if season == "summer" then return { mix(c.gold, c.cream, .7), mix(c.sky, c.cream, .12), c.gold } end
    if season == "autumn" then return { mix(c.bloom, c.cream, .72), mix(c.gold, c.cream, .3), c.bloom } end
    return { mix(c.sky, c.cream, .66), mix(c.sky, c.ink, .3), c.sky }
end

-- A wedge of the round about (cx, cy) of radius r between two angles.
local function wedge(cx, cy, r, from, to, fill, stroke, sw)
    local x0, y0 = Svg.pol(r, from, cx, cy)
    local x1, y1 = Svg.pol(r, to, cx, cy)
    return path(string.format("M%s %s L%s %s A%s %s 0 0 1 %s %s Z", n(cx), n(cy), n(x0), n(y0), n(r), n(r), n(x1), n(y1)), fill, stroke, sw)
end

-- A snow crystal of radius `s` at the origin: six arms, each with two pairs
-- of side branches, in white edged with ink.
local function crystal(c, s)
    local d = {}
    for k = 0, 5 do
        local a = k * 60
        local x, y = Svg.pol(s, a)
        d[#d + 1] = string.format("M0 0 L%s %s", n(x), n(y))
        for _i, b in ipairs({ { .42, .3 }, { .7, .2 } }) do
            local bx, by = Svg.pol(s * b[1], a)
            local lx, ly = Svg.pol(s * b[2], a - 50, bx, by)
            local rx, ry = Svg.pol(s * b[2], a + 50, bx, by)
            d[#d + 1] = string.format("M%s %s L%s %s L%s %s", n(lx), n(ly), n(bx), n(by), n(rx), n(ry))
        end
    end
    d = table.concat(d, " ")
    return line(d, c.ink, s * .2) .. line(d, c.cream, s * .1) .. circle(0, 0, s * .16, c.cream, c.ink, s * .05)
end

-- The motif of a season drawn at the origin, about `s` in radius.
local function motif(c, season, s)
    if season == "spring" then
        local leaf = Flora.petal(c, s * .9, s * .16, c.leaf, s * .04)
        return group(0, s * .62, -32, leaf) .. group(0, s * .62, 30, leaf) .. Blooms.crocus(c, 0, s * .6, 0, s * 1.1)
    elseif season == "summer" then
        return Kit.sunflower(c, s * .4, true)
    elseif season == "autumn" then
        return Blooms.maple(c, 0, s * .66, -12, s * 1.3, c.bloom)
    end
    return crystal(c, s * .8)
end

-- A stem parting two quarters from radius r0 to r1 along `deg`, with a pair of leaves halfway.
local function parting(c, cx, cy, r0, r1, deg, u)
    local x0, y0 = Svg.pol(r0, deg, cx, cy)
    local x1, y1 = Svg.pol(r1, deg, cx, cy)
    local mx, my = Svg.pol((r0 + r1) / 2, deg, cx, cy)
    local leaf = Flora.petal(c, u * .05, u * .014, c.sage, u * .003)
    return line(string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1)), c.ink, u * .009) .. line(string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1)), c.stem, u * .004)
        .. group(mx, my, deg, group(0, 0, -50, leaf) .. group(0, 0, 50, leaf) .. group(0, u * .03, -40, leaf, .7) .. group(0, u * .03, 40, leaf, .7))
end

-- The arc of radius `r` along a quarter starting at `from`, as points.
local function arc(cx, cy, r, from)
    local pts = {}
    for d = from + 2, from + 88, 2 do
        local x, y = Svg.pol(r, d, cx, cy)
        pts[#pts + 1] = { x, y }
    end
    return pts
end

-- The big wheel.
function Seasons.garden_season_wheel(c, vw, _vh, param)
    c = Wash.apply(c, param)
    local season = tostring(param or ""):match("%a+")
    local cx, cy, u = vw / 2, vw / 2, vw
    local out = { circle(cx, cy, u * .497, c.gold, c.ink, u * .006), Weave.ring(c, cx, cy, u * .4795, u * .0085, 20, u * .0105),
        circle(cx, cy, u * .461, c.pale, c.ink, u * .005) }
    for _i, s in ipairs(ORDER) do
        local t = tone(c, s)
        out[#out + 1] = wedge(cx, cy, u * .442, QUARTER[s], QUARTER[s] + 90, mix(t[1], t[3], .22), c.ink, u * .004) .. wedge(cx, cy, u * .418, QUARTER[s], QUARTER[s] + 90, t[1])
        for d = QUARTER[s] + 6, QUARTER[s] + 84, 6 do
            local x, y = Svg.pol(u * .43, d, cx, cy)
            out[#out + 1] = circle(x, y, u * (d % 18 == 0 and .0042 or .0024), mix(t[3], c.ink, .25))
        end
    end
    out[#out + 1] = circle(cx, cy, u * .418, nil, c.ink, u * .0025)
    if QUARTER[season] then out[#out + 1] = Weave.band(c, arc(cx, cy, u * .4515, QUARTER[season]), u * .011, c.gold, u * .003) end
    for _i, deg in ipairs({ 0, 90, 180, 270 }) do out[#out + 1] = parting(c, cx, cy, u * .06, u * .442, deg, u) end
    local r = u * .062
    for _i, s in ipairs(ORDER) do
        local x, y = Svg.pol(u * .132, QUARTER[s] + 45, cx, cy)
        if s == season then out[#out + 1] = circle(x, y, r * 1.16, c.gold, c.ink, u * .004) end
        out[#out + 1] = circle(x, y, r, tone(c, s)[2], c.ink, u * .004) .. group(x, y, 0, motif(c, s, r * .82))
    end
    out[#out + 1] = Flora.around(cx, cy, u * .012, 8, Flora.petal(c, u * .042, u * .016, c.gold, u * .004), 22.5)
        .. circle(cx, cy, u * .028, c.bloom, c.ink, u * .006) .. circle(cx, cy, u * .011, c.gold, c.ink, u * .004)
    return table.concat(out)
end

-- The small picture for the top bar's button: a gold rim round four
-- quarters, the season's one in its colour with its motif, the rest plain.
function Seasons.garden_season_icon(c, vw, _vh, param)
    c = Wash.apply(c, param)
    local season = tostring(param or ""):match("%a+")
    local out = { circle(50, 50, 47, c.gold, c.ink, 3.4) }
    for _i, s in ipairs(ORDER) do
        if s ~= season then out[#out + 1] = wedge(50, 50, 39, QUARTER[s], QUARTER[s] + 90, c.cream, c.ink, 3) end
    end
    out[#out + 1] = circle(50, 50, 39, nil, c.ink, 3.4)
    if QUARTER[season] then
        local x, y = Svg.pol(22, QUARTER[season] + 45, 50, 50)
        out[#out + 1] = wedge(50, 50, 43, QUARTER[season], QUARTER[season] + 90, tone(c, season)[2], c.ink, 3.4) .. group(x, y, 0, motif(c, season, 16))
    end
    out[#out + 1] = circle(50, 50, 5, c.bloom, c.ink, 2.4)
    return group(0, 0, 0, table.concat(out), vw / 100)
end

return Seasons
