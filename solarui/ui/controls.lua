-- Setting controls built from the shared Button and Panel: a toggle switch, a
-- segmented choice and a stepper. Each calls on_change(new_value).

local Button = require("solarui/ui/button")
local Element = require("solarui/ui/element")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Paint = require("solarui/gfx/paint")
local Panel = require("solarui/ui/panel")
local Theme = require("solarui/theme")

local Controls = {}

---------------------------------------------------------------- Toggle
local Toggle = Element:extend({ on = false })
Controls.Toggle = Toggle

-- A fixed-size switch.
function Toggle:naturalWidth() return Theme.px(64) end
function Toggle:naturalHeight() return Theme.px(32) end

-- Flip and report the new state.
function Toggle:on_tap()
    self.on = not self.on
    if self.on_change then self.on_change(self.on) end
end

-- A rounded track, filled when on, with a round knob on the side of the state.
function Toggle:draw(bb, x, y)
    local th = Theme.get()
    local t = th.size.stroke
    local r = math.floor(self.h / 2)
    Paint.roundBox(bb, x, y, self.w, self.h, r, "trbl", t, self.on and th.c.accent or nil, self.on and th.c.accent or th.c.ink)
    local inset = t + Theme.px(3)
    local d = self.h - 2 * inset
    local kx = self.on and (x + self.w - inset - d) or (x + inset)
    Paint.round(bb, kx, y + inset, d, d, math.floor(d / 2), "trbl", self.on and th.c.on_accent or th.c.ink)
end

---------------------------------------------------------------- Segmented
-- A framed row of choices; `options` is a list of { label, value } (with an
-- optional `icon`, `on_hold` and `on_tap` of their own; `disabled` for all).
function Controls.Segmented(o)
    local row = Layout.Row:new({ children = {} })
    for _i, opt in ipairs(o.options) do
        row.children[#row.children + 1] = Button:new({
            label = opt[1], icon = opt.icon, grow = true, height = o.height or Theme.px(38),
            kind = o.kind or "mono_small",
            variant = (opt[2] == o.value) and "seg_on" or "seg", disabled = o.disabled,
            on_tap = not o.disabled and function()
                if opt.on_tap then opt.on_tap() elseif o.on_change then o.on_change(opt[2]) end
            end or nil,
            on_hold = not o.disabled and opt.on_hold or nil,
        })
    end
    local th = Theme.get()
    return Panel:new({ shape = "frame", pad = th.size.stroke, child = row, width = o.width, grow = o.grow })
end

---------------------------------------------------------------- Stepper
-- A framed minus / value / plus control for numbers from `min` to `max`.
function Controls.Stepper(o)
    local step = o.step or 1
    local function set(v)
        v = math.max(o.min, math.min(o.max, v))
        if v ~= o.value and o.on_change then o.on_change(v) end
    end
    local side = Theme.px(40)
    local row = Layout.Row:new({ children = {
        Button:new({ icon = "back", variant = "seg", width = side, height = side, icon_size = 16,
            on_tap = function() set(o.value - step) end }),
        Label:new({ text = o.format and o.format(o.value) or tostring(o.value), kind = "mono", align = "center",
            width = Theme.px(o.value_w or 64) }),
        Button:new({ icon = "forward", variant = "seg_on", width = side, height = side, icon_size = 16,
            on_tap = function() set(o.value + step) end }),
    } })
    return Panel:new({ shape = "frame", pad = Theme.get().size.stroke, child = row })
end

return Controls
