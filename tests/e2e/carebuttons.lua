-- The Feed and Water buttons on the home card of a resident who needs care
-- work (the card around them answers a tap, but not the button's own).
local H = ...
local UIManager = require("ui/uimanager")
local function state() return require("solarui/garden/state") end
H.step(1.5, function()
    local State = state()
    local Pet = require("solarui/garden/pet")
    State.refresh()
    if Pet.get() then Pet.goodbye() end
    local d = State.get()
    -- an animal that is about (or hiding) now, whatever the season: made hungry
    for _, a in ipairs(require("solarui/garden/cast").ANIMALS) do
        d.animals[a.id] = d.animals[a.id] or { found = State.clock(), fed = State.clock() }
    end
    for _, e in ipairs(State.animals()) do
        if not e.resting and not H.animal then H.animal = e.def.id end
    end
    d.animals[H.animal].fed = State.clock() - 90 * 86400
    State.save()
    require("solarui/settings").set("home_companion", H.animal)
    H.app().go("home")
end)
H.step(1, function() UIManager:forceRePaint(); H.shot("care-feed-before") end)
H.step(.5, function()
    local before = state().get().animals[H.animal].fed
    H.tap("Feed")
    H.step_before = before
end)
H.step(1, function()
    UIManager:forceRePaint(); H.shot("care-feed-after")
    H.check(state().get().animals[H.animal].fed > H.step_before, "the Feed button on home feeds the animal")
end)
H.step(.5, function()
    local State = state()
    State.get().plants.rose.watered = State.clock() - 90 * 86400
    State.save()
    require("solarui/settings").set("home_companion", "rose")
    H.app().go("home")
end)
H.step(1, function() UIManager:forceRePaint(); H.shot("care-water-before") end)
H.step(.5, function()
    H.step_before = state().get().plants.rose.watered
    H.tap("Water")
end)
H.step(1, function()
    UIManager:forceRePaint(); H.shot("care-water-after")
    H.check(state().get().plants.rose.watered > H.step_before, "the Water button on home waters the plant")
end)
-- the same for the companion for life, whose whole card also answers a tap
H.step(.5, function()
    local State = state()
    local Pet = require("solarui/garden/pet")
    if Pet.get() then Pet.goodbye() end
    State.get().orchard = {}
    State.get().animals[H.animal].fed = State.clock() - 90 * 86400
    State.save()
    H.check(Pet.adopt(H.animal), "a hungry animal is adopted")
    H.app().go("home")
end)
H.step(1, function() UIManager:forceRePaint(); H.shot("care-pet-before") end)
H.step(.5, function()
    H.step_before = state().get().animals[H.animal].fed
    H.tap("Feed")
end)
H.step(1, function()
    UIManager:forceRePaint(); H.shot("care-pet-after")
    H.check(state().get().animals[H.animal].fed > H.step_before, "the Feed button on the companion's card feeds them")
end)
