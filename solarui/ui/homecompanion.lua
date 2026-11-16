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
local ARCH_W, ARCH_H = 150, 190   -- the arch, in the scene's units (with the speech bubble under it)
local QUIET_W, QUIET_H = 220, 356  -- the arch of a companion who does not speak: it takes the bubble's room too
HomeCompanion.BUBBLE_H = 160      -- the speech bubble under it, at the usual text size, in units
HomeCompanion.ROWS = 4            -- rows of text it always has room for

-- The bubble's height in units on a scene scaled by `k`: tall enough for
-- ROWS rows at whatever the text size is.
function HomeCompanion.bubbleHeight(k)
    return math.max(HomeCompanion.BUBBLE_H, 24 + HomeCompanion.ROWS * math.ceil(Text.height("small") / k))
end

-- How much taller than usual the card is on a scene scaled by `k`.
function HomeCompanion.extra(k)
    if not Pet.talks() then return 0 end
    return HomeCompanion.bubbleHeight(k) - HomeCompanion.BUBBLE_H
end

-- The card's height in units on a scene scaled by `k`.
function HomeCompanion.height(k)
    if not Pet.talks() then return QUIET_H end
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

-- Draw the companion's picture inside the arch at (x, y), as large as the
-- arch allows (see ui/archfit.lua).
local function picture(scene, item, x, y, aw, ah)
    local size = item.kind == "plant" and Layout.PLANTS[item.id] or Layout.ANIMALS[item.id]
    local name = (item.kind == "plant" and "plant_" or "animal_") .. item.id
    local param = item.kind == "plant" and GardenView.plantParam(item.entry)
        or GardenView.animalParam(GardenView.posed(item.id, GardenView.stillPose(item.entry)), false)
    local bx, by, bw, bh = require("solarui/ui/archfit").box(name, size, { param }, aw, ah)
    scene:backdrop("home:" .. name, x + bx, y + by, bw, bh, param)   -- (home: the scheme may paint them, see art/natural.lua)
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
-- height, measured by what each line really takes. When room is short the
-- first-visit hint goes, then the Latin name; the care button stays as long
-- as it can fit at all. Returns the column.
function HomeCompanion.header(scene, item, w, budget)
    local gap = scene:px(6)
    local px = scene:px(w)
    local narrow = w < 200   -- (units: a companion who does not speak has a narrow column)
    local lines = narrow and 2 or 1
    -- the queen's name is long: her name above, her title below
    local def = item.entry.def
    local name = Label:new({ text = def.short or State.name(item.id), kind = "heading", lines = lines })
    local sub = item.pet and Label:new({ text = string.format(_("%s \u{B7} day %d"), def.title or def.en, Pet.days()), kind = "micro", color = "muted", lines = lines })
        or Label:new({ text = item.entry.def.latin, kind = "micro", color = "muted" })
    local how = Label:new({ text = mood(item), kind = "micro", lines = item.pet and lines or 2 })
    local p = item.pet and Pet.get()
    local hint = p and Pet.talks() and (p.taps or 0) < Pet.HINTS
        and Label:new({ text = _("Tap to chat. Hold to open their page."), kind = "micro", color = "muted", lines = 2 }) or nil
    local button = item.need > 0 and careButton(scene, item, w) or nil
    local function height(list)
        local total = 0
        for i, el in ipairs(list) do total = total + el:naturalHeight(px) + (i > 1 and gap or 0) end
        return total
    end
    local function with_button(list)
        local all = {}
        for i, el in ipairs(list) do all[i] = el end
        if button then all[#all + 1] = button end
        return all
    end
    -- put the optional rows back in order while the care button and all the rows still fit
    local order = {}
    for _i, el in ipairs({ name, sub, how, hint }) do order[#order + 1] = el end
    local keep = { [name] = true, [how] = true }
    for _i, el in ipairs({ sub, hint }) do
        keep[el] = true
        local list = {}
        for _j, e in ipairs(order) do if keep[e] then list[#list + 1] = e end end
        if height(with_button(list)) > budget then keep[el] = nil end
    end
    local kids = {}
    for _i, e in ipairs(order) do if keep[e] then kids[#kids + 1] = e end end
    -- the care button matters more than a second line of how they are doing
    if button and how.lines > 1 and height(with_button(kids)) > budget then how.lines = 1 end
    if button and height(with_button(kids)) <= budget then kids[#kids + 1] = button end
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
    -- a companion who does not speak has the bubble's room for a bigger arch
    local talk = Pet.talks()
    local aw, ah = ARCH_W, ARCH_H
    if not talk then aw, ah = QUIET_W, QUIET_H end
    scene:backdrop("garden_arch", x, y, aw, ah)
    picture(scene, item, x, y, aw, ah)
    local tx, tw = x + aw + 14, w - aw - 14
    local h = HomeCompanion.height(scene.k)
    -- the whole card answers a tap. It is placed first so the care button, placed after it, is on top and gets its own taps
    if item.pet and not talk then
        scene:touch(x, y, w, h, function() App.push("gardenpet") end, function() App.push("gardenpet") end)
    elseif item.pet then
        -- a tap is greeted with a new line; holding opens their page
        scene:touch(x, y, w, h, function() Pet.tapped(); Voice.fits = fitter(scene, w); Voice.react(); Voice.fits = nil; App.update() end, function() App.push("gardenpet") end)
    else
        scene:touch(x, y, w, h, function() GardenPopup.open(item.id) end)
    end
    scene:place(HomeCompanion.header(scene, item, tw, scene:px(ah)), tx, y, tw, ah)
    if item.pet then Pet.refresh(Voice.beats(item.id)) end
    local text = talk and HomeCompanion.speech(item, fitter(scene, w)) or nil
    if text and text ~= "" then bubble(scene, text, x, y + ah + 6, w) end
    -- something waits to be told: a tap hears it
    if item.pet and Pet.waiting() > 0 then scene:backdrop("garden_badge", x + aw - 30, y - 6, 36, 36) end
    return h
end

return HomeCompanion
