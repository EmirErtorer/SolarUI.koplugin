-- Frames for Ink Away's drawings on SolarUI's notebook shelf, in the Art
-- Nouveau manner: each is drawn for the size it frames (w x h, its band `b`
-- wide), so it hugs a drawing of any shape. The drawing is laid in the
-- window first and the frame drawn over it, its window cut out. Gilt (gold
-- with whiplash corners and a shell at head and foot), Oak (carved, with
-- leaves at the corners), Iron (a fine wrought rule round a cream mat),
-- Halo (an arched window in a cream mount), Lily (green enamel with white
-- lilies), Peacock (blue enamel, gold beads and feather eyes), Copper
-- (hammered, with ginkgo corners) and Pearl (ivory with a shell and a row of
-- pearls). InkFrames.LOOKS lists them; InkFrames.svg(id, w, h) draws one and
-- InkFrames.window(id, w, h) says where the drawing goes.

local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse
local mix = Wash.mix

local InkFrames = {}

local GOLD, GOLD_D, GOLD_L = "#D8AE52", "#8A6424", "#F1D58E"

-- A rectangle inset `i` in a w x h box, as path data.
local function rect(w, h, i)
    return string.format("M%s %s L%s %s L%s %s L%s %sZ", n(i), n(i), n(w - i), n(i), n(w - i), n(h - i), n(i), n(h - i))
end

-- A filled ring between two insets of the box (its middle left clear).
local function ring(w, h, i0, i1, fill, stroke, sw)
    local edge = stroke and string.format(' stroke="%s" stroke-width="%s"', stroke, n(sw or 1)) or ""
    return string.format('<path d="%s %s" fill="%s" fill-rule="evenodd"%s/>', rect(w, h, i0), rect(w, h, i1), fill, edge)
end

-- `body` drawn in each corner of a w x h box (drawn for the top-left one).
local function corners(w, h, body)
    return body .. group(w, 0, 0, body, -1, 1) .. group(0, h, 0, body, 1, -1) .. group(w, h, 0, body, -1, -1)
end

-- A line that swells and thins along the points.
local function whip(pts, wd, colour)
    return path(Svg.ribbon(Svg.spline(pts, 10), Svg.swell(wd, .8)), colour)
end

-- Gilt: a dark outer moulding, a broad gold band and a fine inner lip, a
-- whiplash curl with a leaf in each corner and a shell at head and foot.
local function gilt(w, h, b)
    local out = ring(w, h, 0, b, GOLD, GOLD_D, 1.4) .. ring(w, h, 0, b * .22, GOLD_D) .. ring(w, h, b * .78, b, GOLD_L) .. line(rect(w, h, b - .5), GOLD_D, 1.6)
        .. line(rect(w, h, b * .45), GOLD_D, .8)
    local s = b
    out = out .. corners(w, h, whip({ { s * .4, s * 2.8 }, { s * .55, s * 1.1 }, { s * .75, s * .6 }, { s * 1.1, s * .55 }, { s * 2.8, s * .4 } }, s * .16, GOLD_D)
        .. line(Svg.poly(Svg.spiral(s * .78, s * .78, s * .3, 1.3, 200)), GOLD_D, s * .07)
        .. Flora.leaf({ ink = GOLD_D }, s * .55, s * .55, -135, s * .75, s * .22, GOLD_L, true) .. circle(s * .78, s * .78, s * .09, GOLD_L, GOLD_D, s * .03))
    s = b * 1.4
    local function shell(x, y, flip)
        local ribs = {}
        for k = -3, 3 do ribs[#ribs + 1] = string.format("M0 %s L%s %s", n(s * .1), n(k * s * .12), n(-s * .32)) end
        return group(x, y, 0, path(string.format("M%s %s Q0 %s %s %sZ", n(-s * .42), n(s * .1), n(-s * .6), n(s * .42), n(s * .1)), GOLD_L, GOLD_D, s * .04)
            .. line(table.concat(ribs, " "), GOLD_D, s * .03), 1, flip and -1 or 1)
    end
    return out .. shell(w / 2, b * .55, false) .. shell(w / 2, h - b * .55, true)
end

-- Oak: carved wood with its grain running round the band, a bevelled inner
-- edge and an oak leaf with an acorn carved in each corner.
local function oak(w, h, b)
    local wood, dark = "#9C6B3F", "#5C3A1C"
    local out = ring(w, h, 0, b, wood, dark, 1.4) .. ring(w, h, b * .74, b, mix(wood, "#FFFFFF", .2))
    local grain = {}
    for k = 1, 4 do grain[#grain + 1] = rect(w, h, b * k * .16) end
    out = out .. line(table.concat(grain, " "), mix(wood, dark, .45), .7) .. line(rect(w, h, b - .5), dark, 1.6)
    local s = b
    local block = path(rect(s, s, 0), mix(wood, dark, .2), dark, 1.2)
    for k = 0, 5 do block = block .. group(s / 2, s / 2, k * 60, path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(-s * .12), n(-s * .1), n(-s * .14), n(-s * .3), n(-s * .38), n(s * .14), n(-s * .3), n(s * .12), n(-s * .1)), mix(wood, "#E8C890", .35), dark, s * .025)) end
    block = block .. circle(s / 2, s / 2, s * .08, dark)
    return out .. corners(w, h, Flora.leaf({ ink = dark }, s, s * .5, 0, s * 1.3, s * .3, mix(wood, dark, .3), true) .. Flora.leaf({ ink = dark }, s * .5, s, 90, s * 1.3, s * .3, mix(wood, dark, .3), true) .. block)
end

-- Iron: a cream mat inside a fine black wrought rule, spirals at the corners
-- and the middles, a thin dark line round the window.
local function iron(w, h, b)
    local ink = "#1E1B18"
    local out = ring(w, h, 0, b, "#F1E8D2") .. line(rect(w, h, b * .14) .. " " .. rect(w, h, b * .28), ink, 1.4) .. line(rect(w, h, b - 1), ink, 1.2)
    local s = b
    local curl = line(Svg.poly(Svg.join({ { s * .21, s * .9 }, { s * .4, s * .5 } }, Svg.spiral(s * .55, s * .55, s * .16, 1.4, 220))), ink, s * .05)
        .. line(Svg.poly(Svg.join({ { s * .9, s * .21 }, { s * .5, s * .4 } }, Svg.spiral(s * .55, s * .55, s * .1, 1, 40))), ink, s * .04)
    out = out .. corners(w, h, curl)
    for _i, m in ipairs({ { w / 2, s * .21, 0 }, { w / 2, h - s * .21, 180 }, { s * .21, h / 2, -90 }, { w - s * .21, h / 2, 90 } }) do
        out = out .. group(m[1], m[2], m[3], line(Svg.poly(Svg.spiral(-s * .2, s * .16, s * .12, 1, 0)), ink, s * .04) .. line(Svg.poly(Svg.spiral(s * .2, s * .16, s * .12, 1, 180, true)), ink, s * .04))
    end
    return out
end

-- Halo: a cream mount whose window rises into a round arch, a gold rule
-- round the arch and a flourish at each shoulder. The drawing shows in the
-- arch; the mount covers its top corners.
local function halo(w, h, b)
    local r = (w - 2 * b) / 2
    local top = b + r * .9
    local arch = string.format("M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %sZ", n(b), n(h - b), n(b), n(top), n(r), n(r * .9), n(w - b), n(top), n(w - b), n(h - b))
    local out = string.format('<path d="%s %s" fill="#EFE4CC" fill-rule="evenodd"/>', rect(w, h, 0), arch)
        .. line(arch, GOLD_D, 2.2) .. line(rect(w, h, b * .3), GOLD, 1.4)
    local s = b
    local curl = whip({ { b, top }, { b - s * .5, top - s * .4 }, { b - s * .4, top - s * 1 }, { b + s * .1, top - s * 1.1 } }, s * .1, GOLD_D)
        .. Flora.leaf({ ink = GOLD_D }, b - s * .45, top - s * .5, -150, s * .5, s * .14, GOLD, true)
    return out .. curl .. group(w, 0, 0, curl, -1, 1) .. circle(w / 2, b * .55, s * .16, GOLD, GOLD_D, 1)
end

-- One lily at (x, y), `s` across: six pointed white tepals and gold anthers.
local function lily(x, y, s, rot)
    local out = ""
    for k = 0, 5 do
        out = out .. group(0, 0, k * 60, path(string.format("M0 0 C%s %s %s %s 0 %s C%s %s %s %s 0 0Z", n(-s * .2), n(-s * .2), n(-s * .16), n(-s * .5), n(-s * .62), n(s * .16), n(-s * .5), n(s * .2), n(-s * .2)), "#FBF7EC", "#3A4A38", s * .03))
    end
    return group(x, y, rot, out .. Svg.dots(0, 0, s * .16, 6, s * .05, GOLD) .. circle(0, 0, s * .06, "#7FA060"))
end

-- Lily: green enamel edged in gold, a white lily with leaves at each corner.
local function lilyFrame(w, h, b)
    local green = "#3D6B4E"
    local out = ring(w, h, 0, b, green, GOLD_D, 1.4) .. line(rect(w, h, b * .12) .. " " .. rect(w, h, b - 1.4), GOLD, 1.6)
    local s = b
    return out .. corners(w, h, Flora.leaf({ ink = "#1E3626" }, s * .5, s * .5, 10, s * 1.5, s * .3, "#79A36A") .. Flora.leaf({ ink = "#1E3626" }, s * .5, s * .5, 80, s * 1.5, s * .3, "#5E8A50")
        .. lily(s * .55, s * .55, s * 1.25, 10))
end

-- One peacock feather eye at (x, y), `s` tall, pointing `rot`.
local function eye(x, y, s, rot)
    return group(x, y, rot, ellipse(0, 0, s * .36, s * .5, 0, "#2E7D6E", "#0E2422", s * .03) .. ellipse(0, s * .05, s * .26, s * .36, 0, GOLD)
        .. ellipse(0, s * .08, s * .17, s * .25, 0, "#3A9BB0") .. ellipse(0, s * .11, s * .08, s * .12, 0, "#132548"))
end

-- Peacock: blue enamel, a row of gold beads round the window and a feather
-- eye in each corner.
local function peacockFrame(w, h, b)
    local blue = "#1D3557"
    local out = ring(w, h, 0, b, blue, GOLD_D, 1.4) .. line(rect(w, h, b * .1), GOLD, 1.4) .. line(rect(w, h, b - 1.4), GOLD, 1.4)
    local beads = {}
    local i = b * .78
    local function row(x0, y0, x1, y1)
        local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
        local k = math.max(1, math.floor(len / (b * .22)))
        for j = 0, k do beads[#beads + 1] = circle(x0 + (x1 - x0) * j / k, y0 + (y1 - y0) * j / k, b * .055, GOLD) end
    end
    row(i, i, w - i, i) row(i, h - i, w - i, h - i) row(i, i, i, h - i) row(w - i, i, w - i, h - i)
    return out .. table.concat(beads) .. corners(w, h, eye(b * .55, b * .55, b * 1.3, -45))
end

-- One ginkgo leaf at (x, y), `s` long, pointing `rot`.
local function ginkgo(x, y, s, rot, fill)
    return group(x, y, rot, line(string.format("M0 0 L0 %s", n(s * .6)), "#2E4A3A", s * .05)
        .. path(string.format("M0 0 L%s %s Q%s %s %s %s L0 %s L%s %s Q%s %s %s %sZ", n(-s * .7), n(-s * .55), n(-s * .45), n(-s), n(-s * .06), n(-s * .94), n(-s * .7),
            n(s * .06), n(-s * .94), n(s * .45), n(-s), n(s * .7), n(-s * .55)), fill, "#24382C", s * .03))
end

-- Copper: hammered copper, a lighter beaten edge, ginkgo leaves in
-- verdigris at the corners.
local function copper(w, h, b)
    local cu = "#B06A3B"
    local out = ring(w, h, 0, b, cu, "#5A2E14", 1.4) .. ring(w, h, b * .7, b, mix(cu, "#F0C090", .35)) .. line(rect(w, h, b - .5), "#5A2E14", 1.4)
    local marks = {}
    local step = math.max(6, b * .28)
    for y = step * .5, h, step do
        for x = step * .5, w, step do
            if x < b * .66 or x > w - b * .66 or y < b * .66 or y > h - b * .66 then
                local v = Svg.vary(math.floor(x), math.floor(y))
                marks[#marks + 1] = circle(x + (v - .5) * step * .4, y, step * .18, v > .5 and mix(cu, "#F0C090", .3) or mix(cu, "#3A1A08", .25))
            end
        end
    end
    local s = b
    return out .. table.concat(marks) .. corners(w, h, ginkgo(s * .35, s * .35, s * 1.1, 135, "#6FA58A") .. ginkgo(s * .3, s * .7, s * .7, 170, "#8DBFA2") .. ginkgo(s * .7, s * .3, s * .7, 100, "#8DBFA2"))
end

-- Pearl: ivory, a row of pearls round the window and a scallop shell at
-- the head.
local function pearl(w, h, b)
    local ivory = "#EDE6D6"
    local out = ring(w, h, 0, b, ivory, "#9A8E74", 1.4) .. line(rect(w, h, b * .16), "#C9BCA0", 1.2)
    local beads = {}
    local i = b * .72
    local function row(x0, y0, x1, y1)
        local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
        local k = math.max(1, math.floor(len / (b * .2)))
        for j = 0, k do
            local x, y = x0 + (x1 - x0) * j / k, y0 + (y1 - y0) * j / k
            beads[#beads + 1] = circle(x, y, b * .085, "#FBF8F0", "#A89C82", .8) .. circle(x - b * .025, y - b * .025, b * .025, "#FFFFFF")
        end
    end
    row(i, i, w - i, i) row(i, h - i, w - i, h - i) row(i, i, i, h - i) row(w - i, i, w - i, h - i)
    local s = b * 1.6
    local ribs = {}
    for k = -4, 4 do ribs[#ribs + 1] = string.format("M0 %s L%s %s", n(s * .1), n(k * s * .11), n(-s * .46)) end
    local shell = group(w / 2, b * .62, 0, path(string.format("M%s %s Q%s %s 0 %s Q%s %s %s %sZ", n(-s * .55), n(s * .1), n(-s * .5), n(-s * .5), n(-s * .58), n(s * .5), n(-s * .5), n(s * .55), n(s * .1)), "#F6EFE0", "#9A8E74", 1)
        .. line(table.concat(ribs, " "), "#B8AA8C", .8))
    return out .. table.concat(beads) .. line(rect(w, h, b - .5), "#9A8E74", 1.2) .. shell
end

-- Every frame, in the order they are dealt and offered: id, name, draw and
-- its band as a share of the shorter side.
InkFrames.LOOKS = {
    { id = "gilt", name = "Gilt", draw = gilt, band = .11 },
    { id = "oak", name = "Oak", draw = oak, band = .1 },
    { id = "iron", name = "Iron and mat", draw = iron, band = .14 },
    { id = "halo", name = "Halo", draw = halo, band = .12 },
    { id = "lily", name = "Lily", draw = lilyFrame, band = .12 },
    { id = "peacock", name = "Peacock", draw = peacockFrame, band = .11 },
    { id = "copper", name = "Copper", draw = copper, band = .1 },
    { id = "pearl", name = "Pearl", draw = pearl, band = .11 },
}

-- The frame with this id, or nil.
function InkFrames.look(id)
    for _i, l in ipairs(InkFrames.LOOKS) do
        if l.id == id then return l end
    end
    return nil
end

-- The band of frame `id` for a w x h frame, in pixels.
function InkFrames.band(id, w, h)
    local l = InkFrames.look(id) or InkFrames.LOOKS[1]
    return math.max(6, math.floor(math.min(w, h) * l.band + .5))
end

-- Where the drawing goes in frame `id` of w x h: x, y, w, h.
function InkFrames.window(id, w, h)
    local b = InkFrames.band(id, w, h)
    return b, b, w - 2 * b, h - 2 * b
end

-- The SVG body of frame `id` for a w x h frame.
function InkFrames.svg(id, w, h)
    local l = InkFrames.look(id) or InkFrames.LOOKS[1]
    return l.draw(w, h, InkFrames.band(l.id, w, h))
end

return InkFrames
