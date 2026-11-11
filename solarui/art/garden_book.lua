-- The open book a passage is shown in. garden_book(c, vw, vh) fills a
-- canvas the shape of Layout.BOOK_ART; the words are laid over its pages by
-- the screen, in the boxes of Layout.BOOKPAGE.

local Layout = require("solarui/garden/layout")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local path = Svg.path

local Book = {}

-- Two facing pages with a gutter between them.
function Book.garden_book(c, vw, _vh, param)
    c = Wash.apply(c, param)
    local k = vw / Layout.BOOK_ART.w
    return Svg.group(0, 0, 0, path("M20 40 Q160 20 320 50 Q480 20 620 40 L620 390 Q480 366 320 396 Q160 366 20 390Z", c.cream, c.ink, 3)
        .. Svg.line("M320 50 L320 396", c.ink, 2), k)
end

return Book
