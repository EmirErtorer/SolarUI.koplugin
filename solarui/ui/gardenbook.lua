-- The open book on the garden's table, opened large over the faded garden:
-- a passage from the reader's own highlights (or a line for the season) on
-- the right page with where it stands in this visit's run at its foot; on
-- the left page the book's name and author above the vine, and below it the
-- chapter, the page, the day it was highlighted and the reader's note.
-- Tapping the right page turns to the next passage and the left page back
-- to the one before; the buttons do the same, open the book at the passage
-- ("Read on") and close the book.

local Button = require("solarui/ui/button")
local Format = require("solarui/format")
local Label = require("solarui/ui/label")
local Layout = require("solarui/garden/layout")
local LayoutUI = require("solarui/ui/layout")
local Sky = require("solarui/garden/sky")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local GardenBook = {}

GardenBook.FOOT = 26    -- book units at the foot of the right page, for the passage's number
GardenBook.SPRIG = 358  -- where the pressed sprig begins on the left page, in book units

-- "3 March 2026" for a highlight's time ("2026-03-03 14:22:10"), or nil.
function GardenBook.day(stamp)
    local y, m, d = tostring(stamp or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    if not y then return nil end
    local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
    return (Format.date("%d %B %Y", t):gsub("^0", ""))
end

-- The lines under the vine for the passage q, as labels' options: the
-- chapter, the page, the day it was highlighted and the reader's note.
function GardenBook.details(q)
    local out = {}
    if q.chapter and q.chapter ~= "" then out[#out + 1] = { text = q.chapter, kind = "small", lines = 2 } end
    if q.pageno then out[#out + 1] = { text = string.format(_("Page %s"), tostring(q.pageno)), kind = "small" } end
    local day = GardenBook.day(q.date)
    if day then out[#out + 1] = { text = string.format(_("Highlighted on %s"), day), kind = "small", color = "muted", lines = 2 } end
    if q.note and q.note ~= "" then out[#out + 1] = { text = string.format(_("Your note: %s"), q.note), kind = "small", lines = 3 } end
    return out
end

-- Lay the book out on `scene`. o: { quote (or nil), at (its number in this
-- visit's run), count, on_prev, on_next, on_read (nil when the passage is
-- not from a book), on_close }.
function GardenBook.place(scene, o)
    local th = Theme.get()
    local oy = math.max(0, (scene.vh - Layout.HEIGHT) / 2)
    local art, P = Layout.BOOK_ART, Layout.BOOKPAGE
    local box = { x = 36, y = 112 + oy, w = 1000 }
    box.h = box.w * art.h / art.w
    local k = box.w / art.w
    scene:backdrop("garden_book", box.x, box.y, box.w, box.h, Sky.now())
    local function page(b) return box.x + b.x * k, box.y + b.y * k, b.w * k, b.h * k end
    local function lines(h, kind) return math.max(1, math.floor(scene:px(h) / Text.height(kind or "body"))) end
    local q = o.quote
    -- the right page: the passage, and its number at the foot
    local rx, ry, rw, rh = page(P.right)
    local foot = GardenBook.FOOT * k
    scene:place(Label:new({ text = q and ("\u{201C}" .. q.text .. "\u{201D}") or _("Nothing is written in this book yet. Highlight a passage in one of your books and the passage will appear here."),
        kind = "body", lines = lines(rh - foot) }), rx, ry, rw, rh - foot)
    if q and o.count > 1 then
        scene:place(Label:new({ text = string.format(_("%d of %d"), o.at, o.count), kind = "small", color = "muted", align = "center" }), rx, ry + rh - foot, rw, foot)
    end
    -- the left page: the book above the vine, its details below
    local lx, ly, lw = page(P.left)
    if q then
        local above = (Layout.BOOKDIVIDE - 12 - P.left.y) * k
        local head = {}
        if q.path then head[#head + 1] = Label:new({ text = _("From"), kind = "small", color = "muted" }) end
        head[#head + 1] = Label:new({ text = q.title or "", kind = "heading", lines = 2 })
        head[#head + 1] = Label:new({ text = q.author or "", kind = "small", color = "muted", lines = 2 })
        scene:place(LayoutUI.Column:new({ gap = scene:px(6), children = head }), lx, ly, lw, above)
        local rows = {}
        for _i, d in ipairs(GardenBook.details(q)) do rows[#rows + 1] = Label:new(d) end
        if #rows > 0 then
            -- (clear of the pressed sprig at the foot of the page)
            local top = box.y + (Layout.BOOKDIVIDE + 16) * k
            scene:place(LayoutUI.Column:new({ gap = scene:px(4), clip = true, children = rows }), lx, top, lw, (GardenBook.SPRIG - Layout.BOOKDIVIDE - 16) * k)
        end
    end
    -- turning the pages by tapping them
    if q and o.count > 1 then
        scene:touch(lx, ly, lw, P.left.h * k, o.on_prev)
        scene:touch(rx, ry, rw, rh, o.on_next)
    end
    local y = box.y + box.h + 24
    scene:place(LayoutUI.Row:new({ gap = th.space.s, children = {
        Button:new({ label = _("Previous"), grow = true, disabled = not q or o.count < 2, on_tap = o.on_prev }),
        Button:new({ label = _("Read on"), variant = "primary", grow = true, disabled = not (q and o.on_read), on_tap = o.on_read }),
        Button:new({ label = _("Next"), grow = true, disabled = not q or o.count < 2, on_tap = o.on_next }),
    } }), 166, y, 740)
    scene:place(Button:new({ label = _("Back to the garden"), variant = "secondary", on_tap = o.on_close }), 166, y + th.size.touch + th.space.s, 740, th.size.touch)
end

return GardenBook
