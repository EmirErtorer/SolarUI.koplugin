-- The sky over the garden at each phase of the day, painted behind the trees
-- and the hedge: flat bands of colour parted by long waving edges, far hills
-- at the horizon, and the sun, moon, stars, clouds and birds of sky_bodies.
-- Its colours come from the palette as it is (the sky is the light, so it is
-- not lit itself), mixed with a few colours of the hour, and dimmed under a
-- bank of cloud by the weather of garden_weather.

local Bodies = require("solarui/art/sky_bodies")
local GardenWeather = require("solarui/art/garden_weather")
local Light = require("solarui/art/light")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, path, line = Svg.n, Svg.path, Svg.line
local mix, P = Wash.mix, Light.paint

local GardenSky = {}

local BANDS = 5   -- the bands of colour from the top of the sky to the horizon

-- The colours of the sky for a phase: its bands, the far hills and the bodies in it.
local function colours(c, phase)
    local k = { ink = c.ink, bg = c.bg, cloud = c.cream, star = c.cream, star2 = c.pale }
    if phase == "night" then
        k.bands = { P("#141A38"), P("#1A2246"), P("#212B55"), P("#293566"), P("#324177") }
        k.hills, k.hills2 = P("#3A4878"), P("#43537F")
        k.moon, k.halo, k.halo2 = mix(c.cream, c.pale, .35), P("#2C3869"), P("#36447A")
        k.cloud, k.shade = P("#3E4B7E"), P("#2E3A6A")
    elseif phase == "golden" then
        k.bands = { mix(P("#5C4A86"), c.bloom2, .3), mix(c.bloom2, P("#B26E88"), .35), mix(c.bloom2, c.gold, .45), mix(c.gold, c.pale, .35), mix(c.pale, c.cream, .4) }
        k.hills, k.hills2 = mix(P("#8A5C78"), c.bloom2, .25), mix(P("#A36F7E"), c.bloom2, .4)
        k.sun, k.glow, k.ray, k.halo = mix(c.gold, c.bloom, .32), c.pale, c.gold, mix(c.pale, c.gold, .35)
        k.beam, k.cloud, k.shade = mix(c.pale, c.cream, .45), mix(c.pale, c.bloom2, .45), mix(c.bloom2, c.bloom, .35)
    elseif phase == "morning" then
        k.bands = { mix(c.sky, P("#8EA6D4"), .5), mix(c.sky, P("#C2CCE6"), .6), mix(c.bloom2, c.cream, .5), mix(c.pale, c.cream, .55), mix(c.cream, P("#F7DDC6"), .45) }
        k.hills, k.hills2 = mix(c.sage, P("#B9B4D2"), .55), mix(c.sage, P("#CFC3D6"), .6)
        k.sun, k.glow, k.ray = mix(c.pale, c.cream, .35), c.cream, mix(c.bloom2, c.pale, .45)
        k.shade = mix(c.bloom2, c.cream, .35)
    else
        k.bands = { mix(c.sky, P("#4E86BC"), .55), mix(c.sky, P("#6E9ECB"), .42), mix(c.sky, P("#94BAD8"), .3), mix(c.sky, c.cream, .32), mix(c.sky, c.cream, .58) }
        k.hills, k.hills2 = mix(c.sage, c.sky, .5), mix(c.sage, c.sky, .7)
        k.sun, k.glow, k.ray = c.pale, mix(c.pale, c.cream, .55), c.gold
        k.shade = mix(c.sky, c.cream, .3)
    end
    for i, hex in ipairs(k.bands) do k["band" .. i] = hex end
    k.bands = nil
    return k
end

-- The points of a long waving edge across the sky at height `y`, swelling like a whiplash line.
local function edge(x0, x1, y, amp, seed)
    local pts = {}
    for x = x0, x1 + 24, 24 do
        local u = (x - x0) / (x1 - x0)
        pts[#pts + 1] = { math.min(x, x1), y + amp * math.sin(u * 7.1 + seed) + amp * .55 * math.sin(u * 15.3 + seed * 2.3) }
    end
    return pts
end

-- The bands of the sky between y0 and y1, each over the foot of the one above, edged by a thin line.
local function bands(k, x0, y0, x1, y1)
    local out = path(string.format("M%s %s L%s %s L%s %s L%s %sZ", n(x0), n(y0 + 20), n(x1), n(y0 + 20), n(x1), n(y1), n(x0), n(y1)), k.band1)
    local count = BANDS
    for i = 2, count do
        local pts = edge(x0, x1, y0 + (y1 - y0) * (i - 1.15) / count, 6 + i * 1.3, i * 1.7)
        out = out .. path(Svg.poly(pts) .. string.format(" L%s %s L%s %sZ", n(x1), n(y1), n(x0), n(y1)), k["band" .. i])
            .. line(Svg.poly(pts), mix(k["band" .. i], k["band" .. (i - 1)], .5), 1.4)
    end
    return out
end

-- Far rolling hills along the horizon at y1, in two rows.
local function hills(k, x0, x1, y1)
    local out = ""
    for row, h in ipairs({ { 50, 210, .4, k.hills2 }, { 30, 150, 2.1, k.hills } }) do
        local pts = {}
        for x = x0, x1 + 20, 20 do
            local u = (math.min(x, x1) - x0) / h[2]
            pts[#pts + 1] = { math.min(x, x1), y1 - h[1] - 12 * math.sin(u * 2.4 + h[3]) - 7 * math.sin(u * 5.2 + row) }
        end
        out = out .. path(Svg.poly(pts) .. string.format(" L%s %s L%s %sZ", n(x1), n(y1), n(x0), n(y1)), h[4]) .. line(Svg.poly(pts), mix(h[4], k.ink, .3), 1.2)
    end
    return out
end

-- The top of the sky as a shallow arch with an outline and a fine line inside it.
local function top(k, x0, y0, x1)
    local mid = (x0 + x1) / 2
    local function arch(d)
        return string.format("M%s %s Q%s %s %s %s Q%s %s %s %s", n(x0), n(y0 + 24 + d), n((x0 + mid) / 2), n(y0 + 6 + d), n(mid), n(y0 + 6 + d), n((mid + x1) / 2), n(y0 + 6 + d), n(x1), n(y0 + 24 + d))
    end
    return path(arch(0) .. string.format(" L%s %s L%s %sZ", n(x1), n(y0 + 26), n(x0), n(y0 + 26)), k.band1) .. line(arch(0), k.ink, 1.8) .. line(arch(6), mix(k.band1, k.ink, .35), .9)
end

-- The sun or moon, clouds, stars (hidden under a bank of cloud) and birds of a phase, placed round the arch whose foot is (ax, base).
local function bodies(k, phase, x0, y0, x1, ax, base)
    if phase == "night" then
        return (k.bank and "" or Svg.group(x0, y0 + 28, 0, Bodies.stars(k, x1 - x0, base - y0 - 64, { x = ax + 62 - x0, y = base - 252 - y0, r = 60 })))
            .. Bodies.wisp(k, ax - 260, base - 290, 150) .. Bodies.wisp(k, ax + 150, base - 300, 170) .. Bodies.wisp(k, ax - 120, base - 120, 96, k.shade)
            .. Bodies.moon(k, ax + 62, base - 224, 24)
    elseif phase == "golden" then
        return Bodies.lowsun(k, ax + 80, base - 160, 30) .. Bodies.cloud(k, ax - 252, base - 222, 118, true) .. Bodies.cloud(k, ax + 172, base - 268, 128)
            .. Bodies.birds(k, ax - 196, base - 300, 14)
    elseif phase == "morning" then
        return Bodies.sun(k, ax + 58, base - 172, 20) .. Bodies.wisp(k, ax - 262, base - 250, 150) .. Bodies.wisp(k, ax + 150, base - 296, 170)
            .. Bodies.cloud(k, ax - 150, base - 70, 80, true)
    end
    return Bodies.sun(k, ax + 64, base - 232, 24) .. Bodies.cloud(k, ax - 252, base - 222, 118) .. Bodies.cloud(k, ax + 172, base - 268, 128)
        .. Bodies.cloud(k, ax - 150, base - 70, 80, true)
end

-- The whole sky from (x0, y0) to (x1, base) for the phase and weather in `mode`, faded when it has "wash".
function GardenSky.draw(c, mode, x0, y0, x1, base, ax)
    local phase = Light.phase(mode) or "day"
    local weather = GardenWeather.of(mode)
    local k = GardenWeather.sky(colours(c, phase), weather, phase)
    if tostring(mode or ""):find("wash") then k = Wash.palette(k, c.bg) end
    return bands(k, x0, y0, x1, base + 8) .. bodies(k, phase, x0, y0, x1, ax, base) .. GardenWeather.cover(k, weather, x0, y0 + 20, x1) .. hills(k, x0, x1, base + 8) .. top(k, x0, y0, x1)
end

return GardenSky
