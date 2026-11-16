-- The README's screenshots, in the Garden scheme, light: run with
--   tools/readme/shots.sh  (into assets/screenshots)
local H = ...
local S = 1.5
local Settings = require("solarui/settings")
local UIManager = require("ui/uimanager")
local repo = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/tools/readme/[^/]+$")
local K = dofile(repo .. "/tests/e2e/gardenkit.lua")(H)
local Cast = require("solarui/garden/cast")

-- close any notice another plugin has put on screen, then take the shot
local function shot(name)
    local InfoMessage = require("ui/widget/infomessage")
    for _i, w in ipairs(UIManager._window_stack) do
        if getmetatable(w.widget) == InfoMessage then UIManager:close(w.widget) end
    end
    UIManager:forceRePaint()
    H.shot(name)
end

-- the look the README shows and a book well under way
H.step(2, function()
    for k, v in pairs({ scheme = "garden", mode = "light", cover_size = "m", home_companion = "yuzsuz", companion_talk = true }) do Settings.set(k, v) end
    require("solarui/theme").refresh()
    local cur = require("solarui/data/history").current()
    if cur then
        local ds = require("docsettings"):open(cur.path)
        ds:saveSetting("percent_finished", 0.38)
        local summary = ds:readSetting("summary") or {}
        summary.status = "reading"
        ds:saveSetting("summary", summary)
        ds:flush()
        require("solarui/data/books").forget(cur.path)
    end
    -- five books finished this year, for the goal tree's apples and its shelf
    local year = os.date("%Y")
    local done = 0
    for i, item in ipairs(require("solarui/data/history").recent(20)) do
        if i > 2 and done < 5 then
            local ds = require("docsettings"):open(item.path)
            ds:saveSetting("percent_finished", 1)
            ds:saveSetting("summary", { status = "complete", modified = string.format("%s-%02d-%02d", year, 2 + done * 2, 10 + done) })
            ds:flush()
            require("solarui/data/books").forget(item.path)
            done = done + 1
        end
    end
    Settings.set("year_goal", 8)
    H.app().open("library")   -- (has KOReader read the books' covers and details)
end)
-- a garden with everyone in it: every animal found and every plant in bloom, summer, noon
H.step(30, function()
    for _i, b in ipairs(require("solarui/data/library").all()) do require("solarui/data/books").forget(b) end
    require("solarui/data/covers").forget()
    K.reset({ season = "summer", hour = 11, weather = "clear", total = 3200, streak = 9, books = 6, year_books = 18 })
    K.everyone()
    local State = require("solarui/garden/state")
    for _i, p in ipairs(Cast.PLANTS) do
        local d = State.get()
        d.plants[p.id] = d.plants[p.id] or { stage = 4, grown = 0, at = K.t, watered = K.t, gen = 1 }
    end
    K.plants(4, "fine")
    K.animals("content")
    K.settle()
    H.app().go("home")
end)
H.step(4, function() H.app().render("full"); shot("01-home") end)
H.step(S, function() H.app().push("garden") end)
H.step(2, function()
    local g = H.app().current()
    g.showcase = true   -- (every animal at once, the night ones too)
    H.app().update()
end)
H.step(2.5, function() shot("02-garden") end)
H.step(.5, function()
    local g = H.app().current()
    g.showcase = false
    if g.guide_timer then UIManager:unschedule(g.guide_timer); g.guide_timer = nil end
    g.focus = "yuzsuz"
    H.app().update()
end)
H.step(2.5, function() shot("03-yuzsuz") end)
H.step(S, function() H.app().current().focus = nil; H.app().go("library") end)
H.step(4, function() shot("04-library") end)
H.step(S, function() H.app().go("home"); H.app().push("inkshelf") end)
H.step(18, function() shot("05-notebooks") end)
-- the garden's book open on its own lines (no book's text in the README)
H.step(S, function() H.app().go("home"); H.app().push("garden") end)
H.step(2, function()
    local g = H.app().current()
    if g.guide_timer then UIManager:unschedule(g.guide_timer); g.guide_timer = nil end
    g.showcase = false
    g.part = "garden"
    g.focus = "book"
    H.app().update()
end)
H.step(3, function() shot("06-garden-book") end)
H.step(S, function() H.app().go("history") end)
H.step(3, function() shot("07-log"); H.app().current().tab = "goal"; H.app().update() end)
H.step(3, function() shot("08-goal") end)
H.step(S, function() H.app().go("settings") end)
H.step(3, function() shot("09-settings") end)
