-- The opening card shown while a book opens: the book in home's halo with
-- where reading resumes, its title and a line from the companion. Painted here
-- on its own (opening the book would cover it at once).
local H = ...
local Opening = require("solarui/opening")
H.step(2, function() H.app().open("home") end)
H.step(1.5, function()
    local cur = require("solarui/data/history").current()
    H.check(cur ~= nil and Opening.wanted(cur.path), "the card is on for the book read last")
    H.app().flash(Opening.card(cur.path, require("device").screen:getWidth()))
    H.shot("opening-card")
end)
H.step(1, function() H.app().update() end)
