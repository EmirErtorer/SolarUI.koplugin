-- The garden companion on the home screen: a small arch holding one plant or
-- animal of the garden, its name, Latin name and how it is doing, and either
-- a button to care for it (when it needs care) or a sentence about it.
-- Tapping the card opens it over the home screen (ui/gardenpopup.lua).

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Companion = require("solarui/garden/companion")
local GardenCard = require("solarui/ui/gardencard")
local GardenPopup = require("solarui/ui/gardenpopup")
local GardenView = require("solarui/ui/gardenview")
local Label = require("solarui/ui/label")
local Layout = require("solarui/garden/layout")
local LayoutUI = require("solarui/ui/layout")
local Lore = require("solarui/garden/lore")
local Settings = require("solarui/settings")
local Text = require("solarui/gfx/text")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local HomeCompanion = {}

local ARCH_W, ARCH_H = 124, 196   -- the arch, in the scene's units

-- The pinned companion's id, or "auto".
function HomeCompanion.pinned()
    return Settings.get("home_companion", "auto")
end

-- Today's companion (see Companion.pick), or nil.
function HomeCompanion.pick()
    return Companion.pick(HomeCompanion.pinned(), tonumber(os.date("%j")) or 1, tonumber(os.date("%H")))
end

-- Draw the companion's picture inside the arch at (x, y).
local function picture(scene, item, x, y)
    local size = item.kind == "plant" and Layout.PLANTS[item.id] or Layout.ANIMALS[item.id]
    local k = math.min(92 / size.w, 130 / size.h)
    local w, h = size.w * k, size.h * k
    local px, py = x + (ARCH_W - w) / 2, y + ARCH_H - 14 - h
    if item.kind == "plant" then scene:backdrop("plant_" .. item.id, px, py, w, h, GardenView.plantParam(item.entry))
    else scene:backdrop("animal_" .. item.id, px, py, w, h, GardenView.animalParam("1", false)) end
end

-- How the companion is doing in a few words: a plant that needs a drink says
-- so, in place of the stage it is in.
local function mood(item)
    if item.kind == "plant" and item.need > 0 then return item.entry.thirst == "wilted" and _("Wilted") or _("Thirsty") end
    return GardenCard.mood(item.entry, item.kind)
end

-- The care button for a companion that needs care.
local function careButton(scene, item, w)
    local th = Theme.get()
    local plant = item.kind == "plant"
    local act = plant and State.water or State.feed
    return Button:new({ label = plant and _("Water") or _("Feed"), sub = string.format(_("%d dew"), plant and State.WATER or State.FEED),
        variant = "primary", height = th.size.touch, width = scene:px(w),
        on_tap = function()
            local ok, why = act(item.id)
            App.toast(ok and string.format(plant and _("%s has had a drink.") or _("%s has eaten."), State.name(item.id))
                or why == "dew" and _("Not enough dew. It comes from the pages you read.") or _("It has only just been cared for."))
            App.update()
        end })
end

-- The text beside the arch: the name and how it is doing, then a care button
-- or a sentence about it, and the Latin name when there is room. Whatever
-- the text size, it is built to stay within `budget` pixels of height: the
-- sentence takes as many lines as are left, and the Latin name goes first
-- when room is short. Returns the column and the height it uses.
function HomeCompanion.column(scene, item, w, budget)
    local gap = scene:px(6)
    local name_h, line_h = Text.height("heading"), Text.height("micro")
    local button = item.need > 0 and careButton(scene, item, w) or nil
    -- the name and the mood always show; the rest as room allows
    local used = name_h + gap + line_h
    local lower_h = button and button:naturalHeight() or line_h
    local latin = used + gap + line_h + gap + lower_h <= budget
    if latin then used = used + gap + line_h end
    local kids = { Label:new({ text = State.name(item.id), kind = "heading" }) }
    if latin then kids[#kids + 1] = Label:new({ text = item.entry.def.latin, kind = "micro", color = "muted" }) end
    kids[#kids + 1] = Label:new({ text = mood(item), kind = "micro" })
    if button then
        if used + gap + lower_h <= budget then kids[#kids + 1] = button; used = used + gap + lower_h end
    else
        local lines = math.min(3, math.floor((budget - used - gap) / line_h))
        if lines >= 1 then
            kids[#kids + 1] = Label:new({ text = Lore.get(item.id), kind = "micro", lines = lines })
            used = used + gap + lines * line_h
        end
    end
    return LayoutUI.Column:new({ gap = gap, children = kids }), used
end

-- Put the card on `scene` with its top-left at (x, y), `w` units wide.
function HomeCompanion.place(scene, x, y, w)
    State.refresh()
    local item = HomeCompanion.pick()
    if not item then return end
    scene:backdrop("garden_arch", x, y, ARCH_W, ARCH_H)
    picture(scene, item, x, y)
    local tx, tw = x + ARCH_W + 14, w - ARCH_W - 14
    scene:place(HomeCompanion.column(scene, item, tw, scene:px(ARCH_H)), tx, y, tw, ARCH_H)
    scene:touch(x, y, ARCH_W, ARCH_H, function() GardenPopup.open(item.id) end)
end

return HomeCompanion
