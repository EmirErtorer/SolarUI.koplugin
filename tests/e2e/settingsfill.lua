-- Every settings tab, every page: a page's foot is used by a later row that fits.
local H = ...
local tabs = { "look", "covers", "fonts", "home", "speed", "about" }
H.step(2, function() H.app().open("settings") end)
for _i, t in ipairs(tabs) do
    for p = 1, 4 do
        H.step(.8, function() local s = H.app().current(); s.section, s.page = t, p; H.app().update() end)
        H.step(.8, function()
            local s = H.app().current()
            if p <= (s.pages or 1) then require("ui/uimanager"):forceRePaint(); H.shot(string.format("%s-%d", t, p)) end
        end)
    end
end
