-- The field notes: every plant and animal the garden can have, with its names
-- and whether it is in the garden yet, or what it takes to find it.

local Cast = require("solarui/garden/cast")
local Frame = require("solarui/screens/frame")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Screen = require("solarui/screens/screen")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local Visitors = require("solarui/garden/visitors")
local _ = require("solarui/gettext")

local GardenNotes = Screen:extend()

-- Start on the first page.
function GardenNotes:init() self.page = 1 end

-- One entry: the common name, the Latin and Turkish names, and its state.
local function entry(def, state)
    local th = Theme.get()
    return Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
        Label:new({ text = def.en, kind = "heading" }),
        Label:new({ text = def.latin .. " · " .. def.tr, kind = "small", color = "muted" }),
        Label:new({ text = state, kind = "small", lines = 2 }),
    } })
end

-- Build the page.
function GardenNotes:build()
    State.refresh()
    local items = {}
    for _i, def in ipairs(Cast.PLANTS) do
        local rec = State.get().plants[def.id]
        items[#items + 1] = entry(def, rec and string.format(_("In the garden, generation %d."), rec.gen or 1) or _("Not planted yet. Plant a seed in its bed."))
    end
    for _i, def in ipairs(Cast.ANIMALS) do
        items[#items + 1] = entry(def, State.get().animals[def.id] and _("Has found the garden.") or Visitors.hint(def))
    end
    return Frame.page({ screen = self, title = _("Field notes"), plant = "highlights", body = Frame.paged(self, items, _("Page")) })
end

return GardenNotes
