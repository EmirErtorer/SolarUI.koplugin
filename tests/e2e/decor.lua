-- The garden's furniture and ornaments in every kind of weather, and the
-- open book: the garden in summer, on a clear winter day (snow lying) and
-- while snow falls; then the book on the table opened large with a passage
-- that has every detail, turned by the Next button and by tapping the right
-- page, turned back by tapping the left page, "Read on" opening the book at
-- the highlight, a line for the season (nothing to read on), and closing.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)

local function fresh(o)
    K.reset(o or {})
    K.everyone()
    K.plants(4, "fine")
    K.settle()
    K.go()
end

K.shot("d01-summer", function() fresh({ season = "summer", hour = 11 }) end)
K.shot("d02-winter", function() fresh({ season = "winter", hour = 11 }) end)
K.shot("d03-winter-snowing", function() fresh({ season = "winter", hour = 15, weather = "snow" }) end)
-- who is asleep sleeps in their own pose, and none of those that fly sleep in the air
K.shot("d03b-summer-night", function() fresh({ season = "summer", hour = 2 }) end, function()
    local Layout = require("solarui/garden/layout")
    for id in pairs(Layout.ROOSTS) do
        local r = Layout.roost(id)
        H.check(r.y + r.h > Layout.LAWN_TOP, id .. " roosts on the ground, not in the air")
    end
end)

-- the book, with passages of our own so every detail shows
local opened
K.shot("d04-the-book", function()
    fresh({ season = "summer", hour = 11 })
    require("solarui/actions").openAt = function(path, place) opened = { path = path, place = place } end
    local screen = H.app().current()
    screen.quotes = {
        { text = "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.", title = "Pride and Prejudice",
            author = "Jane Austen", path = "/books/pride.epub", chapter = "Chapter 1", pageno = 3, date = "2026-03-03 14:22:10", note = "The opening everyone remembers.", page = 3, pos0 = "x" },
        { text = "The garden sleeps under the snow and dreams of green.", title = "From the garden", author = "Winter" },
        { text = "Whatever our souls are made of, his and mine are the same.", title = "Wuthering Heights", author = "Emily Brontë", path = "/books/wh.epub", pageno = 81 },
    }
    screen.quote_at = 1
    K.tapOn("book")
end, function()
    H.check(H.app().current().focus == "book", "the book opens")
    H.check(H.find("Chapter 1") ~= nil and H.find("Page 3") ~= nil, "the left page shows the chapter and the page")
    H.check(H.find("Highlighted on 3 March 2026") ~= nil, "and the day it was highlighted")
    H.check(H.find("Your note: The opening everyone remembers.") ~= nil, "and the reader's note")
    H.check(H.find("1 of 3") ~= nil, "the foot of the right page numbers the passage")
end)
K.shot("d05-read-on", function() H.tap("Read on") end, function()
    H.check(opened and opened.path == "/books/pride.epub" and opened.place.page == 3, "Read on opens the book at the highlight")
end)
K.shot("d06-next-button", function() H.tap("Next") end, function()
    H.check(H.find("2 of 3") ~= nil and H.find("From the garden") ~= nil, "Next turns to the season's line")
end)
K.shot("d07-tap-right-page", function()
    local quote = H.findWhere(function(e) return type(e.text) == "string" and e.text:find("^\u{201C}") end)
    if quote then H.tapAt(quote.x + quote.w / 2, quote.y + quote.h / 2) end
end, function()
    H.check(H.find("3 of 3") ~= nil and H.find("Wuthering Heights") ~= nil, "tapping the right page turns to the next passage")
end)
K.shot("d08-tap-left-page", function()
    local name = H.findWhere(function(e) return type(e.text) == "string" and e.text == "Wuthering Heights" end)
    if name then H.tapAt(name.x + name.w / 2, name.y + name.h / 2) end
end, function()
    H.check(H.find("2 of 3") ~= nil, "tapping the left page turns back")
end)
K.shot("d09-close", function() H.tap("Back to the garden") end, function()
    H.check(H.app().current().focus == nil, "Back to the garden closes the book")
end)
