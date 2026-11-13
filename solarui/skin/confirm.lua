-- KOReader's questions in SolarUI's style: the confirm box and the one with
-- two choices. The text, the icon and every button come from the widget
-- (Anatomy), and a tap on a button runs KOReader's own callback, which closes
-- the box and does what was asked.

local Anatomy = require("solarui/skin/anatomy")
local Core = require("solarui/skin/core")
local Device = require("device")
local Specs = require("solarui/skin/specs")

local Screen = Device.screen

local Skin = {}

local function takes(widget)
    return Anatomy.is(widget, "ui/widget/confirmbox") or Anatomy.is(widget, "ui/widget/multiconfirmbox")
end

Core.register({
    name = "confirm",
    matches = function(widget) return takes(widget) and not widget._added_widgets end,
    present = function(widget)
        local Dialog = require("solarui/ui/dialog")
        local kind = Specs.kind(Anatomy.icon(widget))
        local element = Dialog.card({
            tag = kind.tag, icon = kind.icon, danger = kind.danger, text = Anatomy.text(widget),
            rows = Specs.rows(Anatomy.buttons(widget), Specs.ways),
        }, Screen:getWidth())
        return {
            element = element,
            place = Core.centered,
            on_outside = widget.dismissable ~= false and function() Core.dismiss(widget) end or nil,
        }
    end,
})

return Skin
