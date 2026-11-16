-- The twin switch with the twin missing: a tap shows the install prompt, and
-- Install really downloads the twin's newest release from GitHub, checks it
-- and unpacks it (into a throwaway folder here), then asks for a restart.
-- Needs the internet.
local H = ...
local Addons = require("solarui/apps/addons")
local Twin = require("solarui/twin")
local UIManager = require("ui/uimanager")
local dir = os.getenv("SOLARUI_DRIVE_OUT") .. "/plugins-test"
os.execute("mkdir -p '" .. dir .. "'")
local status, installed, plugins = Addons.status, Addons.installedPath, Addons.pluginsDir
local asked
H.step(2, function()
    Addons.pluginsDir = function() return dir end
    Addons.installedPath = function(a) if a.folder == Twin.OTHER.folder then return nil end return installed(a) end
    Addons.status = function(a) if a.folder == Twin.OTHER.folder then return "missing" end return status(a) end
    UIManager.askForRestart = function(_um, text) asked = text end
    -- (the Mac emulator's forked children cannot reach the network; on a reader they can, so the
    -- download runs here in KOReader itself, the way Net.get does where there are no child processes)
    require("ffi/util").runInSubProcess = function() return nil end
    H.app().open("settings")
end)
H.step(1.5, function()
    Twin.switch()
end)
H.step(1.5, function()
    UIManager:forceRePaint(); H.shot("i1-prompt")
    H.check(H.find("Install") ~= nil, "the switch offers to install " .. Twin.OTHER.name)
    H.tap("Install")
end)
H.step(3, function() UIManager:forceRePaint(); H.shot("i2-installing") end)
H.step(40, function()
    UIManager:forceRePaint(); H.shot("i3-done")
    local f = io.open(dir .. "/" .. Twin.OTHER.folder .. "/main.lua")
    H.check(f ~= nil, Twin.OTHER.name .. " was downloaded, checked and unpacked")
    if f then f:close() end
    H.check(asked ~= nil, "then KOReader asks for a restart: " .. tostring(asked))
    local v = io.open(dir .. "/" .. Twin.OTHER.folder .. "/cyberui/version.lua")
    if v then H.say("installed version: " .. v:read("*a"):match('"([^"]+)"')); v:close() end
    Addons.status, Addons.installedPath, Addons.pluginsDir = status, installed, plugins
end)
