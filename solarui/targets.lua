-- What a launcher button can open: a KOReader action (the ones gestures
-- use, plugins' own included). The lists to choose from are in
-- targetlist.lua; this file runs and describes a target.
-- A target is { kind = "action", id, value, title }.

local Dispatcher = require("dispatcher")
local _ = require("solarui/gettext")

local Targets = {}

-- Run a target.
function Targets.run(target)
    if target.kind == "action" then
        Dispatcher:execute({ [target.id] = target.value })
    end
end

-- A short line saying what a target is, for the editor and the button.
function Targets.describe(target)
    if not target then return _("Nothing yet") end
    return tostring(target.title or target.id)
end

return Targets
