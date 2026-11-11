-- The garden's season wheel: a dialog where the reader taps a season to see
-- the garden in it at once, or chooses to follow the calendar, which is the
-- default. A switch under the wheel moves the calendar to the southern
-- hemisphere. It works like the clock (ui/gardenclock.lua).

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local Scene = require("solarui/ui/scene")
local Season = require("solarui/garden/season")
local Text = require("solarui/gfx/text")
local _ = require("solarui/gettext")

local GardenSeason = {}

local SIDE = 1072

-- Where each season's name stands on the wheel, as a fraction of the square.
local PLACES = { spring = { .72, .30 }, summer = { .72, .70 }, autumn = { .28, .70 }, winter = { .28, .30 } }

-- The wheel: a picture with a tap area over each quarter. `pick(season)` is
-- called for the one tapped.
local function wheel(w, pick)
    local side = Dialog.inner(w)
    local scene = Scene.make("seasonwheel", side, side, SIDE)
    scene:backdrop("garden_season_wheel", 0, 0, SIDE, SIDE, Season.now())
    local half = Text.height("heading") / scene.k / 2
    for _i, s in ipairs(Season.ALL) do
        local cx, cy = PLACES[s][1] * SIDE, PLACES[s][2] * SIDE
        scene:caption(Season.NAMES[s], cx - 200, cy - half, 400, "heading")
        scene:touch(cx - 230, cy - 200, 460, 400, function() pick(s) end)
    end
    return scene
end

-- The dialog's card on a screen `w` wide; `after` runs when the season was changed.
function GardenSeason.card(w, after)
    local following = Season.following()
    local function close(change)
        change()
        App.closeDialog()
        after()
    end
    local south = Season.south()
    return Dialog.card({ top = wheel(w, function(s) close(function() Season.set(s) end) end), title = _("Season in the garden"),
        text = following and string.format(_("Following the calendar: it is %s. Tap a season to see the garden then."), Season.NAMES[Season.now()]:lower())
            or string.format(_("Showing %s. Tap another season, or follow the calendar again."), Season.NAMES[Season.now()]:lower()),
        lines = 3, rows = {
            Button:new({ label = south and _("Southern hemisphere: on") or _("Southern hemisphere: off"), variant = "chip", grow = true,
                on_tap = function() close(function() Season.setSouth(not south) end) end }),
            Button:new({ label = _("Follow the calendar"), variant = "primary", disabled = following,
                on_tap = function() close(function() Season.set(nil) end) end }),
        } }, w)
end

-- Open the wheel.
function GardenSeason.open(after)
    App.dialog(function(_close, w) return GardenSeason.card(w, after) end)
end

return GardenSeason
