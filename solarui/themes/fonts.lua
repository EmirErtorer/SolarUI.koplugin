-- The font sets offered in Settings > Fonts, all under the SIL Open Font
-- License (licence texts in the fonts folder) except KOReader's own. Each set
-- names a file for display, title, body and mono text and for home's clock
-- (a set without one shows the clock in its display face); "koreader:" means one
-- of KOReader's built-in faces. `scale` evens out the faces' different sizes
-- so every set fits the same layout; `<role>_scale` sizes one role on its own.
-- Any font installed on the device can be chosen too (see Registry.fontSet).

local _ = require("solarui/gettext")

return {
    {
        id = "nouveau", name = "Griffy", note = _("Curling poster lettering over a soft book face, the default"),
        display = "Griffy-Regular.ttf", title = "Milonga-Regular.ttf", body = "Gabriela-Regular.ttf",
        mono = "Gabriela-Regular.ttf", clock = "Federo-Regular.ttf", scale = 1, display_scale = 1.08,
    },
    {
        id = "milonga", name = "Milonga", note = _("Flourished capitals, calmer than Griffy"),
        display = "Milonga-Regular.ttf", title = "Milonga-Regular.ttf", body = "Gabriela-Regular.ttf",
        mono = "Gabriela-Regular.ttf", clock = "Federo-Regular.ttf", scale = 1,
    },
    {
        id = "federo", name = "Federo", note = _("A 1909 poster face over Glass Antiqua of 1913"),
        display = "Federo-Regular.ttf", title = "Federo-Regular.ttf", body = "GlassAntiqua-Regular.ttf",
        mono = "GlassAntiqua-Regular.ttf", clock = "Federo-Regular.ttf", scale = 1, body_scale = 1.08, mono_scale = 1.08,
    },
    {
        id = "koreader", name = "KOReader", note = _("KOReader's own fonts, for the plainest reading"),
        display = "koreader:tfont", title = "koreader:tfont", body = "koreader:cfont", -- i18n: keep
        mono = "koreader:infont", clock = "koreader:tfont", scale = 0.95,
    },
}
