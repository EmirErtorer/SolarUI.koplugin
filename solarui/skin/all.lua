-- KOReader's own widgets in SolarUI's style, all at once: loads every skin
-- (each registers itself with the core) and switches them on. A skin that is
-- not listed here is not loaded: add its name to SKINS.

local Skin = {}

-- The skins, in the order they are asked about a widget.
local SKINS = { "message", "confirm", "highlightmenu", "edithighlight", "buttondialog", "keyboard", "inputdialog", "list", "dictionary", "textviewer", "numbers", "choice", "keyvalue", "sort", "progress", "qr", "network", "bookstatus" }

-- Style everything. Safe to call every time KOReader starts a reader.
function Skin.install()
    local Core = require("solarui/skin/core")
    for _i, name in ipairs(SKINS) do require("solarui/skin/" .. name) end
    Core.install()
    require("solarui/skin/frontlight").install()
    require("solarui/skin/configdialog").install()
end

return Skin
