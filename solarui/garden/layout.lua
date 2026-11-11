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

-- Plants by id: three trees and the trellis along the back, the rest
-- scattered, the tall ones towards the back and the low ones in front.
Layout.PLANTS = {
    maple = box(34, 112, 262, 332), ivy = box(330, 120, 436, 332), ginkgo = box(776, 128, 262, 332),
    sunflower = box(47, 519, 136, 189), iris = box(218, 504, 120, 176), lily = box(369, 527, 128, 184),
    rose = box(662, 575, 144, 192), poppy = box(914, 601, 112, 176), chamomile = box(547, 861, 112, 160),
    tulip = box(45, 958, 112, 157), narcissus = box(51, 767, 104, 149), honesty = box(921, 1162, 96, 93),
    bracken = box(552, 1165, 120, 93), bellflower = box(175, 1033, 104, 93), crocus = box(441, 1272, 80, 72),
    pansy = box(550, 1271, 80, 72), dandelion = box(329, 1264, 88, 80),
    water_lily = box(722, 918, 136, 120),
}

-- Scenery: the pond (which holds the water lily, the frog and the koi), the
-- table with its chairs and the plaque for a favourite passage.
Layout.PROPS = {
    pond = box(698, 882, 330, 230), table = box(172, 785, 340, 220), plaque = box(318, 1139, 200, 100),
}
Layout.INSIDE_POND = { "water_lily", "frog", "koi" }

-- The small things of the lawn that cannot be tapped.
Layout.EXTRAS = {
    skep = box(829, 698, 64, 67), stones = box(543, 1054, 120, 64), birdbath = box(827, 595, 72, 69),
    lantern = box(721, 795, 35, 61), can = box(191, 1283, 83, 51), pots = box(224, 714, 67, 43),
}

-- The size of each animal (its x and y are dealt on each visit), and the two
-- that always stay in the pond.
Layout.ANIMALS = {
    bee = box(0, 0, 110, 70), butterfly = box(0, 0, 80, 70), moth = box(0, 0, 80, 70), robin = box(0, 0, 110, 80),
    dragonfly = box(0, 0, 100, 64), ladybug = box(0, 0, 60, 50), snail = box(0, 0, 80, 56), hedgehog = box(0, 0, 110, 64),
    fox = box(0, 0, 130, 76), peacock = box(0, 0, 150, 86), frog = box(0, 0, 70, 60), koi = box(0, 0, 100, 56),
}
Layout.FIXED = { frog = box(900, 938, 70, 60), koi = box(896, 1012, 100, 56) }

-- The free spots animals are dealt: three large, four medium and three
-- small, so any animal fits at least one kind.
Layout.SPOTS = {
    { x = 305, y = 1028, w = 150, h = 90 }, { x = 118, y = 1166, w = 150, h = 90 }, { x = 710, y = 1194, w = 150, h = 90 },
    { x = 523, y = 514, w = 110, h = 80 }, { x = 783, y = 784, w = 110, h = 80 }, { x = 888, y = 489, w = 110, h = 80 },
    { x = 525, y = 649, w = 110, h = 80 },
    { x = 675, y = 476, w = 80, h = 70 }, { x = 947, y = 798, w = 80, h = 70 }, { x = 541, y = 749, w = 80, h = 70 },
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
    return { x = b.x, y = math.floor(b.y * Layout.stretch(vh) + .5), w = b.w, h = b.h, flip = b.flip }
end

-- A random number generator from a seed (the same seed gives the same run).
local function rng(seed)
    local s = math.floor(seed) % 2147483646 + 1
    return function()
        s = s * 48271 % 2147483647
        return s / 2147483647
    end
end

-- Whether the box of size w x h fits in the spot.
local function fits(spot, size)
    return size.w <= spot.w and size.h <= spot.h
end

-- Where each animal stands on one visit: { id = box with `flip` }. The two
-- in the pond stay there; the others are dealt a spot each, the biggest
-- first, and a place inside it, and face either way.
function Layout.spread(seed)
    local rand = rng(seed or 1)
    local out = {}
    local roaming = {}
    for id, size in pairs(Layout.ANIMALS) do
        if Layout.FIXED[id] then
            out[id] = box(Layout.FIXED[id].x, Layout.FIXED[id].y, size.w, size.h)
            out[id].flip = rand() < .5
        else
            roaming[#roaming + 1] = id
        end
    end
    table.sort(roaming, function(a, b)
        local sa, sb = Layout.ANIMALS[a], Layout.ANIMALS[b]
        if sa.w * sa.h ~= sb.w * sb.h then return sa.w * sa.h > sb.w * sb.h end
        return a < b
    end)
    local free = {}
    for i, s in ipairs(Layout.SPOTS) do free[i] = s end
    for _i, id in ipairs(roaming) do
        local size, options = Layout.ANIMALS[id], {}
        for j, s in ipairs(free) do
            if fits(s, size) then options[#options + 1] = j end
        end
        local pick = table.remove(options, 1 + math.floor(rand() * #options))
        local s = table.remove(free, pick)
        out[id] = box(s.x + math.floor((s.w - size.w) * rand()), s.y + math.floor((s.h - size.h) * rand()), size.w, size.h)
        out[id].flip = rand() < .5
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
-- dealt by `spread`, the heading and the corners, laid out for a canvas `vh`
-- tall. The pond is left out (see INSIDE_POND), its dwellers stand in for it.
function Layout.all(vh, spread)
    local out = {}
    for _kind, set in ipairs({ Layout.PLANTS, Layout.PROPS, Layout.EXTRAS, spread or Layout.spread(1) }) do
        for id, b in pairs(set) do out[id] = Layout.at(b, vh) end
    end
    out.pond = nil
    for id, b in pairs(Layout.RESERVED) do out[id] = b end
    for i, b in ipairs(Layout.CORNERS_BELOW) do out["corner_b" .. i] = box(b.x, vh + b.y, b.w, b.h) end
    return out
end

return Layout
