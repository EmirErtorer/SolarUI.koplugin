-- The goal tab: books finished this year against the reader's target, the
-- achievements earned, and the year's finished books on a shelf.

local Achievements = require("solarui/data/achievements")
local Actions = require("solarui/actions")
local App = require("solarui/app")
local BookTile = require("solarui/ui/booktile")
local Button = require("solarui/ui/button")
local Controls = require("solarui/ui/controls")
local Frame = require("solarui/screens/frame")
local Goal = require("solarui/data/goal")
local Grid = require("solarui/ui/grid")
local Insights = require("solarui/data/insights")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local ArtView = require("solarui/ui/artview")
local Theme = require("solarui/theme")
local navrow = require("solarui/ui/navrow")
local tile = require("solarui/ui/stattile")
local Screen = require("device").screen
local _ = require("solarui/gettext")

local GoalTab = {}

local PER_ROW = 6   -- chips to a row, so every level fits its chip

-- A ladder of achievements: its name and one chip per level, filled when
-- earned, six to a row.
local function ladder(l)
    local th = Theme.get()
    local rows = {}
    for i = 1, #l.items, PER_ROW do
        local kids = { Label:new({ text = i == 1 and l.name or "", kind = "small", color = "muted", width = Theme.px(76) }) }
        for j = i, math.min(#l.items, i + PER_ROW - 1) do
            local a = l.items[j]
            kids[#kids + 1] = Button:new({ label = a.short, kind = "small", variant = a.got and "chip_on" or "chip", grow = true, height = Theme.px(30) })
        end
        rows[#rows + 1] = Layout.Row:new({ gap = th.space.xs, children = kids })
    end
    return Layout.Column:new({ gap = th.space.xs, children = rows })
end

-- The tree's height: tall on a tall screen, and on a short one low enough that the
-- shelf under the achievements still has room for a row and its pager.
function GoalTab.treeHeight()
    return math.min(Theme.px(300), math.max(Theme.px(130), math.floor(Screen:getHeight() * .14)))
end

-- Build the tab; `screen.goal_back` is how many years back from this one.
function GoalTab.build(screen)
    local th = Theme.get()
    local year = tonumber(os.date("%Y")) - screen.goal_back
    local target = Goal.target()
    local shelf = Goal.finishedIn(year)
    local streaks = Insights.streaks()
    local numbers = { hours = Insights.allTime().seconds / 3600, streak = streaks.day_best, finished = #Goal.finished() }
    local ladders = Achievements.ladders(numbers)
    local got, latest = Achievements.summary(ladders)

    local nav = navrow({ label = string.format(_("%d"), year), can_next = screen.goal_back > 0,
        on_prev = function() screen.goal_back, screen.page = screen.goal_back + 1, 1; App.update() end,
        on_next = function() screen.goal_back, screen.page = screen.goal_back - 1, 1; App.update() end })
    -- the tree, which stands for the year's progress, beside the numbers
    local percent = math.floor(math.min(#shelf / target, 1) * 100 + .5)
    local numbers_col = Layout.Column:new({ grow = true, gap = th.space.s, children = {
        Layout.Row:new({ gap = th.space.s, children = {
            tile(_("Finished"), string.format("%d/%d", #shelf, target), string.format(_("%d%% of the goal"), percent)),
            tile(_("Achieved"), tostring(got), latest or _("None yet")),
        } }),
        Layout.Row:new({ gap = th.space.m, valign = "center", children = {
            Label:new({ text = _("Year goal"), kind = "body", color = "muted", grow = true }),
            Controls.Stepper({ value = target, min = 1, max = 999, step = 1, format = function(v) return tostring(v) end, value_w = 48,
                on_change = function(v) Goal.setTarget(v); App.update() end }),
        } }),
    } })
    local goal = Layout.Row:new({ gap = th.space.m, valign = "center", children = {
        ArtView:new({ name = "goal_tree", param = percent, grow = true, height = GoalTab.treeHeight() }),
        numbers_col,
    } })
    local body = { nav, goal }
    for _i, l in ipairs(ladders) do body[#body + 1] = ladder(l) end
    if #shelf == 0 then
        body[#body + 1] = Label:new({ grow = true, text = _("No books finished this year. Mark a book as done and it shelves here."), kind = "small", color = "muted", lines = 3 })
    else
        body[#body + 1] = Grid:new({ grow = true, items = shelf, page = screen.page, min_cell_w = Theme.px(96), ratio = 1.72,
            make = function(item, w, h) return BookTile.build(item.path, w, h, { on_tap = function() Actions.details(item.path) end }) end,
            on_layout = function(_cap, pages, page) screen.pages, screen.page = pages, page end })
        body[#body + 1] = Frame.pager(screen, _("Shelf"), function(p) screen:setPage(p) end)
    end
    return Layout.Column:new({ grow = true, gap = th.space.m, children = body })
end

return GoalTab
