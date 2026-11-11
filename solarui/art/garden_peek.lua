-- The small face that peeks out of the grass in the game of spot the visitor:
-- the top of a furry head with two bright eyes and the tips of two round
-- ears showing over a tuft of grass, one blade standing up between the
-- eyes. Nobody in particular: it could be any animal of the garden.
-- Drawn on a 64 x 52 design and scaled to the canvas.

local Kit = require("solarui/art/plantkit")
local Season = require("solarui/art/plantseason")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local group, path, ellipse, circle = Svg.group, Svg.path, Svg.ellipse, Svg.circle

local Peek = {}

-- The blades of the tuft: { foot x, heading, length, curl, light }, back to front.
local BLADES = {
    { 15, -20, 30, -16, false }, { 49, 20, 30, 16, false }, { 20, -10, 26, -8, true }, { 44, 12, 26, 8, true },
    { 25, -6, 21, 10, false }, { 39, 4, 21, -10, false }, { 32, 2, 27, -8, true }, { 28, -18, 17, -14, true }, { 36, 20, 17, 12, false },
}

-- An ear on the head's crown, its foot at (x, y) leaning `lean` degrees: a round-tipped flap with a pink inside.
local function ear(c, x, y, lean, fur)
    return group(x, y, lean, path("M-6 2 C-6.4 -6 -3.4 -12 0 -12.6 C3.4 -12 6.4 -6 6 2Z", fur, c.ink, 1.5) .. path("M-3 0 C-3.2 -5 -1.6 -8.6 0 -9 C1.6 -8.6 3.2 -5 3 0Z", c.bloom2))
end

-- An eye at (x, y) with a gleam of light in it.
local function eye(c, x, y)
    return ellipse(x, y, 2.7, 3.2, 0, c.ink) .. circle(x + .9, y - 1.2, 1, c.cream)
end

-- The face in its tuft; the param is the light (see art/light.lua) with the season.
function Peek.garden_peek(c, vw, vh, param)
    c = Wash.apply(Season.palette(c, Season.of(param)), param)
    local fur = Wash.mix(c.muted, c.bloom, .28)
    local out = ear(c, 21, 27, -24, fur) .. ear(c, 43, 27, 24, fur)
        .. ellipse(32, 36, 16, 12.5, 0, fur, c.ink, 1.6)
        .. path("M24 27.4 Q26 26 28.4 27.2 M35.6 27.2 Q38 26 40 27.4", nil, c.ink, .9)
        .. eye(c, 26.4, 31.6) .. eye(c, 37.6, 31.6)
    for _i, b in ipairs(BLADES) do
        out = out .. Kit.blade({ c = c }, b[1], 51, b[2], b[3], 3.8, b[4], b[5] and c.sage or c.leaf)
    end
    local k = math.min(vw / 64, vh / 52)
    return group((vw - 64 * k) / 2, vh - 52 * k, 0, out, k)
end

return Peek
