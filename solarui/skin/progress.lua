-- KOReader's progress window (a download, a long job) in SolarUI's style: the
-- title and note over a bar of cells filled as far as KOReader says, or a striped
-- bar when it does not know how far. KOReader reports the progress and asks for the
-- bar to be drawn; the window draws it again each time. A tap outside asks the same
-- question KOReader's own window would (stop or go on).

local Anatomy = require("solarui/skin/anatomy")
local Core = require("solarui/skin/core")
local Device = require("device")
local UIManager = require("ui/uimanager")

local Screen = Device.screen

local Skin = {}

-- The card for the progress KOReader has now.
local function card(widget)
    local Dialog = require("solarui/ui/dialog")
    local _ = require("solarui/gettext")
    local bar = widget.progress_bar
    return Dialog.progress({ tag = _("Working"), title = widget.title, text = widget.subtitle,
        value = widget.progress_bar_visible and bar and bar.percentage or nil }, Screen:getWidth())
end

Core.register({
    name = "progress",
    matches = function(widget) return Anatomy.is(widget, "ui/widget/progressbardialog") end,
    present = function(widget)
        -- KOReader asks for the bar to be drawn (and forces it onto the screen, as it is
        -- busy with the job): the popup is drawn again instead
        widget.redrawProgressbar = function()
            if widget._solarui_popup then Core.redraw(widget, card(widget)) end
            UIManager:forceRePaint()
        end
        local dismiss = widget.dismissable ~= false and function() widget:onDismiss() end or nil
        return { element = card(widget), place = Core.centered, on_outside = dismiss, on_back = dismiss and function() dismiss(); return true end }
    end,
})

return Skin
