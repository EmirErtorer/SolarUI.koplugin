-- The Norway maple of the garden at its stages 2 to 5: a seedling, a young
-- tree in flower before its leaves, the full tree with a broad round crown
-- of five-lobed leaves on a short trunk forking low into ascending limbs,
-- and the tree in autumn gold with its paired winged seeds. Drawn in the
-- plant bed's units with treekit, for plants_trees.

local Blooms = require("solarui/art/blooms")
local Kit = require("solarui/art/plantkit")
local Svg = require("solarui/art/svg")
local Tree = require("solarui/art/treekit")
local Wash = require("solarui/art/wash")

local group, circle = Svg.group, Svg.circle
local mix = Wash.mix

local Maple = {}

-- The trunk of the full tree, from its foot to where it forks.
local TRUNK = { { 0, 0 }, { -3, -40 }, { 3, -80 }, { 0, -114 } }

-- The limbs (see Tree.limbs), with their width at foot and tip.
local LIMBS = {
    { at = .97, way = { { -24, -30 }, { -58, -58 }, { -90, -74 } }, w = { 13, 4 } },
    { at = 1, way = { { -10, -48 }, { -26, -100 }, { -40, -144 } }, w = { 12, 4 } },
    { at = 1, way = { { 12, -54 }, { 22, -108 }, { 30, -160 } }, w = { 12, 3.5 } },
    { at = .95, way = { { 30, -30 }, { 64, -54 }, { 94, -68 } }, w = { 12, 4 } },
    { from = 1, at = .5, way = { { -6, -30 }, { -14, -66 } }, w = { 6, 2.5 } },
    { from = 2, at = .55, way = { { -20, -22 }, { -40, -36 } }, w = { 5, 2.5 } },
    { from = 3, at = .5, way = { { 20, -22 }, { 40, -32 } }, w = { 5, 2.5 } },
    { from = 4, at = .45, way = { { 6, -30 }, { 10, -58 } }, w = { 6, 2.5 } },
    { from = 3, at = .3, way = { { -8, -24 }, { -20, -54 } }, w = { 5, 2.5 } },
}

-- The masses of the crown: { limb whose tip it hides, dx, dy, rx, ry }, the
-- ones at the back first.
local MASSES = {
    { 2, 4, -14, 52, 40 }, { 3, -2, -12, 56, 40 }, { 5, -2, -8, 46, 38 }, { 8, 0, -8, 48, 38 },
    { 1, 0, -2, 44, 34 }, { 4, -4, -2, 40, 32 }, { 6, 4, -6, 40, 32 }, { 7, -4, -6, 42, 34 }, { 9, 2, 6, 44, 36 },
}

-- The colours of the tree: { dark, lit, leaves } in summer or in autumn.
local function tones(p)
    local c = p.c
    if p.st == 5 then return { mix(c.gold, c.bloom, .5), c.gold, c.pale } end
    return { c.stem, c.leaf, c.sage }
end

-- One maple leaf on its stalk at (x, y), `R` tall, finely outlined.
local function leaf(p, x, y, rot, R, fill)
    return Tree.fine(x, y, .55, Blooms.maple(p.c, 0, 0, Tree.hang(p, rot), R / .55, fill))
end

-- A pair of winged seeds hanging from (x, y) on their stalk.
local function samaras(p, x, y, rot)
    return Tree.stalk(p, x, y, x, y + 10, 1.3) .. group(x, y + 10, rot, Kit.seed(p, "samara", 19), 1, -1)
end

-- One to three whole leaves scattered over the lit part of a mass, their tips turned outwards.
local function lit(p, lx, ly, lrx, lry, i, fill)
    local out = ""
    for k = 1, 1 + math.floor(Svg.vary(i, 7) * 2.6) do
        local a = -80 + 160 * Svg.vary(i * 5 + k, 1)
        local r = .2 + .35 * Svg.vary(i * 5 + k, 3)
        local x, y = lx + lrx * r * math.sin(math.rad(a)), ly - lry * r * math.cos(math.rad(a))
        out = out .. leaf(p, x, y + 10, a * .7 + Tree.vary(-12, 12, i * 3 + k, 2), Tree.vary(19, 25, i * 3 + k, 4), fill)
    end
    return out
end

-- The full tree, in summer (stage 4) or in autumn (stage 5).
local function full(p)
    local c, tone = p.c, tones(p)
    local trunk = Svg.spline(TRUNK, 8)
    local limbs = Tree.limbs(p, trunk, LIMBS)
    local crown, leaves, extra = "", "", ""
    for i, m in ipairs(MASSES) do
        local tip = limbs[m[1]][#limbs[m[1]]]
        local body, lx, ly, lrx, lry = Tree.mass(p, { tip[1] + m[2], tip[2] + m[3], m[4], m[5] }, "maple", tone, 30, 11, i * 1.37)
        crown, leaves = crown .. body, leaves .. lit(p, lx, ly, lrx, lry, i, tone[3])
    end
    -- leaves and seeds hanging on short twigs under the crown
    for k, h in ipairs({ { 1, .5, 200, -1 }, { 1, .74, 166, 1 }, { 4, .56, 160, 1 }, { 4, .78, 196, -1 } }) do
        local x, y = Kit.on(limbs[h[1]], h[2])
        local tw = Tree.twig(x, y, h[3], 16, h[4] * 3)
        local tx, ty = tw[#tw][1], tw[#tw][2]
        extra = extra .. Tree.drawTwig(p, tw)
        if p.st == 5 and k % 2 == 0 then extra = extra .. samaras(p, tx, ty, h[4] * 16)
        else extra = extra .. leaf(p, tx, ty, h[3] + h[4] * 10, 22, tone[k % 2 + 2]) end
    end
    if p.st == 5 then
        for k, s in ipairs({ { 2, .35 }, { 7, .7 }, { 6, .6 } }) do
            local x, y = Kit.on(limbs[s[1]], s[2])
            extra = extra .. samaras(p, x, y + 4, k * 14 - 20)
        end
        extra = extra .. leaf(p, -54, -6, 104, 15, c.gold) .. leaf(p, 46, -4, -80, 14, tone[1]) .. leaf(p, -70, -120, 150, 14, c.pale) .. leaf(p, 84, -104, 40, 13, c.gold)
    end
    return Tree.roots(p, 138, 52) .. Tree.wood(p, trunk, 44, 15, limbs, LIMBS) .. crown .. leaves .. extra
end

-- A rounded cluster of small yellow-green flowers held up from a twig tip at (x, y).
local function flowers(p, x, y, rot)
    local c, out = p.c, ""
    local cx, cy = Svg.pol(9, rot, x, y)
    for k = 0, 6 do
        local fx, fy = Svg.pol(k == 0 and 0 or 7.5, rot + k * 60 - 30, cx, cy)
        out = out .. Tree.stalk(p, x, y, fx, fy, .9)
    end
    for k = 0, 6 do
        local fx, fy = Svg.pol(k == 0 and 0 or 7.5, rot + k * 60 - 30, cx, cy)
        out = out .. Svg.dots(fx, fy, 2.6, 5, 4, mix(c.pale, c.leaf, .3)) .. circle(fx, fy, 1.7, c.gold, c.ink, .6)
    end
    return out
end

-- The young tree in spring: open limbs with clusters of flowers, the first leaves and swelling buds.
local function young(p)
    local c = p.c
    local trunk = Svg.spline({ { 0, 0 }, { -2, -50 }, { 2, -104 }, { 0, -140 } }, 8)
    local specs = {
        { at = .8, way = { { -22, -24 }, { -46, -44 }, { -68, -56 } }, w = { 7, 2.4 } },
        { at = 1, way = { { -8, -34 }, { -20, -74 } }, w = { 7, 2.4 } },
        { at = 1, way = { { 10, -36 }, { 20, -80 } }, w = { 7, 2.4 } },
        { at = .72, way = { { 24, -20 }, { 50, -36 }, { 70, -44 } }, w = { 7, 2.4 } },
        { from = 1, at = .55, way = { { -4, -20 }, { -8, -38 } }, w = { 3.4, 1.8 } },
        { from = 4, at = .55, way = { { 6, -20 }, { 10, -36 } }, w = { 3.4, 1.8 } },
        { from = 2, at = .5, way = { { -14, -12 }, { -26, -18 } }, w = { 3, 1.8 } },
        { from = 3, at = .55, way = { { 14, -12 }, { 26, -16 } }, w = { 3, 1.8 } },
    }
    local limbs = Tree.limbs(p, trunk, specs)
    local young_leaf, out = mix(c.leaf, c.pale, .25), ""
    for i = 1, #limbs do
        local tx, ty, ang = Tree.at(limbs[i], 1)
        local up = Tree.hang(p, ang - 90)
        out = out .. leaf(p, tx, ty, up - 78, 17, young_leaf) .. leaf(p, tx, ty, up + 78, 17, young_leaf) .. flowers(p, tx, ty, up)
        if i <= 4 then
            local bx, by, bang = Tree.at(limbs[i], .4)
            out = out .. Svg.ellipse(bx, by - 3, 2.4, 3.8, bang - 90 + (i % 2 == 0 and 30 or -30), mix(c.bloom, c.muted, .3), c.ink, .8)
        end
    end
    return Tree.roots(p, 104, 36) .. Tree.wood(p, trunk, 24, 7, limbs, specs) .. out
end

-- The seedling: a thin stem with its first pairs of leaves.
local function seedling(p)
    return Tree.sapling(p, 60, { { .6, -78, 22 }, { .6, 78, 22 }, { 1, -24, 26 }, { 1, 24, 26 } },
        function(x, y, rot, R, i) return Tree.fine(x, y, .6, Blooms.maple(p.c, 0, 0, rot, R / .6, i < 3 and p.c.leaf or mix(p.c.leaf, p.c.pale, .25))) end)
end

-- The maple at stage 2 to 5.
function Maple.draw(p)
    if p.st == 2 then return seedling(p) end
    if p.st == 3 then return young(p) end
    return full(p)
end

return Maple
