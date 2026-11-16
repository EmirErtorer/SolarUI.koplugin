-- The garden half of the README's header (tools/readme/banners.py adds the
-- title): the home dock's own runner across the whole width with some of the
-- dock's own plants standing on it, drawn by SolarUI's art in the plants'
-- real colours, written as an SVG fragment on a W x H canvas.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tools/readme/header.lua <repo> <out.svgpart>
local REPO, OUT = arg[1], arg[2]
dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Sprites = require("solarui/art/sprites")
local Registry = require("solarui/theme/registry")
local Rootline = require("solarui/art/rootline")
local Theme = require("solarui/theme")

local W, H = 1000, 236            -- the header's canvas
local ROOT_Y, ROOT_H = 188, 44    -- where the runner lies across it
-- the plants on the runner, left to right, at these x (their middle)
local PLANTS = { { "dock_history", 548 }, { "dock_lavender", 624 }, { "dock_rose", 700 }, { "dock_garden", 776 },
    { "dock_tulip", 852 }, { "dock_library", 928 } }
local PW, PH = 92, 80             -- a plant's box (the dock's 150 x 130)

-- every colour role as the drawings want it, the plants' real colours
local c = {}
for role in pairs(Registry.scheme("garden").light) do c[role] = Theme.hex(role, true) end
for _i, role in ipairs({ "bg", "soft", "accent", "accent2", "on_accent" }) do c[role] = c[role] or Theme.hex(role) end

local out = {}
for _i, p in ipairs(PLANTS) do
    local x = p[2] - PW / 2
    local foot = ROOT_Y + Rootline.y(W, ROOT_H, p[2])
    out[#out + 1] = string.format('<g transform="translate(%.1f %.1f)">%s</g>', x, foot - PH, Sprites[p[1]](c, PW, PH))
end
out[#out + 1] = string.format('<g transform="translate(0 %d)">%s</g>', ROOT_Y, Sprites.root(c, W, ROOT_H))
local f = assert(io.open(OUT, "w"))
f:write(table.concat(out))
f:close()
print("wrote " .. OUT)
os.exit(0)
