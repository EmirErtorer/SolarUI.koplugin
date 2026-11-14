-- The Home chip for the week's things outdoors, in its states: nothing done,
-- one done, a full week, a long line, no companion, a quiet companion, no
-- companion dialogue. Saves o-<state>.png.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local State = K.state()
local Pet = require("solarui/garden/pet")
local Settings = require("solarui/settings")
local function pet(id)
    local d = State.get()
    d.pet, d.orchard = nil, {}
    d.animals[id] = d.animals[id] or { found = K.t, fed = K.t }
    State.refresh()
    Pet.adopt(id)
end
K.shot("o01-baseline", function()
    K.reset({}); K.everyone(); Settings.set("companion_talk", true); pet("robin")
    H.app().go("home")
end)
K.shot("o02-one-done", function() State.toggleOutside(1); Pet.outside(false); H.app().update() end,
    function() H.check(State.outsideSummary().done == 1, "one thing is ticked") end)
K.shot("o03-all-done", function() State.toggleOutside(2); State.toggleOutside(3); Pet.outside(true); H.app().update() end,
    function() H.check(State.outsideSummary().full, "the week is full") end)
K.shot("o04-untick-all-and-open-card", function()
    for k = 1, 3 do if State.outsideWeek()[k].done then State.toggleOutside(k) end end
    H.app().update()
end)
K.shot("o05-tap-the-chip", function()
    -- the chip is the lowest wide touch box in the book's column
    local el
    H.findWhere(function(e)
        if e.on_tap and e.x and e.x < 300 and (e.w or 0) > 250 and (e.h or 0) < 130 and (not el or e.y > el.y) then el = e end
        return false
    end)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) else H.check(false, "the chip has a touch box") end
end, function() H.check(H.app().overlay() ~= nil, "tapping the chip opens the card") end)
K.shot("o06-tick-in-card", function()
    local el = H.findWhere(function(e) return e.variant == "icon" and e.label == " " end)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) else H.check(false, "a box to tick in the card") end
end, function() H.check(State.outsideSummary().done == 1, "ticking in the card is kept") end)
K.shot("o07-card-close", function() H.tap("Close") end)
K.shot("o08-companion-answers", function() H.app().update() end, function()
    local p = Pet.get()
    H.say("now: " .. tostring(p and p.now and p.now.text) .. " / " .. tostring(p and p.now and p.now.moment))
end)
K.shot("o09-resident-no-companion", function()
    Pet.goodbye(); Settings.set("home_companion", "sunflower"); H.app().update()
end)
K.shot("o10-quiet-companion", function()
    Settings.set("home_companion", "auto"); State.get().orchard = {}; pet("robin"); Settings.set("companion_talk", false); H.app().update()
end)
K.shot("o11-chip-off", function() Settings.set("companion_talk", true); Settings.set("home_outside", false); H.app().update() end)
K.shot("o12-chip-on-again", function() Settings.set("home_outside", true); H.app().update() end)
K.shot("o13-dark", function()
    State.toggleOutside(1)
    require("solarui/theme").set("mode", "dark"); H.app().update()
end)
K.shot("o14-dark-card", function()
    local el
    H.findWhere(function(e)
        if e.on_tap and e.x and e.x < 300 and (e.w or 0) > 250 and (e.h or 0) < 130 and (not el or e.y > el.y) then el = e end
        return false
    end)
    if el then H.tapAt(el.x + el.w / 2, el.y + el.h / 2) end
end)
K.shot("o15-light-empty-home", function()
    H.app().closeDialog()
    require("solarui/theme").set("mode", "light")
    local home = H.app().current()
    home.shown = function() return nil end
    H.app().update()
end)
