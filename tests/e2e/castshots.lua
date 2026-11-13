-- Every plant and animal of the cast as the companion on home, each with two
-- of their lines (what they say first, then what they answer to a tap).
-- Saves c-<id>-a.png and c-<id>-b.png.
local H = ...
local UIManager = require("ui/uimanager")
local Cast = require("solarui/garden/cast")
local ids = {}
for _, p in ipairs(Cast.PLANTS) do ids[#ids + 1] = { p.id, "plant" } end
for _, a in ipairs(Cast.ANIMALS) do ids[#ids + 1] = { a.id, "animal" } end
H.step(1.5, function() require("solarui/settings").set("companion_talk", true) end)
for _, it in ipairs(ids) do
    local id, kind = it[1], it[2]
    H.step(.5, function()
        local State = require("solarui/garden/state")
        local Pet = require("solarui/garden/pet")
        local d = State.get()
        d.pet, d.orchard = nil, {}
        local now = State.clock()
        if kind == "plant" then d.plants[id] = d.plants[id] or { stage = 4, grown = 0, at = now, watered = now, gen = 1 }
        else d.animals[id] = d.animals[id] or { found = now, fed = now } end
        State.refresh()
        H.check(Pet.adopt(id), id .. " is the companion")
        H.app().go("home")
    end)
    H.step(.7, function() UIManager:forceRePaint(); H.shot("c-" .. id .. "-a") end)
    H.step(.3, function()
        local Voice = require("solarui/garden/voice")
        local Pet = require("solarui/garden/pet")
        -- an idle line (a tap answers with a short reaction; both are theirs)
        Pet.get().now = nil
        Pet.get().day = os.date("%Y%m%d", require("solarui/garden/state").clock())
        H.app().update()
    end)
    H.step(.7, function() UIManager:forceRePaint(); H.shot("c-" .. id .. "-b") end)
end
