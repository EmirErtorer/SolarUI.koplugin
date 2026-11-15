-- Yüzsüz The Magnificent in the garden: the garden with her in it, her card
-- with its four buttons and her many names, a tap on her picture (another pose), a pat on the
-- right side too many (the bite), her food menu, her popup over home and a tap
-- on her picture there, and her as the companion on home.
local H = ...
local UIManager = require("ui/uimanager")
local function paint() UIManager:forceRePaint() end
H.step(1.5, function()
    local Pet = require("solarui/garden/pet")
    local State = require("solarui/garden/state")
    State.get().guide_seen = true
    State.refresh()
    if Pet.get() then Pet.goodbye() end
    H.check(State.rec("yuzsuz") ~= nil, "the queen is in the garden")
    H.app().go("garden")
end)
H.step(1.5, function() paint(); H.shot("q-garden") end)
H.step(.5, function()
    local screen = H.app().current()
    screen.focus = "yuzsuz"
    H.app().update()
end)
H.step(1.2, function()
    paint(); H.shot("q-card")
    -- under her name, the card says she is known by many, many names, in full
    local label
    H.findWhere(function(el) if el.text and tostring(el.text):find("many, many names", 1, true) then label = el end return false end)
    H.check(label ~= nil, "her card says she is known by many, many names across the multiverse")
    local shown = label and table.concat(label.shown or { label.text }, " ") or ""
    H.check(shown:find("multiverse", 1, true) and not shown:find("\226\128\166", 1, true), "and the line is not cut: " .. shown)
end)
-- a tap on her big picture shows her in another pose
H.step(.5, function()
    local Yuzsuz = require("solarui/garden/yuzsuz")
    H.queen_was = Yuzsuz.shown(H.app().current().pose.yuzsuz)
    local box
    H.findWhere(function(el) if el.on_tap and el.y and el.y < 600 and (el.h or 0) > 150 then box = el end return false end)
    H.check(box ~= nil, "her picture on the card answers a tap")
    if box then H.tapAt(box.x + box.w / 2, box.y + box.h / 2) end
end)
H.step(1, function()
    local Yuzsuz = require("solarui/garden/yuzsuz")
    local now = Yuzsuz.shown(H.app().current().pose.yuzsuz)
    H.check(now:match("^%a+") ~= tostring(H.queen_was):match("^%a+"), "and she is in another pose: " .. tostring(H.queen_was) .. " to " .. now)
    paint(); H.shot("q-card-tapped")
end)
-- an ordinary animal's card, for comparison: the snail
H.step(.5, function() H.app().current().focus = "snail"; H.app().update() end)
H.step(1.2, function() paint(); H.shot("q-snail-card"); H.app().current().focus = "yuzsuz"; H.app().update() end)
H.step(.5, function()
    local a = require("solarui/ui/gardenactions").of("yuzsuz", function() H.app().update() end)
    for _ = 1, 4 do a.queen.on_right() end
end)
H.step(1.2, function() paint(); H.shot("q-bite") end)
H.step(.5, function() require("solarui/ui/gardenqueen").menu(function() H.app().update() end) end)
H.step(1.2, function() paint(); H.shot("q-menu") end)
-- over home, her popup: a tap on her picture changes her pose there too
H.step(.5, function()
    H.app().closeDialog()
    H.app().go("home")
end)
H.step(1, function() require("solarui/ui/gardenpopup").open("yuzsuz") end)
H.step(1, function()
    local Yuzsuz = require("solarui/garden/yuzsuz")
    H.queen_was = Yuzsuz.shown("sit.a")
    local box
    H.findWhere(function(el)
        local art = el.children and el.children[2]
        if el.on_tap and art and art.name == "animal_yuzsuz" then box = el end
        return false
    end)
    H.check(box ~= nil, "her picture in the popup answers a tap")
    if box then H.tapAt(box.x + box.w / 2, box.y + box.h / 2) end
end)
H.step(1, function()
    local now = require("solarui/garden/yuzsuz").shown("sit.a")
    H.check(now:match("^%a+") ~= tostring(H.queen_was):match("^%a+"), "and the popup shows another pose: " .. tostring(H.queen_was) .. " to " .. now)
    paint(); H.shot("q-popup-tapped")
end)
H.step(.5, function()
    H.app().closeDialog()
    local Pet = require("solarui/garden/pet")
    if Pet.get() then Pet.goodbye() end
    local d = require("solarui/garden/state").get()
    d.orchard = {}
    H.check(Pet.adopt("yuzsuz"), "she can be served for life")
    H.app().go("home")
end)
H.step(1.5, function() paint(); H.shot("q-home") end)
