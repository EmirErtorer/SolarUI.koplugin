-- A page composed like a poster: everything sits at a place on a design
-- canvas 1072 units wide, which is scaled to the screen's width (or to its
-- height on a wide, short screen, and centred). Artwork that never changes
-- goes into a backdrop painted once and kept; the rest are elements placed
-- on top, in the order they were added.

local Art = require("solarui/gfx/art")
local ArtView = require("solarui/ui/artview")
local Element = require("solarui/ui/element")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")

local Scene = Element:extend({ design_w = 1072 })

local floor = math.floor

-- A scene for a w x h screen that needs at least `min_vh` units of height.
-- `slot` names its backdrop.
function Scene.make(slot, w, h, min_vh)
    local s = Scene:new({ slot = slot, children = {}, items = {}, sig = {} })
    s.k = math.min(w / s.design_w, h / min_vh)
    s.ox = floor((w - s.design_w * s.k) / 2)
    s.vh = h / s.k
    s.width, s.height = w, h
    return s
end

-- Units to pixels.
function Scene:px(v)
    return floor(v * self.k + 0.5)
end

-- Add artwork to the backdrop at a box in units.
function Scene:backdrop(name, vx, vy, vw, vh, param)
    self.items[#self.items + 1] = { name, self.ox + self:px(vx), self:px(vy), self:px(vw), self:px(vh), vw, vh, param }
    self.sig[#self.sig + 1] = table.concat({ name, vx, vy, vw, vh, tostring(param) }, ",")
end

-- Rule a border `inset` units in from the screen's edge, `t` units thick.
function Scene:border(inset, t)
    self.items[#self.items + 1] = { frame = self:px(inset), t = math.max(1, self:px(t)) }
    self.sig[#self.sig + 1] = "frame" .. inset
end

-- Place an element at a box in units (a nil height lets it take its own).
function Scene:place(el, vx, vy, vw, vh)
    el.sx, el.sy = self.ox + self:px(vx), self:px(vy)
    el.sw, el.sh = vw and self:px(vw) or nil, vh and self:px(vh) or nil
    self.children[#self.children + 1] = el
    return el
end

-- Place artwork that is blended in on every paint (it changes, or lies over
-- other elements).
function Scene:sprite(name, vx, vy, vw, vh, param, param_fn)
    return self:place(ArtView:new({ name = name, param = param, param_fn = param_fn, unit = self.k }), vx, vy, vw, vh)
end

-- A line of text centred in a column `vw` units wide.
function Scene:caption(text, vx, vy, vw, kind, color)
    return self:place(Label:new({ text = text, kind = kind or "label", color = color, align = "center" }), vx, vy, vw)
end

-- A heading with a whiplash rule running off to the right edge of the columns.
function Scene:heading(text, vy)
    local x0, x1 = self.head_x or 158, self.head_end or 1006
    return self:place(Layout.Row:new({ gap = self:px(16), children = {
        Label:new({ text = text, kind = "title" }),
        ArtView:new({ name = "whiplash", unit = self.k, grow = true, height = self:px(24) }),
    } }), x0, vy, x1 - x0, 46)
end

-- Make a box in units answer a tap and a hold.
function Scene:touch(vx, vy, vw, vh, on_tap, on_hold)
    return self:place(Element:new({ on_tap = on_tap, on_hold = on_hold }), vx, vy, vw, vh)
end

-- Give every element its box.
function Scene:layout(w, h)
    self.w, self.h = self.width or w, self.height or h
    for _i, c in ipairs(self.children) do c:layout(c.sw, c.sh) end
end

-- Paint the backdrop, then the elements.
function Scene:paint(bb, x, y)
    self.x, self.y = x, y
    Art.layer(self.slot, bb, x, y, self.w, self.h, self.items, table.concat(self.sig, ";") .. "@" .. self.w)
    for _i, c in ipairs(self.children) do c:paint(bb, x + c.sx, y + c.sy) end
end

return Scene
