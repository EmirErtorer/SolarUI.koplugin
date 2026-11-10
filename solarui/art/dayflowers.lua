-- The seven flowers of the week, one for each weekday, each in bloom and as
-- a closed bud: Sunday a bellflower, Monday a rose, Tuesday a tulip,
-- Wednesday a daisy, Thursday an iris, Friday a poppy, Saturday a lily.
-- Each is function(c, r) returning SVG round the origin, the head `r` in
-- radius, its stalk arriving from below.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n, group, petal, around = Svg.n, Svg.group, Flora.petal, Flora.around

local DayFlowers = {}

-- A small green cup under a bud, at (x, y).
local function cup(c, x, y, r)
    return Svg.ellipse(x, y, r * .2, r * .14, 0, c.leaf, c.ink, 1.2)
end

-- Sunday's bellflower: a nodding bell with a scalloped rim.
local function bell(c, r)
    local d = string.format("M0 %s C%s %s %s %s %s %s L%s %s L%s %s L0 %s L%s %s L%s %s L%s %s C%s %s %s %s 0 %sZ",
        n(-r * .85), n(r * .75), n(-r * .85), n(r * .5), n(r * .15), n(r), n(r * .7),
        n(r * .55), n(r * .5), n(r * .28), n(r * .85), n(r * .55), n(-r * .28), n(r * .85), n(-r * .55), n(r * .5), n(-r), n(r * .7),
        n(-r * .5), n(r * .15), n(-r * .75), n(-r * .85), n(-r * .85))
    return Svg.path(d, c.glass, c.ink, 1.7)
        .. Svg.line(string.format("M0 %s L0 %s", n(-r * .5), n(r * .3)), c.ink, 1)
        .. Svg.circle(0, r * .82, r * .15, c.gold, c.ink, 1.2)
        .. Svg.ellipse(0, -r * .84, r * .3, r * .16, 0, c.leaf, c.ink, 1.3)
end

-- Monday's rose.
local function rose(c, r)
    return Flora.rose(c, 0, 0, r, 15)
end

-- Tuesday's tulip, golden.
local function tulip(c, r)
    return Flora.tulip(c, 0, r * .8, 0, r * 1.2, c.gold)
end

-- Wednesday's daisy.
local function daisy(c, r)
    return Flora.daisy(c, 0, 0, r * 1.05, 11, c.cream)
end

-- Thursday's iris: three petals standing, three falling with a golden streak.
local function iris(c, r)
    local fall = petal(c, r, r * .4, c.sky) .. Svg.line(string.format("M0 %s L0 %s", n(-r * .18), n(-r * .62)), c.gold, 2.4)
    local side = petal(c, r * .92, r * .3, c.glass)
    return group(0, r * .1, 118, fall) .. group(0, r * .1, -118, fall) .. group(0, r * .1, 180, petal(c, r * .8, r * .34, c.sky))
        .. group(0, r * .1, 32, side) .. group(0, r * .1, -32, side) .. group(0, r * .1, 0, petal(c, r * 1.15, r * .36, c.sky))
end

-- Friday's poppy: broad red petals round a dark heart.
local function poppy(c, r)
    return around(0, 0, 0, 4, petal(c, r * 1.08, r * .72, c.bloom2), 45)
        .. around(0, 0, 0, 4, petal(c, r, r * .7, c.bloom))
        .. Svg.circle(0, 0, r * .32, c.ink) .. Svg.dots(0, 0, r * .18, 6, r * .1, c.gold)
end

-- Saturday's lily: a pink star with long stamens.
local function lily(c, r)
    local stamens = {}
    for i = 0, 5 do
        local x, y = Svg.pol(r * .5, i * 60 + 30)
        stamens[#stamens + 1] = Svg.line(string.format("M0 0 L%s %s", n(x), n(y)), c.ink, 1) .. Svg.circle(x, y, r * .09, c.gold, c.ink, .9)
    end
    return around(0, 0, 0, 6, petal(c, r * 1.12, r * .3, c.bloom2) .. Svg.line(string.format("M0 %s L0 %s", n(-r * .2), n(-r * .85)), c.ink, .9))
        .. table.concat(stamens) .. Svg.circle(0, 0, r * .13, c.leaf, c.ink, 1)
end

-- The closed buds, in the same order: small and pale, each with the outline
-- of its flower.
local function bellBud(c, r)
    return Svg.line(string.format("M0 %s Q%s %s %s %s", n(r * .3), n(r * .05), n(-r * .25), n(r * .3), n(-r * .1)), c.stem, 2.4)
        .. Svg.ellipse(r * .32, r * .16, r * .2, r * .3, -12, c.cream, c.ink, 1.5) .. cup(c, r * .3, -r * .1, r)
end
local function roseBud(c, r)
    return Flora.rosebud(c, 0, r * .3, 0, r * .42, c.cream)
end
local function tulipBud(c, r)
    return Flora.tulip(c, 0, r * .3, 0, r * .5, c.cream)
end
local function daisyBud(c, r)
    return Svg.ellipse(0, -r * .08, r * .24, r * .34, 0, c.cream, c.ink, 1.5)
        .. Svg.line(string.format("M0 %s L0 %s", n(-r * .38), n(r * .1)), c.ink, .9) .. cup(c, 0, r * .26, r * 1.4)
end
local function irisBud(c, r)
    return petal(c, r * .95, r * .15, c.cream) .. group(0, r * .3, 0, petal(c, r * .6, r * .17, c.leaf, 1.3))
end
local function poppyBud(c, r)
    return Svg.line(string.format("M0 %s Q%s %s %s %s", n(r * .3), n(-r * .05), n(-r * .4), n(r * .3), n(-r * .2)), c.stem, 2.4)
        .. Svg.ellipse(r * .36, r * .06, r * .22, r * .32, 14, c.sage, c.ink, 1.5)
end
local function lilyBud(c, r)
    return group(0, r * .3, 16, petal(c, r * .95, r * .2, c.cream) .. petal(c, r * .4, r * .16, c.leaf, 1.3))
end

-- By weekday as os.date numbers them (1 is Sunday).
local BLOOMS = { bell, rose, tulip, daisy, iris, poppy, lily }
local BUDS = { bellBud, roseBud, tulipBud, daisyBud, irisBud, poppyBud, lilyBud }

-- Weekday `wday`'s flower in bloom at (x, y), `r` in radius.
function DayFlowers.bloom(c, wday, x, y, r)
    return group(x, y, 0, BLOOMS[wday](c, r))
end

-- Weekday `wday`'s flower still closed, at the head of its stalk at (x, y).
function DayFlowers.bud(c, wday, x, y, r)
    return group(x, y - r * .3, 0, BUDS[wday](c, r))
end

return DayFlowers
