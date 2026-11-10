-- The pictures a typeset book cover can wear behind its title: stained
-- glass, a garden of flowers, a golden halo and peacock scales. Each is
-- function(c, vw, vh, variant) returning SVG for a vw x vh canvas, `variant`
-- (0 to 11, picked from the title) turning the colours and the layout so that
-- books differ. Drawn once per size and variant, then shared by every book.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Frames = require("solarui/art/frames")
local Svg = require("solarui/art/svg")

local n, vary, pol = Svg.n, Svg.vary, Svg.pol

local CoverArt = {}

-- The panes' colours for these colours, turned by the variant.
local function panes(c, v)
    local all = { c.gold, c.sky, c.bloom2, c.leaf, c.glass, c.cream, c.bloom }
    local out = {}
    for i = 1, #all do out[i] = all[(i + v - 1) % #all + 1] end
    return out
end

-- A full-canvas rectangle.
local function sheet(vw, vh, fill)
    return Svg.path(string.format("M0 0 L%s 0 L%s %s L0 %sZ", n(vw), n(vw), n(vh), n(vh)), fill)
end

-- A ring sector of a fan: from radius r0 to r1 between angles a0 and a1,
-- round (cx, cy), as path text.
local function sector(cx, cy, r0, r1, a0, a1)
    local pts = {}
    for i = 0, 3 do
        local x, y = pol(r1, a0 + (a1 - a0) * i / 3, cx, cy)
        pts[#pts + 1] = n(x) .. " " .. n(y)
    end
    if r0 <= 0 then
        pts[#pts + 1] = n(cx) .. " " .. n(cy)
    else
        for i = 3, 0, -1 do
            local x, y = pol(r0, a0 + (a1 - a0) * i / 3, cx, cy)
            pts[#pts + 1] = n(x) .. " " .. n(y)
        end
    end
    return "M" .. table.concat(pts, " L") .. "Z"
end

-- Stained glass: a fan of coloured panes in the arch, a lattice of lozenges
-- below it and a rose in a roundel between, all held by dark lead.
function CoverArt.cover_glass(c, vw, vh, v)
    v = tonumber(v) or 0
    local cols = panes(c, v)
    local m, fy = vw / 2, Frames.rise(vw, vh) * 1.15
    local out = { sheet(vw, vh, c.ink) }
    local K = 5 + 2 * (v % 3)
    for k = 0, K - 1 do
        local a0, a1 = -90 + k * 180 / K, -90 + (k + 1) * 180 / K
        for ring = 0, 1 do
            local r0, r1 = ring == 0 and 0 or vw * .3, ring == 0 and vw * .3 or vw * .85
            out[#out + 1] = Svg.path(sector(m, fy, r0, r1, a0, a1), cols[(k * 3 + ring * 2) % #cols + 1], c.ink, 2.6)
        end
    end
    local dw = vw / (3 + .6 * (math.floor(v / 3) % 4))
    local dh = dw * 1.35
    for i = 0, math.ceil((vh - fy) / (dh / 2)) + 1 do
        for j = -1, 5 do
            local x, y = m + (j - 2 + (i % 2) * .5) * dw, fy + i * dh / 2
            out[#out + 1] = Svg.path(string.format("M%s %s L%s %s L%s %s L%s %sZ", n(x - dw / 2), n(y), n(x), n(y - dh / 2), n(x + dw / 2), n(y), n(x), n(y + dh / 2)),
                cols[math.floor(vary(i * 9 + j, v + 3) * 100) % #cols + 1], c.ink, 2.6)
        end
    end
    local cy, R = vh * .42, vw * .24
    out[#out + 1] = Svg.circle(m, cy, R, c.cream, c.ink, 3.4) .. Svg.circle(m, cy, R * .84, nil, c.gold, 2.2)
        .. (v % 4 == 3 and Flora.daisy(c, m, cy, R * .74, 12) or Flora.rose(c, m, cy, R * .74, v * 22))
    return table.concat(out)
end

-- A climbing stem of one side of the garden, from the foot of the canvas
-- up to its head, with leaves on both sides and a bud at the top.
local function climber(c, vw, vh, side, v)
    local x0 = side < 0 and vw * .1 or vw * .9
    local pts = Svg.spline({ { x0, vh }, { x0 - side * vw * .06, vh * .72 }, { x0 + side * vw * .05, vh * .45 }, { x0 - side * vw * .04, vh * .2 }, { x0, vh * .02 } }, 8)
    local len = Svg.length(pts)
    local out = {}
    for i = 1, 6 do
        local x, y, ang = Svg.along(pts, len * (i * .15))
        local s = vw * (.16 + .1 * vary(i, v + 7))
        out[#out + 1] = Flora.leaf(c, x, y, ang + (i % 2 == 0 and 50 or -50) * side + 90 * (side < 0 and 0 or 0), s, s * .34)
    end
    local tx, ty, tang = Svg.along(pts, len)
    return table.concat(out) .. Svg.stem(pts, Svg.taper(vw * .035, vw * .018), c.stem, c.ink, 1.5)
        .. Flora.rosebud(c, tx, ty, tang + 90, vw * .07, v % 2 == 0 and c.bloom or c.bloom2)
end

-- A garden: climbers up both sides and a main flower in the upper middle,
-- a rose, a few tulips or a cluster of daisies, over a pale ground.
function CoverArt.cover_garden(c, vw, vh, v)
    v = tonumber(v) or 0
    local m = vw / 2
    local out = { sheet(vw, vh, v % 2 == 0 and c.pale or c.soft), climber(c, vw, vh, -1, v), climber(c, vw, vh, 1, v) }
    local kind = math.floor(v / 2) % 3
    if kind == 0 then
        out[#out + 1] = Flora.leaf(c, m, vh * .56, -150, vw * .3, vw * .1) .. Flora.leaf(c, m, vh * .56, -30, vw * .3, vw * .1)
            .. Svg.line(string.format("M%s %s L%s %s", n(m), n(vh * .62), n(m), n(vh * .3)), c.stem, vw * .03)
            .. Flora.rose(c, m, vh * .28, vw * .26, v * 17)
    elseif kind == 1 then
        for i, dx in ipairs({ -.2, 0, .2 }) do
            local x, top = m + dx * vw, vh * (i == 2 and .22 or .3)
            out[#out + 1] = Svg.line(string.format("M%s %s L%s %s", n(m), n(vh * .66), n(x), n(top + vw * .12)), c.stem, vw * .028)
                .. Flora.tulip(c, x, top + vw * .12, dx * 40, vw * .2, i == 2 and c.bloom or c.bloom2)
        end
    else
        for i, p in ipairs({ { -.16, .26, .17 }, { .17, .32, .14 }, { 0, .46, .15 } }) do
            out[#out + 1] = Svg.line(string.format("M%s %s L%s %s", n(m), n(vh * .66), n(m + p[1] * vw), n(vh * p[2])), c.stem, vw * .025)
                .. Flora.daisy(c, m + p[1] * vw, vh * p[2], vw * p[3], 10 + i)
        end
    end
    return table.concat(out)
end

-- A golden halo of tiles round a pale disc with a lily in it, between two
-- flowing whiplash lines that rise from the foot.
function CoverArt.cover_halo(c, vw, vh, v)
    v = tonumber(v) or 0
    local m, cy, R = vw / 2, vh * .36, vw * .4
    local out = { sheet(vw, vh, v % 2 == 0 and c.cream or c.pale) }
    for _i, side in ipairs({ -1, 1 }) do
        local x0 = side < 0 and vw * .04 or vw * .96
        local pts = Svg.spline({ { x0, vh }, { x0 + side * vw * .05, vh * .72 }, { x0 - side * vw * .06, vh * .42 }, { x0 + side * vw * .02, vh * .16 }, { x0 - side * vw * .1, vh * .03 } }, 8)
        local len = Svg.length(pts)
        for i, f in ipairs({ .3, .52, .74 }) do
            local x, y, ang = Svg.along(pts, len * f)
            out[#out + 1] = Flora.leaf(c, x, y, ang + side * (i % 2 == 0 and -70 or 70), vw * .13, vw * .045, c.leaf, true)
        end
        out[#out + 1] = Svg.path(Svg.ribbon(pts, Svg.swell(vw * .035, 1)), c.ink)
    end
    out[#out + 1] = Svg.circle(m, cy, R, c.gold, c.ink, 2.4) .. Svg.dots(m, cy, R * .82, 14 + 4 * (v % 2), R * .17, c.cream)
        .. Svg.dots(m, cy, R * .82, 7 + 2 * (v % 2), R * .13, v % 2 == 0 and c.bloom or c.sky) .. Svg.circle(m, cy, R * .66, c.pale, c.ink, 1.8)
        .. Svg.circle(m, cy, R * .58, nil, c.gold, 1.2) .. (v % 3 == 0 and Flora.rose(c, m, cy, R * .5, v * 20) or v % 3 == 1 and Blooms.lily(c, m, cy, R * .5) or Flora.daisy(c, m, cy, R * .5, 12))
    return table.concat(out)
end

-- Peacock scales: overlapping rows of round scales, each an eye of two
-- colours and a golden dot, the rows turned by the variant.
function CoverArt.cover_scales(c, vw, vh, v)
    v = tonumber(v) or 0
    local cols = panes(c, v)
    local s = vw / (3.4 + .7 * (v % 4))
    local R = s * .62
    local out = { sheet(vw, vh, c.ink) }
    for i = 0, math.ceil(vh / (s * .5)) + 1 do
        for j = -1, 5 do
            local x, y = (j + (i % 2) * .5) * s, i * s * .5
            local a = cols[(i + j * 2) % #cols + 1]
            local b = cols[(i + j * 2 + 3) % #cols + 1]
            out[#out + 1] = Svg.circle(x, y, R, a, c.ink, 2.2) .. Svg.circle(x, y, R * .62, b, c.ink, 1.6) .. Svg.circle(x, y, R * .28, c.gold, c.ink, 1.3)
        end
    end
    return table.concat(out)
end

return CoverArt
