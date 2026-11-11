-- The garden's plants at each stage of their life, one drawing per species:
-- plant_<id>(c, vw, vh, param) where param is the stage 1 to 5 (seed, sprout,
-- bud, bloom, seed head), followed by ":wilt" for a thirsty, drooping plant,
-- ":flip" to turn it the other way round and ":wash" for the faded copy. Every plant grows up from the foot of its
-- canvas, centred. The drawings themselves are in the plants_* files.

local Svg = require("solarui/art/svg")

local Plants = {}

-- A plant's drawing that is turned the other way round when its param has "flip".
local function turning(draw)
    return function(c, vw, vh, param)
        local body = draw(c, vw, vh, param)
        return tostring(param or ""):find("flip") and Svg.group(vw, 0, 0, body, -1, 1) or body
    end
end

for _i, part in ipairs({ "bulbs", "meadow", "shade", "trees" }) do
    for id, draw in pairs(require("solarui/art/plants_" .. part)) do Plants["plant_" .. id] = turning(draw) end
end

return Plants
