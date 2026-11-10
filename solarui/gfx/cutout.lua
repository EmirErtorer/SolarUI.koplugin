-- Pictures cut to a shape and kept: a widget paints itself once into a
-- buffer of its own, the buffer is made see-through outside the shapes it
-- names, and from then on it is only blended in. Used for book covers, so
-- no cover is painted or cut again while it stays on screen.

local Alpha = require("solarui/gfx/alpha")
local Art = require("solarui/gfx/art")
local Blitbuffer = require("ffi/blitbuffer")
local Theme = require("solarui/theme")

local Cutout = {}

local MAX = 48
local kept = {}     -- key -> buffer
local order = {}    -- keys, oldest first
local version       -- the theme version the kept pictures were made for

-- Forget every kept picture.
function Cutout.free()
    for _k, bb in pairs(kept) do bb:free() end
    kept, order = {}, {}
end

-- Pixels per unit of a drawing's canvas outside a scene.
function Cutout.unit()
    return Theme.px(100) / 178
end

-- The kept w x h picture named `key`, made on first use: `paint(buf)` paints
-- it and returns the boxes { { x, y, w, h }, ... } where drawing `shape`
-- lets it show.
function Cutout.get(key, w, h, shape, paint)
    local v = Theme.get().version
    if v ~= version then
        Cutout.free()
        version = v
    end
    local bb = kept[key]
    if bb then return bb end
    bb = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
    local boxes = paint(bb)
    Alpha.clear(bb)
    local k = Cutout.unit()
    for _i, b in ipairs(boxes) do
        local s, dx, dy = Art.sprite(shape, b[3], b[4], b[3] / k, b[4] / k)
        if s then Alpha.show(bb, s, b[1] + dx, b[2] + dy) end
    end
    kept[key] = bb
    order[#order + 1] = key
    if #order > MAX then
        local old = table.remove(order, 1)
        kept[old]:free()
        kept[old] = nil
    end
    return bb
end

return Cutout
