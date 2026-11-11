-- What stands in the garden's sky: the sun with its rays, the crescent moon,
-- stars, clouds and far birds. Each takes the sky's own colours `k` (see
-- garden_sky.lua) and a place, and returns SVG text.

local Svg = require("solarui/art/svg")

local n, group, path, line, circle = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle

local Bodies = {}

-- A ring of pointed rays round the origin from r0 out to r1, every other one only to r2.
local function rays(count, r0, r1, r2, half, first)
    local d = {}
    for i = 0, count - 1 do
        local a = (first or 0) + i * 360 / count
        local x0, y0 = Svg.pol(r0, a - half)
        local x1, y1 = Svg.pol(i % 2 == 0 and r1 or r2, a)
        local x2, y2 = Svg.pol(r0, a + half)
        d[#d + 1] = string.format("M%s %s L%s %s L%s %sZ", n(x0), n(y0), n(x1), n(y1), n(x2), n(y2))
    end
    return table.concat(d, " ")
end

-- Long flat beams fanning out from the origin between the angles a0 and a1.
local function beams(count, a0, a1, r0, r1, half)
    local d = {}
    for i = 0, count - 1 do
        local a = a0 + (a1 - a0) * i / (count - 1)
        local reach = r1 * (.78 + .22 * Svg.vary(i, 4))
        local x0, y0 = Svg.pol(r0, a - half * 3)
        local x1, y1 = Svg.pol(reach, a - half)
        local x2, y2 = Svg.pol(reach, a + half)
        local x3, y3 = Svg.pol(r0, a + half * 3)
        d[#d + 1] = string.format("M%s %s L%s %s L%s %s L%s %sZ", n(x0), n(y0), n(x1), n(y1), n(x2), n(y2), n(x3), n(y3))
    end
    return table.concat(d, " ")
end

-- The sun at (x, y), its disc `r`: a sunburst of long and short rays round a rimmed disc.
function Bodies.sun(k, x, y, r)
    return group(x, y, 0, path(rays(16, r * 1.02, r * 2.05, r * 1.5, 7, 0), k.ray, k.ink, 1.3)
        .. path(rays(16, r * 1.02, r * 1.34, r * 1.34, 4.6, 11.25), k.glow, k.ink, 1.1)
        .. circle(0, 0, r * 1.08, k.sun, k.ink, 1.8) .. circle(0, 0, r * .8, k.glow, k.ink, 1.1))
end

-- The large low sun of the golden hour at (x, y), in a halo with long beams round it.
function Bodies.lowsun(k, x, y, r)
    return group(x, y, 0, path(beams(22, 0, 343.6, r * 1.3, r * 4.4, 1.5), k.beam)
        .. circle(0, 0, r * 1.5, k.halo) .. path(rays(24, r * 1.04, r * 1.42, r * 1.24, 5, 0), k.ray, k.ink, 1.2)
        .. circle(0, 0, r * 1.06, k.sun, k.ink, 1.8) .. line(string.format("M%s %s A%s %s 0 0 1 %s %s", n(-r * .78), n(-r * .1), n(r * .8), n(r * .8), n(r * .1), n(-r * .78)), k.ink, 1))
end

-- A crescent moon at (x, y), `r` across its half, in a pale halo.
function Bodies.moon(k, x, y, r)
    local tx, ty = r * .5, r * .86
    local crescent = string.format("M%s %s A%s %s 0 1 0 %s %s A%s %s 0 0 1 %s %sZ", n(tx), n(-ty), n(r), n(r), n(tx), n(ty), n(r * .92), n(r * .92), n(tx), n(-ty))
    return group(x, y, -24, circle(0, 0, r * 1.9, k.halo) .. circle(0, 0, r * 1.42, k.halo2) .. path(crescent, k.moon, k.ink, 1.6)
        .. line(string.format("M%s %s A%s %s 0 0 0 %s %s", n(-r * .5), n(-r * .56), n(r * .76), n(r * .76), n(-r * .5), n(r * .56)), k.ink, .9))
end

-- A star of four points at (x, y), `s` long, as part of a path.
local function spark(x, y, s)
    local w = s * .16
    return string.format("M%s %s L%s %s L%s %s L%s %s L%s %s L%s %s L%s %s L%s %sZ", n(x), n(y - s), n(x + w), n(y - w), n(x + s * .8), n(y), n(x + w), n(y + w), n(x), n(y + s),
        n(x - w), n(y + w), n(x - s * .8), n(y), n(x - w), n(y - w))
end

-- Stars of many sizes over a field w x h, none inside the circle `keep` { x, y, r }.
function Bodies.stars(k, w, h, keep)
    local dots, sparks = {}, {}
    for i = 1, 74 do
        local x, y = 8 + (w - 16) * Svg.vary(i, 1), 8 + (h - 30) * Svg.vary(i, 2) ^ 1.5
        local dx, dy = x - keep.x, y - keep.y
        if dx * dx + dy * dy > keep.r * keep.r then
            if i % 6 == 0 then sparks[#sparks + 1] = spark(x, y, 5 + 6 * Svg.vary(i, 3))
            else dots[#dots + 1] = circle(x, y, .9 + 1.5 * Svg.vary(i, 3) ^ 2, i % 5 == 0 and k.star2 or k.star) end
        end
    end
    return table.concat(dots) .. path(table.concat(sparks, " "), k.star)
end

-- A cloud `w` long with its level foot at (x, y), a row of round heads and a curl; a low bank when `flat`.
function Bodies.cloud(k, x, y, w, flat)
    local rise = w * (flat and .2 or .36)
    local heads = { { .1, .34 }, { .3, .74 }, { .56, 1 }, { .78, .6 }, { .93, .26 } }
    local d, px, py = { "M0 0" }, 0, 0
    for _i, hd in ipairs(heads) do
        local hx, hy = w * hd[1], -rise * hd[2]
        local r = math.sqrt((hx - px) ^ 2 + (hy - py) ^ 2) * .56
        d[#d + 1] = string.format("A%s %s 0 0 1 %s %s", n(r), n(r), n(hx), n(hy))
        px, py = hx, hy
    end
    d[#d + 1] = string.format("A%s %s 0 0 1 %s 0 Q%s %s 0 0Z", n(w * .09), n(w * .09), n(w), n(w * .5), n(w * .045))
    local curl = line(Svg.poly(Svg.spiral(w * .5, -rise * .52, rise * .3, 1.1, 250)), k.ink, 1)
    return group(x, y, 0, path(table.concat(d, " "), k.cloud, k.ink, 1.7) .. (flat and "" or curl)
        .. line(string.format("M%s %s Q%s %s %s %s", n(w * .16), n(-rise * .14), n(w * .5), n(-rise * .02), n(w * .84), n(-rise * .14)), k.shade, 1.6))
end

-- A thin streak of cloud from (x, y), `w` long, swelling in the middle.
function Bodies.wisp(k, x, y, w, fill)
    local pts = Svg.spline({ { 0, 0 }, { w * .28, -w * .035 }, { w * .6, w * .02 }, { w, -w * .03 } }, 8)
    return group(x, y, 0, path(Svg.ribbon(pts, Svg.swell(w * .05, .6)), fill or k.cloud))
end

-- A few far birds on the wing round (x, y), drawn with two strokes each.
function Bodies.birds(k, x, y, s)
    local d = {}
    for i, b in ipairs({ { 0, 0, 1 }, { 1.9, -.9, .74 }, { 1.2, 1.3, .6 }, { 3.3, .5, .5 } }) do
        local bx, by, q = x + b[1] * s, y + b[2] * s, s * b[3]
        d[i] = string.format("M%s %s Q%s %s %s %s Q%s %s %s %s", n(bx - q), n(by - q * .1), n(bx - q * .4), n(by - q * .62), n(bx), n(by), n(bx + q * .45), n(by - q * .7), n(bx + q * 1.05), n(by - q * .3))
    end
    return line(table.concat(d, " "), k.ink, 1.8)
end

return Bodies
