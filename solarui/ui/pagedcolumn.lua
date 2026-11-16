-- A column of elements that is too long for its box, shown a page at a time:
-- as many whole items as fit make a page, and a paging row appears under them
-- only when there is more than one page. The owner keeps `page` between
-- rebuilds and learns how many pages there are from on_layout(pages, page),
-- so swipes and the page keys can turn them too.

local Element = require("solarui/ui/element")
local Theme = require("solarui/theme")

local PagedColumn = Element:extend({ page = 1 })

-- How many items further on a page may look for one that still fits (with `fill`).
local LOOK_AHEAD = 3

-- Cut the items into pages of at most `room` pixels, each laid out at width
-- w. With `fill`, room left at a page's foot goes to one of the next few
-- items that fits there (settings, whose order is loose), else items keep
-- their order exactly.
local function split(items, w, room, gap, fill)
    local left = {}
    for i, item in ipairs(items) do
        item:layout(w, nil)
        left[i] = item
    end
    local pages = {}
    while #left > 0 do
        local cur, used, i = {}, 0, 1
        while i <= #left do
            local need = left[i].h + (#cur > 0 and gap or 0)
            if #cur == 0 or used + need <= room then
                cur[#cur + 1] = table.remove(left, i)
                used = used + need
            elseif fill and i < LOOK_AHEAD + 1 then
                i = i + 1
            else
                break
            end
        end
        pages[#pages + 1] = cur
    end
    return pages
end

-- Lay the items out and pick the page to show.
function PagedColumn:layout(w, h)
    self.w = self.width or w
    self.h = self.height or h or 0
    self.gap = self.gap or Theme.get().space.m
    local pages = split(self.items, self.w, self.h, self.gap, self.fill)
    if #pages > 1 then
        -- a page is shorter by the paging row
        if not self.pager then self.pager = self.make_pager(self) end
        self.pager:layout(self.w, nil)
        pages = split(self.items, self.w, self.h - self.pager.h - self.gap, self.gap, self.fill)
    end
    self.pages = #pages
    self.page = math.max(1, math.min(self.page, self.pages))
    self.children = {}
    for i, item in ipairs(pages[self.page]) do self.children[i] = item end
    if self.pages > 1 then self.children[#self.children + 1] = self.pager end
    if self.on_layout then self.on_layout(self.pages, self.page) end
end

-- Paint the page's items from the top and the paging row at the bottom.
function PagedColumn:paint(bb, x, y)
    self.x, self.y = x, y
    local cy = y
    for _i, c in ipairs(self.children) do
        if c == self.pager then
            c:paint(bb, x, y + self.h - c.h)
        else
            c:paint(bb, x, cy)
            cy = cy + c.h + self.gap
        end
    end
end

return PagedColumn
