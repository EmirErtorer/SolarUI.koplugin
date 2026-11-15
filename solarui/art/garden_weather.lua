-- The garden's weather and the season on its ground, for garden.lua and
-- garden_sky.lua. The ground's mode names the weather ("rain", "snow",
-- "cloudy" or "mist"; none when it is clear) and the season. Cloud dims the
-- sky and draws a bank of cloud over the sun; rain adds fine slanting ink
-- streaks over the garden and a grey-blue haze on its colours; snow dusts the
-- lawn, caps the hedge and the pond's rim and falls in flakes; mist lies in
-- pale bands over the lawn and the foot of the hedge. In autumn leaves lie
-- on the lawn and in winter frost flecks it. Nothing is see-through: every
-- haze is a colour mixed with another.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Bodies = require("solarui/art/sky_bodies")
local Light = require("solarui/art/light")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle
local mix, P, vary = Wash.mix, Light.paint, Svg.vary

local Weather = {}

local KINDS = { rain = true, snow = true, cloudy = true, mist = true }

-- The colours weather moves things towards, as seen.
local GREY = { day = "#B9C0C8", night = "#2A3044", rain = "#8E9DAE", snow = "#FFFFFF", mist = "#E9E6DC" }

-- The weather named in `mode`, or nil when it is clear.
function Weather.of(mode)
    for token in tostring(mode or ""):gmatch("[^:]+") do
        if KINDS[token] then return token end
    end
    return nil
end

-- The ground's palette `c` under the weather: grey-blue in the rain, the
-- greens whitened under snow (and a little on any winter day, when old snow
-- lies), or as it is.
function Weather.palette(c, weather, season)
    if weather ~= "rain" and weather ~= "snow" then
        if season ~= "winter" then return c end
        local out = {}
        for role, hex in pairs(c) do out[role] = hex end
        out.sage, out.leaf = mix(c.sage, P(GREY.snow), .2), mix(c.leaf, P(GREY.snow), .1)
        return out
    end
    local out = {}
    for role, hex in pairs(c) do out[role] = hex end
    if weather == "rain" then
        for role, hex in pairs(c) do
            if role ~= "ink" and type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$") then out[role] = mix(hex, P(GREY.rain), .16) end
        end
    else
        out.sage, out.leaf = mix(c.sage, P(GREY.snow), .32), mix(c.leaf, P(GREY.snow), .18)
    end
    return out
end

-- The sky's colours `k` dimmed by the weather at the phase: bands, hills and
-- the sun moved towards the grey of a cloudy sky, or the pale of mist.
function Weather.sky(k, weather, phase)
    if not weather then return k end
    local grey = P(weather == "mist" and GREY.mist or (phase == "night" and GREY.night or (weather == "rain" and GREY.rain or GREY.day)))
    local much = ({ cloudy = .38, rain = .5, snow = .42, mist = .3 })[weather]
    local out = {}
    for key, hex in pairs(k) do out[key] = hex end
    for i = 1, 5 do out["band" .. i] = mix(k["band" .. i], grey, much * (.7 + i * .06)) end
    out.hills, out.hills2 = mix(k.hills, grey, much * (weather == "mist" and 1.6 or .8)), mix(k.hills2, grey, much * (weather == "mist" and 1.9 or .9))
    for _i, key in ipairs({ "sun", "glow", "ray", "halo", "moon", "beam" }) do
        if k[key] then out[key] = mix(k[key], grey, much) end
    end
    if weather ~= "mist" then
        out.cloud = mix(k.cloud, grey, .3)
        out.shade = mix(k.shade or k.cloud, grey, .45)
        out.bank = mix(out.band1, out.cloud, .5)
    end
    return out
end

-- The bank of cloud that covers the top of a cloudy, rainy or snowy sky
-- from x0 to x1 below y0: its underside hangs in soft bellies of uneven
-- width, edged in ink with a line of shadow inside and a few curls, and a
-- few lower clouds drift under it.
function Weather.cover(k, weather, x0, y0, x1)
    if not k.bank then return "" end
    local d, shade, curls = { string.format("M%s %s L%s %s", n(x0), n(y0), n(x0), n(y0 + 70)) }, {}, {}
    local x, prev, i = x0, y0 + 70, 0
    while x < x1 do
        i = i + 1
        local w = math.min(x1 - x, 64 + 70 * vary(i, 61))
        if x1 - x - w < 30 then w = x1 - x end
        local y = y0 + 62 + 22 * vary(i, 62)
        local belly = 16 + 18 * vary(i, 63)
        d[#d + 1] = string.format("Q%s %s %s %s", n(x + w / 2), n(math.max(prev, y) + belly), n(x + w), n(y))
        shade[#shade + 1] = string.format("M%s %s Q%s %s %s %s", n(x + w * .22), n(prev - 4), n(x + w / 2), n(math.max(prev, y) + belly - 12), n(x + w * .8), n(y - 3))
        if i % 3 == 1 and w > 70 then curls[#curls + 1] = Svg.poly(Svg.spiral(x + w * .5, y0 + 40 + 10 * vary(i, 64), 9, 1.2, 200, i % 2 == 0)) end
        x, prev = x + w, y
    end
    d[#d + 1] = string.format("L%s %sZ", n(x1), n(y0))
    local out = { path(table.concat(d, " "), k.bank, k.ink, 1.7), line(table.concat(shade, " "), k.shade, 1.5), line(table.concat(curls, " "), mix(k.bank, k.ink, .45), 1) }
    local low = weather == "cloudy" and 3 or 4
    for j = 1, low do
        local w = 70 + 40 * vary(j, 64)
        local cx = x0 + 20 + (x1 - x0 - w - 40) * (j - .5) / low + 24 * (vary(j, 65) - .5)
        out[#out + 1] = Bodies.cloud(k, cx, y0 + 168 + 36 * vary(j, 66), w, j % 2 == 0)
    end
    return table.concat(out)
end

-- Leaves fallen over the lawn in autumn, or flecks of frost on it in winter,
-- between `top` and `floor` and the lawn's sides x0 and x1.
function Weather.lawn(c, season, x0, x1, top, floor)
    local out = {}
    if season == "autumn" then
        local tones = { c.gold, mix(c.bloom, c.gold, .4), c.pale, mix(c.gold, c.muted, .35) }
        for i = 1, 46 do
            local x, y = x0 + 20 + (x1 - x0 - 40) * vary(i, 71), top + 30 + (floor - top - 50) * vary(i, 72)
            local rot = 360 * vary(i, 73)
            if i % 3 == 0 then out[#out + 1] = group(x, y, 0, Flora.ginkgo(c, 0, 0, rot, 24, tones[3], true), .5, .32)
            else out[#out + 1] = group(x, y, 0, Blooms.maple(c, 0, 0, rot, 34, tones[i % 4 + 1]), .42, .28) end
        end
    elseif season == "winter" then
        local frost, d = P("#F3F7F8"), {}
        for i = 1, 170 do
            local x, y = x0 + 10 + (x1 - x0 - 20) * vary(i, 74), top + 16 + (floor - top - 26) * vary(i, 75)
            local s = 2.4 + 2.6 * vary(i, 76)
            d[#d + 1] = string.format("M%s %s l%s 0 M%s %s l%s %s M%s %s l%s %s", n(x - s), n(y), n(s * 2), n(x - s * .5), n(y - s * .8), n(s), n(s * 1.6), n(x + s * .5), n(y - s * .8), n(-s), n(s * 1.6))
        end
        out[#out + 1] = line(table.concat(d, " "), frost, 1.5)
    end
    return table.concat(out)
end

-- The colour of snow, as seen.
function Weather.snow()
    return P(GREY.snow)
end

-- Snow lying in `count` drifts (70 by default) over the lawn, between `top` and `floor`.
function Weather.drifts(c, x0, x1, top, floor, count)
    local snow, edge, out = P(GREY.snow), mix(c.sky, c.ink, .25), {}
    for i = 1, count or 70 do
        local x, y = x0 + 30 + (x1 - x0 - 60) * vary(i, 81), top + 22 + (floor - top - 40) * vary(i, 82)
        local rx = 10 + 22 * vary(i, 83)
        out[#out + 1] = path(string.format("M%s %s Q%s %s %s %s Q%s %s %s %sZ", n(x - rx), n(y), n(x - rx * .3), n(y - rx * .3), n(x + rx), n(y), n(x), n(y + rx * .08), n(x - rx), n(y)), snow)
            .. line(string.format("M%s %s Q%s %s %s %s", n(x - rx * .7), n(y - rx * .08), n(x - rx * .2), n(y - rx * .3), n(x + rx * .5), n(y - rx * .06)), edge, .7)
    end
    return table.concat(out)
end

-- Snow on the top of a scallop of hedge from (x, y) to (x + step, y) rising to `peak`.
function Weather.cap(c, x, y, step, peak)
    local snow = P(GREY.snow)
    return path(string.format("M%s %s Q%s %s %s %s Q%s %s %s %sZ", n(x + step * .08), n(y - 4), n(x + step / 2), n(peak - 3), n(x + step * .92), n(y - 4), n(x + step / 2), n(peak + 14), n(x + step * .08), n(y - 4)), snow, mix(c.sky, c.ink, .4), .8)
end

-- Snow along the far rim of the pond in the box b.
function Weather.rim(c, b)
    local pts = {}
    for a = 186, 354, 8 do
        pts[#pts + 1] = { b.x + b.w / 2 + (b.w / 2 - 6) * math.cos(math.rad(a)), b.y + b.h / 2 + (b.h / 2 - 6) * math.sin(math.rad(a)) - 2 }
    end
    return path(Svg.ribbon(pts, Svg.swell(9, 1)), P(GREY.snow), mix(c.sky, c.ink, .4), .8)
end

-- Pale bands of mist lying over the foot of the hedge at `base` and low
-- over the lawn, from x0 to x1: each band laid in three tones from the
-- lawn's colour to the palest at its heart, so the edges melt.
function Weather.mist(c, x0, x1, base)
    local haze, lawn = mix(c.cream, c.sky, .14), mix(c.sage, c.bg, .5)
    local out = {}
    for i, b in ipairs({ { base - 12, 64, .3 }, { base + 100, 58, 1.7 } }) do
        for layer, f in ipairs({ { 1, .66 }, { .72, .38 }, { .44, .12 } }) do
            local top, bottom = {}, {}
            for x = x0, x1 + 24, 24 do
                local u = math.min(x, x1)
                local half = b[2] / 2 * f[1] * (.74 + .26 * math.sin(u / 110 + b[3] + layer * .7))
                local mid = b[1] - 9 * math.sin(u / 80 + b[3]) - 3 * math.sin(u / 27 + i)
                top[#top + 1] = { u, mid - half }
                bottom[#bottom + 1] = { u, mid + half * .8 }
            end
            local edge = {}
            for j = #bottom, 1, -1 do edge[#edge + 1] = bottom[j] end
            out[#out + 1] = path(Svg.poly(Svg.join(top, edge), true), mix(haze, i == 1 and mix(c.sage, c.sky, .4) or lawn, f[2]))
        end
    end
    return table.concat(out)
end

-- What falls over the whole garden from x0 to x1 and y0 to y1: fine
-- slanting streaks of rain, or flakes of snow.
function Weather.fall(c, weather, x0, x1, y0, y1)
    if weather == "rain" then
        local d, i = {}, 0
        for gy = y0 + 10, y1 - 30, 64 do
            for gx = x0 + 10, x1 - 20, 58 do
                i = i + 1
                local x, y = gx + 40 * vary(i, 91), gy + 40 * vary(i, 92)
                local L = 16 + 16 * vary(i, 93)
                if x + L * .3 < x1 - 6 and y + L < y1 then d[#d + 1] = string.format("M%s %s l%s %s", n(x), n(y), n(-L * .3), n(L)) end
            end
        end
        return line(table.concat(d, " "), mix(c.ink, c.sky, .45), 1.1)
    end
    if weather == "snow" then
        local snow, edge, out, i = P(GREY.snow), mix(c.sky, c.ink, .45), {}, 0
        for gy = y0 + 10, y1 - 20, 56 do
            for gx = x0 + 10, x1 - 16, 52 do
                i = i + 1
                local x, y = gx + 36 * vary(i, 94), gy + 36 * vary(i, 95)
                if x < x1 - 8 and y < y1 - 8 then out[#out + 1] = circle(x, y, 1.6 + 2 * vary(i, 96), snow, edge, .6) end
            end
        end
        return table.concat(out)
    end
    return ""
end

return Weather
