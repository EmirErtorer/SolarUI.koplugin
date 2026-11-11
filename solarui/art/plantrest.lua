-- The winter form of a plant that has died back, in the plant bed's units
-- (origin at the foot, y up as negative): stems cut to short dry stubs with
-- a seed head left on some for the birds, dead strap leaves lying over the
-- earth, a small heap of fallen leaves, all touched with hoarfrost. A plant
-- describes its form with a spec and Rest.form turns it into its `rest`
-- drawing for plantkit's Kit.sprite.

local Flora = require("solarui/art/flora")
local Kit = require("solarui/art/plantkit")
local Season = require("solarui/art/plantseason")
local Svg = require("solarui/art/svg")

local group = Svg.group
local sin, cos, rad = math.sin, math.cos, math.rad

local Rest = {}

-- The plant `p` with its colours dried: greens and flowers turned to straw
-- and the browns of dead leaves, for seed heads left standing.
function Rest.dry(p)
    local c = p.c
    local d = {}
    for role, hex in pairs(c) do d[role] = hex end
    d.leaf, d.sage, d.stem, d.bloom, d.bloom2 = c.dead, c.straw, c.straw, c.rust, c.dead
    d.pale, d.gold, d.sky, d.glass = c.straw, c.dead, c.straw, c.dead
    return { c = d, st = p.st, wilt = false, W = p.W, H = p.H, season = p.season }
end

-- How much of a stub's height is left at the plant's stage: a young plant has less to cut back.
local function grown(p)
    return ({ 1, .55, .8, 1, 1 })[p.st]
end

-- A stub from (x, 0) rising `h` and leaning `lean` across, `w` wide, with its
-- cut face showing on top unless something is to sit there; gives the stub
-- and where its top is with its heading.
function Rest.stub(p, x, h, lean, w, capped)
    local c = p.c
    local pts = Svg.spline({ { x, -2 }, { x + lean * .3, -h * .55 }, { x + lean, -h } }, 6)
    local tx, ty, ang = Kit.on(pts, 1)
    local out = Svg.stem(pts, Svg.taper(w, w * .82), c.straw, c.ink, 1.3)
    if not capped then out = out .. Svg.ellipse(tx, ty, w * .5, w * .2, ang + 90, c.pale, c.ink, 1) end
    return out, tx, ty, ang
end

-- A dead leaf lying on the earth at (x, y), `L` long, its tip curling up.
function Rest.fallen(p, x, y, rot, L, i)
    local c = p.c
    local fill = ({ c.dead, c.rust, c.straw })[i % 3 + 1]
    return Flora.leaf(c, x, y, rot, L, L * .26, fill, L < 16)
end

-- A small heap of fallen leaves `w` across over the foot of the plant, with frost on its crown.
function Rest.heap(p, w, count)
    local out, rim = "", {}
    for k = 1, count do
        local a = -78 + 156 * (k - 1) / math.max(1, count - 1) + 10 * (Svg.vary(k, 11) - .5)
        local L = w * (.5 + .16 * Svg.vary(k, 12))
        out = out .. group(0, -3, 0, Rest.fallen(p, sin(rad(a)) * w * .1, 0, a - 90, L, k), 1, .56)
    end
    for k = 1, count - 1 do
        local a = -60 + 120 * (k - 1) / math.max(1, count - 2)
        out = out .. group(0, -5, 0, Rest.fallen(p, sin(rad(a)) * w * .08, 0, a - 90, w * .4, k + 1), 1, .7)
    end
    for k = 0, 8 do
        local a = rad(-70 + k * 17.5)
        rim[#rim + 1] = { sin(a) * w * .36, -5 - cos(a) * w * .3 }
    end
    return out .. Season.rime(p.c, rim)
end

-- A dead strap leaf lying over the earth from the foot: it sets off at
-- `heading` and bends down to rest on the ground.
function Rest.strap(p, heading, L, W, i)
    local c = p.c
    local side = heading < 0 and -1 or 1
    return Kit.blade({ c = c }, side * 2, -2, heading, L, W, side * (100 - math.abs(heading)), ({ c.dead, c.straw, c.rust })[i % 3 + 1], c.ink)
end

-- The `rest` drawing of a plant from its spec: { w (width of its earth),
-- stubs = { { x, h, lean, width }, ... }, head = function(dry plant, i, plant) drawing
-- a dry seed head standing on the origin, heads = { indices of the stubs that
-- keep one }, straps = { { heading, L, W }, ... }, heap = { w, count },
-- litter = count of dead leaves round the foot, extra = function(p, dry) }.
function Rest.form(spec)
    return function(p)
        local k = grown(p)
        local dry = Rest.dry(p)
        local out = Kit.soil(p, spec.w * (k < 1 and .8 or 1))
        for i = 1, spec.litter or 0 do
            local side = i % 2 == 0 and 1 or -1
            out = out .. Rest.fallen(p, side * spec.w * (.14 + .1 * Svg.vary(i, 3)), -2 - 2 * Svg.vary(i, 4), side > 0 and -6 - 10 * Svg.vary(i, 5) or 186 + 10 * Svg.vary(i, 5), 13 + 5 * Svg.vary(i, 6), i)
        end
        for i, s in ipairs(spec.straps or {}) do out = out .. Rest.strap(p, s[1], s[2] * k, s[3], i) end
        if spec.heap then out = out .. Rest.heap(p, spec.heap[1] * k, spec.heap[2]) end
        local heads = {}
        for _i, h in ipairs(spec.heads or {}) do heads[h] = true end
        local tops = ""
        for i, s in ipairs(spec.stubs or {}) do
            local stub, tx, ty, ang = Rest.stub(p, s[1] * k, s[2] * k, s[3] * k, s[4] or 4, heads[i])
            out = out .. stub
            if heads[i] then tops = tops .. group(tx, ty, ang + 90, spec.head(dry, i, p), k < 1 and .8 or 1) end
        end
        if spec.extra then out = out .. spec.extra(p, dry) end
        return out .. tops
    end
end

return Rest
