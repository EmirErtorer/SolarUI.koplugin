-- Every drawing by name: the home screen's garden, its reading strip, the dock's plants and the
-- small drawings of the other pages.
-- A drawing is function(c, vw, vh, param) returning SVG for a vw x vh canvas
-- in the colours `c`.

local Sprites = {}

for _i, part in ipairs({ "solarui/art/home", "solarui/art/reading", "solarui/art/dock", "solarui/art/pages" }) do
    for name, draw in pairs(require(part)) do Sprites[name] = draw end
end

return Sprites
