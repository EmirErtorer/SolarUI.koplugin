-- The shape every book cover is cut to, an Art Nouveau window: upright
-- sides under a soft pointed arch, the foot's corners gently rounded. The
-- solid shape (what of a cover shows), a blank sheet of that shape and the
-- border drawn over a cover. Each is function(c, vw, vh) returning SVG for
-- a vw x vh canvas.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n = Svg.n

local Frames = {}

-- How far down a w x h window its arch ends and its sides begin.
function Frames.rise(w, h)
    return math.min(w * .36, h * .26)
end

-- The window's outline on a vw x vh canvas, `i` units inside its edge.
local function window(vw, vh, i)
    local function p(x, y) return n(x) .. " " .. n(y) end
    local l, r, t, b, m = i, vw - i, i, vh - i, vw / 2
    local spring = Frames.rise(vw, vh) + i * .4
    local rb = math.min(vw, vh) * .07
    return string.format("M%s C%s %s %s C%s %s %s L%s Q%s %s L%s Q%s %sZ",
        p(l, spring), p(l, spring * .4 + t * .6), p(m - (r - l) * .3, t), p(m, t),
        p(m + (r - l) * .3, t), p(r, spring * .4 + t * .6), p(r, spring),
        p(r, b - rb), p(r, b), p(r - rb, b), p(l + rb, b), p(l, b), p(l, b - rb))
end

-- The solid window: only where it is solid matters.
function Frames.cover_shape(c, vw, vh)
    return Svg.path(window(vw, vh, .4), c.ink)
end

-- A blank sheet of the window's shape (the pages behind a folder's cover).
function Frames.cover_sheet(c, vw, vh)
    return Svg.path(window(vw, vh, 1.6), c.bg, c.ink, 2.4)
end

-- The border over a cover: an ink outline, a fine golden line inside it on
-- all but the smallest, and on a large one a bead between two leaves under
-- the crown of the arch.
function Frames.cover_border(c, vw, vh)
    local out = ""
    if vw >= 70 then
        local inset = vw >= 150 and 8 or 5.5
        out = Svg.line(window(vw, vh, inset), c.gold, vw >= 150 and 1.8 or 1.3)
    end
    out = out .. Svg.line(window(vw, vh, 1.8), c.ink, vw >= 70 and 3.2 or 2.4)
    if vw >= 150 then
        local m = vw / 2
        out = out .. Flora.leaf(c, m - 6, 9, 170, vw * .1, vw * .03, nil, true) .. Flora.leaf(c, m + 6, 9, 10, vw * .1, vw * .03, nil, true)
            .. Svg.circle(m, 8, 7, c.gold, c.ink, 1.5)
    end
    return out
end

return Frames
