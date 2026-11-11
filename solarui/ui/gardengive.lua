-- The question after a book is finished: leave a seed in the wild edge of the
-- garden? Saying yes costs nothing and unlocks nothing, it is only counted
-- (see State.giveBack); saying no is as good. Nothing is ever asked twice for
-- the same book.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local State = require("solarui/garden/state")
local _ = require("solarui/gettext")

local GardenGive = {}

-- The dialog's card on a screen `w` wide; `after` runs once it was answered.
function GardenGive.card(w, after)
    local function answer(yes, said)
        return function()
            State.giveBack(yes)
            App.closeDialog()
            if said then App.toast(said) end
            after()
        end
    end
    return Dialog.card({ title = _("A book is finished"), lines = 5,
        text = _("The garden gave you a book's worth of quiet. Leave a seed in the wild edge, where nobody tends anything? It costs nothing, and nothing is earned. It is only a way of saying thanks."),
        rows = {
            Button:new({ label = _("Leave a seed"), variant = "primary", on_tap = answer(true, _("A seed went into the wild edge.")) }),
            Button:new({ label = _("Not now"), on_tap = answer(false) }),
        } }, w)
end

-- Ask, when a finished book is waiting for an answer. Returns true when the question was put.
function GardenGive.ask(after)
    if State.owed() < 1 or App.overlay() then return false end
    App.dialog(function(_close, w) return GardenGive.card(w, after) end)
    return true
end

return GardenGive
