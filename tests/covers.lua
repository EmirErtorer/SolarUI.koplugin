-- The book cover cards in each art style, three titles to each style, on one
-- sheet saved as a PNG, drawn by the real Cover widget.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/covers.lua <repo> <out.png> [scheme] [mode]

local REPO, OUT = arg[1] or ".", arg[2] or "/tmp/solarui-covers.png"
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Settings = require("solarui/settings")
if arg[3] then Settings.set("scheme", arg[3]) end
if arg[4] then Settings.set("mode", arg[4]) end
local Cover = require("solarui/ui/cover")
local Theme = require("solarui/theme")

local TITLES = { { "The Gardener's Year", "A. Moss" }, { "Salt and Silver", "I. Vane" }, { "Letters from the Orchard", "R. Finch" } }
local W, H, GAP = 220, 330, 24
local bb = Kit.canvas(30 + #Cover.ART * (W + GAP), 30 + #TITLES * (H + GAP))
bb:fill(Theme.color("bg"))
for col, art in ipairs(Cover.ART) do
    Settings.set("card_art", art)
    for row, t in ipairs(TITLES) do
        local cover = Cover:new({ title = t[1], author = t[2], badge = row == 2 and "New" or nil })
        cover.w, cover.h = W, H
        local ok, err = pcall(function() cover:draw(bb, 30 + (col - 1) * (W + GAP), 30 + (row - 1) * (H + GAP)) end)
        Kit.ok(ok, art .. " card " .. row .. " draws: " .. tostring(err))
    end
end
-- a cover picture treated as glass, scales or blossom stays intact and ends up coloured by itself
do
    local Blitbuffer = require("ffi/blitbuffer")
    local Mosaic = require("solarui/gfx/mosaic")
    local pic = Blitbuffer.new(120, 180, Blitbuffer.TYPE_BBRGB32)
    pic:paintRectRGB32(0, 0, 120, 180, Blitbuffer.ColorRGB32(200, 60, 40, 255))
    local out = Blitbuffer.new(120, 180, Blitbuffer.TYPE_BBRGB32)
    for _i, effect in ipairs(Mosaic.EFFECTS) do
        Mosaic.paint(out, pic, 0, 0, 120, 180, effect)
        local px = pic:getPixel(60, 90):getColorRGB32()
        Kit.ok(px.r == 200 and px.g == 60 and px.b == 40, effect .. " leaves the picture it was made from alone")
        local seen = false
        for y = 0, 179, 3 do
            for x = 0, 119, 3 do
                local c = out:getPixel(x, y):getColorRGB32()
                if c.r > c.g + 60 and c.r > c.b + 60 then seen = true end
            end
        end
        Kit.ok(seen, effect .. " shows the picture's colour")
    end
    pic:free()
    out:free()
end
Kit.png(bb, OUT)
print("cover sheet: " .. OUT)
Kit.finish("covers")
