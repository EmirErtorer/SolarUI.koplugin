-- The garden's ground and scenery, painted once as one backdrop: a hedge, the
-- lawn with tufts of grass, the pond, the trellis arch, the table with its
-- chairs and the plaque. garden_ground(c, vw, vh, mode) takes the canvas size
-- (units of the poster, vh as tall as the screen asks) and mode "wash" for the
-- faded copy that stays behind a picture shown larger. The places come from
-- garden/layout.lua, so the plants and animals stand on it without overlap.

local Layout = require("solarui/garden/layout")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, line, path, ellipse = Svg.n, Svg.group, Svg.line, Svg.path, Svg.ellipse

local Garden = {}

-- A tuft of grass blades with its foot at (x, y), `s` tall.
local function tuft(c, x, y, s)
    local blades = {}
    for i, lean in ipairs({ -.5, -.2, .1, .4 }) do
        blades[#blades + 1] = string.format("M%s %s Q%s %s %s %s", n(x + (i - 2.5) * s * .12), n(y), n(x + lean * s * .2), n(y - s * .6), n(x + lean * s * .5 + (i - 2.5) * s * .12), n(y - s * (.8 + .1 * (i % 2))))
    end
    return line(table.concat(blades, " "), c.stem, 2)
end

-- The hedge across the back of the garden, scalloped on top.
local function hedge(c, vh)
    local y0, y1 = Layout.at({ x = 0, y = 400, w = 0, h = 0 }, vh).y, Layout.at({ x = 0, y = 452, w = 0, h = 0 }, vh).y
    local d = string.format("M30 %s", n(y1))
    for x = 30, 1010, 56 do d = d .. string.format(" Q%s %s %s %s", n(x + 28), n(y0 - 16), n(x + 56), n(y0 + 8)) end
    return path(d .. string.format(" L1042 %s Z", n(y1)), c.sage, c.ink, 2)
end

-- The lawn: a wavy edge between each pair of rows and tufts along it.
local function lawn(c, vh)
    local out = {}
    for _i, y in ipairs({ 548, 876, 1112 }) do
        local yy = Layout.at({ x = 0, y = y, w = 0, h = 0 }, vh).y
        out[#out + 1] = line(string.format("M34 %s C250 %s 420 %s 640 %s S930 %s 1038 %s", n(yy), n(yy - 8), n(yy + 8), n(yy), n(yy - 6), n(yy)), c.stem, 2.2)
        for x = 60, 1000, 110 do out[#out + 1] = tuft(c, x + (y % 40), yy, 22) end
    end
    return table.concat(out)
end

-- The pond: a basin with water, ripples and reeds at its edge.
local function pond(c, b)
    local cx, cy = b.x + b.w / 2, b.y + b.h / 2
    return ellipse(cx, cy, b.w / 2, b.h / 2, 0, c.pale, c.ink, 2.4) .. ellipse(cx, cy, b.w / 2 - 12, b.h / 2 - 12, 0, c.sky, c.ink, 1.6)
        .. line(string.format("M%s %s q30 -8 60 0 M%s %s q24 -6 48 0", n(cx - 40), n(cy + 50), n(cx + 20), n(cy - 60)), c.ink, 1.3)
        .. line(string.format("M%s %s l-4 -50 M%s %s l6 -60 M%s %s l12 -44", n(b.x + b.w - 40), n(b.y + 40), n(b.x + b.w - 28), n(b.y + 40), n(b.x + b.w - 16), n(b.y + 44)), c.stem, 3)
end

-- The arch of a trellis round the ivy.
local function trellis(c, b)
    local x0, x1, top = b.x + 24, b.x + b.w - 24, b.y + 20
    return line(string.format("M%s %s L%s %s Q%s %s %s %s L%s %s", n(x0), n(b.y + b.h), n(x0), n(top + 120), n((x0 + x1) / 2), n(top - 90), n(x1), n(top + 120), n(x1), n(b.y + b.h)), c.ink, 4)
end

-- A chair with a curling back, facing right (flipped for the other side).
local function chair(c, x, y, flip)
    local body = line("M0 0 L0 46 M40 0 L40 46 M0 20 L40 20", c.ink, 3) .. line("M0 20 C-26 10 -16 -38 -2 -50 C20 -62 14 -28 10 -14", c.ink, 3)
    return group(x, y, 0, body, flip and -1 or 1, 1)
end

-- The table with two chairs, a cup and a book.
local function table_(c, b)
    local cx = b.x + b.w / 2
    return chair(c, b.x + 40, b.y + b.h - 60, false) .. chair(c, b.x + b.w - 40, b.y + b.h - 60, true)
        .. line(string.format("M%s %s C%s %s %s %s %s %s", n(cx), n(b.y + 110), n(cx - 24), n(b.y + 150), n(cx - 40), n(b.y + 180), n(cx - 56), n(b.y + b.h - 8)), c.ink, 3.5)
        .. line(string.format("M%s %s C%s %s %s %s %s %s", n(cx), n(b.y + 110), n(cx + 24), n(b.y + 150), n(cx + 40), n(b.y + 180), n(cx + 56), n(b.y + b.h - 8)), c.ink, 3.5)
        .. ellipse(cx, b.y + 104, 96, 18, 0, c.pale, c.ink, 2.4)
        .. path(string.format("M%s %s l54 -8 l8 12 l-54 8Z", n(cx - 50), n(b.y + 96)), c.bloom2, c.ink, 1.6)
        .. ellipse(cx + 40, b.y + 90, 16, 6, 0, c.cream, c.ink, 1.5) .. line(string.format("M%s %s q8 -22 16 -6", n(cx + 24), n(b.y + 88)), c.ink, 1.5)
end

-- The plaque: a small arched stone on two posts.
local function plaque(c, b)
    return path(string.format("M%s %s L%s %s Q%s %s %s %s L%s %sZ", n(b.x), n(b.y + b.h), n(b.x), n(b.y + 30), n(b.x + b.w / 2), n(b.y - 24), n(b.x + b.w), n(b.y + 30), n(b.x + b.w), n(b.y + b.h)), c.cream, c.ink, 2.4)
        .. line(string.format("M%s %s L%s %s", n(b.x + 20), n(b.y + b.h), n(b.x + 20), n(b.y + b.h + 8)), c.ink, 3)
end

-- A bare patch of earth in a bed with a seed on it, where a plant can go.
function Garden.garden_plot(c, vw, vh, param)
    c = Wash.apply(c, param)
    return ellipse(vw * .5, vh * .7, vw * .44, vh * .22, 0, c.pale, c.ink, 1.6) .. Svg.circle(vw * .44, vh * .66, vh * .06, c.gold, c.ink, 1.2)
        .. Svg.circle(vw * .58, vh * .72, vh * .05, c.gold, c.ink, 1.2) .. tuft(c, vw * .26, vh * .78, vh * .3)
end

-- A tuft of leaves where an animal is hiding.
function Garden.garden_tuft(c, vw, vh, param)
    c = Wash.apply(c, param)
    return tuft(c, vw * .3, vh * .92, vh * .6) .. tuft(c, vw * .6, vh * .96, vh * .7) .. tuft(c, vw * .8, vh * .92, vh * .5)
end

-- The arch the picture of a tapped plant or animal stands in.
function Garden.garden_arch(c, vw, vh)
    local d = string.format("M10 %s L10 %s Q10 10 %s 10 Q%s 10 %s %s L%s %sZ", n(vh), n(vw * .5), n(vw * .5), n(vw - 10), n(vw - 10), n(vw * .5), n(vw - 10), n(vh))
    return path(d, c.bg, c.ink, 3.2) .. path(string.format("M24 %s L24 %s Q24 24 %s 24 Q%s 24 %s %s L%s %s", n(vh), n(vw * .5), n(vw * .5), n(vw - 24), n(vw - 24), n(vw * .5), n(vw - 24), n(vh)), "none", c.line, 1.4)
end

-- The whole backdrop for a canvas vw x vh.
function Garden.garden_ground(c, _vw, vh, mode)
    c = Wash.apply(c, mode)
    local P = Layout.PROPS
    return hedge(c, vh) .. lawn(c, vh) .. trellis(c, Layout.at(Layout.PLANTS.ivy, vh)) .. pond(c, Layout.at(P.pond, vh))
        .. table_(c, Layout.at(P.table, vh)) .. plaque(c, Layout.at(P.plaque, vh))
end

return Garden
