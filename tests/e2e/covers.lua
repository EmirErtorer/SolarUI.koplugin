-- Every way to show book covers in Settings, Covers: each choice is tapped,
-- must be saved as the matching settings and must show in the library.
local H = ...
local S = 0.9
local Settings = require("solarui/settings")
local WAYS = {
    { "Stained glass", "image", "glass" }, { "Peacock scales", "image", "scales" }, { "Blossom field", "image", "blossom" },
    { "Drawn card", "card", "none" }, { "Original covers", "image", "none" },
}
H.step(S, function() H.app().go("library") end)
H.step(25, function() end)   -- let the background reading of the covers finish
H.step(S, function() H.app().go("settings") end)
H.step(S, function() H.tap("Covers") end)
for i, w in ipairs(WAYS) do
    H.step(S, function() H.tap(w[1]) end)
    H.step(S, function()
        H.check(Settings.get("cover_style") == w[2] and Settings.get("cover_effect") == w[3], w[1] .. " is saved (" .. tostring(Settings.get("cover_style")) .. "/" .. tostring(Settings.get("cover_effect")) .. ")")
        H.shot(string.format("%02d-settings-%s", i, w[3] == "none" and w[2] or w[3]))
        H.app().go("library")
    end)
    H.step(S, function() H.shot(string.format("%02d-library-%s", i, w[1]:gsub(" ", "-"))); H.app().go("settings") end)
    H.step(S, function() H.tap("Covers") end)
end
