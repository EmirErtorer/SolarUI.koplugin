-- The drawings of the plants along the bottom of home (one for each place
-- to go), the root they grow from, and the three living things of the status
-- row. Each is function(c, vw, vh, param) returning SVG for a vw x vh canvas.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Quill = require("solarui/art/quill")
local Rootline = require("solarui/art/rootline")
local Svg = require("solarui/art/svg")

local n = Svg.n

local Dock = {}

-- A stalk from the foot of the canvas up to (x, y).
local function stalk(c, vw, vh, x, y, w)
    return Svg.stem(Svg.spline({ { vw * .5, vh }, { vw * .5 + (x - vw * .5) * .3, vh * .86 }, { x, y } }, 6), Svg.taper(w or 6, (w or 6) * .7), c.stem, c.ink, 1.5)
end

-- The root every plant of the dock grows from: a long swaying runner.
function Dock.root(c, vw, vh)
    local pts = Rootline.points(vw, vh)
    local out = {}
    for i, f in ipairs({ .08, .31, .5, .7, .93 }) do
        local x, y, ang = Svg.along(pts, Svg.length(pts) * f)
        out[#out + 1] = Flora.leaf(c, x, y, ang + (i % 2 == 0 and 140 or 40), vh * .5, vh * .16)
    end
    return table.concat(out) .. Svg.stem(pts, Svg.swell(9, 4), c.stem, c.ink, 1.7)
end

-- Two leaves spreading from the foot of a stalk.
local function foot(c, vw, vh)
    return Flora.leaf(c, vw * .5, vh * .9, -152, vh * .3, vh * .1) .. Flora.leaf(c, vw * .5, vh * .9, -28, vh * .3, vh * .1)
end

-- A ginkgo fan, its veins like the pages of a book fanned open.
function Dock.dock_ginkgo(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .8, 6) .. foot(c, vw, vh)
        .. Flora.ginkgo(c, vw * .5, vh * .82, 0, vh * .56, c.gold)
end

-- Collections: flowers of three kinds gathered into a posy.
function Dock.dock_collections(c, vw, vh)
    local function stem(x, y) return stalk(c, vw, vh, x, y, 4) end
    return stem(vw * .26, vh * .5) .. stem(vw * .74, vh * .46) .. stem(vw * .5, vh * .34)
        .. foot(c, vw, vh)
        .. Flora.tulip(c, vw * .26, vh * .52, -18, vh * .2, c.bloom2)
        .. Flora.daisy(c, vw * .74, vh * .36, vh * .19, 9)
        .. Flora.rose(c, vw * .5, vh * .3, vh * .24, 10)
end

-- A fern crozier still unwinding, a grown frond behind it.
function Dock.dock_fern(c, vw, vh)
    return Flora.frond(c, vw * .66, vh, 26, vh * .5)
        .. Flora.crozier(c, vw * .5, vh, 0, vh * .58, vh * .27)
end

-- The garden: its own sunflower in full bloom, seeds in their spiral.
function Dock.dock_garden(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .5, 6) .. foot(c, vw, vh)
        .. Svg.group(vw * .5, vh * .37, 0, require("solarui/art/plantkit").sunflower(c, vh * .16, true))
end

-- A dandelion clock, a lens on its stem.
function Dock.dock_clock(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .6, 5) .. foot(c, vw, vh)
        .. Flora.dandelion(c, vw * .5, vh * .38, vh * .35)
end

-- Settings: a daisy whose petals are the teeth of a wheel.
function Dock.dock_settings(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .5, 5) .. foot(c, vw, vh)
        .. Flora.daisy(c, vw * .5, vh * .38, vh * .37, 10)
end

-- Library: a narcissus.
function Dock.dock_library(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .6, 5) .. foot(c, vw, vh) .. Blooms.narcissus(c, vw * .5, vh * .4, vh * .38)
end

-- History: a crocus.
function Dock.dock_history(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .62, 5) .. foot(c, vw, vh) .. Blooms.crocus(c, vw * .5, vh * .64, 0, vh * .5)
end

-- Search: a pansy.
function Dock.dock_search(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .6, 5) .. foot(c, vw, vh) .. Blooms.pansy(c, vw * .5, vh * .4, vh * .36)
end

-- Ink Away: a lily with a feather pen lying in its pale heart, the nib
-- to the lower left and a drop of ink beside it.
function Dock.dock_inkaway(c, vw, vh)
    local u, x = vh / 130, vw * .5
    local way = {}
    for i, p in ipairs({ { -21, 73 }, { -15, 62 }, { -6, 50 }, { 4, 40 }, { 13, 33 }, { 21, 28 } }) do way[i] = { x + p[1] * u, p[2] * u } end
    return Dock.dock_lily(c, vw, vh) .. Quill.drop(c, x - 9 * u, 75 * u, 2.2 * u)
        .. Quill.pen(c, way, 18 * u, .27, c.bloom, c.bloom2, .5)
end

-- A lily on its stalk.
function Dock.dock_lily(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .6, 5) .. foot(c, vw, vh) .. Blooms.lily(c, vw * .5, vh * .4, vh * .4)
end

-- A dandelion in bloom (karahindiba).
function Dock.dock_karahindiba(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .6, 5) .. foot(c, vw, vh) .. Blooms.karahindiba(c, vw * .5, vh * .4, vh * .36)
end

-- A maple leaf on its stalk.
function Dock.dock_maple(c, vw, vh)
    return foot(c, vw, vh) .. Blooms.maple(c, vw * .5, vh * .9, 0, vh * .8)
end

-- A single rose.
function Dock.dock_rose(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .5, 5) .. foot(c, vw, vh) .. Flora.rose(c, vw * .5, vh * .36, vh * .3, 10)
end

-- Lavender: a bunch of flowering stems fanned from a tuft of narrow
-- grey-green leaves, the two shorter ones behind; each ends in a spike of
-- tiny lilac and violet florets set in whorls, the lowest whorl standing
-- apart below the rest and the spike closing into a pointed bud.
function Dock.dock_lavender(c, vw, vh)
    local foot_x, foot_y = vw * .5, vh * .95
    local leaves = {}
    for _i, l in ipairs({ { -150, .3 }, { -134, .36 }, { -118, .4 }, { -62, .4 }, { -46, .36 }, { -30, .3 }, { -104, .3 }, { -76, .3 } }) do
        leaves[#leaves + 1] = Flora.leaf(c, foot_x, foot_y, l[1], vh * l[2], vh * .045, c.sage, true)
    end
    -- one stem and its spike: the bud ends at (tx, ty), the spike `len` long and `wide` at its foot
    local function sprig(tx, ty, len, wide)
        local way = { { foot_x, foot_y }, { foot_x + (tx - foot_x) * .45, vh * .58 }, { tx, ty } }
        local pts = Svg.spline(way, 10)
        local stem = Svg.stem(pts, Svg.taper(3.2, 2), c.stem, c.ink, 1.1)
        local total = Svg.length(pts)
        local whorls = {}
        local N = 9
        for k = 0, N - 1 do
            local t = k / (N - 1)
            -- the lowest whorl a little apart, the rest close, the tip a bud
            local along = total - len * (1 - t) + (k == 0 and -len * .12 or 0)
            local x, y, ang = Svg.along(pts, along)
            local lean = (ang or -90) + 90   -- the florets follow the stem
            local r = vh * wide * (1 - .5 * t)
            local a, b = c.violet, c.lilac
            if k % 2 == 1 then a, b = b, a end
            if k == N - 1 then
                whorls[#whorls + 1] = Svg.ellipse(x, y - r * .4, r * .55, r * 1.2, lean, c.violet, c.ink, 1)
            else
                whorls[#whorls + 1] = Svg.ellipse(x - r * .75, y, r * .6, r * .92, lean - 28, a, c.ink, 1)
                    .. Svg.ellipse(x + r * .75, y, r * .6, r * .92, lean + 28, a, c.ink, 1)
                    .. Svg.ellipse(x, y - r * .3, r * .62, r, lean, b, c.ink, 1)
            end
        end
        return stem, table.concat(whorls)
    end
    local back, front = {}, {}
    for _i, sp in ipairs({ { vw * .33, vh * .07, vh * .26, .042 }, { vw * .67, vh * .09, vh * .26, .042 } }) do
        local st, wh = sprig(sp[1], sp[2], sp[3], sp[4])
        back[#back + 1] = st .. wh
    end
    for _i, sp in ipairs({ { vw * .12, vh * .22, vh * .29, .05 }, { vw * .5, vh * .02, vh * .34, .055 }, { vw * .88, vh * .22, vh * .29, .05 } }) do
        local st, wh = sprig(sp[1], sp[2], sp[3], sp[4])
        front[#front + 1] = st .. wh
    end
    return table.concat(back) .. table.concat(leaves) .. table.concat(front)
end

-- A single tulip.
function Dock.dock_tulip(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .6, 5) .. foot(c, vw, vh) .. Flora.tulip(c, vw * .5, vh * .62, 0, vh * .34, c.bloom2)
end

-- Anything else: an honesty pod, a blank disc for the button's own icon.
function Dock.dock_medallion(c, vw, vh)
    return stalk(c, vw, vh, vw * .5, vh * .6, 5) .. foot(c, vw, vh)
        .. Svg.circle(vw * .5, vh * .4, vh * .36, c.pale, c.ink, 2.2) .. Svg.circle(vw * .5, vh * .4, vh * .29, c.cream, c.ink, 1.1)
end

-- Wi-Fi: a dragonfly, its wings coloured in when the network is on.
function Dock.wifi(c, vw, vh, on)
    return Flora.dragonfly(c, vw * .42, vh * .42, 62, vw * .25, tonumber(on) == 1 and 4 or 0)
end

-- The frontlight: a lamp bud hanging from a bent stalk, lit or not.
function Dock.lamp(c, vw, vh, on)
    local lit = tonumber(on) == 1
    local stalk_pts = Svg.spline({ { vw * .2, vh }, { vw * .12, vh * .56 }, { vw * .3, vh * .14 }, { vw * .6, vh * .08 }, { vw * .72, vh * .3 } }, 8)
    local rays = {}
    if lit then
        for a = 120, 240, 30 do
            local x0, y0 = Svg.pol(vw * .44, a, vw * .72, vh * .42)
            local x1, y1 = Svg.pol(vw * .56, a, vw * .72, vh * .42)
            rays[#rays + 1] = string.format("M%s %s L%s %s", n(x0), n(y0), n(x1), n(y1))
        end
    end
    return (lit and Svg.line(table.concat(rays, " "), c.ink, 2) or "")
        .. Svg.stem(stalk_pts, Svg.taper(5, 3), c.stem, c.ink, 1.4)
        .. Flora.rosebud(c, vw * .72, vh * .3, 180, vw * .27, lit and c.gold or c.cream)
end

-- The battery: a leaf coloured in as far as it is charged (`level` 0 to 10),
-- on a curved stalk that rises from the foot of the canvas, where the vine
-- runs, and is tied to it by a knot.
function Dock.battery(c, vw, vh, level)
    local f = math.max(0, math.min(10, tonumber(level) or 0)) / 10
    local L, W, y = vw * .74, vh * .3, vh * .46
    local x0 = vw * .2
    local top = Svg.cubic(0, 0, L * .2, -W * 1.25, L * .7, -W * .95, L, 0, 24)
    local bottom = Svg.cubic(0, 0, L * .3, W * .85, L * .7, W * .55, L, 0, 24)
    local function upTo(edge)
        local out = {}
        for _i, p in ipairs(edge) do
            if p[1] <= L * f then out[#out + 1] = p end
        end
        return out
    end
    local a, b = upTo(top), upTo(bottom)
    local shape = {}
    for _i, p in ipairs(a) do shape[#shape + 1] = p end
    for i = #b, 2, -1 do shape[#shape + 1] = b[i] end
    local whole = Svg.join(top, {})
    for i = #bottom - 1, 2, -1 do whole[#whole + 1] = bottom[i] end
    local body = Svg.path(Svg.poly(whole, true), c.cream)
        .. (#shape > 2 and Svg.path(Svg.poly(shape, true), c.leaf) or "")
        .. Svg.path(Svg.poly(whole, true), nil, c.ink, 2)
        .. Svg.line(string.format("M0 0 Q%s %s %s 0", n(L * .5), n(-W * .25), n(L * .92)), c.ink, 1.1)
    local stalk_pts = Svg.spline({ { vw * .05, vh * .97 }, { vw * .08, vh * .78 }, { vw * .13, vh * .6 }, { x0, y } }, 6)
    return Svg.stem(stalk_pts, Svg.taper(5, 3), c.stem, c.ink, 1.3) .. Svg.group(x0, y, -10, body)
        .. Svg.circle(vw * .05, vh * .97, 4.2, c.leaf, c.ink, 1.3)
end

return Dock
