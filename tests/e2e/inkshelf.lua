-- The notebook shelf (home's Notebooks button): Ink Away's notebooks standing
-- in their covers as they are drawn, the Drawings tab with the drawings in
-- their frames, a long press choosing another cover, and a tap opening a
-- notebook in Ink Away, closed again back to the shelf.
-- Run with HOME_SETUP pointing at a script that copies Ink Away's library in.
local H = ...
local UIManager = require("ui/uimanager")
local function paint() UIManager:forceRePaint() end
local function tiles()
    local out = {}
    H.findWhere(function(el) if el.on_hold and el.name and el.on_tap and el.x then out[#out + 1] = el end return false end)
    return out
end
local function inkView()
    for _i, w in ipairs(UIManager._window_stack or {}) do
        if w.widget and w.widget.name == "inkaway_view" then return w.widget end
    end
end

H.step(2, function()
    local Launcher = require("solarui/data/launcher")
    H.check(Launcher.get("notebooks") ~= nil and not Launcher.get("notebooks").hidden, "home has the Notebooks button")
    H.check(Launcher.get("search").hidden, "the search it replaced is hidden")
    H.app().go("home")
end)
H.step(1.5, function() paint(); H.shot("i00-home") end)
H.step(.5, function() H.app().push("inkshelf") end)
H.step(1.5, function() paint(); H.shot("i01-notebooks-first") ; H.check(#tiles() > 0, "the shelf shows Ink Away's notebooks (" .. #tiles() .. ")") end)
H.step(14, function() paint(); H.shot("i02-notebooks-drawn") end)
H.step(.5, function()
    local covered = 0
    for _i, t in ipairs(tiles()) do if t.file then covered = covered + 1 end end
    H.check(covered > 0, "covers have been drawn (" .. covered .. " of " .. #tiles() .. ")")
    H.tap("Drawings")
end)
H.step(14, function() paint(); H.shot("i03-drawings"); H.check(#tiles() > 0, "the Drawings tab shows the drawings (" .. #tiles() .. ")") end)
H.step(.5, function() H.tap("Notebooks") end)
H.step(1.5, function()
    paint()
    local t = tiles()[1]
    H.queen_was = t and t.file
    if t then H.holdAt(t.x + t.w / 2, t.y + t.h / 2) end
end)
H.step(2.5, function() paint(); H.shot("i04-pick-cover"); H.check(H.app().current().params and H.app().current().params.kind == "notebooks", "a long press opens the cover picker") end)
H.step(.5, function()
    local pick
    H.findWhere(function(el) if el.on_tap and el.child and not pick and el.double ~= true and el.x then pick = el end return false end)
    if pick then H.tapAt(pick.x + pick.w / 2, pick.y + pick.h / 2) end
end)
H.step(3, function()
    paint(); H.shot("i05-cover-changed")
    local t = tiles()[1]
    H.check(t and t.file and t.file ~= H.queen_was, "the notebook has its new cover")
end)
H.step(.5, function()
    local t = tiles()[1]
    if t then H.tapAt(t.x + t.w / 2, t.y + t.h / 2) end
end)
H.step(4, function()
    paint(); H.shot("i06-opened-in-ink-away")
    H.check(inkView() ~= nil, "a tap opens the notebook in Ink Away")
    local v = inkView()
    if v then UIManager:close(v) end
end)
H.step(3, function() paint(); H.shot("i07-back-on-the-shelf"); H.check(inkView() == nil and H.app().current() and H.app().current().kind ~= nil, "closing Ink Away comes back to the shelf") end)
