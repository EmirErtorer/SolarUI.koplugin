-- The open book a passage is shown in, seen from the front: a cloth cover
-- with a tooled border and gold corner pieces, the gilt stacked edges of its
-- leaves, two tall facing pages curving down into a shaded gutter, each with
-- a double ruled frame, a fleuron at the head of the right page, a vine
-- divider across the left page between the book's name and its details, a
-- pressed sprig at the foot of the left page, the corner of the right page
-- lifting, a headband, and two ribbons hanging below. garden_book(c, vw, vh,
-- param) fills a canvas the shape of Layout.BOOK_ART; the screen lays the
-- words over the pages in the boxes of Layout.BOOKPAGE (Layout.BOOKDIVIDE is
-- the divider's height), which stay clear but for the faint lines.

local Flora = require("solarui/art/flora")
local Layout = require("solarui/garden/layout")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle
local mix = Wash.mix

local Book = {}

local GUTTER = 320   -- the middle of the book, where the pages meet
local TOP, BOT = 40, 420   -- the top and bottom of a page at its outer edge

-- The outline of the left page, `d` units out for the leaves under it, sagging towards the gutter.
local function leaf(d)
    return string.format("M%s %s Q%s %s %s %s Q%s %s %s %s L%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %sZ",
        n(GUTTER), n(TOP + 16 + d * .4), n(GUTTER - 6), n(TOP + 2 + d * .6), n(GUTTER - 30), n(TOP + d * .6),
        n(170), n(TOP - 14 - d * .2), n(36 - d), n(TOP + 6 + d * .2), n(36 - d), n(BOT + d),
        n(170), n(BOT - 12 + d * 1.2), n(GUTTER - 30), n(BOT - 4 + d * 1.1), n(GUTTER - 6), n(BOT - 4 + d * 1.1), n(GUTTER), n(BOT + 8 + d * .8),
        n(GUTTER - 4), n((TOP + BOT) / 2), n(GUTTER), n(TOP + 16 + d * .4))
end

-- A gold corner piece of the cover at its top left: a bracket with a leaf and a whiplash curl.
local function corner(c)
    return path("M12 26 L78 26 Q42 36 23 62 Q16 76 12 92Z", c.gold, c.ink, 1.8)
        .. line(Svg.poly(Svg.join({ { 18, 78 }, { 27, 54 } }, Svg.spiral(41, 43, 12, 1.2, 250))), c.ink, 1.4)
        .. Flora.leaf(c, 50, 31, -8, 18, 5, mix(c.gold, c.cream, .4), true) .. circle(19, 31, 2.8, c.cream, c.ink, 1)
end

-- A rule round the box b: a double line with a small diamond at each corner.
local function frame(rule, box)
    local x0, y0, x1, y1 = box.x - 10, box.y - 12, box.x + box.w + 8, box.y + box.h + 10
    local function rect(i) return string.format("M%s %s L%s %s L%s %s L%s %sZ", n(x0 + i), n(y0 + i), n(x1 - i), n(y0 + i), n(x1 - i), n(y1 - i), n(x0 + i), n(y1 - i)) end
    local out = line(rect(0) .. " " .. rect(3.4), rule, .9)
    for _i, p in ipairs({ { x0, y0 }, { x1, y0 }, { x0, y1 }, { x1, y1 } }) do
        out = out .. path(string.format("M%s %s l3 3 l-3 3 l-3 -3Z", n(p[1]), n(p[2] - 3)), rule)
    end
    return out
end

-- The left side of the book: the gilt stacked edges of the leaves, the page,
-- the shade where it curves into the gutter, and the rule round `box`.
local function side(c, paper, rule, box)
    local gilt = mix(paper, c.gold, .42)
    local out = ""
    for i, d in ipairs({ 14, 10.5, 7, 3.5 }) do out = out .. path(leaf(d), i == 1 and mix(gilt, c.line, .3) or gilt, c.ink, i == 1 and 1.8 or .8) end
    out = out .. path(leaf(0), paper, c.ink, 1.8)
    -- the shade, in three bands that darken towards the gutter
    for i, b in ipairs({ { 42, .14 }, { 26, .3 }, { 13, .48 } }) do
        local w = b[1]
        out = out .. path(string.format("M%s %s Q%s %s %s %s L%s %s Q%s %s %s %sZ", n(GUTTER), n(TOP + 16), n(GUTTER - 4), n((TOP + BOT) / 2), n(GUTTER), n(BOT + 8),
            n(GUTTER - w), n(BOT + 3 - i), n(GUTTER - w - 4), n((TOP + BOT) / 2), n(GUTTER - w + 1), n(TOP + 12 + i)), mix(paper, c.line, b[2]))
    end
    return out .. frame(rule, box)
end

-- A pressed sprig of forget-me-not with blue flowers and pink buds curled at its tip.
local function sprig(c)
    local stem = Svg.spline({ { 82, 404 }, { 130, 398 }, { 186, 390 }, { 228, 378 }, { 248, 366 } }, 8)
    local out = ""
    for i, f in ipairs({ .12, .3, .46, .6, .72 }) do
        local x, y, ang = Svg.along(stem, Svg.length(stem) * f)
        out = out .. Flora.leaf(c, x, y, ang + (i % 2 == 0 and 46 or -40), 24 - i * 2, 6 - i * .4, i % 2 == 0 and c.leaf or c.sage, true)
    end
    local curl = Svg.spiral(256, 372, 8, .8, 300)
    for i, f in ipairs({ { 226, 370, 5.4 }, { 214, 362, 4.8 }, { 238, 360, 4.4 } }) do
        out = out .. line(string.format("M%s %s L%s %s", n(i == 1 and 222 or 228), n(381), n(f[1]), n(f[2])), c.stem, 1)
            .. Svg.dots(f[1], f[2], f[3] * .7, 5, f[3] * 1.15, c.sky) .. circle(f[1], f[2], f[3] * .3, c.pale, c.ink, .7)
    end
    for i = 2, #curl, 3 do out = out .. circle(curl[i][1], curl[i][2], 2.4 - i * .06, c.bloom2, c.ink, .7) end
    return Svg.stem(Svg.join(stem, curl), Svg.taper(2.4, 1), c.stem, c.ink, 1) .. out
end

-- The vine across the left page at height y, from x0 to x1: a flower in the
-- middle, leaves along it and a curl at each end.
local function divider(c, x0, x1, y)
    local mid = (x0 + x1) / 2
    local out = line(string.format("M%s %s Q%s %s %s %s Q%s %s %s %s", n(x0 + 10), n(y), n((x0 + mid) / 2), n(y - 5), n(mid), n(y), n((mid + x1) / 2), n(y + 5), n(x1 - 10), n(y)), c.stem, 1.4)
        .. line(Svg.poly(Svg.spiral(x0 + 6, y - 3, 5, 1, 0, true)), c.stem, 1.2) .. line(Svg.poly(Svg.spiral(x1 - 6, y + 3, 5, 1, 180, true)), c.stem, 1.2)
    for k, f in ipairs({ .18, .32, .68, .82 }) do
        local x = x0 + (x1 - x0) * f
        out = out .. Flora.leaf(c, x, y + (f < .5 and -1.5 or 1.5), (k % 2 == 0) and -40 or -140, 12, 4, k % 2 == 0 and c.leaf or c.sage, true)
    end
    for k = 0, 4 do
        local a = math.rad(k * 72 - 90)
        out = out .. circle(mid + math.cos(a) * 4.4, y + math.sin(a) * 4.4, 3.4, c.bloom2, c.ink, .7)
    end
    return out .. circle(mid, y, 2.4, c.gold, c.ink, .7)
end

-- A small fleuron of three leaves and a bud, centred at (x, y).
local function fleuron(c, x, y)
    return Flora.leaf(c, x, y, -160, 13, 4, c.sage, true) .. Flora.leaf(c, x, y, -20, 13, 4, c.sage, true) .. Flora.leaf(c, x, y, -90, 10, 3.6, c.leaf, true)
        .. circle(x, y + 1, 2.2, c.bloom, c.ink, .7) .. line(string.format("M%s %s L%s %s M%s %s L%s %s", n(x - 34), n(y + 2), n(x - 18), n(y + 2), n(x + 18), n(y + 2), n(x + 34), n(y + 2)), c.stem, .9)
end

-- The book, open, on a canvas the shape of Layout.BOOK_ART.
function Book.garden_book(c, vw, _vh, param)
    local lit = Wash.apply(c, param)
    local paper = mix(lit.cream, c.cream, .55)   -- the pages keep some of their own light, for the words
    local rule = mix(paper, lit.line, .6)
    local W, H = Layout.BOOK_ART.w, Layout.BOOK_ART.h
    local cover = string.format("M8 20 Q170 8 312 28 L328 28 Q470 8 632 20 L632 %s Q470 %s 328 %s L312 %s Q170 %s 8 %sZ", n(H - 24), n(H - 36), n(H - 16), n(H - 16), n(H - 36), n(H - 24))
    local pages = Layout.BOOKPAGE
    local mirrored = { x = W - pages.right.x - pages.right.w, y = pages.right.y, w = pages.right.w, h = pages.right.h }
    local tooled = mix(lit.accent, lit.gold, .45)
    local ribbon = function(x, colour, len)
        return path(string.format("M%s %s L%s %s L%s %s L%s %s L%s %s L%s %sZ", n(x - 5), n(H - 30), n(x + 5), n(H - 30), n(x + 6), n(H - 30 + len), n(x), n(H - 36 + len), n(x - 6), n(H - 30 + len), n(x - 5), n(H - 30)), colour, lit.ink, 1.2)
    end
    local body = group(6, 9, 0, path(cover, mix(lit.ink, c.bg, .55)))
        .. ribbon(GUTTER + 12, lit.violet or lit.accent, 30) .. ribbon(GUTTER - 2, lit.bloom, 26)
        .. path(cover, lit.accent, lit.ink, 2.6)
        .. line(string.format("M16 30 Q170 18 310 37 M624 30 Q470 18 330 37 M16 %s Q170 %s 310 %s M624 %s Q470 %s 330 %s", n(H - 33), n(H - 45), n(H - 26), n(H - 33), n(H - 45), n(H - 26)), tooled, 1.2)
        .. line(string.format("M16 30 L16 %s M624 30 L624 %s", n(H - 33), n(H - 33)), tooled, 1.2)
        .. corner(lit) .. group(W, 0, 0, corner(lit), -1, 1) .. group(0, H, 0, corner(lit), 1, -1) .. group(W, H, 0, corner(lit), -1, -1)
        .. side(lit, paper, rule, pages.left) .. group(W, 0, 0, side(lit, paper, rule, mirrored), -1, 1)
        .. path(string.format("M598 %s Q606 %s 604 %s Q590 %s 566 %sZ", n(BOT), n(BOT - 26), n(BOT - 38), n(BOT - 20), n(BOT - 12)), mix(paper, lit.line, .3), lit.ink, 1.4)
        .. path(string.format("M%s 24 L%s 24 L%s %s L%s %s L%s %sZ", n(GUTTER - 3), n(GUTTER + 3), n(GUTTER + 3), n(BOT + 8), n(GUTTER), n(BOT + 14), n(GUTTER - 3), n(BOT + 8)), lit.bloom, lit.ink, 1.1)
        .. path(string.format("M%s 26 Q%s 16 %s 26Z", n(GUTTER - 11), n(GUTTER), n(GUTTER + 11)), lit.gold, lit.ink, 1.2) .. line(string.format("M%s 22 L%s 22", n(GUTTER - 7), n(GUTTER + 7)), lit.bloom, 1.4)
        .. fleuron(lit, pages.right.x + pages.right.w / 2, pages.right.y - 22)
        .. divider(lit, pages.left.x + 20, pages.left.x + pages.left.w - 20, Layout.BOOKDIVIDE)
        .. sprig(lit)
    return group(0, 0, 0, body, vw / W)
end

return Book
