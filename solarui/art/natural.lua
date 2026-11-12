-- Which drawings are living things. Plants and animals keep their real
-- colours whatever scheme the reader chose, so the scheme only dresses the
-- page around them (see Theme.NATURAL_ROLES).

local Natural = {}

-- Names that start like these are plants, animals or what grows with them.
local PREFIXES = { "plant_", "animal_", "dock_", "btn_", "vine_", "garden_ground", "garden_vine", "garden_tuft", "garden_peek" }
-- Drawings named exactly.
local NAMES = { root = true, rose_cluster = true, sprig = true, bee = true, butterfly = true, snail = true, wifi = true, lamp = true,
    battery = true, sunflower = true, week = true, lily = true, goal_tree = true, bar_flower = true, bloom = true, peacock_fan = true,
    sprouts = true, dock_medallion = false }

-- Is drawing `name` a living thing?
function Natural.is(name)
    if NAMES[name] ~= nil then return NAMES[name] end
    for _i, prefix in ipairs(PREFIXES) do
        if name:sub(1, #prefix) == prefix then return true end
    end
    return false
end

return Natural
