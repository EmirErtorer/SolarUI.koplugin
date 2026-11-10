-- A book's cover tile in the reader's cover style: the cover image, or a
-- typeset card with the title, author and a pattern, which is also what a
-- book without a cover gets. Can carry a small badge (New, 64%, Done). A
-- folder shows its first book's cover stacked on two sheets with a strip
-- along the bottom; an empty one a card with a folder icon. Every tile is
-- cut to an arched window with a fine border (art/frames.lua), painted once
-- and kept (gfx/cutout.lua).

local Art = require("solarui/gfx/art")
local Blitbuffer = require("ffi/blitbuffer")
local Cutout = require("solarui/gfx/cutout")
local Element = require("solarui/ui/element")
local Books = require("solarui/data/books")
local Covers = require("solarui/data/covers")
local Frames = require("solarui/art/frames")
local Icons = require("solarui/gfx/icons")
local Paint = require("solarui/gfx/paint")
local Settings = require("solarui/settings")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local Cover = Element:extend({})

-- Blit a picture inverted. The C blitter ends KOReader outright when the
-- picture and the screen differ in pixel type (a colour cover on a colour
-- screen), so such a picture is first copied into the screen's type.
local function invertBlit(bb, img, x, y, w, h)
    if img:getType() == bb:getType() then
        bb:invertblitFrom(img, x, y, 0, 0, w, h)
        return
    end
    local same = Blitbuffer.new(w, h, bb:getType())
    same:blitFrom(img, 0, 0, 0, 0, w, h)
    bb:invertblitFrom(same, x, y, 0, 0, w, h)
    same:free()
end

-- The patterns a data card can wear, picked from the title so a book keeps its look.
local PATTERNS = { "h", "v", "grid", "solid", "plain" }

-- A stable small number from a string.
local function hash(s)
    local h = 0
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 1000003 end
    return h
end

-- Draw the card's background pattern inside the frame.
local function pattern(bb, x, y, w, h, name, th)
    local period, thick = Theme.px(7), Theme.px(2)
    if name == "h" then Paint.stripes(bb, x, y, w, h, "h", period, thick, th.c.line)
    elseif name == "v" then Paint.stripes(bb, x, y, w, h, "v", period, thick, th.c.line)
    elseif name == "grid" then
        Paint.stripes(bb, x, y, w, h, "h", period * 2, thick, th.c.line)
        Paint.stripes(bb, x, y, w, h, "v", period * 2, thick, th.c.line)
    elseif name == "solid" then Paint.fill(bb, x, y, w, h, th.c.soft) end
end

-- The narrowest a cover may be in the library grid, per size setting (base
-- pixels): the grid fits as many as the screen allows, in any orientation.
Cover.SIZES = { s = 90, m = 120, l = 170, xl = 240 }

-- The recent list on home, per size setting (base pixels): row height, cover
-- width and cover height.
Cover.RECENT_SIZES = {
    s = { row = 54, w = 30, h = 44 },
    m = { row = 74, w = 45, h = 66 },
    l = { row = 96, w = 60, h = 88 },
    xl = { row = 126, w = 80, h = 118 },
}

-- The recent list size setting, "s" when unset or unknown.
function Cover.recentSizeKey()
    local k = Settings.get("recent_cover_size", "s")
    return Cover.RECENT_SIZES[k] and k or "s"
end

-- Row height, cover width and cover height for the recent list on home.
function Cover.recentSize()
    local s = Cover.RECENT_SIZES[Cover.recentSizeKey()]
    return Theme.px(s.row), Theme.px(s.w), Theme.px(s.h)
end

-- The cover style: "image" (the default) or "card" (typeset, no pictures).
function Cover.style()
    return Settings.get("cover_style") == "card" and "card" or "image"
end

-- The art a typeset card wears behind its title: "glass", "garden", "halo",
-- "scales" (art/coverart.lua) or "lines", the plain stripes.
Cover.ART = { "glass", "garden", "halo", "scales", "lines" }
function Cover.cardArt()
    local a = Settings.get("card_art", "glass")
    for _i, id in ipairs(Cover.ART) do
        if id == a then return a end
    end
    return "glass"
end

-- Everything the tile's picture depends on, as one text.
function Cover:key()
    local has = self.path and Cover.style() ~= "card" and Covers.get(self.path, self:imageSize()) and 1 or 0
    return table.concat({ self.path or "", self.title or "", self.author or "", self.w, self.h, Cover.style(), Cover.cardArt(), tostring(self.badge),
        tostring(self.badge_on), tostring(self.folder), tostring(self.stack), tostring(self.count), has, Covers.generation(),
        tostring(Covers.stretch()) }, "|")
end

-- The room a cover image has inside the tile's border.
function Cover:imageSize()
    local stroke = Theme.get().size.stroke
    return self.w - 2 * stroke, self.h - 2 * stroke
end

-- Draw the tile from its kept picture.
function Cover:draw(bb, x, y)
    if self.w < 4 or self.h < 4 then return end
    Art.blend(bb, Cutout.get(self:key(), self.w, self.h, "cover_shape", function(buf) return self:compose(buf) end), x, y)
end

-- Draw the border over a face w x h at (x, y).
local function border(bb, name, x, y, w, h)
    local k = Cutout.unit()
    Art.draw(bb, name, x, y, w, h, w / k, h / k)
end

-- Paint the whole tile into its own buffer and say where it shows. A folder
-- (stack = true) is its first book's cover with two sheets peeking out
-- behind it and a strip along the bottom.
function Cover:compose(buf)
    local th = Theme.get()
    local w, h = self.w, self.h
    if not self.stack then
        self:drawFace(buf, 0, 0)
        return { { 0, 0, w, h } }
    end
    local off = math.max(Theme.px(4), math.floor(w / 24))
    local fw, fh = w - 2 * off, h - 2 * off
    Paint.fill(buf, 0, 0, w, h, th.c.bg)
    -- the sheets behind, offset up and to the right
    border(buf, "cover_sheet", 2 * off, 0, fw, fh)
    border(buf, "cover_sheet", off, off, fw, fh)
    -- the front cover
    self.w, self.h = fw, fh
    self:drawFace(buf, 0, 2 * off)
    self:drawFolderStrip(buf, 0, 2 * off, th)
    self.w, self.h = w, h
    return { { 2 * off, 0, fw, fh }, { off, off, fw, fh }, { 0, 2 * off, fw, fh } }
end

-- The strip along a folder's bottom edge: a folder icon and how many it holds.
function Cover:drawFolderStrip(bb, x, y, th)
    local kind = self.w < Theme.px(90) and "micro" or "label"
    local sh = Text.height(kind) + Theme.px(6)
    local sy = y + self.h - sh
    Paint.fill(bb, x, sy, self.w, sh, th.c.ink)
    local isz = sh - Theme.px(6)
    Icons.draw(bb, "folder", x + Theme.px(4), sy + Theme.px(3), isz, th.c.on_ink, th.c.on_ink)
    local text = self.count and tostring(self.count) or _("Folder")
    Text.draw(bb, x + Theme.px(8) + isz, sy + Theme.px(3), kind, Text.fit(kind, text, self.w - isz - Theme.px(12)), th.c.on_ink)
end

-- Draw a cover face: image or data card (an empty slot is just its border),
-- then badge and folder icon, then the window's border over all of it.
function Cover:drawFace(bb, x, y)
    local th = Theme.get()
    local w, h = self.w, self.h
    Paint.fill(bb, x, y, w, h, th.c.bg)
    local drawn = false
    local style = Cover.style()
    if self.path and style ~= "card" then
        local img = Covers.get(self.path, self:imageSize())
        if img then
            local iw, ih = img:getWidth(), img:getHeight()
            local ix, iy = x + math.floor((w - iw) / 2), y + math.floor((h - ih) / 2)
            -- night mode inverts the whole screen, so a picture goes in inverted to come out as it is
            if Theme.nightMode() then invertBlit(bb, img, ix, iy, iw, ih)
            else bb:blitFrom(img, ix, iy, 0, 0, iw, ih) end
            drawn = true
        end
    end
    if not drawn and (self.path or self.title) then self:drawCard(bb, x, y, th) end
    if self.folder and not self.path then self:drawFolderTab(bb, x, y, th) end
    if self.badge then self:drawBadge(bb, x, y, th) end
    border(bb, "cover_border", x, y, w, h)
end

-- The typeset card: pattern, then a box with title and author at the bottom.
function Cover:drawCard(bb, x, y, th)
    local w, h = self.w, self.h
    local info = self.path and Books.info(self.path)
    local title = self.title or (info and info.title) or ""
    local author = self.author or (info and info.author)
    local art = Cover.cardArt()
    if art == "lines" then
        pattern(bb, x, y, w, h, PATTERNS[hash(title) % #PATTERNS + 1], th)
    else
        local k = Cutout.unit()
        Art.draw(bb, "cover_" .. art, x, y, w, h, w / k, h / k, hash(title) % 12)
    end
    if h < Theme.px(60) then return end
    local pad = math.max(Theme.px(4), math.floor(w / 16))
    local inner = w - 4 * pad
    local kind = w < Theme.px(90) and "micro" or "label"
    local lines = Text.wrap(kind, title, inner, h < Theme.px(130) and 2 or 3)
    local lh = Text.height(kind)
    local box_h = #lines * lh + 2 * pad
    local alh = Text.height("micro")
    if author and w >= Theme.px(70) then box_h = box_h + alh end
    local bx, by = x + pad, y + h - pad - box_h
    Paint.fill(bb, bx, by, w - 2 * pad, box_h, th.c.bg)
    for i, line in ipairs(lines) do
        Text.draw(bb, bx + pad, by + pad + (i - 1) * lh, kind, Text.fit(kind, line, inner), th.c.ink)
    end
    if author and w >= Theme.px(70) then
        Text.draw(bb, bx + pad, by + pad + #lines * lh, "micro", Text.fit("micro", author, inner), th.c.muted)
    end
end

-- A small label on the right edge, just under the arch.
function Cover:drawBadge(bb, x, y, th)
    local s = Text.fit("micro", self.badge)
    local pad = Theme.px(4)
    local bw = Text.width("micro", s) + 2 * pad
    local bh = Text.height("micro") + Theme.px(2)
    local fill = self.badge_on and th.c.accent or th.c.ink
    local fg = self.badge_on and th.c.on_accent or th.c.on_ink
    local by = y + math.floor(Frames.rise(self.w, self.h))
    Paint.round(bb, x + self.w - bw - pad, by, bw + pad, bh, math.floor(bh / 2), "tl", fill)
    Text.draw(bb, x + self.w - bw, by + Theme.px(1), "micro", s, fg)
end

-- An empty folder's card: a large folder icon in the middle.
function Cover:drawFolderTab(bb, x, y, th)
    local size = math.floor(math.min(self.w, self.h) * 0.42)
    local ix, iy = x + math.floor((self.w - size) / 2), y + math.floor((self.h - size) / 2) - Theme.px(8)
    Paint.fill(bb, ix - Theme.px(4), iy - Theme.px(4), size + Theme.px(8), size + Theme.px(8), th.c.bg)
    Icons.draw(bb, "folder", ix, iy, size, th.c.ink, th.c.accent)
end

return Cover
