-- The season of the year and what it does to the garden's colours: spring
-- vines blossom white, summer is as drawn, autumn turns gold and rust and
-- winter pale and bare.

local Season = {}

-- The names, in the order of the number a season has (1 to 4).
Season.NAMES = { "spring", "summer", "autumn", "winter" }

-- The season (1 to 4) of a month (1 to 12), by the northern calendar.
function Season.ofMonth(month)
    return ({ 4, 4, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4 })[month] or 2
end

-- Today's season.
function Season.current()
    return Season.ofMonth(tonumber(os.date("%m")) or 6)
end

-- The colours `c` as they are in season `n`: a table that answers for the
-- roles the season changes and passes the rest on.
function Season.palette(c, n)
    local change
    if n == 1 then change = { bloom = c.cream, bloom2 = c.pale, sage = c.leaf }
    elseif n == 3 then change = { leaf = c.gold, sage = c.bloom2, bloom2 = c.gold }
    elseif n == 4 then change = { leaf = c.sage, sage = c.pale, bloom = c.cream, bloom2 = c.pale, stem = c.line }
    else return c end
    return setmetatable(change, { __index = c })
end

return Season
