-- Collections: Favorites pinned as a large card over a paged grid
-- of every other collection, each showing a few of its covers. Tap one to
-- browse it, hold one to rename or delete it; "+ New" makes a new collection.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Books = require("solarui/data/books")
local Collections = require("solarui/data/collections")
local Controls = require("solarui/ui/controls")
local Groups = require("solarui/data/libgroups")
local Cover = require("solarui/ui/cover")
local Frame = require("solarui/screens/frame")
local Grid = require("solarui/ui/grid")
local EmptyState = require("solarui/ui/emptystate")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Panel = require("solarui/ui/panel")
local Screen = require("solarui/screens/screen")
local Theme = require("solarui/theme")
local util = require("util")
local _ = require("solarui/gettext")

local CollectionsScreen = Screen:extend()

-- Start on the first page.
function CollectionsScreen:init(params)
    self.page = 1
    self.mode = params and params.mode or "collections"
end

-- A 2 x 2 mosaic of the collection's first covers.
local function mosaic(books, w, h)
    local gap = Theme.px(3)
    local cw, ch = math.floor((w - gap) / 2), math.floor((h - gap) / 2)
    local function tile(i) return Cover:new({ path = books[i], width = cw, height = ch }) end
    return Layout.Column:new({ gap = gap, width = w, children = {
        Layout.Row:new({ gap = gap, children = { tile(1), tile(2) } }),
        Layout.Row:new({ gap = gap, children = { tile(3), tile(4) } }),
    } })
end

-- Open a collection (or a series, by the name its books carry) in the browser.
local function open(c)
    return function()
        if c.series then App.push("library", { series = c.name }) else App.push("library", { collection = c.name }) end
    end
end

-- Ask, then delete a collection.
local function askRemove(c)
    App.confirm({ title = _("Delete this collection?"), text = c.title, danger = true, ok = _("Delete"), on_ok = function()
        Collections.remove(c.name)
        App.toast(_("Collection deleted"))
        App.update()
    end })
end

-- What went wrong renaming, in words.
local RENAME_FAILED = {
    exists = _("A collection with that name exists"),
    empty = _("Type a name first"),
}

-- Type a new name for a collection.
local function askRename(c)
    App.input(_("Rename collection"), c.title, function(name)
        local ok, why = Collections.rename(c.name, name)
        if ok then
            App.toast(_("Collection renamed"))
            App.update()
        elseif RENAME_FAILED[why] then
            App.toast(RENAME_FAILED[why])
        end
    end, _("Rename"))
end

-- Hold a collection: rename or delete it (Favorites stays as it is, and a
-- series comes from the books themselves).
local function holdSheet(c)
    if c.series then return nil end
    return function()
        if c.name == require("readcollection").default_collection_name then
            return App.toast(_("Favorites always stays"))
        end
        App.sheet({ title = c.title, sub = _("Collection"), actions = {
            { icon = "edit", label = _("Rename"), on_tap = function() askRename(c) end },
            { icon = "trash", label = _("Delete"), danger = true, on_tap = function() askRemove(c) end },
        } })
    end
end

-- One collection card.
local function card(c, _w, h)
    local th = Theme.get()
    local inner_h = h - 2 * th.space.s
    return Panel:new({ shape = "frame", pad = th.space.s, on_tap = open(c), on_hold = holdSheet(c), child = Layout.Row:new({ gap = th.space.m, children = {
        mosaic(c.books, math.floor(inner_h * 0.75), inner_h),
        Layout.Column:new({ grow = true, gap = th.space.xs, children = {
            Label:new({ text = c.title, kind = "heading" }),
            Label:new({ text = string.format(_.n("%d book", "%d books", #c.books), #c.books), kind = "small", color = "muted" }),
        } }),
    } }) })
end

-- The large pinned card for Favorites.
local function pinned(c)
    local th = Theme.get()
    local fan = {}
    for i = 1, 4 do
        fan[i] = Cover:new({ path = c.books[i], width = Theme.px(70), height = Theme.px(100),
            place = "tl", dx = (i - 1) * Theme.px(22), dy = (i - 1) * Theme.px(3) })
    end
    return Panel:new({ shape = "frame", double = true, pad = th.space.l, on_tap = open(c), on_hold = holdSheet(c), child = Layout.Row:new({ gap = th.space.l, children = {
        Layout.Overlay:new({ width = Theme.px(140), height = Theme.px(112), children = fan }),
        Layout.Column:new({ grow = true, gap = th.space.xs, children = {
            Label:new({ text = c.title, kind = "display" }),
            Label:new({ text = string.format(_.n("%d book", "%d books", #c.books), #c.books), kind = "body", color = "muted" }),
        } }),
    } }) })
end

-- Make a new collection from a name typed in.
local function create()
    App.input(_("New collection"), "", function(name)
        name = util.trim(name or "")
        if name == "" then return end
        Collections.create(name)
        App.toast(_("Collection created"))
        App.update()
    end, _("Create"))
end

-- The series the books' metadata names, as cards like the collections' own.
function CollectionsScreen:seriesBody()
    local list = Groups.series()
    for _i, c in ipairs(list) do c.series = true end
    -- books whose details are still being read may add more: look again when done
    Books.whenExtracted(function() if App.current() == self then App.update() end end)
    if #list == 0 then
        return EmptyState.build({ plant = "collections", title = _("No series yet"),
            text = _("A series appears here once books with a series in their details have been read.") })
    end
    return Grid:new({ grow = true, items = list, page = self.page, cols = 2, cell_h = Theme.px(112),
        make = card, on_layout = function(_c, pages, page) self.pages, self.page = pages, page end })
end

-- Build the screen.
function CollectionsScreen:build()
    local th = Theme.get()
    local switch = Controls.Segmented({ value = self.mode, options = { { _("Collections"), "collections" }, { _("Series"), "series" } },
        on_change = function(mode) self.mode, self.page = mode, 1; App.update() end })
    if self.mode == "series" then
        return Frame.page({
            screen = self, title = _("Series"), tab = "collections",
            body = Layout.Column:new({ gap = th.space.l, children = { switch, self:seriesBody(),
                Frame.pager(self, _("Page"), function(p) self:setPage(p) end) } }),
        })
    end
    local all = Collections.list()
    local fav, rest = nil, {}
    for _i, c in ipairs(all) do
        if not fav and c.name == require("readcollection").default_collection_name then fav = c else rest[#rest + 1] = c end
    end
    local kids = { switch }
    if fav then kids[#kids + 1] = pinned(fav) end
    if #rest == 0 then
        kids[#kids + 1] = EmptyState.build({ plant = "collections", title = _("No other collections yet"),
            text = _("Make one with + New.") })
    else
        kids[#kids + 1] = Grid:new({ grow = true, items = rest, page = self.page, cols = 2, cell_h = Theme.px(112),
            make = card, on_layout = function(_c, pages, page) self.pages, self.page = pages, page end })
    end
    kids[#kids + 1] = Frame.pager(self, _("Page"), function(p) self:setPage(p) end)
    return Frame.page({
        screen = self, title = _("Collections"), tab = "collections",
        actions = { Button:new({ label = _("+ New"), variant = "primary", on_tap = create }) },
        body = Layout.Column:new({ gap = th.space.l, children = kids }),
    })
end

return CollectionsScreen
