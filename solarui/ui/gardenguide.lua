-- The guide to the garden: a few short pages in a dialog saying what it is,
-- what dew and seeds are, how to look after it, who visits and when, and how
-- the clock works. Opened by itself the first time, then from the button in
-- the garden's top bar; `on_done` runs when it is closed, however it is.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Cast = require("solarui/garden/cast")
local Dialog = require("solarui/ui/dialog")
local Label = require("solarui/ui/label")
local LayoutUI = require("solarui/ui/layout")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local Visitors = require("solarui/garden/visitors")
local _ = require("solarui/gettext")

local GardenGuide = {}

-- The animals that must be earned, as lines "Name: what it takes".
local function visitors(first, last)
    local out, n = {}, 0
    for _i, a in ipairs(Cast.ANIMALS) do
        if a.find.kind ~= "start" then
            n = n + 1
            if n >= first and n <= last then out[#out + 1] = Label:new({ text = a.en .. ": " .. Visitors.hint(a), kind = "small", lines = 2 }) end
        end
    end
    return out
end

-- The pages: { title, text (or nil), rows (a function making the rows, or nil) }.
function GardenGuide.pages()
    return {
        { title = _("Your garden"), text = _("Everything here is alive. Plants grow and bloom while they are watered, and animals visit and stay while they are fed. Tap anyone to meet them.") },
        { title = _("Dew and seeds"), text = string.format(_("Dew comes from reading: every page you read adds a drop. A drink costs %d dew and a meal %d. Seeds come from finishing books and from cutting back a plant that has gone to seed. A seed makes a growing plant bloom at once."), State.WATER, State.FEED) },
        { title = _("Looking after the garden"), text = _("A plant that is not watered in time wilts and stops growing. An animal that is not fed hides in the grass. Nothing ever dies, and a drink or a meal brings them back.") },
        { title = _("Give and take"), text = _("Dew is taken from the pages you read, so the garden asks for something back. When a plant goes to seed you can keep the seeds, leave them for the birds or scatter some. Finish a book and you may leave a seed in the wild edge, which costs nothing and earns nothing. Bees and butterflies visit the flowers, and a flower they visited gives an extra seed.") },
        { title = _("The seasons"), text = _("The garden follows your calendar. In winter the plants that die back rest, most animals sleep, and plants want water half as often. Nothing is lost, and everyone wakes in spring. Rain waters the beds once a day, and snow only settles. The season button at the top shows the garden in any season, and weather there is the garden's own, not the sky outside.") },
        { title = _("Who, not what"), text = _("Nobody in this garden is called \"it\". Plants and animals are \"they\" and \"who\", because they are living neighbours, not objects. The botanist Robin Wall Kimmerer makes this point in her book Braiding Sweetgrass: English has one word for people and another for everything alive that is not, and speaking of the living as someone changes how we treat them.") },
        { title = _("Who visits"), text = _("The bee, the ladybird and the snail live here from the start. The others come when you earn them:"), rows = function() return visitors(1, 5) end },
        { title = _("Who visits"), text = _("And the rest:"), rows = function() return visitors(6, 9) end },
        { title = _("Day and night"), text = _("The sky follows your clock. The hedgehog, the moth and the fox only come out in the dark, between ten at night and five in the morning, and the other animals are about by day. The clock button at the top lets you look at the garden at any other hour.") },
        { title = _("Notes and quiet"), text = _("The field notes are an almanac: tap the name of anyone you have met. Pages open as you get to know them, after a week and again after a month with a nickname. Once a day a small face peeks out of the grass, and finding the face is worth a drop of dew. And you can simply sit in the garden for a few minutes, with nothing to do.") },
    }
end

-- The dialog's card for page `i` on a screen `w` wide.
function GardenGuide.card(w, i, go, sit)
    local th = Theme.get()
    local all = GardenGuide.pages()
    local p = all[i]
    local rows = p.rows and p.rows() or {}
    local last = i == #all
    if last and sit then rows[#rows + 1] = Button:new({ label = _("Sit in the garden"), sub = _("for a few quiet minutes"), on_tap = function() App.closeDialog(); sit() end }) end
    rows[#rows + 1] = LayoutUI.Row:new({ gap = th.space.s, children = {
        Button:new({ label = _("Back"), grow = true, disabled = i == 1, on_tap = function() go(i - 1) end }),
        Button:new({ label = last and _("Start gardening") or _("Next"), variant = "primary", grow = true,
            on_tap = function() if last then App.closeDialog() else go(i + 1) end end }),
    } })
    return Dialog.card({ tag = string.format(_("%d of %d"), i, #all), title = p.title, text = p.text, lines = 8, rows = rows }, w)
end

-- Open the guide at its first page.
function GardenGuide.open(on_done, sit)
    local function show(i)
        App.dialog(function(_close, w)
            local card = GardenGuide.card(w, i, show, sit)
            card.on_closed = on_done
            return card
        end)
    end
    show(1)
end

return GardenGuide
