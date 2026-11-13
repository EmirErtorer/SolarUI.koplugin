-- Asking a companion who said goodbye to come back. They live in the orchard
-- and speak for themselves: too soon, they say how much more reading they
-- would like to see; once it is earned (Pet.comeback), they say so and the
-- reader can take them back, with their bond and memories as they were.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local GardenPopup = require("solarui/ui/gardenpopup")
local Layout = require("solarui/ui/layout")
local Pet = require("solarui/garden/pet")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local Voice = require("solarui/garden/voice")
local _ = require("solarui/gettext")

local GardenReturn = {}

-- What is still asked, in a line ("40 more pages and 3 more days").
local function asked(c)
    local parts = {}
    if c.pages_left > 0 then parts[#parts + 1] = string.format(_.n("%d more page", "%d more pages", c.pages_left), c.pages_left) end
    if c.days_left > 0 then parts[#parts + 1] = string.format(_.n("%d more day", "%d more days", c.days_left), c.days_left) end
    return table.concat(parts, _(" and "))
end

-- Ask `id` to come back: their answer in a card over the screen. `after` runs once they are back.
function GardenReturn.ask(id, after)
    local c = Pet.comeback(id)
    if not c then return end
    if Pet.get() then return App.toast(_("There is a companion already. Say goodbye to them first.")) end
    local e, kind = State.entry(id)
    local th = Theme.get()
    local name = c.name or State.name(id)
    local words = { name = name, pages = c.pages_left, days = c.days_left }
    App.dialog(function(close, w)
        local rows
        if c.earned then
            rows = { Layout.Row:new({ gap = th.space.m, children = {
                Button:new({ label = _("Not now"), grow = true, height = th.size.touch, on_tap = function() close() end }),
                Button:new({ label = _("Welcome back"), variant = "primary", grow = true, height = th.size.touch, on_tap = function()
                    close()
                    local ok = Pet.comeBack(id)
                    if after then after() end
                    if ok then
                        App.go("home")
                        App.toast(string.format(_("%s is your companion again."), name))
                    end
                end }),
            } }) }
        else
            rows = { Button:new({ label = _("I will keep reading"), variant = "primary", grow = true, height = th.size.touch, on_tap = function() close() end }) }
        end
        local line = Pet.talks() and Voice.say(id, c.earned and "returned" or "locked", words) or nil
        return Dialog.card({ top = e and GardenPopup.picture(id, e, kind) or nil, tag = _("In the orchard"), title = name,
            detail = c.earned and _("Earned: they are ready to come back") or string.format(_("To come back: %s"), asked(c)),
            text = line, lines = 7, rows = rows }, w)
    end)
end

return GardenReturn
