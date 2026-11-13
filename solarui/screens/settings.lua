-- Settings in six sections: Look (colour scheme, light or dark, custom
-- colours), Covers (style and size), Fonts (the font in use, the font page,
-- text size), Home (start with SolarUI, the garden's buttons, top bar, daily
-- goal, KOReader menu), Speed (refresh, keeping the book open, library index)
-- and About.

local Actions = require("solarui/actions")
local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Controls = require("solarui/ui/controls")
local Companion = require("solarui/garden/companion")
local Cover = require("solarui/ui/cover")
local HomeCompanion = require("solarui/ui/homecompanion")
local Covers = require("solarui/data/covers")
local Custom = require("solarui/themes/custom")
local Files = require("solarui/data/files")
local Fonts = require("solarui/screens/fonts")
local Frame = require("solarui/screens/frame")
local Section = require("solarui/ui/section")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Library = require("solarui/data/library")
local Panel = require("solarui/ui/panel")
local QRCode = require("solarui/ui/qrcode")
local Progress = require("solarui/ui/progress")
local Registry = require("solarui/theme/registry")
local Screen = require("solarui/screens/screen")
local Settings = require("solarui/settings")
local Pet = require("solarui/garden/pet")
local State = require("solarui/garden/state")
local row = require("solarui/ui/settingrow")
local Swatch = require("solarui/ui/swatch")
local Theme = require("solarui/theme")
local Version = require("solarui/version")
local _ = require("solarui/gettext")

local SettingsScreen = Screen:extend()

local SECTIONS = { { _("Look"), "look" }, { _("Covers"), "covers" }, { _("Fonts"), "fonts" }, { _("Home"), "home" }, { _("Speed"), "speed" },
    { _("About"), "about" } }

-- Open on the Look section.
function SettingsScreen:init()
    self.section, self.page = "look", 1
end

-- Save a plain setting and redraw.
local function save(key, value)
    Settings.save(key, value)
    App.update()
end

-- Pick a colour for a custom accent with the colour dial.
local function pickColour(key, title)
    App.push("colourpick", { title = title, current = Settings.get(key) or Custom.DEFAULT_ACCENT,
        on_pick = function(hex) Theme.set(key, hex) end })
end

-- The Look section.
function SettingsScreen:look()
    local th = Theme.get()
    local scheme = Settings.get("scheme", Registry.SCHEMES[1])
    local dark = Theme.paintsDark()
    local schemes = {}
    for _i, s in ipairs(Registry.schemeList()) do
        local data = Registry.scheme(s.id)
        local pal = dark and data.dark or data.light
        schemes[#schemes + 1] = Button:new({ label = s.name, align = "left", variant = s.id == scheme and "chip_on" or "chip",
            grow = true, on_tap = function() Theme.set("scheme", s.id) end })
        schemes[#schemes + 1] = Swatch:new({ colors = { pal.bg, pal.ink, pal.accent, pal.accent2 }, width = Theme.px(96) })
    end
    -- two schemes to a row
    local scheme_rows = {}
    for i = 1, #schemes, 4 do
        local kids = {}
        for j = i, math.min(#schemes, i + 3) do kids[#kids + 1] = schemes[j] end
        -- a lone last scheme keeps the width of the others
        if #kids == 2 then
            kids[3] = Layout.Spacer:new({ grow = true })
            kids[4] = Layout.Spacer:new({ width = Theme.px(96) })
        end
        scheme_rows[#scheme_rows + 1] = Layout.Row:new({ gap = th.space.m, children = kids })
    end
    local kids = {
        Section.title(_("Colour scheme"), nil, "pansy"),
        Layout.Column:new({ gap = th.space.s, children = scheme_rows }),
        Section.title(_("Mode"), nil, "lily"),
        Controls.Segmented({ options = { { _("Light"), "light" }, { _("Dark"), "dark" }, { _("System"), "system" } },
            value = Theme.mode(), kind = "small", on_change = function(v) Theme.set("mode", v) end }),
    }
    if scheme == "custom" then
        local a = row(_("Accent"), _("Buttons, badges and the chosen tab"), Button:new({ label = _("Pick"), on_tap = function()
            pickColour("custom_accent", _("Accent")) end }))
        local b = row(_("Second accent"), _("Flowers and highlights"), Button:new({ label = _("Pick"), on_tap = function()
            pickColour("custom_accent2", _("Second accent")) end }))
        a.grow, b.grow = true, true
        kids[#kids + 1] = Layout.Row:new({ gap = th.space.xl, children = { a, b } })
    end
    kids[#kids + 1] = row(_("Book progress"), _("How reading progress is drawn on inner pages and in a book's details"),
        Button:new({ label = Progress.bookStyle().name, on_tap = function() Progress.pickStyle() end }))
    return kids
end

-- The ways a book's cover can be shown: id, name, what it does, the saved
-- style ("image" or "card") and picture effect ("none", "glass", ...).
local COVER_WAYS = {
    { "original", _("Original covers"), _("The cover picture of each book, as it is"), "image", "none" },
    { "glass", _("Stained glass"), _("Each cover remade as coloured glass panes"), "image", "glass" },
    { "scales", _("Peacock scales"), _("Each cover remade as overlapping scales"), "image", "scales" },
    { "blossom", _("Blossom field"), _("Each cover remade as a field of small flowers"), "image", "blossom" },
    { "card", _("Drawn card"), _("No picture: the title on a card with art behind it"), "card", "none" },
}

-- Which way the saved settings add up to.
local function coverWay()
    if Cover.style() == "card" then return "card" end
    local e = Cover.effect()
    return e == "none" and "original" or e
end

-- The Covers section: how covers look (one choice), the art of a drawn card,
-- and their size in the library.
function SettingsScreen:covers()
    local way = coverWay()
    local kids = { Section.title(_("How book covers look"), nil, "narcissus") }
    for _i, w in ipairs(COVER_WAYS) do
        kids[#kids + 1] = Button:new({ label = w[2], sub = w[3], align = "left", height = Theme.px(58),
            icon = w[1] == way and "check" or nil, variant = w[1] == way and "chip_on" or "soft",
            on_tap = function()
                Settings.set("cover_style", w[4])
                Settings.set("cover_effect", w[5])
                Settings.flush()
                App.update()
            end })
    end
    if way == "card" then
        kids[#kids + 1] = Section.title(_("Art on the card"), nil, "rose")
        kids[#kids + 1] = Controls.Segmented({ options = { { _("Glass"), "glass" }, { _("Garden"), "garden" }, { _("Halo"), "halo" }, { _("Scales"), "scales" }, { _("Lines"), "lines" } },
            value = Cover.cardArt(), kind = "small", on_change = function(v) save("card_art", v) end })
    end
    kids[#kids + 1] = Section.title(_("Size of covers"), nil, "daisy")
    kids[#kids + 1] = Controls.Segmented({ options = { { "S", "s" }, { "M", "m" }, { "L", "l" }, { "XL", "xl" } },
        value = Settings.get("cover_size", "m"), kind = "small", on_change = function(v) save("cover_size", v) end })
    if way ~= "card" then
        kids[#kids + 1] = row(_("Stretch covers"), _("Fill each cover frame, even if the proportions change"),
            Controls.Toggle:new({ on = Covers.stretch(), on_change = function(on) save("cover_stretch", on) end }))
    end
    return kids
end

-- The Fonts section: the font in use, the way to every font, and text size.
function SettingsScreen:fonts()
    local kids = {
        Fonts.card(Registry.fontSet(Settings.get("fontset", Registry.fontSets()[1].id)), true),
        row(_("All fonts"), string.format(_.n("%d font set, or any font installed on this device", "%d font sets, or any font installed on this device", #Registry.fontSets()), #Registry.fontSets()),
            Button:new({ label = _("Choose"), on_tap = function() App.push("fonts") end })),
    }
    kids[#kids + 1] = row(_("Text size"), _("Makes every text in SolarUI larger or smaller"),
        Controls.Stepper({ value = math.floor(Settings.get("text_scale", 1) * 100 + 0.5), min = 80, max = 140, step = 10,
            format = function(v) return v .. "%" end, value_w = 64,
            on_change = function(v) Theme.set("text_scale", v / 100) end }))
    return kids
end

-- The Home section.
function SettingsScreen:home()
    local is_home = G_reader_settings:readSetting("start_with") == "solarui"
    return {
        row(_("Start with SolarUI"), _("Open SolarUI when KOReader starts and after closing a book"),
            Controls.Toggle:new({ on = is_home, on_change = function(on)
                G_reader_settings:saveSetting("start_with", on and "solarui" or "filemanager")
                App.update()
            end })),
        row(_("Garden buttons"), _("The plants along the bottom of home: hide, reorder, replace or add your own that open anything in KOReader"),
            Button:new({ label = _("Edit"), on_tap = function() App.push("launcher") end })),
        row(_("Reading on home"), _("Today's minutes, the week and the year as flowers on home"),
            Controls.Toggle:new({ on = Settings.get("home_stats", true), on_change = function(on) save("home_stats", on) end })),
        row(_("Shelf on home"), _("The books you opened last, standing on a shelf on home"),
            Controls.Toggle:new({ on = Settings.get("home_shelf", true), on_change = function(on) save("home_shelf", on) end })),
        row(_("Garden companion"), _("Which plant or animal of the garden keeps you company on home. Left on automatic, whoever needs care most keeps you company"),
            Button:new({ label = HomeCompanion.pinned() == "auto" and _("Automatic") or State.name(HomeCompanion.pinned()), on_tap = function()
                local options = { { label = _("Automatic"), checked = HomeCompanion.pinned() == "auto", on_tap = function() save("home_companion", "auto") end } }
                for _i, item in ipairs(Companion.list()) do
                    options[#options + 1] = { label = State.name(item.id), checked = HomeCompanion.pinned() == item.id, on_tap = function() save("home_companion", item.id) end }
                end
                App.choose({ title = _("Garden companion"), options = options })
            end })),
        row(_("Companion dialogue"), _("The companion speaks in written lines on home and on their page, and tells memories as you read. Turn it off for a quiet companion with a bigger window"),
            Controls.Toggle:new({ on = Pet.talks(), on_change = function(on) save("companion_talk", on) end })),
        row(_("Seasons on home"), _("The vines blossom in spring, turn gold in autumn and go pale in winter"),
            Controls.Toggle:new({ on = Settings.get("home_season", true), on_change = function(on) save("home_season", on) end })),
        row(_("Sleep picture"), _("Draws a picture in the garden's style to choose as KOReader's sleep screen (Settings, Screen, Sleep screen, Wallpaper, Custom image)"),
            Button:new({ label = _("Make"), on_tap = function()
                local function make(kind)
                    return function() App.toast(string.format(_("Saved to %s"), require("solarui/sleep").make(kind))) end
                end
                App.choose({ title = _("Sleep picture"), options = {
                    { label = _("The home poster"), on_tap = make("poster") },
                    { label = _("My garden as it is now"), on_tap = make("garden") },
                } })
            end })),
        row(_("Library opens in"), _("The folder the Library starts in; KOReader's home folder stays the top of the library"),
            Button:new({ label = Settings.get("library_start_dir") and Files.name(Settings.get("library_start_dir")) or _("Home folder"), on_tap = function()
                App.choose({ title = _("Library opens in"), options = {
                    { label = _("Home folder"), checked = not Settings.get("library_start_dir"), on_tap = function() Actions.setLibraryStart(nil) end },
                    { label = _("Pick a folder"), icon = "folder", on_tap = Actions.pickLibraryStart },
                } })
            end })),
        row(_("Double tap to open"), _("In the library a book opens on its second tap, so a stray touch does not start it"),
            Controls.Toggle:new({ on = Settings.get("double_tap_open", false), on_change = function(on) save("double_tap_open", on) end })),
        row(_("Top bar"), _("The readouts across the top of every page"),
            Button:new({ label = _("Change"), on_tap = function() App.push("topbar") end })),
        row(_("Daily goal"), _("Minutes of reading a day, shown on home and in the reading log"),
            Controls.Stepper({ value = Settings.get("daily_goal", 30), min = 5, max = 240, step = 5,
                format = function(v) return string.format(_("%d min"), v) end, value_w = 76, on_change = function(v) save("daily_goal", v) end })),
        row(_("KOReader menu"), _("In SolarUI's style, over home and in a book (off: KOReader's own); also opens with a swipe down from the top"),
            Layout.Row:new({ gap = Theme.get().space.s, children = {
                Controls.Toggle:new({ on = Settings.get("styled_menu", true), on_change = function(on) save("styled_menu", on) end }),
                Button:new({ label = _("Open"), on_tap = function() App.koreaderMenu() end }),
            } })),
        row(_("KOReader dialogs"), _("Notices, menus, lists, the keyboard, pickers and more in SolarUI's style; each kind has its own switch (off: KOReader's own)"),
            Layout.Row:new({ gap = Theme.get().space.s, children = {
                Controls.Toggle:new({ on = Settings.get("styled_widgets", true), on_change = function(on) save("styled_widgets", on) end }),
                Button:new({ label = _("Choose"), on_tap = function() App.push("dialogs") end }),
            } })),
        row(_("Menu height"), _("How much of the screen KOReader's menu may take: taller shows more entries and needs fewer pages"),
            Controls.Segmented({ options = { { "50%", 0.5 }, { "65%", 0.65 }, { "80%", 0.8 }, { "90%", 0.9 } }, value = Settings.get("menu_height", 0.8),
                on_change = function(v) save("menu_height", v) end })),
        row(_("File browser"), _("Leave SolarUI for KOReader's own file browser"),
            Button:new({ label = _("Open"), on_tap = function() App.fileBrowser() end })),
    }
end

-- The Speed section.
function SettingsScreen:speed()
    local th = Theme.get()
    return {
        row(_("Full refresh in dark mode"), _("Dark screens ghost more, so they flash sooner (0 never)"),
            Controls.Stepper({ value = Settings.get("dark_full_refresh_every", 2), min = 0, max = 20,
                format = function(v) return tostring(v) end, value_w = 48, on_change = function(v) save("dark_full_refresh_every", v) end })),
        row(_("Full refresh every"), _("Screens between flashing refreshes that clear ghosting (0 never)"),
            Controls.Stepper({ value = Settings.get("full_refresh_every", 6), min = 0, max = 20,
                format = function(v) return tostring(v) end, value_w = 48, on_change = function(v) save("full_refresh_every", v) end })),
        row(_("Keep the book open on Home"), _("Home shows at once and the same book opens again with no loading; the book is closed later"),
            Controls.Toggle:new({ on = Settings.get("park_reader", true), on_change = function(on)
                save("park_reader", on)
                if not on then require("solarui/park").finish() end
            end })),
        Panel:new({ shape = "frame", pad = th.space.m, child = Layout.Column:new({ gap = th.space.xs, children = {
            Section.title(_("What keeping the book open costs")),
            Label:new({ text = _("Going home puts the book away instead of closing it. KOReader closes it for real when you open a different book, after 30 seconds of not touching the screen, or when you open KOReader's menu or its file browser."),
                kind = "small", lines = 5 }),
            Label:new({ text = _("- A different book, KOReader's menu and the file browser take a moment longer, since the close happens then."),
                kind = "small", lines = 4 }),
            Label:new({ text = _("- The book stays in memory while it is put away."), kind = "small", lines = 2 }),
            Label:new({ text = _("- Sleeping soon after leaving a book shows that book's sleep screen."), kind = "small", lines = 3 }),
            Label:new({ text = _("- KOReader's own gestures (corner taps, edge swipes) do not work on Home until the book is closed."),
                kind = "small", lines = 4 }),
            Label:new({ text = _("- A book read in landscape is closed the normal way."), kind = "small", lines = 2 }),
        } }) }),
        row(_("Library index"), string.format(_.n("%d book indexed; rebuild after copying books over", "%d books indexed; rebuild after copying books over", Library.count() or 0), Library.count() or 0),
            Button:new({ label = _("Rebuild"), on_tap = function()
                Library.reset()
                Library.all()
                App.toast(string.format(_.n("%d book indexed", "%d books indexed", Library.count() or 0), Library.count() or 0))
                App.update()
            end })),
        Panel:new({ shape = "frame", pad = th.space.m, child = Layout.Column:new({ gap = th.space.xs, children = {
            Section.title(_("How SolarUI stays fast")),
            Label:new({ text = _("Home stays loaded while you read, so closing a book is a redraw, not a rebuild. The artwork is drawn once and kept, and the screen is refreshed only where it changed."),
                kind = "small", lines = 4 }),
        } }) }),
    }
end

-- The support note: a QR code for the coffee page and a few humble words.
local SUPPORT_URL = "https://buymeacoffee.com/emirertorer"
local function supportPanel()
    local th = Theme.get()
    return Panel:new({ shape = "header", title = _("Support"), pad = th.space.m,
        child = Layout.Row:new({ gap = th.space.l, valign = "center", children = {
            QRCode:new({ text = SUPPORT_URL, size = 150 }),
            Layout.Column:new({ grow = true, gap = th.space.s, children = {
                Label:new({ text = _("SolarUI is free and made by one person. If it makes your reading better, a coffee helps keep it going."),
                    kind = "body", lines = 5 }),
                Label:new({ text = _("Scan with your phone"), kind = "small", color = "accent" }),
                Label:new({ text = "buymeacoffee.com/emirertorer", kind = "small", color = "muted" }), -- i18n: keep
            } }),
        } }) })
end

-- The About section.
function SettingsScreen:about()
    return {
        row(_("Version"), nil, Label:new({ text = Version, kind = "body" })),
        row(_("Language"), _("SolarUI follows KOReader's language (set in KOReader's own settings). The texts are in the l10n folder and can be edited there."),
            Label:new({ text = require("solarui/gettext").language():upper(), kind = "body" })),
        row(_("Updates"), (function()
                local v = require("solarui/update/updater").available()
                return v and string.format(_("SolarUI %s is ready to install"), v) or _("New versions from GitHub, with their notes")
            end)(),
            Button:new({ label = _("Open"), on_tap = function() App.push("updates") end })),
        row(_("Fonts"), _("Griffy, Milonga, Gabriela, Federo and Glass Antiqua, SIL Open Font License"), Layout.Spacer:new({ width = 1 })),
        Label:new({ text = _("An Art Nouveau garden of a home screen for KOReader."), kind = "body", color = "muted", lines = 2 }),
        supportPanel(),
    }
end

-- Build the screen.
function SettingsScreen:build()
    local th = Theme.get()
    local tabs = Controls.Segmented({ options = SECTIONS, value = self.section, kind = "small", on_change = function(v) self.section, self.page = v, 1; App.update() end })
    return Frame.page({
        screen = self, title = _("Settings"), tab = "settings",
        body = Layout.Column:new({ gap = th.space.m, children = { tabs, Frame.paged(self, self[self.section](self), _("Page")) } }),
    })
end

return SettingsScreen
