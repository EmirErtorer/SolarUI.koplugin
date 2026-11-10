-- Draws a full-screen picture in the garden's style (the border with its
-- corners, the halo, both vines, the flowers of the dock, a bee and a
-- butterfly) and saves it as a PNG, to be chosen as KOReader's sleep screen.

local Blitbuffer = require("ffi/blitbuffer")
local DataStorage = require("datastorage")
local Device = require("device")
local Scene = require("solarui/ui/scene")
local Season = require("solarui/art/season")

local Sleep = {}

-- Where the picture is kept.
function Sleep.path()
    return DataStorage:getSettingsDir() .. "/solarui-sleep.png"
end

-- Compose the picture for a w x h screen into a new buffer.
function Sleep.compose(w, h)
    local scene = Scene.make("sleep", w, h, 1448)
    scene:border(14, 2.5)
    scene:border(21, 1.2)
    scene:frameOrnaments()
    local season = Season.current()
    local cy = scene.vh / 2 - 60
    scene:backdrop("vine_left", 4, 34, 150, scene.vh - 120, season)
    scene:backdrop("vine_right", 990, scene.vh - 470, 78, 400, season)
    scene:backdrop("peacock_fan", 236, cy - 300, 600, 600)
    scene:backdrop("halo", 301, cy - 235, 470, 470)
    scene:backdrop("rose_cluster", 320, cy - 100, 200, 300)
    scene:backdrop("bee", 700, cy - 280, 130, 70)
    scene:backdrop("butterfly", 760, cy + 160, 64, 56)
    local plants = { "dock_library", "dock_collections", "dock_history", "dock_search", "dock_inkaway", "dock_settings" }
    scene:backdrop("root", 20, scene.vh - 150, 1032, 40)
    for i, name in ipairs(plants) do scene:backdrop(name, 120 + (i - 1) * 150, scene.vh - 250, 130, 113) end
    scene:layout(w, h)
    local bb = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
    scene:paint(bb, 0, 0)
    return bb
end

-- Make the picture at the screen's size and save it; returns the path.
function Sleep.make()
    local bb = Sleep.compose(Device.screen:getWidth(), Device.screen:getHeight())
    local path = Sleep.path()
    bb:writePNG(path)
    bb:free()
    return path
end

return Sleep
