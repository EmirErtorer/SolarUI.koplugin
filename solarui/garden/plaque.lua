-- The passage carved on the garden's plaque: one of the reader's own
-- highlights from a recently read book, a different one each day.

local Annotations = require("solarui/data/annotations")
local Books = require("solarui/data/books")
local History = require("solarui/data/history")

local Plaque = {}

local MIN, MAX = 30, 140   -- letters a passage may have to fit the plaque

-- Is this a passage rather than a heading? It has lower-case letters, and
-- they are most of its letters.
function Plaque.readable(text)
    local lower = select(2, text:gsub("%l", ""))
    local upper = select(2, text:gsub("%u", ""))
    return lower >= 15 and lower > upper * 2
end

-- The highlights short enough for the plaque from the last books read:
-- { text, title }.
function Plaque.candidates()
    local out = {}
    for _i, item in ipairs(History.recent(8)) do
        local path = item.path
        for _j, a in ipairs(Annotations.kinds(path).highlights) do
            local n = select(2, a.text:gsub("[^\128-\191]", ""))   -- letters, not bytes
            if n >= MIN and n <= MAX and Plaque.readable(a.text) then out[#out + 1] = { text = a.text, title = Books.info(path).title } end
        end
    end
    return out
end

-- Today's passage, or nil when there are no highlights yet. `day` is the
-- day number (the date's day of the year by default).
function Plaque.today(day)
    local list = Plaque.candidates()
    if #list == 0 then return nil end
    return list[((day or tonumber(os.date("%j"))) % #list) + 1]
end

return Plaque
