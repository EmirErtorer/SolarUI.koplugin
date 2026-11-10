-- How the garden's lives change with time. Nothing runs in the background:
-- every function takes the time `now` and works out what happened since the
-- record was last looked at. A plant has a record { stage, grown, at, watered,
-- gen }; an animal { fed }. Nothing ever dies: a thirsty plant wilts and
-- stops growing, a hungry animal hides, and a drink or a meal brings it back.

local Care = {}

Care.FINE = "fine"
Care.THIRSTY = "thirsty"
Care.WILTED = "wilted"
Care.CONTENT = "content"
Care.HUNGRY = "hungry"
Care.HIDING = "hiding"

-- How a plant is: fine up to one interval after its last drink, thirsty up to
-- two, wilted after that. A plant that needs no water is always fine.
function Care.thirst(rec, def, now)
    if not def.interval then return Care.FINE end
    local age = now - (rec.watered or rec.at or now)
    if age <= def.interval then return Care.FINE end
    if age <= 2 * def.interval then return Care.THIRSTY end
    return Care.WILTED
end

-- Let a plant grow up to `now`. It grows only while it is not wilted; each
-- stage takes the plant's days (def.need) and the last, the seed head, takes
-- no more. Returns the stages it reached, in order.
function Care.grow(rec, def, now)
    local reached = {}
    local from = rec.at or now
    local dry = def.interval and ((rec.watered or from) + 2 * def.interval) or math.huge
    local thriving = math.max(0, math.min(now, dry) - from)
    rec.at = math.max(from, now)
    if rec.stage >= #def.need + 1 then return reached end
    rec.grown = (rec.grown or 0) + thriving
    while rec.stage <= #def.need and rec.grown >= def.need[rec.stage] do
        rec.grown = rec.grown - def.need[rec.stage]
        rec.stage = rec.stage + 1
        reached[#reached + 1] = rec.stage
    end
    if rec.stage > #def.need then rec.grown = 0 end
    return reached
end

-- Give a plant a drink.
function Care.water(rec, now)
    rec.watered = now
end

-- Cut back a plant that has gone to seed: it starts again as a sprout, one
-- generation on. Returns false when it has not gone to seed.
function Care.collect(rec, def, now)
    if rec.stage <= #def.need then return false end
    rec.stage, rec.grown, rec.at, rec.watered = 2, 0, now, now
    rec.gen = (rec.gen or 1) + 1
    return true
end

-- How an animal is: content up to one interval after its last meal, hungry up
-- to two, hiding after that.
function Care.hunger(rec, def, now)
    local age = now - (rec.fed or now)
    if age <= def.interval then return Care.CONTENT end
    if age <= 2 * def.interval then return Care.HUNGRY end
    return Care.HIDING
end

-- Feed an animal.
function Care.feed(rec, now)
    rec.fed = now
end

-- Seconds until a plant is thirsty again (0 when it already is, nil when it
-- needs no water).
function Care.untilThirsty(rec, def, now)
    if not def.interval then return nil end
    return math.max(0, (rec.watered or now) + def.interval - now)
end

return Care
