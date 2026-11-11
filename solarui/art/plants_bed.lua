-- The Three Sisters bed through the stages of its life: a mound of earth
-- with a tall stalk of maize, a climbing bean winding up the stalk and a
-- squash sprawling at the maize's foot. The seeds of all three, the first
-- sprouts, the young bed, the bed in bloom with ears, pods and a squash, the
-- dry harvest, and the bed after the harvest in winter, drawn with plantkit
-- and returned by name for gardenplants.

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

local MAIZE = 8     -- where the maize stands, across from the middle of the bed
local CROWN = -24   -- where the squash grows from

-- The colours of the bed at a stage: green and growing, or dried at the seed head.
local function tones(p)
    local c = p.c
    if p.st < 5 then
        return { blade = c.leaf, stalk = c.stem, husk = mix(c.sage, c.pale, .3), cob = c.gold, pod = c.leaf, squash = c.leaf, back = mix(c.leaf, c.sage, .5), gourd = c.gold }
    end
    local straw, dead, rust = Season.dried(c)
    return { blade = straw, stalk = straw, husk = straw, cob = mix(c.gold, rust, .25), pod = dead, squash = dead, back = straw, gourd = mix(c.gold, c.bloom, .5), dead = dead }
end

-- A thin climbing stem along `pts`, `w` wide.
local function wire(p, pts, w)
    return Svg.stem(pts, Svg.taper(w, w * .75), p.c.stem, p.c.ink, 1)
end

-- The maize's tassel standing up from the origin, `s` tall: a spike and
-- branches arching out and over, beaded with flowers.
local function tassel(c, s, fill)
    local out, beads = "", {}
    for i, a in ipairs({ -64, -34, 0, 30, 58 }) do
        local L = s * (a == 0 and 1 or .86 - math.abs(a) / 400)
        local dx, dy = Svg.dir(a)
        local pts = Svg.spline({ { 0, 0 }, { dx * L * .45, dy * L * .5 }, { dx * L * .95, dy * L * .62 + L * .3 * math.abs(a) / 64 } }, 6)
        out = out .. Svg.stem(pts, Svg.taper(2.4, .9), fill, c.ink, .9)
        for k = 2, 5 do
            local x, y, ang = Kit.on(pts, .15 + k * .17)
            local side = (k + i) % 2 == 0 and 1 or -1
            beads[#beads + 1] = ellipse(x, y, 1.1, 2.2, ang + side * 50, fill, c.ink, .6)
        end
    end
    return out .. table.concat(beads)
end

-- An ear of maize pointing up from the origin, `s` long: husk leaves round
-- a cob of kernels with silk at the tip, or with the husk pulled back when dry.
local function ear(c, t, s, dry)
    local cob = ellipse(0, -s * .52, s * .17, s * .44, 0, t.cob, c.ink, 1.2)
    local rows = {}
    for k = 1, 6 do
        local y = -s * (.18 + k * .1)
        local half = s * .15 * sin(pi * (k / 7)) ^ .5
        rows[#rows + 1] = string.format("M%s %s Q0 %s %s %s", n(-half), n(y), n(y + s * .03), n(half), n(y))
    end
    cob = cob .. line(table.concat(rows, " ") .. string.format(" M0 %s L0 %s", n(-s * .12), n(-s * .9)), c.ink, .6)
    if dry then
        return group(0, 0, 150, petal(c, s * .6, s * .16, t.husk, 1.1)) .. group(0, 0, -150, petal(c, s * .56, s * .15, t.husk, 1.1))
            .. group(0, 0, 175, petal(c, s * .5, s * .14, t.husk, 1.1)) .. cob
    end
    local silk = {}
    for k = -2, 2 do
        silk[#silk + 1] = string.format("M0 %s Q%s %s %s %s", n(-s * .92), n(k * s * .06), n(-s * 1.08), n(k * s * .14 + s * .04), n(-s * 1.1 + math.abs(k) * s * .07))
    end
    return line(table.concat(silk, " "), c.bloom, 1) .. cob
        .. group(0, 0, -8, petal(c, s * .74, s * .2, t.husk, 1.2)) .. group(0, 0, 10, petal(c, s * .68, s * .18, mix(t.husk, c.leaf, .4), 1.2))
end

-- The maize stalk at a stage over 2: strap leaves from its joints, and from
-- stage 4 ears in husks and a tassel on top. Gives the leaves, the stalk,
-- the ears with the tassel, and the stalk's points for the bean to climb.
local function maize(p, t)
    local c, st = p.c, p.st
    local tall = ({ 0, 0, 74, 110, 104 })[st]
    local stalk = Kit.rise(p, { { MAIZE, -3 }, { MAIZE + 3, -tall * .42 }, { MAIZE - 1, -tall * .78 }, { MAIZE + 1, -tall } }, 54, .5)
    if st == 5 and not p.wilt then stalk = Kit.droop(stalk, 22, .72) end
    local leaves, joints = "", {}
    for i, f in ipairs(st == 3 and { .16, .36, .56, .76 } or { .1, .24, .38, .52, .66, .8 }) do
        local x, y, ang = Kit.on(stalk, f)
        local side = i % 2 == 0 and 1 or -1
        local L = (st == 3 and 44 or 56) - 26 * f
        local curl = st == 5 and side * (120 - 20 * f) or side * (70 - 30 * f)
        leaves = leaves .. Kit.blade(p, x, y, ang + 90 + side * (36 + 18 * f), L, st == 3 and 6 or 7, curl, (st == 5 and i % 3 == 0) and t.dead or t.blade, c.ink)
        joints[#joints + 1] = string.format("M%s %s l%s 0", n(x - 3.4), n(y), n(6.8))
    end
    local body, top = Svg.stem(stalk, Svg.taper(7, 3.6), t.stalk, c.ink, 1.4) .. line(table.concat(joints, " "), c.ink, 1), ""
    if st >= 4 then
        for i, f in ipairs({ .36, .52 }) do
            local x, y, ang = Kit.on(stalk, f)
            local side = i == 1 and 1 or -1
            top = top .. group(x + side * 2, y, ang + 90 + side * (st == 5 and 44 or 24), ear(c, t, i == 1 and 34 or 30, st == 5))
        end
        local x, y, ang = Kit.on(stalk, 1)
        top = top .. group(x, y, ang + 90, tassel(c, 24, st == 5 and t.stalk or c.pale))
    end
    return leaves, body, top, stalk
end

-- The bean winding round the maize stalk `stalk` up to `top` of the way,
-- `turns` times round: gives the stems behind the stalk, the stems in front,
-- the joints { x, y, side, f } where the leaves grow and where the tip ends.
local function twine(p, stalk, top, turns)
    local len, steps = Svg.length(stalk), 80
    local runs, nodes = { { front = true, pts = { { MAIZE + 16, -2 }, { MAIZE + 9, -8 } } } }, {}
    for k = 0, steps do
        local u = k / steps
        local f = .05 + (top - .05) * u
        local x, y, ang = Svg.along(stalk, len * f)
        local w = 2 * pi * turns * u + pi * .2
        local off = (6.2 - 2 * f) * sin(w)
        local pt = { x - sin(rad(ang)) * off, y + cos(rad(ang)) * off }
        local front = cos(w) >= 0
        local run = runs[#runs]
        run.pts[#run.pts + 1] = pt
        if run.front ~= front then runs[#runs + 1] = { front = front, pts = { pt } } end
    end
    for m = 0, math.floor(turns * 2) do
        local u = ((m + .5) * pi - pi * .2) / (2 * pi * turns)
        if u > 0 and u < .96 then
            local f = .05 + (top - .05) * u
            local x, y, ang = Svg.along(stalk, len * f)
            local side = m % 2 == 0 and 1 or -1
            local off = 6.2 - 2 * f
            nodes[#nodes + 1] = { x - sin(rad(ang)) * off * side, y + cos(rad(ang)) * off * side, side, f }
        end
    end
    local back, front = "", ""
    for _i, r in ipairs(runs) do
        if #r.pts > 1 then
            if r.front then front = front .. wire(p, r.pts, 2.4) else back = back .. wire(p, r.pts, 2.4) end
        end
    end
    local last = runs[#runs].pts
    return back, front, nodes, last[#last]
end

-- A bean leaf of three leaflets on a short stalk, pointing right from (x, y), `L` long.
local function trefoil(c, x, y, rot, L, fill)
    local stalk = string.format("M-1 0 L%s 0", n(L * .3))
    return group(x, y, rot, line(stalk, c.ink, 2.8) .. line(stalk, c.stem, 1.2)
        .. Flora.leaf(c, L * .3, 0, -66, L * .5, L * .2, fill, true) .. Flora.leaf(c, L * .3, 0, 66, L * .5, L * .2, fill, true)
        .. Flora.leaf(c, L * .3, 0, 0, L * .66, L * .24, fill, true))
end

-- A bean pod hanging from the origin, `L` long, plump with beans; `dry`
-- twists it a little and shows the beans as bumps.
local function pod(c, L, fill, dry)
    local body = path(string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s %s %s C%s %s %s %s 0 0Z", n(3.4), n(L * .2), n(4.2), n(L * .66), n(1.6), n(L),
        n(.6), n(L * 1.06), n(-.2), n(L * 1.04), n(-.2), n(L * .96), n(.4), n(L * .62), n(-1.8), n(L * .22)), fill, c.ink, 1)
    local seam = line(string.format("M.6 %s Q2.6 %s 1.2 %s", n(L * .1), n(L * .5), n(L * .9)), c.ink, .6)
    if not dry then return body .. seam end
    local bumps = {}
    for k = 1, 4 do bumps[#bumps + 1] = string.format("M%s %s q1.8 %s 0 %s", n(2.6 - k * .2), n(L * (.12 + k * .17)), n(L * .07), n(L * .14)) end
    return body .. line(table.concat(bumps, " "), c.ink, .7)
end

-- A small bean flower at (x, y): a broad banner petal over two wings.
local function beanFlower(c, x, y, rot)
    return group(x, y, rot, group(0, 0, -48, petal(c, 4.6, 2, c.cream, .8)) .. group(0, 0, 48, petal(c, 4.6, 2, c.cream, .8))
        .. path("M0 0 C-4.6 -1 -4.4 -6.4 -1.4 -6.6 Q0 -5.4 1.4 -6.6 C4.4 -6.4 4.6 -1 0 0Z", c.bloom2, c.ink, .9))
end

-- What grows from the bean's joints: leaves, and at stage 4 pods and flowers by turns, at 5 dry pods.
local function beanJoints(p, t, nodes)
    local c, st, out = p.c, p.st, ""
    for i, j in ipairs(nodes) do
        local x, y, side = j[1], j[2], j[3]
        local leaf = st < 5 or i % 3 == 1
        if leaf then
            local L = (st == 3 and 18 or 24 - 6 * j[4]) * (st == 5 and .7 or 1)
            out = out .. trefoil(c, x, y, Kit.turn(p, -90, side, 66, .5), L, st == 5 and t.dead or (i % 2 == 0 and c.leaf or t.back))
        end
        if st == 4 and i % 2 == 0 then
            out = out .. group(x, y + 1, side * -14, pod(c, 22 - 4 * j[4], t.pod, false))
        elseif st == 4 and i > 1 then
            out = out .. beanFlower(c, x + side * 2, y - 2, side * 30)
        elseif st == 5 and i > 1 then
            out = out .. group(x, y + 1, side * -24, pod(c, 22, t.pod, true))
        end
    end
    return out
end

-- A squash leaf growing up from its stalk at (x, y), `s` tall: broad and
-- heart-shaped at the foot, with five shallow rounded lobes and a vein to each.
local function squashLeaf(c, x, y, rot, s, fill)
    local lobes = { { -118, .66 }, { -60, .9 }, { 0, 1.06 }, { 60, .9 }, { 118, .66 } }
    local way, veins = { { 0, 0 }, { -s * .22, s * .02 } }, {}
    for i, l in ipairs(lobes) do
        local tx, ty = Svg.pol(s * l[2], l[1], 0, -s * .14)
        way[#way + 1] = { tx, ty }
        veins[#veins + 1] = string.format("M0 %s L%s %s", n(-s * .1), n(tx * .78), n(-s * .14 + (ty + s * .14) * .78))
        if i < #lobes then
            local a = (l[1] + lobes[i + 1][1]) / 2
            local sx, sy = Svg.pol(s * .66, a, 0, -s * .14)
            way[#way + 1] = { sx, sy }
        end
    end
    way[#way + 1] = { s * .22, s * .02 }
    way[#way + 1] = { 0, 0 }
    return group(x, y, rot, path(Svg.poly(Svg.spline(way, 5), true), fill, c.ink, 1.5) .. line(table.concat(veins, " "), c.ink, .8))
end

-- The places of the squash's leaves at a stage: { x, y, tilt, size }, back to front.
local LEAVES = {
    [3] = { { -50, -14, -54, 18 }, { -30, -24, -14, 21 }, { -8, -12, 30, 15 } },
    [4] = { { -54, -12, -58, 21 }, { -38, -28, -32, 25 }, { -16, -32, -2, 25 }, { 30, -10, 56, 18 }, { -2, -16, 30, 20 } },
    [5] = { { -52, -8, -64, 17 }, { -32, -16, -24, 19 }, { 26, -6, 66, 14 } },
}

-- A squash at the stage: big five-lobed leaves on long stalks from the
-- crown, a runner along the earth, from stage 4 a yellow flower and a squash.
local function squash(p, t)
    local c, st = p.c, p.st
    local out = st >= 4 and wire(p, Svg.spline({ { CROWN, -3 }, { 0, -2 }, { 24, -3 }, { 40, -5 } }, 6), 2.6) or ""
    for i, l in ipairs(LEAVES[st]) do
        local side = l[3] < 0 and -1 or 1
        local tilt = Kit.turn(p, -90, side, math.abs(l[3]), .4) + 90
        local bx, by = l[1] + (p.wilt and side * 3 or 0), l[2] + (p.wilt and 5 or 0)
        local from = l[1] > 0 and { l[1] - 12, -3 } or { CROWN, -3 }
        out = out .. wire(p, Svg.spline({ from, { (from[1] + bx) / 2, by * .55 - 3 }, { bx, by } }, 6), 2.2)
            .. squashLeaf(c, bx, by, tilt, l[4], (i % 2 == 0 or st == 5) and t.squash or t.back)
    end
    if st == 4 then
        local fx, fy = -26, p.wilt and -36 or -46
        out = out .. line(string.format("M%s -4 Q%s %s %s %s", n(CROWN), n(fx - 4), n(fy * .5), n(fx), n(fy)), c.ink, 2.6) .. line(string.format("M%s -4 Q%s %s %s %s", n(CROWN), n(fx - 4), n(fy * .5), n(fx), n(fy)), c.stem, 1.2)
            .. group(fx, fy, 0, Flora.around(0, 0, 0, 5, petal(c, 10, 4.6, c.gold, 1.1), 18) .. Svg.circle(0, 0, 3.2, c.pale, c.ink, .9) .. Svg.circle(0, 0, 1.2, c.gold), 1, .72)
    end
    return out
end

-- A squash lying on the earth at (x, 0), `r` across its half: ribbed, with its stalk on top.
local function gourd(c, x, r, fill)
    local cy = -r * .68
    return ellipse(x, cy, r, r * .68, 0, fill, c.ink, 1.4) .. ellipse(x, cy, r * .56, r * .68, 0, nil, c.ink, .9) .. ellipse(x, cy, r * .16, r * .68, 0, nil, c.ink, .8)
        .. path(string.format("M%s %s Q%s %s %s %s L%s %s Q%s %s %s %sZ", n(x - 1.4), n(cy - r * .62), n(x - 1), n(cy - r * .9), n(x + 1.6), n(cy - r * 1.04), n(x + 3.4), n(cy - r * .96),
            n(x + 1.4), n(cy - r * .84), n(x + 1.6), n(cy - r * .62)), c.stem, c.ink, 1)
end

-- The first sprouts: a spike of maize unrolling two blades, a bean seedling
-- with the halves of its seed and two first leaves, and a squash seedling
-- with two round seed leaves and its first true leaf.
local function sprouts(p)
    local c = p.c
    local spike = Kit.rise(p, { { MAIZE, -2 }, { MAIZE + 1, -12 }, { MAIZE, -22 } }, 50, .4)
    local bean = Kit.rise(p, { { 34, -2 }, { 35, -12 }, { 32, -22 }, { 30, -24 } }, 60, .4)
    local bx, by = Kit.on(bean, 1)
    local leaf = Kit.turn(p, -90, -1, 70, .5)
    return group(0, 0, 0, Kit.soil(p, 110)
        .. Kit.blade(p, MAIZE, -9, 34, 24, 4.6, 44) .. Kit.blade(p, MAIZE, -14, -28, 20, 4, -40) .. Svg.stem(spike, Svg.taper(3.4, 1.2), c.leaf, c.ink, 1.1)
        .. wire(p, bean, 2.6) .. ellipse(30, -9, 4, 2.6, -24, c.pale, c.ink, 1) .. ellipse(39, -9, 4, 2.6, 24, c.pale, c.ink, 1)
        .. Flora.leaf(c, bx, by, leaf, 14, 5.6, c.leaf, true) .. Flora.leaf(c, bx, by, 180 - leaf, 14, 5.6, c.leaf, true)
        .. wire(p, Kit.rise(p, { { CROWN, -2 }, { CROWN + 1, -10 } }, 30), 2.6) .. squashLeaf(c, CROWN + 1, -10, 6, 10, c.leaf)
        .. Flora.leaf(c, CROWN, -8, Kit.turn(p, -90, -1, 74, .3), 15, 6, c.sage, true) .. Flora.leaf(c, CROWN + 2, -8, Kit.turn(p, -90, 1, 74, .3), 15, 6, c.sage, true), 1.3)
end

-- The bed at a stage from 2: the three sisters grown together, the squash low behind the maize's foot.
local function bed(p)
    if p.st == 2 then return sprouts(p) end
    local c, st = p.c, p.st
    local t = tones(p)
    local leaves, stalk, top, pts = maize(p, t)
    local back, front, nodes, tip = twine(p, pts, st == 3 and .58 or .86, st == 3 and 1.6 or 3.6)
    local out = Kit.soil(p, 130) .. squash(p, t) .. back .. leaves .. stalk .. front .. beanJoints(p, t, nodes) .. top
    if st < 5 then out = out .. Flora.tendril(c, tip[1], tip[2], 18, 8) end
    if st >= 4 then out = out .. gourd(c, 46, st == 5 and 15 or 10, t.gourd) end
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
