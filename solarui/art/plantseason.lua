-- The season on the garden's plants. A plant's param carries one of the
-- tokens "spring", "summer", "autumn", "winter" or "dormant" (died back for
-- the winter); summer is the palette as drawn. Spring freshens the greens,
-- autumn yellows them, winter dulls them towards a cold blue-green and brings
-- a white rime that the leaf helpers draw along their upper edges. A dormant
-- plant is drawn in its own winter form (see plantrest), in the same cold
-- light, with the dry colours of dead stems and leaves.

local Light = require("solarui/art/light")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, mix = Svg.n, Wash.mix

local Season = {}

local NAMES = { spring = true, summer = true, autumn = true, winter = true, dormant = true }

-- What each season does to the greens: { role, towards (a role or a colour as seen), how far }.
local SHIFTS = {
    spring = { { "leaf", "#8FC65A", .45 }, { "sage", "#B9DA8A", .4 }, { "stem", "leaf", .32 } },
    autumn = { { "leaf", "gold", .42 }, { "sage", "pale", .36 }, { "sage", "bloom", .08 }, { "stem", "muted", .28 } },
    winter = { { "leaf", "sky", .34 }, { "sage", "sky", .3 }, { "stem", "glass", .18 }, { "leaf", "muted", .14 } },
}
SHIFTS.dormant = SHIFTS.winter

local FROST = "#F3F7F8"   -- the white of hoarfrost, as seen

local made = setmetatable({}, { __mode = "k" })   -- for each palette, its copy in each season

-- The season named in `param` (summer when it names none).
function Season.of(param)
    for token in tostring(param or ""):gmatch("[^:]+") do
        if NAMES[token] then return token end
    end
    return "summer"
end

-- The palette `c` in `season`: the greens moved, and for winter the roles
-- `frost` (hoarfrost), `straw` (dead stems), `dead` and `rust` (dead leaves).
function Season.palette(c, season)
    local shift = SHIFTS[season]
    if not shift then return c end
    made[c] = made[c] or {}
    local out = made[c][season]
    if out then return out end
    out = {}
    for role, hex in pairs(c) do out[role] = hex end
    for _i, s in ipairs(shift) do out[s[1]] = mix(out[s[1]], s[2]:sub(1, 1) == "#" and Light.paint(s[2]) or c[s[2]], s[3]) end
    if season == "winter" or season == "dormant" then
        out.frost = Light.paint(FROST)
        out.straw = mix(c.muted, c.pale, .38)
        out.dead = mix(c.gold, c.muted, .5)
        out.rust = mix(c.bloom, c.muted, .42)
    end
    made[c][season] = out
    return out
end

-- Hoarfrost along an edge through the points `pts`: short broken white
-- strokes with a fleck at every few, or nothing when the palette has no frost.
function Season.rime(c, pts)
    if not c.frost or #pts < 2 then return "" end
    local dashes, flecks = {}, {}
    for i = 1, #pts - 1, 2 do
        local a, b = pts[i], pts[i + 1]
        dashes[#dashes + 1] = string.format("M%s %s L%s %s", n(a[1]), n(a[2]), n(b[1]), n(b[2]))
        if i % 3 == 1 then flecks[#flecks + 1] = Svg.circle(b[1], b[2] - .6, 1.1, c.frost) end
    end
    return Svg.line(table.concat(dashes, " "), c.frost, 1.8) .. table.concat(flecks)
end

return Season
