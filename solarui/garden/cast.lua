-- Who lives in the garden: the plants that can grow there (each one of the
-- species of art/species.lua, with how often it wants water and how many days
-- each stage of its life takes) and the animals that visit (what they eat,
-- when they are about and how they are found). Names come from the species
-- registry for plants and from here for animals; Latin names are never translated.

local Species = require("solarui/art/species")
local _ = require("solarui/gettext")

local Cast = {}

local DAY = 86400

-- Every plant: id, hours between drinks (nil: it needs none), days of the
-- stages seed, sprout, bud and bloom, and whether the garden starts with it.
local PLANTS = {
    { id = "crocus", hours = 72, days = { 1, 2, 2, 4 }, start = true },
    { id = "pansy", hours = 48, days = { 1, 2, 3, 6 }, start = true },
    { id = "chamomile", hours = 48, days = { 1, 2, 2, 5 }, start = true },
    { id = "dandelion", hours = 96, days = { 1, 2, 2, 4 }, start = true },
    { id = "tulip", hours = 48, days = { 1, 2, 3, 5 }, start = true },
    { id = "bracken", hours = 36, days = { 1, 3, 4, 8 }, start = true },
    { id = "narcissus", hours = 72, days = { 1, 2, 3, 5 } },
    { id = "lily", hours = 48, days = { 1, 3, 4, 6 } },
    { id = "rose", hours = 36, days = { 1, 3, 4, 8 } },
    { id = "sunflower", hours = 24, days = { 1, 3, 4, 6 } },
    { id = "iris", hours = 72, days = { 1, 3, 3, 6 } },
    { id = "poppy", hours = 120, days = { 1, 2, 2, 4 } },
    { id = "bellflower", hours = 72, days = { 1, 2, 3, 5 } },
    { id = "honesty", hours = 96, days = { 1, 3, 3, 7 } },
    { id = "maple", hours = 96, days = { 2, 4, 5, 14 } },
    { id = "ginkgo", hours = 120, days = { 2, 4, 5, 14 } },
    { id = "ivy", hours = 72, days = { 1, 3, 3, 10 } },
    { id = "water_lily", days = { 1, 3, 3, 8 } },
}

-- Every animal: id, names, the hours it is about ("day", "night" or "any"),
-- hours between meals, what it eats and the rule that finds it (see
-- garden/visitors.lua). The first three are in the garden from the start.
local ANIMALS = {
    { id = "bee", en = _("Honey bee"), latin = "Apis mellifera", tr = "Bal arısı", about = "day", hours = 12, eats = _("nectar"), find = { kind = "start" } },
    { id = "ladybug", en = _("Seven-spot ladybird"), latin = "Coccinella septempunctata", tr = "Uğur böceği", about = "day", hours = 24, eats = _("aphids"), find = { kind = "start" } },
    { id = "snail", en = _("Garden snail"), latin = "Cornu aspersum", tr = "Bahçe salyangozu", about = "any", hours = 24, eats = _("tender leaves"), find = { kind = "start" } },
    { id = "butterfly", en = _("Swallowtail"), latin = "Papilio machaon", tr = "Kırlangıçkuyruk", about = "day", hours = 12, eats = _("nectar"), find = { kind = "bloom", n = 3 } },
    { id = "robin", en = _("European robin"), latin = "Erithacus rubecula", tr = "Kızılgerdan", about = "day", hours = 12, eats = _("worms and seeds"), find = { kind = "morning", n = 20 } },
    { id = "dragonfly", en = _("Emperor dragonfly"), latin = "Anax imperator", tr = "Yusufçuk", about = "day", hours = 12, eats = _("midges"), find = { kind = "plant", id = "water_lily", stage = 4 } },
    { id = "frog", en = _("Marsh frog"), latin = "Pelophylax ridibundus", tr = "Ova kurbağası", about = "any", hours = 24, eats = _("flies"), find = { kind = "plant", id = "water_lily", stage = 3 } },
    { id = "koi", en = _("Koi carp"), latin = "Cyprinus carpio", tr = "Koi balığı", about = "any", hours = 24, eats = _("pond weed"), find = { kind = "streak", n = 7, id = "water_lily", stage = 4 } },
    { id = "hedgehog", en = _("European hedgehog"), latin = "Erinaceus europaeus", tr = "Kirpi", about = "night", hours = 24, eats = _("beetles and slugs"), find = { kind = "night", n = 20 } },
    { id = "moth", en = _("Elephant hawk-moth"), latin = "Deilephila elpenor", tr = "Şahin güvesi", about = "night", hours = 12, eats = _("nectar"), find = { kind = "night", n = 60 } },
    { id = "fox", en = _("Red fox"), latin = "Vulpes vulpes", tr = "Kızıl tilki", about = "night", hours = 24, eats = _("field mice"), find = { kind = "books", n = 5 } },
    { id = "peacock", en = _("Indian peafowl"), latin = "Pavo cristatus", tr = "Tavus kuşu", about = "any", hours = 36, eats = _("seeds and berries"), find = { kind = "streak", n = 14 } },
}

local plant_by_id, animal_by_id = {}, {}

-- Join the plants to the names of the species registry.
for _i, p in ipairs(PLANTS) do
    local s = Species.get(p.id)
    p.en, p.latin, p.tr = s.en, s.latin, s.tr
    p.interval = p.hours and p.hours * 3600 or nil
    p.need = {}
    for i, d in ipairs(p.days) do p.need[i] = d * DAY end
    plant_by_id[p.id] = p
end
for _i, a in ipairs(ANIMALS) do
    a.interval = a.hours * 3600
    animal_by_id[a.id] = a
end

Cast.PLANTS = PLANTS
Cast.ANIMALS = ANIMALS
Cast.STAGES = 5   -- seed, sprout, bud, bloom, seed head

-- The plant with this id, or nil.
function Cast.plant(id)
    return plant_by_id[id]
end

-- The animal with this id, or nil.
function Cast.animal(id)
    return animal_by_id[id]
end

-- The plant or animal with this id, and which of the two it is.
function Cast.find(id)
    if plant_by_id[id] then return plant_by_id[id], "plant" end
    if animal_by_id[id] then return animal_by_id[id], "animal" end
end

-- Every id, plants first, in the order the garden shows them.
function Cast.ids()
    local out = {}
    for _i, p in ipairs(PLANTS) do out[#out + 1] = p.id end
    for _i, a in ipairs(ANIMALS) do out[#out + 1] = a.id end
    return out
end

return Cast
