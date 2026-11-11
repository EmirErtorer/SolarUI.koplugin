-- The garden's meadow flowers through the stages of their life: sunflower,
-- corn poppy, chamomile, dandelion, pansy and harebell, and how each rests
-- through the winter. All are drawn with plantkit, each in a bed of the
-- plant's own size, and returned by name for gardenplants.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Rest = require("solarui/art/plantrest")
local Svg = require("solarui/art/svg")

local n, group, path, line, petal, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Flora.petal, Svg.circle, Svg.ellipse

local Meadow = {}

-- A thin stem drawn with its outline.
local function wire(p, pts, w)
    return Svg.stem(pts, Svg.taper(w, w * .7), p.c.stem, p.c.ink, 1.2)
end

-- Sunflower: a stout stem with heart-shaped leaves and one great head.
local function sunflower(p)
    local c, st = p.c, p.st
    local tall = ({ 0, 46, 136, 180, 172 })[st]
    local stem = Kit.rise(p, { { 0, -3 }, { tall * .035, -tall * .45 }, { -tall * .025, -tall * .82 }, { 0, -tall } }, st == 5 and 60 or 78, st == 5 and .7 or .5)
    if st == 5 and not p.wilt then stem = Kit.droop(stem, 72, .74) end
    local leaves = ""
    for i, f in ipairs(st == 2 and { .55, .6, .95, 1 } or { .2, .34, .48, .6, .72 }) do
        local x, y, ang = Kit.on(stem, f)
        local L = st == 2 and (i < 3 and 20 or 30) or (58 - 28 * f) * (st == 3 and .8 or 1)
        leaves = leaves .. Kit.heart(c, x, y, Kit.turn(p, ang, i % 2 == 0 and 1 or -1, 66 - 20 * f), L, (st == 5 and f < .4) and c.pale or c.leaf)
    end
    local x, y, ang = Kit.on(stem, 1)
    local head = ""
    if st == 3 then
        head = group(x, y, ang + 90, Flora.around(0, -12, 3, 9, petal(c, 16, 6, c.leaf, 1.3)) .. circle(0, -12, 9, c.sage, c.ink, 1.4) .. Flora.around(0, -12, 0, 5, petal(c, 8, 3, c.gold, 1), 20))
    elseif st == 4 then
        head = group(x, y, ang + 90, group(0, -8, 0, Kit.sunflower(c, 20, true), 1, p.wilt and .7 or 1))
    elseif st == 5 then
        head = group(x, y, ang + 90, group(0, -6, 0, Kit.sunflower(c, 25, false), 1, .8))
    end
    return Kit.soil(p, 92) .. leaves .. Svg.stem(stem, Svg.taper(st == 2 and 4 or 8, st == 2 and 3 or 5.4), c.stem, c.ink, 1.6) .. head
end

-- A poppy's seed capsule standing on the origin, `s` tall: an urn under a ribbed lid.
local function pepperpot(p, s)
    local c = p.c
    return path(string.format("M%s 0 C%s %s %s %s %s %s L%s %s C%s %s %s %s %s 0Z", n(-s * .14), n(-s * .5), n(-s * .25), n(-s * .46), n(-s * .78), n(-s * .3), n(-s * .9), n(s * .3), n(-s * .9), n(s * .46), n(-s * .78), n(s * .5), n(-s * .25), n(s * .14)), c.sage, c.ink, 1.4)
        .. line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(-s * .1), n(-s * .86), n(-s * .2), n(-s * .45), n(-s * .06), n(-s * .04), n(s * .1), n(-s * .86), n(s * .2), n(-s * .45), n(s * .06), n(-s * .04)), c.ink, .8)
        .. ellipse(0, -s * .92, s * .42, s * .11, 0, c.pale, c.ink, 1.3) .. line(string.format("M%s %s L%s %s M0 %s L0 %s M%s %s L%s %s", n(-s * .3), n(-s * .92), n(-s * .1), n(-s * .94), n(-s * 1.0), n(-s * .9), n(s * .3), n(-s * .92), n(s * .1), n(-s * .94)), c.ink, .9)
end

-- A corn poppy seen from a little above, `s` to the edge: four crinkled
-- petals, each with a dark blotch, round a ring of stamens and the capsule.
local function poppyFlower(p, s)
    local c = p.c
    -- one petal `L` long and `W` half across, with a waved outer edge
    local function crinkled(rot, L, W)
        return group(0, 0, rot, path(string.format("M0 0 C%s %s %s %s %s %s Q%s %s %s %s Q%s %s %s %s C%s %s %s %s 0 0Z", n(-W * 1.2), n(-L * .2), n(-W * 1.4), n(-L * .9), n(-W * .56), n(-L), n(-W * .3), n(-L * .9), n(-W * .08), n(-L * 1.04),
            n(W * .2), n(-L * .92), n(W * .52), n(-L * 1.02), n(W * 1.4), n(-L * .9), n(W * 1.2), n(-L * .2)), c.bloom, c.ink, 1.6)
            .. line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(-W * .3), n(-L * .5), n(-W * .44), n(-L * .7), n(-W * .4), n(-L * .86), n(W * .34), n(-L * .5), n(W * .5), n(-L * .7), n(W * .42), n(-L * .84)), c.ink, .8)
            .. petal(c, L * .4, W * .4, c.ink))
    end
    return crinkled(0, s, s * .62) .. crinkled(82, s * .96, s * .56) .. crinkled(-82, s * .96, s * .56) .. crinkled(180, s * .62, s * .68)
        .. Svg.dots(0, 0, s * .27, 14, s * .09, c.ink) .. circle(0, 0, s * .17, c.sage, c.ink, 1.2)
        .. line(string.format("M%s 0 L%s 0 M0 %s L0 %s M%s %s L%s %s M%s %s L%s %s", n(-s * .12), n(s * .12), n(-s * .12), n(s * .12), n(-s * .09), n(-s * .09), n(s * .09), n(s * .09), n(-s * .09), n(s * .09), n(s * .09), n(-s * .09)), c.ink, .9)
end

-- A poppy bud hanging from the origin, `s` long, bristly and split along its side.
local function poppyBud(p, s)
    return ellipse(0, s * .5, s * .3, s * .52, 0, p.c.sage, p.c.ink, 1.4) .. line(string.format("M%s %s Q%s %s %s %s", n(-s * .04), n(s * .06), n(s * .12), n(s * .5), n(-s * .02), n(s * .98)), p.c.ink, .9)
        .. path(string.format("M%s %s L0 %s L%s %sZ", n(-s * .08), n(s * .98), n(s * 1.16), n(s * .1), n(s * .96)), p.c.bloom, p.c.ink, 1)
end

-- Corn poppy: wiry stems over cut leaves, a flower, a nodding bud and a capsule.
local function poppy(p)
    local c, st = p.c, p.st
    local leafc = st == 5 and c.pale or c.leaf
    local leaves = Kit.lobed(c, -3, -4, Kit.turn(p, -90, -1, 58, .1), 52, 11, 5, leafc) .. Kit.lobed(c, 3, -4, Kit.turn(p, -90, 1, 62, .1), 46, 10, 5, leafc)
        .. Kit.lobed(c, -2, -4, Kit.turn(p, -90, -1, 28, .2), 40, 9, 4, c.sage) .. Kit.lobed(c, 2, -4, Kit.turn(p, -90, 1, 30, .2), 36, 9, 4, c.sage)
    if st == 2 then return Kit.soil(p, 70) .. group(0, 0, 0, leaves, .62) end
    local k = st == 3 and .74 or 1
    local main = Kit.rise(p, { { 0, -3 }, { -8, -70 * k }, { -1, -134 * k }, { -8, -168 * k } }, 52)
    local nod = Svg.spline({ { 2, -3 }, { 18, -56 * k }, { 28, -104 * k }, { 36, -124 * k }, { 46, -130 * k }, { 51, -121 * k } }, 8)
    local low = Kit.rise(p, { { -2, -3 }, { -20, -46 * k }, { -34, -86 * k }, { -38, -112 * k } }, 30)
    local out = Kit.soil(p, 78) .. leaves
    local x, y, ang = Kit.on(main, 1)
    local bx, by = Kit.on(nod, 1)
    local lx, ly, lang = Kit.on(low, 1)
    if st == 3 then
        local hook = Svg.spline({ { 0, -3 }, { -8, -50 }, { -2, -100 }, { -7, -126 }, { -16, -132 }, { -22, -122 } }, 8)
        local hx, hy = Kit.on(hook, 1)
        return out .. wire(p, hook, 2.8) .. wire(p, nod, 2.6) .. group(hx, hy, 8, poppyBud(p, 24)) .. group(bx, by, -6, poppyBud(p, 20))
    elseif st == 4 then
        return out .. wire(p, low, 2.6) .. wire(p, nod, 2.6) .. wire(p, main, 3) .. group(lx, ly, lang + 90, pepperpot(p, 22))
            .. group(bx, by, -6, poppyBud(p, 22)) .. group(x, y, ang + 90, group(0, -10, 0, poppyFlower(p, 34), 1, p.wilt and .7 or 1))
    end
    local up = Kit.rise(p, { { 2, -3 }, { 18, -56 }, { 28, -104 }, { 30, -142 } }, 40)
    local ux, uy, uang = Kit.on(up, 1)
    return out .. wire(p, low, 2.6) .. wire(p, up, 2.6) .. wire(p, main, 3) .. group(lx, ly, lang + 90, pepperpot(p, 22))
        .. group(ux, uy, uang + 90, pepperpot(p, 24)) .. group(x, y, ang + 90, pepperpot(p, 28))
end

-- A feathery leaf of thread-thin segments pointing right from (x, y).
local function feather(c, x, y, rot, L)
    local d = { string.format("M-2 0 L%s 0", n(L)) }
    for i = 1, 4 do
        local t, s = L * (.16 + i * .17), L * (.34 - i * .04)
        d[#d + 1] = string.format("M%s 0 l%s %s M%s 0 l%s %s", n(t), n(s * .8), n(-s * .7), n(t), n(s * .8), n(s * .7))
    end
    return group(x, y, rot, line(table.concat(d, " "), c.ink, 2.6) .. line(table.concat(d, " "), c.leaf, 1.3))
end

-- A chamomile head on the origin, `r` to the ray tips: white rays bent back
-- under a raised golden cone. `rays` false leaves the bare cone.
local function camHead(p, r, rays)
    local c = p.c
    local ring = rays and Flora.around(0, 0, r * .2, 15, path(string.format("M%s 0 L%s %s Q0 %s %s %s L%s 0Z", n(-r * .07), n(-r * .12), n(-r * .68), n(-r * .9), n(r * .12), n(-r * .68), n(r * .07)), c.cream, c.ink, 1.2)) or ""
    return group(0, 0, 0, ring, 1, .62) .. ellipse(0, -r * .16, r * .32, r * .36, 0, rays and c.gold or c.pale, c.ink, 1.4)
        .. Svg.dots(0, -r * .2, r * .16, 6, r * .06, c.ink) .. circle(0, -r * .22, r * .03, c.ink)
end

-- Chamomile: a branching bush of thread leaves, each branch ending in a daisy.
local function chamomile(p)
    local c, st = p.c, p.st
    local k = ({ 0, .3, .8, 1, 1 })[st]
    local main = Kit.rise(p, { { 0, -3 }, { -4, -60 * k }, { 3, -120 * k }, { -3, -166 * k } })
    local out, heads = Kit.soil(p, 76), ""
    -- a head (or bud) at the end of a stem
    local function head(pts, r)
        local x, y, ang = Kit.on(pts, 1)
        if st == 3 then
            heads = heads .. group(x, y, ang + 90, circle(0, -4, 5, c.sage, c.ink, 1.3) .. circle(0, -6, 2.4, c.gold, c.ink, .9))
        elseif st > 3 then
            heads = heads .. group(x, y, ang + 90, group(0, -3, 0, camHead(p, r, st == 4)))
        end
    end
    for i, b in ipairs(st == 2 and {} or { { .3, 40, -128, 15 }, { .42, -40, -138, 15 }, { .6, 30, -172, 13 }, { .72, -32, -180, 12 } }) do
        local x, y = Kit.on(main, b[1])
        local side = Kit.rise(p, { { x, y }, { x + (b[2] - x) * .6, y + (b[3] * k - y) * .4 }, { b[2], b[3] * k } })
        local fx, fy, fang = Kit.on(side, .5)
        out = out .. feather(c, fx, fy, Kit.turn(p, fang, i % 2 == 0 and -1 or 1, 50), 20) .. wire(p, side, 2.2)
        head(side, b[4])
    end
    for i, f in ipairs({ .16, .3, .46, .62, .8 }) do
        local x, y, ang = Kit.on(main, f)
        out = out .. feather(c, x, y, Kit.turn(p, ang, i % 2 == 0 and 1 or -1, 54), st == 2 and 24 or 26 - 8 * f)
    end
    head(main, 17)
    return out .. wire(p, main, st == 2 and 2.2 or 3) .. heads
end

-- Dandelion: a rosette of raked leaves and hollow stalks with a golden head.
local function dandelion(p)
    local c, st = p.c, p.st
    local k = st == 2 and .6 or 1
    local rosette = ""
    for _i, l in ipairs({ { -70, 46 }, { 68, 44 }, { -48, 44 }, { 46, 42 }, { -22, 36 }, { 20, 34 } }) do
        rosette = rosette .. Kit.lobed(c, 0, -5, p.wilt and (l[1] * 1.1 - 90) or (l[1] - 90), l[2] * k, 8.5 * k, 5, math.abs(l[1]) > 60 and c.sage or c.leaf, true)
    end
    if st == 2 then return Kit.soil(p, 60) .. rosette end
    local tall = st == 3 and 34 or 62
    local scape = Kit.rise(p, { { -1, -4 }, { -4, -tall * .6 }, { 1, -tall } }, 90, .3)
    local side = Kit.rise(p, { { 2, -4 }, { 12, -24 }, { 22, -40 } }, 90, .3)
    local x, y, ang = Kit.on(scape, 1)
    local sx, sy, sang = Kit.on(side, 1)
    local bud = ellipse(0, -7, 5, 8, 0, c.leaf, c.ink, 1.3) .. path("M-3 -13 L0 -19 L3 -13Z", c.gold, c.ink, 1)
    local head = st == 3 and bud or group(0, -10, 0, st == 4 and Blooms.karahindiba(c, 0, 0, 18) or Flora.dandelion(c, 0, 0, 18), 1, p.wilt and .7 or 1)
    return Kit.soil(p, 64) .. rosette .. Svg.stem(side, Svg.taper(3, 2.4), c.sage, c.ink, 1.2) .. Svg.stem(scape, Svg.taper(3.6, 2.8), c.sage, c.ink, 1.2)
        .. group(sx, sy, sang + 90, bud) .. group(x, y, ang + 90, head)
end

-- A pansy's open seed pod on the origin: three boats of seeds.
local function pansyPod(p, s)
    return Flora.around(0, 0, 0, 3, petal(p.c, s, s * .3, p.c.pale, 1.2) .. Svg.dots(0, -s * .5, s * .12, 2, s * .14, p.c.ink), 60)
end

-- Pansy: a low clump of leaves under flat five-petalled faces.
local function pansy(p)
    local c, st = p.c, p.st
    local out = Kit.soil(p, 62)
    for _i, l in ipairs({ { -72, 30 }, { 70, 28 }, { -40, 28 }, { 44, 26 }, { -10, 22 }, { 14, 20 } }) do
        out = out .. Flora.leaf(c, 0, -4, Kit.turn(p, -90, l[1] < 0 and -1 or 1, math.abs(l[1]), .06), l[2] * (st == 2 and .7 or 1), 8 * (st == 2 and .7 or 1), math.abs(l[1]) > 50 and c.sage or c.leaf)
    end
    if st == 2 then return out end
    local heads = ""
    for _i, f in ipairs({ { -24, -44, 15 }, { 20, -56, 16 }, { 1, -28, 13 } }) do
        local stem = Kit.rise(p, { { 0, -4 }, { f[1] * .3, f[2] * .6 }, { f[1], f[2] } }, 80, .3)
        local x, y, ang = Kit.on(stem, 1)
        out = out .. wire(p, stem, 2.2)
        if st == 3 then
            heads = heads .. Flora.rosebud(c, x, y, ang + 90 + f[1], f[3] * .5, c.glass)
        elseif st == 4 then
            heads = heads .. group(x, y - 2, p.wilt and (ang + 90) or f[1] * .4, Blooms.pansy(c, 0, 0, f[3]), 1, p.wilt and .7 or 1)
        else
            heads = heads .. group(x, y, ang + 90, pansyPod(p, f[3] * .8))
        end
    end
    return out .. heads
end

-- A harebell hanging from the origin, `s` long: a bell of five pointed lobes.
local function bell(p, s, kind)
    local c = p.c
    if kind == 3 then return ellipse(0, s * .34, s * .14, s * .36, 0, c.sky, c.ink, 1.2) .. circle(0, s * .04, s * .1, c.leaf, c.ink, 1) end
    if kind == 5 then return ellipse(0, s * .3, s * .22, s * .3, 0, c.pale, c.ink, 1.2) .. line(string.format("M%s %s l%s %s M0 %s l0 %s M%s %s l%s %s", n(-s * .1), n(s * .56), n(-s * .08), n(s * .2), n(s * .6), n(s * .2), n(s * .1), n(s * .56), n(s * .08), n(s * .2)), c.ink, 1) end
    return path(string.format("M%s 0 C%s %s %s %s %s %s L%s %s L0 %s L%s %s L%s %s C%s %s %s %s %s 0Z", n(-s * .12), n(-s * .44), n(s * .12), n(-s * .32), n(s * .6), n(-s * .56), n(s * .9), n(-s * .26), n(s * .76), n(s * 1.04), n(s * .26), n(s * .76),
        n(s * .56), n(s * .9), n(s * .32), n(s * .6), n(s * .44), n(s * .12), n(s * .12)), c.sky, c.ink, 1.4)
        .. line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(-s * .26), n(s * .76), n(-s * .2), n(s * .5), n(-s * .1), n(s * .3), n(s * .26), n(s * .76), n(s * .2), n(s * .5), n(s * .1), n(s * .3)), c.ink, .8)
        .. path(string.format("M%s %s L0 %s L%s %sZ", n(-s * .16), n(s * .06), n(-s * .08), n(s * .16), n(s * .06)), c.leaf, c.ink, 1)
end

-- Harebell: thread stems with narrow leaves and nodding blue bells.
local function bellflower(p)
    local c, st = p.c, p.st
    local k = ({ 0, .34, .8, 1, 1 })[st]
    local out = Kit.soil(p, 64)
    for _i, l in ipairs({ { -14, -62 }, { 13, 58 }, { -6, -24 }, { 7, 28 } }) do
        local x, y = Svg.pol(13, l[2], 0, -4)
        out = out .. line(string.format("M0 -4 L%s %s", n(x), n(y)), c.ink, 1.6) .. ellipse(x, y, 6, 5.2, 0, c.leaf, c.ink, 1.3)
    end
    local hung = ""
    for _i, s in ipairs({ { { 0, -4 }, { -6, -52 }, { 4, -84 }, { 18, -98 }, { .66, .84, 1 }, 15 }, { { -2, -4 }, { -20, -40 }, { -34, -64 }, { -46, -70 }, { .74, 1 }, 13 }, { { 2, -4 }, { 22, -30 }, { 34, -50 }, { 46, -54 }, { 1 }, 12 } }) do
        local way = {}
        for i = 1, 4 do way[i] = { s[i][1] * (st == 2 and .6 or 1), -4 + (s[i][2] + 4) * k } end
        local stem = Kit.rise(p, way, 60, .4)
        for i, f in ipairs({ .2, .36, .52 }) do
            local x, y, ang = Kit.on(stem, f)
            out = out .. Flora.leaf(c, x, y, Kit.turn(p, ang, i % 2 == 0 and 1 or -1, 34), 15, 2.2, c.leaf, true)
        end
        out = out .. wire(p, stem, 1.9)
        for i, f in ipairs(st == 2 and {} or s[5]) do
            local x, y = Kit.on(stem, f)
            local dx = (i % 2 == 0 and -1 or 1) * (f == 1 and 3 or 7)
            hung = hung .. line(string.format("M%s %s q%s -3 %s 3", n(x), n(y), n(dx * .7), n(dx)), c.ink, 1.3) .. group(x + dx, y + 3, dx * 1.2, bell(p, s[6], st))
        end
    end
    return out .. hung
end

Meadow.sunflower = Kit.sprite("sunflower", "striped", sunflower, false, Rest.form({ w = 92, stubs = { { 0, 78, 4, 7 }, { -16, 30, -6, 4 } }, heads = { 1 }, litter = 4,
    head = function(dry) return group(0, 2, 150, group(0, -6, 0, Kit.sunflower(dry.c, 17, false), 1, .8)) end }))
Meadow.poppy = Kit.sprite("poppy", "pips", poppy, false, Rest.form({ w = 78, stubs = { { -8, 44, -8, 2.8 }, { 3, 60, 3, 3 }, { 14, 36, 10, 2.6 } }, heads = { 1, 2, 3 }, litter = 2,
    head = function(dry, i) return pepperpot(dry, 16 + i * 2) end }))
Meadow.chamomile = Kit.sprite("chamomile", "pips", chamomile, false, Rest.form({ w = 76, stubs = { { -16, 30, -10, 2.2 }, { -6, 44, -4, 2.4 }, { 5, 40, 4, 2.4 }, { 15, 30, 10, 2.2 }, { 0, 20, 1, 2 } }, heads = { 1, 2, 3, 4 },
    head = function(dry) return group(0, -2, 0, camHead(dry, 11, false)) end, heap = { 36, 4 } }))
Meadow.dandelion = Kit.sprite("dandelion", "parachute", dandelion, false, Rest.form({ w = 64, heap = { 56, 6 } }))
Meadow.pansy = Kit.sprite("pansy", "pips", pansy, false, Rest.form({ w = 62, heap = { 50, 5 }, stubs = { { -6, 18, -6, 2 }, { 6, 22, 5, 2 } } }))
Meadow.bellflower = Kit.sprite("bellflower", "pips", bellflower, false, Rest.form({ w = 64, stubs = { { -8, 40, -12, 1.9 }, { 2, 52, 6, 1.9 }, { 10, 32, 14, 1.8 } }, heads = { 1, 2, 3 }, litter = 2,
    head = function(dry, i) return group(0, 0, i % 2 == 0 and 140 or -140, bell(dry, 10, 5)) end }))

return Meadow
