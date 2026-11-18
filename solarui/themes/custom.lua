-- Custom: the reader's own accent colours on the paper they choose (Garden's
-- cream, white or mist; a forest, black or slate page in dark mode). The first accent
-- colours buttons and stems, the second the flowers; softer shades are
-- derived so every role stays readable.

local Color = require("solarui/theme/color")

local Custom = {}

Custom.DEFAULT_ACCENT = "#2F5D46"
Custom.DEFAULT_ACCENT2 = "#C8694A"

-- Ready-made colours offered when picking a custom accent.
Custom.PRESETS = {
    "#2F5D46", "#1F5F6B", "#7A2E3A", "#5B4026", "#6A4C93", "#2B2A22",
    "#C8694A", "#B4405A", "#E0A83A", "#2F7FA0", "#D9A39A", "#5F8A4E",
}

-- The page colours the reader can choose: paper for light mode, and the page
-- for dark mode, by id.
Custom.PAPERS = { cream = "#F3EAD3", white = "#FFFFFF", mist = "#ECEBE6" }
Custom.NIGHTS = { forest = "#13211B", black = "#000000", slate = "#1D2125" }

-- Build the scheme from two hex colours and the page colours' ids.
function Custom.build(accent_hex, accent2_hex, paper_id, night_id)
    local accent = Color.parse(accent_hex) or Color.parse(Custom.DEFAULT_ACCENT)
    local accent2 = Color.parse(accent2_hex) or accent
    local white = { 255, 255, 255 }
    -- on a dark page the accents are lifted so they glow rather than sink
    local function lift(c) return Color.luminance(c) < 0.2 and Color.mix(c, white, 0.35) or c end
    local d1, d2 = lift(accent), lift(accent2)
    local paper = Color.parse(Custom.PAPERS[paper_id] or Custom.PAPERS.cream)
    local night = Color.parse(Custom.NIGHTS[night_id] or Custom.NIGHTS.forest)
    return {
        id = "custom",
        name = "Custom",
        light = {
            bg = Color.hex(paper), ink = "#2B2A22", muted = "#6B6552",
            line = Color.hex(Color.mix(accent, paper, 0.7)), soft = Color.hex(Color.mix(accent, paper, 0.85)),
            accent = Color.hex(accent), accent2 = Color.hex(accent2),
            stem = Color.hex(accent), bloom = Color.hex(accent2), bloom2 = Color.hex(Color.mix(accent2, white, 0.5)),
        },
        dark = {
            bg = Color.hex(night), ink = "#F0E6CC", muted = "#A9A38C",
            line = Color.hex(Color.mix(d1, night, 0.6)), soft = Color.hex(Color.mix(d1, night, 0.8)),
            accent = Color.hex(d1), accent2 = Color.hex(d2),
            stem = Color.hex(Color.mix(d1, white, 0.3)), bloom = Color.hex(d2), bloom2 = Color.hex(Color.mix(d2, white, 0.4)),
        },
    }
end

return Custom
