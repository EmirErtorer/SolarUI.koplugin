-- The feather pen of the Ink Away button: a plume with a curved shaft, a
-- vane on both sides split here and there between the barbs, the bare quill
-- below cut to a nib, and the ink the nib leaves behind.

local Svg = require("solarui/art/svg")

local n = Svg.n
local sin, cos, rad = math.sin, math.cos, math.rad

local Quill = {}

-- How far along the vane the barbs part, on the left and on the right.
local SPLITS = { [-1] = { .28, .56 }, [1] = { .2, .46, .68 } }
-- The same for a small pen, which has room for fewer.
local FEW = { [-1] = { .42 }, [1] = { .28, .6 } }
local LEAN = 48      -- the angle of a barb to the shaft
local GAP = .032      -- how far a split stands open, as a part of the vane

-- How wide the vane is `s` of the way from its base to its tip (0 to 1).
local function breadth(s)
    local rise = 1 - (1 - math.min(1, s / .34)) ^ 2
    return (.3 + .7 * rise) * (1 - s ^ 2.3)
end

-- The point `s` of the way up the vane's shaft with the way a barb leaves
-- there on `side` (-1 left, 1 right): x, y, dx, dy.
local function barb(shaft, len, s, side)
    local x, y, ang = Svg.along(shaft, len * s)
    local a = rad(ang + side * LEAN)
    return x, y, cos(a), sin(a)
end

-- One side of the vane from base to tip as a list of points, `W` at its
-- widest. With `split` (SPLITS or FEW) the barbs part here and there: the edge runs out to a
-- point, cuts in along a barb and starts again with a rounded corner.
local function edge(shaft, len, side, W, split)
    local pts, cuts, at = {}, split and split[side] or {}, 1
    local s, step, from = 0, .0125, nil
    while s <= 1.0001 do
        local x, y, dx, dy = barb(shaft, len, s, side)
        local w = W * breadth(s)
        if from then w = w * (1 - .1 * math.max(0, 1 - (s - from) / .04) ^ 2) end
        pts[#pts + 1] = { x + dx * w, y + dy * w }
        if cuts[at] and s + step > cuts[at] then
            local cut = cuts[at]
            x, y, dx, dy = barb(shaft, len, cut, side)
            w = W * breadth(cut)
            pts[#pts + 1] = { x + dx * w * 1.03, y + dy * w * 1.03 }
            pts[#pts + 1] = { x + dx * w * .5, y + dy * w * .5 }
            s, at, from = cut + GAP, at + 1, cut + GAP
        else
            s = s + step
        end
    end
    return pts
end

-- The barbs drawn on one side of the vane: fine lines from the shaft out,
-- `count` of them, every other one shorter.
local function barbs(shaft, len, side, W, ink, count)
    local d = {}
    for i = 1, count do
        local s = i / (count + 1) - (side == 1 and .04 or 0)
        local x, y, dx, dy = barb(shaft, len, s, side)
        local w = W * breadth(s) * (i % 2 == 0 and .78 or .56)
        d[#d + 1] = string.format("M%s %s L%s %s", n(x), n(y), n(x + dx * w), n(y + dy * w))
    end
    return Svg.line(table.concat(d, " "), ink, .9)
end

-- The vane: both sides in `fill` with a lighter band of `band` along the
-- shaft, the outline and `count` barbs a side in ink.
local function vane(c, shaft, W, fill, band, count)
    local split = count < 9 and FEW or SPLITS
    local len = Svg.length(shaft)
    local left, right = edge(shaft, len, -1, W * .92, split), edge(shaft, len, 1, W, split)
    local inner_l, inner_r = edge(shaft, len, -1, W * .4), edge(shaft, len, 1, W * .46)
    local function closed(a, b)
        local out = Svg.join({ shaft[1] }, a)
        for i = #b, 1, -1 do out[#out + 1] = b[i] end
        return Svg.poly(out, true)
    end
    return Svg.path(closed(left, right), fill, c.ink, 1.9)
        .. Svg.path(closed(inner_l, inner_r), band)
        .. barbs(shaft, len, -1, W * .92, c.ink, count) .. barbs(shaft, len, 1, W, c.ink, count)
end

-- The loose down at the foot of the vane: three little curls a side.
local function down(c, x, y, ang, r)
    local d = {}
    for _i, side in ipairs({ -1, 1 }) do
        for k = 0, 2 do
            local a = rad(ang + side * (62 + k * 26))
            local px, py = x - cos(rad(ang)) * r * k * .3, y - sin(rad(ang)) * r * k * .3
            local ex, ey = px + cos(a) * r * (1 - k * .16), py + sin(a) * r * (1 - k * .16)
            d[#d + 1] = string.format("M%s %s Q%s %s %s %s", n(px), n(py), n((px + ex) / 2 + cos(rad(ang)) * r * .3), n((py + ey) / 2 + sin(rad(ang)) * r * .3), n(ex), n(ey))
        end
    end
    return Svg.line(table.concat(d, " "), c.ink, 1.3)
end

-- The cut nib at the end of the quill: the tip at (x, y), the quill coming
-- down to it heading `ang` degrees, `L` long and `W` wide where it joins.
local function nib(c, x, y, ang, L, W)
    local body = Svg.path(string.format("M%s %s C%s %s %s %s 0 0 C%s %s %s %s %s %sZ", n(-L), n(-W / 2), n(-L * .5), n(-W * .55), n(-L * .3), n(-W * .1),
        n(-L * .3), n(W * .1), n(-L * .5), n(W * .55), n(-L), n(W / 2)), c.gold, c.ink, 1.5)
        .. Svg.line(string.format("M%s 0 L%s 0", n(-L * .66), n(-L * .12)), c.ink, 1)
        .. Svg.circle(-L * .7, 0, W * .11, c.ink)
    return Svg.group(x, y, ang, body)
end

-- A drop of ink hanging point up, `r` its radius, centred on (x, y).
function Quill.drop(c, x, y, r)
    return Svg.path(string.format("M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %sZ", n(x), n(y - r * 2), n(x + r * .3), n(y - r), n(x + r), n(y - r * .5), n(x + r), n(y + r * .1),
        n(x + r), n(y + r * 1.2), n(x - r), n(y + r * 1.2), n(x - r), n(y + r * .1)) .. string.format(" C%s %s %s %s %s %sZ", n(x - r), n(y - r * .5), n(x - r * .3), n(y - r), n(x), n(y - r * 2)), c.ink)
end

-- The feather pen along `way` (points from the nib's tip up to the tip of
-- the plume), the vane `W` wide a side and starting `bare` of the way up.
-- `k` is the size of the pen against the full dock canvas (1 when it fills
-- one): a small pen keeps its bold outline, carries fewer barbs and has no
-- down.
function Quill.pen(c, way, W, bare, fill, band, k)
    k = k or 1
    local all = Svg.spline(way, 10)
    local len = Svg.length(all)
    local shaft = {}
    local x0, y0, a0 = Svg.along(all, len * bare)
    shaft[1] = { x0, y0 }
    local run = 0
    for i = 2, #all do
        run = run + Svg.length({ all[i - 1], all[i] })
        if run > len * bare then shaft[#shaft + 1] = all[i] end
    end
    local nx, ny, na = Svg.along(all, 0)
    local jx, jy = Svg.along(all, len * .1)
    local quill = Svg.join({ { jx, jy } }, {})
    run = 0
    for i = 2, #all do
        run = run + Svg.length({ all[i - 1], all[i] })
        if run > len * .1 then quill[#quill + 1] = all[i] end
    end
    return vane(c, shaft, W, fill, band, k < .7 and 5 or 9)
        .. (k < .7 and "" or down(c, x0, y0, a0, W * .34))
        .. Svg.stem(quill, function(t) return (4 * (1 - t) ^ .7 + 1) * (.4 + .6 * k) end, c.cream, c.ink, 1.4)
        .. nib(c, nx, ny, na + 180, len * .15, 7 * (.35 + .65 * k))
end

return Quill
