-- The garden's furniture, each piece drawn with its top-left corner at the
-- origin of its own box: the pond, the bistro table with two wrought-iron
-- chairs, and the smaller things that stand in the free lawn (a bee skep,
-- stepping stones, a lantern, a watering can and flower pots, and the
-- ornaments of garden_decor.lua). Props.small(id) gives each one; every
-- drawing takes `winter` and then wears its snow.

local Decor = require("solarui/art/garden_decor")
local Flora = require("solarui/art/flora")
local Light = require("solarui/art/light")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse
local mix = Wash.mix

local Props = {}

-- A wrought-iron bar through the given points: it swells and thins like a
-- whiplash line, and may end in a scroll { cx, cy, r, turns, from, ccw }.
local function iron(c, way, w, scroll)
    local pts = Svg.spline(way, 10)
    if scroll then pts = Svg.join(pts, Svg.spiral(scroll[1], scroll[2], scroll[3], scroll[4], scroll[5], scroll[6])) end
    return path(Svg.ribbon(pts, Svg.swell(w, 1.6)), c.ink)
end

-- The pond in a box w x h: a rim of stone round the water, rings on it and
-- bulrushes at the far bank. In winter a shelf of cracked ice runs round
-- the edge and the open water in the middle (where the koi swims) is still.
function Props.pond(c, w, h, winter)
    local rim, water = {}, {}
    for a = 0, 345, 15 do
        local wob = 1 + .025 * math.sin(math.rad(a * 3 + 40))
        rim[#rim + 1] = { w / 2 + (w / 2 - 3) * wob * math.cos(math.rad(a)), h / 2 + (h / 2 - 3) * wob * math.sin(math.rad(a)) }
        water[#water + 1] = { w / 2 + (w / 2 - 17) * wob * math.cos(math.rad(a)), h / 2 + (h / 2 - 14) * wob * math.sin(math.rad(a)) }
    end
    local joints = {}
    for i = 1, #rim, 2 do joints[#joints + 1] = string.format("M%s %s L%s %s", n(rim[i][1]), n(rim[i][2]), n(water[i][1]), n(water[i][2])) end
    rim[#rim + 1], water[#water + 1] = rim[1], water[1]
    local reeds = ""
    for i, r in ipairs({ { w - 44, 46, 10, -6 }, { w - 34, 52, 4, 3 }, { w - 22, 62, 16, 8 } }) do
        local top = r[3]
        reeds = reeds .. line(string.format("M%s %s Q%s %s %s %s", n(r[1]), n(r[2]), n(r[1] + r[4] * .2), n((r[2] + top) / 2), n(r[1] + r[4]), n(top)), c.stem, 2.2)
            .. ellipse(r[1] + r[4] * .86, top + 12, 3.4, 9, r[4] * 1.2, c.muted, c.ink, 1.2)
            .. Flora.leaf(c, r[1] + (i == 2 and 4 or -3), r[2], -90 + r[4] * 3 + (i == 2 and 16 or -14), 34, 3, c.leaf, true)
    end
    local ground = path(Svg.poly(Svg.spline(rim, 4), true), c.line, c.ink, 2) .. line(table.concat(joints, " "), c.ink, 1)
    if winter then
        local open = {}
        for i, p in ipairs(water) do open[i] = { w / 2 + (p[1] - w / 2) * .74, h / 2 + (p[2] - h / 2) * .66 } end
        ground = ground .. path(Svg.poly(Svg.spline(water, 4), true), mix(c.sky, Light.paint("#FFFFFF"), .62), c.ink, 1.8)
            .. line(string.format("M%s %s l14 6 l10 -3 M%s %s l-12 8 l4 9 M%s %s l16 -5 l9 4 M%s %s l-10 -7", n(w * .2), n(h * .3), n(w * .8), n(h * .26), n(w * .26), n(h * .8), n(w * .78), n(h * .76)), mix(c.sky, c.ink, .4), 1)
            .. path(Svg.poly(Svg.spline(open, 4), true), c.sky, mix(c.sky, c.ink, .5), 1.2)
    else
        ground = ground .. path(Svg.poly(Svg.spline(water, 4), true), c.sky, c.ink, 1.8)
            .. line(string.format("M%s %s q16 -6 32 0 M%s %s q12 -4 24 0 M%s %s q14 5 28 0 M%s %s q10 -4 20 0", n(w * .5), n(24), n(w * .62), n(34), n(w * .3), n(h - 22), n(w * .5), n(h - 30)), c.ink, 1.1)
    end
    return ground
        .. reeds
end

-- One chair of the table, facing right, its seat about (66, 150): a back
-- of whiplash scrolls and curved legs with scroll feet.
local function chair(c, winter)
    return iron(c, { { 42, 152 }, { 22, 128 }, { 16, 96 }, { 30, 72 }, { 46, 62 }, { 58, 72 } }, 5, { 50, 78, 9, 1.2, 60 })
        .. iron(c, { { 54, 150 }, { 52, 126 }, { 40, 108 } }, 3.6, { 44, 100, 8.5, 1.3, 200, true })
        .. iron(c, { { 30, 132 }, { 38, 122 }, { 50, 124 } }, 2.6)
        .. iron(c, { { 44, 154 }, { 46, 180 }, { 38, 200 }, { 32, 212 } }, 4.6, { 26, 212, 5.5, .9, 90, true })
        .. iron(c, { { 90, 154 }, { 86, 180 }, { 92, 200 }, { 96, 212 } }, 4.6, { 102, 212, 5.5, .9, 270 })
        .. iron(c, { { 47, 178 }, { 66, 168 }, { 87, 178 } }, 2.6)
        .. ellipse(67, 152, 30, 6.5, 0, c.sage, c.ink, 1.8) .. line("M44 152 Q67 158 90 152", c.ink, .9)
        .. (winter and path("M40 151 C46 145 88 145 94 151 C84 149.4 50 149.4 40 151Z", Light.paint("#FFFFFF"), mix(c.sky, c.ink, .4), .8) or "")
end

-- The open book lying on the table, inside Layout.BOOK: each half of the
-- page block rises from the gutter in an arch and runs level to the gilt
-- fore-edge, the top pages recede with lines of print on them, the cloth
-- cover shows beneath with gold corners, and the ribbon hangs from the
-- gutter over the front of the table. The left half is drawn and mirrored
-- round the gutter at GX.
local GX = 148
local function book(c)
    local gilt = mix(c.cream, c.gold, .38)
    local function half(paper)
        return path("M98 110.5 L148 112.5 L148 116.2 L98 114.2Z", c.accent, c.ink, 1.3) .. path("M98 110.5 L104.5 110.8 L98 114.2Z", c.gold, c.ink, .8)
            .. path("M148 109 C146.5 101 143 97 134 96 C124 95 112 95 104 96 L102 97.5 L102 111 L148 113Z", gilt, c.ink, 1.3)
            .. line("M103 100.6 C115 99.6 128 99.7 140.5 101 M103 104 C115 103 128 103.2 142.6 104.8 M103 107.5 C116 106.6 130 107 145.2 108.7", mix(gilt, c.ink, .35), .7)
            .. path("M148 109 C146.5 101 143 97 134 96 C124 95 112 95 104 96 L102 97.5 L105 85.5 C112 84 124 84 134 85 C142 86 146 89 148 97Z", paper, c.ink, 1.3)
            .. line("M108.5 93.2 C118 92.4 128 92.6 138.5 93.8 M109.5 90.4 C119 89.6 129 89.8 139.5 90.9 M110.5 87.7 C120 86.9 130 87.1 140 88.2", c.line, .9)
    end
    return ellipse(GX, 114.5, 56, 3.6, 0, mix(c.cream, c.line, .7))
        .. half(c.cream) .. group(2 * GX, 0, 0, half(mix(c.cream, c.bg, .35)), -1, 1)
        .. line(string.format("M%s 97 L%s 109.5", GX, GX), c.ink, 1.1) .. ellipse(GX, 115.6, 3.4, 1.8, 0, mix(c.accent, c.ink, .4), c.ink, .8)
        .. path(string.format("M%s 97.5 Q%s 92.6 %s 97.5Z", GX - 3.2, GX, GX + 3.2), c.bloom, c.ink, .8)
        .. path(string.format("M%s 108.6 L%s 108.6 L%s 125 L%s 122.2 L%s 125.4Z", GX - 1.3, GX + 1.3, GX + 3, GX + 1, GX - 1.2), c.bloom, c.ink, .9)
end

-- The cup of tea beside the book, steaming, on its saucer.
local function cup(c)
    return ellipse(224, 109, 14, 3.4, 0, c.cream, c.ink, 1.2) .. path("M215 97 C215 105 218 109 224 109 C230 109 233 105 233 97Z", c.cream, c.ink, 1.4) .. ellipse(224, 97, 9, 2.2, 0, c.gold, c.ink, 1.1)
        .. line("M233 99 C239 99 239 105 232 105", c.ink, 1.3) .. line("M222 91 C218 85 226 81 222 75 M228 89 C225 85 230 82 228 78", c.ink, 1)
end

-- The table with its two chairs in a box 340 x 220, the book and the cup on
-- it; in winter snow lies on the seats and round the book.
function Props.table(c, winter)
    local foot = iron(c, { { 170, 122 }, { 168, 150 }, { 172, 176 } }, 6)
        .. iron(c, { { 171, 170 }, { 156, 184 }, { 140, 204 }, { 132, 212 } }, 4.6, { 126, 212, 5.5, .9, 90, true })
        .. iron(c, { { 171, 170 }, { 186, 184 }, { 202, 204 }, { 210, 212 } }, 4.6, { 216, 212, 5.5, .9, 270 })
        .. iron(c, { { 171, 172 }, { 170, 196 }, { 171, 214 } }, 4)
        .. iron(c, { { 168, 150 }, { 152, 142 }, { 140, 126 } }, 3, { 146, 124, 6, 1.1, 270 }) .. iron(c, { { 172, 150 }, { 188, 142 }, { 200, 126 } }, 3, { 194, 124, 6, 1.1, 90, true })
    local top = ellipse(170, 118, 74, 10, 0, c.line, c.ink, 1.8) .. ellipse(170, 113, 74, 10, 0, c.cream, c.ink, 1.8)
    if winter then top = top .. path("M98 112 C104 101 236 101 242 112 C236 106.6 104 106.6 98 112Z", Light.paint("#FFFFFF"), mix(c.sky, c.ink, .4), .8) end
    return chair(c, winter) .. group(340, 0, 0, chair(c, winter), -1, 1) .. foot .. top .. book(c) .. cup(c)
end

-- A straw bee skep on a low stand, 80 x 84.
local function skep(c, winter)
    local coils = {}
    for i = 1, 5 do coils[#coils + 1] = string.format("M%s %s Q40 %s %s %s", n(12 + (5 - i) * 2.6 - 3), n(20 + i * 9), n(26 + i * 9), n(68 - (5 - i) * 2.6 + 3), n(20 + i * 9)) end
    return line("M14 72 L10 83 M66 72 L70 83", c.ink, 2.6) .. path("M4 68 L76 68 L74 74 L6 74Z", c.muted, c.ink, 1.5)
        .. path("M10 68 C8 40 22 14 40 12 C58 14 72 40 70 68Z", c.pale, c.ink, 1.8) .. line(table.concat(coils, " "), c.ink, 1) .. line("M36 12 Q40 4 44 12", c.ink, 2)
        .. path("M33 68 C33 58 47 58 47 68Z", c.ink)
        .. (winter and path("M17 30 C22 10 58 10 63 30 C54 24 26 24 17 30Z", Light.paint("#FFFFFF"), mix(c.sky, c.ink, .4), .8) or "")
end

-- Three stepping stones that come towards the eye, 150 x 80.
local function stones(c)
    return ellipse(86, 10, 20, 5, 0, c.line, c.ink, 1.4) .. ellipse(56, 32, 30, 7.5, 0, c.line, c.ink, 1.5) .. ellipse(92, 62, 44, 11, 0, c.line, c.ink, 1.6)
        .. line("M70 60 l10 2 M100 66 l14 -2 M46 31 l8 1 M82 9 l6 1", c.ink, .9)
end

-- A lantern hanging from an iron crook, 44 x 76.
local function lantern(c, winter)
    return iron(c, { { 9, 75 }, { 10, 44 }, { 8, 20 }, { 16, 6 }, { 28, 6 } }, 4.4, { 28, 11, 5, 1.1, 0 }) .. line("M2 75 L17 75", c.ink, 3)
        .. line("M31 12 L31 20", c.ink, 1.4) .. path("M23 26 L39 26 L31 18Z", c.glass, c.ink, 1.4) .. path("M24.6 26 L37.4 26 L35.6 44 L26.4 44Z", c.pale, c.ink, 1.4)
        .. line("M31 26 L31 44", c.ink, .9) .. circle(31, 36, 2.6, c.gold, c.ink, .9) .. path("M26 44 L36 44 L31 49Z", c.glass, c.ink, 1.2)
        .. (winter and path("M22 26.4 L31 17 L40 26.4 Q31 23.4 22 26.4Z", Light.paint("#FFFFFF"), mix(c.sky, c.ink, .4), .8) or "")
end

-- A watering can, 104 x 64, its rose to the right.
local function can(c, winter)
    return path("M62 40 L92 12 L97 17 L70 50Z", c.sage, c.ink, 1.6) .. ellipse(96, 13, 3.4, 7, 45, c.pale, c.ink, 1.3)
        .. line("M26 20 C4 14 2 46 26 50", c.ink, 3.4) .. path("M24 16 L70 16 L74 62 L20 62Z", c.sage, c.ink, 1.8) .. ellipse(47, 16, 23, 4.4, 0, c.cream, c.ink, 1.5)
        .. line("M21.4 50 L72.8 50 M23 26 L71 26", c.ink, 1) .. line("M34 14 C36 2 58 2 60 14", c.ink, 2.6)
        .. (winter and ellipse(47, 15, 21, 3.4, 0, Light.paint("#FFFFFF"), mix(c.sky, c.ink, .4), .8) or "")
end

-- Two flower pots, one tipped on its side, 84 x 54.
local function pots(c)
    local pot = path("M-13 -24 L13 -24 L9 0 L-9 0Z", c.bloom, c.ink, 1.6) .. path("M-15 -30 L15 -30 L15 -23 L-15 -23Z", c.bloom, c.ink, 1.6)
    return group(22, 53, 0, pot) .. group(54, 52, 78, pot, .9) .. Flora.leaf(c, 22, 23, -110, 16, 5, c.leaf, true) .. Flora.leaf(c, 22, 23, -60, 18, 5, c.leaf, true)
end

-- The small things by id, each with its drawing and the size it is drawn at.
local SMALL = {
    skep = { draw = skep, w = 80, h = 84 }, stones = { draw = stones, w = 150, h = 80 },
    lantern = { draw = lantern, w = 44, h = 76 }, can = { draw = can, w = 104, h = 64 }, pots = { draw = pots, w = 84, h = 54 },
}
for id, piece in pairs(Decor.PIECES) do SMALL[id] = piece end

-- A small thing: { draw(c, winter), w, h }.
function Props.small(id)
    return SMALL[id]
end

return Props
