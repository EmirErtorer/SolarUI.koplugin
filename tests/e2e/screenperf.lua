-- Opening each screen: time, SVG drawings rasterised and files written.
local H = ...
local UIManager = require("ui/uimanager")
local time = require("ui/time")
local RenderImage = require("ui/renderimage")
local svgs, writes = 0, 0
local render = RenderImage.renderSVGImageFile
RenderImage.renderSVGImageFile = function(...) svgs = svgs + 1; return render(...) end
local LuaSettings = require("luasettings")
local flush = LuaSettings.flush
LuaSettings.flush = function(...) writes = writes + 1; return flush(...) end
H.step(1, function()
    local State = require("solarui/garden/state")
    State.refresh()
    -- two hungry animals hide in the grass: their tufts are placed afresh on every visit
    local d = State.get()
    for _, id in ipairs({ "snail", "frog", "bee", "robin" }) do if d.animals[id] then d.animals[id].fed = State.clock() - 90 * 86400 end end
    State.save()
end)
local screens = { "garden", "home", "garden", "home", "garden", "library", "collections", "history", "search", "settings", "garden", "gardenjournal", "gardennotes", "launcher", "home" }
for _, id in ipairs(screens) do
    for pass = 1, 2 do
        H.step(.6, function()
            svgs, writes = 0, 0
            local t0 = time.now()
            H.app().go(id)
            UIManager:forceRePaint()
            H.say(string.format("PERF %-14s pass %d %5d ms  %3d svg  %d writes", id, pass, time.to_ms(time.since(t0)), svgs, writes))
        end)
    end
end
