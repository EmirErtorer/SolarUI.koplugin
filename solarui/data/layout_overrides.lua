-- Placement tweaks for the named parts of a screen, made in the layout editor
-- (tools/layout-editor.sh) and kept here. Per screen, per component name:
-- dx, dy (units moved right and down), sx, sy (stretch of width and height,
-- from the component's top-left corner) and hidden. The units are the
-- poster's, so one tweak fits every screen size.

return {
    home = {
        ["home.battery"] = { dx = -5.1, dy = 13.0 },
        ["home.bee"] = { dx = 139.6, dy = 20.8 },
        ["home.butterfly"] = { dx = -41.5, dy = -67.5, sx = 1.337, sy = 1.226 },
        ["home.clock"] = { dx = -5.4, dy = 14.0 },
        ["home.companion"] = { dy = 0.5 },
        ["home.dayphase"] = { dx = -149.0, dy = 2.8, sx = 1.399, sy = 1.531 },
        ["home.frontlight"] = { dx = -5.7, dy = 15.0 },
        ["home.reading_sunflower"] = { dy = -1.5 },
        ["home.reading_week"] = { dx = -10.8, dy = 4.7 },
        ["home.shelf_board"] = { dx = 13.6, dy = -4.3 },
        ["home.snail"] = { dx = -70.8, dy = -11.6, sx = 1.493, sy = 1.471 },
        ["home.wifi"] = { dx = -7.0, dy = 17.0 },
    },
}
