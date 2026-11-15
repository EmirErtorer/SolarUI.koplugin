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

-- One slim leg of the fox through the given points, the lower part in its
-- black stocking, ending in a small paw; `far` legs are drawn a shade darker.
local function leg(c, way, far)
    local pts = Svg.spline(way, 8)
    local sock = {}
    for i = math.floor(#pts * .55), #pts do sock[#sock + 1] = pts[i] end
    local tip = way[#way]
    return Svg.stem(pts, Svg.taper(6.4, 3.4), far and mix(c.bloom, c.ink, .25) or c.bloom, c.ink, 1.3) .. Svg.stem(sock, Svg.taper(4.4, 3.4), c.ink, c.ink, 1)
        .. ellipse(tip[1] + 1.6, tip[2] + .6, 3.4, 1.8, 0, c.ink)
end

-- Red fox walking to the right: a slender body on long legs in black
-- stockings, a narrow pointed muzzle, tall black-backed ears, an amber eye,
-- white cheeks, throat and bib, and a long full brush held low with a white
-- tip. In pose two it lowers its head and the legs swap their stride.
function Ground.fox(c, second)
    local tail = about(40, 40, second and -10 or 0, path("M41 37 C30 35 16 43 8 55 C3.6 62 6 68.6 12 68.4 C20 67 31 57 43 47Z", c.bloom, c.ink, 1.6)
        .. path("M8 55 C3.6 62 6 68.6 12 68.4 C14.6 64 13.4 58.6 10.6 54.4 C9.6 54 8.6 54.4 8 55Z", c.cream, c.ink, 1.1)
        .. line("M38 40 C28 41 18 48 12 56", c.ink, .8))
    local head = path("M100 21 L101.4 9 L108 18Z", c.ink, c.ink, 1.4)
        .. path("M104 19 L109.6 7.4 L115 18.6Z", c.bloom, c.ink, 1.5) .. path("M106.6 17.6 L109.4 10.6 L111.6 17.6Z", c.cream) .. line("M109.6 7.4 L115 18.6", c.ink, 2.4)
        .. path("M88 35 C92 28 98 22 104 19 C110 16.6 115.6 18.6 118.4 23 L127.4 29.6 C128.6 31.2 127.4 32.8 125 33 L113.6 35.2 C107.6 37.4 102.6 42.6 100.6 49 C95.6 46.6 91.4 41 88 35Z", c.bloom, c.ink, 1.6)
        .. path("M125 33 L113.6 35.2 C107.6 37.4 102.6 42.6 100.6 49 C98 45 98.6 39.4 103 35.4 C108.6 30.6 117.6 30.8 125 33Z", c.cream, c.ink, 1.1)
        .. circle(126.8, 30.4, 2, c.ink) .. line("M124.6 33 Q120 34.4 116.6 33.6", c.ink, .9)
        .. ellipse(112.4, 25.2, 2.4, 1.5, -18, c.gold, c.ink, .9) .. line("M112.6 24 L112.2 26.4", c.ink, 1)
    local stride = second and -1 or 1
    local farlegs = leg(c, { { 52, 40 }, { 47 - 3 * stride, 58 }, { 50 - 5 * stride, 72 } }, true)
        .. leg(c, { { 91, 40 }, { 92 + 3 * stride, 57 }, { 94 + 6 * stride, 72 } }, true)
    local nearlegs = leg(c, { { 47, 40 }, { 41 + 4 * stride, 58 }, { 45 + 6 * stride, 72 } })
        .. leg(c, { { 95, 40 }, { 95 - 2 * stride, 57 }, { 92 - 6 * stride, 72 } })
    local body = path("M38 42 C40 33 50 30.6 60 31.6 C70 32.6 84 31 95 34 C101 37 103 44 100.6 50 C97 55.4 89 55.6 83 53.6 C73 51.4 63 49.6 55 51.6 C45 54.6 36 50 38 42Z", c.bloom, c.ink, 1.6)
        .. line("M45 38.6 C52 41 55 48 51.6 54 M88.6 37 C93 41 94 47 92 53", c.ink, .9)
        .. path("M100.6 49 C101.6 53 99.6 56 96.4 56.4 C97.4 53 98.6 51 100.6 49Z", c.cream, c.ink, 1)
    return farlegs .. nearlegs .. group(0, -6, 0, tail .. body .. about(92, 38, second and 18 or 0, head))
end

-- One eye of a peacock's train feather at (x, y), pointing away from the
-- rump at `rot` degrees, `k` its size: a bronze-green outer field, a
-- bronze ring, a turquoise ring and a dark blue heart.
local function ocellus(c, x, y, rot, k)
    return group(x, y, rot, ellipse(0, 0, 4.4 * k, 6.2 * k, 0, mix(c.leaf, c.gold, .45), c.ink, .9)
        .. ellipse(0, .8 * k, 3.2 * k, 4.2 * k, 0, mix(c.gold, c.bloom, .35))
        .. ellipse(0, 1.3 * k, 2.4 * k, 3 * k, 0, mix(c.glass, c.sky, .35))
        .. path(string.format("M0 %s C%s %s %s %s 0 %s C%s %s %s %s 0 %sZ", n(-.2 * k), n(1.8 * k), n(.4 * k), n(1.6 * k), n(2.8 * k), n(3.4 * k), n(-1.6 * k), n(2.8 * k), n(-1.8 * k), n(.4 * k), n(-.2 * k)), mix(c.ink, c.violet, .45)))
end

-- The train: a feather from the rump at (rx, ry) to each eye in `eyes`
-- ({ x, y, size }), the far ones first.
local function train(c, rx, ry, eyes)
    local quills, out = {}, ""
    for _i, e in ipairs(eyes) do
        quills[#quills + 1] = string.format("M%s %s L%s %s", n(rx), n(ry), n(e[1]), n(e[2]))
        out = out .. ocellus(c, e[1], e[2], math.deg(math.atan2(-(rx - e[1]), ry - e[2])), e[3] or 1)
    end
    return line(table.concat(quills, " "), mix(c.leaf, c.ink, .3), .8) .. out
end

-- Indian peafowl, the cock, facing right: a slender S of a neck and a breast
-- of deep peacock blue, a small head with white stripes above and below the
-- eye and a crest of bare quills tipped with little fans, a wing barred black
-- and buff with cinnamon flight feathers, a bronze-green scaled back, long
-- grey legs and a long train of eyed feathers trailing on the ground, or in
-- pose two raised behind it into a great fan.
function Ground.peacock(c, second)
    local blue, bronze = mix(c.glass, c.violet, .35), mix(c.leaf, c.gold, .35)
    local tail
    if second then
        local fan, eyes = { { 98, 54 } }, {}
        for a = -100, 14, 6 do fan[#fan + 1] = { Svg.pol(51 + (a % 12 == 0 and 1.6 or 0), a, 98, 54) } end
        for _r, row in ipairs({ { 45, 12, 1 }, { 34, 9, .9 }, { 23, 6, .78 } }) do
            for k = 0, row[2] - 1 do
                local a = -94 + (k + (row[2] % 2 == 0 and .5 or 0)) * 104 / row[2]
                local x, y = Svg.pol(row[1], a, 98, 54)
                eyes[#eyes + 1] = { x, y, row[3] }
            end
        end
        tail = path(Svg.poly(fan, true), bronze, c.ink, 1.6) .. train(c, 98, 54, eyes)
    else
        local eyes = {}
        for k = 0, 9 do
            local x = 10 + k * 8.4
            local top = 62 - k * 1.6
            eyes[#eyes + 1] = { x, top + (k % 2 == 0 and 3.4 or 9.4) - k * .4, 1 - k * .045 }
        end
        tail = path("M96 45 C72 42 36 52 6 66 C2 72 5 80 14 81 C46 80 80 69 98 57Z", bronze, c.ink, 1.6) .. train(c, 97, 50, eyes)
    end
    local legc = mix(c.muted, c.cream, .3)
    local legs = line("M106 61 L104 82 M114 60 L117 82", c.ink, 2.8) .. line("M106 61 L104 82 M114 60 L117 82", legc, 1.2)
        .. line("M104 82 L97.6 83 M104 82 L110 83 M117 82 L111 83 M117 82 L123.4 83", c.ink, 1.4)
    local body = ellipse(108, 50, 20, 12.5, -10, blue, c.ink, 1.6)
        .. path("M90 46 C96 40 108 39 118 43 C116 50 108 56 96 56 C92 54 90 50 90 46Z", mix(c.pale, c.muted, .4), c.ink, 1.3)
        .. line("M95 44 C97 48 97 52 95 55 M100 42 C102 47 102 52 100 56 M105 41 C107 46 107 51 105 55.6 M110 41 C112 45 112 49 110 53", c.ink, 1.1)
        .. path("M90 46 C88 50 88 54 91 56.6 L96 56 C92 54 90 50 90 46Z", mix(c.bloom, c.gold, .35), c.ink, 1)
        .. line("M92 42 q2 -2 4 0 M97 40 q2 -2 4 0", mix(bronze, c.ink, .3), .9)
    local neck = Svg.stem(Svg.spline({ { 112, 50 }, { 126, 39 }, { 123, 26 }, { 130, 16 } }, 8), Svg.taper(13, 5), blue, c.ink, 1.5)
    local crest = line("M129.6 10 L126.6 3 M130.6 9.6 L129.6 2.4 M131.6 9.6 L132.6 2.4 M132.6 10 L135.6 3.2", c.ink, .9)
    for _i, t in ipairs({ { 126.6, 3, -22 }, { 129.6, 2.4, -8 }, { 132.6, 2.4, 8 }, { 135.6, 3.2, 22 } }) do
        crest = crest .. group(t[1], t[2], t[3], ellipse(0, -.6, 1.7, 1.2, 0, mix(c.glass, c.sky, .2), c.ink, .6))
    end
    local head = crest .. circle(131.5, 14.5, 5.2, blue, c.ink, 1.5)
        .. path("M128.4 12.6 Q132 10.2 135.4 12.4 Q132 11.6 128.4 12.6Z", c.cream, c.cream, 1) .. path("M128.6 16.6 Q131.8 18.6 134.6 16.8 Q131.8 17.4 128.6 16.6Z", c.cream, c.cream, 1)
        .. circle(132.4, 14.4, 1.2, c.ink) .. path("M136 13.4 L142.6 15.6 L136 17Z", mix(c.pale, c.muted, .3), c.ink, 1)
    return tail .. legs .. neck .. body .. head
end

return Ground
