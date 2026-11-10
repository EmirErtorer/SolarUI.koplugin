-- A number in a leaf-shaped tile: a small name, the value large, a note under
-- it. The reading log's tiles are all this.

local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Panel = require("solarui/ui/panel")
local Theme = require("solarui/theme")

-- Build the tile; `note` may be nil.
return function(k, v, note)
    local th = Theme.get()
    local kids = {
        Label:new({ text = k, kind = "micro", color = "muted" }),
        Label:new({ text = v, kind = "number" }),
    }
    if note then kids[3] = Label:new({ text = note, kind = "small", color = "muted" }) end
    return Panel:new({ shape = "chamfer", corners = "tb", cut = "cut_small", line = "line", grow = true, pad = th.space.s,
        child = Layout.Column:new({ children = kids }) })
end
