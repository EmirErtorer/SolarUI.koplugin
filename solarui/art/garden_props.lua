-- The garden's furniture, each piece drawn with its top-left corner at the
-- origin of its own box: the pond, the bistro table with two wrought-iron
-- chairs, and the smaller things that stand in the free
-- lawn (a bee skep, stepping stones, a birdbath, a lantern, a watering can
-- and flower pots). Props.small(id) gives each one.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse

local Props = {}

-- A wrought-iron bar through the given points: it swells and thins like a
-- whiplash line, and may end in a scroll { cx, cy, r, turns, from, ccw }.
local function iron(c, way, w, scroll)
    local pts = Svg.spline(way, 10)
    if scroll then pts = Svg.join(pts, Svg.spiral(scroll[1], scroll[2], scroll[3], scroll[4], scroll[5], scroll[6])) end
    return path(Svg.ribbon(pts, Svg.swell(w, 1.6)), c.ink)
end

-- The pond in a box w x h: a rim of stone round the water, rings on it and
-- bulrushes at the far bank.
function Props.pond(c, w, h)
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
    return path(Svg.poly(Svg.spline(rim, 4), true), c.line, c.ink, 2) .. line(table.concat(joints, " "), c.ink, 1)
        .. path(Svg.poly(Svg.spline(water, 4), true), c.sky, c.ink, 1.8)
        .. line(string.format("M%s %s q16 -6 32 0 M%s %s q12 -4 24 0 M%s %s q14 5 28 0 M%s %s q10 -4 20 0", n(w * .5), n(24), n(w * .62), n(34), n(w * .3), n(h - 22), n(w * .5), n(h - 30)), c.ink, 1.1)
        .. reeds
end

-- One chair of the table, facing right, its seat about (66, 150): a back
-- of whiplash scrolls and curved legs with scroll feet.
local function chair(c)
    return iron(c, { { 42, 152 }, { 22, 128 }, { 16, 96 }, { 30, 72 }, { 46, 62 }, { 58, 72 } }, 5, { 50, 78, 9, 1.2, 60 })
        .. iron(c, { { 54, 150 }, { 52, 126 }, { 40, 108 } }, 3.6, { 44, 100, 8.5, 1.3, 200, true })
        .. iron(c, { { 30, 132 }, { 38, 122 }, { 50, 124 } }, 2.6)
        .. iron(c, { { 44, 154 }, { 46, 180 }, { 38, 200 }, { 32, 212 } }, 4.6, { 26, 212, 5.5, .9, 90, true })
        .. iron(c, { { 90, 154 }, { 86, 180 }, { 92, 200 }, { 96, 212 } }, 4.6, { 102, 212, 5.5, .9, 270 })
        .. iron(c, { { 47, 178 }, { 66, 168 }, { 87, 178 } }, 2.6)
        .. ellipse(67, 152, 30, 6.5, 0, c.sage, c.ink, 1.8) .. line("M44 152 Q67 158 90 152", c.ink, .9)
end

-- The table with its two chairs in a box 340 x 220: a round top on a
-- scrolled iron foot, a book and a steaming cup on it.
function Props.table(c)
    local foot = iron(c, { { 170, 122 }, { 168, 150 }, { 172, 176 } }, 6)
        .. iron(c, { { 171, 170 }, { 156, 184 }, { 140, 204 }, { 132, 212 } }, 4.6, { 126, 212, 5.5, .9, 90, true })
        .. iron(c, { { 171, 170 }, { 186, 184 }, { 202, 204 }, { 210, 212 } }, 4.6, { 216, 212, 5.5, .9, 270 })
        .. iron(c, { { 171, 172 }, { 170, 196 }, { 171, 214 } }, 4)
        .. iron(c, { { 168, 150 }, { 152, 142 }, { 140, 126 } }, 3, { 146, 124, 6, 1.1, 270 }) .. iron(c, { { 172, 150 }, { 188, 142 }, { 200, 126 } }, 3, { 194, 124, 6, 1.1, 90, true })
    local top = ellipse(170, 118, 64, 10, 0, c.line, c.ink, 1.8) .. ellipse(170, 113, 64, 10, 0, c.cream, c.ink, 1.8)
    local book = path("M126 106 L160 100 L172 106 L138 113Z", c.cream, c.ink, 1.2) .. path("M126 103 L160 97 L172 103 L138 110Z", c.bloom, c.ink, 1.4) .. line("M134 105.6 L164 100.4", c.ink, .8)
    local cup = ellipse(202, 110, 14, 3.4, 0, c.cream, c.ink, 1.2) .. path("M193 98 C193 106 196 110 202 110 C208 110 211 106 211 98Z", c.cream, c.ink, 1.4) .. ellipse(202, 98, 9, 2.2, 0, c.gold, c.ink, 1.1)
        .. line("M211 100 C217 100 217 106 210 106", c.ink, 1.3) .. line("M200 92 C196 86 204 82 200 76 M206 90 C203 86 208 83 206 79", c.ink, 1)
    return chair(c) .. group(340, 0, 0, chair(c), -1, 1) .. foot .. top .. book .. cup
end

-- A straw bee skep on a low stand, 80 x 84.
local function skep(c)
    local coils = {}
    for i = 1, 5 do coils[#coils + 1] = string.format("M%s %s Q40 %s %s %s", n(12 + (5 - i) * 2.6 - 3), n(20 + i * 9), n(26 + i * 9), n(68 - (5 - i) * 2.6 + 3), n(20 + i * 9)) end
    return line("M14 72 L10 83 M66 72 L70 83", c.ink, 2.6) .. path("M4 68 L76 68 L74 74 L6 74Z", c.muted, c.ink, 1.5)
        .. path("M10 68 C8 40 22 14 40 12 C58 14 72 40 70 68Z", c.pale, c.ink, 1.8) .. line(table.concat(coils, " "), c.ink, 1) .. line("M36 12 Q40 4 44 12", c.ink, 2)
        .. path("M33 68 C33 58 47 58 47 68Z", c.ink)
end

-- Three stepping stones that come towards the eye, 150 x 80.
local function stones(c)
    return ellipse(86, 10, 20, 5, 0, c.line, c.ink, 1.4) .. ellipse(56, 32, 30, 7.5, 0, c.line, c.ink, 1.5) .. ellipse(92, 62, 44, 11, 0, c.line, c.ink, 1.6)
        .. line("M70 60 l10 2 M100 66 l14 -2 M46 31 l8 1 M82 9 l6 1", c.ink, .9)
end

-- A birdbath, 90 x 86: a shallow bowl of water on a turned stem.
local function birdbath(c)
    return path("M33 84 L57 84 L54 76 L36 76Z", c.line, c.ink, 1.5) .. path("M40 76 C44 60 38 48 41 30 L49 30 C52 48 46 60 50 76Z", c.cream, c.ink, 1.6) .. ellipse(45, 52, 6.5, 2.6, 0, c.line, c.ink, 1.1)
        .. path("M6 18 C10 30 30 34 45 34 C60 34 80 30 84 18Z", c.cream, c.ink, 1.8) .. ellipse(45, 18, 39, 6.5, 0, c.sky, c.ink, 1.6) .. line("M30 18 q7 -2 14 0 M50 20 q6 2 12 0", c.ink, .9)
end

-- A lantern hanging from an iron crook, 44 x 76.
local function lantern(c)
    return iron(c, { { 9, 75 }, { 10, 44 }, { 8, 20 }, { 16, 6 }, { 28, 6 } }, 4.4, { 28, 11, 5, 1.1, 0 }) .. line("M2 75 L17 75", c.ink, 3)
        .. line("M31 12 L31 20", c.ink, 1.4) .. path("M23 26 L39 26 L31 18Z", c.glass, c.ink, 1.4) .. path("M24.6 26 L37.4 26 L35.6 44 L26.4 44Z", c.pale, c.ink, 1.4)
        .. line("M31 26 L31 44", c.ink, .9) .. circle(31, 36, 2.6, c.gold, c.ink, .9) .. path("M26 44 L36 44 L31 49Z", c.glass, c.ink, 1.2)
end

-- A watering can, 104 x 64, its rose to the right.
local function can(c)
    return path("M62 40 L92 12 L97 17 L70 50Z", c.sage, c.ink, 1.6) .. ellipse(96, 13, 3.4, 7, 45, c.pale, c.ink, 1.3)
        .. line("M26 20 C4 14 2 46 26 50", c.ink, 3.4) .. path("M24 16 L70 16 L74 62 L20 62Z", c.sage, c.ink, 1.8) .. ellipse(47, 16, 23, 4.4, 0, c.cream, c.ink, 1.5)
        .. line("M21.4 50 L72.8 50 M23 26 L71 26", c.ink, 1) .. line("M34 14 C36 2 58 2 60 14", c.ink, 2.6)
end

-- Two flower pots, one tipped on its side, 84 x 54.
local function pots(c)
    local pot = path("M-13 -24 L13 -24 L9 0 L-9 0Z", c.bloom, c.ink, 1.6) .. path("M-15 -30 L15 -30 L15 -23 L-15 -23Z", c.bloom, c.ink, 1.6)
    return group(22, 53, 0, pot) .. group(54, 52, 78, pot, .9) .. Flora.leaf(c, 22, 23, -110, 16, 5, c.leaf, true) .. Flora.leaf(c, 22, 23, -60, 18, 5, c.leaf, true)
end

-- The small things by id, each with its drawing and the size it is drawn at.
local SMALL = {
    skep = { draw = skep, w = 80, h = 84 }, stones = { draw = stones, w = 150, h = 80 }, birdbath = { draw = birdbath, w = 90, h = 86 },
    lantern = { draw = lantern, w = 44, h = 76 }, can = { draw = can, w = 104, h = 64 }, pots = { draw = pots, w = 84, h = 54 },
}

-- A small thing: { draw(c), w, h }.
function Props.small(id)
    return SMALL[id]
end

return Props
