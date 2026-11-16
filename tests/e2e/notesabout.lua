-- The field notes' About tab: bold headings, both books to read.
local H = ...
local function says(text)
    local found = false
    H.findWhere(function(el) if el.text == text or el.label == text then found = true end return false end)
    return found
end
H.step(2, function() H.app().open("garden") end)
H.step(1, function() H.app().push("gardennotes") end)
H.step(1, function() H.tap("About") end)
H.step(1.5, function()
    require("ui/uimanager"):forceRePaint(); H.shot("about-1")
    H.check(says("Why \"they\"") and says("A book to read"), "the About tab shows its headings")
end)
H.step(.5, function() H.app().current():setPage(2) end)
H.step(1.5, function()
    require("ui/uimanager"):forceRePaint(); H.shot("about-2")
    H.check(says("Another book to read"), "The Overstory is there too")
end)
