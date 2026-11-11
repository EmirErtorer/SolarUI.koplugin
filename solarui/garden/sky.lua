-- The sky over the garden follows the hour on the device: night from ten in
-- the evening to five, morning to eleven, day to five in the afternoon, then
-- the golden hour until night. The same name lights the garden (art/light.lua)
-- and says which animals are about.

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

-- The phase now.
function Sky.now()
    return Sky.phase(tonumber(os.date("%H")) or 12)
end

return Sky
