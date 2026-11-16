-- What every sleeping animal of the garden shares: the little Zs that drift
-- up from a sleeper, a closed eye, and a bed of dry fallen leaves to sleep in
-- or under. The animals_* files draw each animal's own sleeping pose ("sleep")
-- and winter form ("winter") with these.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, line = Svg.n, Svg.line
local mix, vary = Wash.mix, Svg.vary

local Asleep = {}

-- Three Zs rising up and to the right from (x, y), the first `s` tall.
function Asleep.zs(c, x, y, s)
    local d = {}
    for k = 0, 2 do
        local z = s * (1 - k * .22)
        local zx, zy = x + k * s * .9, y - k * s * 1.15
        d[#d + 1] = string.format("M%s %s h%s l%s %s h%s", n(zx), n(zy - z), n(z * .8), n(-z * .8), n(z), n(z * .8))
    end
    return line(table.concat(d, " "), mix(c.ink, c.sky, .35), math.max(.9, s * .16))
end

-- A closed eye at (x, y), `w` wide: a soft downward curve with a lash.
function Asleep.eye(c, x, y, w)
    return line(string.format("M%s %s q%s %s %s 0", n(x - w / 2), n(y), n(w / 2), n(w * .45), n(w)), c.ink, math.max(.9, w * .2))
end

-- One dry fallen leaf, its stalk at (x, y), pointing at `rot` degrees and
-- `s` long, in the `i`-th of the four autumn tones.
function Asleep.leaf(c, i, x, y, rot, s)
    local tones = { mix(c.gold, c.muted, .35), mix(c.bloom, c.muted, .3), mix(c.muted, c.pale, .4), c.gold }
    return Flora.leaf(c, x, y, rot, s, s * .26, tones[i % 4 + 1], true)
end

-- Dry fallen leaves lying in a low heap from x0 to x1 at the ground line y,
-- `k` of them, `s` long; over = true lays a few more across the top.
function Asleep.leaves(c, x0, x1, y, k, s, over)
    local out = {}
    for i = 1, k do
        local f = (i - .5) / k
        local x = x0 + (x1 - x0) * f
        local rise = math.sin(math.pi * f) * s * (over and .7 or .25)
        out[#out + 1] = Asleep.leaf(c, i, x, y - rise * vary(i, 7), (f < .5 and -160 or -20) + (vary(i, 8) - .5) * 70, s * (.7 + .5 * vary(i, 9)))
    end
    return table.concat(out)
end

return Asleep
