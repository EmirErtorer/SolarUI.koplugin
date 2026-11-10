-- The calendar tab: a month of reading days shaded by minutes, stepped back
-- and forward, and when in the week and day the reader reads.

local App = require("solarui/app")
local Charts = require("solarui/ui/charts")
local Format = require("solarui/format")
local Insights = require("solarui/data/insights")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Metric = require("solarui/data/metric")
local Settings = require("solarui/settings")
local Theme = require("solarui/theme")
local navrow = require("solarui/ui/navrow")
local _ = require("solarui/gettext")

local Calendar = {}


-- A row of the weekday initials above the month's columns.
local function weekdays()
    local kids = {}
    for i = 1, 7 do
        -- 1 January 2001 was a Monday
        local initial = Format.chars(Format.upper(Format.date("%a", os.time({ year = 2001, month = 1, day = i, hour = 12 }))), 1)
        kids[i] = Label:new({ text = initial, kind = "micro", color = "muted", align = "center", grow = true })
    end
    return Layout.Row:new({ children = kids })
end

-- Build the tab; `screen.cal_back` is how many months back from now.
function Calendar.build(screen)
    local th = Theme.get()
    local goal = Settings.get("daily_goal", 30)
    local now = os.date("*t")
    local first = os.time({ year = now.year, month = now.month - screen.cal_back, day = 1, hour = 12 })
    local t = os.date("*t", first)
    local days = tonumber(os.date("%d", os.time({ year = t.year, month = t.month + 1, day = 0, hour = 12 })))
    local levels, month_days = {}, {}
    local month_prefix = os.date("%Y-%m-", first)
    local month_seconds, month_pages, top = 0, 0, 0
    for _i, d in ipairs(Insights.days()) do
        if d.date:sub(1, #month_prefix) == month_prefix then
            local day = tonumber(d.date:sub(9, 10))
            month_days[day] = d
            month_seconds, month_pages = month_seconds + d.seconds, month_pages + d.pages
            top = math.max(top, Metric.value(d))
        end
    end
    for day, d in pairs(month_days) do levels[day] = Metric.level(Metric.value(d), goal, top) end
    local nav = navrow({ label = Format.upper(Format.date("%B %Y", first)), can_next = screen.cal_back > 0,
        on_prev = function() screen.cal_back = screen.cal_back + 1; App.update() end,
        on_next = function() screen.cal_back = screen.cal_back - 1; App.update() end })
    local month = Charts.Month:new({ first = (tonumber(os.date("%w", first)) + 6) % 7 + 1, days = days, levels = levels,
        today = screen.cal_back == 0 and now.day or nil })

    -- when the reader reads: a row per weekday, a column per hour
    local grids = Insights.pattern()
    local grid = grids and (Metric.pages() and grids.pages or grids.seconds)
    local lv = {}
    if grid then
        local max = 1
        for w = 1, 7 do for h = 0, 23 do max = math.max(max, grid[w][h]) end end
        for h = 0, 23 do
            for w = 1, 7 do
                local f = grid[w][h] / max
                lv[#lv + 1] = grid[w][h] <= 0 and 0 or (f < 0.15 and 1 or (f < 0.4 and 2 or (f < 0.7 and 3 or 4)))
            end
        end
    end
    local pattern = Layout.Column:new({ gap = th.space.s, children = {
        Label:new({ text = string.format(_("WHEN YOU READ // MON-SUN BY HOUR // %s"), Metric.pages() and _("PAGES") or _("TIME")), kind = "label" }),
        Charts.Heatmap:new({ levels = lv, weeks = 24, rows = 7, col_labels = { [1] = "00", [7] = "06", [13] = "12", [19] = "18", [24] = "23" } }),
    } })
    local note = string.format(_.n("%s // %d PAGE THIS MONTH", "%s // %d PAGES THIS MONTH", month_pages), Format.duration(month_seconds), month_pages)
    local kids = { nav, weekdays(), month }
    kids[#kids + 1] = Label:new({ text = note, kind = "mono_small", color = "muted" })
    kids[#kids + 1] = pattern
    return Layout.Column:new({ grow = true, gap = th.space.m, children = kids })
end

return Calendar
