-- The passages shown in the book on the garden's table: the reader's own
-- highlights from recently read books, in a different order on each visit.

local Annotations = require("solarui/data/annotations")
local Books = require("solarui/data/books")
local History = require("solarui/data/history")
local Nature = require("solarui/garden/nature")
local Season = require("solarui/garden/season")

local Plaque = {}

local MIN, MAX = 30, 220   -- letters a passage may have to fit a page of the book

-- Is this a passage rather than a heading? It has lower-case letters, and
-- they are most of its letters.
function Plaque.readable(text)
    local lower = select(2, text:gsub("%l", ""))
    local upper = select(2, text:gsub("%u", ""))
    return lower >= 15 and lower > upper * 2
end

-- The highlights short enough for the plaque from the last books read:
-- { text, title, author, path, chapter, pageno, date, note, page, pos0 }
-- (page and pos0 are the place in the book, to open it there).
function Plaque.candidates()
    local out = {}
    for _i, item in ipairs(History.recent(8)) do
        local path = item.path
        for _j, a in ipairs(Annotations.kinds(path).highlights) do
            local n = select(2, a.text:gsub("[^\128-\191]", ""))   -- letters, not bytes
            if n >= MIN and n <= MAX and Plaque.readable(a.text) then
                local info = Books.info(path)
                out[#out + 1] = { text = a.text, title = info.title, author = info.author, path = path, chapter = a.chapter, pageno = a.pageno,
                    date = a.date, note = a.note, page = a.page, pos0 = a.pos0 }
            end
        end
    end
    return out
end

-- A list shuffled by `s` (the same seed, the same order); returns the list.
local function shuffled(list, s)
    s = math.floor(s or 1) % 2147483646 + 1
    for i = #list, 2, -1 do
        s = s * 48271 % 2147483647
        local j = 1 + math.floor(s / 2147483647 * i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

-- The passages in an order shuffled by `seed` (the same seed, the same
-- order), so each visit to the garden starts at a different one. Every third
-- one is a line about the season, written for the garden (see garden/nature.lua);
-- with no highlights the lines go on alone.
function Plaque.deal(seed)
    local own = shuffled(Plaque.candidates(), seed)
    local lines = shuffled(Nature.passages(Season.now(), Season.NAMES[Season.now()]), (seed or 1) + 7)
    local out, a, b = {}, 1, 1
    while a <= #own or b <= #lines do
        for _i = 1, 2 do
            if own[a] then out[#out + 1] = own[a]; a = a + 1 end
        end
        if lines[b] then out[#out + 1] = lines[b]; b = b + 1 end
    end
    return out
end

return Plaque
