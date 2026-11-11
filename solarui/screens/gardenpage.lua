-- One page of the almanac: everything the garden knows about a plant or an
-- animal, as far as it has been met. The first fact and the name come at
-- once, the habitat, months and links after a week, and the story and
-- something to look for outdoors once the one on the page has a nickname and
-- a month has passed. Sections not yet open say what opens them.

local Almanac = require("solarui/garden/almanac")
local Cast = require("solarui/garden/cast")
local Frame = require("solarui/screens/frame")
local GardenCard = require("solarui/ui/gardencard")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Lore = require("solarui/garden/lore")
local Screen = require("solarui/screens/screen")
local Season = require("solarui/garden/season")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local GardenPage = Screen:extend()

-- Start on the first page of the one asked for in the params.
function GardenPage:init(params)
    self.page = 1
    self.id = params.id or Cast.PLANTS[1].id
end

-- A titled paragraph.
local function section(title, text, muted)
    local th = Theme.get()
    return Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
        Label:new({ text = title, kind = "small", color = "muted" }),
        Label:new({ text = text, kind = "body", color = muted and "muted" or nil, lines = 6 }),
    } })
end

-- What opens the next tier, as a line.
local function locked(id, tier)
    local rec, wait = State.rec(id), Almanac.waiting(id)
    if tier == 1 then return string.format(_.n("A closed bud. The bud opens in %d day.", "A closed bud. The bud opens in %d days.", math.max(1, wait)), math.max(1, wait)) end
    if not rec.nick then return _("A closed bud. Give them a nickname and stay a month, and the bud opens.") end
    return string.format(_.n("A closed bud. The bud opens in %d day.", "A closed bud. The bud opens in %d days.", math.max(1, wait)), math.max(1, wait))
end

-- The sentences of the section about when and what: months for a plant,
-- what an animal eats and when it sleeps.
local function when(def, kind)
    if kind == "plant" then
        local months = Almanac.months(def.id)
        local line = string.format(_("At their best in %s."), months)
        return def.interval and line or line .. " " .. _("Needs no watering.")
    end
    local line = string.format(_("Eats %s."), def.eats)
    local slept = Season.wakes(def)
    return slept and (line .. " " .. slept) or line
end

-- The items of the page, top to bottom.
function GardenPage:items()
    local def, kind = Cast.find(self.id)
    local tier = Almanac.tier(self.id)
    local page = Almanac.page(self.id)
    local items = {}
    local function add(e) items[#items + 1] = e end
    local th = Theme.get()
    add(Layout.Column:new({ gap = 0, pad = { 0, 0, th.space.s, 0 }, children = {
        Label:new({ text = State.name(self.id), kind = "title" }),
        Label:new({ text = def.latin, kind = "small", color = "muted" }),
    } }))
    if tier == 0 then
        add(section(_("Not met yet"), require("solarui/garden/visitors").hint(def)))
        return items
    end
    local e = State.entry(self.id)
    add(section(_("Now"), GardenCard.status(e, kind)))
    add(section(_("About"), Lore.get(self.id)))
    add(section(_("The name"), page.name))
    if tier >= 2 then
        add(section(_("Where they live"), page.habitat))
        add(section(_("Through the year"), when(def, kind)))
        for _i, l in ipairs(Almanac.linksOf(self.id)) do
            local other = Cast.find(l[1] == self.id and l[2] or l[1])
            add(section(string.format(_("Linked to %s"), other.en), l[3]))
        end
    else
        add(section(_("Where they live"), locked(self.id, 1), true))
    end
    if tier >= 3 then
        add(section(_("How people have lived with them"), page.story))
        add(section(_("Look for them outdoors"), page.look))
    elseif tier == 2 then
        add(section(_("Their story"), locked(self.id, 2), true))
    end
    return items
end

-- Build the page.
function GardenPage:build()
    State.refresh()
    return Frame.page({ screen = self, title = _("Almanac"), plant = "highlights", body = Frame.paged(self, self:items(), _("Page")) })
end

return GardenPage
