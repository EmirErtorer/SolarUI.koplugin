-- The bottom tab bar shared by every screen but home: one tab per section
-- under the runner the home dock grows from, the current one a soft leaf
-- with a mark under its name.

local Button = require("solarui/ui/button")
local ArtView = require("solarui/ui/artview")
local Layout = require("solarui/ui/layout")
local Theme = require("solarui/theme")

local TabBar = {}

-- Build the bar from tabs { id, label, icon }, the current id and on_select(id).
function TabBar.build(tabs, current, on_select)
    local th = Theme.get()
    local row = Layout.Row:new({ height = th.size.tabbar, children = {} })
    for _i, t in ipairs(tabs) do
        row.children[#row.children + 1] = Button:new({
            label = t.label, icon = t.icon, icon_size = 18, grow = true,
            variant = (t.id == current) and "tab_on" or "tab",
            on_tap = function() on_select(t.id) end,
        })
    end
    -- swallow: a tap between the tabs is not KOReader's corner gesture (frontlight...)
    return Layout.Column:new({ swallow = true, children = { ArtView:new({ name = "root", height = Theme.px(16) }), row } })
end

return TabBar
