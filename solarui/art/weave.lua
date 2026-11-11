-- The woven band of two vines that runs round the garden's round dials:
-- the clock's face and the season wheel. Returns SVG text.

local Svg = require("solarui/art/svg")

local path, circle = Svg.path, Svg.circle

local Weave = {}

-- A band `w` wide along `pts`, filled and edged in ink `o` wide, with no seam where two pieces of it meet.
function Weave.band(c, pts, w, fill, o)
    return path(Svg.ribbon(pts, w + 2 * o), c.ink) .. path(Svg.ribbon(pts, w), fill)
end

-- Two vines woven round a ring of radius `r`, crossing `2k` times over and under in turn, a berry in each loop.
function Weave.ring(c, cx, cy, r, a, k, w)
    -- One vine from angle `from` to `to`, on the outer side of the ring first when `s` is 1.
    local function vine(s, from, to)
        local pts = {}
        for d = from, to, .5 do
            local x, y = Svg.pol(r + s * a * math.sin(math.rad(d * k)), d, cx, cy)
            pts[#pts + 1] = { x, y }
        end
        return Weave.band(c, pts, w, c.leaf, w * .32)
    end
    local out = vine(-1, 0, 360) .. vine(1, 0, 360)
    local step = 180 / k
    for m = 1, 2 * k, 2 do out = out .. vine(-1, m * step - step * .35, m * step + step * .35) end
    for m = 0, 2 * k - 1 do
        local x, y = Svg.pol(r, (m + .5) * step, cx, cy)
        out = out .. circle(x, y, w * .62, m % 2 == 0 and c.bloom or c.gold, c.ink, w * .3)
    end
    return out
end

return Weave
