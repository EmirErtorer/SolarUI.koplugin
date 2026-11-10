-- The small flying things of the garden. The bee is drawn from the side
-- heading right with its centre at the origin of its group, `s` its length
-- over two; the trail is a dotted loop of the flight it came by.

local Svg = require("solarui/art/svg")

local n, group = Svg.n, Svg.group

local Insects = {}

-- A bee at (x, y) turned by `rot`: golden body with two dark bands, a dark
-- head with an eye, two pale wings, antennae, a sting and three legs.
function Insects.bee(c, x, y, rot, s)
    local function stripe(px)
        return Svg.line(string.format("M%s %s Q%s 0 %s %s", n(px), n(-s * .26), n(px + s * .04), n(px), n(s * .26)), c.ink, s * .13)
    end
    local legs = {}
    for _i, px in ipairs({ -s * .2, s * .05, s * .28 }) do
        legs[#legs + 1] = string.format("M%s %s L%s %s", n(px), n(s * .3), n(px - s * .06), n(s * .5))
    end
    local body = Svg.ellipse(-s * .05, -s * .3, s * .4, s * .17, -55, c.sky, c.ink, 1.2)
        .. Svg.ellipse(s * .18, -s * .3, s * .36, s * .15, -22, c.cream, c.ink, 1.2)
        .. Svg.line(table.concat(legs, " "), c.ink, 1.3)
        .. Svg.path(string.format("M%s 0 L%s %s L%s %sZ", n(-s * .45), n(-s * .78), n(-s * .04), n(-s * .78), n(s * .06)), c.ink)
        .. Svg.ellipse(0, 0, s * .52, s * .3, 0, c.gold, c.ink, 1.7)
        .. stripe(-s * .12) .. stripe(s * .2)
        .. Svg.circle(s * .62, -s * .02, s * .22, c.ink)
        .. Svg.circle(s * .68, -s * .08, s * .05, c.cream)
        .. Svg.line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(s * .7), n(-s * .2), n(s * .78), n(-s * .42), n(s * .95), n(-s * .4),
            n(s * .62), n(-s * .22), n(s * .62), n(-s * .5), n(s * .78), n(-s * .58)), c.ink, 1.3)
    return group(x, y, rot, body)
end

-- A dotted loop that leads to (x, y), a bee's path through the air.
function Insects.trail(c, pts, size)
    local out = {}
    for i = 1, #pts do out[#out + 1] = Svg.circle(pts[i][1], pts[i][2], size * (.5 + .5 * i / #pts), c.ink) end
    return table.concat(out)
end

return Insects
