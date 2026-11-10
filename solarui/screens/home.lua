-- The home screen, composed like an Art Nouveau poster: the book being read
-- in front of a halo with its roses, its progress as a vine, the day, week
-- and year of reading as three flowers, the last books on a shelf, and a
-- row of plants along the bottom that lead everywhere else. A climbing rose
-- runs up the left edge. Almost everything drawn can be tapped.

local Actions = require("solarui/actions")
local App = require("solarui/app")
local Books = require("solarui/data/books")
local Cover = require("solarui/ui/cover")
local DeviceInfo = require("solarui/data/device")
local Files = require("solarui/data/files")
local Format = require("solarui/format")
local History = require("solarui/data/history")
local Icon = require("solarui/ui/icon")
local Label = require("solarui/ui/label")
local Launcher = require("solarui/ui/launcher")
local LauncherData = require("solarui/data/launcher")
local Layout = require("solarui/ui/layout")
local ArtView = require("solarui/ui/artview")
local Scene = require("solarui/ui/scene")
local Screen = require("solarui/screens/screen")
local Settings = require("solarui/settings")
local StatusBar = require("solarui/ui/statusbar")
local Strip = require("solarui/ui/readingstrip")
local _ = require("solarui/gettext")

local Home = Screen:extend()

-- Heights of the blocks, in the scene's units.
local STATUS_H, HERO_H, STATS_H, SHELF_H, DOCK_H, FOOT = 140, 624, Strip.HEIGHT, 200, 190, 26
local LEFT, RIGHT = 104, 1006   -- the columns' outer edges
-- The flowers that carry a button's own icon in their heart.
local ICON_FLOWERS = { dock_medallion = true, dock_inkaway = true }
local HEAD = 158              -- where headings start, clear of the climbing rose (the scene's own default)

-- Shown again after a book: the book just read is back in front.
function Home:onRaise()
    self.picked = nil
end

-- The book in front: the one picked from the shelf, or the one being read.
-- { path, time } or nil.
function Home:shown()
    if self.picked and Files.exists(self.picked) then
        return { path = self.picked, time = History.lastOpened(self.picked) }
    end
    return History.current()
end

-- The status row: the time over the date in an arched cartouche at the top
-- of the page, a whiplash line running out to each side of it, and three
-- living things that are the Wi-Fi, the frontlight and the battery.
function Home:status(scene)
    local fx, fy, fw, fh = 376, 8, 320, 130
    scene:backdrop("clock_frame", fx, fy, fw, fh)
    scene:backdrop("clock_wing", 172, 63, fx - 176, 84, "l")
    scene:backdrop("clock_wing", fx + fw + 4, 85, 1030 - fx - fw - 4, 84, "r")
    local clock = Label:new({ item = StatusBar.item("clock"), kind = "clock", align = "center", text = DeviceInfo.clock() })
    local date = Label:new({ item = { live = true, read = function() return Format.date("%A, %d %B") end }, kind = "small", color = "muted",
        align = "center", text = Format.date("%A, %d %B") })
    self.clock = scene:place(Layout.Column:new({ children = { clock, Layout.Spacer:new({ grow = true }), date }, labels = { clock, date } }),
        fx + 24, fy + 12, fw - 48, fh - 23)

    local Device = require("device")
    scene:sprite("wifi", 716, 10, 110, 110, nil, function() return DeviceInfo.wifi() and 1 or 0 end)
    scene:touch(712, 8, 110, 112, function() require("dispatcher"):execute({ toggle_wifi = true }) end)
    if Device:hasFrontlight() then
        scene:sprite("lamp", 830, 20, 80, 100, nil, function()
            local ok, on = pcall(function() return Device:getPowerDevice():isFrontlightOn() end)
            return (ok and on) and 1 or 0
        end)
        scene:touch(824, 8, 88, 128, function() require("dispatcher"):execute({ show_frontlight_dialog = true }) end)
    end
    local level = DeviceInfo.battery()
    if level then
        scene:sprite("battery", 912, 85, 100, 50, nil, function() return math.floor((DeviceInfo.battery() or 0) / 10 + 0.5) end)
        scene:caption(level .. "%", 912, 50, 100, "small")
    end
end

-- One of the three plant buttons beside the cover.
local function bookButton(scene, art, text, cx, y, on_tap)
    scene:backdrop(art, cx - 54, y, 108, 108)
    scene:caption(text, cx - 71, y + 112, 142, "small")
    scene:touch(cx - 68, y - 4, 136, 150, on_tap)
end

-- The hero: the book in front of its halo, and all about it to the right.
function Home:hero(scene, y, cur)
    scene:backdrop("halo", 85, y, 470, 470)
    scene:backdrop("sprig", 486, y + 10, 120, 138)
    local x0, w = 612, RIGHT - 612
    if not cur then
        scene:sprite("rose_cluster", 6, y + 330, 200, 300)
        scene:place(Layout.Column:new({ gap = scene:px(14), children = {
            Label:new({ text = _("Nothing open yet"), kind = "hero", lines = 2 }),
            ArtView:new({ name = "whiplash", unit = scene.k, height = scene:px(24) }),
            Label:new({ text = _("Open a book from the library and it will wait for you here."), kind = "body", color = "muted", lines = 4 }),
        } }), x0, y + 60, w)
        scene:sprite("plaque", 140, y + 300, 350, 84)
        scene:place(Label:new({ text = _("Open the library"), kind = "heading", color = "on_accent", align = "center" }), 170, y + 300, 290, 84)
        scene:touch(140, y + 296, 350, 92, function() App.go("library") end)
        return
    end
    local path = cur.path
    local info, st = Books.info(path), Books.state(path)
    local pct = math.floor(st.percent * 100 + 0.5)
    scene:place(Cover:new({ path = path, on_tap = function() Actions.open(path) end, on_hold = function() Actions.details(path) end }),
        172, y + 118, 296, 444)
    scene:sprite("rose_cluster", 6, y + 318, 200, 300)
    scene:sprite("plaque", 145, y + 538, 350, 84)
    scene:place(Label:new({ text = st.percent > 0 and _("Continue reading") or _("Start reading"), kind = "heading", color = "on_accent",
        align = "center" }), 175, y + 538, 290, 84)
    scene:touch(145, y + 534, 350, 92, function() Actions.open(path) end)

    local who = info.author or ""
    if info.series then who = who .. (who ~= "" and "  ·  " or "") .. info.series .. (info.series_index and (" " .. info.series_index) or "") end
    local pages = st.pages and string.format(_("page %d of %d"), math.floor(st.percent * st.pages + 0.5), st.pages) or ""
    local opened = cur.time and string.format(_("Last opened %s"), Format.ago(cur.time)) or _("Not opened yet")
    scene:place(Layout.Column:new({ gap = scene:px(8), children = {
        Label:new({ text = info.title, kind = "hero", lines = 2 }),
        Label:new({ text = who, kind = "heading", color = "muted" }),
        ArtView:new({ name = "whiplash", unit = scene.k, height = scene:px(24) }),
        Label:new({ text = opened, kind = "small", color = "muted" }),
        ArtView:new({ name = "progress", param = pct, unit = scene.k, height = scene:px(70) }),
        Layout.Row:new({ gap = scene:px(14), valign = "center", children = {
            Label:new({ text = pct .. "%", kind = "title" }),
            Label:new({ text = pages, kind = "body", color = "muted", grow = true }),
        } }),
    } }), x0, y + 24, w)

    local by = y + 462
    bookButton(scene, "btn_details", _("Details"), 668, by, function() Actions.details(path) end)
    bookButton(scene, "btn_bookmarks", _("Bookmarks"), 810, by, function() App.push("annotations", { path = path, kind = "bookmarks" }) end)
    bookButton(scene, "btn_highlights", _("Highlights"), 952, by, function() App.push("annotations", { path = path, kind = "highlights" }) end)
end

-- The shelf: the books opened last, standing in a row. Tapping one brings
-- it to the front; holding it opens its details.
function Home:shelf(scene, y, cur)
    scene:heading(_("On the shelf"), y)
    local books = {}
    for _i, item in ipairs(History.recent(8)) do
        if not (cur and item.path == cur.path) and #books < 6 then books[#books + 1] = item.path end
    end
    local x0 = LEFT + 30
    local step = (RIGHT - x0 - 88) / 5
    scene:backdrop("sprouts", x0 + 44, y + 122, step * 5, 64, 5)
    scene:backdrop("shelf", 30, y + 180, 1012, 40)
    if #books == 0 then
        scene:place(Label:new({ text = _("Books you open show up here."), kind = "body", color = "muted" }), HEAD + 20, y + 90, 700)
    end
    for i, p in ipairs(books) do
        scene:place(Cover:new({ path = p, on_tap = function() self.picked = p; App.update() end, on_hold = function() Actions.details(p) end }),
            x0 + (i - 1) * step, y + 54, 88, 132)
    end
end

-- The dock: a plant for each place to go, growing from one root.
function Home:dock(scene, y)
    scene:backdrop("root", 20, y + 104, 1032, 40)
    local entries = LauncherData.visible()
    local slot = (RIGHT - LEFT + 40) / math.max(1, #entries)
    local size = math.min(150, slot - 10)
    local tall = size * 130 / 150
    for i, entry in ipairs(entries) do
        local art, icon, label, action = Launcher.describe(entry)
        local cx = LEFT - 20 + slot * (i - .5)
        local top = y + 120 - tall
        scene:backdrop(art, cx - size / 2, top, size, tall)
        if ICON_FLOWERS[art] then
            scene:place(Icon:new({ name = icon, size = math.floor(size * .3 / 1.787) }), cx - size * .22, top + tall * .4 - size * .22, size * .44, size * .44)
        end
        scene:caption(label, cx - slot / 2, y + 144, slot, #entries > 6 and "small" or "heading")
        scene:touch(cx - slot / 2 + 4, y - 4, slot - 8, DOCK_H, action, function() Launcher.askRemove(entry, App.update) end)
    end
end

-- Build the home screen.
function Home:build(ctx)
    local stats, shelf = Settings.get("home_stats", true), Settings.get("home_shelf", true)
    local blocks = STATUS_H + HERO_H + (stats and STATS_H or 0) + (shelf and SHELF_H or 0) + DOCK_H
    local scene = Scene.make("home", ctx.w, ctx.h, blocks + FOOT)
    local gaps = 2 + (stats and 1 or 0) + (shelf and 1 or 0)
    local gap = math.min(110, math.max(0, (scene.vh - blocks - FOOT) / gaps))
    local cur = self:shown()

    scene:border(14, 2.5)
    scene:border(21, 1.2)
    local y = STATUS_H + gap
    local hero_y = y
    y = y + HERO_H + gap
    local stats_y = y
    if stats then y = y + STATS_H + gap end
    local shelf_y = y
    if shelf then y = y + SHELF_H + gap end
    local dock_y = math.max(y, scene.vh - FOOT - DOCK_H)

    scene:backdrop("vine_left", 4, 34, 150, dock_y + 132 - 34)
    scene:backdrop("vine_right", 990, dock_y - 270, 78, 400)
    self:status(scene)
    self:hero(scene, hero_y, cur)
    if stats then Strip.place(scene, stats_y, Strip.data(), function() App.go("history") end) end
    if shelf then self:shelf(scene, shelf_y, cur) end
    self:dock(scene, dock_y)
    return scene
end

-- The book has now really closed (home was shown before it did): its
-- reading time is counted, so draw home again with the new numbers.
function Home:onBookClosed()
    App.update()
end

-- The library index is ready.
function Home:onIndexed() end

return Home
