-- Every plant and animal as the companion on home, each picture as large as
-- the arch allows without touching it: a shot of each (cf-<id>.png).
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local Cast = require("solarui/garden/cast")
local Settings = require("solarui/settings")
local State = require("solarui/garden/state")
local ids = {}
for _i, p in ipairs(Cast.PLANTS) do ids[#ids + 1] = p.id end
for _i, a in ipairs(Cast.ANIMALS) do ids[#ids + 1] = a.id end
H.step(2, function()
    K.reset({ season = "summer", hour = 11 })
    K.everyone()
    for _i, p in ipairs(Cast.PLANTS) do
        local d = State.get()
        d.plants[p.id] = d.plants[p.id] or { stage = 4, grown = 0, at = K.t, watered = K.t, gen = 1 }
    end
    K.plants(4, "fine")
    K.animals("content")
    K.settle()
    State.get().pet = nil
    Settings.set("companion_talk", true)
    H.app().open("home")
end)
for _i, id in ipairs(ids) do
    H.step(.6, function()
        State.get().pet = nil
        H.check(require("solarui/garden/pet").adopt(id), id .. " is the companion")
        H.app().update()
    end)
    H.step(.8, function() require("ui/uimanager"):forceRePaint(); H.shot("cf-" .. id) end)
end
-- the big card in the garden and the popup, for wide and tall ones
for _i, id in ipairs({ "koi", "peacock", "yuzsuz", "sunflower", "pansy", "dragonfly" }) do
    H.step(.6, function() H.app().go("home"); H.app().push("garden") end)
    H.step(1.2, function()
        local g = H.app().current()
        g.showcase = false
        if g.guide_timer then require("ui/uimanager"):unschedule(g.guide_timer); g.guide_timer = nil end
        g.focus = id
        H.app().update()
    end)
    H.step(1.2, function() require("ui/uimanager"):forceRePaint(); H.shot("card-" .. id); H.app().current().focus = nil; H.app().go("home") end)
    H.step(.8, function() require("solarui/ui/gardenpopup").open(id) end)
    H.step(1.2, function() require("ui/uimanager"):forceRePaint(); H.shot("popup-" .. id); H.app().closeDialog() end)
end
