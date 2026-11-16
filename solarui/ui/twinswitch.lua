-- The switch between SolarUI and its twin CyberUI, shown first on the
-- settings page and in the Quick tab: the plaque (art/twinart.lua), half
-- garden and half deck, the side in charge lit, and a line under it saying
-- what a tap does. A tap hands over to the other at once, or offers to
-- install, switch on or restart for it (see twin.lua).

local Art = require("solarui/gfx/art")
local ArtView = require("solarui/ui/artview")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Theme = require("solarui/theme")
local Twin = require("solarui/twin")
local _ = require("solarui/gettext")

local TwinSwitch = {}

-- How much of the page's width the plaque takes, centred on it.
local SHARE = 0.8

-- The plaque, always five times as wide as it is high.
local Plaque = ArtView:extend({})

-- A fifth of the width it takes.
function Plaque:naturalHeight(w)
    return math.floor((w or self.w or Theme.px(500)) * SHARE / 5)
end

-- Draw the plaque in the middle of the box.
function Plaque:draw(bb, x, y)
    if self.w < 2 or self.h < 2 then return end
    local w = math.floor(self.w * SHARE)
    Art.draw(bb, "twin_switch", x + math.floor((self.w - w) / 2), y, w, self.h, w, self.h, self.param)
end

-- What a tap does, in a line.
local function hint()
    local other = Twin.OTHER.name
    local s = Twin.otherStatus()
    if s == "missing" then return string.format(_("%s is not installed yet. Tap to get it."), other) end
    if s == "disabled" then return string.format(_("%s is switched off. Tap to switch it on."), other) end
    if s == "restart" then return string.format(_("%s is installed. Restart KOReader to use it."), other) end
    return string.format(_("SolarUI is in charge. Tap to switch to %s."), other)
end

-- Build it. o: { width (optional) }.
function TwinSwitch.build(o)
    o = o or {}
    local th = Theme.get()
    return Layout.Column:new({ gap = th.space.xs, width = o.width, on_tap = Twin.switch, children = {
        Plaque:new({ param = Twin.active() }),
        Label:new({ text = hint(), kind = "small", color = "muted", align = "center" }),
    } })
end

return TwinSwitch
