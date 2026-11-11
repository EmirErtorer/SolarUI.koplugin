-- The garden's trees and its climber through the stages of their life:
-- Norway maple and ginkgo (drawn in tree_maple and tree_ginkgo) and the ivy
-- on its trellis. Each is fitted to its own bed with plantkit and returned
-- by name for gardenplants.

local Ginkgo = require("solarui/art/tree_ginkgo")
local Kit = require("solarui/art/plantkit")
local Maple = require("solarui/art/tree_maple")
local Season = require("solarui/art/plantseason")
local Svg = require("solarui/art/svg")
local Tree = require("solarui/art/treekit")
local Trellis = require("solarui/art/trellis")

local n, group, path, line, circle = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle

local Trees = {}

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
    local rim = {}
    for _i, t in ipairs(tips) do
        veins[#veins + 1] = "M0 " .. n(-s * .14) .. " L" .. pt(s * t[2] * .78, t[1])
        if math.abs(t[1]) < 100 then
            for _k, f in ipairs({ .7, .95 }) do
                local px, py = Svg.pol(s * t[2] * f, t[1], 0, -s * .16)
                rim[#rim + 1] = { px, py }
            end
        end
    end
    return group(x, y, rot, line("M0 3 L0 " .. n(-s * .14), c.ink, 1.6) .. path(table.concat(d, " "), fill, c.ink, 1.5) .. line(table.concat(veins, " "), c.cream, 1) .. Season.rime(c, rim))
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
        leaves = leaves .. ivyLeaf(c, x, y, y < -40 and Tree.hang(p, turn) or turn, s, i % 3 == 0 and c.leaf or c.stem)
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
    return leaves .. Svg.stem(way, Svg.taper(4.4, 2), c.stem, c.ink, 1.3) .. extra .. ivyLeaf(c, tx, ty, Tree.hang(p, tang + 90), 15, c.leaf)
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

Trees.maple = Kit.sprite("maple", "samara", Maple.draw)
Trees.ginkgo = Kit.sprite("ginkgo", "nut", Ginkgo.draw)
Trees.ivy = Kit.sprite("ivy", function(p) return Trellis.frame(p.c) .. group(178, 0, 0, Kit.soil(p, 56)) .. group(-178, 0, 0, Kit.seedbed(p, "berry"), .6) end, ivy, true)

return Trees
