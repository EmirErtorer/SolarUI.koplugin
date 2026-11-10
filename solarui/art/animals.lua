-- The garden's animals: animal_<id>(c, vw, vh, pose) with pose 1 or 2, the two
-- poses of the slow animation (wings open or shut, a step forward). Each fills
-- its own canvas, facing right, and rests on the foot of it.

local Flora = require("solarui/art/flora")
local Insects = require("solarui/art/insects")
local Ornaments = require("solarui/art/ornaments")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local group, ellipse, circle, path = Svg.group, Svg.ellipse, Svg.circle, Svg.path

local Animals = {}

-- A small four-legged or round animal: a body, a head with an eye and two
-- ears or none, in the given colours. The base of the other drawings.
local function creature(c, vw, vh, body, head, ears)
    local out = ellipse(vw * .46, vh * .62, vw * .34, vh * .28, 0, body, c.ink, 1.8)
        .. ellipse(vw * .8, vh * .5, vw * .15, vh * .17, 0, head, c.ink, 1.8)
        .. circle(vw * .85, vh * .46, vh * .03, c.ink)
    if ears then out = out .. path(string.format("M%s %s L%s %s L%s %sZ", Svg.n(vw * .74), Svg.n(vh * .36), Svg.n(vw * .76), Svg.n(vh * .2), Svg.n(vw * .82), Svg.n(vh * .36)), head, c.ink, 1.5) end
    return out .. Svg.line(string.format("M%s %s L%s %s M%s %s L%s %s", Svg.n(vw * .3), Svg.n(vh * .86), Svg.n(vw * .3), Svg.n(vh * .96), Svg.n(vw * .6), Svg.n(vh * .86), Svg.n(vw * .6), Svg.n(vh * .96)), c.ink, 2)
end

-- A bee in flight.
function Animals.animal_bee(c, vw, vh, pose)
    return Insects.bee(c, vw * .5, vh * .5, pose == "2" and -8 or 8, vw * .3)
end

-- A ladybird on a leaf.
function Animals.animal_ladybug(c, vw, vh, pose)
    return Insects.ladybug(c, vw * .5, vh * .55, pose == "2" and -10 or 10, vw * .3)
end

-- A snail, creeping a little between poses.
function Animals.animal_snail(c, vw, vh, pose)
    return group(pose == "2" and vw * .06 or 0, 0, 0, Ornaments.snail(c, vw, vh))
end

-- A swallowtail with its wings open or half shut.
function Animals.animal_butterfly(c, vw, vh, pose)
    return group(vw * .5, vh * .5, 0, group(-vw * .5, -vh * .5, 0, Ornaments.butterfly(c, vw, vh)), pose == "2" and .7 or 1, 1)
end

-- A robin: round body, red breast.
function Animals.animal_robin(c, vw, vh)
    return creature(c, vw, vh, c.sage, c.sage, false) .. ellipse(vw * .66, vh * .64, vw * .13, vh * .17, 0, c.bloom, c.ink, 1.5)
        .. path(string.format("M%s %s L%s %s L%s %sZ", Svg.n(vw * .94), Svg.n(vh * .5), Svg.n(vw), Svg.n(vh * .54), Svg.n(vw * .94), Svg.n(vh * .58)), c.gold, c.ink, 1.2)
end

-- A dragonfly hovering, its wings drawn in or out.
function Animals.animal_dragonfly(c, vw, vh, pose)
    return Flora.dragonfly(c, vw * .5, vh * .15, 90, vw * .17, pose == "2" and 2 or 4)
end

-- A frog sitting up.
function Animals.animal_frog(c, vw, vh)
    return ellipse(vw * .5, vh * .68, vw * .38, vh * .26, 0, c.leaf, c.ink, 1.8)
        .. circle(vw * .38, vh * .36, vh * .13, c.leaf, c.ink, 1.6) .. circle(vw * .62, vh * .36, vh * .13, c.leaf, c.ink, 1.6)
        .. circle(vw * .38, vh * .36, vh * .05, c.ink) .. circle(vw * .62, vh * .36, vh * .05, c.ink)
end

-- A koi, with a flick of its tail between poses.
function Animals.animal_koi(c, vw, vh, pose)
    local flick = pose == "2" and -.1 or .1
    return path(string.format("M%s %s L%s %s L%s %sZ", Svg.n(vw * .2), Svg.n(vh * .5), Svg.n(vw * .02), Svg.n(vh * (.25 + flick)), Svg.n(vw * .02), Svg.n(vh * (.75 - flick))), c.bloom, c.ink, 1.5)
        .. ellipse(vw * .56, vh * .5, vw * .38, vh * .3, 0, c.cream, c.ink, 1.8) .. ellipse(vw * .5, vh * .42, vw * .12, vh * .13, 0, c.bloom, c.ink, 1.2)
        .. circle(vw * .85, vh * .44, vh * .05, c.ink)
end

-- A hedgehog: a domed back of spines over a small face.
function Animals.animal_hedgehog(c, vw, vh)
    local spines = {}
    for i = 0, 11 do
        local x, y = Svg.pol(vw * .38, -80 + i * 14, vw * .45, vh * .88)
        local x2, y2 = Svg.pol(vw * .46, -80 + i * 14, vw * .45, vh * .88)
        spines[#spines + 1] = string.format("M%s %s L%s %s", Svg.n(x), Svg.n(y), Svg.n(x2), Svg.n(y2))
    end
    return ellipse(vw * .45, vh * .66, vw * .38, vh * .3, 0, c.stem, c.ink, 1.8) .. Svg.line(table.concat(spines, " "), c.ink, 1.6)
        .. ellipse(vw * .86, vh * .78, vw * .13, vh * .13, 0, c.pale, c.ink, 1.5) .. circle(vw * .88, vh * .74, vh * .03, c.ink)
end

-- An elephant hawk-moth, wings drawn flat.
function Animals.animal_moth(c, vw, vh, pose)
    return group(vw * .5, vh * .5, 0, group(-vw * .5, -vh * .5, 0, Ornaments.butterfly(c, vw, vh)), pose == "2" and .75 or 1, .9)
end

-- A red fox standing: a longer body, a brush of a tail and pointed ears.
function Animals.animal_fox(c, vw, vh)
    return path(string.format("M%s %s C%s %s %s %s %s %sZ", Svg.n(vw * .16), Svg.n(vh * .6), Svg.n(0), Svg.n(vh * .3), Svg.n(vw * .05), Svg.n(vh * .9), Svg.n(vw * .22), Svg.n(vh * .78)), c.bloom, c.ink, 1.8)
        .. creature(c, vw, vh, c.bloom, c.bloom, true)
end

-- A peacock, tail fanned out behind.
function Animals.animal_peacock(c, vw, vh)
    return Flora.peacock(c, vw * .3, vh * .35, 0, vw * .17) .. Flora.peacock(c, vw * .5, vh * .3, 0, vw * .17)
        .. creature(c, vw, vh, c.glass, c.glass, false)
end

-- Every drawing reads its param as the pose (its first letter) and may be
-- asked for the faded copy ("1:wash").
for name, draw in pairs(Animals) do
    Animals[name] = function(c, vw, vh, param) return draw(Wash.apply(c, param), vw, vh, tostring(param or "1"):sub(1, 1)) end
end

return Animals
