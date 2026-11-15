-- Yüzsüz The Magnificent in the garden: the garden with her in it, her card
-- with its four buttons, a pat on the right side too many (the bite), her
-- food menu, and her as the companion on home.
local H = ...
local UIManager = require("ui/uimanager")
local function paint() UIManager:forceRePaint() end
H.step(1.5, function()
    local Pet = require("solarui/garden/pet")
    local State = require("solarui/garden/state")
    State.get().guide_seen = true
    State.refresh()
    if Pet.get() then Pet.goodbye() end
    H.check(State.rec("yuzsuz") ~= nil, "the queen is in the garden")
    H.app().go("garden")
end)
H.step(1.5, function() paint(); H.shot("q-garden") end)
H.step(.5, function()
    local screen = H.app().current()
    screen.focus = "yuzsuz"
    H.app().update()
end)
H.step(1.2, function() paint(); H.shot("q-card") end)
H.step(.5, function()
    local a = require("solarui/ui/gardenactions").of("yuzsuz", function() H.app().update() end)
    for _ = 1, 4 do a.queen.on_right() end
end)
H.step(1.2, function() paint(); H.shot("q-bite") end)
H.step(.5, function() require("solarui/ui/gardenqueen").menu(function() H.app().update() end) end)
H.step(1.2, function() paint(); H.shot("q-menu") end)
H.step(.5, function()
    H.app().closeDialog()
    H.check(require("solarui/garden/pet").adopt("yuzsuz"), "she can be served for life")
    H.app().go("home")
end)
H.step(1.5, function() paint(); H.shot("q-home") end)
