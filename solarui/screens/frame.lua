-- The frame every screen but home shares: status bar, header, the screen's
-- body and the tab bar, with the page margins in one place.

local App = require("solarui/app")
local Header = require("solarui/ui/header")
local Layout = require("solarui/ui/layout")
local PagedColumn = require("solarui/ui/pagedcolumn")
local Pager = require("solarui/ui/pager")
local StatusBar = require("solarui/ui/statusbar")
local TabBar = require("solarui/ui/tabbar")
local Theme = require("solarui/theme")

local Frame = {}

-- Build a page. o: { screen, title, path, plant, actions, body, tab, back }.
-- `plant` names the header's plant (see Header.PLANTS); left out, it is the
-- tab's own. The screen keeps its clock label so the app can tick it.
function Frame.page(o)
    local th = Theme.get()
    local side = th.space.xl
    local status, clock = StatusBar.build()
    o.screen.clock = clock
    local back = o.back ~= false and function() App.back() end or nil
    local top = Layout.Column:new({ pad = { th.space.s, side, 0, side }, gap = th.space.m, children = {
        status,
        Header.pageHeader(o.title, o.plant or o.tab, { sub = o.path, on_back = back, actions = o.actions }),
    } })
    o.body.grow = true
    local body = Layout.Column:new({ grow = true, pad = { th.space.m, side, th.space.m, side }, children = { o.body } })
    local tabs = TabBar.build(App.TABS, o.tab, function(id) App.go(id) end)
    return Layout.Column:new({ children = { top, body, tabs } })
end

-- A paging row (see ui/pager.lua): first, previous, "Label 3 of 24" over
-- page dots, next, last. `state` holds page and pages (filled in by the
-- grid's on_layout).
function Frame.pager(state, label, on_page)
    return Pager.build(state, label, on_page)
end

-- A column of `items` that pages when it is too long, paged by the screen's
-- own `page` and `pages` (so swipes work too) with a paging row labelled
-- `label`.
function Frame.paged(screen, items, label)
    return PagedColumn:new({
        items = items, grow = true, page = screen.page or 1, gap = Theme.get().space.m,
        make_pager = function(pc) return Frame.pager(pc, label, function(p) screen:setPage(p) end) end,
        on_layout = function(pages, page) screen.pages, screen.page = pages, page end,
    })
end

return Frame
