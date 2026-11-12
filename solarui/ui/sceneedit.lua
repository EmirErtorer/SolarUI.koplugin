-- The placement tweaks of a scene's named groups (data/layout_overrides.lua)
-- and what the layout editor needs from a scene: switches to ignore the
-- tweaks or hide a group, and the box of every group once it is laid out.

local SceneEdit = {}

-- Ignore the saved tweaks (the editor draws the plain layout) and hide these groups.
SceneEdit.raw = false
SceneEdit.hide = {}

-- The tweak for a group of a screen, or nil.
function SceneEdit.lookup(slot, id)
    if SceneEdit.hide[id] then return { hidden = true } end
    if SceneEdit.raw then return nil end
    local all = require("solarui/data/layout_overrides")
    local o = all[slot] and all[slot][id]
    if type(o) ~= "table" then return nil end
    return o
end

-- The smallest corner of a group's parts, in units.
local function origin(g)
    local x, y
    for _i, m in ipairs(g.members) do
        x = math.min(x or m.unit[1], m.unit[1])
        y = math.min(y or m.unit[2], m.unit[2])
    end
    return x or 0, y or 0
end

-- Move and stretch a group's parts by its tweak: shifted by dx, dy and
-- stretched from the group's top-left corner by sx, sy.
function SceneEdit.apply(scene, g, o)
    if not o then return end
    local dx, dy, sx, sy = o.dx or 0, o.dy or 0, o.sx or 1, o.sy or 1
    if g.uniform then sy = sx end
    if dx == 0 and dy == 0 and sx == 1 and sy == 1 then return end
    local gx, gy = origin(g)
    for _i, m in ipairs(g.members) do
        local u = m.unit
        scene:refit(m, gx + dx + (u[1] - gx) * sx, gy + dy + (u[2] - gy) * sy, u[3] * sx, u[4] and u[4] * sy)
    end
end

-- The box of every group as laid out, in units: { id, label, x, y, w, h,
-- ox, oy, uniform } where ox, oy is the corner the tweaks stretch from.
function SceneEdit.boxes(scene)
    local out = {}
    local k = scene.k
    for _i, g in ipairs(scene.groups) do
        if not g.hidden then
            local x0, y0, x1, y1
            for _j, m in ipairs(g.members) do
                local px, py, pw, ph = scene:pixelBox(m)
                x0, y0 = math.min(x0 or px, px), math.min(y0 or py, py)
                x1, y1 = math.max(x1 or px + pw, px + pw), math.max(y1 or py + ph, py + ph)
            end
            if x0 then
                local ox, oy = origin(g)
                out[#out + 1] = { id = g.id, label = g.label, x = (x0 - scene.ox) / k, y = y0 / k, w = (x1 - x0) / k, h = (y1 - y0) / k,
                    ox = ox, oy = oy, uniform = g.uniform or nil }
            end
        end
    end
    return out
end

return SceneEdit
