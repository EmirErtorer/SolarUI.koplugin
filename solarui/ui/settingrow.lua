-- One line of a settings page: the setting's name and a short explanation on
-- the left, its control on the right, a budded rule underneath.

local Deco = require("solarui/ui/deco")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Theme = require("solarui/theme")

-- Build the line; `sub` may be nil.
return function(label, sub, control)
    local th = Theme.get()
    local text = { Label:new({ text = label, kind = "heading" }) }
    if sub then text[2] = Label:new({ text = sub, kind = "small", color = "muted", lines = 2 }) end
    return Layout.Column:new({ children = {
        Layout.Row:new({ gap = th.space.m, pad = { th.space.s, 0 }, children = {
            Layout.Column:new({ grow = true, children = text }), control,
        } }),
        Deco.RowRule:new({}),
    } })
end
