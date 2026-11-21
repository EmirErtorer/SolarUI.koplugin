-- Black and white: home, the library and Settings in ink and page only; the
-- garden in colour (the default exception) and then in black and white too;
-- the same in dark mode.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local Theme = require("solarui/theme")
local Settings = require("solarui/settings")
local UIManager = require("ui/uimanager")
local function shot(n) UIManager:forceRePaint(); H.shot(n) end
H.step(2, function()
    K.reset({ season = "summer", hour = 11 }); K.everyone(); K.settle()
    Settings.set("scheme", "garden"); Theme.set("mode", "light"); Theme.set("mono", true)
    H.check(Theme.mono() and Theme.gardenColour(), "black and white on, garden in colour by default")
    local c = Theme.get().rgb
    H.check(c.bg[1] == 255 and c.ink[1] == 0 and c.accent[1] == 0 and c.soft[1] == 255, "the page is white and the ink black")
    H.app().open("home")
end)
H.step(2, function() shot("m1-home") ; H.app().push("garden") end)
H.step(2.5, function()
    local g = H.app().current(); if g.guide_timer then UIManager:unschedule(g.guide_timer); g.guide_timer = nil end
    shot("m2-garden-colour"); Theme.set("mono_garden_colour", false); H.app().update()
end)
H.step(2.5, function() shot("m3-garden-mono"); H.app().go("library") end)
H.step(2.5, function() shot("m4-library"); H.app().go("settings") end)
H.step(2, function() shot("m5-settings"); Theme.set("mono_garden_colour", true); Theme.set("mode", "dark"); H.app().go("home") end)
H.step(2.5, function()
    shot("m6-home-dark")
    local c = Theme.get().rgb
    H.check(c.bg[1] == 0 and c.ink[1] == 255, "in dark mode the page is black and the ink white")
    H.app().push("garden")
end)
H.step(2.5, function() shot("m7-garden-dark-colour"); Theme.set("mono", false); Theme.set("mode", "light") end)
