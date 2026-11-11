-- The garden's bulbs and their kin through the stages of their life: tulip,
-- poet's narcissus, spring crocus, Madonna lily and bearded iris, and how
-- each rests through the winter. Each is drawn in its own bed with plantkit
-- and returned by name for gardenplants.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Rest = require("solarui/art/plantrest")
local Svg = require("solarui/art/svg")

local n, group, path, line, petal = Svg.n, Svg.group, Svg.path, Svg.line, Flora.petal

local Bulbs = {}

-- `body` and its mirror image, side by side about the upright.
local function both(body)
    return body .. group(0, 0, 0, body, -1, 1)
end

-- A seed capsule standing on the origin, `s` tall, ribbed, with a small crown.
local function capsule(p, s, fill)
    return Svg.ellipse(0, -s * .5, s * .26, s * .5, 0, fill or p.c.pale, p.c.ink, 1.5)
        .. line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(-s * .08), n(-s * .06), n(-s * .16), n(-s * .5), n(-s * .08), n(-s * .94), n(s * .08), n(-s * .06), n(s * .16), n(-s * .5), n(s * .08), n(-s * .94)), p.c.ink, .9)
        .. path(string.format("M%s %s L0 %s L%s %sZ", n(-s * .1), n(-s * .96), n(-s * 1.1), n(s * .1), n(-s * .96)), p.c.ink)
end

-- A tulip cup on the origin, `s` tall: three outer tepals in front, the tips
-- of the three inner ones behind. `shut` (0 to 1) closes it into a bud.
local function tulipCup(p, s, fill, shut)
    local k = (p.wilt and 2.3 or 1) * (1 - (shut or 0) * .7)
    local function tep(lean, L, W, f) return group(0, 0, lean * k, petal(p.c, L, W, f, 1.6)) end
    return tep(-25, s * .98, s * .34, p.c.bloom2) .. tep(25, s * .98, s * .34, p.c.bloom2) .. tep(0, s * 1.05, s * .36, p.c.bloom2)
        .. tep(-13, s * .98, s * .46, fill) .. tep(13, s * .98, s * .46, fill) .. tep(0, s * .9, s * .43, fill)
        .. line(string.format("M0 %s Q%s %s 0 %s", n(-s * .1), n(s * .03), n(-s * .4), n(-s * .72)), p.c.ink, .9)
end

-- Tulip: broad clasping leaves and one cup of six tepals.
local function tulip(p)
    local c, st = p.c, p.st
    local tall = ({ 0, 0, 104, 142, 136 })[st]
    local leafc = st == 5 and c.pale or c.sage
    if st == 2 then
        return Kit.soil(p, 78) .. Kit.blade(p, -3, -3, -16, 56, 17, -22, c.sage) .. Kit.blade(p, 3, -3, 12, 44, 15, 26, c.sage) .. Kit.blade(p, 0, -3, -2, 30, 11, 6, c.leaf)
    end
    local stem = Kit.rise(p, { { 0, -3 }, { -5, -tall * .45 }, { 4, -tall * .8 }, { 1, -tall } })
    local x, y, ang = Kit.on(stem, 1)
    local head
    if st == 3 then
        head = tulipCup(p, 34, c.leaf, 1)
    elseif st == 4 then
        head = tulipCup(p, 46, c.bloom)
    else
        head = capsule(p, 30, c.sage)
    end
    return Kit.soil(p, 84) .. Kit.blade(p, -4, -3, -30, tall * .68, 22, -34, leafc) .. Kit.blade(p, 4, -3, 24, tall * .6, 20, 40, leafc)
        .. Svg.stem(stem, Svg.taper(5, 3.6), c.stem, c.ink, 1.5) .. Kit.blade(p, 1, -4, 6, tall * .46, 15, 20, st == 5 and c.gold or c.leaf)
        .. group(x, y, ang + 90, head)
end

-- A poet's narcissus seen from the front, `r` to the tips: six white tepals
-- round a small golden cup with a red rim.
local function poetFlower(p, r)
    local c = p.c
    local back = Flora.around(0, 0, r * .1, 3, petal(c, r * .92, r * .44, c.cream, 1.6), 60)
    local front = Flora.around(0, 0, r * .1, 3, petal(c, r * .92, r * .44, c.cream, 1.6) .. line(string.format("M0 %s L0 %s", n(-r * .3), n(-r * .66)), c.line, 1), 0)
    return back .. front .. Svg.circle(0, 0, r * .27, c.bloom, c.ink, 1.4) .. Svg.circle(0, 0, r * .17, c.gold, c.ink, .9)
        .. Svg.dots(0, 0, r * .07, 3, r * .07, c.ink)
end

-- Narcissus: narrow strap leaves and a flower that looks sideways from a bent neck.
local function narcissus(p)
    local c, st = p.c, p.st
    local tall = ({ 0, 0, 100, 140, 134 })[st]
    local leaves = Kit.blade(p, -5, -3, -15, tall * .8 + 30, 9, -14, c.sage) .. Kit.blade(p, 5, -3, 13, tall * .74 + 30, 9, 20, c.sage)
    if st == 2 then return Kit.soil(p, 72) .. Kit.blade(p, -3, -3, -10, 48, 8, -8, c.sage) .. Kit.blade(p, 3, -3, 9, 40, 8, 12, c.sage) .. Kit.blade(p, 0, -3, 1, 30, 7, 4, c.leaf) end
    local stem = Kit.rise(p, { { 0, -3 }, { -4, -tall * .5 }, { 3, -tall * .86 }, { 9, -tall } }, 64, .55)
    local x, y, ang = Kit.on(stem, 1)
    local spathe = group(x, y, ang + 60, petal(c, 20, 7, c.pale, 1.2))
    local head
    if st == 3 then
        head = group(x, y, ang + 105, petal(c, 30, 9, c.cream, 1.5) .. petal(c, 17, 9, c.pale, 1.2))
        spathe = ""
    elseif st == 4 then
        head = group(x + 6, y - 2, p.wilt and 40 or -8, poetFlower(p, 30), p.wilt and .7 or .9, p.wilt and .85 or 1)
    else
        head = group(x, y, ang + 100, Svg.ellipse(0, -8, 5.5, 9, 0, c.leaf, c.ink, 1.4) .. group(0, -16, -24, petal(c, 15, 4, c.pale, 1.1)) .. group(0, -16, 22, petal(c, 16, 4, c.pale, 1.1))
            .. group(0, -16, 0, petal(c, 13, 3.5, c.pale, 1.1)))
    end
    return Kit.soil(p, 78) .. leaves .. spathe .. Svg.stem(stem, Svg.taper(4.4, 3.2), c.stem, c.ink, 1.4)
        .. Kit.blade(p, 1, -3, 4, tall * .62 + 20, 8, -10, c.leaf) .. head
end

-- A crocus goblet on the origin, `s` tall, with its orange stigma.
local function goblet(p, s, shut)
    local c = p.c
    local k = (p.wilt and 2 or 1) * (shut and .2 or 1)
    local function tep(lean, L, W) return group(0, 0, lean * k, petal(c, L, W, c.sky, 1.5) .. line(string.format("M0 %s L0 %s M%s %s L%s %s M%s %s L%s %s", n(-L * .2), n(-L * .8), n(-W * .3), n(-L * .3), n(-W * .34), n(-L * .68), n(W * .3), n(-L * .3), n(W * .34), n(-L * .68)), c.glass, .9)) end
    return tep(-24, s * .9, s * .3) .. tep(24, s * .9, s * .3)
        .. (shut and "" or line(string.format("M0 %s L0 %s M0 %s L%s %s M0 %s L%s %s", n(-s * .4), n(-s * .98), n(-s * .5), n(-s * .1), n(-s * .93), n(-s * .5), n(s * .1), n(-s * .93)), c.bloom, 2.2))
        .. tep(-15, s * .9, s * .36) .. tep(15, s * .9, s * .36) .. tep(0, shut and s or s * .8, s * .36)
end

-- Crocus: goblets straight from the earth among thin leaves with a pale stripe.
local function crocus(p)
    local c, st = p.c, p.st
    local long = st == 5 and 1.35 or 1
    local function leaf(x, heading, L, curl) return Kit.blade(p, x, -3, heading, L * long, 4.6, curl, c.leaf, c.cream) end
    local leaves = leaf(-6, -38, 44, -30) .. leaf(6, 36, 42, 34) .. leaf(-2, -16, 50, -12) .. leaf(3, 15, 46, 16)
    if st == 2 then return Kit.soil(p, 56) .. leaf(-3, -18, 26, -10) .. leaf(3, 16, 24, 12) .. leaf(0, 0, 30, 2) end
    -- one flower on its pale tube
    local function flower(x, lean, h, s, shut)
        local tube = Kit.rise(p, { { x, -3 }, { x + lean * .4, -h * .5 }, { x + lean, -h } }, 62, .2)
        local tx, ty, ang = Kit.on(tube, 1)
        return Svg.stem(tube, Svg.taper(4.4, 3.6), c.cream, c.ink, 1.2) .. group(tx, ty, ang + 90, goblet(p, s, shut))
    end
    if st == 3 then return Kit.soil(p, 62) .. leaves .. flower(-8, -3, 22, 26, true) .. flower(11, 4, 14, 20, true) end
    if st == 4 then return Kit.soil(p, 62) .. leaves .. flower(13, 7, 20, 27, false) .. flower(-9, -5, 30, 36, false) end
    return Kit.soil(p, 62) .. leaves .. group(-6, -4, -12, capsule(p, 20, c.pale)) .. group(8, -4, 16, capsule(p, 16, c.pale))
end

-- A Madonna lily trumpet on the origin, `s` long: flaring tepals with
-- recurved tips and golden anthers.
local function trumpet(p, s)
    local c = p.c
    local side = path(string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s 0 %sZ", n(-s * .1), n(-s * .45), n(-s * .2), n(-s * .74), n(-s * .52), n(-s * .9), n(-s * .32), n(-s * .98), n(-s * .12), n(-s * .9), n(-s * .5)), c.cream, c.ink, 1.5)
    local anthers = ""
    for _i, a in ipairs({ { -.15, 1.0 }, { 0, 1.07 }, { .15, 1.0 } }) do
        anthers = anthers .. line(string.format("M0 %s L%s %s", n(-s * .5), n(s * a[1]), n(-s * a[2])), c.stem, 1)
            .. Svg.ellipse(s * a[1], -s * a[2], s * .035, s * .075, a[1] * 160, c.gold, c.ink, .9)
    end
    return group(0, 0, -11, petal(c, s * .98, s * .2, c.cream, 1.4)) .. group(0, 0, 11, petal(c, s * .98, s * .2, c.cream, 1.4)) .. anthers .. both(side)
        .. petal(c, s * .9, s * .25, c.cream, 1.5) .. line(string.format("M0 %s L0 %s", n(-s * .2), n(-s * .7)), c.line, 1.1)
        .. Svg.ellipse(0, -1, s * .07, s * .09, 0, c.leaf, c.ink, 1.1)
end

-- Lily: a leafy stem with white trumpets and buds at its top.
local function lily(p)
    local c, st = p.c, p.st
    local tall = ({ 0, 46, 150, 168, 166 })[st]
    local stem = Kit.rise(p, { { 0, -3 }, { -5, -tall * .45 }, { 4, -tall * .8 }, { 0, -tall } }, 58, .5)
    local leaves, count = "", st == 2 and 6 or 15
    for i = 1, count do
        local f = (st == 2 and .2 or .07) + (st == 2 and .8 or .7) * (i - 1) / (count - 1)
        local x, y, ang = Kit.on(stem, f)
        local L = st == 2 and 30 or (34 - 16 * f)
        leaves = leaves .. Flora.leaf(c, x, y, Kit.turn(p, ang, i % 2 == 0 and 1 or -1, 52 - 14 * f, f < .3 and .15 or .5), L, L * .17, (st == 5 and f < .35) and c.pale or c.leaf, true)
    end
    local top = ""
    -- something on a short stalk leaving the stem `f` along, leaning `lean` degrees
    local function bear(f, lean, len, thing)
        local x, y, ang = Kit.on(stem, f)
        local a = ang + 90 + lean
        local ex, ey = Svg.pol(len, a, x, y)
        top = top .. line(string.format("M%s %s L%s %s", n(x), n(y), n(ex), n(ey)), c.ink, 3.6) .. line(string.format("M%s %s L%s %s", n(x), n(y), n(ex), n(ey)), c.stem, 2) .. group(ex, ey, a, thing)
    end
    local bud = Svg.ellipse(0, -13, 5, 14, 0, c.sage, c.ink, 1.4) .. line("M0 -3 L0 -24", c.ink, .8)
    if st == 3 then
        bear(.9, -32, 12, bud); bear(.94, 30, 12, bud); bear(1, 0, 4, bud)
    elseif st == 4 then
        bear(.82, -64, 14, trumpet(p, 40)); bear(.86, 62, 14, trumpet(p, 40)); bear(.95, -20, 10, bud); bear(.97, 24, 12, trumpet(p, 36)); bear(1, 0, 6, bud)
    elseif st == 5 then
        bear(.84, -40, 14, capsule(p, 26)); bear(.9, 38, 14, capsule(p, 26)); bear(1, 0, 6, capsule(p, 28))
    end
    return Kit.soil(p, 80) .. leaves .. Svg.stem(stem, Svg.taper(5.4, 3.2), c.stem, c.ink, 1.5) .. top
end

-- A bearded iris flower on the origin, `s` tall: three standards arching
-- into a dome over three hanging falls, each with its golden beard.
local function irisFlower(p, s)
    local c = p.c
    local standard = path(string.format("M0 %s C%s %s %s %s %s %s C%s %s %s %s 0 %sZ", n(-s * .1), n(-s * .62), n(-s * .3), n(-s * .62), n(-s * .92), n(-s * .05), n(-s * 1.06), n(-s * .22), n(-s * .72), n(-s * .12), n(-s * .4), n(-s * .1)), c.sky, c.ink, 1.6)
        .. line(string.format("M%s %s Q%s %s %s %s", n(-s * .1), n(-s * .24), n(-s * .4), n(-s * .6), n(-s * .14), n(-s * .94)), c.ink, .8)
    local fall = path(string.format("M0 %s C%s %s %s %s %s %s C%s %s %s %s %s %s C%s %s %s %s 0 %sZ", n(-s * .14), n(-s * .5), n(-s * .5), n(-s * .98), n(-s * .32), n(-s * .92), n(s * .24), n(-s * .88), n(s * .52), n(-s * .56), n(s * .46), n(-s * .5), n(s * .14),
        n(-s * .46), n(-s * .08), n(-s * .2), n(-s * .1), n(-s * .14)), c.glass, c.ink, 1.6)
        .. line(string.format("M%s %s Q%s %s %s %s", n(-s * .16), n(-s * .24), n(-s * .42), n(-s * .42), n(-s * .66), n(-s * .3)), c.gold, 3)
    local front = path(string.format("M%s %s C%s %s %s %s 0 %s C%s %s %s %s %s %sZ", n(-s * .14), n(-s * .1), n(-s * .42), n(s * .1), n(-s * .36), n(s * .62), n(s * .7), n(s * .36), n(s * .62), n(s * .42), n(s * .1), n(s * .14), n(-s * .1)), c.glass, c.ink, 1.6)
        .. line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(-s * .08), n(s * .26), n(-s * .2), n(s * .42), n(-s * .16), n(s * .56), n(s * .08), n(s * .26), n(s * .2), n(s * .42), n(s * .16), n(s * .56)), c.sky, 1)
        .. Svg.ellipse(0, s * .08, s * .06, s * .17, 0, c.gold, c.ink, 1.1)
    return petal(c, s * 1.04, s * .4, c.sky, 1.6) .. both(fall) .. both(standard) .. front
end

-- An iris bud on the origin, `s` tall, in its papery sheath.
local function irisBud(p, s)
    return petal(p.c, s, s * .22, p.c.glass, 1.4) .. group(0, 0, -7, petal(p.c, s * .62, s * .24, p.c.pale, 1.2)) .. group(0, 0, 9, petal(p.c, s * .5, s * .22, p.c.sage, 1.2))
end

-- Iris: a fan of sword leaves and a stout stem with the flower at its top.
local function iris(p)
    local c, st = p.c, p.st
    local tall = ({ 0, 0, 126, 152, 148 })[st]
    local k = st == 2 and .42 or 1
    local fan = Kit.blade(p, -9, -3, -24, 128 * k, 15, -8, c.sage) .. Kit.blade(p, 10, -3, 25, 118 * k, 15, 10, c.sage) .. Kit.blade(p, -4, -3, -11, 146 * k, 15, -5, c.leaf)
    if st == 2 then return Kit.soil(p, 76) .. fan .. Kit.blade(p, 3, -3, 8, 50, 13, 4, c.leaf) end
    local stem = Kit.rise(p, { { 2, -3 }, { 6, -tall * .45 }, { 0, -tall * .8 }, { 3, -tall } }, 62, .55)
    local x, y, ang = Kit.on(stem, 1)
    local bx, by, bang = Kit.on(stem, .66)
    local head, side
    if st == 3 then
        head, side = irisBud(p, 40), irisBud(p, 26)
    elseif st == 4 then
        head, side = irisFlower(p, 44), irisBud(p, 34)
    else
        head, side = capsule(p, 34, c.sage), capsule(p, 26, c.sage)
    end
    return Kit.soil(p, 84) .. fan .. Svg.stem(stem, Svg.taper(6, 4.4), c.stem, c.ink, 1.5) .. group(bx, by, bang + 122, side)
        .. Kit.blade(p, 5, -3, 12, 96, 14, 6, c.leaf) .. group(x, y, ang + 90, head)
end

-- The iris in winter: the fans cut back to short squared stubs over the rhizome.
local function irisRest(p, dry)
    local out = ""
    for i, f in ipairs({ { -16, 30, -9 }, { -8, 40, -3 }, { 0, 36, 4 }, { 8, 26, 10 } }) do
        local x, h, lean = f[1], f[2] * (p.st == 2 and .6 or 1), f[3]
        out = out .. path(string.format("M%s -4 L%s %s L%s %s L%s -4Z", n(x - 4), n(x - 3.4 + lean), n(-h), n(x + 3.4 + lean), n(-h - 4), n(x + 4)), i % 2 == 0 and dry.c.dead or dry.c.straw, p.c.ink, 1.4)
            .. line(string.format("M%s -6 L%s %s", n(x + 1), n(x + 1 + lean * .9), n(-h + 4)), p.c.ink, .8)
    end
    return out .. group(18, -1, 0, Kit.seed(p, "rhizome", 20))
end

Bulbs.tulip = Kit.sprite("tulip", "bulb", tulip, false, Rest.form({ w = 84, straps = { { -70, 50, 14 }, { 64, 44, 13 }, { -40, 30, 11 } }, stubs = { { 2, 34, 3, 4 } }, heads = { 1 },
    head = function(dry) return capsule(dry, 26) end }))
Bulbs.narcissus = Kit.sprite("narcissus", "bulb", narcissus, false, Rest.form({ w = 78, straps = { { -74, 56, 8 }, { 70, 50, 8 }, { -50, 40, 7 }, { 46, 34, 7 } } }))
Bulbs.crocus = Kit.sprite("crocus", "bulb", crocus, false, Rest.form({ w = 62, straps = { { -66, 34, 4.6 }, { 62, 30, 4.6 }, { 0, 10, 4 } }, litter = 2 }))
Bulbs.lily = Kit.sprite("lily", "bulb", lily, false, Rest.form({ w = 80, stubs = { { 0, 62, -4, 5 } }, heads = { 1 }, litter = 4,
    head = function(dry) return capsule(dry, 26) end, heap = { 52, 5 } }))
Bulbs.iris = Kit.sprite("iris", "rhizome", iris, false, Rest.form({ w = 84, litter = 2, extra = irisRest }))

return Bulbs
