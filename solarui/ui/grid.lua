-- A paged grid: fills its box with as many equal cells as fit, shows one page
-- of `items` and reports how many fit (on_layout) so the screen can page.
-- Columns are fixed by `cols`, or as many as fit cells `min_cell_w` wide.
-- With `fit` the grid picks the columns and rows that fill the box evenly:
-- cells near `min_cell_w` wide and `ratio` times as tall, stretched a little
-- so no space is left over. One column makes it a paged list.

local Art = require("solarui/gfx/art")
local Element = require("solarui/ui/element")
local Theme = require("solarui/theme")

local Grid = Element:extend({ page = 1 })

-- The columns and rows that fill a w x h box best with cells close to `min_w`
-- wide and `ratio` times as tall: { cols, rows, cell_w, cell_h, space }, or
-- nil when no layout keeps the cells within reason. Cells are either
-- stretched a little to fill the height exactly, or kept in proportion with
-- the room left over shared out evenly as `space` above, between and below
-- the rows.
function Grid.fit(w, h, gap, row_gap, min_w, ratio)
    local base = math.max(2, math.floor((w + gap) / (min_w + gap)))
    local best
    local function offer(cols, rows, cw, ch)
        local used = rows * ch + (rows - 1) * row_gap
        local space = math.floor((h - used) / (rows + 1))
        local r = ch / cw
        if space < 0 or r > ratio * 1.2 or r < ratio * .8 then return end
        local score = math.abs(math.log(cw / min_w)) + 1.5 * math.abs(math.log(r / ratio)) + 2 * space * (rows + 1) / h
        if not best or score < best.score then best = { cols = cols, rows = rows, cell_w = cw, cell_h = ch, space = space, score = score } end
    end
    for cols = math.max(2, base - 1), base + 3 do
        local cw = math.floor((w - gap * (cols - 1)) / cols)
        if cw >= min_w * .85 and cw <= min_w * 1.4 then
            for rows = 1, 8 do
                offer(cols, rows, cw, math.floor((h - row_gap * (rows - 1)) / rows))   -- stretched to fill
                offer(cols, rows, cw, math.floor(cw * ratio))                          -- in proportion
            end
        end
    end
    return best
end

-- Size the cells and build the elements of the current page.
function Grid:layout(w, h)
    self.w = self.width or w
    self.h = self.height or h or 0
    local gap = self.gap or Theme.get().space.m
    local row_gap = self.row_gap or gap
    local cols = self.cols or math.max(2, math.floor((self.w + gap) / ((self.min_cell_w or Theme.px(120)) + gap)))
    local cell_w = math.floor((self.w - gap * (cols - 1)) / cols)
    local cell_h = self.cell_h or math.floor(cell_w * (self.ratio or 1.5))
    -- a row taller than the box (big covers on a landscape screen): narrower
    -- cells, more to a row, until one row fits
    while not self.cell_h and not self.cols and cell_h > self.h and cell_w > Theme.px(40) do
        cols = cols + 1
        cell_w = math.floor((self.w - gap * (cols - 1)) / cols)
        cell_h = math.floor(cell_w * (self.ratio or 1.5))
    end
    local rows = math.max(1, math.floor((self.h + row_gap) / (cell_h + row_gap)))
    local fit = self.fit and not self.cols and not self.cell_h and Grid.fit(self.w, self.h, gap, row_gap, self.min_cell_w or Theme.px(120), self.ratio or 1.5)
    self.y_off, self.space = 0, 0
    if fit then
        cols, rows, cell_w, cell_h = fit.cols, fit.rows, fit.cell_w, fit.cell_h
        self.y_off, self.space = fit.space, fit.space
    end
    self.ncols = cols
    self.x_off = math.floor((self.w - cols * cell_w - gap * (cols - 1)) / 2)
    local capacity = rows * cols
    local pages = math.max(1, math.ceil(#self.items / capacity))
    self.page = math.max(1, math.min(self.page, pages))
    self.children = {}
    local first = (self.page - 1) * capacity
    for i = 1, capacity do
        local item = self.items[first + i]
        if not item then break end
        local el = self.make(item, cell_w, cell_h)
        el:layout(cell_w, cell_h)
        self.children[i] = el
    end
    self.cell_w, self.cell_h, self.gap_x, self.gap_y = cell_w, cell_h, gap, row_gap + self.space
    if self.on_layout then self.on_layout(capacity, pages, self.page) end
end

-- Paint the cells row by row, a shelf rail under each row when `rails` is
-- set and the gap between rows has room for one.
function Grid:paint(bb, x, y)
    self.x, self.y = x, y
    local rh = math.min(Theme.px(12), self.gap_y - Theme.px(3))
    if self.rails and rh >= Theme.px(6) then
        local k = Theme.px(100) / 178
        for row = 0, math.floor((#self.children - 1) / self.ncols) do
            Art.draw(bb, "rail_line", x, y + self.y_off + row * (self.cell_h + self.gap_y) + self.cell_h + Theme.px(2), self.w, rh, self.w / k, rh / k)
        end
    end
    for i, el in ipairs(self.children) do
        local col = (i - 1) % self.ncols
        local row = math.floor((i - 1) / self.ncols)
        el:paint(bb, x + self.x_off + col * (self.cell_w + self.gap_x), y + self.y_off + row * (self.cell_h + self.gap_y))
    end
end

return Grid
