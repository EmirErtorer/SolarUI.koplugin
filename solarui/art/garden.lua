-- The garden's ground and scenery, painted once as one backdrop: a clipped
-- hedge with a gateway under the trellis arch, a line of earth under each
-- row of beds with grass along it, the pond, the table, the plaque and the
-- small furniture of garden_props. garden_ground(c, vw, vh, mode) takes the
-- canvas size (units of the poster, vh as tall as the screen asks) and mode
-- "wash" for the faded copy. The places come from garden/layout.lua, so the
-- plants and animals stand on it without overlap. Also here: the bare bed,
-- the tuft an animal hides in and the arch a picture is shown in.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Layout = require("solarui/garden/layout")
local Props = require("solarui/art/garden_props")
local Svg = require("solarui/art/svg")
local Trellis = require("solarui/art/trellis")
local Wash = require("solarui/art/wash")

local n, group, line, path = Svg.n, Svg.group, Svg.line, Svg.path

local Garden = {}

-- The rows of beds from the back to the front, each with what stands in it
-- (and where its earth stops, when that is short of the right edge).
local ROWS = {
    { "sunflower", "iris", "lily", "rose", "poppy", "chamomile" },
    { "pond", "tulip", "narcissus", "table" },
    { "honesty", "bracken", "bellflower", "crocus", "pansy", "dandelion", stop = 818 },
}

-- The box of a plant, animal or prop on a canvas `vh` tall.
local function box(id, vh)
    return Layout.at(Layout.PLANTS[id] or Layout.ANIMALS[id] or Layout.PROPS[id], vh)
end

-- A tuft of grass with its foot at (x, y), `s` tall.
local function tuft(c, x, y, s)
    local blades = {}
    for i, lean in ipairs({ -.62, -.24, .08, .36, .7 }) do
        local h = s * (.62 + .38 * Svg.vary(i, x))
        blades[#blades + 1] = string.format("M%s %s Q%s %s %s %s", n(x + (i - 3) * s * .1), n(y), n(x + (i - 3) * s * .1 + lean * s * .1), n(y - h * .6), n(x + (i - 3) * s * .1 + lean * s * .56), n(y - h))
    end
    return line(table.concat(blades, " "), c.stem, 1.8)
end

-- A line of earth through the given points with a soft band under it.
local function earth(c, way)
    local pts = Svg.spline(way, 10)
    local band = {}
    for i = 1, #pts do band[i] = { pts[i][1], pts[i][2] + 7 } end
    return path(Svg.ribbon(band, Svg.swell(13, 2)), c.soft) .. Svg.stem(pts, Svg.swell(4.6, 1.4), c.leaf, c.ink, 1.1)
end

-- The earth under a row of beds: a line through the foot of each, and grass
-- in the gaps between them.
local function row(c, ids, vh)
    local way, tufts = {}, ""
    for i, id in ipairs(ids) do
        local b = box(id, vh)
        if i == 1 then way[1] = { 34, b.y + b.h - 3 } end
        way[#way + 1] = { b.x + b.w / 2, b.y + b.h }
        if i > 1 then
            local a = box(ids[i - 1], vh)
            tufts = tufts .. tuft(c, (a.x + a.w + b.x) / 2, (a.y + a.h + b.y + b.h) / 2 + 1, 15)
        end
        if i == #ids then way[#way + 1] = { ids.stop or 1038, b.y + b.h - 3 } end
    end
    return earth(c, way) .. tufts
end

-- A stretch of clipped hedge from x0 to x1 standing on `base`, its top in
-- scallops and small leaves marked on it.
local function hedge(c, x0, x1, base)
    local d, marks = { string.format("M%s %s L%s %s", n(x0), n(base), n(x0), n(base - 44)) }, {}
    local count = math.floor((x1 - x0) / 54 + .5)
    local step = (x1 - x0) / count
    for i = 1, count do
        local x = x0 + (i - 1) * step
        d[#d + 1] = string.format("Q%s %s %s %s", n(x + step / 2), n(base - 74 - 8 * Svg.vary(i, x0)), n(x + step), n(base - 44))
        for k = 1, 3 do
            local mx, my = x + step * (.2 + .3 * k - .15 * (i % 2)), base - 14 - 14 * ((k + i) % 3)
            marks[#marks + 1] = string.format("M%s %s q3 -5 7 -1 M%s %s q-1 -5 4 -6", n(mx), n(my), n(mx + 6), n(my - 1))
        end
    end
    d[#d + 1] = string.format("L%s %sZ", n(x1), n(base))
    return path(table.concat(d, " "), c.sage, c.ink, 1.8) .. line(table.concat(marks, " "), c.ink, .8)
end

-- Short grass scattered over the lawn wherever nothing stands.
local function lawn(c, vh, taken)
    local marks = {}
    for gy = 0, math.floor((vh - 200) / 40) do
        for gx = 0, 12 do
            local x, y = 70 + gx * 72 + 44 * Svg.vary(gx, gy), 130 + gy * 40 + 22 * Svg.vary(gy, gx + 9)
            local free = y < vh - 60
            for _id, b in pairs(taken) do
                if x > b.x - 14 and x < b.x + b.w + 14 and y > b.y - 16 and y < b.y + b.h + 8 then free = false end
            end
            if free then marks[#marks + 1] = string.format("M%s %s l-3 -8 M%s %s l1 -10 M%s %s l5 -7", n(x - 3), n(y), n(x), n(y), n(x + 3), n(y)) end
        end
    end
    return line(table.concat(marks, " "), c.sage, 1.6)
end

-- A bare bed where a plant can go: a mound of earth with seeds on it and a
-- small stake beside them.
function Garden.garden_plot(c, vw, vh, param)
    local p = { c = Wash.apply(c, param) }
    local w = math.min(vw * .7, 110)
    return group(vw / 2, vh - 1, 0, Kit.soil(p, w) .. group(-w * .1, -w * .1, 0, Kit.seed(p, "pips", w * .15))
        .. line(string.format("M%s %s L%s %s", n(w * .24), n(-w * .07), n(w * .26), n(-w * .34)), p.c.ink, 2) .. path(string.format("M%s %s l%s %s l%s %s l%s %sZ", n(w * .17), n(-w * .34),
            n(w * .18), n(-w * .02), n(w * .01), n(-w * .11), n(-w * .18), n(w * .02)), p.c.cream, p.c.ink, 1.3))
end

-- A clump of leaves and grass where an animal is hiding, its eyes showing.
function Garden.garden_tuft(c, vw, vh, param)
    c = Wash.apply(c, param)
    local m, s = vw / 2, math.min(vw * .5, vh * .9)
    local out = tuft(c, m - s * .5, vh - 2, s * .5)
    for i, a in ipairs({ -52, 46, -24, 22, -2 }) do
        out = out .. Kit.blade({ c = c }, m + a * s * .002, vh - 2, a, s * (i < 3 and .72 or .92), s * .2, a * .5, i % 2 == 0 and c.leaf or c.sage)
    end
    return out .. tuft(c, m + s * .5, vh - 2, s * .42) .. Svg.circle(m - s * .08, vh - s * .2, s * .05, c.ink) .. Svg.circle(m + s * .1, vh - s * .2, s * .05, c.ink)
        .. Svg.circle(m - s * .07, vh - s * .21, s * .015, c.cream) .. Svg.circle(m + s * .11, vh - s * .21, s * .015, c.cream)
end

-- The arch the picture of a tapped plant or animal stands in: a round-headed
-- frame with a bud at its crown and a curl of leaves in each upper corner.
function Garden.garden_arch(c, vw, vh)
    local r = vw / 2
    -- the arch `d` units in from the canvas edge
    local function arch(d)
        return string.format("M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s", n(d), n(vh), n(d), n(r), n(r - d), n(r - d), n(vw - d), n(r), n(vw - d), n(vh))
    end
    local corner = line(Svg.poly(Svg.join({ { 12, 96 }, { 18, 70 } }, Svg.spiral(40, 44, 26, 1.5, 250))), c.ink, 2.4) .. Flora.leaf(c, 16, 80, -62, 44, 12, c.leaf)
        .. Flora.leaf(c, 60, 28, -8, 40, 11, c.sage)
    return corner .. group(vw, 0, 0, corner, -1, 1) .. path(arch(12) .. "Z", c.bg, c.ink, 3.2) .. line(arch(26), c.line, 1.4)
        .. Flora.leaf(c, r, 14, -164, 34, 9, c.leaf, true) .. Flora.leaf(c, r, 14, -16, 34, 9, c.leaf, true) .. Flora.rosebud(c, r, 20, 0, 13)
end

-- The whole backdrop for a canvas vw x vh.
function Garden.garden_ground(c, _vw, vh, mode)
    c = Wash.apply(c, mode)
    local ivy, pond, tab, plaque = box("ivy", vh), box("pond", vh), box("table", vh), box("plaque", vh)
    local base = ivy.y + ivy.h
    local taken = Layout.all(vh)
    taken.pond = pond
    local small = ""
    for i, s in ipairs(Props.places(vh)) do
        taken["small" .. i] = s
        small = small .. group(s.x, s.y, 0, s.draw(c))
    end
    local out = lawn(c, vh, taken) .. hedge(c, 34, ivy.x + 46, base) .. hedge(c, ivy.x + ivy.w - 46, 1038, base)
        .. earth(c, { { 34, base }, { 300, base + 2 }, { 760, base - 1 }, { 1038, base } })
        .. group(ivy.x + ivy.w / 2, base, 0, Trellis.frame(c))
    local air = box("robin", vh)
    out = out .. line(string.format("M40 %s C300 %s 700 %s 1032 %s", n(air.y + air.h + 4), n(air.y + air.h - 2), n(air.y + air.h + 10), n(air.y + air.h + 2)), c.sage, 1.8)
    for _i, ids in ipairs(ROWS) do out = out .. row(c, ids, vh) end
    local snail, fox, bird = box("snail", vh), box("fox", vh), box("peacock", vh)
    out = out .. earth(c, { { 104, snail.y + snail.h }, { 250, fox.y + fox.h - 6 }, { 390, fox.y + fox.h }, { 484, fox.y + fox.h - 2 } })
        .. earth(c, { { 584, fox.y + fox.h - 2 }, { 700, fox.y + fox.h + 1 }, { 895, bird.y + bird.h }, { 968, bird.y + bird.h - 2 } })
    return out .. group(pond.x, pond.y, 0, Props.pond(c, pond.w, pond.h)) .. group(tab.x, tab.y, 0, Props.table(c))
        .. group(plaque.x, plaque.y, 0, Props.plaque(c, plaque.w, plaque.h)) .. small
end

return Garden
