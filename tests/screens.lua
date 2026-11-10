-- Screens on KOReader's real blitter with the emulator's library: each screen
-- builds, lays out and paints in every scheme and mode, within a time budget,
-- and is saved as out/<screen>-<scheme>-<mode>.png for a look.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/screens.lua <repo> [out_dir] [screen ...]

local REPO, OUT = arg[1] or ".", arg[2]
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
-- the real library and history of the emulator, read only
G_reader_settings:saveSetting("home_dir", require("datastorage"):getDataDir() .. "/Books")

-- SOLARUI_LANG=de draws in that language (KOReader's own day and month names too);
-- TRUNC=1 lists the texts that were cut short with an ellipsis
local LANG = os.getenv("SOLARUI_LANG")
if LANG and LANG ~= "" then require("gettext").changeLang(LANG) end
local truncated = {}
if os.getenv("TRUNC") then
    local Text = require("solarui/gfx/text")
    local fit = Text.fit
    Text.fit = function(kind, s, w)
        local r = fit(kind, s, w)
        if r ~= s and r:find("…", 1, true) then truncated[s] = true end
        return r
    end
end

local Theme = require("solarui/theme")
local Settings = require("solarui/settings")
local Paint = require("solarui/gfx/paint")
local Library = require("solarui/data/library")

local only = {}
for i = 3, #arg do only[arg[i]] = true end
local SCREENS = { "home", "library", "dossier", "collections", "history", "search", "settings", "trash", "fonts", "topbar", "launcher", "launchedit", "iconpick", "targetpick", "metaedit", "filepick", "colourpick", "annotations", "updates" }
local PARAMS = {
    dossier = function() return { path = Library.all()[1] } end,
    metaedit = function() return { path = Library.all()[1] } end,
    launchedit = function() return { id = "library" } end,
    iconpick = function() return { current = "pen", on_pick = function() end } end,
    targetpick = function() return { done = function() end } end,
    colourpick = function() return { title = "Accent", current = "#2F5D46", on_pick = function() end } end,
    annotations = function() return { path = Library.all()[1], kind = "highlights" } end,
    filepick = function() return { dir = Library.home(), exts = { png = true }, on_pick = function() end } end,
}

Library.all()
local W, H = Kit.Screen:getWidth(), Kit.Screen:getHeight()

-- Where a painted screen has something on its outermost pixels (a drawing
-- cut by the screen's edge), as text; nil when the edge is clear.
local function edgeTouched(bb)
    local bg = Theme.get().painted.bg
    local function clear(x, y)
        local p = bb:getPixel(x, y)
        return p:getR() == bg[1] and p:getG() == bg[2] and p:getB() == bg[3]
    end
    for y = 0, H - 1 do
        if not clear(0, y) then return "left at " .. y end
        if not clear(W - 1, y) then return "right at " .. y end
    end
    for x = 0, W - 1 do
        if not clear(x, 0) then return "top at " .. x end
        if not clear(x, H - 1) then return "bottom at " .. x end
    end
    return nil
end
for _, id in ipairs(SCREENS) do
    if next(only) == nil or only[id] then
        local ok_mod, Mod = pcall(require, "solarui/screens/" .. id)
        if not ok_mod then
            Kit.ok(false, id .. " loads: " .. tostring(Mod))
        else
            for _, scheme in ipairs({ "garden", "rosewood" }) do
                for _, mode in ipairs({ "light", "dark" }) do
                    Settings.set("scheme", scheme)
                    Settings.set("mode", mode)
                    Theme.refresh()
                    local bb = Kit.canvas()
                    local ok, err = pcall(function()
                        local s = Mod:new(PARAMS[id] and PARAMS[id]() or {})
                        local root = s:build({ w = W, h = H })
                        root:layout(W, H)
                        Paint.fill(bb, 0, 0, W, H, Theme.get().c.bg)
                        root:paint(bb, 0, 0)
                        if id == "home" then
                            local where = edgeTouched(bb)
                            Kit.ok(not where, "home keeps its drawings off the screen's edge: " .. tostring(where))
                        end
                        if scheme == "garden" and mode == "light" then
                            local ms = Kit.time(function()
                                local r = Mod:new(PARAMS[id] and PARAMS[id]() or {}):build({ w = W, h = H })
                                r:layout(W, H)
                                r:paint(bb, 0, 0)
                            end, 10)
                            print(string.format("%-12s build+layout+paint %.2f ms", id, ms))
                            Kit.ok(ms < 60, id .. " draws in under 60 ms")
                        end
                    end)
                    Kit.ok(ok, id .. " " .. scheme .. "/" .. mode .. ": " .. tostring(err))
                    if OUT and ok then Kit.png(bb, string.format("%s/%s-%s-%s.png", OUT, id, scheme, mode)) end
                    bb:free()
                end
            end
        end
    end
end

-- the tabs of the reading log each build and paint
if next(only) == nil or only.history then
    local History = require("solarui/screens/history")
    for _, tab in ipairs({ "stats", "streaks", "calendar", "goal" }) do
        for _, mode in ipairs({ "light", "dark" }) do
            Settings.set("scheme", "peacock")
            Settings.set("mode", mode)
            Theme.refresh()
            local bb = Kit.canvas()
            local ok, err = pcall(function()
                local s = History:new({})
                s.tab = tab
                local root = s:build({ w = W, h = H })
                root:layout(W, H)
                Paint.fill(bb, 0, 0, W, H, Theme.get().c.bg)
                root:paint(bb, 0, 0)
            end)
            Kit.ok(ok, "history/" .. tab .. " " .. mode .. ": " .. tostring(err))
            if OUT and ok then Kit.png(bb, string.format("%s/history-%s-%s.png", OUT, tab, mode)) end
            bb:free()
        end
    end
end

local cut = {}
for text in pairs(truncated) do cut[#cut + 1] = text end
table.sort(cut)
for _, text in ipairs(cut) do print("TRUNC " .. (LANG or "en") .. " " .. text) end

Kit.finish("screens")
