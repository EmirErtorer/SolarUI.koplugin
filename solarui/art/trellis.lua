-- The trellis arch the ivy climbs: two latticed posts joined by a round arch
-- with a finial. Drawn in the ivy bed's own units (origin at the middle of
-- its foot, y up as negative), so the ground and the ivy share one shape.

local Svg = require("solarui/art/svg")

local n, line = Svg.n, Svg.line

local Trellis = {}

local POST, SPRING, RISE = 178, 168, 128   -- half the span, where the arch springs, how far it rises

-- The line of the arch from the left foot over the top to the right foot,
-- moved `d` units outwards.
function Trellis.way(d)
    local pts = {}
    for i = 0, 8 do pts[#pts + 1] = { -POST - d, -SPRING * i / 8 } end
    for a = 176, 4, -4 do
        pts[#pts + 1] = { (POST + d) * math.cos(math.rad(a)), -SPRING - (RISE + d) * math.sin(math.rad(a)) }
    end
    for i = 8, 0, -1 do pts[#pts + 1] = { POST + d, -SPRING * i / 8 } end
    return pts
end

-- The frame: two rails, rungs between them, crossed laths on the posts.
function Trellis.frame(c)
    local outer, inner = Trellis.way(11), Trellis.way(-11)
    local rungs, laths = {}, {}
    for i = 1, #outer, 4 do
        rungs[#rungs + 1] = string.format("M%s %s L%s %s", n(outer[i][1]), n(outer[i][2]), n(inner[i][1]), n(inner[i][2]))
        local j = i + 4
        if j <= #outer and (i < 9 or i > #outer - 12) then
            laths[#laths + 1] = string.format("M%s %s L%s %s M%s %s L%s %s", n(outer[i][1]), n(outer[i][2]), n(inner[j][1]), n(inner[j][2]), n(inner[i][1]), n(inner[i][2]), n(outer[j][1]), n(outer[j][2]))
        end
    end
    local top = -SPRING - RISE - 11
    return line(table.concat(laths, " "), c.ink, 1.2) .. line(table.concat(rungs, " "), c.ink, 1.8)
        .. line(Svg.poly(outer), c.ink, 3.2) .. line(Svg.poly(inner), c.ink, 3.2)
        .. line(string.format("M%s -1 L%s -1 M%s -1 L%s -1", n(-POST - 17), n(-POST + 17), n(POST - 17), n(POST + 17)), c.ink, 3.2)
        .. line(string.format("M0 %s L0 %s", n(top), n(top - 6)), c.ink, 2.4) .. Svg.circle(0, top - 9, 4, c.gold, c.ink, 1.6)
end

return Trellis
