-- Shape drawing for every widget, built only from KOReader's C rectangle fills
-- so it stays fast in any rotation: plain boxes and boxes with rounded
-- corners (a leaf has two of its corners rounded), their outlines, stripes,
-- lines and polygons. Colours come from the theme.

local Color = require("solarui/theme/color")

local Paint = {}

local floor = math.floor

-- Fill a rectangle with a theme colour (grey or RGB).
local function fill(bb, x, y, w, h, c)
    if w <= 0 or h <= 0 then return end
    if Color.isRGB(c) then bb:paintRectRGB32(x, y, w, h, c) else bb:paintRect(x, y, w, h, c) end
end
Paint.fill = fill

-- Outline a rectangle with lines `t` pixels thick.
function Paint.frame(bb, x, y, w, h, t, c)
    fill(bb, x, y, w, t, c)
    fill(bb, x, y + h - t, w, t, c)
    fill(bb, x, y + t, t, h - 2 * t, c)
    fill(bb, x + w - t, y + t, t, h - 2 * t, c)
end

-- Which corners are rounded: a string of t(op-left), r (top-right), b (bottom-right)
-- and l (bottom-left), e.g. "tb" for two opposite corners.
local function corners(spec)
    spec = spec or "trbl"
    return spec:find("t", 1, true) ~= nil, spec:find("r", 1, true) ~= nil,
        spec:find("b", 1, true) ~= nil, spec:find("l", 1, true) ~= nil
end

-- How far a rounded corner of radius r cuts into each of its rows.
local insets = {}
local function cornerInsets(r)
    local t = insets[r]
    if not t then
        t = {}
        for i = 0, r - 1 do
            local dy = r - i - 0.5
            t[i] = r - floor(math.sqrt(r * r - dy * dy) + 0.5)
        end
        insets[r] = t
    end
    return t
end

-- How far row `i` (from the top) of an h-tall box is cut on the left and on
-- the right by its rounded corners.
local function rowInsets(i, h, r, ins, tl, tr, br, bl)
    local l, rt = 0, 0
    if i < r then
        if tl then l = ins[i] end
        if tr then rt = ins[i] end
    end
    local j = h - 1 - i
    if j < r then
        if bl and ins[j] > l then l = ins[j] end
        if br and ins[j] > rt then rt = ins[j] end
    end
    return l, rt
end

-- Fill a box whose corners named in `spec` are rounded by `r` pixels.
function Paint.round(bb, x, y, w, h, r, spec, c)
    r = math.min(r, floor(w / 2), floor(h / 2))
    if r <= 0 then return fill(bb, x, y, w, h, c) end
    local tl, tr, br, bl = corners(spec)
    local ins = cornerInsets(r)
    fill(bb, x, y + r, w, h - 2 * r, c)
    for i = 0, r - 1 do
        local l, rt = rowInsets(i, h, r, ins, tl, tr, br, bl)
        fill(bb, x + l, y + i, w - l - rt, 1, c)
        local k = h - 1 - i
        l, rt = rowInsets(k, h, r, ins, tl, tr, br, bl)
        fill(bb, x + l, y + k, w - l - rt, 1, c)
    end
end

-- Outline such a box with lines `t` pixels thick: on each row of a corner,
-- what the outer shape covers and the shape `t` further in does not.
function Paint.roundFrame(bb, x, y, w, h, r, spec, t, c)
    r = math.min(r, floor(w / 2), floor(h / 2))
    if r <= t then return Paint.frame(bb, x, y, w, h, t, c) end
    local tl, tr, br, bl = corners(spec)
    local ins, ins2 = cornerInsets(r), cornerInsets(r - t)
    local h2 = h - 2 * t
    local function row(i)
        local l, rt = rowInsets(i, h, r, ins, tl, tr, br, bl)
        if i < t or i >= h - t then
            fill(bb, x + l, y + i, w - l - rt, 1, c)
        else
            local l2, rt2 = rowInsets(i - t, h2, r - t, ins2, tl, tr, br, bl)
            fill(bb, x + l, y + i, t + l2 - l, 1, c)
            fill(bb, x + w - t - rt2, y + i, t + rt2 - rt, 1, c)
        end
    end
    for i = 0, r - 1 do
        row(i)
        row(h - 1 - i)
    end
    fill(bb, x, y + r, t, h - 2 * r, c)
    fill(bb, x + w - t, y + r, t, h - 2 * r, c)
end

-- A rounded box filled with `fill_c` and outlined with `line_c`.
function Paint.roundBox(bb, x, y, w, h, r, spec, t, fill_c, line_c)
    if fill_c then Paint.round(bb, x, y, w, h, r, spec, fill_c) end
    if line_c then Paint.roundFrame(bb, x, y, w, h, r, spec, t, line_c) end
end

-- Stripes across a box: "h" horizontal, "v" vertical, "d" rising diagonal,
-- "b" falling diagonal; a `thick` line every `period` pixels.
function Paint.stripes(bb, x, y, w, h, dir, period, thick, c)
    if w <= 0 or h <= 0 then return end
    if dir == "h" then
        for yy = 0, h - 1, period do fill(bb, x, y + yy, w, math.min(thick, h - yy), c) end
    elseif dir == "v" then
        for xx = 0, w - 1, period do fill(bb, x + xx, y, math.min(thick, w - xx), h, c) end
    else
        -- diagonals: on each row the stripes shift one pixel
        local run = math.max(1, floor(thick * 1.42 + 0.5))
        for row = 0, h - 1 do
            local shift = (dir == "d" and (h - row) or row) % period
            for xx = shift - period, w - 1, period do
                local x0 = math.max(xx, 0)
                local x1 = math.min(xx + run, w)
                if x1 > x0 then fill(bb, x + x0, y + row, x1 - x0, 1, c) end
            end
        end
    end
end

-- A straight line `t` pixels thick between two points, drawn as runs of the
-- C rectangle fill (one per row for a shallow line, one per column for a steep one).
function Paint.line(bb, x0, y0, x1, y1, t, c)
    x0, y0, x1, y1 = floor(x0 + 0.5), floor(y0 + 0.5), floor(x1 + 0.5), floor(y1 + 0.5)
    local half = floor(t / 2)
    local dx, dy = x1 - x0, y1 - y0
    local shallow = math.abs(dx) >= math.abs(dy)
    if not shallow then x0, y0, dx, dy = y0, x0, dy, dx end   -- work along x, swap back when drawing
    if dx < 0 then x0, y0, dx, dy = x0 + dx, y0 + dy, -dx, -dy end
    local sy = dy >= 0 and 1 or -1
    local steps = math.abs(dy)
    local function from(k) return k == 0 and x0 or x0 + floor(dx * (k - 0.5) / steps + 0.5) end
    for k = 0, steps do
        local xa = from(k)
        local xb = k == steps and x0 + dx or from(k + 1)
        local ya = y0 + k * sy - half
        if shallow then fill(bb, xa, ya, xb - xa + 1, t, c) else fill(bb, ya, xa, t, xb - xa + 1, c) end
    end
end

-- A closed outline through the points { {x, y}, ... }, `t` pixels thick.
function Paint.outline(bb, pts, t, c)
    for i, a in ipairs(pts) do
        local b = pts[i % #pts + 1]
        Paint.line(bb, a[1], a[2], b[1], b[2], t, c)
    end
end

-- Fill the polygon through the points { {x, y}, ... } (any simple shape), a row
-- at a time.
function Paint.polygon(bb, pts, c)
    local top, bottom = math.huge, -math.huge
    for _i, p in ipairs(pts) do
        top, bottom = math.min(top, p[2]), math.max(bottom, p[2])
    end
    local n = #pts
    for y = floor(top), math.ceil(bottom) - 1 do
        local yc, xs = y + 0.5, {}
        for i = 1, n do
            local a, b = pts[i], pts[i % n + 1]
            if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then
                xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1])
            end
        end
        table.sort(xs)
        for j = 1, #xs - 1, 2 do
            local xa, xb = floor(xs[j] + 0.5), floor(xs[j + 1] + 0.5)
            if xb > xa then fill(bb, xa, y, xb - xa, 1, c) end
        end
    end
end

return Paint
