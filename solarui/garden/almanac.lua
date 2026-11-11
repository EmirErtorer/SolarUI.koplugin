-- The almanac behind the field notes. Each plant and animal has pages that
-- open as you get to know them: when they appear, the name, the picture and
-- one fact (tier 1, "seen"); after a week with them, where they live, when
-- they flower or sleep and what they eat (tier 2, "known"); and once they
-- have a nickname of your own and a month has passed, their story and
-- something to look for outdoors (tier 3, "befriended"). The month-by-month
-- calendar and the web of who depends on whom come from here too.

local Cast = require("solarui/garden/cast")
local Plants = require("solarui/garden/almanac_plants")
local Animals = require("solarui/garden/almanac_animals")
local Season = require("solarui/garden/season")
local State = require("solarui/garden/state")
local Web = require("solarui/garden/web")
local _ = require("solarui/gettext")

local Almanac = {}

local DAY = 86400
Almanac.KNOWN_DAYS = 7
Almanac.FRIEND_DAYS = 30

-- The hand-written page of a plant or animal (name, habitat, story, look,
-- and months for a plant), or nil.
function Almanac.page(id)
    return Plants[id] or Animals[id]
end

-- How well the garden knows this plant or animal: 0 not in the garden yet, 1
-- seen, 2 known, 3 befriended.
function Almanac.tier(id)
    local rec = State.rec(id)
    if not rec then return 0 end
    local since = rec.found or State.get().created
    local days = (State.clock() - since) / DAY
    if rec.nick and days >= Almanac.FRIEND_DAYS then return 3 end
    if days >= Almanac.KNOWN_DAYS or (rec.gen or 1) > 1 then return 2 end
    return 1
end

-- Days still to wait for the next tier of this one (0 when there is none).
function Almanac.waiting(id)
    local rec = State.rec(id)
    if not rec then return 0 end
    local tier = Almanac.tier(id)
    local days = (State.clock() - (rec.found or State.get().created)) / DAY
    if tier == 1 then return math.ceil(Almanac.KNOWN_DAYS - days) end
    if tier == 2 then return rec.nick and math.max(0, math.ceil(Almanac.FRIEND_DAYS - days)) or 0 end
    return 0
end

-- The months a plant flowers or shows its best, as "April to June".
function Almanac.months(id)
    local page = Plants[id]
    if not page then return nil end
    local from, to = os.date("%B", os.time({ year = 2001, month = page.months[1], day = 1 })), os.date("%B", os.time({ year = 2001, month = page.months[2], day = 1 }))
    return from == to and from or string.format(_("%s to %s"), from, to)
end

-- The ids of the plants in flower or at their best in a month (1 to 12) and
-- the ids of the animals that are asleep then, for the calendar.
function Almanac.month(m)
    local season = Season.ofMonth(m, Season.south())
    local flowers, asleep = {}, {}
    for _i, p in ipairs(Cast.PLANTS) do
        local from, to = Plants[p.id].months[1], Plants[p.id].months[2]
        if Season.south() then from, to = (from + 5) % 12 + 1, (to + 5) % 12 + 1 end
        local inside = from <= to and (m >= from and m <= to) or (from > to and (m >= from or m <= to))
        if inside then flowers[#flowers + 1] = p.id end
    end
    for _i, a in ipairs(Cast.ANIMALS) do
        if Season.rests(a, season) then asleep[#asleep + 1] = a.id end
    end
    return flowers, asleep
end

-- The set of ids that are in the garden now (plants and animals who found it).
function Almanac.present()
    local set = {}
    for id in pairs(State.get().plants) do set[id] = true end
    for id in pairs(State.get().animals) do set[id] = true end
    return set
end

-- The links of the web among those in the garden: { a, b, text }.
function Almanac.web()
    return Web.links(Almanac.present())
end

-- The links of one plant or animal.
function Almanac.linksOf(id)
    return Web.of(id, Almanac.present())
end

return Almanac
