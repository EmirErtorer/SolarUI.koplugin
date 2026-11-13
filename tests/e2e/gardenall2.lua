-- The card of every plant and every animal, in every state, with a screenshot of
-- each and a check of what it says and which buttons it has: a plant as a seed,
-- a sprout, a bud, in bloom, thirsty, wilted, gone to seed and resting for the
-- winter; an animal content, hungry, hiding and asleep for the winter.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local State = K.state()
local Cast = K.cast()
local GardenPopup = require("solarui/ui/gardenpopup")
local GardenCard = require("solarui/ui/gardencard")

local function open(id)
    GardenPopup.open(id, K.inhabitants)
end

local function has(label) return H.find(label) ~= nil end

local PLANT_STATES = {
    { "seed", 1, "fine", "spring", "Seed" },
    { "sprout", 2, "fine", "spring", "Sprout" },
    { "bud", 3, "fine", "spring", "Bud" },
    { "bloom", 4, "fine", "spring", "In bloom" },
    { "thirsty", 4, "thirsty", "spring", "Thirsty" },
    { "wilted", 4, "wilted", "spring", "Wilted" },
    { "seedhead", 5, "fine", "spring", "Gone to seed" },
    { "winter", 4, "fine", "winter", "Resting for the winter" },
}
local EVERGREEN = { ivy = true, bracken = true, water_lily = true }

for _, def in ipairs(Cast.PLANTS) do
    for _, st in ipairs(PLANT_STATES) do
        local name, stage, state, season, words = st[1], st[2], st[3], st[4], st[5]
        K.shot(string.format("p-%s-%s", def.id, name), function()
            K.reset({ season = season })
            K.everyone()
            K.plants(stage, state)
            K.go()
            open(def.id)
        end, function()
            local e = State.entry(def.id)
            local text = GardenCard.status(e, "plant")
            local want = words
            if season == "winter" and EVERGREEN[def.id] then want = "In bloom" end
            if state == "fine" and stage == 4 and season == "spring" then want = "In bloom" end
            local ok = text:find(want, 1, true) ~= nil
            if def.id == "water_lily" and (state == "thirsty" or state == "wilted") then ok = text:find("Needs no watering", 1, true) ~= nil end
            H.check(H.app().overlay() ~= nil and ok, def.id .. " " .. name .. ": the card says \"" .. want .. "\" (" .. text .. ")")
            if stage == 5 then
                H.check(has(def.id == "three_sisters" and "Harvest" or "Cut back"), def.id .. " gone to seed offers to cut back")
            elseif stage < 4 then
                H.check(has("Grow now"), def.id .. " growing offers a seed to bring it into bloom")
            elseif def.interval then
                H.check(has("Water"), def.id .. " in bloom offers a drink")
            end
        end)
    end
end

local ANIMAL_STATES = {
    { "content", "content", "spring", 13 },
    { "hungry", "hungry", "spring", 13 },
    { "hiding", "hiding", "spring", 13 },
    { "winter", "content", "winter", 13 },
}
for _, def in ipairs(Cast.ANIMALS) do
    for _, st in ipairs(ANIMAL_STATES) do
        local name, mood, season, hour = st[1], st[2], st[3], st[4]
        K.shot(string.format("n-%s-%s", def.id, name), function()
            K.reset({ season = season, hour = hour })
            K.everyone()
            K.animals(mood)
            K.go()
            open(def.id)
        end, function()
            local e = State.entry(def.id, hour)
            local text = GardenCard.status(e, "animal")
            local rests = false
            for _, r in ipairs(def.rests or {}) do if r == season then rests = true end end
            local want = rests and "Asleep" or mood == "hungry" and "Hungry" or mood == "hiding" and "Hiding" or "Content"
            H.check(H.app().overlay() ~= nil and text:find(want, 1, true) ~= nil, def.id .. " " .. name .. ": the card says \"" .. want .. "\" (" .. text .. ")")
            H.check(has("Feed"), def.id .. " has a Feed button")
        end)
    end
end

K.do_(function() if H.app().overlay() then H.app().closeDialog() end end)
