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
        iris = mix(mix(c.gold, c.leaf, .42), c.ink, .35), ground = mix(c.cream, c.muted, .3),
        skin = mix(mix(c.bloom2, c.gold, .45), c.cream, .5) }
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

-- A leg that grows out of her body, through the joints in `way` and as wide
-- at each as `ws` says: no line across its top, the edges inked from `a` and
-- `b` of the way down (see Svg.limb), ending in a paw that points forward
-- (`dir` 1), back (-1) or hangs with no paw drawn (0). `fill` is its colour;
-- with `sock` the leg is that colour down to there (0 to 1) and white below,
-- as her hind legs are on her left side.
local function limb(k, way, ws, fill, a, b, dir, sock)
    local pts = Svg.spline(way, 8)
    local w = Svg.widths(ws)
    local tip = way[#way]
    local foot = sock and k.white or fill
    local out = Svg.limb(pts, w, fill, k.ink, 1.3, a, b)
    if sock then
        local low = {}
        for i = math.floor(#pts * sock) + 1, #pts do low[#low + 1] = pts[i] end
        out = out .. Svg.limb(low, function(t) return w(sock + t * (1 - sock)) end, k.white, k.ink, 1.3, .08)
    end
    dir = dir or 1
    if dir == 0 then return out end
    local s = ws[#ws]
    return out .. ellipse(tip[1] + dir * s * .24, tip[2] - s * .16, s * .64, s * .4, 0, foot, k.ink, 1.2)
        .. line(string.format("M%s %s l0 1.6 M%s %s l0 1.6", n(tip[1] + dir * s * .2), n(tip[2] - s * .22), n(tip[1] + dir * s * .5), n(tip[2] - s * .22)), k.ink, .6)
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

-- Loafing: a compact round loaf seen from her side with her face turned to
-- you, the front paws tucked under her chest so only their round ends show,
-- the haunch a soft curve at the back and her tail brought round along her
-- side (her photos on the sofa and the bed, looking at you).
function POSES.loaf(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 17.4, 65 }, { 20, 74.6 }, { 33, 78.4 }, { 51, 77.4 } },
        b = { { 24, 74 }, { 16, 78.4 }, { 8, 78 }, { 3.6, 73 } },
        c = { { 22, 70 }, { 12, 66 }, { 8, 56 }, { 12, 48 } } })
    local body = "M24 82 C17 76 16.6 62 24 54 C31 46.6 42 44 54 43.6 C64 43.2 74 44 80 46 C88 50 92.4 58 92 68 C91.8 74 89.6 79 86 82Z"
    local under = "M62 45 C60.6 54 60.6 62 62.6 69 C63.6 72.6 62 75.6 58 77 C50 79 40 79.6 32 82 L86 82 C89.6 79 91.8 74 92 68 C92.4 58 88 50 80 46 C74 44.4 68 44.2 62 45Z"
        .. " M56.6 43.8 C58 47.6 60.6 50.6 64 52.4 L65.6 48 C63.4 46.8 61.6 45.4 60.4 43.6Z"
    local patches = "M29.4 49.6 C36 45.6 45 43.9 54 43.6 C56 48 54 53 48 55.6 C41 58 33.6 55.4 29.4 49.6Z M60 43.5 C66 43.4 72 43.8 77 45 C77.4 50.6 73 55 67.6 55 C63 54.6 60 49.6 60 43.5Z"
    local front = (o.tail or "a") == "a"
    local fur = line("M27 77 C25 67 33 59.4 45 59.8 C52 60 57 64 58.6 70", left and k.sheen or k.shade, 1)
        .. line("M35 50.6 C41 47.8 47 46.6 53 46.4", left and k.sheen or k.shade, 1)
        .. line("M70 54 l1.4 1.8 M77 56 l1.4 1.8 M83 58 l1.4 1.8 M73 61 l1.4 1.8 M80 64 l1.4 1.8 M86 65 l1.2 1.8 M70 67 l1.4 1.8", k.shade, .7)
        .. line("M64 71 C67 73.6 71 75 76 75.4 M79.6 75.6 C83 75.4 86 76 88.6 77.4", k.shade, .9)
    local paws = ellipse(72, 79.2, 7.6, 3.3, 0, k.white, k.ink, 1.2) .. line("M74.6 78 l0 2 M77 78.4 l0 1.8", k.ink, .6)
        .. ellipse(85, 79.6, 5.6, 3, 0, k.white, k.ink, 1.2) .. line("M86.6 78.6 l0 1.8 M88.6 79 l0 1.6", k.ink, .6)
    local hind = front and "" or (ellipse(47, 80.4, 6.6, 2.6, 0, k.white, k.ink, 1.2) .. line("M49.6 79.6 l0 1.6 M51.6 79.8 l0 1.4", k.ink, .6))
    -- brought round, the tail comes out from behind her rump before it lies along her side
    local root = { { 32, 60 }, { 22, 58.6 }, { 17, 63 }, { 17.6, 70 } }
    return ellipse(56, 82.6, 42, 2.4, 0, k.ground) .. tail(k, front and root or t, 9, front and 8.6 or 7.4)
        .. coatSide(k, o, body, under, patches) .. fur .. hind .. paws .. (front and tail(k, t, 8.6, 7) or "")
        .. face(k, 76, 34.6, 0, 1.1, { mask = mask(o), eye = o.eye or "open", mouth = o.mouth or "shut" })
end

-- Walking, seen from the side, her tail up in a curl (her photos on the
-- radiator, the carved table and across the bed): the near foreleg straight
-- under the shoulder, the far one reaching for the next step, the near hind
-- leg pushing off behind with its hock bent back, the far one drawn up under
-- the belly.
function POSES.walk(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 32, 45 }, { 23, 32 }, { 24, 16 }, { 33, 8 } },
        b = { { 32, 45 }, { 21, 36 }, { 15, 22 }, { 17, 10 } },
        c = { { 32, 45 }, { 25, 30 }, { 31, 16 }, { 41, 12 } } })
    local body = "M29 49 C28 41 36 35.4 48 34.8 C60 34.2 72 33.6 80 36 C85.6 38 88 43.6 88 50 C88 56 85 60.6 80 62.6 C72 65.6 60 66.6 50 65.6 C42 64.8 35 62.6 31.6 58 C29.6 55.4 29.2 52 29 49Z"
    local under = "M84.6 38.6 C87 42 88 46 88 50 C88 56 85 60.6 80 62.6 C72 65.6 60 66.6 50 65.6 C46 65.2 42 64.4 38.6 63 C46 63.8 56 63.6 63 62.6 C68 61.8 71.6 59.6 73.4 56 C75 52 75.6 47 76 42 C76.2 40 76.6 38.4 77.4 37 L78.6 36.4 C80.6 37.4 82.6 38 84.6 38.6Z"
    local patches = "M56 34.4 C64 34 70 34 76 35 C75.4 41 69.6 44.4 63 43.6 C58.4 42.6 55.6 38.6 56 34.4Z M29 49 C28 41 36 35.4 47 34.8 C46 40 41.6 44 36.6 46.6 C33 48.4 30.8 50.6 29.8 53.6Z"
    local far = mix(k.white, k.lid, .4)
    return ellipse(58, 82.6, 32, 2, 0, k.ground) .. tail(k, t, 8.6, 7.2)
        .. limb(k, { { 47, 58 }, { 54, 67 }, { 48, 74 }, { 51, 80.8 } }, { 11, 8.4, 6.6, 6.4 }, far, 0, 0)
        .. limb(k, { { 81, 56 }, { 85, 66 }, { 88.6, 74 }, { 90.6, 80.8 } }, { 9, 7.6, 6.6, 6.4 }, far, 0, 0)
        .. coatSide(k, o, body, under, patches)
        .. limb(k, { { 40, 50 }, { 45, 62 }, { 34, 70 }, { 32, 80.8 } }, { 17, 12, 7.6, 7 }, left and k.black or k.white, .22, .3, 1, left and .66 or nil)
        .. limb(k, { { 79, 58 }, { 79, 66 }, { 79, 74 }, { 79.2, 80.8 } }, { 10, 9, 8, 7.6 }, k.white, .2, .2)
        .. line("M36 55 C39 49 45 45.6 52 45", left and k.sheen or k.shade, 1)
        .. headSide(k, 92, 33, 5, 1.02, { side = o.side, eye = "open", mouth = o.mouth or "blep" })
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

-- Her body sitting up on her haunches seen from the side, facing right: the
-- round haunch on the ground with the hind foot out in front of it, the back
-- rising to the shoulders and a deep chest. The forelegs and head are the
-- pose's own.
local function sitSide(k, o)
    local left = o.side == "left"
    local body = "M36 82 C27 80.6 23.6 71 26.6 62 C29.6 52 38 44 48 39.6 C53 37.4 58 36.4 63 36.6 L72 40 C76.6 45 78 53 76.4 61 C75.4 66 74 71 73.4 76 L72.6 82Z"
    local under = "M66.6 37.8 L72 40 C76.6 45 78 53 76.4 61 C75.4 66 74 71 73.4 76 L72.6 82 L58 82 C62.6 76 65 69 65.4 62 C65.8 54 64.6 46 62.6 40.6 C63.6 39 65 38 66.6 37.8Z"
    local patches = "M51 38.4 C55 36.9 59 36.4 63 36.6 L67 38.2 C68 43.6 66 48.4 61 50 C55.6 51 51.6 46 51 38.4Z M26.6 62 C28.6 55 34.6 48 41.6 43.4 C45 47.6 45 53.6 41 58 C37 61.8 31 63.2 26.6 62Z"
    return coatSide(k, o, body, under, patches)
        .. line("M31 79 C28 68 35 60.4 46 60.4 C54 60.4 59.6 65 61 72", left and k.sheen or k.shade, 1)
        .. line("M36 51 C40 47 45 44 50 42", left and k.sheen or k.shade, 1)
        .. ellipse(63, 80.2, 8.4, 2.8, 0, k.white, k.ink, 1.2) .. line("M66.6 79.4 l0 1.6 M69 79.6 l0 1.4", k.ink, .6)
        .. (left and ellipse(56.6, 79.6, 2, 1.8, 0, k.black) or "")
end

-- Biting the hand that patted her once too often: sitting up, she has the
-- arm held fast between both forepaws, claws out, and her teeth in the hand,
-- ears flat, eyes narrowed and her tail fluffed up and lashing.
function POSES.bite(k, o)
    local t = wag(o.tail, {
        a = { { 29, 73 }, { 18, 68 }, { 11, 56 }, { 14, 44 } },
        b = { { 29, 74 }, { 17, 76 }, { 7, 70 }, { 4, 60 } },
        c = { { 29, 72 }, { 20, 62 }, { 20, 50 }, { 27, 42 } } })
    local far = mix(k.white, k.lid, .4)
    local arm = Svg.stem(Svg.spline({ { 119, 60 }, { 110, 54.6 }, { 102, 49.6 } }, 6), Svg.taper(9.6, 8.4), k.skin, k.ink, 1.3)
        .. Svg.stem({ { 119.4, 60.2 }, { 112.4, 56 } }, 12, k.dish, k.ink, 1.3)
        .. ellipse(104, 42, 2.8, 5, 30, k.skin, k.ink, 1.2) .. ellipse(98.6, 46.6, 8, 5.6, 28, k.skin, k.ink, 1.3)
    local claws = path("M100.4 50.6 L101.6 53.4 L102.4 50.8Z M103 51 L104.4 53.6 L105 51Z M105.6 51.6 L107.2 53.8 L107.4 51.4Z", k.white, k.ink, .6)
    local ouch = line("M104 35 L106 30.6 M108.6 38 L112.6 34.6 M111 42.6 L116 41.4", k.ink, 1)
    return ellipse(56, 82.6, 34, 2.2, 0, k.ground) .. tail(k, t, 12.4, 10)
        .. limb(k, { { 70, 57 }, { 81, 64 }, { 93, 62 }, { 103, 58.6 } }, { 9, 8, 7, 6.8 }, far, 0, 0)
        .. sitSide(k, o) .. arm
        .. limb(k, { { 68, 52 }, { 79, 57.6 }, { 91, 54 }, { 101, 50.4 } }, { 10, 8.6, 7.6, 7.2 }, k.white, .2, .2) .. claws
        .. headSide(k, 81, 36, 16, 1.02, { side = o.side, eye = "squint", mouth = "fangs", ears = "back" }) .. ouch
end

-- Eating: crouched low over her dish with her shoulders up and her haunches
-- folded under her, head down, eyes shut with joy, the salami going fast
-- (her photo at the yogurt dish). Salami is her favourite thing in the
-- known universe.
function POSES.eat(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 26, 70 }, { 15, 62 }, { 12, 48 }, { 19, 39 } },
        b = { { 26, 72 }, { 14, 74 }, { 6, 68 }, { 4, 58 } },
        c = { { 26, 70 }, { 17, 58 }, { 21, 46 }, { 30, 42 } } })
    local body = "M26 79 C20 71 22 59 31 53 C39 47.6 50 46 60 47 C63 45.4 67 45.4 70 47.6 C76 50 81 54.6 83 60 C85 66 84 73 80.6 78 C79 80.6 76 82 72 82 L32 82 C29 82 27 80.6 26 79Z"
    local under = "M83 60 C85 66 84 73 80.6 78 C79 80.6 76 82 72 82 L38 82 C48 80.8 58 79.6 66 77.4 C71.6 75.6 75 71.6 76.4 66.6 C77.4 63.6 79.6 61 83 60Z"
    local patches = "M31 53 C39 47.6 48 46 56 46.6 C56.6 52 52 56.6 45 57.6 C39 58 34 56.6 31 53Z M61 46.6 C64 45.3 67.6 45.6 70 47.6 C73 49 75.6 51 77.6 53.6 C76 58 71 60 66.6 58.6 C62 57 60 52 61 46.6Z"
    local dish = path("M86 74 L114 74 C113 79 109 82 100 82 C91 82 87 79 86 74Z", k.dish, k.ink, 1.3) .. ellipse(100, 74, 14, 2.6, 0, k.dish, k.ink, 1.1)
        .. ellipse(95, 72.6, 4, 1.6, 0, k.meat, k.ink, .8) .. ellipse(104, 72.4, 4, 1.6, 0, k.meat, k.ink, .8)
        .. circle(94, 72.4, .5, k.white) .. circle(96.4, 72.8, .5, k.white) .. circle(103, 72.2, .5, k.white) .. circle(105.4, 72.6, .5, k.white)
    return ellipse(58, 82.6, 34, 2, 0, k.ground) .. tail(k, t, 8.6, 7.2)
        .. ellipse(84.6, 80.2, 5, 2.6, 0, mix(k.white, k.lid, .4), k.ink, 1.2)
        .. coatSide(k, o, body, under, patches)
        .. line("M30 79 C27 69 33 61.4 44 61 C52 60.8 57.6 65 59 72", left and k.sheen or k.shade, 1)
        .. line("M62 50 C65 48.4 68 48.6 70.6 50.4", left and k.sheen or k.shade, 1)
        .. ellipse(57, 80.2, 8, 2.7, 0, k.white, k.ink, 1.2) .. line("M60.4 79.4 l0 1.6 M62.8 79.6 l0 1.4", k.ink, .6)
        .. (left and ellipse(51, 79.6, 2, 1.8, 0, k.black) or "")
        .. limb(k, { { 71.6, 61 }, { 73.6, 69 }, { 75.6, 76 }, { 76.6, 80.8 } }, { 3, 9.6, 8.2, 7.6 }, k.white, .12, .12)
        .. dish .. headSide(k, 91, 63, 36, .98, { side = o.side, eye = "shut", mouth = "chew" })
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

-- Playing, in a short burst: sitting up on her haunches, eyes on a feather
-- on a string, one paw high to bat at it and the other on its way. Three
-- swats, then she remembers how tiring play is.
function POSES.play(k, o)
    local t = wag(o.tail, {
        a = { { 29, 74 }, { 18, 78 }, { 9, 74.6 }, { 5.6, 65 } },
        b = { { 29, 73 }, { 17, 70 }, { 10, 60 }, { 12, 49 } },
        c = { { 29, 75 }, { 18, 79 }, { 9, 78.6 }, { 4, 73 } } })
    local far = mix(k.white, k.lid, .4)
    local toy = line("M116 3 C115 9 113 14 110 18", k.ink, .8)
        .. group(110, 18, 30, path("M0 0 C-3.6 4.6 -3.6 12 0 17 C3.6 12 3.6 4.6 0 0Z", k.gold, k.ink, 1) .. line("M0 1 L0 16 M0 6 l-2 -1.6 M0 6 l2 -1.6 M0 10.6 l-2.2 -1.6 M0 10.6 l2.2 -1.6", k.ink, .5))
        .. group(110, 18, -4, path("M0 0 C-2.8 3.6 -2.8 9.6 0 13.6 C2.8 9.6 2.8 3.6 0 0Z", k.meat, k.ink, .9) .. line("M0 1 L0 12.6", k.ink, .5))
        .. circle(110, 18, 1.5, k.dish, k.ink, .8)
    local swish = line("M104 44 C106.6 42.6 108.6 40.6 110 38 M107 48 C110 46.4 112.6 44 114 41", k.ink, .8)
    return ellipse(56, 82.6, 34, 2.2, 0, k.ground) .. toy .. tail(k, t, 8.6, 7.2)
        .. limb(k, { { 70, 56 }, { 81, 62.6 }, { 91, 60 }, { 97, 54 } }, { 9, 8, 7, 6.8 }, far, 0, 0, 0) .. paw(k, 98, 52.4, 8, false, true)
        .. sitSide(k, o)
        .. limb(k, { { 68, 51 }, { 80, 55.6 }, { 92, 49 }, { 98.6, 40 } }, { 10, 8.6, 7.6, 7.2 }, k.white, .2, .2, 0) .. paw(k, 99.6, 37.6, 9, true)
        .. headSide(k, 79, 31, -22, 1.02, { side = o.side, eye = "up", mouth = "open" }) .. swish
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
