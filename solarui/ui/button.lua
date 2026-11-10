-- The one button of the style. A variant picks its colours and shape. The
-- large ones are leaves, with two opposite corners rounded: primary and
-- accent2 (filled, with a fine inner line), secondary, soft, danger. The
-- small ones are round like buds: ghost, chip, chip_on, icon, icon_on, seg_on.
-- tab, seg and plain have no shape of their own; tab_on is a soft leaf with
-- a mark under its label. Content is an optional icon, a label and an
-- optional small line under it.

local Element = require("solarui/ui/element")
local Art = require("solarui/gfx/art")
local Icons = require("solarui/gfx/icons")
local Paint = require("solarui/gfx/paint")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")

local Button = Element:extend({ variant = "secondary", align = "center", icon_size = 20 })

-- Fill, outline, text colour, corner radius ("round" is half the height)
-- and which corners are rounded for each variant (two opposite corners make
-- a leaf). `inner` rules a fine line inside the edge, `mark` a short bar
-- under the content.
local VARIANTS = {
    primary   = { fill = "accent", text = "on_accent", cut = "cut", corners = "tb", inner = true },
    accent2   = { fill = "accent2", text = "on_accent2", cut = "cut", corners = "tb", inner = true },
    secondary = { line = "ink", text = "ink", cut = "cut", corners = "tb" },
    soft      = { fill = "soft", text = "ink", cut = "cut_small", corners = "tb" },
    ghost     = { line = "line", text = "ink", cut = "round" },
    chip      = { line = "ink", text = "ink", cut = "round" },
    chip_on   = { fill = "accent", text = "on_accent", cut = "round" },
    tab       = { text = "ink" },
    tab_on    = { fill = "soft", text = "ink", cut = "cut", corners = "tb", mark = "accent" },
    icon      = { line = "ink", text = "ink", cut = "round" },
    icon_on   = { fill = "ink", text = "on_ink", cut = "round" },
    plain     = { text = "ink" },
    seg       = { text = "ink" },
    seg_on    = { fill = "accent", text = "on_accent", cut = "round" },
    danger    = { line = "accent2", text = "accent2", cut = "cut_small", corners = "tb" },
}
Button.VARIANTS = VARIANTS

-- Each variant's look when it is disabled: its own shape, emptied and greyed.
local DISABLED = {}
for name, v in pairs(VARIANTS) do
    DISABLED[name] = { line = (v.fill or v.line) and "line" or nil, text = "muted", cut = v.cut, corners = v.corners }
end

-- The variant's colour roles and shape.
function Button:look()
    local set = self.disabled and DISABLED or VARIANTS
    return set[self.variant] or set.secondary
end

-- Is this one of the bare icon variants (no padding round the icon)?
function Button:bare()
    local v = self.variant
    return v:sub(1, 4) == "icon" or v == "plain"
end

-- Text kinds used for the label and the small line.
function Button:kinds()
    return self.kind or "label", self.sub_kind or "micro"
end

-- Width of the content plus padding.
function Button:naturalWidth()
    if self.width then return self.width end
    local th = Theme.get()
    local kind, sub_kind = self:kinds()
    local w = 0
    if self.label then w = Text.width(kind, self.label) end
    if self.sub then w = math.max(w, Text.width(sub_kind, self.sub)) end
    if self.icon or self.art then
        w = w + Theme.px(self.icon_size) + (self.label and th.space.s or 0)
    end
    local pad = self:bare() and 0 or 2 * th.space.l
    return math.max(w + pad, th.size.touch)
end

-- Buttons are at least one touch target tall.
function Button:naturalHeight()
    return self.height or Theme.get().size.touch
end

-- Draw the shape, then the icon and text.
function Button:draw(bb, x, y)
    local th = Theme.get()
    local look = self:look()
    local fill = look.fill and Theme.color(look.fill)
    local line = look.line and Theme.color(look.line)
    local r = look.cut == "round" and math.floor(self.h / 2) or (look.cut and th.size[look.cut] or 0)
    local spec = self.corners or look.corners
    Paint.roundBox(bb, x, y, self.w, self.h, r, spec, th.size.stroke, fill, line)
    local text = Theme.color(look.text)
    local gap = Theme.px(3)
    if look.inner and self.h >= 12 * gap and self.w >= 20 * gap then
        Paint.roundFrame(bb, x + gap, y + gap, self.w - 2 * gap, self.h - 2 * gap, r - gap, spec, th.size.hair, text)
    end
    if look.mark then
        local mw = math.floor(self.w * .36)
        Paint.round(bb, x + math.floor((self.w - mw) / 2), y + self.h - 2 * gap, mw, gap, gap, "trbl", Theme.color(look.mark))
    end
    -- an icon's accent lights only stand out on an unfilled button
    self:drawContent(bb, x, y, text, not fill and Theme.color("accent") or nil)
end

-- Lay out icon, label and small line inside the button (the small line only
-- when there is room for both).
function Button:drawContent(bb, x, y, color, accent)
    local th = Theme.get()
    local kind, sub_kind = self:kinds()
    local pad = self:bare() and 0 or th.space.m
    local isz = (self.icon or self.art) and Theme.px(self.icon_size) or 0
    local igap = ((self.icon or self.art) and self.label) and th.space.s or 0
    local text_w = self.w - 2 * pad - isz - igap
    local label = self.label and Text.fit(kind, self.label, text_w)
    -- a button too short for both lines keeps its label alone
    local two_lines = self.label and self.sub and Text.height(kind) + Text.height(sub_kind) <= self.h
    local sub = self.sub and (two_lines or not self.label) and Text.fit(sub_kind, self.sub, text_w)
    local lw = label and Text.width(kind, label) or 0
    local sw = sub and Text.width(sub_kind, sub) or 0
    local content_w = isz + igap + math.max(lw, sw)
    local cx = x + pad
    if self.align == "center" then cx = x + math.floor((self.w - content_w) / 2) end
    if self.icon then
        Icons.draw(bb, self.icon, cx, y + math.floor((self.h - isz) / 2), isz, color, accent)
        cx = cx + isz + igap
    elseif self.art then
        local k = Theme.px(100) / 178
        Art.draw(bb, self.art[1], cx, y + math.floor((self.h - isz) / 2), isz, isz, isz / k, isz / k, self.art[2])
        cx = cx + isz + igap
    end
    local lh = label and Text.height(kind) or 0
    local sh = sub and Text.height(sub_kind) or 0
    local ty = y + math.floor((self.h - lh - sh) / 2)
    if label then
        local lx = cx
        if self.align == "center" and lw < sw then lx = cx + math.floor((sw - lw) / 2) end
        Text.draw(bb, lx, ty, kind, label, color)
    end
    if sub then
        local sx = cx
        if self.align == "center" and sw < lw then sx = cx + math.floor((lw - sw) / 2) end
        Text.draw(bb, sx, ty + lh, sub_kind, sub, color)
    end
end

return Button
