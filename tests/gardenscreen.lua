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
