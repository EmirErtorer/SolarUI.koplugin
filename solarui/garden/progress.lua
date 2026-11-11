-- What the reader's year and days of reading grow in the garden, as plain
-- numbers for the pictures: the vine along the frame grows a leaf for each
-- day on which something was read since the garden began and flowers after
-- every thirty (a day missed only pauses it, nothing is ever lost), and the
-- maple wears a golden leaf for each book finished this year, bearing fruit
-- once the year's goal is met.

local Progress = {}

Progress.VINE_DAYS = 30    -- leaves of the vine before it flowers
Progress.MAPLE_LEAVES = 12 -- most golden leaves the maple shows

-- The date "YYYY-MM-DD" of a time.
local function dateOf(t)
    return os.date("%Y-%m-%d", t)
end

-- The vine: { days (read since `created`), leaves (0 to VINE_DAYS), flowers }.
-- `days` is a list of "YYYY-MM-DD" dates on which something was read.
function Progress.vine(created, days)
    local since, n = dateOf(created), 0
    for _i, date in ipairs(days or {}) do
        if date >= since then n = n + 1 end
    end
    return { days = n, leaves = n % Progress.VINE_DAYS, flowers = math.floor(n / Progress.VINE_DAYS) }
end

-- The year: { books (finished this year), goal (or nil), leaves (golden
-- leaves on the maple), ripe (the goal is met) }.
function Progress.year(books, goal)
    books = books or 0
    return { books = books, goal = goal, leaves = math.min(books, Progress.MAPLE_LEAVES), ripe = goal ~= nil and goal > 0 and books >= goal }
end

return Progress
