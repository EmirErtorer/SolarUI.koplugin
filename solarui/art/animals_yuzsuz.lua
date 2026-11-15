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
        lizard = mix(c.leaf, c.gold, .3), stone = mix(c.muted, c.cream, .5), bird = mix(c.muted, c.ink, .1) }
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

-- Her head seen from the side, facing right, centred on (x, y), turned by `rot`
-- and `s` times its size. o: side ("left" shows the black running down the
-- cheek), eye ("open", "up", "squint", "shut", "wide"), mouth ("shut", "blep",
-- "open", "fangs", "chew"), ears ("up" or "back").
local function headSide(k, x, y, rot, s, o)
    local left = o.side ~= "right"
    local eye = o.eye or "open"
    local mouth = o.mouth or "shut"
    local farEar = path("M-9.6 -9.4 L-9 -22 L-2.6 -13.4Z", k.black, k.ink, 1.3)
    local nearEar = path("M-3.6 -13.2 L1 -25 L7 -12.8Z", k.black, k.ink, 1.4) .. path("M-1.6 -13.4 L1.2 -21.4 L4.8 -13.2Z", k.pink)
        .. line("M-.4 -14 L.6 -18 M1.6 -14 L2.4 -18.6", k.white, .5)
    if o.ears == "back" then
        farEar = about(-6, -11, -46, farEar)
        nearEar = about(1, -13, -58, nearEar)
    end
    local skull = "M-12 -2 C-12 -10 -6 -14 1 -14 C7 -14 11 -11 13 -7 C14 -5 15.6 -3 16 -1 C16.4 1 15.4 2.6 14 3 C13 5 11.6 6.4 9.6 7 C6 9 0 10 -4 9.6 C-9 9 -12 5 -12 -2Z"
    local white = left
        and "M8.6 -12.2 C10.4 -11 12 -9.2 13 -7 C14 -5 15.6 -3 16 -1 C16.4 1 15.4 2.6 14 3 C13 5 11.6 6.4 9.6 7 C7.4 8.2 4.6 9.2 1.6 9.8 C2.4 6.4 4.6 2.6 7 .4 C8.6 -2.6 9.4 -7.6 8.6 -12.2Z"
        or "M8.6 -12.2 C10.4 -11 12 -9.2 13 -7 C14 -5 15.6 -3 16 -1 C16.4 1 15.4 2.6 14 3 C13 5 11.6 6.4 9.6 7 C6 9 0 10 -4 9.6 C-6 9.2 -7 8.4 -7.6 7.6 C-6 4 -3 1.6 1.4 1 C5 .4 7.6 -3 8 -6 C8.4 -8.6 8.6 -10.6 8.6 -12.2Z"
    local eyes
    if eye == "shut" then
        eyes = line("M2.6 -4.4 C4 -3 6.6 -3 8.2 -4.4", k.lid, 1.1)
    elseif eye == "squint" then
        eyes = path("M2.6 -4.2 C4.2 -5.2 6.6 -5.4 8.4 -5 C6.8 -3.8 4.4 -3.6 2.6 -4.2Z", k.eye, k.ink, .8) .. ellipse(5.8, -4.5, .6, .7, 0, k.ink)
            .. line("M2 -6.4 L8.6 -6", k.lid, 1)
    else
        local py = eye == "up" and -5.6 or -4.7
        local pw = eye == "wide" and 1.3 or .7
        eyes = path("M2.6 -4.4 C3.6 -6.6 7 -7 8.4 -5 C7.4 -2.8 4 -2.4 2.6 -4.4Z", k.eye, k.ink, .9) .. ellipse(6, py, pw, 1.5, 0, k.ink)
            .. circle(6.8, py - .8, .35, k.white)
    end
    local mouths = {
        shut = line("M15 .6 C14.6 2 13.6 3 12 3.4", k.ink, .9),
        blep = line("M15 .6 C14.6 2 13.6 3 12 3.4", k.ink, .9) .. path("M12.4 3.3 C12.3 5 13.9 5.6 14.4 4.1 C14.5 3.6 14.1 3 13.5 3Z", k.pink, k.ink, .6),
        open = path("M15.2 1.2 C13 2.8 10 4.4 8 4.8 C9 7.6 12 8.4 14 6.6 C14.6 5 15 3 15.2 1.2Z", k.mouth, k.ink, .9) .. path("M9.6 5.6 C11 7.4 13 7.4 13.8 6.2 C12 5.6 10.8 5.4 9.6 5.6Z", k.pink),
        fangs = path("M15.2 1.2 C13 2.8 10 4.4 8 4.8 C9 7.6 12 8.4 14 6.6 C14.6 5 15 3 15.2 1.2Z", k.mouth, k.ink, .9)
            .. path("M14.6 1.8 L14.2 4.2 L13.2 2.4Z M13 6.8 L12.6 4.8 L11.8 6.6Z", k.white, k.ink, .4),
        chew = line("M15 .6 C14.6 2 13.6 3 12 3.4", k.ink, .9) .. line("M11.4 4.6 C12.6 5.4 13.8 5.2 14.4 4.4", k.ink, .7),
    }
    local whiskers = line("M12.6 1 L21 -1.4 M12.8 1.8 L21.6 1.6 M12.4 2.6 L20.6 4.8", k.ink, .45)
    return group(x, y, rot, farEar .. path(skull, k.black, k.ink, 1.5) .. path(white, k.white) .. path(skull, nil, k.ink, 1.5)
        .. nearEar .. eyes .. path("M14.6 -2.8 L16.3 -1.6 L15.2 .3Z", k.nose, k.ink, .5) .. (mouths[mouth] or mouths.shut) .. whiskers, s)
end

-- Her head seen from the front, centred on (x, y), turned by `rot` and `s`
-- times its size. o: mask ("right": the cheek on the viewer's right is black,
-- as it is when she faces you; "left" when mirrored), eye, mouth, ears.
local function headFront(k, x, y, rot, s, o)
    local eye = o.eye or "open"
    local mouth = o.mouth or "shut"
    local ear = path("M-13 -6 L-12.4 -23 L-3.6 -13.6Z", k.black, k.ink, 1.4) .. path("M-11.4 -9.4 L-11.2 -19.6 L-5.6 -13.6Z", k.pink)
        .. line("M-10.4 -11 L-9 -15 M-8.6 -11.6 L-7.6 -15.4", k.white, .5)
    if o.ears == "back" then ear = about(-8, -12, -40, ear) end
    local face = "M-14 -2 C-14 -11 -8 -15 0 -15 C8 -15 14 -11 14 -2 C14 6 9 11 0 11.6 C-9 11 -14 6 -14 -2Z"
    local white = "M0 -10.6 C.8 -8.4 1.8 -6.6 2.4 -4.6 C3 -2 3.8 1 5.6 3.6 C7 5.6 8.4 7.6 8.6 9 C6 10.8 3 11.6 0 11.6 C-9 11 -14 6 -14 -2 C-11 -2.4 -7.6 -2 -5 -1.4 C-3.4 -1.6 -2.6 -3 -2.2 -4.6 C-1.6 -6.8 -.8 -8.6 0 -10.6Z"
    local mask = group(0, 0, 0, path(white, k.white), o.mask == "left" and -1 or 1, 1)
    local function oneEye(side)
        local e
        if eye == "shut" then
            e = line("M-9 -4.6 C-7.6 -3.2 -4.8 -3.2 -3.4 -4.6", k.lid, 1.1)
        elseif eye == "squint" then
            e = path("M-9 -4.4 C-7.6 -5.6 -4.8 -5.8 -3.2 -5.2 C-4.6 -4 -7.4 -3.8 -9 -4.4Z", k.eye, k.ink, .8) .. ellipse(-6, -4.7, .6, .7, 0, k.ink)
                .. line("M-9.6 -6.8 L-3 -6", k.lid, 1)
        else
            local py = eye == "up" and -6.2 or -5.1
            local pw = eye == "wide" and 1.4 or .8
            e = path("M-9.2 -5 C-8 -7.4 -4.6 -7.6 -3.2 -5.4 C-4.4 -3.2 -7.8 -2.8 -9.2 -5Z", k.eye, k.ink, .9) .. ellipse(-6.2, py, pw, 1.7, 0, k.ink)
                .. circle(-5.4, py - .9, .4, k.white)
        end
        return group(0, 0, 0, e, side, 1)
    end
    local mouths = {
        shut = line("M0 1.6 L0 3 M0 3 C-1 4.2 -2.4 4.2 -3 3.4 M0 3 C1 4.2 2.4 4.2 3 3.4", k.ink, .9),
        blep = line("M0 1.6 L0 3 M0 3 C-1 4.2 -2.4 4.2 -3 3.4 M0 3 C1 4.2 2.4 4.2 3 3.4", k.ink, .9) .. path("M-.9 3.8 C-.9 5.8 .9 5.8 .9 3.8Z", k.pink, k.ink, .5),
        open = ellipse(0, 5, 3.2, 2.8, 0, k.mouth, k.ink, .9) .. ellipse(0, 6.4, 2, 1.2, 0, k.pink) .. line("M0 1.6 L0 2.4", k.ink, .9),
        fangs = ellipse(0, 5.2, 3.6, 3.2, 0, k.mouth, k.ink, .9) .. path("M-2.6 3 L-2 5.6 L-1.2 3.2Z M2.6 3 L2 5.6 L1.2 3.2Z", k.white, k.ink, .4) .. line("M0 1.6 L0 2.2", k.ink, .9),
        chew = line("M0 1.6 L0 3 M-2.6 3.6 C-1 4.8 1 4.8 2.6 3.6", k.ink, .9),
    }
    local whiskers = line("M-3 1.6 L-13 -.4 M-3 2.4 L-13.6 2.6 M-3 3.2 L-12.4 5.6 M3 1.6 L13 -.4 M3 2.4 L13.6 2.6 M3 3.2 L12.4 5.6", k.ink, .45)
    return group(x, y, rot, ear .. group(0, 0, 0, ear, -1, 1) .. path(face, k.black, k.ink, 1.5) .. mask .. path(face, nil, k.ink, 1.5)
        .. oneEye(1) .. oneEye(-1) .. path("M-1.8 -.4 L1.8 -.4 L0 1.6Z", k.nose, k.ink, .5) .. (mouths[mouth] or mouths.shut) .. whiskers, s)
end

-- The place of her tail in a pose: "a", "b" or "c" from the pose name, "a" by default.
local function wag(t, ways)
    return ways[t] or ways.a
end

local POSES = {}

-- Sitting up, seen from the side, chin raised to watch something above (her
-- photos on the sofa, looking up).
function POSES.sit(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 30, 79 }, { 44, 82.6 }, { 64, 82.4 }, { 82, 79.4 } },
        b = { { 28, 72 }, { 14, 66 }, { 9, 50 }, { 15, 40 } },
        c = { { 28, 77 }, { 15, 81 }, { 5, 77 }, { 3, 69 } } })
    local tailFront = o.tail ~= "b" and o.tail ~= "c"
    local body = "M34 82 C24 82 20 72 23 61 C26 50 36 41 47 36 C53 33 58 31 63 31 L72 37 C76 46 77 57 73 66 C71 72 70 77 70 82Z"
    local black = left and "M34 82 C24 82 20 72 23 61 C26 50 36 41 47 36 C53 33 58 31 63 31 L68 34 C64 40 60 46 56 50 C49 54 43 58 41 64 C39 70 39 76 40 82Z"
        or "M34 82 C24 82 20 72 23 61 C26 50 36 41 47 36 C53 33 58 31 63 31 L69 35 C67 44 64 54 59 60 C53 64 47 66 44 70 C42 74 42 78 43 82Z"
    return (tailFront and "" or tail(k, t, 6.6, 5.6))
        .. leg(k, { { 60, 58 }, { 61, 70 }, { 62, 80 } }, 6.4, true) .. leg(k, { { 67, 58 }, { 68, 70 }, { 69, 80 } }, 7)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. line("M27 76 C30 65 40 59 49 64", k.ink, .9) .. line("M68.6 64 L69 80", k.ink, .8)
        .. ellipse(45, 80, 7, 2.8, 0, k.white, k.ink, 1.2) .. ellipse(40, 79.2, 1.8, 1.8, 0, k.black)
        .. paw(k, 63, 80.6, 7.4, false, true) .. paw(k, 70, 80.6, 7.6)
        .. (tailFront and tail(k, t, 6.6, 5.6) or "")
        .. headSide(k, 75, o.headY or 24, o.headRot or -20, 1.05, { side = o.side, eye = o.eye or "up", mouth = o.mouth or "shut" })
end

-- Loafing, seen from the front, paws stretched out before her (her photos on
-- the sofa and the bed, looking straight at you).
function POSES.loaf(k, o)
    local t = wag(o.tail, {
        a = { { 92, 74 }, { 102, 78 }, { 108, 72 }, { 106, 64 } },
        b = { { 92, 76 }, { 104, 81 }, { 114, 80 }, { 117, 74 } },
        c = { { 90, 70 }, { 100, 64 }, { 104, 54 }, { 100, 46 } } })
    local body = "M20 82 C18 70 22 58 32 52 C40 47 48 46 52 46 L68 46 C72 46 80 47 88 52 C98 58 102 70 100 82Z"
    local bib = "M46 47 C43 57 42 70 44 82 L76 82 C78 70 77 57 74 47 C66 45 54 45 46 47Z"
    return tail(k, t, 7.4, 6.2) .. path(body, k.black, k.ink, 1.6) .. path(bib, k.white) .. path(body, nil, k.ink, 1.6)
        .. line("M50 82 C49 76 50 70 53 66 M70 82 C71 76 70 70 67 66 M60 72 L60 82", k.ink, .7)
        .. paw(k, 51, 80.2, 11) .. paw(k, 69, 80.2, 11)
        .. headFront(k, 60, 37, 0, 1.18, { mask = o.flip and "left" or "right", eye = o.eye or "open", mouth = o.mouth or "shut" })
end

-- Walking, seen from the side, her tail up in a curl (her photos on the
-- carved table and across the bed).
function POSES.walk(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 33, 44 }, { 24, 30 }, { 25, 14 }, { 34, 8 } },
        b = { { 33, 44 }, { 22, 34 }, { 16, 20 }, { 18, 10 } },
        c = { { 33, 44 }, { 26, 28 }, { 32, 14 }, { 42, 12 } } })
    local body = "M30 50 C30 40 40 34 54 34 C66 34 76 34 82 38 C86 42 87 50 84 56 C80 60 74 62 68 63 C56 67 42 65 36 60 C32 58 30 54 30 50Z"
    local black = left and "M30 50 C30 40 40 34 54 34 C66 34 76 34 82 38 L81 43 C73 45 64 47 56 49 C48 51 42 55 40 62 C35 60 31 57 30 52Z"
        or "M30 50 C30 40 40 34 54 34 C66 34 76 34 82 38 L82 46 C76 50 68 52 60 54 C52 57 46 60 43 63 C38 61 32 58 30 52Z"
    return tail(k, t, 7, 6)
        .. leg(k, { { 74, 56 }, { 71, 70 }, { 70, 81 } }, 6, true) .. leg(k, { { 46, 58 }, { 49, 70 }, { 48, 81 } }, 6.4, true)
        .. leg(k, { { 79, 54 }, { 81, 68 }, { 82, 81 } }, 6.4) .. leg(k, { { 40, 56 }, { 36, 68 }, { 38, 81 } }, 7, false, left)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. headSide(k, 90, 34, 6, 1.02, { side = o.side, eye = "open", mouth = o.mouth or "blep" })
end

-- Her body sitting up seen from the front: black flanks either side of a
-- white chest and white front legs, the hind paws showing at the sides.
local function frontSit(k)
    local body = "M34 82 C30 70 32 57 40 49 C46 44 74 44 80 49 C88 57 90 70 86 82Z"
    local chest = "M47 46 C45 56 45 70 46 82 L74 82 C75 70 75 56 73 46 C66 44 54 44 47 46Z"
    return path(body, k.black, k.ink, 1.6) .. path(chest, k.white) .. path(body, nil, k.ink, 1.6)
        .. line("M60 64 L60 82 M53 62 C52 70 52 76 53 82 M67 62 C68 70 68 76 67 82", k.ink, .7)
        .. paw(k, 54.6, 80.6, 9) .. paw(k, 65.4, 80.6, 9) .. ellipse(37, 80.6, 5, 2.4, 0, k.white, k.ink, 1.1) .. ellipse(83, 80.6, 5, 2.4, 0, k.white, k.ink, 1.1)
end

-- Sitting like a person, leaning back with her belly out and her legs before
-- her, one stretched long (her photos on the sofa, sitting up like a human).
function POSES.slouch(k, o)
    local t = wag(o.tail, {
        a = { { 34, 70 }, { 22, 74 }, { 12, 72 }, { 6, 64 } },
        b = { { 34, 70 }, { 20, 78 }, { 8, 80 }, { 2, 76 } },
        c = { { 34, 68 }, { 24, 62 }, { 20, 52 }, { 24, 44 } } })
    local body = "M36 76 C30 64 32 48 42 40 C48 36 72 36 78 40 C88 48 90 64 84 76 C78 82 42 82 36 76Z"
    local belly = "M45 42 C40 52 40 66 46 76 C54 80 66 80 74 76 C80 66 80 52 75 42 C68 39 52 39 45 42Z"
    return tail(k, t, 7, 6)
        .. path(body, k.black, k.ink, 1.6) .. path(belly, k.white) .. path(body, nil, k.ink, 1.6)
        .. line("M50 60 C54 64 60 65 66 62", k.ink, .6)
        .. Svg.stem(Svg.spline({ { 46, 72 }, { 34, 77 }, { 22, 79 } }, 6), Svg.taper(9, 7), k.white, k.ink, 1.3) .. paw(k, 19, 78, 8.6, true)
        .. Svg.stem(Svg.spline({ { 72, 72 }, { 80, 76 }, { 86, 79 } }, 6), Svg.taper(9, 7.4), k.white, k.ink, 1.3) .. ellipse(86, 79, 1.8, 2.4, 0, k.black) .. paw(k, 89, 78.6, 8.6, true)
        .. Svg.stem(Svg.spline({ { 48, 44 }, { 50, 52 }, { 55, 58 } }, 5), Svg.taper(7, 6), k.white, k.ink, 1.2) .. paw(k, 57, 58.6, 7)
        .. Svg.stem(Svg.spline({ { 72, 44 }, { 76, 54 }, { 79, 64 } }, 5), Svg.taper(7, 6), k.white, k.ink, 1.2) .. paw(k, 79.6, 65, 7)
        .. headFront(k, 60, 30, -6, 1.12, { mask = o.flip and "left" or "right", eye = "open", mouth = "blep" })
end

-- Asleep, stretched out long on her side, front paws reaching past her nose
-- (her photos asleep across the bed).
function POSES.sleep(k, o)
    local t = wag(o.tail, {
        a = { { 22, 64 }, { 12, 58 }, { 6, 50 }, { 8, 42 } },
        b = { { 22, 66 }, { 12, 66 }, { 4, 60 }, { 3, 52 } },
        c = { { 22, 64 }, { 14, 54 }, { 16, 44 }, { 22, 40 } } })
    local body = "M20 72 C18 63 26 57 38 56 C54 55 72 56 84 60 C90 63 92 70 88 76 C80 80 62 81 44 81 C30 81 22 79 20 72Z"
    local black = "M20 72 C18 63 26 57 38 56 C54 55 72 56 84 60 L83 64 C68 62 54 63 40 65 C31 67 27 71 25 77 C22 76 20 74 20 72Z"
    return tail(k, t, 7, 6)
        .. leg(k, { { 28, 74 }, { 16, 77 }, { 6, 77 } }, 6.6, true) .. leg(k, { { 30, 77 }, { 18, 80 }, { 8, 81 } }, 7, false, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. line("M38 70 C48 74 62 74 74 70", k.ink, .6)
        .. leg(k, { { 82, 70 }, { 98, 74 }, { 112, 75 } }, 6.4, true) .. leg(k, { { 84, 74 }, { 100, 78 }, { 113, 80 } }, 6.8)
        .. headSide(k, 94, 64, 10, .98, { side = o.side, eye = "shut", mouth = "shut" })
end

-- On her back, belly up and paws in the air, her head tipped back upside
-- down, offering the belly (her photos on the red sheet and in the sun).
function POSES.belly(k, o)
    local t = wag(o.tail, {
        a = { { 24, 78 }, { 12, 80 }, { 4, 77 }, { 2, 70 } },
        b = { { 24, 78 }, { 12, 76 }, { 6, 68 }, { 8, 60 } },
        c = { { 24, 79 }, { 14, 82 }, { 6, 82 }, { 2, 78 } } })
    local body = "M22 78 C20 64 34 54 56 54 C76 54 90 62 92 74 C92 80 86 82 76 82 L32 82 C26 82 22 81 22 78Z"
    local black = "M22 78 C25 74 31 72 40 74 C56 77 74 77 92 74 C92 80 86 82 76 82 L32 82 C26 82 22 81 22 78Z"
    return tail(k, t, 7, 6)
        .. Svg.stem(Svg.spline({ { 36, 60 }, { 30, 50 }, { 34, 42 } }, 6), Svg.taper(8, 7), mix(k.white, k.lid, .45), k.ink, 1.2) .. paw(k, 35, 41, 7.6, true, true)
        .. Svg.stem(Svg.spline({ { 76, 58 }, { 74, 48 }, { 70, 43 } }, 6), Svg.taper(7, 6), mix(k.white, k.lid, .45), k.ink, 1.2) .. paw(k, 69, 42, 6.6, false, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. line("M44 64 C52 60 64 60 72 64", k.ink, .6)
        .. Svg.stem(Svg.spline({ { 42, 58 }, { 44, 46 }, { 50, 40 } }, 6), Svg.taper(8.6, 7.4), k.white, k.ink, 1.3) .. paw(k, 51, 39, 8, true)
        .. ellipse(47.6, 41.4, 1.6, 2.2, 30, k.black)
        .. Svg.stem(Svg.spline({ { 82, 60 }, { 85, 50 }, { 82, 44 } }, 6), Svg.taper(7.4, 6.4), k.white, k.ink, 1.3) .. paw(k, 81, 42.6, 7)
        .. headFront(k, 101, 68, 158, 1.02, { mask = o.flip and "right" or "left", eye = "open", mouth = "blep" })
end

-- The look she is famous for: sitting square on, eyes narrowed, ears turned
-- back, mouth a flat line, her tail lashing. Someone is about to bleed (her
-- photo in the sun, compared to Death himself).
function POSES.glare(k, o)
    local t = wag(o.tail, {
        a = { { 84, 76 }, { 96, 72 }, { 102, 62 }, { 98, 52 } },
        b = { { 84, 78 }, { 98, 78 }, { 108, 72 }, { 112, 62 } },
        c = { { 84, 76 }, { 94, 66 }, { 94, 54 }, { 88, 46 } } })
    return tail(k, t, 7.6, 6.4) .. frontSit(k)
        .. headFront(k, 60, 31, 0, 1.18, { mask = o.flip and "left" or "right", eye = "squint", mouth = "shut", ears = "back" })
end

-- Sitting, chin up, chattering at a bird with her mouth open, mimicking its
-- call (her photo calling out in the hall). The bird is up in the corner.
function POSES.chatter(k, o)
    local bird = group(104, 12, -10, path("M-6 0 C-4 -3 2 -4 6 -2 C9 -1 10 1 7 2 C3 3 -2 3 -6 0Z", k.bird, k.ink, .9)
        .. path("M-1 -1 C-3 -7 1 -9 4 -8 C3 -5 2 -3 1 -1Z", k.bird, k.ink, .8) .. path("M7 -.6 L10 0 L7 .8Z", k.gold) .. circle(5.6, -.8, .5, k.white)
        .. line("M-6 0 L-9 -1 M-6 0 L-9 1.6", k.ink, .8))
    local calls = line("M97 22 C99 24 99 27 97 29 M100 20 C103 23 103 28 100 31", k.ink, .8)
    return bird .. calls .. POSES.sit(k, { side = o.side, tail = o.tail, flip = o.flip, headRot = -34, eye = "wide", mouth = "open" })
end

-- Staring at her spot. Nobody knows what is there. She has watched it for
-- hours and will watch it for hours more, still as a statue.
function POSES.stare(k, o)
    return POSES.sit(k, { side = o.side, tail = "a", flip = o.flip, headRot = -4, headY = 25, eye = "wide", mouth = "shut" })
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
    local black = left and "M28 66 C26 56 36 50 50 50 C64 50 76 52 82 58 L80 62 C70 61 60 62 50 64 C42 66 36 70 34 75 C30 72 28 69 28 66Z"
        or "M28 66 C26 56 36 50 50 50 C64 50 76 52 82 58 L81 66 C72 67 62 68 52 70 C44 72 39 75 37 77 C31 74 28 70 28 66Z"
    local claws = path("M108 47 L111 45 L109 48Z M108.6 50 L112 49.4 L109 51Z M107.6 53 L110.6 53.6 L107.6 54.4Z", k.white, k.ink, .6)
    return tail(k, t, 11, 9)
        .. leg(k, { { 40, 70 }, { 34, 76 }, { 36, 81 } }, 7.6, true) .. leg(k, { { 74, 70 }, { 76, 76 }, { 78, 81 } }, 6.6, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. leg(k, { { 44, 72 }, { 40, 78 }, { 42, 81 } }, 8, false, left)
        .. Svg.stem(Svg.spline({ { 80, 62 }, { 94, 56 }, { 104, 51 } }, 6), Svg.taper(7, 6), k.white, k.ink, 1.3) .. ellipse(105.4, 50.6, 4.2, 3.4, -20, k.white, k.ink, 1.2) .. claws
        .. headSide(k, 90, 46, 8, 1.04, { side = o.side, eye = "squint", mouth = "fangs", ears = "back" })
end

-- Eating: crouched over her dish, head down, eyes shut with joy, the salami
-- going fast. Salami is her favourite thing in the known universe.
function POSES.eat(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 26, 64 }, { 16, 54 }, { 16, 40 }, { 24, 34 } },
        b = { { 26, 64 }, { 14, 60 }, { 8, 50 }, { 10, 40 } },
        c = { { 26, 64 }, { 18, 50 }, { 24, 40 }, { 32, 38 } } })
    local body = "M24 72 C22 62 30 56 44 55 C58 54 72 56 80 62 C84 66 84 74 80 78 C72 82 52 82 38 81 C28 80 24 77 24 72Z"
    local black = left and "M24 72 C22 62 30 56 44 55 C58 54 72 56 80 62 L78 66 C68 64 56 64 46 66 C38 68 33 72 31 79 C27 77 24 75 24 72Z"
        or "M24 72 C22 62 30 56 44 55 C58 54 72 56 80 62 L80 70 C70 70 60 70 50 72 C42 74 37 77 35 80 C29 79 24 76 24 72Z"
    local dish = path("M86 74 L114 74 C113 79 109 82 100 82 C91 82 87 79 86 74Z", k.dish, k.ink, 1.3) .. ellipse(100, 74, 14, 2.6, 0, k.dish, k.ink, 1.1)
        .. ellipse(95, 72.6, 4, 1.6, 0, k.meat, k.ink, .8) .. ellipse(104, 72.4, 4, 1.6, 0, k.meat, k.ink, .8)
        .. circle(94, 72.4, .5, k.white) .. circle(96.4, 72.8, .5, k.white) .. circle(103, 72.2, .5, k.white) .. circle(105.4, 72.6, .5, k.white)
    return tail(k, t, 7, 6)
        .. leg(k, { { 34, 74 }, { 30, 78 }, { 32, 81 } }, 7, true) .. leg(k, { { 74, 72 }, { 78, 77 }, { 80, 81 } }, 6.4, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. leg(k, { { 38, 76 }, { 36, 79 }, { 38, 81 } }, 7.6, false, left) .. leg(k, { { 78, 74 }, { 82, 78 }, { 84, 81 } }, 6.8)
        .. dish .. headSide(k, 90, 64, 34, 1, { side = o.side, eye = "shut", mouth = "chew" })
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
    local black = left and "M20 70 C18 60 28 54 42 56 C56 58 66 62 74 66 L72 69 C62 67 50 66 40 68 C32 70 28 73 27 78 C23 77 20 74 20 70Z"
        or "M20 70 C18 60 28 54 42 56 C56 58 66 62 74 66 L74 72 C64 72 52 72 42 74 C36 75 32 77 30 79 C24 77 20 74 20 70Z"
    local lizard = group(108, 76, 0, path("M-11 4 C-14 0 14 0 14 4Z", k.stone, k.ink, 1.1)
        .. path("M-6 0 C-3 -2.6 3 -3 7 -1.4 C9 -.8 10 .4 8 .8 C3 1.4 -2 1.4 -6 0Z", k.lizard, k.ink, .9)
        .. path("M-9 0 C-12 0 -14 -2 -13 -4.6 C-12.4 -6 -10.6 -6 -10.8 -4.4", nil, k.ink, 1.6) .. line("M-9 0 C-12 0 -14 -2 -13 -4.6 C-12.4 -6 -10.6 -6 -10.8 -4.4", k.lizard, .9)
        .. line("M-4 0 L-6 2.4 M-3 -.6 L-4 -3.2 M4 0 L6 2.2 M4.6 -1 L6 -3.4", k.ink, .9) .. circle(6.6, -1, .5, k.ink))
    local hunter = tail(k, t, 6.6, 5.6)
        .. leg(k, { { 30, 72 }, { 24, 77 }, { 26, 81 } }, 7, true) .. leg(k, { { 66, 72 }, { 74, 78 }, { 80, 81 } }, 6, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. leg(k, { { 34, 76 }, { 30, 79 }, { 32, 81 } }, 7.6, false, left) .. leg(k, { { 70, 74 }, { 78, 79 }, { 85, 81 } }, 6.6)
        .. headSide(k, 82, 66, 4, 1, { side = o.side, eye = "wide", mouth = "shut" })
    return lizard .. group(-6, 0, 0, hunter)
end

-- Bottom up for a pat: front low, back legs straight, tail straight up, and
-- her head turned to you with her eyes half shut. The left side is for pats
-- (up to a hundred and forty); the right side allows three.
function POSES.butt(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 30, 40 }, { 29, 26 }, { 30, 12 }, { 33, 4 } },
        b = { { 30, 40 }, { 26, 26 }, { 22, 14 }, { 24, 5 } },
        c = { { 30, 40 }, { 32, 26 }, { 38, 14 }, { 44, 8 } } })
    local body = "M26 46 C26 38 34 34 44 36 C56 38 70 46 80 52 C86 56 86 64 80 66 C72 68 60 66 50 62 C40 58 30 56 27 52 C26 50 26 48 26 46Z"
    local black = left and "M26 46 C26 38 34 34 44 36 C56 38 70 46 80 52 L78 56 C68 52 58 50 48 50 C40 50 34 52 30 55 C27 52 26 49 26 46Z"
        or "M26 46 C26 38 34 34 44 36 C56 38 70 46 80 52 L80 60 C70 58 60 56 50 56 C42 56 35 56 30 56 C27 53 26 49 26 46Z"
    return tail(k, t, 7.4, 6.2)
        .. leg(k, { { 32, 50 }, { 30, 66 }, { 30, 81 } }, 7, true) .. leg(k, { { 74, 62 }, { 74, 72 }, { 75, 81 } }, 6.2, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. leg(k, { { 38, 52 }, { 37, 66 }, { 38, 81 } }, 7.6, false, left) .. leg(k, { { 79, 62 }, { 80, 72 }, { 81, 81 } }, 6.6)
        .. headFront(k, 90, 52, 10, .98, { mask = o.flip and "left" or "right", eye = "shut", mouth = "shut" })
end

-- The queen on her throne: sitting square on a plum velvet cushion with gold
-- tassels, a small gold crown between her ears. Supreme ruler of the known
-- and unknown universe, and she knows it.
function POSES.throne(k, o)
    local t = wag(o.tail, {
        a = { { 86, 70 }, { 98, 70 }, { 104, 62 }, { 102, 52 } },
        b = { { 86, 72 }, { 100, 76 }, { 108, 72 }, { 110, 64 } },
        c = { { 86, 70 }, { 96, 62 }, { 96, 50 }, { 90, 44 } } })
    local cushion = path("M22 74 C22 69 30 68 60 68 C90 68 98 69 98 74 C98 80 90 82 60 82 C30 82 22 80 22 74Z", k.cushion, k.ink, 1.4)
        .. line("M30 72 C46 74 74 74 90 72", mix(k.cushion, k.ink, .3), .8)
        .. path("M22 75 L18 80 L24 79Z M98 75 L102 80 L96 79Z", k.gold, k.ink, .8)
    local crown = group(60, 13.4, 0, path("M-7 2 L-7 -3 L-4 0 L0 -5 L4 0 L7 -3 L7 2Z", k.gold, k.ink, 1) .. circle(0, -5.4, .9, k.cushion) .. circle(-7, -3.4, .7, k.white) .. circle(7, -3.4, .7, k.white))
    return tail(k, t, 7.4, 6.2) .. cushion .. group(0, -6, 0, frontSit(k))
        .. headFront(k, 60, 29, 0, 1.12, { mask = o.flip and "left" or "right", eye = "squint", mouth = "shut" }) .. crown
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
    local black = left and "M22 50 C22 42 32 38 46 38 C62 38 76 40 86 44 L85 48 C74 47 62 48 52 50 C42 52 34 54 30 57 C25 55 22 53 22 50Z"
        or "M22 50 C22 42 32 38 46 38 C62 38 76 40 86 44 L87 52 C76 53 64 54 54 55 C44 56 36 57 31 58 C25 56 22 53 22 50Z"
    local dust = circle(6, 78, 3, k.stone, k.ink, .8) .. circle(12, 80, 2.2, k.stone, k.ink, .8) .. circle(2, 81, 1.8, k.stone, k.ink, .8) .. circle(17, 79, 1.4, k.stone, k.ink, .7)
    return dust .. tail(k, t, 6.8, 5.8)
        .. leg(k, { { 80, 56 }, { 90, 64 }, { 97, 70 } }, 6, true) .. leg(k, { { 32, 56 }, { 24, 64 }, { 17, 70 } }, 6.6, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. leg(k, { { 84, 53 }, { 98, 58 }, { 110, 60 } }, 6.4) .. leg(k, { { 28, 54 }, { 16, 60 }, { 5, 62 } }, 7, false, left)
        .. headSide(k, 95, 40, 8, 1.02, { side = o.side, eye = "wide", mouth = "shut", ears = "back" })
end

-- Playing, in a short burst: on her side, one paw up at a feather on a
-- string. Three swats, then she remembers how tiring play is.
function POSES.play(k, o)
    local t = wag(o.tail, {
        a = { { 22, 66 }, { 12, 60 }, { 6, 52 }, { 8, 44 } },
        b = { { 22, 66 }, { 12, 66 }, { 4, 60 }, { 3, 52 } },
        c = { { 22, 66 }, { 14, 56 }, { 16, 46 }, { 22, 42 } } })
    local body = "M20 72 C18 63 26 57 38 56 C54 55 72 56 84 60 C90 63 92 70 88 76 C80 80 62 81 44 81 C30 81 22 79 20 72Z"
    local black = "M20 72 C18 63 26 57 38 56 C54 55 72 56 84 60 L83 64 C68 62 54 63 40 65 C31 67 27 71 25 77 C22 76 20 74 20 72Z"
    local toy = line("M114 0 C112 14 108 26 104 36", k.ink, .7)
        .. group(104, 38, 24, path("M0 0 C-3 4 -3 10 0 14 C3 10 3 4 0 0Z", k.gold, k.ink, .9) .. line("M0 1 L0 13", k.ink, .5))
        .. group(104, 38, -10, path("M0 0 C-2.4 3 -2.4 8 0 11 C2.4 8 2.4 3 0 0Z", k.meat, k.ink, .8))
    return toy .. tail(k, t, 7, 6)
        .. leg(k, { { 28, 74 }, { 16, 77 }, { 6, 77 } }, 6.6, true) .. leg(k, { { 30, 77 }, { 18, 80 }, { 8, 81 } }, 7, false, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. line("M38 70 C48 74 62 74 74 70", k.ink, .6)
        .. leg(k, { { 84, 74 }, { 98, 78 }, { 110, 79 } }, 6.8)
        .. Svg.stem(Svg.spline({ { 82, 68 }, { 94, 60 }, { 101, 50 } }, 6), Svg.taper(6.6, 6), k.white, k.ink, 1.3) .. paw(k, 102, 47.6, 7.4, true)
        .. headSide(k, 84, 62, -24, .98, { side = o.side, eye = "up", mouth = "blep" })
end

-- Hissing at another cat that dared to look at her: back arched high, legs
-- stiff, every hair on end, tail puffed to a bottle brush, fangs out. She
-- hates other cats. All of them.
function POSES.hiss(k, o)
    local left = o.side == "left"
    local t = wag(o.tail, {
        a = { { 30, 52 }, { 22, 38 }, { 22, 22 }, { 28, 14 } },
        b = { { 30, 52 }, { 18, 42 }, { 12, 28 }, { 14, 16 } },
        c = { { 30, 52 }, { 26, 36 }, { 32, 22 }, { 40, 16 } } })
    local body = "M28 64 C26 50 36 32 54 30 C70 30 80 42 84 54 C85 61 82 66 78 66 C70 62 60 60 50 60 C40 60 32 64 28 64Z"
    local black = left and "M28 64 C26 50 36 32 54 30 C70 30 80 42 84 54 L80 56 C72 50 62 48 52 48 C42 49 34 54 31 63 C30 64 29 64 28 64Z"
        or "M28 64 C26 50 36 32 54 30 C70 30 80 42 84 54 L83 61 C74 56 64 54 54 54 C44 55 36 59 32 64 C30 64 29 64 28 64Z"
    return tail(k, t, 12, 10)
        .. leg(k, { { 33, 60 }, { 32, 70 }, { 32, 81 } }, 6.6, true) .. leg(k, { { 76, 62 }, { 77, 72 }, { 78, 81 } }, 6, true)
        .. path(body, k.white, k.ink, 1.6) .. path(black, k.black) .. path(body, nil, k.ink, 1.6)
        .. leg(k, { { 39, 61 }, { 39, 71 }, { 39, 81 } }, 7, false, left) .. leg(k, { { 81, 62 }, { 82, 72 }, { 84, 81 } }, 6.4)
        .. headSide(k, 91, 58, 14, 1.02, { side = o.side, eye = "squint", mouth = "fangs", ears = "back" })
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
