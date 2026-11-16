-- Ink Away's notebooks and drawings for SolarUI's notebook shelf, through the
-- same machinery Ink Away gives Bookshelf (its ink/bookshelf.lua and
-- ink/drawingshelf.lua): the documents of its library, newest first; the
-- pictures it keeps of them (a notebook's first page, a drawing) as it closes
-- them, or draws once in the background for one not opened since; and its
-- cover queue, which draws each cover once, one at a time between redraws,
-- and keeps it in a cache folder of its own until the picture or the look
-- changes. The covers are SolarUI's (gfx/inkrender.lua): eight boards and two
-- that show the first page for notebooks, eight frames for drawings. Each
-- document is given a look at random the first time the shelf sees it, the
-- looks dealt in shuffled rounds so the shelf shows them all; the reader can
-- change it. Looks are kept in Ink Away's binder file beside the documents
-- (keys solar_cover and solar_frame), so they follow a document renamed or
-- moved there. A tap opens the document in Ink Away, on the page it was left.

local InkCovers = require("solarui/art/inkcovers")
local InkFrames = require("solarui/art/inkframes")
local InkRender = require("solarui/gfx/inkrender")

local InkShelf = {}

InkShelf.NOTEBOOKS = "notebooks"
InkShelf.DRAWINGS = "drawings"

-- Ink Away's modules, or nil when Ink Away is not there (or too old to keep
-- its pictures for a home other than Bookshelf).
local function ink()
    local ok, m = pcall(function()
        local Shelf = require("ink/bookshelf")
        if type(Shelf.host) ~= "function" then return nil end
        return { Shelf = Shelf, DShelf = require("ink/drawingshelf"), Library = require("ink/library"), Storage = require("ink/storage"),
            Folder = require("ink/folder"), Cover = require("ink/notebookcover") }
    end)
    return ok and m or nil
end

-- Can the shelf show Ink Away's documents?
function InkShelf.available()
    return ink() ~= nil
end

-- Ink Away's library folder.
local function root(m)
    local G = rawget(_G, "G_reader_settings")
    return m.Library.root(G and G:readSetting("inkaway_library_dir"))
end

-- The ids of a kind's looks, in order.
local function ids(kind)
    local out = {}
    for _i, l in ipairs(kind == InkShelf.DRAWINGS and InkFrames.LOOKS or InkCovers.LOOKS) do out[#out + 1] = l.id end
    return out
end
InkShelf.ids = ids

-- The binder key a kind's look is kept under.
local function keyOf(kind) return kind == InkShelf.DRAWINGS and "solar_frame" or "solar_cover" end

-- The look id of the document at `path` (nil when it has none yet);
-- `binders` caches folders' binder data for a run of documents.
local function lookOf(m, kind, path, binders)
    local dir, name = m.Storage.dirName(path), m.Storage.baseName(path)
    local data = binders and binders[dir]
    if not data then
        data = m.Folder.load(dir)
        if binders then binders[dir] = data end
    end
    local c = type(data.covers) == "table" and type(data.covers[name]) == "table" and data.covers[name] or {}
    local id = c[keyOf(kind)]
    local valid = kind == InkShelf.DRAWINGS and InkFrames.look(id) or InkCovers.look(id)
    return valid and id or nil
end

-- Give the document at `path` the look `id`. Returns whether it was kept.
function InkShelf.setLook(kind, path, id)
    local m = ink()
    if not m then return false end
    local name = m.Storage.baseName(path)
    local ok = m.Folder.update(m.Storage.dirName(path), function(d)
        local c = type(d.covers[name]) == "table" and d.covers[name] or {}
        c[keyOf(kind)] = id
        d.covers[name] = c
    end)
    local q = InkShelf.queues and InkShelf.queues[kind]
    if q then q.redraw(path) end
    return ok
end

-- The look of a document, as the queue knows it: { id }.
function InkShelf.look(kind, path)
    local m = ink()
    return m and lookOf(m, kind, path) or nil
end

-- Give every document in `docs` with no look one at random, the looks dealt
-- in shuffled rounds so neighbours differ and every look shows, one binder
-- write per folder.
local function deal(m, kind, docs, binders)
    local all, round = ids(kind), {}
    local function nextLook()
        if #round == 0 then
            for i, id in ipairs(all) do round[i] = id end
            for i = #round, 2, -1 do
                local j = math.random(i)
                round[i], round[j] = round[j], round[i]
            end
        end
        return table.remove(round)
    end
    local byDir, dirs = {}, {}
    for _i, d in ipairs(docs) do
        if not lookOf(m, kind, d.path, binders) then
            local dir = m.Storage.dirName(d.path)
            if not byDir[dir] then byDir[dir] = {}; dirs[#dirs + 1] = dir end
            table.insert(byDir[dir], { name = m.Storage.baseName(d.path), id = nextLook() })
        end
    end
    for _i, dir in ipairs(dirs) do
        m.Folder.update(dir, function(data)
            for _j, it in ipairs(byDir[dir]) do
                local c = type(data.covers[it.name]) == "table" and data.covers[it.name] or {}
                if not c[keyOf(kind)] then c[keyOf(kind)] = it.id end
                data.covers[it.name] = c
            end
            binders[dir] = data
        end)
    end
end

-- Does look `id` of a notebook show its first page?
local function showsPage(id) return id == "page" or id == "mount" end

-- The cover queue of a kind, made once: Ink Away's queue with SolarUI's
-- covers in a folder of their own, the pictures read from Ink Away's own
-- folder of them. `changed()` redraws the shelf when covers land.
local function queue(m, kind, changed)
    InkShelf.queues = InkShelf.queues or {}
    InkShelf.listeners = InkShelf.listeners or {}
    InkShelf.listeners[kind] = changed
    if InkShelf.queues[kind] then return InkShelf.queues[kind] end
    local UIManager = require("ui/uimanager")
    local drawings = kind == InkShelf.DRAWINGS
    local own = drawings and m.DShelf.host() or m.Shelf.host()
    InkShelf.queues[kind] = m.Shelf.newCovers({
        cacheDir = m.Storage.cacheDir,
        subdir = drawings and "solarui-drawings" or "solarui-notebooks",
        pageDir = function() return own.dir() end,
        lookOf = function(path) return { id = lookOf(m, kind, path) or ids(kind)[1] } end,
        lookKey = function(look) return look.id .. "v" .. InkRender.VERSION end,
        stampOf = function(dir, path, look)
            if not (drawings or showsPage(look.id)) then return 0 end
            local file = m.Shelf.pageFile(dir, path)
            return file and m.Storage.mtime(file) or 0
        end,
        render = function(path, file, look, page)
            local done
            if drawings then done = InkRender.drawing(file, look.id, page)
            else done = InkRender.notebook(file, look.id, m.Storage.stem(path), page) end
            collectgarbage()
            return done
        end,
        draft = function(path, file)
            local done
            if drawings then done = m.DShelf.writeDraft(path, file) else done = m.Cover.writePage(path, file) end
            collectgarbage()
            return done
        end,
        schedule = function(s, fn) UIManager:scheduleIn(s, fn) end,
        unschedule = function(fn) UIManager:unschedule(fn) end,
        changed = function() local fn = InkShelf.listeners[kind]; if fn then fn() end end,
        busy = m.Shelf.busy,
    })
    return InkShelf.queues[kind]
end

-- The documents of a kind as the shelf shows them, newest first: { path,
-- name, look, cover (a PNG, or nil while it is drawn) }. Covers not drawn yet
-- are queued; `changed()` is called as they land. Nil when Ink Away is not there.
local pruned = {}
function InkShelf.list(kind, changed)
    local m = ink()
    if not m then return nil end
    local q = queue(m, kind, changed)
    local docs = m.Shelf.documents(root(m), kind == InkShelf.DRAWINGS)
    local binders = {}
    deal(m, kind, docs, binders)
    local dir, pages = q.dir(), q.pageDir(q.dir())
    q.forgetGone(docs)
    for _i, d in ipairs(docs) do
        d.look = { id = lookOf(m, kind, d.path, binders) or ids(kind)[1] }
        d.key = d.look.id .. "v" .. InkRender.VERSION
        d.stamp = (kind == InkShelf.DRAWINGS or showsPage(d.look.id)) and (function()
            local file = m.Shelf.pageFile(pages, d.path)
            return file and m.Storage.mtime(file) or 0
        end)() or 0
        d.cover = q.get(d, dir)
        if q.wantDraft then q.wantDraft(d, dir, kind == InkShelf.DRAWINGS or showsPage(d.look.id)) end
    end
    local now = os.time()
    if not pruned[kind] or now - pruned[kind] >= m.Shelf.STALE_AFTER then
        pruned[kind] = now
        q.prune(docs, dir, now)
    end
    return docs
end

-- Ink Away's plugin in the file browser or reader open now, or nil.
local function plugin()
    local ui = require("apps/filemanager/filemanager").instance or require("apps/reader/readerui").instance
    return ui and ui["ink-away"] or nil
end

-- Open the document at `path` in Ink Away, on the page it was left; when it
-- closes, its cover follows the picture Ink Away kept of it. False when Ink
-- Away is not running.
function InkShelf.open(kind, path)
    local m, p = ink(), plugin()
    if not (m and p and p.openCanvas) then return false end
    local q = InkShelf.queues and InkShelf.queues[kind]
    m.Shelf.open(p, path, q)
    return true
end

return InkShelf
