-- Settings in six sections: Look (colour scheme, light or dark, custom
-- colours), Covers (style and size), Fonts (the font in use, the font page,
-- text size), Home (start with SolarUI, the garden's buttons, top bar, daily
-- goal, KOReader menu), Speed (refresh, keeping the book open, library index)
-- and About.

local Actions = require("solarui/actions")
local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Controls = require("solarui/ui/controls")
local Cover = require("solarui/ui/cover")
local Covers = require("solarui/data/covers")
local Custom = require("solarui/themes/custom")
local Files = require("solarui/data/files")
local Fonts = require("solarui/screens/fonts")
local Frame = require("solarui/screens/frame")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Library = require("solarui/data/library")
local Panel = require("solarui/ui/panel")
local QRCode = require("solarui/ui/qrcode")
local Progress = require("solarui/ui/progress")
local Registry = require("solarui/theme/registry")
local Screen = require("solarui/screens/screen")
local Settings = require("solarui/settings")
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
        Label:new({ text = _("Colour scheme"), kind = "label" }),
        Layout.Column:new({ gap = th.space.s, children = scheme_rows }),
        Label:new({ text = _("Mode"), kind = "label" }),
        Controls.Segmented({ options = { { _("Light"), "light" }, { _("Dark"), "dark" }, { _("System"), "system" } },
            value = Theme.mode(), kind = "label", on_change = function(v) Theme.set("mode", v) end }),
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

-- The Covers section: style and size in the library.
function SettingsScreen:covers()
    return {
        Label:new({ text = _("Style"), kind = "label" }),
        Controls.Segmented({ options = { { _("Image"), "image" }, { _("Card"), "card" } },
            value = Cover.style(), kind = "label", on_change = function(v) save("cover_style", v) end }),
        Label:new({ text = _("Size in the library"), kind = "label" }),
        Controls.Segmented({ options = { { "S", "s" }, { "M", "m" }, { "L", "l" }, { "XL", "xl" } },
            value = Settings.get("cover_size", "m"), kind = "label", on_change = function(v) save("cover_size", v) end }),
        row(_("Stretch covers"), _("Fill each cover frame, even if the proportions change"),
            Controls.Toggle:new({ on = Covers.stretch(), on_change = function(on) save("cover_stretch", on) end })),
    }
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
        row(_("KOReader menu"), _("Also opens with a swipe down from the top of the screen"),
            Button:new({ label = _("Open"), on_tap = function() App.koreaderMenu() end })),
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
            Label:new({ text = _("What keeping the book open costs"), kind = "micro", color = "muted" }),
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
            Label:new({ text = _("How SolarUI stays fast"), kind = "micro", color = "muted" }),
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
                Label:new({ text = _("Scan with your phone"), kind = "micro", color = "accent" }),
                Label:new({ text = "buymeacoffee.com/emirertorer", kind = "mono_small", color = "muted" }), -- i18n: keep
            } }),
        } }) })
end

-- The About section.
function SettingsScreen:about()
    return {
        row(_("Version"), nil, Label:new({ text = Version, kind = "mono" })),
        row(_("Language"), _("SolarUI follows KOReader's language (set in KOReader's own settings). The texts are in the l10n folder and can be edited there."),
            Label:new({ text = require("solarui/gettext").language():upper(), kind = "mono" })),
        row(_("Updates"), (function()
                local v = require("solarui/update/updater").available()
                return v and string.format(_("SolarUI %s is ready to install"), v) or _("New versions from GitHub, with their notes")
            end)(),
            Button:new({ label = _("Open"), on_tap = function() App.push("updates") end })),
        row(_("Fonts"), _("Griffy, Milonga, Gabriela, Federo, Glass Antiqua and Share Tech Mono, SIL Open Font License"), Layout.Spacer:new({ width = 1 })),
        Label:new({ text = _("An Art Nouveau garden of a home screen for KOReader."), kind = "body", color = "muted", lines = 2 }),
        supportPanel(),
    }
end

-- Build the screen.
function SettingsScreen:build()
    local th = Theme.get()
    local tabs = Controls.Segmented({ options = SECTIONS, value = self.section, kind = "label", on_change = function(v) self.section, self.page = v, 1; App.update() end })
    return Frame.page({
        screen = self, title = _("Settings"), tab = "settings",
        body = Layout.Column:new({ gap = th.space.m, children = { tabs, Frame.paged(self, self[self.section](self), _("Page")) } }),
    })
end

return SettingsScreen
