-- What happens in the garden once a day, worked out when the garden is
-- opened: the bees, butterflies and moths that visit flowers in bloom (a
-- flower they visited gives an extra seed when it is cut back), and a line of
-- thanks for the pages read since the last time. Everything takes the saved
-- garden `d`, the time `now` and `note(kind, id, extra)` to write the journal.

local Cast = require("solarui/garden/cast")
local Season = require("solarui/garden/season")

local Visits = {}

-- The animals that carry pollen from flower to flower.
Visits.POLLINATORS = { bee = true, butterfly = true, moth = true }

-- A number for the day of `now` that changes at local midnight.
function Visits.day(now)
    local t = os.date("*t", now)
    return t.year * 400 + t.yday
end

-- The ids of the plants in bloom, in the cast's order.
local function bloomers(d)
    local out = {}
    for _i, p in ipairs(Cast.PLANTS) do
        local rec = d.plants[p.id]
        if rec and rec.stage == 4 then out[#out + 1] = p.id end
    end
    return out
end

-- Today's visits: each pollinator that has found the garden and is not
-- asleep calls on one flower in bloom, the same one all day, and the flower
-- is marked pollinated. Returns true when anything was written.
function Visits.round(d, now, note)
    local day = Visits.day(now)
    if d.visit_day == day then return false end
    d.visit_day = day
    local open = bloomers(d)
    if #open == 0 then return true end
    for _i, a in ipairs(Cast.ANIMALS) do
        if Visits.POLLINATORS[a.id] and d.animals[a.id] and not Season.rests(a, Season.now()) then
            local id = open[(day + #a.id * 7) % #open + 1]
            d.plants[id].pollinated = true
            note("visit", a.id, id)
        end
    end
    return true
end

-- A line of thanks for the pages read since the last time, at most once a
-- day: which plant was watered by them is the day's pick. `total` is every
-- page ever read. Returns true when a line was written.
function Visits.thanks(d, now, total, note)
    local day = Visits.day(now)
    local seen = d.seen_pages or d.base_pages
    if d.thanks_day == day or total <= seen then return false end
    d.thanks_day, d.seen_pages = day, total
    note("thanks", Cast.PLANTS[day % #Cast.PLANTS + 1].id, nil, total - seen)
    return true
end

return Visits
