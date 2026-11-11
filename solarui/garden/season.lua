-- The seasons of the garden. By default the garden follows the month on the
-- device (the other way round in the southern hemisphere); the reader may pick
-- a season on the garden's season wheel to see it at once, or follow the
-- calendar again. A season changes how often plants want water and how fast
-- they grow, which perennials die back to bare stems, and which animals are
-- asleep. Nothing is ever lost: a sleeping animal and a dormant plant are
-- still in the garden, and wake up when their season comes round.

local Settings = require("solarui/settings")
local _ = require("solarui/gettext")

local Season = {}

-- The seasons in the order the year goes through them.
Season.ALL = { "spring", "summer", "autumn", "winter" }

-- The names, for the wheel and the notes.
Season.NAMES = { spring = _("Spring"), summer = _("Summer"), autumn = _("Autumn"), winter = _("Winter") }

-- How a season changes the garden: `thirst` stretches or shortens the hours
-- between drinks, `growth` how fast the days of a stage pass.
local FACTORS = {
    spring = { thirst = 1, growth = 1 },
    summer = { thirst = .75, growth = 1 },
    autumn = { thirst = 1, growth = .8 },
    winter = { thirst = 2, growth = .5 },
}

-- Plants that keep their leaves all year; every other plant dies back in winter.
local EVERGREEN = { ivy = true, bracken = true, water_lily = true }

-- The season of a month (1 to 12), in the northern hemisphere or the southern.
function Season.ofMonth(month, south)
    if south then month = (month + 5) % 12 + 1 end
    if month == 12 or month <= 2 then return "winter" end
    if month <= 5 then return "spring" end
    if month <= 8 then return "summer" end
    return "autumn"
end

-- Is the garden in the southern hemisphere?
function Season.south()
    return Settings.get("garden_south", false) == true
end

-- Does the garden follow the calendar?
function Season.following()
    return type(Settings.get("garden_season", false)) ~= "string"
end

-- Show the garden in `season`, or with nil follow the calendar.
function Season.set(season)
    Settings.save("garden_season", season or false)
end

-- Choose the hemisphere.
function Season.setSouth(south)
    Settings.save("garden_south", south == true)
end

-- The season of the calendar now.
function Season.calendar()
    return Season.ofMonth(tonumber(os.date("%m")) or 6, Season.south())
end

-- The season of the garden: the one the reader picked, else the calendar's.
-- Tests and previews may replace this.
function Season.now()
    local picked = Settings.get("garden_season", false)
    if type(picked) == "string" and FACTORS[picked] then return picked end
    return Season.calendar()
end

local adjusted = {}

-- A plant's definition with the hours between drinks and the days of its
-- stages changed for the season (everything else reads through to the original).
function Season.adjust(def, season)
    season = season or Season.now()
    local key = def.id .. season
    if adjusted[key] then return adjusted[key] end
    local f = FACTORS[season]
    local need = {}
    for i, v in ipairs(def.need) do need[i] = v / f.growth end
    local copy = setmetatable({ interval = def.interval and def.interval * f.thirst or nil, need = need }, { __index = def })
    adjusted[key] = copy
    return copy
end

-- Has the plant died back for the winter (it grows again in spring)?
function Season.dormant(def, season)
    return (season or Season.now()) == "winter" and not EVERGREEN[def.id]
end

-- Is the animal asleep or away in this season? An animal's `rests` lists them.
function Season.rests(def, season)
    season = season or Season.now()
    for _i, s in ipairs(def.rests or {}) do
        if s == season then return true end
    end
    return false
end

-- A line for the garden's notes about when a sleeping animal wakes.
function Season.wakes(def)
    if not (def.rests and def.rests[1]) then return nil end
    return string.format(_("Asleep in %s."), Season.NAMES[def.rests[1]]:lower())
end

return Season
