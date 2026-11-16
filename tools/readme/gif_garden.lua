-- README moving picture "A day in the garden": wilted plants watered back to
-- life, then the garden at other hours, in other seasons and weathers.
--     SOLARUI_SHOT_BOOKS=<folder> tools/readme/gif.sh garden <out.gif>
local H = ...
H.out = os.getenv("SOLARUI_DRIVE_OUT")
local repo = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/tools/readme/[^/]+$")
local K = dofile(repo .. "/tools/readme/seed.lua")(H, repo)
local G = dofile(repo .. "/tools/readme/gif/gifkit.lua")(H, "garden")
local Find = dofile(repo .. "/tools/readme/gif/find.lua")
local App = require("solarui/app")
local State = require("solarui/garden/state")

-- the plants that start the picture wilted
local WILTED = { "rose", "sunflower", "iris" }

-- Tap the poster's plant or animal `id`.
local function tapOn(id)
    require("ui/uimanager"):forceRePaint()
    local order, list = K.touchOrder(), K.touches()
    for i, who in ipairs(order) do
        if who == id and list[i] then
            local el = list[i]
            G:tap(el.x + el.w / 2, el.y + el.h / 2, 200)
            return
        end
    end
end

-- Tap the element with this text.
local function tapText(text, host)
    local el = Find.text(host or "solarui", text)
    if el then G:tap(Find.middle(el)) end
    return el ~= nil
end

-- Tap the heading button whose art is `art`.
local function tapHeading(art)
    local el = Find.where("solarui", function(e) return e.art and e.art[1] == art end)
    if el then G:tap(Find.middle(el)) end
end

G.run(function()
    G:mute(true)
    for _i, id in ipairs(WILTED) do
        local p = State.get().plants[id]
        p.watered = K.t - 30 * 86400   -- (long dry: wilted whatever their thirst)
        p.noted = nil
    end
    K.settle()
    App.go("home")
    App.push("garden")
    G:wait(1.5)
    local g = App.current()
    if g.guide_timer then require("ui/uimanager"):unschedule(g.guide_timer); g.guide_timer = nil end
    G:mute(false)
    G:hold(1800)
    -- water the wilted plants
    for _i, id in ipairs({ "rose", "sunflower" }) do
        tapOn(id)
        G:wait(0.6)
        G:hold(1200)
        tapText("Water")
        G:wait(0.6)
        G:hold(1500)
        if not tapText("Close") then App.closeDialog() end
        G:wait(0.5)
        G:hold(900)
    end
    -- the hour: evening, then night (the fox, the moth and the hedgehog come out)
    for _i, hour in ipairs({ "7", "11" }) do
        tapHeading("garden_clock_icon")
        G:wait(0.6)
        G:hold(700)
        tapText("PM")
        G:wait(0.5)
        tapText(hour)
        G:wait(0.8)
        G:hold(1800)
    end
    -- the seasons, each in its weather
    local seasons = { { "Autumn", "rain" }, { "Winter", "snow" }, { "Spring", "clear" }, { "Summer", "clear" } }
    tapHeading("garden_clock_icon")
    G:wait(0.6)
    tapText("AM")
    G:wait(0.5)
    tapText("10")
    G:wait(0.8)
    for _i, s in ipairs(seasons) do
        K.weather = s[2]
        tapHeading("garden_season_icon")
        G:wait(0.6)
        G:hold(700)
        tapText(s[1])
        G:wait(0.8)
        G:hold(2000)
    end
end)
