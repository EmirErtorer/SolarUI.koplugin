-- The Art Nouveau style: type sizes, spacing and the shapes every element is
-- drawn with. Sizes are in base pixels; the theme scales them to the screen.
-- The faces come from the font set chosen in Settings > Fonts (themes/fonts.lua).

return {
    id = "nouveau",
    name = "Art Nouveau",
    -- font role (from the font set) and size for each kind of text
    text = {
        hero = { "display", 36 },
        display = { "display", 28 },
        title = { "display", 22 },
        heading = { "title", 17 },
        body = { "body", 15 },
        label = { "title", 15 },
        small = { "body", 13 },
        mono = { "body", 14 },
        mono_small = { "body", 12 },
        micro = { "body", 11 },
        number = { "display", 30 },
    },
    -- letter spacing (base pixels) per kind of text
    tracking = {},
    -- no kind of text is forced into capitals
    caps = {},
    space = { xs = 4, s = 6, m = 10, l = 14, xl = 18 },
    size = {
        touch = 44,        -- smallest tap target
        stroke = 2,        -- outlines
        hair = 1,          -- dividers
        cut = 16,          -- rounded corner on panels and big buttons
        cut_small = 10,    -- rounded corner on chips and tiles
        bracket = 16,      -- room a panel's caption keeps from its corner
        segment_gap = 2,   -- gap between progress segments
        status = 22,       -- status bar height
        tabbar = 58,       -- bottom tab bar height
    },
    -- (a later style may switch decorations of its own on here)
    decor = {},
}
