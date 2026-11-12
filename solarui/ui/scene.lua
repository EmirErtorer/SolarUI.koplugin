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
local SceneEdit = require("solarui/ui/sceneedit")

-- Named groups of parts (see Scene:group) can be moved and stretched by
-- tweaks kept in data/layout_overrides.lua.
local Scene = Element:extend({ design_w = 1072 })

local floor = math.floor

-- A scene for a w x h screen that needs at least `min_vh` units of height.
-- `slot` names its backdrop.
function Scene.make(slot, w, h, min_vh)
    local s = Scene:new({ slot = slot, children = {}, items = {}, sig = {}, groups = {} })
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
    local it = { name, 0, 0, 0, 0, vw, vh, param }
    self.items[#self.items + 1] = it
    self.sig[#self.sig + 1] = ""
    local m = { item = it, sigi = #self.sig, unit = { vx, vy, vw, vh } }
    self:refit(m, vx, vy, vw, vh)
    if self.cur then self.cur.members[#self.cur.members + 1] = m end
end

-- Give a part of the scene a new box in units.
function Scene:refit(m, vx, vy, vw, vh)
    if m.item then
        local it = m.item
        it[2], it[3], it[4], it[5], it[6], it[7] = self.ox + self:px(vx), self:px(vy), self:px(vw), self:px(vh), vw, vh
        self.sig[m.sigi] = table.concat({ it[1], vx, vy, vw, vh, tostring(it[8]) }, ",")
    else
        local el = m.el
        el.sx, el.sy = self.ox + self:px(vx), self:px(vy)
        el.sw, el.sh = vw and self:px(vw) or nil, vh and self:px(vh) or nil
    end
end

-- The box of a part in pixels, as laid out: x, y, w, h.
function Scene:pixelBox(m)
    if m.item then return m.item[2], m.item[3], m.item[4], m.item[5] end
    local el = m.el
    return el.sx, el.sy, el.w or el.sw or 0, el.h or el.sh or 0
end

-- Run `add`, which adds parts to the scene, as one named part of the page
-- (`id` like "home.cover") that the layout editor can move and stretch; its
-- saved tweak is applied, or it is left out when hidden.
function Scene:group(id, label, add)
    local g = { id = id, label = label, members = {} }
    local n_items, n_children, n_sig = #self.items, #self.children, #self.sig
    self.cur = g
    add()
    self.cur = nil
    local o = SceneEdit.lookup(self.slot, id)
    if o and o.hidden then
        for i = #self.items, n_items + 1, -1 do self.items[i] = nil end
        for i = #self.children, n_children + 1, -1 do self.children[i] = nil end
        for i = #self.sig, n_sig + 1, -1 do self.sig[i] = nil end
        g.hidden = true
    else
        SceneEdit.apply(self, g, o)
    end
    self.groups[#self.groups + 1] = g
end

-- Rule a border `inset` units in from the screen's edge, `t` units thick.
function Scene:border(inset, t)
    self.items[#self.items + 1] = { frame = self:px(inset), t = math.max(1, self:px(t)) }
    self.sig[#self.sig + 1] = "frame" .. inset
end

-- Ornaments for the corners of a ruled border and the middle of its foot.
function Scene:frameOrnaments()
    local left, right = -self.ox / self.k, (self.width - self.ox) / self.k - 90
    local bottom = self.vh - 90
    self:backdrop("frame_corner", left, 0, 90, 90, 0)
    self:backdrop("frame_corner", right, 0, 90, 90, 1)
    self:backdrop("frame_corner", right, bottom, 90, 90, 2)
    self:backdrop("frame_corner", left, bottom, 90, 90, 3)
    self:backdrop("frame_bud", (self.width / 2 - self.ox) / self.k - 30, self.vh - 52, 60, 30)
end

-- Place an element at a box in units (a nil height lets it take its own).
function Scene:place(el, vx, vy, vw, vh)
    local m = { el = el, unit = { vx, vy, vw, vh } }
    self:refit(m, vx, vy, vw, vh)
    self.children[#self.children + 1] = el
    if self.cur then self.cur.members[#self.cur.members + 1] = m end
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
