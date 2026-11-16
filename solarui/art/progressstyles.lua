-- More ways to draw a book's progress (ui/progress.lua), each
-- progress_<style>(c, vw, vh, pct) for a vw x vh canvas, read as far as
-- `pct` percent: a string of pearls that fill with gold as the book is read,
-- and a whiplash ribbon of gold with a dragonfly at its tip.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local Styles = {}

-- The points of `pts` up to `frac` of their length.
local function upTo(pts, frac)
    local want, run, out = Svg.length(pts) * frac, 0, { pts[1] }
    for i = 2, #pts do
        local a, b = pts[i - 1], pts[i]
        local seg = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
        if run + seg >= want then
            local t = seg > 0 and (want - run) / seg or 0
            out[#out + 1] = { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t }
            return out
        end
        run = run + seg
        out[#out + 1] = b
    end
    return out
end

-- A gentle wave across the canvas, `amp` of its height up and down.
local function wave(vw, vh, amp, bumps)
    local way = {}
    for i = 0, bumps * 2 do way[#way + 1] = { 14 + (vw - 28) * i / (bumps * 2), vh * (.5 + (i % 2 == 0 and amp or -amp)) } end
    return Svg.spline(way, 8)
end

-- Pearls on a fine gilt chain, gold where read and pale ahead, a leaf at each end.
function Styles.progress_pearls(c, vw, vh, pct)
    local frac = math.max(0, math.min(1, (tonumber(pct) or 0) / 100))
    local pts = wave(vw, vh, .1, 3)
    local count = math.max(6, math.floor((vw - 60) / 30))
    local total = Svg.length(pts)
    local out = { Flora.leaf(c, 16, vh * .55, 160, vh * .42, vh * .14, c.leaf), Flora.leaf(c, vw - 16, vh * .55, 20, vh * .42, vh * .14, c.leaf),
        Svg.line(Svg.poly(pts), c.gold, 1.4) }
    local r = math.min(vh * .2, total / count * .32)
    for i = 1, count do
        local x, y = Svg.along(pts, total * (i - .5) / count)
        local read = (i - .5) / count <= frac
        if read then
            out[#out + 1] = Svg.circle(x, y, r, c.gold, c.ink, 1.4) .. Svg.circle(x - r * .3, y - r * .32, r * .3, c.cream)
        else
            out[#out + 1] = Svg.circle(x, y, r * .78, c.cream, c.line, 1.2)
        end
    end
    return table.concat(out)
end

-- A whiplash ribbon: gold and broad as far as the book is read, a fine line
-- after, and a dragonfly resting at the tip of the gold.
function Styles.progress_ribbon(c, vw, vh, pct)
    local frac = math.max(0, math.min(1, (tonumber(pct) or 0) / 100))
    local pts = wave(vw, vh, .16, 2)
    local out = { Svg.line(Svg.poly(pts), c.line, 1.6) }
    if frac > 0.01 then
        local read = upTo(pts, frac)
        if #read >= 2 then
            out[#out + 1] = Svg.stem(read, Svg.taper(vh * .07, vh * .2), c.gold, c.ink, 1.4)
        end
        -- (the dragonfly flies along the ribbon, just above the tip, and stays inside the bar)
        local tip = read[#read]
        local s = vh * .34
        out[#out + 1] = Flora.dragonfly(c, math.min(tip[1], vw - s * .9), tip[2] - vh * .2, 90, s, 4)
    end
    return table.concat(out)
end

return Styles
