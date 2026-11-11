-- The garden's weather. The device cannot know the real weather, so the
-- garden has its own: each day has one kind, worked out from the date and the
-- season so it is the same all day and on every visit, and never claimed to
-- match what is outside. Rain gives the plants half a drink, once a day.

local Season = require("solarui/garden/season")
local Settings = require("solarui/settings")
local _ = require("solarui/gettext")

local Weather = {}

-- The kinds, in the order the chances below list them.
Weather.KINDS = { "clear", "cloudy", "rain", "snow", "mist" }

Weather.NAMES = { clear = _("Clear"), cloudy = _("Cloudy"), rain = _("Rain"), snow = _("Snow"), mist = _("Mist") }

-- The chances of each kind in a season, out of 100: clear, cloudy, rain, snow, mist.
local CHANCES = {
    spring = { 40, 25, 30, 0, 5 },
    summer = { 55, 25, 15, 0, 5 },
    autumn = { 30, 30, 30, 0, 10 },
    winter = { 30, 35, 0, 25, 10 },
}

-- Is the garden's weather on? It is, unless the reader turned it off.
function Weather.on()
    return Settings.get("garden_weather", true) ~= false
end

-- Turn the weather on or off.
function Weather.setOn(on)
    Settings.save("garden_weather", on ~= false)
end

-- A number from 0 to 99 for a day that looks random but is always the same for that day.
local function roll(day)
    local x = math.sin(day * 12.9898 + 78.233) * 43758.5453
    return math.floor((x - math.floor(x)) * 100)
end

-- The weather of a day (see Visits.day) in a season: one of Weather.KINDS.
function Weather.of(day, season)
    if not Weather.on() then return "clear" end
    local at, r = 0, roll(day)
    for i, chance in ipairs(CHANCES[season or Season.now()]) do
        at = at + chance
        if r < at then return Weather.KINDS[i] end
    end
    return "clear"
end

return Weather
