-- Where the garden spends its time: opening it, tapping a plant, caring for
-- one, closing the card, and the same on home. Counts the SVG drawings
-- rasterised and the files written on each step, and times each in ms.
local H = ...
local UIManager = require("ui/uimanager")
local time = require("ui/time")
local RenderImage = require("ui/renderimage")
local svgs, writes = 0, 0
local render = RenderImage.renderSVGImageFile
local detail = {}
RenderImage.renderSVGImageFile = function(self, path, w, h, z)
    svgs = svgs + 1
    local t0 = time.now()
    local bb = render(self, path, w, h, z)
    local f = io.open(path); local size = #f:read("*a"); f:close()
    detail[#detail + 1] = { w = w, h = h, bytes = size, ms = time.to_ms(time.since(t0)) }
    return bb
end
local LuaSettings = require("luasettings")
local flush = LuaSettings.flush
LuaSettings.flush = function(...) writes = writes + 1; return flush(...) end
local out = {}
local function measure(name, fn)
    svgs, writes = 0, 0
    local t0 = time.now()
    fn()
    UIManager:forceRePaint()
    out[#out + 1] = string.format("%-34s %5d ms  %3d svg  %2d writes", name, time.to_ms(time.since(t0)), svgs, writes)
end
H.step(1.5, function()
    local State = require("solarui/garden/state")
    State.refresh()
    measure("home (already open) rebuild", function() H.app().update() end)
    measure("open the garden", function() H.app().go("garden") end)
end)
H.step(1, function() measure("garden rebuild (no change)", function() H.app().update() end) end)
H.step(.5, function()
    local box
    H.findWhere(function(el) if el.on_tap and el.x and el.w and el.w < 300 and el.w > 60 and el.y > 300 then box = el return true end return false end)
    measure("tap a plant (card opens)", function() H.tapAt(box.x + box.w / 2, box.y + box.h / 2) end)
end)
H.step(1, function() measure("close the card", function() H.app().closeDialog() end) end)
H.step(.5, function()
    local State = require("solarui/garden/state")
    State.get().plants.rose.watered = State.clock() - 40 * 86400
    State.save()
    measure("rebuild after a plant wilts", function() H.app().update() end)
end)
H.step(.5, function()
    local State = require("solarui/garden/state")
    measure("water the wilted rose", function() State.water("rose"); H.app().update() end)
end)
H.step(.5, function() measure("tick (small movement)", function() local g = H.app().current(); if g.tick then g:tick() end end) end)
H.step(.5, function()
    measure("back to home", function() H.app().go("home") end)
end)
H.step(.5, function()
    for _, l in ipairs(out) do H.say("PERF " .. l) end
    table.sort(detail, function(a, b) return a.ms > b.ms end)
    local sum = 0
    for _, d in ipairs(detail) do sum = sum + d.ms end
    H.say(string.format("PERF all %d drawings: %d ms in the rasteriser", #detail, sum))
    for i = 1, 8 do local d = detail[i]; H.say(string.format("PERF slowest %d: %dx%d px, svg %d KB, %.1f ms", i, d.w, d.h, d.bytes / 1024, d.ms)) end
    local small = 0
    for _, d in ipairs(detail) do if d.ms < 3 then small = small + 1 end end
    H.say("PERF drawings under 3 ms: " .. small)
end)
