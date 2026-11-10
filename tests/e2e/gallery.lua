-- A shot of every area the garden ornaments touched: home, the library with
-- its rails, details, empty pages, the log charts, the goal tree, settings,
-- the keyboard, dialogs and the flower chooser.
local H = ...
local S = 0.9

local function shot(name, fn)
    H.step(S, function() if fn then fn() end end)
    H.step(S, function() H.check(H.onTop(), name .. ": SolarUI stays on top"); H.shot(name) end)
end

local function book()
    local cur = require("solarui/data/history").current()
    return cur and cur.path
end

shot("01-home")
shot("02-library", function() H.app().go("library") end)
shot("03-details", function() H.app().push("dossier", { path = book() }) end)
shot("04-highlights-empty", function() H.app().push("annotations", { path = book(), kind = "highlights" }) end)
shot("05-bookmarks-empty", function() H.app().pop(); H.app().push("annotations", { path = book(), kind = "bookmarks" }) end)
shot("06-log", function() H.app().go("history") end)
H.step(S, function() H.tap("Streaks") end)
shot("07-streaks")
H.step(S, function() H.tap("Calendar") end)
shot("08-calendar")
H.step(S, function() H.tap("Goal") end)
shot("09-goal")
shot("10-collections-empty", function() H.app().go("collections") end)
H.step(S, function() H.tap("Series") end)
shot("11-series-empty")
shot("12-settings-covers", function() H.app().go("settings") end)
H.step(S, function() H.tap("Covers") end)
shot("13-settings-covers")
H.step(S, function() H.tap("Home") end)
shot("14-settings-home")
shot("15-trash-empty", function() H.app().push("trash") end)
shot("16-flowers", function() H.app().pop(); H.app().push("flowerpick", { current = "dock_library", on_pick = function() end }) end)
shot("17-confirm", function() H.app().pop(); H.app().confirm({ title = "Leave the library?", text = "Nothing will be lost.", ok = "Leave" }) end)
H.step(S, function() H.tap("Cancel") end)
shot("18-search", function() H.app().push("search") end)
