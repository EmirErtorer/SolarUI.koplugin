-- Home's "books this year" and the reading log's Goal tab count the same books:
-- those marked finished this year.
local H = ...
H.step(2, function()
    local year = os.date("%Y")
    local n = 0
    for i, item in ipairs(require("solarui/data/history").recent(20)) do
        if i <= 3 then
            local ds = require("docsettings"):open(item.path)
            ds:saveSetting("summary", { status = "complete", modified = year .. "-03-0" .. i })
            ds:flush()
            require("solarui/data/books").forget(item.path)
            n = n + 1
        end
    end
    require("solarui/data/statsdb").invalidate()
    local Stats, Goal = require("solarui/data/stats"), require("solarui/data/goal")
    local home, goal = Stats.booksThisYear(), #Goal.finishedIn(tonumber(year))
    H.check(home == goal and home >= n, string.format("home says %d, the Goal tab %d (marked %d)", home, goal, n))
    H.app().open("home")
end)
H.step(2, function() require("ui/uimanager"):forceRePaint(); H.shot("home") end)
