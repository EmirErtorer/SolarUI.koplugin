-- KOReader's own frontlight window (Settings > Frontlight, or a gesture)
-- drawn as SolarUI's: a floating card with a slider for the light and, when
-- the device has it, one for the warmth, and a switch. KOReader still builds
-- the window and sets the light through it (so the device's rules about
-- limits and toggling stay its own); its widgets are never painted.

local Device = require("device")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")
local Core = require("solarui/skin/core")

local Screen = Device.screen

local Skin = {}

-- The card for the window `w`: its title, the sliders and the buttons.
local function build(w, popup_of)
    local Button = require("solarui/ui/button")
    local Host = require("solarui/host")
    local Label = require("solarui/ui/label")
    local Layout = require("solarui/ui/layout")
    local Slider = require("solarui/ui/slider")
    local Theme = require("solarui/theme")
    local _ = require("solarui/gettext")
    local th = Theme.get()
    local function row(name, min, max, value, set)
        local slider = Slider:new({ min = min, max = max, value = value, grow = true, on_change = set,
            on_redraw = function(el)
                local popup = popup_of()
                if popup then UIManager:setDirty(popup, Theme.isDark() and "ui" or "fast", Host.box(el)) end
            end })
        return Layout.Row:new({ gap = th.space.s, children = {
            Label:new({ text = name, kind = "label", width = Theme.px(112) }), slider } })
    end
    local kids = {}
    kids[#kids + 1] = row(_("Brightness"), w.fl.min, w.fl.max, w.fl.cur, function(v) w:setBrightness(v) end)
    if w.has_nl and w.nl then
        kids[#kids + 1] = row(_("Warmth"), w.nl.min, w.nl.max, w.nl.cur, function(v) w:setWarmth(v, true) end)
    end
    local function close() UIManager:close(w) end
    kids[#kids + 1] = Layout.Row:new({ gap = th.space.s, children = {
        Button:new({ label = _("Close"), variant = "ghost", grow = true, on_tap = close }),
    } })
    return require("solarui/ui/dialog").card({ tag = _("Light"), title = _("Frontlight"), rows = kids }, Screen:getWidth())
end

-- Style KOReader's frontlight window (patches its class once).
function Skin.install()
    local FrontLightWidget = require("ui/widget/frontlightwidget")
    if FrontLightWidget._solarui_skin then return end
    FrontLightWidget._solarui_skin = true
    local init, on_show, on_close_widget = FrontLightWidget.init, FrontLightWidget.onShow, FrontLightWidget.onCloseWidget
    FrontLightWidget.init = function(self, ...)
        init(self, ...)
        if not Core.wanted("frontlight") then return end
        local Popup = require("solarui/popup")
        local ok, element = pcall(build, self, function() return self._solarui_popup end)
        if not ok then
            require("logger").warn("SolarUI frontlight:", element)
            return
        end
        -- KOReader's window stays unpainted and its own refreshes do nothing
        self.paintTo = function() end
        self.update = function() return true end
        self.dimen = Geom:new({ x = 0, y = 0, w = 0, h = 0 })
        self.ges_events, self.key_events = {}, {}
        self._solarui_popup = Popup:new({
            element = element,
            place = Core.centered,
            on_outside = function() UIManager:close(self) end,
        })
    end
    FrontLightWidget.onShow = function(self)
        local popup = self._solarui_popup
        if popup then
            UIManager:show(popup, "ui", popup:box())
            return true
        end
        return on_show(self)
    end
    FrontLightWidget.onCloseWidget = function(self, ...)
        local popup = self._solarui_popup
        if popup then
            self._solarui_popup = nil
            UIManager:close(popup, "flashui", popup:box())
            return
        end
        return on_close_widget(self, ...)
    end
end

return Skin
