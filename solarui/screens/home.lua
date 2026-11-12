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
local HomeCompanion = require("solarui/ui/homecompanion")
local Icon = require("solarui/ui/icon")
local Label = require("solarui/ui/label")
local Launcher = require("solarui/ui/launcher")
local LauncherData = require("solarui/data/launcher")
local Layout = require("solarui/ui/layout")
local ArtView = require("solarui/ui/artview")
local Scene = require("solarui/ui/scene")
local Screen = require("solarui/screens/screen")
local Season = require("solarui/art/season")
local Settings = require("solarui/settings")
local StatusBar = require("solarui/ui/statusbar")
local Strip = require("solarui/ui/readingstrip")
local _ = require("solarui/gettext")

local Home = Screen:extend()

-- Heights of the blocks, in the scene's units.
local STATUS_H, HERO_H, STATS_H, DOCK_H, FOOT = 140, 624, Strip.HEIGHT, 190, 26
-- A cover on the shelf, per cover size setting (the library's): width and
-- height in the scene's units. The two biggest sizes share one, for room.
local SHELF_COVER = { s = { 72, 108 }, m = { 88, 132 }, l = { 104, 156 }, xl = { 104, 156 } }
local LEFT, RIGHT = 104, 1006   -- the columns' outer edges
-- The flowers that carry a button's own icon in their heart.
local ICON_FLOWERS = { dock_medallion = true }
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
    scene:group("home.clock", "Clock and date", function()
        scene:backdrop("clock_frame", fx, fy, fw, fh)
        scene:backdrop("clock_wing", 172, 71, fx - 176, 84, "l")
        scene:backdrop("clock_wing", fx + fw + 4, 85, 1030 - fx - fw - 4, 84, "r")
        local clock = Label:new({ item = StatusBar.item("clock"), kind = "clock", align = "center", text = DeviceInfo.clock() })
        local date = Label:new({ item = { live = true, read = function() return Format.date("%a, %d %B") end }, kind = "small", color = "muted",
            align = "center", text = Format.date("%a, %d %B") })
        self.clock = scene:place(Layout.Column:new({ children = { clock, Layout.Spacer:new({ grow = true }), date }, labels = { clock, date } }),
            fx + 24, fy + 12, fw - 48, fh - 23)
    end)

    scene:group("home.bee", "Bee", function() scene:backdrop("bee", 750, 132, 130, 70) end)
    local Device = require("device")
    scene:group("home.wifi", "Wi-Fi", function()
        scene:sprite("wifi", 716, 10, 110, 110, nil, function() return DeviceInfo.wifi() and 1 or 0 end)
        scene:touch(712, 8, 110, 112, function() require("dispatcher"):execute({ toggle_wifi = true }) end)
    end)
    if Device:hasFrontlight() then
        scene:group("home.frontlight", "Frontlight lamp", function()
            scene:sprite("lamp", 830, 20, 80, 100, nil, function()
                local ok, on = pcall(function() return Device:getPowerDevice():isFrontlightOn() end)
                return (ok and on) and 1 or 0
            end)
            scene:touch(824, 8, 88, 128, function() require("dispatcher"):execute({ show_frontlight_dialog = true }) end)
        end)
    end
    local level = DeviceInfo.battery()
    if level then
        scene:group("home.battery", "Battery", function()
            scene:sprite("battery", 912, 74, 100, 50, nil, function() return math.floor((DeviceInfo.battery() or 0) / 10 + 0.5) end)
            scene:caption(level .. "%", 912, 50, 100, "small")
        end)
    end
end

-- One of the three plant buttons beside the cover.
local function bookButton(scene, id, label, art, text, cx, y, on_tap)
    scene:group(id, label, function()
        scene:backdrop(art, cx - 54, y, 108, 108)
        scene:caption(text, cx - 71, y + 112, 142, "small")
        scene:touch(cx - 68, y - 4, 136, 150, on_tap)
    end)
end

-- The hero: the book in front of its halo, and all about it to the right.
function Home:hero(scene, y, cur)
    scene:group("home.peacock_fan", "Peacock fan behind the cover", function() scene:backdrop("peacock_fan", 20, y - 65, 600, 600) end)
    -- the sprig grows from behind the halo, so it is drawn first
    scene:group("home.sprig", "Sprig", function() scene:backdrop("sprig", 486, y + 10, 120, 138) end)
    scene:group("home.halo", "Halo", function() scene:backdrop("halo", 85, y, 470, 470) end)
    local x0, w = 612, RIGHT - 612
    if not cur then
        scene:sprite("rose_cluster", 6, y + 330, 200, 300)
        scene:group("home.empty_text", "Nothing open yet", function()
            scene:place(Layout.Column:new({ gap = scene:px(14), children = {
                Label:new({ text = _("Nothing open yet"), kind = "hero", lines = 2 }),
                ArtView:new({ name = "whiplash", unit = scene.k, height = scene:px(24) }),
                Label:new({ text = _("Open a book from the library and it will wait for you here."), kind = "body", color = "muted", lines = 4 }),
            } }), x0, y + 60, w)
        end)
        scene:group("home.library_button", "Open the library button", function()
            scene:sprite("plaque", 140, y + 300, 350, 84)
            scene:place(Label:new({ text = _("Open the library"), kind = "heading", color = "on_accent", align = "center" }), 170, y + 300, 290, 84)
            scene:touch(140, y + 296, 350, 92, function() App.go("library") end)
        end)
        return
    end
    local path = cur.path
    local st = Books.state(path)
    local pct = math.floor(st.percent * 100 + 0.5)
    scene:group("home.cover", "Book cover", function()
        -- the cover opens the book's details; "Continue reading" opens the book
        scene:place(Cover:new({ path = path, on_tap = function() Actions.details(path) end, on_hold = function() Actions.details(path) end }),
            172, y + 118, 296, 444)
    end)
    scene:sprite("rose_cluster", 6, y + 318, 200, 300)
    scene:group("home.continue_button", "Continue reading button", function()
        scene:sprite("plaque", 145, y + 538, 350, 84)
        scene:place(Label:new({ text = st.percent > 0 and _("Continue reading") or _("Start reading"), kind = "heading", color = "on_accent",
            align = "center" }), 175, y + 538, 290, 84)
        scene:touch(145, y + 534, 350, 92, function() Actions.open(path) end)
    end)

    local pages = st.pages and string.format(_("page %d of %d"), math.floor(st.percent * st.pages + 0.5), st.pages) or ""
    local opened = cur.time and string.format(_("Last opened %s"), Format.ago(cur.time)) or _("Not opened yet")
    scene:group("home.companion", "Garden companion card", function() HomeCompanion.place(scene, x0, y + 58, w) end)
    scene:group("home.progress", "Reading progress vine", function()
        scene:place(Layout.Column:new({ gap = scene:px(8), children = {
            Label:new({ text = opened, kind = "small", color = "muted" }),
            ArtView:new({ name = "progress", param = pct, unit = scene.k, height = scene:px(70) }),
            Layout.Row:new({ gap = scene:px(14), valign = "center", children = {
                Label:new({ text = pct .. "%", kind = "title" }),
                Label:new({ text = pages, kind = "body", color = "muted", grow = true }),
            } }),
        } }), x0, y + 270, w)
    end)

    local by = y + 462
    bookButton(scene, "home.btn_details", "Details button", "btn_details", _("Details"), 668, by, function() Actions.details(path) end)
    bookButton(scene, "home.btn_bookmarks", "Bookmarks button", "btn_bookmarks", _("Bookmarks"), 810, by,
        function() App.push("annotations", { path = path, kind = "bookmarks" }) end)
    bookButton(scene, "home.btn_highlights", "Highlights button", "btn_highlights", _("Highlights"), 952, by,
        function() App.push("annotations", { path = path, kind = "highlights" }) end)
end

-- The size of a cover on the shelf and the height of the whole shelf.
local function shelfSize()
    local c = SHELF_COVER[Settings.get("cover_size", "m")] or SHELF_COVER.m
    return c[1], c[2], 200 + c[2] - 132
end

-- The shelf: the books opened last, standing in a row. Tapping one brings
-- it to the front; holding it opens its details.
function Home:shelf(scene, y, cur)
    scene:group("home.shelf_heading", "On the shelf heading", function() scene:heading(_("On the shelf"), y) end)
    scene:group("home.snail", "Snail", function() scene:sprite("snail", 780, y - 6, 46, 31) end)   -- on the heading's rule, over it
    local books = {}
    for _i, item in ipairs(History.recent(8)) do
        if not (cur and item.path == cur.path) and #books < 6 then books[#books + 1] = item.path end
    end
    local x0 = LEFT + 30
    local cw, ch = shelfSize()
    local step = (RIGHT - x0 - 88) / 5
    scene:group("home.shelf_sprouts", "Sprouts on the shelf", function() scene:backdrop("sprouts", x0 + 44, y + ch - 10, step * 5, 64, 5) end)
    scene:group("home.shelf_board", "Shelf board", function() scene:backdrop("shelf", 30, y + ch + 48, 1012, 40) end)
    if #books == 0 then
        scene:group("home.shelf_empty", "Empty shelf text", function()
            scene:place(Label:new({ text = _("Books you open show up here."), kind = "body", color = "muted" }), HEAD + 20, y + 90, 700)
        end)
    end
    for i, p in ipairs(books) do
        scene:group("home.shelf_book_" .. i, "Shelf book " .. i, function()
            scene:place(Cover:new({ path = p, on_tap = function() self.picked = p; App.update() end, on_hold = function() Actions.details(p) end }),
                x0 + (i - 1) * step + (88 - cw) / 2, y + 54, cw, ch)
        end)
    end
end

-- The dock: a plant for each place to go, growing from one root.
function Home:dock(scene, y)
    scene:group("home.dock_root", "Root under the dock", function() scene:backdrop("root", 20, y + 104, 1032, 40) end)
    local entries = LauncherData.visible()
    local slot = (RIGHT - LEFT + 40) / math.max(1, #entries)
    local size = math.min(150, slot - 10)
    local tall = size * 130 / 150
    for i, entry in ipairs(entries) do
        local art, icon, label, action = Launcher.describe(entry)
        local cx = LEFT - 20 + slot * (i - .5)
        local top = y + 120 - tall
        scene:group("home.dock_" .. entry.id, label .. " plant", function()
            scene:backdrop(art, cx - size / 2, top, size, tall)
            if ICON_FLOWERS[art] then
                scene:place(Icon:new({ name = icon, size = math.floor(size * .3 / 1.787) }), cx - size * .22, top + tall * .4 - size * .22, size * .44, size * .44)
            end
            scene:caption(label, cx - slot / 2, y + 144, slot, #entries > 6 and "small" or "heading")
            scene:touch(cx - slot / 2 + 4, y - 4, slot - 8, DOCK_H, action, function() Launcher.askRemove(entry, App.update) end)
        end)
    end
end

-- The ornaments of the border, the sun or moon of the hour and a butterfly.
function Home:ornaments(scene)
    scene:frameOrnaments()
    scene:group("home.dayphase", "Sun or moon of the hour", function()
        scene:sprite("dayphase", 268, 24, 64, 44, nil, function()
            local h = tonumber(os.date("%H")) or 12
            return (h >= 5 and h < 8) and 1 or (h >= 8 and h < 17) and 2 or (h >= 17 and h < 20) and 3 or 0
        end)
    end)
    scene:group("home.butterfly", "Butterfly", function() scene:backdrop("butterfly", 548, 700, 64, 56) end)
end

-- Build the home screen.
function Home:build(ctx)
    local stats, shelf = Settings.get("home_stats", true), Settings.get("home_shelf", true)
    local shelf_h = select(3, shelfSize())
    local blocks = STATUS_H + HERO_H + (stats and STATS_H or 0) + (shelf and shelf_h or 0) + DOCK_H
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
    if shelf then y = y + shelf_h + gap end
    local dock_y = math.max(y, scene.vh - FOOT - DOCK_H)

    local season = Settings.get("home_season", true) and Season.current() or 2
    scene:group("home.vine_left", "Climbing vine, left", function() scene:backdrop("vine_left", 4, 34, 150, dock_y + 132 - 34, season) end)
    scene:group("home.vine_right", "Climbing vine, right", function() scene:backdrop("vine_right", 990, dock_y - 270, 78, 400, season) end)
    self:ornaments(scene)
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
