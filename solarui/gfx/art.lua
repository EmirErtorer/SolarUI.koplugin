-- The artwork: plants drawn as SVG in the theme's colours at exactly the size
-- asked for, rasterised once and kept. A drawing is a function in
-- solarui/art/sprites.lua. Small ones that change (a flower that fills) are
-- kept as sprites and blended in on every paint; a whole backdrop of them is
-- composed once into a layer the size of the screen and then just copied.
-- A drawing may reach past the box it is given: it is rasterised with room
-- around it and trimmed to what was drawn, so its box never cuts it.

local Alpha = require("solarui/gfx/alpha")
local Blitbuffer = require("ffi/blitbuffer")
local DataStorage = require("datastorage")
local RenderImage = require("ui/renderimage")
local Natural = require("solarui/art/natural")
local Svg = require("solarui/art/svg")
local Theme = require("solarui/theme")
local lfs = require("libs/libkoreader-lfs")

local Art = {}

-- The colour roles a drawing may use.
local ROLES = { "ink", "bg", "muted", "line", "soft", "accent", "accent2", "on_accent",
    "leaf", "stem", "gold", "pale", "bloom", "bloom2", "sky", "sage", "glass", "cream" }

local MAX_SPRITES = 64

-- The kinds of buffer KOReader can blend a colour sprite straight into.
local DIRECT = { [Blitbuffer.TYPE_BB8] = true, [Blitbuffer.TYPE_BBRGB16] = true, [Blitbuffer.TYPE_BBRGB32] = true }

local PIECE_BYTES = 48 * 1024 * 1024   -- what the drawings kept for backdrops may take

local pieces = {}    -- key -> { bb, dx, dy, bytes } (drawings composed into backdrops, kept so one change redraws one drawing)
local piece_order = {}   -- their keys, oldest first
local piece_bytes = 0
local sprites = {}   -- key -> buffer (false when the drawing failed)
local order = {}     -- keys, oldest first
local layers = {}    -- slot -> { sig, w, h, type, bb }
local version        -- the theme version everything kept was drawn for
local colours        -- the roles as "#rrggbb" for that version, and the same with living things' real colours
local natural_colours
local svg_file

-- Forget everything when the look changed since it was drawn.
local function sync()
    local v = Theme.get().version
    if v ~= version then
        Art.free()
        version = v
    end
end

-- The theme's colours as the drawings want them.
local function palette(natural)
    if not colours then
        colours, natural_colours = {}, {}
        for _i, role in ipairs(ROLES) do
            colours[role] = Theme.hex(role)
            natural_colours[role] = Theme.hex(role, true)
        end
    end
    return natural and natural_colours or colours
end

-- The file a drawing is written to on its way to the renderer.
local function scratch()
    if not svg_file then
        local dir = DataStorage:getDataDir() .. "/cache"
        if lfs.attributes(dir, "mode") ~= "directory" then lfs.mkdir(dir) end
        svg_file = dir .. "/solarui-art.svg"
    end
    return svg_file
end

-- How far a drawing may reach past its box on every side, in pixels at
-- `zoom` pixels a unit: plants lean out of the box they were composed in.
local function bleed(vw, vh, zoom)
    return math.ceil(math.max(12, math.min(80, math.min(vw, vh) * .4)) * zoom)
end

-- Rasterise drawing `name` for a w x h pixel box from a vw x vh canvas, with
-- room around the box for what reaches past it, trimmed to what was drawn.
-- Gives the picture, where its corner lies from the box's corner, and
-- whether it ran out of even that room; nil when there is no such drawing
-- or it fails.
local function render(name, w, h, vw, vh, param)
    local draw = require("solarui/art/sprites")[name]
    if not draw or w < 1 or h < 1 then return nil end
    local zoom = math.min(w / vw, h / vh)
    local pad = bleed(vw, vh, zoom)
    local ox, oy = pad + (w - vw * zoom) / 2, pad + (h - vh * zoom) / 2
    local W, H = w + 2 * pad, h + 2 * pad
    local f = io.open(scratch(), "w")
    if not f then return nil end
    f:write(Svg.document(W, H, string.format('<g transform="translate(%.2f %.2f) scale(%.4f)">%s</g>', ox, oy, zoom,
        draw(palette(Natural.is(name)), vw, vh, param))))
    f:close()
    local bb = RenderImage:renderSVGImageFile(scratch(), W, H, 1)
    if not bb then return nil end
    local full_w, full_h = bb:getWidth(), bb:getHeight()
    local x, y
    bb, x, y = Alpha.trim(bb)
    local cut = x == 0 or y == 0 or x + bb:getWidth() == full_w or y + bb:getHeight() == full_h
    return bb, x - pad, y - pad, cut
end

-- Blend a 32-bit picture with see-through parts into `bb` with its top-left
-- at (x, y).
function Art.blend(bb, s, x, y)
    local w, h = s:getWidth(), s:getHeight()
    if not DIRECT[bb:getType()] then
        -- blending straight into any other kind of buffer ends KOReader, so go through a copy
        local tmp = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
        tmp:blitFrom(bb, 0, 0, x, y, w, h)
        tmp:alphablitFrom(s, 0, 0, 0, 0, w, h)
        bb:blitFrom(tmp, x, y, 0, 0, w, h)
        tmp:free()
    else
        bb:alphablitFrom(s, x, y, 0, 0, w, h)
    end
end

-- The kept sprite of a drawing (see render), drawn on first use: the
-- picture, where its corner lies from the box's corner, and whether the
-- drawing ran off its canvas.
function Art.sprite(name, w, h, vw, vh, param)
    sync()
    local key = table.concat({ name, w, h, vw, vh, tostring(param) }, "|")
    local s = sprites[key]
    if s == nil then
        local pic, dx, dy, cut = render(name, w, h, vw, vh, param)
        s = pic and { bb = pic, dx = dx, dy = dy, cut = cut } or false
        sprites[key] = s
        order[#order + 1] = key
        if #order > MAX_SPRITES then
            local old = table.remove(order, 1)
            if sprites[old] then sprites[old].bb:free() end
            sprites[old] = nil
        end
    end
    if not s then return nil end
    return s.bb, s.dx, s.dy, s.cut
end

-- Draw a kept sprite for the box with its top-left at (x, y).
function Art.draw(bb, name, x, y, w, h, vw, vh, param)
    local s, dx, dy = Art.sprite(name, w, h, vw, vh, param)
    if s then Art.blend(bb, s, x + dx, y + dy) end
end

-- The drawing of a backdrop item, from the pieces kept or drawn now and kept:
-- the picture and where its corner lies from the box's corner. Where the item
-- sits on the screen is not part of what is kept, so moving it costs nothing.
local function piece(it)
    local key = table.concat({ it[1], it[4], it[5], it[6], it[7], tostring(it[8]) }, "|")
    local p = pieces[key]
    if p == nil then
        local bb, dx, dy = render(it[1], it[4], it[5], it[6], it[7], it[8])
        p = bb and { bb = bb, dx = dx, dy = dy, bytes = bb:getWidth() * bb:getHeight() * 4 } or false
        pieces[key] = p
        piece_order[#piece_order + 1] = key
        piece_bytes = piece_bytes + (p and p.bytes or 0)
        -- the oldest go first, but never the one just drawn
        while piece_bytes > PIECE_BYTES and #piece_order > 1 do
            local old = table.remove(piece_order, 1)
            local o = pieces[old]
            if o then o.bb:free(); piece_bytes = piece_bytes - o.bytes end
            pieces[old] = nil
        end
    end
    return p
end

-- Compose `items` over the page colour (or over a copy of `under`, a canvas
-- already composed) into a new RGB32 canvas w x h.
local function compose(w, h, items, under)
    local th = Theme.get()
    local function rgb(role)
        local p = th.painted[role]
        return Blitbuffer.ColorRGB32(p[1], p[2], p[3], 0xFF)
    end
    local canvas = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
    if under then canvas:blitFrom(under, 0, 0, 0, 0, w, h) else canvas:paintRectRGB32(0, 0, w, h, rgb("bg")) end
    for _i, it in ipairs(items) do
        if it.frame then
            local i, t, c = it.frame, it.t, rgb("ink")
            canvas:paintRectRGB32(i, i, w - 2 * i, t, c)
            canvas:paintRectRGB32(i, h - i - t, w - 2 * i, t, c)
            canvas:paintRectRGB32(i, i, t, h - 2 * i, c)
            canvas:paintRectRGB32(w - i - t, i, t, h - 2 * i, c)
        else
            local p = piece(it)
            if p then canvas:alphablitFrom(p.bb, it[2] + p.dx, it[3] + p.dy, 0, 0, p.bb:getWidth(), p.bb:getHeight()) end
        end
    end
    return canvas
end

-- Paint a backdrop: `items` are { name, x, y, w, h, vw, vh, param } (or
-- { frame = inset, t = thickness } for a ruled border), composed over the
-- page colour the first time and whenever `sig` (a text naming what is on
-- it) changes, then copied in one go. `slot` names the backdrop.
function Art.layer(slot, bb, x, y, w, h, items, sig)
    sync()
    local l = layers[slot]
    if not l or l.sig ~= sig or l.w ~= w or l.h ~= h or l.type ~= bb:getType() then
        if l then l.bb:free() end
        -- the leading items marked `base` (a backdrop that rarely changes: the garden's ground)
        -- are composed once into a layer of their own, which every change starts from
        local base_items, rest = {}, {}
        for _i, it in ipairs(items) do
            if it.base and #rest == 0 then base_items[#base_items + 1] = it else rest[#rest + 1] = it end
        end
        local under
        if #base_items > 0 then
            local keys = {}
            for i, it in ipairs(base_items) do keys[i] = it.key end
            local base_sig = table.concat(keys, ";") .. "@" .. w .. "x" .. h
            local bl = layers[slot .. "|base"]
            if not bl or bl.sig ~= base_sig then
                if bl then bl.bb:free() end
                bl = { sig = base_sig, bb = compose(w, h, base_items) }
                layers[slot .. "|base"] = bl
            end
            under = bl.bb
        end
        local canvas = compose(w, h, rest, under)
        local out = canvas
        if bb:getType() ~= Blitbuffer.TYPE_BBRGB32 then
            out = Blitbuffer.new(w, h, bb:getType())
            out:blitFrom(canvas, 0, 0, 0, 0, w, h)
            canvas:free()
        end
        l = { sig = sig, w = w, h = h, type = bb:getType(), bb = out }
        layers[slot] = l
    end
    bb:blitFrom(l.bb, x, y, 0, 0, w, h)
end

-- Free every sprite and backdrop (the look changed, or SolarUI closed).
function Art.free()
    for _k, s in pairs(sprites) do
        if s then s.bb:free() end
    end
    for _k, l in pairs(layers) do l.bb:free() end
    for _k, p in pairs(pieces) do
        if p then p.bb:free() end
    end
    sprites, order, layers, colours, natural_colours = {}, {}, {}, nil, nil
    pieces, piece_order, piece_bytes = {}, {}, 0
end

return Art
