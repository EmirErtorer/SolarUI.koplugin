-- The faded copy of the garden that stays behind a picture shown larger:
-- every colour of the palette moved most of the way towards the page's own.
-- A drawing asks for it by having "wash" in its param.

local Light = require("solarui/art/light")

local Wash = {}

local STRENGTH = .72   -- how far each colour is moved towards the page's

-- A hex colour moved `t` of the way towards another.
function Wash.mix(a, b, t)
    local function parts(h) return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16) end
    local ar, ag, ab = parts(a)
    local br, bg, bb = parts(b)
    return string.format("#%02x%02x%02x", math.floor(ar + (br - ar) * t + .5), math.floor(ag + (bg - ag) * t + .5), math.floor(ab + (bb - ab) * t + .5))
end

-- The palette `c` faded towards the page colour `page` (its own bg if none).
function Wash.palette(c, page)
    local out = {}
    page = page or c.bg or "#ffffff"
    for role, hex in pairs(c) do
        out[role] = (type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$")) and Wash.mix(hex, page, STRENGTH) or hex
    end
    return out
end

-- The palette lit for the hour in `param` and faded towards the page when it asks for the wash.
function Wash.apply(c, param)
    local lit = Light.tint(c, param)
    if tostring(param or ""):find("wash") then return Wash.palette(lit, c.bg) end
    return lit
end

return Wash
