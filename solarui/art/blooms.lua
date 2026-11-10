-- More flowers and leaves of the garden: a maple leaf, the dandelion in
-- bloom, narcissus, crocus, pansy and the lily. Each is drawn upright with
-- its centre (or its stalk, for the leaf) at the origin of its group and
-- returns SVG text, like the plants of art/flora.lua.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n, group, petal, around = Svg.n, Svg.group, Flora.petal, Flora.around

local Blooms = {}

-- The five lobes of a maple leaf: the angle each points at from straight up,
-- its length (in units of the leaf's height) and how far its edges spread, in
-- degrees. The leaf's edge is the farthest any lobe reaches in each direction,
-- notched like a saw.
local LOBES = { { -100, .5, 38 }, { -52, .68, 38 }, { 0, .82, 42 }, { 52, .68, 38 }, { 100, .5, 38 } }
local HUB = -.25

-- A maple leaf standing on its stalk at (x, y), `R` tall, in `fill`, with a
-- vein out to each lobe and a curved stalk.
function Blooms.maple(c, x, y, rot, R, fill)
    local pts = {}
    for deg = -134, 134, 2 do
        local r = 0
        for _i, lobe in ipairs(LOBES) do r = math.max(r, lobe[2] * math.max(0, 1 - math.abs(deg - lobe[1]) / lobe[3])) end
        if r > .3 then r = r * (1 - .2 * (math.abs(deg) % 8) / 8) end
        local a = math.rad(deg)
        pts[#pts + 1] = { R * r * math.sin(a), HUB * R - R * r * math.cos(a) }
    end
    local veins = {}
    for _i, lobe in ipairs(LOBES) do
        local a = math.rad(lobe[1])
        veins[#veins + 1] = string.format("M0 %s L%s %s", n(HUB * R), n(R * lobe[2] * .85 * math.sin(a)), n(HUB * R - R * lobe[2] * .85 * math.cos(a)))
    end
    local body = Svg.path(Svg.poly(pts, true), fill or c.bloom, c.ink, 2)
        .. Svg.line(table.concat(veins, " "), c.ink, 1.2)
        .. Svg.line(string.format("M0 %s Q%s %s %s %s", n(HUB * R), n(R * .03), n(HUB * R * .3), n(-R * .02), n(R * .04)), c.ink, 2.6)
    return group(x, y, rot, body)
end

-- A dandelion in bloom (karahindiba) of radius `R` seen from the front: a
-- ruff of green bracts under two rings of thin golden florets.
function Blooms.karahindiba(c, cx, cy, R)
    local body = around(0, 0, R * .1, 12, petal(c, R * .98, R * .1, c.leaf, 1.2), 15)
        .. around(0, 0, R * .1, 24, petal(c, R * .9, R * .11, c.gold, 1.2), 7)
        .. around(0, 0, R * .08, 18, petal(c, R * .62, R * .1, c.pale, 1.1), 10)
        .. Svg.circle(0, 0, R * .2, c.gold, c.ink, 1.4) .. Svg.dots(0, 0, R * .08, 5, R * .06, c.ink)
    return group(cx, cy, 0, body)
end

-- A narcissus (nergis) of radius `R`: six cream petals round a ruffled
-- golden cup.
function Blooms.narcissus(c, cx, cy, R)
    local body = around(0, 0, 0, 6, petal(c, R, R * .42, c.cream, 1.7), 0)
        .. Svg.circle(0, 0, R * .46, c.gold, c.ink, 1.9)
        .. Svg.dots(0, 0, R * .46, 10, R * .13, c.gold) .. Svg.circle(0, 0, R * .3, c.bloom2, c.ink, 1.3)
        .. Svg.circle(0, 0, R * .12, c.ink)
    return group(cx, cy, 0, body)
end

-- A crocus of height `s` at (x, y): three pointed petals forming a goblet
-- round a tuft of golden stamens.
function Blooms.crocus(c, x, y, rot, s)
    local side = petal(c, s, s * .36, c.cream, 1.7)
    local body = group(0, 0, -26, side) .. group(0, 0, 26, side)
        .. Svg.line(string.format("M%s %s L%s %s M%s %s L%s %s M0 %s L0 %s", n(-s * .05), n(-s * .2), n(-s * .12), n(-s * .7),
            n(s * .05), n(-s * .2), n(s * .12), n(-s * .7), n(-s * .1), n(-s * .66)), c.gold, 3)
        .. group(0, 0, 0, petal(c, s * 1.1, s * .4, c.cream, 1.7))
        .. Svg.line(string.format("M0 %s L0 %s M%s %s L%s %s M%s %s L%s %s", n(-s * .15), n(-s * .85), n(-s * .1), n(-s * .15), n(-s * .26), n(-s * .6), n(s * .1), n(-s * .15), n(s * .26), n(-s * .6)), c.bloom2, 2.2)
    return group(x, y, rot, body)
end

-- A pansy (hercai menekşe) of radius `R`: two upper petals, two at the
-- sides and a broad golden one below, with whiskers to the dark eye.
function Blooms.pansy(c, cx, cy, R)
    local whiskers = {}
    for _i, a in ipairs({ -50, 0, 50 }) do
        local x, y = Svg.pol(R * .5, a + 180)
        whiskers[#whiskers + 1] = string.format("M0 0 L%s %s", n(x), n(y))
    end
    local body = group(0, 0, -36, petal(c, R * 1.05, R * .55, c.sky, 1.7)) .. group(0, 0, 36, petal(c, R * 1.05, R * .55, c.sky, 1.7))
        .. group(0, 0, -96, petal(c, R * .95, R * .5, c.glass, 1.7)) .. group(0, 0, 96, petal(c, R * .95, R * .5, c.glass, 1.7))
        .. group(0, 0, 180, petal(c, R * 1.05, R * .7, c.gold, 1.7))
        .. Svg.line(table.concat(whiskers, " "), c.ink, 1.3) .. Svg.circle(0, 0, R * .2, c.gold, c.ink, 1.4) .. Svg.circle(0, 0, R * .09, c.ink)
    return group(cx, cy, 0, body)
end

-- A lily (zambak) of radius `R`: six long cream petals streaked with pink, a
-- paler disc at the heart for an icon, and stamens with golden anthers.
function Blooms.lily(c, cx, cy, R)
    local stamens = {}
    for i = 0, 5 do
        local x, y = Svg.pol(R * .56, i * 60 + 30)
        stamens[#stamens + 1] = Svg.line(string.format("M0 0 L%s %s", n(x), n(y)), c.ink, 1) .. Svg.ellipse(x, y, R * .09, R * .05, i * 60 + 30, c.gold, c.ink, 1)
    end
    local body = around(0, 0, 0, 6, petal(c, R, R * .3, c.cream, 1.7) .. Svg.line(string.format("M0 %s L0 %s", n(-R * .25), n(-R * .8)), c.bloom, 2), 0)
        .. around(0, 0, 0, 6, petal(c, R * .78, R * .24, c.cream, 1.5), 30)
        .. table.concat(stamens) .. Svg.circle(0, 0, R * .6, c.cream, c.ink, 1.6)
    return group(cx, cy, 0, body)
end

return Blooms
