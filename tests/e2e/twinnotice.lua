-- The one-time word about the twin: shown a little after opening when the twin
-- is not installed, with Install; never again once seen.
local H = ...
local Addons = require("solarui/apps/addons")
local Twin = require("solarui/twin")
local Settings = require("solarui/settings")
local status = Addons.status
H.step(2, function()
    Addons.status = function(a) if a.folder == "CyberUI.koplugin" then return "missing" end return status(a) end
    Settings.set("twin_told", nil)
    H.app().open("home")
    Twin.announceSoon()
end)
H.step(6, function()
    require("ui/uimanager"):forceRePaint(); H.shot("notice")
    local found = false
    H.findWhere(function(el) if el.text == "Meet CyberUI" or el.title == "Meet CyberUI" then found = true end return false end)
    H.check(H.app().overlay() ~= nil, "the word about CyberUI shows")
    H.check(Settings.get("twin_told") == true, "it is remembered as seen")
    H.app().closeDialog()
    Twin.announceSoon()
end)
H.step(6, function()
    H.check(H.app().overlay() == nil, "it does not show again")
    Addons.status = status
end)
