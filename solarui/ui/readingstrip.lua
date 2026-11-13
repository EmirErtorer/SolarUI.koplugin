-- Home's reading strip: today's minutes as a sunflower whose petals turn
-- golden toward the daily goal, the last seven days as a row of weekday
-- flowers (open for a day read, a bud for a day missed) and the year's
-- books as the petals of a water lily. Under each stands its number and a
-- small line saying what the drawing counts.

local Format = require("solarui/format")
local ReadingArt = require("solarui/art/reading")
local Settings = require("solarui/settings")
local Stats = require("solarui/data/stats")
local _ = require("solarui/gettext")

local Strip = {}

-- The strip's height in the scene's units.
Strip.HEIGHT = 262

-- What the strip shows now: { minutes, goal, days = { { read, wday, letter } x 7,
-- oldest first }, streak, books }.
function Strip.data()
    local days = {}
    for i, d in ipairs(Stats.daily(7)) do
        local noon = d.time + 43200
        days[i] = { read = d.seconds > 0, wday = os.date("*t", noon).wday, letter = Format.chars(Format.date("%a", noon), 2) }
    end
    return { minutes = Format.minutes(Stats.today()), goal = Settings.get("daily_goal", 30), days = days,
        streak = Stats.streak(), books = Stats.booksThisYear() }
end

-- A number line and the small line under it, centred on a column.
local function captions(scene, x, y, w, text, sub, sub_color)
    scene:caption(text, x, y, w)
    scene:caption(sub, x, y + 29, w, "micro", sub_color or "muted")
end

-- Put the strip on `scene` with its top at `y`, showing `d` (see Strip.data);
-- a tap anywhere on it calls `on_tap`.
function Strip.place(scene, y, d, on_tap)
    scene:group("home.reading_heading", "Your reading heading", function() scene:heading(_("Your reading"), y) end)
    -- the captions sit close under the drawings (which end at about y + 172, the weekday letters a little lower) and on one line across
    -- the three columns, whatever the drawings above were nudged to
    local base = y + 180

    local reached = d.goal > 0 and d.minutes >= d.goal
    local petals = reached and ReadingArt.PETALS + 1 or math.floor(d.minutes / math.max(1, d.goal) * ReadingArt.PETALS)
    if d.minutes > 0 then petals = math.max(1, petals) end
    scene:group("home.reading_sunflower", "Sunflower and minutes today", function()
        scene:sprite("sunflower", 152, y + 46, 126, 126, petals)
    end)

    local wx, wy, ww, wh = 362, y + 40, 410, 126
    local marks, read = {}, 0
    for i, day in ipairs(d.days) do
        marks[i] = day.read and "1" or "0"
        if day.read then read = read + 1 end
    end
    scene:group("home.reading_week", "Week of flowers and streak", function()
        scene:sprite("week", wx, wy, ww, wh, table.concat(marks) .. "|" .. (d.days[1] and d.days[1].wday or 2))
        for i, s in ipairs(ReadingArt.weekSpots(ww, wh)) do
            local day = d.days[i]
            if day then scene:caption(day.letter, wx + s[1] - 28, wy + s[2] + 1, 56, "micro", i == #d.days and "ink" or "muted") end
        end
    end)

    scene:group("home.reading_lily", "Water lily and books this year", function()
        scene:sprite("lily", 826, y + 44, 140, 130, d.books)
    end)
    -- the three numbers, each under its drawing
    scene:group("home.reading_captions", "Numbers under the drawings", function()
        captions(scene, 90, base, 250, string.format(_("%d min today"), d.minutes),
            reached and _("goal reached") or string.format(_("goal %d min"), d.goal), reached and "accent" or nil)
        captions(scene, wx - 10.8, base, ww, string.format(_.n("%d day in a row", "%d days in a row", d.streak), d.streak),
            string.format(_("read on %d of the last 7 days"), read))
        captions(scene, 770, base, 240, string.format(_.n("%d book this year", "%d books this year", d.books), d.books), _("a petal for each book"))
    end)
    scene:group("home.reading_tap", "Reading strip tap area", function() scene:touch(90, y + 40, 920, Strip.HEIGHT - 40, on_tap) end)
end

return Strip
