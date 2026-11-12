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

-- How far in from the screen's edge the lawn reaches: up to the ruled border.
Layout.EDGE = 21.6

-- On a canvas `vw` units wide the lawn and sky reach from EDGE to `vw` - EDGE
-- instead of from 34 to 1038: { f = how much further apart things stand,
-- at(x) = where the poster's x goes }.
function Layout.fan(vw)
    local f = (vw - 2 * Layout.EDGE) / Layout.SKY.w
    return { f = f, at = function(x) return Layout.EDGE + (x - Layout.SKY.x) * f end }
end

-- Plants by id: three trees and the trellis along the back, standing on the
-- lawn's edge, the rest scattered, tall and low mixed.
Layout.PLANTS = {
    maple = box(34, 124, 262, 332), ivy = box(330, 124, 436, 332), ginkgo = box(776, 124, 262, 332),
    lily = box(250, 484, 136, 196), poppy = box(781, 484, 119, 187), rose = box(45, 558, 153, 204),
    narcissus = box(753, 693, 110, 158), sunflower = box(882, 701, 144, 201), iris = box(251, 762, 128, 187),
    chamomile = box(54, 814, 119, 170), honesty = box(629, 872, 102, 99), tulip = box(744, 881, 119, 167),
    bracken = box(899, 933, 128, 99), bellflower = box(255, 971, 110, 99), crocus = box(149, 1001, 85, 76),
    pansy = box(310, 1128, 85, 76), dandelion = box(644, 1255, 94, 85),
    water_lily = box(434, 1031, 124, 110), three_sisters = box(110, 1085, 160, 140),
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
-- SCALES[id] (else ANIMAL_SCALE) times as big, so the small ones can be seen
-- and tapped. Their places are dealt on each visit, and the ones that fly may
-- be dealt any free place in the garden or the sky; the two that live in the
-- pond keep to their paths there (PATHS, top-left corners to hop or swim to).
Layout.ANIMAL_SCALE = 1.3
Layout.SCALES = { bee = 1.0, dragonfly = 1.0, butterfly = 1.1, moth = 1.1, frog = 1.0, koi = .85, fox = 1.1, peacock = 1.0 }
Layout.ANIMALS = {
    bee = box(0, 0, 110, 70), butterfly = box(0, 0, 80, 70), moth = box(0, 0, 80, 70), robin = box(0, 0, 110, 80),
    dragonfly = box(0, 0, 100, 64), ladybug = box(0, 0, 60, 50), snail = box(0, 0, 80, 56), hedgehog = box(0, 0, 110, 64),
    fox = box(0, 0, 130, 76), peacock = box(0, 0, 150, 86), frog = box(0, 0, 70, 60), koi = box(0, 0, 100, 56),
}
Layout.FLIES = { bee = true, butterfly = true, moth = true, dragonfly = true }
Layout.PATHS = {
    frog = { { 560, 1048 }, { 586, 1058 }, { 610, 1070 } },
    koi = { { 526, 1150 }, { 504, 1142 }, { 550, 1142 }, { 538, 1146 } },
}
Layout.HIT = 90   -- the least a box to tap may be on a side

-- The free spots the animals that walk are dealt: large, medium and small,
-- so any of them fits at least one kind. Tapping a spot taps the animal in it.
Layout.SPOTS = {
    { x = 827, y = 1087, w = 200, h = 120 },
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
    local size, k = Layout.ANIMALS[id], Layout.SCALES[id] or Layout.ANIMAL_SCALE
    return { w = math.floor(size.w * k + .5), h = math.floor(size.h * k + .5) }
end

-- A box to tap that is at least HIT on a side, centred on `b`.
local function hitOf(b)
    local hw, hh = math.max(b.w, Layout.HIT), math.max(b.h, Layout.HIT)
    return box(b.x + (b.w - hw) / 2, b.y + (b.h - hh) / 2, hw, hh)
end

-- The animal of a pond path at its `i`th place: a box with `hit`.
function Layout.waypoint(id, i)
    local path, size = Layout.PATHS[id], Layout.shown(id)
    local p = path[(i - 1) % #path + 1]
    local b = box(p[1], p[2], size.w, size.h)
    b.hit = hitOf(b)
    return b
end

-- Do two boxes overlap?
local function overlap(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

-- The boxes that stay where they are (everything but the animals), for a
-- canvas `vh` tall, by name: plants, props, extras, the heading and the
-- corners. The pond and its lily are left out, its dwellers stand in for them, and the
-- trellis counts only as its two posts and its top: the sky shows through
-- the arch.
function Layout.static(vh)
    local out = {}
    for _kind, set in ipairs({ Layout.PLANTS, Layout.PROPS, Layout.EXTRAS }) do
        for id, b in pairs(set) do out[id] = Layout.at(b, vh) end
    end
    out.pond, out.ivy, out.water_lily = nil, nil, nil
    local ivy = Layout.PLANTS.ivy
    out.ivy_left = Layout.at(box(ivy.x, ivy.y + 80, 70, ivy.h - 80), vh)
    out.ivy_right = Layout.at(box(ivy.x + ivy.w - 70, ivy.y + 80, 70, ivy.h - 80), vh)
    out.ivy_top = Layout.at(box(ivy.x, ivy.y, ivy.w, 80), vh)
    for id, b in pairs(Layout.RESERVED) do out[id] = b end
    for i, b in ipairs(Layout.CORNERS_BELOW) do out["corner_b" .. i] = box(b.x, vh + b.y, b.w, b.h) end
    return out
end

-- A free place for an animal that flies: anywhere in the garden or the sky
-- that overlaps nothing in `taken` (a list of boxes), or nil.
local function sky(rand, size, taken)
    local hit = hitOf(box(0, 0, size.w, size.h))
    for _try = 1, 3000 do
        local x, y = 44 + rand() * (984 - hit.w), 128 + rand() * (1340 - hit.h - 128)
        local b = box(math.floor(x), math.floor(y), hit.w, hit.h)
        local clear = true
        for _i, t in ipairs(taken) do
            if overlap(b, { x = t.x - 6, y = t.y - 6, w = t.w + 12, h = t.h + 12 }) then clear = false; break end
        end
        if clear then return b end
    end
end

-- Where each animal stands on one visit: { id = box with `flip` and `hit` (the
-- box to tap) }. The two in the pond start on their paths. The ones that walk
-- are dealt a spot each, the biggest first, and a place inside it. The ones
-- that fly go anywhere free. Each faces either way.
function Layout.spread(seed)
    local rand = rng(seed or 1)
    local out, walkers, flyers = {}, {}, {}
    for id in pairs(Layout.ANIMALS) do
        if Layout.PATHS[id] then
            out[id] = Layout.waypoint(id, 1)
            out[id].flip = rand() < .5
        elseif Layout.FLIES[id] then
            flyers[#flyers + 1] = id
        else
            walkers[#walkers + 1] = { id = id, size = Layout.shown(id) }
        end
    end
    table.sort(walkers, function(a, b)
        local sa, sb = a.size.w * a.size.h, b.size.w * b.size.h
        if sa ~= sb then return sa > sb end
        return a.id < b.id
    end)
    table.sort(flyers)
    local free = {}
    for i, s in ipairs(Layout.SPOTS) do free[i] = s end
    local taken = { box(Layout.PROPS.pond.x, Layout.PROPS.pond.y, Layout.PROPS.pond.w, Layout.PROPS.pond.h) }
    for _id, b in pairs(Layout.static(Layout.HEIGHT)) do taken[#taken + 1] = b end
    for _i, r in ipairs(walkers) do
        local options = {}
        for j, s in ipairs(free) do
            if fits(s, r.size) then options[#options + 1] = j end
        end
        local s = table.remove(free, options[1 + math.floor(rand() * #options)])
        out[r.id] = box(s.x + math.floor((s.w - r.size.w) * rand()), s.y + math.floor((s.h - r.size.h) * rand()), r.size.w, r.size.h)
        out[r.id].hit = box(s.x, s.y, s.w, s.h)
        out[r.id].flip = rand() < .5
        taken[#taken + 1] = out[r.id].hit
    end
    for _i, id in ipairs(flyers) do
        local size = Layout.shown(id)
        local hit = sky(rand, size, taken) or table.remove(free, 1) or box(44, 128, Layout.HIT, Layout.HIT)
        out[id] = box(hit.x + math.floor((hit.w - size.w) / 2), hit.y + math.floor((hit.h - size.h) / 2), size.w, size.h)
        out[id].hit = box(hit.x, hit.y, hit.w, hit.h)
        out[id].flip = rand() < .5
        taken[#taken + 1] = out[id].hit
    end
    return out
end

-- The size of the small face that peeks out of the grass in the game of
-- spot the visitor (see State.peek).
Layout.PEEK = { w = 64, h = 52 }

-- Where the face peeks out on this visit: a free place on the lawn, away
-- from everything else on the poster (the plants, the props and the animals
-- as dealt by `spread`). A box with `hit` for tapping; nil when no free place
-- is found.
function Layout.peek(seed, spread)
    local rand = rng((seed or 1) + 4242)
    local hit = hitOf(box(0, 0, Layout.PEEK.w, Layout.PEEK.h))
    local others = Layout.all(Layout.HEIGHT, spread)
    others.pond = Layout.PROPS.pond
    -- the same test for a box on the lawn; a face centred in it when it is clear
    local function clear(b)
        for _id, o in pairs(others) do
            if overlap(b, o) then return nil end
        end
        local face = box(b.x + math.floor((hit.w - Layout.PEEK.w) / 2), b.y + math.floor((hit.h - Layout.PEEK.h) / 2), Layout.PEEK.w, Layout.PEEK.h)
        face.hit = box(b.x, b.y, hit.w, hit.h)
        return face
    end
    for _try = 1, 200 do
        local s = Layout.SPOTS[1 + math.floor(rand() * #Layout.SPOTS)]
        local face = clear(box(s.x + math.floor(rand() * math.max(0, s.w - hit.w)), s.y + math.floor(rand() * math.max(0, s.h - hit.h)), hit.w, hit.h))
        if face then return face end
    end
    -- none by chance: walk the lawn in steps from a random place
    local STEP = 10
    local cols, rows = math.floor((984 - hit.w - 44) / STEP), math.floor((1330 - Layout.LAWN_TOP - 10 - hit.h) / STEP)
    local start = math.floor(rand() * cols * rows)
    for i = 0, cols * rows - 1 do
        local k = (start + i) % (cols * rows)
        local face = clear(box(44 + (k % cols) * STEP, Layout.LAWN_TOP + 10 + math.floor(k / cols) * STEP, hit.w, hit.h))
        if face then return face end
    end
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

-- Every box with a name, for checks: everything of Layout.static and the
-- animals as dealt by `spread` (the place they are tapped at counts too),
-- laid out for a canvas `vh` tall.
function Layout.all(vh, spread)
    local out = Layout.static(vh)
    for id, b in pairs(spread or Layout.spread(1)) do out[id] = Layout.at(b.hit or b, vh) end
    return out
end

return Layout
