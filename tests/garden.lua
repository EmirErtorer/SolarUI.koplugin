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

local Season = require("solarui/garden/season")
Season.set("spring")   -- the suite does not depend on the month it runs in

local DAY, HOUR = 86400, 3600
local now = 1700000000
State.clock = function() return now end
local reading = { total = 100, pages = {}, streak = 0, books = 2 }
State.source = function() return reading end

-- the cast
do
    for _, p in ipairs(Cast.PLANTS) do
        Kit.ok(Lore.get(p.id) ~= "", "lore for the plant " .. p.id)
        Kit.ok(p.latin and p.en and #p.need == 4, "names and stages for " .. p.id)
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
        local b = Layout.PLANTS[id] or Layout.waypoint(id, 1)
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
    Kit.ok(not State.water("tulip") and select(2, State.water("tulip")) == "fresh", "a plant just watered is not watered again")
    now = now + 30 * HOUR
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

-- visits, thanks, cutting back and giving back, on a fresh garden
do
    local Settings = require("solarui/settings")
    Settings.set("garden", nil)
    State.unload()
    now = 1700000000 + 400 * DAY
    reading.total, reading.books = 100, 2
    State.get()
    now = now + 3600
    State.refresh()
    local d = State.get()
    local function text() local t = {}; for _, l in ipairs(Journal.lines()) do t[#t + 1] = l.text end; return table.concat(t, "|") end
    Kit.ok(text():find("visited") or text():find("afternoon at") or text():find("called on"), "the bee visits a flower the first day")
    local marked = 0
    for _, rec in pairs(d.plants) do if rec.pollinated then marked = marked + 1 end end
    Kit.ok(marked == 1, "and the flower is marked pollinated (" .. marked .. ")")
    local before = #State.journal()
    State.refresh()
    Kit.ok(#State.journal() == before, "visits happen once a day")
    now = now + DAY
    reading.total = 140
    State.refresh()
    Kit.ok(text():find("40 pages"), "pages read are thanked for")
    local lines = #State.journal()
    reading.total = 150
    State.refresh()
    Kit.ok(not text():find("10 pages"), "but only once a day")
    -- cutting back
    local rec = d.plants.tulip
    rec.stage, rec.seeded, rec.pollinated = 5, now, nil
    local seeds = State.seeds()
    local ok, gain = State.collect("tulip")
    Kit.ok(ok and gain == .5, "seed heads cut back too early give half")
    rec.stage, rec.seeded = 5, now - 3 * DAY
    ok, gain = State.collect("tulip")
    Kit.ok(ok and gain == 1 and State.seeds() == seeds + 1, "ripe ones give a seed")
    rec.stage, rec.seeded, rec.pollinated = 5, now - 3 * DAY, true
    ok, gain = State.collect("tulip")
    Kit.ok(gain == 2, "and a visited flower gives one more")
    rec.stage, rec.seeded = 5, now - 3 * DAY
    d.animals.bee.fed = now - 10 * HOUR
    d.animals.ladybug.fed = now - 60 * HOUR
    ok, gain = State.collect("tulip", "birds")
    Kit.ok(ok and gain == 0 and d.animals.ladybug.fed == now and d.animals.bee.fed < now, "seed heads left for the birds feed the hungriest animal")
    rec.stage, rec.seeded = 5, now - 3 * DAY
    ok, gain = State.collect("tulip", "scatter")
    Kit.ok(gain == .5, "scattered seeds give half a seed")
    Kit.ok(not State.collect("tulip"), "a sprout cannot be cut back")
    -- giving back
    Kit.ok(State.owed() == 0 and not State.giveBack(true), "nothing to give back before a book is finished")
    reading.books = 3
    Kit.ok(State.owed() == 1, "a finished book asks for a gift to the wild edge")
    Kit.ok(State.giveBack(true) and State.given() == 1 and State.owed() == 0, "giving counts and answers the book")
    reading.books = 4
    State.giveBack(false)
    Kit.ok(State.given() == 1 and State.owed() == 0, "a gift can be passed over")
    Kit.ok(text():find("wild edge"), "the journal remembers it")
    Settings.set("garden", nil)
    State.unload()
end

-- the sky, the larger animals and the book
do
    local Sky = require("solarui/garden/sky")
    Kit.ok(Sky.phase(4) == "night" and Sky.phase(5) == "morning" and Sky.phase(10) == "morning" and Sky.phase(11) == "day"
        and Sky.phase(16) == "day" and Sky.phase(17) == "golden" and Sky.phase(21) == "golden" and Sky.phase(22) == "night" and Sky.phase(0) == "night",
        "the sky changes at five, eleven, five in the afternoon and ten at night")
    local small, places = 0, {}
    for seed = 1, 60 do
        local d = Layout.spread(seed)
        for id, b in pairs(d) do
            local hit = b.hit or b
            if hit.w < Layout.HIT or hit.h < Layout.HIT then small = small + 1 end
            local shown = Layout.shown(id)
            if b.w ~= shown.w or b.h ~= shown.h then small = small + 1 end
        end
        places[d.bee.x .. "," .. d.bee.y] = true
    end
    local n = 0
    for _ in pairs(places) do n = n + 1 end
    Kit.ok(small == 0, "every animal is shown at its own size and can be tapped on at least " .. Layout.HIT .. " units")
    Kit.ok(Layout.shown("bee").w <= 110 and Layout.shown("dragonfly").w <= 100 and Layout.shown("fox").w > 130, "the bee and the dragonfly are not enlarged, the others are")
    Kit.ok(n >= 25, "the bee is dealt a different place almost every visit (" .. n .. " in 60)")
    -- the frog and the koi stay in the water on every place of their paths and never meet
    local cx, cy, ax, by = Layout.PROPS.pond.x + 150, Layout.PROPS.pond.y + 107.5, 133, 93.5
    local lily = Layout.PLANTS.water_lily
    local function inWater(b)
        for _, px in ipairs({ b.x, b.x + b.w }) do
            for _, py in ipairs({ b.y, b.y + b.h }) do
                if ((px - cx) / ax) ^ 2 + ((py - cy) / by) ^ 2 > 1 then return false end
            end
        end
        return true
    end
    local function meets(a, c) return a.x < c.x + c.w and c.x < a.x + a.w and a.y < c.y + c.h and c.y < a.y + a.h end
    local out, met = {}, {}
    for _, id in ipairs({ "frog", "koi" }) do
        for i = 1, #Layout.PATHS[id] do
            local b = Layout.waypoint(id, i)
            if not inWater(b) or meets(b, lily) then out[#out + 1] = id .. i end
        end
    end
    for i = 1, #Layout.PATHS.frog do
        for j = 1, #Layout.PATHS.koi do
            if meets(Layout.waypoint("frog", i), Layout.waypoint("koi", j)) then met[#met + 1] = i .. "/" .. j end
        end
    end
    Kit.ok(#out == 0, "every place of the frog's and the koi's paths is in the water, clear of the lily: " .. table.concat(out, ", "))
    Kit.ok(#met == 0, "the frog and the koi never meet: " .. table.concat(met, ", "))
    local hit = Layout.bookHit(1430)
    local t = Layout.at(Layout.PROPS.table, 1430)
    Kit.ok(hit.x >= t.x and hit.y >= t.y and hit.x + hit.w <= t.x + t.w and hit.y + hit.h <= t.y + t.h and hit.w >= 90, "the book on the table can be tapped inside the table")
    local Plaque = require("solarui/garden/plaque")
    Kit.ok(Plaque.readable("It was the best of times, it was the worst of times") and not Plaque.readable("A BIOGRAPHY BASED ON THE MOST RELIABLE TEXTS VOL"),
        "a passage is a sentence, not a heading in capitals")
end

-- the companion on home
do
    local Companion = require("solarui/garden/companion")
    local list = {
        { id = "a", kind = "plant", entry = { thirst = "fine" } },
        { id = "b", kind = "plant", entry = { thirst = "thirsty" } },
        { id = "c", kind = "animal", entry = { mood = "hiding" } },
        { id = "d", kind = "animal", entry = { mood = "hiding" } },
    }
    Kit.ok(Companion.need(list[2].entry, "plant") == 2 and Companion.need(list[3].entry, "animal") == 3, "needs are scored")
    Kit.ok(Companion.choose(list, "auto", 0).id == "c" and Companion.choose(list, "auto", 1).id == "d", "the neediest is chosen, the day picks among equals")
    Kit.ok(Companion.choose(list, "a", 0).id == "a", "a pinned one wins")
    Kit.ok(Companion.choose(list, "gone", 0).id == "c", "a pinned one that is not about is ignored")
    local fine = { list[1], { id = "e", kind = "plant", entry = { thirst = "fine" } } }
    Kit.ok(Companion.choose(fine, "auto", 0).id == "a" and Companion.choose(fine, "auto", 1).id == "e", "with nothing needed, the day chooses")
    Kit.ok(Companion.choose({}, "auto", 0) == nil, "an empty garden has no companion")
    local picked = Companion.pick("auto", 3, 12)
    Kit.ok(picked and picked.id and picked.need ~= nil, "a real garden gives a companion")
end

-- wording: nobody in the garden is called "it"
do
    local Guide = require("solarui/ui/gardenguide")
    local function clean(text, where)
        local bad = text:match("%f[%a][Ii]t%f[%A]") or text:match("%f[%a][Ii]ts%f[%A]") or text:match("%f[%a]itself%f[%A]") or text:match("%f[%a][Ii]t's%f[%a]")
        Kit.ok(not bad, "no \"it\" in " .. where .. (bad and (": " .. text) or ""))
    end
    for _, id in ipairs(Cast.ids()) do clean(Lore.get(id), "the lore of " .. id) end
    for _, a in ipairs(Cast.ANIMALS) do clean(Visitors.hint(a), "the hint for " .. a.id) end
    for k = 1, 3 do
        for _, kind in ipairs({ "sown", "sprout", "bud", "bloom", "seedhead", "wilt", "found", "hide", "back" }) do
            clean(Journal.line({ t = k, k = kind, id = "rose" }).text, "the journal line " .. kind .. k)
        end
    end
    for i, p in ipairs(Guide.pages()) do if p.title ~= "Who, not what" then clean((p.title or "") .. " " .. (p.text or ""), "guide page " .. i) end end
end

-- wording in the code: no "it" in any text of the garden's modules
do
    local files = {}
    local p = io.popen("ls '" .. REPO .. "'/solarui/garden/*.lua '" .. REPO .. "'/solarui/ui/garden*.lua '" .. REPO .. "'/solarui/screens/garden*.lua '" .. REPO .. "'/solarui/ui/homecompanion.lua")
    for f in p:lines() do files[#files + 1] = f end
    p:close()
    local bad = 0
    for _, f in ipairs(files) do
        local fh = io.open(f)
        local src = fh:read("*a")
        fh:close()
        for text in src:gmatch('_%(("[^\n]-")%)') do
            if not text:find('\\"it\\"', 1, true) then
                local hit = text:match("%f[%a][Ii]t%f[%A]") or text:match("%f[%a][Ii]ts%f[%A]") or text:match("%f[%a]itself%f[%A]") or text:match("%f[%a][Ii]t's%f[%A]")
                if hit then bad = bad + 1; print("FAIL: \"it\" in " .. f:match("[^/]*$") .. ": " .. text:sub(1, 90)) end
            end
        end
    end
    Kit.ok(bad == 0, "no \"it\" in any text of the garden's code (" .. bad .. ")")
end

-- the almanac
do
    local Almanac = require("solarui/garden/almanac")
    local Web = require("solarui/garden/web")
    local PlantPages, AnimalPages = require("solarui/garden/almanac_plants"), require("solarui/garden/almanac_animals")
    for _, id in ipairs(Cast.ids()) do
        local page = Almanac.page(id)
        Kit.ok(page and page.name and page.habitat and page.story and page.look, "an almanac page for " .. id)
        if page then for _, f in ipairs({ "name", "habitat", "story", "look" }) do
            local bad = page[f]:match("%f[%a][Ii]t%f[%A]") or page[f]:match("%f[%a][Ii]ts%f[%A]") or page[f]:match("%f[%a]itself%f[%A]")
            Kit.ok(not bad, "no \"it\" in the " .. f .. " of " .. id)
        end end
    end
    for _, p in ipairs(Cast.PLANTS) do
        local m = PlantPages[p.id].months
        Kit.ok(m and m[1] >= 1 and m[2] <= 12, "months for " .. p.id)
    end
    local n = 0
    for _ in pairs(PlantPages) do n = n + 1 end
    for _ in pairs(AnimalPages) do n = n + 1 end
    Kit.ok(n == #Cast.PLANTS + #Cast.ANIMALS, "no page for anyone who is not in the cast")
    for _, l in ipairs(Web.LINKS) do
        Kit.ok(Cast.find(l[1]) and Cast.find(l[2]) and l[3] ~= "", "a link between known members: " .. l[1] .. " " .. l[2])
        local bad = l[3]:match("%f[%a][Ii]t%f[%A]") or l[3]:match("%f[%a][Ii]ts%f[%A]")
        Kit.ok(not bad, "no \"it\" in the link " .. l[1] .. " " .. l[2])
    end
    Settings = require("solarui/settings")
    Settings.set("garden", nil)
    State.unload()
    now = 1700000000 + 800 * DAY
    reading.total, reading.books = 100, 2
    State.get()
    Kit.ok(Almanac.tier("rose") == 1 and Almanac.tier("fox") == 0, "a new neighbour is seen, an absent one not met")
    now = now + 8 * DAY
    Kit.ok(Almanac.tier("rose") == 2, "after a week they are known")
    State.rename("rose", "Rosie")
    Kit.ok(Almanac.tier("rose") == 2, "a nickname alone does not make a friend")
    now = now + 25 * DAY
    Kit.ok(Almanac.tier("rose") == 3, "a month and a nickname do")
    Kit.ok(Almanac.waiting("tulip") == 0 and Almanac.waiting("rose") == 0, "nothing is left to wait for")
    local flowers, asleep = Almanac.month(5)
    Kit.ok(#flowers > 3 and #asleep == 0, "May is full of flowers and nobody sleeps")
    flowers, asleep = Almanac.month(1)
    local sleeping = {}
    for _, id in ipairs(asleep) do sleeping[id] = true end
    Kit.ok(sleeping.hedgehog and not sleeping.robin, "the hedgehog sleeps in January")
    Kit.ok(#Almanac.web() >= 5 and #Almanac.linksOf("rose") == 1, "the web links the plants and the animals present")
    Kit.ok(Almanac.months("tulip") == "April to May", "months are put in words (" .. tostring(Almanac.months("tulip")) .. ")")
    Settings.set("garden", nil)
    State.unload()
end

-- the lines about the seasons in the book
do
    local Nature, Plaque = require("solarui/garden/nature"), require("solarui/garden/plaque")
    for _, season in ipairs(Season.ALL) do
        Kit.ok(#Nature.LINES[season] == 12, "twelve lines for " .. season)
        for _, text in ipairs(Nature.LINES[season]) do
            local n = select(2, text:gsub("[^\128-\191]", ""))
            Kit.ok(n >= 30 and n <= 220 and Plaque.readable(text), "a line that fits the book: " .. text:sub(1, 30))
        end
    end
    local candidates = Plaque.candidates
    Plaque.candidates = function() return { { text = "One", title = "T", author = "A" }, { text = "Two", title = "T", author = "A" }, { text = "Three", title = "T", author = "A" } } end
    Season.set("autumn")
    local dealt = Plaque.deal(5)
    Kit.ok(#dealt == 3 + 12 and dealt[3].title == "From the garden" and dealt[1].title == "T", "every third passage is a line about the season")
    Plaque.candidates = function() return {} end
    Kit.ok(#Plaque.deal(5) == 12, "with no highlights the lines go on alone")
    Plaque.candidates = candidates
    Season.set("spring")
end

-- the maple counts only books finished after the garden began
do
    local began = 1700000000
    local day = function(offset) return os.date("%Y-%m-%d", began + offset * DAY) end
    local list = { { date = day(-400) }, { date = day(-1) }, { date = day(0) }, { date = day(3) }, { date = day(90) } }
    Kit.ok(State.booksSince(list, began) == 3, "only the books finished on or after the day the garden began count")
    Kit.ok(State.booksSince(list, nil) == 5, "with no start every book counts")
    Kit.ok(State.booksSince({ { date = nil } }, began) == 0, "a book with no date is not counted")
end

-- what reading grows
do
    local Progress = require("solarui/garden/progress")
    local created = os.time({ year = 2026, month = 3, day = 10, hour = 12 })
    local v = Progress.vine(created, { "2026-03-09", "2026-03-10", "2026-03-12" })
    Kit.ok(v.days == 2 and v.leaves == 2 and v.flowers == 0, "the vine counts days read since the garden began")
    local many = {}
    for i = 1, 65 do many[i] = string.format("2026-%02d-%02d", 4 + math.floor((i - 1) / 28), (i - 1) % 28 + 1) end
    v = Progress.vine(created, many)
    Kit.ok(v.days == 65 and v.flowers == 2 and v.leaves == 5, "it flowers after every thirty")
    Kit.ok(Progress.vine(created, nil).days == 0, "no reading, no leaves")
    local y = Progress.year(3, 12)
    Kit.ok(y.leaves == 3 and not y.ripe, "the maple wears a leaf for each book of the year")
    Kit.ok(Progress.year(20, 12).leaves == Progress.MAPLE_LEAVES and Progress.year(12, 12).ripe, "up to a number, and the goal ripens the fruit")
    Kit.ok(not Progress.year(5, nil).ripe, "with no goal there is no fruit")
    local saved = reading.days
    reading.days, reading.year_books, reading.goal = { os.date("%Y-%m-%d", State.get().created + DAY) }, 4, 10
    local p = State.progress()
    Kit.ok(p.vine.days == 1 and p.year.books == 4 and p.year.goal == 10, "the garden reports it")
    reading.days = saved
end

-- the Three Sisters bed
do
    local Settings = require("solarui/settings")
    Settings.set("garden", nil)
    State.unload()
    now = 1700000000 + 2000 * DAY
    reading.total, reading.books = 100, 2
    State.get()
    State.refresh()
    Kit.ok(State.get().plants.three_sisters == nil, "the bed is not there at the start")
    Kit.ok(Visitors.hint(Cast.plant("three_sisters")):find("3 books"), "and the hint says what it takes")
    reading.books = 3
    State.refresh()
    local rec = State.get().plants.three_sisters
    Kit.ok(rec and rec.stage == 1, "three finished books lay out the bed, as a seed")
    State.refresh()
    Kit.ok(State.get().plants.three_sisters == rec, "once")
    rec.stage, rec.seeded = 5, now - 3 * DAY
    local d = State.get()
    d.animals.bee.fed, d.animals.snail.fed, d.animals.ladybug.fed = now - 50 * HOUR, now - 60 * HOUR, now - 70 * HOUR
    local seeds = State.seeds()
    local ok, gain = State.collect("three_sisters", "share")
    Kit.ok(ok and gain == 1 and State.seeds() == seeds + 1, "the harvest gives a seed")
    Kit.ok(d.animals.bee.fed == now and d.animals.snail.fed == now and d.animals.ladybug.fed == now, "and sharing it feeds the three hungriest")
    Settings.set("garden", nil)
    State.unload()
end

-- spot the visitor
do
    for seed = 1, 60 do
        local spread = Layout.spread(seed)
        local peek = Layout.peek(seed, spread)
        Kit.ok(peek and peek.hit.w >= Layout.HIT, "a place to peek for seed " .. seed)
        if peek then
            local others = Layout.all(Layout.HEIGHT, spread)
            for id, o in pairs(others) do
                local b = peek.hit
                Kit.ok(not (b.x < o.x + o.w and o.x < b.x + b.w and b.y < o.y + o.h and o.y < b.y + b.h), "the peeking face does not overlap " .. id .. " (seed " .. seed .. ")")
            end
        end
    end
    local Settings = require("solarui/settings")
    Settings.set("garden", nil)
    State.unload()
    State.get()
    local before = State.dew()
    local who = State.peek()
    Kit.ok(who == "bee" or who == "ladybug" or who == "snail", "one of the animals present is peeking")
    Kit.ok(State.claimPeek() == who and State.dew() == before + 1, "finding the face is a drop of dew")
    Kit.ok(State.peek() == nil and State.claimPeek() == false and State.dew() == before + 1, "once a day")
    now = now + DAY
    Kit.ok(State.peek() ~= nil, "and again tomorrow")
    Settings.set("garden", nil)
    State.unload()
end

-- the weekly things to do outdoors
do
    local Prompts = require("solarui/garden/prompts")
    for _, season in ipairs(Season.ALL) do Kit.ok(#Prompts.LIST[season] == 12, "twelve to choose from for " .. season) end
    local a, b = Prompts.of(1700000000, "spring"), Prompts.of(1700000000 + 7 * DAY, "spring")
    Kit.ok(#a.items == 3 and a.items[1].text ~= b.items[1].text and a.week ~= b.week, "three things, and different ones the next week")
    Kit.ok(Prompts.of(1700000000, "spring").items[2].text == a.items[2].text, "and the same all week")
    local Settings = require("solarui/settings")
    Settings.set("garden", nil)
    State.unload()
    State.get()
    local week = State.outsideWeek()
    Kit.ok(#week == 3 and not week[1].done and State.outsideTotals().done == 0, "a new week has nothing ticked")
    Kit.ok(State.toggleOutside(2) and State.outsideWeek()[2].done and not State.outsideWeek()[1].done, "ticking marks one thing")
    Kit.ok(State.outsideTotals().done == 1 and #State.outsideLog() == 1 and State.outsideLog()[1].text == week[2].text, "and keeps it in the log")
    Kit.ok(not State.toggleOutside(2) and State.outsideTotals().done == 0, "a tick can be taken back")
    State.toggleOutside(1); State.toggleOutside(2); State.toggleOutside(3)
    Kit.ok(State.outsideTotals().full_weeks == 1 and State.outsideTotals().since == now, "three done is a full week")
    now = now + 7 * DAY
    Kit.ok(not State.outsideWeek()[1].done and State.outsideTotals().done == 3, "the next week is fresh, and the log is kept")
    State.unload()
    Kit.ok(#State.outsideLog() == 3, "the log survives a reload")
    Settings.set("garden", nil)
    State.unload()
end

-- the weather
do
    local Weather = require("solarui/garden/weather")
    local Visits = require("solarui/garden/visits")
    local seen, counts = {}, {}
    for day = 1, 400 do
        local k = Weather.of(day, "summer")
        counts[k] = (counts[k] or 0) + 1
        seen[Weather.of(day, "winter")] = true
        Kit.ok(Weather.of(day, "summer") == k, "a day's weather does not change")
        Kit.ok(Weather.of(day, "summer") ~= "snow" and Weather.of(day, "winter") ~= "rain", "no snow in summer, no rain in winter")
    end
    Kit.ok(counts.clear > counts.rain and counts.rain > 20 and seen.snow, "summer is mostly clear, rain comes, winter brings snow")
    Weather.setOn(false)
    Kit.ok(Weather.of(5, "summer") == "clear", "with the weather off every day is clear")
    Weather.setOn(true)
    -- rain waters the beds once
    local Settings = require("solarui/settings")
    Settings.set("garden", nil)
    State.unload()
    Season.set("autumn")
    local day = 1
    now = 1700000000 + 1200 * DAY
    while Weather.of(Visits.day(now), "autumn") ~= "rain" do now = now + DAY end
    reading.total, reading.books = 100, 2
    State.get()
    local rec = State.get().plants.tulip
    rec.watered = now - 30 * HOUR
    local was = rec.watered
    State.refresh()
    Kit.ok(rec.watered == was + Season.adjust(Cast.plant("tulip"), "autumn").interval / 2, "rain gives half a drink")
    local again = rec.watered
    State.refresh()
    Kit.ok(rec.watered == again, "but only once a day")
    local text = {}
    for _, l in ipairs(Journal.lines()) do text[#text + 1] = l.text end
    Kit.ok(table.concat(text, "|"):find("[Rr]ain"), "and the journal says so")
    Settings.set("garden", nil)
    State.unload()
    Season.set("spring")
end

-- the seasons
do
    Kit.ok(Season.ofMonth(1) == "winter" and Season.ofMonth(4) == "spring" and Season.ofMonth(7) == "summer" and Season.ofMonth(10) == "autumn", "months fall in the northern seasons")
    Kit.ok(Season.ofMonth(1, true) == "summer" and Season.ofMonth(7, true) == "winter", "and the other way round in the south")
    Kit.ok(not Season.following() and Season.now() == "spring", "a picked season is the garden's season")
    Season.set(nil)
    Kit.ok(Season.following() and Season.now() == Season.calendar(), "with none picked the calendar rules")
    local tulip, ivy = Cast.plant("tulip"), Cast.plant("ivy")
    Kit.ok(Season.adjust(tulip, "winter").interval == tulip.interval * 2 and Season.adjust(tulip, "summer").interval < tulip.interval, "winter stretches the hours between drinks, summer shortens them")
    Kit.ok(Season.adjust(tulip, "winter").need[1] > tulip.need[1] and Season.adjust(tulip, "winter").latin == tulip.latin, "winter slows growth and the rest reads through")
    Kit.ok(Season.dormant(tulip, "winter") and not Season.dormant(ivy, "winter") and not Season.dormant(tulip, "summer"), "perennials die back in winter, ivy does not")
    Kit.ok(Season.rests(Cast.animal("hedgehog"), "winter") and not Season.rests(Cast.animal("hedgehog"), "summer") and not Season.rests(Cast.animal("robin"), "winter"), "some animals sleep through winter")
    Season.set("winter")
    local seen = {}
    for _, e in ipairs(State.animals(12)) do seen[e.def.id] = e end
    Kit.ok(seen.bee and seen.bee.resting and not seen.bee.here and seen.bee.mood == Care.CONTENT, "a sleeping animal is not about and never hungry")
    Kit.ok(State.plants()[1].dormant, "winter plants are dormant")
    Season.set("spring")
end

-- the companion for life: adopting, the bond, memories, goodbye
do
    local Pet = require("solarui/garden/pet")
    local Voice = require("solarui/garden/voice")
    State.unload()
    require("solarui/settings").set("garden", nil)
    now = 1700000000
    reading.total, reading.books, reading.streak = 100, 2, 0
    Kit.ok(Pet.get() == nil, "no companion at first")
    Kit.ok(not Pet.adopt("fox", "Rusty") and select(2, Pet.adopt("fox", "Rusty")) == "none", "someone not in the garden cannot be the companion")
    Kit.ok(Pet.adopt("tulip", "Tuli") and Pet.is("tulip") and State.name("tulip") == "Tuli", "a plant can be the companion, with a name")
    Kit.ok(not Pet.adopt("rose") and select(2, Pet.adopt("rose")) == "have", "only one companion at a time")
    Kit.ok(Pet.pages() == 0 and Pet.level() == 1 and Pet.days() == 1, "the bond starts at level one, day one")
    reading.total = 100 + Pet.LEVELS[2] + 5
    Pet.refresh({})
    local p = Pet.get()
    Kit.ok(p.level == 2 and #p.events == 1 and p.events[1].kind == "level", "reading together deepens the bond, and there is something to tell")
    Kit.ok(#p.diary == 2, "and the diary notes it")
    reading.total = 100 + 10
    Kit.ok(Pet.level(Pet.pages()) == 1, "the level is a function of the pages (the bond never drops: the saved level stays)")
    Kit.ok(p.level == 2, "the saved bond does not shrink")
    reading.total = 100 + Pet.LEVELS[3] + 1
    local beats = { { id = "a", at = 20, title = "The den", text = "A story for {days} days." }, { id = "b", at = 400, title = "The river", text = "A longer one." } }
    Pet.refresh(beats)
    Kit.ok(p.beats.a and not p.beats.b, "a memory comes at its pages, the next waits")
    -- books, streaks, anniversaries
    reading.books, reading.streak = 3, 7
    now = now + 40 * DAY
    Pet.refresh(beats)
    local kinds = {}
    for _, e in ipairs(p.events) do kinds[e.kind] = (kinds[e.kind] or 0) + 1 end
    Kit.ok(kinds.book == 1 and kinds.streak >= 2 and kinds.anniversary >= 2, "a finished book, streaks and days together are told")
    -- the voice: never a line said lately, conditions hold, words are filled in
    local ctx = { hour = "day", season = "spring", weather = "rain", level = 3, streak = 7, pages_today = 12, book = "Black Sheep", author = "Heyer",
        last = "Emma", total = 200, days = 41, name = "Tuli", away = 0, hour_number = 12 }
    local seen = {}
    for _ = 1, 3 do seen[Voice.pick("tap", ctx).key] = true end
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    Kit.ok(n == 3, "three taps give three different lines from a voice of three (" .. n .. ")")
    for _ = 1, 60 do
        local l = Voice.pick("idle", ctx, true)
        Kit.ok(not l.text:find("Snow"), "a snow line is not said in the rain")
    end
    local line = Voice.pick("book_now", ctx, true)
    Kit.ok(line and line.text:find("Black Sheep", 1, true) and not line.text:find("{"), "the book's name is filled in")
    local told = Voice.current()
    Kit.ok(told and told ~= "", "the companion has something to say on home")
    local again = Voice.current()
    Kit.ok(again == told, "the line stays until something changes")
    Kit.ok(Voice.react() ~= nil, "a tap is answered")
    -- a tap hears what waits to be told, one thing at a time
    local pet_p = Pet.get()
    pet_p.events = { { kind = "level", level = 2 }, { kind = "book" } }
    Kit.ok(Pet.waiting() == 2, "two things wait to be told")
    Voice.react()
    Kit.ok(Pet.waiting() == 1 and Pet.get().now.moment == "level", "a tap tells the first of them")
    Voice.react(); Voice.react()
    Kit.ok(Pet.waiting() == 0, "and the next, and then a tap is a plain tap again")
    -- a quiet companion: no lines, no memories, nothing waiting
    local Settings = require("solarui/settings")
    Settings.set("companion_talk", false)
    Kit.ok(Voice.current() == nil and Voice.react() == nil and #Voice.beats(Pet.get().id) == 0, "with the dialogue off the companion says nothing")
    Pet.get().events = {}
    reading.total = reading.total + 100000
    Pet.refresh({})
    Kit.ok(Pet.waiting() == 0, "and nothing waits to be told")
    Settings.set("companion_talk", true)
    Kit.ok(Pet.talks() and Voice.current() ~= nil, "the dialogue is on by default and comes back when switched on")
    -- goodbye
    Kit.ok(Pet.goodbye() and Pet.get() == nil and #Pet.orchard() == 1 and Pet.orchard()[1].name == "Tuli", "goodbye sends the companion to the orchard")
    Kit.ok(Pet.remembered("tulip") and not Pet.remembered("rose"), "the one who left is remembered")
    local Companion = require("solarui/garden/companion")
    local still = false
    for _, item in ipairs(Companion.list(12)) do if item.id == "tulip" then still = true end end
    Kit.ok(not still, "and no longer keeps company on home")
    Kit.ok(select(2, Pet.adopt("tulip")) == "orchard", "and cannot be taken again")
    -- coming back has to be earned: pages and days since they left
    local back = Pet.comeback("tulip")
    Kit.ok(back and not back.earned and back.pages_left == Pet.RETURN_PAGES and back.days_left == Pet.RETURN_DAYS, "a companion who left asks for pages and days before coming back")
    Kit.ok(select(2, Pet.comeBack("tulip")) == "have" or select(2, Pet.comeBack("tulip")) == "earn", "and cannot be taken back too soon")
    reading.total = reading.total + Pet.RETURN_PAGES
    Kit.ok(not Pet.comeback("tulip").earned, "pages alone are not enough")
    now = now + (Pet.RETURN_DAYS + 1) * DAY
    Kit.ok(Pet.comeback("tulip").earned, "pages and days together earn it")
    local left_level, left_diary = Pet.orchard()[#Pet.orchard()].level, #Pet.orchard()[#Pet.orchard()].diary
    Kit.ok(Pet.comeBack("tulip") and Pet.is("tulip") and not Pet.remembered("tulip") and Pet.get().returns == 1, "and they come back")
    Kit.ok(Pet.get().level == left_level and #Pet.get().diary == left_diary + 1, "with their bond and diary kept")
    Kit.ok(Voice.say("tulip", "locked", { name = "Tuli", pages = 10, days = 2 }) ~= nil and Voice.say("tulip", "returned", {}) ~= nil, "and they speak for themselves about it")
    local clean = true
    for _ = 1, 40 do
        local l = Voice.say("rose", "locked", { name = "Rosie", pages = 0, days = 3 })
        if l and l:find("0 pages", 1, true) then clean = false end
    end
    Kit.ok(clean, "a line never speaks of 0 pages still to read")
    Kit.ok(Pet.goodbye(), "and may say goodbye again")
    Kit.ok(Pet.adopt("rose", "Rosie") and Pet.is("rose"), "while a new companion can be chosen")
    Pet.goodbye()
    State.unload()
    require("solarui/settings").set("garden", nil)
    reading.books, reading.streak = 2, 0
end

-- wording of every voice: nobody in the garden is called "it"
do
    local files = {}
    local pf = io.popen("ls '" .. REPO .. "'/solarui/garden/voices/*.lua 2>/dev/null")
    for f in pf:lines() do files[#files + 1] = f end
    pf:close()
    local bad = 0
    for _, f in ipairs(files) do
        local fh = io.open(f)
        local src = fh:read("*a")
        fh:close()
        for text in src:gmatch('"([^"\n]*)"') do
            local hit = text:match("%f[%a][Ii]t%f[%A]") or text:match("%f[%a][Ii]ts%f[%A]") or text:match("%f[%a]itself%f[%A]") or text:match("%f[%a][Ii]t's%f[%A]")
            if hit and not text:find("[a-z_]+/") then bad = bad + 1; print("FAIL: \"it\" in " .. f:match("[^/]*$") .. ": " .. text:sub(1, 90)) end
        end
    end
    Kit.ok(bad == 0, "no \"it\" in any voice (" .. bad .. " in " .. #files .. " files)")
end

Kit.finish("garden")
