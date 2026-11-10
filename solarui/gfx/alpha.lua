-- The see-through part of 32-bit buffers: where a drawing really is inside
-- its buffer, a copy trimmed to just that, and one buffer cut to the shape
-- of another. All of it runs once, when a picture is made and kept.

local Blitbuffer = require("ffi/blitbuffer")
local ffi = require("ffi")

local Alpha = {}

-- The alpha byte of the first pixel and the bytes in a row.
local function alphas(bb)
    return ffi.cast("uint8_t*", bb.data) + 3, bb.stride
end

-- The box holding everything that is not fully see-through: x, y, w, h (nil
-- when the buffer is empty).
function Alpha.bounds(bb)
    local p, stride = alphas(bb)
    local w, h = bb:getWidth(), bb:getHeight()
    local x0, y0, x1, y1 = w, h, -1, -1
    for y = 0, h - 1 do
        local row = p + y * stride
        local first
        for x = 0, w - 1 do
            if row[x * 4] ~= 0 then first = x; break end
        end
        if first then
            local last = first
            for x = w - 1, first, -1 do
                if row[x * 4] ~= 0 then last = x; break end
            end
            if first < x0 then x0 = first end
            if last > x1 then x1 = last end
            if y < y0 then y0 = y end
            y1 = y
        end
    end
    if x1 < 0 then return nil end
    return x0, y0, x1 - x0 + 1, y1 - y0 + 1
end

-- `bb` trimmed to what is drawn in it: the new buffer and where its corner
-- was (the old one is freed), or `bb` itself at 0, 0 when nothing can go.
function Alpha.trim(bb)
    local x, y, w, h = Alpha.bounds(bb)
    if not x or (w == bb:getWidth() and h == bb:getHeight()) then return bb, 0, 0 end
    local out = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
    out:blitFrom(bb, 0, 0, x, y, w, h)
    bb:free()
    return out, x, y
end

-- Make all of `bb` see-through (its colours stay).
function Alpha.clear(bb)
    local p, stride = alphas(bb)
    local w = bb:getWidth()
    for y = 0, bb:getHeight() - 1 do
        local row = p + y * stride
        for x = 0, w - 1 do row[x * 4] = 0 end
    end
end

-- Show `bb` wherever `shape`, laid with its corner at (dx, dy), is solid:
-- each pixel takes the shape's alpha when that is more than its own.
function Alpha.show(bb, shape, dx, dy)
    local p, stride = alphas(bb)
    local sp, sstride = alphas(shape)
    local w, h = bb:getWidth(), bb:getHeight()
    local sw, sh = shape:getWidth(), shape:getHeight()
    for sy = math.max(0, -dy), math.min(sh, h - dy) - 1 do
        local row, srow = p + (sy + dy) * stride, sp + sy * sstride
        for sx = math.max(0, -dx), math.min(sw, w - dx) - 1 do
            local a = srow[sx * 4]
            if a > row[(sx + dx) * 4] then row[(sx + dx) * 4] = a end
        end
    end
end

return Alpha
