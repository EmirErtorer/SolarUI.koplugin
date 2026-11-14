-- The Three Sisters bed through the stages of its life, each sister drawn
-- to be told from the others at a glance: one tall stalk of maize with long
-- arching blue-green blades, an ear in its husk and a tassel; one pole bean
-- twining up the stalk with light green leaves of three leaflets, scarlet
-- flowers and hanging pods; and a squash sprawling low in front on both
-- sides with a few broad dark leaves, a yellow trumpet flower and one fruit
-- on the earth. The seeds of all three, the first sprouts, the young bed,
-- the bed in bloom, the dry harvest and the bed in winter, drawn with
-- plantkit and returned by name for gardenplants.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Rest = require("solarui/art/plantrest")
local Season = require("solarui/art/plantseason")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, ellipse, petal = Svg.n, Svg.group, Svg.path, Svg.line, Svg.ellipse, Flora.petal
local sin, cos, rad, pi = math.sin, math.cos, math.rad, math.pi
local mix = Wash.mix

local Bed = {}

local MAIZE = 6     -- where the maize stands, across from the middle of the bed
local EAR = .44     -- how far up the stalk the ear grows, on the left
local CROWN = -26   -- where the squash grows from

-- The colours of the bed at a stage. Growing, each sister has a green of
-- its own: the maize blue-green, the bean light and the squash dark. At the
-- seed head all three have dried.
local function tones(p)
    local c = p.c
    if p.st < 5 then
        return { blade = mix(c.glass, c.sage, .45), stalk = mix(c.glass, c.stem, .5), husk = mix(c.sage, c.pale, .45), cob = c.gold, tassel = c.pale,
            bean = mix(c.leaf, c.pale, .42), vine = mix(c.leaf, c.pale, .18), pod = mix(c.leaf, c.pale, .3),
            squash = mix(c.leaf, c.stem, .62), runner = mix(c.leaf, c.stem, .4), gourd = c.gold }
    end
    local straw, dead, rust = Season.dried(c)
    return { blade = straw, stalk = straw, husk = straw, cob = mix(c.gold, rust, .25), tassel = straw, bean = dead, vine = dead, pod = dead,
        squash = mix(dead, c.leaf, .3), runner = dead, gourd = mix(c.gold, c.bloom, .5), dead = dead }
end

-- A thin stem along `pts`, `w` wide, in `fill`.
local function wire(p, pts, w, fill)
    return Svg.stem(pts, Svg.taper(w, w * .75), fill or p.c.stem, p.c.ink, 1)
end

-- The maize's tassel standing up from the origin, `s` tall: a spike and
-- four branches arching out and over.
local function tassel(c, s, fill)
    local out = ""
    for _i, a in ipairs({ -62, 58, -30, 28, 0 }) do
        local L = s * (a == 0 and 1 or .9 - math.abs(a) / 300)
        local dx, dy = Svg.dir(a)
        local pts = Svg.spline({ { 0, 0 }, { dx * L * .45, dy * L * .5 }, { dx * L * .95, dy * L * .62 + L * .3 * math.abs(a) / 62 } }, 6)
        out = out .. Svg.stem(pts, Svg.taper(3, 1.4), fill, c.ink, 1)
    end
    return out
end

-- An ear of maize pointing up from the origin, `s` long: a cob of kernels
-- between two husk leaves with a tuft of silk at the tip, or with the husk
-- pulled back when dry.
local function ear(c, t, s, dry)
    local rows = {}
    for k = 1, 5 do
        local y = -s * (.2 + k * .12)
        local half = s * .15 * sin(pi * (k / 6)) ^ .5
        rows[#rows + 1] = string.format("M%s %s Q0 %s %s %s", n(-half), n(y), n(y + s * .03), n(half), n(y))
    end
    local cob = ellipse(0, -s * .52, s * .17, s * .44, 0, t.cob, c.ink, 1.2) .. line(table.concat(rows, " ") .. string.format(" M0 %s L0 %s", n(-s * .14), n(-s * .9)), c.ink, .7)
    if dry then
        return group(0, 0, 150, petal(c, s * .6, s * .16, t.husk, 1.1)) .. group(0, 0, -150, petal(c, s * .56, s * .15, t.husk, 1.1)) .. cob
    end
    local silk = {}
    for k = -1, 1 do silk[#silk + 1] = string.format("M0 %s Q%s %s %s %s", n(-s * .9), n(k * s * .1), n(-s * 1.08), n(k * s * .2 + s * .05), n(-s * 1.14 + math.abs(k) * s * .06)) end
    return line(table.concat(silk, " "), c.bloom, 1.4) .. cob
        .. group(-s * .05, 0, -7, petal(c, s * .8, s * .2, t.husk, 1.2)) .. group(s * .06, 0, 9, petal(c, s * .7, s * .17, t.husk, 1.2))
end

-- The joints of the maize at a stage: how far up the stalk each blade leaves and to which side.
local JOINTS = {
    [3] = { { .3, -1 }, { .5, 1 }, { .7, -1 }, { .9, 1 } },
    [4] = { { .26, 1 }, { .42, -1 }, { .58, 1 }, { .73, -1 }, { .87, 1 } },
}
JOINTS[5] = JOINTS[4]

-- The maize stalk at a stage over 2: long strap blades arching from the
-- joints, and from stage 4 an ear in the axil of a blade and a tassel on top.
-- Gives the blades, the stalk, the ear with the tassel, and the stalk's
-- points for the bean to climb.
local function maize(p, t)
    local c, st = p.c, p.st
    local tall = ({ 0, 0, 74, 112, 106 })[st]
    local stalk = Kit.rise(p, { { MAIZE, -3 }, { MAIZE + 2, -tall * .42 }, { MAIZE - 1, -tall * .78 }, { MAIZE, -tall } }, 50, .5)
    if st == 5 and not p.wilt then stalk = Kit.droop(stalk, 18, .72) end
    local blades, joints = "", {}
    for i, j in ipairs(JOINTS[st]) do
        local x, y, ang = Kit.on(stalk, j[1])
        local L = (st == 3 and 50 or 70) - 34 * j[1]
        local spread, curl = 18 + 26 * (1 - j[1]), st == 5 and 132 or 124 - 44 * j[1]
        blades = blades .. Kit.blade(p, x, y, ang + 90 + j[2] * spread, L, st == 3 and 7.5 or 9.5, j[2] * curl, (st == 5 and i % 2 == 0) and t.dead or t.blade, c.ink)
        joints[#joints + 1] = string.format("M%s %s l%s 0", n(x - 3.2), n(y), n(6.4))
    end
    local body, top = Svg.stem(stalk, Svg.taper(7, 4), t.stalk, c.ink, 1.4) .. line(table.concat(joints, " "), c.ink, 1), ""
    if st >= 4 then
        local x, y, ang = Kit.on(stalk, EAR)
        top = group(x - 2, y, ang + 90 - (st == 5 and 44 or 24), ear(c, t, 32, st == 5))
        x, y, ang = Kit.on(stalk, 1)
        top = top .. group(x, y, ang + 90, tassel(c, 22, t.tassel))
    end
    return blades, body, top, stalk
end

-- The bean winding round the maize stalk `stalk` up to `top` of the way,
-- `turns` times round: gives the stem where it passes behind the stalk, the
-- stem in front, the joints { x, y, side, f } where the leaves grow and
-- where the tip ends.
local function twine(p, t, stalk, top, turns)
    local len, steps = Svg.length(stalk), 80
    local runs, nodes = { { front = true, pts = { { MAIZE + 20, -2 }, { MAIZE + 12, -7 } } } }, {}
    local function reach(f) return 7 - 2 * f end
    for k = 0, steps do
        local u = k / steps
        local f = .06 + (top - .06) * u
        local x, y, ang = Svg.along(stalk, len * f)
        local w = 2 * pi * turns * u + pi * .2
        local pt = { x - sin(rad(ang)) * reach(f) * sin(w), y + cos(rad(ang)) * reach(f) * sin(w) }
        local front = cos(w) >= 0
        local run = runs[#runs]
        run.pts[#run.pts + 1] = pt
        if run.front ~= front then runs[#runs + 1] = { front = front, pts = { pt } } end
    end
    for m = 0, math.floor(turns * 2) do
        local u = ((m + .5) * pi - pi * .2) / (2 * pi * turns)
        if u > 0 and u < .96 then
            local f = .06 + (top - .06) * u
            local x, y, ang = Svg.along(stalk, len * f)
            local side = m % 2 == 0 and 1 or -1
            nodes[#nodes + 1] = { x - sin(rad(ang)) * reach(f) * side, y + cos(rad(ang)) * reach(f) * side, side, f }
        end
    end
    local back, front = "", ""
    for _i, r in ipairs(runs) do
        if #r.pts > 1 then
            if r.front then front = front .. wire(p, r.pts, 3, t.vine) else back = back .. wire(p, r.pts, 3, t.vine) end
        end
    end
    local last = runs[#runs].pts
    return back, front, nodes, last[#last]
end

-- A bean leaf of three broad leaflets on a stalk, pointing right from (x, y), `L` long.
local function trefoil(c, t, x, y, rot, L)
    local stalk = string.format("M-1 0 L%s 0", n(L * .5))
    return group(x, y, rot, line(stalk, c.ink, 3) .. line(stalk, t.vine, 1.4)
        .. Flora.leaf(c, L * .48, 0, -68, L * .5, L * .26, t.bean, true) .. Flora.leaf(c, L * .48, 0, 68, L * .5, L * .26, t.bean, true)
        .. Flora.leaf(c, L * .5, 0, 0, L * .62, L * .32, t.bean, L < 18))
end

-- A bean pod hanging from the origin, `L` long, swollen over each bean.
local function pod(c, L, fill)
    local w = L * .13
    local bumps = {}
    for k = 1, 3 do bumps[#bumps + 1] = string.format("M%s %s q%s %s 0 %s", n(w * .5), n(L * (.08 + k * .2)), n(w * .9), n(L * .08), n(L * .16)) end
    return path(string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s %s %s C%s %s %s %s 0 0Z", n(w * 1.5), n(L * .2), n(w * 1.9), n(L * .66), n(w * .7), n(L),
        n(w * .3), n(L * 1.07), n(-w * .1), n(L * 1.04), n(-w * .1), n(L * .96), n(w * .2), n(L * .62), n(-w * .8), n(L * .22)), fill, c.ink, 1.1)
        .. line(table.concat(bumps, " "), c.ink, .7)
end

-- A bean flower on the origin, `s` tall: a broad scarlet banner petal over two paler wings.
local function beanFlower(c, s)
    return group(0, 0, -50, petal(c, s * .8, s * .34, c.bloom, .9)) .. group(0, 0, 50, petal(c, s * .8, s * .34, c.bloom, .9))
        .. path(string.format("M0 0 C%s %s %s %s %s %s Q0 %s %s %s C%s %s %s %s 0 0Z", n(-s * .8), n(-s * .16), n(-s * .76), n(-s), n(-s * .24), n(-s * 1.04), n(-s * .84), n(s * .24), n(-s * 1.04),
            n(s * .76), n(-s), n(s * .8), n(-s * .16)), c.bloom, c.ink, 1)
end

-- What grows from the bean's joints: a leaf at each, and at stage 4 pods
-- and flowers by turns, at 5 dry pods and few leaves.
local function beanJoints(p, t, nodes)
    local c, st, out = p.c, p.st, ""
    local pods, right = "", 0
    for i, j in ipairs(nodes) do
        local x, y, side = j[1], j[2], j[3]
        local hang = x + side * 9
        if side == 1 then right = right + 1 end
        local fruit = side == 1 and right % 2 == 1
        if (st == 4 and fruit) or (st == 5 and side == 1) then
            local L = st == 5 and 26 or 30 - 6 * j[4]
            pods = pods .. group(hang, y + 2, side * -(st == 5 and 20 or 6), pod(c, L, t.pod)) .. group(hang + side * 4, y + 3, side * -18, pod(c, L * .8, t.pod))
        end
        local by_ear = st >= 4 and side == -1 and j[4] > EAR - .08 and j[4] < EAR + .3
        if (st < 5 or i % 2 == 1) and not by_ear then
            out = out .. trefoil(c, t, x, y, Kit.turn(p, -90, side, 58, .5), (st == 3 and 22 or 30 - 8 * j[4]) * (st == 5 and .8 or 1))
        end
        if st == 4 and side == 1 and not fruit then
            out = out .. group(x + 6, y - 4, 40, beanFlower(c, 7.5)) .. group(x + 11, y - 1, 64, beanFlower(c, 6.5))
        end
    end
    out = pods .. out
    return out
end

-- A squash leaf growing up from its stalk at (x, y), `s` tall: broad and
-- heart-shaped at the foot, with five shallow lobes and a vein to each.
local function squashLeaf(c, x, y, rot, s, fill)
    local lobes = { { -116, .7 }, { -60, .92 }, { 0, 1.04 }, { 60, .92 }, { 116, .7 } }
    local way, veins = { { 0, 0 }, { -s * .24, s * .04 } }, {}
    for i, l in ipairs(lobes) do
        local tx, ty = Svg.pol(s * l[2], l[1], 0, -s * .14)
        way[#way + 1] = { tx, ty }
        veins[#veins + 1] = string.format("M0 %s L%s %s", n(-s * .1), n(tx * .76), n(-s * .14 + (ty + s * .14) * .76))
        if i < #lobes then
            local sx, sy = Svg.pol(s * .8, (l[1] + lobes[i + 1][1]) / 2, 0, -s * .14)
            way[#way + 1] = { sx, sy }
        end
    end
    way[#way + 1] = { s * .24, s * .04 }
    way[#way + 1] = { 0, 0 }
    return group(x, y, rot, path(Svg.poly(Svg.spline(way, 5), true), fill, c.ink, 1.5) .. line(table.concat(veins, " "), c.ink, .8))
end

-- A squash flower seen from the side, growing up from the origin, `s`
-- tall: a yellow funnel opening into a rim of five pointed lobes round an
-- orange throat, on a green cup.
local function trumpet(c, s)
    local tips = { { -.52, -.9 }, { -.27, -1.02 }, { 0, -1.06 }, { .27, -1.02 }, { .52, -.9 } }
    local rim = {}
    for i, tp in ipairs(tips) do
        rim[#rim + 1] = string.format("L%s %s", n(tp[1] * s), n(tp[2] * s))
        if i < #tips then rim[#rim + 1] = string.format("L%s %s", n((tp[1] + tips[i + 1][1]) / 2 * s), n(-s * .84)) end
    end
    local funnel = path(string.format("M%s 0 C%s %s %s %s %s %s %s C%s %s %s %s %s 0Z", n(-s * .09), n(-s * .1), n(-s * .42), n(-s * .3), n(-s * .66), n(-s * .52), n(-s * .9), table.concat(rim, " "),
        n(s * .3), n(-s * .66), n(s * .1), n(-s * .42), n(s * .09)), c.gold, c.ink, 1.2)
    local ribs = string.format("M0 %s L0 %s M%s %s L%s %s M%s %s L%s %s", n(-s * .1), n(-s * .9), n(-s * .05), n(-s * .12), n(-s * .4), n(-s * .86), n(s * .05), n(-s * .12), n(s * .4), n(-s * .86))
    return funnel .. ellipse(0, -s * .86, s * .3, s * .07, 0, mix(c.gold, c.bloom, .45), c.ink, .9) .. line(ribs, mix(c.gold, c.bloom, .5), .9)
        .. ellipse(0, -s * .03, s * .17, s * .12, 0, c.leaf, c.ink, 1)
end

-- The places of the squash's leaves at a stage: { x, y, tilt, size }, back to front.
local LEAVES = {
    [3] = { { -46, -16, -50, 19 }, { -26, -24, -8, 21 }, { 30, -14, 44, 17 } },
    [4] = { { -52, -15, -58, 22 }, { 58, -15, 58, 21 }, { -31, -27, -18, 25 }, { 17, -19, 20, 18 } },
    [5] = { { -50, -9, -64, 18 }, { -30, -17, -22, 20 }, { 56, -8, 66, 16 } },
}

-- The squash at a stage over 2: a runner along the earth, broad leaves on
-- long stalks to both sides and, at stage 4, a trumpet flower.
local function squash(p, t)
    local c, st = p.c, p.st
    local out = wire(p, Svg.spline({ { CROWN, -3 }, { 0, -2 }, { 30, -3 }, { st == 3 and 34 or 60, -5 } }, 6), 2.8, t.runner)
    for _i, l in ipairs(LEAVES[st]) do
        local side = l[3] < 0 and -1 or 1
        local tilt = Kit.turn(p, -90, side, math.abs(l[3]), .4) + 90
        local bx, by = l[1] + (p.wilt and side * 3 or 0), l[2] + (p.wilt and 6 or 0)
        local from = l[1] > 0 and { l[1] - 10, -3 } or { CROWN, -3 }
        out = out .. wire(p, Svg.spline({ from, { (from[1] + bx) / 2, by * .55 - 3 }, { bx, by } }, 6), 2.4, t.runner)
            .. squashLeaf(c, bx, by, tilt, l[4], (st == 5 and l[1] > 0) and t.dead or t.squash)
    end
    if st == 4 then out = out .. group(-8, -4, p.wilt and -50 or -12, trumpet(c, 20)) end
    return out
end

-- A squash lying on the earth at (x, 0), `r` across its half: ribbed, with its stalk on top.
local function gourd(c, x, r, fill)
    local cy = -r * .68
    return ellipse(x, cy, r, r * .68, 0, fill, c.ink, 1.4) .. ellipse(x, cy, r * .56, r * .68, 0, nil, c.ink, .9) .. ellipse(x, cy, r * .16, r * .68, 0, nil, c.ink, .8)
        .. path(string.format("M%s %s Q%s %s %s %s L%s %s Q%s %s %s %sZ", n(x - 1.4), n(cy - r * .62), n(x - 1), n(cy - r * .9), n(x + 1.6), n(cy - r * 1.04), n(x + 3.4), n(cy - r * .96),
            n(x + 1.4), n(cy - r * .84), n(x + 1.6), n(cy - r * .62)), c.stem, c.ink, 1)
end

-- The first sprouts, each in its own green: a spike of maize unrolling two
-- blades, a bean seedling with the halves of its seed and two first leaves,
-- and a squash seedling with two round seed leaves and its first true leaf.
local function sprouts(p)
    local c, t = p.c, tones(p)
    local spike = Kit.rise(p, { { MAIZE, -2 }, { MAIZE + 1, -12 }, { MAIZE, -22 } }, 50, .4)
    local bean = Kit.rise(p, { { 34, -2 }, { 35, -12 }, { 32, -22 }, { 30, -24 } }, 60, .4)
    local bx, by = Kit.on(bean, 1)
    local leaf = Kit.turn(p, -90, -1, 70, .5)
    return group(0, 0, 0, Kit.soil(p, 110)
        .. Kit.blade(p, MAIZE, -9, 34, 24, 4.6, 44, t.blade) .. Kit.blade(p, MAIZE, -14, -28, 20, 4, -40, t.blade) .. Svg.stem(spike, Svg.taper(3.4, 1.2), t.blade, c.ink, 1.1)
        .. wire(p, bean, 2.6, t.vine) .. ellipse(30, -9, 4, 2.6, -24, c.pale, c.ink, 1) .. ellipse(39, -9, 4, 2.6, 24, c.pale, c.ink, 1)
        .. Flora.leaf(c, bx, by, leaf, 14, 5.6, t.bean, true) .. Flora.leaf(c, bx, by, 180 - leaf, 14, 5.6, t.bean, true)
        .. wire(p, Kit.rise(p, { { CROWN, -2 }, { CROWN + 1, -10 } }, 30), 2.6, t.runner) .. squashLeaf(c, CROWN + 1, -10, 6, 10, t.squash)
        .. Flora.leaf(c, CROWN, -8, Kit.turn(p, -90, -1, 74, .3), 15, 6, t.squash, true) .. Flora.leaf(c, CROWN + 2, -8, Kit.turn(p, -90, 1, 74, .3), 15, 6, t.squash, true), 1.3)
end

-- The bed at a stage from 2, back to front: the maize, the bean wound round
-- the stalk, then the squash low over the maize's foot and its fruit.
local function bed(p)
    if p.st == 2 then return sprouts(p) end
    local c, st = p.c, p.st
    local t = tones(p)
    local blades, stalk, top, pts = maize(p, t)
    local back, front, nodes, tip = twine(p, t, pts, st == 3 and .6 or .84, st == 3 and 1.25 or 2.25)
    local out = Kit.soil(p, 136) .. back .. blades .. stalk .. front .. top .. beanJoints(p, t, nodes)
    if st < 5 then out = out .. Flora.tendril(c, tip[1], tip[2], 16, 9) end
    out = out .. squash(p, t)
    if st >= 4 then out = out .. gourd(c, 38, st == 5 and 16 or 12, t.gourd) end
    return out
end

-- The bed in winter: dry husks hanging from the cut maize stalk, a bean
-- stub, and one last small squash left on the earth.
local function bedRest(p, dry)
    local c, out = p.c, ""
    for i, h in ipairs({ { -34, 1 }, { -26, -1 }, { -44, -1 } }) do
        out = out .. Kit.blade(dry, 2 * h[2], h[1], h[2] * 150, 26, 6, h[2] * 30, i == 2 and c.dead or c.straw, c.ink)
    end
    return out .. gourd(c, -36, 12, c.gold)
end

Bed.three_sisters = Kit.sprite("three_sisters", "sisters", bed, false, Rest.form({ w = 120, stubs = { { 0, 62, -3, 6 }, { 30, 24, 6, 3 } }, litter = 3, extra = bedRest }))

return Bed
