-- The vine along the garden's frame: a leaf for each day read, flowers after
-- every thirty. The param is "leaves:flowers" (see garden/progress.lua).
-- Drawn over the whole poster, along the margin between the frame's two
-- rules: the vine comes out from behind the bottom-left corner ornament,
-- runs along the foot, up the right side, back along the top and down the
-- left side, passing behind each corner ornament and under the bud in the
-- middle of the foot. Thirty leaves take it all the way round; once it has
-- flowered, the days of the next thirty show as small new leaves.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local group = Svg.group

local Vine = {}

local LEAVES = 30   -- leaves of a vine grown all the way round
local EDGE = 18.5     -- how far the stem runs in from the poster's edge, between the two rules
local CORNER = 72   -- how far from each corner the stem hides behind the corner ornament
local START = 30    -- the length of stem before the first leaf
local BUD = 46      -- half the width of the gap left for the bud in the middle of the foot

-- The four runs of the stem round a vw x vh poster, each a list of points
-- with a gentle wave, in the order the vine grows along them.
local function runs(vw, vh)
    local sides = {
        { CORNER, vh - EDGE, vw - CORNER, vh - EDGE },
        { vw - EDGE, vh - CORNER, vw - EDGE, CORNER },
        { vw - CORNER, EDGE, CORNER, EDGE },
        { EDGE, CORNER, EDGE, vh - CORNER },
    }
    local out = {}
    for i, s in ipairs(sides) do
        local dx, dy = s[3] - s[1], s[4] - s[2]
        local len = math.sqrt(dx * dx + dy * dy)
        local steps = math.ceil(len / 6)
        local pts = {}
        for k = 0, steps do
            local t = k / steps
            local wave = 1.4 * math.sin(t * len / 58 * 2 * math.pi + i)
            pts[k + 1] = { s[1] + dx * t + dy / len * wave, s[2] + dy * t - dx / len * wave }
        end
        out[i] = { pts = pts, len = Svg.length(pts) }
    end
    return out
end

-- Where the vine is `d` along its runs: the run's number, x, y and the heading there.
local function at(all, d)
    for i, r in ipairs(all) do
        if d <= r.len or i == #all then
            local x, y, ang = Svg.along(r.pts, math.min(d, r.len))
            return i, x, y, ang
        end
        d = d - r.len
    end
end

-- Whether a point on the foot is under the bud in its middle, where nothing may grow inwards.
local function underBud(vw, run, x)
    return run == 1 and math.abs(x - vw / 2) < BUD
end

-- The stem grown `grown` along the runs, an inked green band thinning towards the tip.
local function stem(c, all, grown)
    local out = ""
    for _i, r in ipairs(all) do
        if grown <= 0 then break end
        local part = Svg.head(r.pts, math.min(grown, r.len))
        if #part > 1 then out = out .. Svg.stem(part, 3, c.leaf, c.ink, 1.1) end
        grown = grown - r.len
    end
    return out
end

-- A small leaf on the stem at distance `d`, leaning inwards or outwards from the way it grows.
local function leaf(c, vw, all, d, inward, L, fill)
    local run, x, y, ang = at(all, d)
    if underBud(vw, run, x) then inward = false end
    return Flora.leaf(c, x, y, ang + (inward and -22 or 22), L, L * .28, fill, true)
end

-- A tiny curl of tendril at distance `d`, on one side of the stem.
local function curl(c, all, d, side)
    local _run, x, y, ang = at(all, d)
    local pts = Svg.join(Svg.spline({ { 0, 0 }, { 4, -side * 2.6 }, { 9, -side * 4 } }, 4), Svg.spiral(9, -side * 7.6, 3.6, 1.4, side > 0 and 180 or 0, side > 0))
    return group(x, y, ang, Svg.path(Svg.ribbon(pts, Svg.taper(1.8, .7)), c.stem))
end

-- A small open flower on the stem at distance `d`.
local function flower(c, all, d, k)
    local _run, x, y = at(all, d)
    local fill = k % 2 == 0 and c.bloom2 or c.bloom
    return Flora.around(x, y, 0, 5, Flora.petal(c, 7.4, 3.8, fill, 1), k * 17) .. Svg.circle(x, y, 2.6, c.gold, c.ink, .9)
end

-- The node of each flower among the thirty leaves: spread evenly, none under the bud.
local function flowerNodes(vw, all, count, step)
    local nodes, used = {}, {}
    for j = 1, math.min(count, LEAVES) do
        local k = math.max(1, math.min(LEAVES, math.floor((j - .5) * LEAVES / math.min(count, LEAVES)) + 1))
        local tries = 0
        while tries < LEAVES do
            local run, x = at(all, START + (k - .5) * step)
            if not used[k] and not underBud(vw, run, x) then break end
            k, tries = k % LEAVES + 1, tries + 1
        end
        used[k] = true
        nodes[#nodes + 1] = k
    end
    return nodes
end

-- The vine for the param "leaves:flowers".
function Vine.garden_vine(c, vw, vh, param)
    local leaves, flowers = tostring(param or ""):match("^(%d+):?(%d*)")
    leaves, flowers = math.min(LEAVES, tonumber(leaves) or 0), tonumber(flowers) or 0
    local all = runs(vw, vh)
    local total = 0
    for _i, r in ipairs(all) do total = total + r.len end
    local step = (total - START) / LEAVES
    local full = flowers > 0
    local grown = full and total or START + leaves * step
    local out = { stem(c, all, grown) }
    for k = 1, full and LEAVES or leaves do
        local d = START + (k - .5) * step
        out[#out + 1] = leaf(c, vw, all, d, k % 2 == 1, 17, k % 3 == 0 and c.sage or c.leaf)
        if full and k <= leaves then out[#out + 1] = leaf(c, vw, all, d + 5, k % 2 == 0, 9, c.sage) end
        local run, x = at(all, d + step * .5)
        if (k < LEAVES or full) and not underBud(vw, run, x) then out[#out + 1] = curl(c, all, d + step * .5, k % 2 == 0 and 1 or -1) end
    end
    if full then
        for j, k in ipairs(flowerNodes(vw, all, flowers, step)) do out[#out + 1] = flower(c, all, START + (k - .5) * step, j) end
    else
        local _run, x, y, ang = at(all, grown)
        out[#out + 1] = Flora.tendril(c, x, y, ang + 90, 13, true)
    end
    return table.concat(out)
end

return Vine
