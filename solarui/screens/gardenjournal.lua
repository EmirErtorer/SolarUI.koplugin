-- The garden journal: what has happened, newest first, one dated line each.

local Frame = require("solarui/screens/frame")
local Journal = require("solarui/garden/journal")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Screen = require("solarui/screens/screen")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local GardenJournal = Screen:extend()

-- Start on the first page.
function GardenJournal:init() self.page = 1 end

-- One line of the journal: the date in the margin, then what happened.
local function row(line)
    local th = Theme.get()
    return Layout.Row:new({ gap = th.space.m, children = {
        Label:new({ text = line.date, kind = "small", color = "muted", width = Theme.px(64) }),
        Label:new({ text = line.text, kind = "body", lines = 2, grow = true }),
    } })
end

-- Build the page.
function GardenJournal:build()
    State.refresh()
    local items = {}
    for _i, line in ipairs(Journal.lines()) do items[#items + 1] = row(line) end
    if #items == 0 then items[1] = Label:new({ text = _("Nothing has happened yet. Give it a day or two."), kind = "body", color = "muted", lines = 2 }) end
    return Frame.page({ screen = self, title = _("Journal"), plant = "notes", body = Frame.paged(self, items, _("Page")) })
end

return GardenJournal
