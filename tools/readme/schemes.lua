-- Home in every colour scheme, light and then dark, for the README's scheme
-- collage (tools/readme/schemes.py makes it): s-<scheme>-<mode>.png.
--   run by tools/readme/shots.sh
local H = ...
local repo = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/tools/readme/[^/]+$")
dofile(repo .. "/tools/readme/seed.lua")(H, repo)
local Settings = require("solarui/settings")
local Registry = require("solarui/theme/registry")
-- Custom with accents of its own (its defaults are Garden's), so it shows as a scheme apart
Settings.set("custom_accent", "#6B3A6B")
Settings.set("custom_accent2", "#D08A2E")
-- the scheme paints home's plants and animals too, the companion keeping their own colours
Settings.set("scheme_living", "home")
Settings.set("scheme_companion_kept", true)
for _i, scheme in ipairs(Registry.SCHEMES) do
    for _j, mode in ipairs({ "light", "dark" }) do
        H.step(1.5, function()
            Settings.set("scheme", scheme)
            Settings.set("mode", mode)
            require("solarui/theme").refresh()
            H.app().go("home")
            H.app().render("full")
        end)
        H.step(2.5, function() require("ui/uimanager"):forceRePaint(); H.shot("s-" .. scheme .. "-" .. mode) end)
    end
end
