-- The garden's flying animals, each in the units of its own place and facing
-- right: honey bee, seven-spot ladybird, swallowtail, elephant hawk-moth and
-- emperor dragonfly. Each takes the colours, whether it is in its second
-- pose and the pose's name, and returns SVG: "sleep" is how each one sleeps
-- (never in the air) and "winter" how each one passes the winter.

local Asleep = require("solarui/art/asleep")
local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse

local mix = Wash.mix

local Air = {}

-- `body` turned by `deg` degrees about (x, y).
local function about(x, y, deg, body)
    return group(x, y, deg, group(-x, -y, 0, body))
end

-- `body` and its mirror image across the upright through the origin.
local function both(body)
    return body .. group(0, 0, 0, body, -1, 1)
end

-- An outline of soft fur round an ellipse at (cx, cy): `k` small tufts
-- bulging out from it, filled with `fill`.
local function fuzz(c, cx, cy, rx, ry, k, fill)
    local d = {}
    for i = 0, k do
        local a = 2 * math.pi * i / k
        local x, y = cx + rx * math.cos(a), cy + ry * math.sin(a)
        if i == 0 then d[1] = string.format("M%s %s", n(x), n(y))
        else
            local m = 2 * math.pi * (i - .5) / k
            d[#d + 1] = string.format("Q%s %s %s %s", n(cx + rx * 1.18 * math.cos(m)), n(cy + ry * 1.18 * math.sin(m)), n(x), n(y))
        end
    end
    return path(table.concat(d, " ") .. "Z", fill, c.ink, 1.4)
end

-- A clear insect wing from the origin, `L` long and `W` wide, pointing up,
-- with two veins.
local function clearWing(c, L, W, fill)
    return path(string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s 0 0Z", n(W), n(-L * .22), n(W * 1.05), n(-L * .82), n(W * .15), n(-L), n(-W * .55), n(-L * .96), n(-W * .45), n(-L * .38)), fill, c.ink, 1.2)
        .. line(string.format("M0 %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(-L * .05), n(W * .5), n(-L * .4), n(W * .35), n(-L * .86), n(W * .1), n(-L * .2), n(-W * .1), n(-L * .55), n(-W * .2), n(-L * .8)), c.ink, .7)
end

-- Honey bee in flight seen from the side and a little above, heading right:
-- a dark head with its big compound eye and elbowed antennae, a furry thorax,
-- an amber abdomen banded in brown that hangs a little, two pairs of clear
-- wings and jointed legs, the hind pair carrying pollen. Pose one has the
-- wings raised, pose two has them swept down and the body bobbed lower.
-- The bee asleep, clinging to a straw at the door of the skep, winter or
-- summer night alike: the wings folded flat back over the abdomen, the head
-- bowed, the antennae drooping and the legs drawn in.
local function beeAsleep(c, amber, band, thorax, head, glass, far)
    local abdomen = group(36, 46, -6, ellipse(0, 0, 22, 12.4, 0, amber)
        .. line("M-2 -12 Q-7 0 -2 12 M5 -11.6 Q0 0 5 11.6 M12 -9.8 Q7 0 12 9.8", band, 4.2)
        .. path("M-19 -6 C-24 -3 -24 3 -19 6 C-17 2 -17 -2 -19 -6Z", band) .. ellipse(0, 0, 22, 12.4, 0, nil, c.ink, 1.6))
    local face = about(80, 36, 22, path("M75 27 C81 22 88 24 90 31 C92 39 88 47 83 47 C78 46 74 38 75 27Z", head, c.ink, 1.5)
        .. path("M77.5 26.5 C81 24.5 84.5 27 84.5 33 C84.5 39 82 42.5 79.8 40.5 C77.8 37.5 76.8 31 77.5 26.5Z", c.ink))
    return line("M14 60 Q52 54 96 58", c.ink, 3.4) .. line("M14 60 Q52 54 96 58", c.pale, 1.8)
        .. group(58, 30, -96, clearWing(c, 30, 7, far)) .. abdomen .. line("M56 46 L54 55 M63 47 L63 56 M70 46 L73 55", c.ink, 1.5)
        .. fuzz(c, 63, 38, 12, 11, 16, thorax) .. face .. line("M88.6 30 L95 35.4 L97 44 M87 29.4 L92 35.6 L93.4 44", c.ink, 1.3)
        .. group(61, 30, -102, clearWing(c, 35, 9, glass)) .. Asleep.zs(c, 92, 20, 7)
end

function Air.bee(c, second, name)
    local amber, band = mix(c.gold, c.bloom, .18), mix(c.ink, c.bloom, .25)
    local thorax, head = mix(c.gold, c.muted, .45), mix(c.ink, c.muted, .45)
    local glass, far = mix(c.cream, c.sky, .25), mix(c.cream, c.sky, .55)
    if name == "sleep" or name == "winter" then return beeAsleep(c, amber, band, thorax, head, glass, far) end
    local beat = second and -46 or 0
    local wings_far = about(62, 26, beat, group(62, 26, -30, clearWing(c, 30, 9, far)) .. group(60, 28, -62, clearWing(c, 21, 7, far)))
    local wings_near = about(64, 27, beat, group(64, 27, -44, clearWing(c, 36, 11, glass)) .. group(61, 29, -78, clearWing(c, 25, 8, glass)))
    -- abdomen, tilted down at the back, its bands following the round of the body
    local bands = {}
    for _i, u in ipairs({ -.1, .22, .52 }) do
        local h = 12.4 * math.sqrt(1 - u * u) * .96
        bands[#bands + 1] = string.format("M%s %s Q%s 0 %s %s", n(u * 22), n(-h), n(u * 22 - 5), n(u * 22), n(h))
    end
    local abdomen = group(36, 44, -18, ellipse(0, 0, 22, 12.4, 0, amber)
        .. line(table.concat(bands, " "), band, 4.2)
        .. path("M-19 -6 C-24 -3 -24 3 -19 6 C-17 2 -17 -2 -19 -6Z", band)
        .. ellipse(0, 0, 22, 12.4, 0, nil, c.ink, 1.6)
        .. path("M-22 -1.4 L-28 .4 L-22 1.6Z", c.ink, c.ink, .8))
    local legs = line("M70 40 L73 48 L71 56 M64 42 L63 51 L59 58 M57 41 L50 49 L49 59 M66 41 L68 47 L74 52", c.ink, 1.5)
        .. ellipse(50.5, 53, 3.6, 4.6, 12, mix(c.gold, c.bloom, .5), c.ink, 1.1)
    local face = path("M75 25 C81 20 88 22 90 29 C92 37 88 45 83 45 C78 44 74 36 75 25Z", head, c.ink, 1.5)
        .. path("M77.5 24.5 C81 22.5 84.5 25 84.5 31 C84.5 37 82 40.5 79.8 38.5 C77.8 35.5 76.8 29 77.5 24.5Z", c.ink)
        .. ellipse(80, 27.5, .9, 1.6, -15, c.cream)
        .. line("M87 25 L91 16 L99 13 M85 24 L87 15 L94 10", c.ink, 1.4)
        .. line("M85 44 L87 48", c.ink, 1.6)
    local body = wings_far .. legs .. abdomen .. fuzz(c, 63, 35, 12, 11, 16, thorax)
        .. face .. wings_near
    return group(0, second and 4 or 0, 0, body)
end

-- One wing case of the ladybird seen from the side, hinged at the shield:
-- the red dome in `fill`, with its spots and the light on it when `spots`.
local function wingCase(c, fill, spots)
    local out = path("M12 35 C10 22 20 13 31 13 C40 13 46 19 47 31 C38 36 21 37 12 35Z", fill, c.ink, 1.6)
    if not spots then return out end
    return out .. path("M19 21 C22 17 27 15 31 15.5 C27 17 23 19 21 23Z", mix(fill, c.cream, .6))
        .. line("M43 17 Q30 14 15 29", c.ink, 1.2)
        .. ellipse(31, 16.6, 2.6, 1.5, -8, c.ink) .. ellipse(22, 20, 2.3, 1.5, -30, c.ink)
        .. circle(41.5, 17.6, 2.2, c.ink)
        .. ellipse(36, 26, 3.4, 3, 0, c.ink) .. ellipse(25.5, 28, 3.8, 3.3, 0, c.ink) .. ellipse(17, 30.5, 2.6, 2.4, 0, c.ink)
end

-- Seven-spot ladybird walking along a blade of grass, seen from the side and
-- a little above, heading right: a red domed shell with a light on it, three
-- spots on the near side, two peeping over the top and one where the cases
-- meet, a black shield running on from the dome with a white patch at its
-- front corner, the small head tucked under it with short clubbed antennae,
-- and short jointed legs. In pose two both wing cases are raised, the far one
-- higher, and the clear hind wings reach up and back behind them.
-- The ladybird asleep on its blade of grass: legs drawn in under the shell
-- and the head pulled back under the shield. In winter three of them huddle
-- together under a curled dry leaf, as ladybirds do.
local function ladybugAsleep(c, winter, shield)
    local tucked = ellipse(51.4, 32.6, 2.6, 2.8, -10, c.ink)
    if not winter then return Flora.leaf(c, 0, 46, -4, 60, 5, c.leaf) .. wingCase(c, c.bloom, true) .. tucked .. shield .. Asleep.zs(c, 48, 12, 5) end
    local one = wingCase(c, c.bloom, true) .. tucked .. shield
    local dry = mix(c.gold, c.muted, .38)
    return Asleep.leaves(c, 2, 58, 47, 6, 12) .. group(-2, 22, 0, one, .5) .. group(26, 24, 0, one, .5) .. group(12, 18, 0, one, .48)
        .. Flora.leaf(c, -2, 34, -12, 62, 15, dry) .. Asleep.zs(c, 46, 8, 4)
end

function Air.ladybug(c, second, name)
    local blade = Flora.leaf(c, 0, 46, -4, 60, 5, c.leaf)
    local legs = line("M20 36 L17 40 L14 43.5 M28 37 L28 41 L26 44 M36 36 L39 40 L41 43", c.ink, 1.6)
        .. line("M24 37 L23 41 M33 37 L35 41", c.ink, 1.2)
    local head = ellipse(53.2, 30.6, 3.3, 3.6, -10, c.ink) .. circle(55.2, 31.4, .7, c.cream)
        .. line("M55.4 28 Q57 26.6 58.4 26.8", c.ink, .9) .. ellipse(58.6, 26.9, 1.1, .8, -10, c.ink)
    local shield = path("M43.5 17 C47.5 17 50.8 19.6 51.6 23.6 C52.2 26.8 52 29.6 50.6 31.8 C49 33.2 47.2 33.4 46.4 33 C46.6 27 46 21.4 43.5 17Z", c.ink, c.ink, 1.2)
        .. path("M49.2 23.4 C50.6 23.8 51.4 25.4 51.4 27.6 C51.2 29.4 50.4 30.6 49.6 30.8 C49.2 28.4 49.2 25.6 49.2 23.4Z", c.cream)
    if name == "sleep" or name == "winter" then return ladybugAsleep(c, name == "winter", shield) end
    if second then
        return blade .. legs
            .. about(44, 18, 48, wingCase(c, mix(c.bloom, c.ink, .2), false))
            .. group(39, 23, -86, clearWing(c, 34, 8.5, mix(c.cream, c.sky, .55)))
            .. path("M14 34 C14 26 24 21 34 21 C41 21 46 25 47 31 C38 36 22 37 14 34Z", mix(c.ink, c.bloom, .25), c.ink, 1.4)
            .. group(38, 26, -110, clearWing(c, 33, 9, mix(c.cream, c.sky, .3)))
            .. about(44, 18, 36, wingCase(c, c.bloom, true)) .. head .. shield
    end
    return blade .. legs .. wingCase(c, c.bloom, true) .. head .. shield
end

-- The right pair of a swallowtail's wings seen from above, the body along the
-- upright through the origin and the head up: a yellow forewing with a black
-- base, black bars along its front edge and a black outer band holding a row
-- of yellow spots, and a yellow hindwing with a black band of blue spots, a
-- black tail and a red eye with a blue fleck at its inner corner. Both poses
-- are made of this one drawing, so the wings look the same in each.
local function swallowWings(c)
    local hind = path("M1 0 C10 -1 20 0 25 2 C27 8 25 15 21 20 L16 21 L13 22 C9 22 6 20 4 16 C2 12 1 6 1 0Z", c.pale, c.ink, 1.5)
        .. path("M1 0 C1 6 2 12 4 16 L7.5 14 C5.5 10 4.5 5 4.5 1Z", c.ink)
        .. path("M25 2 C27 8 25 15 21 20 L16 21 C18.5 15 20.5 9 20 3Z", c.ink)
        .. path("M18.6 20.8 Q17.6 25 16.4 29.4 Q15.4 29.8 14.8 29 Q15.6 25 15.8 21.2Z", c.ink, c.ink, 1)
        .. circle(22.6, 7, 1.4, c.sky) .. circle(22, 12, 1.4, c.sky) .. circle(19.4, 16.6, 1.3, c.sky)
        .. circle(9.6, 15, 1.4, c.sky) .. circle(7, 18.4, 2.5, c.bloom, c.ink, 1)
        .. line("M4 2 L21 5 M4 3.5 L19 12 M4.5 5 L15 18", c.ink, .7)
    local fore = path("M1 -6 C10 -18 24 -28 36 -31 C35 -22 31 -9 26 -2 C18 -1 8 -1 2 -1Z", c.pale, c.ink, 1.5)
        .. path("M1 -6 C4 -10 7 -12 10 -14 L7 -1.4 L2 -1Z", c.ink)
        .. path("M36 -31 C35 -22 31 -9 26 -2 L21 -2 C25 -9 28 -20 30 -28.4Z", c.ink)
        .. circle(31.2, -24, 1.3, c.pale) .. circle(29.6, -17.5, 1.3, c.pale) .. circle(27.4, -11, 1.3, c.pale) .. circle(24.6, -5.4, 1.2, c.pale)
        .. line("M13.5 -16.5 L15.5 -10 M19.5 -22 L21.5 -15 M25.5 -26 L26.8 -19.5", c.ink, 2.8)
        .. line("M4 -3 L22 -4 M5 -6 L25 -11 M7 -9 L27 -18 M9 -12 L29 -24", c.ink, .7)
    return hind .. fore
end

-- A swallowtail's body along the upright, head up: a black abdomen striped
-- yellow down its sides, the thorax and the head.
local function swallowBody(c)
    return ellipse(0, 3, 2.7, 11.5, 0, c.ink) .. line("M-1.6 -1 L-1.4 11 M1.6 -1 L1.4 11", c.pale, .7) .. circle(0, -9.5, 2.6, c.ink)
end

-- Swallowtail, the old world kind: basking with its wings spread flat seen
-- from above, or in pose two resting with them closed over its back, seen
-- from the side, legs on a grass tip and antennae forward.
-- The swallowtail asleep, wings closed over its back on a drooping stem and
-- the antennae lowered; in winter it is a chrysalis, angular and horned at
-- the head, standing out from a dry twig in its silk girdle.
local function butterflyAsleep(c, winter)
    if winter then
        local pupa = mix(c.leaf, c.muted, .5)
        return Svg.stem(Svg.spline({ { 30, 70 }, { 32, 40 }, { 34, 2 } }, 6), Svg.taper(3.6, 2), mix(c.muted, c.gold, .2), c.ink, 1.2)
            .. line("M32 30 L22 18", c.ink, 1.8) .. line("M32 30 L22 18", mix(c.muted, c.gold, .2), .8)
            .. path("M35 62 C33.4 52 34.4 40 37 30 C38.4 24 39.6 19 40.4 14.4 L43 17.6 L46.4 12 C48.6 16 50.6 22 51 30 C51.4 38 49.6 47 45 55 C42 59.4 38.6 61.6 35 62Z", pupa, c.ink, 1.5)
            .. line("M38 30 C42 31 46 31 50.6 29 M37 38 C41 39 46 39 50 37.4 M37 46 C41 47 45 46.6 48 45", mix(pupa, c.ink, .45), .8)
            .. line("M39.4 22 C45 29 47.6 40 44 53", c.ink, .9) .. line("M32.6 34 Q42 30 51 33.6", c.cream, 1.1) .. ellipse(34.4, 62, 2.6, 1.6, 0, c.cream, c.ink, .7)
            .. Asleep.zs(c, 56, 18, 5)
    end
    local folded = group(0, 0, 90, swallowWings(c) .. swallowBody(c), -1, 1)
    return line("M4 66 Q28 58 50 66", c.leaf, 2.2)
        .. group(42, 60, 8, line("M2 2 L0 7.6 M6 2 L7 7.4 M-3 1.6 L-7 7.2", c.ink, 1.1) .. folded
            .. line("M11 -1.4 Q16 2 20 7 M11 -.6 Q17 3 23 6", c.ink, 1) .. circle(20, 7, 1.2, c.ink) .. circle(23, 6, 1.2, c.ink))
        .. Asleep.zs(c, 58, 22, 6)
end

function Air.butterfly(c, second, name)
    if name == "sleep" or name == "winter" then return butterflyAsleep(c, name == "winter") end
    if second then
        local folded = group(0, 0, 90, swallowWings(c) .. swallowBody(c), -1, 1)
        return line("M4 68 Q30 62 52 66", c.leaf, 2.2)
            .. group(44, 58, 0, line("M2 2 L0 7.6 M6 2 L7 7.4 M-3 1.6 L-7 7.2", c.ink, 1.1) .. folded
                .. line("M11 -1.4 Q18 -8 24 -10 M11 -.6 Q19 -5 26 -6", c.ink, 1) .. circle(24, -10, 1.2, c.ink) .. circle(26, -6, 1.2, c.ink))
    end
    return group(40, 36, 18, both(swallowWings(c)) .. swallowBody(c)
        .. line("M-1 -11 Q-3 -19 -7 -23 M1 -11 Q3 -19 7 -23", c.ink, 1.1) .. circle(-7, -23, 1.3, c.ink) .. circle(7, -23, 1.3, c.ink), .8)
end

-- The right forewing of the elephant hawk-moth from its root at the origin,
-- the body along the upright and the head up: olive with a pink front edge,
-- two pink bands slanting across and a pink outer border.
local function hawkFore(c, olive, pink)
    return path("M1 -6 C7 1 14 11 19 22 C16 24.4 13 25.4 10 25.2 C7 18 4 11 0.6 5Z", olive, c.ink, 1.4)
        .. line("M2.8 -3.4 C8 3 13.4 11.4 17 19.6", pink, 1.2)
        .. line("M3 6 C6.6 11 9.4 16 11.4 22.6 M5.4 2.4 C9 7.6 12.2 13 14.6 19.6", pink, 1.1)
        .. line("M17.6 22.8 C15.6 24 13 24.6 10.8 24.4", pink, 1.4)
end

-- The right hindwing: rose pink with a black base and a pale fringe.
local function hawkHind(c, pink)
    return path("M1 2 C6 5 10.6 10 13 16 C10.6 19.4 7 20.6 3.6 19.6 C2 13.6 1 8 1 2Z", pink, c.ink, 1.3)
        .. path("M1 2 C4 4 6.4 6.6 7.6 9.6 C5.4 11.4 3.4 12.2 2.4 12 C1.4 9 1 6 1 2Z", c.ink)
end

-- Elephant hawk-moth seen from above, heading up and to the right: at rest
-- its olive and pink forewings are swept back into a dart over the pink
-- hindwings; in pose two it hovers with the same wings spread wide, the
-- hindwings showing, and its long tongue out to reach a flower.
-- The hawk-moth asleep by day, clinging head up (to the lantern it loves),
-- its forewings swept back into a dart and the antennae laid back along
-- them; in winter it is a glossy brown pupa lying in the leaf litter.
local function mothAsleep(c, winter, olive, pink)
    if winter then
        local brown = mix(c.muted, c.bloom, .3)
        local rings = {}
        for k = 0, 5 do rings[#rings + 1] = string.format("M%s %s q-1.4 4.4 0 8.6", n(30 + k * 5), n(48.4 - k * .6)) end
        return Asleep.leaves(c, 4, 76, 66, 7, 16) .. ellipse(40, 55, 18, 7.4, -6, brown, c.ink, 1.5) .. path("M22.6 56.4 C18 56 15 55 14 53.6 C16.6 53 19.6 53 22.4 53.4Z", brown, c.ink, 1)
            .. line(table.concat(rings, " "), mix(brown, c.ink, .5), .8) .. path("M50 50 C54 51 57 54 57 57", nil, c.ink, .9) .. ellipse(46, 52, 4, 1.4, -6, mix(brown, c.cream, .45))
            .. Asleep.leaves(c, 46, 74, 62, 3, 14, true) .. Asleep.zs(c, 56, 34, 5)
    end
    local body = path("M0 -15 C5 -13 6.4 -3 5 8 C3.6 17 1.6 24 0 27 C-1.6 24 -3.6 17 -5 8 C-6.4 -3 -5 -13 0 -15Z", olive, c.ink, 1.4)
        .. line("M0 -9 L0 24", pink, 1.6) .. line("M-4.6 6 L4.6 6 M-4 12 L4 12 M-2.8 18 L2.8 18", c.ink, .7)
        .. circle(-3, -14.6, 2.2, c.ink) .. circle(3, -14.6, 2.2, c.ink)
        .. line("M-1.6 -17 C-4 -14 -6 -8 -7 -1 M1.6 -17 C4 -14 6 -8 7 -1", c.ink, 1.6) .. line("M-1.6 -17 C-4 -14 -6 -8 -7 -1 M1.6 -17 C4 -14 6 -8 7 -1", c.cream, .7)
    return group(38, 38, 0, both(hawkHind(c, pink)) .. both(hawkFore(c, olive, pink)) .. body, 1.05) .. Asleep.zs(c, 54, 16, 6)
end

function Air.moth(c, second, name)
    local olive, pink = mix(c.sage, c.leaf, .3), mix(c.bloom2, c.bloom, .25)
    if name == "sleep" or name == "winter" then return mothAsleep(c, name == "winter", olive, pink) end
    local hind = about(0, 2, second and -40 or 0, hawkHind(c, pink))
    local fore = about(1, -6, second and -64 or 0, hawkFore(c, olive, pink))
    local body = path("M0 -15 C5 -13 6.4 -3 5 8 C3.6 17 1.6 24 0 27 C-1.6 24 -3.6 17 -5 8 C-6.4 -3 -5 -13 0 -15Z", olive, c.ink, 1.4)
        .. line("M0 -9 L0 24", pink, 1.6) .. line("M-3.4 -6 C-4 2 -3.6 10 -2 18 M3.4 -6 C4 2 3.6 10 2 18", pink, 1.2)
        .. line("M-4.6 6 L4.6 6 M-4 12 L4 12 M-2.8 18 L2.8 18", c.ink, .7)
        .. circle(-3, -14.6, 2.2, c.ink) .. circle(3, -14.6, 2.2, c.ink)
        .. line("M-1.6 -17 C-3 -21 -5 -23 -7.6 -24 M1.6 -17 C3 -21 5 -23 7.6 -24", c.ink, 1.6) .. line("M-1.6 -17 C-3 -21 -5 -23 -7.6 -24 M1.6 -17 C3 -21 5 -23 7.6 -24", c.cream, .7)
        .. (second and line("M0 -17 L0 -30", c.ink, 1) or "")
    return group(40, 36, 36, both(hind) .. both(fore) .. body, second and .92 or 1.05)
end

-- One dragonfly wing from the origin pointing up, `L` long and `W` wide
-- (broader at the root for a hind wing): clear, with a few veins and the
-- amber pterostigma near the tip of its front edge, which faces right.
local function gauze(c, L, W, hind)
    local root = hind and W * 1.3 or W * .5
    return path(string.format("M%s 0 C%s %s %s %s %s %s C%s %s %s %s %s 0Z", n(-root), n(-root * 1.1), n(-L * .4), n(-W * .6), n(-L * .92), n(W * .1), n(-L), n(W * .7), n(-L * .96), n(W * .65), n(-L * .4), n(W * .45)),
        mix(c.cream, c.sky, .35), c.ink, 1.1)
        .. line(string.format("M%s 0 L%s %s M0 0 Q%s %s %s %s M%s 0 Q%s %s %s %s", n(W * .3), n(W * .45), n(-L * .86), n(-W * .05), n(-L * .5), n(-W * .1), n(-L * .9), n(-root * .6), n(-root * .7), n(-L * .5), n(-W * .35), n(-L * .8)), c.ink, .6)
        .. ellipse(W * .48, -L * .86, .9, 2.6, 4, mix(c.gold, c.bloom, .35), c.ink, .6)
end

-- Emperor dragonfly seen from above as it hunts, heading right: big
-- blue-green eyes meeting on top of the head, an apple-green thorax, a long
-- sky-blue abdomen with a black stripe along its back and dark rings, and
-- four clear wings held flat out to the sides. In pose two the fore and
-- hind wings swing apart in their beat.
-- The dragonfly's nymph passing the winter under the pond: brown and squat
-- with big eyes and wing pads, its six legs gripping a reed stem below the
-- surface, a few bubbles rising.
local function nymph(c)
    local brown = mix(c.muted, c.leaf, .3)
    local rings = {}
    for k = 1, 5 do rings[#rings + 1] = string.format("M%s %s q6 1.6 12 0", n(46), n(34 + k * 4.4)) end
    return line("M0 10 q8 -3 16 0 t16 0 t16 0 t16 0 t16 0 t16 0 t16 0", mix(c.sky, c.ink, .5), 1.1)
        .. Svg.stem(Svg.spline({ { 60, 64 }, { 59, 30 }, { 61, 0 } }, 6), Svg.taper(3.4, 2.4), c.stem, c.ink, 1)
        .. line("M48 30 L42 26 L40 20 M47 36 L40 38 L37 44 M48 42 L42 48 L41 55 M58 30 L61 26 M58 36 L61 38 M58 42 L61 47", c.ink, 1.3)
        .. ellipse(52, 44, 7.4, 14, 0, brown, c.ink, 1.4) .. line(table.concat(rings, " "), mix(brown, c.ink, .5), .8)
        .. ellipse(52, 30, 6.4, 4.4, 0, brown, c.ink, 1.3) .. path("M47 32 C46 38 48 42 51 44 L52 32Z", mix(brown, c.ink, .3)) .. path("M57 32 C58 38 56 42 53 44 L52 32Z", mix(brown, c.ink, .3))
        .. ellipse(52, 23, 7.4, 4.6, 0, brown, c.ink, 1.3) .. circle(46.6, 21.6, 2.8, mix(c.glass, c.ink, .3), c.ink, .9) .. circle(57.4, 21.6, 2.8, mix(c.glass, c.ink, .3), c.ink, .9)
        .. circle(64, 16, 1.6, nil, c.ink, .8) .. circle(67, 12.4, 1.1, nil, c.ink, .8)
end

function Air.dragonfly(c, second, name)
    local blue, green = mix(c.sky, c.glass, .3), mix(c.leaf, c.pale, .3)
    if name == "winter" then return nymph(c) end
    local beat = second and 12 or 0
    local function pair(x, L, W, hind, tilt)
        local one = group(x, -2.6, tilt, gauze(c, L, W, hind))
        return one .. group(0, 0, 0, one, 1, -1)
    end
    local wings = pair(26, 33, 7.6, true, -12 - beat) .. pair(34, 35, 6.4, false, 9 + beat)
    local tail = { { 24, 0 }, { 0, 0 }, { -26, 0 }, { -52, 0 } }
    local rings = {}
    for i = 1, 8 do rings[#rings + 1] = string.format("M%s -2.6 L%s 2.6", n(18 - i * 8.6), n(18 - i * 8.6 - .6)) end
    local body = Svg.stem(Svg.spline(tail, 8), Svg.taper(6.4, 4), blue, c.ink, 1.3)
        .. ellipse(20, 0, 5.2, 4.2, 0, blue, c.ink, 1.2)
        .. line("M24 0 L-51 0", c.ink, 1.6) .. line(table.concat(rings, " "), c.ink, .9)
        .. path("M-52 -1.8 L-56.4 -3 L-55 0 L-56.4 3 L-52 1.8Z", c.ink, c.ink, .8)
        .. ellipse(31, 0, 7.4, 6.2, 0, green, c.ink, 1.4) .. line("M27 -3.4 L34 -1.6 M27 3.4 L34 1.6", c.ink, .9)
        .. path("M37 -6.4 C42.4 -7.2 45.6 -3 45.6 0 C45.6 3 42.4 7.2 37 6.4 C38.4 3 38.4 -3 37 -6.4Z", mix(c.glass, c.sky, .4), c.ink, 1.3)
        .. line("M39 0 L45 0", c.ink, .8)
    if name == "sleep" then
        -- asleep on a reed leaf, lying along it with the wings swept back
        local back = pair(26, 33, 7.6, true, -64) .. pair(34, 35, 6.4, false, -48)
        return Flora.leaf(c, 4, 58, -24, 98, 6, c.leaf) .. group(54, 38, -24, back .. body, .76) .. Asleep.zs(c, 80, 14, 6)
    end
    return group(54, 34, -8, wings .. body, .8)
end

return Air
