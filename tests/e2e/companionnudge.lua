-- Settings' companion button with a companion for life: a nudge to say
-- goodbye first, with their page one tap away. Also the book progress styles.
local H = ...
local State = require("solarui/garden/state")
local Pet = require("solarui/garden/pet")
H.step(2, function()
    State.get().pet = nil
    Pet.adopt("bee")
    H.check(Pet.get() ~= nil, "the bee is the companion for life")
    H.app().open("settings")
    local s = H.app().current(); s.section, s.page = "home", 1; H.app().update()
end)
-- (the button is on one of the Home tab's pages)
for p = 1, 5 do
    H.step(.6, function()
        if H.found then return end
        local s = H.app().current(); s.page = p; H.app().update()
        require("ui/uimanager"):forceRePaint()
        if H.find("Garden companion") then
            H.found = true
            local b = H.findWhere(function(el) return el.on_tap and el.label and el.y and el.y > H.find("Garden companion").y - 20 and el.y < H.find("Garden companion").y + 120 end)
            if b then H.tapAt(b.x + b.w / 2, b.y + b.h / 2) end
        end
    end)
end
H.step(1.5, function()
    require("ui/uimanager"):forceRePaint(); H.shot("nudge")
    H.check(H.find("Open their page") ~= nil, "the companion button nudges to say goodbye first")
    H.tap("Open their page")
end)
H.step(1.5, function()
    require("ui/uimanager"):forceRePaint(); H.shot("their-page")
    H.check(H.screen() == "gardenpet", "their page opens, where goodbye is")
end)
for _i, st in ipairs({ "pearls", "ribbon" }) do
    H.step(.8, function()
        require("solarui/settings").set("progress_style", st)
        local cur = require("solarui/data/history").current()
        if cur then H.app().push("dossier", { path = cur.path }) end
    end)
    H.step(1.5, function() require("ui/uimanager"):forceRePaint(); H.shot("details-" .. st); H.app().pop() end)
end
