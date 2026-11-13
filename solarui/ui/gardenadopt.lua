-- Taking a plant or animal of the garden as the companion, and saying goodbye
-- to them: each asks twice (a name, then a sure answer), because the
-- companion is for life.

local App = require("solarui/app")
local Pet = require("solarui/garden/pet")
local State = require("solarui/garden/state")
local _ = require("solarui/gettext")

local GardenAdopt = {}

-- Make `id` the companion: ask for a name, then make sure. `after` runs once it is done,
-- and then the home screen opens, where the companion greets you.
function GardenAdopt.start(id, after)
    if Pet.get() then return App.toast(_("There is a companion already. Say goodbye to them first.")) end
    App.input(_("Name your companion"), State.rec(id).nick or "", function(text)
        local name = (text and text ~= "") and text or State.name(id)
        App.confirm({ title = string.format(_("%s, for life?"), name),
            text = _("A companion stays with you for life. You can say goodbye one day, and they will live on in the orchard."),
            ok = _("Yes, for life"), cancel = _("Not yet"),
            on_ok = function()
                local ok = Pet.adopt(id, text)
                if after then after() end
                if ok then
                    -- straight to the home screen, where the new companion says hello
                    App.closeDialog()
                    App.go("home")
                    App.toast(string.format(_("%s is your companion."), name))
                else
                    App.toast(_("That did not work."))
                end
            end })
    end, _("Next"), { placeholder = State.name(id) })
end

-- Say goodbye to the companion: they go to the orchard, where they stay and are remembered.
function GardenAdopt.goodbye(after)
    local p = Pet.get()
    if not p then return end
    local name = State.name(p.id)
    App.confirm({ title = string.format(_("Say goodbye to %s?"), name), danger = true,
        text = _("They will live in the orchard from now on, with their diary and memories. You can then choose a new companion."),
        ok = _("Say goodbye"), cancel = _("Stay together"),
        on_ok = function()
            Pet.goodbye()
            App.toast(string.format(_("%s is in the orchard now."), name))
            if after then after() end
        end })
end

return GardenAdopt
