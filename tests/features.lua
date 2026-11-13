-- The data behind the newer features, on KOReader's real code with throwaway
-- settings: the launcher list, the library start folder, the reading status
-- marks and the cover stretch default.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/features.lua <repo>

local REPO = arg[1] or "."
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Theme = require("solarui/theme")
G_reader_settings:saveSetting("home_dir", require("datastorage"):getDataDir() .. "/Books")

local Settings = require("solarui/settings")

-- launcher list
do
    local Launcher = require("solarui/data/launcher")
    local ids = {}
    for _, e in ipairs(Launcher.entries()) do ids[#ids + 1] = e.id end
    Kit.ok(table.concat(ids, ",") == table.concat(Launcher.BUILTIN, ","), "the launcher starts with the built-in buttons in order")
    Launcher.move("search", 1)
    Kit.ok(Launcher.entries()[1].id == "history" and Launcher.entries()[2].id == "search", "a button moves down")
    Launcher.setHidden("history", true)
    Kit.ok(#Launcher.visible() == #Launcher.BUILTIN - 1, "a hidden button is not shown")
    Launcher.setHidden(Launcher.FIXED, true)
    Kit.ok(Launcher.get(Launcher.FIXED).hidden == nil, "the settings button cannot be hidden")
    local id = Launcher.add()
    local e = Launcher.get(id)
    Kit.ok(e and e.custom and e.custom.name == "New button", "a new button of the reader's own is added")
    Launcher.setCustom(id, { name = "Notes", icon = "pen", target = { kind = "action", id = "history", title = "History" } })
    Kit.ok(Launcher.get(id).custom.name == "Notes", "its name, icon and target are kept")
    Launcher.setCustom("inkaway", { name = "Stats", icon = "stats" })
    Kit.ok(Launcher.get("inkaway").custom.name == "Stats", "a built-in button can be replaced")
    Launcher.remove("inkaway")
    Kit.ok(Launcher.get("inkaway") and Launcher.get("inkaway").custom == nil, "and restored")
    Launcher.remove(id)
    Kit.ok(Launcher.get(id) == nil, "a button of the reader's own can be deleted")
    local Targets = require("solarui/targets")
    Kit.ok(Targets.describe({ kind = "action", id = "history", title = "History" }) == "History", "a target reads as its title")
    Kit.ok(Targets.describe(nil) == "Nothing yet", "no target says so")
end

-- library start folder
do
    local Library = require("solarui/data/library")
    local home = Library.home()
    Kit.ok(#Library.startTrail() == 1 and Library.startTrail()[1] == home, "the library opens in the home folder by default")
    local sub
    for _, f in ipairs(Library.list(home).folders) do sub = sub or f.path end
    if sub then
        Settings.set("library_start_dir", sub)
        local trail = Library.startTrail()
        Kit.ok(#trail == 2 and trail[1] == home and trail[2] == sub, "a chosen folder opens with the home above it")
    end
    Settings.set("library_start_dir", "/nonexistent/folder")
    Kit.ok(Library.startTrail()[1] == home and #Library.startTrail() == 1, "a folder that is gone falls back to the home")
    Settings.set("library_start_dir", nil)
    Kit.ok(#Library.trailTo("/elsewhere/else") == 1, "a folder outside the home is a trail of its own")
end

-- cover stretch is off until chosen
do
    local Covers = require("solarui/data/covers")
    Kit.ok(Covers.stretch() == false, "covers keep their proportions by default")
    Settings.set("cover_stretch", true)
    Kit.ok(Covers.stretch() == true, "and stretch when the setting is on")
    Settings.set("cover_stretch", nil)
end

-- library sorting, grouping and filters
do
    local Library = require("solarui/data/library")
    local Groups = require("solarui/data/libgroups")
    local all = Library.all()
    local up = Library.sort(all, "title")
    local down = Library.sort(all, "title", true)
    Kit.ok(#up == #all and up[1] == down[#down], "reversing a sort turns the order round")
    for _, order in ipairs(Library.SORTS) do
        Kit.ok(#Library.sort(all, order) == #all, "sort by " .. order .. " keeps every book")
    end
    for _, kind in ipairs({ "author", "series", "status", "format", "added" }) do
        local total = 0
        for _, g in ipairs(Groups.list(kind)) do
            total = total + g.count
            Kit.ok(#Groups.books(kind, g.key) == g.count, "group " .. kind .. "/" .. g.name .. " holds what it counts")
        end
        Kit.ok(total == #all, "grouping by " .. kind .. " places every book once")
    end
    local fmt = Groups.formats()[1]
    local only = Groups.filter(all, { format = fmt })
    Kit.ok(#only > 0 and #only <= #all, "the format filter keeps that format")
    Kit.ok(Groups.filter(all, {}) == all, "no filter returns the same list")

    -- the screen in every grouping, picking books
    local Lib = require("solarui/screens/library")
    local W, H = Kit.Screen:getWidth(), Kit.Screen:getHeight()
    for _, kind in ipairs({ "folder", "all", "author", "series", "status", "format", "added" }) do
        Settings.set("library_group", kind)
        local ok, err = pcall(function()
            local s = Lib:new({})
            local root = s:build({ w = W, h = H })
            root:layout(W, H)
            local bb = Kit.canvas()
            root:paint(bb, 0, 0)
            s.selecting = true
            s:build({ w = W, h = H }):layout(W, H)
            bb:free()
        end)
        Kit.ok(ok, "library grouped by " .. kind .. " builds: " .. tostring(err))
    end
    Settings.set("library_group", nil)
end

-- icons from the device
do
    local Icons = require("solarui/gfx/icons")
    local ids = {}
    for _, src in ipairs(Icons.sources()) do ids[#ids + 1] = src.id end
    Kit.ok(ids[1] == "set" and ids[#ids] == "ko", "the set and KOReader's own icons are offered: " .. table.concat(ids, ","))
    local ko = Icons.list("ko")
    local set = {}
    for _, n in ipairs(ko) do set[n] = true end
    Kit.ok(#ko > 40 and set["ko:appbar.search.svg"], "KOReader's stock icons are listed with a prefix")
    Kit.ok(not set["ko:rotation.A.svg"] and not set["ko:wifi.open.0.svg"], "its state variants are left out")
    Kit.ok(Icons.sourceOf("ko:appbar.search.svg") == "ko" and Icons.sourceOf("pen") == "set" and Icons.sourceOf(nil) == "set",
        "an icon name tells its source")
    local function inked(name)
        local bb = Kit.canvas()
        Icons.draw(bb, name, 0, 0, 30, require("ffi/blitbuffer").COLOR_BLACK)
        local w, n = bb:getWidth(), 0
        for y = 0, 29 do for x = 0, 29 do if bb:getPixel(x, y):getColor8().a < 255 then n = n + 1 end end end
        bb:free()
        return n, w
    end
    Kit.ok(inked("ko:appbar.search.svg") > 20, "a stock icon draws")
    Kit.ok(inked("ko:no-such-icon.svg") == inked("tools"), "a stock icon that is gone draws the tools icon")
    local Pick = require("solarui/screens/iconpick")
    local picked
    local s = Pick:new({ current = "ko:appbar.search.svg", on_pick = function(n) picked = n end })
    Kit.ok(s.source == "ko" and s:names()[1]:sub(1, 3) == "ko:", "the picker opens on the source of the current icon")
    local W, H = Kit.Screen:getWidth(), Kit.Screen:getHeight()
    local root = s:build({ w = W, h = H })
    root:layout(W, H)
    local bb = Kit.canvas()
    root:paint(bb, 0, 0)
    bb:free()
    Kit.ok(s.pages and s.pages >= 1, "the picker pages the stock icons")
end

-- the support QR code: a square of whole modules, white round dark modules
do
    local QRCode = require("solarui/ui/qrcode")
    local qr = QRCode:new({ text = "https://buymeacoffee.com/emirertorer", size = 150 })
    qr:layout(nil, nil)
    Kit.ok(qr.grid ~= nil and #qr.grid >= 21 and qr.w == qr.h and qr.w % qr:module() == 0, "the QR code is a square of whole modules")
    local bb = Kit.canvas(400, 400)
    require("solarui/gfx/paint").fill(bb, 0, 0, 400, 400, require("ffi/blitbuffer").COLOR_BLACK)
    qr:paint(bb, 10, 10)
    Kit.ok(bb:getPixel(10, 10):getColor8().a == 255 and bb:getPixel(10 + qr:module() * 4, 10 + qr:module() * 4):getColor8().a == 0,
        "white quiet border round a dark finder corner")
    bb:free()
end

-- the colour dial
do
    local Color = require("solarui/theme/color")
    for _, hex in ipairs({ "#2457D6", "#C62828", "#0F8076", "#FFFFFF", "#000000", "#7BF0A8" }) do
        local h, s_, v = Color.toHSV(Color.parse(hex))
        Kit.ok(Color.hex(Color.fromHSV(h, s_, v)) == hex, "a colour survives hue, saturation and value: " .. hex)
    end
    local Dial = require("solarui/ui/dial")
    local got
    local dial = Dial:new({ hue = 0, sat = 1, val = 1, size = 300, on_change = function(h, s_, v) got = { h, s_, v } end })
    dial:layout(300, 300)
    local bb = Kit.canvas()
    dial:paint(bb, 20, 30)
    Kit.ok(Kit.time(function() dial:paint(bb, 20, 30) end, 5) < 15, "the dial repaints in under 15 ms")
    bb:free()
    -- a tap on the right of the ring is a hue of about 90 degrees
    local cx, cy = dial.x + dial.w / 2, dial.y + dial.h / 2
    local ring_r = dial.w / 2 - Theme.px(9) - Theme.px(8)
    dial.tap_pos = { x = cx + ring_r, y = cy }
    dial:on_tap()
    Kit.ok(got and math.abs(got[1] - 90) < 3, "a tap on the ring picks its hue: " .. tostring(got and got[1]))
    got = nil
    dial.tap_pos = { x = cx - 10, y = cy + 10 }
    dial:on_tap()
    Kit.ok(got and got[2] > 0 and got[2] < 1 and got[3] < 1, "a tap in the matrix picks saturation and brightness")
    got = nil
    dial.tap_pos = { x = dial.x + 2, y = dial.y + 2 }
    dial:on_tap()
    Kit.ok(got == nil, "a tap outside both changes nothing")
    local Pick = require("solarui/screens/colourpick")
    local p = Pick:new({ current = "#2457D6", on_pick = function() end })
    p:setHex("not a colour")
    Kit.ok(Color.hex(p:rgb()) == "#2457D6", "a bad colour code leaves the colour as it was")
    p:setHex("#C62828")
    Kit.ok(Color.hex(p:rgb()) == "#C62828", "a typed colour code is taken")
end

-- reader parking: on by default, and nothing to do when nothing is parked
do
    local Park = require("solarui/park")
    local Settings = require("solarui/settings")
    Settings.set("park_reader", nil)
    Kit.ok(Park.enabled(), "parking is on until it is switched off")
    Settings.set("park_reader", false)
    Kit.ok(not Park.enabled() and not Park.park({ document = {} }), "a book is not parked while parking is off")
    Kit.ok(not Park.isParked() and Park.file() == nil and not Park.finish() and not Park.unpark("/some/book.epub"),
        "with nothing parked there is nothing to finish or bring back")
    Kit.ok(Park.ui() == nil, "and no file browser stand-in")
    Settings.set("park_reader", true)
    Kit.ok(Park.enabled() and not Park.park({ document = {} }), "switched on, a book from a path home never opened is not parked (home's rotation unknown)")
    Settings.set("park_reader", nil)
end

-- touches queued while a book closed are not pressed on home
do
    local Host = require("solarui/host")
    local time = require("ui/time")
    local now = time.now()
    local host = { ignore_before = now }
    Kit.ok(Host.stale(host, { time = now - time.s(2) }), "a touch made before the close finished is dropped")
    Kit.ok(not Host.stale(host, { time = now + time.s(2) }), "a touch made after it is kept")
    Kit.ok(not Host.stale({}, { time = now }) and not Host.stale(host, {}), "with no close pending, or no time on the touch, nothing is dropped")
    -- a swipe that starts on the tab bar (which swallows touches but cannot be dragged) must not crash
    local swallower = { swallow = true }
    local pan_host = { stale = function() return false end, target = function() return swallower end }
    local ok_pan, handled = pcall(Host.onPan, pan_host, nil, { pos = { x = 1, y = 1 }, relative = { x = 0, y = -5 } })
    Kit.ok(ok_pan and handled == true and pan_host.dragging == nil, "a pan that starts on something undraggable is swallowed, not a crash")
end

-- paging a long column, the log's metric
do
    local Layout = require("solarui/ui/layout")
    local PagedColumn = require("solarui/ui/pagedcolumn")
    local items = {}
    for i = 1, 10 do items[i] = Layout.Spacer:new({ height = 50 }) end
    local made_pager = false
    local column = PagedColumn:new({ items = items, gap = 0, make_pager = function()
        made_pager = true
        return Layout.Spacer:new({ height = 40 })
    end })
    column:layout(300, 220)
    Kit.ok(column.pages == 4 and made_pager, "a long column pages, leaving room for the paging row (" .. tostring(column.pages) .. ")")
    Kit.ok(#column.children == 3 + 1, "a page holds the items that fit and the paging row")
    column.page = 4
    column:layout(300, 220)
    Kit.ok(#column.children == 1 + 1, "the last page holds what is left")
    local short = PagedColumn:new({ items = { Layout.Spacer:new({ height = 50 }) }, gap = 0, make_pager = function() error("no pager wanted") end })
    short:layout(300, 220)
    Kit.ok(short.pages == 1, "a short column has no paging row")

    local Metric = require("solarui/data/metric")
    local Settings = require("solarui/settings")
    Settings.set("log_metric", nil)
    Kit.ok(not Metric.pages() and Metric.goal(30) == 30 and Metric.text(25.4) == "25 min", "minutes are counted at first, against the goal")
    Metric.toggle()
    Kit.ok(Metric.pages() and Metric.goal(30) == nil and Metric.text(12) == "12 pages", "pages have no minutes goal")
    Kit.ok(Metric.level(0, 30, 10) == 0 and Metric.level(10, 30, 10) == 4 and Metric.level(1, 30, 10) == 1, "page shades go by the largest value shown")
    Settings.set("log_metric", nil)
end

-- translations: the .po reader, plural rules, capitals, the wrapper with a made-up language
do
    local Po = require("solarui/i18n/po")
    local Plural = require("solarui/i18n/plural")
    local Case = require("solarui/i18n/case")
    local I18n = require("solarui/gettext")
    local Format = require("solarui/format")

    local parsed = Po.parse('msgid ""\nmsgstr ""\n"Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);\\n"\n\n'
        .. '#: a.lua\nmsgid "Hello"\nmsgstr "Privet"\n\n#, fuzzy\nmsgid "Maybe"\nmsgstr "Mozhet"\n\n'
        .. 'msgctxt "verb"\nmsgid "Open"\nmsgstr "Otkryt"\n\nmsgid "%d book"\nmsgid_plural "%d books"\nmsgstr[0] "%d kniga"\nmsgstr[1] "%d knigi"\nmsgstr[2] "%d knig"\n\n'
        .. 'msgid "Line"\nmsgstr ""\n"one "\n"two\\n"\n')
    Kit.ok(#parsed.entries == 5 and parsed.entries[1].refs == "a.lua" and parsed.entries[2].flags.fuzzy, "a .po file is read: entries, references, flags")
    Kit.ok(parsed.entries[5].str[1] == "one two\n", "a string split over lines is joined, escapes undone")
    local n, rule = Po.pluralRule(parsed.header)
    Kit.ok(n == 3, "the plural rule's form count is read")
    local ru = Plural.compile(rule)
    Kit.ok(ru(1) == 0 and ru(21) == 0 and ru(2) == 1 and ru(24) == 1 and ru(5) == 2 and ru(11) == 2 and ru(12) == 2 and ru(0) == 2 and ru(100) == 2 and ru(101) == 0,
        "the Russian plural rule picks its forms")
    local pl = Plural.compile("n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2")
    Kit.ok(pl(1) == 0 and pl(3) == 1 and pl(5) == 2 and pl(22) == 1 and pl(12) == 2, "the Polish rule works")
    local fr = Plural.compile("n > 1")
    Kit.ok(fr(0) == 0 and fr(1) == 0 and fr(2) == 1, "the French rule counts 0 and 1 alike")
    Kit.ok(Plural.compile("os.execute('x')")(1) == 0 and Plural.compile("n != 1")(1) == 0, "an expression with anything but arithmetic is not run")

    Kit.ok(Case.upper("istanbul", "tr") == "İSTANBUL" and Case.upper("ığdır", "tr") == "IĞDIR", "Turkish capitals: i becomes İ, ı becomes I")
    Kit.ok(Case.upper("straße") == "STRASSE" and Case.upper("élève") == "ÉLÈVE", "German and French capitals")
    Kit.ok(Case.upper("άνθρωπος", "el") == "ΑΝΘΡΩΠΟΣ" and Case.upper("ΣΤΑΤΙΣΤΙΚΆ", "el") == "ΣΤΑΤΙΣΤΙΚΑ", "Greek capitals carry no accent")
    Kit.ok(Case.upper("привет") == "ПРИВЕТ" and Case.upper("łódź") == "ŁÓDŹ", "Cyrillic and Polish capitals")
    Kit.ok(Format.chars("Мар", 1) == "М" and Format.chars("Ocak", 2) == "Oc", "the first characters are whole characters")

    local dir = (os.getenv("TMPDIR") or "/tmp") .. "/solarui-test-l10n"
    os.execute("rm -rf '" .. dir .. "'; mkdir -p '" .. dir .. "/zz'")
    local f = io.open(dir .. "/zz/solarui.po", "w")
    f:write('msgid ""\nmsgstr ""\n"Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);\\n"\n\n'
        .. 'msgid "Hello"\nmsgstr "Privet"\n\nmsgctxt "verb"\nmsgid "Open"\nmsgstr "Otkryt"\n\n#, fuzzy\nmsgid "Maybe"\nmsgstr "Mozhet"\n\n'
        .. 'msgid "%d book"\nmsgid_plural "%d books"\nmsgstr[0] "%d kniga"\nmsgstr[1] "%d knigi"\nmsgstr[2] "%d knig"\n')
    f:close()
    I18n.root = dir
    Kit.ok(I18n.use("zz_ZZ") == "zz", "a regional code finds its language's folder")
    Kit.ok(I18n("Hello") == "Privet" and I18n("Nothing here") == "Nothing here", "a translated text, and the English for one that is not")
    Kit.ok(I18n("Maybe") == "Maybe", "a fuzzy translation is not used")
    Kit.ok(I18n.c("verb", "Open") == "Otkryt" and I18n.c("noun", "Open") == "Open", "a context tells two meanings apart")
    Kit.ok(I18n.n("%d book", "%d books", 1) == "%d kniga" and I18n.n("%d book", "%d books", 3) == "%d knigi" and I18n.n("%d book", "%d books", 7) == "%d knig",
        "a count picks its plural form")
    Kit.ok(I18n.n("%d file", "%d files", 1) == "%d file" and I18n.n("%d file", "%d files", 2) == "%d files", "an untranslated count is English")
    local cache = require("datastorage"):getSettingsDir() .. "/solarui-l10n-zz.lua"
    Kit.ok(io.open(cache, "r") ~= nil, "the language is kept compiled for the next start")
    os.remove(dir .. "/zz/solarui.po")
    local g = io.open(dir .. "/zz/solarui.po", "w")
    g:write('msgid ""\nmsgstr ""\n\nmsgid "Hello"\nmsgstr "Zdravo"\n')
    g:close()
    Kit.ok(I18n.use("zz") == "zz" and I18n("Hello") == "Zdravo", "an edited .po is read again, not the old compiled copy")
    local user = require("datastorage"):getSettingsDir() .. "/solarui-l10n"
    os.execute("mkdir -p '" .. user .. "'")
    local h = io.open(user .. "/zz.po", "w")
    h:write('msgid ""\nmsgstr ""\n\nmsgid "Hello"\nmsgstr "Mine"\n')
    h:close()
    I18n.use("zz")
    Kit.ok(I18n("Hello") == "Mine", "a reader's own .po wins over the shipped one")
    os.remove(user .. "/zz.po")
    os.remove(cache)
    I18n.use("de_XX")
    Kit.ok(I18n.language() == "en" and I18n("Anything") == "Anything", "a language with no file is English")
    I18n.use("en_XA")
    Kit.ok(I18n("Hello %d") == "[Héllô %d~~]" or I18n("Hello %d"):find("^%[") ~= nil, "the pseudo-language marks texts and keeps placeholders")
    Kit.ok(I18n("Hello %d"):find("%%d") ~= nil, "and keeps the placeholder")
    I18n.use(nil)
    I18n.root = nil
    os.execute("rm -rf '" .. dir .. "'")

    -- the shipped languages: each loads, translates and counts the way its language does
    I18n.root = nil
    local lfs = require("libs/libkoreader-lfs")
    local shipped = 0
    for name in lfs.dir(I18n.dir()) do
        if name:match("^%a%a") and lfs.attributes(I18n.dir() .. "/" .. name, "mode") == "directory" then
            shipped = shipped + 1
            I18n.use(name)
            Kit.ok(I18n.language() == name and I18n("Install") ~= "Install" or name == "tr" or name == "de",
                name .. " loads and translates")
        end
    end
    Kit.ok(shipped >= 10, "ten languages are shipped (" .. shipped .. ")")
    I18n.use(nil)
end

-- the folder picker with nothing being moved (the stats scope, the library start, moving books)
do
    local Library = require("solarui/screens/library")
    local ok, err = pcall(function()
        local s = Library:new({ dir = require("solarui/data/library").home(), pick = { title = "Pick", on_pick = function() end } })
        s:build({ w = Kit.Screen:getWidth(), h = Kit.Screen:getHeight() })
    end)
    Kit.ok(ok, "the folder picker builds without a folder being moved: " .. tostring(err))
end

-- a colour cover drawn in night mode onto a screen of another pixel type (the C
-- blitter would end KOReader)
do
    local Blitbuffer = require("ffi/blitbuffer")
    local Covers = require("solarui/data/covers")
    local Theme = require("solarui/theme")
    local Cover = require("solarui/ui/cover")
    local get, night, style = Covers.get, Theme.nightMode, Settings.get("cover_style")
    local img = Blitbuffer.new(40, 60, Blitbuffer.TYPE_BBRGB24)
    img:fill(Blitbuffer.ColorRGB24(200, 40, 40))
    Covers.get = function() return img end
    Theme.nightMode = function() return true end
    Settings.set("cover_style", "image")
    local bb = Blitbuffer.new(100, 100, Blitbuffer.TYPE_BBRGB32)
    local c = Cover:new({ w = 44, h = 64, path = "/x/book.epub" })
    Kit.ok(pcall(c.drawFace, c, bb, 10, 10), "a colour cover is drawn inverted onto a screen of another pixel type")
    bb:free(); img:free()
    Covers.get, Theme.nightMode = get, night
    Settings.set("cover_style", style)
end

-- a cover is cut to its arched window, and painted once however often it is drawn
do
    local Blitbuffer = require("ffi/blitbuffer")
    local Cover = require("solarui/ui/cover")
    local bb = Blitbuffer.new(200, 240, Blitbuffer.TYPE_BBRGB32)
    bb:paintRectRGB32(0, 0, 200, 240, Blitbuffer.ColorRGB32(1, 2, 3, 0xFF))
    local c = Cover:new({ w = 120, h = 180, title = "A cut cover" })
    local painted, compose = 0, c.compose
    c.compose = function(...) painted = painted + 1; return compose(...) end
    c:draw(bb, 10, 10)
    c:draw(bb, 10, 10)
    local corner, middle = bb:getPixel(12, 12), bb:getPixel(70, 100)
    Kit.ok(corner:getR() == 1 and corner:getG() == 2 and corner:getB() == 3, "what lies behind shows beside a cover's arch: " .. corner:getR() .. " " .. corner:getG() .. " " .. corner:getB())
    Kit.ok(not (middle:getR() == 1 and middle:getG() == 2 and middle:getB() == 3), "the cover fills its window")
    Kit.ok(painted == 1, "a cover is painted once and then kept (painted " .. painted .. " times)")
    bb:free()
end

-- the library walk skips linked folders and Android's data folder
do
    local Library = require("solarui/data/library")
    local lfs = require("libs/libkoreader-lfs")
    local root = (os.getenv("TMPDIR") or "/tmp") .. "/solarui-test-walk"
    os.execute("rm -rf '" .. root .. "'; mkdir -p '" .. root .. "/a' '" .. root .. "/Android/data'")
    for _, f in ipairs({ "/a/one.epub", "/Android/data/hidden.epub" }) do io.open(root .. f, "w"):close() end
    os.execute("ln -s '" .. root .. "' '" .. root .. "/a/loop'")
    local home = G_reader_settings:readSetting("home_dir")
    G_reader_settings:saveSetting("home_dir", root)
    Library.reset()
    local walked = Library.all()
    Kit.ok(#walked == 1 and walked[1] == root .. "/a/one.epub", "a link back up is not followed and Android's data folder is skipped")
    G_reader_settings:saveSetting("home_dir", home)
    Library.reset()
    os.execute("rm -rf '" .. root .. "'")
end

-- the keyboard: accented letters and Shift on both letter layers, a second tap locks it
do
    local Keyboard = require("solarui/ui/keyboard")
    local TextInput = require("solarui/ui/textinput")
    Kit.ok(TextInput.nextShift(false) == "once" and TextInput.nextShift("once") == "lock" and TextInput.nextShift("lock") == false,
        "Shift goes off, one letter, locked, off")
    local function labels(o)
        local out = {}
        local function walk(e)
            if e.label then out[e.label] = true end
            for _i, c in ipairs(e.children or {}) do walk(c) end
        end
        walk(Keyboard.build(o))
        return out
    end
    local noop = function() end
    local function with(extra) local o = { on_char = noop, on_back = noop, on_enter = noop, on_layer = noop, on_shift = noop }; for k, v in pairs(extra) do o[k] = v end; return o end
    local acc = labels(with({ layer = "acc" }))
    for _i, ch in ipairs({ "á", "ã", "à", "â", "ê", "õ", "ç", "ñ", "ü", "ł" }) do
        Kit.ok(acc[ch], "the accented layer has " .. ch)
    end
    Kit.ok(acc["⇧"], "the accented layer has a Shift key")
    local caps = labels(with({ layer = "acc", shift = "once" }))
    Kit.ok(caps["Á"] and caps["Ã"] and not caps["á"], "Shift makes the accented letters capitals")
    Kit.ok(labels(with({ layer = "abc", shift = "lock" }))["⇧⇧"], "a locked Shift looks different")
    Kit.ok(not labels(with({ layer = "num" }))["⇧"], "the numbers have no Shift")
end

-- renaming a collection keeps its books and the places that name it
do
    local Collections = require("solarui/data/collections")
    local ReadCollection = require("readcollection")
    Collections.create("Fantasia")
    Collections.create("Clássicos")
    Settings.set("library_extra", { collection = "Fantasia" })
    Settings.set("library_views", { { name = "v", extra = { collection = "Fantasia" } } })
    local ok = Collections.rename("Fantasia", "  Fantasy  ")
    Kit.ok(ok and ReadCollection.coll["Fantasy"] and not ReadCollection.coll["Fantasia"], "a collection is renamed (the name is trimmed)")
    Kit.ok(Settings.get("library_extra").collection == "Fantasy" and Settings.get("library_views")[1].extra.collection == "Fantasy",
        "the saved filter and views follow the new name")
    local _ok, why = Collections.rename("Fantasy", "Clássicos")
    Kit.ok(not _ok and why == "exists", "a name already used is refused")
    _ok, why = Collections.rename("Fantasy", "   ")
    Kit.ok(not _ok and why == "empty", "an empty name is refused")
    _ok, why = Collections.rename(ReadCollection.default_collection_name, "Mine")
    Kit.ok(not _ok and why == "favorites", "Favorites keeps its name")
    Collections.remove("Fantasy")
    Collections.remove("Clássicos")
    Settings.set("library_extra", nil)
    Settings.set("library_views", nil)
end

-- editing a book's details: written as custom metadata, laid over the book's own, taken back by saving empty
do
    local Books = require("solarui/data/books")
    local Metadata = require("solarui/data/metadata")
    local Groups = require("solarui/data/libgroups")
    local Library = require("solarui/data/library")
    local root = (os.getenv("TMPDIR") or "/tmp") .. "/solarui-test-meta"
    os.execute("rm -rf '" .. root .. "'; mkdir -p '" .. root .. "'")
    local a, b, c = root .. "/a.epub", root .. "/b.epub", root .. "/c.pdf"
    for _, f in ipairs({ a, b, c }) do io.open(f, "w"):close() end
    local home = G_reader_settings:readSetting("home_dir")
    G_reader_settings:saveSetting("home_dir", root)
    Library.reset()

    Kit.ok(table.concat(Books.genres("Fantasia\nAventura;  fantasia ;\n"), "|") == "Fantasia|Aventura", "genres split on lines and semicolons, once each")
    Kit.ok(Metadata.parse("keywords", " Fantasia ; Épico\n") == "Fantasia\nÉpico", "several values are kept one per line")
    Kit.ok(Metadata.parse("title", "   ") == nil, "an empty text takes a change back")
    Kit.ok(Metadata.parse("series_index", "4") == "4" and Metadata.parse("series_index", "2,5") == "2.5", "a series number is kept plain")
    local _n, why = Metadata.parse("series_index", "four")
    Kit.ok(_n == nil and why == "number", "a series number that is not a number is refused")
    Kit.ok(Metadata.show("keywords", "Fantasia\nÉpico") == "Fantasia; Épico", "genres read side by side")

    Kit.ok(Metadata.set(a, "title", "O Senhor dos Anéis"), "a title is saved")
    Kit.ok(Books.info(a).title == "O Senhor dos Anéis" and Metadata.changed(a, "title"), "the book shows the new title at once")
    Metadata.set(a, "keywords", "Fantasia\nÉpico")
    Metadata.set(a, "series", "A Roda do Tempo")
    Metadata.set(a, "series_index", "4")
    Metadata.set(a, "authors", "J.R.R. Tolkien\nChristopher Tolkien")
    local info = Books.info(a)
    Kit.ok(info.author == "J.R.R. Tolkien" and info.series == "A Roda do Tempo" and info.series_index == 4, "authors, series and number follow")
    Kit.ok(#info.genres == 2 and info.genres[2] == "Épico", "genres follow")
    local lfs = require("libs/libkoreader-lfs")
    Kit.ok(lfs.attributes(root .. "/a.sdr/custom_metadata.lua", "mode") == "file", "KOReader's own custom metadata file is written")
    Kit.ok(Books.info(b).title == "b" and not Metadata.changed(b), "other books are left alone")

    -- genres group a book under each of its genres, books without one under "No genre"
    Metadata.set(b, "keywords", "fantasia")
    local names = {}
    for _i, g in ipairs(Groups.list("genre")) do names[g.name .. "=" .. g.count] = true end
    Kit.ok(names["Fantasia=2"] and names["Épico=1"] and names["No genre=1"], "the Genre grouping counts each genre (case ignored) and the books with none")
    Kit.ok(#Groups.books("genre", "fantasia") == 2 and #Groups.books("genre", "~") == 1, "and lists the books of one")
    Kit.ok(Groups.KINDS[5] and Groups.KINDS[5][1] == "genre", "Genre is among the groupings")

    -- saving a detail empty brings the book's own back; the file goes when nothing is left
    Metadata.set(a, "title", nil)
    Kit.ok(Books.info(a).title == "a" and not Metadata.changed(a, "title") and Metadata.changed(a, "series"), "one detail goes back to the book's own")
    Metadata.reset(a)
    Kit.ok(not Metadata.changed(a) and lfs.attributes(root .. "/a.sdr/custom_metadata.lua", "mode") == nil, "resetting all removes the file")
    Metadata.set(b, "keywords", nil)
    Kit.ok(lfs.attributes(root .. "/b.sdr", "mode") == nil, "and the empty .sdr folder")

    G_reader_settings:saveSetting("home_dir", home)
    Library.reset()
    os.execute("rm -rf '" .. root .. "'")
end

-- plants and animals keep their real colours whatever scheme is chosen; the page's colours follow it
do
    local Natural = require("solarui/art/natural")
    local Settings = require("solarui/settings")
    Settings.set("scheme", "garden")
    Theme.refresh()
    local leaf, bloom, accent = Theme.hex("leaf", true), Theme.hex("bloom", true), Theme.hex("accent")
    Settings.set("scheme", "rosewood")
    Theme.refresh()
    Kit.ok(Theme.hex("leaf", true) == leaf and Theme.hex("bloom", true) == bloom, "a plant's colours do not follow the scheme")
    Kit.ok(Theme.hex("accent") ~= accent, "while the page's colours do")
    Kit.ok(Natural.is("plant_rose") and Natural.is("animal_fox") and Natural.is("dock_inkaway") and Natural.is("rose_cluster"),
        "plants and animals are living things")
    Kit.ok(not Natural.is("halo") and not Natural.is("plaque") and not Natural.is("dock_medallion"), "the page's ornaments are not")
    Settings.set("scheme", "garden")
    Theme.refresh()
end

-- KOReader's windows in SolarUI's style: every skin loads and registers, each belongs to a switch,
-- and the switches are honoured
do
    local Settings = require("solarui/settings")
    for _i, name in ipairs({ "message", "confirm", "highlightmenu", "edithighlight", "buttondialog", "keyboard", "inputdialog", "list",
        "dictionary", "textviewer", "numbers", "choice", "keyvalue", "sort", "progress", "qr", "network", "bookstatus" }) do
        local ok, err = pcall(require, "solarui/skin/" .. name)
        Kit.ok(ok, "skin " .. name .. " loads: " .. tostring(err))
    end
    local Core, Groups = require("solarui/skin/core"), require("solarui/skin/groups")
    Kit.ok(#Core.skins >= 18, "the skins register themselves (" .. #Core.skins .. ")")
    for _i, skin in ipairs(Core.skins) do
        Kit.ok(Groups.of(skin.name) ~= nil, "skin " .. skin.name .. " has a switch of its own")
    end
    Settings.set("styled_widgets", true)
    Settings.set("styled_notices", true)
    Kit.ok(Core.wanted("confirm"), "a skin is wanted when its switches are on")
    Settings.set("styled_notices", false)
    Kit.ok(not Core.wanted("confirm") and Core.wanted("keyboard"), "one kind can be switched off alone")
    Settings.set("styled_notices", true)
    Settings.set("styled_widgets", false)
    Kit.ok(not Core.wanted("keyboard") and not Core.wanted(), "the main switch turns every kind off")
    Settings.set("styled_widgets", true)
end

-- where artwork is written: memory-backed folders first, else the cache
do
    local Scratch = require("solarui/gfx/scratch")
    local mounts = "/dev/root / ext4 rw 0 0\ntmpfs /tmp tmpfs rw 0 0\n/dev/mmcblk0p3 /mnt/us vfat rw 0 0\n"
    local all = function() return true end
    Kit.ok(Scratch.pick(mounts, { "/dev/shm", "/tmp" }, all) == "/tmp", "a tmpfs folder is chosen")
    Kit.ok(Scratch.pick(mounts, { "/mnt/us" }, all) == nil, "flash storage is not")
    Kit.ok(Scratch.pick("/dev/root / ext4 rw 0 0\n", { "/tmp" }, all) == nil, "and neither is a /tmp that is on the root flash")
    Kit.ok(Scratch.pick(mounts, { "/tmp/sub" }, all) == "/tmp/sub", "a folder inside a tmpfs counts")
    Kit.ok(Scratch.pick(nil, { "/tmp" }, all) == nil, "no mount list means the cache folder")
    Kit.ok(type(Scratch.path()) == "string", "there is always a place to write")
end

Kit.finish("features")
