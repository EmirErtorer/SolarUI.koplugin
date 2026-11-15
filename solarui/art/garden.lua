-- The garden's ground and scenery, painted once as one backdrop: a green
-- lawn bristling with blades of grass, a clipped hedge with a gateway under
-- the trellis arch, the pond, the table and the small furniture
-- of garden_props, in the colours of the season and under the weather of
-- garden_weather. garden_ground(c, vw, vh, mode) takes the canvas size
-- (units of the poster, vh as tall as the screen asks) and a mode of colon
-- parted tokens: the sky phase, the weather, the season and "wash" for the
-- faded copy. The places come from garden/layout.lua, so the plants and
-- animals stand on it without overlap. Also here: the tuft an animal hides
-- in, the nest one sleeps in through the winter and the arch a picture is
-- shown in.

local Flora = require("solarui/art/flora")
local GardenSky = require("solarui/art/garden_sky")
local Decor = require("solarui/art/garden_decor")
local GardenWeather = require("solarui/art/garden_weather")
local Kit = require("solarui/art/plantkit")
local Layout = require("solarui/garden/layout")
local PlantSeason = require("solarui/art/plantseason")
local Props = require("solarui/art/garden_props")
local Svg = require("solarui/art/svg")
local Trellis = require("solarui/art/trellis")
local Wash = require("solarui/art/wash")

local n, group, line, path = Svg.n, Svg.group, Svg.line, Svg.path

local Garden = {}

-- The box of a plant or prop on a canvas `vh` tall.
local function box(id, vh)
    return Layout.at(Layout.PLANTS[id] or Layout.PROPS[id], vh)
end

-- A tuft of grass with its foot at (x, y), `s` tall.
local function tuft(c, x, y, s)
    local blades = {}
    for i, lean in ipairs({ -.62, -.24, .08, .36, .7 }) do
        local h = s * (.62 + .38 * Svg.vary(i, x))
        blades[#blades + 1] = string.format("M%s %s Q%s %s %s %s", n(x + (i - 3) * s * .1), n(y), n(x + (i - 3) * s * .1 + lean * s * .1), n(y - h * .6), n(x + (i - 3) * s * .1 + lean * s * .56), n(y - h))
    end
    return line(table.concat(blades, " "), c.stem, 1.8)
end

-- A stretch of clipped hedge from x0 to x1 standing on `base`, its top in
-- scallops and small leaves marked on it.
local function hedge(c, x0, x1, base, snow)
    local d, marks, caps = { string.format("M%s %s L%s %s", n(x0), n(base), n(x0), n(base - 44)) }, {}, {}
    local count = math.floor((x1 - x0) / 54 + .5)
    local step = (x1 - x0) / count
    for i = 1, count do
        local x = x0 + (i - 1) * step
        local peak = base - 74 - 8 * Svg.vary(i, x0)
        d[#d + 1] = string.format("Q%s %s %s %s", n(x + step / 2), n(peak), n(x + step), n(base - 44))
        if snow then caps[#caps + 1] = GardenWeather.cap(c, x, base - 44, step, (peak + base - 44) / 2) end
        for k = 1, 3 do
            local mx, my = x + step * (.2 + .3 * k - .15 * (i % 2)), base - 14 - 14 * ((k + i) % 3)
            if mx + 12 < x1 then marks[#marks + 1] = string.format("M%s %s q3 -5 7 -1 M%s %s q-1 -5 4 -6", n(mx), n(my), n(mx + 6), n(my - 1)) end
        end
    end
    d[#d + 1] = string.format("L%s %sZ", n(x1), n(base))
    return path(table.concat(d, " "), c.sage, c.ink, 1.8) .. line(table.concat(marks, " "), c.ink, .8) .. table.concat(caps)
end

-- The lawn: a green ground under the hedge with its top edge running along
-- the hedge's foot, then blades of grass over it, three to a tuft, all of
-- similar height and leaning this way and that, and what the season and
-- the weather leave on it.
local function lawn(c, floor, top, season, weather, x0, x1, extra)
    -- in winter the lawn lies under snow, only the tips of the grass showing through
    local winter = season == "winter"
    local fill = winter and Wash.mix(GardenWeather.snow(), c.sky, .22) or Wash.mix(c.sage, c.bg, .5)
    local ground = path(string.format("M%s %s C%s %s %s %s %s %s L%s %s L%s %s Z", n(x0), n(top), n(x0 + (x1 - x0) * .26), n(top - 5), n(x0 + (x1 - x0) * .7),
        n(top + 5), n(x1), n(top), n(x1), n(floor), n(x0), n(floor)), fill)
    local dark, light = {}, {}
    local function blade(set, x, y, h, lean, w)
        set[#set + 1] = string.format("M%s %s Q%s %s %s %sQ%s %s %s %sZ", n(x - w), n(y), n(x - w + lean * .2), n(y - h * .6), n(x + lean), n(y - h),
            n(x + w + lean * .3), n(y - h * .5), n(x + w), n(y))
    end
    for gy = 0, math.floor((floor - top - 20) / 34) do
        for gx = 0, math.floor((x1 - x0 - 24) / 34) do
            local x, y = x0 + 12 + gx * 34 + 22 * Svg.vary(gx, gy), top + 30 + gy * 34 + 18 * Svg.vary(gy, gx + 5)
            if y < floor - 4 and (not winter or (gx * 3 + gy) % 3 == 0) then
                for k = -1, 1 do
                    local v = Svg.vary(gx * 7 + k, gy)
                    blade((gx + gy + k) % 3 == 0 and light or dark, x + k * 4, y, (12 + 11 * v) * (winter and .5 or 1), (k * 5 + 8 * (v - .5)) * (winter and .6 or 1), 1.7)
                end
            end
        end
    end
    -- in winter snow lies on the lawn every day, deeper when snow is falling
    local drifts = weather == "snow" and 70 or (season == "winter" and 44 or 0)
    return ground .. GardenWeather.lawn(c, season, x0, x1, top, floor) .. path(table.concat(dark, " "), c.leaf) .. path(table.concat(light, " "), c.sage)
        .. (extra or "") .. (drifts > 0 and GardenWeather.drifts(c, x0, x1, top, floor, drifts) or "")
end

-- A nest of fallen leaves `s` large on the ground at (m, base) where an
-- animal sleeps through the winter: curled round with the tail wrapped
-- under the chin and the eyes shut, a breath rising.
local function nest(c, m, base, s)
    local leaves = { Wash.mix(c.gold, c.muted, .35), Wash.mix(c.bloom, c.muted, .3), Wash.mix(c.muted, c.pale, .4), c.gold }
    local fur, light, out = Wash.mix(c.muted, c.bloom, .28), Wash.mix(c.muted, c.pale, .45), ""
    for i, a in ipairs({ -176, -158, -140, -40, -22, -4 }) do
        out = out .. Flora.leaf(c, m + (i < 4 and -s * .1 or s * .1), base - s * .1, a, s * (.4 + .1 * Svg.vary(i, 3)), s * .1, leaves[i % 4 + 1], true)
    end
    local bx, by, hx, hy = m + s * .06, base - s * .28, m - s * .26, base - s * .26
    local tail = Svg.spline({ { bx + s * .38, by + s * .02 }, { bx + s * .3, by + s * .2 }, { bx - s * .02, by + s * .24 }, { hx + s * .02, hy + s * .16 }, { hx - s * .16, hy + s * .12 } }, 6)
    out = out .. Svg.ellipse(bx, by, s * .4, s * .24, -4, fur, c.ink, 1.5)
        .. line(string.format("M%s %s q%s %s %s %s M%s %s q%s %s %s %s", n(bx - s * .06), n(by - s * .14), n(s * .1), n(-s * .06), n(s * .2), n(-s * .02), n(bx + s * .04), n(by - s * .04), n(s * .1), n(-s * .05), n(s * .18), n(0)), c.ink, 1)
        .. path(string.format("M%s %s q%s %s %s %s", n(hx + s * .04), n(hy - s * .15), n(s * .02), n(-s * .1), n(s * .1), n(-s * .08)), fur, c.ink, 1.2)
        .. Svg.circle(hx, hy, s * .17, fur, c.ink, 1.4)
        .. line(string.format("M%s %s q%s %s %s 0 M%s %s q%s %s %s 0", n(hx - s * .1), n(hy - s * .02), n(s * .04), n(s * .045), n(s * .08), n(hx + s * .01), n(hy - s * .03), n(s * .04), n(s * .045), n(s * .08)), c.ink, 1.1)
        .. Svg.stem(tail, Svg.swell(s * .13, s * .03), light, c.ink, 1.3) .. Svg.circle(hx - s * .15, hy + s * .03, s * .025, c.ink)
    for i, a in ipairs({ 176, 190, 6, -8, 184 }) do
        out = out .. Flora.leaf(c, m + (i - 3) * s * .17, base - s * .03, a, s * (.28 + .08 * Svg.vary(i, 5)), s * .08, leaves[(i + 1) % 4 + 1], true)
    end
    return out .. Svg.circle(hx - s * .1, hy - s * .28, s * .03, nil, c.ink, .9) .. Svg.circle(hx - s * .17, hy - s * .4, s * .045, nil, c.ink, .9)
end

-- A clump of leaves and grass where an animal is hiding, eyes showing,
-- or with ":sleep" in the param a nest where an animal sleeps for the winter.
function Garden.garden_tuft(c, vw, vh, param)
    c = Wash.apply(c, param)
    local m, s = vw / 2, math.min(vw * .5, vh * .9)
    if tostring(param or ""):find("sleep") then return nest(c, m, vh - 2, math.min(vw * .66, vh * 1.05)) end
    local out = tuft(c, m - s * .5, vh - 2, s * .5)
    for i, a in ipairs({ -52, 46, -24, 22, -2 }) do
        out = out .. Kit.blade({ c = c }, m + a * s * .002, vh - 2, a, s * (i < 3 and .72 or .92), s * .2, a * .5, i % 2 == 0 and c.leaf or c.sage)
    end
    return out .. tuft(c, m + s * .5, vh - 2, s * .42) .. Svg.circle(m - s * .08, vh - s * .2, s * .05, c.ink) .. Svg.circle(m + s * .1, vh - s * .2, s * .05, c.ink)
        .. Svg.circle(m - s * .07, vh - s * .21, s * .015, c.cream) .. Svg.circle(m + s * .11, vh - s * .21, s * .015, c.cream)
end

-- The arch the picture of a tapped plant or animal stands in: a round-headed
-- frame with a bud at its crown and a curl of leaves in each upper corner.
function Garden.garden_arch(c, vw, vh)
    local r = vw / 2
    -- the arch `d` units in from the canvas edge
    local function arch(d)
        return string.format("M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s", n(d), n(vh), n(d), n(r), n(r - d), n(r - d), n(vw - d), n(r), n(vw - d), n(vh))
    end
    local corner = line(Svg.poly(Svg.join({ { 12, 96 }, { 18, 70 } }, Svg.spiral(40, 44, 26, 1.5, 250))), c.ink, 2.4) .. Flora.leaf(c, 16, 80, -62, 44, 12, c.leaf)
        .. Flora.leaf(c, 60, 28, -8, 40, 11, c.sage)
    return corner .. group(vw, 0, 0, corner, -1, 1) .. path(arch(12) .. "Z", c.bg, c.ink, 3.2) .. line(arch(26), c.line, 1.4)
        .. Flora.leaf(c, r, 14, -164, 34, 9, c.leaf, true) .. Flora.leaf(c, r, 14, -16, 34, 9, c.leaf, true) .. Flora.rosebud(c, r, 20, 0, 13)
end

-- The speech bubble under a companion's arch: a rounded panel with a small
-- tail pointing up at the arch and a sprig of leaves in the lower corner.
function Garden.garden_bubble(c, vw, vh)
    local r, t, tx = 18, 10, 52
    local function panel(d)
        return string.format("M%s %s L%s %s L%s %s L%s %s L%s %s Q%s %s %s %s L%s %s Q%s %s %s %s L%s %s Q%s %s %s %s L%s %s Q%s %s %s %s Z",
            n(r + d), n(t + d), n(tx - 9), n(t + d), n(tx), n(d), n(tx + 11), n(t + d), n(vw - r - d), n(t + d),
            n(vw - d), n(t + d), n(vw - d), n(t + r + d), n(vw - d), n(vh - r - d), n(vw - d), n(vh - d), n(vw - r - d), n(vh - d),
            n(r + d), n(vh - d), n(d), n(vh - d), n(d), n(vh - r - d), n(d), n(t + r + d), n(d), n(t + d), n(r + d), n(t + d))
    end
    return path(panel(3), c.bg, c.ink, 2.6) .. line(panel(9), c.line, 1.2)
        .. Flora.leaf(c, vw - 13, vh - 9, -168, 20, 6, c.leaf) .. Flora.leaf(c, vw - 13, vh - 9, -122, 17, 5, c.sage)
end

-- The badge that says the companion has something to tell: a gold bud-round
-- with three dots of speech and a leaf.
function Garden.garden_badge(c, vw, vh)
    local r = math.min(vw, vh) / 2 - 3
    local m, mid = vw / 2, vh / 2
    return Svg.circle(m, mid, r, c.gold, c.ink, 2.4) .. Svg.circle(m - r * .45, mid, r * .15, c.ink) .. Svg.circle(m, mid, r * .15, c.ink)
        .. Svg.circle(m + r * .45, mid, r * .15, c.ink) .. Flora.leaf(c, m + r * .55, mid - r * .8, -50, r * .8, r * .3, c.leaf)
end

-- The chip on home for the week's things outdoors: a low rounded panel with
-- a sprig at the left and three round pips at the right, filled for each
-- thing done (`param` is three flags, "101"). With all three done the sprig
-- opens a gold flower.
function Garden.garden_chip(c, vw, vh, param)
    local r = 18
    local function panel(d)
        return string.format("M%s %s L%s %s Q%s %s %s %s L%s %s Q%s %s %s %s L%s %s Q%s %s %s %s L%s %s Q%s %s %s %s Z",
            n(r + d), n(d), n(vw - r - d), n(d), n(vw - d), n(d), n(vw - d), n(r + d), n(vw - d), n(vh - r - d), n(vw - d), n(vh - d), n(vw - r - d), n(vh - d),
            n(r + d), n(vh - d), n(d), n(vh - d), n(d), n(vh - r - d), n(d), n(r + d), n(d), n(d), n(r + d), n(d))
    end
    local flags = tostring(param or "000")
    local out = path(panel(3), c.bg, c.ink, 2.6) .. line(panel(9), c.line, 1.2)
    -- the sprig: a stem, two leaves and a bud (a gold flower when the week is done)
    local cy = vh / 2
    out = out .. line(string.format("M30 %s Q31 %s 30 %s", n(cy + 20), n(cy + 4), n(cy - 10)), c.ink, 2.4)
        .. Flora.leaf(c, 30, cy + 8, -48, 22, 7, c.leaf) .. Flora.leaf(c, 30, cy + 8, -132, 22, 7, c.sage)
    if flags == "111" then
        for i = 0, 5 do
            local a = math.rad(i * 60)
            out = out .. Svg.circle(30 + math.cos(a) * 8, cy - 14 + math.sin(a) * 8, 5.2, c.gold, c.ink, 1.4)
        end
        out = out .. Svg.circle(30, cy - 14, 4.2, c.rose or c.leaf, c.ink, 1.2)
    else
        out = out .. Flora.rosebud(c, 30, cy - 12, 0, 11)
    end
    -- the pips
    for k = 1, 3 do
        local cx = vw - 26 - (3 - k) * 26
        local done = flags:sub(k, k) == "1"
        out = out .. Svg.circle(cx, 25, 9.5, done and c.leaf or c.bg, c.ink, 2.2)
        if done then out = out .. line(string.format("M%s 25.5 L%s 29.5 L%s 20.5", n(cx - 4.2), n(cx - 1), n(cx + 4.6)), c.bg, 2.2) end
    end
    return out
end

-- The whole backdrop for a canvas vw x vh.
function Garden.garden_ground(c, vw, vh, mode)
    local ivy, pond, tab = box("ivy", vh), box("pond", vh), box("table", vh)
    local base = ivy.y + ivy.h
    -- the lawn reaches the borders: things keep their size and stand further apart
    -- (the screen says how far in the border is, in the mode as "edge<units>")
    local edge = tonumber(tostring(mode or ""):match("edge([%d%.]+)")) or Layout.EDGE
    local fan = Layout.fan(vw, edge)
    local x0, x1 = edge, vw - edge
    local function moved(b) return { x = fan.at(b.x + b.w / 2) - b.w / 2, y = b.y, w = b.w, h = b.h } end
    local arch = fan.at(ivy.x + ivy.w / 2)
    pond, tab = moved(pond), moved(tab)
    local sky = GardenSky.draw(c, mode, x0, Layout.SKY.y, x1, base, arch)
    local season, weather = PlantSeason.of(mode), GardenWeather.of(mode)
    c = Wash.apply(GardenWeather.palette(PlantSeason.palette(c, season), weather, season), mode)
    -- snow lies all winter, not only on the days it falls
    local snow = weather == "snow" or season == "winter"
    -- the stepping stones and the lawn's flowers, in the poster's units moved onto this canvas
    local k = Layout.stretch(vh)
    local function place(x, y) return fan.at(x), y * k end
    local standing = Layout.static(Layout.HEIGHT)
    standing.pond = Layout.PROPS.pond
    local function free(x, y)
        for _id, b in pairs(standing) do
            if x > b.x - 8 and x < b.x + b.w + 8 and y > b.y - 4 and y < b.y + b.h + 6 then return false end
        end
        return true
    end
    local ground = Decor.path(c, place, snow) .. Decor.flowers(c, season, free, place, Layout.LAWN_TOP, Layout.HEIGHT - edge)
        .. (season == "winter" and Decor.tracks(c, place) or "")
    local out = sky .. lawn(c, vh - edge, base, season, weather, x0, x1, ground) .. hedge(c, x0, arch - ivy.w / 2 + 46, base, snow)
        .. hedge(c, arch + ivy.w / 2 - 46, x1, base, snow) .. group(arch, base, 0, Trellis.frame(c))
    if weather == "mist" then out = out .. GardenWeather.mist(c, x0, x1, base) end
    out = out .. group(pond.x, pond.y, 0, Props.pond(c, pond.w, pond.h, season == "winter")) .. (snow and GardenWeather.rim(c, pond) or "")
        .. group(tab.x, tab.y, 0, Props.table(c, snow), tab.w / Layout.TABLE_ART.w, tab.h / Layout.TABLE_ART.h)
    -- the small things, the far ones first so the near ones stand in front
    local order = {}
    for id in pairs(Layout.EXTRAS) do order[#order + 1] = id end
    table.sort(order, function(a, b) return Layout.EXTRAS[a].y + Layout.EXTRAS[a].h < Layout.EXTRAS[b].y + Layout.EXTRAS[b].h end)
    for _i, id in ipairs(order) do
        local at, small = moved(Layout.at(Layout.EXTRAS[id], vh)), Props.small(id)
        out = out .. group(at.x, at.y, 0, small.draw(c, snow), at.w / small.w, at.h / small.h)
    end
    return out .. GardenWeather.fall(c, weather, x0, x1, Layout.SKY.y + 30, vh - edge - 4)
end

return Garden
