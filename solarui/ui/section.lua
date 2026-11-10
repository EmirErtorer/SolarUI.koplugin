-- The title of a section of a page: its name, then a hairline that runs to
-- the right and ends in a leaf and a curl. The curl is one kept drawing of a
-- fixed size, so any number of sections costs one sprite.

local ArtView = require("solarui/ui/artview")
local Deco = require("solarui/ui/deco")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Theme = require("solarui/theme")

local Section = {}

-- Build the title line; `right` is an optional small text at its end (a count).
function Section.title(text, right)
    local th = Theme.get()
    local kids = {
        Label:new({ text = text, kind = "heading" }),
        Layout.Spacer:new({ width = th.space.s }),
        Deco.Divider:new({ grow = true, color = "ink" }),
        ArtView:new({ name = "section_curl", width = Theme.px(56), height = Theme.px(14) }),
    }
    if right then kids[#kids + 1] = Label:new({ text = right, kind = "small", color = "muted" }) end
    return Layout.Row:new({ gap = 0, children = kids, pad = { th.space.xs, 0, 0, 0 } })
end

return Section
