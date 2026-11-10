-- Editing the home launcher: every button in order, with moves, hide or show,
-- and edit; new buttons of the reader's own are added at the bottom.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local EditRow = require("solarui/ui/editrow")
local Frame = require("solarui/screens/frame")
local Icon = require("solarui/ui/icon")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Launcher = require("solarui/data/launcher")
local LauncherUI = require("solarui/ui/launcher")
local Screen = require("solarui/screens/screen")
local _ = require("solarui/gettext")

local LauncherScreen = Screen:extend()

-- One button of the launcher: its glyph and name, then its moves.
local function entryRow(entry, i, count)
    local icon, label, sub = LauncherUI.describe(entry)
    local fixed = entry.id == Launcher.FIXED
    local muted = entry.hidden and "muted" or "ink"
    local buttons = {
        EditRow.button("up", function() Launcher.move(entry.id, -1); App.update() end, i > 1),
        EditRow.button("down", function() Launcher.move(entry.id, 1); App.update() end, i < count),
    }
    if not fixed then
        buttons[#buttons + 1] = EditRow.button(entry.hidden and "plus" or "eye", function()
            Launcher.setHidden(entry.id, not entry.hidden)
            App.update()
        end)
        buttons[#buttons + 1] = EditRow.button("edit", function() App.push("launchedit", { id = entry.id }) end)
    end
    return EditRow.line({
        Icon:new({ name = icon, size = 24, color = muted }),
        Layout.Column:new({ grow = true, children = {
            Label:new({ text = label, kind = "heading", color = muted }),
            Label:new({ text = entry.hidden and _("Hidden") or sub, kind = "mono_small", color = "muted" }),
        } }),
    }, buttons, not fixed and function() LauncherUI.askRemove(entry, App.update) end or nil)
end

-- Build the editor.
function LauncherScreen:build()
    local entries = Launcher.entries()
    local body = {}
    for i, entry in ipairs(entries) do body[#body + 1] = entryRow(entry, i, #entries) end
    body[#body + 1] = Button:new({ label = _("+ Add button"), variant = "primary", corners = "tb", on_tap = function()
        if not Launcher.canAdd() then return App.toast(_("The launcher is full")) end
        App.push("launchedit", { id = Launcher.add() })
    end })
    return Frame.page({ screen = self, title = _("Launcher"), tab = "settings",
        body = Frame.paged(self, body, _("Page")) })
end

return LauncherScreen
