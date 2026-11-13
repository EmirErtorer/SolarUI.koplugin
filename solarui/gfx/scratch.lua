-- Where artwork is written on its way to the renderer. Every drawing goes
-- through one small file, so on a device whose storage is flash it should be
-- a place kept in memory (/dev/shm or /tmp when they are tmpfs); anywhere
-- else it is KOReader's own cache folder.

local DataStorage = require("datastorage")
local lfs = require("libs/libkoreader-lfs")

local Scratch = {}

local RAM = { tmpfs = true, ramfs = true }

-- The first of `dirs` that is a folder lying on a memory-backed mount of
-- `mounts` (the text of /proc/mounts), or nil. `is_dir(path)` tells folders.
function Scratch.pick(mounts, dirs, is_dir)
    local fs = {}
    for line in (mounts or ""):gmatch("[^\n]+") do
        local mp, kind = line:match("^%S+ (%S+) (%S+)")
        if mp then fs[mp] = kind end
    end
    for _i, dir in ipairs(dirs) do
        if is_dir(dir) then
            -- the mount that holds it is the longest mount point that starts it
            local best, kind = -1, nil
            for mp, k in pairs(fs) do
                local prefix = mp == "/" and "/" or (mp .. "/")
                if (dir == mp or (dir .. "/"):sub(1, #prefix) == prefix) and #mp > best then best, kind = #mp, k end
            end
            if kind and RAM[kind] then return dir end
        end
    end
    return nil
end

local path

-- The file to write drawings to (made once).
function Scratch.path()
    if path then return path end
    local text
    local f = io.open("/proc/mounts")
    if f then text = f:read("*a"); f:close() end
    local dir = Scratch.pick(text, { "/dev/shm", "/tmp" }, function(d) return lfs.attributes(d, "mode") == "directory" end)
    if dir then
        local candidate = dir .. "/solarui-art.svg"
        local probe = io.open(candidate, "w")
        if probe then probe:close(); path = candidate; return path end
    end
    local cache = DataStorage:getDataDir() .. "/cache"
    if lfs.attributes(cache, "mode") ~= "directory" then lfs.mkdir(cache) end
    path = cache .. "/solarui-art.svg"
    return path
end

return Scratch
