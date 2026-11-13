-- Which resident of the garden keeps the reader company on the home screen:
-- the one the reader pinned, else whoever needs care most (a wilted plant or
-- a hiding animal before a thirsty or hungry one), else one chosen by the
-- day. Plain functions of a list so they can be tested.

local Care = require("solarui/garden/care")
local Pet = require("solarui/garden/pet")
local State = require("solarui/garden/state")

local Companion = {}

-- How much care an entry needs: 0 none, 2 thirsty or hungry, 3 wilted or hiding.
function Companion.need(entry, kind)
    if kind == "plant" then return entry.thirst == Care.WILTED and 3 or entry.thirst == Care.THIRSTY and 2 or 0 end
    return entry.mood == Care.HIDING and 3 or entry.mood == Care.HUNGRY and 2 or 0
end

-- The one to show from a list { id, kind, entry }: the pinned id when it is
-- in the list, else the neediest (on `day`, which picks among equals).
function Companion.choose(list, pinned, day)
    if #list == 0 then return nil end
    for _i, item in ipairs(list) do
        if item.id == pinned then return item end
    end
    local top, tied = -1, {}
    for _i, item in ipairs(list) do
        local need = Companion.need(item.entry, item.kind)
        if need > top then top, tied = need, {} end
        if need == top then tied[#tied + 1] = item end
    end
    return tied[day % #tied + 1]
end

-- Everyone who can be shown now: the plants, and the animals that are about
-- or hiding (an animal asleep for the night is not).
function Companion.list(hour)
    local out = {}
    -- (one who has said goodbye lives in the orchard and does not keep company on home any more)
    for _i, e in ipairs(State.plants()) do
        if not Pet.remembered(e.def.id) then out[#out + 1] = { id = e.def.id, kind = "plant", entry = e } end
    end
    for _i, e in ipairs(State.animals(hour)) do
        if (e.here or e.mood == Care.HIDING) and not Pet.remembered(e.def.id) then out[#out + 1] = { id = e.def.id, kind = "animal", entry = e } end
    end
    return out
end

-- The companion for today: { id, kind, entry, need } or nil.
function Companion.pick(pinned, day, hour)
    local item = Companion.choose(Companion.list(hour), pinned, day)
    if item then item.need = Companion.need(item.entry, item.kind) end
    return item
end

return Companion
