-- Widgets on KOReader's real blitter: every element lays out and paints in
-- every scheme and mode without errors, taps reach the right element, and a
-- sheet of all of them is saved for a look (out/widgets-<scheme>-<mode>.png).
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/widgets.lua <repo> [out_dir]

local REPO, OUT = arg[1] or ".", arg[2]
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)

local Theme = require("solarui/theme")
local Layout = require("solarui/ui/layout")
local Label = require("solarui/ui/label")
local Button = require("solarui/ui/button")
local Panel = require("solarui/ui/panel")
local Progress = require("solarui/ui/progress")
local Controls = require("solarui/ui/controls")
local Deco = require("solarui/ui/deco")
local Icon = require("solarui/ui/icon")
local Registry = require("solarui/theme/registry")

local tapped
-- One of everything, in a column.
local function sheet()
    local function btn(v, label, extra)
        local o = { variant = v, label = label, on_tap = function() tapped = label end }
        for k, val in pairs(extra or {}) do o[k] = val end
        return Button:new(o)
    end
    return Layout.Column:new({ pad = 16, gap = 10, children = {
        Label:new({ text = "Display heading", kind = "display" }),
        Label:new({ text = "Body text that is long enough to need an ellipsis at the end of the line for sure", kind = "body" }),
        Label:new({ text = "mono 0123456789 micro", kind = "mono", color = "muted" }),
        Layout.Row:new({ gap = 8, children = {
            btn("primary", "Resume", { icon = "forward" }), btn("secondary", "Secondary"), btn("soft", "Soft", { sub = "sub line" }),
        } }),
        Layout.Row:new({ gap = 8, children = {
            btn("chip_on", "Reading"), btn("chip", "Unread"), btn("ghost", "Ghost"), btn("icon", nil, { icon = "search", width = 44 }),
            btn("secondary", "Locked", { disabled = true }),
        } }),
        Progress:new({ value = 0.64 }),
        Layout.Row:new({ gap = 12, children = {
            Controls.Toggle:new({ on = true }), Controls.Toggle:new({ on = false }),
            Controls.Stepper({ value = 6, min = 1, max = 20, format = function(v) return v .. " PG" end }),
        } }),
        Controls.Segmented({ options = { { "Light", "light" }, { "Dark", "dark" }, { "System", "system" } }, value = "dark" }),
        Panel:new({ shape = "chamfer", label = "Active file", pad = 12, child = Label:new({ text = "Leaf panel" }) }),
        Panel:new({ shape = "frame", label = "Frame", pad = 12, child = Label:new({ text = "Framed panel" }) }),
        Panel:new({ shape = "header", title = "Now reading", title_right = "Page 41", pad = 10,
            child = Label:new({ text = "Header panel" }) }),
        Layout.Row:new({ gap = 8, height = 30, children = {
            Deco.Stripes:new({ width = 90, dir = "d" }), Deco.Divider:new({ grow = true }),
            Icon:new({ name = "home" }), Icon:new({ name = "library", color = "accent" }),
        } }),
        require("solarui/ui/header").pageHeader("Highlights", "highlights", { sub = "A book", on_back = function() end }),
        require("solarui/ui/section").title("Section", "3 of 6"),
        require("solarui/ui/listrow").build({ title = "A row", meta = "Its small line", value = "12" }),
        require("solarui/ui/pager").build({ page = 2, pages = 5 }, "Page", function() end),
        require("solarui/ui/emptystate").build({ plant = "bookmarks", title = "No bookmarks yet", text = "Tap the top corner of a page.",
            action = btn("primary", "Open the book") }),
    } })
end

local W, H = Kit.Screen:getWidth(), Kit.Screen:getHeight()
for _, s in ipairs(Registry.schemeList()) do
    for _, mode in ipairs({ "light", "dark" }) do
        local Settings = require("solarui/settings")
        Settings.set("scheme", s.id)
        Settings.set("mode", mode)
        Theme.refresh()
        local root = sheet()
        local ok, err = pcall(function()
            root:layout(W, H)
            local bb = Kit.canvas()
            local t = Theme.get()
            require("solarui/gfx/paint").fill(bb, 0, 0, W, H, t.c.bg)
            root:paint(bb, 0, 0)
            if OUT then Kit.png(bb, string.format("%s/widgets-%s-%s.png", OUT, s.id, mode)) end
            bb:free()
        end)
        Kit.ok(ok, s.id .. "/" .. mode .. " paints: " .. tostring(err))
    end
end

-- taps land on the innermost element that answers them
do
    local root = sheet()
    root:layout(W, H)
    local bb = Kit.canvas()
    root:paint(bb, 0, 0)
    local resume = root.children[4].children[1]
    local hit = root:hit(resume.x + 5, resume.y + 5, "on_tap")
    Kit.ok(hit == resume, "a tap on Resume finds Resume")
    hit.on_tap()
    Kit.ok(tapped == "Resume", "and runs its action")
    local locked = root.children[5].children[5]
    Kit.ok(root:hit(locked.x + 5, locked.y + 5, "on_tap") == nil, "a disabled button takes no taps")
    Kit.ok(root:hit(W - 2, H - 2, "on_tap") == nil, "empty room takes no taps")
    -- timing: a whole sheet laid out and painted
    local ms = Kit.time(function() root:layout(W, H); root:paint(bb, 0, 0) end, 30)
    print(string.format("sheet layout+paint: %.2f ms", ms))
    Kit.ok(ms < 30, "a full sheet paints in under 30 ms")
    bb:free()
end

-- a tap between the tabs is swallowed (it must not reach KOReader's corner gestures)
do
    local bar = require("solarui/ui/tabbar").build({ { id = "a", label = "A" }, { id = "b", label = "B" } }, "a", function() end)
    bar:layout(W, nil)
    bar:paint(Kit.canvas(), 0, 0)
    local gap = bar:hit(W / 2, 2, "on_tap")
    Kit.ok(gap ~= nil and gap.on_tap == nil, "the tab bar swallows taps that miss a tab")
end

-- the paging row turns pages within the pages there are, and no further
do
    local state, went = { page = 1, pages = 3 }, nil
    local row = require("solarui/ui/pager").build(state, "Page", function(p) went = p end)
    row:layout(W, nil)
    row.children[2].on_tap()
    Kit.ok(went == nil, "back on the first page goes nowhere")
    row.children[4].on_tap()
    Kit.ok(went == 2, "forward opens the next page")
    row.children[5].on_tap()
    Kit.ok(went == 3, "last opens the last page")
    Kit.ok(#require("solarui/ui/pager").build(state, nil, function() end, false).children == 3, "without ends it is two arrows round the page")
end

-- a header shows the plant asked for, or the sprout for a name the garden does not know
do
    local Header = require("solarui/ui/header")
    Kit.ok(Header.plant("search").name == "plant_search", "a known plant is drawn by its name")
    Kit.ok(Header.plant("nowhere").name == "plant_sprout" and Header.plant(nil).name == "plant_sprout", "any other page gets the sprout")
    local Sprites = require("solarui/art/sprites")
    for name in pairs(Header.PLANTS) do Kit.ok(Sprites["plant_" .. name] ~= nil, "plant_" .. name .. " is a drawing") end
end

-- Arabic is shaped and measured as joined text, and paints
do
    local Text = require("solarui/gfx/text")
    local ar = "مرحبا بالعالم"
    local w = Text.width("body", ar)
    Kit.ok(w > 0, "Arabic text has a width")
    local bb = Kit.canvas()
    local drawn = Text.draw(bb, 10, 10, "body", ar, Theme.color("ink"))
    Kit.ok(drawn == w, "and is drawn as wide as it is measured")
    local plain = 0
    for _i, cp in ipairs(Text.codepoints(ar)) do
        plain = plain + require("ui/rendertext"):getGlyph(Theme.text("body").face, cp, false).ax
    end
    Kit.ok(w ~= plain, "joined letters measure differently from isolated ones")
    bb:free()
end

-- the keyboard in every layer and Shift state, and the details editor, paint on every kind of
-- screen buffer devices use (colour 32 and 24 bit, 16 bit, and grey) in every scheme and mode
do
    local BB = require("ffi/blitbuffer")
    local Paint = require("solarui/gfx/paint")
    local Keyboard = require("solarui/ui/keyboard")
    local Settings = require("solarui/settings")
    local noop = function() end
    local types = { RGB32 = BB.TYPE_BBRGB32, RGB24 = BB.TYPE_BBRGB24, RGB16 = BB.TYPE_BBRGB16, GREY8 = BB.TYPE_BB8, GREY4 = BB.TYPE_BB4 }
    for name, type_ in pairs(types) do
        for _, s in ipairs(Registry.schemeList()) do
            for _, mode in ipairs({ "light", "dark" }) do
                Settings.set("scheme", s.id)
                Settings.set("mode", mode)
                Theme.refresh()
                local ok, err = pcall(function()
                    local bb = BB.new(W, H, type_)
                    Paint.fill(bb, 0, 0, W, H, Theme.get().c.bg)
                    for _, layer in ipairs({ "abc", "acc", "num" }) do
                        for _, shift in ipairs({ false, "once", "lock" }) do
                            local kb = Keyboard.build({ layer = layer, shift = shift, on_char = noop, on_back = noop,
                                on_enter = noop, on_layer = noop, on_shift = noop })
                            kb:layout(W, nil)
                            kb:paint(bb, 0, 0)
                        end
                    end
                    local edit = require("solarui/screens/metaedit"):new({ path = require("solarui/data/library").all()[1] })
                    local root = edit:build({ w = W, h = H })
                    root:layout(W, H)
                    root:paint(bb, 0, 0)
                    bb:free()
                end)
                Kit.ok(ok, name .. " " .. s.id .. "/" .. mode .. " keyboard and editor paint: " .. tostring(err))
            end
        end
    end
end

-- the schemes, the default font set and the book progress styles
do
    local ids = {}
    for _, sc in ipairs(Registry.schemeList()) do ids[#ids + 1] = sc.id end
    Kit.ok(table.concat(ids, ",") == "garden,rosewood,peacock,sepia,custom", "the schemes are garden, rosewood, peacock, sepia, custom: " .. table.concat(ids, ","))
    Kit.ok(Registry.fontSets()[1].id == "nouveau", "the default font set is nouveau")
    local styles = {}
    for _, st in ipairs(Progress.STYLES) do styles[#styles + 1] = st.id end
    Kit.ok(table.concat(styles, ",") == "vine,bar,segments", "the progress styles are vine, bar, segments")
    for _, id in ipairs(styles) do
        require("solarui/settings").set("progress_style", id)
        local ok, err = pcall(function()
            local p = Progress:new({ value = 0.4, book = true })
            p:layout(300, nil)
            local bb = Kit.canvas(400, 100)
            p:paint(bb, 10, 10)
            bb:free()
        end)
        Kit.ok(ok, "the " .. id .. " progress paints: " .. tostring(err))
    end
    require("solarui/settings").set("progress_style", nil)
end

-- rounded shapes draw without error at several sizes, including a radius larger than half the box
do
    local Paint = require("solarui/gfx/paint")
    local c = Theme.get().c.ink
    local bb = Kit.canvas(200, 200)
    local ok, err = pcall(function()
        for _, size in ipairs({ { 1, 1 }, { 3, 40 }, { 40, 3 }, { 24, 24 }, { 90, 60 } }) do
            for _, r in ipairs({ 0, 1, 5, 12, 100 }) do
                Paint.round(bb, 10, 10, size[1], size[2], r, "trbl", c)
                Paint.round(bb, 10, 10, size[1], size[2], r, "tr", c)
                Paint.roundFrame(bb, 10, 10, size[1], size[2], r, "trbl", 2, c)
                Paint.roundBox(bb, 10, 10, size[1], size[2], r, "tl", 1, c, c)
            end
        end
    end)
    Kit.ok(ok, "round, roundFrame and roundBox draw at every size: " .. tostring(err))
    local bw = Kit.canvas(60, 60)
    Paint.fill(bw, 0, 0, 60, 60, require("ffi/blitbuffer").COLOR_WHITE)
    Paint.round(bw, 10, 10, 40, 40, 100, "trbl", require("ffi/blitbuffer").COLOR_BLACK)
    Kit.ok(bw:getPixel(30, 30):getColor8().a == 0 and bw:getPixel(10, 10):getColor8().a == 255,
        "a radius past half the box gives a round shape: centre filled, corner left empty")
    bb:free()
    bw:free()
end

Kit.finish("widgets")
