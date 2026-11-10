-- The small drawings every page but home is dressed with: a plant for each
-- page's header, the rule under the header, the curl that ends a section
-- title and the crest over a dialog. Each is function(c, vw, vh) returning
-- SVG for a vw x vh canvas. They are drawn bold, to read at the size of a
-- button.

local Blooms = require("solarui/art/blooms")
local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")

local n = Svg.n

local Pages = {}

-- A short stalk from the foot of the canvas up to `top` of its height, with
-- a leaf on each side.
local function stalk(c, vw, vh, top)
    local pts = Svg.spline({ { vw * .5, vh }, { vw * .46, vh * (top + 1) / 2 }, { vw * .5, vh * top } }, 8)
    local len = Svg.length(pts)
    local x1, y1 = Svg.along(pts, len * .1)
    local x2, y2 = Svg.along(pts, len * .2)
    return Svg.line(Svg.poly(pts), c.stem, vh * .06)
        .. Flora.leaf(c, x1, y1, -150, vh * .3, vh * .1, nil, true)
        .. Flora.leaf(c, x2, y2, -32, vh * .34, vh * .11, nil, true)
end

-- Library: a narcissus.
function Pages.plant_library(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Blooms.narcissus(c, vw * .5, vh * .38, vh * .36)
end

-- Collections: a rose between two leaves.
function Pages.plant_collections(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Flora.rose(c, vw * .5, vh * .4, vh * .34, 12)
end

-- The reading log: a crocus.
function Pages.plant_history(c, vw, vh)
    return stalk(c, vw, vh, .66) .. Blooms.crocus(c, vw * .5, vh * .66, 0, vh * .56)
end

-- Search: a pansy.
function Pages.plant_search(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Blooms.pansy(c, vw * .5, vh * .38, vh * .34)
end

-- Settings: a daisy like a toothed wheel.
function Pages.plant_settings(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Flora.daisy(c, vw * .5, vh * .38, vh * .36, 10)
end

-- A book's details: a fern frond.
function Pages.plant_details(c, vw, vh)
    return Flora.frond(c, vw * .5, vh * .98, -8, vh * .84)
end

-- Highlights: a dandelion in bloom.
function Pages.plant_highlights(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Blooms.karahindiba(c, vw * .5, vh * .38, vh * .34)
end

-- Bookmarks: a maple leaf, like one pressed between pages.
function Pages.plant_bookmarks(c, vw, vh)
    return Blooms.maple(c, vw * .5, vh * .88, 8, vh * .8)
end

-- Notes: a tulip.
function Pages.plant_notes(c, vw, vh)
    return stalk(c, vw, vh, .56) .. Flora.tulip(c, vw * .5, vh * .58, 0, vh * .34)
end

-- Any other page: a bud between two leaves.
function Pages.plant_sprout(c, vw, vh)
    return stalk(c, vw, vh, .56) .. Flora.rosebud(c, vw * .5, vh * .58, 0, vh * .28)
end

-- The little flower that ends a page's rule, by the name of the page (the
-- same flowers as the page's plant); a bud for any other page.
local function ruleBloom(c, name, x, y, ang, vh)
    if name == "library" then return Blooms.narcissus(c, x, y, vh * .34)
    elseif name == "history" then return Blooms.crocus(c, x, y + vh * .2, 0, vh * .55)
    elseif name == "search" then return Blooms.pansy(c, x, y, vh * .34)
    elseif name == "settings" then return Flora.daisy(c, x, y, vh * .34, 10)
    elseif name == "collections" then return Flora.rose(c, x, y, vh * .36, 10)
    elseif name == "highlights" then return Blooms.karahindiba(c, x, y, vh * .34)
    elseif name == "bookmarks" then return Blooms.maple(c, x, y + vh * .3, 0, vh * .6)
    elseif name == "notes" then return Flora.tulip(c, x, y + vh * .2, 0, vh * .36)
    end
    return Flora.rosebud(c, x, y, ang + 50, vh * .26)
end

-- The rule under a page's header: a whiplash line with a few leaves on it
-- and, before its curl, a flower of the page (`page` is its name).
function Pages.page_rule(c, vw, vh, page)
    local line, pts = Flora.whiplash(c, vw, vh)
    local len = Svg.length(pts)
    local out = {}
    for i, f in ipairs({ .12, .34, .58 }) do
        local x, y, ang = Svg.along(pts, len * f)
        out[#out + 1] = Flora.leaf(c, x, y, ang + (i % 2 == 0 and 34 or -34), vh * .7, vh * .22, i == 2 and c.sage or c.leaf, true)
    end
    local x, y, ang = Svg.along(pts, len * .86)
    return table.concat(out) .. line .. ruleBloom(c, page, x, y - vh * .02, ang, vh * 1.05)
end

-- The start of a row's rule in a list: a bud on a short stalk between two
-- leaves; row_curl is its end, a small curl.
function Pages.row_bud(c, vw, vh)
    local y = vh * .6
    return Flora.leaf(c, vw * .38, y, -150, vw * .36, vh * .26, nil, true) .. Flora.leaf(c, vw * .38, y, -35, vw * .42, vh * .26, nil, true)
        .. Svg.line(string.format("M0 %s L%s %s", n(y), n(vw), n(y)), c.line, 1.3) .. Flora.rosebud(c, vw * .3, y, -40, vh * .62)
end
function Pages.row_curl(c, vw, vh)
    local r = vh * .3
    return Svg.line(Svg.poly(Svg.join({ { 0, vh * .6 }, { vw - r * 2.2, vh * .6 } }, Svg.spiral(vw - r * 2.2, vh * .6 - r, r, 1.3, 180, true))), c.line, 1.3)
end

-- The year's goal as an apple tree on a wide canvas: a trunk that forks into
-- a round crown of leaves, with as many of its places bearing an apple as
-- `pct` percent of the goal and the rest still in blossom, on a grassy mound.
function Pages.goal_tree(c, vw, vh, pct)
    local m = vw / 2
    local u = vh
    -- the crown: overlapping circles (centre x, y, radius, in units of the height)
    local crown = { { 0, .34, .25 }, { -.27, .4, .19 }, { .27, .4, .19 }, { -.17, .2, .19 }, { .17, .2, .19 }, { 0, .12, .17 },
        { -.4, .5, .12 }, { .4, .5, .12 }, { -.09, .5, .15 }, { .09, .5, .15 } }
    local out = {}
    -- grassy mound
    out[#out + 1] = Svg.path(string.format("M%s %s C%s %s %s %s %s %s L%s %s Z", n(m - u * .75), n(u), n(m - u * .5), n(u * .86), n(m + u * .5), n(u * .86), n(m + u * .75), n(u),
        n(m + u * .75), n(u * 1.2), n(m - u * .75)), c.sage, c.stem, 2)
    out[#out + 1] = Svg.line(string.format("M0 %s C%s %s %s %s %s %s M%s %s C%s %s %s %s %s %s", n(u * .97), n(vw * .2), n(u * .92), n(vw * .35), n(u * 1.02), n(m - u * .76), n(u * .99),
        n(m + u * .76), n(u * .99), n(vw * .65), n(u * 1.02), n(vw * .8), n(u * .92), n(vw), n(u * .97)), c.stem, 2)
    for i = -4, 4 do
        local gx = m + i * u * .13 + (Svg.vary(i + 9, 2) - .5) * u * .05
        local gy = u * (.93 - .03 * math.abs(i) / 4) + 2
        out[#out + 1] = Svg.line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(gx), n(gy), n(gx - 2), n(gy - u * .05), n(gx - 5), n(gy - u * .08),
            n(gx + 3), n(gy), n(gx + 5), n(gy - u * .05), n(gx + 9), n(gy - u * .07)), c.stem, 1.6)
    end
    -- trunk with a flare at its foot, and the limbs into the crown
    local trunk = Svg.path(string.format("M%s %s C%s %s %s %s %s %s L%s %s C%s %s %s %s %s %sZ", n(m - u * .16), n(u * .95), n(m - u * .05), n(u * .9), n(m - u * .05), n(u * .8), n(m - u * .045), n(u * .6),
        n(m + u * .045), n(u * .6), n(m + u * .05), n(u * .8), n(m + u * .05), n(u * .9), n(m + u * .16), n(u * .95)), c.muted, c.ink, 2)
    local function limb(x1, y1, x2, y2, w)
        return Svg.stem(Svg.spline({ { m, u * .62 }, { (m + x1) / 2, (u * .62 + y1) / 2 }, { x1, y1 }, { x2, y2 } }, 6), Svg.taper(w, w * .5), c.muted, c.ink, 1.6)
    end
    out[#out + 1] = limb(m - u * .16, u * .46, m - u * .26, u * .36, u * .05) .. limb(m + u * .16, u * .46, m + u * .26, u * .36, u * .05)
        .. limb(m, u * .42, m, u * .26, u * .045) .. trunk
    -- the crown as one cloud: every outline first, then every fill over the inner ones
    for _i, k in ipairs(crown) do out[#out + 1] = Svg.circle(m + k[1] * u, k[2] * u, k[3] * u, c.ink, c.ink, 3.4) end
    for _i, k in ipairs(crown) do out[#out + 1] = Svg.circle(m + k[1] * u, k[2] * u, k[3] * u, c.leaf) end
    for i, k in ipairs(crown) do
        local lx, ly = Svg.pol(k[3] * u * .55, 40 + i * 70, m + k[1] * u, k[2] * u)
        out[#out + 1] = Svg.line(string.format("M%s %s q%s %s %s %s", n(lx), n(ly), n(u * .03), n(-u * .03), n(u * .06), n(u * .005)), c.sage, 2.2)
    end
    -- places for fruit on a staggered grid, kept to the inside of the crown so that no two touch
    local R = u * .052
    local spots = {}
    local row = 0
    for gy = .1, .56, .115 do
        for gx = -.5, .5, .13 do
            local x, y = gx + (row % 2) * .065 + (Svg.vary(row * 17 + math.floor((gx + .5) * 20), 6) - .5) * .05, gy + (Svg.vary(row * 5 + math.floor((gx + .5) * 20), 7) - .5) * .05
            for _i, k in ipairs(crown) do
                local dx, dy = x - k[1], y - k[2]
                if math.sqrt(dx * dx + dy * dy) < k[3] - .065 then
                    spots[#spots + 1] = { m + x * u, y * u, Svg.vary(#spots + 1, 5) }
                    break
                end
            end
        end
        row = row + 1
    end
    local count = #spots
    local filled = math.floor((math.max(0, math.min(100, tonumber(pct) or 0)) / 100) * count + .5)
    local order = {}
    for i = 1, count do order[i] = i end
    table.sort(order, function(a, b) return spots[a][3] < spots[b][3] end)
    local rank = {}
    for r, i in ipairs(order) do rank[i] = r end
    for i, sp in ipairs(spots) do
        local x, y = sp[1], sp[2]
        if rank[i] <= filled then
            out[#out + 1] = Svg.line(string.format("M%s %s Q%s %s %s %s", n(x), n(y - R * .8), n(x + 1), n(y - R * 1.5), n(x + R * .5), n(y - R * 1.7)), c.ink, 1.5)
                .. (i % 2 == 0 and Flora.leaf(c, x + 1, y - R * 1.3, -25, R * 1.3, R * .5, c.sage, true) or "")
                .. Svg.circle(x, y, R, c.bloom, c.ink, 1.6) .. Svg.line(string.format("M%s %s q%s %s %s %s", n(x - R * .55), n(y - R * .1), n(R * .05), n(-R * .5), n(R * .55), n(-R * .55)), c.cream, 1.6)
        else
            out[#out + 1] = Flora.around(x, y, R * .45, 5, Flora.petal(c, R * .95, R * .4, c.cream, 1)) .. Svg.circle(x, y, R * .3, c.gold, c.ink, .8)
        end
    end
    return table.concat(out)
end

-- A small flower head, by species id, to stand before a section's name.
function Pages.bloom(c, vw, vh, id)
    local r = math.min(vw, vh) * .42
    local m = vw / 2
    if id == "pansy" then return Blooms.pansy(c, m, vh / 2, r)
    elseif id == "lily" then return Blooms.lily(c, m, vh / 2, r)
    elseif id == "narcissus" then return Blooms.narcissus(c, m, vh / 2, r)
    elseif id == "rose" then return Flora.rose(c, m, vh / 2, r, 10)
    elseif id == "tulip" then return Flora.tulip(c, m, vh * .8, 0, r * 1.5)
    elseif id == "dandelion" then return Blooms.karahindiba(c, m, vh / 2, r)
    elseif id == "maple" then return Blooms.maple(c, m, vh * .95, 0, r * 2)
    end
    return Flora.daisy(c, m, vh / 2, r, 10)
end

-- The end of a section title's line: the line runs in from the left, bears
-- a leaf and winds into a curl.
function Pages.section_curl(c, vw, vh)
    local r = vh * .3
    local y = vh * .5
    local pts = Svg.join({ { 0, y }, { vw - r * 2.4, y } }, Svg.spiral(vw - r * 2.4, y - r, r, 1.4, 180, true))
    return Flora.leaf(c, vw * .3, y, -38, vh * .62, vh * .2, nil, true) .. Svg.line(Svg.poly(pts), c.ink, 1.6)
end

-- The crest over a dialog: a bud in the middle, a leaf and a curling line
-- running out to each side.
function Pages.crest(c, vw, vh)
    local m, y = vw / 2, vh * .62
    local reach = math.min(vw * .42, vh * 5)
    local r = vh * .24
    local function wing(dir)
        local pts = Svg.spline({ { m + dir * vh * .3, y }, { m + dir * reach * .5, y - vh * .16 }, { m + dir * (reach - r * 2), y } }, 8)
        local last = pts[#pts]
        return Svg.path(Svg.ribbon(pts, Svg.swell(vh * .12, 1)), c.ink)
            .. Svg.line(Svg.poly(Svg.spiral(last[1], last[2] - r, r, 1.2, 180, dir > 0)), c.ink, 1.5)
            .. Flora.leaf(c, m + dir * vh * .34, y, dir > 0 and -24 or -156, vh * .8, vh * .24, nil, true)
    end
    return wing(-1) .. wing(1) .. Flora.rosebud(c, m, vh * .8, 0, vh * .36)
end

return Pages
