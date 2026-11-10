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
shot("02-garden", function() H.app().push("garden") end)
shot("03-plant", function() H.app().current().focus = "tulip"; H.app().update() end)
shot("04-watered", function() H.app().current():actions("tulip").on_water() end)
shot("05-animal", function() H.app().current().focus = "bee"; H.app().update() end)
shot("06-name", function() H.app().current().focus = nil; H.app().update(); H.app().input("A name for it", "", function() end, "Save") end)
shot("07-keyboard-closed", function() H.app().closeDialog() end)
shot("08-seed-ask", function() H.app().current():askPlant("poppy") end)
shot("09-journal", function() H.app().closeDialog(); H.app().push("gardenjournal") end)
shot("10-notes", function() H.app().pop(); H.app().push("gardennotes") end)
