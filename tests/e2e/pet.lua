-- The companion for life: adopt one, see them on home, tap them and open
-- their page. Saves screenshots of each.
local H = ...
local UIManager = require("ui/uimanager")
local function paint() UIManager:forceRePaint() end
H.step(1.5, function()
    local Pet = require("solarui/garden/pet")
    local State = require("solarui/garden/state")
    State.refresh()
    if Pet.get() then Pet.goodbye() end
    H.check(Pet.adopt("snail", "Pip"), "a companion is adopted")
    H.app().go("home")
end)
H.step(1.2, function() paint(); H.shot("pet-home") end)
H.step(.5, function()
    local Voice = require("solarui/garden/voice")
    H.check(Voice.react() ~= nil, "a tap is answered")
    H.app().update()
end)
H.step(1, function() paint(); H.shot("pet-home-tap") end)
H.step(.5, function() H.app().push("gardenpet") end)
H.step(1.2, function() paint(); H.shot("pet-page") end)
-- something waits to be told: the badge shows on the card and on the Garden plant
H.step(.5, function()
    local Pet = require("solarui/garden/pet")
    Pet.get().events = { { kind = "level", level = 2 }, { kind = "book" } }
    H.app().go("home")
end)
H.step(1.2, function() paint(); H.shot("pet-badge") end)
