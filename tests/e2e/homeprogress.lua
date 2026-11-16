-- The book progress style chosen in Settings is the one home shows.
local H = ...
local Settings = require("solarui/settings")
for _i, st in ipairs({ "vine", "blossoms", "moons" }) do
    H.step(1.2, function()
        Settings.set("progress_style", st)
        H.app().open("home"); H.app().go("home"); H.app().update()
    end)
    H.step(1.2, function()
        require("ui/uimanager"):forceRePaint(); H.shot("home-" .. st)
        local want = ({ vine = "progress", blossoms = "progress_blossoms", moons = "progress_moons" })[st]
        H.check(H.findWhere(function(el) return el.name == want end) ~= nil, "home shows " .. st)
    end)
end
