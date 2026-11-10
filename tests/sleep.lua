-- The sleep picture: composed for a portrait screen, it paints more than the
-- page colour and saves as a PNG.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/sleep.lua <repo> <out.png>

local REPO, OUT = arg[1] or ".", arg[2] or "/tmp/solarui-sleep.png"
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Sleep = require("solarui/sleep")
local Theme = require("solarui/theme")

local bb = Sleep.compose(600, 800)
local bg = Theme.color("bg"):getColor8().a
local painted = 0
for y = 0, 799, 7 do
    for x = 0, 599, 7 do
        if bb:getPixel(x, y):getColor8().a ~= bg then painted = painted + 1 end
    end
end
Kit.ok(painted > 400, "the sleep picture is painted (" .. painted .. " samples differ from the page)")
Kit.png(bb, OUT)
bb:free()
local gb = Sleep.compose(600, 800, "garden")
local gpainted = 0
for y = 0, 799, 7 do
    for x = 0, 599, 7 do
        if gb:getPixel(x, y):getColor8().a ~= bg then gpainted = gpainted + 1 end
    end
end
Kit.ok(gpainted > 400, "the garden sleep picture is painted (" .. gpainted .. " samples differ from the page)")
Kit.png(gb, OUT:gsub("%.png$", "-garden.png"))
gb:free()
print("sleep picture: " .. OUT)
Kit.finish("sleep")
