-- A plant or animal of the garden opened over whatever screen is showing (the
-- home screen's companion uses it): its picture in an arch, its names, how it
-- is doing and a few sentences about it, with the buttons to care for it. A tap
-- outside closes it; "Open the garden" goes on to the garden itself. The
-- garden screen opens it too, with arrows to the neighbours.

local App = require("solarui/app")
local ArtView = require("solarui/ui/artview")
local Dialog = require("solarui/ui/dialog")
local GardenActions = require("solarui/ui/gardenactions")
local GardenCard = require("solarui/ui/gardencard")
local GardenView = require("solarui/ui/gardenview")
local Layout = require("solarui/garden/layout")
local LayoutUI = require("solarui/ui/layout")
local Lore = require("solarui/garden/lore")
local Sky = require("solarui/garden/sky")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")

local GardenPopup = {}

-- The picture: the arch with the plant or animal standing in it.
local function picture(id, e, kind)
    local ph = Theme.px(220)
    local aw = math.floor(ph * 1.2)
    local size = kind == "plant" and Layout.PLANTS[id] or Layout.ANIMALS[id]
    local k = math.min(aw * .76 / size.w, ph * .66 / size.h)
    local bw, bh = math.floor(size.w * k), math.floor(size.h * k)
    local param = kind == "plant" and GardenView.plantParam(e, false, Sky.now()) or GardenView.animalParam("1", false, false, Sky.now())
    return LayoutUI.Overlay:new({ height = ph, children = {
        ArtView:new({ name = "garden_arch", width = aw, height = ph, unit = aw / 600, place = "c" }),
        ArtView:new({ name = (kind == "plant" and "plant_" or "animal_") .. id, param = param, width = bw, height = bh, unit = k, place = "c", dy = math.floor(ph * .13) }),
    } })
end

-- The picture of `id` in its arch (also on the companion's page).
GardenPopup.picture = picture

-- The popup's card for `id` on a screen `w` wide, or nil when it is not in
-- the garden. With `list` (a function giving the ids to move between) the
-- card has arrows to the neighbours and "Back to the garden", else it
-- has "Close" and "Open the garden".
function GardenPopup.card(id, w, list)
    local e, kind = State.entry(id)
    if not e then return nil end
    local function again() App.updateChanged(); GardenPopup.open(id, list) end
    local a = GardenActions.of(id, again)
    a.on_close = function() App.closeDialog() end
    if list then
        local function step(delta)
            local ids = list()
            for i, v in ipairs(ids) do
                if v == id then App.closeDialog(); return GardenPopup.open(ids[(i - 1 + delta) % #ids + 1], list) end
            end
        end
        a.on_prev, a.on_next = function() step(-1) end, function() step(1) end
    else
        a.on_open = function() App.closeDialog(); App.push("garden") end
    end
    return Dialog.card({ top = picture(id, e, kind), tag = e.def.latin, title = State.name(id),
        detail = GardenCard.status(e, kind), text = Lore.get(id), lines = 7, rows = GardenCard.rows(id, a) }, w)
end

-- Open the plant or animal `id` over the screen; nothing happens when it is
-- not in the garden.
function GardenPopup.open(id, list)
    if not State.entry(id) then return end
    App.dialog(function(_close, w) return GardenPopup.card(id, w, list) end)
end

return GardenPopup
