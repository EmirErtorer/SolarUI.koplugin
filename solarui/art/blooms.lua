-- More flowers and leaves of the garden: a maple leaf, the dandelion in
-- bloom, narcissus, crocus, pansy, the lily, a five-petal blossom and a
-- seedling. Each is drawn upright with its centre (or its stalk, for the
-- leaf) at the origin of its group and returns SVG text, like the plants of
-- art/flora.lua.

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

-- A lily (zambak) of radius `R`, kept plain: six long cream petals round a
-- large pale disc that carries a button's icon.
function Blooms.lily(c, cx, cy, R)
    local body = around(0, 0, 0, 6, petal(c, R, R * .34, c.cream, 1.8), 0)
        .. Svg.circle(0, 0, R * .62, c.cream, c.ink, 1.8)
    return group(cx, cy, 0, body)
end

-- A broad petal with a notch at its tip, growing up from the origin.
local function notched(c, L, W, fill, sw)
    return Svg.path(string.format("M0 0 C%s %s %s %s %s %s Q0 %s %s %s C%s %s %s %s 0 0Z",
        n(-W * .95), n(-L * .28), n(-W * 1.2), n(-L * .96), n(-W * .3), n(-L), n(-L * .84), n(W * .3), n(-L),
        n(W * 1.2), n(-L * .96), n(W * .95), n(-L * .28)), fill, c.ink, sw)
end

-- A five-petal blossom (apple, wild rose) of radius `R` in `fill`, with a
-- golden heart: `back`, when given, is the colour of five more petals that
-- show between the first; a large one gets a line down each petal and
-- stamens round its heart.
function Blooms.blossom(c, cx, cy, R, fill, back, rot)
    local sw = math.max(.9, math.min(1.7, R * .07))
    local body = (back and around(0, 0, 0, 5, notched(c, R, R * .46, back, sw), 36) or "")
        .. around(0, 0, 0, 5, notched(c, back and R * .85 or R, R * .5, fill or c.cream, sw), 0)
    if R >= 18 then
        body = body .. around(0, 0, R * .34, 5, Svg.line(string.format("M0 0 L0 %s", n(-R * .34)), c.ink, sw * .6), 0)
            .. Svg.dots(0, 0, R * .38, 10, R * .09, c.ink)
    end
    body = body .. Svg.circle(0, 0, R * .26, c.gold, c.ink, sw)
    if R >= 18 then body = body .. Svg.dots(0, 0, R * .12, 5, R * .07, c.ink) end
    return group(cx, cy, rot or 0, body)
end

-- A seedling standing on (x, y), `s` tall: two leaves on a bent stalk, the
-- husk of the seed (golden, or in `husk`) still on the taller leaf.
function Blooms.seedling(c, x, y, s, husk)
    local pts = Svg.spline({ { x, y }, { x + s * .15, y - s * .45 }, { x - s * .05, y - s } }, 8)
    local tx, ty = pts[#pts][1], pts[#pts][2]
    return Svg.line(Svg.poly(pts), c.stem, math.max(1.6, s * .13))
        .. Flora.leaf(c, tx, ty, -152, s * .76, s * .29, c.sage, true)
        .. Flora.leaf(c, tx, ty, -44, s * .9, s * .32, c.leaf, true)
        .. Svg.ellipse(tx + s * .67, ty - s * .66, s * .19, s * .12, -44, husk or c.gold, c.ink, math.max(.9, s * .06))
end

return Blooms
