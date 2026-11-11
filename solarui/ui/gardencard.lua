-- The card under the big picture of a tapped plant or animal: its name (the
-- nickname when it has one), Latin name, how it is doing, a few
-- sentences about it and the buttons to care for it, rename it and move on to
-- the next. All actions come in as functions; the card only shows and asks.

local Button = require("solarui/ui/button")
local Care = require("solarui/garden/care")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Lore = require("solarui/garden/lore")
local Panel = require("solarui/ui/panel")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local GardenCard = {}

local STAGES = { _("Seed"), _("Sprout"), _("Bud"), _("In bloom"), _("Gone to seed") }

-- A span of seconds as "about N hours" or "about N days".
local function span(seconds)
    local hours = math.max(1, math.floor(seconds / 3600 + .5))
    if hours < 48 then return string.format(_.n("%d hour", "%d hours", hours), hours) end
    local days = math.floor(hours / 24 + .5)
    return string.format(_.n("%d day", "%d days", days), days)
end

-- How a plant is doing, in one line.
local function plantStatus(e)
    local gen = e.rec.gen or 1
    local line = STAGES[e.rec.stage] .. (gen > 1 and (" · " .. string.format(_("generation %d"), gen)) or "")
    if not e.def.interval then return line, _("Needs no watering.") end
    if e.thirst == Care.WILTED then return line, _("Wilted. A drink will bring them round.") end
    if e.thirst == Care.THIRSTY then return line, _("Thirsty.") end
    return line, string.format(_("Fine for another %s."), span(e.thirsty_in))
end

-- How an animal is doing, in one line.
local function animalStatus(e)
    local mood = ({ content = _("Content"), hungry = _("Hungry"), hiding = _("Hiding, hungry") })[e.mood]
    local when = ({ day = _("out by day"), night = _("out at night"), any = _("out day and night") })[e.def.about]
    return mood .. " · " .. when, string.format(_("Eats %s."), e.def.eats)
end

-- How the plant or animal of this entry is doing, as one sentence.
function GardenCard.status(e, kind)
    local line, care = (kind == "plant" and plantStatus or animalStatus)(e)
    return line .. ". " .. care
end

-- How the plant or animal of this entry is doing, in a few words ("In
-- bloom", "Hungry · out by day").
function GardenCard.mood(e, kind)
    return (kind == "plant" and plantStatus or animalStatus)(e)
end

-- The row of buttons that care for what is shown: o.on_water, on_feed,
-- on_collect, on_rename.
local function actions(e, kind, o)
    local th = Theme.get()
    local row = { gap = th.space.s, children = {} }
    local function add(b) row.children[#row.children + 1] = b end
    if kind == "plant" and e.rec.stage == 5 then
        add(Button:new({ label = _("Cut back"), sub = _("seeds, birds or beds"), variant = "primary", grow = true, on_tap = o.on_collect }))
    elseif kind == "plant" then
        add(Button:new({ label = _("Water"), sub = string.format(_("%d dew"), State.WATER), variant = "primary", grow = true, disabled = not e.def.interval, on_tap = o.on_water }))
    else
        add(Button:new({ label = _("Feed"), sub = string.format(_("%d dew"), State.FEED), variant = "primary", grow = true, on_tap = o.on_feed }))
    end
    if kind == "plant" and e.rec.stage < 4 then
        add(Button:new({ label = _("Grow now"), sub = _("1 seed"), grow = true, on_tap = o.on_sow }))
    end
    add(Button:new({ label = _("Name"), icon = "edit", icon_size = 18, grow = true, on_tap = o.on_rename }))
    return Layout.Row:new(row)
end

-- The row that moves between the garden's inhabitants, or (with o.on_open)
-- the one that closes the card or opens the garden.
local function moves(o)
    local th = Theme.get()
    if o.on_open then
        return Layout.Row:new({ gap = th.space.s, children = {
            Button:new({ label = _("Close"), grow = true, on_tap = o.on_close }),
            Button:new({ label = _("Open the garden"), grow = true, on_tap = o.on_open }),
        } })
    end
    return Layout.Row:new({ gap = th.space.s, children = {
        Button:new({ icon = "back", icon_size = 18, variant = "icon", width = th.size.touch, on_tap = o.on_prev }),
        Button:new({ label = _("Back to the garden"), variant = "secondary", grow = true, on_tap = o.on_close }),
        Button:new({ icon = "forward", icon_size = 18, variant = "icon", width = th.size.touch, on_tap = o.on_next }),
    } })
end

-- The card for the plant or animal `id` that is in the garden; `o` holds the
-- actions. Returns the panel.
function GardenCard.build(id, o)
    local th = Theme.get()
    local e, kind = State.entry(id)
    local def, rec = e.def, State.rec(id)
    local status, care = (kind == "plant" and plantStatus or animalStatus)(e)
    local names = (rec.nick and (def.en .. " · ") or "") .. def.latin
    return Panel:new({ shape = "frame", double = true, fill = "bg", pad = th.space.m, child = Layout.Column:new({ gap = th.space.s, children = {
        Label:new({ text = State.name(id), kind = "title" }),
        Label:new({ text = names, kind = "small", color = "muted" }),
        Label:new({ text = status .. ". " .. care, kind = "small" }),
        Label:new({ text = Lore.get(id), kind = "body", lines = 7 }),
        Layout.Spacer:new({ grow = true }),
        actions(e, kind, o),
        moves(o),
    } }) })
end

-- The care and moving buttons alone, for a card that is not this panel (the
-- popup over home): { actions row, moves row }.
function GardenCard.rows(id, o)
    local e, kind = State.entry(id)
    return { actions(e, kind, o), moves(o) }
end

return GardenCard
