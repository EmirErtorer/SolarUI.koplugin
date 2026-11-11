-- The garden in the real emulator: open it from home's dock, tap a plant and
-- an animal, care for them, rename one, plant a seed in a bare bed, the
-- journal and the field notes.
local H = ...
local S = 0.9

local function shot(name, fn)
    H.step(S, function() if fn then fn() end end)
    H.step(S, function() H.check(H.onTop(), name .. ": SolarUI stays on top"); H.shot(name) end)
end

shot("01-home")
shot("01b-popup-over-home", function() require("solarui/ui/gardenpopup").open("tulip") end)
shot("01c-popup-closed", function() H.app().closeDialog() end)
shot("02-garden", function() H.app().push("garden") end)
shot("02b-guide", function() H.app().current():guide() end)
shot("02c-guide-closed", function() H.app().closeDialog() end)
shot("02d-clock", function() require("solarui/ui/gardenclock").open(true, function() H.app().update() end) end)
shot("02e-clock-closed", function() H.app().closeDialog() end)
shot("03-plant", function() H.app().current().focus = "tulip"; H.app().update() end)
shot("04-watered", function() H.app().current():actions("tulip").on_water() end)
shot("05-animal", function() H.app().current().focus = "bee"; H.app().update() end)
shot("06-name", function() H.app().current().focus = nil; H.app().update(); H.app().input("A name for it", "", function() end, "Save") end)
shot("07-keyboard-closed", function() H.app().closeDialog() end)
shot("08-journal", function() H.app().push("gardenjournal") end)
shot("09-notes", function() H.app().pop(); H.app().push("gardennotes") end)
