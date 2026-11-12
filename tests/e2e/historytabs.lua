-- Saves a screenshot of each tab of the reading log (log, stats, goal) in the
-- emulator, for looking at its charts and the goal's tree.
local H = ...
H.step(3, function() H.app().go("history") end)
for _i, tab in ipairs({ "log", "stats", "goal" }) do
    H.step(1, function()
        local s = H.app().current()
        s.tab, s.page = tab, 1
        H.app().update()
        require("ui/uimanager"):forceRePaint()
    end)
    H.step(.6, function() H.shot("history-" .. tab) end)
end
