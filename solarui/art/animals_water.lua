-- The animals of the garden's pond, each in the units of its own place and
-- facing right: the marsh frog on a lily pad and the koi seen from above.
-- Each takes the colours and whether it is in its second pose.

local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local group, path, line, circle, ellipse = Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse

local mix = Wash.mix

local Water = {}

-- Marsh frog sitting on a lily pad, facing right: olive green with dark
-- blotches, a pale green stripe down the back and a pale ridge along each
-- side, a pointed snout, a golden eye high on the head with its level pupil,
-- the round eardrum behind it, a pale throat, straight front legs and the
-- hind leg folded in three with a long webbed foot. In pose two it calls,
-- the grey sac at the corner of its mouth blown up.
function Water.frog(c, second)
    local olive, blotch = mix(c.leaf, c.muted, .25), mix(c.leaf, c.ink, .55)
    local stripe, pale = mix(c.leaf, c.pale, .55), mix(c.cream, c.pale, .3)
    local sac = second and (ellipse(60.6, 37.4, 6.6, 5.4, 10, mix(c.muted, c.cream, .45), c.ink, 1.3) .. line("M57 34.4 Q60.6 33 64 35.4", c.ink, .7)) or ""
    local body = path("M10 46 C8 36 18 25 32 22 C38 18 45 15 51 15.6 C57 16 62 21 66.4 27.6 C67.4 29.6 66 31.4 63.4 32 C61 34 59 36.4 58 38.6 C57 44 52 48.6 46 49.4 L20 50 C14 50 10.6 49 10 46Z", olive, c.ink, 1.7)
        .. path("M63.4 32 C61 34 59 36.4 58 38.6 C57 44 53 47.6 48 49 C50.6 45 51.6 40 53.6 36.6 C56.6 33.6 60 32.6 63.4 32Z", pale, c.ink, 1)
        .. line("M50 16.6 C40 19 27 24.6 15 35", stripe, 2.2) .. line("M46 22.6 C37 25.6 26 31 16 41", pale, 1.4)
        .. path("M27 27 C30 25.6 32 27 31 29 C29 30.6 26 30 27 27Z", blotch) .. path("M36 24 C38.6 23 40 24.6 39 26.4 C37 27.4 35 26.6 36 24Z", blotch)
        .. path("M21 34 C24 33 25.6 35 24 37 C22 38 20 36.6 21 34Z", blotch) .. path("M38 31 C40.6 30.4 41.6 32.4 40 34 C38 34.6 36.6 33 38 31Z", blotch)
        .. line("M66.4 28.4 Q60 31 52.6 30.2", c.ink, 1.2) .. circle(46, 26.6, 3.2, mix(olive, c.muted, .45), c.ink, 1)
        .. circle(53, 18.4, 4.8, c.gold, c.ink, 1.5) .. ellipse(53.4, 18.4, 2.8, 1.4, 0, c.ink) .. circle(64.2, 26, .7, c.ink)
    local front = Svg.stem(Svg.spline({ { 51, 40 }, { 53.6, 46 }, { 53.4, 52.6 } }, 5), Svg.taper(5.2, 3.4), olive, c.ink, 1.3)
        .. line("M53.4 52.6 L59 51.6 M53.4 52.6 L59.4 54 M53.4 52.6 L57 56.4 M53.4 52.6 L50 55.6", c.ink, 1.3)
    local hind = ellipse(24, 41.6, 13.6, 8.4, -24, olive, c.ink, 1.6)
        .. path("M27 36 C31 40.4 30 46 24 48 C19 49.6 14 50 12.6 48.4 C14 46 18 45 22 43.6 C25 42.4 26 39.6 27 36Z", olive, c.ink, 1.3)
        .. path("M13.6 49 C22 48 32 48.4 41 49.4 L47 47.6 L45.6 50.4 L49.4 51 L45 52.4 L47.4 54.6 L42 53.6 C32 53.4 22 52.6 13.6 51.6Z", olive, c.ink, 1.2)
        .. path("M18 39 C21 38 22.6 40 21 42 C19 43 17 41.4 18 39Z", blotch) .. path("M28 44 C30.6 43.4 31.6 45.4 30 47 C28 47.6 26.6 46 28 44Z", blotch)
    local frog = sac .. body .. front .. hind
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
