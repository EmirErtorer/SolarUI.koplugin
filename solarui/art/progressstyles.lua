-- More ways to draw a book's progress (ui/progress.lua), each
-- progress_<style>(c, vw, vh, pct) for a vw x vh canvas, read as far as
-- `pct` percent: a row of blossoms on a fine runner, open where the book is
-- read, opening at the place reached and still buds ahead; and a row of
-- moons on a gilt line, full where read, waxing at the place reached and new
-- ahead.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n = Svg.n

local Styles = {}

-- The share read, from 0 to 1.
local function share(pct) return math.max(0, math.min(1, (tonumber(pct) or 0) / 100)) end

-- How many marks fit across vw, and their spacing.
local function marks(vw, size)
    local count = math.max(5, math.floor((vw - 20) / size))
    return count, (vw - 20) / count
end

-- Blossoms: daisies open where read, a half-open rosebud at the place reached,
-- small closed buds ahead, each on a short stem from a fine runner.
function Styles.progress_blossoms(c, vw, vh, pct)
    local f = share(pct)
    local count, step = marks(vw, vh * .62)
    local ground = vh * .86
    local out = { Svg.line(string.format("M%s %s L%s %s", n(6), n(ground), n(vw - 6), n(ground)), c.stem, 2.2) }
    local reached = f * count
    for i = 1, count do
        local x = 10 + step * (i - .5)
        local top = vh * (.42 + ((i % 2 == 0) and .06 or 0))
        out[#out + 1] = Svg.line(string.format("M%s %s Q%s %s %s %s", n(x), n(ground), n(x + step * .08), n((ground + top) / 2), n(x), n(top)), c.stem, 1.6)
        if i <= math.floor(reached) then
            out[#out + 1] = Flora.daisy(c, x, top, vh * .26, 8, (i % 3 == 0) and c.bloom2 or c.cream)
        elseif i == math.floor(reached) + 1 and f > 0 then
            out[#out + 1] = Flora.rosebud(c, x, top + vh * .06, 0, vh * .3, c.bloom)
        else
            out[#out + 1] = Svg.ellipse(x, top, vh * .07, vh * .12, 0, c.leaf, c.ink, 1.2)
        end
    end
    return table.concat(out)
end

-- The lit part of a moon of radius r at (cx, cy), `lit` from 0 (new) to 1 (full), waxing from the right.
local function moon(c, cx, cy, r, lit)
    local out = Svg.circle(cx, cy, r, c.cream, c.ink, 1.3)
    if lit >= .99 then
        -- a full moon, with a few soft shadows on the face
        return Svg.circle(cx, cy, r, c.gold, c.ink, 1.3) .. Svg.circle(cx - r * .3, cy - r * .2, r * .2, c.pale) .. Svg.circle(cx + r * .28, cy + r * .3, r * .14, c.pale)
    end
    if lit <= .01 then return out end
    local rx = r * math.abs(1 - 2 * lit)
    local sweep = lit < .5 and 0 or 1
    local d = string.format("M%s %s A%s %s 0 0 1 %s %s A%s %s 0 0 %d %s %s Z",
        n(cx), n(cy - r), n(r), n(r), n(cx), n(cy + r), n(rx), n(r), sweep, n(cx), n(cy - r))
    return out .. Svg.path(d, c.gold, c.ink, 1.3)
end

-- Moons: full gold where read, waxing at the place reached, new ahead, on a gilt line with a star at each end.
function Styles.progress_moons(c, vw, vh, pct)
    local f = share(pct)
    local count, step = marks(vw, vh * .5)
    local cy, r = vh * .5, math.min(vh * .22, step * .36)
    local out = { Svg.line(string.format("M%s %s L%s %s", n(8), n(cy), n(vw - 8), n(cy)), c.gold, 1.4) }
    for _i, x in ipairs({ 8, vw - 8 }) do
        out[#out + 1] = Svg.path(string.format("M%s %s L%s %s L%s %s L%s %s Z", n(x), n(cy - r * .7), n(x + r * .22), n(cy), n(x), n(cy + r * .7), n(x - r * .22), n(cy)), c.gold, c.ink, 1)
    end
    local reached = f * count
    for i = 1, count do
        local lit = math.max(0, math.min(1, reached - (i - 1)))
        out[#out + 1] = moon(c, 10 + step * (i - .5), cy, r, lit)
    end
    return table.concat(out)
end

return Styles
