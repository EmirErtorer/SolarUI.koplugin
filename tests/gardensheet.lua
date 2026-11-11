-- Every drawing of the garden on KOReader's real SVG renderer: each plant in
-- each stage (and wilted), each plant in every season and died back for the
-- winter, the maple with the leaves and fruit of the reader's year, the
-- trees in the light of every phase, each animal
-- in both poses, the ground at every phase, season and weather and faded,
-- the tuft a hiding or sleeping animal lies in, the open book and the
-- clock (its button and its dial), the vine along the frame, the face
-- peeking from the grass and the season wheel and its button,
-- laid out on one sheet saved as a PNG. Checks every drawing draws and none is cut by
-- its canvas.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/gardensheet.lua <repo> <out.png>

local REPO, OUT = arg[1] or ".", arg[2] or "/tmp/solarui-gardensheet.png"
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Art = require("solarui/gfx/art")
local Cast = require("solarui/garden/cast")
local Layout = require("solarui/garden/layout")
local Sky = require("solarui/garden/sky")
local Theme = require("solarui/theme")

local W = 1400
local bb = Kit.canvas(W, 11600)
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
-- each plant at stage 4 in every season and died back, then at stage 2 and 3 died back
for _, p in ipairs(Cast.PLANTS) do
    local box = Layout.PLANTS[p.id]
    local w, h = math.floor(box.w * .45), math.floor(box.h * .45)
    x, y, row_h = 20, y + row_h + 16, 0
    for _, season in ipairs({ "spring", "summer", "autumn", "winter", "dormant" }) do put("plant_" .. p.id, w, h, "4:" .. season) end
    put("plant_" .. p.id, w, h, "5:autumn")
    put("plant_" .. p.id, w, h, "2:dormant")
    put("plant_" .. p.id, w, h, "3:dormant:wilt:flip")
end
-- the maple with the golden leaves of the reader's year, and the fruit when the goal is met
x, y, row_h = 20, y + row_h + 16, 0
for _, param in ipairs({ "4:summer:y6", "4:dormant:y12f", "5:autumn:y12f", "3:spring:y3", "2:dormant:y12f" }) do
    local box = Layout.PLANTS.maple
    put("plant_maple", math.floor(box.w * .6), math.floor(box.h * .6), param)
end
-- the trees in the light of every phase
for _, id in ipairs({ "maple", "ginkgo" }) do
    local box = Layout.PLANTS[id]
    local w, h = math.floor(box.w * .6), math.floor(box.h * .6)
    x, y, row_h = 20, y + row_h + 16, 0
    for _, phase in ipairs(Sky.PHASES) do
        put("plant_" .. id, w, h, "4:" .. phase)
        put("plant_" .. id, w, h, "5:wilt:flip:" .. phase)
    end
end
-- the ground in every phase, season and weather and faded, and the open book
x, y, row_h = 20, y + row_h + 16, 0
local gw, gh = 268, 340
for _, mode in ipairs({ "morning", "day", "golden", "night", "wash:night", "day:spring", "day:summer", "day:autumn", "day:winter", "day:cloudy:summer",
    "day:rain:autumn", "night:rain:spring", "day:snow:winter", "night:snow:winter", "morning:mist:autumn", "golden:mist:spring", "night:cloudy:winter", "wash:day:rain:autumn" }) do
    if x + gw > W - 20 then x, y, row_h = 20, y + row_h + 16, 0 end
    local ground, _dx, _dy, cut = Art.sprite("garden_ground", gw, gh, Layout.WIDTH, Layout.HEIGHT, mode)
    Kit.ok(ground ~= nil, "the ground draws at " .. mode)
    Kit.ok(not cut, "the ground at " .. mode .. " is not cut by its canvas")
    Art.draw(bb, "garden_ground", x, y, gw, gh, Layout.WIDTH, Layout.HEIGHT, mode)
    x, row_h = x + gw + 16, math.max(row_h, gh)
end
x, y, row_h = 20, y + row_h + 16, 0
-- the tuft a hiding animal lies in, and the nest of one asleep for the winter, at two animals' sizes
for _, id in ipairs({ "hedgehog", "ladybug" }) do
    local box = Layout.ANIMALS[id]
    for _, param in ipairs({ "day:summer", "day:winter:sleep", "night:snow:winter:sleep", "wash:golden:winter:sleep" }) do put("garden_tuft", box.w, box.h, param) end
end
x, y, row_h = 20, y + row_h + 16, 0
for _, phase in ipairs({ "day", "night" }) do put("garden_book", Layout.BOOK_ART.w / 2, Layout.BOOK_ART.h / 2, phase) end
-- the clock on the top bar's button at three sizes, and the big dial for picking an hour
x, y, row_h = 20, y + row_h + 16, 0
for _, param in ipairs({ "", "3", "14", "3:am", "9:pm", "6:wash", "23:night" }) do
    for _, size in ipairs({ 40, 56, 112 }) do put("garden_clock_icon", size, size, param) end
end
x, y, row_h = 20, y + row_h + 16, 0
for _, param in ipairs({ "3", "14", "3:am", "9:pm", "6:wash", "0:am:night" }) do put("garden_clock_face", 300, 300, param) end
-- the vine along the frame: just started, part grown, grown round and flowering, and on a long poster
x, y, row_h = 20, y + row_h + 16, 0
for _, v in ipairs({ { "0:0", 1430 }, { "12:0", 1430 }, { "30:2", 1430 }, { "7:5", 2000 } }) do
    local vw, vh = math.floor(Layout.WIDTH * .3), math.floor(v[2] * .3)
    local vine, _dx, _dy, cut = Art.sprite("garden_vine", vw, vh, Layout.WIDTH, v[2], v[1])
    Kit.ok(vine ~= nil, "the vine draws at " .. v[1])
    Kit.ok(not cut, "the vine at " .. v[1] .. " is not cut by its canvas")
    Art.draw(bb, "garden_vine", x, y, vw, vh, Layout.WIDTH, v[2], v[1])
    x, row_h = x + vw + 16, math.max(row_h, vh)
end
Kit.png(bb, OUT)
print("garden sheet: " .. OUT)
Kit.finish("gardensheet")
