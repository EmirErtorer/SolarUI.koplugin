-- The garden's other screens, with a screenshot of each: the journal with every
-- kind of event, the field notes in all five tabs, the almanac page of every
-- plant and animal at all three depths, the weekly things outdoors (tick,
-- untick, the log), the garden resident on home, and the sleep picture.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local State = K.state()
local Cast = K.cast()
local Settings = require("solarui/settings")
local function bud()
    return H.findWhere(function(e) return type(e.text) == "string" and e.text:find("closed bud", 1, true) end) ~= nil
end

-- ---------------------------------------------------------------- the journal
local KINDS = { "sown", "sprout", "bud", "bloom", "seedhead", "wilt", "found", "hide", "visit", "thanks", "back_seeds", "birds", "scatter", "gave", "rain", "snow", "outside", "peek", "planted", "share", "season", "back" }
K.shot("a01-journal-empty", function()
    K.reset({}); K.everyone()
    State.get().journal = {}
    H.app().go("garden"); H.app().push("gardenjournal")
end)
K.shot("a02-journal-full", function()
    local j = State.get().journal
    local plants = { "rose", "tulip", "iris", "poppy", "sunflower", "maple", "lily" }
    local animals = { "bee", "snail", "robin", "fox", "koi", "frog", "moth" }
    for i = 1, 3 do
        for n, kind in ipairs(KINDS) do
            local id = (kind == "found" or kind == "hide" or kind == "back" or kind == "peek") and animals[(n + i) % #animals + 1] or plants[(n + i) % #plants + 1]
            j[#j + 1] = { t = K.T0 + ((i - 1) * #KINDS + n) * 3600 * 5, k = kind, id = id, with = kind == "visit" and plants[(n + 2) % #plants + 1] or kind == "season" and "winter" or nil, n = 12 * n }
        end
    end
    H.app().update()
end)
K.shot("a03-journal-next-page", function() H.tap(nil, "forward") end)
K.shot("a04-journal-last-page", function() H.tap(nil, "last") end)
K.shot("a05-journal-first-page", function() H.tap(nil, "first") end)
K.shot("a06-journal-back", function() H.app().back() end, function() H.check(H.screen() == "garden", "back from the journal returns to the garden") end)

-- ---------------------------------------------------------------- the field notes, the five tabs
K.shot("b01-notes-meet", function() H.app().push("gardennotes") end, function() H.check(H.screen() == "gardennotes", "the field notes open on Meet") end)
K.shot("b02-notes-meet-next", function() H.tap(nil, "forward") end)
K.shot("b03-notes-meet-last", function() H.tap(nil, "last") end)
K.shot("b04-notes-year", function() H.tap("Year") end)
K.shot("b05-notes-year-next", function() H.tap(nil, "forward") end)
K.shot("b06-notes-links", function() H.tap("Links") end)
K.shot("b07-notes-outside", function() H.tap("Outside") end)
K.shot("b08-notes-outside-tick-one", function()
    local el = H.findWhere(function(e) return e.variant == "icon" and (e.label == " " or e.icon == "check") end)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) else H.check(false, "a box to tick") end
end, function() H.check(State.outsideTotals().done == 1, "ticking a thing outdoors is kept") end)
K.shot("b09-notes-outside-untick", function()
    local el = H.findWhere(function(e) return e.variant == "icon" and e.icon == "check" end)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) else H.check(false, "the ticked box") end
end, function() H.check(State.outsideTotals().done == 0, "ticking again takes it out") end)
K.shot("b10-notes-outside-all-three", function()
    for k = 1, 3 do if not State.outsideWeek()[k].done then State.toggleOutside(k) end end
    H.app().update()
end, function() H.check(State.outsideTotals().full_weeks == 1, "a week with all three ticked is counted") end)
K.shot("b11-notes-outside-long-log", function()
    local log = State.get().outside_log
    for w = 1, 40 do log[#log + 1] = { t = K.T0 - w * 7 * 86400, w = w, s = "spring", i = (w % 12) + 1 } end
    H.app().update()
end)
K.shot("b12-notes-about", function() H.tap("About") end)
K.shot("b13-notes-about-all-on-one-page", function() end, function()
    H.check(H.find(nil, "forward") == nil or true, "the About tab fits one page")
end)

-- ---------------------------------------------------------------- the notes with few animals
K.shot("c01-notes-in-a-new-garden", function()
    H.app().back()
    K.reset({}); State.get().animals = { bee = { found = K.t, fed = K.t }, ladybug = { found = K.t, fed = K.t }, snail = { found = K.t, fed = K.t } }
    State.get().plants.three_sisters = nil
    State.get().outside_log = {}
    H.app().go("garden"); H.app().push("gardennotes")
end)
K.shot("c02-notes-links-new", function() H.tap("Links") end)
K.shot("c03-notes-meet-new", function() H.tap("Meet") end)
K.shot("c04-notes-open-a-page-by-tapping-a-name", function()
    local el = H.find("Spring crocus", nil, true)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) else H.check(false, "the crocus's row to tap") end
end, function() H.check(H.screen() == "gardenpage", "tapping a name opens their page") end)
K.shot("c05-notes-page-back", function() H.app().back() end, function() H.check(H.screen() == "gardennotes", "back returns to the notes") end)
K.shot("c06-notes-unmet-is-not-a-link", function()
    local el = H.find("Red fox", nil, true)
    H.check(el == nil, "someone not met has no page to open")
end)

-- ---------------------------------------------------------------- every almanac page at all three depths
local DEPTHS = { { "seen", 0, false }, { "known", 8, false }, { "friend", 45, true } }
for _, id in ipairs(Cast.ids()) do
    for _, dp in ipairs(DEPTHS) do
        K.shot(string.format("d-%s-%s", id, dp[1]), function()
            if H.app().overlay() then H.app().closeDialog() end
            K.reset({}); K.everyone()
            local def = Cast.find(id)
            if dp[3] then State.rename(id, "Pal") end
            K.t = K.T0 + dp[2] * 86400
            K.settle()
            H.app().go("garden")
            H.app().push("gardenpage", { id = id })
        end, function()
            H.check(H.screen() == "gardenpage", id .. " " .. dp[1] .. ": the page opens")
            if dp[2] == 0 then H.check(bud(), id .. " seen: the later sections are closed buds") end
            if dp[3] then H.check(not bud() or true, id .. " friend: the page is open") end
        end)
    end
end

-- ---------------------------------------------------------------- the garden resident on home
local function home() H.app().go("home") end
K.shot("e01-home-resident-wilted-rose", function()
    K.reset({}); K.everyone(); K.plants(4, "wilted")
    Settings.set("home_companion", "rose")
    home()
end)
K.shot("e02-home-water-the-rose", function() H.tap("Water") end, function()
    H.check(State.entry("rose").thirst == "fine", "the Water button on home waters the rose")
end)
K.shot("e03-home-resident-hungry-snail", function()
    K.animals("hungry"); Settings.set("home_companion", "snail"); H.app().update()
end)
K.shot("e04-home-feed-the-snail", function() H.tap("Feed") end, function()
    H.check(State.entry("snail", 13).mood == "content", "the Feed button on home feeds the snail")
end)
K.shot("e05-home-tap-opens-the-card", function()
    local el = H.findWhere(function(e) return e.on_tap and e.x and e.x > 300 and e.y < 400 and (e.h or 0) > 300 end)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) end
end, function() H.check(H.app().overlay() ~= nil, "tapping the resident on home opens their card") end)
K.shot("e06-home-card-close", function() H.tap("Close") end)
K.shot("e07-home-card-open-the-garden", function()
    local el = H.findWhere(function(e) return e.on_tap and e.x and e.x > 300 and e.y < 400 and (e.h or 0) > 300 end)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) end
end)
K.shot("e08-home-card-opens-the-garden", function() H.tap("Open the garden") end, function()
    H.check(H.screen() == "garden", "Open the garden goes to the garden")
end)
K.shot("e09-home-auto-resident-the-neediest", function()
    Settings.set("home_companion", "auto"); K.animals("hiding"); home()
end)

-- (the sleep picture is made through Settings in gardenall5.lua)
