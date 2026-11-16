-- The open book on the garden's table: in the middle, clear over the faded
-- garden, with the reader's highlights and the garden's lines in two parts.
local H = ...
local UIManager = require("ui/uimanager")
local function paint() UIManager:forceRePaint() end
local function says(text)
    local found = false
    H.findWhere(function(el) if el.text == text or el.label == text then found = true end return false end)
    return found
end
H.step(2, function() H.app().go("garden") end)
H.step(2, function() local g = H.app().current(); g.focus = "book"; H.app().update() end)
H.step(2, function()
    paint(); H.shot("b1-highlights")
    local g = H.app().current()
    H.check(g.part ~= nil, "the book opens on a part (" .. tostring(g.part) .. ")")
    H.check(says("Your highlights") and says("From the garden"), "the switch shows both parts")
    local q = g:quote()
    H.check(g.part ~= "highlights" or (q and q.path ~= nil), "a highlight is from one of the reader's books")
end)
H.step(.5, function() H.tap("From the garden") end)
H.step(2, function()
    paint(); H.shot("b2-garden")
    local g = H.app().current()
    local q = g:quote()
    H.check(g.part == "garden" and q and q.path == nil, "the garden's part shows the garden's lines")
    H.check(not says("Read on"), "no Read on for the garden's lines")
end)
H.step(.5, function() H.tap("Next") end)
H.step(1.5, function() paint(); H.shot("b3-garden-next") end)
H.step(.5, function() H.tap("Your highlights") end)
H.step(1.5, function() paint(); H.shot("b4-back-to-highlights") end)
