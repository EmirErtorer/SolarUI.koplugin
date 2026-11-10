-- Every drawing on KOReader's real SVG renderer, laid out on one sheet and
-- saved as a PNG for a look, with the time each takes.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/art.lua <repo> <out.png> [scheme] [mode] [scale]

local REPO, OUT = arg[1] or ".", arg[2] or "/tmp/solarui-art.png"
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Settings = require("solarui/settings")
if arg[3] then Settings.set("scheme", arg[3]) end
if arg[4] then Settings.set("mode", arg[4]) end
local K = tonumber(arg[5]) or 1
local Art = require("solarui/gfx/art")
local Theme = require("solarui/theme")
local time = require("ui/time")

-- name, virtual width, virtual height, param
local SHEET = {
    { "vine_left", 150, 900 }, { "vine_right", 80, 420 }, { "halo", 480, 480 }, { "rose_cluster", 200, 300 }, { "sprig", 130, 150 },
    { "clock_frame", 320, 130 }, { "clock_wing", 200, 84, "l" }, { "clock_wing", 330, 84, "r" }, { "bee", 130, 70 }, { "frame_corner", 90, 90, 0 }, { "frame_corner", 90, 90, 1 }, { "frame_bud", 60, 30 }, { "dayphase", 64, 44, 0 }, { "dayphase", 64, 44, 1 }, { "dayphase", 64, 44, 2 }, { "dayphase", 64, 44, 3 }, { "butterfly", 64, 56 }, { "snail", 56, 38 }, { "peacock_fan", 600, 600 }, { "vine_left", 150, 800, 3 }, { "goal_tree", 500, 110, 0 }, { "goal_tree", 500, 110, 60 }, { "goal_tree", 500, 110, 100 }, { "card_curl", 30, 30, 0 }, { "card_curl", 30, 30, 2 }, { "scene_fox", 220, 140 }, { "scene_branch", 220, 140 }, { "scene_shelf", 220, 140 }, { "scene_book", 220, 140 }, { "scene_leaves", 220, 140 }, { "plaque", 350, 84 }, { "whiplash", 500, 24 },
    { "progress", 400, 70, 0 }, { "progress", 400, 70, 7 }, { "progress", 400, 70, 42 }, { "progress", 400, 70, 78 }, { "progress", 400, 70, 100 },
    { "btn_details", 120, 120 }, { "btn_bookmarks", 120, 120 }, { "btn_highlights", 120, 120 },
    { "sunflower", 150, 150, 13 }, { "week", 410, 126, "0011011|5" }, { "week", 410, 126, "1100000|1" }, { "sunflower", 150, 150, 21 }, { "lily", 170, 160, 23 }, { "lily", 170, 160, 12 }, { "lily", 170, 160, 0 },
    { "shelf", 1012, 40 }, { "sprouts", 902, 64, 5 }, { "root", 1032, 40 },
    { "dock_library", 150, 130 }, { "dock_collections", 150, 130 }, { "dock_history", 150, 130 }, { "dock_search", 150, 130 }, { "dock_inkaway", 150, 130 }, { "dock_karahindiba", 150, 130 }, { "dock_maple", 150, 130 }, { "dock_rose", 150, 130 }, { "dock_tulip", 150, 130 }, { "dock_ginkgo", 150, 130 }, { "dock_fern", 150, 130 }, { "dock_clock", 150, 130 },
    { "dock_settings", 150, 130 }, { "dock_medallion", 150, 130 },
    { "plant_library", 80, 80 }, { "plant_collections", 80, 80 }, { "plant_history", 80, 80 }, { "plant_search", 80, 80 },
    { "plant_settings", 80, 80 }, { "plant_details", 80, 80 }, { "plant_highlights", 80, 80 }, { "plant_bookmarks", 80, 80 },
    { "plant_notes", 80, 80 }, { "plant_sprout", 80, 80 }, { "section_curl", 100, 24 }, { "crest", 300, 40 },
    { "cover_glass", 160, 240, 0 }, { "cover_glass", 160, 240, 3 }, { "cover_garden", 160, 240, 0 }, { "cover_garden", 160, 240, 3 }, { "cover_halo", 160, 240, 0 }, { "cover_halo", 160, 240, 3 }, { "cover_scales", 160, 240, 0 }, { "cover_scales", 160, 240, 3 }, { "page_rule", 992, 28 }, { "cover_border", 296, 444 }, { "cover_border", 88, 132 }, { "cover_sheet", 120, 180 }, { "cover_shape", 60, 90 }, { "plant_collections", 220, 220 },
    { "wifi", 90, 90, 1 }, { "wifi", 90, 90, 0 }, { "lamp", 80, 100, 1 }, { "lamp", 80, 100, 0 }, { "battery", 100, 50, 7 }, { "battery", 100, 50, 2 },
}

local W = math.floor(1100 * K)
local bb = Kit.canvas(W, math.floor(3400 * K))
bb:fill(Theme.color("bg"))
local x, y, row_h = 30, 30, 0
local total = 0
for _, s in ipairs(SHEET) do
    local w, h = math.floor(s[2] * K), math.floor(s[3] * K)
    if x + w > W - 30 then x, y, row_h = 30, y + row_h + 40, 0 end
    local t0 = time.now()
    local sprite, _dx, _dy, cut = Art.sprite(s[1], w, h, s[2], s[3], s[4])
    local ms = time.to_ms(time.since(t0))
    total = total + ms
    Kit.ok(sprite ~= nil, s[1] .. " draws")
    -- the pictures of a cover (and the sheets under it) fill their canvas on purpose
    Kit.ok(not cut or s[1]:find("^cover_"), s[1] .. " is not cut by its canvas")
    if sprite then Art.draw(bb, s[1], x, y, w, h, s[2], s[3], s[4]) end
    print(string.format("%-18s %4dx%-4d %6.1f ms", s[1], w, h, ms))
    x, row_h = x + w + 40, math.max(row_h, h)
end
print(string.format("total %.0f ms", total))
Kit.png(bb, OUT)
Kit.finish("art")
