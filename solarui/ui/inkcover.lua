-- One of Ink Away's notebooks or drawings on SolarUI's notebook shelf: its
-- cover (a PNG drawn once by gfx/inkrender.lua) fitted to the cell, standing
-- on the shelf at the cell's foot and centred, with a soft shadow; a pale
-- card with the name while the cover is still being drawn. Decoded and
-- scaled pictures are kept in a small most-recently-used cache, so turning
-- pages or coming back costs no decoding.

local Blitbuffer = require("ffi/blitbuffer")
local Element = require("solarui/ui/element")
local Paint = require("solarui/gfx/paint")
local RenderImage = require("ui/renderimage")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")

local InkCover = Element:extend({})

local MAX = 40
local cache, count, tick = {}, 0, 0   -- key -> { bb, used }

-- The picture in `file` scaled to fit w x h, kept; nil when it can't be read.
local function fitted(file, w, h)
    local key = file .. "|" .. w .. "|" .. h
    tick = tick + 1
    local e = cache[key]
    if e then e.used = tick; return e.bb or nil end
    local bb = false
    local ok, img = pcall(function() return RenderImage:renderImageFile(file, false) end)
    if ok and img then
        local iw, ih = img:getWidth(), img:getHeight()
        local k = math.min(w / iw, h / ih)
        bb = RenderImage:scaleBlitBuffer(img, math.max(1, math.floor(iw * k)), math.max(1, math.floor(ih * k)), true)
    end
    if count >= MAX then
        local oldest, old_key
        for k2, c in pairs(cache) do
            if not oldest or c.used < oldest then oldest, old_key = c.used, k2 end
        end
        if cache[old_key].bb then cache[old_key].bb:free() end
        cache[old_key], count = nil, count - 1
    end
    cache[key] = { bb = bb, used = tick }
    count = count + 1
    return bb or nil
end

-- Forget every kept picture (the covers were drawn anew).
function InkCover.forget()
    for _k, e in pairs(cache) do if e.bb then e.bb:free() end end
    cache, count = {}, 0
end

-- Draw the cover, or the card that stands in for it.
function InkCover:draw(bb, x, y)
    local th = Theme.get()
    local w, h = self.w, self.h
    local shadow = math.max(2, Theme.px(4))
    local img = self.file and fitted(self.file, w - shadow, h - shadow)
    if img then
        local iw, ih = img:getWidth(), img:getHeight()
        local ix, iy = x + math.floor((w - shadow - iw) / 2), y + h - shadow - ih
        Paint.fill(bb, ix + shadow, iy + shadow, iw, ih, th.c.line)
        if Theme.nightMode() then
            local same = Blitbuffer.new(iw, ih, bb:getType())
            same:blitFrom(img, 0, 0, 0, 0, iw, ih)
            bb:invertblitFrom(same, ix, iy, 0, 0, iw, ih)
            same:free()
        else
            bb:blitFrom(img, ix, iy, 0, 0, iw, ih)
        end
        return
    end
    -- still being drawn: a card in the shelf's shape with the name
    local cw = math.min(w - shadow, math.floor((h - shadow) * 2 / 3))
    local cx = x + math.floor((w - shadow - cw) / 2)
    Paint.fill(bb, cx + shadow, y + shadow, cw, h - shadow, th.c.line)
    Paint.fill(bb, cx, y, cw, h - shadow, th.c.soft)
    local lines = Text.wrap("small", self.name or "", cw - Theme.px(12), 3)
    local lh = Text.height("small")
    for i, l in ipairs(lines) do
        Text.draw(bb, cx + math.floor((cw - Text.width("small", l)) / 2), y + math.floor((h - #lines * lh) / 2) + (i - 1) * lh, "small", l, th.c.muted)
    end
end

return InkCover
