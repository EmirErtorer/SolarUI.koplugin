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

-- Koi seen from above, swimming to the right: a white body with red patches
-- lying inside its outline and a red cap on the head, a few black flecks, a
-- fin ridge along the back, clear rayed pectoral and pelvic fins, a forked
-- tail with its rays, eyes on the sides of the head and two pairs of barbels
-- at the mouth. It bends the other way in pose two.
function Water.koi(c, second)
    local k = second and -1 or 1
    local red, fin = mix(c.bloom, c.gold, .12), mix(c.cream, c.sky, .3)
    local spine = Svg.spline({ { 24, 28 + 5 * k }, { 42, 28 - 4 * k }, { 62, 28 + 3 * k }, { 80, 28 - 2 * k }, { 93, 28 } }, 8)
    local count, len = #spine, Svg.length(spine)
    -- how wide the body is `t` of the way from tail to nose
    local function girth(t) return 4.5 * (1 - t) ^ .4 + 16 * math.sin(math.pi * t ^ .78) ^ .62 end
    -- the points of the spine between two places along it
    local function part(t0, t1)
        local pts = {}
        for i = math.floor(1 + (count - 1) * t0), math.floor(1 + (count - 1) * t1) do pts[#pts + 1] = spine[i] end
        return pts
    end
    -- a patch of colour between two places, `w` of the body's width, rounded at both ends and set off the middle by `off`
    local function patch(t0, t1, w, off)
        return group(0, off or 0, 0, path(Svg.ribbon(part(t0, t1), function(u) return girth(t0 + (t1 - t0) * u) * w * math.sin(math.pi * (.08 + .84 * u)) ^ .5 end), red))
    end
    -- a pair of fins `t` along, swept back by `sweep`, `s` long
    local function fins(t, s, sweep)
        local x, y, ang = Svg.along(spine, len * t)
        local one = string.format("M3 0 C%s %s %s %s %s %s C%s %s %s %s 0 2Z", Svg.n(s * .5), Svg.n(s * .2), Svg.n(s * .9), Svg.n(s * .7), Svg.n(s * .7), Svg.n(s * 1.1), Svg.n(s * .3), Svg.n(s), Svg.n(-s * .1), Svg.n(s * .6))
        local rays = string.format("M2 1 L%s %s M2 1 L%s %s M2 1 L%s %s", Svg.n(s * .7), Svg.n(s * .9), Svg.n(s * .4), Svg.n(s * .9), Svg.n(s * .1), Svg.n(s * .7))
        local f = path(one, fin, c.ink, 1.1) .. line(rays, c.ink, .6)
        local girthy = girth(t) * .42
        return group(x, y, ang + 180 - sweep, group(0, girthy, 0, f)) .. group(x, y, ang + 180 + sweep, group(0, -girthy, 0, f, 1, -1))
    end
    local tx, ty = spine[1][1], spine[1][2]
    local tail = group(tx + 2, ty, -12 * k, path("M0 0 C-8 -3 -14 -12 -22 -15 C-19 -8 -16 -4 -13 0 C-16 4 -19 8 -22 15 C-14 12 -8 3 0 0Z", mix(fin, c.bloom2, .35), c.ink, 1.4)
        .. line("M-2 0 L-12 0 M-3 -1.6 L-18 -11 M-3 1.6 L-18 11 M-3 -1 L-15 -6 M-3 1 L-15 6", c.ink, .6))
    local hx, hy, hang = Svg.along(spine, len * .93)
    local face = group(hx, hy, hang, circle(-1, -5.8, 1.5, c.ink) .. circle(-1, 5.8, 1.5, c.ink) .. line("M6.6 -2.2 L10.6 -4.6 M6.6 2.2 L10.6 4.6 M5 -3.4 L8 -6.6 M5 3.4 L8 6.6", c.ink, .9))
    local mx, my = Svg.along(spine, len * .5)
    return line(string.format("M%s %s q8 -4 16 0 M70 %s q7 3 14 0", Svg.n(4), Svg.n(8 + (second and 38 or 0)), Svg.n(second and 8 or 49)), c.ink, 1)
        .. tail .. fins(.38, 12, 34) .. fins(.72, 19, 46) .. path(Svg.ribbon(spine, girth), c.cream, c.ink, 1.7)
        .. patch(.18, .4, .78, -1.4 * k) .. patch(.5, .68, .7, 1.6 * k) .. patch(.8, .97, .62)
        .. ellipse(mx - 2, my - 4 * k, 2.6, 1.8, 20, c.ink) .. ellipse(mx - 24, my + 2.4 * k, 1.8, 1.3, 0, c.ink) .. ellipse(mx + 20, my + 3.6 * k, 1.6, 1.2, 0, c.ink)
        .. line(Svg.poly(part(.3, .62)), c.ink, 1.1) .. path(Svg.ribbon(spine, girth), nil, c.ink, 1.7) .. face
end

return Water
