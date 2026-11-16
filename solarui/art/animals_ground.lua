-- The garden's animals that walk or creep, each in the units of its own place
-- and facing right: garden snail, robin, hedgehog, red fox and peafowl. Each
-- takes the colours and whether it is in its second pose, and returns SVG.

local Asleep = require("solarui/art/asleep")
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
-- is in flight: the same bird tipped level, legs tucked, both wings raised and
-- the tail spread.
-- The robin asleep: fluffed round against the cold on one leg, the head
-- turned back with the bill tucked into the feathers of its back, the eye
-- shut and the short tail angled down.
local function robinAsleep(c, brown, dark, orange)
    local legc = mix(c.bloom2, c.muted, .5)
    local fluff = {}
    for k = 0, 6 do fluff[#fluff + 1] = string.format("M%s %s q3 2 6 0", n(48 + k * 4), n(58 + (k % 2) * 3)) end
    return line("M64 68 L64 77", c.ink, 2.4) .. line("M64 68 L64 77", legc, 1) .. line("M64 77 L58 77.6 M64 77 L70 77.6", c.ink, 1.3)
        .. path("M44 54 L22 62 L24 67.6 L46 60Z", dark, c.ink, 1.5)
        .. ellipse(64, 47, 26, 23, 0, brown, c.ink, 1.8)
        .. path("M71 26 C85 28 92 39 91 50 C90 61 82 68 70 70 C80 60 82 38 71 26Z", orange, c.ink, 1.1)
        .. path("M52 66 C60 71.6 74 71.6 82 66 C74 69 60 69 52 66Z", c.cream, c.ink, .9) .. line(table.concat(fluff, " "), mix(brown, c.ink, .35), .8)
        .. path("M42 44 C49 35 62 37 67 47 C63 58 52 62 43 58 C40 54 40 48 42 44Z", dark, c.ink, 1.4) .. line("M50 42 C55 46 56 52 53 58 M45 47 C48 50 48 54 46 57", c.ink, .8)
        .. circle(71, 28, 11.5, brown, c.ink, 1.6) .. path("M75 19 C81 21.6 83 29 79.6 35 C76 37.6 72 37 69.6 34.4 C73.6 31 75 25 75 19Z", orange, c.ink, 1)
        .. Asleep.eye(c, 68, 27, 4.4) .. path("M61.4 29.6 L55 32 L61 33.6Z", c.ink, c.ink, .8)
        .. Asleep.zs(c, 84, 14, 7)
end

function Ground.robin(c, second, name)
    local brown, dark = c.muted, mix(c.muted, c.ink, .25)
    local orange, grey = mix(c.bloom, c.gold, .2), mix(c.sky, c.muted, .45)
    if name == "sleep" then return robinAsleep(c, brown, dark, orange) end
    local tail = path("M49 50 L21 61 L23 67 L51 57Z", dark, c.ink, 1.5) .. line("M46 53 L24 63", c.ink, .8)
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
    if not second then return legs .. tail .. body .. wing .. breast .. belly .. face end
    -- a spread wing from the shoulder at the origin, reaching up and back, its flight feathers fingered at the tip
    local function spread(fill)
        return path("M2 2 C0 -8 -6 -20 -16 -30 C-19 -32.6 -23 -31.6 -22 -28.4 C-25.6 -29 -27.6 -25.6 -24.6 -23.6 C-27.6 -23 -28.4 -19.4 -25.4 -18.2 C-27.4 -16.6 -26.6 -13.4 -23.4 -13.4 C-19 -8 -12 -2 -4 4Z", fill, c.ink, 1.4)
            .. line("M-2 -2 C-8 -10 -13 -18 -18 -26 M-5 0 C-11 -7 -16 -13 -21 -18 M-8 2 C-13 -3 -17 -7 -21 -11", c.ink, .8)
    end
    local fan = path("M49 50 L22 56 L20 62 L24 67 L51 57Z", dark, c.ink, 1.5) .. line("M47 53 L23 61.6 M47 55 L22 57.4 M48 55 L24 65", c.ink, .8)
    local tucked = line("M68 64 L62 67 M74 64 L68 67.6", c.ink, 2.2) .. line("M68 64 L62 67 M74 64 L68 67.6", legc, .9)
    return group(62, 36, -14, spread(mix(dark, c.ink, .2)), 1) .. about(70, 52, 22, fan .. tucked .. body .. breast .. belly .. face) .. group(70, 39, 6, spread(dark), 1.12)
end

-- European hedgehog trundling to the right: a low mound of spines, dark
-- with pale tips and lying back towards the rump, a shaggy fringe of brown
-- fur beneath, a brown face with a tapering snout, a black nose, a bead of an
-- eye and a small round ear tucked at the edge of the spines, and short legs
-- with clawed feet. In pose two it lifts its snout to sniff and takes a step.
-- The hedgehog asleep, tucked into a round ball: the spines lie back from
-- the brow over the whole of the back, a fringe of fur shows along the
-- bottom, and the small face rests low at the front with the eye shut, the
-- snout on the ground and the feet drawn in under the chin. In winter the
-- ball lies deep in a nest of fallen leaves, heaped behind and in front
-- with a few on top, for the long sleep.
local function hedgehogAsleep(c, winter, spine, tip, fur)
    local cx, cy, rx, ry = 50, 37.6, 30, 24
    local function at(deg, k) local a = math.rad(deg); return cx + rx * k * math.cos(a), cy - ry * k * math.sin(a) end
    -- the spiny edge from the brow over the back and round under the rump, closed along the belly
    local edge = {}
    for k = 0, 50 do
        local x, y = at(-24 + k * 5.2, k % 2 == 0 and .95 or 1.07)
        edge[#edge + 1] = { x, y }
    end
    local ball = {}
    for i, p in ipairs(edge) do ball[i] = p end
    for k = 0, 8 do ball[#ball + 1] = { at(240 + k * 12, .8) } end
    -- the spines, each lying away from the face
    local dark, pale = {}, {}
    local fx, fy = 80, 60
    for row = 0, 8 do
        for col = 0, 12 do
            local x, y = 17 + col * 5.6 + (row % 2) * 2.8, 19 + row * 4.6
            local ex, ey = (x - cx) / (rx * .9), (y - cy) / (ry * .88)
            local gx, gy = (x - 70) / 15, (y - 53) / 13
            if ex * ex + ey * ey < 1 and gx * gx + gy * gy > 1 and y < 56 then
                local dx, dy = x - fx, (y - fy) * 1.5
                local len = math.sqrt(dx * dx + dy * dy)
                dx, dy = dx / len * 5.6, dy / len * 5.6
                local x0, y0 = x - dx * .4, y - dy * .4
                local xm, ym = x + dx * .3, y + dy * .3
                dark[#dark + 1] = string.format("M%s %sL%s %s", n(x0), n(y0), n(xm), n(ym))
                pale[#pale + 1] = string.format("M%s %sL%s %s", n(xm), n(ym), n(x + dx * .6), n(y + dy * .6))
            end
        end
    end
    -- the fur along the bottom of the ball, a shaggy fringe
    local skirt = {}
    for k = 0, 16 do skirt[#skirt + 1] = { at(226 + k * 6.4, k % 2 == 0 and 1.02 or .95) } end
    for k = 0, 8 do skirt[#skirt + 1] = { at(328 - k * 12.6, .72) } end
    local feet = ellipse(70, 60.6, 4.2, 1.9, 0, spine, c.ink, 1.1) .. line("M71.4 60.2 l0 1.4 M73 60.4 l0 1.2", c.ink, .7)
        .. ellipse(80.4, 60.8, 3.8, 1.8, 0, spine, c.ink, 1.1) .. line("M81.6 60.4 l0 1.4 M83 60.6 l0 1.2", c.ink, .7)
    local face = path("M66 45 C70 40.6 78 40 84 44 C89 47.4 93.6 52 96.4 56 C97.6 58 96.6 60 94.4 60 C88 60.4 80 60 74 58 C68 56 64.6 50 66 45Z", fur, c.ink, 1.5)
        .. ellipse(96, 57.6, 2.3, 2, 20, c.ink) .. line("M88 59.6 Q91 59.6 93.4 58.6", c.ink, .8)
        .. line("M79.6 50.6 q2.6 2.4 5.4 .4", c.ink, 1.2)
    local ear = ellipse(73.4, 44.6, 3.2, 3.6, -30, mix(c.bloom2, c.muted, .4), c.ink, 1.1)
    local hog = path(Svg.poly(skirt, true), fur, c.ink, 1.1) .. group(-4, 0, 0, feet)
        .. path(Svg.poly(ball, true), spine) .. line(Svg.poly(edge), c.ink, 1.6) .. line(table.concat(dark, " "), c.ink, 1.3) .. line(table.concat(pale, " "), tip, 1.4)
        .. group(-4, 0, 0, face .. ear)
    if not winter then
        return Asleep.leaf(c, 1, 20, 61.6, -172, 14) .. Asleep.leaf(c, 4, 100, 62.4, -8, 11) .. hog
            .. Asleep.leaf(c, 3, 34, 62.6, -178, 13) .. Asleep.zs(c, 86, 30, 7)
    end
    local back, front = {}, {}
    -- the heap behind: leaves lying along the round of the ball from side to side
    for i = 0, 13 do
        local deg = 200 - i * 17
        local x, y = at(deg, i % 2 == 0 and 1.06 or .94)
        local lie = math.deg(math.atan2(ry * math.cos(math.rad(deg)), rx * math.sin(math.rad(deg))))
        back[#back + 1] = Asleep.leaf(c, i, x, math.min(y, 60), lie + (i % 2 == 0 and -14 or 10), 17 + (i % 3) * 2)
    end
    -- the leaves pulled up in front, lying low, and one fallen on top
    for i, l in ipairs({ { 0, 61, -16, 18 }, { 109, 61, -164, 18 }, { 8, 55, 8, 19 }, { 50, 51, 172, 18 }, { 16, 49, 14, 16 }, { 28, 62.6, -6, 19 }, { 64, 62.4, -176, 17 },
        { 38, 57.6, 6, 17 }, { 100, 62.8, -178, 13 }, { 34, 24, 16, 14 } }) do
        front[#front + 1] = Asleep.leaf(c, i + 2, l[1], l[2], l[3], l[4])
    end
    return table.concat(back) .. hog .. table.concat(front) .. Asleep.zs(c, 92, 24, 7)
end

function Ground.hedgehog(c, second, name)
    local spine, tip, fur = mix(c.muted, c.ink, .35), mix(c.cream, c.pale, .3), mix(c.muted, c.cream, .48)
    if name == "sleep" or name == "winter" then return hedgehogAsleep(c, name == "winter", spine, tip, fur) end
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

-- One leg of the fox through the joints in `way`, as wide at each as `ws`
-- says: the top is part of the body (no line across it, the edges inked from
-- `a` and `b` of the way down), the lower part in its black stocking, ending
-- in a small paw. `far` legs are a shade darker; `down` turns the paw of a
-- lifted leg to hang.
local function foxLeg(c, way, ws, far, a, b, down)
    local pts = Svg.spline(way, 8)
    local w = Svg.widths(ws)
    local from = (#way - 2) / (#way - 1)
    local sock = {}
    for i = math.floor(#pts * from) + 1, #pts do sock[#sock + 1] = pts[i] end
    local tip = way[#way]
    local red = far and mix(c.bloom, c.ink, .28) or c.bloom
    return Svg.limb(pts, w, red, c.ink, 1.4, a or 0, b or a or 0)
        .. Svg.stem(sock, function(t) return w(from + t * (1 - from)) end, c.ink, c.ink, 1)
        .. (down and ellipse(tip[1] + .4, tip[2] + 1, 2.2, 2.8, 20, c.ink) or ellipse(tip[1] + 1.8, tip[2] - .2, 3.6, 1.9, 0, c.ink))
end

-- The fox's haunch: the round of the thigh about (x, y), rx by ry and
-- turned by `rot`, in the body's own red, inked all round but for the top,
-- which melts into the back. The shin drawn over it grows out of it.
local function haunch(c, x, y, rx, ry, rot)
    local arc = {}
    local cr, sr = math.cos(math.rad(rot)), math.sin(math.rad(rot))
    for i = 0, 24 do
        local a = math.rad(-66 + i * 11.4)
        local px, py = rx * math.cos(a), ry * math.sin(a)
        arc[#arc + 1] = { x + px * cr - py * sr, y + px * sr + py * cr }
    end
    return ellipse(x, y, rx, ry, rot, c.bloom) .. line(Svg.poly(arc), c.ink, 1.4)
end

-- The fox's brush along `way`: full in the middle, the last third white.
-- With `a` and `b` its root has no line (see Svg.limb), to grow out of the body under it.
local function foxBrush(c, way, w, a, b)
    local pts = Svg.spline(way, 10)
    local width = function(t) return math.max(1, w * math.sin(math.pi * (.1 + .9 * t)) ^ .6) end
    local tip = {}
    local from = .7
    for i = math.floor(#pts * from) + 1, #pts do tip[#tip + 1] = pts[i] end
    return (a and Svg.limb(pts, width, c.bloom, c.ink, 1.6, a, b) or Svg.stem(pts, width, c.bloom, c.ink, 1.6)) .. Svg.stem(tip, function(t) return width(from + t * (1 - from)) end, c.cream, c.ink, 1.3)
end

-- The fox's head in profile, facing right, its crown at (x, y), turned by
-- `rot` and `s` times its size (a negative `sx` faces it left): the far ear
-- black, the near ear red with a black tip and a pale inside, a narrow
-- muzzle with a black nose, white along the jaw and the cheek ruff, and an
-- amber eye, shut when `asleep`. The nape and throat have no line: the head
-- grows out of the neck drawn under it, which must reach (-11.5, 2.9) and
-- the tip of the ruff at (-2.4, 31).
local function foxHead(c, x, y, rot, asleep, sx, s)
    local far = path("M-4 2 C-3.4 -3.6 -.8 -7.4 2.8 -9.8 C5 -7 6 -3.6 6 .8Z", c.ink, c.ink, 1.5)
    local near = path("M-11.5 5.3 C-11.5 -1.2 -9.1 -6.5 -5.3 -9.6 C-1.9 -6.2 0 -2.4 .5 1.7Z", c.bloom)
        .. path("M-9.4 -3.8 C-8.2 -6.2 -6.7 -8.2 -5.3 -9.6 C-3.6 -7.9 -2.4 -6 -1.4 -4.1 C-4.1 -5 -6.7 -5 -9.4 -3.8Z", c.ink)
        .. path("M-8.4 3.1 C-8.2 -.5 -7.2 -3.1 -5.5 -5 C-3.8 -2.9 -2.9 -.7 -2.4 1.9Z", c.cream)
        .. line("M-11.5 5.3 C-11.5 -1.2 -9.1 -6.5 -5.3 -9.6 C-1.9 -6.2 0 -2.4 .5 1.7", c.ink, 1.6)
    local edge = "M-11.5 2.9 C-9 .5 -4 -.7 0 0 C4.1 .7 6.7 3.4 8.4 6.5 L20.9 13.7 C23.5 14.9 24 17.5 22.1 18.7 C17.5 20.4 12.7 22.1 8.4 22.8 C5.5 23.5 3.1 24.7 1.2 26.4 L-2.4 31"
    local white = "M22.1 18.7 C17.5 20.4 12.7 22.1 8.4 22.8 C5.5 23.5 3.1 24.7 1.2 26.4 L-2.4 31 C-4.2 30.7 -5.9 29.8 -7.4 28.4 C-8.6 27.4 -9.6 26.2 -10.3 25.1 C-10 24.2 -9.4 23.4 -8 22.6 C-4 20.2 5 17.9 11.6 16.9"
        .. " C15.6 16.3 19.6 16.1 22.4 16.1 C23.2 17.1 23 17.9 22.1 18.7Z"
    local eye = asleep and line("M2 10.2 q3.2 2.4 6.4 -.2", c.ink, 1.3)
        or (path("M1.7 10.3 C3.4 7.7 6.7 7 9.1 8.2 C7.4 10.6 4.3 11.3 1.7 10.3Z", c.gold, c.ink, 1.2) .. ellipse(5.8, 9.2, 1, 1.6, 0, c.ink))
    return group(x, y, rot, far .. path(edge .. " C-8 30 -14 22 -14 14 C-14 10 -13.4 6 -11.5 2.9Z", c.bloom) .. path(white, c.cream) .. line(edge, c.ink, 1.6)
        .. near .. eye .. ellipse(22.1, 16.3, 2.4, 2.2, 0, c.ink) .. line("M20.4 19 C16.8 20.4 13.7 20.9 10.8 20.6", c.ink, 1), sx or 1, s or math.abs(sx or 1))
end

-- Red fox walking to the right: a slender body on long legs in black
-- stockings, the shoulders and haunches part of the body, a narrow pointed
-- muzzle, tall ears with black backs, an amber eye, a white muzzle, throat
-- and chest, and a long full brush held low with a white tip. Poses one and
-- two are two steps of the slow walk: in the second a forepaw is lifted,
-- the hind legs have changed places and the brush has swung up a little.
local function foxWalk(c, second)
    local body = "M40 33 C46 27.6 56 27 64 28.4 C72 29.6 79 28.6 84 25.6 C87.6 23.4 90.4 18.4 92.9 14.4 L100 26 L102 42.5"
        .. " C100.4 44 99.6 46 99.4 48.6 C99.2 52 96.6 54.6 92 54.6 C84 54.4 74 51.6 64 49.6 C58 48.6 54 48.4 50 49.6 C47 50.6 43.4 47.6 41 43 C39.6 40 39.4 36 40 33Z"
    local white = "M94.1 36.6 L102 42.5 C100.4 44 99.6 46 99.4 48.6 C99.2 52 96.6 54.6 92 54.6 C91.4 48 91.6 40 94.1 36.6Z"
    local brush = second and { { 44, 35 }, { 31, 34 }, { 17, 39 }, { 5, 49 } } or { { 44, 35 }, { 32, 37 }, { 18, 46 }, { 7, 59 } }
    local hindW, shinW, foreW = { 15, 10, 5, 4.2 }, { 11, 5.4, 4.2 }, { 11, 7, 4.6, 4 }
    local legs, near
    if second then
        legs = foxLeg(c, { { 49, 40 }, { 50, 52 }, { 41, 62 }, { 37, 72.2 } }, hindW, true)
            .. foxLeg(c, { { 84, 40 }, { 84.6, 50 }, { 85.4, 61 }, { 86, 72.2 } }, foreW, true)
        near = haunch(c, 51.6, 43, 10.6, 12.4, -24) .. foxLeg(c, { { 56, 49 }, { 50.6, 61.6 }, { 53.6, 72.2 } }, shinW, false, .28, .2)
            .. foxLeg(c, { { 88, 38 }, { 90, 49 }, { 98, 55.6 }, { 96.4, 64 } }, foreW, false, .45, .3, true)
    else
        legs = foxLeg(c, { { 50, 40 }, { 59, 51 }, { 53, 62 }, { 56, 72.2 } }, hindW, true)
            .. foxLeg(c, { { 84, 40 }, { 81, 50 }, { 76.6, 61 }, { 74, 72.2 } }, foreW, true)
        near = haunch(c, 50, 43, 9.8, 12.4, 8) .. foxLeg(c, { { 51, 49 }, { 42, 61.6 }, { 38, 72.2 } }, shinW, false, .3, .28)
            .. foxLeg(c, { { 88, 38 }, { 89, 49 }, { 90.6, 61 }, { 91.6, 72.2 } }, foreW, false, .45, .3)
    end
    return legs .. path(body, c.bloom, c.ink, 1.6) .. path(white, c.cream) .. path(body, nil, c.ink, 1.6)
        .. foxBrush(c, brush, 18, .1, .22) .. near .. foxHead(c, 104.4, 11.5, 0)
end

-- The fox asleep by day in the classic curl: the back a round mound, the
-- haunch drawn up, the head brought round to lie along the ground with the
-- eye shut, and the brush wrapped round the front with its white tip laid
-- over the nose.
local function foxAsleep(c)
    local body = "M18 63 C14 44 34 27 60 26.4 C80 26 98 33 105 46 C109.6 55 108 66 102 72.4 L28 72.4 C22 71.4 19 68 18 63Z"
    return path(body, c.bloom, c.ink, 1.7)
        .. line("M33 70 C29 57 39 47 53 47 C60 47 65.6 50 68 55", c.ink, 1.3) .. line("M40 36 C50 31.6 62 30.6 72 32", mix(c.bloom, c.ink, .3), 1)
        .. foxHead(c, 87, 38, 3, true, -1.08)
        .. foxBrush(c, { { 27, 52 }, { 22, 62 }, { 38, 65.4 }, { 58, 63 }, { 72, 55 } }, 15, .12, .36)
        .. Asleep.zs(c, 104, 22, 8)
end

-- The fox in winter, awake and alert: sitting upright in the snow with the
-- ears pricked, the forelegs straight under the white chest and the brush
-- brought round over the paws, while the snow falls.
local function foxWinter(c)
    local body = "M70.5 14.4 C63 21 54 32 49 44 C44.6 55 44 65 49 72.4 L84 72.4 L85.6 54 C85.4 49 83 45.4 79.6 42.5 L78 26Z"
    local white = "M71.7 36.6 L79.6 42.5 C83 45.4 85.4 49 85.6 54 C82 53.6 78.6 51.4 76.4 48 C74 44.6 72 40.6 71.7 36.6Z"
    local snow = mix(c.cream, c.sky, .12)
    local flakes = ""
    for i, f in ipairs({ { 30, 14 }, { 44, 28 }, { 22, 42 }, { 104, 10 }, { 113, 36 }, { 100, 50 }, { 34, 56 }, { 58, 8 } }) do
        flakes = flakes .. circle(f[1], f[2], i % 2 == 0 and 1.5 or 1.9, snow, c.ink, .6)
    end
    return foxLeg(c, { { 77.6, 46 }, { 77.4, 54 }, { 77.4, 63 }, { 77.8, 72.2 } }, { 8, 6, 4.8, 4.2 }, true)
        .. path(body, c.bloom, c.ink, 1.6) .. path(white, c.cream) .. path(body, nil, c.ink, 1.6)
        .. haunch(c, 58.6, 59.6, 13, 12.6, -14)
        .. foxLeg(c, { { 81.6, 50 }, { 82.4, 58 }, { 83, 65 }, { 83.4, 72.2 } }, { 8.4, 6.6, 5, 4.4 }, false, .22, .12)
        .. foxHead(c, 82, 11.5, 0)
        .. foxBrush(c, { { 52, 56 }, { 45, 64 }, { 56, 68 }, { 72, 66.4 } }, 12, .12, .4)
        .. path("M30 74.6 C40 71.4 50 72.6 60 72 C72 71.2 84 73 96 71.4 C102 70.6 108 72 113 74.6Z", snow) .. line("M30 74.6 C40 71.4 50 72.6 60 72 C72 71.2 84 73 96 71.4 C102 70.6 108 72 113 74.6", c.ink, 1.1)
        .. flakes
end

function Ground.fox(c, second, name)
    if name == "sleep" then return foxAsleep(c) end
    if name == "winter" then return foxWinter(c) end
    return foxWalk(c, second)
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
