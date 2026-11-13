-- The companion for life: one plant or animal of the garden the reader has
-- taken as their own. The garden keeps caring for them as for everyone; what
-- this adds is a name that stays, a bond that grows with the pages read while
-- they are the companion (and never shrinks), a diary of what they shared, the
-- memories they tell as the bond deepens, and a goodbye that sends them to the
-- orchard, where they are remembered. Everything lives in the garden's saved
-- table (`pet` and `orchard`), so tests can set the time and the reading
-- numbers through State.clock and State.source.

local Settings = require("solarui/settings")
local State = require("solarui/garden/state")
local _ = require("solarui/gettext")

local Pet = {}

-- Pages together at which each level of the bond begins (level 1 on the first day).
Pet.LEVELS = { 0, 40, 150, 400, 900 }
-- The names of the levels.
Pet.LEVEL_NAMES = { _("New friend"), _("Friend"), _("Close friend"), _("Dear friend"), _("Old friend") }
-- Days together that are marked, and streaks of reading days that are praised.
Pet.ANNIVERSARIES = { 7, 30, 100, 200, 365, 730 }
Pet.STREAKS = { 3, 7, 14, 30, 60, 100 }

local DIARY_MAX = 120
local DAY = 86400

-- The companion's record, or nil when there is none.
function Pet.get()
    return State.get().pet
end

-- Is this plant or animal the companion?
function Pet.is(id)
    local p = Pet.get()
    return p ~= nil and p.id == id
end

-- Add a line to the diary: kind ("adopt", "level", "beat", "book", "streak",
-- "days"), the text and when.
function Pet.note(kind, text)
    local p = Pet.get()
    if not p then return end
    p.diary[#p.diary + 1] = { at = State.clock(), kind = kind, text = text }
    while #p.diary > DIARY_MAX do table.remove(p.diary, 1) end
end

-- Take the plant or animal `id`, who is in the garden, as the companion with
-- the name `name` (their own when blank). Returns true, or false and why:
-- "none" (not in the garden), "have" (a companion already), "orchard" (one who said goodbye: they come back through Pet.comeBack).
function Pet.adopt(id, name)
    local e, kind = State.entry(id)
    if not e then return false, "none" end
    if Pet.get() then return false, "have" end
    if Pet.remembered(id) then return false, "orchard" end
    local d, reading, now = State.get(), State.source(), State.clock()
    if name and name ~= "" then State.rename(id, name) end
    d.pet = { id = id, kind = kind, since = now, pages0 = reading.total or 0, books_seen = reading.books or 0, level = 1,
        beats = {}, streaks = {}, days_marked = {}, seen = {}, n = 0, rng = (now % 100000) + #id, diary = {}, events = {}, last_open = now }
    Pet.note("adopt", string.format(_("%s became your companion."), State.name(id)))
    State.save()
    return true
end

-- How many taps teach the way to talk to the companion (the hint on the home card goes after).
Pet.HINTS = 3

-- Count a tap on the companion.
function Pet.tapped()
    local p = Pet.get()
    if not p then return end
    p.taps = (p.taps or 0) + 1
    State.save()
end

-- How many pages have been read since the adoption.
function Pet.pages(reading)
    local p = Pet.get()
    if not p then return 0 end
    reading = reading or State.source()
    return math.max(0, (reading.total or 0) - p.pages0)
end

-- The bond: its level (1 to 5), the pages into this level and the pages the
-- level asks (nil at the top).
function Pet.level(pages)
    pages = pages or Pet.pages()
    local level = 1
    for i, at in ipairs(Pet.LEVELS) do
        if pages >= at then level = i end
    end
    local from, to = Pet.LEVELS[level], Pet.LEVELS[level + 1]
    return level, pages - from, to and (to - from) or nil
end

-- Days together, counting the first as one.
function Pet.days()
    local p = Pet.get()
    if not p then return 0 end
    return math.floor((State.clock() - p.since) / DAY) + 1
end

-- Change their name (the garden's nickname, kept for them).
function Pet.rename(text)
    local p = Pet.get()
    if p then State.rename(p.id, text) end
end

-- Add an event for the voice to tell (a level reached, a memory, a book).
local function event(p, kind, extra)
    if not Pet.talks() then return end
    local e = extra or {}
    e.kind = kind
    p.events[#p.events + 1] = e
end

-- Does the companion talk? (a setting, on by default: some readers prefer
-- a companion without written dialogue)
function Pet.talks()
    return Settings.get("companion_talk", true)
end

-- How many things wait to be told (a memory, a level, a book, a streak).
function Pet.waiting()
    local p = Pet.get()
    return p and Pet.talks() and #p.events or 0
end

-- A short text that changes when anything Pet.refresh keeps changes.
local function stamp(p)
    local n = 0
    for _k in pairs(p.beats) do n = n + 1 end
    for _k in pairs(p.streaks) do n = n + 1 end
    for _k in pairs(p.days_marked) do n = n + 1 end
    return table.concat({ p.level, #p.diary, #p.events, p.books_seen, n }, ":")
end

-- Bring the bond up to date: new levels, memories (`beats`: { { id, at, title,
-- text } } from the voice), books finished, streaks and days together each
-- become a diary line and an event for the voice. Call when the home screen is built.
function Pet.refresh(beats)
    local p = Pet.get()
    if not p then return end
    local reading, now = State.source(), State.clock()
    local before = stamp(p)
    local pages = Pet.pages(reading)
    local level = Pet.level(pages)
    if level > p.level then
        for l = p.level + 1, level do
            Pet.note("level", string.format(_("The bond reached level %d: %s."), l, Pet.LEVEL_NAMES[l]))
            event(p, "level", { level = l })
        end
        p.level = level
    end
    for _i, b in ipairs(beats or {}) do
        if not p.beats[b.id] and pages >= b.at then
            p.beats[b.id] = now
            Pet.note("beat", b.title)
            event(p, "beat", { id = b.id })
        end
    end
    local books = reading.books or 0
    if books > p.books_seen then
        p.books_seen = books
        event(p, "book")
        Pet.note("book", _("A book was finished together."))
    end
    for _i, s in ipairs(Pet.STREAKS) do
        if (reading.streak or 0) >= s and not p.streaks[s] then
            p.streaks[s] = now
            Pet.note("streak", string.format(_.n("%d day of reading in a row.", "%d days of reading in a row.", s), s))
            event(p, "streak", { days = s })
        end
    end
    local days = Pet.days()
    for _i, a in ipairs(Pet.ANNIVERSARIES) do
        if days >= a and not p.days_marked[a] then
            p.days_marked[a] = now
            Pet.note("days", string.format(_("%d days together."), a))
            event(p, "anniversary", { days = a })
        end
    end
    if stamp(p) ~= before then State.save() end
end

-- Say goodbye: the companion goes to the orchard, where they stay in the
-- garden and are remembered. Returns false when there is no companion.
function Pet.goodbye()
    local d, p = State.get(), Pet.get()
    if not p then return false end
    d.orchard = d.orchard or {}
    d.orchard[#d.orchard + 1] = { id = p.id, kind = p.kind, name = State.name(p.id), since = p.since, left = State.clock(), pages = Pet.pages(),
        days = Pet.days(), level = p.level, diary = p.diary, beats = p.beats, total = State.source().total or 0, returns = p.returns }
    d.pet = nil
    State.save()
    return true
end

-- Has `id` been a companion who is now in the orchard?
function Pet.remembered(id)
    for _i, o in ipairs(State.get().orchard or {}) do
        if o.id == id then return true end
    end
    return false
end

-- What a companion who said goodbye asks before they come back: pages read and
-- days passed since they left.
Pet.RETURN_PAGES = 250
Pet.RETURN_DAYS = 7

-- The orchard entry of `id`, or nil.
local function orchardEntry(id)
    for i, o in ipairs(State.get().orchard or {}) do
        if o.id == id then return o, i end
    end
end

-- How far the reader is from earning the return of `id`: { pages_left,
-- days_left, earned } (nil when they are not in the orchard).
function Pet.comeback(id)
    local o = orchardEntry(id)
    if not o then return nil end
    local read = math.max(0, (State.source().total or 0) - (o.total or State.source().total or 0))
    local days = math.floor((State.clock() - o.left) / DAY)
    local pages_left, days_left = math.max(0, Pet.RETURN_PAGES - read), math.max(0, Pet.RETURN_DAYS - days)
    return { pages_left = pages_left, days_left = days_left, earned = pages_left == 0 and days_left == 0, name = o.name }
end

-- Take `id` back from the orchard as the companion, with their bond, memories
-- and diary as they were. Returns true, or false and why: "have" (a companion
-- already), "none" (not in the orchard), "earn" (not earned yet).
function Pet.comeBack(id)
    if Pet.get() then return false, "have" end
    local o, i = orchardEntry(id)
    if not o then return false, "none" end
    if not Pet.comeback(id).earned then return false, "earn" end
    local d, reading, now = State.get(), State.source(), State.clock()
    table.remove(d.orchard, i)
    local marked = {}
    for _i, a in ipairs(Pet.ANNIVERSARIES) do if a <= o.days then marked[a] = now end end
    d.pet = { id = id, kind = o.kind, since = now - o.days * DAY, pages0 = (reading.total or 0) - o.pages, books_seen = reading.books or 0,
        level = o.level, beats = o.beats or {}, streaks = {}, days_marked = marked, seen = {}, n = 0, rng = (now % 100000) + #id,
        diary = o.diary or {}, events = {}, last_open = now, returns = (o.returns or 0) + 1 }
    Pet.note("return", string.format(_("%s came back to you."), State.name(id)))
    State.save()
    return true
end

-- Everyone who lives in the orchard now, oldest first.
function Pet.orchard()
    return State.get().orchard or {}
end

return Pet
