-- Which drawings are living things, and whether a living thing keeps its
-- real colours or is painted in the colour scheme. By default plants and
-- animals keep their real colours whatever scheme the reader chose, so the
-- scheme only dresses the page around them (see Theme.NATURAL_ROLES). The
-- reader may let the scheme paint them everywhere, or on home only, and keep
-- the companion on home in their own colours either way. Yüzsüz always keeps
-- hers. A drawing named "home:<name>" is <name> on home (the companion).

local Settings = require("solarui/settings")

local Natural = {}

-- Names that start like these are plants, animals or what grows with them.
local PREFIXES = { "plant_", "animal_", "dock_", "btn_", "vine_", "garden_ground", "garden_vine", "garden_tuft", "garden_peek" }
-- Drawings named exactly.
local NAMES = { root = true, rose_cluster = true, sprig = true, bee = true, butterfly = true, snail = true, wifi = true, lamp = true,
    battery = true, sunflower = true, week = true, lily = true, goal_tree = true, bar_flower = true, bloom = true, peacock_fan = true,
    sprouts = true, dock_medallion = false }
-- The living things drawn on home (besides the companion and the dock's plants).
local ON_HOME = { root = true, rose_cluster = true, sprig = true, bee = true, butterfly = true, snail = true, wifi = true, lamp = true,
    battery = true, sunflower = true, week = true, lily = true, bloom = true, peacock_fan = true, sprouts = true }

-- How the scheme treats living things: "off" (their real colours), "all" or "home".
function Natural.mode()
    return Settings.get("scheme_living", "off")
end

-- Does the companion on home keep their own colours when the scheme paints home?
function Natural.companionKept()
    return Settings.get("scheme_companion_kept", false)
end

-- Is drawing `name` a living thing?
local function living(name)
    if NAMES[name] ~= nil then return NAMES[name] end
    for _i, prefix in ipairs(PREFIXES) do
        if name:sub(1, #prefix) == prefix then return true end
    end
    return false
end

-- Is drawing `name` on home?
local function onHome(name)
    return ON_HOME[name] or name:sub(1, 5) == "dock_" or name:sub(1, 5) == "vine_"
end

-- The drawing a name stands for (without its "home:").
function Natural.drawing(name)
    return (name:gsub("^home:", ""))
end

-- Does drawing `name` keep its real colours (true), or take the scheme's?
function Natural.is(name)
    local companion = name:sub(1, 5) == "home:"
    if companion then name = name:sub(6) end
    if not living(name) then return false end
    if name == "animal_yuzsuz" then return true end   -- (Yüzsüz is always herself)
    local mode = Natural.mode()
    if mode == "off" then return true end
    if companion then return Natural.companionKept() end
    if mode == "all" then return false end
    return not onHome(name)
end

return Natural
