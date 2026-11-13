-- Tapping a plant in the garden opens its card as a dialog over the garden, with arrows to the neighbours.
local H = ...
local UIManager = require("ui/uimanager")
H.step(1.5, function() H.app().go("garden") end)
H.step(1, function() UIManager:forceRePaint() end)
H.step(.5, function()
    local box
    H.findWhere(function(el) if el.on_tap and el.x and el.w and el.w < 300 and el.w > 60 and el.y > 300 then box = el return true end return false end)
    H.tapAt(box.x + box.w / 2, box.y + box.h / 2)
end)
H.step(1, function()
    UIManager:forceRePaint(); H.shot("garden-card")
    H.check(H.app().overlay() ~= nil, "a card opens over the garden")
end)
H.step(.5, function() H.tap("Back to the garden") end)
H.step(.8, function() H.check(H.app().overlay() == nil, "and closes") end)
