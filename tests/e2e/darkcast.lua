-- Every plant and animal in the garden poster and in the home arch, light then dark.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local State = K.state()
local Theme = require("solarui/theme")
for _, mode in ipairs({ "light", "dark" }) do
    K.shot("d-garden-" .. mode, function()
        Theme.set("mode", mode)
        K.reset({}); K.everyone(); K.plants(4, "fine")
        H.app().go("garden")
    end)
    K.shot("d-card-" .. mode, function()
        require("solarui/ui/gardenpopup").open("robin", K.inhabitants)
    end)
    K.shot("d-close-" .. mode, function() H.app().closeDialog() end)
end
