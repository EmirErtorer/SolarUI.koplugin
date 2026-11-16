-- The passages shown in the book on the garden's table, in two parts the
-- reader switches between: their own highlights, drawn at random from every
-- book they have highlighted in, and lines the garden writes about the
-- season. Each comes in a different order on each visit.

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

-- What one book gives the plaque: its highlights short enough for a page,
-- { text, title, author, path, chapter, pageno, date, note, page, pos0 }
-- (page and pos0 are the place in the book, to open it there).
local function fromBook(path)
    local out, info = {}, nil
    for _j, a in ipairs(Annotations.kinds(path).highlights) do
        local n = select(2, a.text:gsub("[^\128-\191]", ""))   -- letters, not bytes
        if n >= MIN and n <= MAX and Plaque.readable(a.text) then
            info = info or Books.info(path)
            out[#out + 1] = { text = a.text, title = info.title, author = info.author, path = path, chapter = a.chapter, pageno = a.pageno,
                date = a.date, note = a.note, page = a.page, pos0 = a.pos0 }
        end
    end
    return out
end

-- Each book's passages as read this session, by path: a book's reading data
-- is read once, except for the few read last, where new highlights land.
local seen = {}

-- The highlights short enough for the plaque from every book in the
-- reading history.
function Plaque.candidates()
    local out, fresh = {}, {}
    for _i, item in ipairs(History.recent(3)) do fresh[item.path] = true end
    for _i, item in ipairs(History.recent(math.huge)) do
        local path = item.path
        if fresh[path] or not seen[path] then seen[path] = fromBook(path) end
        for _j, q in ipairs(seen[path]) do out[#out + 1] = q end
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

-- The two parts of the book.
Plaque.HIGHLIGHTS = "highlights"
Plaque.GARDEN = "garden"

-- The passages of one part (`which`, Plaque.HIGHLIGHTS by default) in an
-- order shuffled by `seed` (the same seed, the same order), so each visit to
-- the garden starts at a different one: the reader's highlights, or the lines
-- about the season written for the garden (see garden/nature.lua).
function Plaque.deal(seed, which)
    if which == Plaque.GARDEN then
        return shuffled(Nature.passages(Season.now(), Season.NAMES[Season.now()]), (seed or 1) + 7)
    end
    return shuffled(Plaque.candidates(), seed)
end

return Plaque
