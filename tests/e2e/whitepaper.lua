-- The Custom scheme on white paper, and on a black night page in dark mode.
local H = ...
local Theme = require("solarui/theme")
local Settings = require("solarui/settings")
H.step(2, function()
    Settings.set("scheme", "custom"); Settings.set("custom_paper", "white"); Theme.set("mode", "light")
    H.app().open("home")
end)
H.step(2, function()
    require("ui/uimanager"):forceRePaint(); H.shot("white-home")
    local c = Theme.get().rgb.bg
    H.check(c[1] == 255 and c[2] == 255 and c[3] == 255, "the page is white")
    Settings.set("custom_night", "black"); Theme.set("mode", "dark")
end)
H.step(2, function()
    require("ui/uimanager"):forceRePaint(); H.shot("black-home")
    local c = Theme.get().rgb.bg
    H.check(c[1] == 0 and c[2] == 0 and c[3] == 0, "the night page is black")
    H.app().go("settings")
end)
H.step(2, function()
    require("ui/uimanager"):forceRePaint(); H.shot("settings")
    Settings.set("custom_paper", nil); Settings.set("custom_night", nil); Settings.set("scheme", "garden"); Theme.set("mode", "light")
end)
