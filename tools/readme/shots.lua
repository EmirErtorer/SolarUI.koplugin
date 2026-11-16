-- The README's screenshots, in the Garden scheme, light: run with
--   tools/readme/shots.sh  (into assets/screenshots)
local H = ...
local S = 1.5
local Settings = require("solarui/settings")
local UIManager = require("ui/uimanager")
local repo = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/tools/readme/[^/]+$")

-- close any notice another plugin has put on screen, then take the shot
local function shot(name)
    local InfoMessage = require("ui/widget/infomessage")
    for _i, w in ipairs(UIManager._window_stack) do
        if getmetatable(w.widget) == InfoMessage then UIManager:close(w.widget) end
    end
    UIManager:forceRePaint()
    H.shot(name)
end

dofile(repo .. "/tools/readme/seed.lua")(H, repo)
Settings.set("home_companion", "yuzsuz")
H.step(4, function() H.app().render("full"); shot("01-home") end)
H.step(S, function() H.app().push("garden") end)
H.step(2, function()
    local g = H.app().current()
    g.showcase = true   -- (every animal at once, the night ones too)
    H.app().update()
end)
H.step(2.5, function() shot("02-garden") end)
H.step(.5, function()
    local g = H.app().current()
    g.showcase = false
    if g.guide_timer then UIManager:unschedule(g.guide_timer); g.guide_timer = nil end
    g.focus = "yuzsuz"
    H.app().update()
end)
H.step(2.5, function() shot("03-yuzsuz") end)
H.step(S, function() H.app().current().focus = nil; H.app().go("library") end)
H.step(4, function() shot("04-library") end)
H.step(S, function() H.app().go("home"); H.app().push("inkshelf") end)
H.step(18, function() shot("05-notebooks") end)
-- the garden's book open on its own lines (no book's text in the README)
H.step(S, function() H.app().go("home"); H.app().push("garden") end)
H.step(2, function()
    local g = H.app().current()
    if g.guide_timer then UIManager:unschedule(g.guide_timer); g.guide_timer = nil end
    g.showcase = false
    g.part = "garden"
    g.focus = "book"
    H.app().update()
end)
H.step(3, function() shot("06-garden-book") end)
H.step(S, function() H.app().go("history") end)
H.step(3, function() shot("07-log"); H.app().current().tab = "goal"; H.app().update() end)
H.step(3, function() shot("08-goal") end)
-- KOReader's menu in SolarUI's style, on SolarUI's own Quick tab
H.step(S, function()
    H.app().go("home")
    H.app().koreaderMenu()
    local m = require("solarui/menu").current()
    for i, t in ipairs(m and m.tabs or {}) do if t.deck then m:switchTab(i) end end
end)
H.step(3, function() shot("09-menu") end)
