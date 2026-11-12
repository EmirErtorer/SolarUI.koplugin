-- The year's reading goal as an apple tree: goal_tree(c, vw, vh, pct) draws a
-- tree on a small lawn whose crown bears an apple at as many of its places as
-- `pct` percent of the goal, the rest still in blossom. The tree is drawn
-- once in its own units (U tall, the middle of its top edge at the origin)
-- and fitted into the middle of any canvas with room left on every side.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Tree = require("solarui/art/treekit")

local n = Svg.n
local sin, cos, pi = math.sin, math.cos, math.pi

local Goal = {}

-- The height of the drawing in its own units, and its width.
local U, WIDE = 400, 1.1

-- The masses of the crown, back to front: { x, y, rx, ry, lobes, back },
-- in parts of U.
local CROWN = {
    { .03, .205, .25, .17, 11, true }, { -.25, .275, .2, .16, 10, true }, { .26, .285, .2, .155, 10, true },
    { -.33, .42, .17, .12, 9 }, { .335, .425, .165, .115, 9 }, { -.015, .375, .25, .15, 12 },
}

-- A list of points given in parts of U, in units.
local function way(list)
    local out = {}
    for i, p in ipairs(list) do out[i] = { p[1] * U, p[2] * U } end
    return out
end

-- The outline of one mass of leaves: an oval whose edge is a run of round
-- lobes of uneven size, each leaning down the side of the crown the lobe is on.
local function massPath(m, seed)
    local cx, cy, rx, ry, count = m[1] * U, m[2] * U, m[3] * U, m[4] * U, m[5]
    local function at(a, r) return n(cx + rx * r * sin(a)) .. " " .. n(cy - ry * r * cos(a)) end
    -- the lobes meet at uneven steps round the oval
    local turn = {}
    for k = 0, count do turn[k] = 2 * pi * (k + .5 + (k < count and k > 0 and (Svg.vary(k, seed + 9) - .5) * .36 or 0)) / count end
    local d = { "M" .. at(turn[0], 1) }
    for k = 0, count - 1 do
        local a0, da = turn[k], turn[k + 1] - turn[k]
        local h = (.2 + .1 * Svg.vary(k, seed)) * da * count / (2 * pi)
        local lean = sin(a0 + da / 2) >= 0 and .12 or -.12
        d[#d + 1] = string.format("C%s %s %s", at(a0 + da * (.08 + lean), 1 + h * 1.25), at(a0 + da * (.92 + lean), 1 + h * 1.25), at(a0 + da, 1))
    end
    return table.concat(d) .. "Z"
end

-- Is the point (x, y), in parts of U, inside the crown and `inset` clear of its edge?
local function inCrown(x, y, inset)
    for _i, m in ipairs(CROWN) do
        local dx, dy = (x - m[1]) / (m[3] - inset), (y - m[2]) / (m[4] - inset)
        if dx * dx + dy * dy < 1 then return true end
    end
    return false
end

-- The crown: the masses at the back in the darker green, those in front
-- lighter, and small pale leaves scattered between the places for fruit.
local function crown(c)
    local out = {}
    for i, m in ipairs(CROWN) do
        out[#out + 1] = Svg.path(massPath(m, i), m[6] and c.stem or c.leaf, c.ink, 2.6)
    end
    return table.concat(out)
end

-- The places for fruit: a staggered grid kept to the inside of the crown, so
-- that no two touch; each is { x, y, order } with the order apples come in.
local function places()
    local spots, row = {}, 0
    for gy = .08, .52, .093 do
        for gx = -.5, .5, .114 do
            local id = row * 31 + math.floor((gx + .5) * 20)
            local x = gx + (row % 2) * .057 + (Svg.vary(id, 6) - .5) * .022
            local y = gy + (Svg.vary(id, 7) - .5) * .022
            if inCrown(x, y, .05) then spots[#spots + 1] = { x * U, y * U, Svg.vary(#spots + 1, 5) } end
        end
        row = row + 1
    end
    return spots
end

-- Small pale leaves in the gaps of the fruit grid, by twos.
local function leafMarks(c)
    local out, row = {}, 0
    for gy = .1265, .52, .093 do
        for gx = -.5, .5, .114 do
            local id = row * 13 + math.floor((gx + .5) * 20)
            local x, y = gx + ((row + 1) % 2) * .057, gy
            if Svg.vary(id, 3) < .42 and inCrown(x, y, .05) then
                local rot = -90 + (x < 0 and -1 or 1) * (35 + 40 * Svg.vary(id, 4))
                out[#out + 1] = Flora.leaf(c, x * U, y * U, rot, U * .042, U * .015, c.sage, true)
                    .. Flora.leaf(c, x * U, y * U, rot + (x < 0 and -62 or 62), U * .034, U * .013, c.sage, true)
            end
        end
        row = row + 1
    end
    return table.concat(out)
end

-- An apple of radius R at (x, y) with its stalk, a leaf and a gleam.
local function apple(c, x, y, R, leafy)
    local body = Svg.line(string.format("M0 %s Q%s %s %s %s", n(-R * .7), n(R * .05), n(-R * 1.25), n(R * .42), n(-R * 1.5)), c.ink, 1.8)
        .. (leafy and Flora.leaf(c, R * .1, -R * 1.05, -150, R * 1.1, R * .42, c.sage, true) or "")
        .. Svg.path(string.format("M0 %s C%s %s %s %s %s 0 C%s %s %s %s 0 %s C%s %s %s %s %s 0 C%s %s %s %s 0 %sZ", n(-R * .72),
            n(-R * .5), n(-R * 1.16), n(-R * 1.08), n(-R * .72), n(-R), n(-R * .94), n(R * .76), n(-R * .4), n(R * 1.06), n(R * .86),
            n(R * .4), n(R * 1.06), n(R * .94), n(R * .76), n(R), n(R * 1.08), n(-R * .72), n(R * .5), n(-R * 1.16), n(-R * .72)), c.bloom, c.ink, 1.9)
        .. Svg.line(string.format("M%s %s Q%s %s %s %s", n(-R * .62), n(R * .05), n(-R * .6), n(-R * .46), n(-R * .22), n(-R * .58)), c.cream, 1.9)
    return Svg.group(x, y, 0, body)
end

-- The fruit: an apple at the first `pct` percent of the places, a blossom at the rest.
local function fruit(c, pct)
    local spots = places()
    local filled = math.floor(math.max(0, math.min(100, tonumber(pct) or 0)) / 100 * #spots + .5)
    local order = {}
    for i = 1, #spots do order[i] = i end
    table.sort(order, function(a, b) return spots[a][3] < spots[b][3] end)
    local out = {}
    for rank, i in ipairs(order) do
        local x, y = spots[i][1], spots[i][2]
        out[#out + 1] = rank <= filled and apple(c, x, y, U * .034, i % 3 ~= 0)
            or Blooms.blossom(c, x, y, U * .038, c.cream, nil, i * 47 % 72)
    end
    return table.concat(out)
end

-- The wood: a trunk that flares into three roots and forks into three
-- limbs, drawn as one piece without seams, with lines of bark and a knot.
local function wood(c)
    local parts = {
        Svg.ribbon(Svg.spline(way({ { .005, .905 }, { -.012, .8 }, { .008, .7 }, { 0, .6 } }), 8), Tree.flare(U * .125, U * .072)),
        Svg.ribbon(Svg.spline(way({ { -.01, .85 }, { -.07, .878 }, { -.13, .9 }, { -.2, .91 } }), 6), Svg.taper(U * .06, U * .006)),
        Svg.ribbon(Svg.spline(way({ { .01, .85 }, { .08, .882 }, { .15, .895 }, { .215, .912 } }), 6), Svg.taper(U * .06, U * .006)),
        Svg.ribbon(Svg.spline(way({ { .0, .87 }, { .03, .91 }, { .06, .93 }, { .1, .938 } }), 6), Svg.taper(U * .045, U * .006)),
        Svg.ribbon(Svg.spline(way({ { 0, .67 }, { -.06, .585 }, { -.16, .51 }, { -.27, .45 } }), 6), Svg.taper(U * .058, U * .022)),
        Svg.ribbon(Svg.spline(way({ { 0, .675 }, { .07, .59 }, { .17, .515 }, { .28, .46 } }), 6), Svg.taper(U * .058, U * .022)),
        Svg.ribbon(Svg.spline(way({ { 0, .65 }, { .016, .56 }, { 0, .45 } }), 6), Svg.taper(U * .056, U * .024)),
    }
    local out = {}
    for _i, d in ipairs(parts) do out[#out + 1] = Svg.path(d, c.ink, c.ink, 5.2) end
    for _i, d in ipairs(parts) do out[#out + 1] = Svg.path(d, c.muted) end
    out[#out + 1] = Svg.line(Svg.poly(Svg.spline(way({ { -.018, .86 }, { -.026, .79 }, { -.012, .72 }, { -.02, .66 } }), 6)), c.ink, 1.5)
        .. Svg.line(Svg.poly(Svg.spline(way({ { .03, .84 }, { .02, .8 }, { .026, .76 } }), 6)), c.ink, 1.5)
        .. Svg.line(Svg.poly(Svg.spline(way({ { .012, .66 }, { .02, .625 }, { .05, .585 } }), 6)), c.ink, 1.5)
        .. Svg.line(Svg.poly(Svg.spiral(U * .012, U * .715, U * .013, 1.3, 200)), c.ink, 1.4)
    return table.concat(out)
end

-- The height of the lawn's upper edge and of its underside at `x`, for a lawn reaching `gw` to each side.
local function lawnEdge(x, gw)
    local k = math.max(0, cos(pi / 2 * x / gw)) ^ .8
    return U * (.916 - .08 * k), U * (.916 + .05 * k)
end

-- A tuft of grass standing on (x, y), `s` tall.
local function tuft(c, x, y, s)
    return Svg.line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(x - s * .14), n(y), n(x - s * .2), n(y - s * .5), n(x - s * .5), n(y - s * .8),
        n(x), n(y), n(x + s * .02), n(y - s * .6), n(x + s * .1), n(y - s), n(x + s * .14), n(y), n(x + s * .22), n(y - s * .45), n(x + s * .52), n(y - s * .7)), c.stem, 2.4)
end

-- A small flower of the lawn standing on (x, y), `s` tall, leaning by `lean`.
local function lawnFlower(c, x, y, s, fill, lean)
    local hx, hy = x + s * lean, y - s
    return Svg.line(string.format("M%s %s Q%s %s %s %s", n(x), n(y), n(x - s * lean * .4), n(y - s * .55), n(hx), n(hy)), c.stem, 2.2)
        .. Flora.leaf(c, x, y - s * .3, lean > 0 and -160 or -20, s * .5, s * .17, c.leaf, true)
        .. Blooms.blossom(c, hx, hy, s * .36, fill, nil, s * 9)
end

-- A toadstool standing on (x, y), `s` tall.
local function toadstool(c, x, y, s)
    local body = Svg.path(string.format("M%s 0 C%s %s %s %s %s %s L%s %s C%s %s %s %s %s 0Z", n(-s * .16), n(-s * .2), n(-s * .2), n(-s * .1), n(-s * .4), n(-s * .1), n(-s * .55),
        n(s * .1), n(-s * .55), n(s * .1), n(-s * .4), n(s * .2), n(-s * .2), n(s * .16)), c.cream, c.ink, 1.7)
        .. Svg.path(string.format("M%s %s C%s %s %s %s %s %s Q0 %s %s %sZ", n(-s * .5), n(-s * .5), n(-s * .46), n(-s * 1.14), n(s * .46), n(-s * 1.14), n(s * .5), n(-s * .5),
            n(-s * .36), n(-s * .5), n(-s * .5)), c.bloom, c.ink, 1.9)
        .. Svg.circle(-s * .16, -s * .76, s * .08, c.cream) .. Svg.circle(s * .14, -s * .66, s * .06, c.cream) .. Svg.circle(s * .06, -s * .9, s * .05, c.cream)
    return Svg.group(x, y, 0, body)
end

-- The lawn, reaching `gw` to each side: a low rise of turf with a darker
-- underside, the tree's shade, tufts of grass, flowers, fallen petals, a
-- toadstool and a seedling.
local function lawn(c, gw)
    local top, under, band = {}, {}, {}
    for i = 0, 28 do
        local x = gw * (i / 14 - 1)
        local y1, y2 = lawnEdge(x, gw)
        top[#top + 1] = { x, y1 }
        table.insert(under, 1, { x, y2 })
        table.insert(band, 1, { x, y2 - (y2 - y1) * .22 })
    end
    -- what stands on the lawn: where (in parts of gw), how far below the upper edge, and the drawing
    local function on(f, drop, draw)
        local x = gw * f
        return draw(x, lawnEdge(x, gw) + U * drop)
    end
    local out = {
        Svg.path(Svg.poly(Svg.join(top, under), true), c.leaf, c.ink, 2.6),
        Svg.path(Svg.poly(Svg.join(top, band), true), c.sage),
        Svg.line(Svg.poly(top), c.ink, 2.6),
        Svg.ellipse(U * .015, U * .9, math.min(gw * .62, U * .3), U * .022, 0, c.leaf),
    }
    for i, f in ipairs({ -.9, -.74, -.5, .6, .8, .94 }) do
        out[#out + 1] = on(f, .004, function(x, y) return tuft(c, x, y, U * (.03 + .012 * Svg.vary(i, 8))) end)
    end
    for i, p in ipairs({ { -.3, .05 }, { .24, .058 }, { .66, .04 }, { -.6, .045 }, { .44, .07 }, { -.08, .075 } }) do
        out[#out + 1] = on(p[1], p[2], function(x, y) return Svg.ellipse(x, y, U * .013, U * .007, 30 - i * 47, c.cream, c.ink, 1.1) end)
    end
    return table.concat(out)
        .. on(-.5, .03, function(x, y) return tuft(c, x, y, U * .03) end) .. on(.3, .05, function(x, y) return tuft(c, x, y, U * .028) end)
        .. on(-.66, .014, function(x, y) return lawnFlower(c, x, y, U * .058, c.cream, -.22) end)
        .. on(-.82, .012, function(x, y) return lawnFlower(c, x, y, U * .04, c.bloom2, .2) end)
        .. on(.72, .014, function(x, y) return lawnFlower(c, x, y, U * .052, c.bloom2, .22) end)
        .. on(.5, .026, function(x, y) return toadstool(c, x, y, U * .05) end)
        .. on(-.44, .03, function(x, y) return Blooms.seedling(c, x, y, U * .04) end)
end

-- The tree for a vw x vh canvas, with `pct` percent of its fruit ripe: as
-- large as fits with a margin on every side, the lawn wider on a wide canvas.
function Goal.goal_tree(c, vw, vh, pct)
    local size = math.min(vh * .87, vw * .87 / WIDE)
    local gw = math.min(vw * .43 / size, .76) * U
    local body = lawn(c, gw) .. wood(c) .. crown(c) .. leafMarks(c) .. fruit(c, pct)
    -- (written out here: Svg.group keeps one decimal of a scale, too coarse for a fit)
    return string.format('<g transform="translate(%s %s) scale(%.4f)">%s</g>', n(vw / 2), n((vh - size * .97) / 2), size / U, body)
end

return Goal
