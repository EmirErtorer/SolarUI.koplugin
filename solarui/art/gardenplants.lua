-- The garden's plants at each stage of their life, one drawing per species:
-- plant_<id>(c, vw, vh, param) where param is the stage 1 to 5 (seed, sprout,
-- bud, bloom, seed head), followed by ":wilt" for a thirsty, drooping plant
-- and ":wash" for the faded copy. Every plant grows up from the foot of its
-- canvas, centred. The drawings themselves are in the plants_* files.

local Plants = {}

for _i, part in ipairs({ "bulbs", "meadow", "shade", "trees" }) do
    for id, draw in pairs(require("solarui/art/plants_" .. part)) do Plants["plant_" .. id] = draw end
end

return Plants
