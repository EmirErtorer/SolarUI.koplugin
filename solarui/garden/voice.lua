-- What the companion says. Each plant and animal has a voice of their own
-- (garden/voices/<id>.lua; the ones not written yet use a plain voice): lines
-- by moment, some of them only for a time of day, a season, the weather, a
-- level of the bond or a reading streak, and a list of memories told as the
-- bond deepens. This picks the line for now, and never one that was said
-- recently: each companion remembers the last lines they said, so a voice
-- with plenty of lines does not repeat itself for weeks.
--
-- A line is a text or { t = text, when = { hour, season, weather, level,
-- max_level, streak, pages, no_pages, book, quote, away, after } }. In
-- the text, {name} {book} {author} {last} {pages} {total} {days} {streak}
-- {quote} stand for what they are, and [a|b|c] stands for one of its parts.

local Pet = require("solarui/garden/pet")
local Season = require("solarui/garden/season")
local Sky = require("solarui/garden/sky")
local State = require("solarui/garden/state")

local Voice = {}

-- How many lines a companion remembers having said.
Voice.MEMORY = 48
-- The moments that tell something that waited (they are held a few hours when told).
local EVENTS = { beat = true, level = true, finished = true, streak = true, anniversary = true }

-- How long a line stays on the home screen before another is chosen, in seconds.
Voice.HOLD = 3 * 3600

-- The voice of the plant or animal `id`: its own file, else the plain voice for plants or for animals.
function Voice.of(id)
    local ok, v = pcall(require, "solarui/garden/voices/" .. id)
    if ok and type(v) == "table" then return v end
    local _e, kind = State.entry(id)
    local ok2, plain = pcall(require, "solarui/garden/voices/_" .. (kind == "plant" and "plant" or "animal"))
    return ok2 and plain or { moments = {}, beats = {} }
end

-- The memories of the companion `id`.
function Voice.beats(id)
    return Voice.of(id).beats or {}
end

-- A number from the companion's own generator (kept with them, so a saved
-- garden gives the same lines in the same order).
local function roll(p, n)
    p.rng = (p.rng * 1103515245 + 12345) % 2147483648
    return math.floor(p.rng / 65536) % n + 1
end

-- What is true now, for lines that ask: { hour, season, weather, level, streak,
-- pages (read today), book (a book is open) and the numbers and names the text may use }.
function Voice.context(p)
    local ok, ctx = pcall(function()
        local Stats = require("solarui/data/stats")
        local History = require("solarui/data/history")
        local Books = require("solarui/data/books")
        local Goal = require("solarui/data/goal")
        local today = Stats.daily(1)
        local cur = History.current()
        local info = cur and Books.info(cur.path) or {}
        local done = Goal.finished()
        local last = done[#done]
        local last_info = last and Books.info(last.path or last) or {}
        return { pages_today = today and today[1] and today[1].pages or 0, streak = Stats.streak(), book = info.title, author = info.author,
            last = last_info.title, goal_reached = (today and today[1] and today[1].seconds or 0) >= (require("solarui/settings").get("daily_goal", 30)) * 60 }
    end)
    ctx = ok and ctx or { pages_today = 0, streak = 0 }
    local hour = tonumber(os.date("%H", State.clock())) or 12
    local reading = State.source()
    ctx.hour, ctx.season, ctx.weather = Sky.phase(hour), Season.now(), State.weather()
    ctx.level, ctx.total, ctx.days = p.level, Pet.pages(reading), Pet.days()
    ctx.name = State.name(p.id)
    ctx.hour_number = hour
    -- a passage the reader highlighted, cut at a word, for lines that quote
    local okq, q = pcall(function() return require("solarui/garden/plaque").deal(p.id .. os.date("%j", State.clock()))[1] end)
    if okq and q and q.text and q.text ~= "" then
        local t = q.text
        if #t > 110 then
            t = require("solarui/utf8safe").clean(t:sub(1, 110))
            t = t:gsub("%s+%S*$", "") .. "..."
        end
        ctx.quote = t
        ctx.quote_title = q.title
    end
    ctx.away = math.floor((State.clock() - (p.last_open or State.clock())) / 86400)
    return ctx
end

-- Does a line's `when` hold now?
local function holds(when, ctx)
    if not when then return true end
    local function is(want, have)
        if type(want) == "table" then
            for _i, w in ipairs(want) do if w == have then return true end end
            return false
        end
        return want == have
    end
    if when.hour and not is(when.hour, ctx.hour) then return false end
    if when.season and not is(when.season, ctx.season) then return false end
    if when.weather and not is(when.weather, ctx.weather) then return false end
    if when.level and ctx.level < when.level then return false end
    if when.max_level and ctx.level > when.max_level then return false end
    if when.streak and ctx.streak < when.streak then return false end
    if when.pages and ctx.pages_today < when.pages then return false end
    if when.no_pages and ctx.pages_today > 0 then return false end
    if when.book and not ctx.book then return false end
    if when.quote and not ctx.quote then return false end
    if when.away and ctx.away < when.away then return false end
    if when.after and ctx.hour_number < when.after then return false end
    return true
end

-- The text of a line with its [a|b|c] parts chosen and its {words} filled in.
local function fill(text, ctx, p)
    text = text:gsub("%[([^%]]-)%]", function(set)
        local parts = {}
        for part in (set .. "|"):gmatch("(.-)|") do parts[#parts + 1] = part end
        return parts[roll(p, #parts)]
    end)
    text = text:gsub("{(%w+)}", function(k)
        local v = ctx[k]
        if v == nil then return "" end
        return tostring(v)
    end)
    -- (one page, not "1 pages")
    return (text:gsub("%f[%d]1 pages", "1 page"))
end

-- Has this line been said lately?
local function said(p, key)
    for _i, k in ipairs(p.seen) do if k == key then return true end end
    return false
end

-- Remember a line as said.
local function remember(p, key)
    p.seen[#p.seen + 1] = key
    while #p.seen > Voice.MEMORY do table.remove(p.seen, 1) end
end

-- A line of this moment for now: { text, key } or nil when the voice has none
-- that holds. Lines said lately are left out while others remain, and lines
-- with a condition are twice as likely as plain ones, so the day's own
-- circumstances come through. `peek` leaves the line unremembered.
function Voice.pick(moment, ctx, peek)
    local p = Pet.get()
    if not p then return nil end
    local pool = Voice.of(p.id).moments[moment]
    if not pool or #pool == 0 then pool = Voice.of("_" .. (p.kind == "plant" and "plant" or "animal")).moments[moment] end
    if not pool then return nil end
    local fresh, any = {}, {}
    for i, line in ipairs(pool) do
        local text = type(line) == "table" and line.t or line
        local when = type(line) == "table" and line.when or nil
        if holds(when, ctx) then
            local key = moment .. ":" .. i
            local item = { text = text, key = key, weight = when and 2 or 1 }
            any[#any + 1] = item
            if not said(p, key) then fresh[#fresh + 1] = item end
        end
    end
    local from = #fresh > 0 and fresh or any
    if #from == 0 then return nil end
    local total = 0
    for _i, it in ipairs(from) do total = total + it.weight end
    local at, chosen = roll(p, total), from[1]
    for _i, it in ipairs(from) do
        at = at - it.weight
        if at <= 0 then chosen = it break end
    end
    if not peek then remember(p, chosen.key) end
    return { text = fill(chosen.text, ctx, p), key = chosen.key }
end

-- A text of the voice (a memory) with its words filled in for now.
function Voice.render(text)
    local p = Pet.get()
    if not p then return text end
    return fill(text, Voice.context(p), p)
end

-- The memory with this id of the companion's voice, or nil.
function Voice.beat(id)
    local p = Pet.get()
    if not p then return nil end
    for _i, b in ipairs(Voice.beats(p.id)) do
        if b.id == id then return b end
    end
    return nil
end

-- The next thing waiting to be told (a memory, a level, a finished book, a
-- streak, an anniversary) as { text, moment }, taking it from the waiting
-- list, or nil.
local function pending(p, ctx)
    local e = table.remove(p.events, 1)
    if not e then return nil end
    if e.kind == "beat" then
        local b = Voice.beat(e.id)
        if b then return { text = fill(b.text, ctx, p), moment = "beat", title = b.title } end
        return pending(p, ctx)
    end
    ctx.streak_days = e.days
    if e.days then ctx.days, ctx.streak = e.days, e.days end
    local moment = ({ level = "level", book = "finished", streak = "streak", anniversary = "anniversary" })[e.kind]
    if e.level then ctx.level = e.level end
    local line = moment and Voice.pick(moment, ctx)
    if line then return { text = line.text, moment = moment } end
    return pending(p, ctx)
end

-- The line to show on the home screen: what waits to be told first, then a
-- greeting at the first visit of a day, a welcome after days away, praise for
-- the day's goal, and otherwise a line about the reading, the book or the moment.
-- It stays for a few hours (or until the reading changes) so the card does not flicker.
-- Returns the text.
function Voice.current()
    local p = Pet.get()
    if not p then return nil end
    local now = State.clock()
    local ctx = Voice.context(p)
    local key = table.concat({ os.date("%Y%m%d", now), ctx.pages_today, ctx.goal_reached and 1 or 0 }, ":")
    if p.now then
        -- a tap is answered for a moment, and what was told (a memory, a level) stays its few hours
        -- before the next waiting thing is told, so the visits do not use them up at once
        local age = now - p.now.at
        if p.now.moment == "tap" and age < 120 then return p.now.text end
        if EVENTS[p.now.moment] and age < Voice.HOLD then return p.now.text end
        if p.now.key == key and age < Voice.HOLD and #p.events == 0 then return p.now.text end
    end
    local chosen = pending(p, ctx)
    local day = os.date("%Y%m%d", now)
    local first = p.day ~= day
    if not chosen and first then
        local away = ctx.away >= 3 and Voice.pick("welcome_back", ctx)
        chosen = away and { text = away.text, moment = "welcome_back" } or nil
        if not chosen then
            local g = Voice.pick("greet", ctx)
            chosen = g and { text = g.text, moment = "greet" } or nil
        end
    end
    if not chosen and ctx.goal_reached and p.goal_day ~= day then
        local g = Voice.pick("goal", ctx)
        if g then chosen = { text = g.text, moment = "goal" }; p.goal_day = day end
    end
    if not chosen then
        -- a moment by what is true now, the idle lines among them
        local moments = { "idle", "idle" }
        if ctx.pages_today > 0 then moments[#moments + 1] = "read_today" else moments[#moments + 1] = "nudge" end
        if ctx.book then moments[#moments + 1] = "book_now" end
        local order = {}
        local start = roll(p, #moments)
        for i = 0, #moments - 1 do order[#order + 1] = moments[(start + i - 1) % #moments + 1] end
        for _i, m in ipairs(order) do
            local l = Voice.pick(m, ctx)
            if l then chosen = { text = l.text, moment = m } break end
        end
    end
    p.day, p.last_open = day, now
    if chosen then p.now = { text = chosen.text, moment = chosen.moment, key = key, at = now } end
    State.save()
    return chosen and chosen.text or nil
end

-- A reaction to a tap: a new line each time.
function Voice.react()
    local p = Pet.get()
    if not p then return nil end
    local ctx = Voice.context(p)
    local line = Voice.pick("tap", ctx)
    if line then
        p.now = { text = line.text, moment = "tap", key = "tap", at = State.clock() }
        State.save()
        return line.text
    end
    return nil
end

return Voice
