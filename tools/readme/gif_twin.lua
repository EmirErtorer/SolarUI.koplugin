-- README moving picture "The twin switch": SolarUI hands home over to CyberUI
-- with one tap on Settings' plaque, and CyberUI hands it back.
--     SOLARUI_SHOT_BOOKS=<folder> tools/readme/gif.sh twin <out.gif>
local H = ...
H.out = os.getenv("SOLARUI_DRIVE_OUT")
local repo = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/tools/readme/[^/]+$")
dofile(repo .. "/tools/readme/seed.lua")(H, repo)
local G = dofile(repo .. "/tools/readme/gif/gifkit.lua")(H, "twin")
local Find = dofile(repo .. "/tools/readme/gif/find.lua")
local App = require("solarui/app")

-- Tap the twin plaque on the settings page of `host`, on its other half.
local function tapPlaque(host)
    local el = Find.where(host, function(e) return e.on_tap and e.children and e.children[1] and (e.children[1].param or e.children[1].active) end)
    if el then G:tap(el.x + el.w * (host == "solarui" and .72 or .28), el.y + el.w / 10, 300) end
end

G.run(function()
    G:mute(true)
    G_reader_settings:saveSetting("twin_ui", "solarui")
    -- CyberUI as a reader would see it: a handle of its own, the device a Kindle, no highlight shard
    local CyberSettings = require("cyberui/settings")
    CyberSettings.set("handle", "NOVA_7")
    CyberSettings.set("home_shard", false)
    require("cyberui/data/banner").device = function() return "KINDLE" end
    require("cyberui/data/device").name = function() return "KINDLE" end
    App.go("home")
    G:wait(1.5)
    G:mute(false)
    G:hold(1500)
    G:tap(Find.middle(Find.text("solarui", "Settings")))
    G:wait(0.8)
    G:hold(1300)
    tapPlaque("solarui")
    G:wait(1.5)
    G:hold(1800)
    -- CyberUI's System page, then its plaque hands back
    local CyberApp = require("cyberui/app")
    local tab = Find.text("cyberui", "SYSTEM") or Find.text("cyberui", "System")
    if tab then G:tap(Find.middle(tab)) else CyberApp.go("settings") end
    G:wait(1)
    G:hold(1300)
    tapPlaque("cyberui")
    G:wait(1.5)
    G:hold(2000)
end)
