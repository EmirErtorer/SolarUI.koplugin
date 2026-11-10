-- The small extra drawings of the home page: ornaments for the corners of
-- its border and the middle of its foot, the sun or moon of the hour, a
-- butterfly, a snail and a fan of peacock feathers. Each is
-- function(c, vw, vh, param) returning SVG for a vw x vh canvas.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n, group = Svg.n, Svg.group

local Ornaments = {}

-- One corner of the border: a golden bead where the two rules meet, a curl
-- and a leaf running along each rule. `k` (0 to 3) turns it to the corner.
function Ornaments.frame_corner(c, vw, _vh, k)
    local body = Flora.leaf(c, 22, 21, 6, 46, 12, nil, true) .. Flora.leaf(c, 21, 22, 84, 46, 12, nil, true)
        .. Svg.line(Svg.poly(Svg.spiral(36, 36, 11, 1.7, 180)), c.ink, 2.2)
        .. Svg.line("M14 14 C22 22 26 28 30 30", c.ink, 2.2)
        .. Svg.circle(14, 14, 6.5, c.gold, c.ink, 1.6) .. Svg.circle(14, 14, 2.2, c.bloom, c.ink, 1)
    local m = vw / 2
    return group(m, m, (tonumber(k) or 0) * 90, group(-m, -m, 0, body))
end

-- The bud in the middle of the border's foot, between two leaves.
function Ornaments.frame_bud(c, vw, vh)
    local m = vw / 2
    return Flora.leaf(c, m, vh, -150, vw * .3, vw * .08, nil, true) .. Flora.leaf(c, m, vh, -30, vw * .3, vw * .08, nil, true)
        .. Flora.rosebud(c, m, vh, 0, vh * .55)
end

-- The sun or the moon of the hour: phase 0 night, 1 dawn, 2 day, 3 dusk.
function Ornaments.dayphase(c, vw, vh, phase)
    phase = tonumber(phase) or 2
    local cx, hy = vw / 2, vh * .72
    local horizon = Svg.line(string.format("M%s %s C%s %s %s %s %s %s", n(vw * .06), n(hy), n(vw * .3), n(hy - 5), n(vw * .7), n(hy + 5), n(vw * .94), n(hy)), c.stem, 3)
    local function star(x, y, s)
        return Svg.path(string.format("M%s %s L%s %s L%s %s L%s %s L%s %s L%s %s L%s %s L%s %sZ", n(x), n(y - s), n(x + s * .25), n(y - s * .25), n(x + s), n(y),
            n(x + s * .25), n(y + s * .25), n(x), n(y + s), n(x - s * .25), n(y + s * .25), n(x - s), n(y), n(x - s * .25), n(y - s * .25)), c.gold, c.ink, 1)
    end
    if phase == 0 then
        local r = vh * .3
        return star(vw * .2, vh * .3, 6) .. star(vw * .8, vh * .22, 5) .. star(vw * .74, vh * .5, 4) .. horizon
            .. Svg.path(string.format("M%s %s A%s %s 0 1 1 %s %s A%s %s 0 0 0 %s %sZ", n(cx + r * .5), n(hy - r * 1.3), n(r), n(r), n(cx - r * .3), n(hy - r * .1),
                n(r * .78), n(r * .78), n(cx + r * .5), n(hy - r * 1.3)), c.cream, c.ink, 2)
    end
    local r = vh * .27
    local sun = phase == 3 and c.bloom or c.gold
    local rays = {}
    for a = -80, 80, 20 do
        local x0, y0 = Svg.pol(r * 1.25, a, cx, hy)
        local x1, y1 = Svg.pol(r * (math.abs(a) % 40 == 20 and 1.55 or 1.7), a, cx, hy)
        rays[#rays + 1] = string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1))
    end
    if phase == 2 then
        local out = Flora.around(0, 0, r * .9, 12, Flora.petal(c, r * .55, r * .17, c.gold, 1.3)) .. Svg.circle(0, 0, r * .85, c.pale, c.ink, 2)
            .. Svg.circle(0, 0, r * .45, c.gold, c.ink, 1.4)
        return group(cx, vh * .4, 0, out) .. horizon
    end
    local bits = Svg.line(table.concat(rays, " "), c.ink, 2)
        .. Svg.path(string.format("M%s %s A%s %s 0 0 1 %s %sZ", n(cx - r), n(hy), n(r), n(r), n(cx + r), n(hy)), sun, c.ink, 2)
    return bits .. (phase == 3 and (star(vw * .16, vh * .26, 5) .. star(vw * .84, vh * .2, 4)) or "") .. horizon
end

-- A butterfly seen from above, wings spread.
function Ornaments.butterfly(c, vw, vh)
    local m = vw / 2
    local function side(s)
        local function p(x, y) return n(m + s * (x - m)) .. " " .. n(y) end
        return Svg.path(string.format("M%s C%s %s %s C%s %s %sZ", p(m, vh * .46), p(m - vw * .2, vh * .04), p(vw * .04, 0), p(vw * .02, vh * .36),
            p(0, vh * .5), p(m - vw * .12, vh * .52), p(m, vh * .52)), c.sky, c.ink, 1.7)
            .. Svg.path(string.format("M%s C%s %s %s C%s %s %sZ", p(m, vh * .54), p(m - vw * .1, vh * .58), p(vw * .1, vh * .62), p(vw * .16, vh * .8),
                p(vw * .2, vh * .98), p(m - vw * .1, vh * .9), p(m, vh * .7)), c.bloom2, c.ink, 1.7)
            .. Svg.circle(m + s * vw * .22, vh * .3, vw * .06, c.cream, c.ink, 1.1) .. Svg.circle(m + s * vw * .22, vh * .8, vw * .035, c.cream, c.ink, 1)
            .. Svg.line(string.format("M%s L%s M%s L%s M%s L%s", p(m, vh * .48), p(vw * .12, vh * .18), p(m, vh * .5), p(vw * .08, vh * .38),
                p(m, vh * .6), p(vw * .22, vh * .86)), c.ink, 1)
    end
    return side(1) .. side(-1) .. Svg.ellipse(m, vh * .5, vw * .035, vh * .22, 0, c.ink)
        .. Svg.line(string.format("M%s %s C%s %s %s %s %s %s M%s %s C%s %s %s %s %s %s", n(m), n(vh * .3), n(m - 2), n(vh * .14), n(m - vw * .1), n(vh * .06), n(m - vw * .12), n(vh * .02),
            n(m), n(vh * .3), n(m + 2), n(vh * .14), n(m + vw * .1), n(vh * .06), n(m + vw * .12), n(vh * .02)), c.ink, 1.3)
end

-- A snail crawling right, a golden spiral shell on its back.
function Ornaments.snail(c, vw, vh)
    local s = vw / 70
    local body = Svg.path("M4 42 C4 34 12 32 24 33 H44 C52 33 56 30 56 22 C56 16 58 12 62 12 C66 12 67 17 65 22 C64 28 68 33 68 38 C68 41 66 42 62 42Z", c.pale, c.ink, 1.8)
        .. Svg.line("M59 14 L56 5 M64 13 L67 4", c.ink, 1.5) .. Svg.circle(56, 4, 1.8, c.ink) .. Svg.circle(67, 3, 1.8, c.ink)
        .. Svg.circle(32, 22, 16, c.gold, c.ink, 1.8) .. Svg.line(Svg.poly(Svg.spiral(32, 22, 12, 1.8, 90)), c.ink, 1.5)
    return group(0, vh * .02, 0, body, s, s)
end

-- A fan of peacock feathers round the centre of a vw x vh canvas, their eyes
-- at `reach`, for the part of a ring that peeks out from behind a halo.
function Ornaments.peacock_fan(c, vw, vh)
    local cx, cy, reach = vw / 2, vh / 2, vw * .43
    local out = {}
    for _i, a in ipairs({ 38, 58, 78 }) do
        local x, y = Svg.pol(reach, a, cx, cy)
        local qx, qy = Svg.pol(reach * .5, a, cx, cy)
        out[#out + 1] = Svg.line(string.format("M%s %s L%s %s", n(qx), n(qy), n(x), n(y)), c.stem, 3) .. Flora.peacock(c, x, y, a, 24)
    end
    return table.concat(out)
end

return Ornaments
