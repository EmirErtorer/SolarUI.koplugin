-- The garden poster in every state, with a screenshot of each: the first visit
-- (every animal, the guide, sitting in the garden), every hour in every
-- season, every kind of weather, the plants at each stage and when thirsty,
-- wilted or resting for the winter, the animals content, hungry, hiding or
-- asleep, the vine and the maple that reading grows, and the face in the grass.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local State = K.state()
local Settings = require("solarui/settings")
local Cast = K.cast()

local function onGarden() return H.screen() == "garden" end

-- ---------------------------------------------------------------- the first visit
K.do_(function() K.reset({ guide = false, season = "summer", hour = 12 }); K.go() end, 1.5)
K.shot("a01-first-visit-everyone-shown", nil, function()
    H.check(onGarden(), "the garden opens")
    H.check(H.app().current().showcase == true, "the first visit shows every animal that may come")
end)
H.step(11, function()
    H.check(H.app().overlay() ~= nil, "the guide opens by itself after ten seconds")
end)
K.shot("a02-guide-page-1")
for i = 2, 10 do
    K.shot(string.format("a03-guide-page-%02d", i), function() H.tap("Next") end, function() H.check(H.app().overlay() ~= nil, "guide page " .. i .. " shows") end)
end
K.shot("a04-guide-back-once", function() H.tap("Back") end)
K.shot("a05-guide-forward-again", function() H.tap("Next") end)
K.shot("a06-sit-in-the-garden", function() H.tap("Sit in the garden") end, function()
    H.check(H.app().current().sitting == true, "sitting hides the heading and keeps the garden alone")
end)
K.shot("a07-sit-ended-by-a-tap", function() H.tapAt(300, 700) end, function()
    H.check(H.app().current().sitting == false, "a tap ends the sitting")
end)
K.shot("a08-sit-time-is-up", function() H.app().current():sit(); end)
K.shot("a09-sit-asks-what-next", function() H.app().current():endSit(true) end, function()
    H.check(H.app().overlay() ~= nil, "when the time is up the garden asks what next")
end)
K.shot("a10-sit-a-little-longer", function() H.tap("Sit a little longer") end)
K.shot("a11-then-back-to-the-garden", function() H.app().current():endSit(true) end)
K.shot("a12-back-to-the-garden", function() H.tap("Back to the garden") end, function()
    H.check(H.app().overlay() == nil, "the question closes")
end)
K.shot("a13-after-the-guide-only-who-is-there", function()
    H.app().current().showcase = false
    State.markGuide()
    H.app().update()
end)

-- ---------------------------------------------------------------- every hour in every season
for _, season in ipairs({ "spring", "summer", "autumn", "winter" }) do
    for _, hh in ipairs({ { 3, "night" }, { 8, "morning" }, { 13, "day" }, { 19, "golden" } }) do
        K.shot(string.format("b-%s-%s", season, hh[2]), function()
            K.reset({ season = season, hour = hh[1] })
            K.everyone()
            K.settle()
            K.go()
        end, function() H.check(onGarden(), season .. " at " .. hh[1] .. ":00 shows") end)
    end
end

-- ---------------------------------------------------------------- weather
for _, kind in ipairs({ "clear", "cloudy", "rain", "snow", "mist" }) do
    for _, hh in ipairs({ { 13, "day" }, { 3, "night" } }) do
        K.shot(string.format("c-weather-%s-%s", kind, hh[2]), function()
            K.reset({ season = kind == "snow" and "winter" or "spring", hour = hh[1], weather = kind })
            K.everyone(); K.settle(); K.go()
        end, function() H.check(onGarden(), kind .. " weather at " .. hh[1] .. " shows") end)
    end
end

-- ---------------------------------------------------------------- plants at every stage and state
for stage = 1, 5 do
    K.shot("d-plants-stage-" .. stage, function()
        K.reset({}); K.everyone(); K.plants(stage, "fine"); K.go()
    end)
end
K.shot("d-plants-thirsty", function() K.reset({}); K.everyone(); K.plants(4, "thirsty"); K.go() end)
K.shot("d-plants-wilted", function() K.reset({}); K.everyone(); K.plants(4, "wilted"); K.go() end)
K.shot("d-plants-winter-dormant", function() K.reset({ season = "winter" }); K.everyone(); K.plants(4, "fine"); K.go() end)
K.shot("d-plants-winter-wilted", function() K.reset({ season = "winter" }); K.everyone(); K.plants(4, "wilted"); K.go() end)
K.shot("d-three-sisters-not-yet-planted", function() K.reset({}); K.go() end, function()
    H.check(State.get().plants.three_sisters == nil, "the Three Sisters bed is not there before three books")
end)
K.shot("d-three-sisters-planted-after-three-books", function()
    K.reading.books = 3
    State.refresh()
    H.app().update()
end, function()
    H.check(State.get().plants.three_sisters ~= nil, "the Three Sisters bed is planted when three books are finished")
end)

-- ---------------------------------------------------------------- animals
K.shot("e-animals-content-day", function() K.reset({ hour = 13 }); K.everyone(); K.animals("content"); K.go() end)
K.shot("e-animals-content-night", function() K.reset({ hour = 3 }); K.everyone(); K.animals("content"); K.go() end)
K.shot("e-animals-hungry", function() K.reset({ hour = 13 }); K.everyone(); K.animals("hungry"); K.go() end)
K.shot("e-animals-hiding-day", function() K.reset({ hour = 13 }); K.everyone(); K.animals("hiding"); K.go() end)
K.shot("e-animals-hiding-night", function() K.reset({ hour = 3 }); K.everyone(); K.animals("hiding"); K.go() end)
K.shot("e-animals-asleep-winter", function() K.reset({ season = "winter", hour = 13 }); K.everyone(); K.go() end)
K.shot("e-animals-asleep-winter-night", function() K.reset({ season = "winter", hour = 3 }); K.everyone(); K.go() end)
K.shot("e-animals-only-the-first-three", function() K.reset({ hour = 13 }); State.get().animals = { bee = { found = K.t, fed = K.t }, ladybug = { found = K.t, fed = K.t }, snail = { found = K.t, fed = K.t } }; K.go() end)
K.shot("e-new-garden-after-first-refresh", function()
    Settings.set("garden", nil); State.unload(); State.get().guide_seen = true
    State.refresh()
    H.app().update()
end)

-- ---------------------------------------------------------------- what reading grows
local function dates(n)
    local out = {}
    for i = 0, n - 1 do out[#out + 1] = os.date("%Y-%m-%d", K.T0 + i * 86400) end
    return out
end
K.shot("f-vine-none", function() K.reset({}); K.everyone(); K.go() end)
K.shot("f-vine-10-days", function() K.reading.days = dates(10); H.app().update() end)
K.shot("f-vine-29-days", function() K.reading.days = dates(29); H.app().update() end)
K.shot("f-vine-in-flower-45-days", function() K.reading.days = dates(45); H.app().update() end)
K.shot("f-vine-100-days", function() K.reading.days = dates(100); H.app().update() end)
K.shot("f-maple-no-books", function() K.reading.goal, K.reading.year_books = 12, 0; H.app().update() end)
K.shot("f-maple-six-books", function() K.reading.year_books = 6; H.app().update() end)
K.shot("f-maple-goal-met-fruit", function() K.reading.year_books = 12; H.app().update() end)

-- ---------------------------------------------------------------- the face in the grass
K.shot("g-peek-face-in-the-grass", function() K.reset({}); K.everyone(); K.go() end, function()
    H.check(State.peek() ~= nil, "a face peeks out of the grass today")
end)
K.shot("g-peek-found", function() K.tapOn("peek") end, function()
    H.check(State.peek() == nil, "finding the face is counted for the day")
end)
K.shot("g-peek-next-day", function() K.t = K.t + 86400; H.app().update() end, function()
    H.check(State.peek() ~= nil, "and a face peeks again the next day")
end)

-- ---------------------------------------------------------------- the same in dark mode
K.shot("h-dark-mode-day", function()
    K.reset({ hour = 13 }); K.everyone(); K.go()
    require("solarui/theme").set("mode", "dark")
end)
K.shot("h-dark-mode-night", function() Settings.set("garden_hour", 3); H.app().update() end)
K.shot("h-back-to-light", function() require("solarui/theme").set("mode", "light"); H.app().update() end)
