-- The sky over the garden follows the hour on the device: night from ten in
-- the evening to five, morning to eleven, day to five in the afternoon, then
-- the golden hour until night. The same name lights the garden (art/light.lua)
-- and says which animals are about.

local Settings = require("solarui/settings")

local Sky = {}

-- The phases in the order the day goes through them.
Sky.PHASES = { "morning", "day", "golden", "night" }

-- The phase of an hour (0 to 23).
function Sky.phase(hour)
    if hour >= 22 or hour < 5 then return "night" end
    if hour < 11 then return "morning" end
    if hour < 17 then return "day" end
    return "golden"
end

-- The hour of the garden (0 to 23): the one the reader picked on the garden's
-- clock, else the device's own. Tests and previews may replace this.
function Sky.hour()
    local picked = Settings.get("garden_hour", nil)
    if type(picked) == "number" then return picked end
    return tonumber(os.date("%H")) or 12
end

-- The phase now.
function Sky.now()
    return Sky.phase(Sky.hour())
end

return Sky
