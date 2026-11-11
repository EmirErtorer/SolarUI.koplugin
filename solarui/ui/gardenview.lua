-- The garden as a poster: the frame and the heading's room, the ground, every
-- plant at its stage and every animal that is about, each animal at the spot
-- it was dealt on this visit (see Layout.spread) and facing the way it was
-- dealt, plus tufts where hungry animals hide. Used by the garden screen and
-- the sleep picture. With `o.faded` it is the pale copy that stays behind a
-- picture shown larger. Taps are added only when `o.on_tap` is given.

local Layout = require("solarui/garden/layout")
local Sky = require("solarui/garden/sky")
local State = require("solarui/garden/state")

local GardenView = {}

-- The param of a plant's drawing: its stage, wilting, turning, fading and
-- the light of the sky phase.
function GardenView.plantParam(entry, faded, phase)
    return entry.rec.stage .. (entry.thirst == "wilted" and ":wilt" or "") .. (Layout.turned(entry.def.id) and ":flip" or "")
        .. (faded and ":wash" or "") .. (phase and (":" .. phase) or "")
end

-- The pose param of an animal's drawing: pose, turning, fading and light.
function GardenView.animalParam(pose, flip, faded, phase)
    return pose .. (flip and ":flip" or "") .. (faded and ":wash" or "") .. (phase and (":" .. phase) or "")
end

-- Put the garden on `scene`. o: { faded, seed (what deals the animals), pose
-- (id -> "1" or "2"), hour, on_tap(id, kind) for a plant or animal, sprites
-- (a table that is filled with each animal's element, to repaint it alone) }.
function GardenView.compose(scene, o)
    o = o or {}
    local vh = scene.vh
    local phase = Sky.phase(o.hour or tonumber(os.date("%H")))
    local light = (o.faded and "wash:" or "") .. phase
    scene:backdrop("garden_ground", 0, 0, Layout.WIDTH, vh, light)
    scene:border(14, 2.5)
    scene:border(21, 1.2)
    scene:frameOrnaments()
    for _i, e in ipairs(State.plants()) do
        local b = Layout.place(e.def.id, vh)
        scene:backdrop("plant_" .. e.def.id, b.x, b.y, b.w, b.h, GardenView.plantParam(e, o.faded, phase))
        if o.on_tap then scene:touch(b.x, b.y, b.w, b.h, function() o.on_tap(e.def.id, "plant") end) end
    end
    if o.on_book then
        local b = Layout.bookHit(vh)
        scene:touch(b.x, b.y, b.w, b.h, o.on_book)
    end
    local spread = Layout.spread(o.seed)
    for _i, a in ipairs(State.animals(o.hour)) do
        local id = a.def.id
        local b = Layout.at(spread[id], vh)
        if a.here then
            local function param() return GardenView.animalParam(o.pose and o.pose[id] or "1", b.flip, o.faded, phase) end
            if o.faded then scene:backdrop("animal_" .. id, b.x, b.y, b.w, b.h, param())
            else
                local el = scene:sprite("animal_" .. id, b.x, b.y, b.w, b.h, nil, param)
                if o.sprites then o.sprites[id] = el end
            end
        elseif a.mood == "hiding" then
            scene:backdrop("garden_tuft", b.x, b.y, b.w, b.h, light)
        end
        local hit = b.hit or b
        if o.on_tap and (a.here or a.mood == "hiding") then scene:touch(hit.x, hit.y, hit.w, hit.h, function() o.on_tap(id, "animal") end) end
    end
end

return GardenView
