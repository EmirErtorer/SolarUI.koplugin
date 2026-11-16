-- A plant or animal standing in the garden's arch (art/garden.lua
-- garden_arch) as large as the arch allows: the drawing's strokes (not its
-- box, which keeps room around the art) are measured once, then scaled until
-- they nearly touch the arch's inner rule, at its straight sides or its round
-- head, standing on its floor. Used on home, on the garden's big card and in
-- the garden's popup.

local Art = require("solarui/gfx/art")

local ArchFit = {}

-- The arch's inner rule, how far the picture keeps from it and how high its
-- floor is, in the units of the arch's own drawing canvas.
ArchFit.INSET = 20
ArchFit.GAP = 6
ArchFit.FLOOR = 16

-- Where the strokes of drawing `name` (in its box `size`) lie with each of
-- `params`, joined: { x, y, w, h } in the box's units; measured once.
local drawn = {}
local function strokes(name, size, params)
    local x0, y0, x1, y1
    for _i, param in ipairs(params) do
        local key = name .. "|" .. tostring(param)
        local c = drawn[key]
        if not c then
            local bb, dx, dy = Art.sprite(name, size.w, size.h, size.w, size.h, param)
            c = bb and { x = dx, y = dy, w = bb:getWidth(), h = bb:getHeight() } or { x = 0, y = 0, w = size.w, h = size.h }
            drawn[key] = c
        end
        x0, y0 = math.min(x0 or c.x, c.x), math.min(y0 or c.y, c.y)
        x1, y1 = math.max(x1 or c.x + c.w, c.x + c.w), math.max(y1 or c.y + c.h, c.y + c.h)
    end
    return { x = x0, y = y0, w = x1 - x0, h = y1 - y0 }
end

-- The largest scale at which strokes `c` stand on the floor of an arch aw x
-- ah, centred, clear of its sides and round head; `u` is the size of one
-- unit of the arch's canvas.
local function scale(c, aw, ah, u)
    local r = aw / 2
    local R = r - (ArchFit.INSET + ArchFit.GAP) * u
    local floor = ah - ArchFit.FLOOR * u
    local function fits(k)
        local hw, top = c.w * k / 2, floor - c.h * k
        if hw > R then return false end
        return top >= r - math.sqrt(R * R - hw * hw)
    end
    local lo, hi = 0, floor / math.max(1, c.h)
    for _i = 1, 24 do
        local mid = (lo + hi) / 2
        if fits(mid) then lo = mid else hi = mid end
    end
    return lo
end

-- Where to draw `name` (box `size`, drawn with any of `params`, the first being
-- the one shown) in an arch aw x ah whose canvas is `canvas_w` units wide
-- (aw when the arch is drawn in the same units): x, y (from the arch's corner),
-- w, h of the drawing's box.
function ArchFit.box(name, size, params, aw, ah, canvas_w)
    local u = aw / (canvas_w or aw)
    local c = strokes(name, size, params)
    local k = scale(c, aw, ah, u)
    return aw / 2 - (c.x + c.w / 2) * k, ah - ArchFit.FLOOR * u - (c.y + c.h) * k, size.w * k, size.h * k
end

return ArchFit
