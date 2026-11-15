-- The card under the big picture of a tapped plant or animal: its name (the
-- nickname when it has one), Latin name, how it is doing, a few
-- sentences about it and the buttons to care for it, rename it and move on to
-- the next. All actions come in as functions; the card only shows and asks.

local Button = require("solarui/ui/button")
local Care = require("solarui/garden/care")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Lore = require("solarui/garden/lore")
local Pet = require("solarui/garden/pet")
local Panel = require("solarui/ui/panel")
local Season = require("solarui/garden/season")
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
    if e.dormant then return line, _("Resting for the winter. The plant wakes in spring.") end
    if not e.def.interval then return line, _("Needs no watering.") end
    if e.thirst == Care.WILTED then return line, _("Wilted. A drink will bring them round.") end
    if e.thirst == Care.THIRSTY then return line, _("Thirsty.") end
    return line, string.format(_("Fine for another %s."), span(e.thirsty_in))
end

-- How the queen is doing, in one line: she never hides, and her card keeps
-- count of the blood she has drawn.
local function queenStatus(e)
    local mood = ({ content = _("Content, for now"), hungry = _("Demanding food"), hiding = _("Furious, and not hiding: the queen never hides") })[e.mood]
    local bites = e.rec.bites or 0
    local blood = bites > 0 and (" " .. string.format(_.n("She has drawn blood %d time.", "She has drawn blood %d times.", bites), bites)) or ""
    return mood .. " · " .. _("rules day and night"), string.format(_("Eats %s."), e.def.eats) .. blood
end

-- How an animal is doing, in one line.
local function animalStatus(e)
    if e.def.queen then return queenStatus(e) end
    if e.resting then return _("Asleep"), Season.wakes(e.def) or _("Resting until the season turns.") end
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
    if e.def.queen and o.queen then
        -- the queen is fed from a menu and patted with care; her name cannot be changed
        local q = o.queen
        add(Button:new({ label = _("Feed"), sub = _("her menu"), variant = "primary", grow = true, on_tap = q.on_feed }))
        add(Button:new({ label = _("Left side"), sub = _("pat, up to 140"), grow = true, on_tap = q.on_left }))
        add(Button:new({ label = _("Right side"), sub = _("pat, 3 at most"), grow = true, on_tap = q.on_right }))
        add(Button:new({ label = _("Belly"), sub = _("rub, at your risk"), grow = true, on_tap = q.on_rub }))
        return Layout.Row:new(row)
    end
    if kind == "plant" and e.rec.stage == 5 then
        add(Button:new({ label = e.def.id == "three_sisters" and _("Harvest") or _("Cut back"), sub = e.def.id == "three_sisters" and _("share or keep") or _("seeds, birds or beds"), variant = "primary", grow = true, on_tap = o.on_collect }))
    elseif kind == "plant" then
        add(Button:new({ label = _("Water"), sub = string.format(_("%d dew"), State.WATER), variant = "primary", grow = true, disabled = not e.def.interval, on_tap = o.on_water }))
    else
        add(Button:new({ label = _("Feed"), sub = string.format(_("%d dew"), State.FEED), variant = "primary", grow = true, disabled = e.resting, on_tap = o.on_feed }))
    end
    if kind == "plant" and e.rec.stage < 4 then
        add(Button:new({ label = _("Grow now"), sub = _("1 seed"), grow = true, on_tap = o.on_sow }))
    end
    add(Button:new({ label = _("Name"), icon = "edit", icon_size = 18, grow = true, on_tap = o.on_rename }))
    return Layout.Row:new(row)
end

-- The button that takes this one as the companion, or (for the companion
-- already) opens their page; nil when neither applies.
local function companion(id, o)
    if Pet.is(id) then
        return Button:new({ label = _("Their page"), variant = "secondary", grow = true, height = Theme.get().size.touch, on_tap = o.on_pet })
    end
    if Pet.remembered(id) and not Pet.get() and o.on_return then
        return Button:new({ label = string.format(_("Ask %s to come back"), State.name(id)), variant = "secondary", grow = true,
            height = Theme.get().size.touch, on_tap = o.on_return })
    end
    if not Pet.get() and not Pet.remembered(id) and o.on_companion then
        local label = id == "yuzsuz" and string.format(_("Serve %s for life"), State.name(id)) or string.format(_("Make %s my companion"), State.name(id))
        return Button:new({ label = label, variant = "secondary", grow = true,
            height = Theme.get().size.touch, on_tap = o.on_companion })
    end
    return nil
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
    local kids = {
        Label:new({ text = State.name(id), kind = "title" }),
        Label:new({ text = names, kind = "small", color = "muted" }),
        Label:new({ text = status .. ". " .. care, kind = "small" }),
        Label:new({ text = Lore.get(id), kind = "body", lines = 4 }),
        Layout.Spacer:new({ grow = true }),
        actions(e, kind, o),
    }
    local mine = companion(id, o)
    if mine then kids[#kids + 1] = mine end
    kids[#kids + 1] = moves(o)
    return Panel:new({ shape = "frame", double = true, fill = "bg", pad = th.space.m, child = Layout.Column:new({ gap = th.space.s, children = kids }) })
end

-- The care and moving buttons alone, for a card that is not this panel (the
-- popup over home): { actions row, moves row }.
function GardenCard.rows(id, o)
    local e, kind = State.entry(id)
    local out = { actions(e, kind, o) }
    local mine = companion(id, o)
    if mine then out[#out + 1] = mine end
    out[#out + 1] = moves(o)
    return out
end

return GardenCard
