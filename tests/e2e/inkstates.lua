-- The notebook shelf when Ink Away cannot fill it: not installed (what it is
-- and an Install button), too old (Update, and what an update says while
-- the newest release is the one already there), switched off and waiting
-- for a restart; then the shelf again with Ink Away as it should be.
-- Run with HOME_SETUP pointing at a script that copies Ink Away's library in.
local H = ...
local UIManager = require("ui/uimanager")
local Addons = require("solarui/apps/addons")
local GitHub = require("solarui/install/github")
local function paint() UIManager:forceRePaint() end
local status, latest = Addons.status, GitHub.latest
local Shelf = require("ink/bookshelf")
local host = Shelf.host
local function as(state)
    Shelf.host = host
    Addons.status = status
    if state == "old" then Shelf.host = nil
    elseif state ~= "ready" then Addons.status = function() return state end end
    H.app().update()
end
local function says(text)
    local found = false
    H.findWhere(function(el) if el.text == text or el.label == text then found = true end return false end)
    return found
end

H.step(2, function() H.app().go("home") end)
H.step(1, function() as("missing"); H.app().push("inkshelf") end)
H.step(1.5, function() paint(); H.shot("s1-not-installed"); H.check(says("Get Ink Away") and says("Install Ink Away"), "without Ink Away: what it is and an Install button") end)
H.step(.5, function() as("old") end)
H.step(1.5, function() paint(); H.shot("s2-too-old"); H.check(says("Update Ink Away"), "with an old Ink Away: Update Ink Away") end)
H.step(.5, function()
    GitHub.latest = function(_addon, done) done({ tag = "v" .. Addons.version(require("solarui/apps/inkaway")), version = Addons.version(require("solarui/apps/inkaway")), url = "x", size = 1 }) end
    H.tap("Update Ink Away")
end)
H.step(2, function() paint(); H.shot("s3-update-already-newest"); H.check(says("Ink Away is up to date"), "an update with nothing newer says so") end)
H.step(.5, function() H.tap("OK"); GitHub.latest = latest end)
H.step(1, function() as("disabled") end)
H.step(1.5, function() paint(); H.shot("s4-switched-off"); H.check(says("Ink Away is switched off") and says("Switch on"), "switched off: Switch on") end)
H.step(.5, function() as("restart") end)
H.step(1.5, function() paint(); H.shot("s5-restart"); H.check(says("Restart to finish") and says("Restart now"), "installed, not running: Restart now") end)
H.step(.5, function() as("ready") end)
H.step(12, function() paint(); H.shot("s6-ready") ; H.check(not says("Update Ink Away"), "with Ink Away as it should be: the shelf") end)
H.step(.5, function() H.app().push("inkpick", { kind = "notebooks", path = "x", name = "x", current = "ginkgo" }) end)
H.step(2, function() paint(); H.shot("s7-ginkgo-preview") end)
