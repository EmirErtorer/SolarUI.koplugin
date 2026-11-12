-- Named parts of a poster screen: a group's saved tweak moves, stretches or
-- hides all of its parts, the plain layout can be asked for, every part of
-- home has a unique name, and the editor gets a box for each.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/sceneedit.lua <repo>

local REPO = arg[1] or "."
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Scene = require("solarui/ui/scene")
local SceneEdit = require("solarui/ui/sceneedit")
local Label = require("solarui/ui/label")

-- Tweaks for a made-up screen "t", given to the scene as if saved.
package.loaded["solarui/data/layout_overrides"] = {
    t = { ["t.moved"] = { dx = 10, dy = 20, sx = 2 }, ["t.gone"] = { hidden = true } },
}

-- A scene with a few named parts.
local function make()
    local s = Scene.make("t", 1072, 1448, 1448)
    s:group("t.plain", "Plain", function() s:backdrop("bee", 100, 100, 50, 40) end)
    s:group("t.moved", "Moved", function()
        s:backdrop("bee", 200, 300, 60, 30)
        s:place(Label:new({ text = "hello" }), 220, 340, 100)
    end)
    s:group("t.gone", "Gone", function() s:backdrop("bee", 400, 400, 50, 50); s:place(Label:new({ text = "x" }), 400, 460, 50) end)
    s:layout(1072, 1448)
    return s
end

local s = make()
Kit.ok(s.items[1][2] == s:px(100) and s.items[1][3] == s:px(100), "an untouched part stays where it was put")
Kit.ok(s.items[2][2] == s:px(210) and s.items[2][3] == s:px(320), "a moved part is shifted by its tweak")
Kit.ok(s.items[2][4] == s:px(120) and s.items[2][5] == s:px(30), "a stretched part's width grows, its height stays")
Kit.ok(s.children[1].sx == s:px(220 + 10 + 20 * 1) and s.children[1].sy == s:px(360), "text in the group moves and stretches from the group's corner")
Kit.ok(s.children[1].sw == s:px(200), "text in the group is given the stretched width")
Kit.ok(#s.items == 2 and #s.children == 1, "a hidden part leaves nothing behind")
Kit.ok(s.items[2].key:find("210", 1, true) ~= nil, "a backdrop's key follows its box, so a change redraws it")
Kit.ok(#s.groups == 3, "every group is listed, hidden ones too")

SceneEdit.raw = true
local plain = make()
Kit.ok(plain.items[2][2] == plain:px(200) and #plain.items == 3, "the plain layout ignores the tweaks")
local boxes = SceneEdit.boxes(plain)
Kit.ok(#boxes == 3 and boxes[2].id == "t.moved" and math.abs(boxes[2].x - 200) < 1, "the editor gets each group's box in units")
Kit.ok(boxes[2].ox == 200 and boxes[2].oy == 300, "and the corner a stretch grows from")
SceneEdit.hide = { ["t.plain"] = true }
Kit.ok(#make().groups == 3 and #make().items == 2, "the editor can leave one group out")
SceneEdit.raw, SceneEdit.hide = false, {}

-- Home: every part named, once, in the same way
package.loaded["solarui/data/layout_overrides"] = { home = {} }
local Settings = require("solarui/settings")
local Home = require("solarui/screens/home")
local W, H = 1072, 1448
local function homeScene(w, h)
    local scene = Home:new({}):build({ w = w, h = h })
    scene:layout(w, h)
    return scene
end
local home = homeScene(W, H)
local seen, n = {}, 0
for _i, g in ipairs(home.groups) do
    n = n + 1
    Kit.ok(not seen[g.id], "part name used once: " .. g.id)
    Kit.ok(g.id:match("^home%.[%w_]+$") ~= nil, "part name is plain: " .. g.id)
    seen[g.id] = true
end
Kit.ok(n >= 25, "home names its parts (" .. n .. ")")
Kit.ok(#SceneEdit.boxes(home) >= 25, "the editor gets a box for home's parts")

-- a tweak on home moves just that part, on screens of any shape
for _i, size in ipairs({ { 600, 800 }, { 758, 1024 }, { 1072, 1448 }, { 1264, 1680 }, { 1448, 1072 } }) do
    package.loaded["solarui/data/layout_overrides"] = { home = {} }
    local before = homeScene(size[1], size[2])
    package.loaded["solarui/data/layout_overrides"] = { home = { ["home.snail"] = { dx = 40, dy = -10 } } }
    local after = homeScene(size[1], size[2])
    local function snail(sc)
        for _j, g in ipairs(sc.groups) do if g.id == "home.snail" then return g.members[1] end end
    end
    local a, b = snail(before), snail(after)
    -- (each corner is rounded to a pixel on its own, so allow one pixel)
    Kit.ok(a and b and math.abs(b.el.sx - a.el.sx - after:px(40)) <= 1 and math.abs(b.el.sy - a.el.sy + after:px(10)) <= 1,
        string.format("a tweak moves the snail by 40 units on %dx%d", size[1], size[2]))
    Kit.ok(#before.items == #after.items and #before.children == #after.children, "the rest of home is untouched")
end
package.loaded["solarui/data/layout_overrides"] = { home = { ["home.snail"] = { hidden = true } } }
local hidden = homeScene(W, H)
Kit.ok(#hidden.children == #home.children - 1, "a hidden part is not on home")

Kit.finish("sceneedit")
