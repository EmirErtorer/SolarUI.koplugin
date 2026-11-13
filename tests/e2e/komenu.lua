-- The drop-down menu in SolarUI's style: over home, its tabs and a submenu,
-- and inside a book. Saves a screenshot of each.
local H = ...
local Menu
H.step(1.5, function()
    H.app().koreaderMenu()
    Menu = require("solarui/menu")
    H.check(Menu.current() ~= nil, "the menu opens over home")
end)
H.step(1, function() require("ui/uimanager"):forceRePaint(); H.shot("menu-1") end)
H.step(.8, function() Menu.current():switchTab(2) end)
H.step(1, function() require("ui/uimanager"):forceRePaint(); H.shot("menu-2") end)
H.step(.8, function()
    local m = Menu.current()
    for _i, it in ipairs(m:visible()) do
        if it.sub_item_table or it.sub_item_table_func then m:select(it); break end
    end
end)
H.step(1, function() require("ui/uimanager"):forceRePaint(); H.shot("menu-3") end)
H.step(.8, function() Menu.current():switchTab(1); end)
H.step(1, function() require("ui/uimanager"):forceRePaint(); H.shot("menu-quick") end)
H.step(.8, function() Menu.current():close(); H.check(Menu.current() == nil, "it closes") end)
H.step(.8, function()
    local book = require("solarui/data/library").all()[1]
    H.app().openBook(book)
end)
H.step(3, function()
    local ui = require("apps/reader/readerui").instance
    H.check(ui ~= nil, "a book is open")
    ui.menu:onShowMenu()
end)
H.step(1.2, function()
    H.check(Menu.current() ~= nil, "the menu opens in the book")
    require("ui/uimanager"):forceRePaint()
    H.shot("menu-book")
end)
