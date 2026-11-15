-- The garden's animals that walk or creep, each in the units of its own place
-- and facing right: garden snail, robin, hedgehog, red fox and peafowl. Each
-- takes the colours and whether it is in its second pose, and returns SVG.

local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse

local mix = Wash.mix

local Ground = {}

-- `body` turned by `deg` degrees about (x, y).
local function about(x, y, deg, body)
    return group(x, y, deg, group(-x, -y, 0, body))
end

-- A snail shell's coil about (cx, cy): `r0` from the centre at `a0` degrees,
-- shrinking by `k` each radian over `turns` turns towards the tip, as a line.
local function coil(cx, cy, r0, a0, turns, k)
    local pts = {}
    for i = 0, 72 do
        local t = i / 72 * turns * 2 * math.pi
        local r, a = r0 * math.exp(-k * t), math.rad(a0) - t
        pts[#pts + 1] = { cx + r * math.cos(a), cy + r * math.sin(a) }
    end
    return Svg.poly(pts)
end

-- The pale lip of a snail's shell, a crescent inside the lower right of its
-- outline (the ellipse at (cx, cy), rx by ry, turned by `rot`).
local function lip(c, cx, cy, rx, ry, rot)
    local outer, inner = {}, {}
    local cr, sr = math.cos(math.rad(rot)), math.sin(math.rad(rot))
    for i = 0, 12 do
        local a = math.rad(12 + 64 * i / 12)
        for _j, side in ipairs({ { outer, 1 }, { inner, .84 + .06 * math.sin(math.pi * i / 12) * -1 } }) do
            local x, y = rx * side[2] * math.cos(a), ry * side[2] * math.sin(a)
            table.insert(side[1], { cx + x * cr - y * sr, cy + x * sr + y * cr })
        end
    end
    local pts = {}
    for i = 1, #outer do pts[#pts + 1] = outer[i] end
    for i = #inner, 1, -1 do pts[#pts + 1] = inner[i] end
    return path(Svg.poly(pts, true), c.cream, c.ink, 1)
end

-- Garden snail gliding to the right: a tawny shell with dark brown bands
-- following its whorls and a pale lip where the body comes out, on a long
-- grey-brown foot with grooved skin. The head carries two long eye stalks and
-- one short feeler below. In pose two the head dips and the stalks draw in.
function Ground.snail(c, second)
    local skin, shellc = mix(c.muted, c.cream, .42), mix(c.gold, c.muted, .45)
    local band = mix(shellc, mix(c.ink, c.bloom, .3), .75)
    local top = second and 33 or 24
    local foot = path(string.format("M3 51.5 C9 48.6 18 46.4 30 46 L51 45.4 C56 45.2 58 %s 59.5 %s C61 %s 64 %s 68 %s C72.5 %s 74 %s 72.5 %s C71.5 %s 76 45 76 48.5 C76 51.5 73.5 52.5 69 52.5 L8 52.5 C5 52.5 3 52.2 3 51.5Z",
        n(top + 15), n(top + 9), n(top + 3), n(top), n(top), n(top + .5), n(top + 6), n(top + 11), n(top + 16)), skin, c.ink, 1.6)
        .. line(string.format("M10 50.2 l3 -.6 M18 49.2 l3 -.4 M46 48.6 l3 -.2 M60.5 %s l2 -1.4", n(top + 13)), c.ink, .8)
    local reach = second and { { 65, -3 }, { 67, -6.5 }, { 71, -3 }, { 73.5, -5.5 } } or { { 63.5, -6 }, { 62, -12.5 }, { 70.5, -6 }, { 73, -11.5 } }
    local function stalk(x0, mid, tip)
        local pts = Svg.spline({ { x0, top + 1.5 }, { mid[1], top + mid[2] }, { tip[1], top + tip[2] } }, 6)
        return Svg.stem(pts, Svg.taper(2.8, 1.7), skin, c.ink, 1) .. circle(tip[1], top + tip[2], 1.6, c.ink)
    end
    local horns = stalk(64.5, reach[1], reach[2]) .. stalk(68.5, reach[3], reach[4])
        .. Svg.stem(Svg.spline({ { 72.5, top + 9 }, { 75, top + 9.6 }, { 77, top + 10.8 } }, 4), Svg.taper(2.2, 1.3), skin, c.ink, .9)
    local shell = ellipse(33, 28, 19, 18, -10, shellc, c.ink, 1.8)
        .. line(coil(30.5, 25.5, 12.8, 64, 1.6, .15), band, 2.8)
        .. line(coil(30.5, 25.5, 10.2, 64, 1.4, .15), band, 1.2)
        .. line(coil(30.5, 25.5, 15.6, 64, 1.95, .15), c.ink, 1.3)
        .. lip(c, 33, 28, 19, 18, -10)
    return line("M2 53 L78 53", c.line, 1.6) .. group(second and 1 or -1, 0, 0, horns .. foot .. shell)
end

-- European robin standing on the ground, facing right: a plump upright bird,
-- olive brown above, the orange-red of its face and breast edged with a band
-- of blue-grey, a white belly, a folded wing over the flank, a short tail
-- angled down, a fine dark bill, a big dark eye and thin legs. In pose two it
-- bobs forward with its tail cocked up, the way a robin does.
function Ground.robin(c, second)
    local brown, dark = c.muted, mix(c.muted, c.ink, .25)
    local orange, grey = mix(c.bloom, c.gold, .2), mix(c.sky, c.muted, .45)
    local tail = about(48, 53, second and 46 or 0, path("M49 50 L21 61 L23 67 L51 57Z", dark, c.ink, 1.5) .. line("M46 53 L24 63", c.ink, .8))
    local body = path("M46 53 C44 40 52 28 64 20 C68 12 79 9 86 14 C90 17 92 22 91 28 C96 37 95 51 86 59 C78 66 62 67 54 61 C50 58 47 56 46 53Z", brown, c.ink, 1.8)
    local breast = path("M87 14.5 C90 17 92 22 91 28 C94.4 34 95.2 41.4 93.6 48 C88 52.6 79 54 71 52.6 C70.6 46 71 40 71.5 35 C72 29 73 25 76 21 C78 17 82 14.5 87 14.5Z", orange, c.ink, 1.1)
        .. line("M86 13.6 C80 13 75.4 16.4 73.4 21 C71 26.6 70 32 69.6 38 C69.4 43 69.4 48 70 52.4", grey, 2.6)
    local belly = path("M93.6 48 C92 52.6 89.6 56.4 86 59 C78 66 62 67 54 61 C60 59.4 65.6 55.6 70 52.4 C78 54.2 87.6 52.6 93.6 48Z", c.cream, c.ink, 1.1)
    local wing = path("M61 28 C71 30 75 40 71 50 C65 56 53 58 41 57.6 C47 50 53 40 61 28Z", dark, c.ink, 1.4)
        .. line("M63 33 C68 38 68 45 65 51 M57 37 C61 43 60 49 56 54.6 M51 47 C53 51 51 54 48 57", c.ink, .8)
    local face = circle(81, 21, 2.7, c.ink) .. circle(82, 20.2, .8, c.cream) .. path("M90.4 23 L99 25.6 L90.4 27.6Z", c.ink, c.ink, .8)
    local legc = mix(c.bloom2, c.muted, .5)
    local legs = line("M66 64 L64.4 77 M74 64.4 L75.6 77", c.ink, 2.4) .. line("M66 64 L64.4 77 M74 64.4 L75.6 77", legc, 1)
        .. line("M64.4 77 L58.6 77.6 M64.4 77 L69 77.6 M75.6 77 L70.6 77.6 M75.6 77 L81.4 77.6", c.ink, 1.3)
    return legs .. about(70, 66, second and 14 or 0, tail .. body .. wing .. breast .. belly .. face)
end

-- European hedgehog trundling to the right: a low mound of spines, dark
-- with pale tips and lying back towards the rump, a shaggy fringe of brown
-- fur beneath, a brown face with a tapering snout, a black nose, a bead of an
-- eye and a small round ear tucked at the edge of the spines, and short legs
-- with clawed feet. In pose two it lifts its snout to sniff and takes a step.
function Ground.hedgehog(c, second)
    local spine, tip, fur = mix(c.muted, c.ink, .35), mix(c.cream, c.pale, .3), mix(c.muted, c.cream, .48)
    local cx, cy, rx, ry = 46, 52, 41, 34
    local function at(deg, k) local a = math.rad(deg); return cx + rx * k * math.cos(a), cy - ry * k * math.sin(a) end
    local edge = { { 6, 52 } }
    for k = 0, 44 do
        local x, y = at(184 - k * 4.1 + (k % 2 == 0 and 2.4 or 0), k % 2 == 0 and 1.05 or .93)
        edge[#edge + 1] = { x, y }
    end
    edge[#edge + 1] = { 87, 52 }
    local dark, pale = {}, {}
    for _r, row in ipairs({ { .88, 18 }, { .74, 15 }, { .6, 13 }, { .46, 10 }, { .32, 7 }, { .18, 4 } }) do
        for k = 0, row[2] - 1 do
            local deg = 172 - (k + (row[1] * 10 % 1)) * 158 / row[2]
            local x0, y0 = at(deg, row[1] - .1)
            local x1, y1 = at(deg + 9, row[1] + .1)
            local xm, ym = x0 + (x1 - x0) * .74, y0 + (y1 - y0) * .74
            dark[#dark + 1] = string.format("M%s %sL%s %s", n(x0), n(y0), n(xm), n(ym))
            pale[#pale + 1] = string.format("M%s %sL%s %s", n(xm), n(ym), n(x1), n(y1))
        end
    end
    local skirt = { { 9, 50 } }
    for k = 0, 19 do skirt[#skirt + 1] = { 11 + k * 3.9, 55.4 + (k % 2 == 0 and 1.8 or 0) } end
    skirt[#skirt + 1] = { 86, 50 }
    local face = path("M73 28 C83 28.6 95 37 103.6 43.6 C106.6 45.6 106.6 48.6 103.6 49.8 C97.6 52.8 89 54.4 80 54.4 L71 54.4 C67 44 68 34 73 28Z", fur, c.ink, 1.6)
        .. ellipse(105, 46.6, 2.6, 2.2, 20, c.ink) .. circle(91, 40.4, 2, c.ink) .. circle(91.6, 39.8, .6, c.cream)
        .. line("M97 51 Q100.6 50.4 103 48.8", c.ink, .9)
    local step = second and 4 or 0
    local function foot(x, far)
        local f = far and mix(spine, c.muted, .5) or spine
        return path(string.format("M%s 52 L%s 59.6 L%s 60.4 L%s 52Z", n(x - 2.8), n(x - 3.4), n(x + 3.8), n(x + 2.8)), f, c.ink, 1.2)
            .. line(string.format("M%s 60.4 l1.6 .8 M%s 60.4 l1.6 .8", n(x + 1), n(x + 3)), c.ink, .9)
    end
    local legs = foot(34 - step, true) .. foot(74 - step * .6, true) .. foot(24 + step) .. foot(82 + step)
    return legs .. about(76, 44, second and -14 or 0, face) .. path(Svg.poly(skirt, true), fur, c.ink, 1.1)
        .. path(Svg.poly(edge, true), spine) .. line(Svg.poly(edge), c.ink, 1.6) .. line(table.concat(dark, " "), c.ink, 1.3) .. line(table.concat(pale, " "), tip, 1.4)
        .. ellipse(81.6, 33.4, 3.4, 3.8, -20, mix(c.bloom2, c.muted, .4), c.ink, 1.2)
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
