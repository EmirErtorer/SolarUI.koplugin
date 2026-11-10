-- Turns a cover picture into something made of pieces: stained glass (lozenge
-- panes held by lead), peacock scales (overlapping round scales) or a
-- blossom field (a small flower for each spot of the picture). Each piece
-- takes the colour of the picture where it sits, so the cover stays
-- recognisable. Painted once into the cover's kept tile, never per frame.

local Blitbuffer = require("ffi/blitbuffer")
local Paint = require("solarui/gfx/paint")
local RenderImage = require("ui/renderimage")
local Theme = require("solarui/theme")

local Mosaic = {}

local floor, max, min = math.floor, math.max, math.min

-- How many pieces fit across a cover for each effect.
local ACROSS = { glass = 8, scales = 8, blossom = 10 }

-- The effects, in the order the settings show them.
Mosaic.EFFECTS = { "glass", "scales", "blossom" }

-- The picture shrunk to cols x rows, as a function (col, row) -> r, g, b
-- (night mode inverts the screen, so the colours go in inverted).
local function sampler(img, cols, rows)
    local small = RenderImage:scaleBlitBuffer(img, max(1, cols), max(1, rows), false)
    local night = Theme.nightMode()
    local function at(cx, cy)
        local px = small:getPixel(min(small:getWidth() - 1, max(0, cx)), min(small:getHeight() - 1, max(0, cy))):getColorRGB32()
        local r, g, b = px.r, px.g, px.b
        -- richer than the print, so the pieces read as coloured glass and petals
        local m = (r + g + b) / 3
        r, g, b = min(255, max(0, m + (r - m) * 1.8)), min(255, max(0, m + (g - m) * 1.8)), min(255, max(0, m + (b - m) * 1.8))
        if night then r, g, b = 255 - r, 255 - g, 255 - b end
        return floor(r), floor(g), floor(b)
    end
    return at, function() small:free() end
end

-- A colour to paint into the tile with: the tile is always RGB, and is turned
-- to grey on a black and white screen when it is blended in.
local function rgb(r, g, b)
    return Blitbuffer.ColorRGB32(max(0, min(255, floor(r))), max(0, min(255, floor(g))), max(0, min(255, floor(b))), 0xFF)
end

-- A colour made richer and coarser for glass.
local function glass(r, g, b)
    local m = (r + g + b) / 3
    local function q(v) return max(0, min(255, floor((m + (v - m) * 1.35) / 43 + .5) * 43)) end
    return rgb(q(r), q(g), q(b))
end

-- A colour pulled towards white by `t`.
local function lighter(r, g, b, t)
    return rgb(r + (255 - r) * t, g + (255 - g) * t, b + (255 - b) * t)
end

-- A filled circle of radius r about (cx, cy).
local function disc(bb, cx, cy, r, c)
    if r < 1 then return end
    Paint.disc(bb, floor(cx - r + .5), floor(cy - r + .5), floor(2 * r + .5), c)
end

-- Stained glass: staggered lozenges, each a pane of the picture's colour
-- inside lead lines.
local function paintGlass(bb, w, h, at)
    local ink = Theme.color("ink")
    Paint.fill(bb, 0, 0, w, h, ink)
    local dw = w / ACROSS.glass
    local dh = dw * 1.3
    local lead = max(1, floor(dw / 10))
    local gw, gh = floor(w / (dw / 2) + .5), floor(h / (dh / 2) + .5)
    for i = -1, floor(h / (dh / 2)) + 1 do
        for j = -1, ACROSS.glass + 1 do
            local cx, cy = (j + .5 + (i % 2) * .5) * dw, i * dh / 2
            local r, g, b = at(floor(cx / (w / gw)), floor(cy / (h / gh)))
            local c = glass(r, g, b)
            for dy = -floor(dh / 2) + lead, floor(dh / 2) - lead do
                local half = (dw / 2) * (1 - math.abs(dy) / (dh / 2)) - lead * 1.2
                if half > 0 then Paint.fill(bb, floor(cx - half), floor(cy + dy), floor(2 * half), 1, c) end
            end
        end
    end
end

-- Peacock scales: rows of overlapping round scales in the picture's colours,
-- each with a paler eye, drawn from the top down so lower rows overlap.
local function paintScales(bb, w, h, at)
    local ink = Theme.color("ink")
    Paint.fill(bb, 0, 0, w, h, ink)
    local s = w / ACROSS.scales
    local R = s * .62
    local lead = max(1, floor(s / 16))
    local gw, gh = floor(w / (s / 2) + .5), floor(h / (s / 2) + .5)
    for i = -1, floor(h / (s * .5)) + 1 do
        for j = -1, ACROSS.scales + 1 do
            local cx, cy = (j + (i % 2) * .5) * s, i * s * .5
            local r, g, b = at(floor(cx / (w / gw)), floor(cy / (h / gh)))
            disc(bb, cx, cy, R + lead, ink)
            disc(bb, cx, cy, R, rgb(r, g, b))
            disc(bb, cx, cy, R * .5 + lead, ink)
            disc(bb, cx, cy, R * .5, lighter(r, g, b, .3))
            disc(bb, cx, cy, R * .26, rgb(r, g, b))
        end
    end
end

-- A blossom field: a flower of five petals and a pale heart for each spot
-- of the picture, on the page's colour.
local function paintBlossom(bb, w, h, at)
    Paint.fill(bb, 0, 0, w, h, Theme.color("bg"))
    local ink = Theme.color("ink")
    local gold = Theme.color("gold")
    local cols = ACROSS.blossom
    local p = w / cols
    local rows = floor(h / p + .999)
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local cx, cy = (col + .5 + (row % 2) * .25 - .125) * p, (row + .5) * p
            local r, g, b = at(col, row)
            local c = rgb(r, g, b)
            local pr = p * .2
            for k = 0, 4 do
                local a = math.rad(k * 72 + row * 17)
                disc(bb, cx + math.sin(a) * p * .22, cy - math.cos(a) * p * .22, pr + 1, ink)
            end
            for k = 0, 4 do
                local a = math.rad(k * 72 + row * 17)
                disc(bb, cx + math.sin(a) * p * .22, cy - math.cos(a) * p * .22, pr, c)
            end
            disc(bb, cx, cy, p * .13, gold)
        end
    end
end

-- Paint `img` as `effect` into the box (x, y, w, h) of `bb`.
function Mosaic.paint(bb, img, x, y, w, h, effect)
    local tmp = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
    local cols, rows
    if effect == "blossom" then
        cols = ACROSS.blossom
        rows = floor(h / (w / cols) + .999)
    elseif effect == "scales" then
        cols, rows = floor(w / (w / ACROSS.scales / 2) + .5), floor(h / (w / ACROSS.scales / 2) + .5)
    else
        cols, rows = floor(w / (w / ACROSS.glass / 2) + .5), floor(h / (w / ACROSS.glass * 1.3 / 2) + .5)
    end
    local at, done = sampler(img, cols, rows)
    if effect == "blossom" then paintBlossom(tmp, w, h, at)
    elseif effect == "scales" then paintScales(tmp, w, h, at)
    else paintGlass(tmp, w, h, at) end
    done()
    bb:blitFrom(tmp, x, y, 0, 0, w, h)
    tmp:free()
end

return Mosaic
