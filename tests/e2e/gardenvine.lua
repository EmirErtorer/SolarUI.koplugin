-- The vine along the garden's frame at no growth and at full growth (and between), in full size.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local function dates(n)
    local out = {}
    for i = 0, n - 1 do out[#out + 1] = os.date("%Y-%m-%d", K.T0 + i * 86400) end
    return out
end
K.shot("v00-days-0", function() K.reset({ hour = 13 }); K.everyone(); K.settle(); K.go() end)
for _, n in ipairs({ 5, 10, 15, 20, 25, 29, 30, 45, 60, 90, 180 }) do
    K.shot(string.format("v%03d-days-%d", n, n), function() K.reading.days = dates(n); H.app().update() end)
end
