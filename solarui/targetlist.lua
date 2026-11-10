-- What the launcher editor offers a button to open, as lists a reader can
-- browse: the actions plugins add and KOReader's own actions by kind. A row
-- is { icon, label, sub, rows = fn (opens a list) } or { icon, label, sub, target }.

local Dispatcher = require("dispatcher")
local _ = require("solarui/gettext")

local TargetList = {}

-- The kinds of KOReader action that make sense on home, with Dispatcher's
-- own section ids.
local SECTIONS = {
    { "general", _("General"), "controls" }, { "device", _("Device"), "power" },
    { "screen", _("Screen and lights"), "light" }, { "filemanager", _("File browser"), "files" },
}

-- Dispatcher keeps its list of actions to itself; its own functions hold it.
local function actionTable()
    local i = 1
    while true do
        local name, value = debug.getupvalue(Dispatcher.registerAction, i)
        if not name then return nil end
        if name == "settingsList" then return value end
        i = i + 1
    end
end

-- The ids of the actions KOReader itself has, read from the list in its own
-- source (anything else in Dispatcher's table was added by a plugin); nil when
-- the source cannot be read.
local core_ids
local function coreActions()
    if core_ids == nil then
        core_ids = false
        local f = io.open("frontend/dispatcher.lua", "r")
        local text = f and f:read("*a")
        if f then f:close() end
        local body = text and text:match("local dispatcher_menu_order = (%b{})")
        if body then
            core_ids = {}
            for id in body:gmatch('"([%w_]+)"') do core_ids[id] = true end
        end
    end
    return core_ids or nil
end

-- The actions anyone can run with nothing more to say, as { id, title, plugin,
-- section } sorted by title.
local function plainActions()
    local list, core, out = actionTable(), coreActions(), {}
    for id, a in pairs(list or {}) do
        if type(a) == "table" and a.category == "none" and a.title and a.condition ~= false then
            out[#out + 1] = { id = id, title = tostring(a.title), plugin = core ~= nil and not core[id], a = a }
        end
    end
    table.sort(out, function(x, y) return x.title:lower() < y.title:lower() end)
    return out
end

-- A leaf row that picks an action.
local function actionRow(entry)
    return { icon = "controls", label = entry.title, sub = _("Action"),
        target = { kind = "action", id = entry.id, value = true, title = entry.title } }
end

-- The rows of the actions plugins added, or of one section of KOReader's.
local function actionRows(want)
    local rows = {}
    for _i, e in ipairs(plainActions()) do
        if want(e) then rows[#rows + 1] = actionRow(e) end
    end
    return rows
end

-- The top list of places to pick a target from.
function TargetList.root()
    local rows = {
        { icon = "plus", label = _("Plugin actions"), sub = _("What plugins add to gestures"), rows = function()
            return actionRows(function(e) return e.plugin end)
        end },
    }
    for _i, s in ipairs(SECTIONS) do
        rows[#rows + 1] = { icon = s[3], label = s[2], sub = _("KOReader actions"), rows = function()
            return actionRows(function(e) return e.a[s[1]] == true and not e.plugin end)
        end }
    end
    return rows
end

return TargetList
