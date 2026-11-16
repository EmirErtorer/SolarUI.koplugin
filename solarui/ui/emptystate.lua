-- What a page shows when it has nothing to list: a plant, a title, a line or
-- two saying what would fill it, and an optional button, centred in the room
-- it is given.

local ArtView = require("solarui/ui/artview")
local Header = require("solarui/ui/header")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Theme = require("solarui/theme")

local EmptyState = {}

-- The small scene a page with nothing in it shows, by its plant; any other
-- page shows its plant.
local SCENES = { history = "fox", collections = "branch", library = "shelf", highlights = "book", notes = "book", bookmarks = "book",
    search = "leaves", settings = "leaves" }

-- Build it from { plant (see Header.PLANTS), title, text, action = a button,
-- note = a small line under the button }.
function EmptyState.build(o)
    local th = Theme.get()
    local kids = { Layout.Spacer:new({ grow = true }), SCENES[o.plant] and ArtView:new({ name = "scene_" .. SCENES[o.plant], width = Theme.px(220), height = Theme.px(140) }) or Header.plant(o.plant, 110) }
    if o.title then kids[#kids + 1] = Label:new({ text = o.title, kind = "title", align = "center", lines = 2 }) end
    if o.text then kids[#kids + 1] = Label:new({ text = o.text, kind = "body", color = "muted", align = "center", lines = 4 }) end
    if o.action then kids[#kids + 1] = o.action end
    if o.note then kids[#kids + 1] = Label:new({ text = o.note, kind = "small", color = "muted", align = "center", lines = 2 }) end
    kids[#kids + 1] = Layout.Spacer:new({ grow = 2 })
    return Layout.Column:new({ grow = true, gap = th.space.m, align = "center", pad = { 0, th.space.xl }, children = kids })
end

return EmptyState
