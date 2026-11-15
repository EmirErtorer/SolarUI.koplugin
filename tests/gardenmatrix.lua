-- The garden, every scenario for every plant and animal, on the real code with
-- a fake clock and fake reading numbers: growth through all five stages in each
-- season, thirst and wilting, watering, feeding, seeds (sowing and cutting
-- back in every way), nicknames, seasons and dormancy, hunger and hiding,
-- resting through winter, the hour each animal is about, the rule that finds
-- each animal, visits, the peeker, dew and seeds, giving back, weather and
-- rain, the journal, the almanac, the weekly things outdoors, every picture
-- in every state, and the companion for life for all of them.
-- Prints one line per group and writes every check to <report> when given.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/gardenmatrix.lua <repo> [report]

local REPO, REPORT = arg[1] or ".", arg[2]
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)

local Cast = require("solarui/garden/cast")
local Care = require("solarui/garden/care")
local Settings = require("solarui/settings")
local Season = require("solarui/garden/season")
local Sky = require("solarui/garden/sky")
local State = require("solarui/garden/state")
local Visitors = require("solarui/garden/visitors")
local Visits = require("solarui/garden/visits")
local Weather = require("solarui/garden/weather")

local DAY, HOUR = 86400, 3600
local T0 = 1700000000

local now = T0
State.clock = function() return now end
local reading = { total = 0, pages = {}, streak = 0, books = 0, days = {}, year_books = 0 }
State.source = function() return reading end

-- every check, by group
local groups, order, log = {}, {}, {}
local current = "misc"
local function group(name) current = name end
local function ck(ok, what)
    local g = groups[current]
    if not g then g = { n = 0, bad = 0 }; groups[current] = g; order[#order + 1] = current end
    g.n = g.n + 1
    if not ok then g.bad = g.bad + 1; print("FAIL [" .. current .. "] " .. what) end
    log[#log + 1] = string.format("%s\t%s\t%s", ok and "ok" or "FAIL", current, what)
    Kit.ok(ok, current .. ": " .. what)
end

-- A fresh garden in `season` at time T0, with plenty of dew by default.
local function reset(season)
    Settings.set("garden", nil)
    State.unload()
    Settings.set("garden_season", season or "spring")
    Settings.set("garden_hour", false)
    Settings.set("garden_weather", false)   -- no rain in the way, except where weather is the point
    now = T0
    reading.total, reading.books, reading.streak, reading.days, reading.pages, reading.year_books = 0, 0, 0, {}, {}, 0
    local d = State.get()
    d.bonus = 100000   -- dew for every test that is not about dew
    d.collected = 100  -- and seeds
    return d
end

-- A plant record at stage `stage`, just watered.
local function plant(id, stage, extra)
    local d = State.get()
    d.plants[id] = { stage = stage, grown = 0, at = now, watered = now, gen = 1 }
    for k, v in pairs(extra or {}) do d.plants[id][k] = v end
    return d.plants[id]
end

local function animal(id, fed)
    State.get().animals[id] = { found = now, fed = fed or now }
    return State.get().animals[id]
end

local SEASONS = Season.ALL
local ids = Cast.ids()

-- ---------------------------------------------------------------- growth
group("growth: every plant through five stages, every season")
for _, def in ipairs(Cast.PLANTS) do
    for _, s in ipairs(SEASONS) do
        reset(s)
        local rec = plant(def.id, 1)
        local eff = Season.adjust(def, s)
        local at, stage_at = 0, { [1] = 0 }
        local total = 0
        for i = 1, 4 do total = total + eff.need[i] end
        local step = 6 * HOUR
        local last = 1
        while at <= total + 2 * DAY do
            now = T0 + at
            if def.interval then rec.watered = now end   -- watered in time, every time
            for _i, st in ipairs(Care.grow(rec, eff, now)) do stage_at[st] = at end
            if rec.stage ~= last then last = rec.stage end
            at = at + step
        end
        local want, sum = {}, 0
        for i = 1, 4 do sum = sum + eff.need[i]; want[i + 1] = sum end
        local ok = rec.stage == 5
        for st = 2, 5 do
            local got = stage_at[st]
            ok = ok and got ~= nil and got >= want[st] - 1 and got <= want[st] + step
        end
        ck(ok, def.id .. " reaches seed, sprout, bud, bloom and seed head on time in " .. s)
    end
end
-- growth through the real refresh (journal notes, seeded time), in spring
for _, def in ipairs(Cast.PLANTS) do
    reset("spring")
    State.get().plants, State.get().animals = {}, {}   -- (so the journal holds only this one)
    plant(def.id, 1)
    local eff = Season.adjust(def, "spring")
    local total = 0
    for i = 1, 4 do total = total + eff.need[i] end
    for at = 0, total + DAY, 6 * HOUR do
        now = T0 + at
        State.get().plants[def.id].watered = now
        State.refresh()
    end
    local rec = State.get().plants[def.id]
    local kinds = {}
    for _, e in ipairs(State.get().journal) do if e.id == def.id then kinds[e.k] = true end end
    ck(rec.stage == 5 and rec.seeded and kinds.sprout and kinds.bud and kinds.bloom and kinds.seedhead, def.id .. " grows to seed through the garden and writes its journal")
end

-- ---------------------------------------------------------------- thirst
group("thirst: fine, thirsty, wilted, in every season")
for _, def in ipairs(Cast.PLANTS) do
    for _, s in ipairs(SEASONS) do
        reset(s)
        local rec = plant(def.id, 4)
        local eff = Season.adjust(def, s)
        if not def.interval then
            now = T0 + 400 * DAY
            ck(Care.thirst(rec, eff, now) == Care.FINE, def.id .. " never wants water (" .. s .. ")")
        else
            local i = eff.interval
            ck(Care.thirst(rec, eff, T0 + i) == Care.FINE and Care.thirst(rec, eff, T0 + i + 1) == Care.THIRSTY
                and Care.thirst(rec, eff, T0 + 2 * i) == Care.THIRSTY and Care.thirst(rec, eff, T0 + 2 * i + 1) == Care.WILTED,
                def.id .. " is fine, then thirsty, then wilted at the right times in " .. s)
            ck(Care.untilThirsty(rec, eff, T0) == i and Care.untilThirsty(rec, eff, T0 + 3 * i) == 0, def.id .. " says how long until thirsty in " .. s)
        end
    end
end

group("wilting stops growth and watering brings a plant back")
for _, def in ipairs(Cast.PLANTS) do
    if def.interval then
        reset("spring")
        local rec = plant(def.id, 2)
        local eff = Season.adjust(def, "spring")
        now = T0 + 2 * eff.interval + 20 * DAY
        State.refresh()
        local grown, stage = rec.grown, rec.stage
        now = now + 40 * DAY
        State.refresh()
        ck(rec.grown == grown and rec.stage == stage and rec.noted == "wilt", def.id .. " stays as it was while wilted, and is noted")
        local ok = State.water(def.id)
        State.refresh()
        ck(ok and Care.thirst(rec, eff, now) == Care.FINE and rec.noted == nil, def.id .. " is fine again after a drink")
        local before = rec.stage * 1e9 + rec.grown
        now = now + 10 * DAY
        rec.watered = now
        State.refresh()
        ck(rec.stage * 1e9 + rec.grown > before or rec.stage == 5, def.id .. " grows on after the drink")
    end
end

-- ---------------------------------------------------------------- water
group("watering: results for every plant")
for _, def in ipairs(Cast.PLANTS) do
    reset("spring")
    plant(def.id, 4)
    local eff = Season.adjust(def, "spring")
    if not def.interval then
        local ok, why = State.water(def.id)
        ck(not ok and why == "dry", def.id .. " needs no watering")
    else
        local ok, why = State.water(def.id)
        ck(not ok and why == "fresh", def.id .. " is not watered just after a drink")
        now = T0 + eff.interval / 2 + 1
        local dew = State.dew()
        ok = State.water(def.id)
        ck(ok and State.dew() == dew - State.WATER, def.id .. " is watered once half its time has passed, for " .. State.WATER .. " dew")
        now = now + eff.interval
        State.get().bonus, State.get().spent = 0, State.dew() + State.GIFT_DEW + 5
        ok, why = State.water(def.id)
        ck(not ok and why == "dew", def.id .. " is not watered without dew")
    end
    local ok, why = State.water("nothingthere")
    ck(not ok and why == "none", "watering someone who is not planted says so")
end

-- ---------------------------------------------------------------- sow
group("seeds: sowing a growing plant into bloom")
for _, def in ipairs(Cast.PLANTS) do
    for stage = 1, 5 do
        reset("spring")
        plant(def.id, stage)
        local seeds = State.seeds()
        local ok, why = State.sow(def.id)
        if stage < 4 then
            ck(ok and State.get().plants[def.id].stage == 4 and State.seeds() == seeds - 1, def.id .. " at stage " .. stage .. " blooms at once for a seed")
        else
            ck(not ok and why == "bloom", def.id .. " at stage " .. stage .. " is already in bloom or past it")
        end
    end
    reset("spring")
    plant(def.id, 2)
    State.get().collected, State.get().seeds_used = 0, State.GIFT_SEEDS
    local ok, why = State.sow(def.id)
    ck(not ok and why == "seed", def.id .. " is not sown without a seed")
end

-- ---------------------------------------------------------------- collect
group("cutting back: keep, birds, scatter, share, ripe and unripe, pollinated")
local function gains(id, how, o)
    reset("spring")
    local rec = plant(id, 5, { seeded = o.ripe and (T0 - 3 * DAY) or T0, pollinated = o.pollinated })
    State.get().collected = 0
    local ok, gain = State.collect(id, how)
    return ok, gain, State.get().plants[id], State.get().collected
end
for _, def in ipairs(Cast.PLANTS) do
    local ok, gain, rec, coll = gains(def.id, "keep", { ripe = true })
    ck(ok and gain == 1 and coll == 1 and rec.stage == 2 and rec.gen == 2 and rec.seeded == nil, def.id .. " cut back and kept: a seed, a new generation, starting again as a sprout")
    ok, gain = gains(def.id, "keep", { ripe = false })
    ck(ok and gain == .5, def.id .. " cut back before the seeds ripened gives half")
    ok, gain = gains(def.id, "keep", { ripe = true, pollinated = true })
    ck(ok and gain == 2, def.id .. " visited by a bee or butterfly gives one more")
    ok, gain = gains(def.id, "birds", { ripe = true, pollinated = true })
    ck(ok and gain == 0, def.id .. " left for the birds gives nothing for the reader")
    ok, gain = gains(def.id, "scatter", { ripe = true })
    ck(ok and gain == .5, def.id .. " scattered gives half a seed")
    ok, gain = gains(def.id, "share", { ripe = true })
    ck(ok and gain == 1, def.id .. " shared gives a seed")
    reset("spring")
    plant(def.id, 4)
    ck(State.collect(def.id, "keep") == false, def.id .. " cannot be cut back before it has gone to seed")
    reset("spring")
    ck(State.collect("nothingthere", "keep") == false, "cutting back someone who is not planted does nothing")
end
group("cutting back: the birds and the harvest feed the hungry")
do
    reset("spring")
    animal("bee", T0 - 80 * HOUR); animal("snail", T0 - 10 * HOUR); animal("ladybug", T0 - 30 * HOUR)
    plant("rose", 5, { seeded = T0 - 3 * DAY })
    State.collect("rose", "birds")
    ck(State.get().animals.bee.fed == now and State.get().animals.snail.fed < now, "the birds feed the hungriest animal for free")
    reset("spring")
    animal("bee", T0 - 80 * HOUR); animal("snail", T0 - 70 * HOUR); animal("ladybug", T0 - 60 * HOUR)
    plant("three_sisters", 5, { seeded = T0 - 3 * DAY })
    State.collect("three_sisters", "share")
    ck(State.get().animals.bee.fed == now and State.get().animals.snail.fed == now and State.get().animals.ladybug.fed == now, "sharing the harvest feeds the three who wait longest")
end

group("reseeding: a plant cut back grows again, generation after generation")
for _, def in ipairs(Cast.PLANTS) do
    reset("spring")
    State.get().plants, State.get().animals = {}, {}
    plant(def.id, 5, { seeded = T0 - 3 * DAY })
    local eff = Season.adjust(def, "spring")
    local ok = true
    for gen = 2, 4 do
        local took = State.collect(def.id, "keep")
        local rec = State.get().plants[def.id]
        ok = ok and took and rec.gen == gen and rec.stage == 2
        -- from a sprout to a seed head again, watered all the way
        local need = eff.need[2] + eff.need[3] + eff.need[4]
        for at = 0, need + DAY, 6 * HOUR do
            now = now + 6 * HOUR
            if def.interval then rec.watered = now end
            State.refresh()
        end
        ok = ok and rec.stage == 5 and rec.seeded ~= nil
        now = now + 3 * DAY
    end
    ck(ok, def.id .. " grows from a sprout to seed again after each cutting back, for three generations")
    ck(State.get().plants[def.id].gen == 4, def.id .. " is on its fourth generation")
end

-- ---------------------------------------------------------------- names
group("names: nicknames for everyone")
for _, id in ipairs(ids) do
    reset("spring")
    if Cast.plant(id) then plant(id, 4) else animal(id) end
    local def = Cast.find(id)
    ck(State.name(id) == def.en, id .. " goes by the common name at first")
    if def.queen then
        ck(State.rename(id, "  Pip  ") == nil and State.name(id) == def.en, id .. " keeps her name: the queen cannot be renamed")
        goto continue
    end
    ck(State.rename(id, "  Pip  ") == "Pip" and State.name(id) == "Pip", id .. " takes a nickname, trimmed")
    local long = State.rename(id, string.rep("a", 30))
    ck(long and #long == State.NICK_MAX, id .. " keeps at most " .. State.NICK_MAX .. " letters")
    local uni = State.rename(id, string.rep("\u{E9}", 20))
    local count = 0
    for _ in uni:gmatch("[%z\1-\127\194-\244][\128-\191]*") do count = count + 1 end
    ck(count == State.NICK_MAX, id .. " counts letters, not bytes, in a nickname")
    ck(State.rename(id, "   ") == nil and State.name(id) == def.en, id .. " goes back to the common name when the nickname is cleared")
    ::continue::
end
ck(State.rename("nothingthere", "x") == nil, "naming someone who is not in the garden does nothing")

-- ---------------------------------------------------------------- seasons
group("seasons: dormancy, speed and thirst for every plant")
local EVERGREEN = { ivy = true, bracken = true, water_lily = true }
for _, def in ipairs(Cast.PLANTS) do
    for _, s in ipairs(SEASONS) do
        reset(s)
        plant(def.id, 4)
        local e = State.entry(def.id)
        ck(e.dormant == (s == "winter" and not EVERGREEN[def.id]), def.id .. (e.dormant and " dies back" or " stays up") .. " in " .. s)
        local eff = Season.adjust(def, s)
        local f = ({ spring = { 1, 1 }, summer = { .75, 1 }, autumn = { 1, .8 }, winter = { 2, .5 } })[s]
        ck((not def.interval or eff.interval == def.interval * f[1]) and math.abs(eff.need[2] - def.need[2] / f[2]) < 1e-6, def.id .. " has the thirst and speed of " .. s)
        local GardenCard = require("solarui/ui/gardencard")
        local text = GardenCard.status(e, "plant")
        ck(type(text) == "string" and #text > 0 and (not e.dormant or text:find("winter")), def.id .. " says how it is in " .. s)
    end
end
group("seasons: the calendar, both hemispheres")
for month = 1, 12 do
    local north, south = Season.ofMonth(month), Season.ofMonth(month, true)
    local want = ({ "winter", "winter", "spring", "spring", "spring", "summer", "summer", "summer", "autumn", "autumn", "autumn", "winter" })[month]
    ck(north == want and south ~= north, "month " .. month .. " is " .. want .. " in the north and the opposite half-year in the south")
end

-- ---------------------------------------------------------------- animals
group("hunger: content, hungry, hiding for every animal")
for _, def in ipairs(Cast.ANIMALS) do
    reset("spring")
    local rec = animal(def.id)
    local i = def.interval
    ck(Care.hunger(rec, def, T0 + i) == Care.CONTENT and Care.hunger(rec, def, T0 + i + 1) == Care.HUNGRY
        and Care.hunger(rec, def, T0 + 2 * i) == Care.HUNGRY and Care.hunger(rec, def, T0 + 2 * i + 1) == Care.HIDING,
        def.id .. " is content, then hungry, then hiding at the right times")
end
group("feeding: every animal")
for _, def in ipairs(Cast.ANIMALS) do
    reset("spring")
    local rec = animal(def.id)
    local ok, why = State.feed(def.id)
    ck(not ok and why == "full", def.id .. " is not fed just after a meal")
    now = T0 + def.interval / 2 + 1
    local dew = State.dew()
    ok = State.feed(def.id)
    ck(ok and State.dew() == dew - State.FEED and rec.fed == now, def.id .. " is fed after half its time, for " .. State.FEED .. " dew")
    now = now + def.interval
    State.get().bonus, State.get().spent = 0, State.dew() + State.GIFT_DEW + 5
    ok, why = State.feed(def.id)
    ck(not ok and why == "dew", def.id .. " is not fed without dew")
    ck(select(2, State.feed("nothingthere")) == "none", "feeding someone who is not in the garden says so")
end
group("hiding: an animal hides when hungry too long and comes back for a meal")
for _, def in ipairs(Cast.ANIMALS) do
    reset("spring")
    animal(def.id)
    now = T0 + 2 * def.interval + HOUR
    Season.calendar = function() return "spring" end
    State.refresh()
    local e = State.entry(def.id, 12)
    if def.queen then
        ck(e.mood == Care.HIDING and e.here and State.get().animals[def.id].noted == "hide", def.id .. " never hides: hungry, she stays and demands")
    else
        ck(e.mood == Care.HIDING and not e.here and State.get().animals[def.id].noted == "hide", def.id .. " hides and the journal says so")
    end
    State.feed(def.id)
    State.refresh()
    e = State.entry(def.id, 12)
    local back = false
    for _, j in ipairs(State.get().journal) do if j.k == "back" and j.id == def.id then back = true end end
    ck(e.mood == Care.CONTENT and back, def.id .. " comes back out when fed")
end
group("resting: who sleeps through which season")
for _, def in ipairs(Cast.ANIMALS) do
    for _, s in ipairs(SEASONS) do
        reset(s)
        animal(def.id)
        now = T0 + 90 * DAY
        local e = State.entry(def.id, 12)
        local rests = false
        for _, r in ipairs(def.rests or {}) do if r == s then rests = true end end
        ck(e.resting == rests and (not rests or (e.mood == Care.CONTENT and not e.here)), def.id .. (rests and " sleeps" or " is about") .. " in " .. s)
        if rests then
            Season.calendar = function() return s end
            State.refresh()
            ck(State.get().animals[def.id].fed >= now - 1 and State.get().animals[def.id].noted ~= "hide", def.id .. " is not hungry after sleeping through " .. s)
        end
    end
end
Season.calendar = nil
Season.calendar = function() return Season.ofMonth(tonumber(os.date("%m")) or 6, Season.south()) end

group("the hour: when each animal is about")
for _, def in ipairs(Cast.ANIMALS) do
    for hour = 0, 23 do
        local night = Sky.phase(hour) == "night"
        local want = def.about == "day" and not night or def.about == "night" and night or def.about == "any"
        ck(Visitors.about(def, hour) == want, def.id .. " at " .. hour .. ":00 is " .. (want and "about" or "away"))
    end
end
for _, def in ipairs(Cast.ANIMALS) do
    reset("spring")
    animal(def.id)
    for _, hour in ipairs({ 3, 8, 13, 18, 23 }) do
        local e = State.entry(def.id, hour)
        ck(e.here == Visitors.about(def, hour), def.id .. " is shown only when it is the right hour (" .. hour .. ")")
    end
end
group("the sky: five phases of the day")
do
    local seen = {}
    for hour = 0, 23 do seen[Sky.phase(hour)] = true end
    ck(seen.night and seen.morning and seen.day and seen.golden, "night, morning, day and golden hour all happen")
    ck(Sky.phase(21) == "golden" and Sky.phase(22) == "night" and Sky.phase(4) == "night" and Sky.phase(5) == "morning" and Sky.phase(11) == "day" and Sky.phase(17) == "golden", "the phases change at 22, 5, 11 and 17")
end

-- ---------------------------------------------------------------- finding
group("finding: the rule that brings each animal and plant")
local function facts(o)
    local plants = o.plants or {}
    local bloom = 0
    for _, rec in pairs(plants) do if rec.stage == 4 then bloom = bloom + 1 end end
    return { bloom = o.bloom or bloom, plants = plants, streak = o.streak or 0, books = o.books or 0, morning = o.morning or 0, night = o.night or 0 }
end
for _, def in ipairs(Cast.ANIMALS) do
    local f = def.find
    local need = {
        start = function() return facts({}), nil end,
        bloom = function() return facts({ bloom = f.n }), facts({ bloom = f.n - 1 }) end,
        morning = function() return facts({ morning = f.n }), facts({ morning = f.n - 1 }) end,
        night = function() return facts({ night = f.n }), facts({ night = f.n - 1 }) end,
        books = function() return facts({ books = f.n }), facts({ books = f.n - 1 }) end,
        streak = function()
            local good = { streak = f.n, plants = f.id and { [f.id] = { stage = f.stage } } or {} }
            local bad_streak = { streak = f.n - 1, plants = good.plants }
            local bad_plant = f.id and { streak = f.n, plants = { [f.id] = { stage = f.stage - 1 } } } or nil
            return facts(good), facts(bad_streak), bad_plant and facts(bad_plant)
        end,
        plant = function() return facts({ plants = { [f.id] = { stage = f.stage } } }), facts({ plants = { [f.id] = { stage = f.stage - 1 } } }) end,
    }
    local yes, no, no2 = need[f.kind]()
    ck(Visitors.found(def, yes), def.id .. " finds the garden when " .. f.kind .. " holds")
    if no then ck(not Visitors.found(def, no), def.id .. " does not find it a step short") end
    if no2 then ck(not Visitors.found(def, no2), def.id .. " does not find it without the plant grown") end
    ck(#Visitors.hint(def) > 0, def.id .. " has a hint for the field notes")
end
group("finding: through the garden, with the reading numbers")
for _, def in ipairs(Cast.ANIMALS) do
    reset("spring")
    local d = State.get()
    d.animals = {}
    -- everything a rule asks, at once
    reading.books, reading.streak = 10, 20
    reading.pages = { [1] = { [8] = 100, [23] = 100 } }
    for _, p in ipairs(Cast.PLANTS) do if not p.find then d.plants[p.id] = { stage = 4, grown = 0, at = now, watered = now, gen = 1 } end end
    State.refresh()
    ck(State.get().animals[def.id] ~= nil, def.id .. " has found the garden once everything is earned")
end
do
    reset("spring")
    State.get().animals = {}
    State.refresh()
    local a = State.get().animals
    ck(a.bee and a.ladybug and a.snail, "a new garden has the bee, the ladybird and the snail from the start")
    ck(a.butterfly and a.dragonfly and a.frog, "and the butterfly, the dragonfly and the frog as soon as the beds are in bloom")
    ck(not (a.robin or a.hedgehog or a.moth or a.fox or a.koi or a.peacock), "and nobody who has to be earned by reading")
    ck(State.get().plants.three_sisters == nil, "and the Three Sisters bed is not planted yet")
    reading.books = 3
    State.refresh()
    ck(State.get().plants.three_sisters and State.get().plants.three_sisters.stage == 1, "the Three Sisters bed is planted after three books")
    local planted = false
    for _, j in ipairs(State.get().journal) do if j.k == "planted" and j.id == "three_sisters" then planted = true end end
    ck(planted, "and the journal says a bed was laid out")
end

-- ---------------------------------------------------------------- visits, peek
group("visits: pollinators call on a flower in bloom each day")
do
    reset("spring")
    animal("bee"); animal("butterfly"); animal("moth")
    for _, p in ipairs(Cast.PLANTS) do if State.get().plants[p.id] and State.get().plants[p.id].stage == 4 then State.get().plants[p.id].pollinated = nil end end
    local visited = {}
    local function note(kind, id, with) if kind == "visit" then visited[id] = with end end
    ck(Visits.round(State.get(), now, note), "a round is made on a new day")
    ck(visited.bee and visited.butterfly and visited.moth, "the bee, the butterfly and the moth each call on a flower")
    local count = 0
    for _, rec in pairs(State.get().plants) do if rec.pollinated then count = count + 1 end end
    ck(count >= 1 and count <= 3, "the flowers they called on are marked pollinated")
    ck(not Visits.round(State.get(), now, note), "and no second round the same day")
    now = now + DAY
    ck(Visits.round(State.get(), now, note), "but another the next day")
    reset("winter")
    animal("bee")
    visited = {}
    Visits.round(State.get(), now, note)
    ck(next(visited) == nil, "no one visits in winter, when the pollinators sleep")
    reset("spring")
    animal("bee")
    for _, rec in pairs(State.get().plants) do rec.stage = 3 end
    visited = {}
    Visits.round(State.get(), now, note)
    ck(next(visited) == nil, "no one calls when nothing is in bloom")
end
group("the peeker: the face in the grass")
do
    reset("spring")
    local d = State.get()
    d.animals = { bee = { found = now, fed = now } }
    local who = State.peek()
    ck(who == "bee", "the only animal there is peeks")
    local dew = State.dew()
    ck(State.claimPeek() == "bee" and State.dew() == dew + 1, "finding the face is worth a drop of dew")
    ck(State.peek() == nil and State.claimPeek() == false, "once a day")
    now = now + DAY
    ck(State.peek() == "bee", "and it is back the next day")
    reset("spring")
    State.get().animals = {}
    ck(State.peek() == nil, "nobody peeks when no animal has come")
end

-- ---------------------------------------------------------------- economy
group("dew and seeds: what reading earns and what is spent")
do
    reset("spring")
    State.get().bonus, State.get().collected = 0, 0
    reading.total, reading.books = 0, 0
    ck(State.dew() == State.GIFT_DEW and State.seeds() == State.GIFT_SEEDS, "a new garden has the gift of dew and seeds")
    reading.total = 120
    ck(State.dew() == State.GIFT_DEW + 120, "every page read is a drop of dew")
    reading.books = 2
    ck(State.seeds() == State.GIFT_SEEDS + 2, "every book finished is a seed")
    plant("rose", 4)
    now = T0 + 36 * HOUR / 2 + 1
    State.water("rose")
    ck(State.dew() == State.GIFT_DEW + 120 - State.WATER, "a drink costs " .. State.WATER .. " dew")
    State.get().spent = 100000
    ck(State.dew() < 0 or select(2, State.water("rose")) ~= nil, "dew never goes below what is paid")
end
group("giving back: a seed to the wild edge after a book")
do
    reset("spring")
    State.get().bonus = 0
    reading.books = 0
    ck(State.owed() == 0 and State.giveBack(true) == false, "nothing is asked when no book was finished")
    reading.books = 2
    ck(State.owed() == 2, "two finished books wait for an answer")
    ck(State.giveBack(true) and State.given() == 1 and State.owed() == 1, "yes leaves a seed and counts it")
    ck(State.giveBack(false) and State.given() == 1 and State.owed() == 0, "not now lets the moment pass, uncounted")
    ck(State.giveBack(true) == false, "nothing is asked twice for the same book")
    reading.books = 3
    ck(State.owed() == 1, "and the next book asks again")
end

-- ---------------------------------------------------------------- weather
group("weather: every season, rain and snow")
do
    reset("spring")
    Settings.set("garden_weather", true)
    for _, s in ipairs(SEASONS) do
        local seen = {}
        for day = 1, 800 do seen[Weather.of(day, s)] = (seen[Weather.of(day, s)] or 0) + 1 end
        ck(seen.clear and seen.cloudy and seen.mist, s .. " has clear, cloudy and misty days")
        ck((s == "winter") == (seen.snow ~= nil) and (s ~= "winter") == (seen.rain ~= nil), s .. (s == "winter" and " has snow and no rain" or " has rain and no snow"))
        ck(Weather.of(37, s) == Weather.of(37, s), s .. " weather is the same all day")
    end
    Weather.setOn(false)
    local all = true
    for day = 1, 200 do if Weather.of(day, "winter") ~= "clear" then all = false end end
    Weather.setOn(true)
    ck(all, "with the weather off every day is clear")
    -- rain gives half a drink once a day
    reset("spring")
    Settings.set("garden_weather", true)
    local rainy
    for day = 1, 2000 do if Weather.of(Visits.day(T0 + day * DAY), "spring") == "rain" then rainy = day break end end
    now = T0 + rainy * DAY
    plant("rose", 4, { watered = now - 20 * HOUR })
    local before = State.get().plants.rose.watered
    Settings.set("garden_weather", true)
    ck(State.rain(now) == true and State.get().plants.rose.watered > before, "rain waters the thirsty beds by half a drink")
    local after = State.get().plants.rose.watered
    ck(State.rain(now) == false and State.get().plants.rose.watered == after, "but only once a day")
    ck(select(2, pcall(function() return State.weather(now) end)) == "rain", "the garden says it rained")
    reset("winter")
    Settings.set("garden_weather", true)
    local snowy
    for day = 1, 2000 do if Weather.of(Visits.day(T0 + day * DAY), "winter") == "snow" then snowy = day break end end
    now = T0 + snowy * DAY
    plant("ivy", 4, { watered = now - 20 * HOUR })
    local w = State.get().plants.ivy.watered
    ck(State.rain(now) == true and State.get().plants.ivy.watered == w, "snow settles and waters nothing")
    local noted = false
    for _, j in ipairs(State.get().journal) do if j.k == "snow" then noted = true end end
    ck(noted, "and the journal notes the snow")
end

-- ---------------------------------------------------------------- journal
group("journal: every kind of event in words")
do
    reset("spring")
    local kinds = { "sown", "sprout", "bud", "bloom", "seedhead", "wilt", "found", "hide", "visit", "thanks", "back_seeds", "birds", "scatter", "gave", "rain", "snow", "outside", "peek", "planted", "share", "season", "back" }
    for _, k in ipairs(kinds) do
        for t = 0, 2 do
            local e = { t = T0 + t, k = k, id = "rose", with = k == "visit" and "tulip" or k == "season" and "winter" or nil, n = 12 }
            local ok, line = pcall(require("solarui/garden/journal").line, e)
            ck(ok and type(line) == "table" and #line.text > 3 and not line.text:find("%%"), "a journal line for " .. k .. " (" .. t .. ")")
        end
    end
    for _, id in ipairs(ids) do
        local line = require("solarui/garden/journal").line({ t = T0, k = "found", id = id })
        ck(#line.text > 3, "the journal can say about " .. id)
    end
end

-- ---------------------------------------------------------------- almanac
group("almanac: every page at every depth")
do
    local Almanac = require("solarui/garden/almanac")
    for _, id in ipairs(ids) do
        reset("spring")
        if Cast.plant(id) then plant(id, 4) else animal(id) end
        ck(Almanac.tier(id) == 1, id .. " is seen at first")
        now = T0 + 8 * DAY
        ck(Almanac.tier(id) == 2, id .. " is known after a week")
        State.rename(id, "Friend")
        now = T0 + 40 * DAY
        ck(Almanac.tier(id) == 3, id .. " is befriended after a month and a name")
        local page = Almanac.page(id)
        ck(page and page.name and page.habitat and page.story and page.look, id .. " has a full page")
        ck(Almanac.waiting(id) == 0, id .. " has nothing left to wait for")
        ck(#Almanac.linksOf(id) >= 0, id .. " lists its links")
    end
    for m = 1, 12 do
        local flowers, asleep = Almanac.month(m)
        ck(type(flowers) == "table" and type(asleep) == "table", "the year calendar has month " .. m)
    end
end

-- ---------------------------------------------------------------- outside
group("outside: the weekly things to do")
do
    local Prompts = require("solarui/garden/prompts")
    for _, s in ipairs(SEASONS) do
        for i = 1, #Prompts.LIST[s] do ck(#Prompts.text(s, i) > 5 and Prompts.kind(s, i) ~= nil, s .. " thing " .. i .. " has words and a kind") end
    end
    reset("spring")
    ck(State.toggleOutside(1) == true and State.outsideTotals().done == 1, "ticking a thing is kept")
    ck(State.outsideWeek()[1].done and not State.outsideWeek()[2].done, "and shows as done")
    ck(State.toggleOutside(1) == false and State.outsideTotals().done == 0, "ticking it again takes it out")
    State.toggleOutside(1); State.toggleOutside(2); State.toggleOutside(3)
    ck(State.outsideTotals().full_weeks == 1 and #State.outsideLog() == 3, "a week with all ticked is counted, and the log keeps each")
    ck(State.toggleOutside(99) == false, "a thing that is not there is not ticked")
end

group("outside: the garden's pick, no repeats, seen outside, firsts, notes")
do
    local Prompts = require("solarui/garden/prompts")
    reset("spring")
    -- twelve weeks (a thing of each kind is offered again only when all twelve of them have been): the same
    -- things all week, one of each kind, and nothing offered twice
    local offered, repeats, garden_weeks, wrong_kind, unstable, expected = {}, 0, 0, 0, 0, 0
    for w = 0, 11 do
        now = T0 + w * 7 * DAY
        if Prompts.gardenWeek(Prompts.week(now)) then expected = expected + 1 end
        local week = State.outsideWeek()
        local again = State.outsideWeek()
        for k = 1, 3 do
            if week[k].text ~= again[k].text then unstable = unstable + 1 end
            if week[k].kind ~= Prompts.KINDS[k] then wrong_kind = wrong_kind + 1 end
            local key = week[k].who and ("who:" .. week[k].who) or ("i:" .. week[k].i)
            if week[k].who then garden_weeks = garden_weeks + 1 end
            if offered[key] and not week[k].who then repeats = repeats + 1 end
            offered[key] = true
        end
    end
    ck(unstable == 0, "a week's three things stay the same all week")
    ck(wrong_kind == 0, "each week has one to look at, one to listen to and one to do")
    ck(repeats == 0, "no thing from the list comes twice in twelve weeks")
    ck(garden_weeks == expected and expected >= 7 and expected <= 9, "the garden's pick takes the thing to look at in two weeks of three (" .. garden_weeks .. " of 12)")
    -- the pick is someone in the garden, and someone never seen outdoors comes first
    reset("spring")
    plant("rose", 4); plant("tulip", 4); animal("bee")
    now = T0 + 7 * DAY
    local look = State.outsideWeek()[1]
    ck(not Prompts.gardenWeek(Prompts.week(now)) or (look.who and State.rec(look.who) ~= nil), "the garden's pick is someone who lives in the garden")
    ck(look.text:find("From your garden", 1, true) ~= nil or look.who == nil, "and says so")
    -- seen outside: ticking the pick stamps their page, unticking takes it away
    reset("spring")
    plant("rose", 4)
    now = T0 + 7 * DAY
    local pick = State.outsideWeek()[1]
    if pick.who then
        ck(State.seenOutside(pick.who) == nil, "not seen outside before the tick")
        State.toggleOutside(1)
        local seen = State.seenOutside(pick.who)
        ck(seen and seen.t == now and seen.n == 1, "ticking the garden's pick marks who was seen outside")
        ck(State.outsideLog()[1].who == pick.who, "and the log says who")
        State.toggleOutside(1)
        ck(State.seenOutside(pick.who) == nil, "unticking takes the mark away")
    else
        ck(false, "a week with the garden's pick for the test")
    end
    -- notes
    reset("spring")
    now = T0
    ck(State.noteOutside(2, "heard a wren") == false, "a note needs a ticked thing")
    State.toggleOutside(2)
    ck(State.noteOutside(2, "  heard a wren  ") and State.outsideWeek()[2].note == "heard a wren" and State.outsideLog()[1].note == "heard a wren", "a note is kept with the tick and in the log")
    ck(State.noteOutside(2, ("x"):rep(300)) and #State.outsideWeek()[2].note == 140, "a note is cut at 140 characters")
    ck(State.noteOutside(2, "") and State.outsideWeek()[2].note == nil, "a blank note takes it away")
    -- firsts: tick one, and a year on the garden says the date
    reset("winter")
    local first_i
    for i = 1, #Prompts.LIST.winter do if Prompts.first("winter", i) then first_i = i break end end
    ck(first_i ~= nil and Prompts.first("winter", 12) == "the first snowdrop or catkin", "some things are firsts to remember the date of")
    local d = State.get()
    d.outside_log = { { t = T0 - 300 * DAY, w = Prompts.week(T0 - 300 * DAY), s = "winter", i = 12 } }
    d.outside_now = { w = Prompts.week(T0), s = "winter", picks = { { i = 1 }, { i = 2 }, { i = 12 } } }
    local item = State.outsideWeek()[3]
    ck(item.first and item.last == T0 - 300 * DAY, "a year on, the thing says when it was last ticked")
    ck(#State.outsideFirsts() == 1 and State.outsideFirsts()[1].label == "the first snowdrop or catkin", "the firsts are listed")
    -- the summary and a thing ticked before the week's things were made
    reset("spring")
    now = T0
    ck(State.outsideSummary().done == 0 and State.outsideSummary().next ~= nil and not State.outsideSummary().full, "a new week has all three to do")
    State.get().outside_now = nil
    State.get().outside_log = { { t = T0, w = Prompts.week(T0), s = "spring", i = 5 } }
    ck(State.outsideWeek()[2].done and State.outsideWeek()[2].i == 5, "a thing ticked before the week was made stays in it")
    ck(State.outsideSummary().done == 1 and State.outsideSummary().next.k == 1, "and the summary counts it")
end

-- ---------------------------------------------------------------- the pictures
group("pictures: every plant in every state")
do
    local Art = require("solarui/gfx/art")
    local GardenView = require("solarui/ui/gardenview")
    local Layout = require("solarui/garden/layout")
    local PHASES = { "night", "morning", "day", "golden" }
    local failed = {}
    local count = 0
    for _, def in ipairs(Cast.PLANTS) do
        local size = Layout.PLANTS[def.id]
        for stage = 1, 5 do
            for _, wilt in ipairs({ false, true }) do
                for _, s in ipairs(SEASONS) do
                    local phase = PHASES[(stage + #s) % 4 + 1]
                    local e = { rec = { stage = stage }, thirst = wilt and "wilted" or "fine", def = def, dormant = s == "winter" and not EVERGREEN[def.id] }
                    local param = GardenView.plantParam(e, false, phase, s, { leaves = 3, ripe = false })
                    local bb = Art.sprite("plant_" .. def.id, 120, math.floor(120 * size.h / size.w), size.w, size.h, param)
                    count = count + 1
                    if not bb then failed[#failed + 1] = def.id .. " " .. param end
                end
            end
        end
        -- every sky phase at bloom, and the pale copy
        for _, phase in ipairs(PHASES) do
            local param = GardenView.plantParam({ rec = { stage = 4 }, thirst = "fine", def = def }, false, phase, "summer")
            if not Art.sprite("plant_" .. def.id, 120, math.floor(120 * size.h / size.w), size.w, size.h, param) then failed[#failed + 1] = def.id .. " " .. param end
            count = count + 1
        end
    end
    ck(#failed == 0, count .. " pictures of plants draw (" .. table.concat(failed, "; ", 1, math.min(#failed, 3)) .. ")")
    for _, def in ipairs(Cast.PLANTS) do
        local size = Layout.PLANTS[def.id]
        local bad = 0
        for stage = 1, 5 do
            local a = Art.sprite("plant_" .. def.id, 120, math.floor(120 * size.h / size.w), size.w, size.h, GardenView.plantParam({ rec = { stage = stage }, thirst = "fine", def = def }, false, "day", "spring"))
            if not a then bad = bad + 1 end
        end
        ck(bad == 0, def.id .. " draws at every stage")
    end
end
group("pictures: every animal in every pose")
do
    local Art = require("solarui/gfx/art")
    local GardenView = require("solarui/ui/gardenview")
    local Layout = require("solarui/garden/layout")
    for _, def in ipairs(Cast.ANIMALS) do
        local size = Layout.ANIMALS[def.id]
        local bad = {}
        for _, pose in ipairs({ "1", "2" }) do
            for _, flip in ipairs({ false, true }) do
                for _, phase in ipairs({ "night", "morning", "day", "golden" }) do
                    local param = GardenView.animalParam(pose, flip, false, phase)
                    if not Art.sprite("animal_" .. def.id, 120, math.floor(120 * size.h / size.w), size.w, size.h, param) then bad[#bad + 1] = param end
                end
            end
        end
        ck(#bad == 0, def.id .. " draws in both poses, both ways, at every hour (" .. table.concat(bad, ",") .. ")")
    end
    -- the tuft, the nest, the peek, the pond, the table and the ground
    local sprites = require("solarui/art/sprites")
    local palette = {}
    for _, role in ipairs({ "ink", "bg", "muted", "line", "soft", "accent", "accent2", "on_accent", "leaf", "stem", "gold", "pale", "bloom", "bloom2", "sky", "sage", "glass", "cream", "violet", "lilac" }) do palette[role] = require("solarui/theme").hex(role, true) end
    local fails = {}
    for _, phase in ipairs({ "night", "morning", "day", "golden" }) do
        for _, weather in ipairs(Weather.KINDS) do
            for _, s in ipairs(SEASONS) do
                local mode = phase .. ":" .. weather .. ":" .. s .. ":edge21.600"
                for _, name in ipairs({ "garden_ground", "garden_tuft", "garden_peek" }) do
                    local ok, svg = pcall(sprites[name], palette, 1072, 1430, mode)
                    if not ok or type(svg) ~= "string" or #svg < 50 then fails[#fails + 1] = name .. " " .. mode end
                end
                local ok, svg = pcall(sprites.garden_tuft, palette, 140, 100, mode .. ":sleep")
                if not ok or type(svg) ~= "string" then fails[#fails + 1] = "nest " .. mode end
            end
        end
    end
    ck(#fails == 0, "the ground, tufts, nests and peeks draw in every sky, weather and season (" .. table.concat(fails, "; ", 1, math.min(#fails, 2)) .. ")")
end

-- ---------------------------------------------------------------- the layout
group("layout: nobody overlaps at any hour, in any season, with any animals")
do
    local Layout = require("solarui/garden/layout")
    local clashes = 0
    for seed = 1, 80 do
        local all = Layout.all(1430, Layout.spread(seed))
        local names = {}
        for id in pairs(all) do names[#names + 1] = id end
        table.sort(names)
        for i = 1, #names do
            local a = all[names[i]]
            for j = i + 1, #names do
                local b = all[names[j]]
                if a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h then clashes = clashes + 1 end
            end
        end
    end
    ck(clashes == 0, "80 different deals never overlap (" .. clashes .. " clashes)")
end

-- ---------------------------------------------------------------- settings
group("clock and season: the garden at any hour, in any season")
do
    local GardenClock = require("solarui/ui/gardenclock")
    ck(GardenClock.following(), "the clock follows the device at first")
    for hour = 0, 23 do
        GardenClock.set(hour)
        ck(not GardenClock.following() and Sky.hour() == hour, "the garden can be shown at " .. hour .. ":00")
    end
    GardenClock.set(nil)
    ck(GardenClock.following(), "and follows the device again")
    for _, s in ipairs(SEASONS) do
        Season.set(s)
        ck(Season.now() == s and not Season.following(), "the garden can be shown in " .. s)
    end
    Season.set(nil)
    ck(Season.following(), "and follows the calendar again")
    Season.setSouth(true)
    ck(Season.south() == true and Season.ofMonth(1, true) == "summer", "the southern hemisphere turns the calendar over")
    Season.setSouth(false)
    ck(Season.south() == false, "and back")
end

-- ---------------------------------------------------------------- persistence
group("the kept garden: saving, loading and the old format")
do
    reset("spring")
    plant("rose", 3)
    State.rename("rose", "Rosie")
    State.save()
    local snapshot = State.get().plants.rose.stage
    State.unload()
    ck(State.get().plants.rose.stage == snapshot and State.get().plants.rose.nick == "Rosie", "a saved garden is the same when loaded again")
    Settings.set("garden", { v = 1, junk = true })
    State.unload()
    local d = State.get()
    ck(d.v == 2 and d.plants.rose and d.animals.bee, "an old format is replaced by a fresh garden")
    ck(State.get().journal and #State.journal() >= 0, "and has a journal")
end

-- ---------------------------------------------------------------- the companion
group("companion for life: all of them")
do
    local Pet = require("solarui/garden/pet")
    local Voice = require("solarui/garden/voice")
    Settings.set("companion_talk", true)
    for _, id in ipairs(ids) do
        reset("spring")
        if Cast.plant(id) then plant(id, 4) else animal(id) end
        ck(Pet.adopt(id, "Pal") and Pet.is(id), id .. " can be the companion")
        local line = Voice.current()
        ck(type(line) == "string" and #line > 5, id .. " says something on home")
        ck(Voice.react() ~= nil, id .. " answers a tap")
        ck(#Voice.beats(id) == 12, id .. " has twelve memories")
        local ctx = Voice.context(Pet.get())
        ck(ctx.left == 3 and ctx.next ~= "", id .. ": three things are left outdoors at first")
        for _, m in ipairs({ "outside_ask", "outside_done", "outside_week" }) do
            ck(Voice.pick(m, ctx, true) ~= nil, id .. " has lines for " .. m)
        end
        State.toggleOutside(1); Pet.outside(false); Voice.current()
        ck(Pet.get().now.moment == "outside_done", id .. " answers a thing ticked outdoors")
        State.toggleOutside(2); State.toggleOutside(3); Pet.outside(true); Voice.current()
        ck(Pet.get().now.moment == "outside_week", id .. " answers a week done outdoors")
        reading.total = 5000
        Pet.refresh(Voice.beats(id))
        ck(Pet.get().level == 5 and Pet.waiting() > 0, id .. " reaches the top of the bond and has things to tell")
        local told = 0
        while Pet.waiting() > 0 and told < 40 do Voice.react(); told = told + 1 end
        ck(Pet.waiting() == 0, id .. " tells everything that waits, one thing at a tap")
        ck(Pet.goodbye() and Pet.remembered(id), id .. " can be said goodbye to")
        ck(not Pet.comeback(id).earned, id .. " cannot come back too soon")
        reading.total = reading.total + Pet.RETURN_PAGES
        now = now + (Pet.RETURN_DAYS + 1) * DAY
        ck(Pet.comeback(id).earned and Pet.comeBack(id) and Pet.is(id) and Pet.get().returns == 1, id .. " comes back once it is earned")
        ck(Voice.say(id, "locked", { name = "Pal", pages = 5, days = 2 }) ~= nil and Voice.say(id, "returned", { name = "Pal" }) ~= nil, id .. " speaks about leaving and returning")
        Pet.goodbye()
    end
end

-- ---------------------------------------------------------------- report
print("")
local total, bad = 0, 0
for _, name in ipairs(order) do
    local g = groups[name]
    total, bad = total + g.n, bad + g.bad
    print(string.format("%-78s %5d checks, %d failed", name, g.n, g.bad))
end
print(string.format("gardenmatrix: %d checks in %d groups, %d failed", total, #order, bad))
if REPORT then
    local f = io.open(REPORT, "w")
    if f then f:write(table.concat(log, "\n"), "\n"); f:close() end
end
Kit.finish("gardenmatrix")
