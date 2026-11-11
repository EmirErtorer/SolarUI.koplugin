-- The garden's clock: a dial in a dialog where the reader taps an hour to see
-- the garden at that hour at once (the sky, the light and which animals are
-- about), or chooses to follow the device's own clock, which is the default.
-- Morning and afternoon are picked with AM and PM under the dial.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local LayoutUI = require("solarui/ui/layout")
local Scene = require("solarui/ui/scene")
local Settings = require("solarui/settings")
local Sky = require("solarui/garden/sky")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local GardenClock = {}

local SIDE = 1072          -- the dial's square, in the scene's units
local RING = .33 * SIDE    -- how far from the centre the numerals stand

-- Is the garden following the device's clock?
function GardenClock.following()
    return type(Settings.get("garden_hour", false)) ~= "number"
end

-- Show the garden at `hour` (0 to 23), or with nil follow the device's clock.
function GardenClock.set(hour)
    Settings.save("garden_hour", hour or false)
end

-- The dial for the hour shown (am or pm), with a numeral and a tap area at
-- each hour: `pick(hour)` is called for the one tapped.
local function dial(w, pm, pick)
    local side = Dialog.inner(w)
    local scene = Scene.make("clockdial", side, side, SIDE)
    local shown = Sky.hour()
    scene:backdrop("garden_clock_face", 0, 0, SIDE, SIDE, string.format("%d:%s", shown % 12, pm and "pm" or "am"))
    local half = Text.height("heading") / scene.k / 2
    for n = 1, 12 do
        local a = math.rad(n * 30)
        local cx, cy = SIDE / 2 + RING * math.sin(a), SIDE / 2 - RING * math.cos(a)
        scene:caption(tostring(n), cx - 80, cy - half, 160, "heading")
        scene:touch(cx - 100, cy - 100, 200, 200, function() pick(n % 12 + (pm and 12 or 0)) end)
    end
    return scene
end

-- The dialog's card on a screen `w` wide; `pm` says which half of the day the
-- dial shows; `after` runs when the garden's hour was changed.
function GardenClock.card(w, pm, after)
    local th = Theme.get()
    local function pick(hour)
        GardenClock.set(hour)
        App.closeDialog()
        after()
    end
    local following = GardenClock.following()
    local halves = LayoutUI.Row:new({ gap = th.space.s, children = {
        Button:new({ label = _("AM"), variant = not pm and "chip_on" or "chip", grow = true, on_tap = function() GardenClock.open(false, after) end }),
        Button:new({ label = _("PM"), variant = pm and "chip_on" or "chip", grow = true, on_tap = function() GardenClock.open(true, after) end }),
    } })
    return Dialog.card({ top = dial(w, pm, pick), title = _("Time in the garden"),
        text = following and _("Following your clock. Tap an hour to see the garden then.") or string.format(_("Showing %d:00. Tap another hour, or follow your clock again."), Sky.hour()),
        lines = 3, rows = { halves, Button:new({ label = _("Follow my clock"), variant = "primary", disabled = following,
            on_tap = function() GardenClock.set(nil); App.closeDialog(); after() end }) } }, w)
end

-- Open the dial; it starts on the half of the day the garden is showing.
function GardenClock.open(pm, after)
    if pm == nil then pm = Sky.hour() >= 12 end
    App.dialog(function(_close, w) return GardenClock.card(w, pm, after) end)
end

return GardenClock
