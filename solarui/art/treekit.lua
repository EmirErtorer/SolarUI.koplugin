-- What the garden's trees are built with, in a plant bed's units (origin at
-- the foot, y up as negative): a trunk that flares into its roots on a mound
-- of earth, limbs that grow from the trunk or from each other and droop when
-- the tree is thirsty, and a crown of overlapping masses of foliage, each a
-- dark body with a lighter one over it lit from the upper left, their edges
-- made of leaf tips (maple) or leaf fans (ginkgo); in winter the bare
-- twigs that fork out from the limbs, and leaves fallen at the foot.

local Kit = require("solarui/art/plantkit")
local Svg = require("solarui/art/svg")

local n, path, line = Svg.n, Svg.path, Svg.line
local sin, cos, pi = math.sin, math.cos, math.pi

local Tree = {}

-- The heights of one stretch of a crown's edge from one dip to the next
-- { along, height }: three pointed tips for maple leaves, a round fan with
-- a notch in the middle for ginkgo.
local EDGES = {
    maple = { { 0, 0 }, { .1, .45 }, { .2, .3 }, { .32, .76 }, { .42, .56 }, { .5, 1 }, { .58, .56 }, { .68, .76 }, { .8, .3 }, { .9, .45 } },
    ginkgo = { { 0, 0 }, { .04, .55 }, { .12, .85 }, { .25, .97 }, { .4, 1 }, { .47, .86 }, { .5, .64 }, { .53, .86 }, { .6, 1 }, { .75, .97 }, { .88, .85 }, { .96, .55 } },
}

-- The turn of a leaf on a tree: as given, or hanging when the tree is thirsty.
function Tree.hang(p, rot)
    if not p.wilt then return rot end
    local a = (rot + 180) % 360 - 180
    return a + ((a < 0 and -180 or 180) - a) * .6
end

-- A width from `w1` at the top to `w0` at the foot, swelling where a trunk meets its roots.
function Tree.flare(w0, w1)
    return function(t)
        local u = 1 - t
        return w1 + (w0 - w1) * (u ^ 7 * .6 + u * .4)
    end
end

-- The mound of earth under a tree, `w` across, with roots reaching `spread` out over it.
function Tree.roots(p, w, spread)
    local c, out = p.c, Kit.soil(p, w)
    for _i, r in ipairs({ { -1, 1, .9 }, { 1, 1, 1 }, { -1, .55, .5 }, { 1, .6, .62 } }) do
        local s, reach = r[1], spread * r[2]
        local pts = Svg.spline({ { s * 4, -12 * r[3] }, { s * reach * .45, -7 * r[3] }, { s * reach * .8, -3 }, { s * reach, 1 } }, 6)
        out = out .. Svg.stem(pts, Svg.taper(10 * r[3] + 3, 1.6), c.muted, c.ink, 1.4)
    end
    return out
end

-- The trunk along `pts`, `w0` wide at its flared foot and `w1` at the top, with lines of bark.
function Tree.trunk(p, pts, w0, w1)
    local width = Tree.flare(w0, w1)
    local bark, count = {}, #pts
    for _k, side in ipairs({ -.24, .18, .02 }) do
        local seg = {}
        for i = math.floor(count * (.06 + math.abs(side))), math.floor(count * (.62 - side)) do
            local a, b = pts[math.max(1, i - 1)], pts[math.min(count, i + 1)]
            local dx, dy = b[1] - a[1], b[2] - a[2]
            local len = math.sqrt(dx * dx + dy * dy)
            local off = width((i - 1) / (count - 1)) * side
            seg[#seg + 1] = { pts[i][1] - dy / len * off, pts[i][2] + dx / len * off }
        end
        if #seg > 2 then bark[#bark + 1] = Svg.poly(seg) end
    end
    return Svg.stem(pts, width, p.c.muted, p.c.ink, 1.8) .. line(table.concat(bark, " "), p.c.ink, .9)
end

-- The limbs as point lists, each { from, at, way, droop } growing from limb `from` (0 the trunk) and drooping when thirsty.
function Tree.limbs(p, trunk, specs)
    local out = { [0] = trunk }
    for i, s in ipairs(specs) do
        local x, y = Kit.on(out[s.from or 0], s.at)
        local way = { { x, y } }
        for _j, w in ipairs(s.way) do way[#way + 1] = { x + w[1], y + w[2] } end
        local pts = Svg.spline(way, 7)
        out[i] = p.wilt and Kit.droop(pts, s.droop or 24, .2) or pts
    end
    return out
end

-- The limbs and the trunk drawn in bark, each limb running out of its parent without a seam.
function Tree.wood(p, trunk, w0, w1, limbs, specs)
    local out, joins = {}, {}
    for i = #specs, 1, -1 do
        local w = specs[i].w
        out[#out + 1] = Svg.stem(limbs[i], Svg.taper(w[1], w[2]), p.c.muted, p.c.ink, 1.4)
        local head = Svg.head(limbs[i], math.min(Svg.length(limbs[i]) * .3, 16))
        if #head > 1 then joins[#joins + 1] = Svg.ribbon(head, w[1] - 2.8) end
    end
    local top = trunk[#trunk]
    return table.concat(out) .. Tree.trunk(p, trunk, w0, w1) .. path(table.concat(joins, " "), p.c.muted)
        .. Svg.circle(top[1], top[2], w1 / 2 - 1, p.c.muted)
end

-- The outline of a mass of leaves round (cx, cy), its edge a run of `edge` stretches `span` long and `teeth` proud.
function Tree.blob(cx, cy, rx, ry, edge, span, teeth, seed)
    local count = math.max(6, math.floor(2 * pi * math.sqrt((rx * rx + ry * ry) / 2) / span + .5))
    local pts, mean = {}, (rx + ry) / 2
    for k = 0, count - 1 do
        local swell = .93 + .12 * Svg.vary(k, seed)
        for _i, e in ipairs(EDGES[edge]) do
            local a = 2 * pi * (k + e[1]) / count + seed
            local r = swell + (e[2] - .6) * teeth / mean
            pts[#pts + 1] = { cx + rx * sin(a) * r, cy - ry * cos(a) * r }
        end
    end
    return Svg.poly(pts, true)
end

-- One mass { x, y, rx, ry } of the crown, dark with a lighter part at its upper left; also gives that part.
function Tree.mass(p, m, edge, tones, span, teeth, seed)
    local lx, ly, lrx, lry = m[1] - m[3] * .12, m[2] - m[4] * .15, m[3] * .74, m[4] * .7
    return path(Tree.blob(m[1], m[2], m[3], m[4], edge, span, teeth, seed), tones[1], p.c.ink, 1.7)
        .. path(Tree.blob(lx, ly, lrx, lry, edge, span * .86, teeth * .85, seed + 2.1), tones[2]), lx, ly, lrx, lry
end

-- A drawing `k` times its size at (x, y), so its outlines come out finer.
function Tree.fine(x, y, k, body)
    return Svg.group(x, y, 0, body, k)
end

-- The points of a twig from (x, y) heading `deg` degrees for `L` units, bowed by `bow`.
function Tree.twig(x, y, deg, L, bow)
    local dx, dy = sin(deg * pi / 180), -cos(deg * pi / 180)
    return Svg.spline({ { x, y }, { x + dx * L * .5 - dy * bow, y + dy * L * .5 + dx * bow }, { x + dx * L, y + dy * L } }, 5)
end

-- A twig drawn along `pts`, thin, in bark.
function Tree.drawTwig(p, pts, w)
    return Svg.stem(pts, Svg.taper(w or 2.6, 1.2), p.c.muted, p.c.ink, 1)
end

-- A short stalk from (x, y) to (x2, y2), as a plain line.
function Tree.stalk(p, x, y, x2, y2, w)
    return line(string.format("M%s %s L%s %s", n(x), n(y), n(x2), n(y2)), p.c.ink, w or 1.2)
end

-- A seedling: a thin stem `tall` high with leaves drawn by `leaf` at the places { along, turn, size }.
function Tree.sapling(p, tall, spots, leaf)
    local stem = Kit.rise(p, { { 0, -3 }, { -tall * .04, -tall * .5 }, { tall * .02, -tall } }, 40, .5)
    local out = ""
    for i, s in ipairs(spots) do
        local x, y, ang = Kit.on(stem, s[1])
        out = out .. leaf(x, y, Tree.hang(p, ang + 90 + s[2]), s[3], i)
    end
    return Kit.soil(p, 90) .. out .. Svg.stem(stem, Svg.taper(tall * .05 + 2, 2.4), p.c.muted, p.c.ink, 1.4)
end

-- Where a line of points is `f` along, with the turn a leaf growing straight out of it there takes.
function Tree.at(pts, f)
    local x, y, ang = Kit.on(pts, f)
    return x, y, ang + 90
end

-- Bare twigs forking out from (x, y) heading `deg` (0 is up): each `L`
-- long, splitting in two `depth` more times, the last ones fine ink lines.
-- `spread` is how far each fork opens, `lift` how far forks turn upwards.
function Tree.fork(p, x, y, deg, L, w, depth, spread, lift, seed)
    local pts = Tree.twig(x, y, deg, L, (Svg.vary(seed, 3) - .5) * L * .3)
    local tx, ty = pts[#pts][1], pts[#pts][2]
    local out = depth > 0 and Tree.drawTwig(p, pts, w) or line(Svg.poly(pts), p.c.ink, 1.3)
    if depth > 0 then
        local up = -((deg + 180) % 360 - 180) * (lift or .15)
        for k, side in ipairs({ -1, 1 }) do
            local turn = deg + up + side * spread * (.75 + .5 * Svg.vary(seed * 2 + k, 5))
            out = out .. Tree.fork(p, tx, ty, turn, L * (.62 + .12 * Svg.vary(seed + k, 7)), w * .72, depth - 1, spread, lift, seed * 2 + k)
        end
    end
    return out
end

-- Bare twigs at the tip of each limb and one off the side of each long one.
function Tree.bare(p, limbs, specs, L, depth, spread, lift)
    local out = ""
    for i = 1, #specs do
        local x, y, deg = Tree.at(limbs[i], 1)
        deg = deg - 90
        out = out .. Tree.fork(p, x, y, deg, L, specs[i].w[2] * .9, depth, spread, lift, i)
        if Svg.length(limbs[i]) > 60 then
            local sx, sy, sd = Tree.at(limbs[i], .62)
            local side = i % 2 == 0 and 1 or -1
            out = out .. Tree.fork(p, sx, sy, sd - 90 + side * 42, L * .7, specs[i].w[2] * .8, depth - 1, spread, lift, i + 20)
        end
    end
    return out
end

-- Leaves fallen round the foot of a tree, `reach` to either side: `draw(x, y, rot, i)` draws one.
function Tree.litter(reach, count, draw)
    local out = ""
    for i = 1, count do
        local side = i % 2 == 0 and 1 or -1
        local x = side * reach * (.3 + .7 * Svg.vary(i, 31))
        out = out .. draw(x, -1 - 4 * Svg.vary(i, 32), (side > 0 and 70 or -110) + 60 * Svg.vary(i, 33), i)
    end
    return out
end

-- `count` points spread evenly over an ellipse round (cx, cy), rx by ry (a
-- sunflower's spiral), for things scattered through a crown.
function Tree.scatter(cx, cy, rx, ry, count)
    local out = {}
    for i = 1, count do
        local r = math.sqrt((i - .4) / count)
        local a = i * 137.5 * pi / 180
        out[i] = { cx + rx * r * sin(a), cy - ry * r * cos(a) }
    end
    return out
end

-- A number between a and b, fixed for index `i` and `salt`.
function Tree.vary(a, b, i, salt)
    return a + (b - a) * Svg.vary(i, salt)
end

return Tree
