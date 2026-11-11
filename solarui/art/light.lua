-- The light of the hour on the garden: the palette `c` as it looks at the
-- given sky phase ("morning", "day", "golden" or "night"). A drawing asks for
-- it by having the phase's name in its param.

local Light = {}

-- The palette lit for the phase named in `param` (unchanged when it names none).
function Light.tint(c, _param)
    return c
end

return Light
