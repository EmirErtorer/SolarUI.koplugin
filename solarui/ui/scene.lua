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
-- `slot` names its backdrop; `screen`, when set, is the name its parts are
-- tweaked under (data/layout_overrides.lua), else the slot.
function Scene.make(slot, w, h, min_vh)
    local s = Scene:new({ slot = slot, children = {}, items = {}, groups = {} })
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
    local it = { name, 0, 0, 0, 0, vw, vh, param, base = self.in_base }
    self.items[#self.items + 1] = it
    local m = { item = it, unit = { vx, vy, vw, vh }, art = { vw, vh }, fixed = self.fixed }
    self:refit(m, vx, vy, vw, vh)
    if self.cur then self.cur.members[#self.cur.members + 1] = m end
end

-- Give a part of the scene a new box in units.
function Scene:refit(m, vx, vy, vw, vh)
    if m.item then
        local it = m.item
        -- the drawing keeps the space it was made for; only its box on the screen changes
        it[2], it[3], it[4], it[5], it[6], it[7] = self.ox + self:px(vx), self:px(vy), self:px(vw), self:px(vh), m.art[1], m.art[2]
        it.key = table.concat({ it[1], vx, vy, vw, vh, tostring(it[8]) }, ",")
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
-- Run `add`, which adds backdrop artwork that rarely changes (the garden's
-- ground, first of all): it is composed into a layer of its own once, and
-- every change to the rest of the backdrop starts from that.
function Scene:base(add)
    self.in_base = true
    add()
    self.in_base = nil
end

-- Add parts that a spread leaves where they were put (they are drawn for it already).
function Scene:placed(add)
    local was = self.fixed
    self.fixed = "placed"
    add()
    self.fixed = was
end

-- A part that keeps its size when its group is spread wider (see `span`).
function Scene:keepSize(add)
    local was = self.fixed
    self.fixed = true
    add()
    self.fixed = was
end

-- Spread a group sideways so the stretch of the poster from x0 to x1 fills
-- the screen between the borders, `inset` units in from each edge: parts
-- that keep their size stand further apart, the rest are stretched. Sets
-- scene.spread_by to the factor.
function Scene:spread(g, span)
    local left, right = -self.ox / self.k, (self.width - self.ox) / self.k
    local from = left + span.inset
    local f = ((right - span.inset) - from) / (span.x1 - span.x0)
    self.spread_by = f
    local function at(x) return from + (x - span.x0) * f end
    for _i, m in ipairs(g.members) do
        local u = m.unit
        if m.fixed == "placed" then goto next end
        if m.fixed then m.unit = { at(u[1] + u[3] / 2) - u[3] / 2, u[2], u[3], u[4] }
        else m.unit = { at(u[1]), u[2], u[3] * f, u[4] } end
        self:refit(m, m.unit[1], m.unit[2], m.unit[3], m.unit[4])
        ::next::
    end
end

-- Options: `uniform` keeps the part's shape when stretched; `clip` leaves out
-- the elements a tweak pushes past the top or bottom of the scene; `span`
-- ({ x0, x1, inset }, see Scene:spread) fills the screen's width.
function Scene:group(id, label, add, opts)
    opts = opts or {}
    local g = { id = id, label = label, members = {}, uniform = opts.uniform }
    self.cur = g
    add()
    self.cur = nil
    if opts.span then self:spread(g, opts.span) end
    local o = SceneEdit.lookup(self.screen or self.slot, id)
    if o and o.hidden then
        local gone = {}
        for _i, m in ipairs(g.members) do gone[m.item or m.el] = true end
        local function keep(list)
            local n = 0
            for _i, v in ipairs(list) do
                if not gone[v] then n = n + 1; list[n] = v end
            end
            for i = #list, n + 1, -1 do list[i] = nil end
        end
        keep(self.items)
        keep(self.children)
        g.hidden = true
    else
        SceneEdit.apply(self, g, o)
        if opts.clip and o then self:clipGroup(g) end
    end
    self.groups[#self.groups + 1] = g
end

-- Drop the elements of a group that now reach past the top or bottom of the scene.
function Scene:clipGroup(g)
    local out = {}
    for _i, m in ipairs(g.members) do
        local el = m.el
        if el and el.sh and (el.sy < 0 or el.sy + el.sh > self.height) then out[el] = true end
    end
    local n = 0
    for _i, c in ipairs(self.children) do
        if not out[c] then n = n + 1; self.children[n] = c end
    end
    for i = #self.children, n + 1, -1 do self.children[i] = nil end
end

-- Run `add` with whatever it puts on the scene left out of the current group.
function Scene:apart(add)
    local g = self.cur
    self.cur = nil
    add()
    self.cur = g
end

-- Rule a border `inset` units in from the screen's edge, `t` units thick.
function Scene:border(inset, t)
    self.items[#self.items + 1] = { frame = self:px(inset), t = math.max(1, self:px(t)), key = "frame" .. inset }
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
    local m = { el = el, unit = { vx, vy, vw, vh }, fixed = self.fixed }
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
    local keys = {}
    for i, it in ipairs(self.items) do keys[i] = it.key end
    Art.layer(self.slot, bb, x, y, self.w, self.h, self.items, table.concat(keys, ";") .. "@" .. self.w)
    for _i, c in ipairs(self.children) do c:paint(bb, x + c.sx, y + c.sy) end
end

return Scene
