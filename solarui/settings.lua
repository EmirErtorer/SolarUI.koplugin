-- SolarUI's own settings, kept in settings/solarui.lua next to KOReader's.
-- One shared store so every module reads and writes the same file.

local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")

local Settings = {}

local store
local dirty = false         -- something was set that the file does not have yet
local flush_timer          -- the pending write, when one is waiting

local LATER = 2.5          -- seconds a write waits, so changes made together are written once

-- Open the settings file on first use.
local function open()
    if not store then
        store = LuaSettings:open(DataStorage:getSettingsDir() .. "/solarui.lua")
    end
    return store
end

-- Read a setting, or `default` when it was never saved.
function Settings.get(key, default)
    local v = open():readSetting(key)
    if v == nil then return default end
    return v
end

-- Save a setting in memory; flush() writes it to disk.
function Settings.set(key, value)
    local s = open()
    -- a number, text or switch that is already what it should be is no change
    if type(value) ~= "table" and s:readSetting(key) == value then return end
    s:saveSetting(key, value)
    dirty = true
end

-- Save a setting and have it written to disk in a moment (see Settings.later).
function Settings.save(key, value)
    Settings.set(key, value)
    Settings.later()
end

-- Write what is not on disk yet in a moment: a write is slow on an e-reader, and
-- a screen that saves several times in a row is written once. KOReader's own
-- flush events (suspend, exit) and SolarUI closing write it at once.
function Settings.later()
    if flush_timer or not dirty then return end
    local ok, UIManager = pcall(require, "ui/uimanager")
    if not ok then return Settings.flush() end
    flush_timer = function() flush_timer = nil; Settings.flush() end
    UIManager:scheduleIn(LATER, flush_timer)
end

-- Write pending changes to disk now (nothing is written when there are none).
function Settings.flush()
    if flush_timer then
        local ok, UIManager = pcall(require, "ui/uimanager")
        if ok then UIManager:unschedule(flush_timer) end
        flush_timer = nil
    end
    if store and dirty then
        dirty = false
        store:flush()
    end
end

return Settings
