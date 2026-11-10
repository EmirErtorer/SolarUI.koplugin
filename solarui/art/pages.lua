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
    return Svg.line(string.format("M%s %s Q%s %s %s %s", n(vw * .5), n(vh), n(vw * .44), n(vh * (top + 1) / 2), n(vw * .5), n(vh * top)), c.stem, vh * .06)
        .. Flora.leaf(c, vw * .49, vh * .92, -150, vh * .3, vh * .1, nil, true)
        .. Flora.leaf(c, vw * .49, vh * .88, -32, vh * .34, vh * .11, nil, true)
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

-- The year's goal as a blossom tree on a wide canvas: a leafy crown in which
-- as many of 24 places are in flower as `pct` percent of the goal, the rest
-- still buds, on a trunk that forks, standing on a rolling line of ground.
function Pages.goal_tree(c, vw, vh, pct)
    local filled = math.floor((math.max(0, math.min(100, tonumber(pct) or 0)) / 100) * 24 + .5)
    local m, cy = vw / 2, vh * .4
    local rx, ry = math.min(vw * .3, vh * 1.15), vh * .34
    local out = { Svg.line(string.format("M0 %s C%s %s %s %s %s %s", n(vh * .93), n(vw * .25), n(vh * .8), n(vw * .35), n(vh * 1.04), n(m - vw * .06), n(vh * .94)), c.stem, 2.4),
        Svg.line(string.format("M%s %s C%s %s %s %s %s %s", n(m + vw * .06), n(vh * .94), n(vw * .65), n(vh * 1.04), n(vw * .75), n(vh * .8), n(vw), n(vh * .93)), c.stem, 2.4) }
    out[#out + 1] = Svg.stem(Svg.spline({ { m, vh * .96 }, { m + 3, vh * .78 }, { m - 2, vh * .6 }, { m, cy + ry * .5 } }, 6), Svg.taper(vh * .09, vh * .05), c.stem, c.ink, 1.6)
    out[#out + 1] = Svg.line(string.format("M%s %s Q%s %s %s %s M%s %s Q%s %s %s %s", n(m), n(vh * .66), n(m - vh * .12), n(vh * .55), n(m - rx * .5), n(cy), n(m), n(vh * .66), n(m + vh * .1), n(vh * .52), n(m + rx * .5), n(cy - ry * .1)), c.stem, vh * .035)
    out[#out + 1] = Svg.ellipse(m, cy, rx, ry, 0, c.leaf, c.ink, 2)
    for i = 0, 23 do
        local a = i * 360 / 24 + 8 * Svg.vary(i, 9)
        local ring = i % 2 == 0 and .62 or .28
        local px, py = Svg.pol(1, a, 0, 0)
        local x, y = m + px * rx * ring * (.85 + .2 * Svg.vary(i, 3)), cy - py * ry * ring * (.85 + .2 * Svg.vary(i, 4))
        local r = vh * .075
        if i < filled then
            out[#out + 1] = Flora.petal and (Flora.around(x, y, r * .5, 5, Flora.petal(c, r * 1.3, r * .55, c.bloom2, 1.1))) or ""
            out[#out + 1] = Svg.circle(x, y, r * .5, c.gold, c.ink, 1)
        else
            out[#out + 1] = Svg.circle(x, y, r * .55, c.sage, c.ink, 1.1)
        end
    end
    return table.concat(out)
end

-- A shelf rail for under a row of covers: a rule with a curl at each end.
function Pages.rail_line(c, vw, vh)
    local r = vh * .3
    local y = vh * .55
    local left = Svg.spiral(r * 1.2, y - r, r, 1.3, 0, true)
    local rail = {}
    for i = #left, 1, -1 do rail[#rail + 1] = left[i] end
    rail = Svg.poly(Svg.join(rail, Svg.join({ { r * 1.2, y }, { vw - r * 1.2, y } }, Svg.spiral(vw - r * 1.2, y - r, r, 1.3, 0))))
    return Svg.line(rail, c.ink, 2.6) .. Svg.line(rail, c.stem, 1.2)
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
