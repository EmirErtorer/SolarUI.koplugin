-- The garden's trees and its climber through the stages of their life:
-- Norway maple, ginkgo and the ivy on its trellis. Each is drawn in its own
-- bed with plantkit and returned by name for gardenplants.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Svg = require("solarui/art/svg")
local Trellis = require("solarui/art/trellis")

local n, group, path, line, circle = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle

local Trees = {}

-- A trunk or limb through the given points, in bark, `w0` wide narrowing to `w1`.
local function limb(p, way, w0, w1)
    return Svg.stem(Svg.spline(way, 8), Svg.taper(w0, w1), p.c.muted, p.c.ink, 1.6)
end

-- The turn of a leaf on a tree: as given, or hanging when the tree is thirsty.
local function hang(p, rot)
    if not p.wilt then return rot end
    local a = (rot + 180) % 360 - 180
    return a + ((a < 0 and -180 or 180) - a) * .6
end

-- A young tree: a thin stem with leaves at the given places. `leaf` draws one.
local function sapling(p, tall, spots, leaf)
    local stem = Kit.rise(p, { { 0, -3 }, { -tall * .04, -tall * .5 }, { tall * .02, -tall } }, 40, .5)
    local out = ""
    for _i, s in ipairs(spots) do
        local x, y, ang = Kit.on(stem, s[1])
        out = out .. leaf(x, y, hang(p, ang + 90 + s[2]), s[3])
    end
    return Kit.soil(p, 90) .. out .. Svg.stem(stem, Svg.taper(tall * .05 + 2, 2.4), p.c.muted, p.c.ink, 1.4)
end

-- Norway maple: a round crown of pointed five-lobed leaves on a short trunk.
local function maple(p)
    local c, st = p.c, p.st
    local autumn = { c.gold, c.bloom, c.pale, c.gold, c.bloom2 }
    -- one leaf, in the colour of the season
    local function leaf(x, y, rot, R, i)
        return Blooms.maple(c, x, y, rot, R, st == 5 and autumn[(i or 0) % 5 + 1] or ((i or 0) % 3 == 1 and c.sage or c.leaf))
    end
    if st == 2 then return sapling(p, 50, { { .6, -70, 22 }, { .64, 70, 22 }, { 1, -24, 26 }, { 1, 26, 24 } }, leaf) end
    if st == 3 then return sapling(p, 150, { { .42, -62, 30 }, { .52, 60, 30 }, { .66, -50, 32 }, { .76, 52, 32 }, { .9, -34, 32 }, { .94, 36, 30 }, { 1, 0, 34 } }, leaf) end
    local out = Kit.soil(p, 120) .. limb(p, { { 2, -128 }, { -34, -170 }, { -78, -196 } }, 9, 4) .. limb(p, { { 0, -134 }, { 36, -176 }, { 84, -192 } }, 9, 4)
        .. limb(p, { { 0, -140 }, { -16, -200 }, { -36, -250 } }, 8, 3) .. limb(p, { { 2, -140 }, { 22, -206 }, { 44, -246 } }, 8, 3)
        .. limb(p, { { 0, -4 }, { -7, -60 }, { 6, -112 }, { 0, -150 }, { 4, -200 } }, 24, 7)
        .. line("M-5 -20 Q-9 -50 -4 -78 M5 -30 Q1 -64 7 -96", c.ink, 1)
    local crown = {}
    for a = 0, 330, 30 do
        local r = 1 + .08 * math.sin(math.rad(a * 3))
        crown[#crown + 1] = { 112 * r * math.sin(math.rad(a)), -218 - 92 * r * math.cos(math.rad(a)) }
    end
    crown[#crown + 1] = crown[1]
    out = out .. path(Svg.poly(Svg.spline(crown, 6), true), st == 5 and c.pale or c.sage, c.ink, 1.8)
    local i = 0
    for _r, ring in ipairs({ { 12, .86, 36, 15 }, { 8, .5, 36, 0 }, { 3, .16, 34, 40 } }) do
        for k = 0, ring[1] - 1 do
            i = i + 1
            local a = ring[4] + k * 360 / ring[1]
            local x, y = 104 * ring[2] * math.sin(math.rad(a)), -218 - 84 * ring[2] * math.cos(math.rad(a))
            if st == 4 and i % 4 == 0 then
                out = out .. circle(x - 5, y + 3, 3.4, c.pale, c.ink, 1) .. circle(x + 4, y + 5, 3.4, c.pale, c.ink, 1) .. circle(x, y - 3, 3.4, c.pale, c.ink, 1)
            elseif st == 5 and i % 4 == 0 then
                out = out .. group(x, y + 8, 90 + (k % 2) * 30, Kit.seed(p, "samara", 13))
            end
            out = out .. leaf(x, y, hang(p, a + (Svg.vary(i, 3) - .5) * 40), ring[3] * (.9 + .2 * Svg.vary(i, 5)), i)
        end
    end
    if st == 5 then out = out .. leaf(-64, -16, 100, 22, 1) .. leaf(56, -14, -70, 20, 0) end
    return out
end

-- Ginkgo: an upright tree, its fans in clusters along rising branches.
local function ginkgo(p)
    local c, st = p.c, p.st
    -- one fan, green in summer and golden when the seeds are ripe
    local function fan(x, y, rot, R, i)
        return Flora.ginkgo(c, x, y, rot, R, st == 5 and ((i or 0) % 3 == 0 and c.pale or c.gold) or ((i or 0) % 3 == 0 and c.sage or c.leaf), R < 16)
    end
    if st == 2 then return sapling(p, 46, { { .66, -74, 17 }, { .7, 70, 17 }, { 1, -30, 18 }, { 1, 30, 18 } }, fan) end
    if st == 3 then return sapling(p, 150, { { .4, -66, 20 }, { .5, 62, 20 }, { .62, -56, 20 }, { .72, 56, 20 }, { .84, -44, 20 }, { .9, 44, 20 }, { 1, -20, 20 }, { 1, 22, 20 } }, fan) end
    local trunk = Svg.spline({ { 0, -4 }, { 5, -90 }, { -4, -180 }, { 0, -262 } }, 8)
    local out, leaves, i = Kit.soil(p, 110), "", 0
    for b, br in ipairs({ { .32, -86, -150 }, { .4, 88, -168 }, { .52, -78, -214 }, { .6, 76, -232 }, { .72, -56, -268 }, { .8, 52, -284 }, { .92, -26, -306 }, { 1, 10, -304 } }) do
        local x, y = Kit.on(trunk, br[1])
        local pts = Svg.spline({ { x, y }, { x + (br[2] - x) * .5, y + (br[3] - y) * .35 }, { br[2], br[3] } }, 8)
        out = out .. Svg.stem(pts, Svg.taper(7 - b * .5, 2.4), c.muted, c.ink, 1.4)
        for k, f in ipairs({ .34, .58, .8, 1 }) do
            local lx, ly, ang = Kit.on(pts, f)
            if f < 1 or br[1] < 1 then
                for _j, turn in ipairs(f == 1 and { -48, 48, 0 } or { (k + b) % 2 == 0 and -62 or 62, (k + b) % 2 == 0 and 40 or -40 }) do
                    i = i + 1
                    leaves = leaves .. fan(lx, ly, hang(p, ang + 90 + turn), 21 - b * .5, i)
                end
                if st == 5 and (k + b) % 3 == 0 then
                    leaves = leaves .. line(string.format("M%s %s l-4 12 M%s %s l5 13", n(lx), n(ly), n(lx), n(ly)), c.ink, 1.1) .. circle(lx - 4, ly + 15, 4.4, c.pale, c.ink, 1.2) .. circle(lx + 5, ly + 16, 4.4, c.pale, c.ink, 1.2)
                end
            end
        end
    end
    out = out .. Svg.stem(trunk, Svg.taper(20, 5), c.muted, c.ink, 1.6) .. line("M-3 -24 Q-6 -60 -1 -96 M5 -40 Q2 -80 3 -120", c.ink, 1) .. leaves
    if st == 5 then out = out .. fan(-60, -10, -40, 17, 1) .. fan(54, -9, 50, 16, 3) end
    return out
end

-- An ivy leaf growing up from its stalk at (x, y), `s` tall: five shallow
-- pointed lobes and pale veins.
local function ivyLeaf(c, x, y, rot, s, fill)
    local tips = { { -122, .6 }, { -64, .84 }, { 0, 1.12 }, { 64, .84 }, { 122, .6 } }
    local function pt(r, a)
        local px, py = Svg.pol(r, a, 0, -s * .16)
        return n(px) .. " " .. n(py)
    end
    local d, veins = { "M0 0 Q" .. n(-s * .3) .. " " .. n(s * .12) .. " " .. pt(s * tips[1][2], tips[1][1]) }, {}
    for i = 2, #tips do d[#d + 1] = "L" .. pt(s * .56, (tips[i - 1][1] + tips[i][1]) / 2) .. " L" .. pt(s * tips[i][2], tips[i][1]) end
    d[#d + 1] = "Q" .. n(s * .3) .. " " .. n(s * .12) .. " 0 0Z"
    for _i, t in ipairs(tips) do veins[#veins + 1] = "M0 " .. n(-s * .14) .. " L" .. pt(s * t[2] * .78, t[1]) end
    return group(x, y, rot, line("M0 3 L0 " .. n(-s * .14), c.ink, 1.6) .. path(table.concat(d, " "), fill, c.ink, 1.5) .. line(table.concat(veins, " "), c.cream, 1))
end

-- A vine along the first `share` of `pts`, weaving from side to side, with a
-- leaf every few steps and berries or flower heads where `fruit` says.
local function vine(p, pts, share, fruit)
    local c = p.c
    local total = Svg.length(pts) * share
    local way, leaves, extra = {}, "", ""
    for d = 0, total, 9 do
        local x, y, ang = Svg.along(pts, d)
        local off = 9 * math.sin(d / 26)
        way[#way + 1] = { x + off * math.cos(math.rad(ang + 90)), y + off * math.sin(math.rad(ang + 90)) }
    end
    if #way < 3 then return "" end
    local i = 0
    for d = 14, Svg.length(way) - 4, 21 do
        i = i + 1
        local x, y, ang = Svg.along(way, d)
        local side = i % 2 == 0 and 1 or -1
        local s = 22 + 6 * Svg.vary(i, 2)
        local turn = ang + 90 + side * (58 + 20 * Svg.vary(i, 7))
        leaves = leaves .. ivyLeaf(c, x, y, y < -40 and hang(p, turn) or turn, s, i % 3 == 0 and c.leaf or c.stem)
        if fruit and i % 4 == 2 then
            local fx, fy = Svg.pol(15, ang + 90 - side * 80, x, y)
            extra = extra .. line(string.format("M%s %s L%s %s", n(x), n(y), n(fx), n(fy)), c.ink, 1.4)
            for k = 0, 4 do
                local bx, by = Svg.pol(k == 0 and 0 or 5.4, k * 90, fx, fy)
                extra = extra .. circle(bx, by, 3.6, fruit == 5 and c.ink or c.pale, c.ink, 1) .. (fruit == 5 and circle(bx - 1, by - 1, .9, c.cream) or "")
            end
        end
    end
    local tx, ty, tang = Svg.along(way, Svg.length(way))
    return leaves .. Svg.stem(way, Svg.taper(4.4, 2), c.stem, c.ink, 1.3) .. extra .. ivyLeaf(c, tx, ty, hang(p, tang + 90), 15, c.leaf)
end

-- The earth at the two feet of the trellis.
local function feet(p)
    return group(-178, 0, 0, Kit.soil(p, 56)) .. group(178, 0, 0, Kit.soil(p, 56))
end

-- Ivy: two vines that climb the posts of the trellis and meet over the arch.
local function ivy(p)
    local left, right = Trellis.way(0), {}
    for i = #left, 1, -1 do right[#right + 1] = left[i] end
    local reach = ({ 0, { .09, 0 }, { .34, .2 }, { .6, .44 }, { .6, .44 } })[p.st]
    return Trellis.frame(p.c) .. feet(p) .. vine(p, right, reach[2], p.st > 3 and p.st) .. vine(p, left, reach[1], p.st > 3 and p.st)
end

Trees.maple = Kit.sprite("maple", "samara", maple)
Trees.ginkgo = Kit.sprite("ginkgo", "nut", ginkgo)
Trees.ivy = Kit.sprite("ivy", function(p) return Trellis.frame(p.c) .. group(178, 0, 0, Kit.soil(p, 56)) .. group(-178, 0, 0, Kit.seedbed(p, "berry"), .6) end, ivy, true)

return Trees
