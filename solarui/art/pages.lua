-- The small drawings every page but home is dressed with: a plant for each
-- page's header, the rule under the header, the curl that ends a section
-- title and the crest over a dialog. Each is function(c, vw, vh) returning
-- SVG for a vw x vh canvas. They are drawn bold, to read at the size of a
-- button.

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

-- Library: a ginkgo fan.
function Pages.plant_library(c, vw, vh)
    return Svg.line(string.format("M%s %s q%s %s %s %s", n(vw * .5), n(vh * .78), n(vh * .06), n(vh * .1), n(-vh * .04), n(vh * .2)), c.stem, vh * .06)
        .. Flora.ginkgo(c, vw * .5, vh * .8, 0, vh * .56, c.gold)
end

-- Collections: a rose between two leaves.
function Pages.plant_collections(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Flora.rose(c, vw * .5, vh * .4, vh * .34, 12)
end

-- The reading log: a fern crozier.
function Pages.plant_history(c, vw, vh)
    return Flora.crozier(c, vw * .56, vh, 0, vh * .58, vh * .26)
end

-- Search: a dandelion clock.
function Pages.plant_search(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Flora.dandelion(c, vw * .5, vh * .38, vh * .34)
end

-- Settings: a daisy like a toothed wheel.
function Pages.plant_settings(c, vw, vh)
    return stalk(c, vw, vh, .6) .. Flora.daisy(c, vw * .5, vh * .38, vh * .36, 10)
end

-- A book's details: a fern frond.
function Pages.plant_details(c, vw, vh)
    return Flora.frond(c, vw * .5, vh * .98, -8, vh * .84)
end

-- Highlights: the eye of a peacock feather.
function Pages.plant_highlights(c, vw, vh)
    return Flora.peacock(c, vw * .52, vh * .4, 12, vh * .32)
end

-- Bookmarks: a single sage ginkgo leaf, like one pressed between pages.
function Pages.plant_bookmarks(c, vw, vh)
    return Flora.ginkgo(c, vw * .5, vh * .88, 8, vh * .5, c.sage)
end

-- Notes: a tulip.
function Pages.plant_notes(c, vw, vh)
    return stalk(c, vw, vh, .56) .. Flora.tulip(c, vw * .5, vh * .58, 0, vh * .34)
end

-- Any other page: a bud between two leaves.
function Pages.plant_sprout(c, vw, vh)
    return stalk(c, vw, vh, .56) .. Flora.rosebud(c, vw * .5, vh * .58, 0, vh * .28)
end

-- The rule under a page's header: a whiplash line with a few leaves on it
-- and a bud before its curl.
function Pages.page_rule(c, vw, vh)
    local line, pts = Flora.whiplash(c, vw, vh)
    local len = Svg.length(pts)
    local out = {}
    for i, f in ipairs({ .12, .34, .58 }) do
        local x, y, ang = Svg.along(pts, len * f)
        out[#out + 1] = Flora.leaf(c, x, y, ang + (i % 2 == 0 and 34 or -34), vh * .7, vh * .22, i == 2 and c.sage or c.leaf, true)
    end
    local x, y, ang = Svg.along(pts, len * .86)
    return table.concat(out) .. line .. Flora.rosebud(c, x, y, ang + 50, vh * .26)
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
