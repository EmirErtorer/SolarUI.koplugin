-- Small scenes for pages with nothing to show, each 220 x 140: a sleeping
-- fox in ferns, a bare branch with one bud, an empty shelf, an open book with
-- a tulip growing from it and fallen maple leaves. Each is
-- function(c, vw, vh) returning SVG.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n = Svg.n

local Scenes = {}

-- A fox curled up asleep, ferns on both sides of it.
function Scenes.scene_fox(c, vw, vh)
    local ground = Svg.line(string.format("M8 %s C60 %s 150 %s %s %s", n(vh * .93), n(vh * .9), n(vh * .97), n(vw - 8), n(vh * .93)), c.stem, 2.4)
    local tail = Svg.path("M166 100 C200 78 196 134 128 130 C108 130 92 126 84 120 C128 124 168 116 166 100Z", c.bloom, c.ink, 2)
    local body = Svg.ellipse(112, 102, 60, 28, -4, c.bloom, c.ink, 2)
    local head = Svg.circle(66, 100, 21, c.bloom, c.ink, 2)
    local ears = Svg.path("M52 86 L50 64 L66 80Z M72 82 L82 62 L86 84Z", c.bloom, c.ink, 2)
    local face = Svg.path("M48 104 C54 116 74 118 82 106 C72 108 58 108 48 104Z", c.cream, c.ink, 1.5)
        .. Svg.line("M56 97 Q61 101 66 97", c.ink, 1.8) .. Svg.circle(47, 104, 2.2, c.ink)
    return Flora.frond(c, 30, vh * .95, -22, 96) .. Flora.frond(c, 196, vh * .95, 24, 86) .. ground .. tail .. body .. head .. ears .. face
        .. Svg.ellipse(150, 126, 16, 5, -8, c.cream, c.ink, 1.4)
end

-- A bare branch with a single bud and a falling leaf.
function Scenes.scene_branch(c, vw, vh)
    local way = Svg.spline({ { 8, vh * .75 }, { vw * .3, vh * .6 }, { vw * .6, vh * .5 }, { vw * .86, vh * .3 } }, 8)
    local twigs = {}
    for _i, f in ipairs({ .3, .52, .74 }) do
        local x, y = Svg.along(way, Svg.length(way) * f)
        twigs[#twigs + 1] = Svg.stem(Svg.spline({ { x, y }, { x + 14, y + (f > .5 and -22 or 20) }, { x + 30, y + (f > .5 and -34 or 30) } }, 5), Svg.taper(4, 1.6), c.stem, c.ink, 1.2)
    end
    local tx, ty = way[#way][1], way[#way][2]
    return Svg.stem(way, Svg.taper(10, 4), c.stem, c.ink, 1.6) .. table.concat(twigs) .. Flora.rosebud(c, tx, ty, 35, 18, c.bloom2)
        .. Blooms.maple(c, vw * .24, vh * .38, -35, 26, c.gold)
end

-- An empty shelf with a curled rail, a sprout on it.
function Scenes.scene_shelf(c, vw, vh)
    local y = vh * .8
    local left = Svg.spiral(22, y + 8, 8, 1.2, 0, true)
    local rail = {}
    for i = #left, 1, -1 do rail[#rail + 1] = left[i] end
    rail = Svg.poly(Svg.join(rail, Svg.spiral(vw - 22, y + 8, 8, 1.2, 0)))
    return Svg.line(string.format("M54 %s c20 26 36 26 52 0 M%s %s c-20 26 -36 26 -52 0", n(y + 6), n(vw - 54), n(y + 6)), c.ink, 1.6)
        .. Svg.line(rail, c.ink, 7) .. Svg.line(rail, c.stem, 3.2)
        .. Flora.crozier(c, vw * .5, y - 2, 0, 66, 18) .. Flora.leaf(c, vw * .5, y - 2, -30, 34, 10) .. Flora.leaf(c, vw * .5, y - 2, -150, 34, 10)
end

-- An open book with a tulip growing out of its gutter.
function Scenes.scene_book(c, vw, vh)
    local m, y = vw / 2, vh * .86
    local left = Svg.path(string.format("M%s %s C%s %s %s %s %s %s L%s %s C%s %s %s %s %s %sZ", n(m), n(y - 6), n(m - 30), n(y - 22), n(m - 70), n(y - 22), n(m - 96), n(y - 8),
        n(m - 96), n(y + 12), n(m - 70), n(y - 2), n(m - 30), n(y - 2), n(m), n(y + 12)), c.cream, c.ink, 2)
    local right = Svg.path(string.format("M%s %s C%s %s %s %s %s %s L%s %s C%s %s %s %s %s %sZ", n(m), n(y - 6), n(m + 30), n(y - 22), n(m + 70), n(y - 22), n(m + 96), n(y - 8),
        n(m + 96), n(y + 12), n(m + 70), n(y - 2), n(m + 30), n(y - 2), n(m), n(y + 12)), c.cream, c.ink, 2)
    return Svg.line(string.format("M%s %s Q%s %s %s %s", n(m), n(y - 4), n(m + 3), n(y - 40), n(m), n(vh * .36)), c.stem, 4)
        .. Flora.leaf(c, m, y - 22, -30, 38, 11) .. Flora.leaf(c, m, y - 18, -150, 38, 11)
        .. left .. right .. Flora.tulip(c, m, vh * .4, 0, 34, c.bloom2)
        .. Svg.line(string.format("M%s %s q22 -8 44 0 M%s %s q22 -8 40 0", n(m - 84), n(y - 4), n(m + 46), n(y - 4)), c.line, 1.3)
end

-- Fallen maple leaves lying on the ground.
function Scenes.scene_leaves(c, vw, vh)
    return Svg.line(string.format("M8 %s C70 %s 150 %s %s %s", n(vh * .9), n(vh * .86), n(vh * .95), n(vw - 8), n(vh * .9)), c.stem, 2.4)
        .. Blooms.maple(c, vw * .3, vh * .86, -70, 62, c.gold) .. Blooms.maple(c, vw * .62, vh * .88, 62, 56, c.bloom)
        .. Blooms.maple(c, vw * .5, vh * .74, 12, 48, c.bloom2)
end

return Scenes
