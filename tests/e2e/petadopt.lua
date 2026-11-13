-- Choosing a companion in the garden: the card of an animal offers "Make ... my
-- companion"; its name and confirmation come next. Saves screenshots.
local H = ...
local UIManager = require("ui/uimanager")
H.step(1.5, function()
    local Pet = require("solarui/garden/pet")
    require("solarui/garden/state").refresh()
    if Pet.get() then Pet.goodbye() end
    H.app().go("garden")
end)
H.step(1.5, function()
    local g = H.app().current()
    g.focus = "snail"
    H.app().update()
end)
H.step(1, function() UIManager:forceRePaint(); H.shot("adopt-card") end)
H.step(.5, function() H.tap("Make Garden snail my companion") end)
H.step(1.2, function() UIManager:forceRePaint(); H.shot("adopt-name") end)
