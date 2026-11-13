-- A toast shown while a dialog is open lies clear of the dialog.
local H = ...
local UIManager = require("ui/uimanager")
H.step(1.5, function() H.app().go("garden"); require("solarui/ui/gardenpopup").open("tulip", function() return { "tulip", "rose" } end) end)
H.step(.8, function() H.app().toast("Left for the birds."); UIManager:forceRePaint() end)
H.step(.8, function()
    UIManager:forceRePaint(); H.shot("toast-with-dialog")
    local host = require("solarui/app")
    H.check(true, "shot")
end)
