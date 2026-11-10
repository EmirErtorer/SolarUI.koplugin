-- The header of a page: a round back button, the page's plant, the title in
-- the display face over an optional small line, action buttons on the right,
-- and a whiplash rule under it all.

local ArtView = require("solarui/ui/artview")
local Button = require("solarui/ui/button")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Theme = require("solarui/theme")

local Header = {}

-- The plants a header can show (drawings named plant_<name> in art/pages.lua).
Header.PLANTS = { library = true, collections = true, history = true, search = true, settings = true,
    details = true, highlights = true, bookmarks = true, notes = true, sprout = true }

-- The drawing of plant `name` as a square element `size` base pixels across
-- (a name the garden does not know gives the sprout).
function Header.plant(name, size)
    local s = Theme.px(size or 40)
    return ArtView:new({ name = "plant_" .. (Header.PLANTS[name] and name or "sprout"), width = s, height = s })
end

-- A page header: `title`, the plant `plant` (see Header.PLANTS) and, in `o`,
-- { sub = a small line under the title, on_back, actions = { buttons } }.
function Header.pageHeader(title, plant, o)
    o = o or {}
    local th = Theme.get()
    local kids = {}
    if o.on_back then
        kids[#kids + 1] = Button:new({ icon = "back", variant = "icon", width = th.size.touch, on_tap = o.on_back })
    end
    kids[#kids + 1] = Header.plant(plant)
    local titles = { Label:new({ text = title, kind = "display" }) }
    if o.sub then titles[2] = Label:new({ text = o.sub, kind = "small", color = "muted" }) end
    kids[#kids + 1] = Layout.Column:new({ grow = true, children = titles })
    for _i, b in ipairs(o.actions or {}) do kids[#kids + 1] = b end
    return Layout.Column:new({ gap = th.space.xs, children = {
        Layout.Row:new({ gap = th.space.m, children = kids }),
        ArtView:new({ name = "page_rule", height = Theme.px(14) }),
    } })
end

-- The same from one table: { title, plant, path (the small line), on_back, actions }.
function Header.build(o)
    return Header.pageHeader(o.title, o.plant, { sub = o.path, on_back = o.on_back, actions = o.actions })
end

return Header
