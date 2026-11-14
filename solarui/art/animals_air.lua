-- The garden's flying animals, each in the units of its own place and facing
-- right: honey bee, seven-spot ladybird, swallowtail, elephant hawk-moth and
-- emperor dragonfly. Each takes the colours and whether it is in its second
-- pose, and returns SVG.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse, petal = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse, Flora.petal

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
function Air.bee(c, second)
    local amber, band = mix(c.gold, c.bloom, .18), mix(c.ink, c.bloom, .25)
    local thorax, head = mix(c.gold, c.muted, .45), mix(c.ink, c.muted, .45)
    local glass, far = mix(c.cream, c.sky, .25), mix(c.cream, c.sky, .55)
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

-- Seven-spot ladybird walking along a blade of grass, seen from the side and
-- a little above, heading right: a red domed shell with a light on it, three
-- spots on the near side, two peeping over the top and one where the cases
-- meet, a black shield with its white patch, a small dark head and short
-- jointed legs. In pose two the shell is lifted open and the wings unfold.
function Air.ladybug(c, second)
    local blade = Flora.leaf(c, 0, 46, -4, 60, 5, c.leaf)
    local legs = line("M20 36 L17 40 L14 43.5 M28 37 L28 41 L26 44 M36 36 L39 40 L41 43", c.ink, 1.6)
        .. line("M24 37 L23 41 M33 37 L35 41", c.ink, 1.2)
    local shield = path("M42 16 C48 16 53 21 53 28 C52 32 48 34 45 33 C47 27 46 21 42 16Z", c.ink, c.ink, 1.2)
        .. path("M49 20 C51 21 52 24 51.5 26 C50 25 49 23 49 20Z", c.cream)
    local head = ellipse(53.5, 31.5, 4.2, 3.4, 10, c.ink) .. circle(55, 30.2, 1, c.cream)
        .. line("M56.5 29.5 Q58.5 27 58 24.5", c.ink, 1)
    local shell = path("M12 35 C10 22 20 13 31 13 C40 13 46 19 47 31 C38 36 21 37 12 35Z", c.bloom, c.ink, 1.6)
        .. path("M19 21 C22 17 27 15 31 15.5 C27 17 23 19 21 23Z", mix(c.bloom, c.cream, .6))
        .. line("M43 17 Q30 14 15 29", c.ink, 1.2)
        .. ellipse(31, 16.6, 2.6, 1.5, -8, c.ink) .. ellipse(22, 20, 2.3, 1.5, -30, c.ink)
        .. circle(41.5, 17.6, 2.2, c.ink)
        .. ellipse(36, 26, 3.4, 3, 0, c.ink) .. ellipse(25.5, 28, 3.8, 3.3, 0, c.ink) .. ellipse(17, 30.5, 2.6, 2.4, 0, c.ink)
    if second then
        local w = mix(c.cream, c.sky, .3)
        return blade .. legs
            .. group(31, 23, -72, clearWing(c, 30, 7.5, mix(c.cream, c.sky, .55))) .. group(30, 25, -100, clearWing(c, 28, 8, w))
            .. path("M14 34 C14 26 24 21 34 21 C41 21 46 25 47 31 C38 36 22 37 14 34Z", mix(c.ink, c.bloom, .25), c.ink, 1.4)
            .. about(44, 20, 30, shell) .. shield .. head
    end
    return blade .. legs .. shell .. shield .. head
end

-- One side of a swallowtail, body along the upright: yellow wings with black
-- bars and borders, blue spots and a red eye by the tail.
local function swallowWing(c)
    return path("M2 0 C12 -3 24 -1 28 2 C31 10 27 20 21 24 L20 33 L15 25 C10 26 5 18 2 9Z", c.pale, c.ink, 1.5)
        .. path("M28 2 C31 10 27 20 21 24 L20 33 L15 25 C19 22 23 14 22 5Z", c.ink) .. circle(23.5, 9, 1.7, c.sky) .. circle(22.5, 15, 1.7, c.sky) .. circle(19.5, 20.5, 1.6, c.sky)
        .. circle(7, 19, 2.6, c.bloom, c.ink, 1)
        .. path("M2 -6 C10 -26 28 -32 37 -28 C35 -18 31 -8 27 -1 C17 -2 8 -3 2 -2Z", c.pale, c.ink, 1.5)
        .. path("M37 -28 C35 -18 31 -8 27 -1 L22 -2 C26 -10 29 -19 30 -29Z", c.ink) .. circle(31, -22, 1.5, c.pale) .. circle(29, -15, 1.5, c.pale) .. circle(26.5, -8, 1.5, c.pale)
        .. line("M10 -21 L12 -11 M18 -27 L20 -15", c.ink, 3) .. line("M3 -4 L22 -4 M3 3 L20 8 M3 6 L14 20", c.ink, .8)
end

-- Swallowtail: wings spread in flight, or folded up over its back at rest.
function Air.butterfly(c, second)
    if second then
        local wing = group(0, 0, 0, swallowWing(c), -1, 1)
        return group(34, 56, 0, about(0, 0, 100, wing) .. line("M4 2 L2 10 M8 2 L9 10 M12 1 L15 9", c.ink, 1.2) .. ellipse(4, 0, 13, 2.8, -4, c.ink) .. circle(18, -2, 2.8, c.ink)
            .. line("M19 -4 Q24 -12 30 -13 M20 -3 Q27 -8 32 -7", c.ink, 1.1) .. circle(30, -13, 1.3, c.ink) .. circle(32, -7, 1.3, c.ink))
    end
    return group(39, 33, 24, both(swallowWing(c)) .. ellipse(0, 3, 2.7, 11, 0, c.ink) .. circle(0, -9.5, 2.6, c.ink)
        .. line("M-1 -11 Q-3 -19 -7 -23 M1 -11 Q3 -19 7 -23", c.ink, 1.1) .. circle(-7, -23, 1.3, c.ink) .. circle(7, -23, 1.3, c.ink), .82)
end

-- Elephant hawk-moth: olive and pink, its wings swept back at rest and
-- raised to hover, tongue out, in pose two.
function Air.moth(c, second)
    local fore = path("M3 -10 C14 -15 30 -5 37 8 C28 9 16 7 4 5Z", c.sage, c.ink, 1.5) .. path("M37 8 C28 9 16 7 4 5 L5 1 C16 3 26 5 33 5Z", c.bloom2, c.ink, .9)
        .. line("M6 -8 C16 -10 26 -3 32 4", c.bloom2, 2.2)
    local hind = path("M3 2 L24 9 L11 18 C6 14 4 8 3 2Z", c.bloom2, c.ink, 1.4) .. path("M3 2 L13 5.5 L7 11 C5 8 4 5 3 2Z", c.ink)
    local wings = both(hind) .. both(about(3, -6, second and -34 or 0, fore))
    local body = path("M0 -16 C7 -14 8 -2 5 8 C3 16 1 22 0 26 C-1 22 -3 16 -5 8 C-8 -2 -7 -14 0 -16Z", c.sage, c.ink, 1.5)
        .. line("M-2.6 -12 L-2.6 -2 M2.6 -12 L2.6 -2 M0 2 L0 22", c.bloom2, 1.8) .. line("M-4.6 7 L4.6 7 M-3.6 13 L3.6 13 M-2.4 19 L2.4 19", c.ink, .8)
        .. circle(-3.4, -16, 2.4, c.ink) .. circle(3.4, -16, 2.4, c.ink) .. line("M-2 -18 L-8 -25 M2 -18 L8 -25", c.cream, 2.4) .. line("M-2 -18 L-8 -25 M2 -18 L8 -25", c.ink, .9)
        .. (second and line("M0 -18 C0 -24 3 -28 6 -27 C9 -26 8 -22 5 -23", c.ink, 1.1) or "")
    return group(second and 36 or 38, second and 42 or 40, 38, wings .. body, second and .84 or 1)
end

-- One dragonfly wing growing up from the origin, `L` long, with its dark mark.
local function gauze(c, L, fill)
    return petal(c, L, L * .16, fill, 1.2) .. line(string.format("M0 0 Q%s %s %s %s M%s %s L%s %s", n(-L * .09), n(-L * .5), n(-L * .02), n(-L * .92), n(-L * .05), n(-L * .8), n(-L * .03), n(-L * .9)), c.ink, 1.1)
end

-- Emperor dragonfly: green thorax, long blue abdomen in rings, four wings
-- held high, or beaten level as it lifts in pose two.
function Air.dragonfly(c, second)
    local tail = Svg.spline({ { 68, 50 }, { 44, 51 }, { 24, 54 }, { 6, 53 } }, 8)
    local rings = {}
    for i = 1, 8 do
        local x, y = Svg.along(tail, Svg.length(tail) * i / 9)
        rings[#rings + 1] = string.format("M%s %s l.6 5", n(x - .3), n(y - 2.5))
    end
    local wings = ""
    for _i, w in ipairs(second and { { 46, 40 }, { -86, 38 }, { 30, 44 }, { -72, 42 } } or { { 40, 40 }, { -50, 38 }, { 20, 44 }, { -30, 42 } }) do
        wings = wings .. group(73, 46, w[1], gauze(c, w[2], _i < 3 and c.sky or c.cream))
    end
    local body = Svg.stem(tail, Svg.taper(5.4, 3.4), c.sky, c.ink, 1.3) .. line(Svg.poly(tail), c.ink, 1) .. line(table.concat(rings, " "), c.ink, 1)
        .. line("M72 53 L70 60 L73 62 M76 53 L77 60 L80 61 M80 52 L83 58 L86 58", c.ink, 1.2) .. wings
        .. ellipse(75, 49, 9, 6, -6, c.leaf, c.ink, 1.5) .. line("M70 47 L79 45 M71 51 L80 49", c.ink, .8) .. ellipse(87, 47, 5.6, 5.2, 0, c.glass, c.ink, 1.4) .. circle(89, 45.6, 1.2, c.cream)
    return group(second and -6 or 0, second and -5 or 0, 0, about(75, 49, second and -6 or 0, body))
end

return Air
