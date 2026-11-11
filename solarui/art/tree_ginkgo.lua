-- The ginkgo of the garden at its stages 2 to 5: a seedling, a young tree
-- whose spur shoots are breaking into leaf, the full tree with a leader
-- running up through a narrow open crown of rising limbs, its fan leaves in
-- tufts on short spurs, and the tree turned butter yellow with its pale
-- orange seeds hanging in pairs. Through the year the fans are fresh and
-- light in spring, clear yellow in autumn with a carpet of them fallen at
-- the foot, and in winter the tree stands bare, the limbs knobbed with the
-- short spurs the fans grow from. Drawn with treekit, for plants_trees.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Svg = require("solarui/art/svg")
local Tree = require("solarui/art/treekit")
local Wash = require("solarui/art/wash")

local circle, group = Svg.circle, Svg.group
local mix = Wash.mix

local Ginkgo = {}

-- The trunk of the full tree, running up as the leader.
local TRUNK = { { 0, 0 }, { 4, -70 }, { -3, -150 }, { 2, -230 }, { 0, -300 } }

-- The limbs (see Tree.limbs), rising alternately left and right.
local LIMBS = {
    { at = .3, way = { { -30, -26 }, { -58, -48 }, { -80, -62 } }, w = { 9, 3 }, droop = 30 },
    { at = .37, way = { { 30, -28 }, { 60, -54 }, { 84, -70 } }, w = { 9, 3 }, droop = 30 },
    { at = .52, way = { { -24, -24 }, { -46, -44 }, { -64, -58 } }, w = { 8, 3 }, droop = 28 },
    { at = .6, way = { { 24, -26 }, { 46, -48 }, { 64, -62 } }, w = { 8, 3 }, droop = 28 },
    { at = .73, way = { { -18, -18 }, { -34, -34 }, { -46, -46 } }, w = { 6, 2.5 } },
    { at = .8, way = { { 18, -20 }, { 32, -36 }, { 42, -50 } }, w = { 6, 2.5 } },
}

-- The sprays of the crown: { limb whose tip they sit on (0 the leader),
-- dx, dy, rx, ry }. FAR ones hang behind the wood, on the leader `at` along.
local SPRAYS = {
    { 1, -4, -6, 34, 24 }, { 2, 4, -6, 36, 25 }, { 3, -2, -6, 32, 22 }, { 4, 2, -6, 32, 22 }, { 5, 0, -6, 28, 20 }, { 6, 0, -6, 28, 20 }, { 0, 0, -10, 26, 22 },
}
local FAR = { { .5, -26, 0, 38, 26 }, { .64, 30, 0, 36, 24 }, { .8, -18, -4, 30, 22 }, { .86, 22, -6, 28, 20 } }

-- The colours of the tree: { dark, lit, fans } in summer, in autumn (clear
-- yellow, as when the tree is in seed) and fresh in spring.
local function tones(p)
    local c = p.c
    if p.st == 5 or p.season == "autumn" then return { mix(c.gold, c.muted, .2), c.pale, mix(c.pale, c.cream, .45) } end
    if p.season == "spring" then return { mix(c.stem, c.leaf, .6), mix(c.leaf, c.pale, .3), mix(c.sage, c.pale, .45) } end
    return { mix(c.stem, c.leaf, .45), mix(c.leaf, c.sage, .35), mix(c.sage, c.pale, .3) }
end

-- One fan leaf on its long stalk from (x, y), heading `rot`, finely outlined with its veins.
local function fan(p, x, y, rot, R, fill)
    rot = Tree.hang(p, rot)
    local fx, fy = Svg.pol(R * .6, rot, x, y)
    return Tree.stalk(p, x, y, fx, fy, 1) .. Tree.fine(fx, fy, .6, Flora.ginkgo(p.c, 0, 0, rot, R / .6, fill, R < 10))
end

-- A tuft of fans on a short spur at (x, y), spreading round `up` degrees.
local function tuft(p, x, y, up, R, fill, i)
    local out = ""
    for k, a in ipairs({ -48, -16, 16, 48 }) do out = out .. fan(p, x, y, up + a + Tree.vary(-8, 8, i * 4 + k, 3), R * Tree.vary(.88, 1.08, i * 4 + k, 5), fill) end
    return out .. circle(x, y, 2.2, p.c.muted, p.c.ink, .9)
end

-- A spray of fans crowding round a short shoot at (x, y), rx by ry, over a dark body of leaves.
local function spray(p, x, y, rx, ry, tone, seed)
    local out = Svg.path(Tree.blob(x, y + ry * .1, rx * .6, ry * .52, "ginkgo", 15, 5, seed), tone[1], p.c.ink, 1.5)
    local count, R = math.max(7, math.floor(rx / 4)), math.min(15, ry * .62)
    for k = 0, count - 1 do
        local a = -138 + 276 * k / (count - 1) + Tree.vary(-9, 9, k, seed)
        local bx, by = x + rx * .42 * math.sin(math.rad(a)), y - ry * .42 * math.cos(math.rad(a)) + ry * .1
        out = out .. fan(p, bx, by, a * .92, R * Tree.vary(.86, 1.06, k, seed + 1), Svg.vary(k, seed + 2) < .55 and tone[2] or tone[3])
    end
    for k, a in ipairs({ -34, 6, 40 }) do out = out .. fan(p, x + a * rx * .006, y - ry * .05, a, R * .92, k == 2 and tone[3] or tone[2]) end
    return out
end

-- A pair of the fleshy seeds hanging from (x, y) on their long stalks.
local function seeds(p, x, y)
    local c, out = p.c, ""
    for _k, s in ipairs({ { -5, 15 }, { 5, 17 } }) do
        out = out .. Tree.stalk(p, x, y, x + s[1], y + s[2], 1.1) .. Svg.ellipse(x + s[1], y + s[2] + 4, 4.6, 5.2, 0, mix(c.gold, c.bloom, .3), c.ink, 1.1)
    end
    return out
end

-- The short spurs along a bare limb, knobs that the fans of spring will grow from.
local function spurs(p, pts, count, seed)
    local out = ""
    for k = 1, count do
        local x, y, ang = Tree.at(pts, .25 + .7 * (k - .5) / count)
        local side = (k + seed) % 2 == 0 and 1 or -1
        local ex, ey = Svg.pol(5, ang - 90 + side * 55, x, y)
        out = out .. Tree.stalk(p, x, y, ex, ey, 2.6) .. circle(ex, ey, 2, p.c.muted, p.c.ink, .8)
    end
    return out
end

-- The bare tree in winter: the leader and limbs with their spurs, and fine twigs rising from the tips.
local function bare(p, trunk, limbs, specs)
    local out = Tree.bare(p, limbs, specs, 22, 1, 16, .5)
    for i = 1, #specs do out = out .. spurs(p, limbs[i], 4, i) end
    local tx, ty = trunk[#trunk][1], trunk[#trunk][2]
    return out .. Tree.fork(p, tx, ty, 0, 18, 3, 1, 14, .5, 9) .. spurs(p, Svg.head(trunk, Svg.length(trunk)), 6, 3)
end

-- Fans fallen round the foot in autumn, a yellow carpet.
local function fallen(p, tone)
    return Tree.litter(112, 12, function(x, y, rot, i) return group(x, y, 0, Flora.ginkgo(p.c, 0, 0, rot, 9, tone[i % 2 + 2], true), 1, .6) end)
end

-- The full tree, in summer (stage 4) or in autumn (stage 5), or bare in winter.
local function full(p)
    local c, tone = p.c, tones(p)
    local trunk = Svg.spline(TRUNK, 8)
    local limbs = Tree.limbs(p, trunk, LIMBS)
    if p.season == "dormant" then return Tree.roots(p, 128, 48) .. Tree.wood(p, trunk, 40, 5, limbs, LIMBS) .. bare(p, trunk, limbs, LIMBS) end
    local far, near, extra = "", "", ""
    local shade = { mix(tone[1], c.ink, .22), tone[1], tone[2] }
    for i, f in ipairs(FAR) do
        local x, y = Kit.on(trunk, f[1])
        far = far .. spray(p, x + f[2], y + f[3], f[4], f[5], shade, i * 2.3)
    end
    for i, m in ipairs(SPRAYS) do
        local tip = limbs[m[1]][#limbs[m[1]]]
        near = near .. spray(p, tip[1] + m[2], tip[2] + m[3], m[4], m[5], tone, i * 1.71)
    end
    -- tufts on the bare stretch of each limb, and seeds under some in autumn
    for i = 1, 4 do
        local x, y, ang = Tree.at(limbs[i], .42)
        extra = extra .. tuft(p, x, y, ang - 90 + (i % 2 == 0 and -20 or 20), 13, tone[3], i)
        if p.st == 5 then extra = extra .. seeds(p, Kit.on(limbs[i], .64)) end
    end
    if p.st == 5 then extra = extra .. Flora.ginkgo(c, -50, -5, -100, 11, c.pale) .. Flora.ginkgo(c, 44, -3, 96, 10, c.gold) .. fan(p, -62, -100, 200, 11, c.pale) end
    if p.season == "autumn" then extra = extra .. fallen(p, tone) end
    return Tree.roots(p, 128, 48) .. far .. Tree.wood(p, trunk, 40, 5, limbs, LIMBS) .. near .. extra
end

-- The young tree: a slender leader and rising limbs with spur shoots opening into small tufts.
local function young(p)
    local c = p.c
    local trunk = Svg.spline({ { 0, 0 }, { 3, -60 }, { -2, -130 }, { 0, -190 } }, 8)
    local specs = {
        { at = .42, way = { { -22, -22 }, { -40, -38 }, { -52, -50 } }, w = { 5, 2.2 } },
        { at = .52, way = { { 22, -22 }, { 40, -40 }, { 50, -54 } }, w = { 5, 2.2 } },
        { at = .72, way = { { -16, -18 }, { -30, -34 } }, w = { 4, 2 } },
        { at = .78, way = { { 16, -18 }, { 28, -34 } }, w = { 4, 2 } },
    }
    local limbs = Tree.limbs(p, trunk, specs)
    local tx, ty = trunk[#trunk][1], trunk[#trunk][2]
    if p.season == "dormant" then
        return Tree.roots(p, 96, 30) .. Tree.wood(p, trunk, 20, 4.5, limbs, specs) .. bare(p, trunk, limbs, specs) .. Svg.ellipse(tx, ty - 2, 2.6, 4, 0, c.bloom, c.ink, .9)
    end
    local tone = p.season == "autumn" and tones(p) or { nil, mix(c.leaf, c.sage, .4), mix(c.sage, c.pale, .35) }
    local out = ""
    for i = 1, #limbs do
        for k, f in ipairs({ .5, 1 }) do
            local x, y, ang = Tree.at(limbs[i], f)
            out = out .. tuft(p, x, y, ang - 90, 9, tone[k + 1], i * 2 + k)
        end
    end
    out = out .. tuft(p, tx, ty, 0, 10, tone[3], 9) .. Svg.ellipse(tx, ty - 2, 2.6, 4, 0, c.bloom, c.ink, .9)
    return Tree.roots(p, 96, 30) .. Tree.wood(p, trunk, 20, 4.5, limbs, specs) .. out
end

-- The seedling: a thin stem with the first fans, or a bare stem and a bud in winter.
local function seedling(p)
    if p.season == "dormant" then
        return Tree.sapling(p, 50, { { 1, 0, 5 } }, function(x, y, rot, R) return Svg.ellipse(x, y - R * .6, R * .55, R, rot, p.c.muted, p.c.ink, .9) end)
    end
    local fill = p.season == "autumn" and p.c.pale or p.c.leaf
    return Tree.sapling(p, 50, { { .66, -74, 15 }, { .7, 70, 15 }, { 1, -30, 16 }, { 1, 30, 16 } },
        function(x, y, rot, R) return Tree.fine(x, y, .6, Flora.ginkgo(p.c, 0, 0, rot, R / .6, fill)) end)
end

-- The ginkgo at stage 2 to 5.
function Ginkgo.draw(p)
    if p.st == 2 then return seedling(p) end
    if p.st == 3 then return young(p) end
    return full(p)
end

return Ginkgo
