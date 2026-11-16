-- Finding what is on screen in either twin, for the README's moving pictures:
-- the first element in the window of host `host` ("solarui" or "cyberui"),
-- dialog first, for which pick(el) is true, and its middle.
local UIManager = require("ui/uimanager")

local Find = {}

-- The trees shown in a host's window: its open dialog, then its page.
local function roots(host)
    local out = {}
    for i = #UIManager._window_stack, 1, -1 do
        local w = UIManager._window_stack[i].widget
        if w.name == host .. "_popup" and w.element then out[#out + 1] = w.element
        elseif w.name == host then
            if w.overlay then out[#out + 1] = w.overlay end
            out[#out + 1] = w.root
            break
        end
    end
    return out
end

-- The first element for which pick(el) is true, or nil.
function Find.where(host, pick)
    local function walk(el)
        if type(el) ~= "table" then return nil end
        if el.x and pick(el) then return el end
        for _i, c in ipairs(el.children or {}) do
            local f = walk(c)
            if f then return f end
        end
        if el.child then return walk(el.child) end
    end
    UIManager:forceRePaint()   -- (a rebuilt page has no places until it is painted)
    for _i, root in ipairs(roots(host)) do
        local f = walk(root)
        if f then return f end
    end
end

-- The element whose label or text is `text`.
function Find.text(host, text)
    return Find.where(host, function(el) return el.label == text or el.text == text end)
end

-- The middle of an element.
function Find.middle(el)
    return el.x + el.w / 2, el.y + el.h / 2
end

return Find
