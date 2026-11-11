-- The Norway maple of the garden at its stages 2 to 5: a seedling, a young
-- tree in flower before its leaves, the full tree with a broad round crown
-- of five-lobed leaves on a short trunk forking low into ascending limbs,
-- and the tree in autumn gold with its paired winged seeds. Through the year
-- the crown is young and flecked with flowers in spring, russet and gold in
-- autumn with leaves fallen at the foot, and bare in winter. The golden
-- leaves of the reader's year hang in the crown in every season, and its
-- fruit when the year's goal is met. Drawn in the plant bed's units with
-- treekit, for plants_trees.

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

-- The colours of the tree: { dark, lit, leaves } in summer, in autumn
-- (russet and gold, as when it is in seed) and young in spring.
local function tones(p)
    local c = p.c
    if p.season == "autumn" then return { mix(c.bloom, c.gold, .3), mix(c.gold, c.bloom, .18), c.pale } end
    if p.st == 5 then return { mix(c.gold, c.bloom, .5), c.gold, c.pale } end
    if p.season == "spring" then return { mix(c.stem, c.leaf, .55), mix(c.leaf, c.pale, .3), mix(c.sage, c.pale, .45) } end
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

-- Small clusters of yellow-green flowers flecked over the crown in spring.
local function blossom(p)
    local c, out = p.c, ""
    for i, at in ipairs(Tree.scatter(0, -228, 104, 74, 16)) do
        local x, y = at[1] + Tree.vary(-6, 6, i, 41), at[2] + Tree.vary(-6, 6, i, 42)
        out = out .. Svg.dots(x, y, 3.2, 5, 3.8, mix(c.pale, c.leaf, .25)) .. circle(x, y, 1.6, c.gold, c.ink, .6)
    end
    return out
end

-- A few of the tree's leaves fallen round its foot in autumn.
local function fallen(p, tone)
    return Tree.litter(118, 7, function(x, y, rot, i) return Tree.fine(x, y, .55, group(0, 0, 0, Blooms.maple(p.c, 0, 0, rot, 14 / .55, tone[i % 3 + 1]), 1, .55)) end)
end

-- The bare crown in winter: the limbs forking into fine twigs, a last dry leaf or two hanging.
local function bare(p, limbs)
    local c = p.c
    local out = Tree.bare(p, limbs, LIMBS, 28, 2, 19, .4)
    for _k, h in ipairs({ { 4, .8, 15 }, { 2, .55, 13 } }) do
        local x, y = Kit.on(limbs[h[1]], h[2])
        out = out .. Tree.stalk(p, x, y, x + 2, y + 8, 1) .. leaf(p, x + 2, y + 8, 180, h[3], c.dead or c.gold)
    end
    return out
end

-- The full tree, in summer (stage 4) or in autumn (stage 5), or bare in winter.
local function full(p)
    local c, tone = p.c, tones(p)
    local trunk = Svg.spline(TRUNK, 8)
    local limbs = Tree.limbs(p, trunk, LIMBS)
    if p.season == "dormant" then return Tree.roots(p, 138, 52) .. Tree.wood(p, trunk, 44, 15, limbs, LIMBS) .. bare(p, limbs) end
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
    elseif p.season == "autumn" then
        extra = extra .. fallen(p, tone) .. leaf(p, -70, -120, 150, 14, c.pale) .. leaf(p, 84, -104, 40, 13, c.gold)
    elseif p.season == "spring" and p.st == 4 then
        extra = extra .. blossom(p)
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
    local young_leaf, out = p.season == "autumn" and c.gold or mix(c.leaf, c.pale, .25), ""
    if p.season == "dormant" then out = Tree.bare(p, limbs, specs, 20, 1, 26, .2) end
    for i = 1, #limbs do
        local tx, ty, ang = Tree.at(limbs[i], 1)
        local up = Tree.hang(p, ang - 90)
        if p.season ~= "dormant" then out = out .. leaf(p, tx, ty, up - 78, 17, young_leaf) .. leaf(p, tx, ty, up + 78, 17, young_leaf) end
        if p.season == "spring" or p.season == "summer" then out = out .. flowers(p, tx, ty, up) end
        if i <= 4 then
            local bx, by, bang = Tree.at(limbs[i], .4)
            out = out .. Svg.ellipse(bx, by - 3, 2.4, 3.8, bang - 90 + (i % 2 == 0 and 30 or -30), mix(c.bloom, c.muted, .3), c.ink, .8)
        end
    end
    return Tree.roots(p, 104, 36) .. Tree.wood(p, trunk, 24, 7, limbs, specs) .. out
end

-- The seedling: a thin stem with its first pairs of leaves, or only its buds in winter.
local function seedling(p)
    local c = p.c
    if p.season == "dormant" then
        return Tree.sapling(p, 60, { { .6, -40, 4 }, { .6, 40, 4 }, { 1, 0, 5 } },
            function(x, y, rot, R) return Svg.ellipse(x, y - R * .6, R * .55, R, rot, mix(c.bloom, c.muted, .3), c.ink, .9) end)
    end
    return Tree.sapling(p, 60, { { .6, -78, 22 }, { .6, 78, 22 }, { 1, -24, 26 }, { 1, 24, 26 } },
        function(x, y, rot, R, i) return Tree.fine(x, y, .6, Blooms.maple(c, 0, 0, rot, R / .6, i < 3 and c.leaf or mix(c.leaf, c.pale, .25))) end)
end

-- The crown at each stage { cx, cy, rx, ry, size of a leaf }, where the year's leaves hang.
local CROWNS = { [2] = { 0, -38, 12, 24, 6 }, [3] = { 0, -176, 70, 44, 13 }, [4] = { 0, -226, 100, 70, 16 }, [5] = { 0, -226, 100, 70, 16 } }

-- The order the year's leaves take their places in the crown, so even a few are spread through it.
local ORDER = { 7, 2, 11, 4, 9, 1, 12, 6, 3, 10, 5, 8 }

-- A golden fruit hanging on its stalk from (x, y).
local function fruit(p, x, y, s)
    local c = p.c
    return Tree.stalk(p, x, y, x + 1, y + s * .9, 1.1) .. circle(x + 1, y + s * 1.5, s * .7, mix(c.gold, c.bloom, .45), c.ink, 1.2)
        .. circle(x + .4 - s * .2, y + s * 1.3, s * .2, c.pale) .. Svg.ellipse(x + s * .5, y + s * .7, s * .45, s * .18, -30, c.leaf, c.ink, .8)
end

-- The golden leaves of the reader's year in the crown, with the fruit when the year's goal is met.
local function year(p)
    local crown = CROWNS[p.st]
    local out = ""
    if p.year > 0 then
        local spots = Tree.scatter(crown[1], crown[2], crown[3], crown[4], 12)
        for k = 1, p.year do
            local at = spots[ORDER[k]]
            out = out .. leaf(p, at[1], at[2] + crown[5] * .6, Tree.vary(-40, 40, k, 51), crown[5], mix(p.c.gold, p.c.pale, .2))
        end
    end
    if p.fruit then
        for k, at in ipairs(Tree.scatter(crown[1], crown[2] + crown[4] * .2, crown[3] * .8, crown[4] * .6, 5)) do
            out = out .. fruit(p, at[1] + Tree.vary(-5, 5, k, 52), at[2], crown[5] * .5)
        end
    end
    return out
end

-- The maple at stage 2 to 5.
function Maple.draw(p)
    local body
    if p.st == 2 then body = seedling(p)
    elseif p.st == 3 then body = young(p)
    else body = full(p) end
    return body .. year(p)
end

return Maple
