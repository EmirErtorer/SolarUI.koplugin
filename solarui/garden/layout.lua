-- Where everything stands in the garden, on the poster's design canvas (1072
-- units wide, DESIGN_H tall). Every plant and animal has a place of its own
-- and so has each prop of the scenery, so the artwork can be drawn around
-- them and no two ever overlap (tests/garden.lua checks it). A taller screen
-- spreads the rows apart; the pictures keep their size.

local Layout = {}

Layout.WIDTH = 1072
Layout.HEIGHT = 1360

-- A box { x, y, w, h }.
local function box(x, y, w, h) return { x = x, y = y, w = w, h = h } end

-- Plants by id: trees and the trellis at the back, the tall beds, the beds
-- by the pond and table, then the low flowers at the front.
Layout.PLANTS = {
    maple = box(34, 112, 262, 332), ivy = box(318, 112, 436, 332), ginkgo = box(776, 112, 262, 332),
    sunflower = box(34, 556, 170, 236), iris = box(216, 572, 150, 220), lily = box(378, 562, 160, 230),
    rose = box(550, 552, 180, 240), poppy = box(742, 572, 140, 220), chamomile = box(894, 592, 140, 200),
    water_lily = box(50, 902, 170, 150), tulip = box(380, 904, 140, 196), narcissus = box(530, 914, 130, 186),
    honesty = box(34, 1124, 120, 116), bracken = box(166, 1124, 150, 116), bellflower = box(328, 1124, 130, 116),
    crocus = box(470, 1154, 100, 90), pansy = box(582, 1154, 100, 90), dandelion = box(694, 1144, 110, 100),
}

-- Animals by id: the air between the rows, the pond, and the ground in front.
Layout.ANIMALS = {
    bee = box(70, 456, 110, 70), butterfly = box(240, 456, 80, 70), moth = box(780, 456, 80, 70), robin = box(900, 452, 110, 80),
    dragonfly = box(120, 806, 100, 64), ladybug = box(430, 812, 60, 50),
    frog = box(236, 936, 70, 60), koi = box(232, 1010, 100, 56),
    snail = box(112, 1258, 80, 56), hedgehog = box(204, 1252, 110, 64), fox = box(326, 1248, 130, 76), peacock = box(820, 1238, 150, 86),
}

-- Scenery that cannot be tapped: the table with its chairs and the plaque
-- for a favourite passage, and the pond, which holds the water lily, the
-- frog and the koi inside its edge.
Layout.PROPS = {
    pond = box(34, 880, 330, 230), table = box(690, 890, 340, 220), plaque = box(830, 1130, 200, 100),
}
Layout.INSIDE_POND = { "water_lily", "frog", "koi" }

-- Parts of the page that belong to the frame and the heading: the title row
-- and the corner ornaments (the ones below are measured from the bottom edge,
-- and include the bud at the middle of the foot).
Layout.RESERVED = {
    title = box(110, 30, 852, 76), corner_tl = box(-10, -10, 110, 110), corner_tr = box(972, -10, 110, 110),
}
Layout.CORNERS_BELOW = { box(-10, -100, 110, 110), box(972, -100, 110, 110), box(500, -60, 72, 60) }

-- The vertical stretch for a canvas `vh` units tall (never below one).
function Layout.stretch(vh)
    return math.max(1, vh / Layout.HEIGHT)
end

-- A box moved to its place on a canvas `vh` tall: only y changes.
function Layout.at(b, vh)
    return { x = b.x, y = math.floor(b.y * Layout.stretch(vh) + .5), w = b.w, h = b.h }
end

-- The place of a plant or animal on a canvas `vh` tall, or nil.
function Layout.place(id, vh)
    local b = Layout.PLANTS[id] or Layout.ANIMALS[id]
    return b and Layout.at(b, vh) or nil
end

-- Every box with a name, for checks: plants, animals, props, the heading
-- and the corners, laid out for a canvas `vh` tall. The pond is left out
-- (see INSIDE_POND), its three dwellers stand in for it.
function Layout.all(vh)
    local out = {}
    for _kind, set in ipairs({ Layout.PLANTS, Layout.ANIMALS, Layout.PROPS }) do
        for id, b in pairs(set) do out[id] = Layout.at(b, vh) end
    end
    out.pond = nil
    for id, b in pairs(Layout.RESERVED) do out[id] = b end
    for i, b in ipairs(Layout.CORNERS_BELOW) do out["corner_b" .. i] = box(b.x, vh + b.y, b.w, b.h) end
    return out
end

return Layout
