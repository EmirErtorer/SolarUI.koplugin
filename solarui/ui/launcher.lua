-- The home launcher's buttons as home shows them: for each entry of the
-- launcher list (the built-in places and the reader's own buttons) its plant,
-- icon, name and what it does.

local Addons = require("solarui/apps/addons")
local App = require("solarui/app")
local InkAway = require("solarui/apps/inkaway")
local LauncherData = require("solarui/data/launcher")
local Targets = require("solarui/targets")
local _ = require("solarui/gettext")

local Launcher = {}

-- The built-in buttons: id -> function giving plant, icon, name, action.
local BUILTIN = {
    library = function() return "dock_library", "library", _("Library"), function() App.go("library") end end,
    collections = function() return "dock_collections", "collections", _("Collections"), function() App.go("collections") end end,
    history = function() return "dock_history", "history", _("History"), function() App.go("history") end end,
    search = function() return "dock_search", "search", _("Search"), function() App.push("search") end end,
    inkaway = function() return "dock_medallion", InkAway.icon, "Ink Away", function() Addons.launch(InkAway) end end, -- i18n: keep
    settings = function() return "dock_settings", "settings", _("Settings"), function() App.go("settings") end end,
}

-- The plant, icon, name and action of an entry: the reader's own when it has
-- them (on a blank seed pod that carries its icon), else the built-in one.
function Launcher.describe(entry)
    local c = entry.custom
    if c then
        return "dock_medallion", c.icon, c.name or "",
            function() if c.target then Targets.run(c.target) else App.toast(_("Pick what this button opens")) end end
    end
    return BUILTIN[entry.id]()
end

-- Ask before taking a button away: the reader's own are deleted, a built-in
-- one is hidden (it can be shown again in the launcher editor).
function Launcher.askRemove(entry, after)
    if entry.id == LauncherData.FIXED then return App.toast(_("This button always stays, so the settings stay reachable")) end
    local _art, _icon, label = Launcher.describe(entry)
    local builtin = LauncherData.isBuiltin(entry.id)
    App.confirm({ title = builtin and _("Hide this button?") or _("Delete this button?"), text = label, danger = true,
        ok = builtin and _("Hide") or _("Delete"), on_ok = function()
            if builtin then LauncherData.setHidden(entry.id, true) else LauncherData.remove(entry.id) end
            if after then after() end
        end })
end

return Launcher
