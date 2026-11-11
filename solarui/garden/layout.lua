-- Where everything stands in the garden, on the poster's design canvas (1072
-- units wide, HEIGHT tall). Plants, scenery and the places animals may stand
-- are scattered over the lawn, each with a box of its own big enough for the
-- plant fully grown, so no two ever overlap however the garden grows (tests/
-- garden.lua checks it). Animals do not own a place: on every visit each one
-- is dealt one of the free spots, so they turn up somewhere new, and faces
-- left or right. A taller screen spreads the lawn apart; the pictures keep
-- their size.

local Layout = {}

Layout.WIDTH = 1072
Layout.HEIGHT = 1430

-- A box { x, y, w, h }.
local function box(x, y, w, h) return { x = x, y = y, w = w, h = h } end

-- The sky: the band between the heading and the foot of the hedge, behind
-- the trees. The hedge stands at the foot of the trees, where the lawn begins.
Layout.SKY = box(34, 112, 1004, 344)
Layout.LAWN_TOP = 456

-- Plants by id: three trees and the trellis along the back, standing on the
-- lawn's edge, the rest scattered, tall and low mixed.
Layout.PLANTS = {
    maple = box(34, 124, 262, 332), ivy = box(330, 124, 436, 332), ginkgo = box(776, 124, 262, 332),
    lily = box(250, 484, 136, 196), poppy = box(781, 484, 119, 187), rose = box(45, 558, 153, 204),
    narcissus = box(753, 693, 110, 158), sunflower = box(882, 701, 144, 201), iris = box(251, 762, 128, 187),
    chamomile = box(54, 814, 119, 170), honesty = box(629, 872, 102, 99), tulip = box(744, 881, 119, 167),
    bracken = box(899, 933, 128, 99), bellflower = box(255, 971, 110, 99), crocus = box(149, 1001, 85, 76),
    pansy = box(310, 1128, 85, 76), dandelion = box(644, 1255, 94, 85),
    water_lily = box(434, 1031, 124, 110),
}

-- Scenery: the pond (which holds the water lily, the frog and the koi) and
-- the table with its chairs, drawn at TABLE_ART units and fitted to its box.
Layout.PROPS = {
    pond = box(418, 1007, 300, 215), table = box(438, 663, 300, 195),
}
Layout.TABLE_ART = { w = 340, h = 220 }
Layout.INSIDE_POND = { "water_lily", "frog", "koi" }

-- The book lying on the table, in the table art's own units: tapping it
-- opens a passage from the reader's books.
Layout.BOOK = box(80, 45, 140, 100)

-- The open book a passage is shown in, in its own units (the drawing is
-- BOOK_ART big): where the words go on the left and right page.
Layout.BOOK_ART = { w = 640, h = 420 }
Layout.BOOKPAGE = { left = box(62, 64, 236, 262), right = box(344, 64, 236, 262) }

-- The small things of the lawn that cannot be tapped.
Layout.EXTRAS = {
    skep = box(50, 1006, 64, 67), birdbath = box(956, 531, 72, 69), lantern = box(752, 1097, 35, 61), can = box(936, 1264, 83, 51),
}

-- The size each animal is drawn at (its art's own units); it is shown
-- ANIMAL_SCALE times as big, so the small ones can be seen and tapped. Their
-- places are dealt on each visit; the two in the pond stay there. The ones
-- that fly may be dealt a place in the sky.
Layout.ANIMAL_SCALE = 1.3
Layout.ANIMALS = {
    bee = box(0, 0, 110, 70), butterfly = box(0, 0, 80, 70), moth = box(0, 0, 80, 70), robin = box(0, 0, 110, 80),
    dragonfly = box(0, 0, 100, 64), ladybug = box(0, 0, 60, 50), snail = box(0, 0, 80, 56), hedgehog = box(0, 0, 110, 64),
    fox = box(0, 0, 130, 76), peacock = box(0, 0, 150, 86), frog = box(0, 0, 70, 60), koi = box(0, 0, 100, 56),
}
Layout.FLIES = { bee = true, butterfly = true, moth = true, dragonfly = true }
Layout.FIXED = { frog = box(594, 1035, 91, 78), koi = box(568, 1145, 130, 73) }

-- The free spots animals are dealt: in the sky (inside the trellis arch)
-- and on the lawn, large, medium and small, so any animal fits at least one
-- kind. Tapping a spot taps the animal in it.
Layout.SPOTS = {
    { x = 415, y = 215, w = 150, h = 105, air = true }, { x = 480, y = 338, w = 150, h = 105, air = true },
    { x = 827, y = 1087, w = 200, h = 120 }, { x = 95, y = 1098, w = 200, h = 120 },
    { x = 537, y = 484, w = 150, h = 105 }, { x = 444, y = 879, w = 150, h = 105 },
    { x = 767, y = 1243, w = 150, h = 105 }, { x = 297, y = 1246, w = 150, h = 105 },
    { x = 412, y = 527, w = 110, h = 92 }, { x = 151, y = 1243, w = 110, h = 92 }, { x = 511, y = 1245, w = 110, h = 92 },
}

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
    local k = Layout.stretch(vh)
    return { x = b.x, y = math.floor(b.y * k + .5), w = b.w, h = b.h, flip = b.flip, hit = b.hit and Layout.at(b.hit, vh) or nil }
end

-- The box to tap for the book on the table, on a canvas `vh` tall.
function Layout.bookHit(vh)
    local t, art = Layout.at(Layout.PROPS.table, vh), Layout.TABLE_ART
    local sx, sy = t.w / art.w, t.h / art.h
    return { x = t.x + Layout.BOOK.x * sx, y = t.y + Layout.BOOK.y * sy, w = Layout.BOOK.w * sx, h = Layout.BOOK.h * sy }
end

-- A random number generator from a seed (the same seed gives the same run).
local function rng(seed)
    local s = math.floor(seed) % 2147483646 + 1
    return function()
        s = s * 48271 % 2147483647
        return s / 2147483647
    end
end

-- Whether the animal's box fits in the spot.
local function fits(spot, size)
    return size.w <= spot.w and size.h <= spot.h
end

-- The size an animal is shown at.
function Layout.shown(id)
    local size = Layout.ANIMALS[id]
    return { w = math.floor(size.w * Layout.ANIMAL_SCALE + .5), h = math.floor(size.h * Layout.ANIMAL_SCALE + .5) }
end

-- Where each animal stands on one visit: { id = box with `flip` and `hit` (the
-- box to tap) }. The two in the pond stay there; the others are dealt a spot
-- each, the biggest first, and a place inside it, and face either way. The
-- ones that fly are dealt a spot in the sky while there is one.
function Layout.spread(seed)
    local rand = rng(seed or 1)
    local out = {}
    local roaming = {}
    for id in pairs(Layout.ANIMALS) do
        local size = Layout.shown(id)
        if Layout.FIXED[id] then
            local f = Layout.FIXED[id]
            out[id] = box(f.x, f.y, f.w, f.h)
            local hw, hh = math.max(f.w, 96), math.max(f.h, 96)
            out[id].hit = box(f.x + (f.w - hw) / 2, f.y + (f.h - hh) / 2, hw, hh)
            out[id].flip = rand() < .5
        else
            roaming[#roaming + 1] = { id = id, size = size }
        end
    end
    table.sort(roaming, function(a, b)
        local sa, sb = a.size.w * a.size.h, b.size.w * b.size.h
        if sa ~= sb then return sa > sb end
        return a.id < b.id
    end)
    local free = {}
    for i, s in ipairs(Layout.SPOTS) do free[i] = s end
    for _i, r in ipairs(roaming) do
        local options, sky = {}, {}
        for j, s in ipairs(free) do
            if fits(s, r.size) and (Layout.FLIES[r.id] or not s.air) then
                options[#options + 1] = j
                if s.air then sky[#sky + 1] = j end
            end
        end
        local pool = #sky > 0 and sky or options
        local s = table.remove(free, pool[1 + math.floor(rand() * #pool)])
        out[r.id] = box(s.x + math.floor((s.w - r.size.w) * rand()), s.y + math.floor((s.h - r.size.h) * rand()), r.size.w, r.size.h)
        out[r.id].hit = box(s.x, s.y, s.w, s.h)
        out[r.id].flip = rand() < .5
    end
    return out
end

-- Whether a plant is drawn turned the other way round: fixed for each
-- plant, so it does not change between visits. The trellis is symmetric
-- and shared with the ground, so the ivy never turns.
function Layout.turned(id)
    if id == "ivy" then return false end
    local h = 0
    for i = 1, #id do h = (h * 31 + id:byte(i)) % 1009 end
    return h % 2 == 1
end

-- The place of a plant on a canvas `vh` tall, or nil.
function Layout.place(id, vh)
    local b = Layout.PLANTS[id]
    return b and Layout.at(b, vh) or nil
end

-- Every box with a name, for checks: plants, props, extras, the animals as
-- dealt by `spread` (the place they are tapped at counts too), the heading and
-- the corners, laid out for a canvas `vh` tall. The pond is left out (see
-- INSIDE_POND), its dwellers stand in for it, and the trellis counts only as
-- its two posts and its top: the sky shows through the arch.
function Layout.all(vh, spread)
    local out = {}
    spread = spread or Layout.spread(1)
    for _kind, set in ipairs({ Layout.PLANTS, Layout.PROPS, Layout.EXTRAS, spread }) do
        for id, b in pairs(set) do out[id] = Layout.at(b.hit or b, vh) end
    end
    out.pond, out.ivy = nil, nil
    local ivy = Layout.PLANTS.ivy
    out.ivy_left = Layout.at(box(ivy.x, ivy.y + 80, 70, ivy.h - 80), vh)
    out.ivy_right = Layout.at(box(ivy.x + ivy.w - 70, ivy.y + 80, 70, ivy.h - 80), vh)
    out.ivy_top = Layout.at(box(ivy.x, ivy.y, ivy.w, 80), vh)
    for id, b in pairs(Layout.RESERVED) do out[id] = b end
    for i, b in ipairs(Layout.CORNERS_BELOW) do out["corner_b" .. i] = box(b.x, vh + b.y, b.w, b.h) end
    return out
end

return Layout
