-- Tapping the home companion card (a resident, not a companion for life) opens
-- their popup; nothing of the tap's flash may stay on the screen afterwards.
local H = ...
local UIManager = require("ui/uimanager")
local function paint() UIManager:forceRePaint() end
H.step(1.5, function()
    local Pet = require("solarui/garden/pet")
    local State = require("solarui/garden/state")
    State.refresh()
    if Pet.get() then Pet.goodbye() end
    State.get().plants.sunflower = State.get().plants.sunflower or {}
    State.get().plants.sunflower.watered = State.clock() - 30 * 86400
    State.save()
    require("solarui/settings").set("home_companion", "sunflower")
    H.app().go("home")
end)
H.step(1.2, function() paint(); H.shot("card-before") end)
H.step(.5, function()
    local box
    H.findWhere(function(el) if el.on_tap and el.x and el.x > 300 and el.y < 400 and (el.h or 0) > 300 then box = el end return false end)
    H.check(box ~= nil, "the companion card has a touch box")
    H.say(string.format("card box %d,%d %dx%d", box.x, box.y, box.w, box.h))
    H.tapAt(box.x + box.w / 2, box.y + box.h / 2)
end)
H.step(1.2, function() paint(); H.shot("card-popup") end)
H.step(.5, function() H.app().closeDialog() end)
H.step(1, function() paint(); H.shot("card-after") end)
