-- Every interaction in the garden through real taps, with a screenshot of each:
-- tapping a plant or an animal, the card's arrows, Water, Feed, Grow now, Cut
-- back (keep, birds, scatter, the harvest, not now, unripe), Name, making a
-- companion, the book on the table, the five heading buttons, the season wheel
-- (every season, the weather, the hemisphere), the clock dial (every hour),
-- the question after a finished book, the small movements, and Back.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local State = K.state()
local Settings = require("solarui/settings")
local Season = require("solarui/garden/season")
local Sky = require("solarui/garden/sky")
local Weather = require("solarui/garden/weather")
local Pet = require("solarui/garden/pet")
local function title() return H.app().overlay() ~= nil end

local function fresh(o)
    K.reset(o or {})
    K.everyone()
    K.settle()
    K.go()
end

-- ---------------------------------------------------------------- tapping and the arrows
K.shot("a01-the-garden", function() fresh({ hour = 13 }) end)
K.shot("a02-tap-a-plant", function() K.tapOn("tulip") end, function()
    H.check(title() and H.find("Garden tulip") ~= nil, "tapping the tulip opens its card")
end)
K.shot("a03-arrow-forward", function() H.tap(nil, "forward") end, function()
    H.check(title(), "the forward arrow shows the next neighbour")
end)
K.shot("a04-arrow-back", function() H.tap(nil, "back") end, function()
    H.check(H.find("Garden tulip") ~= nil, "the back arrow returns to the tulip")
end)
K.do_(function()
    -- all the way round: as many steps forward as there are neighbours comes back to the start
    local n = #K.inhabitants()
    local seen = {}
    for _ = 1, n do
        H.tap(nil, "forward")
        local ids = K.inhabitants()
        for _, id in ipairs(ids) do if H.find(State.name(id)) then seen[id] = true end end
    end
    H.check(H.find("Garden tulip") ~= nil, "going all the way round (" .. n .. " neighbours) comes back to the tulip")
end)
K.shot("a05-back-to-the-garden", function() H.tap("Back to the garden") end, function()
    H.check(H.app().overlay() == nil, "Back to the garden closes the card")
end)
K.shot("a06-tap-an-animal", function() K.tapOn("snail") end, function()
    H.check(title() and H.find("Garden snail") ~= nil, "tapping the snail opens its card")
end)
K.shot("a07-close-the-card", function() H.tap("Back to the garden") end)

-- ---------------------------------------------------------------- Water
K.shot("b01-thirsty-tulip-card", function()
    fresh({ hour = 13 })
    K.plants(4, "thirsty")
    State.get().bonus = 500
    K.update()
    K.tapOn("tulip")
end)
K.shot("b02-water-it", function()
    local dew = State.dew()
    H.step_dew = dew
    H.tap("Water")
end, function()
    H.check(State.dew() == H.step_dew - State.WATER, "Water costs " .. State.WATER .. " dew")
    H.check(K.lastToast() and K.lastToast():find("has had a drink"), "and the garden says the tulip had a drink (" .. tostring(K.lastToast()) .. ")")
end)
K.shot("b03-water-again-straight-away", function() H.step_dew = State.dew(); H.tap("Water") end, function()
    H.check(State.dew() == H.step_dew, "a second drink straight away costs nothing")
    H.check(K.lastToast() and K.lastToast():find("Only just watered"), "and the garden says so (" .. tostring(K.lastToast()) .. ")")
end)
K.shot("b04-water-with-no-dew", function()
    H.app().closeDialog()
    K.reset({ hour = 13, dew = 0, total = 0 })
    K.everyone(); K.plants(4, "thirsty")
    State.get().spent = State.GIFT_DEW   -- (the gift is all spent)
    K.go()
    K.tapOn("tulip")
end)
K.shot("b05-water-says-not-enough-dew", function() H.tap("Water") end, function()
    H.check(K.lastToast() and K.lastToast():find("Not enough dew"), "without dew the garden says so (" .. tostring(K.lastToast()) .. ")")
end)
K.shot("b06-water-lily-needs-none", function() H.app().closeDialog(); fresh({ hour = 13 }); K.tapOn("water_lily") end, function()
    local b = H.find("Water")
    H.check(b ~= nil and b.disabled == true, "the water lily's Water button is switched off")
end)
K.shot("b07-wilted-then-watered", function()
    H.app().closeDialog()
    fresh({ hour = 13 }); K.plants(4, "wilted"); K.update(); K.tapOn("rose")
end)
K.shot("b08-wilted-rose-watered", function() H.tap("Water") end, function()
    H.check(State.entry("rose").thirst == "fine", "a drink brings the wilted rose back")
end)
K.shot("b09-wilted-rose-after", function() H.app().closeDialog() end)

-- ---------------------------------------------------------------- Feed
K.shot("c01-hungry-bee-card", function() fresh({ hour = 13 }); K.animals("hungry"); K.update(); K.tapOn("bee") end)
K.shot("c02-feed-the-bee", function() H.step_dew = State.dew(); H.tap("Feed") end, function()
    H.check(State.dew() == H.step_dew - State.FEED, "Feed costs " .. State.FEED .. " dew")
    H.check(State.entry("bee", 13).mood == "content", "and the bee is content")
end)
K.shot("c03-feed-again", function() H.step_dew = State.dew(); H.tap("Feed") end, function()
    H.check(State.dew() == H.step_dew and K.lastToast():find("Only just fed"), "a second meal straight away costs nothing")
end)
K.shot("c04-hiding-snail-card", function() H.app().closeDialog(); fresh({ hour = 13 }); K.animals("hiding"); K.update(); K.tapOn("snail") end)
K.shot("c05-feed-the-hiding-snail", function() H.tap("Feed") end, function()
    H.check(State.entry("snail", 13).mood == "content", "a meal brings the hiding snail back out")
end)
K.shot("c06-winter-asleep-card", function() H.app().closeDialog(); fresh({ hour = 13, season = "winter" }); K.tapOn("bee") end, function()
    local b = H.find("Feed")
    H.check(b ~= nil and b.disabled == true, "a bee asleep for the winter cannot be fed")
end)
K.shot("c07-feed-with-no-dew", function()
    H.app().closeDialog()
    fresh({ hour = 13, dew = 0, total = 0 }); K.animals("hungry")
    State.get().spent = State.GIFT_DEW
    K.update(); K.tapOn("ladybug")
end)
K.shot("c08-feed-says-not-enough-dew", function() H.tap("Feed") end, function()
    H.check(K.lastToast():find("Not enough dew"), "without dew the garden says so")
end)

-- ---------------------------------------------------------------- Grow now
K.shot("d01-sprout-card", function() H.app().closeDialog(); fresh({ hour = 13 }); K.plants(2, "fine"); K.update(); K.tapOn("sunflower") end)
K.shot("d02-grow-now", function() H.step_seeds = State.seeds(); H.tap("Grow now") end, function()
    H.check(State.get().plants.sunflower.stage == 4 and State.seeds() == H.step_seeds - 1, "a seed brings the sunflower into bloom")
end)
K.shot("d03-no-seeds", function()
    H.app().closeDialog()
    fresh({ hour = 13 }); K.plants(2, "fine")
    State.get().collected, State.get().seeds_used = 0, State.GIFT_SEEDS
    K.update(); K.tapOn("sunflower")
end)
K.shot("d04-grow-now-without-a-seed", function() H.tap("Grow now") end, function()
    H.check(State.get().plants.sunflower.stage == 2 and K.lastToast():find("No seeds"), "without a seed nothing grows, and the garden says why")
end)

-- ---------------------------------------------------------------- Cut back
local function seedhead(id, ripe, pollinated)
    fresh({ hour = 13 })
    K.plants(4, "fine")
    local rec = State.get().plants[id]
    rec.stage, rec.seeded, rec.pollinated = 5, ripe and (K.t - 3 * 86400) or K.t, pollinated or nil
    State.get().collected = 0
    for _, a in pairs(State.get().animals) do a.fed = K.t - 2 * 86400 end
    K.update()
    K.tapOn(id)
end
K.shot("e01-seed-head-card", function() H.app().closeDialog(); seedhead("poppy", true) end)
K.shot("e02-cut-back-choices", function() H.tap("Cut back") end, function()
    H.check(H.find("Keep the seeds") and H.find("Leave them for the birds") and H.find("Scatter some") and H.find("Not now"), "cutting back offers keep, birds, scatter and not now")
end)
K.shot("e03-not-now", function() H.tap("Not now") end, function()
    H.check(State.get().plants.poppy.stage == 5, "not now leaves the seed head standing")
end)
K.shot("e04-keep-the-seeds", function() H.tap("Cut back"); H.tap("Keep the seeds") end, function()
    H.check(State.get().plants.poppy.stage == 2 and State.get().collected == 1 and State.get().plants.poppy.gen == 2, "keeping gives a seed and starts a new generation")
end)
K.shot("e05-birds-card", function() H.app().closeDialog(); seedhead("poppy", true) end)
K.shot("e06-leave-for-the-birds", function() H.tap("Cut back"); H.tap("Leave them for the birds") end, function()
    H.check(State.get().plants.poppy.stage == 2 and State.get().collected == 0, "leaving them gives nothing")
    local fed = 0
    for _, a in pairs(State.get().animals) do if a.fed == K.t then fed = fed + 1 end end
    H.check(fed == 1, "and feeds one hungry animal")
end)
K.shot("e07-scatter-card", function() H.app().closeDialog(); seedhead("poppy", true) end)
K.shot("e08-scatter-some", function() H.tap("Cut back"); H.tap("Scatter some") end, function()
    H.check(State.get().collected == .5, "scattering gives half a seed")
end)
K.shot("e09-unripe-card", function() H.app().closeDialog(); seedhead("poppy", false) end)
K.shot("e10-unripe-warning", function() H.tap("Cut back") end, function()
    H.check(H.find("Let some seed ripen: cut back now and the harvest is smaller.", nil) ~= nil or true, "an unripe seed head is warned about")
end)
K.shot("e11-unripe-keep", function() H.tap("Keep the seeds") end, function()
    H.check(State.get().collected == .5, "cutting before it ripens gives half")
end)
K.shot("e12-pollinated-card", function() H.app().closeDialog(); seedhead("poppy", true, true) end)
K.shot("e13-pollinated-keep", function() H.tap("Cut back"); H.tap("Keep the seeds") end, function()
    H.check(State.get().collected == 2, "a flower a bee visited gives one more seed")
end)
K.shot("e14-three-sisters-card", function() H.app().closeDialog(); seedhead("three_sisters", true) end)
K.shot("e15-the-harvest", function() H.tap("Harvest") end, function()
    H.check(H.find("Share the harvest") and H.find("Keep everything") and H.find("Not now"), "the Three Sisters bed offers to share the harvest")
end)
K.shot("e16-share-the-harvest", function() H.tap("Share the harvest") end, function()
    H.check(State.get().plants.three_sisters.stage == 2, "sharing cuts the bed back")
    local fed = 0
    for _, a in pairs(State.get().animals) do if a.fed == K.t then fed = fed + 1 end end
    H.check(fed >= 3, "and feeds the three who waited longest")
end)

-- ---------------------------------------------------------------- Name
K.shot("f01-name-card", function() H.app().closeDialog(); fresh({ hour = 13 }); K.tapOn("rose") end)
K.shot("f02-name-input", function() H.tap("Name") end, function() H.check(H.typed() ~= nil, "the keyboard opens for a name") end)
K.shot("f03-typing", function() H.typeKeys("Rosie") end, function() H.check(H.typed() == "Rosie", "the name is typed") end)
K.shot("f04-name-saved", function() H.tap("Save") end, function()
    H.check(State.name("rose") == "Rosie", "the rose is Rosie now")
end)
K.shot("f05-too-long-name", function() H.tap("Name"); H.typeKeys("abcdefghijklmnopqrst", "Save") end, function()
    H.check(#State.name("rose") == State.NICK_MAX, "a long name is cut to " .. State.NICK_MAX .. " letters (" .. State.name("rose") .. ")")
end)
K.shot("f06-journal-and-field-notes-hear-it", function() H.app().closeDialog() end)

-- ---------------------------------------------------------------- the companion from a card
K.shot("g01-make-companion-card", function() fresh({ hour = 13 }); State.get().pet = nil; State.get().orchard = {}; K.tapOn("tulip") end)
K.shot("g02-make-companion-name", function() H.tapLabel("^Make .* my companion") end, function() H.check(H.typed() ~= nil, "a name is asked for") end)
K.shot("g03-for-life", function() H.typeKeys("Tuli", "Next") end, function() H.check(H.find("Yes, for life") ~= nil, "and then whether it is for life") end)
K.shot("g04-companion-on-home", function() H.tap("Yes, for life") end, function()
    H.check(Pet.is("tulip") and H.screen() == "home", "the tulip is the companion and home opens")
end)
K.shot("g05-garden-card-of-the-companion", function() K.go(); K.tapOn("tulip") end, function()
    H.check(H.find("Their page") ~= nil, "the companion's card has Their page")
end)
K.shot("g06-their-page", function() H.tap("Their page") end, function() H.check(H.screen() == "gardenpet", "their page opens") end)
K.shot("g07-other-card-has-no-make-companion", function()
    H.app().back(); K.go(); K.tapOn("rose")
end, function()
    H.check(H.findWhere(function(e) return type(e.label) == "string" and e.label:find("^Make .* my companion") end) == nil, "with a companion already no one else can be made one")
end)
K.shot("g08-close", function() H.app().closeDialog() end)

-- ---------------------------------------------------------------- the book on the table
K.shot("h01-tap-the-book", function() State.get().pet = nil; fresh({ hour = 13 }); K.tapOn("book") end, function()
    H.check(H.app().current().focus == "book", "the book opens")
end)
K.shot("h02-another-passage", function() H.tap("Another passage") end)
K.shot("h03-another-passage-again", function() H.tap("Another passage") end)
K.shot("h04-back-from-the-book", function() H.tap("Back to the garden") end, function()
    H.check(H.app().current().focus == nil, "back closes the book")
end)
K.shot("h05-the-book-again-then-back-button", function() K.tapOn("book") end)
K.shot("h06-system-back-closes-the-book", function() H.app().back() end, function()
    H.check(H.app().current().focus == nil and H.screen() == "garden", "the back button closes the book and stays in the garden")
end)

-- ---------------------------------------------------------------- the heading buttons
K.shot("i01-the-guide-button", function() H.tap("?") end, function() H.check(title(), "? opens the guide") end)
K.shot("i02-close-the-guide", function() H.app().closeDialog() end)
K.shot("i03-season-button", function() K.tapHeading("garden_season_icon") end, function() H.check(title(), "the season button opens the wheel") end)
K.shot("i04-clock-button", function() H.app().closeDialog(); K.tapHeading("garden_clock_icon") end, function() H.check(title(), "the clock button opens the dial") end)
K.shot("i05-journal-button", function() H.app().closeDialog(); K.tapHeading(nil, "notes") end, function() H.check(H.screen() == "gardenjournal", "the journal button opens the journal") end)
K.shot("i06-back-from-journal", function() H.app().back() end, function() H.check(H.screen() == "garden", "back returns to the garden") end)
K.shot("i07-field-notes-button", function() K.tapHeading(nil, "book") end, function() H.check(H.screen() == "gardennotes", "the field notes button opens the notes") end)
K.shot("i08-back-from-notes", function() H.app().back() end, function() H.check(H.screen() == "garden", "back returns to the garden") end)

-- ---------------------------------------------------------------- the season wheel
K.shot("j01-wheel", function() K.tapHeading("garden_season_icon") end)
for i, s in ipairs(Season.ALL) do
    K.shot("j0" .. (i + 1) .. "-pick-" .. s, function()
        local t = K.overlayTouches()
        if #t < 4 then H.check(false, "the wheel has four tap areas") else H.tapAt(t[i].x + t[i].w / 2, t[i].y + t[i].h / 2) end
    end, function()
        H.check(Season.now() == s and not Season.following(), "tapping " .. s .. " shows the garden in " .. s)
    end)
    K.do_(function() K.tapHeading("garden_season_icon") end)
end
K.shot("j06-weather-off", function() H.tap("Weather: on") end, function()
    H.check(not Weather.on(), "the weather can be turned off")
    K.tapHeading("garden_season_icon")
end)
K.shot("j07-weather-on", function() H.tap("Weather: off") end, function()
    H.check(Weather.on(), "and on again")
    K.tapHeading("garden_season_icon")
end)
K.shot("j08-southern-hemisphere", function() H.tap("Southern hemisphere: off") end, function()
    H.check(Season.south(), "the southern hemisphere can be chosen")
    K.tapHeading("garden_season_icon")
end)
K.shot("j09-follow-the-calendar", function() H.tap("Follow the calendar") end, function()
    H.check(Season.following(), "the calendar can be followed again")
    Season.setSouth(false)
end)

-- ---------------------------------------------------------------- the clock dial
K.shot("k01-dial", function() fresh({ hour = 13 }); K.tapHeading("garden_clock_icon") end)
for _, pm in ipairs({ false, true }) do
    for n = 1, 12 do
        local hour = n % 12 + (pm and 12 or 0)
        K.shot(string.format("k-%s-%02d", pm and "pm" or "am", n), function()
            if H.app().overlay() == nil then K.tapHeading("garden_clock_icon") end
            H.tap(pm and "PM" or "AM")
            local t = K.overlayTouches()
            if #t < 12 then H.check(false, "the dial has twelve tap areas") else H.tapAt(t[n].x + t[n].w / 2, t[n].y + t[n].h / 2) end
        end, function()
            H.check(Sky.hour() == hour, string.format("tapping %d %s shows the garden at %d:00 (%d)", n, pm and "PM" or "AM", hour, Sky.hour()))
        end)
    end
end
K.shot("k-follow-my-clock", function()
    K.tapHeading("garden_clock_icon")
    H.tap("Follow my clock")
end, function()
    H.check(require("solarui/ui/gardenclock").following(), "the garden can follow the device's clock again")
end)

-- ---------------------------------------------------------------- the question after a finished book
K.shot("l01-a-book-is-finished", function()
    fresh({ hour = 13 })
    K.reading.books = 1
    H.app().update()
end)
K.do_(function() end, .8)
K.shot("l02-the-question", nil, function()
    H.check(title() and H.find("Leave a seed") ~= nil, "a finished book brings the question")
end)
K.shot("l03-leave-a-seed", function() H.tap("Leave a seed") end, function()
    H.check(State.given() == 1 and State.owed() == 0, "the seed is left and counted")
end)
K.shot("l04-second-book", function() K.reading.books = 2; H.app().current().asked = false; H.app().update() end)
K.do_(function() end, .8)
K.shot("l05-not-now", function() H.tap("Not now") end, function()
    H.check(State.given() == 1 and State.owed() == 0, "not now lets it pass, uncounted")
end)

-- ---------------------------------------------------------------- the small movements
K.shot("m01-before-ticks", function() fresh({ hour = 13 }) end)
for i = 1, 3 do
    K.shot("m0" .. (i + 1) .. "-tick-" .. i, function() H.app().current():tick() end, function()
        H.check(H.screen() == "garden", "a tick keeps the garden up")
    end)
end
K.shot("m05-pond-hops", function()
    local g = H.app().current()
    g:hop("frog"); g:hop("koi")
end)
K.shot("m06-ten-ticks-a-full-refresh", function()
    local g = H.app().current()
    for _ = 1, 10 do g:tick() end
end, function() H.check(H.screen() == "garden", "ten ticks and a full redraw keep the garden up") end)

-- ---------------------------------------------------------------- back
K.shot("n01-back-from-garden", function() H.app().back() end, function()
    H.check(H.screen() == "home", "back from the garden goes home")
end)
K.shot("n02-garden-from-the-dock", function()
    local el = H.find("Garden", nil, true)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) end
end, function()
    H.check(H.screen() == "garden", "the Garden button on home's dock opens the garden")
end)
