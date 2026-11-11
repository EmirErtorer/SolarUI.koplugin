-- Which animals have found the garden and which are about at this hour. An
-- animal is found when its rule holds (see garden/cast.lua): by how many
-- plants are in bloom, by how the reader reads (pages in the morning or at
-- night, the longest streak, books finished) or by how a plant is growing.
-- Everything is a plain function of a facts table so it can be tested.

local Cast = require("solarui/garden/cast")
local Sky = require("solarui/garden/sky")
local _ = require("solarui/gettext")

local Visitors = {}

-- Pages read in a range of hours (wrapping past midnight when from > to) in a
-- grid of the weekly pattern pages[weekday][hour].
function Visitors.pagesIn(pages, from, to)
    local total = 0
    for w = 1, 7 do
        local row = pages[w] or {}
        for h = 0, 23 do
            local inside = from <= to and (h >= from and h <= to) or (from > to and (h >= from or h <= to))
            if inside then total = total + (row[h] or 0) end
        end
    end
    return total
end

-- The facts the rules look at, from the plants { id = record } and the
-- reading numbers { pages (the weekly grid), streak, books }.
function Visitors.facts(plants, reading)
    local bloom = 0
    for _id, rec in pairs(plants) do
        if rec.stage == 4 then bloom = bloom + 1 end
    end
    local pages = reading.pages or {}
    return {
        bloom = bloom, plants = plants, streak = reading.streak or 0, books = reading.books or 0,
        morning = Visitors.pagesIn(pages, 5, 11), night = Visitors.pagesIn(pages, 20, 4),
    }
end

-- Does the animal's rule hold for these facts?
function Visitors.found(def, facts)
    local f = def.find
    if f.kind == "start" then return true end
    if f.kind == "bloom" then return facts.bloom >= f.n end
    if f.kind == "morning" then return facts.morning >= f.n end
    if f.kind == "night" then return facts.night >= f.n end
    if f.kind == "books" then return facts.books >= f.n end
    local grown = true
    if f.id then
        local rec = facts.plants[f.id]
        grown = rec ~= nil and rec.stage >= f.stage
    end
    if f.kind == "streak" then return facts.streak >= f.n and grown end
    return grown
end

-- The ids of the animals whose rule holds, in the cast's order.
function Visitors.foundAll(facts)
    local out = {}
    for _i, a in ipairs(Cast.ANIMALS) do
        if Visitors.found(a, facts) then out[#out + 1] = a.id end
    end
    return out
end

-- Is the animal about at this hour (0..23)? Day animals whenever the sky is
-- not dark, night ones only in the dark (see garden/sky.lua).
function Visitors.about(def, hour)
    local night = Sky.phase(hour) == "night"
    if def.about == "day" then return not night end
    if def.about == "night" then return night end
    return true
end

-- What to do to find an animal, as a sentence for the field notes.
function Visitors.hint(def)
    local f = def.find
    local text
    if f.kind == "start" then return _("Lives in the garden from the start.") end
    if f.kind == "bloom" then text = string.format(_("Have %d plants in bloom."), f.n)
    elseif f.kind == "morning" then text = string.format(_("Read %d pages in the early morning."), f.n)
    elseif f.kind == "night" then text = string.format(_("Read %d pages late at night."), f.n)
    elseif f.kind == "books" then text = string.format(_("Finish %d books."), f.n)
    elseif f.kind == "streak" then text = string.format(_("Read %d days in a row."), f.n)
    else text = "" end
    if f.id then
        local plant = Cast.plant(f.id)
        local until_ = f.stage == 3 and _("it has a bud") or _("it blooms")
        text = (text ~= "" and (text .. " ") or "") .. string.format(_("Grow the %s until %s."), plant.en, until_)
    end
    return text
end

return Visitors
