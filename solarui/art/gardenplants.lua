-- The garden's plants at each stage of their life, one drawing per species:
-- plant_<id>(c, vw, vh, param) where param is the stage 1..5 (seed, sprout,
-- bud, bloom, seed head), followed by ":wilt" for a thirsty, drooping plant and ":wash" for the faded copy.
-- Every plant grows up from the foot of its canvas, centred.

local Blooms = require("solarui/art/blooms")
local Cast = require("solarui/garden/cast")
local Flora = require("solarui/art/flora")
local Svg = require("solarui/art/svg")
local Wash = require("solarui/art/wash")

local group = Svg.group

local Plants = {}

-- The flower of each species at (x, y) with radius `r`; the rest use a plain
-- bloom in the colour given beside them.
local BLOOM = {
    rose = function(c, x, y, r) return Flora.rose(c, x, y, r, 0) end,
    tulip = function(c, x, y, r) return Flora.tulip(c, x, y + r * .8, 0, r * 1.3, c.bloom2) end,
    sunflower = function(c, x, y, r) return Flora.sunflower(c, x, y, r * .45, r * .55, 14, 14) end,
    chamomile = function(c, x, y, r) return Flora.daisy(c, x, y, r, 14) end,
    dandelion = function(c, x, y, r) return Blooms.karahindiba(c, x, y, r) end,
    narcissus = function(c, x, y, r) return Blooms.narcissus(c, x, y, r) end,
    crocus = function(c, x, y, r) return Blooms.crocus(c, x, y + r * .5, 0, r * 1.5) end,
    pansy = function(c, x, y, r) return Blooms.pansy(c, x, y, r) end,
    lily = function(c, x, y, r) return Flora.lily(c, x, y, r * 1.2, 6, 3) end,
    maple = function(c, x, y, r) return Blooms.maple(c, x, y + r, 0, r * 1.6, c.gold) end,
    ginkgo = function(c, x, y, r) return Flora.ginkgo(c, x, y + r, 0, r * 1.6, c.gold) end,
    bracken = function(c, x, y, r) return Flora.frond(c, x, y + r * 1.6, 0, r * 2.4) end,
    honesty = function(c, x, y, r) return Flora.honesty(c, x, y, r * .8) end,
    ivy = function(c, x, y, r) return Flora.vineLeaf(c, x, y + r, 0, r * 1.2) end,
    water_lily = function(c, x, y, r) return Flora.lilypad(c, x, y + r * .6, r * 1.5, 30) .. Flora.lily(c, x, y, r, 8, 4) end,
}

-- Colours of the plain blooms of the species without a drawing of their own.
local PLAIN = { bellflower = "sky", iris = "glass", poppy = "bloom" }

-- The flower of `id` at (x, y), `r` across.
local function bloom(c, id, x, y, r)
    if BLOOM[id] then return BLOOM[id](c, x, y, r) end
    local fill = c[PLAIN[id] or "bloom"]
    return Flora.around(x, y, r * .1, 5, Flora.petal(c, r, r * .5, fill, 1.7)) .. Svg.circle(x, y, r * .2, c.gold, c.ink, 1.4)
end

-- A stalk from the foot up to (x, y), with a pair of leaves on it.
local function stalk(c, vw, vh, x, y, w)
    local pts = Svg.spline({ { vw * .5, vh }, { vw * .5 + (x - vw * .5) * .3, vh - (vh - y) * .5 }, { x, y } }, 6)
    local leaves = Flora.leaf(c, vw * .5, vh * .84, -30, vh * .2, vh * .06) .. Flora.leaf(c, vw * .5, vh * .72, -150, vh * .2, vh * .06)
    return leaves .. Svg.stem(pts, Svg.taper(w, w * .6), c.stem, c.ink, 1.4)
end

-- The picture of a plant of `id` in the given stage.
local function stage(c, id, vw, vh, st)
    local r = math.min(vw, vh) * .3
    if st == 1 then
        return Svg.ellipse(vw * .5, vh * .94, vw * .3, vh * .06, 0, c.pale, c.ink, 1.5) .. Svg.circle(vw * .5, vh * .9, vh * .03, c.ink)
    elseif st == 2 then
        return stalk(c, vw, vh, vw * .5, vh * .66, 3)
    elseif st == 3 then
        return stalk(c, vw, vh, vw * .52, vh * .4, 3.5) .. Flora.rosebud(c, vw * .52, vh * .42, 0, r * .8, c[PLAIN[id] or "bloom"])
    elseif st == 4 then
        return stalk(c, vw, vh, vw * .5, vh * .38, 4) .. bloom(c, id, vw * .5, vh * .32, r)
    end
    return stalk(c, vw, vh, vw * .5, vh * .38, 4) .. Flora.dandelion(c, vw * .5, vh * .32, r * .8)
end

-- A plant drawn for a stage, tilted over when it is wilting.
local function plant(id)
    return function(c, vw, vh, param)
        local st, rest = tostring(param or "4"):match("^(%d)(.*)$")
        local body = stage(Wash.apply(c, param), id, vw, vh, tonumber(st) or 4)
        if rest and rest:find("wilt") then body = group(vw * .5, vh, 14, group(-vw * .5, -vh, 0, body), .92) end
        return body
    end
end

for _i, def in ipairs(Cast.PLANTS) do Plants["plant_" .. def.id] = plant(def.id) end

return Plants
