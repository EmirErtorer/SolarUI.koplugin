-- The garden's logic on KOReader's real code with throwaway settings: growth
-- and thirst on a fake clock, hunger, dew and seeds from reading, who finds
-- the garden and when, nicknames, the journal, lore for every one, and that
-- nothing on the poster overlaps.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/garden.lua <repo>

local REPO = arg[1] or "."
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)

local Cast = require("solarui/garden/cast")
local Care = require("solarui/garden/care")
local Layout = require("solarui/garden/layout")
local Lore = require("solarui/garden/lore")
local State = require("solarui/garden/state")
local Visitors = require("solarui/garden/visitors")
local Journal = require("solarui/garden/journal")

local DAY, HOUR = 86400, 3600
local now = 1700000000
State.clock = function() return now end
local reading = { total = 100, pages = {}, streak = 0, books = 2 }
State.source = function() return reading end

-- the cast
do
    for _, p in ipairs(Cast.PLANTS) do
        Kit.ok(Lore.get(p.id) ~= "", "lore for the plant " .. p.id)
        Kit.ok(p.latin and p.tr and p.en and #p.need == 4, "names and stages for " .. p.id)
        Kit.ok(Layout.PLANTS[p.id] ~= nil, "a place for the plant " .. p.id)
    end
    for _, a in ipairs(Cast.ANIMALS) do
        Kit.ok(Lore.get(a.id) ~= "", "lore for the animal " .. a.id)
        Kit.ok(Layout.ANIMALS[a.id] ~= nil, "a place for the animal " .. a.id)
    end
    local n = 0
    for _ in pairs(Layout.PLANTS) do n = n + 1 end
    Kit.ok(n == #Cast.PLANTS, "every place holds a plant of the cast")
end

-- care: plants
do
    local def = Cast.plant("tulip")
    local rec = { stage = 1, grown = 0, at = now, watered = now, gen = 1 }
    Kit.ok(Care.thirst(rec, def, now + def.interval) == Care.FINE, "a plant is fine for one interval")
    Kit.ok(Care.thirst(rec, def, now + def.interval + 1) == Care.THIRSTY, "then thirsty")
    Kit.ok(Care.thirst(rec, def, now + 2 * def.interval + 1) == Care.WILTED, "then wilted")
    Kit.ok(Care.thirst(rec, Cast.plant("water_lily"), now + 100 * DAY) == Care.FINE, "a water lily never thirsts")
    local reached = Care.grow(rec, def, now + def.need[1] + 5)
    Kit.ok(rec.stage == 2 and reached[1] == 2, "a seed becomes a sprout after its days")
    -- water it all along and it blooms
    local t = now + def.need[1]
    for _ = 1, 120 do
        t = t + 12 * HOUR
        Care.water(rec, t)
        Care.grow(rec, def, t)
    end
    Kit.ok(rec.stage == 5, "a plant kept watered goes to seed (stage " .. rec.stage .. ")")
    Kit.ok(Care.collect(rec, def, t) and rec.stage == 2 and rec.gen == 2, "cutting back starts a new generation")
    Kit.ok(not Care.collect(rec, def, t), "a sprout cannot be cut back")
    -- left alone it stops growing instead of dying
    local lazy = { stage = 2, grown = 0, at = now, watered = now, gen = 1 }
    Care.grow(lazy, def, now + 400 * DAY)
    Kit.ok(lazy.stage == 3 or lazy.stage == 2, "a neglected plant stalls (stage " .. lazy.stage .. ")")
    Kit.ok(lazy.stage >= 2 and Care.thirst(lazy, def, now + 400 * DAY) == Care.WILTED, "and wilts, but is still there")
end

-- care: animals
do
    local def = Cast.animal("bee")
    local rec = { fed = now }
    Kit.ok(Care.hunger(rec, def, now + def.interval) == Care.CONTENT, "an animal is content for one interval")
    Kit.ok(Care.hunger(rec, def, now + def.interval + 1) == Care.HUNGRY, "then hungry")
    Kit.ok(Care.hunger(rec, def, now + 2 * def.interval + 1) == Care.HIDING, "then hiding")
end

-- visitors
do
    Kit.ok(Visitors.about(Cast.animal("bee"), 12) and not Visitors.about(Cast.animal("bee"), 23), "bees fly by day")
    Kit.ok(Visitors.about(Cast.animal("hedgehog"), 23) and not Visitors.about(Cast.animal("hedgehog"), 12), "hedgehogs walk at night")
    Kit.ok(Visitors.about(Cast.animal("snail"), 3) and Visitors.about(Cast.animal("snail"), 15), "snails are about any time")
    local pages = {}
    for w = 1, 7 do pages[w] = {}; for h = 0, 23 do pages[w][h] = 0 end end
    pages[1][22], pages[2][2], pages[3][8] = 10, 5, 5
    Kit.ok(Visitors.pagesIn(pages, 20, 4) == 15 and Visitors.pagesIn(pages, 5, 11) == 5, "pages by the hours they were read")
    local facts = Visitors.facts({ tulip = { stage = 4 }, rose = { stage = 4 }, iris = { stage = 4 } }, { pages = pages, streak = 8, books = 1 })
    local found = table.concat(Visitors.foundAll(facts), ",")
    Kit.ok(found:find("butterfly") and not found:find("hedgehog") and found:find("bee"), "three blooms bring the butterfly (" .. found .. ")")
    local f2 = Visitors.facts({ water_lily = { stage = 4 } }, { pages = pages, streak = 8, books = 0 })
    local g = table.concat(Visitors.foundAll(f2), ",")
    Kit.ok(g:find("frog") and g:find("dragonfly") and g:find("koi") and not g:find("peacock"), "the pond brings frog, dragonfly and koi (" .. g .. ")")
end

-- layout: nothing overlaps, nothing leaves the frame, whoever is dealt where
do
    for _, vh in ipairs({ 1430, 1500, 1800 }) do
        for seed = 1, 60 do
            local all, ids = Layout.all(vh, Layout.spread(seed)), {}
            for id in pairs(all) do ids[#ids + 1] = id end
            table.sort(ids)
            local clash = {}
            for i = 1, #ids do
                local a = all[ids[i]]
                if not ids[i]:match("^corner") and (a.x < 30 or a.x + a.w > 1042 or a.y + a.h > vh - 30) then clash[#clash + 1] = ids[i] .. " leaves the frame" end
                for j = i + 1, #ids do
                    local b = all[ids[j]]
                    if a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h then clash[#clash + 1] = ids[i] .. "/" .. ids[j] end
                end
            end
            Kit.ok(#clash == 0, "nothing overlaps on a canvas " .. vh .. " tall, deal " .. seed .. ": " .. table.concat(clash, ", "))
            if #clash > 0 then break end
        end
    end
    local pond = Layout.PROPS.pond
    for _, id in ipairs(Layout.INSIDE_POND) do
        local b = Layout.PLANTS[id] or Layout.FIXED[id]
        Kit.ok(b.x >= pond.x and b.y >= pond.y and b.x + b.w <= pond.x + pond.w and b.y + b.h <= pond.y + pond.h, id .. " is inside the pond")
    end
    local seen = {}
    for seed = 1, 40 do
        local d = Layout.spread(seed)
        seen[d.fox.x .. "," .. d.fox.y .. "," .. tostring(d.fox.flip)] = true
    end
    local count = 0
    for _ in pairs(seen) do count = count + 1 end
    Kit.ok(count >= 4, "the animals are dealt different places and faces on different visits (" .. count .. " different for the fox)")
    local d1, d2 = Layout.spread(7), Layout.spread(7)
    Kit.ok(d1.bee.x == d2.bee.x and d1.bee.y == d2.bee.y, "the same deal gives the same places")
    local turned = 0
    for id in pairs(Layout.PLANTS) do if Layout.turned(id) then turned = turned + 1 end end
    Kit.ok(turned >= 4 and turned < #Cast.PLANTS - 3 and not Layout.turned("ivy"), "some plants face the other way (" .. turned .. ")")
end

-- the kept garden
do
    local d = State.get()
    Kit.ok(d.plants.tulip and d.plants.tulip.stage == 4 and d.plants.rose.stage == 4, "the garden starts with every plant in bloom")
    Kit.ok(d.animals.bee and d.animals.snail and not d.animals.fox, "and three animals")
    Kit.ok(State.dew() == State.GIFT_DEW and State.seeds() == State.GIFT_SEEDS, "a gift of dew and seeds to begin with")
    reading.total = 130
    Kit.ok(State.dew() == State.GIFT_DEW + 30, "each page read is a drop of dew")
    Kit.ok(State.water("tulip") and State.dew() == State.GIFT_DEW + 30 - State.WATER, "watering costs dew")
    local ok, why = State.water("water_lily")
    Kit.ok(not ok and why == "dry", "a water lily needs no watering")
    Kit.ok(not State.sow("rose") and select(2, State.sow("rose")) == "bloom", "a plant in bloom needs no seed")
    State.get().plants.rose.stage = 2
    Kit.ok(State.sow("rose") and State.seeds() == State.GIFT_SEEDS - 1 and State.get().plants.rose.stage == 4, "a seed brings a plant into bloom")
    State.get().plants.iris.stage = 3
    Kit.ok(State.sow("iris") and not State.sow("lily"), "and seeds run out")
    reading.books = 3
    Kit.ok(State.seeds() == 1, "a finished book is a seed")
    -- a week passes unwatered: wilted, hidden animals, a journal that says so
    now = now + 8 * DAY
    State.refresh()
    local names = {}
    for _, l in ipairs(Journal.lines()) do names[#names + 1] = l.text end
    local all = table.concat(names, "|")
    Kit.ok(all:find("wilted") or all:find("drooped") or all:find("ran dry"), "the journal remembers what wilted")
    Kit.ok(all:find("hiding") or all:find("hidden") or all:find("hungry"), "and who went hiding")
    local hid = 0
    for _, a in ipairs(State.animals(12)) do if a.mood == Care.HIDING then hid = hid + 1 end end
    Kit.ok(hid == 3, "hungry animals hide")
    Kit.ok(State.feed("bee") and #State.animals(12) == 6, "a meal brings one back, and the new arrivals are not hungry")
    local bee
    for _, a in ipairs(State.animals(12)) do if a.def.id == "bee" then bee = a end end
    Kit.ok(bee.here and not (State.animals(23)[1].here and State.animals(23)[1].def.id == "bee"), "and the bee is about by day only")
    -- nickname
    Kit.ok(State.rename("tulip", "  Tülay  ") == "Tülay" and State.name("tulip") == "Tülay", "a plant takes a nickname")
    Kit.ok(State.rename("tulip", "a very very long nickname") == "a very very lo", "cut to fourteen letters")
    Kit.ok(State.rename("tulip", "") == nil and State.name("tulip") == "Garden tulip", "blank gives the common name back")
    -- it survives being loaded again
    State.unload()
    Kit.ok(State.get().plants.rose ~= nil, "the garden is kept between visits")
end

Kit.finish("garden")
