-- The stats tab: a week, month or year at a time, with a back and forward
-- step, a bar chart, averages and a comparison with the period before.

local App = require("solarui/app")
local Charts = require("solarui/ui/charts")
local Controls = require("solarui/ui/controls")
local Format = require("solarui/format")
local Insights = require("solarui/data/insights")
local Section = require("solarui/ui/section")
local Layout = require("solarui/ui/layout")
local Statsdb = require("solarui/data/statsdb")
local Theme = require("solarui/theme")
local navrow = require("solarui/ui/navrow")
local tile = require("solarui/ui/stattile")
local _ = require("solarui/gettext")

local Period = {}

local DAY = 86400

-- Midnight at the start of a date table.
local function at(y, m, d)
    return os.time({ year = y, month = m, day = d, hour = 0 })
end

-- The period `back` steps before now: { from, to (times), caption, count (bars),
-- label(i), start(i) (the time bar i begins at), span (seconds per bar) }.
local function range(kind, back)
    local now = os.date("*t")
    if kind == "week" then
        local monday = Statsdb.midnight((now.wday + 5) % 7 + 7 * back)
        local last = monday + 6 * DAY
        return { from = monday, to = monday + 7 * DAY - 1, count = 7, span = DAY,
            caption = Format.date("%d %b", monday) .. " - " .. Format.date("%d %b", last),
            label = function(i) return Format.date("%a", monday + (i - 1) * DAY + 43200) end,
            start = function(i) return monday + (i - 1) * DAY end }
    elseif kind == "month" then
        local first = at(now.year, now.month - back, 1)
        local t = os.date("*t", first)
        local days = tonumber(os.date("%d", at(t.year, t.month + 1, 0)))
        return { from = first, to = first + days * DAY - 1, count = days, span = DAY,
            caption = Format.date("%B %Y", first),
            label = function(i) return (i == 1 or i % 5 == 0) and tostring(i) or "" end,
            start = function(i) return first + (i - 1) * DAY end }
    end
    local year = now.year - back
    return { from = at(year, 1, 1), to = at(year + 1, 1, 1) - 1, count = 12, month = true, year = year,
        caption = tostring(year),
        label = function(i) return Format.chars(Format.date("%b", at(year, i, 1)), 1) end,
        start = function(i) return at(year, i, 1) end }
end

-- Seconds and pages read in each bar of a period, as two lists.
local function bars(r)
    local secs, pages = {}, {}
    for i = 1, r.count do secs[i], pages[i] = 0, 0 end
    if r.month then
        for i, m in ipairs(Insights.months(r.year)) do secs[i], pages[i] = m.seconds, m.pages end
        return secs, pages
    end
    for _i, d in ipairs(Insights.days()) do
        if d.time >= r.from and d.time <= r.to then
            local i = math.floor((d.time - r.from) / DAY) + 1
            if secs[i] then secs[i], pages[i] = d.seconds, d.pages end
        end
    end
    return secs, pages
end

-- Whole days of the period gone by now (all of it for a past period).
local function elapsed(r)
    local last = math.min(os.time(), r.to)
    return math.max(1, math.ceil((last - r.from) / DAY))
end

-- "+12% VS BEFORE", or nothing to compare with.
local function versus(now_s, before_s)
    if before_s <= 0 then return _("Nothing before") end
    local pct = math.floor((now_s - before_s) / before_s * 100 + 0.5)
    return string.format(pct >= 0 and _("+%d%% vs before") or _("%d%% vs before"), pct)
end

-- One bar chart under its title, the picked bar's value (or the best) on the right.
local function barChart(screen, title, detail, values, labels, pick, height)
    return Layout.Column:new({ gap = Theme.get().space.s, children = {
        Section.title(title, detail),
        Charts.Bars:new({ values = values, labels = labels, selected = pick or 0, height = Theme.px(height),
            on_select = function(i) screen.bar = i; App.update() end }),
    } })
end

-- Build the tab. State on the screen: period ("week", "month", "year"),
-- back (steps back from now) and bar (the bar picked, or nil). Minutes and
-- pages each get a chart (or one chart of both).
function Period.build(screen)
    local th = Theme.get()
    local kind, back = screen.period, screen.back
    local r, before = range(kind, back), range(kind, back + 1)
    local secs, pages = bars(r)
    local total = Insights.range(r.from, r.to)
    -- a period not over yet is set against the same stretch of the one before
    local prev = Insights.range(before.from, back == 0 and before.from + (os.time() - r.from) or before.to)
    local best_s, best_p = 0, 0
    local mins, labels = {}, {}
    for i, s in ipairs(secs) do
        mins[i] = s / 60
        labels[i] = r.label(i)
        best_s, best_p = math.max(best_s, s), math.max(best_p, pages[i])
    end
    local pick = screen.bar and secs[screen.bar] and screen.bar or nil
    local when = pick and Format.date("%d %b", r.start(pick) + 43200)

    local seg = Controls.Segmented({ options = { { _("Week"), "week" }, { _("Month"), "month" }, { _("Year"), "year" } },
        value = kind, kind = "small", on_change = function(v) screen.period, screen.back, screen.bar = v, 0, nil; App.update() end })
    local nav = navrow({ label = r.caption, can_next = back > 0,
        on_prev = function() screen.back, screen.bar = back + 1, nil; App.update() end,
        on_next = function() screen.back, screen.bar = back - 1, nil; App.update() end })
    local tiles = Layout.Row:new({ gap = th.space.m, children = {
        tile(_("Time"), Format.duration(total.seconds), versus(total.seconds, prev.seconds)),
        tile(_("Pages"), tostring(total.pages), string.format(_.n("%d day read", "%d days read", total.days), total.days)),
        tile(_("Average per day"), Format.duration(math.floor(total.seconds / elapsed(r))), _("Over the period")),
    } })
    local body = { seg, nav, tiles }
    body[#body + 1] = barChart(screen, _("Minutes read"), pick and string.format(_("%s = %d min"), when, Format.minutes(secs[pick]))
        or string.format(_("Best %s"), Format.duration(best_s)), mins, labels, pick, 120)
    body[#body + 1] = barChart(screen, _("Pages read"), pick and string.format(_("%s = %d pages"), when, pages[pick])
        or string.format(_("Best %d pages"), best_p), pages, labels, pick, 100)
    return Layout.Column:new({ grow = true, gap = th.space.l, children = body })
end

return Period
