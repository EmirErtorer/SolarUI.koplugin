-- The few SVG pieces every drawing is made of, kept to what KOReader's SVG
-- renderer draws: paths, circles and ellipses with flat fills and outlines,
-- and groups that move, turn and scale. Everything returns SVG text.

local Svg = {}

local sin, cos, rad, sqrt, pi = math.sin, math.cos, math.rad, math.sqrt, math.pi

-- A number as SVG wants it: one decimal, no trailing zero.
local function n(v)
    local s = string.format("%.1f", v)
    return (s:gsub("%.0$", ""))
end
Svg.n = n

-- The point `r` away from (cx, cy) at `deg` degrees (0 is up, clockwise).
function Svg.pol(r, deg, cx, cy)
    local a = rad(deg)
    return (cx or 0) + r * sin(a), (cy or 0) - r * cos(a)
end

-- "x y" for a path.
local function xy(x, y)
    return n(x) .. " " .. n(y)
end
Svg.xy = xy

-- The outline attributes of a shape.
local function outline(stroke, sw)
    if not stroke then return "" end
    return string.format(' stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"', stroke, n(sw or 2))
end

-- A path with a fill (none when nil) and an optional outline.
function Svg.path(d, fill, stroke, sw)
    return string.format('<path d="%s" fill="%s"%s/>', d, fill or "none", outline(stroke, sw))
end

-- An open line.
function Svg.line(d, stroke, sw)
    return Svg.path(d, nil, stroke, sw or 2)
end

-- A circle.
function Svg.circle(cx, cy, r, fill, stroke, sw)
    return string.format('<circle cx="%s" cy="%s" r="%s" fill="%s"%s/>', n(cx), n(cy), n(r), fill or "none", outline(stroke, sw))
end

-- An ellipse turned by `rot` degrees about its centre.
function Svg.ellipse(cx, cy, rx, ry, rot, fill, stroke, sw)
    local turn = (rot and rot ~= 0) and string.format(' transform="rotate(%s %s %s)"', n(rot), n(cx), n(cy)) or ""
    return string.format('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"%s%s/>', n(cx), n(cy), n(rx), n(ry), fill or "none",
        outline(stroke, sw), turn)
end

-- A ring of dots: `count` of them, `size` across, on a circle.
function Svg.dots(cx, cy, r, count, size, fill)
    local out = {}
    for i = 0, count - 1 do
        local x, y = Svg.pol(r, i * 360 / count, cx, cy)
        out[#out + 1] = Svg.circle(x, y, size / 2, fill)
    end
    return table.concat(out)
end

-- `body` moved to (x, y), turned by `rot` degrees and scaled.
function Svg.group(x, y, rot, body, sx, sy)
    local t = string.format("translate(%s %s)", n(x), n(y))
    if rot and rot ~= 0 then t = t .. string.format(" rotate(%s)", n(rot)) end
    if sx then t = t .. string.format(" scale(%s %s)", n(sx), n(sy or sx)) end
    return string.format('<g transform="%s">%s</g>', t, body)
end

-- A smooth curve through the given points { {x, y}, ... } as a list of
-- points, `steps` to each stretch (a Catmull-Rom spline).
function Svg.spline(way, steps)
    steps = steps or 10
    local pts = {}
    local count = #way
    for i = 1, count - 1 do
        local p0, p1, p2, p3 = way[math.max(1, i - 1)], way[i], way[i + 1], way[math.min(count, i + 2)]
        for s = 0, steps - 1 do
            local t = s / steps
            local t2, t3 = t * t, t * t * t
            pts[#pts + 1] = {
                0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3),
                0.5 * ((2 * p1[2]) + (-p0[2] + p2[2]) * t + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t2 + (-p0[2] + 3 * p1[2] - 3 * p2[2] + p3[2]) * t3),
            }
        end
    end
    pts[#pts + 1] = { way[count][1], way[count][2] }
    return pts
end

-- The points of a spiral winding in from radius r0 at angle a0 (0 is up),
-- clockwise unless `ccw`.
function Svg.spiral(cx, cy, r0, turns, a0, ccw)
    local pts = {}
    local steps = 30
    local total = math.floor(steps * turns)
    for i = 0, total do
        local t = i / steps
        local r = r0 * (1 - t / (turns + 0.22))
        local x, y = Svg.pol(r, a0 + (ccw and -360 or 360) * t, cx, cy)
        pts[#pts + 1] = { x, y }
    end
    return pts
end

-- Two point lists joined into one.
function Svg.join(a, b)
    local out = {}
    for i = 1, #a do out[#out + 1] = a[i] end
    for i = 1, #b do out[#out + 1] = b[i] end
    return out
end

-- The path through a list of points with straight pieces.
function Svg.poly(pts, closed)
    local parts = {}
    for i, p in ipairs(pts) do parts[i] = xy(p[1], p[2]) end
    return "M" .. table.concat(parts, " L") .. (closed and "Z" or "")
end

-- The outline of a stroke along `pts` whose width changes along the way:
-- `width` is a number, or a function of how far along (0 to 1).
function Svg.ribbon(pts, width)
    local left, right = {}, {}
    local count = #pts
    for i = 1, count do
        local a, b = pts[math.max(1, i - 1)], pts[math.min(count, i + 1)]
        local dx, dy = b[1] - a[1], b[2] - a[2]
        local len = sqrt(dx * dx + dy * dy)
        if len == 0 then len = 1 end
        local t = (i - 1) / (count - 1)
        local half = (type(width) == "function" and width(t) or width) / 2
        local nx, ny = -dy / len * half, dx / len * half
        left[i] = xy(pts[i][1] + nx, pts[i][2] + ny)
        right[count - i + 1] = xy(pts[i][1] - nx, pts[i][2] - ny)
    end
    return "M" .. table.concat(left, " L") .. " L" .. table.concat(right, " L") .. "Z"
end

-- A width that runs evenly from w0 to w1.
function Svg.taper(w0, w1)
    return function(t) return w0 + (w1 - w0) * t end
end

-- A width that swells to `w` in the middle and thins to points: the whiplash line.
function Svg.swell(w, thin)
    thin = thin or 0.8
    return function(t) return thin + (w - thin) * sin(pi * t) ^ 0.8 end
end

-- Points along the curve from (x0, y0) to (x3, y3) with control points
-- (x1, y1) and (x2, y2).
function Svg.cubic(x0, y0, x1, y1, x2, y2, x3, y3, steps)
    local pts = {}
    for i = 0, steps do
        local t = i / steps
        local u = 1 - t
        pts[#pts + 1] = {
            u * u * u * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x3,
            u * u * u * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y3,
        }
    end
    return pts
end

-- Where a list of points is `dist` along, with the direction there in
-- degrees for a group's rotate (0 points right).
function Svg.along(pts, dist)
    local run = 0
    for i = 2, #pts do
        local a, b = pts[i - 1], pts[i]
        local dx, dy = b[1] - a[1], b[2] - a[2]
        local len = sqrt(dx * dx + dy * dy)
        if run + len >= dist and len > 0 then
            local t = (dist - run) / len
            return a[1] + dx * t, a[2] + dy * t, math.deg(math.atan2(dy, dx))
        end
        run = run + len
    end
    local last, before = pts[#pts], pts[#pts - 1]
    return last[1], last[2], math.deg(math.atan2(last[2] - before[2], last[1] - before[1]))
end

-- The length of a list of points.
function Svg.length(pts)
    local run = 0
    for i = 2, #pts do
        local dx, dy = pts[i][1] - pts[i - 1][1], pts[i][2] - pts[i - 1][2]
        run = run + sqrt(dx * dx + dy * dy)
    end
    return run
end

-- A stem along `pts`: filled, with an ink outline, its width changing as given.
function Svg.stem(pts, width, fill, ink, ow)
    return Svg.path(Svg.ribbon(pts, width), fill, ink, ow or 1.6)
end

-- The whole drawing: a `vw` by `vh` canvas holding `body`.
function Svg.document(vw, vh, body)
    return string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">%s</svg>',
        n(vw), n(vh), n(vw), n(vh), body)
end

-- A fixed number from 0 to 1 for index `i` (and a `salt` to tell uses apart):
-- the same unevenness every time a plant is drawn.
function Svg.vary(i, salt)
    local v = sin(i * 12.9898 + (salt or 0) * 78.233) * 43758.5453
    return v - math.floor(v)
end

-- cos and sin of an angle in degrees (0 is up, clockwise), for drawings that
-- place many points.
function Svg.dir(deg)
    local a = rad(deg)
    return sin(a), -cos(a)
end

return Svg
