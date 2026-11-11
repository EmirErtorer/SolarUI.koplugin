-- The garden screen on KOReader's real blitter: the poster, then each plant
-- and animal shown large with its card, and the care actions through the
-- buttons' own handlers. Saves the poster and two big pictures as PNGs.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/gardenscreen.lua <repo> <out_prefix>

local REPO, OUT = arg[1] or ".", arg[2] or "/tmp/solarui-garden"
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Cast = require("solarui/garden/cast")
local Garden = require("solarui/screens/garden")
local Paint = require("solarui/gfx/paint")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")

local W, H = Kit.Screen:getWidth(), Kit.Screen:getHeight()
State.source = function() return { total = 500, pages = {}, streak = 20, books = 8 } end

-- Build, lay out and paint the screen as it is; returns the picture.
local function paint(s)
    local bb = Kit.canvas()
    local root = s:build({ w = W, h = H })
    root:layout(W, H)
    Paint.fill(bb, 0, 0, W, H, Theme.get().c.bg)
    root:paint(bb, 0, 0)
    return bb
end

local s = Garden:new({})
local bb = paint(s)
Kit.png(bb, OUT .. "-poster.png")
bb:free()

local offset = 40 * 3600   -- two days on, so the plants are due a drink
State.clock = function() return os.time() + offset end

-- every plant and animal in the garden, shown large
State.get().animals.fox = { found = State.clock(), fed = State.clock() }
State.get().plants.rose = { stage = 4, grown = 0, at = State.clock(), watered = State.clock(), gen = 1 }
local shown = 0
for _, id in ipairs(Cast.ids()) do
    if State.entry(id, 12) or State.entry(id, 23) then
        s.focus = id
        local ok, err = pcall(function() local p = paint(s); if id == "rose" then Kit.png(p, OUT .. "-plant.png") end; if id == "bee" then Kit.png(p, OUT .. "-animal.png") end; p:free() end)
        Kit.ok(ok, id .. " shows large: " .. tostring(err))
        shown = shown + 1
    end
end
Kit.ok(shown >= 8, "many are shown large (" .. shown .. ")")
s.focus = nil

-- the card's own buttons
s.focus = "tulip"
local a = s:actions("tulip")
local dew = State.dew()
a.on_water()
Kit.ok(State.dew() == dew - State.WATER, "the water button spends dew")
a.on_next()
Kit.ok(s.focus ~= "tulip", "next moves on")
a.on_prev()
Kit.ok(s.focus == "tulip", "and previous moves back")
s.sprites = { bee = { x = 0 } }
s:move("bee")
Kit.ok(s.pose.bee == "2", "a movement flips an animal's pose")
s:move("bee")
Kit.ok(s.pose.bee == "1", "and back")
a.on_close()
Kit.ok(s.focus == nil, "close returns to the garden")
Kit.ok(s:onBack() == false, "back from the garden leaves it")
s.focus = "tulip"
Kit.ok(s:onBack() == true and s.focus == nil, "back from a picture closes it")
-- the first visit shows everyone, and the guide has pages for it
do
    local Guide = require("solarui/ui/gardenguide")
    local Settings = require("solarui/settings")
    local Sky = require("solarui/garden/sky")
    State.get().guide_seen = nil
    local first = Garden:new({})
    Kit.ok(first.showcase == true, "the first visit is a showcase")
    paint(first):free()
    local n = 0
    for _ in pairs(first.sprites) do n = n + 1 end
    Kit.ok(n == 12, "every animal is on show, foxes too (" .. n .. ")")
    for i = 1, 6 do
        local ok, err = pcall(function() local card = Guide.card(W, i, function() end); card:layout(nil, nil) end)
        Kit.ok(ok, "guide page " .. i .. " builds: " .. tostring(err))
    end
    State.markGuide()
    local later = Garden:new({})
    Kit.ok(later.showcase == false and State.guideSeen(), "after the guide the garden shows only who has come")
    paint(later):free()
    local seen = 0
    for _ in pairs(later.sprites) do seen = seen + 1 end
    Kit.ok(seen < 12, "and not everyone (" .. seen .. ")")
    local Clock = require("solarui/ui/gardenclock")
    for _, pm in ipairs({ false, true }) do
        local ok, err = pcall(function() local card = Clock.card(W, pm, function() end); card:layout(nil, nil); local b = Kit.canvas(); card:paint(b, 0, 0); b:free() end)
        Kit.ok(ok, "the clock dialog draws" .. (pm and " in the afternoon" or " in the morning") .. ": " .. tostring(err))
    end
    Clock.set(15)
    Kit.ok(Sky.hour() == 15 and not Clock.following(), "an hour picked on the clock is the garden's hour")
    Clock.set(nil)
    Kit.ok(Clock.following(), "and the clock can follow the device again")
    Settings.set("garden_hour", 3)
    Kit.ok(Sky.hour() == 3, "a picked hour is the garden's hour")
    Settings.set("garden_hour", false)
    Kit.ok(Sky.hour() == (tonumber(os.date("%H")) or 12), "and following the clock is the default")
end

-- the guide's longest pages fit on the screen
do
    local Guide = require("solarui/ui/gardenguide")
    for _, i in ipairs({ 4, 5, 10 }) do
        local card = Guide.card(W, i, function() end, function() end)
        card:layout(nil, nil)
        local b = Kit.canvas()
        card:paint(b, 0, 0)
        Kit.png(b, OUT .. "-guide" .. i .. ".png")
        b:free()
    end
end

-- sitting in the garden: only the garden, then a question
do
    local sit = Garden:new({})
    sit.sitting = true
    local ok, err = pcall(function() paint(sit):free() end)
    Kit.ok(ok, "the garden alone draws: " .. tostring(err))
    local card = require("solarui/ui/gardensit").card(W, function() end)
    ok, err = pcall(function() card:layout(nil, nil); local b = Kit.canvas(); card:paint(b, 0, 0); b:free() end)
    Kit.ok(ok, "the question after sitting draws: " .. tostring(err))
end

-- the season wheel
do
    local SeasonUI = require("solarui/ui/gardenseason")
    local Season = require("solarui/garden/season")
    local ok, err = pcall(function() local card = SeasonUI.card(W, function() end); card:layout(nil, nil); local b = Kit.canvas(); card:paint(b, 0, 0); b:free() end)
    Kit.ok(ok, "the season wheel draws: " .. tostring(err))
    do local card = SeasonUI.card(W, function() end); card:layout(nil, nil); local b = Kit.canvas(); card:paint(b, 0, 0); Kit.png(b, OUT .. "-wheel.png"); b:free() end
    Season.set("autumn")
    Kit.ok(Season.now() == "autumn" and not Season.following(), "a season picked on the wheel is the garden's season")
    local scr = Garden:new({})
    paint(scr):free()
    Season.set(nil)
    Kit.ok(Season.following(), "and the calendar can be followed again")
end

-- the almanac: every tab, and the page of someone met, of a friend and of a stranger
do
    local Notes, Page = require("solarui/screens/gardennotes"), require("solarui/screens/gardenpage")
    for _, tab in ipairs({ "meet", "calendar", "links", "about" }) do
        local n = Notes:new({})
        n.tab = tab
        local ok, err = pcall(function() paint(n):free() end)
        Kit.ok(ok, "the field notes draw their " .. tab .. " tab: " .. tostring(err))
        if tab == "meet" then Kit.png(paint(n), OUT .. "-notes.png") end
    end
    State.rename("rose", "Rosie")
    State.get().created = State.clock() - 60 * 86400
    for _, id in ipairs({ "rose", "bee", "fox", "water_lily" }) do
        local ok, err = pcall(function() paint(Page:new({ id = id })):free() end)
        Kit.ok(ok, "the almanac page of " .. id .. " draws: " .. tostring(err))
    end
    Kit.png(paint(Page:new({ id = "rose" })), OUT .. "-page.png")
end

-- the cut-back choice and the question after a book
do
    local function draws(card)
        local ok, err = pcall(function() card:layout(nil, nil); local b = Kit.canvas(); card:paint(b, 0, 0); b:free() end)
        return ok, err
    end
    local ok, err = draws(require("solarui/ui/gardencut").card(W, "rose", function() end))
    Kit.ok(ok, "the cut-back choice draws: " .. tostring(err))
    ok, err = draws(require("solarui/ui/gardengive").card(W, function() end))
    Kit.ok(ok, "the question after a book draws: " .. tostring(err))
end

-- the open book: a passage on its page, another on request, and a view with none
do
    local Plaque = require("solarui/garden/plaque")
    local deal = Plaque.deal
    Plaque.deal = function() return { { text = "A first passage that is long enough to want several lines on a page of the book.", title = "A Book", author = "An Author" },
        { text = "A second passage, shorter than the first one.", title = "Another", author = "Someone" } } end
    local book = Garden:new({})
    book.focus = "book"
    local ok, err = pcall(function() local p = paint(book); Kit.png(p, OUT .. "-book.png"); p:free() end)
    Kit.ok(ok, "the book view draws: " .. tostring(err))
    local first = book:quote().title
    book.quote_at = book.quote_at + 1
    Kit.ok(book:quote().title ~= first, "another passage is another passage")
    Plaque.deal = function() return {} end
    local empty = Garden:new({})
    empty.focus = "book"
    ok, err = pcall(function() paint(empty):free() end)
    Kit.ok(ok and empty:quote() == nil, "the book view draws with no highlights: " .. tostring(err))
    Plaque.deal = deal
end

-- the companion's text never outgrows its card, at any text size
do
    local Companion = require("solarui/garden/companion")
    local HomeCompanion = require("solarui/ui/homecompanion")
    local Scene = require("solarui/ui/scene")
    local Settings = require("solarui/settings")
    State.get().plants.rose.watered = State.clock() - 10 * 86400
    State.get().animals.bee.fed = State.clock() - 10 * 86400
    State.rename("tulip", "fourteen letter")
    local picks = {}
    for _, item in ipairs(Companion.list(12)) do
        if item.id == "rose" or item.id == "bee" or item.id == "tulip" then
            item.need = Companion.need(item.entry, item.kind)
            picks[#picks + 1] = item
        end
    end
    Kit.ok(#picks == 3, "a wilted plant, a hiding animal and a fine one to try (" .. #picks .. ")")
    for _, scale in ipairs({ 80, 100, 120, 140 }) do
        Settings.set("text_scale", scale / 100)
        Theme.refresh()
        local scene = Scene.make("t", W, H, 1430)
        for _, item in ipairs(picks) do
            local budget = scene:px(196)
            local col, used = HomeCompanion.column(scene, item, 270, budget)
            col:layout(scene:px(270), budget)
            local total = 0
            for _, c in ipairs(col.children) do total = total + c.h + col.gap end
            total = total - col.gap
            Kit.ok(used <= budget and total <= budget, item.id .. " fits its card at text size " .. scale .. "% (" .. total .. " of " .. budget .. ")")
        end
    end
    Settings.set("text_scale", 1)
    Theme.refresh()
end

Kit.finish("gardenscreen")
