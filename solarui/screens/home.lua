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
local HomeArt = require("solarui/art/home")
local Icon = require("solarui/ui/icon")
local Label = require("solarui/ui/label")
local Launcher = require("solarui/ui/launcher")
local LauncherData = require("solarui/data/launcher")
local Layout = require("solarui/ui/layout")
local ArtView = require("solarui/ui/artview")
local Scene = require("solarui/ui/scene")
local Screen = require("solarui/screens/screen")
local Settings = require("solarui/settings")
local Stats = require("solarui/data/stats")
local StatusBar = require("solarui/ui/statusbar")
local _ = require("solarui/gettext")

local Home = Screen:extend()

-- Heights of the blocks, in the scene's units.
local STATUS_H, HERO_H, STATS_H, SHELF_H, DOCK_H, FOOT = 140, 624, 212, 200, 190, 26
local LEFT, RIGHT = 104, 1006   -- the columns' outer edges
local HEAD = 158              -- where headings start, clear of the climbing rose

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

-- A heading with a whiplash rule running off to the right.
local function heading(scene, text, y)
    scene:place(Layout.Row:new({ gap = scene:px(16), children = {
        Label:new({ text = text, kind = "title" }),
        ArtView:new({ name = "whiplash", unit = scene.k, grow = true, height = scene:px(24) }),
    } }), HEAD, y, RIGHT - HEAD, 46)
end

-- A caption centred under a drawing.
local function caption(scene, text, x, y, w, kind)
    scene:place(Label:new({ text = text, kind = kind or "label", align = "center" }), x, y, w)
end

-- The status row: the time and date, and three living things that are the
-- Wi-Fi, the frontlight and the battery.
function Home:status(scene)
    local clock = Label:new({ item = StatusBar.item("clock"), kind = "hero", text = DeviceInfo.clock() })
    local date = Label:new({ item = { live = true, read = function() return Format.date("%A, %d %B") end }, kind = "heading", color = "muted",
        text = Format.date("%A, %d %B") })
    local row = Layout.Row:new({ gap = scene:px(22), valign = "bottom", children = { clock, date }, labels = { clock, date } })
    self.clock = scene:place(row, 168, 22, 540, 78)
    scene:backdrop("tendril_top", 40, 86, 992, 70)

    local Device = require("device")
    scene:sprite("wifi", 716, 10, 110, 110, nil, function() return DeviceInfo.wifi() and 1 or 0 end)
    scene:touch(712, 8, 110, 112, function() require("dispatcher"):execute({ toggle_wifi = true }) end)
    if Device:hasFrontlight() then
        scene:sprite("lamp", 830, 16, 80, 100, nil, function()
            local ok, on = pcall(function() return Device:getPowerDevice():isFrontlightOn() end)
            return (ok and on) and 1 or 0
        end)
        scene:touch(824, 8, 88, 112, function() require("dispatcher"):execute({ show_frontlight_dialog = true }) end)
    end
    local level = DeviceInfo.battery()
    if level then
        scene:sprite("battery", 912, 58, 100, 50, nil, function() return math.floor((DeviceInfo.battery() or 0) / 10 + 0.5) end)
        caption(scene, level .. "%", 912, 26, 100, "small")
    end
end

-- One of the three plant buttons beside the cover.
local function bookButton(scene, art, text, cx, y, on_tap)
    scene:backdrop(art, cx - 54, y, 108, 108)
    caption(scene, text, cx - 71, y + 112, 142, "small")
    scene:touch(cx - 68, y - 4, 136, 150, on_tap)
end

-- The hero: the book in front of its halo, and all about it to the right.
function Home:hero(scene, y, cur)
    scene:backdrop("halo", 85, y, 470, 470)
    scene:backdrop("sprig", 486, y + 10, 120, 138)
    local x0, w = 612, RIGHT - 612
    if not cur then
        scene:sprite("rose_cluster", 0, y + 330, 200, 300)
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
        Layout.Row:new({ gap = scene:px(14), valign = "bottom", children = {
            Label:new({ text = pct .. "%", kind = "title" }),
            Label:new({ text = pages, kind = "small", color = "muted", grow = true }),
        } }),
    } }), x0, y + 24, w)

    local by = y + 462
    bookButton(scene, "btn_details", _("Details"), 668, by, function() Actions.details(path) end)
    bookButton(scene, "btn_bookmarks", _("Bookmarks"), 810, by, function() App.push("annotations", { path = path, kind = "bookmarks" }) end)
    bookButton(scene, "btn_highlights", _("Highlights"), 952, by, function() App.push("annotations", { path = path, kind = "highlights" }) end)
end

-- The reading block: today as a sunflower filling toward the goal, the week
-- as a stem of roses and the year as a water lily. A tap opens the reading log.
function Home:reading(scene, y)
    heading(scene, _("Your reading"), y)
    local goal = Settings.get("daily_goal", 30)
    local minutes = Format.minutes(Stats.today())
    local week = Stats.daily(7)
    local days, letters = {}, {}
    for i, d in ipairs(week) do
        days[i] = d.seconds > 0 and "1" or "0"
        letters[i] = Format.chars(Format.date("%a", d.time + 43200), 1)
    end
    local streak, books = Stats.streak(), Stats.booksThisYear()
    local function log() App.go("history") end

    scene:sprite("sunflower", 150, y + 44, 130, 130, math.floor(math.min(1, minutes / goal) * 20 + 0.5))
    caption(scene, string.format(_("%d min today"), minutes), 100, y + 176, 230)
    scene:touch(100, y + 44, 230, 166, log)

    local wx, wy, ww, wh = 392, y + 40, 350, 124
    scene:sprite("week", wx, wy, ww, wh, table.concat(days))
    for i, s in ipairs(HomeArt.weekSpots(ww, wh)) do
        caption(scene, letters[i], wx + s[1] - 20, wy + s[2] + 6, 40, "micro")
    end
    caption(scene, string.format(_.n("%d day in a row", "%d days in a row", streak), streak), wx, y + 176, ww)
    scene:touch(wx, y + 44, ww, 166, log)

    scene:sprite("lily", 818, y + 40, 146, 136, books)
    caption(scene, string.format(_.n("%d book this year", "%d books this year", books), books), 770, y + 176, 240)
    scene:touch(770, y + 44, 236, 166, log)
end

-- The shelf: the books opened last, standing in a row. Tapping one brings
-- it to the front; holding it opens its details.
function Home:shelf(scene, y, cur)
    heading(scene, _("On the shelf"), y)
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
        if art == "dock_medallion" then
            scene:place(Icon:new({ name = icon, size = math.floor(size * .3 / 1.787) }), cx - size * .22, top + tall * .4 - size * .22, size * .44, size * .44)
        end
        caption(scene, label, cx - slot / 2, y + 144, slot, #entries > 6 and "small" or "heading")
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
    if stats then self:reading(scene, stats_y) end
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
