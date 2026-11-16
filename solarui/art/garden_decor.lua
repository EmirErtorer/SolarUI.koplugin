-- The garden's ornaments and the small life of its lawn, each piece drawn
-- with its top-left corner at the origin of its own box: a two-tier stone
-- fountain, a sundial, a bug hotel, a painted birdhouse on a post, a mossy
-- log with mushrooms and a bird feeder. Every piece takes `winter` and then
-- wears its snow: caps on rims, roofs and tops, the fountain's water frozen
-- with icicles under the upper bowl, and no mushrooms. Decor.path lays a
-- gravel path of flagstones from the gate to the table and on past the pond,
-- and Decor.flowers scatters daisies and clover over the free grass.

local Flora = require("solarui/art/flora")
local Light = require("solarui/art/light")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse
local mix, vary = Wash.mix, Svg.vary

local Decor = {}

-- The colours shared by the pieces: stone, weathered wood and snow.
local function tones(c)
    local wood = mix(c.bloom, c.muted, .55)
    return { stone = mix(c.line, c.cream, .35), shade = mix(c.line, c.ink, .18), wood = wood, dark = mix(wood, c.ink, .3), snow = Light.paint("#FFFFFF"),
        edge = mix(c.sky, c.ink, .4), bronze = mix(c.gold, c.muted, .45) }
end

-- A cap of snow lying along the top of an ellipse at (cx, cy) with radii rx, ry.
local function snowRim(t, cx, cy, rx, ry)
    return path(string.format("M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %sZ", n(cx - rx), n(cy), n(cx - rx * .8), n(cy - ry * 1.7), n(cx + rx * .8), n(cy - ry * 1.7), n(cx + rx), n(cy),
        n(cx + rx * .6), n(cy - ry * .6), n(cx - rx * .6), n(cy - ry * .6), n(cx - rx), n(cy)), t.snow, t.edge, .8)
end

-- Snow on a roof running from (x0, y0) up to the ridge (xm, ym) and down to (x1, y1).
local function snowRoof(t, x0, y0, xm, ym, x1, y1)
    return path(string.format("M%s %s L%s %s L%s %s Q%s %s %s %s Q%s %s %s %sZ", n(x0), n(y0), n(xm), n(ym - 3.2), n(x1), n(y1),
        n((xm + x1) / 2 + 2), n((ym + y1) / 2 + 3.4), n(xm), n(ym + 2.6), n((x0 + xm) / 2 - 2), n((ym + y0) / 2 + 3.4), n(x0), n(y0)), t.snow, t.edge, .8)
end

-- A stream of water from a list of points: ink outside, sky within.
local function stream(c, d, w)
    return line(d, c.ink, w + 1.6) .. line(d, c.sky, w)
end

-- A two-tier stone fountain, 110 x 136: a stepped plinth, a baluster with a
-- moulded ring, a wide lower basin with a whiplash band, a column rising out
-- of its water to a small upper bowl crowned with a bud, and water spilling
-- from the upper bowl into the lower one. In winter the water is ice and
-- icicles hang where the streams were.
local function fountain(c, winter)
    local t = tones(c)
    local water = winter and mix(c.sky, c.cream, .62) or c.sky
    local out = path("M22 136 L88 136 L84 128 L26 128Z", t.stone, c.ink, 1.6) .. path("M30 128 L80 128 L76 121 L34 121Z", t.stone, c.ink, 1.5)
        .. Flora.leaf(c, 30, 129, -158, 15, 5, c.leaf, true) .. Flora.leaf(c, 32, 129, -128, 12, 4.4, c.sage, true) .. Flora.leaf(c, 81, 130, -24, 13, 4.6, c.leaf, true)
        .. path("M40 121 C45 113 40 105 46 97 L64 97 C70 105 65 113 70 121Z", t.stone, c.ink, 1.6) .. ellipse(55, 108, 9.5, 2.4, 0, t.shade, c.ink, 1)
        .. path("M7 76 C11 90 33 98 55 98 C77 98 99 90 103 76Z", t.stone, c.ink, 1.8) .. line("M17 83.5 Q35 92 55 92 Q75 92 93 83.5", c.ink, .9)
        .. line("M30 88.5 q4 -5 9 -2 M80 88.5 q-4 -5 -9 -2", c.ink, .8)
        .. ellipse(55, 76, 48, 8.6, 0, t.stone, c.ink, 1.7) .. ellipse(55, 76, 41, 6, 0, water, c.ink, 1.2)
    if not winter then out = out .. line("M33 77 q7 -1.6 14 0 M64 77.5 q7 1.6 14 0", c.ink, .8) .. ellipse(23, 75.6, 5, 1.4, 0, nil, c.ink, .7) .. ellipse(87, 75.6, 5, 1.4, 0, nil, c.ink, .7) end
    out = out .. path("M51.5 77 C50 68 52.5 60 51 52 L59 52 C57.5 60 60 68 58.5 77Z", t.stone, c.ink, 1.4) .. ellipse(55, 64, 5.4, 1.6, 0, t.shade, c.ink, .9)
        .. path("M32 44 C35 52 45 56 55 56 C65 56 75 52 78 44Z", t.stone, c.ink, 1.5) .. ellipse(55, 44, 23.5, 4.6, 0, t.stone, c.ink, 1.4) .. ellipse(55, 44, 19, 3.1, 0, water, c.ink, 1)
        .. path("M53 44 L53 33 L57 33 L57 44Z", t.stone, c.ink, 1.2) .. path("M55 17 C60.5 23 61.5 29 55 34 C48.5 29 49.5 23 55 17Z", t.stone, c.ink, 1.3) .. line("M55 21 L55 31", c.ink, .7)
    if winter then
        for _i, x in ipairs({ 35, 41, 47, 63, 69, 75 }) do out = out .. path(string.format("M%s 49 L%s 49 L%s %sZ", n(x - 1.8), n(x + 1.8), n(x), n(54 + (x % 3) * 2.4)), mix(t.snow, c.sky, .25), c.ink, .7) end
        out = out .. snowRim(t, 55, 74.6, 46, 4.2) .. snowRim(t, 55, 43, 22.5, 2.6) .. path("M50.6 21.5 C53 17.4 57 17.4 59.4 21.5 Q55 20 50.6 21.5Z", t.snow, t.edge, .7)
    else
        out = out .. stream(c, "M32.6 45 C26.5 50 23.5 60 23 75", 1.5) .. stream(c, "M77.4 45 C83.5 50 86.5 60 87 75", 1.5)
            .. stream(c, "M55 17 C53.6 9 46.4 9.6 44.4 21", 1.1) .. stream(c, "M55 17 C56.4 9 63.6 9.6 65.6 21", 1.1)
            .. circle(42.6, 27, 1.3, c.sky, c.ink, .6) .. circle(67.4, 27, 1.3, c.sky, c.ink, .6) .. circle(20, 66, 1.2, c.sky, c.ink, .6) .. circle(90, 66, 1.2, c.sky, c.ink, .6)
    end
    return out
end

-- A sundial, 76 x 88: a bronze dial with hour marks and a gnomon on a
-- stone pedestal with a scrolled leaf. Snow lies on the dial in winter.
local function sundial(c, winter)
    local t = tones(c)
    local marks = {}
    for a = 0, 330, 30 do
        local r = math.rad(a)
        marks[#marks + 1] = string.format("M%s %s L%s %s", n(38 + 21 * math.cos(r)), n(37.5 + 5.6 * math.sin(r)), n(38 + 25.5 * math.cos(r)), n(37.5 + 6.9 * math.sin(r)))
    end
    local out = path("M17 88 L59 88 L56 81.5 L20 81.5Z", t.stone, c.ink, 1.5)
        .. path("M25 81.5 C29.5 72 25.5 60 31 48 L45 48 C50.5 60 46.5 72 51 81.5Z", t.stone, c.ink, 1.5) .. ellipse(38, 70, 9.4, 2.2, 0, t.shade, c.ink, .9)
        .. Flora.leaf(c, 38, 66, -58, 11, 3.4, c.sage, true) .. Flora.leaf(c, 38, 66, -122, 11, 3.4, c.sage, true) .. circle(38, 66, 1.6, c.gold, c.ink, .6)
        .. path("M23 48 L53 48 L50 42 L26 42Z", t.stone, c.ink, 1.4)
        .. ellipse(38, 40, 28, 7.8, 0, mix(t.bronze, c.ink, .25), c.ink, 1.4) .. ellipse(38, 37.5, 28, 7.8, 0, t.bronze, c.ink, 1.4)
        .. line(table.concat(marks, " "), c.ink, 1) .. line("M38 37.5 L54 40.6", mix(t.bronze, c.ink, .45), 2)
    if winter then out = out .. path("M12 37.5 C14 32 30 30.4 38 30.4 C46 30.4 62 32 64 37.5 C56 35.6 20 35.6 12 37.5Z", t.snow, t.edge, .8) .. snowRim(t, 38, 42.4, 13, 1.6) end
    return out .. path("M46 37.6 L31 37.6 L31 22.5 Q33 30 46 37.6Z", mix(t.bronze, c.ink, .35), c.ink, 1.2) .. circle(31, 22.5, 1.6, t.bronze, c.ink, .8)
end

-- A bug hotel, 78 x 88: a wooden house on two legs under a gabled roof,
-- its rooms filled with bamboo canes, drilled logs, pine cones, straw and
-- stacked log ends, twigs in the gable.
local function bughotel(c, winter)
    local t = tones(c)
    local out = line("M15 78 L13 88 M63 78 L65 88", c.ink, 3) .. path("M10 31 L39 11 L68 31Z", t.wood, c.ink, 1.3)
        .. line("M22 28 L52 18 M26 30 L58 24 M30 22 L48 28", t.dark, 1.3) .. path("M8 30 L70 30 L70 80 L8 80Z", t.wood, c.ink, 1.8)
    -- bamboo canes, top left
    for _i, p in ipairs({ { 14, 36 }, { 21, 36 }, { 28, 36 }, { 34.5, 36 }, { 17.5, 42 }, { 24.5, 42 }, { 31.5, 42 } }) do
        out = out .. circle(p[1], p[2], 3.3, c.pale, c.ink, .9) .. circle(p[1], p[2], 1.3, c.ink)
    end
    -- a drilled log, top right
    out = out .. path("M40 32 L68 32 L68 46 L40 46Z", mix(t.wood, c.cream, .45), c.ink, .9)
    for _i, p in ipairs({ { 45, 36 }, { 52, 35.5 }, { 59, 36.5 }, { 64, 41 }, { 48, 42 }, { 56, 42.5 } }) do out = out .. circle(p[1], p[2], 1.4, c.ink) end
    -- pine cones, middle left
    for _i, p in ipairs({ { 16, 54 }, { 29, 54.6 } }) do
        out = out .. ellipse(p[1], p[2], 5.6, 6.6, 0, t.dark, c.ink, 1) .. line(string.format("M%s %s l7 -2 M%s %s l7 0 M%s %s l7 2", n(p[1] - 3.5), n(p[2] - 2), n(p[1] - 3.5), n(p[2] + 1), n(p[1] - 3.5), n(p[2] + 4)), mix(t.dark, c.pale, .5), .8)
    end
    -- straw, middle right
    out = out .. path("M40 47 L68 47 L68 62 L40 62Z", c.pale, c.ink, .9) .. line("M41 50 L67 52 M41 54 L67 53 M41 57 L67 59 M41 60 L66 58", mix(c.pale, c.gold, .6), 1)
    -- stacked log ends along the bottom
    for i = 0, 5 do
        local x, y = 14 + i * 10, 68 + (i % 2) * 6
        out = out .. circle(x, y, 4.8, mix(t.wood, c.cream, .5), c.ink, .9) .. circle(x, y, 2.4, nil, mix(t.wood, c.ink, .3), .6)
    end
    out = out .. line("M8 46.5 L70 46.5 M8 62.5 L70 62.5 M39 30 L39 62.5", c.ink, 1.6)
        .. path("M2 33 L39 5 L76 33 L70 36 L39 13 L8 36Z", t.dark, c.ink, 1.6)
    if winter then out = out .. snowRoof(t, 2, 33, 39, 5, 76, 33) end
    return out
end

-- A painted birdhouse on a post, 56 x 94: a red roof, a round door with a
-- perch, two painted leaves and a tuft at the foot of the post.
local function birdhouse(c, winter)
    local t = tones(c)
    local out = path("M25 94 L31 94 L31 46 L25 46Z", t.wood, c.ink, 1.4) .. Flora.leaf(c, 25, 93, -150, 11, 3.6, c.leaf, true) .. Flora.leaf(c, 31, 93, -30, 10, 3.4, c.sage, true)
        .. line("M28 58 L16 49 M28 58 L40 49", c.ink, 1.8)
        .. path("M10 45 L46 45 L46 19 L28 7 L10 19Z", mix(c.sky, c.cream, .35), c.ink, 1.6) .. path("M8 45 L48 45 L48 49 L8 49Z", t.wood, c.ink, 1.3)
        .. circle(28, 27, 5.2, c.ink) .. line("M28 35.5 L28 40", c.ink, 2.2) .. circle(28, 40.4, 1.4, t.wood, c.ink, .8)
        .. Flora.leaf(c, 19, 38, -120, 8, 3, c.leaf, true) .. Flora.leaf(c, 37, 38, -60, 8, 3, c.leaf, true)
        .. path("M4 22 L28 2 L52 22 L48 25 L28 9 L8 25Z", c.bloom, c.ink, 1.6)
    if winter then out = out .. snowRoof(t, 4, 22, 28, 2, 52, 22) end
    return out
end

-- One mushroom with its foot at (x, y), `s` tall: a pale stem and a red cap spotted with cream.
local function mushroom(c, x, y, s, lean)
    local w = s * .5
    return group(x, y, lean or 0, path(string.format("M%s 0 C%s %s %s %s %s %s L%s %s C%s %s %s %s %s 0Z", n(-w * .28), n(-w * .22), n(-s * .3), n(-w * .2), n(-s * .5), n(-w * .18), n(-s * .66),
        n(w * .18), n(-s * .66), n(w * .2), n(-s * .5), n(w * .22), n(-s * .3), n(w * .28)), c.cream, c.ink, 1)
        .. path(string.format("M%s %s C%s %s %s %s 0 %s C%s %s %s %s %s %s Q0 %s %s %sZ", n(-w), n(-s * .6), n(-w), n(-s * .95), n(-w * .5), n(-s * 1.08), n(-s * 1.08), n(w * .5), n(-s * 1.08), n(w), n(-s * .95), n(w), n(-s * .6), n(-s * .7), n(-w), n(-s * .6)), c.bloom, c.ink, 1.1)
        .. circle(-w * .45, -s * .82, s * .07, c.cream) .. circle(w * .2, -s * .93, s * .08, c.cream) .. circle(w * .58, -s * .74, s * .06, c.cream))
end

-- A mossy log lying in the grass, 124 x 46, its cut end showing rings,
-- with red mushrooms at its foot and on its top. In winter snow lies along
-- its top and the mushrooms are gone.
local function log(c, winter)
    local t = tones(c)
    local out = path("M14 15 L104 10.5 C111 10.5 116 23 112 36.5 L16 40.5 C8 40.5 5.5 17 14 15Z", t.wood, c.ink, 1.8)
        .. line("M20 22 L60 19.6 M30 30 L88 27 M66 17 L100 15.4 M24 35 L52 34", t.dark, 1.1)
        .. ellipse(107.5, 23.5, 8.6, 13, 0, mix(t.wood, c.cream, .5), c.ink, 1.5) .. ellipse(107.5, 23.5, 5, 8, 0, nil, t.dark, .8) .. ellipse(107.5, 23.5, 2, 3.4, 0, nil, t.dark, .8)
        .. path("M30 16.6 C34 10 46 9.6 52 15.4Z", c.sage, c.ink, 1) .. path("M70 13.6 C73 9 82 9 86 12.6Z", c.leaf, c.ink, 1)
    if winter then return out .. path("M12 16 C30 9 80 6 104 9 C108 9.4 110 12 111 15 C90 12 40 14 14 19Z", t.snow, t.edge, .8) end
    return out .. mushroom(c, 22, 45, 15, -6) .. mushroom(c, 33, 46, 10, 8) .. mushroom(c, 78, 12, 9, 4) .. Flora.leaf(c, 46, 44, -160, 12, 4, c.leaf, true)
end

-- A bird feeder on a post, 44 x 120: a green roof on two uprights over a
-- tray of seed, with a glass hopper of seed between them.
local function feeder(c, winter)
    local t = tones(c)
    local seed = mix(c.gold, c.muted, .3)
    local out = path("M19 120 L25 120 L25 50 L19 50Z", t.wood, c.ink, 1.4) .. Flora.leaf(c, 19, 119, -150, 11, 3.6, c.leaf, true)
        .. line("M22 59 L13 52 M22 59 L31 52", c.ink, 1.7) .. line("M8 49 L8 26 M36 49 L36 26", c.ink, 2.2)
        .. path("M14 27 L30 27 L30 46 L14 46Z", t.wood, c.ink, 1.3) .. path("M17 31 L27 31 L27 43 L17 43Z", mix(c.glass, c.cream, .72), c.ink, 1)
        .. path("M17.4 37 L26.6 37 L26.6 42.6 L17.4 42.6Z", seed) .. Svg.dots(22, 39.8, 2.2, 5, .8, mix(seed, c.ink, .4))
        .. path("M3 46 L41 46 L39 52 L5 52Z", t.dark, c.ink, 1.4) .. path("M7 46 Q12 42.6 17 45 Q22 43 27 45 Q32 42.8 37 46Z", seed, c.ink, .7)
        .. path("M0 27 L22 8 L44 27 L40 30 L22 14 L4 30Z", c.accent, c.ink, 1.6)
    if winter then out = out .. snowRoof(t, 0, 27, 22, 8, 44, 27) end
    return out
end

-- The pieces by id, each with its drawing and the size it is drawn at.
Decor.PIECES = {
    fountain = { draw = fountain, w = 110, h = 136 }, sundial = { draw = sundial, w = 76, h = 88 }, bughotel = { draw = bughotel, w = 78, h = 88 },
    birdhouse = { draw = birdhouse, w = 56, h = 94 }, log = { draw = log, w = 124, h = 46 }, feeder = { draw = feeder, w = 44, h = 120 },
}

-- The path's way, in the poster's units: in through the gate and down to the
-- table, from under the table to the pond's rim, and from the pond's foot
-- off the bottom of the lawn.
Decor.WAY = {
    { { 548, 452 }, { 554, 520 }, { 568, 600 }, { 586, 700 } },
    { { 600, 870 }, { 606, 940 }, { 612, 1004 } },
    { { 562, 1218 }, { 567, 1300 }, { 575, 1410 } },
}

-- How wide the path is at height y: narrow by the gate, wide near the eye.
local function breadth(y) return 46 + (y - 452) * .07 end

-- Is the poster point (x, y) on the path (or within `margin` of it)?
function Decor.onPath(x, y, margin)
    for _s, way in ipairs(Decor.WAY) do
        if y >= way[1][2] - 10 and y <= way[#way][2] + 10 then
            for _k, p in ipairs(Svg.spline(way, 12)) do
                local half = breadth(p[2]) / 2 + (margin or 8)
                if math.abs(p[1] - x) < half and math.abs(p[2] - y) < 14 then return true end
            end
        end
    end
    return false
end

-- An irregular flagstone round (cx, cy), rx by ry, its outline smoothed
-- through eight points that wander in and out by `seed`.
local function flag(cx, cy, rx, ry, seed)
    local pts = {}
    for k = 0, 7 do
        local a = math.rad(k * 45 + vary(seed, k + 50) * 20)
        local r = .84 + .26 * vary(seed, k + 60)
        pts[#pts + 1] = { cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r }
    end
    local d = {}
    for k = 1, 8 do
        local p, q = pts[k], pts[k % 8 + 1]
        local mx, my = (p[1] + q[1]) / 2, (p[2] + q[2]) / 2
        d[#d + 1] = (k == 1 and string.format("M%s %s", n(mx), n(my)) or "") .. string.format(" Q%s %s %s %s", n(q[1]), n(q[2]), n((q[1] + pts[(k + 1) % 8 + 1][1]) / 2), n((q[2] + pts[(k + 1) % 8 + 1][2]) / 2))
    end
    return table.concat(d) .. "Z"
end

-- The path along Decor.WAY: a band of pale gravel widening as it comes
-- nearer, edged with a fine line, and laid with big flat flagstones, each
-- with its thickness showing beneath and a worn crack or two, in pairs where
-- the path is wide. `place(x, y)` turns a poster point into the canvas's.
-- In winter the gravel lies under the snow and only the stones show,
-- dusted white.
function Decor.path(c, place, winter)
    local t = tones(c)
    local gravel, stone = mix(c.line, c.cream, .2), mix(c.cream, c.sky, .28)
    local out, i = {}, 0
    for _s, way in ipairs(Decor.WAY) do
        local pts = Svg.spline(way, 30)
        local moved = {}
        for k, p in ipairs(pts) do local x, y = place(p[1], p[2]); moved[k] = { x, y } end
        if not winter then
            local w0, w1 = breadth(way[1][2]), breadth(way[#way][2])
            out[#out + 1] = path(Svg.ribbon(moved, Svg.taper(w0, w1)), gravel, mix(gravel, c.ink, .45), 1.1)
            local dots = {}
            for k = 1, #moved, 2 do
                local p = moved[k]
                local w = breadth(pts[k][2])
                for j = 1, 3 do
                    local dx = (vary(k * 3 + j, 31) - .5) * w * .8
                    dots[#dots + 1] = string.format("M%s %s h1.6", n(p[1] + dx), n(p[2] + (vary(k + j, 32) - .5) * 6))
                end
            end
            out[#out + 1] = line(table.concat(dots, " "), mix(gravel, c.ink, .4), 1.6)
        end
        local len, at = Svg.length(pts), 6
        while at < len - 4 do
            local x, y = Svg.along(pts, at)
            local w = breadth(y)
            local ry = w * .2
            local twin = w > 64
            for side = twin and -1 or 0, twin and 1 or 0, 2 do
                i = i + 1
                local rx = twin and w * .25 or w * .42
                local px, py = place(x + side * w * .23 + (vary(i, 41) - .5) * w * .08, y + (vary(i, 43) - .5) * ry * .4)
                local d = flag(px, py, rx, ry, i)
                out[#out + 1] = group(0, ry * .32, 0, path(d, t.shade)) .. path(d, stone, c.ink, 1.3)
                    .. line(string.format("M%s %s q%s %s %s %s", n(px - rx * .45), n(py - ry * .1), n(rx * .25), n(-ry * .3), n(rx * .6), n(-ry * .12)), mix(stone, c.ink, .45), .9)
                if winter then out[#out + 1] = path(flag(px - rx * .05, py - ry * .14, rx * .78, ry * .62, i + 7), t.snow) end
            end
            at = at + ry * 2 + 5
        end
    end
    return table.concat(out)
end

-- A daisy `s` across at (x, y): six white petals round a gold heart.
local function daisy(c, x, y, s)
    local out = ""
    for k = 0, 5 do out = out .. ellipse(x + math.cos(math.rad(k * 60)) * s * .32, y + math.sin(math.rad(k * 60)) * s * .2, s * .26, s * .13, k * 60, c.cream, c.ink, .6) end
    return out .. circle(x, y, s * .15, c.gold, c.ink, .5)
end

-- A tuft of clover `s` across at (x, y): three round leaves and, in summer, a pink head.
local function clover(c, x, y, s, head)
    local out = ""
    for k = 0, 2 do out = out .. circle(x + math.cos(math.rad(k * 120 - 90)) * s * .22, y + math.sin(math.rad(k * 120 - 90)) * s * .14, s * .2, c.leaf, c.ink, .6) end
    if head then out = out .. line(string.format("M%s %s L%s %s", n(x + s * .3), n(y), n(x + s * .36), n(y - s * .7)), c.stem, 1) .. circle(x + s * .36, y - s * .8, s * .2, c.bloom2, c.ink, .6) end
    return out
end

-- Daisies and clover in the free grass for the season (daisies in spring and
-- summer, clover until autumn, nothing in winter), never under anything that
-- stands: `free(x, y)` says whether a poster point is clear, `place(x, y)`
-- turns it into the canvas's, and the lawn runs from `top` to `floor`.
function Decor.flowers(c, season, free, place, top, floor)
    if season == "winter" then return "" end
    local out, daisies, clovers = {}, 0, 0
    local want_d, want_c = ({ spring = 30, summer = 26, autumn = 0 })[season] or 0, ({ spring = 10, summer = 16, autumn = 10 })[season] or 0
    for i = 1, 600 do
        if daisies >= want_d and clovers >= want_c then break end
        local x, y = 40 + 992 * vary(i, 61), top + 18 + (floor - top - 30) * vary(i, 62)
        if free(x, y) then
            local s = 9 + (y - top) / (floor - top) * 6
            local px, py = place(x, y)
            if daisies < want_d and (i % 3 ~= 0 or clovers >= want_c) then
                daisies = daisies + 1
                out[#out + 1] = daisy(c, px, py, s)
            elseif clovers < want_c then
                clovers = clovers + 1
                out[#out + 1] = clover(c, px, py, s * 1.1, season == "summer" and i % 2 == 0)
            end
        end
    end
    return table.concat(out)
end

-- Tracks in the winter snow: a cat's paw prints wandering from the left
-- edge to the table and on round the pond, and a bird's three-toed prints
-- under the feeder; `place(x, y)` turns a poster point into the canvas's.
function Decor.tracks(c, place)
    local mark = mix(c.sky, c.ink, .35)
    local out = {}
    local pts = Svg.spline({ { 60, 600 }, { 200, 640 }, { 330, 720 }, { 400, 860 }, { 360, 960 }, { 300, 1000 } }, 40)
    local len, at, i = Svg.length(pts), 0, 0
    while at < len do
        i = i + 1
        local x, y, ang = Svg.along(pts, at)
        local side = (i % 2 == 0) and 1 or -1
        local s = .8 + (y - 456) / 1000
        local px, py = place(x + side * 5 * s * math.sin(math.rad(ang or 0)), y - side * 3 * s)
        out[#out + 1] = ellipse(px, py, 2.8 * s, 2 * s, 0, mark)
        for k = -1, 1 do out[#out + 1] = circle(px + k * 2.6 * s, py - 3.2 * s + math.abs(k) * .8 * s, 1.1 * s, mark) end
        out[#out + 1] = circle(px + 3.8 * s * side, py - 1.4 * s, 1 * s, mark)
        at = at + 16 * s
    end
    local toes = {}
    for k, p in ipairs({ { 352, 1150 }, { 372, 1158 }, { 344, 1170 }, { 400, 1164 }, { 386, 1178 }, { 414, 1150 } }) do
        local px, py = place(p[1], p[2])
        local r = math.rad((k * 47) % 90 - 45)
        local function toe(a, l) return string.format("M%s %s L%s %s", n(px), n(py), n(px + math.sin(r + a) * l), n(py - math.cos(r + a) * l)) end
        toes[#toes + 1] = toe(0, 5) .. " " .. toe(.7, 4.2) .. " " .. toe(-.7, 4.2) .. " " .. toe(math.pi, 2.6)
    end
    return table.concat(out) .. line(table.concat(toes, " "), mark, 1.2)
end

return Decor
