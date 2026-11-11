-- The garden as it is kept between visits: what is planted and how far it has
-- grown, who has found the garden, the dew earned by reading and the seeds
-- earned by finishing books, nicknames and a short journal. All of it is one
-- table in the settings; `refresh` brings it up to the present (growth,
-- wilting, new visitors) and every action saves at once. Time and the reading
-- numbers come through State.clock and State.source so tests can set them.

local Cast = require("solarui/garden/cast")
local Care = require("solarui/garden/care")
local Settings = require("solarui/settings")
local Visitors = require("solarui/garden/visitors")

local State = {}

State.WATER = 2          -- dew a drink costs
State.FEED = 3           -- dew a meal costs
State.GIFT_DEW = 30
State.GIFT_SEEDS = 2
State.NICK_MAX = 14      -- letters in a nickname
State.JOURNAL_MAX = 80   -- lines the journal keeps

-- The time now; replaced in tests.
State.clock = os.time

-- The reading numbers { total (pages ever), pages (weekly grid), streak
-- (longest), books (finished) }; replaced in tests.
function State.source()
    local ok, r = pcall(function()
        local Goal = require("solarui/data/goal")
        local Insights = require("solarui/data/insights")
        local pattern = Insights.pattern()
        return { total = Insights.allTime().pages, pages = pattern and pattern.pages or {}, streak = Insights.streaks().day_best, books = #Goal.finished() }
    end)
    return ok and r or { total = 0, pages = {}, streak = 0, books = 0 }
end

local data

-- A new garden: every plant in bloom, some a little further on than others,
-- and the three animals that are always there, counting reading from now.
local function fresh()
    local now, reading = State.clock(), State.source()
    local d = { v = 2, created = now, base_pages = reading.total, base_books = reading.books, spent = 0, seeds_used = 0,
        collected = 0, plants = {}, animals = {}, journal = {} }
    for _i, p in ipairs(Cast.PLANTS) do
        local spread = 0
        for i = 1, #p.id do spread = (spread * 31 + p.id:byte(i)) % 50 end
        d.plants[p.id] = { stage = 4, grown = p.need[4] * spread / 100, at = now, watered = now, gen = 1 }
    end
    for _i, a in ipairs(Cast.ANIMALS) do
        if a.find.kind == "start" then d.animals[a.id] = { found = now, fed = now } end
    end
    return d
end

-- The saved garden, made on first use.
function State.get()
    if not data then
        data = Settings.get("garden", nil)
        if type(data) ~= "table" or data.v ~= 2 then data = fresh(); Settings.save("garden", data) end
    end
    return data
end

-- Forget what is loaded (the next call reads the settings again).
function State.unload()
    data = nil
end

-- Write the garden.
function State.save()
    Settings.save("garden", State.get())
end

-- Add a line to the journal: what happened ("sown", "sprout", "bud", "bloom",
-- "seedhead", "wilt", "back", "hide", "found") to whom.
local function note(kind, id)
    local j = State.get().journal
    j[#j + 1] = { t = State.clock(), k = kind, id = id }
    while #j > State.JOURNAL_MAX do table.remove(j, 1) end
end

-- Dew in hand: a gift to begin with and a drop for every page read since.
function State.dew()
    local d = State.get()
    return State.GIFT_DEW + math.max(0, State.source().total - d.base_pages) - d.spent
end

-- Seeds in hand: a gift, a seed for each book finished since and for each
-- seed head cut back, less the ones used.
function State.seeds()
    local d = State.get()
    return State.GIFT_SEEDS + math.max(0, State.source().books - d.base_books) + d.collected - d.seeds_used
end

-- Spend dew; false when there is not enough.
local function spend(cost)
    if State.dew() < cost then return false end
    State.get().spent = State.get().spent + cost
    return true
end

-- Bring the garden up to the present: plants grow, those left too long wilt,
-- animals left too long hide and come back, new visitors arrive. Returns
-- true when anything changed.
function State.refresh()
    local d, now = State.get(), State.clock()
    local dirty = false
    for id, rec in pairs(d.plants) do
        local def = Cast.plant(id)
        for _i, stage in ipairs(Care.grow(rec, def, now)) do
            note(({ "", "sprout", "bud", "bloom", "seedhead" })[stage], id)
            dirty = true
        end
        local wilted = Care.thirst(rec, def, now) == Care.WILTED
        if wilted ~= (rec.noted == "wilt") then
            if wilted then note("wilt", id) end
            rec.noted, dirty = wilted and "wilt" or nil, true
        end
    end
    for id, rec in pairs(d.animals) do
        local hiding = Care.hunger(rec, Cast.animal(id), now) == Care.HIDING
        if hiding ~= (rec.noted == "hide") then
            if hiding then note("hide", id) end
            rec.noted, dirty = hiding and "hide" or nil, true
        end
    end
    local facts = Visitors.facts(d.plants, State.source())
    for _i, id in ipairs(Visitors.foundAll(facts)) do
        if not d.animals[id] then
            d.animals[id] = { found = now, fed = now }
            note("found", id)
            dirty = true
        end
    end
    if dirty then State.save() end
    return dirty
end

-- Every plant that is planted, in the cast's order: { def, rec, thirst, until }.
function State.plants()
    local out, now = {}, State.clock()
    for _i, def in ipairs(Cast.PLANTS) do
        local rec = State.get().plants[def.id]
        if rec then out[#out + 1] = { def = def, rec = rec, thirst = Care.thirst(rec, def, now), thirsty_in = Care.untilThirsty(rec, def, now) } end
    end
    return out
end

-- Every animal that has found the garden: { def, rec, mood, here } where
-- `here` says it is about now (the right hour and not hiding).
function State.animals(hour)
    local out, now = {}, State.clock()
    hour = hour or tonumber(os.date("%H"))
    for _i, def in ipairs(Cast.ANIMALS) do
        local rec = State.get().animals[def.id]
        if rec then
            local mood = Care.hunger(rec, def, now)
            out[#out + 1] = { def = def, rec = rec, mood = mood, here = mood ~= Care.HIDING and Visitors.about(def, hour) }
        end
    end
    return out
end

-- The entry (see State.plants and State.animals) of a plant or an animal
-- that is in the garden, and which of the two it is; nil when it is not.
function State.entry(id, hour)
    for _i, e in ipairs(State.plants()) do
        if e.def.id == id then return e, "plant" end
    end
    for _i, e in ipairs(State.animals(hour)) do
        if e.def.id == id then return e, "animal" end
    end
end

-- The record of a plant or an animal, or nil.
function State.rec(id)
    local d = State.get()
    return d.plants[id] or d.animals[id]
end

-- Water a plant; returns false (and why: "none", "dry", "fresh" for a drink
-- taken less than half an interval ago, or "dew") when it cannot be done.
function State.water(id)
    local rec, def = State.get().plants[id], Cast.plant(id)
    if not rec then return false, "none" end
    if not def.interval then return false, "dry" end
    if State.clock() - rec.watered < def.interval / 2 then return false, "fresh" end
    if not spend(State.WATER) then return false, "dew" end
    Care.water(rec, State.clock())
    rec.noted = nil
    State.save()
    return true
end

-- Feed an animal; false and why ("none", "full" for a meal eaten less than
-- half an interval ago, or "dew") when it cannot be done.
function State.feed(id)
    local rec = State.get().animals[id]
    if not rec then return false, "none" end
    if State.clock() - rec.fed < Cast.animal(id).interval / 2 then return false, "full" end
    if not spend(State.FEED) then return false, "dew" end
    local was = rec.noted
    Care.feed(rec, State.clock())
    rec.noted = nil
    if was == "hide" then note("back", id) end
    State.save()
    return true
end

-- Use a seed to bring a plant that is still growing into bloom at once;
-- false and why ("none", "bloom" or "seed") when it cannot be done.
function State.sow(id)
    local d = State.get()
    local rec = d.plants[id]
    if not rec then return false, "none" end
    if rec.stage >= 4 then return false, "bloom" end
    if State.seeds() < 1 then return false, "seed" end
    local now = State.clock()
    rec.stage, rec.grown, rec.at, rec.watered = 4, 0, now, now
    d.seeds_used = d.seeds_used + 1
    note("sown", id)
    State.save()
    return true
end

-- Cut back a plant that has gone to seed: it keeps its name and starts
-- another generation, and the seeds it dropped are yours. False when it has
-- not gone to seed.
function State.collect(id)
    local d, def = State.get(), Cast.plant(id)
    local rec = d.plants[id]
    if not rec or not Care.collect(rec, def, State.clock()) then return false end
    d.collected = d.collected + 1
    State.save()
    return true
end

-- Give a plant or an animal a nickname (blank clears it). Returns the name
-- kept, cut to NICK_MAX letters.
function State.rename(id, text)
    local rec = State.rec(id)
    if not rec then return nil end
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local kept = {}
    for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if #kept < State.NICK_MAX then kept[#kept + 1] = ch end
    end
    rec.nick = #kept > 0 and table.concat(kept) or nil
    State.save()
    return rec.nick
end

-- The name to show: the nickname when there is one, else the common name.
function State.name(id)
    local rec, def = State.rec(id), Cast.find(id)
    return rec and rec.nick or (def and def.en) or id
end

-- The journal, newest first: { t, k, id }.
function State.journal()
    local out, j = {}, State.get().journal
    for i = #j, 1, -1 do out[#out + 1] = j[i] end
    return out
end

return State
