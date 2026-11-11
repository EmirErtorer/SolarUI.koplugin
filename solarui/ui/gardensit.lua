-- Sitting in the garden: the screen shows only the garden for a few minutes,
-- with nothing to tap and nothing moving, so the reader can look and breathe.
-- When the time is up, this dialog offers the book being read, or more
-- sitting. Opened from the last page of the guide.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local History = require("solarui/data/history")
local _ = require("solarui/gettext")

local GardenSit = {}

GardenSit.SECONDS = 180   -- how long the garden is left alone

-- The dialog's card on a screen `w` wide: open the book being read, or stay
-- (`again` sits for another while).
function GardenSit.card(w, again)
    local current = History.current()
    local rows = {}
    if current then
        rows[#rows + 1] = Button:new({ label = _("Open my book"), variant = "primary",
            on_tap = function() App.closeDialog(); App.openBook(current.path) end })
    end
    rows[#rows + 1] = Button:new({ label = _("Sit a little longer"), variant = current and nil or "primary", on_tap = function() App.closeDialog(); again() end })
    rows[#rows + 1] = Button:new({ label = _("Back to the garden"), on_tap = function() App.closeDialog() end })
    return Dialog.card({ title = _("A good while"), lines = 3,
        text = _("The garden kept still for you. Whenever you are ready, there is a book waiting."), rows = rows }, w)
end

-- Ask what next; `again` sits another while.
function GardenSit.ask(again)
    App.dialog(function(_close, w) return GardenSit.card(w, again) end)
end

return GardenSit
