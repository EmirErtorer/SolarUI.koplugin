-- The line of the root every plant of the home dock grows from: a long runner
-- swaying between peaks and troughs. The dock draws it (art/dock.lua) and
-- stands each plant on it, so both need its points.

local Svg = require("solarui/art/svg")

local Rootline = {}

-- The smooth points of the runner on a vw x vh canvas.
function Rootline.points(vw, vh)
    local way = {}
    for i = 0, 8 do way[#way + 1] = { 6 + (vw - 12) * i / 8, vh * (i % 2 == 0 and .62 or .36) } end
    return Svg.spline(way, 10)
end

-- How far down the runner's middle is at x on a vw x vh canvas.
function Rootline.y(vw, vh, x)
    local pts = Rootline.points(vw, vh)
    for i = 2, #pts do
        local a, b = pts[i - 1], pts[i]
        if x <= b[1] then
            local t = b[1] > a[1] and (x - a[1]) / (b[1] - a[1]) or 0
            return a[2] + (b[2] - a[2]) * math.max(0, math.min(1, t))
        end
    end
    return pts[#pts][2]
end

return Rootline
