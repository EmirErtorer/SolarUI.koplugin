-- Feeds the layout editor (tools/layout-editor.sh): shows a screen in the real
-- emulator at the size it was started with and saves the plain layout, the
-- screen as it really looks, and one more picture for every named part with
-- that part left out, so the editor can lift each part's own pixels out.
-- SOLARUI_EXPORT_SCREEN names the screen (default home).
local H = ...
local SceneEdit = require("solarui/ui/sceneedit")
local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local screen = os.getenv("SOLARUI_EXPORT_SCREEN") or "home"
-- stand the clock still, so no picture differs from another by the minute
local real_date, frozen = os.date, os.time()
os.date = function(f, t) return real_date(f, t or frozen) end
local boxes, scene = {}, nil

-- Draw again with the current switches and save the screen.
local function snap(name)
    H.app().update()
    UIManager:forceRePaint()
    H.shot(name)
end

H.step(1, function()
    if H.screen() ~= screen then H.app().go(screen) end
end)
H.step(1.5, function()
    H.check(H.screen() == screen, screen .. " is shown")
    snap("live")
    SceneEdit.raw = true
    snap("base")
    scene = H.findWhere(function(el) return el.groups ~= nil end)
    H.check(scene ~= nil, "the screen is a scene")
    boxes = SceneEdit.boxes(scene)
    H.check(#boxes > 0, "the scene has named parts")
end)
H.step(0.3, function()
    for i, b in ipairs(boxes) do
        SceneEdit.hide = { [b.id] = true }
        snap("without_" .. i)
    end
    SceneEdit.hide, SceneEdit.raw = {}, false
end)
H.step(0.5, function()
    local out = {
        screen = screen, w = Screen:getWidth(), h = Screen:getHeight(), dpi = Screen:getDPI(),
        k = scene.k, ox = scene.ox, vh = scene.vh, design_w = scene.design_w,
        parts = boxes, overrides = (require("solarui/data/layout_overrides"))[screen] or {},
        all_overrides = require("solarui/data/layout_overrides"),
    }
    local f = io.open(H.out .. "/layout.json", "w")
    f:write(require("json").encode(out))
    f:close()
    H.check(true, "layout.json written with " .. #boxes .. " parts")
end)
