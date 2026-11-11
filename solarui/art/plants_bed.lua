-- The Three Sisters bed through the stages of its life: a mound of earth
-- with a tall stalk of maize, a climbing bean winding up it and a squash
-- sprawling at its foot, and the bed after the harvest in winter, drawn with
-- plantkit and returned by name for gardenplants.

local Kit = require("solarui/art/plantkit")
local Rest = require("solarui/art/plantrest")
local Svg = require("solarui/art/svg")

local circle, ellipse = Svg.circle, Svg.ellipse

local Bed = {}

-- The bed at a stage: how tall the maize stands, and what shows on each plant.
local function bed(p)
    local c, st = p.c, p.st
    local tall = ({ 0, 40, 90, 130, 124 })[st]
    local stalk = Kit.rise(p, { { 0, -3 }, { 3, -tall * .5 }, { -2, -tall } }, 60, .5)
    local out = Kit.soil(p, 120) .. Svg.stem(stalk, Svg.taper(6, 3.6), c.stem, c.ink, 1.4)
    for i, f in ipairs({ .3, .45, .6, .75 }) do
        local x, y, ang = Kit.on(stalk, f)
        out = out .. Kit.blade(p, x, y, Kit.turn(p, ang, i % 2 == 0 and 1 or -1, 60, .5), 36 - 8 * f * 3, 7, 28, c.leaf)
    end
    if st >= 4 then
        local x, y = Kit.on(stalk, .55)
        out = out .. ellipse(x + 8, y, 6, 14, 12, st == 5 and c.pale or c.gold, c.ink, 1.3)
    end
    if st >= 3 then
        out = out .. ellipse(-38, -8, 22, 9, 0, c.leaf, c.ink, 1.3) .. ellipse(40, -6, 20, 8, 0, c.sage, c.ink, 1.3)
        if st >= 4 then out = out .. circle(-34, -9, 7, c.gold, c.ink, 1.3) .. circle(-18, -22, 3.5, c.bloom, c.ink, 1) end
    end
    return out
end

-- The bed in winter: dry husks hanging from the cut maize stalk, a bean
-- stub, and one last small squash left on the earth.
local function bedRest(p, dry)
    local c, out = p.c, ""
    for i, h in ipairs({ { -34, 1 }, { -26, -1 }, { -44, -1 } }) do
        out = out .. Kit.blade(dry, 2 * h[2], h[1], h[2] * 150, 26, 6, h[2] * 30, i == 2 and c.dead or c.straw, c.ink)
    end
    return out .. ellipse(-36, -9, 13, 8.5, -6, c.gold, c.ink, 1.4) .. Svg.line("M-42 -4 Q-46 -10 -42 -15 M-30 -4 Q-26 -10 -30 -16", c.ink, .9)
        .. Svg.path("M-37 -16 L-36 -23 L-33 -22 L-34 -16Z", c.straw, c.ink, 1)
end

Bed.three_sisters = Kit.sprite("three_sisters", "pips", bed, false, Rest.form({ w = 120, stubs = { { 0, 62, -3, 6 }, { 30, 24, 6, 3 } }, litter = 3, extra = bedRest }))

return Bed
