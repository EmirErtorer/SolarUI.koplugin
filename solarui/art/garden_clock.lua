-- The garden's clock, twice. garden_clock_icon is the small picture on the
-- top bar's button: a brass dial on wrought-iron scroll feet under a crest
-- of sun petals, its hands at the hour in the param's first number (0 to
-- 23, 10:10 when there is none). garden_clock_face is the big dial the
-- reader picks an hour on: a band of two vines woven round it, a flower or
-- bud at each hour, a single hand at H o'clock and, for "am" or "pm" in the
-- param ("H:am", "H:pm"), a sun or a moon in a medallion at the top. The
-- screen lays the numerals on a ring of 0.33 of the canvas, which stays
-- clear of all but faint marks from 0.26 to 0.40.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle
local mix = Wash.mix

local Clock = {}

-- The tokens of a param parted by colons, as a set, and its first number.
local function tokens(param)
    local set, first = {}, nil
    for t in tostring(param or ""):gmatch("[^:]+") do
        set[t] = true
        if first == nil then first = tonumber(t) end
    end
    return set, first
end

-- A band `w` wide along `pts`, filled and edged in ink `o` wide, with no seam where two pieces of it meet.
local function inked(c, pts, w, fill, o)
    return path(Svg.ribbon(pts, w + 2 * o), c.ink) .. path(Svg.ribbon(pts, w), fill)
end

-- A whiplash bar of wrought iron through `way` that ends in a scroll { cx, cy, r, turns, from, ccw }.
local function scroll(c, way, w, s)
    local pts = Svg.join(Svg.spline(way, 10), Svg.spiral(s[1], s[2], s[3], s[4], s[5], s[6]))
    return path(Svg.ribbon(pts, Svg.swell(w, w * .3)), c.ink)
end

-- A hand pointing up from the origin, `L` long: weight, shaft and leaf tip, with a gold heart and two scrolls when `pierce`.
local function hand(c, L, w, pierce)
    -- The outline of the leaf tip, or with `k` of 1 the smaller heart inside it.
    local function head(k)
        local b, t, x = -L * (.56 + .05 * k), -L * (1 - .09 * k), w * (1 - .5 * k)
        return string.format("M0 %s C%s %s %s %s 0 %s C%s %s %s %s 0 %sZ", n(b), n(x * 1.25), n(b - L * .02), n(x * .75), n(b - L * .24), n(t),
            n(-x * .75), n(b - L * .24), n(-x * 1.25), n(b - L * .02), n(b))
    end
    local out = group(0, 0, 180, Flora.petal(c, L * .24, w * .55, c.ink, w * .1)) .. path(Svg.ribbon({ { 0, 0 }, { 0, -L * .6 } }, Svg.taper(w * .42, w * .26)), c.ink)
        .. path(head(0), c.ink, c.ink, w * .1)
    if not pierce then return out end
    local curls = {}
    for _i, s in ipairs({ 1, -1 }) do
        curls[#curls + 1] = Svg.poly(Svg.join({ { 0, -L * .5 } }, Svg.spiral(s * w * .62, -L * .5, w * .55, 1.15, s > 0 and 270 or 90, s < 0)))
    end
    return out .. path(head(1), c.gold) .. line(table.concat(curls, " "), c.ink, w * .17) .. circle(0, L * .17, w * .14, c.gold)
end

-- The picture for the top bar's button: dial, casing, crest, feet and hands.
function Clock.garden_clock_icon(c, vw, _vh, param)
    c = Wash.apply(c, param)
    local _set, h = tokens(param)
    local hour, minute = 10 + 10 / 60, 10
    if h then hour, minute = h % 12, 0 end
    local feet = scroll(c, { { 36, 82 }, { 26, 89 }, { 15, 89 } }, 6.4, { 11, 83, 6, 1.1, 180 })
    local crest = Flora.around(50, 22, 2, 7, function(i) return Flora.petal(c, 15 - math.abs(i - 3) * 2.2, 3.4, i % 2 == 0 and c.gold or c.bloom, 2) end, -72)
        .. circle(50, 22, 4.2, c.bloom2, c.ink, 2.2)
    local ticks = {}
    for k = 0, 3 do
        local x0, y0 = Svg.pol(24, k * 90, 50, 58)
        local x1, y1 = Svg.pol(19, k * 90, 50, 58)
        ticks[#ticks + 1] = string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1))
    end
    local body = feet .. group(100, 0, 0, feet, -1, 1)
        .. Flora.leaf(c, 45, 27, 196, 23, 6.5, c.leaf, true) .. Flora.leaf(c, 55, 27, -16, 23, 6.5, c.leaf, true) .. crest
        .. circle(50, 58, 32, c.gold, c.ink, 3.2) .. circle(50, 58, 27.6, nil, c.ink, 1.3)
        .. circle(50, 58, 24.5, c.cream, c.ink, 2.6) .. line(table.concat(ticks, " "), c.ink, 3.4)
        .. group(50, 58, minute * 6, hand(c, 21.5, 3.2)) .. group(50, 58, hour * 30, hand(c, 16, 4.4))
        .. circle(50, 58, 3.2, c.gold, c.ink, 1.8)
    return group(0, 0, 0, body, vw / 100)
end

-- Two vines woven round a ring of radius `r`, crossing `2k` times over and under in turn, a berry in each loop.
local function vines(c, cx, cy, r, a, k, w)
    -- One vine from angle `from` to `to`, on the outer side of the ring first when `s` is 1.
    local function vine(s, from, to)
        local pts = {}
        for d = from, to, .5 do
            local x, y = Svg.pol(r + s * a * math.sin(math.rad(d * k)), d, cx, cy)
            pts[#pts + 1] = { x, y }
        end
        return inked(c, pts, w, c.leaf, w * .32)
    end
    local out = vine(-1, 0, 360) .. vine(1, 0, 360)
    local step = 180 / k
    for m = 1, 2 * k, 2 do out = out .. vine(-1, m * step - step * .35, m * step + step * .35) end
    for m = 0, 2 * k - 1 do
        local x, y = Svg.pol(r, (m + .5) * step, cx, cy)
        out = out .. circle(x, y, w * .62, m % 2 == 0 and c.bloom or c.gold, c.ink, w * .3)
    end
    return out
end

-- The medallion at the top of the dial: a sun for "am", a moon and star for "pm".
local function medallion(c, x, y, r, pm)
    local out = circle(x, y, r, c.cream, c.ink, r * .1)
    if pm then
        local m = r * .62
        return out .. path(string.format("M%s %s A%s %s 0 1 0 %s %s A%s %s 0 0 1 %s %sZ", n(x + m * .2), n(y - m), n(m), n(m), n(x + m * .2), n(y + m),
            n(m * 1.4), n(m * 1.4), n(x + m * .2), n(y - m)), c.gold, c.ink, r * .08)
            .. Flora.around(x + r * .4, y - r * .22, 0, 4, Flora.petal(c, r * .3, r * .11, c.gold, r * .05))
    end
    return out .. Flora.around(x, y, r * .34, 12, function(i) return Flora.petal(c, r * (i % 2 == 0 and .5 or .36), r * .14, c.gold, r * .05) end)
        .. circle(x, y, r * .36, c.gold, c.ink, r * .08) .. circle(x, y, r * .12, c.bloom)
end

-- The mark of an hour pointing out from the origin, `s` long: a flower at the quarters, else a bud between leaves.
local function marker(c, s, quarter)
    local sw = s * .08
    if quarter then
        return Flora.around(0, 0, s * .08, 6, Flora.petal(c, s * .46, s * .24, c.bloom, sw)) .. circle(0, 0, s * .15, c.gold, c.ink, sw)
    end
    local leaf = Flora.petal(c, s * .48, s * .17, c.leaf, sw)
    return group(0, s * .42, -44, leaf) .. group(0, s * .42, 44, leaf)
        .. path(string.format("M0 %s C%s %s %s %s 0 %s C%s %s %s %s 0 %sZ", n(s * .46), n(s * .3), n(s * .3), n(s * .26), n(-s * .24), n(-s * .5),
            n(-s * .26), n(-s * .24), n(-s * .3), n(s * .3), n(s * .46)), c.bloom, c.ink, sw)
        .. line(string.format("M%s %s Q%s %s 0 %s", n(-s * .1), n(s * .3), n(s * .12), n(-s * .05), n(-s * .42)), c.ink, sw * .7)
end

-- The stem the hour marks grow on, a ring of radius `r` with a sprig of two leaves halfway between hours.
local function garland(c, cx, cy, r, s)
    local out = circle(cx, cy, r, nil, c.stem, s * .1)
    for i = 0, 11 do
        local leaf = Flora.petal(c, s * .55, s * .16, c.sage, s * .07)
        out = out .. group(cx, cy, i * 30 + 15, group(0, -r, 0, group(0, 0, 64, leaf) .. group(0, 0, 116, leaf)))
    end
    return out
end

-- The faint whirl of curved petals at the heart of the dial, under the hand.
local function whirl(cx, cy, r, fill, edge)
    local d = string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s 0 0Z", n(-r * .22), n(-r * .3), n(-r * .1), n(-r * .78), n(r * .2), n(-r),
        n(r * .12), n(-r * .7), n(r * .2), n(-r * .3))
    return Flora.around(cx, cy, 0, 12, path(d, fill, edge, r * .012))
end

-- The big dial: woven band, hour marks, faint minute dots, a whirl of petals, the hand and the boss.
function Clock.garden_clock_face(c, vw, _vh, param)
    c = Wash.apply(c, param)
    local set, h = tokens(param)
    local cx, cy, u = vw / 2, vw / 2, vw
    local face = mix(c.cream, c.bg, .25)
    local faint = mix(face, c.line, .4)
    local out = circle(cx, cy, u * .497, c.gold, c.ink, u * .006)
        .. vines(c, cx, cy, u * .4795, u * .0085, 20, u * .0105)
        .. circle(cx, cy, u * .461, c.pale, c.ink, u * .005) .. circle(cx, cy, u * .419, face, c.ink, u * .004)
        .. garland(c, cx, cy, u * .44, u * .03)
    for i = 0, 11 do
        local deg = i * 30
        if not (i == 0 and (set.am or set.pm)) then
            local x, y = Svg.pol(u * .44, deg, cx, cy)
            out = out .. group(x, y, deg, marker(c, u * .048, i % 3 == 0))
        end
    end
    if set.am or set.pm then
        local x, y = Svg.pol(u * .452, 0, cx, cy)
        out = out .. medallion(c, x, y, u * .04, set.pm)
    end
    for m = 0, 59 do
        if m % 5 ~= 0 then
            local x, y = Svg.pol(u * .407, m * 6, cx, cy)
            out = out .. circle(x, y, u * .0022, faint)
        end
    end
    out = out .. circle(cx, cy, u * .245, nil, faint, u * .003)
        .. whirl(cx, cy, u * .215, mix(face, c.sage, .14), faint)
    if h then out = out .. group(cx, cy, (h % 12) * 30, hand(c, u * .22, u * .032, true)) end
    out = out .. Flora.around(cx, cy, u * .012, 8, Flora.petal(c, u * .042, u * .016, c.gold, u * .004), 22.5)
        .. circle(cx, cy, u * .03, c.bloom, c.ink, u * .006) .. circle(cx, cy, u * .012, c.gold, c.ink, u * .004)
    return out
end

return Clock
