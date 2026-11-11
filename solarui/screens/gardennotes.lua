-- The field notes: the garden's almanac in four tabs. Meet lists everyone the
-- garden can have and opens a page for each one met; Calendar goes month by
-- month through what flowers and who sleeps; Links shows who depends on
-- whom among those in the garden; About holds the count of seeds given back,
-- why the garden says "they", and a book to read.

local Almanac = require("solarui/garden/almanac")
local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Cast = require("solarui/garden/cast")
local Frame = require("solarui/screens/frame")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local ListRow = require("solarui/ui/listrow")
local Screen = require("solarui/screens/screen")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local Visitors = require("solarui/garden/visitors")
local _ = require("solarui/gettext")

local GardenNotes = Screen:extend()

local TABS = { { "meet", _("Meet") }, { "calendar", _("Calendar") }, { "links", _("Links") }, { "about", _("About") } }

-- Start on the first page of the first tab.
function GardenNotes:init() self.page, self.tab = 1, "meet" end

-- How well someone is known, in a word.
local function knowing(tier)
    return ({ _("Not met"), _("Seen"), _("Known"), _("A friend") })[tier + 1]
end

-- A row for each plant and animal; a tap opens the page of anyone met.
local function meet()
    local items = {}
    for _i, def in ipairs(Cast.ids()) do
        local d = Cast.find(def)
        local tier = Almanac.tier(d.id)
        items[#items + 1] = ListRow.build({ title = tier > 0 and State.name(d.id) or d.en, meta = tier > 0 and d.latin or Visitors.hint(d),
            value = knowing(tier), dim = tier == 0, on_tap = tier > 0 and function() App.push("gardenpage", { id = d.id }) end or nil })
    end
    return items
end

-- A list of names as a sentence ("Crocus, Pansy"), or "-" when empty.
local function names(ids)
    local out = {}
    for _i, id in ipairs(ids) do out[#out + 1] = Cast.find(id).en end
    return #out > 0 and table.concat(out, ", ") or "-"
end

-- One block for each month: what flowers and who sleeps.
local function calendar()
    local items, th = {}, Theme.get()
    local now = tonumber(os.date("%m")) or 1
    for m = 1, 12 do
        local flowers, asleep = Almanac.month(m)
        local name = os.date("%B", os.time({ year = 2001, month = m, day = 1 }))
        items[#items + 1] = Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
            Label:new({ text = m == now and (name .. " · " .. _("now")) or name, kind = "heading" }),
            Label:new({ text = _("In flower: ") .. names(flowers), kind = "small", lines = 3 }),
            Label:new({ text = _("Asleep: ") .. names(asleep), kind = "small", color = "muted", lines = 2 }),
        } })
    end
    return items
end

-- A block for each link between two in the garden.
local function links()
    local items, th = {}, Theme.get()
    for _i, l in ipairs(Almanac.web()) do
        items[#items + 1] = Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
            Label:new({ text = Cast.find(l[1]).en .. " · " .. Cast.find(l[2]).en, kind = "heading" }),
            Label:new({ text = l[3], kind = "small", lines = 3 }),
        } })
    end
    if #items == 0 then items[1] = Label:new({ text = _("Nothing is linked yet. As more arrive, the web grows."), kind = "body", color = "muted", lines = 2 }) end
    return items
end

-- The About tab: seeds given back, why "they", and a book to read.
local function about()
    local th = Theme.get()
    local function block(title, text)
        return Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.s, 0 }, children = {
            Label:new({ text = title, kind = "heading" }),
            Label:new({ text = text, kind = "body", lines = 8 }),
        } })
    end
    return {
        block(_("Given back"), string.format(_.n("%d seed left in the wild edge.", "%d seeds left in the wild edge.", State.given()), State.given())),
        block(_("Why \"they\""), _("Nobody in this garden is called \"it\". Plants and animals are \"they\" and \"who\", because they are living neighbours, not objects. The botanist Robin Wall Kimmerer makes this point in Braiding Sweetgrass.")),
        block(_("A book to read"), _("Braiding Sweetgrass, by Robin Wall Kimmerer (Milkweed Editions, 2013): a botanist and a member of the Citizen Potawatomi Nation writes about plants, gratitude and what we owe the living world.")),
    }
end

-- Build the page.
function GardenNotes:build()
    State.refresh()
    local th = Theme.get()
    local chips = {}
    for _i, t in ipairs(TABS) do
        chips[#chips + 1] = Button:new({ label = t[2], variant = self.tab == t[1] and "chip_on" or "chip", grow = true,
            on_tap = function() self.tab, self.page = t[1], 1; App.update() end })
    end
    local items = ({ meet = meet, calendar = calendar, links = links, about = about })[self.tab]()
    local body = Layout.Column:new({ gap = th.space.s, children = { Layout.Row:new({ gap = th.space.s, children = chips }), Frame.paged(self, items, _("Page")) } })
    return Frame.page({ screen = self, title = _("Field notes"), plant = "highlights", body = body })
end

return GardenNotes
