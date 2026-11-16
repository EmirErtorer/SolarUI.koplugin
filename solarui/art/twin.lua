-- The twin switch's plaque as a drawing (see art/twinart.lua): twin_switch
-- with the id of the UI in charge as its state.

local TwinArt = require("solarui/art/twinart")

return {
    twin_switch = function(_c, vw, vh, active) return TwinArt.body(vw, vh, active) end,
}
