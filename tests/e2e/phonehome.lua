-- Home on a phone-shaped screen with a crowded dock: text fits its room and
-- the dock takes two rows in the space above it.
local H = ...
local Launcher = require("solarui/data/launcher")
H.step(2, function()
    Launcher.setHidden("search", false)
    Launcher.add(); Launcher.add()
    H.check(#Launcher.visible() >= 10, "ten buttons on the dock (" .. #Launcher.visible() .. ")")
    H.app().open("home")
end)
H.step(2, function() require("ui/uimanager"):forceRePaint(); H.shot("phone-home") end)
H.step(.5, function() Launcher.setHidden("search", true) end)
