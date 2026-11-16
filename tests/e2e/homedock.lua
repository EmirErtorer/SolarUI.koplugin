-- Home's dock: History first, then Notebooks as a lavender, and no bud at the
-- foot of the frame under the names.
local H = ...
H.step(2, function()
    local Launcher = require("solarui/data/launcher")
    local v = Launcher.visible()
    H.check(v[1].id == "history" and v[2].id == "notebooks", "History comes first, Notebooks second")
    H.app().go("home")
end)
H.step(2, function() require("ui/uimanager"):forceRePaint(); H.shot("home") end)
