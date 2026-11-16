-- README moving picture "Companions": home with one garden companion after
-- another, each answering a tap with a line of their own.
--     SOLARUI_SHOT_BOOKS=<folder> tools/readme/gif.sh companions <out.gif>
local H = ...
H.out = os.getenv("SOLARUI_DRIVE_OUT")
local repo = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/tools/readme/[^/]+$")
dofile(repo .. "/tools/readme/seed.lua")(H, repo)
local G = dofile(repo .. "/tools/readme/gif/gifkit.lua")(H, "companions")
local Find = dofile(repo .. "/tools/readme/gif/find.lua")
local App = require("solarui/app")
local Pet = require("solarui/garden/pet")
local State = require("solarui/garden/state")

-- many companions, plants and animals alike; Yüzsüz is one of them
local WHO = { "robin", "sunflower", "frog", "yuzsuz", "koi", "rose" }

G.run(function()
    G:mute(true)
    require("solarui/settings").set("companion_talk", true)
    G:wait(1)
    G:mute(false)
    for _i, id in ipairs(WHO) do
        State.get().pet = nil
        Pet.adopt(id)
        App.go("home")
        App.update()
        G:wait(0.6)
        G:hold(1700)
        for _t = 1, 2 do
            -- the companion's card on home: the area right of the book that answers a tap and a hold
            local sw = require("device").screen:getWidth()
            local card = Find.where("solarui", function(e) return e.on_tap and e.on_hold and not e.label and not e.text and e.x > sw * .5 and e.y < sw * .6 end)
            G:tap(card.x + card.w * .7, card.y + card.h * .2, 200)
            G:wait(0.4)
            G:hold(1900)
        end
    end
end)
