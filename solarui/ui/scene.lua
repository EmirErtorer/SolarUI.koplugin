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
local Theme = require("solarui/theme")

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
function Scene:frameOrnaments(no_bud)
    local left, right = -self.ox / self.k, (self.width - self.ox) / self.k - 90
    local bottom = self.vh - 90
    self:backdrop("frame_corner", left, 0, 90, 90, 0)
    self:backdrop("frame_corner", right, 0, 90, 90, 1)
    self:backdrop("frame_corner", right, bottom, 90, 90, 2)
    self:backdrop("frame_corner", left, bottom, 90, 90, 3)
    if no_bud then return end
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

-- The signature of the backdrop (what is on it, at this width).
function Scene:signature()
    local keys = {}
    for i, it in ipairs(self.items) do keys[i] = it.key end
    return table.concat(keys, ";") .. "@" .. (self.w or self.width)
end

-- Compose the backdrop now, without painting it (the screen is idle): it is
-- kept, and the first paint is a copy.
function Scene:prepare(btype)
    Art.prepare(self.slot, btype, self.width, self.height, self.items, self:signature(), self.fade)
end

-- Draw the artwork of the elements ahead of time: a list of functions, each
-- drawing and keeping one sprite (see Art.sprite). The scene must be laid out.
function Scene.spriteJobs(root)
    local jobs = {}
    local function walk(c)
        if type(c) ~= "table" then return end
        if c.name and c.w and c.h and c.scale and c.w >= 2 and c.h >= 2 then
            -- (an element may name the other looks it can take: an animal facing either way)
            local params = c.variants and c.variants() or { c.param_fn and c.param_fn() or c.param }
            for _i, param in ipairs(params) do
                jobs[#jobs + 1] = function()
                    local k = c:scale()
                    Art.sprite(c.name, c.w, c.h, math.floor(c.w / k + 0.5), math.floor(c.h / k + 0.5), param)
                end
            end
        end
        if c.art and c.icon_size and c.art[1] then
            -- (a button with a picture in it, drawn at the size Button gives it)
            jobs[#jobs + 1] = function()
                local isz, k = Theme.px(c.icon_size), Theme.px(100) / 178
                Art.sprite(c.art[1], isz, isz, isz / k, isz / k, c.art[2])
            end
        end
        for _i, kid in ipairs(c.children or {}) do walk(kid) end
        walk(c.child)
    end
    walk(root)
    return jobs
end

-- What a scene shows, to tell after a rebuild what changed: its backdrop
-- items and its elements, each by what is drawn and where.
function Scene:snapshot()
    local snap = { x = self.x or 0, y = self.y or 0, items = {}, kids = {} }
    for i, it in ipairs(self.items) do snap.items[i] = { it.key, it[2], it[3], it[4], it[5] } end
    local function sig(c)
        local parts = { c.name or "", tostring(c.param_fn and c.param_fn() or c.param), tostring(c.text), tostring(c.label), tostring(c.value), tostring(c.disabled) }
        if c.art then parts[#parts + 1] = tostring(c.art[1]) .. tostring(c.art[2]) end
        for _i, kid in ipairs(c.children or {}) do parts[#parts + 1] = sig(kid) end
        if type(c.child) == "table" then parts[#parts + 1] = sig(c.child) end
        return table.concat(parts, "\1")
    end
    for i, c in ipairs(self.children) do snap.kids[i] = { sig(c), c.sx or 0, c.sy or 0, c.sw or c.w or 0, c.sh or c.h or 0 } end
    return snap
end

-- The box in screen pixels that changed between two snapshots of a scene of
-- the same make (x, y, w, h), grown by `margin`; nil when the two are not
-- alike enough to say (then the whole screen is the safe answer), false
-- when nothing changed.
function Scene.changed(old, new, margin)
    if #old.items ~= #new.items or #old.kids ~= #new.kids then return nil end
    local x0, y0, x1, y1
    local function add(x, y, w, h)
        x0, y0 = math.min(x0 or x, x), math.min(y0 or y, y)
        x1, y1 = math.max(x1 or x + w, x + w), math.max(y1 or y + h, y + h)
    end
    for i, a in ipairs(old.items) do
        local b = new.items[i]
        if a[1] ~= b[1] then add(a[2], a[3], a[4], a[5]); add(b[2], b[3], b[4], b[5]) end
    end
    for i, a in ipairs(old.kids) do
        local b = new.kids[i]
        if a[1] ~= b[1] or a[2] ~= b[2] or a[3] ~= b[3] or a[4] ~= b[4] or a[5] ~= b[5] then
            add(a[2], a[3], a[4], a[5]); add(b[2], b[3], b[4], b[5])
        end
    end
    if not x0 then return false end
    return { x = old.x + x0 - margin, y = old.y + y0 - margin, w = x1 - x0 + 2 * margin, h = y1 - y0 + 2 * margin }
end

-- Paint the backdrop, then the elements.
function Scene:paint(bb, x, y)
    self.x, self.y = x, y
    Art.layer(self.slot, bb, x, y, self.w, self.h, self.items, self:signature(), self.fade)
    for _i, c in ipairs(self.children) do c:paint(bb, x + c.sx, y + c.sy) end
end

return Scene
