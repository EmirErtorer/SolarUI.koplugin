-- Every drawing by name: the home screen's garden, its reading strip, the
-- dock's plants, the small drawings of the other pages and the covers' window.
-- A drawing is function(c, vw, vh, param) returning SVG for a vw x vh canvas
-- in the colours `c`.

local Sprites = {}

for _i, part in ipairs({ "solarui/art/home", "solarui/art/reading", "solarui/art/dock", "solarui/art/pages", "solarui/art/frames", "solarui/art/coverart", "solarui/art/ornaments", "solarui/art/scenes", "solarui/art/garden", "solarui/art/gardenplants", "solarui/art/animals" }) do
    for name, draw in pairs(require(part)) do Sprites[name] = draw end
end

return Sprites
