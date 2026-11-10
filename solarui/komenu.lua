-- KOReader's own drop-down menu, found so home can open it.

local KoMenu = {}

-- The file browser's menu with the most entries (some plugins add an empty one).
function KoMenu.fileManagerMenu()
    local fm = require("apps/filemanager/filemanager").instance
    if not fm then return nil end
    local function entries(m) return m and m.registered_widgets and #m.registered_widgets or 0 end
    local best = fm.menu
    for _i, module in ipairs(fm) do
        if module.name == "filemanagermenu" and entries(module) > entries(best) then best = module end
    end
    return best
end

return KoMenu
