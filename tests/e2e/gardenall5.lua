-- The sleep picture of the garden, made through Settings by real taps.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local UIManager = require("ui/uimanager")
local function scrollToMake()
    -- the Sleep picture row is on the Home tab of the settings
    local tab = H.findWhere(function(e) return e.label == "Home" and e.y and e.y < 400 end)
    if tab then H.tapAt(tab.x + tab.w / 2, tab.y + tab.h / 2); UIManager:forceRePaint() end
    for _ = 1, 12 do
        if H.find("Make") then return true end
        local fwd = H.find(nil, "forward", true)
        if not fwd then break end
        H.tapAt(fwd.x + fwd.w / 2, fwd.y + fwd.h / 2)
        UIManager:forceRePaint()
    end
    return H.find("Make") ~= nil
end
K.shot("f01-settings", function() K.reset({}); K.everyone(); H.app().go("settings") end)
K.shot("f02-settings-scrolled-to-sleep-picture", function() scrollToMake() end, function() H.check(H.find("Make") ~= nil, "the Sleep picture row is reached by scrolling") end)
K.shot("f03-sleep-picture-choices", function() H.tap("Make") end, function() H.check(H.find("My garden as it is now") ~= nil, "Make offers the poster and the garden") end)
K.shot("f04-garden-picture-saved", function()
    H.tap("My garden as it is now")
    os.execute(string.format("cp '%s' '%s/sleep-garden.png'", require("solarui/sleep").path(), H.out))
end, function() H.check(K.lastToast() and K.lastToast():find("Saved"), "the garden picture is saved (" .. tostring(K.lastToast()) .. ")") end)
K.shot("f05-make-again", function() H.tap("Make") end)
K.shot("f06-poster-saved", function()
    H.tap("The home poster")
    os.execute(string.format("cp '%s' '%s/sleep-poster.png'", require("solarui/sleep").path(), H.out))
end, function() H.check(K.lastToast() and K.lastToast():find("Saved"), "the poster is saved") end)
