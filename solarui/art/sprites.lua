-- Every drawing by name: the home screen's garden and the dock's plants.
-- A drawing is function(c, vw, vh, param) returning SVG for a vw x vh canvas
-- in the colours `c`.

local Sprites = {}

for _i, part in ipairs({ "solarui/art/home", "solarui/art/dock" }) do
    for name, draw in pairs(require(part)) do Sprites[name] = draw end
end

return Sprites
