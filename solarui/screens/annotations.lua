-- A book's highlights, notes or bookmarks as cards (which of the three comes in
-- params.kind): the chapter and page over the passage or the note, newest
-- first. A tap opens the book at that place.

local Actions = require("solarui/actions")
local Annotations = require("solarui/data/annotations")
local Books = require("solarui/data/books")
local EmptyState = require("solarui/ui/emptystate")
local Frame = require("solarui/screens/frame")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Panel = require("solarui/ui/panel")
local Screen = require("solarui/screens/screen")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local AnnotationsScreen = Screen:extend()

-- What each kind is called and says when there is none.
local KINDS = {
    highlights = { title = _("Highlights"), empty = _("No highlights in this book yet. Select text while reading and choose Highlight.") },
    notes = { title = _("Notes"), empty = _("No notes in this book yet. Add a note to a highlight while reading.") },
    bookmarks = { title = _("Bookmarks"), empty = _("No bookmarks in this book yet. Tap the top corner of a page while reading to add one.") },
}

-- Start on the first page.
function AnnotationsScreen:init() self.page = 1 end

-- The line over a card: chapter, page and date.
local function meta(a)
    local parts = {}
    if a.chapter and a.chapter ~= "" then parts[#parts + 1] = a.chapter end
    if a.pageno then parts[#parts + 1] = string.format(_("Page %s"), a.pageno) end
    if a.date then parts[#parts + 1] = a.date:match("^%S+") or a.date end
    return table.concat(parts, " · ")
end

-- One saved item as a card.
local function card(path, a, kind)
    local th = Theme.get()
    local kids = { Label:new({ text = meta(a), kind = "small", color = "muted", lines = 2 }) }
    local shown = kind == "notes" and a.note or a.text
    if shown and shown ~= "" then kids[#kids + 1] = Label:new({ text = shown, kind = "body", lines = 6 }) end
    if kind ~= "notes" and a.note then
        kids[#kids + 1] = Label:new({ text = a.note, kind = "small", color = "accent", lines = 3 })
    elseif kind == "notes" and a.text ~= "" then
        kids[#kids + 1] = Label:new({ text = a.text, kind = "small", color = "muted", lines = 3 })
    end
    return Panel:new({ shape = "frame", pad = th.space.m, on_tap = function() Actions.openAt(path, a) end,
        child = Layout.Column:new({ gap = th.space.xs, children = kids }) })
end

-- Build the screen.
function AnnotationsScreen:build()
    local th = Theme.get()
    local path = self.params.path
    local kind = KINDS[self.params.kind] and self.params.kind or "highlights"
    local list = Annotations.kinds(path)[kind]
    local cards = {}
    for i = #list, 1, -1 do cards[#cards + 1] = card(path, list[i], kind) end   -- newest first
    local body
    if #cards == 0 then
        body = EmptyState.build({ plant = kind, title = KINDS[kind].title, text = KINDS[kind].empty })
    else
        body = Frame.paged(self, cards, _("Page"))
    end
    return Frame.page({
        screen = self, title = KINDS[kind].title, path = Books.info(path).title, tab = "library", plant = kind,
        body = Layout.Column:new({ gap = th.space.l, children = { body } }),
    })
end

return AnnotationsScreen
