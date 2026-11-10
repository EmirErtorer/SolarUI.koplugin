-- Home's reading strip in every state worth a look, one under the other on
-- a sheet saved as a PNG: nothing read, a little, streaks of three and
-- seven days, a broken week, many books, the goal reached.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/strip.lua <repo> <out.png> [scheme] [mode]

local REPO, OUT = arg[1] or ".", arg[2] or "/tmp/solarui-strip.png"
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Settings = require("solarui/settings")
if arg[3] then Settings.set("scheme", arg[3]) end
if arg[4] then Settings.set("mode", arg[4]) end
local Art = require("solarui/gfx/art")
local Scene = require("solarui/ui/scene")
local Strip = require("solarui/ui/readingstrip")
local Theme = require("solarui/theme")

local LETTERS = { "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" }

-- Seven days ending on weekday `last` (1 is Sunday), read where `marks` has a 1.
local function week(marks, last)
    local days = {}
    for i = 1, 7 do
        local wday = (last - 7 + i - 1) % 7 + 1
        days[i] = { read = marks:sub(i, i) == "1", wday = wday, letter = LETTERS[wday] }
    end
    return days
end

-- what the row shows, minutes, goal, days read, weekday of today, streak, books
local STATES = {
    { "Nothing yet: 0 min, no day read, no book", 0, 30, "0000000", 3, 0, 0 },
    { "A little: 8 of 30 min, today only, 1 book", 8, 30, "0000001", 3, 1, 1 },
    { "Three days in a row, 18 of 30 min, 4 books", 18, 30, "0000111", 3, 3, 4 },
    { "A broken week: 4 of 7 days, 25 of 30 min, 9 books", 25, 30, "1101001", 6, 1, 9 },
    { "Goal reached: 45 of 30 min, 5 days in a row, 12 books", 45, 30, "0011111", 1, 5, 12 },
    { "A full week: 7 days in a row, 30 of 30 min, 16 books", 30, 30, "1111111", 7, 7, 16 },
    { "Many books: 23 this year, a 12 day streak, 60 of 20 min", 60, 20, "1111111", 4, 12, 23 },
}

local W, ROW = 1072, Strip.HEIGHT + 70
local bb = Kit.canvas(W, ROW * #STATES)
bb:fill(Theme.color("bg"))
for i, s in ipairs(STATES) do
    local d = { minutes = s[2], goal = s[3], days = week(s[4], s[5]), streak = s[6], books = s[7] }
    local ok, err = pcall(function()
        local scene = Scene.make("strip" .. i, W, ROW, ROW)
        scene:caption(s[1], 40, 10, W - 80, "small", "muted")
        Strip.place(scene, 50, d, function() end)
        scene:layout(W, ROW)
        scene:paint(bb, 0, (i - 1) * ROW)
    end)
    Kit.ok(ok, s[1] .. ": " .. tostring(err))
    local _pic, _dx, _dy, cut = Art.sprite("week", 410, 126, 410, 126, s[4] .. "|" .. d.days[1].wday)
    Kit.ok(not cut, "the week of state " .. i .. " is not cut by its canvas")
end

-- every weekday's flower differs from the others, open and closed
local DayFlowers = require("solarui/art/dayflowers")
local seen = {}
local c = setmetatable({}, { __index = function(_t, role) return role end })
for wday = 1, 7 do
    local open, closed = DayFlowers.bloom(c, wday, 0, 0, 20), DayFlowers.bud(c, wday, 0, 0, 20)
    Kit.ok(open ~= closed and not seen[open] and not seen[closed], "weekday " .. wday .. " has a flower and a bud of its own")
    seen[open], seen[closed] = true, true
end

Kit.png(bb, OUT)
print("strip sheet: " .. OUT)
Kit.finish("strip")
