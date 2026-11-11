-- The animals of the garden's pond, each in the units of its own place and
-- facing right: the marsh frog on a lily pad and the koi seen from above.
-- Each takes the colours and whether it is in its second pose.

local Svg = require("solarui/art/svg")

local group, path, line, circle, ellipse = Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse

local Water = {}

-- Marsh frog sitting on a lily pad: folded hind leg, pale belly, a light
-- stripe down its spotted back. In pose two it calls, a sac swelling at its cheek.
function Water.frog(c, second)
    local sac = second and (circle(60, 35, 7.5, c.cream, c.ink, 1.3) .. line("M56 31 Q60 29 64 32", c.ink, .8)) or ""
    local frog = sac .. path("M10 47 C8 36 20 24 34 22 C40 18 46 15 50 15 C56 14 62 20 65 27 C66 31 62 34 58 36 C58 42 54 47 48 49 L22 50 C16 50 11 50 10 47Z", c.leaf, c.ink, 1.7)
        .. path("M63 30 C57 34 53 40 47 48 L50 49 C56 46 58 41 58 36 C61 34 63 33 63 30Z", c.cream, c.ink, 1)
        .. line("M21 30 C29 25 38 22 46 20", c.pale, 2) .. ellipse(28, 30, 3, 2, -20, c.ink) .. ellipse(37, 26, 2.6, 1.8, -10, c.ink) .. ellipse(24, 37, 2.2, 1.6, 0, c.ink) .. ellipse(40, 33, 2, 1.5, 0, c.ink)
        .. line(second and "M65 28 L52 29 L57 32" or "M65 28 Q58 30 51 29", c.ink, 1.2) .. circle(45, 26, 3, c.sage, c.ink, 1)
        .. circle(52, 17, 4.8, c.gold, c.ink, 1.5) .. ellipse(52.5, 17, 2.6, 1.5, 0, c.ink)
        .. Svg.stem(Svg.spline({ { 51, 41 }, { 54, 47 }, { 53, 53 } }, 5), Svg.taper(5.5, 3.6), c.leaf, c.ink, 1.3) .. line("M53 53 L60 52 M53 53 L60 55 M53 53 L57 57", c.ink, 1.4)
        .. ellipse(23, 42, 13, 8, -22, c.leaf, c.ink, 1.6) .. Svg.stem(Svg.spline({ { 34, 38 }, { 20, 50 }, { 30, 53 }, { 42, 53 } }, 6), Svg.taper(5, 3.4), c.leaf, c.ink, 1.3)
        .. line("M42 53 L48 51 M42 53 L49 54 M42 53 L46 57", c.ink, 1.4)
    return ellipse(35, 54, 33, 5, 0, c.sage, c.ink, 1.5) .. line("M35 54 L14 52 M35 54 L56 52 M35 54 L30 58", c.ink, .8) .. group(second and -2 or 0, second and -2 or 0, second and -4 or 0, frog)
end

-- Koi from above: a white body with red saddles and black flecks, fins and a
-- fan of a tail. It bends the other way in pose two.
function Water.koi(c, second)
    local k = second and -1 or 1
    local spine = Svg.spline({ { 24, 28 + 5 * k }, { 42, 28 - 4 * k }, { 62, 28 + 3 * k }, { 80, 28 - 2 * k }, { 93, 28 } }, 8)
    local count = #spine
    -- how wide the body is `t` of the way from tail to nose
    local function girth(t) return 4.5 * (1 - t) ^ .4 + 16 * math.sin(math.pi * t ^ .78) ^ .62 end
    -- the part of the body between two places along it, as its own outline
    local function saddle(t0, t1, narrow)
        local part = {}
        for i = math.floor(1 + (count - 1) * t0), math.floor(1 + (count - 1) * t1) do part[#part + 1] = spine[i] end
        return Svg.ribbon(part, function(t) return girth(t0 + (t1 - t0) * t) * (narrow or 1) end)
    end
    local tx, ty = spine[1][1], spine[1][2]
    local tail = group(tx + 2, ty, -12 * k, path("M0 0 C-8 -3 -15 -12 -21 -13 C-18 -7 -17 -3 -15 0 C-17 3 -18 7 -21 13 C-15 12 -8 3 0 0Z", c.bloom2, c.ink, 1.4) .. line("M-3 0 L-14 0 M-4 -2 L-16 -8 M-4 2 L-16 8", c.ink, .8))
    local fx, fy, fang = Svg.along(spine, Svg.length(spine) * .7)
    local fins = group(fx, fy, fang + 90, path("M-6 0 C-16 2 -20 10 -17 15 C-11 13 -7 7 -5 2Z M6 0 C16 2 20 10 17 15 C11 13 7 7 5 2Z", c.bloom2, c.ink, 1.2))
    local hx, hy, hang = Svg.along(spine, Svg.length(spine) * .93)
    local face = group(hx, hy, hang, circle(0, -4.6, 1.5, c.ink) .. circle(0, 4.6, 1.5, c.ink) .. line("M6 -2.4 L10 -4.4 M6 2.4 L10 4.4", c.ink, 1) .. circle(-4, 0, 3.4, c.bloom, c.ink, .8))
    local mx, my = Svg.along(spine, Svg.length(spine) * .5)
    return line(string.format("M%s %s q8 -4 16 0 M70 %s q7 3 14 0", Svg.n(4), Svg.n(8 + (second and 38 or 0)), Svg.n(second and 8 or 49)), c.ink, 1)
        .. tail .. fins .. path(saddle(0, 1), c.cream, c.ink, 1.7) .. path(saddle(.2, .44), c.bloom, c.ink, .9) .. path(saddle(.56, .72, .98), c.bloom, c.ink, .9)
        .. ellipse(mx - 1, my - 4 * k, 4, 2.6, 20, c.ink) .. ellipse(mx - 26, my + 1, 2.6, 1.8, 0, c.ink) .. ellipse(mx + 22, my + 3 * k, 2.4, 1.8, 0, c.ink)
        .. line(Svg.poly(Svg.head(spine, Svg.length(spine) * .56)), c.ink, .9) .. path(saddle(0, 1), nil, c.ink, 1.7) .. face
end

return Water
