-- The paging row under a list or a grid: round arrows, the page as words
-- ("Page 3 of 24") over a row of dots, one for each page with the current
-- one filled. The pages and screen share it with the dialogs.

local Button = require("solarui/ui/button")
local Element = require("solarui/ui/element")
local Layout = require("solarui/ui/layout")
local Paint = require("solarui/gfx/paint")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local Pager = {}

local MAX_DOTS = 12

-- The words and the dots in the middle; `state` holds page and pages as they
-- are when it is painted.
local Middle = Element:extend({})

-- Tall enough for the words and the dots.
function Middle:naturalHeight()
    return Text.height("small") + Theme.px(10)
end

-- Draw "Label 3 of 24" and, for a few pages, a dot for each.
function Middle:draw(bb, x, y)
    local th = Theme.get()
    local page, pages = self.state.page or 1, self.state.pages or 1
    local s = Text.fit("small", string.format(_("%s %d of %d"), self.label, page, pages), self.w)
    Text.draw(bb, x + math.floor((self.w - Text.width("small", s)) / 2), y, "small", s, th.c.ink)
    if pages < 2 or pages > MAX_DOTS then return end
    local d, gap = Theme.px(6), Theme.px(6)
    local dx = x + math.floor((self.w - pages * d - (pages - 1) * gap) / 2)
    local dy = y + self.h - d
    for i = 1, pages do
        if i == page then
            Paint.disc(bb, dx, dy, d, th.c.accent)
        else
            Paint.roundFrame(bb, dx, dy, d, d, math.floor(d / 2), "trbl", th.size.hair, th.c.muted)
        end
        dx = dx + d + gap
    end
end

-- Build the row. `state` holds page and pages (a paged list fills them in
-- when it is laid out), `label` names what is paged ("Page" when nil) and
-- on_page(p) opens a page; it is not called for a page that is not there.
-- `ends` false leaves out the first and last buttons.
function Pager.build(state, label, on_page, ends)
    local th = Theme.get()
    local w = Theme.px(46)
    local function go(icon, variant, target)
        return Button:new({ icon = icon, variant = variant, width = w, on_tap = function()
            local p = math.max(1, math.min(target(), state.pages or 1))
            if p ~= state.page then on_page(p) end
        end })
    end
    local kids = {
        go("back", "icon", function() return state.page - 1 end),
        Middle:new({ grow = true, state = state, label = label or _("Page") }),
        go("forward", "icon_on", function() return state.page + 1 end),
    }
    if ends ~= false then
        table.insert(kids, 1, go("first", "plain", function() return 1 end))
        kids[#kids + 1] = go("last", "plain", function() return state.pages or 1 end)
    end
    return Layout.Row:new({ gap = th.space.s, children = kids })
end

return Pager
