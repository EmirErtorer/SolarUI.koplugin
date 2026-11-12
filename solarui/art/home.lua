-- The drawings of the home screen's garden: the climbing rose up the left
-- edge, the clock's cartouche, the halo behind the cover with its roses, the Continue plaque, the
-- progress vine and the shelf. Each is
-- function(c, vw, vh, param) returning SVG for a vw x vh canvas.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Insects = require("solarui/art/insects")
local Season = require("solarui/art/season")
local Svg = require("solarui/art/svg")

local n, group, vary = Svg.n, Svg.group, Svg.vary
local sin = math.sin

local Home = {}

-- What grows at stop `k` of the climbing rose, at (x, y) where the stem
-- heads `ang`: stops alternate sides and each carries one thing (a leaf of
-- five or three leaflets, a budding shoot, a tendril with a leaf, a rose on a
-- stalk), so neighbours never lie on one another. `reach` is how far it may
-- spread, `size` and `lean` make no two stops alike.
local function growth(c, k, x, y, ang, reach, size, lean)
    local side = k % 2 == 0 and 1 or -1
    if side < 0 then reach = math.min(reach, (x - 6) / 1.25) end
    local out = ang + side * (62 + lean * .4)
    local kind = k % 5
    if kind == 0 then
        return Flora.roseLeaf(c, x, y, out, reach * 1.1 * size, 5)
    elseif kind == 1 then
        return Flora.shoot(c, x, y, out - side * 10, reach * 1.0 * size, "bud")
    elseif kind == 2 then
        return Flora.roseLeaf(c, x, y, out, reach * .8 * size, 3, c.sage)
            .. Flora.tendril(c, x, y, ang - side * 70, reach * .26, side > 0)
    elseif kind == 3 then
        local warm = k % 10 == 3
        local sx, sy = x + side * reach * .5, y - reach * .2
        return Svg.stem(Svg.spline({ { x, y }, { x + side * reach * .22, y + reach * .02 }, { sx, sy } }, 6), Svg.taper(4.4, 2.8), c.stem, c.ink, 1.3)
            .. Flora.rose(c, sx, sy, reach * .3, k * 23, warm and c.bloom or c.bloom2, warm and c.bloom2 or c.bloom)
    end
    return Flora.shoot(c, x, y, out - side * 10, reach * .85 * size, "tendril", c.sage)
end

-- The climbing stem dressed from `from` to `to` along it: a stop about every
-- `step` units, never quite evenly.
local function dress(c, pts, from, to, step, reach)
    local out = {}
    local k, d = 0, from
    while d < to do
        local x, y, ang = Svg.along(pts, d)
        out[#out + 1] = growth(c, k, x, y, ang, reach, .82 + .2 * vary(k, 1), (vary(k, 2) - .5) * 20)
        d = d + step * (.9 + .3 * vary(k, 3))
        k = k + 1
    end
    return table.concat(out)
end

-- The path of the climbing rose's stem up a vw x vh canvas. `anchor` ({ x, y },
-- or nil) is a place it must pass through: where the rose cluster's shoots
-- grow out of it.
local function leftStem(vw, vh, anchor)
    local way = { { vw * .36, vh } }
    local y, side, i = vh - 150, 1, 0
    while y > 150 do
        -- bends close to the anchor are left out so the stem runs straight through it
        if not (anchor and math.abs(y - anchor[2]) < 110) then
            way[#way + 1] = { vw * ((side > 0 and .45 or .31) + (vary(i, 4) - .5) * .06), y }
        elseif anchor and not anchor.used then
            way[#way + 1] = { anchor[1], anchor[2] }
            anchor.used = true
        end
        y, side, i = y - 150 - 50 * vary(i, 5), -side, i + 1
    end
    way[#way + 1] = { vw * .32, 96 }
    way[#way + 1] = { vw * .34, 60 }
    return Svg.spline(way, 12)
end

-- The climbing rose up the left edge: it rises from the bottom of the canvas,
-- sways unevenly, thickens at its joints and curls over into a crozier at
-- the top.
function Home.vine_left(c, vw, vh, param)
    -- param: the season, then where the rose cluster grows from it ("season:x:y")
    local season, ax, ay = tostring(param or "2"):match("^(%d+):([%d%.]+):([%d%.]+)$")
    c = Season.palette(c, tonumber(season or param) or 2)
    local r = vw * .22
    local stem = leftStem(vw, vh, ax and { tonumber(ax), tonumber(ay) } or nil)
    local top = stem[#stem]
    local pts = Svg.join(stem, Svg.spiral(top[1] + r, top[2], r, 1.7, -90))
    local len = Svg.length(stem)
    local function width(t) return (11 - 6.5 * t) * (1 + .09 * sin(t * 46)) end
    return dress(c, stem, 70, len - 60, 56, vw * .52)
        .. Svg.stem(pts, width, c.stem, c.ink, 1.7)
end

-- A knot on the climbing rose where the rose cluster's shoots leave it: a
-- swelling of the stem with a leaf on each side, over the ends of the shoots.
function Home.vine_knot(c, vw, vh)
    local x, y = vw / 2, vh * .56
    return Flora.leaf(c, x, y, 205, vw * .42, vh * .2, c.sage, true) .. Flora.leaf(c, x, y, -25, vw * .42, vh * .2, nil, true)
        .. Svg.ellipse(x, y, vw * .3, vh * .22, 0, c.stem, c.ink, 1.7)
        .. Svg.line(string.format("M%s %s q%s %s %s 0", n(x - vw * .2), n(y), n(vw * .2), n(-vh * .08), n(vw * .4)), c.ink, 1.1)
end

-- The shorter vine up the right edge, leaning left, ending in a bud: ivy
-- leaves of several sizes, some doubled, and a tendril now and then.
function Home.vine_right(c, vw, vh, season)
    c = Season.palette(c, tonumber(season) or 2)
    local stem = Svg.spline({ { vw * .7, vh }, { vw * .82, vh * .72 }, { vw * .6, vh * .44 }, { vw * .74, vh * .2 }, { vw * .5, 34 } }, 12)
    local out = {}
    local d, k = 46, 0
    local len = Svg.length(stem)
    while d < len - 30 do
        local x, y, ang = Svg.along(stem, d)
        local side = (k % 2 == 0 or x > vw * .6) and -1 or 1
        local turn = ang + side * (62 + (vary(k, 6) - .5) * 24)
        local s = vw * (.2 + .08 * vary(k, 7))
        local reach = s * .4
        local px, py = Svg.pol(reach, turn + 90, x, y)
        out[#out + 1] = Svg.line(string.format("M%s %s L%s %s", n(x), n(y), n(px), n(py)), c.ink, 3.2)
            .. Svg.line(string.format("M%s %s L%s %s", n(x), n(y), n(px), n(py)), c.stem, 1.6)
            .. Flora.vineLeaf(c, px, py, turn + 90, s, k % 3 == 2 and c.sage or c.leaf)
        if k % 3 == 1 then out[#out + 1] = Flora.tendril(c, x, y, ang - side * 70, vw * .22, side > 0) end
        d, k = d + 62 + 30 * vary(k, 8), k + 1
    end
    local tx, ty = stem[#stem][1], stem[#stem][2]
    return table.concat(out) .. Svg.stem(stem, Svg.taper(8, 3.5), c.stem, c.ink, 1.6) .. Flora.rosebud(c, tx, ty, -28, vw * .2)
end

-- The outline of the clock's cartouche on a vw x vh canvas, drawn `i` units
-- inside its edge: upright sides under a low arch.
local function cartouche(vw, vh, i)
    local function p(x, y) return n(x) .. " " .. n(y) end
    local l, r, t, b = 4 + i, vw - 4 - i, 4 + i, vh - 4 - i
    return string.format("M%s C%s %s %s C%s %s %s C%s %s %s C%s %s %sZ",
        p(l + 20, b), p(l + 4, b), p(l - 2, vh * .64), p(l + 4, vh * .46),
        p(l + 16, vh * .14 + i * .5), p(vw * .3, t), p(vw / 2, t),
        p(vw * .7, t), p(r - 16, vh * .14 + i * .5), p(r - 4, vh * .46),
        p(r + 2, vh * .64), p(r - 4, b), p(r - 20, b))
end

-- The clock's cartouche: an arched panel with a fine golden line inside it,
-- a rosette between two leaves at its crown, a curl at each foot and a short
-- rule between the time and the date.
function Home.clock_frame(c, vw, vh)
    local m = vw / 2
    local function foot(x, ccw)
        return Svg.line(Svg.poly(Svg.spiral(x, vh - 15, 10, 1.3, 180, ccw)), c.ink, 2.2)
    end
    local ry = vh * .635
    return foot(12, false) .. foot(vw - 12, true)
        .. Svg.path(cartouche(vw, vh, 0), c.cream, c.ink, 2.8)
        .. Svg.line(cartouche(vw, vh, 7), c.gold, 1.8)
        .. Svg.line(string.format("M%s %s L%s %s M%s %s L%s %s", n(m - vw * .2), n(ry), n(m - 9), n(ry), n(m + 9), n(ry), n(m + vw * .2), n(ry)), c.ink, 1.3)
        .. Svg.circle(m, ry, 3.2, c.bloom, c.ink, 1)
        .. Flora.leaf(c, m - 5, 5, 172, 30, 9, nil, true) .. Flora.leaf(c, m + 5, 5, 8, 30, 9, nil, true)
        .. Svg.circle(m, 4, 8, c.gold, c.ink, 1.6) .. Svg.circle(m, 4, 3, c.bloom, c.ink, 1)
end

-- A leaf, a bud or a leaf of ivy on a short curved stalk that starts at (x, y)
-- on the line and heads `ang`, so that whatever grows is joined to the line.
local function branch(c, x, y, ang, len, tip, fill)
    local end_ = {
        leaf = function() return Flora.leaf(c, len, 0, -8, len * 1.5, len * .5, fill) end,
        ivy = function() return Flora.vineLeaf(c, len, 0, 80, len * 1.25, fill) end,
        bud = function() return Flora.rosebud(c, len, 0, 90, len * .8, fill) end,
    }
    return group(x, y, ang, Svg.line(string.format("M-2 0 Q%s %s %s 0", n(len * .5), n(-len * .22), n(len)), c.stem, 2.6) .. end_[tip]())
end

-- A whiplash line running out from the clock's cartouche with leaves, ivy and
-- a bud, each on its own stalk from the line: `side` "l" runs left with its
-- growth up, "r" runs right with it hanging.
function Home.clock_wing(c, vw, vh, side)
    local line, pts = Flora.whiplash(c, vw, vh * .56)
    local len, up = Svg.length(pts), side == "l"
    local out = {}
    for i, node in ipairs({ { .2, "leaf", 20, 58 }, { .42, "bud", 17, 70 }, { .62, "ivy", 16, 56 }, { .84, "leaf", 19, 64 } }) do
        local x, y, ang = Svg.along(pts, len * node[1])
        out[#out + 1] = branch(c, x, y, ang + node[4] * (up and -1 or 1), node[3], node[2], i % 2 == 0 and c.sage or nil)
    end
    local body = table.concat(out) .. line
    return Svg.group(up and vw or 0, up and vh * .34 or vh * .1, 0, body, up and -1 or 1, 1)
end

-- A bee flying below the branch, a dotted loop behind it.
function Home.bee(c, vw, vh)
    local way = Svg.spline({ { vw * .04, vh * .3 }, { vw * .2, vh * .68 }, { vw * .36, vh * .42 }, { vw * .3, vh * .2 }, { vw * .46, vh * .35 }, { vw * .64, vh * .55 } }, 3)
    local dots = {}
    for i = 1, #way, 4 do dots[#dots + 1] = way[i] end
    return Insects.trail(c, dots, 3) .. Insects.bee(c, vw * .78, vh * .6, -12, vh * .46)
end

-- The halo behind the cover: a golden ring of tiles round a pale disc.
function Home.halo(c, vw)
    local m = vw / 2
    local ro, ri = m - 4, m * .815
    local spokes = {}
    for i = 0, 35 do
        local x0, y0 = Svg.pol(ri, i * 10, m, m)
        local x1, y1 = Svg.pol(ro, i * 10, m, m)
        spokes[#spokes + 1] = string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1))
    end
    local beads = {}
    for i = 0, 17 do
        local x, y = Svg.pol((ro + ri) / 2, i * 20 + 5, m, m)
        beads[#beads + 1] = Svg.circle(x, y, (ro - ri) * .26, i % 3 == 0 and c.bloom or c.cream, c.ink, 1.2)
    end
    return Svg.circle(m, m, ro, c.gold, c.ink, 3)
        .. Svg.line(table.concat(spokes, " "), c.ink, 1.2)
        .. table.concat(beads)
        .. Svg.circle(m, m, ri, c.pale, c.ink, 2.4)
        .. Svg.dots(m, m, ri * .92, 44, 8, c.gold)
        .. Svg.circle(m, m, ri * .84, nil, c.ink, 1.1)
        .. Svg.dots(m, m, ri * .77, 30, 5, c.bloom)
end

-- Roses, a bud and leaves gathered at the cover's lower corner.
function Home.rose_cluster(c, vw, vh)
    local function shoot(way, w)
        return Svg.stem(Svg.spline(way, 8), Svg.taper(w, w * .55), c.stem, c.ink, 1.4)
    end
    return shoot({ { vw * .06, vh }, { vw * .2, vh * .74 }, { vw * .34, vh * .62 } }, 6)
        .. shoot({ { vw * .06, vh }, { vw * .1, vh * .62 }, { vw * .36, vh * .36 }, { vw * .5, vh * .3 } }, 7)
        .. shoot({ { vw * .1, vh * .7 }, { vw * .3, vh * .3 }, { vw * .74, vh * .16 } }, 5)
        .. Flora.roseLeaf(c, vw * .18, vh * .8, 20, vw * .46, 5)
        .. Flora.roseLeaf(c, vw * .16, vh * .6, -118, vw * .22, 3)
        .. Flora.roseLeaf(c, vw * .44, vh * .5, 38, vw * .44, 5)
        .. Flora.roseLeaf(c, vw * .4, vh * .24, -70, vw * .3, 3)
        .. Flora.roseLeaf(c, vw * .56, vh * .46, 4, vw * .34, 3, c.sage)
        .. Flora.shoot(c, vw * .24, vh * .5, -66, vw * .3, "tendril", c.sage)
        .. Flora.rosebud(c, vw * .74, vh * .16, 52, vw * .11)
        .. Flora.rose(c, vw * .34, vh * .66, vw * .21, 20, c.bloom2, c.bloom)
        .. Flora.rose(c, vw * .52, vh * .32, vw * .28, 0, c.bloom, c.bloom2)
end

-- A budding shoot beside the halo.
function Home.sprig(c, vw, vh)
    local pts = Svg.spline({ { vw * .06, vh * .94 }, { vw * .3, vh * .62 }, { vw * .52, vh * .4 }, { vw * .8, vh * .2 } }, 8)
    local len = Svg.length(pts)
    local x1, y1, a1 = Svg.along(pts, len * .3)
    local x2, y2, a2 = Svg.along(pts, len * .55)
    local x3, y3, a3 = Svg.along(pts, len * .72)
    return Flora.roseLeaf(c, x1, y1, a1 + 58, vw * .36, 3)
        .. Flora.roseLeaf(c, x2, y2, a2 - 62, vw * .4, 3)
        .. Flora.tendril(c, x3, y3, a3 + 60, vw * .2)
        .. Svg.stem(pts, Svg.taper(5, 2.6), c.stem, c.ink, 1.4)
        .. Flora.rosebud(c, vw * .8, vh * .2, 50, vw * .15)
end

-- The Continue plaque: an uneven cartouche held by two hooks, like the sign
-- over a Metro entrance.
function Home.plaque(c, vw, vh)
    local function sx(v) return n(v * vw / 350) end
    local function sy(v) return n(v * vh / 84) end
    local function shape(inset)
        local i = inset
        return string.format("M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %s C%s %s %s %s %s %s C%s %s %s %s %s %sZ",
            sx(6 + i * 2), sy(44), sx(40 + i), sy(4 + i), sx(110), sy(14 + i), sx(175), sy(10 + i),
            sx(245), sy(6 + i), sx(305 - i), sy(2 + i), sx(344 - i * 2), sy(42),
            sx(310 - i), sy(80 - i), sx(245), sy(72 - i), sx(175), sy(74 - i),
            sx(105), sy(76 - i), sx(46 + i), sy(82 - i), sx(6 + i * 2), sy(44))
    end
    return Svg.line(string.format("M%s %s C%s %s %s %s %s %s M%s %s C%s %s %s %s %s %s", sx(30), sy(8), sx(6), sy(14), sx(2), sy(34), sx(12), sy(42),
        sx(322), sy(6), sx(346), sy(12), sx(350), sy(32), sx(340), sy(40)), c.ink, 2.6)
        .. Svg.path(shape(0), c.accent, c.ink, 3)
        .. Svg.line(shape(8), c.sage, 1.3)
end

-- A whiplash rule: it swells, thins and ends in a curl.
function Home.whiplash(c, vw, vh)
    return (Flora.whiplash(c, vw, vh))
end

-- The way the progress vine takes across a vw x vh canvas: a wave whose
-- swings are never the same width or height twice.
local function vineWay(vw, vh)
    local way = { { 10, vh * .62 } }
    local x, i = 10, 0
    while true do
        x = x + vw * (.07 + .08 * vary(i, 31))
        if x > vw - 44 then break end
        way[#way + 1] = { x, vh * (.56 + (i % 2 == 0 and -1 or 1) * (.05 + .15 * vary(i, 32))) }
        i = i + 1
    end
    way[#way + 1] = { vw - 26, vh * .5 }
    return Svg.spline(way, 8)
end

-- What grows at stop `k` of the read part of the progress vine, at (x, y)
-- where it heads `ang`: a broad leaf, a rose leaf, a bud on a short stalk,
-- two small leaves or a tendril, on whichever side, `s` the canvas height.
local function vineGrowth(c, k, x, y, ang, s)
    local side = vary(k, 33) > .5 and 1 or -1
    local turn = ang + side * (48 + 34 * vary(k, 34))
    local kind = math.floor(vary(k, 35) * 5)
    if kind == 0 then
        local L = s * (.42 + .2 * vary(k, 36))
        return Flora.leaf(c, x, y, turn, L, L * .34)
    elseif kind == 1 then
        return Flora.roseLeaf(c, x, y, turn, s * .6, 3)
    elseif kind == 2 then
        local bx, by = Svg.pol(s * .26, turn + 90, x, y)
        return Svg.line(string.format("M%s %s L%s %s", n(x), n(y), n(bx), n(by)), c.stem, 2.4)
            .. Flora.rosebud(c, bx, by, turn + 90, s * .12, k % 2 == 0 and c.bloom or c.bloom2)
    elseif kind == 3 then
        return Flora.leaf(c, x, y, turn, s * .36, s * .13) .. Flora.leaf(c, x, y, ang - side * 62, s * .27, s * .1, c.sage)
    end
    return Flora.tendril(c, x, y, turn + 90, s * .3, side > 0) .. Flora.leaf(c, x, y, ang - side * 50, s * .3, s * .11, c.sage)
end

-- The progress vine: lush as far as `pct` percent, with leaves, buds and
-- tendrils along a thick stem and a rose in bloom at its tip; the way still
-- to go a thin line with pale leaf outlines. Unread, it is a bud at the start.
function Home.progress(c, vw, vh, pct)
    pct = math.max(0, math.min(100, tonumber(pct) or 0))
    local pts = vineWay(vw, vh)
    local len = Svg.length(pts)
    local tip = len * pct / 100
    local faint = setmetatable({ ink = c.muted, leaf = c.soft, sage = c.soft }, { __index = c })
    local out = { Svg.line(Svg.poly(pts), c.muted, 1.7) }
    local lush = {}
    local d, k = 16, 0
    while d < len - 8 do
        local x, y, ang = Svg.along(pts, d)
        if d < tip - 18 then
            lush[#lush + 1] = vineGrowth(c, k, x, y, ang, vh)
        elseif d > tip + 24 and k % 2 == 0 then
            out[#out + 1] = Flora.leaf(faint, x, y, ang + (k % 4 == 0 and -58 or 58), vh * (.2 + .1 * vary(k, 38)), vh * .075, nil, true)
        end
        d, k = d + 19 + 22 * vary(k, 37), k + 1
    end
    out[#out + 1] = table.concat(lush)
    local tx, ty, tang = Svg.along(pts, tip)
    if pct == 0 then
        return table.concat(out) .. Flora.leaf(c, tx, ty, tang + 70, vh * .3, vh * .1) .. Flora.rosebud(c, tx, ty + 4, 24, vh * .2)
    end
    local grown = Svg.head(pts, tip)
    if #grown > 1 and tip > 6 then out[#out + 1] = Svg.stem(grown, Svg.taper(7, 4.6), c.stem, c.ink, 1.5) end
    return table.concat(out) .. Flora.leaf(c, tx, ty, tang - 128, vh * .34, vh * .12) .. Flora.leaf(c, tx, ty, tang + 118, vh * .3, vh * .11, c.sage)
        .. Flora.rose(c, tx + 2, ty, vh * (.23 + .05 * pct / 100), pct * 3, c.bloom, c.bloom2)
end

-- The three book buttons, each its own plant.
function Home.btn_details(c, vw, vh)
    return Flora.frond(c, vw * .5, vh * .98, -8, vh * .8)
end
function Home.btn_bookmarks(c, vw, vh)
    return Blooms.maple(c, vw * .5, vh * .84, 8, vh * .72)
end
function Home.btn_highlights(c, vw, vh)
    return Svg.line(string.format("M%s %s q-8 14 2 %s", n(vw * .5), n(vh * .6), n(vh * .36)), c.stem, 3.4)
        .. Blooms.karahindiba(c, vw * .5, vh * .38, vh * .34)
end

-- The shelf: a rail with curled ends and ironwork curves beneath it.
function Home.shelf(c, vw, vh)
    local y = vh * .3
    local left = Svg.spiral(18, y + 9, 9, 1.2, 0, true)
    local rail = {}
    for i = #left, 1, -1 do rail[#rail + 1] = left[i] end
    rail = Svg.poly(Svg.join(rail, Svg.spiral(vw - 18, y + 9, 9, 1.2, 0)))
    local irons = {}
    for _i, f in ipairs({ .16, .5, .84 }) do
        local x = vw * f
        irons[#irons + 1] = string.format("M%s %s c30 %s 70 %s 96 0 M%s %s c26 %s 58 %s 80 0", n(x - 48), n(y + 4), n(vh * .42), n(vh * .42),
            n(x - 40), n(y + 4), n(vh * .24), n(vh * .24))
    end
    return Svg.line(table.concat(irons, " "), c.ink, 1.4) .. Svg.line(rail, c.ink, 7.5) .. Svg.line(rail, c.stem, 3.5)
end

-- Small growth standing on the shelf between the books; `gaps` is how many
-- there are, evenly spread.
function Home.sprouts(c, vw, vh, gaps)
    gaps = tonumber(gaps) or 5
    local out = {}
    for i = 1, gaps do
        local x = vw * (i - .5) / gaps
        local kind = i % 4
        if kind == 1 then
            out[#out + 1] = Flora.crozier(c, x, vh, 0, vh * .5, vh * .2)
        elseif kind == 2 then
            out[#out + 1] = Svg.line(string.format("M%s %s q-2 %s 3 %s", n(x), n(vh), n(-vh * .25), n(-vh * .46)), c.stem, 2.4)
                .. Flora.rosebud(c, x + 3, vh * .56, 8, vh * .18, c.bloom2)
        elseif kind == 3 then
            out[#out + 1] = Svg.line(string.format("M%s %s q0 %s -4 %s", n(x), n(vh), n(-vh * .2), n(-vh * .36)), c.stem, 2.4)
                .. Flora.ginkgo(c, x - 4, vh * .66, -18, vh * .34, c.gold) .. Flora.ginkgo(c, x + 2, vh * .84, 46, vh * .24, c.sage, true)
        else
            out[#out + 1] = Flora.tendril(c, x, vh, 0, vh * .5) .. Flora.vineLeaf(c, x, vh * .9, 40, vh * .3)
        end
    end
    return table.concat(out)
end

return Home
