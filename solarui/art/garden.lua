-- The garden's ground and scenery, painted once as one backdrop: a green
-- lawn bristling with blades of grass, a clipped hedge with a gateway under
-- the trellis arch, the pond, the table and the small furniture
-- of garden_props. garden_ground(c, vw, vh, mode) takes the canvas size
-- (units of the poster, vh as tall as the screen asks) and mode "wash" for
-- the faded copy. The places come from garden/layout.lua, so the plants and
-- animals stand on it without overlap. Also here: the tuft an animal hides in
-- and the arch a picture is shown in.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Layout = require("solarui/garden/layout")
local Props = require("solarui/art/garden_props")
local Svg = require("solarui/art/svg")
local Trellis = require("solarui/art/trellis")
local Wash = require("solarui/art/wash")

local n, group, line, path = Svg.n, Svg.group, Svg.line, Svg.path

local Garden = {}

-- The box of a plant or prop on a canvas `vh` tall.
local function box(id, vh)
    return Layout.at(Layout.PLANTS[id] or Layout.PROPS[id], vh)
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

-- The lawn: a green ground under the hedge with its top edge running along
-- the hedge's foot, then blades of grass over it, three to a tuft, all of
-- similar height and leaning this way and that.
local function lawn(c, vh, top)
    local fill = Wash.mix(c.sage, c.bg, .5)
    local floor = vh - 30
    local ground = path(string.format("M34 %s C300 %s 700 %s 1038 %s L1038 %s L34 %s Z", n(top), n(top - 5), n(top + 5), n(top), n(floor), n(floor)), fill)
    local dark, light = {}, {}
    local function blade(set, x, y, h, lean, w)
        set[#set + 1] = string.format("M%s %s Q%s %s %s %sQ%s %s %s %sZ", n(x - w), n(y), n(x - w + lean * .2), n(y - h * .6), n(x + lean), n(y - h),
            n(x + w + lean * .3), n(y - h * .5), n(x + w), n(y))
    end
    for gy = 0, math.floor((floor - top - 20) / 34) do
        for gx = 0, 28 do
            local x, y = 46 + gx * 34 + 22 * Svg.vary(gx, gy), top + 30 + gy * 34 + 18 * Svg.vary(gy, gx + 5)
            if y < floor - 4 then
                for k = -1, 1 do
                    local v = Svg.vary(gx * 7 + k, gy)
                    blade((gx + gy + k) % 3 == 0 and light or dark, x + k * 4, y, 12 + 11 * v, (k * 5 + 8 * (v - .5)), 1.7)
                end
            end
        end
    end
    return ground .. path(table.concat(dark, " "), c.leaf) .. path(table.concat(light, " "), c.sage)
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
    local ivy, pond, tab = box("ivy", vh), box("pond", vh), box("table", vh)
    local base = ivy.y + ivy.h
    local out = lawn(c, vh, base) .. hedge(c, 34, ivy.x + 46, base) .. hedge(c, ivy.x + ivy.w - 46, 1038, base)
        .. group(ivy.x + ivy.w / 2, base, 0, Trellis.frame(c))
    out = out .. group(pond.x, pond.y, 0, Props.pond(c, pond.w, pond.h)) .. group(tab.x, tab.y, 0, Props.table(c), tab.w / Layout.TABLE_ART.w, tab.h / Layout.TABLE_ART.h)
    for id, b in pairs(Layout.EXTRAS) do
        local at, small = Layout.at(b, vh), Props.small(id)
        out = out .. group(at.x, at.y, 0, small.draw(c), at.w / small.w, at.h / small.h)
    end
    return out
end

return Garden
