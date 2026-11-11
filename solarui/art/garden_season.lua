-- The season wheel, twice. garden_season_wheel is the big round the reader
-- picks a season on: four quarters, spring top right, summer bottom right,
-- autumn bottom left and winter top left, the season in the param (its name)
-- marked with a gold ring. garden_season_icon is the same round, small, for
-- the top bar's button, its quarter for the season in the param lit.

local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, path, circle = Svg.n, Svg.path, Svg.circle

local Seasons = {}

-- The quarter each season takes: where its wedge starts, in degrees from the top.
local QUARTER = { spring = 0, summer = 90, autumn = 180, winter = 270 }

-- The colour of a season's quarter.
local function tone(c, season)
    return ({ spring = c.leaf, summer = c.bloom, autumn = c.gold, winter = c.cream })[season]
end

-- A wedge of the round about (cx, cy) of radius r between two angles.
local function wedge(cx, cy, r, from, to, fill, stroke, sw)
    local x0, y0 = Svg.pol(r, from, cx, cy)
    local x1, y1 = Svg.pol(r, to, cx, cy)
    return path(string.format("M%s %s L%s %s A%s %s 0 0 1 %s %s Z", n(cx), n(cy), n(x0), n(y0), n(r), n(r), n(x1), n(y1)), fill, stroke, sw)
end

-- The round with its four quarters; `season` is lit.
local function round(c, size, season, sw)
    local mid, r = size / 2, size * .46
    local out = {}
    for _i, s in ipairs({ "spring", "summer", "autumn", "winter" }) do
        out[#out + 1] = wedge(mid, mid, r, QUARTER[s], QUARTER[s] + 90, tone(c, s), c.ink, sw)
    end
    out[#out + 1] = circle(mid, mid, r, nil, c.ink, sw * 1.6)
    if season and QUARTER[season] then
        out[#out + 1] = wedge(mid, mid, r * .97, QUARTER[season], QUARTER[season] + 90, nil, c.gold, sw * 2.4)
    end
    return table.concat(out)
end

-- The big wheel.
function Seasons.garden_season_wheel(c, vw, _vh, param)
    c = Wash.apply(c, param)
    return round(c, vw, tostring(param or ""):match("%a+"), vw * .008)
end

-- The small picture for the top bar's button.
function Seasons.garden_season_icon(c, vw, _vh, param)
    c = Wash.apply(c, param)
    return round(c, vw, tostring(param or ""):match("%a+"), vw * .035)
end

return Seasons
