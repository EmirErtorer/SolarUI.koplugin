-- The reading log: tabs for the log itself, a week, month or
-- year at a time, streaks and records, a calendar, and the yearly goal. A
-- scope button limits every number to chosen folders. Each tab is a module
-- in screens/log/.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Calendar = require("solarui/screens/log/calendar")
local Controls = require("solarui/ui/controls")
local Frame = require("solarui/screens/frame")
local GoalTab = require("solarui/screens/log/goal")
local Layout = require("solarui/ui/layout")
local Metric = require("solarui/data/metric")
local Period = require("solarui/screens/log/period")
local Scope = require("solarui/data/statsscope")
local ScopeSheet = require("solarui/screens/log/scope")
local Screen = require("solarui/screens/screen")
local Stats = require("solarui/data/stats")
local Streaks = require("solarui/screens/log/streaks")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")
local Week = require("solarui/screens/log/week")
local _ = require("solarui/gettext")

local History = Screen:extend()

-- The tabs: name, id and the module that builds it.
local TABS = {
    { _("Log"), "log", Week }, { _("Stats"), "stats", Period }, { _("Streaks"), "streaks", Streaks },
    { _("Calendar"), "calendar", Calendar }, { _("Goal"), "goal", GoalTab },
}

-- Start on the log, today selected, and every period at the present.
function History:init()
    self.tab = "log"
    self.day = 7
    self.period, self.back = "week", 0
    self.cal_back, self.goal_back = 0, 0
    self.page = 1
end

-- Build the log.
function History:build()
    local th = Theme.get()
    local options, module = {}, nil
    for i, t in ipairs(TABS) do
        options[i] = { t[1], t[2] }
        if t[2] == self.tab then module = t[3] end
    end
    local tabs = Controls.Segmented({ options = options, value = self.tab, kind = "small",
        on_change = function(v) self.tab, self.page = v, 1; App.update() end })
    local scope = Button:new({ icon = "folder", variant = Scope.active() and "icon_on" or "icon", width = th.size.touch,
        on_tap = ScopeSheet.open })
    local actions = { scope }
    if self.tab == "log" or self.tab == "calendar" then
        actions[#actions + 1] = Button:new({ label = Metric.unit(), variant = "secondary", width = math.max(th.size.touch, Text.width("label", Metric.unit()) + 2 * th.space.m), height = th.size.touch,
            on_tap = function() Metric.toggle(); App.update() end })
    end
    local n = #Scope.folders()
    local path = Scope.active() and string.format(_.n("%d folder", "%d folders", n), n) or nil
    return Frame.page({
        screen = self, title = _("Reading log"), path = path, tab = "history", actions = actions,
        body = Layout.Column:new({ gap = th.space.m, children = { tabs, module.build(self) } }),
    })
end

-- Coming back after reading: the numbers changed.
function History:onRaise()
    Stats.invalidate()
end

return History
