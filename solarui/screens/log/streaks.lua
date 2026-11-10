-- The streaks tab: streaks of days and weeks, the personal records, totals
-- since the first day and the clearance level (hours read against the next
-- milestone).

local Format = require("solarui/format")
local Insights = require("solarui/data/insights")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Panel = require("solarui/ui/panel")
local Progress = require("solarui/ui/progress")
local Theme = require("solarui/theme")
local tile = require("solarui/ui/stattile")
local _ = require("solarui/gettext")

local Streaks = {}

-- A label and its value on one line.
local function fact(k, v)
    return Layout.Row:new({ children = {
        Label:new({ text = k, kind = "mono_small", color = "muted", grow = true }),
        Label:new({ text = v, kind = "mono_small" }),
    } })
end

-- A date as "12 OCT 2026".
local function date(d)
    return d and d.date and Format.date("%d %b %Y", d.time) or "-"
end

-- Build the tab.
function Streaks.build()
    local th = Theme.get()
    local s = Insights.streaks()
    local all = Insights.allTime()
    local rec = Insights.records()
    local hours = all.seconds / 3600
    local c = Insights.clearance(hours)
    local frac = c.next and (hours - (c.last or 0)) / (c.next - (c.last or 0)) or 1

    local tiles = Layout.Row:new({ gap = th.space.m, children = {
        tile(_("Day streak"), tostring(s.day_now), string.format(_("Best %d"), s.day_best)),
        tile(_("Week streak"), tostring(s.week_now), string.format(_("Best %d"), s.week_best)),
        tile(_("Hours"), string.format("%d", math.floor(hours)), string.format(_.n("%d page", "%d pages", all.pages), all.pages)),
    } })
    local records = Panel:new({ shape = "frame", pad = th.space.m, child = Layout.Column:new({ gap = th.space.xs, children = {
        Label:new({ text = _("Records"), kind = "micro", color = "muted" }),
        fact(_("Longest day"), string.format("%s · %s", Format.duration(rec.time.seconds), date(rec.time))),
        fact(_("Most pages"), string.format("%d · %s", rec.pages.pages or 0, date(rec.pages))),
        fact(_("Days read"), tostring(all.days)),
        fact(_("Since"), all.first and Format.date("%d %b %Y", all.first) or "-"),
    } }) })
    local level = Layout.Column:new({ gap = th.space.s, children = {
        Layout.Row:new({ children = {
            Label:new({ text = string.format(_("Hours level %02d"), c.level), kind = "label", grow = true }),
            Label:new({ text = c.next and string.format(_("Next %dh, %dh left"), c.next, math.ceil(c.next - hours)) or _("Maxed"),
                kind = "mono_small", color = "muted" }),
        } }),
        Progress:new({ value = math.max(0, math.min(frac, 1)) }),
    } })
    return Layout.Column:new({ grow = true, gap = th.space.l, children = { tiles, records, level } })
end

return Streaks
