-- The light of the hour on the garden: the palette `c` as it looks at the
-- given sky phase ("morning", "day", "golden" or "night"). A drawing asks for
-- it by having the phase's name as one of the tokens of its param (tokens are
-- parted by colons, as in "4:wilt:golden"). Morning and the golden hour pass
-- every colour through a coloured glass and move it a little towards a haze;
-- night keeps each colour's lightness on a darker scale and turns most of
-- its hue to moonlit blue. Light things stay lighter than dark ones, so the
-- garden reads the same in grey. Colours are lit as they are seen: under
-- KOReader's night mode the palette is painted inverted, so it is turned
-- back first.

local Theme = require("solarui/theme")

local Light = {}

-- Each phase's light. glass: the share of red, green and blue kept; haze and
-- much: the colour everything moves towards and how far. moon: the blue that
-- lightness is turned into, from `low` (black) to `high` (white), `keep` of
-- the colour's own hue kept. Day is the palette as it is.
local PHASES = {
    morning = { glass = { .98, .96, .98 }, haze = "#F6D9C9", much = .12 },
    day = false,
    golden = { glass = { 1, .94, .8 }, haze = "#E8A057", much = .09 },
    night = { moon = { .8, .92, 1.24 }, low = .1, high = .62, keep = .36 },
}

local INK = .3   -- the share of the light the outlines take, so they stay dark against what they edge

local lit = {}   -- for each phase, the lit copy of each palette, kept while the palette lives

-- The phase named in `param`, or nil.
function Light.phase(param)
    for token in tostring(param or ""):gmatch("[^:]+") do
        if PHASES[token] ~= nil then return token end
    end
    return nil
end

-- Red, green and blue of a hex colour.
local function parts(hex)
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

-- A hex colour from red, green and blue, each kept between 0 and 255.
local function hex3(r, g, b)
    local function clamp(v) return math.max(0, math.min(255, math.floor(v + .5))) end
    return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
end

-- A colour turned between how it is seen and how it is painted (inverted under night mode).
function Light.paint(hex)
    if not Theme.get().night then return hex end
    local r, g, b = parts(hex)
    return hex3(255 - r, 255 - g, 255 - b)
end

-- Red, green and blue of a seen colour in the light `p`.
local function seenIn(p, r, g, b)
    local v = { r, g, b }
    if p.moon then
        local l = (.299 * r + .587 * g + .114 * b) / 255
        local value = (p.low + (p.high - p.low) * l ^ .85) * 255
        for i = 1, 3 do
            local own = l > 0 and v[i] * value / (l * 255) or value
            v[i] = value * p.moon[i] + (own - value * p.moon[i]) * p.keep
        end
        return v
    end
    local hr, hg, hb = parts(p.haze)
    local haze = { hr, hg, hb }
    for i = 1, 3 do
        local through = v[i] * p.glass[i]
        v[i] = through + (haze[i] - through) * p.much
    end
    return v
end

-- One hex colour in the light `p`, `share` of the way (1 is all of it).
local function shine(hex, p, share)
    local r, g, b = parts(Light.paint(hex))
    local v = seenIn(p, r, g, b)
    return Light.paint(hex3(r + (v[1] - r) * share, g + (v[2] - g) * share, b + (v[3] - b) * share))
end

-- The palette lit for the phase named in `param`, or unchanged when it names none or day.
function Light.tint(c, param)
    local phase = Light.phase(param)
    local p = phase and PHASES[phase]
    if not p then return c end
    lit[phase] = lit[phase] or setmetatable({}, { __mode = "k" })
    local out = lit[phase][c]
    if not out then
        out = {}
        for role, hex in pairs(c) do
            out[role] = (type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$")) and shine(hex, p, role == "ink" and INK or 1) or hex
        end
        lit[phase][c] = out
    end
    return out
end

return Light
