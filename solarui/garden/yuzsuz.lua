-- Yüzsüz The Magnificent: what makes the queen of the garden unlike everyone
-- else in it. She was here before the garden and never hides; hungry, she
-- demands. Her left side takes up to a hundred and forty pats in a session,
-- her right side three, and the fourth is answered with teeth. She takes
-- belly rubs until, at a moment only she knows, she decides you deserve
-- death. She eats from a menu, salami first. And she chooses her own pose
-- through the day, her tail moving all the while: asleep at night, glaring
-- when hungry, chattering when the robin is about, and staring at her spot
-- for hours. A session is a run of touches with no gap of half an hour.
-- Everything is a plain function of the time and a random source, which
-- tests can set.

local State = require("solarui/garden/state")
local _ = require("solarui/gettext")

local Yuzsuz = {}

Yuzsuz.ID = "yuzsuz"
Yuzsuz.LEFT_MAX = 140
Yuzsuz.RIGHT_MAX = 3
Yuzsuz.SESSION = 30 * 60
Yuzsuz.HOLD = 90   -- seconds a pose she was put in by a touch stays

-- What she eats, best first. Salami is her favourite thing in the universe.
Yuzsuz.FOODS = {
    { id = "salami", label = _("Salami"), sub = _("her favourite") },
    { id = "kebab", label = _("Kebab") },
    { id = "chicken", label = _("Chicken") },
    { id = "mince", label = _("Minced meat") },
    { id = "cheese", label = _("Cheese") },
    { id = "yogurt", label = _("Yogurt") },
}

-- The counts of left pats that she remarks on.
local MILESTONES = { [1] = true, [10] = true, [25] = true, [50] = true, [77] = true, [100] = true, [120] = true, [139] = true }

local session, forced
local random = math.random

-- Use `fn` (returning 0 to 1) as the random source, or math.random again.
function Yuzsuz.useRandom(fn)
    random = fn or math.random
end

-- Forget the session and any pose she was put in (for tests).
function Yuzsuz.reset()
    session, forced = nil, nil
end

-- Is `id` her?
function Yuzsuz.is(id)
    return id == Yuzsuz.ID
end

-- How many rubs she allows this time: a secret between two and nine.
local function rubLimit()
    return 2 + math.floor(random() * 8)
end

-- The touches of this session, a new one after half an hour without any.
function Yuzsuz.session()
    local now = State.clock()
    if not session or now - session.at > Yuzsuz.SESSION then
        session = { left = 0, right = 0, rubs = 0, limit = rubLimit(), at = now, said = {} }
    end
    session.at = now
    return session
end

-- Add one to a count kept with her for good (pats, bites, rubs, meals).
local function count(key)
    local rec = State.rec(Yuzsuz.ID)
    if not rec then return 0 end
    rec[key] = (rec[key] or 0) + 1
    State.save()
    return rec[key]
end

-- Put her in `pose` for a little while, after a touch.
local function show(pose)
    forced = { pose = pose, at = State.clock() }
end

-- Pat her left side. Returns the moment to answer with and the count.
function Yuzsuz.patLeft()
    local s = Yuzsuz.session()
    if s.left >= Yuzsuz.LEFT_MAX then show("walk"); return "pat_left_over", s.left end
    s.left = s.left + 1
    count("pats")
    if s.left == Yuzsuz.LEFT_MAX then show("walk"); return "pat_left_done", s.left end
    show("butt")
    if MILESTONES[s.left] then return "pat_left_milestone", s.left end
    return "pat_left", s.left
end

-- Pat her right side: three are allowed; the fourth draws blood.
function Yuzsuz.patRight()
    local s = Yuzsuz.session()
    s.right = s.right + 1
    if s.right > Yuzsuz.RIGHT_MAX then
        s.right = 0
        count("bites")
        State.mark("bite", Yuzsuz.ID)
        show("bite")
        return "pat_right_bite", Yuzsuz.RIGHT_MAX + 1
    end
    show("butt")
    return "pat_right_" .. s.right, s.right
end

-- Rub her belly, until she decides you deserve death.
function Yuzsuz.rub()
    local s = Yuzsuz.session()
    s.rubs = s.rubs + 1
    count("rubs")
    if s.rubs > s.limit then
        s.rubs, s.limit = 0, rubLimit()
        count("bites")
        State.mark("bite", Yuzsuz.ID)
        show("bite")
        return "rub_bite", s.limit
    end
    show("belly")
    return "rub", s.rubs
end

-- She has been fed `food` (an id of FOODS): show her eating.
function Yuzsuz.ate(food)
    count("meals")
    show("eat")
    return "food_" .. food
end

-- Every pose she has (see art/animals_yuzsuz.lua).
Yuzsuz.POSES = { "sit", "loaf", "walk", "slouch", "sleep", "belly", "glare", "chatter", "stare", "bite", "eat", "lizard", "butt", "throne",
    "sprint", "play", "hiss" }

-- A tap on her picture: a pose chosen at random, never the one she is in
-- (`prev`, "loaf.b"...), with her tail somewhere new. She stays in it while a
-- touch's pose holds. Returns the pose.
function Yuzsuz.shuffle(prev)
    local was = tostring(prev or ""):match("^([%w_]+)")
    if forced and State.clock() - forced.at < Yuzsuz.HOLD then was = forced.pose:match("^([%w_]+)") end
    local name
    repeat name = Yuzsuz.POSES[1 + math.floor(random() * #Yuzsuz.POSES) % #Yuzsuz.POSES] until name ~= was
    local pose = name .. "." .. ({ "a", "b", "c" })[1 + math.floor(random() * 3) % 3]
    show(pose)
    return pose
end

-- The pose she was put in by a touch, while it holds, else `pose`.
function Yuzsuz.shown(pose)
    if forced and State.clock() - forced.at < Yuzsuz.HOLD then return forced.pose end
    return pose
end

-- How many times she has bitten, and drawn blood (a count kept for good).
function Yuzsuz.bites()
    local rec = State.rec(Yuzsuz.ID)
    return rec and rec.bites or 0
end

-- Choose one name from a weighted list { name, weight, ... }.
local function weigh(list)
    local total = 0
    for i = 2, #list, 2 do total = total + list[i] end
    local r = random() * total
    for i = 1, #list, 2 do
        r = r - list[i + 1]
        if r <= 0 then return list[i] end
    end
    return list[1]
end

-- The poses of a day with nothing in particular going on, and how likely each is.
local DAY = { "loaf", 14, "sit", 9, "stare", 14, "slouch", 8, "walk", 7, "belly", 7, "sleep", 9, "butt", 4, "throne", 6, "lizard", 4, "play", 3,
    "sprint", 3, "hiss", 2 }
local NIGHT = { "sleep", 10, "belly", 4, "loaf", 4, "stare", 2 }
local HUNGRY = { "glare", 10, "walk", 5, "sit", 3, "hiss", 1 }
local TAILS = { a = "b", b = "c", c = "a" }

-- Her next pose after `prev` ("loaf.b"...), for ctx { phase (of the sky),
-- mood ("content", "hungry" or "hiding"), robin (the robin is about) }. Her
-- tail always moves on; a stare goes on and on; a burst of play or a sprint
-- ends in a loaf, because she is lazy.
function Yuzsuz.next(prev, ctx)
    ctx = ctx or {}
    local name, t = tostring(prev or "loaf.a"):match("^([%w_]+)%.?(%a?)$")
    local tail = TAILS[t] or "a"
    local pose
    if name == "stare" and random() < .75 then pose = "stare"
    elseif name == "play" or name == "sprint" then pose = random() < .7 and "loaf" or "sleep"
    elseif ctx.mood == "hungry" or ctx.mood == "hiding" then pose = weigh(HUNGRY)
    elseif ctx.phase == "night" then pose = weigh(NIGHT)
    elseif ctx.robin and random() < .3 then pose = "chatter"
    else pose = weigh(DAY) end
    if (name == "sleep" or name == "belly") and pose == name and random() < .5 then pose = name end
    return pose .. "." .. tail
end

-- Her pose for a still picture (home, the sleep picture): asleep at night,
-- glaring when hungry, else one for the day of the year.
function Yuzsuz.still(ctx)
    ctx = ctx or {}
    if ctx.mood == "hungry" or ctx.mood == "hiding" then return "glare" end
    if ctx.phase == "night" then return "sleep" end
    local day = { "loaf", "sit", "throne", "slouch", "stare", "belly" }
    return day[(tonumber(os.date("%j", State.clock())) or 1) % #day + 1]
end

return Yuzsuz
