-- The garden as a poster: the frame and the heading's room, the ground, every
-- plant at its stage, every animal that is about, bare beds for what could be
-- planted and tufts where hungry animals hide. Used by the garden screen and
-- the sleep picture. With `o.faded` it is the pale copy that stays behind a
-- picture shown larger. Taps are added only when `o.on_tap` is given.

local Cast = require("solarui/garden/cast")
local Layout = require("solarui/garden/layout")
local State = require("solarui/garden/state")

local GardenView = {}

-- The param of a plant's drawing: its stage, wilting and fading.
local function plantParam(entry, faded)
    return entry.rec.stage .. (entry.thirst == "wilted" and ":wilt" or "") .. (faded and ":wash" or "")
end

-- Put the garden on `scene`. o: { faded, pose (id -> "1" or "2"), hour,
-- on_tap(id, kind) for a plant or animal, on_bed(id) for a bare bed, sprites
-- (a table that is filled with each animal's element, to repaint it alone) }.
function GardenView.compose(scene, o)
    o = o or {}
    local vh = scene.vh
    local wash = o.faded and "wash" or nil
    scene:border(14, 2.5)
    scene:border(21, 1.2)
    scene:frameOrnaments()
    scene:backdrop("garden_ground", 0, 0, Layout.WIDTH, vh, wash)
    local planted = {}
    for _i, e in ipairs(State.plants()) do
        local b = Layout.place(e.def.id, vh)
        planted[e.def.id] = true
        scene:backdrop("plant_" .. e.def.id, b.x, b.y, b.w, b.h, plantParam(e, o.faded))
        if o.on_tap then scene:touch(b.x, b.y, b.w, b.h, function() o.on_tap(e.def.id, "plant") end) end
    end
    for _i, def in ipairs(Cast.PLANTS) do
        if not planted[def.id] then
            local b = Layout.place(def.id, vh)
            scene:backdrop("garden_plot", b.x, b.y + b.h - 70, b.w, 70, wash)
            if o.on_bed then scene:touch(b.x, b.y + b.h - 80, b.w, 80, function() o.on_bed(def.id) end) end
        end
    end
    for _i, a in ipairs(State.animals(o.hour)) do
        local b = Layout.place(a.def.id, vh)
        if a.here then
            local pose = (o.pose and o.pose[a.def.id] or "1") .. (o.faded and ":wash" or "")
            if o.faded then scene:backdrop("animal_" .. a.def.id, b.x, b.y, b.w, b.h, pose)
            else
                local el = scene:sprite("animal_" .. a.def.id, b.x, b.y, b.w, b.h, nil, function() return (o.pose and o.pose[a.def.id] or "1") end)
                if o.sprites then o.sprites[a.def.id] = el end
            end
        elseif a.mood == "hiding" then
            scene:backdrop("garden_tuft", b.x, b.y, b.w, b.h, wash)
        end
        if o.on_tap and (a.here or a.mood == "hiding") then scene:touch(b.x, b.y, b.w, b.h, function() o.on_tap(a.def.id, "animal") end) end
    end
end

return GardenView
