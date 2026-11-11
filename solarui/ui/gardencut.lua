-- The choice when a plant that has gone to seed is cut back: keep the seeds,
-- leave them for the birds, or scatter some in the beds. A plant cut before
-- the seeds have ripened is told to wait, and gives less.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local State = require("solarui/garden/state")
local _ = require("solarui/gettext")

local GardenCut = {}

-- Have the seeds of this plant had time to ripen?
function GardenCut.ripe(id)
    local rec = State.rec(id)
    return not rec.seeded or State.clock() - rec.seeded >= State.RIPEN
end

-- The dialog's card on a screen `w` wide for the plant `id`; `after` runs
-- once it was cut back.
function GardenCut.card(w, id, after)
    local function choose(how, said)
        return function()
            local ok, gain = State.collect(id, how)
            App.closeDialog()
            if ok then
                local count = gain >= 1 and string.format(_.n(" You have %d more seed."," You have %d more seeds.", math.floor(gain)), math.floor(gain)) or ""
                App.toast(said .. count)
            end
            after()
        end
    end
    local name = State.name(id)
    local text = GardenCut.ripe(id) and string.format(_("%s has gone to seed. What becomes of the seeds?"), name)
        or string.format(_("%s has only just gone to seed. Let some seed ripen: cut back now and the harvest is smaller."), name)
    return Dialog.card({ title = _("Cut back"), text = text, lines = 4, rows = {
        Button:new({ label = _("Keep the seeds"), sub = _("seeds for you"), variant = "primary", on_tap = choose("keep", _("Cut back.")) }),
        Button:new({ label = _("Leave them for the birds"), sub = _("feeds a hungry visitor"), on_tap = choose("birds", _("Left for the birds.")) }),
        Button:new({ label = _("Scatter some"), sub = _("half a seed for you"), on_tap = choose("scatter", _("Scattered in the beds.")) }),
        Button:new({ label = _("Not now"), on_tap = function() App.closeDialog() end }),
    } }, w)
end

-- Open the choice.
function GardenCut.open(id, after)
    App.dialog(function(_close, w) return GardenCut.card(w, id, after) end)
end

return GardenCut
