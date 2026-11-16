-- Covers for Ink Away's notebooks on SolarUI's notebook shelf: eight boards in
-- the Art Nouveau manner, each drawn on a 300 x 450 canvas with the room for
-- the notebook's name (its plate) left clear: Verdure (green leather tooled in
-- gold with whiplash vines and tulips), Tooled (brown leather blind-tooled at
-- the corners, laced at the spine with a tie), Nasturtium (a sage board, a
-- panel of round leaves and trumpet flowers inside a cream ribbon), Peacock
-- (midnight blue, a fan of feathers under a gold arch), Iris (violet, irises
-- in an arched window), Poppy (cream, red poppies before a halo in black
-- line), Dragonfly (teal, a lace-winged dragonfly over lily pads) and Ginkgo
-- (ochre, a rising sun and falling ginkgo leaves). Two more show the first
-- page instead of a name (data/inkcovers.lua composes those).
-- InkCovers.LOOKS lists them; InkCovers.svg(id, c) draws one.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse
local mix = Wash.mix

local InkCovers = {}

local W, H = 300, 450
InkCovers.W = W
InkCovers.H = H

local GOLD, GOLD_D = "#D8AE52", "#8A6424"

-- `body` and its mirror across the board's upright middle.
local function mirrored(body) return body .. group(W, 0, 0, body, -1, 1) end

-- The board: cloth or leather in `fill`, a lighter edge, the groove of the
-- hinge near the spine and a shade along the spine.
local function board(fill)
    return path(string.format("M0 0 L%d 0 L%d %d L0 %dZ", W, W, H, H), fill)
        .. path(string.format("M0 0 L22 0 L22 %d L0 %dZ", H, H), mix(fill, "#000000", .22))
        .. line(string.format("M24 0 L24 %d M28 0 L28 %d", H, H), mix(fill, "#000000", .35), 1.4)
        .. path(string.format("M0 0 L%d 0 L%d 6 L6 6 L6 %d L0 %dZ", W, W - 6, H - 6, H), mix(fill, "#FFFFFF", .1))
end

-- A ruled rectangle from (x0, y0) to (x1, y1).
local function rect(x0, y0, x1, y1)
    return string.format("M%s %s L%s %s L%s %s L%s %sZ", n(x0), n(y0), n(x1), n(y0), n(x1), n(y1), n(x0), n(y1))
end

-- A gold line that swells and thins along the points (a whiplash).
local function whip(pts, w, colour, k)
    return path(Svg.ribbon(Svg.spline(pts, k or 10), Svg.swell(w, .9)), colour or GOLD)
end

-- A stylised tulip in gold line, its cup `s` tall, at (x, y), turned `rot`.
local function tulip(x, y, s, rot, colour)
    local col = colour or GOLD
    local cup = string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(-s * .55), n(-s * .1), n(-s * .55), n(-s * .8), n(-s), n(s * .55), n(-s * .8), n(s * .55), n(-s * .1))
    local hatch = {}
    for k = 1, 4 do hatch[#hatch + 1] = string.format("M%s %s L%s %s", n(-s * .3 + k * s * .12), n(-s * .2), n(-s * .3 + k * s * .12), n(-s * .7)) end
    return group(x, y, rot, line(cup, col, 2.2) .. line(table.concat(hatch, " "), col, 1.2)
        .. line(string.format("M0 0 C%s %s %s %s %s %s M0 0 C%s %s %s %s %s %s", n(-s * .2), n(-s * .5), n(-s * .5), n(-s * .9), n(-s * .32), n(-s * 1.2), n(s * .2), n(-s * .5), n(s * .5), n(-s * .9), n(s * .32), n(-s * 1.2)), col, 1.6))
end

-- A row of dots along a straight line from (x0, y0) to (x1, y1), `gap` apart.
local function dots(x0, y0, x1, y1, gap, r, colour)
    local out, len = {}, math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
    local k = math.max(1, math.floor(len / gap))
    for i = 0, k do out[#out + 1] = circle(x0 + (x1 - x0) * i / k, y0 + (y1 - y0) * i / k, r, colour or GOLD) end
    return table.concat(out)
end

-- Verdure: green morocco tooled in gold, a ruled double border with a band
-- of dots between, and two whiplash vines rising from the foot to meet at the
-- head, carrying tulips; an oval cartouche for the name.
local function verdure()
    local g = "#24412F"
    local out = board(g) .. line(rect(40, 16, 286, 434) .. " " .. rect(52, 28, 274, 422), GOLD, 1.6)
        .. dots(46, 22, 280, 22, 7, 1.3) .. dots(46, 428, 280, 428, 7, 1.3) .. dots(46, 22, 46, 428, 7, 1.3) .. dots(280, 22, 280, 428, 7, 1.3)
    -- a dotted panel in each corner, cut off by an arc
    local function panel()
        local d = {}
        for y = 38, 96, 8 do
            for x = 64, 122, 8 do
                if (x - 52) ^ 2 + (y - 28) ^ 2 < 70 * 70 then d[#d + 1] = circle(x + (y % 16 == 6 and 4 or 0), y, 1.6, GOLD) end
            end
        end
        return table.concat(d) .. line("M52 98 A70 70 0 0 0 122 28", GOLD, 2)
    end
    local corners = panel() .. group(W + 26, 0, 0, panel(), -1, 1)
    out = out .. corners .. group(0, H, 0, corners, 1, -1)
    -- a vine up each side, looping inward, tulips at its turns
    local vine = whip({ { 70, 404 }, { 94, 366 }, { 82, 318 }, { 66, 280 }, { 84, 232 }, { 120, 214 }, { 104, 168 }, { 74, 132 }, { 92, 86 }, { 136, 70 } }, 4.6)
        .. circle(110, 300, 24, nil, GOLD, 2)
        .. whip({ { 94, 366 }, { 124, 356 }, { 136, 330 } }, 2.6) .. whip({ { 120, 214 }, { 140, 226 }, { 146, 248 } }, 2.4) .. whip({ { 92, 86 }, { 120, 100 }, { 124, 124 } }, 2.2)
        .. tulip(136, 332, 30, 30) .. tulip(146, 252, 28, 165) .. tulip(124, 128, 26, 160) .. tulip(136, 72, 28, 70)
    out = out .. group(13, 0, 0, mirrored(vine))
    return out .. ellipse(163, 236, 66, 46, 0, g, GOLD, 2.4) .. ellipse(163, 236, 60, 40, 0, nil, GOLD, 1)
        .. tulip(163, 186, 22, 0) .. tulip(163, 286, 22, 180)
end

-- Tooled: brown leather darker at the edges, blind-tooled brackets with
-- spirals in each corner (pressed into the leather: a dark line with a light
-- one beside it), and a leather lace wound round the spine, tied in a cord.
local function tooled()
    local b, dark, light = "#82573A", "#4A2C16", "#B5845A"
    local out = board(mix(b, "#000000", .15)) .. path(rect(40, 14, W - 12, H - 14), b) .. path(rect(70, 60, W - 40, H - 60), mix(b, "#FFFFFF", .06))
    local function corner()
        local d = "M54 28 L120 28 Q104 40 106 56 L92 56 Q86 74 70 74 L70 92 Q56 96 54 114Z M66 40 C80 40 84 52 76 58 C70 62 64 56 68 52"
        return group(1.4, 1.4, 0, line(d, light, 3.6)) .. line(d, dark, 2.4)
            .. group(1.2, 1.2, 0, line("M120 28 Q132 30 138 22 M54 114 Q52 126 44 132", light, 3)) .. line("M120 28 Q132 30 138 22 M54 114 Q52 126 44 132", dark, 1.8)
    end
    local four = corner() .. group(W + 28, 0, 0, corner(), -1, 1)
    out = out .. four .. group(0, H, 0, four, 1, -1)
    -- the lace round the spine and its tie
    for _i, y in ipairs({ 70, 170, 280, 380 }) do
        out = out .. path(string.format("M0 %d L30 %d L30 %d L0 %dZ", y, y + 2, y + 14, y + 16), mix(b, "#000000", .3), dark, 1.2)
    end
    out = out .. line("M26 176 C40 196 38 230 30 262 M28 178 C46 204 50 238 44 276", dark, 3.2) .. line("M26 176 C40 196 38 230 30 262 M28 178 C46 204 50 238 44 276", light, 1.4)
    -- a blind-tooled cartouche for the name
    local cart = "M86 172 Q86 160 98 160 L246 160 Q258 160 258 172 L258 278 Q258 290 246 290 L98 290 Q86 290 86 278Z"
    return out .. group(1.4, 1.4, 0, line(cart, light, 3)) .. line(cart, dark, 2)
end

-- One nasturtium leaf: a round pad with its veins from a centre off-middle.
local function pad(x, y, r, fill, vein)
    local out = circle(x, y, r, fill, "#1F2B1E", 1.2)
    local v = {}
    for k = 0, 7 do
        local a = math.rad(k * 45 + 10)
        v[#v + 1] = string.format("M%s %s L%s %s", n(x + r * .08), n(y + r * .06), n(x + math.cos(a) * r * .9), n(y + math.sin(a) * r * .9))
    end
    return out .. line(table.concat(v, " "), vein, 1.1)
end

-- One nasturtium flower: a trumpet of five rounded petals with its spur.
local function nasturtium(x, y, s, rot)
    local petals = ""
    for k = 0, 4 do
        petals = petals .. group(0, 0, k * 72, path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(-s * .4), n(-s * .2), n(-s * .45), n(-s * .8), n(-s * .9), n(s * .45), n(-s * .8), n(s * .4), n(-s * .2)), "#E9A24E", "#7A3E14", 1))
    end
    return group(x, y, rot, line(string.format("M0 0 L%s %s", n(s * .9), n(s * .6)), "#C97C2E", 2.6) .. petals .. circle(0, 0, s * .16, "#B8452A") .. line(string.format("M0 %s L0 %s M%s 0 L%s 0", n(-s * .5), n(-s * .2), n(-s * .5), n(-s * .2)), "#7A3E14", .9))
end

-- Nasturtium: a sage board; a dark panel thick with round leaves and orange
-- trumpets, two cream ribbons weaving round it; the name on a cream plate
-- at the foot.
local function nasturtiumCover()
    local sage, cream = "#8F9D78", "#EBDDB8"
    local out = board(sage) .. path(rect(56, 40, 270, 360), "#33452F")
    local leaves = { { 80, 70, 26 }, { 132, 58, 22 }, { 190, 76, 30 }, { 248, 62, 20 }, { 96, 130, 30 }, { 160, 126, 24 }, { 236, 134, 30 },
        { 72, 196, 22 }, { 128, 190, 28 }, { 200, 200, 26 }, { 256, 196, 18 }, { 96, 258, 26 }, { 168, 262, 30 }, { 244, 260, 26 }, { 80, 326, 24 }, { 140, 330, 22 }, { 210, 326, 28 } }
    for i, l in ipairs(leaves) do out = out .. pad(l[1], l[2], l[3], i % 3 == 0 and "#9DB880" or (i % 3 == 1 and "#B9CF97" or "#86A46A"), "#E4EDD0") end
    out = out .. nasturtium(150, 98, 20, 20) .. nasturtium(220, 168, 18, -40) .. nasturtium(110, 230, 22, 60) .. nasturtium(196, 290, 18, 10) .. nasturtium(250, 330, 14, 200)
    -- the ribbons weaving round the panel
    local left = { { 60, 30 }, { 44, 80 }, { 60, 160 }, { 44, 240 }, { 60, 320 }, { 48, 372 } }
    local ribbon = path(Svg.ribbon(Svg.spline(left, 12), Svg.taper(9, 9)), cream, "#5C5A3E", 1.2)
    out = out .. ribbon .. group(326, 0, 0, ribbon, -1, 1)
        .. path(Svg.ribbon(Svg.spline({ { 52, 34 }, { 110, 22 }, { 163, 40 }, { 216, 22 }, { 274, 34 } }, 12), Svg.taper(8, 8)), cream, "#5C5A3E", 1.2)
    return out .. path(rect(56, 370, 270, 436), cream, "#5C5A3E", 1.4) .. line(rect(62, 376, 264, 430), "#8C8461", .9)
end

-- One eye of a peacock feather at (x, y), pointing `rot`, `s` across.
local function feather(x, y, s, rot)
    local barbs = {}
    for k = -6, 6 do barbs[#barbs + 1] = string.format("M0 %s L%s %s", n(s * .9), n(k * s * .14), n(-s * .9 + math.abs(k) * s * .08)) end
    return group(x, y, rot, line(table.concat(barbs, " "), "#4E8A6E", 1)
        .. ellipse(0, 0, s * .42, s * .56, 0, "#2E7D6E", "#0F2A2A", 1) .. ellipse(0, s * .04, s * .3, s * .4, 0, GOLD) .. ellipse(0, s * .08, s * .2, s * .27, 0, "#3A9BB0")
        .. ellipse(0, s * .12, s * .1, s * .14, 0, "#132548"))
end

-- Peacock: midnight blue; a gold pointed arch; a fan of feathers rising
-- from the foot; the name on a gold-ruled plate at the head.
local function peacock()
    local out = board("#1E2A4C") .. line("M50 430 L50 150 Q50 40 163 30 Q276 40 276 150 L276 430Z", GOLD, 2.4) .. line("M60 430 L60 152 Q62 52 163 40 Q264 52 266 152 L266 430Z", GOLD, 1)
    out = out .. path("M60 430 L60 152 Q62 52 163 40 Q264 52 266 152 L266 430Z", "#24345C")
    for _row, fan in ipairs({ { { 0, 296 }, { 12, 276 }, { -12, 276 }, { 24, 226 }, { -24, 226 }, { 34, 160 }, { -34, 160 } }, { { 6, 190 }, { -6, 190 }, { 18, 150 }, { -18, 150 } } }) do
        for _i, f in ipairs(fan) do
            local a = math.rad(f[1])
            local x, y = 163 + math.sin(a) * f[2], 436 - math.cos(a) * f[2]
            out = out .. line(string.format("M163 436 Q%s %s %s %s", n(163 + math.sin(a) * f[2] * .5), n(436 - math.cos(a) * f[2] * .55), n(x), n(y)), GOLD_D, 1.4) .. feather(x, y, 30, f[1])
        end
    end
    return out .. path(rect(84, 60, 242, 132), "#1E2A4C", GOLD, 1.8) .. line(rect(90, 66, 236, 126), GOLD, .8)
end

-- One iris: three falls, three standards, a stem and a sword of a leaf.
local function iris(x, y, s, lean)
    local petal = function(rot, k) return group(0, 0, rot, path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(-s * .3), n(-s * .2), n(-s * .32), n(-s * .7), n(-s * k), n(s * .32), n(-s * .7), n(s * .3), n(-s * .2)), "#7A62B8", "#2E2050", 1.2)) end
    return line(string.format("M%s %s Q%s %s %s %s", n(x), n(y + s * 3.4), n(x + lean * .5), n(y + s * 1.6), n(x), n(y)), "#3F6B3C", 3)
        .. Flora.leaf({ ink = "#20301E" }, x - 4, y + s * 3.4, -96 + lean, s * 2.8, s * .26, "#5E8A50") .. Flora.leaf({ ink = "#20301E" }, x + 4, y + s * 3.4, -78 + lean, s * 2.4, s * .24, "#4E7A44")
        .. group(x, y, 0, petal(-150, .9) .. petal(150, .9) .. petal(180, .8) .. petal(-20, .95) .. petal(20, .95) .. petal(0, 1.05) .. circle(0, 0, s * .1, GOLD))
end

-- Iris: violet cloth; an arched window of pale sky with two irises; a gold
-- border; the name below the window.
local function irisCover()
    local out = board("#4E3E78") .. line(rect(40, 16, 286, 434), GOLD, 1.8)
        .. path("M64 330 L64 140 Q64 46 163 40 Q262 46 262 140 L262 330Z", "#E8E2F0", GOLD, 2.6)
        .. path("M64 300 Q120 284 163 296 Q210 306 262 290 L262 330 L64 330Z", "#B8C7A6")
    out = out .. iris(126, 150, 30, -6) .. iris(206, 186, 26, 8)
    out = out .. path("M64 330 L64 140 Q64 46 163 40 Q262 46 262 140 L262 330Z", nil, GOLD_D, 1) .. line("M72 322 L72 142 Q74 56 163 50 Q252 56 254 142 L254 322", GOLD, .9)
    local curl = whip({ { 64, 140 }, { 50, 112 }, { 58, 84 }, { 76, 80 } }, 2.4) .. tulip(76, 80, 16, 70)
    out = out .. curl .. group(W + 26, 0, 0, curl, -1, 1)
    return out .. line("M60 340 L266 340 M60 424 L266 424", GOLD, 1.4) .. circle(60, 382, 4, GOLD) .. circle(266, 382, 4, GOLD)
end

-- One poppy seen from the front: four round petals and the dark heart.
local function poppy(x, y, s)
    local out = ""
    for k = 0, 3 do out = out .. group(x, y, k * 90 + 20, path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(-s * .7), n(-s * .1), n(-s * .7), n(-s), n(-s * 1.05), n(s * .7), n(-s), n(s * .7), n(-s * .1)), "#C7432E", "#1C1612", 1.6)) end
    return out .. circle(x, y, s * .26, "#2A2018") .. Svg.dots(x, y, s * .36, 10, s * .07, "#2A2018")
end

-- Poppy: cream; a halo of rings behind three poppies on wavy stems, in
-- black line; the name in a dark band at the head.
local function poppyCover()
    local ink = "#1C1612"
    local out = board("#EFE3C8") .. line(rect(40, 16, 286, 434), ink, 1.8)
    out = out .. circle(163, 250, 110, "#E4CFA6", ink, 1.6) .. circle(163, 250, 96, nil, ink, 1) .. circle(163, 250, 82, nil, "#B89A66", 1)
    for _i, st in ipairs({ { 120, 210, 0 }, { 196, 246, 1 }, { 150, 300, 2 } }) do
        out = out .. line(string.format("M%s 434 C%s 380 %s %s %s %s", n(st[1] - 8 + st[3] * 10), n(st[1] + 20), n(st[1] - 16), n(st[2] + 60), n(st[1]), n(st[2])), "#3F5A36", 2.4)
    end
    out = out .. Flora.leaf({ ink = ink }, 110, 420, -120, 50, 10, "#6F8F5A") .. Flora.leaf({ ink = ink }, 216, 420, -60, 46, 10, "#6F8F5A")
    out = out .. poppy(120, 210, 30) .. poppy(196, 246, 34) .. poppy(150, 300, 26)
    return out .. path(rect(40, 40, 286, 104), ink) .. line(rect(46, 46, 280, 98), "#C9A86A", 1)
end

-- Dragonfly: teal; ripples and lily pads at the foot, a dragonfly with lace
-- wings above, all in pale gold line; the name in the middle.
local function dragonfly()
    local col = "#E6C987"
    local out = board("#2C6466") .. line(rect(40, 16, 286, 434), col, 1.6)
    out = out .. line("M60 360 q30 -8 60 0 t60 0 t60 0 t40 0 M70 388 q30 -8 60 0 t60 0 t60 0 M80 414 q30 -8 60 0 t60 0 t40 0", col, 1.2)
    for _i, p in ipairs({ { 96, 372, 30 }, { 214, 396, 36 }, { 250, 360, 20 } }) do
        out = out .. path(string.format("M%s %s A%s %s 0 1 1 %s %s L%s %sZ", n(p[1] + p[3]), n(p[2]), n(p[3]), n(p[3] * .36), n(p[1] + p[3] * .8), n(p[2] - p[3] * .2), n(p[1]), n(p[2])), "#3E7A5E", col, 1.4)
    end
    local function wing(rot, L)
        return group(163, 120, rot, path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(L * .2), n(-L * .2), n(L * .2), n(-L * .9), n(-L), n(-L * .16), n(-L * .9), n(-L * .14), n(-L * .2)), "#3E8C8A", col, 1.4)
            .. line(string.format("M0 0 L0 %s M%s %s L%s %s M%s %s L%s %s", n(-L * .95), n(-L * .08), n(-L * .3), n(L * .06), n(-L * .6), n(L * .08), n(-L * .3), n(-L * .06), n(-L * .7)), col, .8))
    end
    out = out .. wing(-62, 84) .. wing(-110, 76) .. wing(62, 84) .. wing(110, 76)
        .. path("M160 106 L166 106 L167 250 L163 262 L159 250Z", col, "#14302F", 1) .. circle(163, 100, 8, col, "#14302F", 1)
    return out .. ellipse(163, 302, 94, 44, 0, "#2C6466", col, 1.8) .. ellipse(163, 302, 88, 38, 0, nil, col, .8)
end

-- One ginkgo leaf: a fan on a stalk, notched in the middle, veins fanning.
local function ginkgo(x, y, s, rot, fill)
    local veins = {}
    for k = -4, 4 do veins[#veins + 1] = string.format("M0 0 L%s %s", n(math.sin(math.rad(k * 13)) * s), n(-math.cos(math.rad(k * 13)) * s)) end
    return group(x, y, rot, line(string.format("M0 0 L0 %s", n(s * .7)), "#6A4A18", 1.6)
        .. path(string.format("M0 0 L%s %s Q%s %s %s %s L0 %s L%s %s Q%s %s %s %sZ", n(-s * .78), n(-s * .62), n(-s * .5), n(-s * 1.08), n(-s * .08), n(-s * 1.02), n(-s * .78),
            n(s * .08), n(-s * 1.02), n(s * .5), n(-s * 1.08), n(s * .78), n(-s * .62)), fill, "#5A3A10", 1.2)
        .. line(table.concat(veins, " "), mix(fill, "#5A3A10", .45), .7))
end

-- Ginkgo: ochre; a sun rising behind a gold arch, its rays fanning; ginkgo
-- leaves falling; the name on a dark plate below.
local function ginkgoCover()
    local out = board("#B8822E") .. line(rect(40, 16, 286, 434), "#5A3A10", 1.6)
    local rays = {}
    for k = -8, 8 do
        local a = math.rad(k * 10)
        -- (each ray stops short of the ruled frame, 40 to 286 across and 16 down)
        local r = math.min(150, 111 / math.max(math.abs(math.sin(a)), .01), 222 / math.max(math.cos(a), .01))
        rays[#rays + 1] = string.format("M%s %s L%s %s", n(163 + math.sin(a) * 66), n(250 - math.cos(a) * 66), n(163 + math.sin(a) * r), n(250 - math.cos(a) * r))
    end
    out = out .. line(table.concat(rays, " "), "#F2D48A", 3) .. path("M93 250 A70 70 0 0 1 233 250Z", "#F4DA92", "#5A3A10", 1.6)
        .. line("M60 250 L266 250", "#5A3A10", 2) .. line("M60 258 L266 258", "#5A3A10", .9)
    out = out .. ginkgo(96, 120, 34, -30, "#F0C860") .. ginkgo(232, 96, 28, 40, "#E8B048") .. ginkgo(206, 186, 22, 160, "#F0C860") .. ginkgo(80, 214, 24, 100, "#E8B048") .. ginkgo(250, 216, 20, -70, "#F4DA92")
    return out .. path(rect(60, 300, 266, 380), "#4A2E0E") .. line(rect(66, 306, 260, 374), "#F2D48A", 1)
end

-- Every look, in the order they are dealt and offered: id, draw (or nil for
-- one that shows the first page), the plate the name is set on (x, y, w, h on
-- the 300 x 450 canvas) and its ink, and whether the plate is round.
InkCovers.LOOKS = {
    { id = "verdure", draw = verdure, plate = { 107, 202, 112, 68 }, ink = GOLD, name = "Verdure" },
    { id = "tooled", draw = tooled, plate = { 72, 180, 200, 90 }, ink = "#3A2312", light = "#9A6A43", name = "Tooled" },
    { id = "nasturtium", draw = nasturtiumCover, plate = { 68, 378, 190, 50 }, ink = "#3A3A22", name = "Nasturtium" },
    { id = "peacock", draw = peacock, plate = { 92, 68, 142, 56 }, ink = GOLD, name = "Peacock" },
    { id = "iris", draw = irisCover, plate = { 70, 348, 186, 70 }, ink = GOLD, name = "Iris" },
    { id = "poppy", draw = poppyCover, plate = { 50, 48, 226, 48 }, ink = "#EFE3C8", name = "Poppy" },
    { id = "dragonfly", draw = dragonfly, plate = { 86, 270, 154, 64 }, ink = "#E6C987", name = "Dragonfly" },
    { id = "ginkgo", draw = ginkgoCover, plate = { 70, 310, 186, 60 }, ink = "#F2D48A", name = "Ginkgo" },
    { id = "page", name = "First page" },
    { id = "mount", name = "First page, mounted" },
}

-- The look with this id, or nil.
function InkCovers.look(id)
    for _i, l in ipairs(InkCovers.LOOKS) do
        if l.id == id then return l end
    end
    return nil
end

-- The SVG body of look `id` on the 300 x 450 canvas, or nil for a look that
-- shows the first page.
function InkCovers.svg(id)
    local l = InkCovers.look(id)
    return l and l.draw and l.draw() or nil
end

-- The cloth spine and gilt bands down the left of a cover that shows the
-- first page, and the edges of the leaves along the right and the foot.
function InkCovers.pageEdges()
    local out = path(string.format("M%d 0 L%d 4 L%d %d L%d %dZ", W - 10, W, W, H, W - 10, H - 4), "#E9E1CC", "#7A705A", 1)
    for k = 1, 3 do out = out .. line(string.format("M%d %d L%d %d", W - 10 + k * 2.4, 2 + k, W - 10 + k * 2.4, H - 2 - k), "#B9AF96", .6) end
    return out .. path(string.format("M0 0 L34 0 L34 %d L0 %dZ", H, H), "#2E4A3A") .. line(string.format("M34 0 L34 %d", H), "#1A2A20", 1.6)
        .. line("M0 40 L34 40 M0 46 L34 46 M0 404 L34 404 M0 410 L34 410", GOLD, 1.6)
        .. path("M17 210 C24 220 24 230 17 240 C10 230 10 220 17 210Z", GOLD, GOLD_D, 1)
end

-- A gilt mount round a first page shown on a cream card: a fine gold rule
-- with whiplash flourishes curling out of each corner.
function InkCovers.mount()
    local function corner()
        return line("M30 70 L30 30 L70 30", GOLD, 2.4) .. line(Svg.poly(Svg.join({ { 30, 30 }, { 44, 44 } }, Svg.spiral(52, 40, 8, 1.1, 200))), GOLD, 1.6)
            .. Flora.leaf({ ink = GOLD_D }, 30, 30, -135, 22, 6, GOLD, true)
    end
    local four = corner() .. group(W, 0, 0, corner(), -1, 1)
    return line(rect(30, 30, W - 30, H - 30), GOLD, 1.2) .. four .. group(0, H, 0, four, 1, -1)
end

return InkCovers
