-- The garden companion on the home screen: a small arch holding one plant or
-- animal of the garden, beside it their name and how they are doing (and a
-- button to care for them when they need care), and under the two a speech
-- bubble as wide as the card with what they are saying. Tapping the card
-- opens it over the home screen (ui/gardenpopup.lua); the companion for life
-- answers a tap with a new line and opens their page when held.

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
local Pet = require("solarui/garden/pet")
local Settings = require("solarui/settings")
local Text = require("solarui/gfx/text")
local Voice = require("solarui/garden/voice")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local HomeCompanion = {}

HomeCompanion.WIDTH = 394         -- the card's width, in units
local ARCH_W, ARCH_H = 150, 190   -- the arch, in the scene's units
HomeCompanion.BUBBLE_H = 160      -- the speech bubble under it, at the usual text size, in units
HomeCompanion.ROWS = 4            -- rows of text it always has room for

-- The bubble's height in units on a scene scaled by `k`: tall enough for
-- ROWS rows at whatever the text size is.
function HomeCompanion.bubbleHeight(k)
    return math.max(HomeCompanion.BUBBLE_H, 24 + HomeCompanion.ROWS * math.ceil(Text.height("small") / k))
end

-- How much taller than usual the card is on a scene scaled by `k`.
function HomeCompanion.extra(k)
    return HomeCompanion.bubbleHeight(k) - HomeCompanion.BUBBLE_H
end

-- The card's height in units on a scene scaled by `k`.
function HomeCompanion.height(k)
    return ARCH_H + 6 + HomeCompanion.bubbleHeight(k)
end

-- The pinned companion's id, or "auto".
function HomeCompanion.pinned()
    return Settings.get("home_companion", "auto")
end

-- The companion for life as an item { id, kind, entry, need, pet }, or nil
-- (they are always shown, asleep by night or not).
local function pet()
    local p = Pet.get()
    if not p then return nil end
    local e, kind = State.entry(p.id, tonumber(os.date("%H")))
    if not e then return nil end
    return { id = p.id, kind = kind, entry = e, need = Companion.need(e, kind), pet = true }
end

-- The companion for life, else today's resident (see Companion.pick), or nil.
function HomeCompanion.pick()
    return pet() or Companion.pick(HomeCompanion.pinned(), tonumber(os.date("%j")) or 1, tonumber(os.date("%H")))
end

-- Draw the companion's picture inside the arch at (x, y).
local function picture(scene, item, x, y)
    local size = item.kind == "plant" and Layout.PLANTS[item.id] or Layout.ANIMALS[item.id]
    local k = math.min((ARCH_W - 30) / size.w, (ARCH_H - 44) / size.h)
    local w, h = size.w * k, size.h * k
    local px, py = x + (ARCH_W - w) / 2, y + ARCH_H - 12 - h
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
                or why == "dew" and _("Not enough dew. Dew comes from the pages you read.") or _("Only just cared for."))
            App.update()
        end })
end

-- The text beside the arch: the name, who they are (the companion for life:
-- their kind and how long they have been together; the others: the Latin
-- name) and how they are doing, then the care button when they need care.
-- Whatever the text size it is built to stay within `budget` pixels of
-- height: the Latin name goes first, then the button, when room is short.
-- Returns the column.
function HomeCompanion.header(scene, item, w, budget)
    local gap = scene:px(6)
    local name_h, line_h = Text.height("heading"), Text.height("micro")
    local used = name_h + gap + line_h
    local kids = { Label:new({ text = State.name(item.id), kind = "heading" }) }
    if item.pet then
        kids[#kids + 1] = Label:new({ text = string.format(_("%s \u{B7} day %d"), item.entry.def.en, Pet.days()), kind = "micro", color = "muted" })
        kids[#kids + 1] = Label:new({ text = mood(item), kind = "micro" })
        used = used + gap + line_h
    else
        local latin = used + gap + line_h + gap + line_h <= budget
        if latin then
            kids[#kids + 1] = Label:new({ text = item.entry.def.latin, kind = "micro", color = "muted" })
            used = used + gap + line_h
        end
        kids[#kids + 1] = Label:new({ text = mood(item), kind = "micro", lines = 2 })
        used = used + gap + 2 * line_h
    end
    -- the first few visits say how to talk to them
    local p = item.pet and Pet.get()
    if p and (p.taps or 0) < Pet.HINTS then
        local hint = Label:new({ text = _("Tap to chat. Hold to open their page."), kind = "micro", color = "muted", lines = 2 })
        if used + gap + 2 * line_h + gap + (item.need > 0 and careButton(scene, item, w):naturalHeight() or 0) <= budget then
            kids[#kids + 1] = hint
            used = used + gap + 2 * line_h
        end
    end
    if item.need > 0 then
        local button = careButton(scene, item, w)
        if used + gap + button:naturalHeight() <= budget then kids[#kids + 1] = button end
    end
    return LayoutUI.Column:new({ gap = gap, children = kids })
end

-- What the companion says in the bubble: the companion for life their line
-- of the moment (a memory, which is long, is only hinted at here and told in
-- full on their page), any other a sentence about them. `fits` says whether
-- a line fits the bubble, so the lines chosen are ones that do.
function HomeCompanion.speech(item, fits)
    if not item.pet then return Lore.get(item.id) end
    Voice.fits = fits
    local text = Voice.current()
    Voice.fits = nil
    local p = Pet.get()
    if text and p and p.now and p.now.moment == "beat" and p.now.text == text and p.now.title then
        return string.format(_("A memory came back to me: %s. Hold me to hear the story."), p.now.title)
    end
    return text
end

-- Does a line fit the bubble `w` units wide on this scene?
local function fitter(scene, w)
    local px = scene:px(w - 36)
    return function(text) return #Text.wrap("small", text, px) <= HomeCompanion.ROWS end
end

-- The speech bubble under the arch, with `text` in its rows (the rest of a
-- very long line ends in an ellipsis).
local function bubble(scene, text, x, y, w)
    local pad, h = 18, HomeCompanion.bubbleHeight(scene.k)
    scene:backdrop("garden_bubble", x, y, w, h)
    scene:place(Label:new({ text = text, kind = "small", lines = HomeCompanion.ROWS }), x + pad, y + 12, w - 2 * pad, h - 24)
end

-- Put the card on `scene` with its top-left at (x, y), `w` units wide, and
-- return the height it uses (HomeCompanion.height, so what is under it stays put).
function HomeCompanion.place(scene, x, y, w)
    State.refresh()
    local item = HomeCompanion.pick()
    if not item then return HomeCompanion.height(scene.k) end
    scene:backdrop("garden_arch", x, y, ARCH_W, ARCH_H)
    picture(scene, item, x, y)
    local tx, tw = x + ARCH_W + 14, w - ARCH_W - 14
    scene:place(HomeCompanion.header(scene, item, tw, scene:px(ARCH_H)), tx, y, tw, ARCH_H)
    if item.pet then Pet.refresh(Voice.beats(item.id)) end
    local text = HomeCompanion.speech(item, fitter(scene, w))
    if text and text ~= "" then bubble(scene, text, x, y + ARCH_H + 6, w) end
    local h = HomeCompanion.height(scene.k)
    if item.pet then
        -- a tap is greeted with a new line; holding opens their page
        scene:touch(x, y, w, h, function() Pet.tapped(); Voice.fits = fitter(scene, w); Voice.react(); Voice.fits = nil; App.update() end, function() App.push("gardenpet") end)
    else
        scene:touch(x, y, w, h, function() GardenPopup.open(item.id) end)
    end
    return h
end

return HomeCompanion
