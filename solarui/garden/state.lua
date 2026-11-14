-- The garden as it is kept between visits: what is planted and how far it has
-- grown, who has found the garden, the dew earned by reading and the seeds
-- earned by finishing books, nicknames and a short journal. All of it is one
-- table in the settings; `refresh` brings it up to the present (growth,
-- wilting, new visitors) and every action saves at once. Time and the reading
-- numbers come through State.clock and State.source so tests can set them.

local Cast = require("solarui/garden/cast")
local _ = require("solarui/gettext")
local Care = require("solarui/garden/care")
local Progress = require("solarui/garden/progress")
local Prompts = require("solarui/garden/prompts")
local Season = require("solarui/garden/season")
local Settings = require("solarui/settings")
local Sky = require("solarui/garden/sky")
local Visitors = require("solarui/garden/visitors")
local Weather = require("solarui/garden/weather")
local Visits = require("solarui/garden/visits")

local State = {}

State.WATER = 2          -- dew a drink costs
State.FEED = 3           -- dew a meal costs
State.GIFT_DEW = 30
State.GIFT_SEEDS = 2
State.NICK_MAX = 14      -- letters in a nickname
State.JOURNAL_MAX = 80   -- lines the journal keeps
State.RIPEN = 2 * 86400  -- seconds a seed head wants before it is cut back for a full harvest

-- The time now; replaced in tests.
State.clock = os.time

-- How many of the books `list` ({ { date = "YYYY-MM-DD" }, ... }) were
-- finished on or after the day the garden began (`created`, a time); all of
-- them when the garden has no start yet. Books finished before count for nothing.
function State.booksSince(list, created)
    if not created then return #list end
    local since, n = os.date("%Y-%m-%d", created), 0
    for _i, b in ipairs(list) do
        if b.date and b.date >= since then n = n + 1 end
    end
    return n
end

-- The reading numbers { total (pages ever), pages (weekly grid), streak
-- (longest), books (finished), days (dates with reading), year_books (finished
-- this year), goal (books a year, or nil) }; replaced in tests.
function State.source()
    local ok, r = pcall(function()
        local Goal = require("solarui/data/goal")
        local Insights = require("solarui/data/insights")
        local pattern = Insights.pattern()
        local days = {}
        for _i, day in ipairs(Insights.days()) do days[#days + 1] = day.date end
        return { total = Insights.allTime().pages, pages = pattern and pattern.pages or {}, streak = Insights.streaks().day_best, books = #Goal.finished(),
            days = days, year_books = State.booksSince(Goal.finishedIn(tonumber(os.date("%Y"))), State.startedAt()), goal = Goal.target() }
    end)
    return ok and r or { total = 0, pages = {}, streak = 0, books = 0, days = {}, year_books = 0 }
end

local data

-- When the garden began, from the saved garden (nil before there is one).
function State.startedAt()
    local d = data or Settings.get("garden", nil)
    return type(d) == "table" and d.created or nil
end

-- A new garden: every plant in bloom, some a little further on than others,
-- and the three animals that are always there, counting reading from now.
local function fresh()
    local now, reading = State.clock(), State.source()
    local d = { v = 2, created = now, base_pages = reading.total, base_books = reading.books, spent = 0, seeds_used = 0,
        collected = 0, plants = {}, animals = {}, journal = {} }
    for _i, p in ipairs(Cast.PLANTS) do
        local spread = 0
        for i = 1, #p.id do spread = (spread * 31 + p.id:byte(i)) % 50 end
        if not p.find then d.plants[p.id] = { stage = 4, grown = p.need[4] * spread / 100, at = now, watered = now, gen = 1 } end
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

-- Write the garden. `State.version` counts the saves, so a screen can tell
-- whether the garden is the one it drew.
State.version = 0
function State.save()
    State.version = State.version + 1
    Settings.save("garden", State.get())
end

-- Add a line to the journal: what happened ("sown", "sprout", "bud", "bloom",
-- "seedhead", "wilt", "back", "hide", "found") to whom.
local function note(kind, id, with, n)
    local j = State.get().journal
    j[#j + 1] = { t = State.clock(), k = kind, id = id, with = with, n = n }
    while #j > State.JOURNAL_MAX do table.remove(j, 1) end
end

-- Dew in hand: a gift to begin with and a drop for every page read since.
function State.dew()
    local d = State.get()
    return State.GIFT_DEW + math.max(0, State.source().total - d.base_pages) - d.spent + (d.bonus or 0)
end

-- Seeds in hand: a gift, a seed for each book finished since and for each
-- seed head cut back, less the ones used.
function State.seeds()
    local d = State.get()
    return math.floor(State.GIFT_SEEDS + math.max(0, State.source().books - d.base_books) + d.collected - d.seeds_used + 1e-6)
end

-- Books finished since the garden began that have not yet been answered with
-- a gift to the wild edge (see State.giveBack).
function State.owed()
    local d = State.get()
    return math.max(0, State.source().books - d.base_books - (d.given or 0) - (d.passed or 0))
end

-- Answer a finished book: with `yes` leave a seed in the wild edge, which
-- costs nothing and unlocks nothing, only counts as given; otherwise let the
-- moment pass. Does nothing when no finished book is waiting.
function State.giveBack(yes)
    local d = State.get()
    if State.owed() < 1 then return false end
    if yes then d.given = (d.given or 0) + 1; note("gave", "bee") else d.passed = (d.passed or 0) + 1 end
    State.save()
    return true
end

-- How many seeds have been left in the wild edge.
function State.given()
    return State.get().given or 0
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
        local def = Season.adjust(Cast.plant(id))
        for _i, stage in ipairs(Care.grow(rec, def, now)) do
            note(({ "", "sprout", "bud", "bloom", "seedhead" })[stage], id)
            if stage == 5 then rec.seeded = now end
            dirty = true
        end
        local wilted = Care.thirst(rec, def, now) == Care.WILTED
        if wilted ~= (rec.noted == "wilt") then
            if wilted then note("wilt", id) end
            rec.noted, dirty = wilted and "wilt" or nil, true
        end
    end
    for id, rec in pairs(d.animals) do
        if Season.rests(Cast.animal(id), Season.calendar()) then rec.fed, dirty = math.max(rec.fed or 0, now), true end
        local hiding = Care.hunger(rec, Cast.animal(id), now) == Care.HIDING
        if hiding ~= (rec.noted == "hide") then
            if hiding then note("hide", id) end
            rec.noted, dirty = hiding and "hide" or nil, true
        end
    end
    if d.season_seen ~= Season.calendar() then
        if d.season_seen then note("season", "water_lily", Season.calendar()) end
        d.season_seen, dirty = Season.calendar(), true
    end
    if State.rain(now) then dirty = true end
    for _i, p in ipairs(Cast.PLANTS) do
        if p.find and not d.plants[p.id] and Visitors.found(p, Visitors.facts(d.plants, State.source())) then
            d.plants[p.id], dirty = { stage = 1, grown = 0, at = now, watered = now, gen = 1 }, true
            note("planted", p.id)
        end
    end
    if Visits.round(d, now, note) then dirty = true end
    if Visits.thanks(d, now, State.source().total, note) then dirty = true end
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

-- The visitor peeking out of the grass today: the id of one of the animals in
-- the garden, or nil when it was found already today or no animal is here
-- (see Visits.peeker).
function State.peek()
    local d = State.get()
    if d.peek_day == Visits.day(State.clock()) then return nil end
    return Visits.peeker(d, State.clock())
end

-- Spot the visitor: tapping the face in the grass is worth a drop of dew, once
-- a day. Returns the id of the animal found, or false when there was none.
function State.claimPeek()
    local who = State.peek()
    if not who then return false end
    local d = State.get()
    d.peek_day = Visits.day(State.clock())
    d.bonus = (d.bonus or 0) + 1
    note("peek", who)
    State.save()
    return who
end

-- The plants and animals the garden could point at this week (not the animals
-- asleep for the season), in the cast's order.
local function pickable()
    local out, season = {}, Season.now()
    for _i, id in ipairs(Cast.ids()) do
        if State.rec(id) then
            local _e, kind = State.entry(id)
            if not (kind == "animal" and Season.rests(Cast.find(id), season)) then out[#out + 1] = id end
        end
    end
    return out
end

-- When each thing was last offered: what the weeks have recorded, with
-- everything in the log too (a log from before the weeks were kept still counts).
local function offeredWeeks()
    local d = State.get()
    local out = {}
    for k, w in pairs(d.outside_hist or {}) do out[k] = w end
    for _j, e in ipairs(d.outside_log or {}) do
        local key = e.who and ("who:" .. e.who) or (e.s .. ":" .. tostring(e.i))
        if (out[key] or -1) < e.w then out[key] = e.w end
    end
    return out
end

-- The one in the garden the garden points at: someone never seen outdoors
-- first, then whoever was offered longest ago (and among equals a shuffle by
-- the week). Nil when the garden is empty.
local function gardenPick(week, offered)
    local best, best_seen, best_at, best_tie
    for n, id in ipairs(pickable()) do
        local seen = State.seenOutside(id) and 1 or 0
        local at = offered["who:" .. id] or -1
        local tie = (week * 7 + n * 13) % 53
        if not best or seen < best_seen or (seen == best_seen and (at < best_at or (at == best_at and tie < best_tie))) then
            best, best_seen, best_at, best_tie = id, seen, at, tie
        end
    end
    return best
end

-- This week's three things (a table { w, s, picks = { { i } or { who } x 3 } }, made
-- once for the week and kept, so they stay the same all week). A thing already
-- ticked this week stays among them.
local function weekRecord()
    local d = State.get()
    local week, season = Prompts.week(State.clock()), Season.now()
    local cur = d.outside_now
    if cur and cur.w == week and cur.s == season then return cur end
    local offered = offeredWeeks()
    local picks = {}
    for _j, e in ipairs(d.outside_log or {}) do   -- (ticked already this week, before the record was made)
        if e.w == week and e.s == season then
            local kind = e.who and "look" or Prompts.kind(season, e.i)
            for k, name in ipairs(Prompts.KINDS) do
                if name == kind and not picks[k] then picks[k] = e.who and { who = e.who } or { i = e.i }; break end
            end
        end
    end
    for k, kind in ipairs(Prompts.KINDS) do
        if not picks[k] then
            local who = kind == "look" and Prompts.gardenWeek(week) and gardenPick(week, offered) or nil
            if who then picks[k] = { who = who }
            else
                local skip = {}
                for _k, pk in pairs(picks) do if pk.i then skip[pk.i] = true end end
                picks[k] = { i = Prompts.choose(season, week, kind, offered, skip) }
            end
        end
    end
    d.outside_hist = d.outside_hist or {}
    for _k, pk in pairs(picks) do d.outside_hist[pk.who and ("who:" .. pk.who) or (season .. ":" .. tostring(pk.i))] = week end
    d.outside_now = { w = week, s = season, picks = picks }
    State.save()
    return d.outside_now
end

-- The words of a thing the garden points at: the one to look for in the world.
local function gardenText(id)
    local Almanac = require("solarui/garden/almanac")   -- (not at the top: the almanac needs the state)
    local page, name = Almanac.page(id), Cast.find(id).en
    if page and page.look and Almanac.tier(id) >= 3 then return string.format(_("From your garden: %s. %s"), name, page.look) end
    return string.format(_("From your garden: %s. Can you find a real one outdoors this week?"), name)
end

-- The log entry of this week's thing `pk`, or nil.
local function logged(pk, rec)
    for j, e in ipairs(State.get().outside_log or {}) do
        if e.w == rec.w and e.s == rec.s and ((pk.who and e.who == pk.who) or (pk.i and e.i == pk.i)) then return e, j end
    end
    return nil
end

-- When the thing `season`, `i` was last ticked more than a season ago ("last
-- year's date" of a first), as a time, or nil.
local function lastYear(season, i)
    local best
    for _j, e in ipairs(State.get().outside_log or {}) do
        if e.s == season and e.i == i and State.clock() - e.t > 200 * 86400 and (not best or e.t > best) then best = e.t end
    end
    return best
end

-- Who has been seen outdoors, the first time and how often: { t, n } or nil.
function State.seenOutside(id)
    local first, n
    for _j, e in ipairs(State.get().outside_log or {}) do
        if e.who == id then first = math.min(first or e.t, e.t); n = (n or 0) + 1 end
    end
    return first and { t = first, n = n } or nil
end

-- This week's things to do outdoors: a list of { kind, i or who, season, text,
-- done, note, first (what to remember the date of), last (when it was last
-- ticked a year ago) }.
function State.outsideWeek()
    local rec = weekRecord()
    local out = {}
    for k, pk in ipairs(rec.picks) do
        local e = logged(pk, rec)
        local item = { kind = Prompts.KINDS[k], i = pk.i, who = pk.who, season = rec.s, done = e ~= nil, note = e and e.note or nil }
        if pk.who then item.text = gardenText(pk.who)
        else
            item.text = Prompts.text(rec.s, pk.i) or ""
            item.first = Prompts.first(rec.s, pk.i)
            if item.first then item.last = lastYear(rec.s, pk.i) end
        end
        out[#out + 1] = item
    end
    return out
end

-- Tick or untick the `k`th of this week's things (1 to PER_WEEK). A tick is
-- kept in the log with its date; unticking takes it out again. Returns true
-- when it is now ticked.
function State.toggleOutside(k)
    local d = State.get()
    local rec = weekRecord()
    local pk = rec.picks[k]
    if not pk then return false end
    d.outside_log = d.outside_log or {}
    local _e, j = logged(pk, rec)
    if j then
        table.remove(d.outside_log, j)
        State.save()
        return false
    end
    d.outside_log[#d.outside_log + 1] = { t = State.clock(), w = rec.w, s = rec.s, i = pk.i, who = pk.who }
    note("outside", pk.who or "water_lily")
    State.save()
    return true
end

-- Put a line of the reader's own on the `k`th of this week's things when it is
-- ticked (blank takes it away). Returns true when it was kept.
function State.noteOutside(k, text)
    local rec = weekRecord()
    local pk = rec.picks[k]
    local e = pk and logged(pk, rec)
    if not e then return false end
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    e.note = text ~= "" and text:sub(1, 140) or nil
    State.save()
    return true
end

-- Everything ever ticked, newest first: { t, text, note, who }.
function State.outsideLog()
    local out, log = {}, State.get().outside_log or {}
    for j = #log, 1, -1 do
        local e = log[j]
        out[#out + 1] = { t = e.t, text = e.who and gardenText(e.who) or Prompts.text(e.s, e.i) or "", note = e.note, who = e.who }
    end
    return out
end

-- The firsts remembered, newest first: { t, label, note }. Each time one comes
-- round is a line, so the years sit side by side.
function State.outsideFirsts()
    local out, log = {}, State.get().outside_log or {}
    for j = #log, 1, -1 do
        local e = log[j]
        local label = not e.who and Prompts.first(e.s, e.i)
        if label then out[#out + 1] = { t = e.t, label = label, note = e.note } end
    end
    return out
end

-- Where the week stands: { done, total, next (the first thing left, or nil), full }.
function State.outsideSummary()
    local week, done, nxt = State.outsideWeek(), 0, nil
    for k, item in ipairs(week) do
        if item.done then done = done + 1 elseif not nxt then nxt = item; nxt.k = k end
    end
    return { done = done, total = #week, next = nxt, full = done == #week }
end

-- How many things have been done outdoors, and in how many weeks all of that
-- week's things were done: { done, full_weeks, since (time of the first, or nil) }.
function State.outsideTotals()
    local log, weeks = State.get().outside_log or {}, {}
    for _j, e in ipairs(log) do weeks[e.w] = (weeks[e.w] or 0) + 1 end
    local full = 0
    for _w, n in pairs(weeks) do
        if n >= Prompts.PER_WEEK then full = full + 1 end
    end
    return { done = #log, full_weeks = full, since = log[1] and log[1].t or nil }
end

-- What reading has grown: { vine = (see Progress.vine), year = (see Progress.year) }.
function State.progress()
    local reading = State.source()
    return { vine = Progress.vine(State.get().created, reading.days), year = Progress.year(reading.year_books, reading.goal) }
end

-- The garden's weather today (see garden/weather.lua).
function State.weather(now)
    return Weather.of(Visits.day(now or State.clock()), Season.now())
end

-- On a day of rain, once: every plant that needs water gets half a drink (the
-- wait for its next drink grows by half an interval), and the journal says
-- so. Snow is only noted. Returns true when something was written.
function State.rain(now)
    local d = State.get()
    local day = Visits.day(now)
    if d.weather_day == day then return false end
    d.weather_day = day
    local kind = Weather.of(day, Season.now())
    if kind == "rain" then
        for id, rec in pairs(d.plants) do
            local eff = Season.adjust(Cast.plant(id))
            if eff.interval then rec.watered = math.min(now, (rec.watered or now) + eff.interval / 2); rec.noted = nil end
        end
        note("rain", "water_lily")
    elseif kind == "snow" then
        note("snow", "water_lily")
    end
    return true
end

-- Every plant that is planted, in the cast's order: { def, rec, thirst, until }.
function State.plants()
    local out, now = {}, State.clock()
    local season = Season.now()
    for _i, def in ipairs(Cast.PLANTS) do
        local rec = State.get().plants[def.id]
        local eff = Season.adjust(def, season)
        if rec then out[#out + 1] = { def = def, rec = rec, thirst = Care.thirst(rec, eff, now), thirsty_in = Care.untilThirsty(rec, eff, now),
            dormant = Season.dormant(def, season), season = season } end
    end
    return out
end

-- Every animal that has found the garden: { def, rec, mood, here, resting }
-- where `here` says it is about now (the right hour, not hiding and not
-- asleep for the season) and `resting` that it sleeps through this season.
function State.animals(hour)
    local out, now = {}, State.clock()
    hour = hour or Sky.hour()
    local season = Season.now()
    for _i, def in ipairs(Cast.ANIMALS) do
        local rec = State.get().animals[def.id]
        if rec then
            local resting = Season.rests(def, season)
            local mood = resting and Care.CONTENT or Care.hunger(rec, def, now)
            out[#out + 1] = { def = def, rec = rec, mood = mood, resting = resting, season = season,
                here = not resting and mood ~= Care.HIDING and Visitors.about(def, hour) }
        end
    end
    return out
end

-- Has the reader seen the guide to the garden?
function State.guideSeen()
    return State.get().guide_seen == true
end

-- Note that the guide has been seen.
function State.markGuide()
    if State.guideSeen() then return end
    State.get().guide_seen = true
    State.save()
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
    local eff = Season.adjust(def)
    if not eff.interval then return false, "dry" end
    if State.clock() - rec.watered < eff.interval / 2 then return false, "fresh" end
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
-- another generation. `how` says what becomes of the seed heads: "keep" (the
-- default) the seeds are yours, "birds" they are left for the birds, who feed
-- the hungriest animal for free, "scatter" half a seed is yours and the
-- rest falls in the beds, and "share" (the Three Sisters bed's harvest) a
-- seed is yours and the three hungriest animals are fed. Seed heads cut before they have ripened for
-- RIPEN seconds give only half, and a plant the bees and butterflies visited
-- gives one more. Returns true and the seeds gained; false when the plant
-- has not gone to seed.
function State.collect(id, how)
    local d, def = State.get(), Cast.plant(id)
    local rec = d.plants[id]
    local now = State.clock()
    local ripe = not rec or not rec.seeded or now - rec.seeded >= State.RIPEN
    local pollinated = rec and rec.pollinated
    if not rec or not Care.collect(rec, def, now) then return false end
    how = how or "keep"
    local gain = (how == "keep" or how == "share") and 1 or how == "scatter" and .5 or 0
    if not ripe then gain = gain / 2 end
    if pollinated and how ~= "birds" then gain = gain + 1 end
    rec.seeded, rec.pollinated = nil, nil
    d.collected = d.collected + gain
    if how == "birds" then State.feedHungriest() end
    if how == "share" then for _n = 1, 3 do State.feedHungriest() end end
    note(how == "keep" and "back_seeds" or how, id)
    State.save()
    return true, gain
end

-- Feed the animal that has gone longest without a meal, free; returns its id.
function State.feedHungriest()
    local worst, at = nil, math.huge
    local now = State.clock()
    for id, rec in pairs(State.get().animals) do
        if not Season.rests(Cast.animal(id), Season.now()) and (rec.fed or now) < at then worst, at = id, rec.fed or now end
    end
    if worst then Care.feed(State.get().animals[worst], now); State.get().animals[worst].noted = nil end
    return worst
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
