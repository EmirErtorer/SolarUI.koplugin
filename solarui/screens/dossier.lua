-- A book's details: who the book is, the synopsis with the room that is left, the
-- saved highlights, notes and bookmarks as buttons to their lists, and the actions.

local Actions = require("solarui/actions")
local Annotations = require("solarui/data/annotations")
local App = require("solarui/app")
local Books = require("solarui/data/books")
local Button = require("solarui/ui/button")
local Collections = require("solarui/data/collections")
local ArtView = require("solarui/ui/artview")
local Panel = require("solarui/ui/panel")
local Section = require("solarui/ui/section")
local Cover = require("solarui/ui/cover")
local Format = require("solarui/format")
local Frame = require("solarui/screens/frame")
local History = require("solarui/data/history")
local Insights = require("solarui/data/insights")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Progress = require("solarui/ui/progress")
local Screen = require("solarui/screens/screen")
local ScrollText = require("solarui/ui/scrolltext")
local Theme = require("solarui/theme")
local filemanagerutil = require("apps/filemanager/filemanagerutil")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")
local _ = require("solarui/gettext")

local Dossier = Screen:extend()

-- Reading status as the details screen names it.
local STATUS = { new = _("New"), reading = _("Reading"), complete = _("Done"), abandoned = _("Paused") }

-- Swipe up and down to page through a long synopsis.
function Dossier:onSwipe(dir)
    if not self.synopsis then return false end
    if dir == "north" then return self.synopsis:turn(1) end
    if dir == "south" then return self.synopsis:turn(-1) end
    return false
end

-- One line of small grey facts.
local function line(text)
    return Label:new({ text = text, kind = "small", color = "muted", lines = 2 })
end

-- Format, size and pages of the book on one line.
local function formatLine(path, info, st)
    local _dir, file = util.splitFilePathName(path)
    local ext = (file:match("%.([^.]+)$") or "?"):upper()
    local parts = { ext, Format.size((lfs.attributes(path) or {}).size) }
    local pages = st.pages or info.pages
    if pages then parts[#parts + 1] = string.format(_.n("%d page", "%d pages", pages), pages) end
    return table.concat(parts, " \u{B7} ")
end

-- When the book was added and last opened.
local function datesLine(path)
    local added = (lfs.attributes(path) or {}).modification
    return string.format(_("Added %s · opened %s"), added and os.date("%Y-%m-%d", added) or "?", Format.ago(History.lastOpened(path)))
end

-- How far the book is read: one line of numbers over the bar (nothing for a book not started).
local function progress(path, st)
    local th = Theme.get()
    local pct = math.floor(st.percent * 100 + 0.5)
    local text = string.format(_("%d%% read"), pct)
    local t = Insights.book(path)
    if t and t.seconds > 0 then
        local left = st.status == "complete" and 0 or math.max(0, t.total_pages - t.pages) * t.per_page
        text = text .. string.format(" · %s", Format.duration(t.seconds))
        if left > 0 then text = text .. string.format(_(" · %s left"), Format.duration(left)) end
    end
    return Layout.Column:new({ gap = th.space.xs, children = {
        Label:new({ text = text, kind = "small", lines = 2 }),
        Progress:new({ value = st.percent, segments = 30, book = true }),
    } })
end

-- Build the details screen: who the book is, the synopsis with all the room that is left, and a short row of actions.
function Dossier:build()
    local th = Theme.get()
    self.synopsis_page = self.synopsis_page or {}
    local path = self.params.path
    local info, st = Books.info(path), Books.state(path)
    local dir = util.splitFilePathName(path)
    local who = info.author or _("Unknown author")
    if info.series then who = who .. " \u{B7} " .. info.series .. (info.series_index and (" #" .. info.series_index) or "") end
    local held = Collections.holding(path)
    -- after a rename or move the screen follows the book to its new path
    local function moved(to) self.params.path = to; App.update() end

    local chips = Layout.Row:new({ gap = th.space.s, children = {
        Button:new({ label = string.format("%s \u{B7} %s", _("Status"), STATUS[st.status] or ""), variant = "chip", kind = "small",
            on_tap = function() Actions.statusSheet(path) end }),
        Button:new({ label = #held > 0 and string.format(_("Collections \u{B7} %d"), #held) or _("+ Collection"), variant = "chip", kind = "small",
            on_tap = function() Actions.collect(path) end }),
    } })
    local facts = { Label:new({ text = info.title, kind = "display", lines = 3 }),
        Label:new({ text = who, kind = "body", color = "muted", lines = 2 }) }
    if info.genres and #info.genres > 0 then facts[#facts + 1] = line(table.concat(info.genres, " \u{B7} ")) end
    facts[#facts + 1] = line(formatLine(path, info, st))
    facts[#facts + 1] = line(datesLine(path))
    facts[#facts + 1] = chips
    -- an ex libris plate under the cover
    local plate = Panel:new({ shape = "frame", double = true, pad = { th.space.xs, th.space.s }, child = Layout.Row:new({ gap = th.space.xs, valign = "center", children = {
        ArtView:new({ name = "bloom", param = "daisy", width = Theme.px(22), height = Theme.px(22) }),
        Label:new({ text = _("Ex libris"), kind = "small", color = "muted", grow = true, align = "center" }),
    } }) })
    local head = Layout.Row:new({ gap = th.space.l, valign = "top", children = {
        Layout.Column:new({ gap = th.space.s, width = Theme.px(110), children = {
            Cover:new({ path = path, width = Theme.px(110), height = Theme.px(162) }), plate } }),
        Layout.Column:new({ grow = true, gap = th.space.s, children = facts }),
    } })

    -- the synopsis opens with a large initial, the rest of the text beside it
    local text = info.description and util.htmlToPlainTextIfHtml(info.description) or _("No description in this book's details.")
    local initial
    if info.description then
        initial = text:match("^%s*([%z\1-\127\194-\244][\128-\191]*)")
        if initial and initial:match("%w") then text = text:gsub("^%s*[%z\1-\127\194-\244][\128-\191]*", "", 1) else initial = nil end
    end
    local body = ScrollText:new({ grow = true, text = text, color = info.description and "ink" or "muted", state = self.synopsis_page, on_turn = function() App.update() end })
    local synopsis = Layout.Column:new({ grow = true, gap = th.space.s, children = {
        Section.title(_("Synopsis")),
        initial and Layout.Row:new({ grow = true, gap = th.space.xs, valign = "top", children = {
            Label:new({ text = initial:upper(), kind = "hero", color = "accent" }), body } }) or body,
    } })
    self.synopsis = body

    -- the saved items as three buttons, each opening its list
    local kinds = Annotations.kinds(path)
    local function count(kind, label)
        return Button:new({ label = string.format("%02d", #kinds[kind]), sub = label, kind = "number", grow = true, height = Theme.px(64),
            on_tap = function() App.push("annotations", { path = path, kind = kind }) end })
    end
    local counts = Layout.Row:new({ gap = th.space.m, children = {
        count("highlights", _("Highlights")), count("notes", _("Notes")), count("bookmarks", _("Bookmarks")),
    } })

    local main = Button:new({ label = _("Open book"), icon = "forward", variant = "primary", corners = "tb", grow = true, on_tap = function() Actions.open(path) end })
    local actions = Layout.Row:new({ gap = th.space.s, height = Theme.px(64), children = {
        main,
        Button:new({ label = _("Edit details"), icon = "edit", variant = "tab", kind = "small", on_tap = function() Actions.editDetails(path) end }),
        Button:new({ label = _("More"), icon = "menu", variant = "tab", kind = "small", on_tap = function() Actions.moreSheet(path, moved) end }),
    } })

    local kids = { head }
    if st.opened then kids[#kids + 1] = progress(path, st) end
    kids[#kids + 1] = synopsis
    kids[#kids + 1] = counts
    kids[#kids + 1] = actions
    return Frame.page({
        plant = "details", screen = self, title = _("Details"), path = filemanagerutil.abbreviate(dir), tab = "library",
        body = Layout.Column:new({ gap = th.space.l, children = kids }),
    })
end

return Dossier
