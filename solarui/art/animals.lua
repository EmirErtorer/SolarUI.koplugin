-- The garden's animals: animal_<id>(c, vw, vh, pose) with pose "1" or "2",
-- the two poses of the slow animation, followed by ":wash" for the faded
-- copy. Each is drawn in the units of its own place in the garden, facing
-- right, by the animals_* files; here they are fitted to the canvas asked for.

local Layout = require("solarui/garden/layout")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local Animals = {}

for _i, part in ipairs({ "air", "ground", "water" }) do
    for id, draw in pairs(require("solarui/art/animals_" .. part)) do
        local box = Layout.ANIMALS[id]
        Animals["animal_" .. id] = function(c, vw, vh, param)
            local s = tostring(param or "1")
            return Svg.group(0, 0, 0, draw(Wash.apply(c, s), s:sub(1, 1) == "2"), math.min(vw / box.w, vh / box.h))
        end
    end
end

return Animals
