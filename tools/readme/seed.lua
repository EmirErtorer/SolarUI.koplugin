-- What the README's screenshots and moving pictures start from: the Garden
-- scheme, light, covers size M, a book well under way, five finished this
-- year, and a garden with everyone in it (every animal found, every plant in
-- bloom, summer, before noon). Adds the steps to the scenario; returns the
-- garden kit (tests/e2e/gardenkit.lua) for scenes that change the garden.
--   local K = dofile(repo .. "/tools/readme/seed.lua")(H, repo)

return function(H, repo)
    local Settings = require("solarui/settings")
    local Cast = require("solarui/garden/cast")
    local K = dofile(repo .. "/tests/e2e/gardenkit.lua")(H)
    -- the look the README shows and a book well under way
    H.step(2, function()
        for k, v in pairs({ scheme = "garden", mode = "light", cover_size = "m", companion_talk = true }) do Settings.set(k, v) end
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
    return K
end
