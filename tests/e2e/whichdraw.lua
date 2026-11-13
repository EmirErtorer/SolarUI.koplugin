-- Which drawings are made when the garden opens (after waiting for the idle pre-drawing).
local H = ...
local UIManager = require("ui/uimanager")
local sprites = require("solarui/art/sprites")
local log = {}
local on = true
local Art = require("solarui/gfx/art")
local sprite = Art.sprite
Art.sprite = function(name, w, h, vw, vh, p) if name == "root" then log[#log + 1] = string.format("[root %s %s %s %s]", tostring(w), tostring(h), tostring(vw), tostring(vh)) end return sprite(name, w, h, vw, vh, p) end
for name, fn in pairs(sprites) do
    if type(fn) == "function" then
        sprites[name] = function(...) if on then log[#log + 1] = name end return fn(...) end
    end
end
H.step(14, function() end)
H.step(.5, function() log[#log + 1] = "|OPEN|"; H.app().go("garden"); UIManager:forceRePaint(); on = false end)
H.step(.5, function() H.say("DRAWN " .. table.concat(log, " ")) end)
