-- The garden's animals that walk or creep, each in the units of its own place
-- and facing right: garden snail, robin, hedgehog, red fox and peafowl. Each
-- takes the colours and whether it is in its second pose, and returns SVG.

local Svg = require("solarui/art/svg")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse

local Ground = {}

-- `body` turned by `deg` degrees about (x, y).
local function about(x, y, deg, body)
    return group(x, y, deg, group(-x, -y, 0, body))
end

-- Garden snail: a banded spiral shell on a soft foot. In pose two it has
-- drawn its head and horns half in.
function Ground.snail(c, second)
    local top = second and 31 or 19
    local foot = path(string.format("M5 50 C5 44 13 42 25 42 L50 42 C57 42 59 %s 60 %s C61 %s 63 %s 67 %s C72 %s 73 %s 71 %s C70 %s 75 45 75 48 C75 51 73 52 69 52 L9 52 C6 52 5 51 5 50Z",
        n(top + 14), n(top + 9), n(top + 3), n(top), n(top), n(top), n(top + 6), n(top + 11), n(top + 17)), c.cream, c.ink, 1.7)
        .. line("M14 48 l3 0 M24 47 l3 0 M56 47 l3 0 M64 44 l2 1", c.ink, .9)
    local horns = second and (line(string.format("M65 %s L63 %s M69 %s L71 %s", n(top + 1), n(top - 5), n(top + 1), n(top - 5)), c.ink, 1.5) .. circle(63, top - 6, 1.6, c.ink) .. circle(71, top - 6, 1.6, c.ink))
        or (line("M65 20 Q62 12 60 6 M69 20 Q70 12 73 6 M72 30 L77 33", c.ink, 1.5) .. circle(60, 5, 1.8, c.ink) .. circle(73, 5, 1.8, c.ink))
    local shell = circle(35, 27, 19, c.gold, c.ink, 1.8) .. line(Svg.poly(Svg.spiral(35, 27, 16.4, 1.75, 90)), c.muted, 3) .. line(Svg.poly(Svg.spiral(35, 27, 13.6, 1.9, 90)), c.ink, 1.5)
    return line("M2 53 L78 53", c.line, 1.6) .. group(second and 2 or -1, 0, 0, horns .. foot .. shell)
end

-- European robin: a round bird with an orange-red face and breast, a pale
-- belly and thin legs. In pose two it bobs forward with its tail cocked.
function Ground.robin(c, second)
    local tail = about(27, 45, second and -34 or -6, path("M30 40 L3 38 L2 46 L30 50Z", c.muted, c.ink, 1.5) .. line("M6 42 L26 44", c.ink, .8))
    local bird = tail .. path("M24 44 C22 26 40 14 58 16 C66 9 80 9 86 19 C90 25 90 32 87 36 C88 50 78 64 60 66 C42 68 26 60 24 44Z", c.muted, c.ink, 1.8)
        .. path("M36 57 C44 66 60 69 71 62 C66 58 63 54 62 47 C56 55 46 59 36 57Z", c.cream, c.ink, 1)
        .. path("M79 12 C87 15 91 25 88 35 C89 48 82 58 71 62 C63 56 60 46 64 38 C66 30 69 23 72 17 C74 13 76 12 79 12Z", c.bloom, c.ink, 1.3)
        .. path("M31 38 C38 28 54 27 62 35 C59 46 46 54 28 52 C30 47 30 42 31 38Z", c.muted, c.ink, 1.5) .. line("M36 44 C44 44 52 41 57 37 M34 48 C42 49 50 47 55 43", c.ink, .9)
        .. circle(80, 23, 3, c.ink) .. circle(81, 22, .9, c.cream) .. path("M88 25 L98 28 L88 31Z", c.ink, c.ink, 1)
    return line("M52 65 L51 76 M63 64 L65 76 M51 76 L45 77 M51 76 L57 77 M65 76 L59 77 M65 76 L71 77", c.ink, 1.6) .. about(58, 68, second and 13 or 0, bird)
end

-- European hedgehog: a dome of spines over a pale pointed face and small
-- feet. In pose two it lifts its snout to sniff and takes a step.
function Ground.hedgehog(c, second)
    local dome, ticks = { { 8, 54 } }, {}
    for k = 0, 30 do
        local a = math.rad(180 - k * 5.4)
        local r = (k % 2 == 0 and 44 or 39) * (second and 1.02 or 1)
        dome[#dome + 1] = { 46 + r * math.cos(a) * .98, 54 - r * math.sin(a) * .98 }
    end
    dome[#dome + 1] = { 82, 54 }
    for _r, ring in ipairs({ { 31, 9 }, { 21, 7 }, { 11, 4 } }) do
        for k = 1, ring[2] do
            local a = math.rad(172 - k * 150 / ring[2])
            local x, y = 46 + ring[1] * math.cos(a), 54 - ring[1] * math.sin(a)
            ticks[#ticks + 1] = string.format("M%s %s l-4 -5 M%s %s l2 -6", n(x), n(y), n(x), n(y))
        end
    end
    local face = path("M76 31 C89 32 101 42 106 48 C105 52 99 55 91 55 L72 55 C69 46 71 36 76 31Z", c.cream, c.ink, 1.6) .. circle(105.5, 48.5, 2.8, c.ink)
        .. circle(90, 42, 2.2, c.ink) .. ellipse(79, 35, 4.6, 5.6, -10, c.bloom2, c.ink, 1.3) .. line("M96 53 Q100 52 103 50", c.ink, 1)
    local step = second and 5 or 0
    local feet = ellipse(24 + step, 58, 5.4, 3.2, 0, c.bloom2, c.ink, 1.3) .. ellipse(40 - step, 58, 5.4, 3.2, 0, c.bloom2, c.ink, 1.3) .. ellipse(64 + step, 58, 5.4, 3.2, 0, c.bloom2, c.ink, 1.3)
        .. ellipse(80 - step * .6, 58, 5.4, 3.2, 0, c.bloom2, c.ink, 1.3)
    return feet .. path(Svg.poly(dome, true), c.muted, c.ink, 1.6) .. line(table.concat(ticks, " "), c.ink, 1.1)
        .. path("M14 54 C30 50 60 50 78 54 C60 58 30 58 14 54Z", c.cream, c.ink, 1.2) .. about(76, 46, second and -16 or 0, face)
end

-- One leg of the fox through the given points, with its black sock.
local function leg(c, way)
    local pts = Svg.spline(way, 8)
    local sock = {}
    for i = math.floor(#pts * .5), #pts do sock[#sock + 1] = pts[i] end
    return Svg.stem(pts, Svg.taper(8, 4.2), c.bloom, c.ink, 1.4) .. Svg.stem(sock, Svg.taper(5.6, 4.2), c.ink, c.ink, 1)
end

-- Red fox: pointed muzzle, black-backed ears and socks, a white bib and a
-- white tip to its brush. In pose two it lowers its head and strides on.
function Ground.fox(c, second)
    local tail = about(32, 40, second and -24 or 0, path("M34 36 C20 32 6 42 4 56 C4 64 9 70 15 68 C22 62 32 52 42 46Z", c.bloom, c.ink, 1.6)
        .. path("M4 56 C4 64 9 70 15 68 C17 62 14 56 10 52 C7 52 5 54 4 56Z", c.cream, c.ink, 1.2))
    local head = path("M98 20 L97 7 L106 16Z", c.ink, c.ink, 1.5) .. path("M104 18 L108 4 L115 17Z", c.bloom, c.ink, 1.5) .. path("M107 16 L108.6 8 L112 16Z", c.ink)
        .. path("M82 34 C88 26 94 20 100 16 C106 13 113 15 115 21 L126 29 C127 31 125 33 122 33 L111 35 C105 38 100 44 98 52 C92 52 84 46 82 34Z", c.bloom, c.ink, 1.6)
        .. path("M122 33 L111 35 C105 38 100 44 98 52 C94 48 95 40 101 34 C107 31 116 31 122 33Z", c.cream, c.ink, 1.1)
        .. circle(125.6, 30, 2.2, c.ink) .. path("M108 22 Q111 20 113 23 Q110 24 108 22Z", c.ink) .. line("M118 33 Q114 34 112 33", c.ink, .9)
    local legs = second and (leg(c, { { 44, 48 }, { 34, 60 }, { 28, 72 } }) .. leg(c, { { 86, 48 }, { 80, 60 }, { 74, 72 } }))
        or (leg(c, { { 44, 48 }, { 50, 60 }, { 46, 72 } }) .. leg(c, { { 86, 48 }, { 90, 60 }, { 92, 72 } }))
    local near = second and (leg(c, { { 40, 48 }, { 50, 58 }, { 54, 72 } }) .. leg(c, { { 90, 48 }, { 96, 60 }, { 100, 72 } }))
        or (leg(c, { { 40, 48 }, { 32, 60 }, { 36, 72 } }) .. leg(c, { { 90, 48 }, { 84, 60 }, { 82, 72 } }))
    return tail .. legs .. near .. path("M32 38 C44 28 72 28 90 32 C99 35 100 46 95 52 C84 58 56 57 40 55 C30 52 27 44 32 38Z", c.bloom, c.ink, 1.6)
        .. path("M48 55 C60 57 78 57 92 53 C80 52 62 52 48 55Z", c.cream, c.ink, 1) .. about(88, 36, second and 26 or 0, head)
end

-- The train of the peafowl: feathers with eyes at the given places, their
-- quills running back to the rump at (rx, ry).
local function train(c, rx, ry, eyes)
    local out = ""
    for _i, e in ipairs(eyes) do
        out = out .. line(string.format("M%s %s L%s %s", n(rx), n(ry), n(e[1]), n(e[2])), c.stem, 1.4)
            .. group(e[1], e[2], math.deg(math.atan2(-(rx - e[1]), ry - e[2])), ellipse(0, 0, 4.6, 6, 0, c.gold, c.ink, 1) .. ellipse(0, .6, 3, 3.8, 0, c.glass) .. ellipse(0, 1.6, 1.6, 1.9, 0, c.ink))
    end
    return out
end

-- Indian peafowl: a blue neck and crest, a barred wing and a long train of
-- eyed feathers, trailing on the ground or raised into a fan in pose two.
function Ground.peacock(c, second)
    local tail
    if second then
        local fan, eyes = { { 98, 54 } }, {}
        for a = -96, 12, 9 do fan[#fan + 1] = { Svg.pol(50 + (a % 18 == 0 and 2 or 0), a, 98, 54) } end
        for _i, e in ipairs({ { -84, 40 }, { -58, 41 }, { -32, 41 }, { -6, 40 }, { -72, 24 }, { -45, 25 }, { -18, 24 } }) do eyes[#eyes + 1] = { Svg.pol(e[2], e[1], 98, 54) } end
        tail = path(Svg.poly(fan, true), c.leaf, c.ink, 1.6) .. train(c, 98, 54, eyes)
    else
        tail = path("M96 44 C72 40 32 52 6 66 C3 74 9 81 20 81 C50 79 82 68 98 58Z", c.leaf, c.ink, 1.6)
            .. train(c, 96, 50, { { 15, 73 }, { 30, 63 }, { 38, 75 }, { 50, 56 }, { 58, 68 }, { 72, 51 }, { 78, 62 } })
    end
    return tail .. line("M106 62 L104 81 M114 61 L117 81 M104 81 L98 82 M104 81 L110 82 M117 81 L111 82 M117 81 L123 82", c.ink, 1.6)
        .. Svg.stem(Svg.spline({ { 116, 50 }, { 128, 38 }, { 124, 26 }, { 130, 16 } }, 8), Svg.taper(13, 5.4), c.glass, c.ink, 1.5)
        .. ellipse(108, 51, 20, 12.5, -10, c.glass, c.ink, 1.6) .. path("M92 48 C98 42 112 42 120 48 C114 58 100 60 92 48Z", c.cream, c.ink, 1.3)
        .. line("M98 48 q3 3 6 0 M105 47 q3 3 6 0 M101 52 q3 3 6 0 M109 51 q3 3 6 0", c.ink, 1)
        .. line("M130 10 L126 2 M131 10 L130 1 M132 10 L134 2 M133 11 L138 4", c.ink, 1) .. circle(126, 2, 1.4, c.glass) .. circle(130, 1.4, 1.4, c.glass) .. circle(134, 2, 1.4, c.glass) .. circle(138, 4, 1.4, c.glass)
        .. circle(131.5, 14.5, 5.4, c.glass, c.ink, 1.5) .. line("M129 12 Q132 10 135 12 M129 17 Q132 18 134 17", c.cream, 1.4) .. circle(132.6, 14, 1.2, c.ink)
        .. path("M136 13 L143 16 L136 17.5Z", c.pale, c.ink, 1)
end

return Ground
