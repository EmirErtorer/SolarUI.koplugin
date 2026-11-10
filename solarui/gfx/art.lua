-- The artwork: plants drawn as SVG in the theme's colours at exactly the size
-- asked for, rasterised once and kept. A drawing is a function in
-- solarui/art/sprites.lua. Small ones that change (a flower that fills) are
-- kept as sprites and blended in on every paint; a whole backdrop of them is
-- composed once into a layer the size of the screen and then just copied.

local Blitbuffer = require("ffi/blitbuffer")
local DataStorage = require("datastorage")
local RenderImage = require("ui/renderimage")
local Svg = require("solarui/art/svg")
local Theme = require("solarui/theme")
local lfs = require("libs/libkoreader-lfs")

local Art = {}

-- The colour roles a drawing may use.
local ROLES = { "ink", "bg", "muted", "line", "soft", "accent", "accent2", "on_accent",
    "leaf", "stem", "gold", "pale", "bloom", "bloom2", "sky", "sage", "glass", "cream" }

local MAX_SPRITES = 48

local sprites = {}   -- key -> buffer (false when the drawing failed)
local order = {}     -- keys, oldest first
local layers = {}    -- slot -> { sig, w, h, type, bb }
local version        -- the theme version everything kept was drawn for
local colours        -- the roles as "#rrggbb" for that version
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
local function palette()
    if not colours then
        colours = {}
        for _i, role in ipairs(ROLES) do colours[role] = Theme.hex(role) end
    end
    return colours
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

-- Rasterise drawing `name` at w x h pixels from a vw x vh canvas; nil when
-- there is no such drawing or it fails.
local function render(name, w, h, vw, vh, param)
    local draw = require("solarui/art/sprites")[name]
    if not draw or w < 1 or h < 1 then return nil end
    local f = io.open(scratch(), "w")
    if not f then return nil end
    f:write(Svg.document(vw, vh, draw(palette(), vw, vh, param)))
    f:close()
    return RenderImage:renderSVGImageFile(scratch(), w, h) or nil
end

-- Blend a sprite into `bb` with its top-left at (x, y).
local function blend(bb, s, x, y)
    local w, h = s:getWidth(), s:getHeight()
    if bb:getType() == Blitbuffer.TYPE_BBRGB24 then
        -- blending straight into a 24-bit buffer ends KOReader, so go through a copy
        local tmp = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
        tmp:blitFrom(bb, 0, 0, x, y, w, h)
        tmp:alphablitFrom(s, 0, 0, 0, 0, w, h)
        bb:blitFrom(tmp, x, y, 0, 0, w, h)
        tmp:free()
    else
        bb:alphablitFrom(s, x, y, 0, 0, w, h)
    end
end

-- The kept sprite of a drawing (see render), drawn on first use.
function Art.sprite(name, w, h, vw, vh, param)
    sync()
    local key = table.concat({ name, w, h, vw, vh, tostring(param) }, "|")
    local s = sprites[key]
    if s == nil then
        s = render(name, w, h, vw, vh, param) or false
        sprites[key] = s
        order[#order + 1] = key
        if #order > MAX_SPRITES then
            local old = table.remove(order, 1)
            if sprites[old] then sprites[old]:free() end
            sprites[old] = nil
        end
    end
    return s or nil
end

-- Draw a kept sprite with its top-left at (x, y).
function Art.draw(bb, name, x, y, w, h, vw, vh, param)
    local s = Art.sprite(name, w, h, vw, vh, param)
    if s then blend(bb, s, x, y) end
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
        local th = Theme.get()
        local function rgb(role)
            local p = th.painted[role]
            return Blitbuffer.ColorRGB32(p[1], p[2], p[3], 0xFF)
        end
        local canvas = Blitbuffer.new(w, h, Blitbuffer.TYPE_BBRGB32)
        canvas:paintRectRGB32(0, 0, w, h, rgb("bg"))
        for _i, it in ipairs(items) do
            if it.frame then
                local i, t, c = it.frame, it.t, rgb("ink")
                canvas:paintRectRGB32(i, i, w - 2 * i, t, c)
                canvas:paintRectRGB32(i, h - i - t, w - 2 * i, t, c)
                canvas:paintRectRGB32(i, i, t, h - 2 * i, c)
                canvas:paintRectRGB32(w - i - t, i, t, h - 2 * i, c)
            else
                local s = render(it[1], it[4], it[5], it[6], it[7], it[8])
                if s then
                    canvas:alphablitFrom(s, it[2], it[3], 0, 0, s:getWidth(), s:getHeight())
                    s:free()
                end
            end
        end
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
        if s then s:free() end
    end
    for _k, l in pairs(layers) do l.bb:free() end
    sprites, order, layers, colours = {}, {}, {}, nil
end

return Art
