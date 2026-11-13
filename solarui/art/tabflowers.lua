-- The flowers of the drop-down menu's tabs: each tab is a small plant whose
-- cream heart holds the tab's own icon. There are twelve plants, each with
-- its own head, stalk and leaves: 1 sunflower, 2 narcissus, 3 daisy, 4 tulip,
-- 5 pansy, 6 poppy, 7 lily, 8 rose, 9 iris, 10 bluebell, 11 anemone, 12 cosmos.
-- tab_flower(c, vw, vh, param) draws on a canvas vw x vh; param is
-- "<kind 1-12>:<chosen 0|1>". The heart is a disc centred at (vw / 2, vh * .4)
-- with radius Tabflowers.HEART * R, where R is the flower's outer radius,
-- min(vw * .46, vh * .36); the menu lays the icon over it, so nothing else is
-- drawn there. The chosen tab's plant is in full bloom: deeper colours, a
-- bolder outline and a gold ring round its heart.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Svg = require("solarui/art/svg")

local n, pol, group, around = Svg.n, Svg.pol, Svg.group, Flora.around
local abs, sin, cos, rad, pi = math.abs, math.sin, math.cos, math.rad, math.pi

local Tabflowers = {}

-- The heart's radius as a share of the flower's outer radius.
Tabflowers.HEART = .62

-- The tip of a rounded petal: how far out its edge is, from one side (-1) to the other (1).
local function round(u)
    return 1 - .1 * u * u - .12 * u ^ 6
end

-- The tip of a crinkled petal, as a poppy's.
local function crinkled(u)
    return round(u) * (1 + .04 * cos(5 * pi * u))
end

-- The tip of a toothed petal, as a cosmos's.
local function toothed(u)
    return round(u) - .07 * abs(sin(2.5 * pi * u))
end

-- A petal that fans out from the origin, `L` long and `half` degrees to each
-- side, with the given tip.
local function fan(p, L, half, tip, fill)
    local pts = { { 0, 0 } }
    for k = -14, 14 do
        pts[#pts + 1] = { pol(L * tip(k / 14), k / 14 * half) }
    end
    return Svg.path(Svg.poly(pts, true), fill, p.c.ink, p.sw)
end

-- A pointed petal `L` long and `W` to each side.
local function spear(p, L, W, fill)
    return Flora.petal(p.c, L, W, fill, p.sw)
end

-- A ring of `count` petals round the head, no two quite the same length:
-- `make` draws one from its share of the full length.
local function ring(count, start, salt, make)
    return around(0, 0, 0, count, function(i) return make(.93 + .07 * Svg.vary(i, salt)) end, start)
end

-- The colour of a part: `full` on the chosen tab, `plain` on the others.
local function tint(p, plain, full)
    return p.on and full or plain
end

-- A closed outline round the head whose distance from the centre is `r(a)`
-- at `a` degrees (0 is up).
local function rim(p, r, fill)
    local pts = {}
    for a = -180, 175, 5 do pts[#pts + 1] = { pol(r(a), a) } end
    return Svg.path(Svg.poly(pts, true), fill, p.c.ink, p.sw)
end

-- Short ink strokes on the petals, pointing out from the heart at the given angles.
local function creases(p, angles, r0, r1)
    local d = {}
    for i, a in ipairs(angles) do
        local x0, y0 = pol(p.R * r0, a)
        local x1, y1 = pol(p.R * r1, a)
        d[i] = string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1))
    end
    return Svg.line(table.concat(d, " "), p.c.ink, 1.1)
end

-- Sunflower: two rings of pointed rays.
local function sunflowerHead(p)
    local c, R = p.c, p.R
    return ring(13, 14, 1, function(k) return spear(p, R * k, R * .2, tint(p, c.sage, c.bloom)) end)
        .. ring(13, 0, 2, function(k) return spear(p, R * k, R * .23, tint(p, c.pale, c.gold)) end)
end

-- Narcissus: six pointed petals behind a frilled cup.
local function narcissusHead(p)
    local c, R = p.c, p.R
    return ring(6, 0, 3, function(k) return spear(p, R * (.94 + k * .06), R * .5, tint(p, c.cream, c.pale)) end)
        .. rim(p, function(a) return R * (.77 + .03 * cos(rad(a * 10))) end, tint(p, c.pale, c.bloom))
end

-- Daisy: many slender blunt petals, a second ring behind them in bloom.
local function daisyHead(p)
    local c, R = p.c, p.R
    return (p.on and ring(13, 14, 4, function(k) return fan(p, R * k * .97, 12, round, c.bloom) end) or "")
        .. ring(13, 0, 5, function(k) return fan(p, R * k, 13, round, tint(p, c.cream, c.bloom2)) end)
end

-- Tulip: a cup round the heart with three pointed tips, the middle petal in front.
local function tulipHead(p)
    local c, R = p.c, p.R
    local function cup(a)
        if abs(a) < 75 then return R * (.74 + .26 * (1 - abs(sin(rad(a * 3.6))))) end
        return R * (.74 + .13 * sin(rad((abs(a) - 75) / 105 * 90)))
    end
    local fold = {}
    for i, side in ipairs({ -1, 1 }) do
        local way = {}
        for j, at in ipairs({ { 25, .75 }, { 62, .7 }, { 104, .71 }, { 140, .86 } }) do way[j] = { pol(R * at[2], side * at[1]) } end
        fold[i] = Svg.poly(Svg.spline(way, 5))
    end
    return rim(p, cup, tint(p, c.bloom2, c.bloom)) .. Svg.line(table.concat(fold, " "), c.ink, 1.1)
end

-- Pansy: two upper petals, two at the sides and a broad whiskered one below.
local function pansyHead(p)
    local c, R = p.c, p.R
    local upper, side, lower = tint(p, c.sky, c.glass), tint(p, c.cream, c.sky), tint(p, c.pale, c.gold)
    return group(0, 0, -34, fan(p, R, 40, round, upper)) .. group(0, 0, 34, fan(p, R * .97, 40, round, upper))
        .. group(0, 0, -103, fan(p, R * .9, 36, round, side)) .. group(0, 0, 103, fan(p, R * .92, 36, round, side))
        .. group(0, 0, 180, fan(p, R * .96, 50, round, lower))
        .. creases(p, { 150, 165, 180, 195, 210, -103, 103 }, .68, .8)
end

-- Poppy: four wide crinkled petals, two behind and two in front.
local function poppyHead(p)
    local c, R = p.c, p.R
    local fill = tint(p, c.gold, c.bloom)
    return group(0, 0, 84, fan(p, R * .9, 44, crinkled, fill)) .. group(0, 0, -94, fan(p, R * .92, 44, crinkled, fill))
        .. group(0, 0, -6, fan(p, R, 54, crinkled, fill)) .. group(0, 0, 176, fan(p, R * .98, 52, crinkled, fill))
        .. creases(p, { -28, -6, 16, 62, 106, 154, 176, 198, -72, -116 }, .69, .83)
end

-- Lily: six long pointed petals with a stamen in each gap.
local function lilyHead(p)
    local c, R = p.c, p.R
    local anthers = around(0, 0, R * .88, 6, Svg.ellipse(0, 0, R * .085, R * .05, 0, tint(p, c.gold, c.bloom), c.ink, 1), 30)
    return creases(p, { 30, 90, 150, 210, 270, 330 }, .6, .86) .. anthers
        .. ring(3, 60, 6, function(k) return spear(p, R * k, R * .3, tint(p, c.cream, c.gold)) end)
        .. ring(3, 0, 7, function(k) return spear(p, R * k, R * .34, tint(p, c.cream, c.gold)) end)
end

-- Rose: green sepal tips, then two rings of round overlapping petals.
local function roseHead(p)
    local c, R = p.c, p.R
    return around(0, 0, 0, 5, spear(p, R, R * .16, c.leaf), 36)
        .. ring(5, 0, 8, function(k) return fan(p, R * k * .97, 46, round, tint(p, c.pale, c.bloom)) end)
        .. ring(5, 36, 9, function(k) return fan(p, R * k * .84, 44, round, tint(p, c.cream, c.bloom2)) end)
end

-- Iris: three standards up, three broad falls down, the middle one bearded.
local function irisHead(p)
    local c, R = p.c, p.R
    local up, down = tint(p, c.cream, c.sky), tint(p, c.sky, c.glass)
    return group(0, 0, -44, spear(p, R * .92, R * .34, up)) .. group(0, 0, 44, spear(p, R * .92, R * .34, up))
        .. spear(p, R, R * .4, up)
        .. group(0, 0, -112, fan(p, R * .97, 30, round, down)) .. group(0, 0, 112, fan(p, R * .97, 30, round, down))
        .. group(0, 0, 180, fan(p, R, 34, round, down))
        .. group(0, 0, 180, spear(p, R * .9, R * .1, c.gold))
end

-- Bluebell: a hanging bell with a flared, scalloped mouth and a small cap.
local function bluebellHead(p)
    local c, R = p.c, p.R
    local function at(x, y) return n(x * R) .. " " .. n(y * R) end
    local bell = string.format("M%s C%s %s %s C%s %s %s Q%s %s Q%s %s Q%s %s C%s %s %s C%s %s %sZ", at(0, -.8),
        at(-.52, -.8), at(-.78, -.45), at(-.74, .05), at(-.72, .32), at(-.78, .56), at(-.96, .8),
        at(-.62, .72), at(-.36, .99), at(0, .8), at(.36, .99), at(.62, .72), at(.96, .8),
        at(.78, .56), at(.72, .32), at(.74, .05), at(.78, -.45), at(.52, -.8), at(0, -.8))
    return Svg.path(bell, tint(p, c.sky, c.glass), c.ink, p.sw)
        .. around(0, 0, R * .64, 1, spear(p, R * .26, R * .1, c.leaf), -26)
        .. around(0, 0, R * .64, 1, spear(p, R * .26, R * .1, c.leaf), 26)
        .. around(0, 0, R * .64, 1, spear(p, R * .3, R * .11, c.leaf))
end

-- Anemone: a double ring of rounded petals.
local function anemoneHead(p)
    local c, R = p.c, p.R
    return ring(7, 26, 10, function(k) return fan(p, R * k, 27, round, tint(p, c.sky, c.glass)) end)
        .. ring(7, 0, 11, function(k) return fan(p, R * k * .86, 25, round, tint(p, c.cream, c.sky)) end)
end

-- Cosmos: eight toothed petals, a second ring behind them in bloom.
local function cosmosHead(p)
    local c, R = p.c, p.R
    return (p.on and ring(8, 22.5, 12, function(k) return fan(p, R * k * .96, 20, toothed, c.bloom2) end) or "")
        .. ring(8, 0, 13, function(k) return fan(p, R * k, 23, toothed, tint(p, c.bloom2, c.bloom)) end)
end

-- The line of a stalk from the ground up to under the head: `bends` are its
-- sideways steps, in head radii, at even heights.
local function stalkLine(p, bends)
    local way = {}
    for i, dx in ipairs(bends) do
        way[i] = { p.cx + dx * p.R, p.ground - p.H * (i - 1) / (#bends - 1) }
    end
    return Svg.spline(way, 6)
end

-- A stalk drawn along its line, `w` wide.
local function stalk(p, pts, w)
    return Svg.stem(pts, Svg.taper(w * 1.25, w), p.c.stem, p.c.ink, 1.2)
end

-- The place and heading `f` of the way up a stalk.
local function on(pts, f)
    return Svg.along(pts, Svg.length(pts) * f)
end

-- A sword leaf rising from the ground `x` head radii off the middle, its tip
-- leaning `lean` radii aside, `L` stalk heights tall and `W` radii wide.
local function blade(p, x, lean, L, W, fill)
    local x0 = p.cx + x * p.R
    local pts = Svg.spline({ { x0, p.ground }, { x0 + lean * p.R * .3, p.ground - L * p.H * .55 },
        { x0 + lean * p.R, p.ground - L * p.H } }, 8)
    return Svg.stem(pts, Svg.taper(W * p.R, .6), fill or p.c.leaf, p.c.ink, 1.3)
end

-- A plain leaf on a stalk, `f` of the way up, turned `rot` and `L` radii long.
local function leafOn(p, pts, f, rot, L, fill)
    local x, y = on(pts, f)
    return Flora.leaf(p.c, x, y, rot, L * p.R, L * p.R * .3, fill, true)
end

-- Sunflower: a stout straight stalk with two broad heart leaves.
local function sunflowerBody(p)
    local pts = stalkLine(p, { 0, .02, 0 })
    local x1, y1 = on(pts, .16)
    local x2, y2 = on(pts, .34)
    return Kit.heart(p.c, x1, y1, 196, p.R * .8) .. Kit.heart(p.c, x2, y2, -24, p.R * .72, p.c.sage) .. stalk(p, pts, 6)
end

-- Narcissus: a slim stalk in a sheaf of strap leaves.
local function narcissusBody(p)
    return blade(p, -.1, -.8, 1.05, .2, p.c.sage) .. blade(p, .1, .86, .92, .2)
        .. blade(p, -.04, -.42, .9, .18) .. blade(p, .05, .4, 1, .18, p.c.sage)
        .. stalk(p, stalkLine(p, { 0, 0 }), 3.6)
end

-- Daisy: a thin bowed stalk out of a low rosette of leaves.
local function daisyBody(p)
    local pts = stalkLine(p, { .14, -.1, 0 })
    local out = ""
    for i, rot in ipairs({ 186, -8, 214, -36, 240, -62 }) do
        out = out .. leafOn(p, pts, .03, rot, .62 - .06 * i, i % 2 == 0 and p.c.sage or p.c.leaf)
    end
    return out .. stalk(p, pts, 3)
end

-- Tulip: a straight stalk clasped by two broad leaves.
local function tulipBody(p)
    return blade(p, .08, .9, .8, .42, p.c.sage) .. stalk(p, stalkLine(p, { 0, 0 }), 5) .. blade(p, -.06, -.78, .95, .46)
end

-- Pansy: a winding stalk with three small heart leaves.
local function pansyBody(p)
    local pts = stalkLine(p, { -.2, .16, -.08, 0 })
    local x1, y1 = on(pts, .22)
    local x2, y2 = on(pts, .42)
    local x3, y3 = on(pts, .06)
    return Kit.heart(p.c, x3, y3, 190, p.R * .62) .. Kit.heart(p.c, x1, y1, -30, p.R * .6, p.c.sage)
        .. Kit.heart(p.c, x2, y2, 204, p.R * .5) .. stalk(p, pts, 3.4)
end

-- Poppy: a thin swaying stalk, cut leaves at its foot and a nodding bud.
local function poppyBody(p)
    local c, R = p.c, p.R
    local pts = stalkLine(p, { .1, -.12, .08, 0 })
    local x1, y1 = on(pts, .06)
    local x2, y2 = on(pts, .3)
    local neck = Svg.spline({ { x2, y2 }, { x2 + R * .42, y2 - R * .34 }, { x2 + R * .74, y2 - R * .3 }, { x2 + R * .8, y2 - R * .06 } }, 6)
    return Kit.lobed(c, x1, y1, 202, R * .92, R * .2, 4, c.leaf, true) .. Kit.lobed(c, x1, y1, -16, R * .7, R * .17, 3, c.sage, true)
        .. Svg.line(Svg.poly(neck), c.ink, 2)
        .. Svg.ellipse(x2 + R * .8, y2 + R * .04, R * .12, R * .19, 8, c.leaf, c.ink, 1.3)
        .. stalk(p, pts, 2.8)
end

-- Lily: a straight stalk with a ladder of short leaves.
local function lilyBody(p)
    local pts = stalkLine(p, { 0, 0 })
    local out = ""
    for i, f in ipairs({ .06, .16, .26, .36, .46, .56 }) do
        local left = i % 2 == 1
        out = out .. leafOn(p, pts, f, left and 212 or -32, .62 - .03 * i, left and p.c.leaf or p.c.sage)
    end
    return out .. stalk(p, pts, 4.4)
end

-- Rose: a thorny stalk that changes course at each leaf.
local function roseBody(p)
    local c, R = p.c, p.R
    local pts = stalkLine(p, { -.16, .14, -.1, 0 })
    local x1, y1 = on(pts, .17)
    local x2, y2 = on(pts, .4)
    local x3, y3 = on(pts, .06)
    local x4, y4 = on(pts, .29)
    return Flora.roseLeaf(c, x1, y1, -22, R * .86, 3) .. Flora.roseLeaf(c, x2, y2, 196, R * .8, 3, c.sage)
        .. Flora.thorn(c, x3, y3, -70, R * .16) .. Flora.thorn(c, x4, y4, 62, R * .16)
        .. stalk(p, pts, 4.2)
end

-- Iris: a fan of sword leaves round a straight stalk.
local function irisBody(p)
    return blade(p, -.12, -.84, .98, .24) .. blade(p, .12, .84, .9, .24, p.c.sage)
        .. blade(p, -.06, -.5, 1.1, .24, p.c.sage) .. blade(p, .06, .5, 1.1, .24)
        .. stalk(p, stalkLine(p, { 0, 0 }), 4)
end

-- Bluebell: a stalk that climbs one side and crooks over to hang the bell,
-- with grass blades at its foot.
local function bluebellBody(p)
    local R, cx, cy = p.R, p.cx, p.cy
    local pts = Svg.spline({ { cx + R * .1, p.ground }, { cx + R * .74, cy + R * 1.2 }, { cx + R * .93, cy + R * .3 },
        { cx + R * .84, cy - R * .56 }, { cx + R * .4, cy - R * .97 }, { cx + R * .04, cy - R * .88 }, { cx, cy - R * .76 } }, 8)
    return blade(p, -.04, -.9, .8, .2) .. blade(p, -.12, -.5, .96, .18, p.c.sage) .. blade(p, .3, .62, .5, .16, p.c.sage)
        .. Svg.stem(pts, Svg.taper(4.6, 2.6), p.c.stem, p.c.ink, 1.2)
end

-- Anemone: a bare stalk with a ruff of cut leaves under the flower.
local function anemoneBody(p)
    local c, R = p.c, p.R
    local pts = stalkLine(p, { -.06, .06, 0 })
    local x, y = on(pts, .52)
    return Kit.lobed(c, x, y, 160, R * .82, R * .22, 3, c.leaf) .. Kit.lobed(c, x, y, 20, R * .82, R * .22, 3, c.leaf)
        .. Kit.lobed(c, x, y, 100, R * .5, R * .2, 2, c.sage)
        .. stalk(p, pts, 3.4)
end

-- A feathery leaf of thin threads, pointing right from (x, y), `L` long.
local function threads(p, x, y, rot, L)
    local d = { string.format("M0 0 Q%s %s %s 0", n(L * .5), n(-L * .12), n(L)) }
    for i, t in ipairs({ .3, .52, .74 }) do
        local reach = L * (.4 - .08 * i)
        d[#d + 1] = string.format("M%s %s L%s %s M%s %s L%s %s", n(L * t), n(-L * .05), n(L * t + reach * .7), n(-reach),
            n(L * t), n(-L * .05), n(L * t + reach * .8), n(reach * .8))
    end
    return group(x, y, rot, Svg.line(table.concat(d, " "), p.c.stem, 2.2))
end

-- Cosmos: a wiry stalk with thread leaves in pairs.
local function cosmosBody(p)
    local pts = stalkLine(p, { .12, -.06, .06, 0 })
    local x1, y1 = on(pts, .1)
    local x2, y2 = on(pts, .34)
    return threads(p, x1, y1, -24, p.R * .8) .. threads(p, x1, y1, 204, p.R * .7)
        .. threads(p, x2, y2, -40, p.R * .6) .. threads(p, x2, y2, 216, p.R * .66)
        .. stalk(p, pts, 2.6)
end

-- The twelve plants: the head, the body and how far the head is turned.
local PLANTS = {
    { sunflowerHead, sunflowerBody, 0 }, { narcissusHead, narcissusBody, 30 }, { daisyHead, daisyBody, 7 },
    { tulipHead, tulipBody, 0 }, { pansyHead, pansyBody, 0 }, { poppyHead, poppyBody, 0 },
    { lilyHead, lilyBody, 30 }, { roseHead, roseBody, 12 }, { irisHead, irisBody, 0 },
    { bluebellHead, bluebellBody, 0 }, { anemoneHead, anemoneBody, 9 }, { cosmosHead, cosmosBody, 11 },
}

-- The heart that holds the icon, with a gold ring round it on the chosen tab.
local function heart(p)
    local r = p.R * Tabflowers.HEART
    return (p.on and Svg.circle(p.cx, p.cy, r + p.R * .09, p.c.gold, p.c.ink, p.sw) or "")
        .. Svg.circle(p.cx, p.cy, r, p.c.cream, p.c.ink, p.on and 2.2 or 1.6)
end

-- One tab's plant on a vw x vh canvas; param is "<kind 1-12>:<chosen 0|1>".
function Tabflowers.tab_flower(c, vw, vh, param)
    local kind, chosen = tostring(param or "1:0"):match("^(%d+):(%d)$")
    local plant = PLANTS[(math.max(1, tonumber(kind) or 1) - 1) % #PLANTS + 1]
    local R = math.min(vw * .46, vh * .36)
    local p = { c = c, cx = vw / 2, cy = vh * .4, R = R, on = chosen == "1", sw = chosen == "1" and 2.2 or 1.5, ground = vh - 1.5 }
    p.H = p.ground - (p.cy + R * .78)
    return plant[2](p) .. group(p.cx, p.cy, plant[3], plant[1](p)) .. heart(p)
end

return Tabflowers
