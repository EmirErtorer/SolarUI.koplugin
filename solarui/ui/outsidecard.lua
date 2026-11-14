-- The week's things outdoors in a card over whatever screen shows: the three
-- things with a box to tick each, a line of the reader's own under a ticked
-- one, and a way on to the field notes. The home screen's chip opens it.
-- Ticking tells the companion, who answers on the next look.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Pet = require("solarui/garden/pet")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local OutsideCard = {}

-- The name of a kind of thing, for the small label over it.
OutsideCard.KIND = { look = _("Look"), listen = _("Listen"), ["do"] = _("Do") }

-- Tick or untick the `k`th of this week's things: say so, tell the companion
-- and run `after` (to show the change).
function OutsideCard.tick(k, after)
    if State.toggleOutside(k) then
        local full = State.outsideSummary().full
        Pet.outside(full)
        App.toast(full and _("All three done this week. Well walked.") or _("Ticked off, and kept in your log."))
    else
        App.toast(_("Unticked."))
    end
    if after then after() end
end

-- Ask for a line of the reader's own to keep with the `k`th thing; `after` runs once it is kept.
function OutsideCard.writeNote(k, item, after)
    App.input(_("What did you notice?"), item.note or "", function(text) State.noteOutside(k, text); if after then after() end end, _("Save"))
end

-- The small button that adds or changes the line of one's own, at the left of its row.
function OutsideCard.noteButton(item, on_tap)
    return Layout.Row:new({ children = {
        Button:new({ label = item.note and _("Change the note") or _("Add a note"), variant = "chip", on_tap = on_tap }),
        Layout.Spacer:new({ grow = true }),
    } })
end

-- The card for a screen `w` wide.
function OutsideCard.card(w, close)
    local th = Theme.get()
    local sum = State.outsideSummary()
    local function again() App.updateChanged(); OutsideCard.open() end
    local rows = {}
    for k, item in ipairs(State.outsideWeek()) do
        local words = { Label:new({ text = OutsideCard.KIND[item.kind] or "", kind = "micro", color = "muted" }),
            Label:new({ text = item.text, kind = "small", lines = 5, color = item.done and "muted" or nil }) }
        if item.first and item.last then
            words[#words + 1] = Label:new({ text = string.format(_("Last year: %s."), os.date("%d %B", item.last)), kind = "micro", lines = 2 })
        elseif item.first then
            words[#words + 1] = Label:new({ text = string.format(_("Remember the date of %s."), item.first), kind = "micro", color = "muted", lines = 2 })
        end
        if item.done then
            words[#words + 1] = OutsideCard.noteButton(item, function() close(); OutsideCard.writeNote(k, item, OutsideCard.open) end)
            if item.note then words[#words + 1] = Label:new({ text = "\u{201C}" .. item.note .. "\u{201D}", kind = "micro", lines = 3 }) end
        end
        rows[#rows + 1] = Layout.Row:new({ gap = th.space.m, children = {
            Button:new({ variant = "icon", icon = item.done and "check" or nil, label = item.done and nil or " ", width = th.size.touch,
                on_tap = function() close(); OutsideCard.tick(k, again) end }),
            Layout.Column:new({ gap = th.space.xs, grow = true, children = words }),
        } })
    end
    rows[#rows + 1] = Layout.Row:new({ gap = th.space.m, children = {
        Button:new({ label = _("Close"), grow = true, height = th.size.touch, on_tap = close }),
        Button:new({ label = _("Field notes"), variant = "primary", grow = true, height = th.size.touch,
            on_tap = function() close(); App.push("gardennotes", { tab = "outside" }) end }),
    } })
    return Dialog.card({ tag = _("Outdoors this week"), title = sum.full and _("All three done") or string.format(_("%d of %d done"), sum.done, sum.total),
        text = _("Nothing is earned, and nothing is lost if you skip a week."), lines = 2, rows = rows }, w)
end

-- Open the card.
function OutsideCard.open()
    App.dialog(function(close, w) return OutsideCard.card(w, close) end)
end

return OutsideCard
