-- The chip on the home screen for the week's things outdoors: how many of the
-- three are done (as pips) and the next thing left, in a line or two. A tap
-- opens the card (ui/outsidecard.lua) to tick them. It can be turned off in
-- the settings.

local Label = require("solarui/ui/label")
local OutsideCard = require("solarui/ui/outsidecard")
local Settings = require("solarui/settings")
local State = require("solarui/garden/state")
local Text = require("solarui/gfx/text")
local _ = require("solarui/gettext")

local OutsideChip = {}

local PAD, TEXT_X = 8, 62   -- the padding, the space above and where the words start, in units
OutsideChip.MIN_H = 62

-- Is the chip shown?
function OutsideChip.visible()
    return Settings.get("home_outside", true)
end

-- The chip's height in units on a scene scaled by `k`: a heading and a row of text.
function OutsideChip.height(k)
    return math.max(OutsideChip.MIN_H, 2 * PAD + 4 + math.ceil(Text.height("micro") * 2 / k))
end

-- What comes next, in a few words: the kind of thing (or whom to look for).
function OutsideChip.teaser(item)
    if item.who then return string.format(_("Next: look for %s"), State.name(item.who)) end
    return ({ look = _("Next: something to look at"), listen = _("Next: something to listen to"), ["do"] = _("Next: something to do") })[item.kind] or ""
end

-- Put the chip on `scene` with its top-left at (x, y), `w` units wide; returns the height used.
function OutsideChip.place(scene, x, y, w)
    local sum = State.outsideSummary()
    local h = OutsideChip.height(scene.k)
    local flags = {}
    for k, item in ipairs(State.outsideWeek()) do flags[k] = item.done and "1" or "0" end
    scene:backdrop("garden_chip", x, y, w, h, table.concat(flags))
    scene:touch(x, y, w, h, function() OutsideCard.open() end)
    local head = _("Outdoors this week")
    local hh = math.ceil(Text.height("micro") / scene.k)
    scene:place(Label:new({ text = head, kind = "micro", color = "muted" }), x + TEXT_X, y + PAD, w - TEXT_X - 96, hh)
    local body = sum.full and _("A whole week. Well walked.") or OutsideChip.teaser(sum.next)
    scene:place(Label:new({ text = body, kind = "micro", lines = 1 }), x + TEXT_X, y + PAD + hh + 2, w - TEXT_X - 16, h - 2 * PAD - hh - 2)
    return h
end

return OutsideChip
