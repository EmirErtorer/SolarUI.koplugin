-- The plants every drawing is put together from: leaves, roses and buds,
-- vines with tendrils, and the other flowers of the garden. Each takes the
-- colours `c` (ink, leaf, stem, gold, pale, bloom, bloom2, sky, sage, glass,
-- cream) and a place, and returns SVG text.

local Svg = require("solarui/art/svg")

local n, pol, group = Svg.n, Svg.pol, Svg.group
local sin, pi = math.sin, math.pi

local Flora = {}

-- `body` (drawn pointing up from the origin) repeated `count` times around
-- (cx, cy), each `r0` out from the centre. `body` may be a function of the index.
local function around(cx, cy, r0, count, body, start)
    local out = {}
    for i = 0, count - 1 do
        local b = type(body) == "function" and body(i) or body
        out[#out + 1] = string.format('<g transform="translate(%s %s) rotate(%s) translate(0 %s)">%s</g>',
            n(cx), n(cy), n((start or 0) + i * 360 / count), n(-r0), b)
    end
    return table.concat(out)
end
Flora.around = around

-- A pointed petal growing up from the origin.
local function petal(c, L, W, fill, sw)
    return Svg.path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z",
        n(-W), n(-L * .3), n(-W * .8), n(-L * .8), n(-L), n(W * .8), n(-L * .8), n(W), n(-L * .3)), fill, c.ink, sw or 1.6)
end
Flora.petal = petal

-- A smooth leaf pointing right from (x, y), with its midrib and, when it is
-- large, side veins.
function Flora.leaf(c, x, y, rot, L, W, fill, bare)
    local body = Svg.path(string.format("M0 0 C%s %s %s %s %s 0 C%s %s %s %s 0 0Z",
        n(L * .2), n(-W * 1.25), n(L * .7), n(-W * .95), n(L), n(L * .7), n(W * .55), n(L * .3), n(W * .85)), fill or c.leaf, c.ink, 1.8)
    if not bare then
        body = body .. Svg.line(string.format("M0 0 Q%s %s %s 0", n(L * .5), n(-W * .25), n(L * .9)), c.ink, 1.1)
        if L >= 36 then
            for _i, t in ipairs({ .28, .48, .66 }) do
                body = body .. Svg.line(string.format("M%s %s L%s %s M%s %s L%s %s", n(L * t), n(-W * .1), n(L * (t + .15)), n(-W * .62 * (1.1 - t)),
                    n(L * t), n(-W * .02), n(L * (t + .15)), n(W * .42 * (1.1 - t))), c.ink, .9)
            end
        end
    end
    return group(x, y, rot, body)
end

-- The outline of a saw-edged leaflet pointing right from the origin.
local function leafletPath(L, W, teeth)
    local function width(t) return W * sin(pi * t ^ 0.72) ^ 0.85 end
    local top, bottom = {}, {}
    for k = 0, teeth - 1 do
        local t0, t1 = k / teeth, (k + 0.62) / teeth
        top[#top + 1] = { L * t0, -width(t0) }
        top[#top + 1] = { L * (t1 + 0.03), -width(t1) * 1.18 }
        bottom[#bottom + 1] = { L * t0, width(t0) }
        bottom[#bottom + 1] = { L * (t1 + 0.03), width(t1) * 1.18 }
    end
    local pts = top
    pts[#pts + 1] = { L, 0 }
    for i = #bottom, 2, -1 do pts[#pts + 1] = bottom[i] end
    return Svg.poly(pts, true)
end

-- One saw-edged leaflet with its veins.
local function leaflet(c, x, y, rot, L, fill)
    local W = L * .3
    local body = Svg.path(leafletPath(L, W, 5), fill or c.leaf, c.ink, 1.5)
        .. Svg.line(string.format("M0 0 L%s 0", n(L * .9)), c.ink, 1)
    if L >= 26 then
        for _i, t in ipairs({ .25, .45, .65 }) do
            body = body .. Svg.line(string.format("M%s 0 L%s %s M%s 0 L%s %s", n(L * t), n(L * (t + .13)), n(-W * .7 * (1.15 - t)),
                n(L * t), n(L * (t + .13)), n(W * .7 * (1.15 - t))), c.ink, .8)
        end
    end
    return group(x, y, rot, body)
end
Flora.leaflet = leaflet

-- A rose leaf: three or five saw-edged leaflets on a stalk `L` long, pointing
-- right from (x, y).
function Flora.roseLeaf(c, x, y, rot, L, count, fill)
    local body = Svg.line(string.format("M0 0 Q%s %s %s 0", n(L * .3), n(-L * .04), n(L * .58)), c.ink, 1.6)
    local pairs_at = count == 5 and { .2, .42 } or { .3 }
    for _i, t in ipairs(pairs_at) do
        body = body .. leaflet(c, L * t, 0, -52, L * .36, fill) .. leaflet(c, L * t, 0, 52, L * .36, fill)
    end
    body = body .. leaflet(c, L * .56, 0, 0, L * .46, fill)
    return group(x, y, rot, body)
end

-- A five-lobed vine leaf growing up from its stalk at (x, y), `s` tall.
function Flora.vineLeaf(c, x, y, rot, s, fill)
    local tips = { { -112, .72 }, { -58, .95 }, { 0, 1.18 }, { 58, .95 }, { 112, .72 } }
    local d = { "M0 0" }
    local function p(r, a)
        local px, py = pol(r, a, 0, -s * .12)
        return n(px) .. " " .. n(py)
    end
    d[#d + 1] = string.format("Q%s %s %s", n(-s * .62), n(s * .2), p(s * tips[1][2], tips[1][1]))
    for i = 2, #tips do
        local mid = (tips[i - 1][1] + tips[i][1]) / 2
        d[#d + 1] = string.format("Q%s %s", p(s * .36, mid), p(s * tips[i][2], tips[i][1]))
    end
    d[#d + 1] = string.format("Q%s %s 0 0Z", n(s * .62), n(s * .2))
    local body = Svg.path(table.concat(d, " "), fill or c.leaf, c.ink, 1.7)
    local veins = {}
    for _i, t in ipairs(tips) do veins[#veins + 1] = "M0 " .. n(-s * .04) .. " L" .. p(s * t[2] * .8, t[1]) end
    body = body .. Svg.line(table.concat(veins, " "), c.ink, .9)
    return group(x, y, rot, body)
end

-- A thin tendril growing up from (x, y) and curling over, `s` tall; `flip`
-- curls it the other way.
function Flora.tendril(c, x, y, rot, s, flip)
    local pts = Svg.join(Svg.spline({ { 0, 0 }, { -s * .1, -s * .5 }, { 0, -s } }, 8), Svg.spiral(s * .3, -s, s * .3, 1.7, -90))
    return group(x, y, rot, Svg.path(Svg.ribbon(pts, Svg.taper(2.8, .9)), c.stem), flip and -1 or 1, 1)
end

-- A thorn on a stem at (x, y), pointing along `rot`.
function Flora.thorn(c, x, y, rot, s)
    return group(x, y, rot, Svg.path(string.format("M%s 0 L0 %s L%s 0Z", n(-s * .4), n(-s), n(s * .4)), c.stem, c.ink, 1.2))
end

-- A full rose seen from above, `r` across its outer petals.
function Flora.rose(c, cx, cy, r, rot, fill, fill2)
    fill, fill2 = fill or c.bloom, fill2 or c.bloom2
    local function rosePetal(L, W, colour)
        return Svg.path(string.format("M0 0 C%s %s %s %s %s %s Q0 %s %s %s C%s %s %s %s 0 0Z",
            n(-W * 1.05), n(-L * .2), n(-W * 1.3), n(-L * .92), n(-W * .28), n(-L * 1.03), n(-L * .9), n(W * .28), n(-L * 1.03),
            n(W * 1.3), n(-L * .92), n(W * 1.05), n(-L * .2)), colour, c.ink, 1.5)
            .. Svg.line(string.format("M%s %s Q0 %s %s %s", n(-W * .62), n(-L * .7), n(-L * .9), n(W * .62), n(-L * .7)), c.ink, .9)
    end
    local body = around(0, 0, r * .55, 5, petal(c, r * .62, r * .2, c.leaf, 1.3), 36)
        .. around(0, 0, 0, 5, rosePetal(r, r * .5, fill))
        .. around(0, 0, 0, 5, rosePetal(r * .74, r * .4, fill2), 36)
        .. around(0, 0, 0, 4, rosePetal(r * .5, r * .3, fill), 15)
        .. around(0, 0, 0, 3, rosePetal(r * .3, r * .2, fill2), 50)
        .. Svg.circle(0, 0, r * .1, fill, c.ink, 1.2)
    return group(cx, cy, rot or 0, body)
end

-- A small rose for where a full one would blur: a disc with a spiral of petals.
function Flora.roseGlyph(c, cx, cy, r, rot, fill)
    local body = around(0, 0, r * .7, 4, petal(c, r * .5, r * .22, c.leaf, 1.1), 45)
        .. Svg.circle(0, 0, r, fill or c.bloom, c.ink, 1.6)
        .. Svg.line(Svg.poly(Svg.spiral(0, 0, r * .72, 1.5, 0)), c.ink, 1.2)
        .. Svg.line(string.format("M%s %s Q%s %s %s %s", n(-r * .9), n(r * .1), n(-r * .5), n(r * .75), n(r * .3), n(r * .86)), c.ink, 1)
    return group(cx, cy, rot or 0, body)
end

-- A rosebud growing up from its stalk at (x, y), `s` tall to the shoulder.
function Flora.rosebud(c, x, y, rot, s, fill)
    local body = Svg.path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z",
        n(-s * .6), n(-s * .25), n(-s * .55), n(-s), n(-s * 1.45), n(s * .55), n(-s), n(s * .6), n(-s * .25)), fill or c.bloom, c.ink, 1.7)
        .. Svg.line(string.format("M%s %s C%s %s %s %s %s %s", n(-s * .26), n(-s * .25), n(-s * .1), n(-s * .7), n(s * .3), n(-s * .9), n(s * .05), n(-s * 1.38)), c.ink, 1)
        .. Svg.path(string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s 0 0Z",
            n(-s * .62), n(-s * .2), n(-s * .6), n(-s * .7), n(-s * .3), n(-s * .98), n(-s * .3), n(-s * .6), n(-s * .15), n(-s * .3)), c.leaf, c.ink, 1.3)
        .. Svg.path(string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s 0 0Z",
            n(s * .55), n(-s * .1), n(s * .85), n(-s * .4), n(s * .92), n(-s * .78), n(s * .6), n(-s * .5), n(s * .3), n(-s * .3)), c.leaf, c.ink, 1.3)
        .. Svg.ellipse(0, s * .08, s * .22, s * .2, 0, c.leaf, c.ink, 1.3)
    return group(x, y, rot, body)
end

-- A ginkgo leaf fanning up from its stalk at (x, y), `R` tall.
function Flora.ginkgo(c, x, y, rot, R, fill, bare)
    local function p(r, a)
        local px, py = pol(r, a)
        return n(px) .. " " .. n(py)
    end
    local d = string.format("M0 0 Q%s %s %s Q%s %s Q%s %s Q%s %s Q%s %s Q%s %s 0 0Z",
        n(-R * .4), n(-R * .02), p(R, -72), p(R * 1.22, -52), p(R * 1.03, -24), p(R * .95, -8), p(R * .66, 0),
        p(R * .95, 8), p(R * 1.03, 24), p(R * 1.22, 52), p(R, 72), n(R * .4), n(-R * .02))
    local body = Svg.path(d, fill or c.gold, c.ink, 2)
    if not bare then
        local veins = {}
        for _i, a in ipairs({ -58, -44, -30, -16, 16, 30, 44, 58 }) do veins[#veins + 1] = "M0 0 L" .. p(R * .86, a) end
        body = body .. Svg.line(table.concat(veins, " "), c.ink, 1)
    end
    return group(x, y, rot, body)
end

-- A fern frond growing up from (x, y), `H` tall.
function Flora.frond(c, x, y, rot, H, fill)
    local function bend(t) return H * .12 * sin(t * 2.2) end
    local body, pairs_n = "", 6
    for i = 0, pairs_n - 1 do
        local t = .14 + .78 * i / pairs_n
        local L = H * .4 * (1 - i / pairs_n * .7)
        body = body .. Flora.leaf(c, bend(t), -H * t, -28, L, L * .3, fill, true) .. Flora.leaf(c, bend(t), -H * t, 208, L * .92, L * .3, fill, true)
    end
    local spine = {}
    for k = 0, 12 do spine[#spine + 1] = { bend(k / 12), -H * k / 12 } end
    body = body .. Svg.line(Svg.poly(spine), c.ink, 2.6) .. Flora.leaf(c, bend(1), -H, -80, H * .16, H * .05, fill, true)
    return group(x, y, rot, body)
end

-- A fern crozier: a stalk rising from (x, y) that curls over into a spiral of
-- radius `r`, with small leaves along its back.
function Flora.crozier(c, x, y, rot, H, r, fill)
    local pts = Svg.join(Svg.spline({ { 0, 0 }, { -r * .5, -H * .45 }, { -r, -H } }, 10), Svg.spiral(0, -H, r, 1.8, -90))
    local body = Svg.stem(pts, Svg.taper(r * .34, r * .16), fill or c.leaf, c.ink, 1.8)
    for _i, k in ipairs({ .12, .24, .36, .46, .56 }) do
        local p = pts[math.max(1, math.floor(#pts * k))]
        local q = pts[math.max(1, math.floor(#pts * k)) + 1]
        local ang = math.deg(math.atan2(q[2] - p[2], q[1] - p[1])) - 115
        body = body .. Flora.leaf(c, p[1], p[2], ang, r * .5, r * .15, fill, true)
    end
    return group(x, y, rot, body)
end

-- A peacock feather's eye centred on (x, y), `s` half its height, its quill
-- running down.
function Flora.peacock(c, x, y, rot, s)
    local barbs = {}
    for a = -156, 156, 12 do
        local px, py = s * .76 * sin(math.rad(a)), -s * math.cos(math.rad(a)) - s * .05
        barbs[#barbs + 1] = string.format("M%s %s L%s %s", n(px), n(py), n(px * 1.36), n((py + s * .05) * 1.3 - s * .05))
    end
    local body = Svg.line(table.concat(barbs, " "), c.stem, 1.3)
        .. Svg.line(string.format("M0 %s C%s %s %s %s %s %s", n(s * .9), n(s * .1), n(s * 1.4), n(-s * .1), n(s * 1.8), n(-s * .3), n(s * 2.1)), c.ink, 2.6)
        .. Svg.path(string.format("M0 %s C%s %s %s %s 0 %s C%s %s %s %s 0 %sZ", n(s * .95), n(-s * .8), n(s * .5), n(-s * .75), n(-s * .75),
            n(-s * 1.05), n(s * .75), n(-s * .75), n(s * .8), n(s * .5), n(s * .95)), c.leaf, c.ink, 2)
        .. Svg.ellipse(0, -s * .12, s * .46, s * .58, 0, c.gold, c.ink, 1.6)
        .. Svg.ellipse(0, -s * .08, s * .33, s * .4, 0, c.glass, c.ink, 1.3)
        .. Svg.ellipse(0, 0, s * .17, s * .2, 0, c.ink)
    return group(x, y, rot, body)
end

-- A sunflower: `count` petals, the first `filled` of them golden (the rest
-- pale), around a seeded disc of radius `rd`.
function Flora.sunflower(c, cx, cy, rd, pl, count, filled)
    local body = around(0, 0, rd * .8, count, petal(c, pl * .86, pl * .2, c.sage, 1.2), 180 / count)
        .. around(0, 0, rd * .8, count, function(i) return petal(c, pl, pl * .25, i < filled and c.gold or c.cream, 1.5) end)
        .. Svg.circle(0, 0, rd, c.bloom, c.ink, 2)
        .. Svg.dots(0, 0, rd * .74, 16, rd * .11, c.ink) .. Svg.dots(0, 0, rd * .46, 10, rd * .11, c.ink) .. Svg.dots(0, 0, rd * .18, 4, rd * .11, c.ink)
    return group(cx, cy, 0, body)
end

-- A daisy whose blunt petals read as the teeth of a wheel.
function Flora.daisy(c, cx, cy, r, count, fill)
    local function blunt(L, W)
        return Svg.path(string.format("M%s 0 L%s %s Q0 %s %s %s L%s 0Z", n(-W * .7), n(-W), n(-L * .8), n(-L * 1.12), n(W), n(-L * .8), n(W * .7)), fill or c.cream, c.ink, 1.6)
    end
    local body = around(0, 0, r * .36, count, blunt(r * .64, r * .17))
        .. Svg.circle(0, 0, r * .42, c.gold, c.ink, 2)
        .. Svg.circle(0, 0, r * .16, c.bloom, c.ink, 1.4)
    return group(cx, cy, 0, body)
end

-- A water-lily pad of radius `R` with its notch at angle `notch`.
function Flora.lilypad(c, cx, cy, R, notch, fill)
    local x1, y1 = pol(R, notch + 15)
    local x2, y2 = pol(R, notch - 15)
    local body = Svg.path(string.format("M0 0 L%s %s A%s %s 0 1 1 %s %sZ", n(x1), n(y1), n(R), n(R), n(x2), n(y2)), fill or c.leaf, c.ink, 2)
    local veins = {}
    for k = 1, 8 do
        local vx, vy = pol(R * .88, notch + 15 + k * 330 / 9)
        veins[#veins + 1] = string.format("M0 0 L%s %s", n(vx), n(vy))
    end
    return group(cx, cy, 0, body .. Svg.line(table.concat(veins, " "), c.stem, 1))
end

-- A water lily seen from above: `outer` long petals and `inner` short ones.
function Flora.lily(c, cx, cy, L, outer, inner)
    local body = around(0, 0, L * .12, outer, petal(c, L, L * .3, c.cream, 1.5))
        .. around(0, 0, L * .08, inner, petal(c, L * .62, L * .24, c.bloom2, 1.3), 180 / inner)
        .. Svg.circle(0, 0, L * .2, c.gold, c.ink, 1.5)
    return group(cx, cy, 0, body)
end

-- A dandelion clock of radius `R`.
function Flora.dandelion(c, cx, cy, R)
    local rays, tufts = {}, {}
    for i = 0, 17 do
        local a = i * 20
        local x0, y0 = pol(R * .14, a)
        local x1, y1 = pol(R * .76, a)
        local xa, ya = pol(R * .9, a - 7)
        local xb, yb = pol(R * .9, a + 7)
        rays[#rays + 1] = string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1))
        tufts[#tufts + 1] = string.format("M%s %s L%s %s L%s %s", n(xa), n(ya), n(x1), n(y1), n(xb), n(yb))
    end
    local body = Svg.circle(0, 0, R, c.cream, c.ink, 2) .. Svg.line(table.concat(rays, " "), c.ink, 1.1)
        .. Svg.line(table.concat(tufts, " "), c.ink, 1) .. Svg.circle(0, 0, R * .13, c.gold, c.ink, 1.5)
    return group(cx, cy, 0, body)
end

-- A dragonfly heading up from (x, y); `wings` of its four are coloured in.
function Flora.dragonfly(c, x, y, rot, s, wings)
    wings = wings or 4
    local body = ""
    for i, w in ipairs({ { 68, 1.55 }, { -68, 1.55 }, { 108, 1.3 }, { -108, 1.3 } }) do
        body = body .. string.format('<g transform="translate(0 %s) rotate(%s)">%s</g>', n(-s * .3), n(w[1]),
            petal(c, s * w[2], s * .24, i <= wings and c.sky or c.cream, 1.3))
    end
    body = body .. Svg.path(string.format("M%s %s L%s %s L%s %s L%s %sZ", n(-s * .12), n(-s * .2), n(s * .12), n(-s * .2), n(s * .05), n(s * 2.1), n(-s * .05), n(s * 2.1)), c.glass, c.ink, 1.4)
        .. Svg.ellipse(0, -s * .3, s * .2, s * .32, 0, c.glass, c.ink, 1.4)
        .. Svg.circle(0, -s * .74, s * .2, c.ink)
    return group(x, y, rot, body)
end

-- An honesty seed pod: a paper disc with its seeds showing.
function Flora.honesty(c, cx, cy, r)
    return Svg.circle(cx, cy, r, c.pale, c.ink, 2) .. Svg.circle(cx, cy, r * .66, c.cream, c.ink, 1)
        .. Svg.dots(cx, cy, r * .3, 3, r * .22, c.ink)
end

-- A tulip growing up from (x, y), `s` tall in the cup.
function Flora.tulip(c, x, y, rot, s, fill)
    local body = Svg.path(string.format("M0 0 C%s %s %s %s %s %s L%s %s L0 %s L%s %s L%s %s C%s %s %s %s 0 0Z",
        n(-s * .7), n(-s * .05), n(-s * .7), n(-s * .7), n(-s * .5), n(-s * 1.15), n(-s * .22), n(-s * .8), n(-s * 1.25), n(s * .22), n(-s * .8),
        n(s * .5), n(-s * 1.15), n(s * .7), n(-s * .7), n(s * .7), n(-s * .05)), fill or c.bloom, c.ink, 1.7)
        .. Svg.line(string.format("M%s %s Q%s %s 0 %s M%s %s Q%s %s 0 %s", n(-s * .22), n(-s * .8), n(-s * .3), n(-s * .3), n(-s * .02),
            n(s * .22), n(-s * .8), n(s * .3), n(-s * .3), n(-s * .02)), c.ink, 1)
    return group(x, y, rot, body)
end

return Flora
