-- Yüzsüz, the queen of the garden, drawn from life in many poses. She is a
-- chonky black and white cat, and her markings are always the same:
--   head: a black cap over the crown, the back of the head and both ears (pink
--     inside), a narrow white blaze running up the middle of the forehead to a
--     point between the eyes, a white muzzle, chin and throat, a pink nose and
--     yellow-green eyes;
--   mask: black round both eyes, but not alike: on her right side the black
--     stops under the eye and the cheek is white, on her left side it runs down
--     the cheek to the jaw;
--   body: black from the back of the neck along the back to the rump and the
--     tops of the thighs, the black coming further down her right flank; a
--     white chest, belly and four white legs, pink pads, and a small black spot
--     on a hind heel;
--   tail: all black, long and full, and never still;
--   mouth: often a little open, the tip of a pink tongue showing.
-- A pose is named (see POSES); "1" and "2" are her sitting and her loaf. A name
-- may end in ".a", ".b" or ".c", the place of her tail. Every pose is drawn
-- facing right in the units of her box (120 by 84, the ground at 82); facing
-- right shows her left side, and when she faces left (`flip`) her right side
-- is drawn, so the mirror shows the right markings.

local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local n, group, path, line, circle, ellipse = Svg.n, Svg.group, Svg.path, Svg.line, Svg.circle, Svg.ellipse
local mix = Wash.mix

local Cat = {}

-- Her colours, from the palette.
local function coat(c)
    return { black = mix(c.ink, c.muted, .2), white = c.cream, pink = mix(c.bloom2, c.cream, .2), nose = mix(c.bloom2, c.bloom, .3),
        eye = mix(c.gold, c.leaf, .42), mouth = mix(c.ink, c.bloom, .35), lid = mix(c.muted, c.cream, .35), ink = c.ink,
        cushion = mix(c.violet, c.bloom, .35), gold = c.gold, dish = mix(c.sky, c.cream, .4), meat = mix(c.bloom, c.bloom2, .4),
        lizard = mix(c.leaf, c.gold, .3), stone = mix(c.muted, c.cream, .5), bird = mix(c.muted, c.ink, .1),
        sheen = mix(mix(c.ink, c.muted, .2), c.cream, .24), shade = mix(c.cream, c.muted, .22), whisker = mix(c.ink, c.cream, .5),
        iris = mix(mix(c.gold, c.leaf, .42), c.ink, .35), ground = mix(c.cream, c.muted, .3) }
end

-- `body` turned by `deg` degrees about (x, y).
local function about(x, y, deg, body)
    return group(x, y, deg, group(-x, -y, 0, body))
end

-- A closed outline along the points `pts`, `w0` wide at the start thinning to
-- `w1`, with a round end: a tail. Filled black and inked.
local function tail(k, way, w0, w1)
    local pts = Svg.spline(way, 10)
    local left, right = {}, {}
    local count = #pts
    for i = 1, count do
        local a, b = pts[math.max(1, i - 1)], pts[math.min(count, i + 1)]
        local dx, dy = b[1] - a[1], b[2] - a[2]
        local len = math.sqrt(dx * dx + dy * dy)
        if len == 0 then len = 1 end
        local w = (w0 + (w1 - w0) * (i - 1) / (count - 1)) / 2
        left[i] = { pts[i][1] - dy / len * w, pts[i][2] + dx / len * w }
        right[i] = { pts[i][1] + dy / len * w, pts[i][2] - dx / len * w }
    end
    local out = {}
    for i = 1, count do out[#out + 1] = left[i] end
    -- the round tip
    local last, prev = pts[count], pts[count - 1]
    local ang = math.atan2(last[2] - prev[2], last[1] - prev[1])
    for j = 1, 7 do
        local a = ang + math.pi / 2 - math.pi * j / 8
        out[#out + 1] = { last[1] + math.cos(a) * w1 / 2, last[2] + math.sin(a) * w1 / 2 }
    end
    for i = count, 1, -1 do out[#out + 1] = right[i] end
    return path(Svg.poly(out, true), k.black, k.ink, 1.4)
end

-- A white leg through the points `way`, `w` wide, ending in a paw; `far` legs
-- are a shade darker, and `heel` puts her black spot on the back of the foot.
local function leg(k, way, w, far, heel)
    local fill = far and mix(k.white, k.lid, .45) or k.white
    local tip, before = way[#way], way[#way - 1]
    local dir = tip[1] >= before[1] and 1 or -1
    return Svg.stem(Svg.spline(way, 6), Svg.taper(w, w * .82), fill, k.ink, 1.3)
        .. ellipse(tip[1] + dir * 1.6, tip[2] - 1, w * .62, w * .36, 0, fill, k.ink, 1.2)
        .. line(string.format("M%s %s l0 1.6 M%s %s l0 1.6", n(tip[1] + dir * 1), n(tip[2] - 1.6), n(tip[1] + dir * 3), n(tip[2] - 1.6)), k.ink, .6)
        .. (heel and ellipse(tip[1] - dir * 2.2, tip[2] - 3.4, 1.8, 2.6, 0, k.black) or "")
end

-- A paw seen from the front or underneath at (x, y), `s` across, with its
-- pink pads when `pads`.
local function paw(k, x, y, s, pads, far)
    local fill = far and mix(k.white, k.lid, .45) or k.white
    return ellipse(x, y, s / 2, s * .4, 0, fill, k.ink, 1.2)
        .. (pads and (ellipse(x, y + s * .06, s * .17, s * .13, 0, k.pink) .. circle(x - s * .2, y - s * .14, s * .07, k.pink) .. circle(x, y - s * .2, s * .07, k.pink)
            .. circle(x + s * .2, y - s * .14, s * .07, k.pink))
            or line(string.format("M%s %s l0 %s M%s %s l0 %s", n(x - s * .14), n(y - s * .1), n(s * .3), n(x + s * .14), n(y - s * .1), n(s * .3)), k.ink, .6))
end

-- Her head seen from the side, facing right, centred on (x, y), turned by
-- `rot` and `s` times its size, in the same detail as her face: a big ear
-- with pale tufts and the far ear behind, the black cap, the blaze as a white
-- stripe down the front of the face, a white muzzle and chin, a pink nose,
-- a yellow-green eye and long whiskers. Facing right shows her left side,
-- where the black comes down the cheek to the mouth and the jaw is white;
-- o.side "right" shows her right side, a band of black at the eye and the
-- cheek white below it. o.eye, o.mouth and o.ears as for her face.
local function headSide(k, x, y, rot, s, o)
    local left = o.side ~= "right"
    local eye, mouth = o.eye or "open", o.mouth or "shut"
    local farEar = path("M-9.8 -8.6 C-11 -14 -10.4 -19.6 -8.6 -23.4 C-5.6 -20.6 -3.6 -17 -2.6 -13.4Z", k.black, k.ink, 1.3)
    local nearEar = path("M-4.4 -13 C-4.6 -18.6 -2.6 -24.4 1 -27.4 C3.8 -23 5.8 -17.6 7.2 -12.4Z", k.black, k.ink, 1.4)
        .. path("M-2.4 -13.4 C-2.4 -17.6 -1 -21.8 1.2 -24 C3 -20.6 4.4 -16.6 5.2 -13Z", k.pink)
        .. line("M-.8 -14.2 C-.6 -16.8 0 -19 .6 -20.6 M1.4 -14 C1.6 -16.2 2 -18 2.6 -19.4 M3.4 -13.8 L4 -16", k.white, .55)
    if o.ears == "back" then
        farEar = about(-6, -11, -50, farEar)
        nearEar = about(1, -13, -62, nearEar)
    end
    local skull = "M-12 -2 C-12 -10 -6 -14.4 1 -14.4 C7 -14.4 11 -11.4 13 -7.4 C14 -5.4 15.6 -3.2 16.2 -1.2 C16.6 .8 15.6 2.6 14.2 3.2"
        .. " C13.2 5.2 11.8 6.6 9.8 7.2 C6.6 9.2 1 10.2 -3.4 9.8 C-6.6 9.6 -9.2 8.6 -10.8 7 L-13.4 7.4 L-12.2 5 L-14.2 4 L-12.4 2.2 C-12.4 .6 -12.2 -.8 -12 -2Z"
    local white = left
        and "M8.6 -12.4 C10.4 -11.2 12 -9.4 13 -7.4 C14 -5.4 15.6 -3.2 16.2 -1.2 C16.6 .8 15.6 2.6 14.2 3.2 C13.2 5.2 11.8 6.6 9.8 7.2 C6.6 9.2 1 10.2 -3.4 9.8 C-.6 7.6 3 5.6 6.2 4.4 C7.8 2.2 8.4 -1 8.4 -4 C8.6 -7 8.8 -10 8.6 -12.4Z"
        or "M8.6 -12.4 C10.4 -11.2 12 -9.4 13 -7.4 C14 -5.4 15.6 -3.2 16.2 -1.2 C16.6 .8 15.6 2.6 14.2 3.2 C13.2 5.2 11.8 6.6 9.8 7.2 C6.6 9.2 1 10.2 -3.4 9.8 C-6.6 9.6 -9.2 8.6 -10.8 7 L-13.4 7.4 L-12.2 5 L-14.2 4 L-12.4 2.2 C-12.4 1.4 -12.3 .6 -12.2 0 C-8 .8 -3 1.2 1.6 .6 C5.6 -.2 7.8 -3 8.2 -6 C8.4 -8.6 8.6 -10.8 8.6 -12.4Z"
    local eyes
    if eye == "shut" then
        eyes = line("M2.4 -4.4 C4 -2.8 7 -2.8 8.6 -4.6", k.lid, 1.2)
    elseif eye == "squint" then
        eyes = path("M2.4 -4.2 C4.2 -5.4 6.8 -5.6 8.8 -5 C7 -3.6 4.4 -3.4 2.4 -4.2Z", k.eye, k.ink, .9) .. ellipse(6, -4.5, .6, .8, 0, k.ink)
            .. line("M1.8 -6.6 C4 -6.8 6.6 -6.8 9 -6", k.sheen, 1)
    else
        local py = eye == "up" and -5.8 or -4.8
        local pw = eye == "wide" and 1.4 or .8
        eyes = path("M2.4 -4.4 C3.4 -7.4 7.6 -7.8 9 -5 C8.2 -2.2 3.8 -1.8 2.4 -4.4Z", k.eye, k.ink, 1)
            .. path("M2.4 -4.4 C3.4 -7.4 7.6 -7.8 9 -5", nil, k.iris, .8)
            .. ellipse(6.4, py, pw, 2, 0, k.ink) .. circle(7.3, py - 1, .5, k.white)
    end
    local mouths = {
        shut = line("M15.2 .8 C14.8 2.2 13.8 3.2 12.2 3.6", k.ink, .9),
        blep = line("M15.2 .8 C14.8 2.2 13.8 3.2 12.2 3.6", k.ink, .9) .. path("M12.6 3.5 C12.5 5.2 14.1 5.8 14.6 4.3 C14.7 3.8 14.3 3.2 13.7 3.2Z", k.pink, mix(k.pink, k.ink, .4), .5),
        open = path("M15.4 1.4 C13.2 3 10.2 4.6 8.2 5 C9.2 7.8 12.2 8.6 14.2 6.8 C14.8 5.2 15.2 3.2 15.4 1.4Z", k.mouth, k.ink, .9) .. path("M9.8 5.8 C11.2 7.6 13.2 7.6 14 6.4 C12.2 5.8 11 5.6 9.8 5.8Z", k.pink),
        fangs = path("M15.4 1.4 C13.2 3 10.2 4.6 8.2 5 C9.2 7.8 12.2 8.6 14.2 6.8 C14.8 5.2 15.2 3.2 15.4 1.4Z", k.mouth, k.ink, .9)
            .. path("M14.8 2 L14.4 4.4 L13.4 2.6Z M13.2 7 L12.8 5 L12 6.8Z", k.white, k.ink, .4),
        chew = line("M15.2 .8 C14.8 2.2 13.8 3.2 12.2 3.6", k.ink, .9) .. line("M11.6 4.8 C12.8 5.6 14 5.4 14.6 4.6", k.ink, .7),
    }
    local pad = line("M10.4 .6 C11.6 2.8 13.4 3.4 14.6 2.8", k.shade, .7) .. circle(11.8, 1.2, .3, k.shade) .. circle(12.8, 2.2, .3, k.shade)
    local nose = path("M14.8 -2.8 C15.8 -3 16.6 -2.2 16.6 -1.4 C16.4 -.4 15.6 .4 15 .4 C14.8 -.6 14.6 -1.8 14.8 -2.8Z", k.nose, mix(k.nose, k.ink, .4), .5)
    local whiskers = line("M12.8 1 C17 -.6 21 -1.2 25.6 -.6 M13 1.8 C17.4 1.4 21.6 2 25.6 3.6 M12.6 2.6 C16.4 3.6 19.8 5.2 23 7.6", k.whisker, .5)
    local cap = line("M-6 -11.6 C-2.6 -13.2 2.4 -13.2 6 -11.8", k.sheen, .7)
    return group(x, y, rot, farEar .. path(skull, k.black, k.ink, 1.5) .. path(white, k.white) .. cap .. path(skull, nil, k.ink, 1.5)
        .. nearEar .. eyes .. pad .. nose .. (mouths[mouth] or mouths.shut) .. whiskers, s)
end

-- Her face seen from the front in full detail, centred on (x, y), turned by
-- `rot` and `s` times its size: the broad chubby face with tufted cheeks, big
-- ears with pale tufts, the black cap, the narrow blaze, the mask (black down
-- the cheek on the viewer's right when o.mask is "right", as when she faces
-- you; "left" when mirrored), puffy whisker pads, long whiskers, a pink nose,
-- and large yellow-green eyes. o.eye: "open", "up", "squint", "shut", "wide";
-- o.mouth: "shut", "blep", "open", "fangs"; o.ears: "up" or "back".
local function face(k, x, y, rot, s, o)
    local eye, mouth = o.eye or "open", o.mouth or "shut"
    -- the outline: wide at the cheeks, tufts of fur at the jowls
    local outline = "M-15 -1 C-15.8 -9 -11 -15.4 0 -15.8 C11 -15.4 15.8 -9 15 -1 L16.6 1.6 L15.2 2.6 L16.4 5.2 L14.2 5.8 C13.4 8.4 11.4 10.4 8.6 11.6"
        .. " C6 12.8 3 13.2 0 13.2 C-3 13.2 -6 12.8 -8.6 11.6 C-11.4 10.4 -13.4 8.4 -14.2 5.8 L-16.4 5.2 L-15.2 2.6 L-16.6 1.6Z"
    local function ear(side)
        local e = path("M-14.6 -6.6 C-16 -13 -15.6 -20.6 -13 -26 C-8.6 -23.4 -5 -19.4 -3 -14.6Z", k.black, k.ink, 1.4)
            .. path("M-12.8 -9.4 C-13.6 -14.4 -13.2 -19.6 -12.2 -22.4 C-9.6 -20.2 -7.4 -17.4 -5.8 -14.6Z", k.pink)
            .. line("M-11.6 -11 C-11.2 -14 -10.6 -16.4 -10.4 -18 M-9.6 -11.4 C-9.2 -13.6 -8.6 -15.6 -8.2 -16.6 M-12.6 -10.6 L-13.4 -13.4", k.white, .55)
            .. line("M-13.6 -15 C-13.8 -18 -13.4 -21 -12.8 -23", k.sheen, .6)
        if o.ears == "back" then e = about(-8, -13, -42, e) end
        return group(0, 0, 0, e, side, 1)
    end
    -- the white of the face: the broad blaze to a point at the brow, the muzzle,
    -- chin and jaw; on the viewer's right the black comes down the cheek only
    -- to the mouth; on the viewer's left the cheek is
    -- white below a band of black that runs from that eye to the edge of the face
    local white = "M0 -10.8 C1 -9.2 2.2 -7.6 2.9 -5.9 C3.4 -3.4 3.9 -1 5 1.4 C6.8 2.6 10.4 3.4 14.4 3.6 L15.2 2.6 L16.4 5.2 L14.2 5.8"
        .. " C13.4 8.4 11.4 10.4 8.6 11.6 C6 12.8 3 13.2 0 13.2"
        .. " C-3 13.2 -6 12.8 -8.6 11.6 C-11.4 10.4 -13.4 8.4 -14.2 5.8 L-16.4 5.2 L-15.2 2.6 L-16.6 1.6 L-15 -1"
        .. " C-12.4 -.6 -9.4 -.2 -6.8 -.4 C-4.8 -.6 -3.4 -1.8 -3 -3.4 C-2.8 -4.4 -2.8 -5.2 -2.9 -5.9 C-2.2 -7.6 -1 -9.2 0 -10.8Z"
    local mask = group(0, 0, 0, path(white, k.white), o.mask == "left" and -1 or 1, 1)
    -- the sheen on the black cap
    local sheen = line("M-4 -12.6 C-2.6 -13.6 2.6 -13.6 4 -12.6 M-9.6 -9.6 L-10.6 -11.6 M9.6 -9.6 L10.6 -11.6", k.sheen, .7)
    local function oneEye(side)
        local e
        if eye == "shut" then
            e = line("M-10 -4.8 C-8.4 -3 -4.6 -3 -3 -4.8", k.lid, 1.2) .. line("M-10 -4.8 L-11 -5.6", k.lid, .9)
        elseif eye == "squint" then
            e = path("M-10.2 -4.4 C-8.6 -6 -4.8 -6.4 -2.8 -5.4 C-4.4 -3.8 -8.4 -3.4 -10.2 -4.4Z", k.eye, k.ink, 1) .. ellipse(-6.4, -4.8, .7, .9, 0, k.ink)
                .. line("M-10.8 -7.2 C-8.4 -7.6 -5 -7.4 -2.6 -6.2", k.sheen, 1)
        else
            local py = eye == "up" and -6.6 or -5.2
            local pw = eye == "wide" and 1.7 or 1
            e = path("M-10.4 -4.8 C-9.4 -8.4 -4.4 -9 -2.6 -5.8 C-3.4 -2.4 -8.8 -1.8 -10.4 -4.8Z", k.eye, k.ink, 1.1)
                .. path("M-10.4 -4.8 C-9.4 -8.4 -4.4 -9 -2.6 -5.8", nil, k.iris, .9)
                .. ellipse(-6.5, py, pw, 2.3, 0, k.ink) .. circle(-5.4, py - 1.2, .65, k.white) .. circle(-7.6, py + 1.3, .3, k.white)
        end
        return group(0, 0, 0, e, side, 1)
    end
    local pads = ellipse(-3.3, 5, 4.2, 3.2, 0, k.white, k.shade, .7) .. ellipse(3.3, 5, 4.2, 3.2, 0, k.white, k.shade, .7)
        .. circle(-4.6, 4.4, .3, k.shade) .. circle(-3, 5.6, .3, k.shade) .. circle(-5, 6, .3, k.shade)
        .. circle(4.6, 4.4, .3, k.shade) .. circle(3, 5.6, .3, k.shade) .. circle(5, 6, .3, k.shade)
    local nose = path("M-2.5 .4 C-2.6 -.8 2.6 -.8 2.5 .4 C2.4 1.4 .9 2.6 0 2.8 C-.9 2.6 -2.4 1.4 -2.5 .4Z", k.nose, mix(k.nose, k.ink, .4), .5)
        .. ellipse(-.8, -.2, .7, .35, 0, mix(k.nose, k.white, .5))
    local mouths = {
        shut = line("M0 2.8 L0 4.4 M0 4.4 C-.8 5.6 -2.4 5.8 -3.4 5 M0 4.4 C.8 5.6 2.4 5.8 3.4 5", k.ink, .8),
        blep = line("M0 2.8 L0 4.4 M0 4.4 C-.8 5.6 -2.4 5.8 -3.4 5 M0 4.4 C.8 5.6 2.4 5.8 3.4 5", k.ink, .8)
            .. path("M-1 5 C-1.1 7.2 1.1 7.2 1 5 C.6 4.8 -.6 4.8 -1 5Z", k.pink, mix(k.pink, k.ink, .4), .5),
        open = line("M0 2.8 L0 3.6", k.ink, .8) .. path("M-3.4 4.6 C-2 3.6 2 3.6 3.4 4.6 C3 8 -3 8 -3.4 4.6Z", k.mouth, k.ink, .8) .. ellipse(0, 6.6, 2, 1, 0, k.pink),
        fangs = line("M0 2.8 L0 3.4", k.ink, .8) .. path("M-3.8 4.4 C-2 3.2 2 3.2 3.8 4.4 C3.4 8.6 -3.4 8.6 -3.8 4.4Z", k.mouth, k.ink, .8)
            .. path("M-2.8 4 L-2.2 6.4 L-1.4 4.1Z M2.8 4 L2.2 6.4 L1.4 4.1Z", k.white, k.ink, .4),
    }
    local whiskers = line("M-6 4.4 C-11 3.2 -16 2.6 -22 3.4 M-6 5.4 C-11 5.2 -16 5.8 -21.4 7.4 M-5.6 6.4 C-10 7.2 -14 8.6 -18.6 11"
        .. " M6 4.4 C11 3.2 16 2.6 22 3.4 M6 5.4 C11 5.2 16 5.8 21.4 7.4 M5.6 6.4 C10 7.2 14 8.6 18.6 11", k.whisker, .5)
    return group(x, y, rot, ear(1) .. ear(-1) .. path(outline, k.black, k.ink, 1.5) .. mask .. sheen .. path(outline, nil, k.ink, 1.5)
        .. oneEye(1) .. oneEye(-1) .. pads .. nose .. (mouths[mouth] or mouths.shut) .. whiskers, s)
end

-- The place of her tail in a pose: "a", "b" or "c" from the pose name, "a" by default.
local function wag(t, ways)
    return ways[t] or ways.a
end

local POSES = {}

-- Sitting, her body turned three quarters to the right and her face to you,
-- the way she sits in most of her photos: the broad face with its lopsided
-- mask, a deep fluffy white chest, chonky haunches, thick white front legs
-- side by side and the big black tail wrapped round behind her paws (or
-- curled up behind, or flicking out). o.head (eye, mouth, ears, rot, dy) changes her face for
-- the poses built on this one.
function POSES.sit(k, o)
    local t = wag(o.tail, {
        a = { { 40, 76 }, { 54, 81 }, { 70, 82.2 }, { 84, 80 }, { 91.6, 74 } },
        b = { { 28, 70 }, { 14, 62 }, { 10, 47 }, { 16, 37 } },
        c = { { 30, 76 }, { 16, 81 }, { 6, 78 }, { 2, 70 } } })
    local h = o.head or {}
    -- the whole of her, haunch to chest, white; the chest ends above the front legs
    local body = "M31 82 C21 81.4 16.4 71 19 60 C21.6 49 30 41.6 41 38.4 C47 36.6 52 35.6 57 35.6 L76 38 C83 43 87.6 51 87 60"
        .. " C86.6 64.6 84.6 67.4 81 68 C76 68.8 69 68.6 63.6 67.4 C60.6 71 58 76 56 82Z"
    -- the black: on her left side (facing right) the back, side and haunch are
    -- black down to the belly, with a thin white collar from the bib round the
    -- neck; on her right side she is whiter, a patch on the shoulder and the
    -- back and the haunch's top black
    local black = o.side == "left"
        and "M31 82 C21 81.4 16.4 71 19 60 C21.6 49 30 41.6 41 38.4 C47 36.6 52 35.6 55 35.6 C57 39 59.4 42 62.6 44.4 C61.2 50 60.6 56 60.4 62 C60 68 57.6 74 52.4 78 C47 81 40 82 34 82Z"
        or "M21 66 C20.4 62 20 59.6 21.6 54 C24 48 31 42 40 39 C45 37.4 50 36.4 54.6 36.4 C57 40 59 43 61.6 45 C58 47.6 54 49 50 49.6 C44 50.4 38 52 33 56.6 C29 60.4 26 64 24.4 68.6 C23 68 21.6 67.2 21 66Z"
    local collar = path("M55 35.6 C57 39 59.4 42 62.6 44.4 L64.8 40.6 C62 38.8 59.6 36.8 58 34.8Z", k.white)
    -- fur: the haunch's curve, the sheen on the black, tufts down the chest
    local fur = (o.side == "left" and line("M24.6 73 C26 63 35 56.6 46 59.6", k.sheen, 1) or line("M24.6 73 C26 63 35 56.6 46 59.6", k.shade, 1))
        .. line("M28 47.6 C32 44.6 37 42.6 42 41.6", k.sheen, 1) .. collar
        .. line("M73 46 l1.6 1.8 M78 48.4 l1.6 1.8 M70.6 51 l1.6 1.8 M76 54 l1.6 1.8 M81.6 53 l1.4 1.8 M73 58 l1.6 1.8 M79 60.4 l1.6 1.6 M83.4 59.6 l1.2 1.6", k.shade, .7)
    -- the front legs come down from under the chest; the paws rest on the tail
    local legs = Svg.stem(Svg.spline({ { 67, 60 }, { 67.4, 72 }, { 67.6, 80 } }, 6), Svg.taper(8.6, 8.2), k.white, k.ink, 1.3)
        .. Svg.stem(Svg.spline({ { 77, 60 }, { 77.4, 72 }, { 77.6, 80 } }, 6), Svg.taper(8.8, 8.4), k.white, k.ink, 1.3)
        .. line("M64.4 70 l1.4 .4 M80.6 70 l-1.4 .4", k.shade, .7)
    local paws = paw(k, 67.8, 80.2, 10) .. paw(k, 77.8, 80.2, 10.2)
    local hind = ellipse(46, 80.4, 8, 3, -4, k.white, k.ink, 1.2) .. line("M49.6 79.4 l0 1.8 M52 79.6 l0 1.6", k.ink, .6)
        .. (o.side == "left" and ellipse(40, 79.6, 2, 1.9, 0, k.black) or "")
    -- the tail comes from behind the haunch and wraps behind her front paws
    return ellipse(54, 82.6, 36, 2.4, 0, k.ground) .. tail(k, t, 9.4, 7.4)
        .. legs .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. fur .. path(body, nil, k.ink, 1.6)
        .. hind .. paws
        .. face(k, 71 + (h.dx or 0), 29 + (h.dy or 0), h.rot or 0, 1.08, { mask = o.flip and "left" or "right", eye = h.eye or "open", mouth = h.mouth or "blep", ears = h.ears })
end

-- Her coat on a body seen from the side: `body` the outline; on her left
-- side (facing right) she is black but for `under` (the chest, the belly
-- and what else is white); on her right side she is white with the black
-- `patches`. Inked round the outline once more on top.
local function coatSide(k, o, body, under, patches)
    local marks = o.side == "left" and (path(body, k.black) .. path(under, k.white)) or path(patches, k.black)
    return path(body, k.white, k.ink, 1.6) .. marks .. path(body, nil, k.ink, 1.6)
end

-- The mask of her face for a pose seen from the front: the black cheek is
-- always on the viewer's right as she faces you (so mirrored when she faces left).
local function mask(o)
    return o.flip and "left" or "right"
end

-- Loafing, seen from the front, paws tucked and peeking out, her head sunk
-- into her shoulders (her photos on the sofa and the bed, looking at you).
function POSES.loaf(k, o)
    local t = wag(o.tail, {
        a = { { 90, 74 }, { 100, 79 }, { 108, 74 }, { 106, 66 } },
        b = { { 90, 76 }, { 102, 81.6 }, { 112, 80 }, { 116, 74 } },
        c = { { 88, 70 }, { 98, 64 }, { 103, 54 }, { 99, 46 } } })
    local body = "M18 82 C16 70 21 58 31 52 C39 47.4 47 46 52 46 L68 46 C73 46 81 47.4 89 52 C99 58 104 70 102 82Z"
    local bib = "M45 47 C42 56 41 69 43 82 L77 82 C79 69 78 56 75 47 C67 45 53 45 45 47Z"
    local fur = line("M24 70 C26 62 30 57 36 53 M96 70 C94 62 90 57 84 53", k.sheen, 1)
        .. line("M52 56 l1.4 1.8 M58 60 l1.4 1.8 M64 56 l1.4 1.8 M68 62 l1.4 1.8 M50 64 l1.4 1.8 M60 68 l1.4 1.8", k.shade, .7)
    return ellipse(60, 82.6, 44, 2.4, 0, k.ground) .. tail(k, t, 9, 7.4)
        .. path(body, k.black, k.ink, 1.6) .. path(bib, k.white) .. fur .. path(body, nil, k.ink, 1.6)
        .. line("M49 82 C48.4 77 49.4 72.6 52 70 M71 82 C71.6 77 70.6 72.6 68 70", k.shade, .9)
        .. paw(k, 51, 80.2, 11.4) .. paw(k, 69, 80.2, 11.4)
        .. face(k, 60, 34, 0, 1.12, { mask = mask(o), eye = o.eye or "open", mouth = o.mouth or "shut" })
end

-- Walking, seen from the side, her tail up in a curl (her photos on the
-- radiator, the carved table and across the bed).
function POSES.walk(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 33, 45 }, { 24, 31 }, { 25, 15 }, { 34, 8 } },
        b = { { 33, 45 }, { 22, 35 }, { 16, 21 }, { 18, 10 } },
        c = { { 33, 45 }, { 26, 29 }, { 32, 15 }, { 42, 12 } } })
    local body = "M30 50 C30 40 40 34 54 34 C66 34 76 34 82 38 C86 42 87 50 84 56 C80 60 74 62 68 63 C56 67 42 65 36 60 C32 58 30 54 30 50Z"
    local under = "M82 38 C86 42 87 50 84 56 C80 60 74 62 68 63 C56 67 42 65 36 60 C44 61.6 54 62 62 60.4 C70 58.6 76 55 79.6 50 C79.4 45.6 80.2 41.4 82 38Z"
    local patches = "M56 34.2 C64 34 70 34.6 76 36.4 C73.6 41 68 43.4 61.6 42.6 C57.6 41.6 55.6 38 56 34.2Z M30 50 C30 40 40 34 50 34.2 C48.4 38.6 43 42 37.6 44.6 C34 46.4 31.6 48.4 30.4 52Z"
    return ellipse(58, 82.6, 30, 2, 0, k.ground) .. tail(k, t, 8.6, 7.2)
        .. leg(k, { { 74, 56 }, { 71, 70 }, { 70, 81 } }, 7, true) .. leg(k, { { 46, 58 }, { 49, 70 }, { 48, 81 } }, 7.4, true)
        .. leg(k, { { 79, 54 }, { 81, 68 }, { 82, 81 } }, 7.4) .. leg(k, { { 40, 56 }, { 36, 68 }, { 38, 81 } }, 8, false, left)
        .. coatSide(k, o, body, under, patches) .. line("M36 56 C40 50 46 46 52 45", left and k.sheen or k.shade, 1)
        .. headSide(k, 91, 34, 6, 1.02, { side = o.side, eye = "open", mouth = o.mouth or "blep" })
end

-- Her body sitting up seen from the front: black flanks either side of a
-- deep white chest and white front legs, the hind paws showing at the sides.
local function frontSit(k)
    local body = "M33 82 C29 70 31 57 39 49 C45 44 75 44 81 49 C89 57 91 70 87 82Z"
    local chest = "M46 46 C44 56 44 70 45 82 L75 82 C76 70 76 56 74 46 C67 44 53 44 46 46Z"
    return ellipse(60, 82.6, 32, 2.4, 0, k.ground)
        .. path(body, k.black, k.ink, 1.6) .. path(chest, k.white) .. path(body, nil, k.ink, 1.6)
        .. line("M36 72 C37 62 40 55 44 51 M84 72 C83 62 80 55 76 51", k.sheen, 1)
        .. line("M52 50 l1.4 1.8 M60 52 l1.4 1.8 M67 50 l1.4 1.8 M56 57 l1.4 1.8 M64 58 l1.4 1.8", k.shade, .7)
        .. line("M60 64 L60 82 M52.6 63 C52 70 52 76 52.6 82 M67.4 63 C68 70 68 76 67.4 82", k.shade, .9)
        .. paw(k, 54.4, 80.4, 9.6) .. paw(k, 65.6, 80.4, 9.6) .. ellipse(36.4, 80.6, 5.4, 2.4, 0, k.white, k.ink, 1.1) .. ellipse(83.6, 80.6, 5.4, 2.4, 0, k.white, k.ink, 1.1)
end

-- Sitting like a person, leaning back with her belly out and her legs before
-- her, one stretched long (her photos on the sofa, sitting up like a human).
function POSES.slouch(k, o)
    local t = wag(o.tail, {
        a = { { 34, 70 }, { 22, 74 }, { 12, 72 }, { 6, 64 } },
        b = { { 34, 70 }, { 20, 78 }, { 8, 80 }, { 2, 76 } },
        c = { { 34, 68 }, { 24, 62 }, { 20, 52 }, { 24, 44 } } })
    local body = "M35 76 C29 64 31 47 41 39 C47 35 73 35 79 39 C89 47 91 64 85 76 C79 82 41 82 35 76Z"
    local belly = "M45 41 C39 52 39 66 45 76 C53 80.4 67 80.4 75 76 C81 66 81 52 75 41 C68 38 52 38 45 41Z"
    return ellipse(56, 82, 38, 2.2, 0, k.ground) .. tail(k, t, 8.6, 7.2)
        .. path(body, k.black, k.ink, 1.6) .. path(belly, k.white) .. path(body, nil, k.ink, 1.6)
        .. line("M50 60 C54 64 60 65 66 62 M48 68 C54 71 62 72 70 69", k.shade, .8)
        .. Svg.stem(Svg.spline({ { 46, 72 }, { 34, 77 }, { 22, 79 } }, 6), Svg.taper(10, 8), k.white, k.ink, 1.3) .. paw(k, 19, 78, 9.6, true)
        .. Svg.stem(Svg.spline({ { 72, 72 }, { 80, 76 }, { 86, 79 } }, 6), Svg.taper(10, 8.4), k.white, k.ink, 1.3) .. ellipse(86, 79, 1.8, 2.4, 0, k.black) .. paw(k, 89.4, 78.6, 9.6, true)
        .. Svg.stem(Svg.spline({ { 48, 44 }, { 50, 52 }, { 55, 58 } }, 5), Svg.taper(8, 7), k.white, k.ink, 1.2) .. paw(k, 57, 58.6, 8)
        .. Svg.stem(Svg.spline({ { 72, 44 }, { 76, 54 }, { 79, 64 } }, 5), Svg.taper(8, 7), k.white, k.ink, 1.2) .. paw(k, 79.6, 65, 8)
        .. face(k, 60, 28, -6, 1.08, { mask = mask(o), eye = "open", mouth = "blep" })
end

-- Asleep, stretched out long on her side, front paws reaching past her nose
-- (her photos asleep across the bed and on the cushion).
local SLEEPER = "M20 72 C18 63 26 57 38 56 C54 55 72 56 84 60 C90 63 92 70 88 76 C80 80 62 81 44 81 C30 81 22 79 20 72Z"
local SLEEPER_UNDER = "M88 76 C80 80 62 81 44 81 C30 81 22 79 20 72 C26 74 34 75.4 44 75.4 C58 75.4 72 74 84 70 C86.4 71.6 87.8 73.8 88 76Z"
local SLEEPER_PATCHES = "M38 56 C46 55.4 54 55.2 62 55.6 C60 60 54 62.6 46 62.6 C40 62.4 37 59.6 38 56Z M20 72 C18 63 26 57 34 56.4 C33 61 29 65 24 68.6Z"
function POSES.sleep(k, o)
    local t = wag(o.tail, {
        a = { { 22, 64 }, { 12, 58 }, { 6, 50 }, { 8, 42 } },
        b = { { 22, 66 }, { 12, 66 }, { 4, 60 }, { 3, 52 } },
        c = { { 22, 64 }, { 14, 54 }, { 16, 44 }, { 22, 40 } } })
    return ellipse(56, 82, 46, 2, 0, k.ground) .. tail(k, t, 8.6, 7.2)
        .. leg(k, { { 28, 74 }, { 16, 77 }, { 6, 77 } }, 7.4, true) .. leg(k, { { 30, 77 }, { 18, 80 }, { 8, 81 } }, 7.8, false, o.side == "left")
        .. coatSide(k, o, SLEEPER, SLEEPER_UNDER, SLEEPER_PATCHES) .. line("M30 64 C40 60 52 59 64 59.6", o.side == "left" and k.sheen or k.shade, 1)
        .. leg(k, { { 82, 70 }, { 98, 74 }, { 112, 75 } }, 7, true) .. leg(k, { { 84, 74 }, { 100, 78 }, { 113, 80 } }, 7.4)
        .. headSide(k, 94, 64, 12, .96, { side = o.side, eye = "shut", mouth = "shut" })
end

-- On her back, belly up and paws in the air, her head tipped back upside
-- down, offering the belly (her photos on the red sheet, in the sun and on the floor).
function POSES.belly(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 24, 78 }, { 12, 80 }, { 4, 77 }, { 2, 70 } },
        b = { { 24, 78 }, { 12, 76 }, { 6, 68 }, { 8, 60 } },
        c = { { 24, 79 }, { 14, 82 }, { 6, 82 }, { 2, 78 } } })
    local body = "M22 78 C20 64 34 54 56 54 C76 54 90 62 92 74 C92 80 86 82 76 82 L32 82 C26 82 22 81 22 78Z"
    local black = left and "M22 78 C22 72 26 68 34 68 C48 70 62 71 76 70 C84 69.6 89 68 91.2 68 C92 70 92 72 92 74 C92 80 86 82 76 82 L32 82 C26 82 22 81 22 78Z"
        or "M22 78 C25 75 31 74 40 75.6 C56 78 74 77.6 92 74 C92 80 86 82 76 82 L32 82 C26 82 22 81 22 78Z"
    local farLeg = mix(k.white, k.lid, .45)
    return ellipse(56, 82.6, 38, 2, 0, k.ground) .. tail(k, t, 8.6, 7.2)
        .. Svg.stem(Svg.spline({ { 36, 60 }, { 30, 50 }, { 34, 42 } }, 6), Svg.taper(9, 8), farLeg, k.ink, 1.2) .. paw(k, 35, 41, 8.4, true, true)
        .. Svg.stem(Svg.spline({ { 76, 58 }, { 74, 48 }, { 70, 43 } }, 6), Svg.taper(8, 7), farLeg, k.ink, 1.2) .. paw(k, 69, 42, 7.4, false, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. line("M44 63 C52 59.4 64 59.4 72 63 M48 58 l1.4 1.6 M58 57 l1.4 1.6 M66 58 l1.4 1.6", k.shade, .8)
        .. Svg.stem(Svg.spline({ { 42, 58 }, { 44, 46 }, { 50, 40 } }, 6), Svg.taper(9.6, 8.4), k.white, k.ink, 1.3) .. paw(k, 51, 39, 9, true)
        .. ellipse(47.4, 41.6, 1.6, 2.2, 30, k.black)
        .. Svg.stem(Svg.spline({ { 82, 60 }, { 85, 50 }, { 82, 44 } }, 6), Svg.taper(8.4, 7.4), k.white, k.ink, 1.3) .. paw(k, 81, 42.6, 8)
        .. face(k, 101, 67, 158, .98, { mask = o.flip and "right" or "left", eye = "open", mouth = "blep" })
end

-- The look she is famous for: sitting square on, eyes narrowed, ears turned
-- back, mouth a flat line, her tail lashing. Someone is about to bleed (her
-- photo in the sun, side by side with Death himself).
function POSES.glare(k, o)
    local t = wag(o.tail, {
        a = { { 84, 76 }, { 96, 72 }, { 102, 62 }, { 98, 52 } },
        b = { { 84, 78 }, { 98, 78 }, { 108, 72 }, { 112, 62 } },
        c = { { 84, 76 }, { 94, 66 }, { 94, 54 }, { 88, 46 } } })
    return tail(k, t, 9, 7.6) .. frontSit(k)
        .. face(k, 60, 30, 0, 1.12, { mask = mask(o), eye = "squint", mouth = "shut", ears = "back" })
end

-- Sitting, chin up, chattering at a bird with her mouth open, answering its
-- call in its own language (her photo calling out in the hall). The bird is
-- up in the corner.
function POSES.chatter(k, o)
    local bird = group(106, 10, -10, path("M-6 0 C-4 -3 2 -4 6 -2 C9 -1 10 1 7 2 C3 3 -2 3 -6 0Z", k.bird, k.ink, .9)
        .. path("M-1 -1 C-3 -7 1 -9 4 -8 C3 -5 2 -3 1 -1Z", k.bird, k.ink, .8) .. path("M7 -.6 L10 0 L7 .8Z", k.gold) .. circle(5.6, -.8, .5, k.white)
        .. line("M-6 0 L-9 -1 M-6 0 L-9 1.6", k.ink, .8))
    local calls = line("M92 14 C94 16 94 19 92 21 M96 12 C99 15 99 20 96 23", k.ink, .8)
    return bird .. calls .. POSES.sit(k, { side = o.side, tail = o.tail, flip = o.flip, head = { eye = "up", mouth = "open", rot = -10, dy = -1 } })
end

-- Staring at her spot. Nobody knows what is there. She has watched it for
-- hours and will watch it for hours more, still as a statue.
function POSES.stare(k, o)
    return POSES.sit(k, { side = o.side, tail = "a", flip = o.flip, head = { eye = "wide", mouth = "shut" } })
end

-- Attacking: low and bunched, ears flat, fangs bared, one paw lashing out
-- with every claw, her tail fluffed up twice its size.
function POSES.bite(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 30, 60 }, { 18, 50 }, { 12, 36 }, { 16, 24 } },
        b = { { 30, 60 }, { 16, 56 }, { 6, 44 }, { 6, 32 } },
        c = { { 30, 60 }, { 20, 46 }, { 22, 32 }, { 30, 24 } } })
    local body = "M28 66 C26 56 36 50 50 50 C64 50 76 52 82 58 C84 64 82 72 76 76 C64 80 46 80 36 76 C30 74 28 70 28 66Z"
    local under = "M82 58 C84 64 82 72 76 76 C64 80 46 80 36 76 C46 76 58 75.4 68 73.4 C74 71.6 78 67 79 62 C80 60.6 81 59 82 58Z"
    local patches = "M52 50 C62 50 70 51 76 53.6 C72 57.6 64 59 57 58 C53 57 51 54 52 50Z M28 66 C26 56 36 50 46 50.2 C44 55 38 59 32 62.4Z"
    local claws = path("M108.6 46.6 L111.6 44.6 L109.6 47.8Z M109.2 49.8 L112.6 49.2 L109.6 51Z M108.2 52.8 L111.2 53.4 L108.2 54.2Z", k.white, k.ink, .6)
    return ellipse(56, 82, 30, 2, 0, k.ground) .. tail(k, t, 13, 10.6)
        .. leg(k, { { 40, 70 }, { 34, 76 }, { 36, 81 } }, 8.4, true) .. leg(k, { { 74, 70 }, { 76, 76 }, { 78, 81 } }, 7.4, true)
        .. leg(k, { { 46, 72 }, { 42, 78 }, { 44, 81 } }, 8.8, false, left)
        .. coatSide(k, o, body, under, patches)
        .. Svg.stem(Svg.spline({ { 80, 62 }, { 94, 56 }, { 104, 51 } }, 6), Svg.taper(8, 7), k.white, k.ink, 1.3) .. ellipse(105.6, 50.4, 4.6, 3.6, -20, k.white, k.ink, 1.2) .. claws
        .. headSide(k, 88, 47, 8, 1.02, { side = o.side, eye = "squint", mouth = "fangs", ears = "back" })
end

-- Eating: crouched over her dish, head down, eyes shut with joy, the salami
-- going fast (her photo at the yogurt dish). Salami is her favourite thing
-- in the known universe.
function POSES.eat(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 26, 64 }, { 16, 54 }, { 16, 40 }, { 24, 34 } },
        b = { { 26, 64 }, { 14, 60 }, { 8, 50 }, { 10, 40 } },
        c = { { 26, 64 }, { 18, 50 }, { 24, 40 }, { 32, 38 } } })
    local body = "M24 72 C22 62 30 56 44 55 C58 54 72 56 80 62 C84 66 84 74 80 78 C72 82 52 82 38 81 C28 80 24 77 24 72Z"
    local under = "M80 62 C84 66 84 74 80 78 C72 82 52 82 38 81 C48 80 60 79 70 77 C76 75 78.6 71 79 66 C79.2 64.6 79.6 63 80 62Z"
    local patches = "M46 55 C56 54.2 66 55 74 58 C70 62 62 63.6 54 63 C49 62.4 46 59 46 55Z M24 72 C22 62 30 56 40 55.2 C38 60 34 64 28 67.6Z"
    local dish = path("M86 74 L114 74 C113 79 109 82 100 82 C91 82 87 79 86 74Z", k.dish, k.ink, 1.3) .. ellipse(100, 74, 14, 2.6, 0, k.dish, k.ink, 1.1)
        .. ellipse(95, 72.6, 4, 1.6, 0, k.meat, k.ink, .8) .. ellipse(104, 72.4, 4, 1.6, 0, k.meat, k.ink, .8)
        .. circle(94, 72.4, .5, k.white) .. circle(96.4, 72.8, .5, k.white) .. circle(103, 72.2, .5, k.white) .. circle(105.4, 72.6, .5, k.white)
    return ellipse(56, 82.6, 30, 2, 0, k.ground) .. tail(k, t, 8.6, 7.2)
        .. leg(k, { { 34, 74 }, { 30, 78 }, { 32, 81 } }, 8, true) .. leg(k, { { 74, 72 }, { 78, 77 }, { 80, 81 } }, 7.2, true)
        .. leg(k, { { 38, 76 }, { 36, 79 }, { 38, 81 } }, 8.6, false, left) .. leg(k, { { 78, 74 }, { 82, 78 }, { 84, 81 } }, 7.6)
        .. coatSide(k, o, body, under, patches)
        .. dish .. headSide(k, 90, 64, 36, .98, { side = o.side, eye = "shut", mouth = "chew" })
end

-- Hunting her enemy, the lizard: flat to the ground, eyes wide, ears up and
-- forward, hindquarters set to spring, the tip of her tail twitching. The
-- lizard basks on a stone, not yet aware.
function POSES.lizard(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 22, 66 }, { 10, 70 }, { 2, 68 }, { 0, 62 } },
        b = { { 22, 66 }, { 10, 66 }, { 3, 60 }, { 4, 54 } },
        c = { { 22, 66 }, { 11, 72 }, { 4, 74 }, { 1, 70 } } })
    local body = "M20 70 C18 60 28 54 42 56 C56 58 66 62 74 66 C78 70 78 76 72 78 C60 80 40 80 30 79 C24 78 20 75 20 70Z"
    local under = "M74 66 C78 70 78 76 72 78 C60 80 40 80 30 79 C40 78 52 77 62 75.6 C68 74.6 71.6 71 72.6 67.4 C73 67 73.6 66.6 74 66Z"
    local patches = "M42 56 C52 57.4 60 59.6 68 63 C63 66 56 66.6 50 65.6 C44 64.4 41 60.6 42 56Z M20 70 C18 60 28 54 36 55 C34 60 30 64 24 67Z"
    local lizard = group(108, 76, 0, path("M-11 4 C-14 0 14 0 14 4Z", k.stone, k.ink, 1.1)
        .. path("M-6 0 C-3 -2.6 3 -3 7 -1.4 C9 -.8 10 .4 8 .8 C3 1.4 -2 1.4 -6 0Z", k.lizard, k.ink, .9)
        .. path("M-6 0 C-9 .2 -11.6 -1.2 -11.4 -3.6 C-11.2 -5 -9.6 -5.4 -9.4 -4.2", nil, k.ink, 1.6) .. line("M-6 0 C-9 .2 -11.6 -1.2 -11.4 -3.6 C-11.2 -5 -9.6 -5.4 -9.4 -4.2", k.lizard, .9)
        .. line("M-2 0 L-4 2.4 M-1 -.8 L-2 -3.2 M4 0 L6 2.2 M4.6 -1 L6 -3.4", k.ink, .9) .. circle(6.6, -1, .5, k.ink))
    local hunter = tail(k, t, 8, 6.8)
        .. leg(k, { { 30, 72 }, { 24, 77 }, { 26, 81 } }, 8, true) .. leg(k, { { 66, 72 }, { 74, 78 }, { 80, 81 } }, 7, true)
        .. leg(k, { { 34, 76 }, { 30, 79 }, { 32, 81 } }, 8.6, false, left) .. leg(k, { { 70, 74 }, { 78, 79 }, { 85, 81 } }, 7.4)
        .. coatSide(k, o, body, under, patches)
        .. headSide(k, 82, 66, 4, .98, { side = o.side, eye = "wide", mouth = "shut" })
    return ellipse(50, 82.4, 30, 1.8, 0, k.ground) .. lizard .. group(-6, 0, 0, hunter)
end

-- Tail end up for a pat: front low, back legs straight, tail straight up, and
-- her face turned to you with her eyes shut, very pleased. The left side takes
-- a hundred and forty pats; the right side allows three.
function POSES.butt(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 30, 40 }, { 29, 26 }, { 30, 12 }, { 33, 4 } },
        b = { { 30, 40 }, { 26, 26 }, { 22, 14 }, { 24, 5 } },
        c = { { 30, 40 }, { 32, 26 }, { 38, 14 }, { 44, 8 } } })
    local body = "M26 46 C26 38 34 34 44 36 C56 38 70 46 80 52 C86 56 86 64 80 66 C72 68 60 66 50 62 C40 58 30 56 27 52 C26 50 26 48 26 46Z"
    local under = "M80 52 C86 56 86 64 80 66 C72 68 60 66 50 62 C40 58 30 56 27 52 C36 54 46 56 56 57.6 C66 59 74 58 78.6 55 C79 54 79.6 53 80 52Z"
    local patches = "M44 36 C54 37.6 64 42 72 47 C68 50 60 50.6 54 49 C48 47.4 44 42 44 36Z M26 46 C26 38 34 34 40 35.2 C38 40 34 44 28.6 47.4Z"
    return ellipse(56, 82.4, 30, 1.8, 0, k.ground) .. tail(k, t, 9, 7.6)
        .. leg(k, { { 32, 50 }, { 30, 66 }, { 30, 81 } }, 8, true) .. leg(k, { { 74, 62 }, { 74, 72 }, { 75, 81 } }, 7.2, true)
        .. leg(k, { { 38, 52 }, { 37, 66 }, { 38, 81 } }, 8.6, false, left) .. leg(k, { { 79, 62 }, { 80, 72 }, { 81, 81 } }, 7.6)
        .. coatSide(k, o, body, under, patches)
        .. face(k, 90, 52, 10, .94, { mask = mask(o), eye = "shut", mouth = "shut" })
end

-- The queen on her throne: sitting square on a plum velvet cushion with gold
-- tassels, a small gold crown between her ears. Supreme ruler of the known
-- and unknown universe, and she knows it.
function POSES.throne(k, o)
    local t = wag(o.tail, {
        a = { { 86, 70 }, { 98, 70 }, { 104, 62 }, { 102, 52 } },
        b = { { 86, 72 }, { 100, 76 }, { 108, 72 }, { 110, 64 } },
        c = { { 86, 70 }, { 96, 62 }, { 96, 50 }, { 90, 44 } } })
    local cushion = path("M20 74 C20 69 30 68 60 68 C90 68 100 69 100 74 C100 80 90 82 60 82 C30 82 20 80 20 74Z", k.cushion, k.ink, 1.4)
        .. line("M30 72 C46 74 74 74 90 72", mix(k.cushion, k.ink, .3), .8)
        .. path("M20 75 L16 80 L22 79Z M100 75 L104 80 L98 79Z", k.gold, k.ink, .8)
    local crown = group(60, 12, 0, path("M-7 2 L-7 -3 L-4 0 L0 -5 L4 0 L7 -3 L7 2Z", k.gold, k.ink, 1) .. circle(0, -5.4, .9, k.cushion) .. circle(-7, -3.4, .7, k.white) .. circle(7, -3.4, .7, k.white))
    return tail(k, t, 9, 7.6) .. cushion .. group(0, -6, 0, frontSit(k))
        .. face(k, 60, 26, 0, 1.06, { mask = mask(o), eye = "squint", mouth = "shut" }) .. crown
end

-- Sprinting out of the litter box the moment she is done, as she always
-- does: flat out in the air, front paws reaching, ears back, tail streaming,
-- a puff of litter left behind.
function POSES.sprint(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 24, 47 }, { 13, 42 }, { 4, 40 }, { 0, 36 } },
        b = { { 24, 47 }, { 14, 38 }, { 8, 30 }, { 6, 22 } },
        c = { { 24, 47 }, { 12, 48 }, { 4, 52 }, { 0, 50 } } })
    local body = "M22 50 C22 42 32 38 46 38 C62 38 76 40 86 44 C92 47 92 54 88 58 C80 62 66 60 54 60 C40 60 28 58 24 56 C22 54 22 52 22 50Z"
    local under = "M86 44 C92 47 92 54 88 58 C80 62 66 60 54 60 C40 60 28 58 24 56 C36 56.6 48 56.6 60 55.6 C72 54.4 80 52 84.6 48 C85 46.6 85.4 45.2 86 44Z"
    local patches = "M46 38 C58 38 70 39.4 80 42 C76 46 68 47.6 60 47.2 C52 46.6 46 43 46 38Z M22 50 C22 42 32 38 40 38.2 C38 43 33 47 26 50.6Z"
    local dust = circle(6, 78, 3, k.stone, k.ink, .8) .. circle(12, 80, 2.2, k.stone, k.ink, .8) .. circle(2, 81, 1.8, k.stone, k.ink, .8) .. circle(17, 79, 1.4, k.stone, k.ink, .7)
    return dust .. tail(k, t, 8.4, 7)
        .. leg(k, { { 80, 56 }, { 90, 64 }, { 97, 70 } }, 7, true) .. leg(k, { { 32, 56 }, { 24, 64 }, { 17, 70 } }, 7.6, true)
        .. leg(k, { { 84, 53 }, { 98, 58 }, { 110, 60 } }, 7.4) .. leg(k, { { 28, 54 }, { 16, 60 }, { 5, 62 } }, 8, false, left)
        .. coatSide(k, o, body, under, patches)
        .. headSide(k, 95, 40, 8, 1, { side = o.side, eye = "wide", mouth = "shut", ears = "back" })
end

-- Playing, in a short burst: on her side, one paw up at a feather on a
-- string. Three swats, then she remembers how tiring play is.
function POSES.play(k, o)
    local t = wag(o.tail, {
        a = { { 22, 66 }, { 12, 60 }, { 6, 52 }, { 8, 44 } },
        b = { { 22, 66 }, { 12, 66 }, { 4, 60 }, { 3, 52 } },
        c = { { 22, 66 }, { 14, 56 }, { 16, 46 }, { 22, 42 } } })
    local toy = line("M114 0 C112 14 108 26 104 36", k.ink, .7)
        .. group(104, 38, 24, path("M0 0 C-3 4 -3 10 0 14 C3 10 3 4 0 0Z", k.gold, k.ink, .9) .. line("M0 1 L0 13", k.ink, .5))
        .. group(104, 38, -10, path("M0 0 C-2.4 3 -2.4 8 0 11 C2.4 8 2.4 3 0 0Z", k.meat, k.ink, .8))
    return ellipse(56, 82, 46, 2, 0, k.ground) .. toy .. tail(k, t, 8.6, 7.2)
        .. leg(k, { { 28, 74 }, { 16, 77 }, { 6, 77 } }, 7.4, true) .. leg(k, { { 30, 77 }, { 18, 80 }, { 8, 81 } }, 7.8, false, o.side == "left")
        .. coatSide(k, o, SLEEPER, SLEEPER_UNDER, SLEEPER_PATCHES)
        .. leg(k, { { 84, 74 }, { 98, 78 }, { 110, 79 } }, 7.4)
        .. Svg.stem(Svg.spline({ { 82, 68 }, { 94, 60 }, { 101, 50 } }, 6), Svg.taper(7.4, 6.8), k.white, k.ink, 1.3) .. paw(k, 102, 47.6, 8, true)
        .. headSide(k, 84, 61, -24, .96, { side = o.side, eye = "up", mouth = "blep" })
end

-- Hissing at another cat that dared to look at her: back arched high, legs
-- stiff, tail puffed to a bottle brush, fangs out. She hates other cats. All
-- of them.
function POSES.hiss(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 30, 52 }, { 22, 38 }, { 22, 22 }, { 28, 14 } },
        b = { { 30, 52 }, { 18, 42 }, { 12, 28 }, { 14, 16 } },
        c = { { 30, 52 }, { 26, 36 }, { 32, 22 }, { 40, 16 } } })
    local body = "M28 64 C26 50 36 32 54 30 C70 30 80 42 84 54 C85 61 82 66 78 66 C70 62 60 60 50 60 C40 60 32 64 28 64Z"
    local under = "M84 54 C85 61 82 66 78 66 C70 62 60 60 50 60 C40 60 32 64 28 64 C34 58 42 55.6 52 55.6 C62 55.6 72 57.6 78 60 C80 58.6 81.6 56.4 84 54Z"
    local patches = "M54 30 C66 30 74 36.4 79 44 C73 46 66 45.6 60 43 C55 40.6 52.4 35.6 54 30Z M28 64 C26 50 36 32 46 30.8 C44 38 38 46 32 52 C30 56 29 60 28.6 64Z"
    return ellipse(58, 82.4, 30, 1.8, 0, k.ground) .. tail(k, t, 14, 11.6)
        .. leg(k, { { 33, 60 }, { 32, 70 }, { 32, 81 } }, 7.6, true) .. leg(k, { { 76, 62 }, { 77, 72 }, { 78, 81 } }, 7, true)
        .. leg(k, { { 39, 61 }, { 39, 71 }, { 39, 81 } }, 8, false, left) .. leg(k, { { 81, 62 }, { 82, 72 }, { 84, 81 } }, 7.4)
        .. coatSide(k, o, body, under, patches)
        .. headSide(k, 91, 58, 14, 1, { side = o.side, eye = "squint", mouth = "fangs", ears = "back" })
        .. line("M110 60 L115 58 M110.6 63 L116 63.4 M110 66 L114.6 68", k.ink, .8)
end

-- The poses by name; "1" and "2" are the ones the rest of the garden asks for.
POSES["1"] = POSES.sit
POSES["2"] = POSES.loaf

Cat.POSES = POSES

-- Draw Yüzsüz in the pose `name` ("sit", "loaf", "walk"...; "1" and "2" too),
-- facing right, the side shown chosen by `flip`.
function Cat.yuzsuz(c, second, name, flip)
    local k = coat(c)
    local pose, t = tostring(name or (second and "2" or "1")):match("^([%w_]+)%.?(%a?)$")
    local draw = POSES[pose or ""] or POSES.sit
    return draw(k, { side = flip and "right" or "left", flip = flip, tail = t ~= "" and t or "a" })
end

return Cat
