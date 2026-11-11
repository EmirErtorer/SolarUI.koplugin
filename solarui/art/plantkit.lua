-- What the garden's plants are built with: a sprite maker that fits a plant
-- drawn in its own bed (origin at the foot, x across, y up as negative) into
-- any canvas in the colours of the season, stems that droop when the plant
-- is thirsty, strap leaves, the mound of earth every plant stands in and the
-- seed each one starts from.

local Flora = require("solarui/art/flora")
local Layout = require("solarui/garden/layout")
local Season = require("solarui/art/plantseason")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line = Svg.n, Svg.group, Svg.path, Svg.line
local sin, cos, rad = math.sin, math.cos, math.rad

local Kit = {}

-- A plant's drawing for the sprite list: `seed` is the kind of seed shown at
-- stage 1 (or a drawing of the plant's own) and `draw` paints the stages 2 to
-- 5; `rest` paints them when the plant has died back for the winter (the
-- evergreens have none and are drawn by `draw` in the winter colours). Each
-- takes p = { c, st, wilt, W, H, season, year, fruit } and returns SVG in the
-- bed's own units; `year` is the count of the maple's golden leaves ("y<N>",
-- with "f" when the tree bears fruit). A thirsty plant is drawn a little smaller
-- unless the plant is `fixed` to something that cannot shrink.
function Kit.sprite(id, seed, draw, fixed, rest)
    local box = Layout.PLANTS[id]
    return function(c, vw, vh, param)
        local s = tostring(param or "4")
        local st = math.max(1, math.min(5, tonumber(s:match("^(%d)")) or 4))
        local season = Season.of(s)
        local year, fruit = s:match(":y(%d+)(f?)")
        local p = { c = Wash.apply(Season.palette(c, season), s), st = st, wilt = s:find("wilt") ~= nil, W = box.w, H = box.h, season = season,
            year = year and math.min(12, tonumber(year)) or 0, fruit = fruit == "f" }
        local body
        if st > 1 then body = (season == "dormant" and rest or draw)(p)
        elseif type(seed) == "function" then body = seed(p) else body = Kit.seedbed(p, seed) end
        return group(vw / 2, vh, 0, body, math.min(vw / box.w, vh / box.h) * ((p.wilt and not fixed) and .92 or 1))
    end
end

-- A line of points bent over more and more towards its tip, by up to `deg`
-- degrees, starting `from` of the way along: a stem gone limp.
function Kit.droop(pts, deg, from)
    from = from or .45
    local total, run = Svg.length(pts), 0
    local out = { { pts[1][1], pts[1][2] } }
    local side = pts[#pts][1] < pts[1][1] and -1 or 1
    for i = 2, #pts do
        local dx, dy = pts[i][1] - pts[i - 1][1], pts[i][2] - pts[i - 1][2]
        run = run + math.sqrt(dx * dx + dy * dy)
        local a = rad(side * deg * math.max(0, (run / total - from) / (1 - from)) ^ 1.3)
        out[i] = { out[i - 1][1] + dx * cos(a) - dy * sin(a), out[i - 1][2] + dx * sin(a) + dy * cos(a) }
    end
    return out
end

-- A stem through the given points, limp when the plant is thirsty.
function Kit.rise(p, way, deg, from)
    local pts = Svg.spline(way, 8)
    return p.wilt and Kit.droop(pts, deg or 72, from) or pts
end

-- Where a stem is `f` of the way along: x, y and its direction.
function Kit.on(pts, f)
    return Svg.along(pts, Svg.length(pts) * f)
end

-- The turn of a leaf that leaves a stem heading `ang` on `side` (1 or -1)
-- at `spread` degrees; a thirsty plant lets it hang, by `sag` of the way down.
function Kit.turn(p, ang, side, spread, sag)
    local a = (ang + side * spread) % 360
    if not p.wilt then return a end
    if a > 270 then a = a - 360 end
    return a + (90 - a) * (sag or .55)
end

-- A strap leaf from (x, y): it sets off at `heading` degrees (0 is up),
-- turns by `curl` degrees along its `L`, is `W` wide and ends in a point.
function Kit.blade(p, x, y, heading, L, W, curl, fill, rib)
    if p.wilt then
        local side = (heading + curl * .5) < 0 and -1 or 1
        heading, curl, L = heading + side * 6, curl + side * 40, L * .86
    end
    local pts, steps = { { x, y } }, 14
    for i = 1, steps do
        local a = rad(heading + curl * ((i - .5) / steps) ^ 1.4)
        pts[i + 1] = { pts[i][1] + sin(a) * L / steps, pts[i][2] - cos(a) * L / steps }
    end
    local function width(t) return W * math.min(1, .5 + t * 2.6) * (1 - t ^ 2.6) ^ .8 end
    local mid = {}
    for i = 1, steps - 2 do mid[i] = pts[i] end
    return Svg.stem(pts, width, fill or p.c.leaf, p.c.ink, 1.5) .. line(Svg.poly(mid), rib or p.c.ink, .8) .. Season.rime(p.c, Kit.edge(pts, width, 1, .1, .8))
end

-- The points along one side of a stroke through `pts` whose width is given
-- as in Svg.ribbon, from `t0` to `t1` of the way along, on `side` (1 or -1).
function Kit.edge(pts, width, side, t0, t1)
    local out, count = {}, #pts
    for i = math.max(1, math.floor(count * t0)), math.floor(count * t1) do
        local a, b = pts[math.max(1, i - 1)], pts[math.min(count, i + 1)]
        local dx, dy = b[1] - a[1], b[2] - a[2]
        local len = math.sqrt(dx * dx + dy * dy)
        local half = width((i - 1) / (count - 1)) / 2 * side
        if len > 0 then out[#out + 1] = { pts[i][1] - dy / len * half, pts[i][2] + dx / len * half } end
    end
    return out
end

-- A leaf with a cut edge pointing right from (x, y): `lobes` teeth a side,
-- rounded, or raked back towards the stalk like a dandelion's when `back`.
function Kit.lobed(c, x, y, rot, L, W, lobes, fill, back)
    local top, bottom, steps = {}, {}, lobes * 5
    for i = 0, steps do
        local t = i / steps
        local phase = (t * lobes) % 1
        local tooth = back and (phase < .2 and phase * 5 or 1 - (phase - .2) * 1.1) or sin(math.pi * phase)
        local half = W * sin(math.pi * t ^ .8) ^ .6 * (.3 + .7 * tooth)
        top[#top + 1] = { L * t, -half }
        bottom[#bottom + 1] = { L * t, half }
    end
    local rim = {}
    for i = 2, #top - 1 do rim[i - 1] = top[i] end
    for i = #bottom - 1, 2, -1 do top[#top + 1] = bottom[i] end
    return group(x, y, rot, path(Svg.poly(top, true), fill or c.leaf, c.ink, 1.3) .. line(string.format("M-2 0 L%s 0", n(L * .86)), c.ink, .9) .. Season.rime(c, rim))
end

-- A heart-shaped leaf on its stalk, pointing right from (x, y), `L` long.
function Kit.heart(c, x, y, rot, L, fill)
    local a, W = L * .26, L * .4
    local body = line(string.format("M-2 0 L%s 0", n(a + 2)), c.ink, 3.6) .. line(string.format("M-2 0 L%s 0", n(a + 2)), c.stem, 2)
        .. path(string.format("M%s 0 C%s %s %s %s %s 0 C%s %s %s %s %s 0Z", n(a + L * .05), n(a - L * .16), n(-W * .9), n(L * .5), n(-W * 1.15), n(L), n(L * .5), n(W * 1.15), n(a - L * .16), n(W * .9), n(a + L * .05)), fill or c.leaf, c.ink, 1.6)
        .. line(string.format("M%s 0 L%s 0 M%s 0 L%s %s M%s 0 L%s %s M%s 0 L%s %s M%s 0 L%s %s", n(a), n(L * .9), n(a + L * .08), n(L * .42), n(-W * .52), n(a + L * .08), n(L * .42), n(W * .52), n(L * .5), n(L * .7), n(-W * .32),
            n(L * .5), n(L * .7), n(W * .32)), c.ink, .9)
    return group(x, y, rot, body)
end

-- A sunflower head seen from the front, the disc `rd` across its half: green
-- bracts, two rings of rays and seeds set in a Fibonacci spiral.
function Kit.sunflower(c, rd, rays)
    local seeds = {}
    for i = 1, 60 do
        local x, y = Svg.pol(rd * .9 * math.sqrt(i / 60), i * 137.5)
        seeds[#seeds + 1] = Svg.circle(x, y, rd * (.035 + .03 * i / 60), i < 9 and c.pale or c.ink)
    end
    local ring = rays and (Flora.around(0, 0, rd * .8, 13, Flora.petal(c, rd * 1.25, rd * .3, c.pale, 1.3), 14) .. Flora.around(0, 0, rd * .8, 13, Flora.petal(c, rd * 1.3, rd * .32, c.gold, 1.5)))
        or Flora.around(0, 0, rd * .8, 13, Flora.petal(c, rd * .5, rd * .16, c.pale, 1.1), 9)
    return Flora.around(0, 0, rd * .7, 13, Flora.petal(c, rd * (rays and 1 or .74), rd * .3, c.leaf, 1.3), 7) .. ring
        .. Svg.circle(0, 0, rd, c.bloom, c.ink, 1.8) .. table.concat(seeds)
end

-- The mound of earth a plant stands in, `w` across.
function Kit.soil(p, w)
    local h = w * .1
    return path(string.format("M%s -1 C%s %s %s %s %s -1Z", n(-w / 2), n(-w * .3), n(-h * 1.5), n(w * .3), n(-h * 1.5), n(w / 2)), p.c.line, p.c.ink, 1.4)
        .. line(string.format("M%s %s l%s 0 M%s %s l%s 0 M%s %s l%s 0", n(-w * .28), n(-h * .42), n(w * .07), n(w * .12), n(-h * .5), n(w * .08), n(-w * .04), n(-h * .2), n(w * .06)), p.c.ink, 1)
end

-- A bulb with its nose up, `s` tall, a few roots below.
local function bulb(p, s)
    return line(string.format("M%s 0 q%s %s %s %s M0 0 q%s %s %s %s M%s 0 q%s %s %s %s", n(-s * .12), n(-s * .1), n(s * .1), n(-s * .22), n(s * .14), n(s * .04), n(s * .1), n(0), n(s * .2), n(s * .12), n(s * .1),
        n(s * .1), n(s * .22), n(s * .14)), p.c.ink, 1)
        .. path(string.format("M0 0 C%s 0 %s %s %s %s C%s %s %s %s 0 %s C%s %s %s %s %s %s C%s %s %s 0 0 0Z", n(-s * .5), n(-s * .52), n(-s * .5), n(-s * .2), n(-s * .72), n(-s * .08), n(-s * .82), n(-s * .04), n(-s * .9), n(-s),
            n(s * .04), n(-s * .9), n(s * .08), n(-s * .82), n(s * .2), n(-s * .72), n(s * .52), n(-s * .5), n(s * .5)), p.c.pale, p.c.ink, 1.5)
        .. line(string.format("M%s %s Q%s %s 0 %s M%s %s Q%s %s 0 %s", n(-s * .22), n(-s * .08), n(-s * .3), n(-s * .5), n(-s * .9), n(s * .14), n(-s * .06), n(s * .28), n(-s * .45), n(-s * .86)), p.c.ink, .9)
end

-- The seed of each kind, standing or lying at the origin, about `s` large.
local SEEDS = {
    bulb = bulb,
    pips = function(p, s)
        return Svg.ellipse(-s * .42, -s * .2, s * .24, s * .15, -24, p.c.muted, p.c.ink, 1.2) .. Svg.ellipse(s * .1, -s * .28, s * .24, s * .15, 18, p.c.muted, p.c.ink, 1.2)
            .. Svg.ellipse(s * .55, -s * .16, s * .22, s * .14, -8, p.c.muted, p.c.ink, 1.2)
    end,
    striped = function(p, s)
        return group(0, -s * .1, -62, Flora.petal(p.c, s * 1.05, s * .32, p.c.cream, 1.4) .. line(string.format("M%s %s L%s %s M%s %s L%s %s", n(-s * .1), n(-s * .16), n(-s * .08), n(-s * .8), n(s * .1), n(-s * .16), n(s * .08), n(-s * .8)), p.c.ink, 1.3))
    end,
    parachute = function(p, s)
        local rays = {}
        for a = -60, 60, 20 do
            local x, y = Svg.pol(s * .62, a, 0, -s * .95)
            rays[#rays + 1] = string.format("M0 %s L%s %s", n(-s * .95), n(x), n(y))
        end
        return group(0, -s * .1, 16, line(string.format("M0 %s L0 %s", n(-s * .3), n(-s * .95)) .. " " .. table.concat(rays, " "), p.c.ink, 1)
            .. Svg.ellipse(0, -s * .18, s * .09, s * .2, 0, p.c.muted, p.c.ink, 1))
    end,
    samara = function(p, s)
        local wing = path(string.format("M0 0 C%s %s %s %s %s %s C%s %s %s %s 0 0Z", n(s * .3), n(-s * .34), n(s * 1.1), n(-s * .5), n(s * 1.3), n(-s * .16), n(s * 1.1), n(s * .1), n(s * .4), n(s * .12)), p.c.pale, p.c.ink, 1.3)
            .. line(string.format("M%s %s L%s %s M%s %s L%s %s", n(s * .4), n(-s * .04), n(s * .9), n(-s * .3), n(s * .56), n(s * .02), n(s * 1.08), n(-s * .16)), p.c.ink, .8)
        return group(0, -s * .3, 0, group(0, 0, 8, wing) .. group(0, 0, 172, wing, 1, -1) .. Svg.ellipse(s * .06, -s * .02, s * .2, s * .15, 8, p.c.gold, p.c.ink, 1.3)
            .. Svg.ellipse(-s * .08, 0, s * .2, s * .15, -8, p.c.gold, p.c.ink, 1.3))
    end,
    nut = function(p, s)
        return Svg.ellipse(0, -s * .34, s * .36, s * .44, 14, p.c.pale, p.c.ink, 1.5) .. line(string.format("M%s %s Q%s %s %s %s", n(-s * .05), n(-s * .72), n(s * .1), n(-s * .36), n(-s * .04), n(s * .04)), p.c.ink, 1)
    end,
    rhizome = function(p, s)
        return path(string.format("M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %s C%s %s %s %s %s %sZ", n(-s * .9), n(-s * .14), n(-s * .7), n(-s * .5), n(-s * .1), n(-s * .5), n(s * .1), n(-s * .34), n(s * .5), n(-s * .56), n(s), n(-s * .4), n(s * .9),
            n(-s * .1), n(s * .5), n(s * .08), n(-s * .5), n(s * .1), n(-s * .9), n(-s * .14)), p.c.pale, p.c.ink, 1.5)
            .. line(string.format("M%s %s q%s %s %s %s M%s %s q%s %s %s %s", n(-s * .45), n(-s * .42), n(s * .08), n(s * .2), n(-s * .02), n(s * .42), n(s * .1), n(-s * .34), n(s * .1), n(s * .16), n(s * .02), n(s * .36)), p.c.ink, .9)
            .. path(string.format("M%s %s q%s %s %s %s q%s %s %s %sZ", n(s * .5), n(-s * .46), n(s * .02), n(-s * .4), n(s * .26), n(-s * .5), n(s * .04), n(s * .3), n(-s * .08), n(s * .46)), p.c.leaf, p.c.ink, 1.2)
    end,
    sisters = function(p, s)
        local c = p.c
        return path(string.format("M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %sZ", n(-s * .66), n(-s * .04), n(-s * .8), n(-s * .26), n(-s * .76), n(-s * .44), n(-s * .6), n(-s * .5), n(-s * .44), n(-s * .42),
            n(-s * .38), n(-s * .22), n(-s * .5), n(-s * .02), n(-s * .58), n(s * .02), n(-s * .66), n(-s * .04)), c.gold, c.ink, 1.2)
            .. Svg.ellipse(-s * .58, -s * .3, s * .06, s * .11, 14, c.pale)
            .. Svg.ellipse(-s * .02, -s * .22, s * .27, s * .15, -8, c.bloom2, c.ink, 1.2) .. Svg.ellipse(-s * .02, -s * .1, s * .08, s * .035, -8, c.cream, c.ink, .8)
            .. Svg.ellipse(s * .6, -s * .2, s * .25, s * .14, 22, c.cream, c.ink, 1.2) .. Svg.ellipse(s * .6, -s * .2, s * .17, s * .08, 22, nil, c.ink, .7)
    end,
    disc = function(p, s)
        return Svg.ellipse(-s * .3, -s * .18, s * .34, s * .2, -10, p.c.muted, p.c.ink, 1.2) .. Svg.ellipse(s * .4, -s * .2, s * .32, s * .19, 14, p.c.muted, p.c.ink, 1.2)
    end,
    berry = function(p, s)
        return Svg.circle(-s * .3, -s * .26, s * .27, p.c.ink) .. Svg.circle(s * .3, -s * .24, s * .25, p.c.ink) .. Svg.circle(-s * .38, -s * .34, s * .07, p.c.cream) .. Svg.circle(s * .22, -s * .32, s * .07, p.c.cream)
    end,
}

-- The seed of one kind at the origin, about `s` large.
function Kit.seed(p, kind, s)
    return SEEDS[kind](p, s)
end

-- Stage one: the mound with the plant's seed lying in a dip of it.
function Kit.seedbed(p, kind)
    local w = math.min(p.W * .62, 110)
    local s = w * .26
    local lip = path(string.format("M%s %s Q0 %s %s %s L%s 0 L%s 0Z", n(-s * 1.5), n(-w * .09), n(-w * .03), n(s * 1.5), n(-w * .09), n(s * 1.5), n(-s * 1.5)), p.c.line)
        .. line(string.format("M%s %s Q0 %s %s %s", n(-s * 1.5), n(-w * .095), n(-w * .03), n(s * 1.5), n(-w * .095)), p.c.ink, 1.2)
    return Kit.soil(p, w) .. group(0, -w * .05, 0, Kit.seed(p, kind, s)) .. lip
end

return Kit
