-- The garden's shrub, shade and water plants through the stages of their
-- life: damask rose, honesty, a clump of bracken and the white water lily, and how the
-- rose and honesty rest through the winter. All are drawn with plantkit,
-- each in a bed of the plant's own size, and returned by name for gardenplants.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Rest = require("solarui/art/plantrest")
local Season = require("solarui/art/plantseason")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, petal, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Flora.petal, Svg.circle, Svg.ellipse
local mix = Wash.mix

local Shade = {}

-- A rose hip on the origin, `s` tall, under its dried sepals.
local function hip(p, s)
    return ellipse(0, -s * .46, s * .36, s * .46, 0, p.c.bloom, p.c.ink, 1.5)
        .. line(string.format("M0 %s L%s %s M0 %s L0 %s M0 %s L%s %s", n(-s * .9), n(-s * .22), n(-s * 1.2), n(-s * .9), n(-s * 1.26), n(-s * .9), n(s * .22), n(-s * 1.2)), p.c.ink, 1.5)
end

-- A rose seen from the side, standing on the origin, `r` across its half:
-- reflexed sepals under the green receptacle, two guard petals curled back,
-- a cup of broad outer petals that overlap, and the inner petals showing
-- over the rim.
local function roseProfile(c, r, fill, fill2)
    -- a path written for a rose one unit across its half, at this rose's size
    local function sized(d) return (d:gsub("-?%d*%.?%d+", function(v) return n(tonumber(v) * r) end)) end
    local function shape(d, colour) return path(sized(d), colour, c.ink, 1.5) end
    local function fold(d) return line(sized(d), c.ink, .9) end
    local sepals = ""
    for _i, a in ipairs({ -112, 112, -150, 150 }) do sepals = sepals .. group(0, -r * .12, a, petal(c, r * (math.abs(a) > 130 and .5 or .68), r * .15, c.leaf, 1.3)) end
    local heart = shape("M-.62 -.95 C-.78 -1.6 -.2 -1.86 0 -1.5 C.25 -1.86 .82 -1.56 .62 -.95Z", fill)
        .. shape("M-.48 -1 C-.54 -1.52 .02 -1.64 .14 -1.08Z", fill2) .. shape("M-.06 -1 C-.04 -1.6 .54 -1.52 .48 -1Z", fill2)
        .. shape("M-.26 -1 C-.26 -1.38 .28 -1.38 .26 -1Z", fill) .. fold("M-.1 -1.06 C-.08 -1.24 .14 -1.24 .1 -1.1")
    local guard = shape("M-.08 -.14 C-.6 -.02 -1.26 -.16 -1.34 -.6 C-1.02 -.72 -.5 -.52 -.08 -.14Z", fill) .. fold("M-1.2 -.5 Q-.8 -.5 -.5 -.3")
    local side = shape("M0 -.15 C-.72 -.15 -1.16 -.56 -1.02 -1.06 C-.96 -1.32 -.6 -1.3 -.44 -1.08 C-.3 -.8 -.1 -.5 0 -.15Z", fill)
        .. fold("M-.92 -1.02 Q-.74 -1.14 -.56 -1.04")
    local front = shape("M-.1 -.12 C-.62 -.16 -.84 -.62 -.66 -1.02 C-.4 -1.2 .02 -1.16 .2 -.98 C.3 -.6 .2 -.26 -.1 -.12Z", fill)
        .. shape("M.08 -.12 C-.3 -.3 -.34 -.78 -.14 -1.04 C.14 -1.2 .5 -1.14 .7 -.98 C.84 -.6 .6 -.16 .08 -.12Z", fill)
        .. fold("M-.56 -.96 Q-.3 -1.06 -.04 -.98 M-.04 -.98 Q.3 -1.08 .6 -.94")
    return sepals .. heart .. guard .. group(0, 0, 0, guard, -1, 1) .. side .. group(0, 0, 0, side, -1, 1) .. front .. ellipse(0, -r * .08, r * .22, r * .18, 0, c.leaf, c.ink, 1.3)
end

-- Rose: three thorny canes with toothed leaves, each ending in a full bloom
-- that faces the viewer, or is seen from the side when the bloom nods on a thirsty cane.
local function rose(p)
    local c, st = p.c, p.st
    if st == 2 then
        local cane = Kit.rise(p, { { 0, -3 }, { -3, -26 }, { 3, -52 } })
        local x, y, ang = Kit.on(cane, 1)
        local mx, my, mang = Kit.on(cane, .5)
        return Kit.soil(p, 90) .. Flora.roseLeaf(c, mx, my, Kit.turn(p, mang, -1, 56), 30, 3, c.bloom2) .. Flora.roseLeaf(c, x, y, Kit.turn(p, ang, 1, 50), 32, 3, c.bloom2)
            .. Flora.roseLeaf(c, x, y, Kit.turn(p, ang, -1, 20), 26, 3, c.leaf) .. Svg.stem(cane, Svg.taper(4.4, 3), c.stem, c.ink, 1.4)
    end
    local k = st == 3 and .82 or 1
    local canes = {
        { way = { { -3, -3 }, { -30, -50 * k }, { -52, -92 * k }, { -56, -118 * k } }, r = 19, leaves = { { .36, -1, 36 }, { .68, 1, 30 } } },
        { way = { { 3, -3 }, { 30, -58 * k }, { 50, -108 * k }, { 52, -140 * k } }, r = 23, leaves = { { .3, 1, 38 }, { .52, -1, 30 }, { .76, 1, 30 } } },
        { way = { { 0, -3 }, { -8, -70 * k }, { 5, -138 * k }, { -1, -180 * k } }, r = 30, leaves = { { .34, 1, 36 }, { .5, -1, 40 }, { .68, 1, 34 }, { .84, -1, 30 } } },
    }
    local out, heads = Kit.soil(p, 100), ""
    for i, cane in ipairs(canes) do
        local pts = Kit.rise(p, cane.way, 46, .5)
        for j, l in ipairs(cane.leaves) do
            local x, y, ang = Kit.on(pts, l[1])
            out = out .. Flora.roseLeaf(c, x, y, Kit.turn(p, ang, l[2], 58), l[3], j == 1 and 5 or 3, (st == 5 and j == 1) and c.pale or c.leaf)
        end
        for t, f in ipairs({ .16, .44, .62 }) do
            local x, y, ang = Kit.on(pts, f + i * .03)
            out = out .. Flora.thorn(c, x, y, ang + (t % 2 == 0 and 180 or 0), 5)
        end
        out = out .. Svg.stem(pts, Svg.taper(5.6, 3.4), c.stem, c.ink, 1.5)
        local x, y, ang = Kit.on(pts, 1)
        if st == 3 then
            heads = heads .. Flora.rosebud(c, x, y, ang + 90, cane.r * .52, c.bloom2)
        elseif st == 4 and p.wilt then
            heads = heads .. group(x, y, (ang + 90) * 1.5, roseProfile(c, cane.r * .9, c.bloom2, c.bloom))
        elseif st == 4 then
            heads = heads .. group(x, y, ang + 90, group(0, -cane.r * .62, i * 40, Flora.rose(c, 0, 0, cane.r, 0, c.bloom2, c.bloom)))
        else
            heads = heads .. group(x, y, ang + 90, hip(p, cane.r * .66))
        end
    end
    return out .. heads
end

-- An honesty flower on the origin, `r` across: four rounded petals in a cross.
local function cross(p, r)
    return Flora.around(0, 0, r * .12, 4, path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(-r * .7), n(-r * .3), n(-r * .6), n(-r), n(-r), n(r * .6), n(-r), n(r * .7), n(-r * .3)), p.c.bloom2, p.c.ink, 1.2), 45)
        .. circle(0, 0, r * .2, p.c.gold, p.c.ink, .9)
end

-- An honesty pod on the origin, `r` across: a flat paper moon with its
-- seeds showing through, green while young.
local function moon(p, r, young)
    local c = p.c
    return line(string.format("M0 0 L0 %s M0 %s L0 %s", n(-r * .4), n(-r * 2.5), n(-r * 2.8)), c.ink, 1.2) .. ellipse(0, -r * 1.4, r * .9, r * 1.1, 0, young and c.sage or c.pale, c.ink, 1.4)
        .. (young and "" or ellipse(0, -r * 1.4, r * .62, r * .82, 0, c.cream, c.ink, .8)) .. Svg.dots(0, -r * 1.4, r * .34, 3, r * .26, young and c.leaf or c.ink)
end

-- Honesty: heart leaves low down, purple crosses above, then silver moons.
local function honesty(p)
    local c, st = p.c, p.st
    local k = ({ 0, .36, .82, 1, 1 })[st]
    local main = Kit.rise(p, { { 0, -3 }, { -3, -50 * k }, { 3, -78 * k }, { 0, -94 * k } }, 70)
    local stems = { main }
    if st > 2 then
        for _i, b in ipairs({ { .4, 34, -80 }, { .32, -34, -70 } }) do
            local x, y = Kit.on(main, b[1])
            stems[#stems + 1] = Kit.rise(p, { { x, y }, { x + (b[2] - x) * .7, y + (b[3] * k - y) * .45 }, { b[2], b[3] * k } }, 70)
        end
    end
    local out, tops = Kit.soil(p, 66), ""
    for i, f in ipairs(st == 2 and { .5, .9 } or { .14, .3 }) do
        local x, y, ang = Kit.on(main, f)
        out = out .. Kit.heart(c, x, y, Kit.turn(p, ang, i % 2 == 0 and 1 or -1, 64, .2), st == 2 and 24 or 28, (st == 5 and i == 1) and c.pale or c.leaf)
    end
    for i, pts in ipairs(stems) do
        out = out .. Svg.stem(pts, Svg.taper(i == 1 and 3.2 or 2.4, 1.8), c.stem, c.ink, 1.2)
        local x, y, ang = Kit.on(pts, 1)
        if st == 3 then
            tops = tops .. group(x, y, ang + 90, ellipse(-3, -3, 2.6, 4, -20, c.bloom2, c.ink, 1) .. ellipse(3, -3, 2.6, 4, 20, c.bloom2, c.ink, 1) .. ellipse(0, -6, 2.8, 4.4, 0, c.bloom2, c.ink, 1))
        elseif st == 4 then
            local px, py, pang = Kit.on(pts, i == 1 and .7 or .62)
            tops = tops .. group(px, py, pang + 90 + (i == 2 and 62 or -62), moon(p, 5.4, true))
                .. group(x, y, ang + 90, group(-6, -3, 0, cross(p, 6.5)) .. group(6, -5, 20, cross(p, 6.5)) .. group(0, -12, 40, cross(p, 7)))
        elseif st == 5 then
            for j, f in ipairs(i == 1 and { .62, .8, 1 } or { .6, 1 }) do
                local px, py, pang = Kit.on(pts, f)
                tops = tops .. group(px, py, pang + 90 + (f == 1 and 0 or ((i + j) % 2 == 0 and 58 or -58)), moon(p, 7.4))
            end
        end
    end
    return out .. tops
end

-- A bracken frond on the given rachis: pinnae in pairs that shorten to the
-- tip, each cut into lobes, so the whole blade is a triangle.
local function frond(p, pts, reach, fill)
    local out = ""
    for i = 0, 5 do
        local x, y, ang = Kit.on(pts, .4 + .52 * i / 5)
        local L = reach * (1 - i / 6.6)
        local lobes = math.max(3, math.floor(L / 6.5))
        out = out .. Kit.lobed(p.c, x, y, Kit.turn(p, ang, -1, 66, .3), L, L * .15 + 1.5, lobes, fill) .. Kit.lobed(p.c, x, y, Kit.turn(p, ang, 1, 72, .3), L * .82, L * .15 + 1.5, lobes, fill)
    end
    local x, y, ang = Kit.on(pts, .97)
    return out .. Kit.lobed(p.c, x, y, ang, reach * .34, reach * .08, 3, fill) .. Svg.stem(Svg.head(pts, Svg.length(pts) * .97), Svg.taper(reach * .1, reach * .04), p.c.stem, p.c.ink, 1.3)
end

-- The fronds of the bracken clump, back to front: the way each rachis
-- rises from the rhizome and how far its lowest pinnae reach.
local FRONDS = {
    { way = { { 0, -3 }, { -3, -40 }, { 1, -74 }, { 10, -98 } }, reach = 30 },
    { way = { { -7, -3 }, { -14, -30 }, { -34, -52 }, { -60, -60 } }, reach = 27 },
    { way = { { 7, -3 }, { 15, -32 }, { 36, -56 }, { 60, -68 } }, reach = 27 },
}

-- The colours of the fronds, back to front: green, russet and copper in
-- autumn and at the seed head, brown when the clump has died back.
local function frondTones(p)
    local c = p.c
    if p.season == "dormant" then return { c.dead, mix(c.dead, c.straw, .5), c.straw } end
    if p.season == "autumn" or p.st == 5 then
        local copper = mix(c.gold, c.bloom, .55)
        return { mix(copper, c.muted, .3), copper, mix(c.gold, c.bloom, .2) }
    end
    return { mix(c.leaf, c.stem, .45), c.leaf, mix(c.leaf, c.sage, .5) }
end

-- Bracken: a clump of croziers from one creeping rhizome that unroll into
-- broad three-cornered fronds of different heights.
local function bracken(p)
    local c, st = p.c, p.st
    local out = Kit.soil(p, 84)
    if st == 2 then return out .. Flora.crozier(c, 22, -3, 12, 20, 7, c.sage) .. Flora.crozier(c, 8, -3, 6, 32, 9, c.sage) .. Flora.crozier(c, -10, -3, -6, 46, 12, c.leaf) end
    local tones = frondTones(p)
    local k = st == 3 and .66 or 1
    for i, f in ipairs(FRONDS) do
        -- the young clump has two small fronds open, and the tallest still rolled
        if st > 3 or i > 1 then
            local way = {}
            for j, pt in ipairs(f.way) do way[j] = { pt[1] * k, -3 + (pt[2] + 3) * k } end
            out = out .. frond(p, Kit.rise(p, way, 50, .4), f.reach * k, tones[i])
        end
    end
    if st == 3 then return out .. Flora.crozier(c, 2, -3, 4, 70, 12, c.leaf) .. Flora.crozier(c, 20, -3, 14, 16, 6.5, c.sage) end
    return (st == 4 and p.season ~= "dormant") and out .. Flora.crozier(c, 24, -3, 16, 17, 7.5, c.sage) or out
end

-- A floating lily pad seen at a slant, its notch at `notch` degrees.
local function pad(p, x, y, rx, ry, notch, fill)
    local pts, veins, rim = { { x, y } }, {}, {}
    for a = notch + 14, notch + 346, 12 do
        local px, py = x + rx * math.cos(math.rad(a)), y + ry * math.sin(math.rad(a))
        pts[#pts + 1] = { px, py }
        if py < y - ry * .3 then rim[#rim + 1] = { px, py + 1.5 } end
        if (a - notch - 14) % 48 == 24 then veins[#veins + 1] = string.format("M%s %s L%s %s", n(x), n(y), n(x + (px - x) * .8), n(y + (py - y) * .8)) end
    end
    return path(Svg.poly(pts, true), fill or p.c.leaf, p.c.ink, 1.6) .. line(table.concat(veins, " "), p.c.ink, .8) .. Season.rime(p.c, rim)
end

-- Rings on the water round (x, y).
local function ripples(p, x, y, w)
    return line(string.format("M%s %s q%s %s %s 0 M%s %s q%s %s %s 0 M%s %s q%s %s %s 0", n(x - w), n(y), n(w * .3), n(-w * .09), n(w * .6), n(x + w * .3), n(y + w * .12), n(w * .3), n(w * .08), n(w * .6), n(x - w * .5), n(y + w * .24),
        n(w * .25), n(w * .07), n(w * .5)), p.c.ink, 1.1)
end

-- A water lily in flower on the origin, `s` tall: rows of pointed petals
-- cupped round a golden heart. `shut` (0 to 1) closes it.
local function nymphaea(p, s, shut)
    local c = p.c
    local k = 1 - (shut or 0) * .75
    local out = ""
    for _i, a in ipairs({ -84, 84, -58, 58, -30, 30, 0 }) do out = out .. group(0, 0, a * k, petal(c, s, s * .25, c.cream, 1.5)) end
    out = out .. ellipse(0, -s * .2, s * .26 * k, s * .14, 0, c.gold, c.ink, 1.2)
    for _i, a in ipairs({ -66, 66, -40, 40, -14, 14 }) do out = out .. group(0, s * .04, a * k, petal(c, s * .56, s * .2, c.cream, 1.4)) end
    return out .. group(0, s * .06, -70 * k, petal(c, s * .5, s * .2, c.sage, 1.3)) .. group(0, s * .06, 70 * k, petal(c, s * .5, s * .2, c.sage, 1.3))
end

-- Water lily: pads with a notch lying on the water, and the flower among them.
local function waterLily(p)
    local c, st = p.c, p.st
    if st == 1 then return ripples(p, 0, -22, 30) .. ellipse(0, -30, 6, 4.4, 0, c.pale, c.ink, 1.3) .. line("M-12 -30 q12 9 24 0", c.ink, 1.1) end
    if st == 2 then
        return ripples(p, 22, -14, 26) .. pad(p, -12, -30, 26, 9, 200) .. path("M22 -30 C16 -44 20 -58 26 -62 C30 -54 30 -42 26 -30Z", c.sage, c.ink, 1.5) .. line("M24 -34 Q22 -48 26 -58", c.ink, .8)
    end
    local pads = pad(p, 6, -62, 34, 11, 150, c.sage) .. pad(p, -44, -30, 36, 12, 215, st == 5 and c.gold or c.leaf) .. pad(p, 44, -24, 34, 11.5, 310) .. ripples(p, -6, -10, 30) .. ripples(p, 50, -52, 20)
    local tilt = p.wilt and 24 or 0
    if st == 3 then return pads .. group(2, -36, tilt + 6, nymphaea(p, 30, 1)) end
    if st == 4 then return pads .. group(2, -32, tilt, nymphaea(p, 46, p.wilt and .5 or 0)) end
    return pads .. group(2, -38, 10, ellipse(0, -9, 11, 12, 0, c.sage, c.ink, 1.5) .. line("M-4 -18 Q0 -8 -3 2 M4 -18 Q8 -8 4 2", c.ink, .8) .. ellipse(0, -20, 5, 2.4, 0, c.gold, c.ink, 1))
end

-- The canes of the rose pruned for the winter: { x, h, lean, width }.
local ROSE_CANES = { { -10, 40, -18, 5.4 }, { 3, 52, 2, 5.6 }, { 12, 44, 16, 5.4 }, { -2, 22, -6, 4 } }

-- Thorns on the cut canes and a few hips left for the birds.
local function roseRest(p)
    local out, k = "", p.st == 2 and .55 or (p.st == 3 and .8 or 1)
    for i, cane in ipairs(ROSE_CANES) do
        for j, f in ipairs({ .3, .62 }) do
            local side = (i + j) % 2 == 0 and 1 or -1
            out = out .. Flora.thorn(p.c, (cane[1] + cane[3] * f * f) * k + side * cane[4] * .45, -cane[2] * f * k, side > 0 and 90 or -90, 4.4)
        end
    end
    for i = 1, 3, 2 do
        local cane = ROSE_CANES[i]
        local tx, ty = (cane[1] + cane[3] * .6) * k, -cane[2] * .78 * k
        local hx, hy = Svg.pol(12, cane[3] > 0 and 50 or -50, tx, ty)
        out = out .. line(string.format("M%s %s L%s %s", n(tx), n(ty), n(hx), n(hy)), p.c.ink, 1.4) .. group(hx, hy, cane[3] > 0 and 50 or -50, hip(p, 13))
    end
    return out
end

Shade.rose = Kit.sprite("rose", "pips", rose, false, Rest.form({ w = 100, stubs = ROSE_CANES, litter = 4, extra = roseRest }))
Shade.honesty = Kit.sprite("honesty", "disc", honesty, false, Rest.form({ w = 66, stubs = { { -4, 72, -4, 2.6 }, { 6, 56, 10, 2.4 }, { -10, 40, -14, 2.2 } }, heads = { 1, 2, 3 },
    head = function(_dry, i, p) return group(0, 0, i % 2 == 0 and 24 or -24, moon(p, 6.4)) .. group(0, i * 6 - 4, i % 2 == 0 and -60 or 60, moon(p, 5.6)) end, litter = 2 }))
Shade.bracken = Kit.sprite("bracken", "rhizome", bracken)
Shade.water_lily = Kit.sprite("water_lily", waterLily, waterLily)

return Shade
