-- The drawings of the home screen's garden: the climbing rose up the left
-- edge, the halo behind the cover with its roses, the Continue plaque, the
-- progress vine, the three reading flowers and the shelf. Each is
-- function(c, vw, vh, param) returning SVG for a vw x vh canvas.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n, vary = Svg.n, Svg.vary
local sin, pi = math.sin, math.pi

local Home = {}

-- What grows at stop `k` of the climbing rose, at (x, y) where the stem
-- heads `ang`: leaves in overlapping pairs, thorns, side shoots, buds and
-- blooms by turns. `reach` is how far it may spread, `size` and `lean` make
-- no two stops alike.
local function growth(c, k, x, y, ang, reach, size, lean)
    local right, left = ang + 60 + lean, ang - 60 + lean
    local kind = k % 6
    if kind == 0 then
        return Flora.roseLeaf(c, x, y, right + 34, reach * .5 * size, 3, c.sage)
            .. Flora.roseLeaf(c, x, y, right, reach * .78 * size, 5)
    elseif kind == 1 then
        return Flora.thorn(c, x, y, ang + 180, 9) .. Flora.tendril(c, x, y, ang + 30, reach * .26, true)
            .. Flora.roseLeaf(c, x, y, left, reach * .44 * size, 3)
    elseif kind == 2 then
        return Flora.roseLeaf(c, x, y, left - 20, reach * .34 * size, 3, c.sage)
            .. Flora.shoot(c, x, y, right - 20, reach * .62 * size, "bud")
    elseif kind == 3 then
        return Flora.roseLeaf(c, x, y, left, reach * .42 * size, 3)
            .. Flora.roseLeaf(c, x, y, right + 18, reach * .6 * size, 3)
    elseif kind == 4 then
        local sx, sy = x + reach * .5, y - reach * .2
        local warm = k % 12 == 4
        return Svg.stem(Svg.spline({ { x, y }, { x + reach * .22, y + reach * .02 }, { sx, sy } }, 6), Svg.taper(4.4, 2.8), c.stem, c.ink, 1.3)
            .. Flora.roseLeaf(c, x + reach * .2, y, ang + 128, reach * .42, 3)
            .. Flora.roseLeaf(c, x + reach * .24, y - reach * .04, ang + 20, reach * .36, 3, c.sage)
            .. Flora.rose(c, sx, sy, reach * .33, k * 23, warm and c.bloom or c.bloom2, warm and c.bloom2 or c.bloom)
    end
    return Flora.thorn(c, x, y, ang, 9) .. Flora.roseLeaf(c, x, y, left, reach * .46 * size, 3)
        .. Flora.shoot(c, x, y, right, reach * .44 * size, "tendril", c.sage)
end

-- The climbing stem dressed from `from` to `to` along it: a stop about every
-- `step` units, never quite evenly.
local function dress(c, pts, from, to, step, reach)
    local out = {}
    local k, d = 0, from
    while d < to do
        local x, y, ang = Svg.along(pts, d)
        out[#out + 1] = growth(c, k, x, y, ang, reach, .82 + .3 * vary(k, 1), (vary(k, 2) - .5) * 26)
        d = d + step * (.78 + .44 * vary(k, 3))
        k = k + 1
    end
    return table.concat(out)
end

-- The climbing rose up the left edge: it rises from the bottom of the canvas,
-- sways unevenly, thickens at its joints and curls over into a crozier at
-- the top.
function Home.vine_left(c, vw, vh)
    local way = { { vw * .36, vh } }
    local y, side, i = vh - 150, 1, 0
    while y > 150 do
        way[#way + 1] = { vw * ((side > 0 and .45 or .31) + (vary(i, 4) - .5) * .06), y }
        y, side, i = y - 150 - 50 * vary(i, 5), -side, i + 1
    end
    way[#way + 1] = { vw * .32, 96 }
    way[#way + 1] = { vw * .34, 60 }
    local r = vw * .22
    local stem = Svg.spline(way, 12)
    local top = stem[#stem]
    local pts = Svg.join(stem, Svg.spiral(top[1] + r, top[2], r, 1.7, -90))
    local len = Svg.length(stem)
    local function width(t) return (11 - 6.5 * t) * (1 + .09 * sin(t * 46)) end
    return dress(c, stem, 70, len - 60, 62, vw * .52)
        .. Svg.stem(pts, width, c.stem, c.ink, 1.7)
end

-- The shorter vine up the right edge, leaning left, ending in a bud: ivy
-- leaves of several sizes, some doubled, and a tendril now and then.
function Home.vine_right(c, vw, vh)
    local stem = Svg.spline({ { vw * .7, vh }, { vw * .82, vh * .72 }, { vw * .6, vh * .44 }, { vw * .74, vh * .2 }, { vw * .5, 34 } }, 12)
    local out = {}
    local d, k = 46, 0
    local len = Svg.length(stem)
    while d < len - 30 do
        local x, y, ang = Svg.along(stem, d)
        local turn = ang + (k % 2 == 0 and -60 or 60) + (vary(k, 6) - .5) * 30
        local s = vw * (.22 + .12 * vary(k, 7))
        if k % 3 == 0 then out[#out + 1] = Flora.vineLeaf(c, x, y, turn + (k % 2 == 0 and -40 or 40), s * .7, c.sage) end
        out[#out + 1] = Flora.vineLeaf(c, x, y, turn, s, k % 4 == 3 and c.sage or c.leaf)
        if k % 3 == 1 then out[#out + 1] = Flora.tendril(c, x, y, ang - 60, vw * .26, k % 2 == 0) end
        d, k = d + 58 + 30 * vary(k, 8), k + 1
    end
    local tx, ty = stem[#stem][1], stem[#stem][2]
    return table.concat(out) .. Svg.stem(stem, Svg.taper(8, 3.5), c.stem, c.ink, 1.6) .. Flora.rosebud(c, tx, ty, -28, vw * .2)
end

-- The line under the status row: a whiplash tendril with a few vine leaves.
function Home.tendril_top(c, vw, vh)
    local pts = Svg.spline({ { 4, vh * .86 }, { vw * .2, vh * .34 }, { vw * .42, vh * .62 }, { vw * .62, vh * .36 }, { vw * .84, vh * .3 }, { vw - 8, vh * .56 } }, 14)
    local out = {}
    for i, f in ipairs({ .16, .33, .5, .7, .88 }) do
        local x, y, ang = Svg.along(pts, Svg.length(pts) * f)
        if i % 2 == 1 then
            out[#out + 1] = Flora.vineLeaf(c, x, y, ang + (i % 4 == 1 and 150 or -30) + 90, vh * .44, i == 3 and c.sage or c.leaf)
        else
            out[#out + 1] = Flora.tendril(c, x, y, ang + 30, vh * .34, i == 4)
        end
    end
    return table.concat(out) .. Svg.path(Svg.ribbon(pts, Svg.swell(6, 1.2)), c.ink)
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
        .. Flora.roseLeaf(c, vw * .1, vh * .6, -150, vw * .24, 3)
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
    local x, y = Svg.along(pts, Svg.length(pts) * .45)
    return Flora.roseLeaf(c, x, y, -80, vw * .5, 3)
        .. Flora.roseLeaf(c, vw * .3, vh * .62, 30, vw * .44, 3)
        .. Flora.tendril(c, vw * .5, vh * .42, 70, vw * .22)
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

-- Where the progress vine's stem is at `x` (shared with what is set on it).
local function vineY(x, vw, vh)
    return vh * .56 + vh * .13 * sin(2 * pi * (x - 6) / (vw * .243))
end

-- The progress vine: grown and in leaf as far as `pct` percent, a rose at
-- its tip; the rest a dotted line with buds still closed.
function Home.progress(c, vw, vh, pct)
    pct = math.max(0, math.min(100, tonumber(pct) or 0))
    local x0, x1 = 8, vw - 22
    local tip = x0 + (x1 - x0) * pct / 100
    local wave = vw * .243
    local out, dots, grown = {}, {}, {}
    for x = x0, x1, 9 do
        if x > tip + 14 then dots[#dots + 1] = Svg.circle(x, vineY(x, vw, vh), 1.5, c.ink) end
    end
    for x = x0, tip, 4 do grown[#grown + 1] = { x, vineY(x, vw, vh) } end
    grown[#grown + 1] = { tip, vineY(tip, vw, vh) }
    -- a leaf or a closed bud at every crest and trough
    local k = 0
    local x = x0 + wave * .25
    while x < x1 do
        local up = k % 2 == 1
        local y = vineY(x, vw, vh)
        if x < tip - 10 then
            out[#out + 1] = Flora.leaf(c, x, y, up and -62 or 62, vh * .46, vh * .15)
        elseif x > tip + 22 then
            out[#out + 1] = Flora.leaf(c, x, y, up and -62 or 62, vh * .26, vh * .08, c.cream, true)
        end
        x, k = x + wave / 2, k + 1
    end
    local stem = #grown > 1 and Svg.stem(grown, Svg.taper(6.5, 4.5), c.stem, c.ink, 1.5) or ""
    return table.concat(dots) .. table.concat(out) .. stem
        .. Flora.roseGlyph(c, tip + 4, vineY(tip, vw, vh), vh * .2, pct * 3, c.bloom)
end

-- The three book buttons, each its own plant.
function Home.btn_details(c, vw, vh)
    return Flora.frond(c, vw * .5, vh * .98, -8, vh * .8)
end
function Home.btn_bookmarks(c, vw, vh)
    return Svg.line(string.format("M%s %s q6 12 -4 22", n(vw * .5), n(vh * .78)), c.ink, 3)
        .. Flora.ginkgo(c, vw * .5, vh * .8, 8, vh * .47)
end
function Home.btn_highlights(c, vw, vh)
    return Flora.peacock(c, vw * .54, vh * .38, 14, vh * .3)
end

-- Today's reading: a sunflower with `filled` of its twenty petals golden.
function Home.sunflower(c, vw, vh, filled)
    return Flora.sunflower(c, vw / 2, vh / 2, vw * .2, vw * .27, 20, tonumber(filled) or 0)
end

-- Where the seven days sit along the week's stem: { {x, y}, ... }.
function Home.weekSpots(vw, vh)
    local stem = Svg.spline({ { vw * .03, vh * .8 }, { vw * .26, vh * .88 }, { vw * .5, vh * .66 }, { vw * .76, vh * .64 }, { vw * .97, vh * .42 } }, 12)
    local len = Svg.length(stem)
    local spots = {}
    for i = 0, 6 do
        local x, y = Svg.along(stem, len * (.05 + i * .15))
        spots[#spots + 1] = { x, y }
    end
    return spots, stem
end

-- The week: a rose in bloom for each day read ("1"), a closed bud for the
-- others, on one stem; `days` is seven characters, oldest first.
function Home.week(c, vw, vh, days)
    days = tostring(days or "0000000")
    local spots, stem = Home.weekSpots(vw, vh)
    local out = {}
    for i, s in ipairs(spots) do
        local top_x, top_y = s[1] + (i % 2) * 6 - 3, s[2] - vh * (.3 + (i % 3) * .04)
        out[#out + 1] = Svg.line(string.format("M%s %s Q%s %s %s %s", n(s[1]), n(s[2]), n(s[1] - 6), n(s[2] - vh * .16), n(top_x), n(top_y)), c.stem, 2.6)
        if days:sub(i, i) == "1" then
            out[#out + 1] = Flora.roseGlyph(c, top_x, top_y, vh * (i == 7 and .16 or .13), i * 40, i % 2 == 0 and c.bloom2 or c.bloom)
        else
            out[#out + 1] = Flora.rosebud(c, top_x, top_y + vh * .06, -8, vh * .09, c.cream)
        end
    end
    return Svg.stem(stem, Svg.taper(6, 3.5), c.leaf, c.ink, 1.5) .. table.concat(out)
end

-- The year: a water lily on its pad, a petal for each book finished.
function Home.lily(c, vw, vh, books)
    books = math.max(0, math.min(16, tonumber(books) or 0))
    local pad = Flora.lilypad(c, vw * .53, vh * .55, vw * .4, 118)
    if books == 0 then
        return pad .. Flora.rosebud(c, vw * .47, vh * .6, 0, vw * .1, c.cream)
    end
    local outer = math.max(1, math.ceil(books * .6))
    return pad .. Flora.lily(c, vw * .47, vh * .49, vw * .24, outer, books - outer)
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
