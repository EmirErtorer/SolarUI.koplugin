-- Every drawing of the garden on KOReader's real SVG renderer: each plant in
-- each stage (and wilted), each animal in both poses, and the ground, laid out
-- on one sheet saved as a PNG. Checks every drawing draws and none is cut by
-- its canvas.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/gardensheet.lua <repo> <out.png>

local REPO, OUT = arg[1] or ".", arg[2] or "/tmp/solarui-gardensheet.png"
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Art = require("solarui/gfx/art")
local Cast = require("solarui/garden/cast")
local Layout = require("solarui/garden/layout")
local Theme = require("solarui/theme")

local W = 1400
local bb = Kit.canvas(W, 3000)
bb:fill(Theme.color("bg"))
local x, y, row_h = 20, 20, 0

-- Draw one drawing on the sheet and check it.
local function put(name, w, h, param)
    if x + w > W - 20 then x, y, row_h = 20, y + row_h + 16, 0 end
    local sprite, _dx, _dy, cut = Art.sprite(name, w, h, w, h, param)
    Kit.ok(sprite ~= nil, name .. " " .. tostring(param) .. " draws")
    Kit.ok(not cut, name .. " " .. tostring(param) .. " is not cut by its canvas")
    if sprite then Art.draw(bb, name, x, y, w, h, w, h, param) end
    x, row_h = x + w + 16, math.max(row_h, h)
end

for _, p in ipairs(Cast.PLANTS) do
    local box = Layout.PLANTS[p.id]
    local w, h = math.floor(box.w * .6), math.floor(box.h * .6)
    for stage = 1, 5 do put("plant_" .. p.id, w, h, tostring(stage)) end
    put("plant_" .. p.id, w, h, "4:wilt")
    x, y, row_h = 20, y + row_h + 16, 0
end
for _, a in ipairs(Cast.ANIMALS) do
    local box = Layout.ANIMALS[a.id]
    put("animal_" .. a.id, box.w, box.h, "1")
    put("animal_" .. a.id, box.w, box.h, "2")
end
x, y, row_h = 20, y + row_h + 16, 0
Kit.ok(Art.sprite("garden_ground", 536, 680, Layout.WIDTH, Layout.HEIGHT) ~= nil, "the ground draws")
Kit.ok(Art.sprite("garden_ground", 536, 680, Layout.WIDTH, Layout.HEIGHT, "wash") ~= nil, "and its faded copy")
Art.draw(bb, "garden_ground", x, y, 536, 680, Layout.WIDTH, Layout.HEIGHT)
Art.draw(bb, "garden_ground", x + 556, y, 536, 680, Layout.WIDTH, Layout.HEIGHT, "wash")
Kit.png(bb, OUT)
print("garden sheet: " .. OUT)
Kit.finish("gardensheet")
