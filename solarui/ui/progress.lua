-- Progress bars. The plain one is a round-ended bar filled up to `value` (0
-- to 1), used for gauges. A book's progress (book = true) is drawn in the
-- reader's chosen style: a vine that has grown that far with a rose at its
-- tip, a string of pearls turning gold, or a gold ribbon with a dragonfly at
-- its tip (art/progressstyles.lua).

local Art = require("solarui/gfx/art")
local Element = require("solarui/ui/element")
local Paint = require("solarui/gfx/paint")
local Settings = require("solarui/settings")
local Theme = require("solarui/theme")
local _ = require("solarui/gettext")

local Progress = Element:extend({ value = 0, segments = 20, cell_h = 12, color = "ink" })

-- The styles a book's progress can be drawn in, and their heights (base px).
Progress.STYLES = {
    { id = "vine", name = _("Vine"), h = 36 },
    { id = "pearls", name = _("Pearls"), h = 30 },
    { id = "ribbon", name = _("Dragonfly"), h = 36 },
}
local GAUGE = { id = "bar" }   -- (plain bars that are not a book's: gauges)
local by_id = {}
for _i, s in ipairs(Progress.STYLES) do by_id[s.id] = s end

-- The style of a book's progress.
function Progress.bookStyle()
    return by_id[Settings.get("progress_style", "vine")] or Progress.STYLES[1]   -- (the old bar and cells come back as the vine)
end

-- The style this bar is drawn in.
function Progress:style()
    return self.book and Progress.bookStyle() or GAUGE
end

-- One cell tall, or the style's height.
function Progress:naturalHeight()
    if self.book then return Theme.px(Progress.bookStyle().h) end
    return Theme.px(self.cell_h)
end

-- Cells filled up to the value, outlined after it.
local function segments(self, bb, x, y, c)
    local th = Theme.get()
    local n = self.segments
    local gap = th.size.segment_gap
    local cell = math.floor((self.w - gap * (n - 1)) / n)
    if cell < 2 then n, cell = math.max(1, math.floor(self.w / 4)), 2 end
    local filled = math.floor(self.v * n + 0.5)
    local hair = th.size.hair
    -- the last cell takes the rounding left over so the bar ends flush
    local cx = x
    for i = 1, n do
        local cw = (i == n) and (x + self.w - cx) or cell
        if i <= filled then Paint.fill(bb, cx, y, cw, self.h, c)
        else Paint.frame(bb, cx, y, cw, self.h, hair, c) end
        cx = cx + cell + gap
    end
end

-- A rounded track filled as far as the value.
local function bar(self, bb, x, y, c)
    local th = Theme.get()
    local r = math.floor(self.h / 2)
    Paint.roundFrame(bb, x, y, self.w, self.h, r, "trbl", th.size.hair, c)
    local w = math.floor(self.w * self.v + 0.5)
    if w >= self.h then Paint.round(bb, x, y, w, self.h, r, "trbl", c) end
end

-- A drawing of the progress (the vine, the pearls, the ribbon) for the bar's size.
local function drawn(name)
    return function(self, bb, x, y)
        local k = self.h / 70
        Art.draw(bb, name, x, y, self.w, self.h, math.floor(self.w / k + 0.5), 70, math.floor(self.v * 100 + 0.5))
    end
end

local DRAW = { segments = segments, bar = bar, vine = drawn("progress"), pearls = drawn("progress_pearls"), ribbon = drawn("progress_ribbon") }

-- Draw in the bar's style.
function Progress:draw(bb, x, y)
    self.v = math.max(0, math.min(1, self.value or 0))
    DRAW[self:style().id](self, bb, x, y, Theme.color(self.color))
end

-- Let the reader pick the style of a book's progress.
function Progress.pickStyle()
    local App = require("solarui/app")
    local cur = Progress.bookStyle().id
    local options = {}
    for _i, s in ipairs(Progress.STYLES) do
        options[#options + 1] = { label = s.name, checked = s.id == cur, on_tap = function()
            Settings.save("progress_style", s.id)
            App.update()
        end }
    end
    App.choose({ title = _("Book progress"), cols = 1, options = options })
end

return Progress
