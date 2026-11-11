-- The open book a passage is shown in, seen from the front: a cloth cover
-- with gold corner pieces, the stacked edges of its leaves, two facing pages
-- curving down into the gutter with a faint ruled frame, the corner of the
-- right page lifting, a ribbon down the gutter and a pressed sprig at the
-- foot of the left page. garden_book(c, vw, vh, param) fills a canvas the
-- shape of Layout.BOOK_ART; the screen lays the words over the pages in the
-- boxes of Layout.BOOKPAGE, which stay clear but for the faint lines.

local Flora = require("solarui/art/flora")
local Layout = require("solarui/garden/layout")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line = Svg.n, Svg.group, Svg.path, Svg.line
local mix = Wash.mix

local Book = {}

local GUTTER = 320   -- the middle of the book, where the pages meet

-- The outline of the left page, `d` units out for the leaves under it, sagging towards the gutter.
local function leaf(d)
    return string.format("M%s %s Q%s %s %s %s Q%s %s %s %s L%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %sZ",
        n(GUTTER), n(52 + d * .4), n(GUTTER - 6), n(38 + d * .6), n(GUTTER - 30), n(36 + d * .6),
        n(170), n(22 - d * .2), n(36 - d), n(42 + d * .2), n(36 - d), n(356 + d),
        n(170), n(344 + d * 1.2), n(GUTTER - 30), n(352 + d * 1.1), n(GUTTER - 6), n(352 + d * 1.1), n(GUTTER), n(364 + d * .8),
        n(GUTTER - 4), n(200), n(GUTTER), n(52 + d * .4))
end

-- A gold corner piece of the cover at its top left, with a whiplash curl.
local function corner(c)
    return path("M12 26 L74 26 Q40 36 22 60 Q16 74 12 88Z", c.gold, c.ink, 1.8)
        .. line(Svg.poly(Svg.join({ { 18, 74 }, { 26, 52 } }, Svg.spiral(40, 42, 12, 1.2, 250))), c.ink, 1.4)
        .. Svg.circle(56, 32, 3, c.cream, c.ink, 1)
end

-- The left side of the book: stacked leaf edges, the page, its faint ruled frame and the gutter shade.
local function side(c, paper, rule, box)
    local out = ""
    for d = 12, 3, -3 do out = out .. path(leaf(d), d == 12 and mix(paper, c.line, .5) or paper, c.ink, d == 12 and 1.8 or .9) end
    out = out .. path(leaf(0), paper, c.ink, 1.8)
    local x0, y0, x1, y1 = box.x - 10, box.y - 12, box.x + box.w + 8, box.y + box.h + 12
    out = out .. line(string.format("M%s %s L%s %s L%s %s L%s %sZ", n(x0), n(y0), n(x1), n(y0), n(x1), n(y1), n(x0), n(y1)), rule, 1)
        .. line(string.format("M%s %s L%s %s", n(x0 + 20), n(y0 - 6), n(x1 - 20), n(y0 - 6)), rule, 1)
    -- the gutter's shade where the page curves away
    return out .. path(string.format("M%s 52 Q%s 200 %s 364 L%s 360 Q%s 200 %s 50Z", n(GUTTER), n(GUTTER - 4), n(GUTTER), n(GUTTER - 14), n(GUTTER - 18), n(GUTTER - 13)), mix(paper, c.line, .45))
end

-- A pressed sprig of forget-me-not with blue flowers and pink buds curled at its tip.
local function sprig(c)
    local stem = Svg.spline({ { 92, 342 }, { 140, 336 }, { 196, 330 }, { 238, 318 }, { 258, 306 } }, 8)
    local out = ""
    for i, f in ipairs({ .12, .3, .46, .6, .72 }) do
        local x, y, ang = Svg.along(stem, Svg.length(stem) * f)
        out = out .. Flora.leaf(c, x, y, ang + (i % 2 == 0 and 46 or -40), 28 - i * 2.4, 7 - i * .5, i % 2 == 0 and c.leaf or c.sage, true)
    end
    local curl = Svg.spiral(266, 312, 9, .8, 300)
    for i, f in ipairs({ { 236, 310, 6 }, { 224, 302, 5.4 }, { 248, 300, 5 } }) do
        out = out .. line(string.format("M%s %s L%s %s", n(i == 1 and 232 or 238), n(321), n(f[1]), n(f[2])), c.stem, 1)
            .. Svg.dots(f[1], f[2], f[3] * .7, 5, f[3] * 1.15, c.sky) .. Svg.circle(f[1], f[2], f[3] * .3, c.pale, c.ink, .7)
    end
    for i = 2, #curl, 3 do out = out .. Svg.circle(curl[i][1], curl[i][2], 2.6 - i * .06, c.bloom2, c.ink, .7) end
    return Svg.stem(Svg.join(stem, curl), Svg.taper(2.6, 1), c.stem, c.ink, 1) .. out
end

-- The book, open, on a canvas the shape of Layout.BOOK_ART.
function Book.garden_book(c, vw, _vh, param)
    local lit = Wash.apply(c, param)
    local paper = mix(lit.cream, c.cream, .55)   -- the pages keep some of their own light, for the words
    local rule = mix(paper, lit.line, .55)
    local cover = "M8 18 Q170 6 312 26 L328 26 Q470 6 632 18 L632 392 Q470 380 328 400 L312 400 Q170 380 8 392Z"
    local pages = Layout.BOOKPAGE
    local mirrored = { x = Layout.BOOK_ART.w - pages.right.x - pages.right.w, y = pages.right.y, w = pages.right.w, h = pages.right.h }
    local body = group(6, 8, 0, path(cover, mix(lit.ink, c.bg, .55)))
        .. path(cover, lit.accent, lit.ink, 2.6) .. line("M14 26 Q170 14 312 34 M626 26 Q470 14 328 34 M14 384 Q170 372 312 392 M626 384 Q470 372 328 392", mix(lit.accent, lit.gold, .5), 1.2)
        .. corner(lit) .. group(640, 0, 0, corner(lit), -1, 1) .. group(0, 420, 0, corner(lit), 1, -1) .. group(640, 420, 0, corner(lit), -1, -1)
        .. side(lit, paper, rule, pages.left) .. group(640, 0, 0, side(lit, paper, rule, mirrored), -1, 1)
        .. path("M598 356 Q606 330 604 318 Q590 336 566 344Z", mix(paper, lit.line, .3), lit.ink, 1.4)
        .. path(string.format("M%s 24 L%s 24 L%s 404 L%s 418 L%s 404 L%s 404Z", n(GUTTER - 4), n(GUTTER + 4), n(GUTTER + 5), n(GUTTER), n(GUTTER - 5), n(GUTTER - 4)), lit.bloom, lit.ink, 1.3)
        .. path(string.format("M%s 24 Q%s 16 %s 24Z", n(GUTTER - 10), n(GUTTER), n(GUTTER + 10)), lit.gold, lit.ink, 1.2)
        .. sprig(lit)
    return group(0, 0, 0, body, vw / Layout.BOOK_ART.w)
end

return Book
