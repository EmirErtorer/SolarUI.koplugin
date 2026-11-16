-- Small drawings of the notebook shelf's looks for the picker: each board of
-- art/inkcovers.lua as "inkcover_<id>" (the two that show the first page on
-- ruled paper) and each frame of art/inkframes.lua round a sheet of paper as
-- "inkframe_<id>".

local InkCovers = require("solarui/art/inkcovers")
local InkFrames = require("solarui/art/inkframes")
local Svg = require("solarui/art/svg")

local Previews = {}

-- Ruled paper over the canvas, for a look that shows the first page.
local function paper(w, h)
    local out = Svg.path(string.format("M0 0 L%d 0 L%d %d L0 %dZ", w, w, h, h), "#FBF8EE")
    for y = 60, h - 20, 22 do out = out .. Svg.line(string.format("M44 %d L%d %d", y, w - 24, y), "#C9D6DE", 1.2) end
    return out
end

for _i, l in ipairs(InkCovers.LOOKS) do
    Previews["inkcover_" .. l.id] = function(_c, vw, vh)
        local body = l.draw and l.draw() or (paper(InkCovers.W, InkCovers.H) .. (l.id == "mount" and InkCovers.mount() or InkCovers.pageEdges()))
        return Svg.group(0, 0, 0, body, vw / InkCovers.W, vh / InkCovers.H)
    end
end
for _i, l in ipairs(InkFrames.LOOKS) do
    Previews["inkframe_" .. l.id] = function(_c, vw, vh)
        local x, y, w, h = InkFrames.window(l.id, vw, vh)
        return Svg.path(string.format("M%s %s L%s %s L%s %s L%s %sZ", x, y, x + w, y, x + w, y + h, x, y + h), "#FBF8EE") .. InkFrames.svg(l.id, vw, vh)
    end
end

return Previews
