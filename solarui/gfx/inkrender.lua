-- Draws the covers of Ink Away's notebooks and the framed pictures of its
-- drawings for SolarUI's notebook shelf, each once, to a PNG that the shelf
-- then only shows (data/inkshelf.lua decides when): a notebook in one of the
-- eight boards of art/inkcovers.lua with its name set on the board's plate,
-- or its first page bound with a cloth spine or mounted in gilt; a drawing
-- (from the picture Ink Away keeps of it) in one of the frames of
-- art/inkframes.lua, the frame hugging the drawing's own shape. Nothing of a
-- notebook's or drawing's strokes is drawn here: the pictures are Ink Away's.

local Blitbuffer = require("ffi/blitbuffer")
local InkCovers = require("solarui/art/inkcovers")
local InkFrames = require("solarui/art/inkframes")
local RenderImage = require("ui/renderimage")
local Svg = require("solarui/art/svg")

local InkRender = {}

-- The size covers are drawn at, in pixels: a notebook's board, and the box a
-- framed drawing fits in.
InkRender.W = 360
InkRender.H = 540

-- Goes up whenever covers are drawn differently, so every cover is drawn anew.
InkRender.VERSION = 6

-- An "#rrggbb" colour as a blitbuffer colour.
local function rgb(hex)
    local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
    return Blitbuffer.ColorRGB32(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), 0xFF)
end

-- Rasterise SVG `body` drawn on a vw x vh canvas into a w x h picture, or nil.
local function raster(body, w, h, vw, vh)
    local file = require("solarui/gfx/scratch").path()
    local f = io.open(file, "w")
    if not f then return nil end
    f:write(Svg.document(w, h, string.format('<g transform="scale(%.5f %.5f)">%s</g>', w / vw, h / vh, body)))
    f:close()
    return RenderImage:renderSVGImageFile(file, w, h, 1)
end

-- Lay picture `img` over `bb` at (x, y), with its see-through parts.
local function over(bb, img, x, y)
    if img then
        bb:alphablitFrom(img, x, y, 0, 0, img:getWidth(), img:getHeight())
        img:free()
    end
end

-- The picture in PNG `file` scaled to cover w x h (cut to it), or nil.
local function picture(file, w, h, contain)
    if not file then return nil end
    local ok, img = pcall(function() return RenderImage:renderImageFile(file, false) end)
    if not (ok and img) then return nil end
    local iw, ih = img:getWidth(), img:getHeight()
    local k = contain and math.min(w / iw, h / ih) or math.max(w / iw, h / ih)
    local sw, sh = math.max(1, math.floor(iw * k + .5)), math.max(1, math.floor(ih * k + .5))
    local small = RenderImage:scaleBlitBuffer(img, sw, sh, false)
    if small ~= img then img:free() end
    return small
end

-- Blit picture `img` into the w x h box at (x, y), centred and cut to it.
local function into(bb, img, x, y, w, h)
    local iw, ih = img:getWidth(), img:getHeight()
    local sx, sy = math.max(0, math.floor((iw - w) / 2)), math.max(0, math.floor((ih - h) / 2))
    local dx, dy = x + math.max(0, math.floor((w - iw) / 2)), y + math.max(0, math.floor((h - ih) / 2))
    bb:blitFrom(img, dx, dy, sx, sy, math.min(w, iw), math.min(h, ih))
end

-- The face names are set in: the theme's display face at `size` pixels.
local function face(size)
    local Font = require("ui/font")
    local spec = require("solarui/theme").text("display")
    local display = spec and rawget(spec, "face")
    local name = display and display["orig_font"]
    -- (getFace scales a size for the screen; a cover is drawn in plain pixels)
    local k = require("device").screen:scaleBySize(1000) / 1000
    local px = math.max(6, size / (k > 0 and k or 1))
    local ok, f = pcall(function() return Font:getFace(name or "tfont", px) end)
    return ok and f or Font:getFace("tfont", px)
end

-- The characters of `s`, as code points and as the strings they are.
local function codepoints(s)
    local out, chars = {}, {}
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local a, b, c, d = ch:byte(1, 4)
        local cp = a
        if a >= 240 then cp = (a - 240) * 262144 + (b - 128) * 4096 + (c - 128) * 64 + (d - 128)
        elseif a >= 224 then cp = (a - 224) * 4096 + (b - 128) * 64 + (c - 128)
        elseif a >= 192 then cp = (a - 192) * 64 + (b - 128) end
        out[#out + 1], chars[#chars + 1] = cp, ch
    end
    return out, chars
end

-- The width of `s` in face `f`.
local function width(f, s)
    local RenderText = require("ui/rendertext")
    local w, prev = 0, 0
    for _i, cp in ipairs(codepoints(s)) do
        local g = RenderText:getGlyph(f, cp, false)
        if prev ~= 0 then w = w + f.ftsize:getKerning(prev, cp) end
        w = w + g.ax
        prev = cp
    end
    return w
end

-- Draw `s` in face `f` and colour `colour` with its baseline at (x, y).
local function glyphs(bb, f, s, x, y, colour)
    local RenderText = require("ui/rendertext")
    local pen, prev = 0, 0
    for _i, cp in ipairs(codepoints(s)) do
        local g = RenderText:getGlyph(f, cp, false)
        if prev ~= 0 then pen = pen + f.ftsize:getKerning(prev, cp) end
        local gb = g.bb
        bb:colorblitFromRGB32(gb, math.floor(x + pen + g.l), math.floor(y - g.t), 0, 0, gb:getWidth(), gb:getHeight(), colour)
        pen = pen + g.ax
        prev = cp
    end
end

-- `s` cut at the end with an ellipsis to fit `w` in face `f`.
local function cut(f, s, w)
    if width(f, s) <= w then return s end
    local _cps, chars = codepoints(s)
    for n = #chars - 1, 1, -1 do
        local t = table.concat(chars, "", 1, n) .. "\u{2026}"
        if width(f, t) <= w then return t end
    end
    return "\u{2026}"
end

-- `s` broken into lines no wider than `w` in face `f`: as many as it takes,
-- a word too long for a line cut to fit.
local function lines(f, s, w)
    local out, cur, cutting = {}, nil, false
    for word in s:gmatch("%S+") do
        local try = cur and (cur .. " " .. word) or word
        if width(f, try) <= w then cur = try
        else
            if cur then out[#out + 1] = cur end
            cur = cut(f, word, w)
            cutting = cutting or cur ~= word
        end
    end
    if cur then out[#out + 1] = cur end
    return out, cutting
end

-- Set the name `s` on the box x, y, w, h of `bb`, centred, in the largest
-- size that fits on up to three lines (the last cut with an ellipsis when it
-- still does not), in `ink`; with `light`, pressed into the board (a light
-- edge under the letters).
local function setName(bb, s, x, y, w, h, ink, light)
    s = (s or ""):gsub("_", " ")
    local size = math.floor(h * .46)
    local f, ls, lh
    while true do
        f = face(size)
        local height, ascent = f.ftsize:getHeightAndAscender()
        lh = height
        local cutting
        ls, cutting = lines(f, s, w * .9)
        if (not cutting and #ls <= 3 and #ls * lh <= h) or size <= 16 then
            f.ascent = ascent
            break
        end
        size = size - 1
    end
    local max = math.max(1, math.min(#ls, 3, math.floor(h / lh)))
    if #ls > max then
        ls[max] = cut(f, table.concat(ls, " ", max), w * .9)
        for i = #ls, max + 1, -1 do ls[i] = nil end
    end
    local top = y + (h - #ls * lh) / 2
    local _h, ascent = f.ftsize:getHeightAndAscender()
    for i, l in ipairs(ls) do
        local lx, base = x + (w - width(f, l)) / 2, top + (i - 1) * lh + ascent
        if light then glyphs(bb, f, l, lx + 1, base + 1, rgb(light)) end
        glyphs(bb, f, l, lx, base, rgb(ink))
    end
end

-- Write `bb` to PNG `file` by way of a temporary file. Returns whether it was written.
local function write(bb, file)
    local tmp = file .. ".tmp"
    local ok = pcall(function() bb:writePNG(tmp) end)
    bb:free()
    if not (ok and os.rename(tmp, file)) then
        os.remove(tmp)
        return false
    end
    return true
end

-- A notebook's cover in look `id` (art/inkcovers.lua) to PNG `file`: its
-- name on the board's plate, or its first page from PNG `page` (ruled paper
-- while there is none yet). Returns whether it was written.
function InkRender.notebook(file, id, name, page)
    local W, H = InkRender.W, InkRender.H
    local k = W / InkCovers.W
    local look = InkCovers.look(id) or InkCovers.LOOKS[1]
    local bb = Blitbuffer.new(W, H, Blitbuffer.TYPE_BBRGB32)
    if look.draw then
        bb:paintRectRGB32(0, 0, W, H, rgb("#3A3A30"))
        over(bb, raster(look.draw(), W, H, InkCovers.W, InkCovers.H), 0, 0)
        local p = look.plate
        setName(bb, name, p[1] * k, p[2] * k, p[3] * k, p[4] * k, look.ink, look.light)
        return write(bb, file)
    end
    -- a cover that shows the first page
    local mount = look.id == "mount"
    bb:paintRectRGB32(0, 0, W, H, rgb(mount and "#EFE4CC" or "#FBF8EE"))
    local x, y, w, h
    if mount then x, y, w, h = math.floor(34 * k), math.floor(34 * k), math.floor(W - 68 * k), math.floor(H - 68 * k)
    else x, y, w, h = math.floor(34 * k), 0, math.floor(W - 44 * k), H end
    local img = picture(page, w, h)
    if img then
        into(bb, img, x, y, w, h)
        img:free()
    else
        bb:paintRectRGB32(x, y, w, h, rgb("#FBF8EE"))
        for ly = y + math.floor(40 * k), y + h - 10, math.floor(18 * k) do bb:paintRectRGB32(x + 8, ly, w - 16, 1, rgb("#C9D6DE")) end
    end
    over(bb, raster(mount and InkCovers.mount() or InkCovers.pageEdges(), W, H, InkCovers.W, InkCovers.H), 0, 0)
    return write(bb, file)
end

-- The outer size of frame `id` round a picture iw x ih, fitted in the box
-- InkRender.W x H: w, h.
function InkRender.frameSize(id, iw, ih)
    local bw, bh = InkRender.W, InkRender.H
    local w, h = bw, bh
    for _i = 1, 3 do
        local b = InkFrames.band(id, w, h)
        local k = math.min((bw - 2 * b) / iw, (bh - 2 * b) / ih)
        w, h = math.floor(iw * k + 2 * b + .5), math.floor(ih * k + 2 * b + .5)
    end
    return w, h
end

-- A drawing in frame `id` (art/inkframes.lua) to PNG `file`, from its
-- picture in PNG `pic` (plain paper in the drawing's shape while there is
-- none yet, `shape` being w / h). Returns whether it was written.
function InkRender.drawing(file, id, pic, shape)
    local img = picture(pic, InkRender.W, InkRender.H, true)
    local iw, ih = 3, 4
    if img then iw, ih = img:getWidth(), img:getHeight()
    elseif shape then iw, ih = 1000 * shape, 1000 end
    local w, h = InkRender.frameSize(id, iw, ih)
    local bb = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
    bb:paintRectRGB32(0, 0, w, h, rgb("#FBF8EE"))
    local wx, wy, ww, wh = InkFrames.window(id, w, h)
    if img then
        local fit = RenderImage:scaleBlitBuffer(img, ww, wh, false)
        bb:blitFrom(fit, wx, wy, 0, 0, ww, wh)
        if fit ~= img then fit:free() end
        img:free()
    end
    over(bb, raster(InkFrames.svg(id, w, h), w, h, w, h), 0, 0)
    return write(bb, file)
end

return InkRender
