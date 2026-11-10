-- The drawings of home's reading strip: today as a sunflower, the last seven
-- days as a row of the weekdays' own flowers, the year as a water lily. Each
-- is function(c, vw, vh, param) returning SVG for a vw x vh canvas.

local DayFlowers = require("solarui/art/dayflowers")
local Flora = require("solarui/art/flora")
local Insects = require("solarui/art/insects")
local Svg = require("solarui/art/svg")

local n, vary = Svg.n, Svg.vary

local Reading = {}

-- How many petals the sunflower has; one more than that as `filled` means
-- the day's goal is reached.
Reading.PETALS = 20

-- Today's reading: a sunflower with `filled` of its petals golden, and a
-- ring of golden seeds round it once the goal is reached.
function Reading.sunflower(c, vw, vh, filled)
    filled = tonumber(filled) or 0
    local rd, pl = vw * .19, vw * .25
    local glow = filled > Reading.PETALS and Svg.dots(vw / 2, vh / 2, rd + pl * 1.02, 20, vw * .045, c.gold) or ""
    return glow .. Flora.sunflower(c, vw / 2, vh / 2, rd, pl, Reading.PETALS, filled)
end

-- Where the seven days stand on the week's runner: { {x, y}, ... }.
function Reading.weekSpots(vw, vh)
    local spots = {}
    for i = 1, 7 do
        spots[i] = { vw * (i - .5) / 7, vh * (.83 + .04 * (vary(i, 21) - .5)) }
    end
    return spots
end

-- One day's plant growing from (x, y): its flower open on a tall stalk with
-- a leaf when the day was read, a closed bud on a short sprout when not.
local function dayPlant(c, wday, x, y, vh, r, read)
    local lean = (vary(wday, 22) - .5) * r * .9
    local hx = x + lean
    local hy = read and vh * (.3 + .1 * vary(wday, 23)) or vh * (.6 + .06 * vary(wday, 24))
    local side = wday % 2 == 0 and 1 or -1
    local stalk = Svg.line(string.format("M%s %s Q%s %s %s %s", n(x), n(y), n(x - lean), n((y + hy) / 2), n(hx), n(hy)), c.stem, 3)
    if not read then
        return stalk .. Flora.leaf(c, x, y - 2, side > 0 and -40 or -140, r * .5, r * .16, c.sage, true) .. DayFlowers.bud(c, wday, hx, hy, r)
    end
    local ly = y - (y - hy) * (.3 + .2 * vary(wday, 25))
    return stalk .. Flora.leaf(c, x - lean * .4, ly, side > 0 and -34 or -146, r * (.8 + .3 * vary(wday, 26)), r * .28, nil, true)
        .. Flora.leaf(c, x, y - 2, side > 0 and -150 or -30, r * .55, r * .18, c.sage, true)
        .. DayFlowers.bloom(c, wday, hx, hy, r)
end

-- The week: `days` is seven characters, oldest first, "1" for a day read,
-- then "|" and the weekday (1 is Sunday) of the first of them.
function Reading.week(c, vw, vh, days)
    local marks, first = tostring(days or ""):match("^([01]*)|?(%d*)$")
    marks, first = marks or "", tonumber(first) or 2
    local spots = Reading.weekSpots(vw, vh)
    local r = math.min(vw / 7 * .42, vh * .2)
    local way, out = { { 3, vh * .87 } }, {}
    for i, s in ipairs(spots) do
        way[#way + 1] = s
        out[i] = dayPlant(c, (first + i - 2) % 7 + 1, s[1], s[2], vh, r, marks:sub(i, i) == "1")
    end
    way[#way + 1] = { vw - 3, vh * .8 }
    return Svg.stem(Svg.spline(way, 8), Svg.swell(6, 2), c.leaf, c.ink, 1.4) .. table.concat(out)
end

-- The year: a water lily on its pad with a petal for each book, up to
-- sixteen; books beyond that open a second, smaller lily beside it.
function Reading.lily(c, vw, vh, books)
    books = math.max(0, math.min(28, tonumber(books) or 0))
    local pad = Flora.lilypad(c, vw * .53, vh * .55, vw * .4, 118)
    -- a ladybird walking on the pad's edge
    local bx, by = Svg.pol(vw * .31, 232, vw * .53, vh * .55)
    local bug = Insects.ladybug(c, bx, by, 232 - 90 + 180, vw * .06)
    if books == 0 then
        return pad .. Flora.rosebud(c, vw * .47, vh * .6, 0, vw * .1, c.cream) .. bug
    end
    local first = math.min(16, books)
    local outer = math.max(1, math.ceil(first * .6))
    local out = pad .. Flora.lily(c, vw * .47, vh * .49, vw * .24, outer, first - outer)
    if books > 16 then
        local more = books - 16
        out = out .. Flora.lily(c, vw * .8, vh * .78, vw * .13, math.max(3, math.ceil(more * .6)), math.floor(more * .4))
    end
    return out .. bug
end

return Reading
