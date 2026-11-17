-- The twin switch with CyberUI installed beside SolarUI: the plaque first on
-- the settings page, a tap handing over to CyberUI (SolarUI closes, CyberUI
-- opens and is in charge, KOReader's windows styled by it alone), CyberUI's
-- own switch handing back, the corner-to-home binding following the twin in
-- charge, and the prompt when the twin is missing.
local H = ...
local UIManager = require("ui/uimanager")
local function paint() UIManager:forceRePaint() end
local function top(name)
    for _i, w in ipairs(UIManager._window_stack or {}) do
        if w.widget and w.widget.name == name then return w.widget end
    end
end
local function cyber() return package.loaded["cyberui/app"] end
local function says(text)
    local found = false
    H.findWhere(function(el) if el.text == text or el.label == text then found = true end return false end)
    return found
end
local Twin = require("solarui/twin")

H.step(2, function()
    H.check(require("apps/filemanager/filemanager").instance.CyberUI ~= nil, "CyberUI runs beside SolarUI")
    G_reader_settings:saveSetting("twin_ui", "solarui")
    H.check(Twin.mine(), "SolarUI is in charge")
    H.app().open("settings")
end)
H.step(1.5, function()
    paint(); H.shot("t1-settings-solar")
    H.check(says("SolarUI is in charge. Tap to switch to CyberUI."), "the switch says what a tap does")
    H.tap("Home")
end)
H.step(1, function()
    paint()
    Twin.setCornerHome(false)
    H.check(not Twin.cornerHome(), "the corner can be cleared")
    H.check(says("Corner to home"), "the Home section has the corner row")
end)
H.step(1, function()
    -- (the toggle calls the same)
    Twin.setCornerHome(true)
    H.check(Twin.cornerHome(), "the corner now opens SolarUI's home")
    local g = require("apps/filemanager/filemanager").instance.gestures
    H.check(g.data.gesture_reader.hold_bottom_right_corner.solarui_home == true, "KOReader's gestures hold the binding")
    H.app().update()
end)
H.step(1, function() paint(); H.shot("t2-corner-row") end)
H.step(.5, function()
    local sw
    H.findWhere(function(el) if el.on_tap and el.children and el.children[1] and el.children[1].param ~= nil and not sw then sw = el end return false end)
    H.check(sw ~= nil, "the plaque is on the page")
    if sw then H.tapAt(sw.x + sw.w * .75, sw.y + sw.h / 3) end
end)
H.step(1.2, function()
    require("ui/uimanager"):forceRePaint()
    H.check(H.find("Switch") ~= nil, "the switch asks first")
    H.tap("Switch")
end)
H.step(3, function()
    paint(); H.shot("t3-cyberui-opened")
    H.check(not H.app().isOpen(), "SolarUI closed")
    H.check(cyber() and cyber().isOpen(), "CyberUI opened in its place")
    H.check(not Twin.mine() and require("cyberui/twin").mine(), "CyberUI is in charge now")
    H.check(G_reader_settings:readSetting("start_with") == "cyberui", "KOReader starts with CyberUI now")
    local g = require("apps/filemanager/filemanager").instance.gestures
    H.check(g.data.gesture_reader.hold_bottom_right_corner.cyberui_home == true, "the corner follows to CyberUI's home")
    H.check(not require("solarui/skin/core").wanted() and require("cyberui/skin/core").wanted(), "only CyberUI styles KOReader's windows")
end)
H.step(.5, function() if cyber().isOpen() then cyber().go("settings") end end)
H.step(2, function() paint(); H.shot("t4-cyberui-settings") end)
H.step(.5, function() require("cyberui/twin").handOver() end)
H.step(3, function()
    paint(); H.shot("t5-back-to-solarui")
    H.check(H.app().isOpen() and not cyber().isOpen(), "CyberUI's switch hands back to SolarUI")
    H.check(Twin.mine(), "SolarUI is in charge again")
    local g = require("apps/filemanager/filemanager").instance.gestures
    H.check(g.data.gesture_reader.hold_bottom_right_corner.solarui_home == true, "the corner came back to SolarUI's home")
    require("cyberui/twin").claim()   -- (CyberUI chosen in KOReader's Start with menu)
    H.check(g.data.gesture_reader.hold_bottom_right_corner.cyberui_home == true, "choosing CyberUI to start with moves the corner to CyberUI")
    Twin.claim()
    H.check(g.data.gesture_reader.hold_bottom_right_corner.solarui_home == true, "choosing SolarUI moves the corner back")
    Twin.setCornerHome(false)
    H.check(not Twin.cornerHome(), "the corner can be given back")
end)
-- the twin missing: the prompt that describes it and installs it
H.step(.5, function()
    local Addons = require("solarui/apps/addons")
    H.status = Addons.status
    Addons.status = function(addon) if addon.folder == "CyberUI.koplugin" then return "missing" end return H.status(addon) end
    H.app().open("settings")
end)
H.step(1.5, function()
    paint(); H.shot("t6-twin-missing")
    H.check(says("CyberUI is not installed yet. Tap to get it."), "with CyberUI missing the switch says so")
    Twin.switch()
end)
H.step(1.5, function()
    paint(); H.shot("t7-install-prompt")
    H.check(says("Install"), "a tap offers to install CyberUI")
    require("solarui/apps/addons").status = H.status
    H.app().closeDialog()
end)
