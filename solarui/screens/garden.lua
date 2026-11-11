-- The garden: a poster of everything growing and visiting, with the dew and
-- seeds earned by reading at the top. Tap a plant or an animal and it shows
-- large over a faded garden with its card; tap the book on the table and it
-- opens large with a passage from your own books written in it. The journal
-- and the field notes are pages of their own.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Care = require("solarui/garden/care")
local GardenActions = require("solarui/ui/gardenactions")
local GardenCard = require("solarui/ui/gardencard")
local GardenClock = require("solarui/ui/gardenclock")
local GardenGuide = require("solarui/ui/gardenguide")
local GardenView = require("solarui/ui/gardenview")
local Label = require("solarui/ui/label")
local Layout = require("solarui/garden/layout")
local Plaque = require("solarui/garden/plaque")
local LayoutUI = require("solarui/ui/layout")
local Scene = require("solarui/ui/scene")
local Screen = require("solarui/screens/screen")
local Sky = require("solarui/garden/sky")
local State = require("solarui/garden/state")
local Text = require("solarui/gfx/text")
local TabBar = require("solarui/ui/tabbar")
local Theme = require("solarui/theme")
local UIManager = require("ui/uimanager")
local _ = require("solarui/gettext")

local Garden = Screen:extend()

local ARCH = { x = 236, y = 118, w = 600, h = 500 }   -- the frame of the big picture
local CARD = { x = 166, y = 640, w = 740, h = 660 }   -- the card under it

local TICK = 45          -- seconds between two small movements
local FULL_EVERY = 10    -- movements between two full refreshes that clear the ghosts

-- Nothing is shown large to begin with, and no animal has moved yet.
function Garden:init()
    self.focus = nil
    self.showcase = not State.guideSeen()   -- the first time, every animal shows and the guide follows
    self.pose = {}
    self.sprites = {}
    self.at = {}   -- where on its path each pond animal is
    self.ticks = 0
    self.seed = os.time()   -- deals the animals a new place and the book a new passage on every visit
    self.quote_at = 1
end

-- The passage shown in the book now, or nil when there are none: the first
-- of this visit's order, or the one the reader moved on to.
function Garden:quote()
    self.quotes = self.quotes or Plaque.deal(self.seed)
    return self.quotes[(self.quote_at - 1) % math.max(1, #self.quotes) + 1]
end

-- Move the frog or the koi on to the next place of its path in the pond,
-- and change its pose, repainting only the two places.
function Garden:hop(id)
    local el, scene = self.sprites[id], self.scene
    if not (el and scene) then return end
    local from = self.at[id] or 1
    local to = from % #Layout.PATHS[id] + 1
    self.at[id] = to
    self.pose[id] = self.pose[id] == "2" and "1" or "2"
    local was, now = Layout.at(Layout.waypoint(id, from), scene.vh), Layout.at(Layout.waypoint(id, to), scene.vh)
    App.repaintMoved(el, scene:px(now.x) - scene:px(was.x), scene:px(now.y) - scene:px(was.y), "fast")
end

-- Make a small movement: flip an animal between its two poses and repaint
-- just its own patch, or (in the pond) swim or hop it on.
function Garden:move(id)
    if Layout.PATHS[id] then return self:hop(id) end
    local el = self.sprites[id]
    if not el then return end
    self.pose[id] = self.pose[id] == "2" and "1" or "2"
    App.repaint(el, "fast")
end

-- A slow tick: one or two of the animals about make a small movement. Every
-- few ticks the screen is redrawn whole to clear the ghosts. It goes on only
-- while the garden is the screen in front.
function Garden:tick()
    self.timer = false
    if not (App.isOpen() and App.current() == self) then return end
    self.ticks = self.ticks + 1
    if self.focus then return self:schedule() end
    local ids = {}
    for id in pairs(self.sprites) do ids[#ids + 1] = id end
    table.sort(ids)
    for i = 0, math.min(1, #ids - 1) do self:move(ids[(self.ticks + i * 3) % #ids + 1]) end
    if self.ticks % FULL_EVERY == 0 then return App.render("full") end
    self:schedule()
end

-- Set the next tick going, once.
function Garden:schedule()
    if self.timer or not App.isOpen() then return end
    self.timer = true
    UIManager:scheduleIn(TICK, function() self:tick() end)
end

-- Back closes the big picture first.
function Garden:onBack()
    if not self.focus then return false end
    self.focus = nil
    App.update()
    return true
end

-- Everything in the garden that can be shown large, plants first.
local function inhabitants()
    local out = {}
    for _i, e in ipairs(State.plants()) do out[#out + 1] = e.def.id end
    for _i, e in ipairs(State.animals()) do
        if e.here or e.mood == Care.HIDING then out[#out + 1] = e.def.id end
    end
    return out
end

-- Show the neighbour of the picture now shown, `delta` places along.
function Garden:step(delta)
    local list = inhabitants()
    for i, id in ipairs(list) do
        if id == self.focus then self.focus = list[(i - 1 + delta) % #list + 1]; break end
    end
    App.update()
end

-- The actions of the card for the picture `id`.
function Garden:actions(id)
    local a = GardenActions.of(id, function() App.update() end)
    a.on_prev = function() self:step(-1) end
    a.on_next = function() self:step(1) end
    a.on_close = function() self.focus = nil; App.update() end
    return a
end

-- Open the guide; when it closes it has been seen, and the garden shows only
-- who has really come.
function Garden:guide()
    if App.overlay() then return end
    GardenGuide.open(function()
        State.markGuide()
        self.showcase = false
        App.update()
    end)
end

-- On the first visit, open the guide after ten seconds of looking around.
function Garden:waitForGuide()
    if not self.showcase or self.guide_timer then return end
    self.guide_timer = true
    UIManager:scheduleIn(10, function()
        self.guide_timer = false
        if self.showcase and App.isOpen() and App.current() == self then self:guide() end
    end)
end

-- The heading row: the title, what is in hand and the buttons, from the right:
-- field notes, journal, the clock and the guide.
function Garden:heading(scene)
    local th = Theme.get()
    local unit = th.size.touch / scene.k
    local gap = 12
    local function button(spec, x, on_tap)
        spec.variant, spec.width, spec.on_tap = "icon", th.size.touch, on_tap
        scene:place(Button:new(spec), x, 34, unit, unit)
        return x - unit - gap
    end
    local x = 962 - unit
    x = button({ icon = "book" }, x, function() App.push("gardennotes") end)
    x = button({ icon = "notes" }, x, function() App.push("gardenjournal") end)
    x = button({ art = { "garden_clock_icon", tostring(Sky.hour()) }, icon_size = 30 }, x, function() GardenClock.open(nil, function() App.update() end) end)
    x = button({ label = "?" }, x, function() self:guide() end)
    scene:place(Label:new({ text = _("Garden"), kind = "display" }), 118, 38, 260)
    local line = Text.height("small") / scene.k
    scene:place(Label:new({ text = string.format(_("Dew %d"), State.dew()), kind = "small", color = "muted", align = "right" }), x - 60, 56 - line / 2, 100 + 60 - 12)
    scene:place(Label:new({ text = string.format(_("Seeds %d"), State.seeds()), kind = "small", color = "muted", align = "right" }), x - 60, 56 + line / 2, 100 + 60 - 12)
end

-- The big picture and its card over the faded garden.
function Garden:focused(scene)
    local oy = math.max(0, (scene.vh - Layout.HEIGHT) / 2)
    scene:backdrop("garden_arch", ARCH.x, ARCH.y + oy, ARCH.w, ARCH.h)
    local e, kind = State.entry(self.focus)
    local fit = { x = ARCH.x + 60, y = ARCH.y + oy + 100, w = ARCH.w - 120, h = ARCH.h - 110 }
    if kind == "plant" then
        scene:backdrop("plant_" .. self.focus, fit.x, fit.y, fit.w, fit.h, GardenView.plantParam(e, false, Sky.now()))
    else
        local b = Layout.ANIMALS[self.focus]
        local flip = Layout.spread(self.seed)[self.focus].flip
        local k = math.min(fit.w / b.w, fit.h / b.h)
        local pic = scene:sprite("animal_" .. self.focus, fit.x + (fit.w - b.w * k) / 2, fit.y + (fit.h - b.h * k) / 2, b.w * k, b.h * k, nil,
            function() return GardenView.animalParam(self.pose[self.focus] or "1", flip, false, Sky.now()) end)
        self.sprites[self.focus] = pic
        scene:touch(fit.x, fit.y, fit.w, fit.h, function() self:move(self.focus) end)
    end
    scene:place(GardenCard.build(self.focus, self:actions(self.focus)), CARD.x, CARD.y + oy, CARD.w, CARD.h)
end

-- The open book over the faded garden: a passage from the reader's books on
-- its right page and where it comes from on its left, and a button for
-- another one.
function Garden:book(scene)
    local oy = math.max(0, (scene.vh - Layout.HEIGHT) / 2)
    local art = Layout.BOOK_ART
    local box = { x = 156, y = 150 + oy, w = 760 }
    box.h = box.w * art.h / art.w
    local k = box.w / art.w
    scene:backdrop("garden_book", box.x, box.y, box.w, box.h, Sky.now())
    local function page(side) local p = Layout.BOOKPAGE[side]; return box.x + p.x * k, box.y + p.y * k, p.w * k, p.h * k end
    local q = self:quote()
    local lines = function(h) return math.max(1, math.floor(scene:px(h) / Text.height("body"))) end
    local rx, ry, rw, rh = page("right")
    scene:place(Label:new({ text = q and ("\u{201C}" .. q.text .. "\u{201D}") or _("Nothing is written in this book yet. Highlight a passage in one of your books and it will appear here."),
        kind = "body", lines = lines(rh) }), rx, ry, rw, rh)
    if q then
        local lx, ly, lw, lh = page("left")
        scene:place(LayoutUI.Column:new({ gap = scene:px(8), children = {
            Label:new({ text = q.title or "", kind = "heading", lines = 3 }),
            Label:new({ text = q.author or "", kind = "small", color = "muted", lines = 2 }),
        } }), lx, ly, lw, lh)
    end
    local th = Theme.get()
    scene:place(LayoutUI.Row:new({ gap = th.space.s, children = {
        Button:new({ label = _("Another passage"), variant = "primary", grow = true, disabled = not q,
            on_tap = function() self.quote_at = self.quote_at + 1; App.update() end }),
        Button:new({ label = _("Back to the garden"), grow = true, on_tap = function() self.focus = nil; App.update() end }),
    } }), 166, box.y + box.h + 30, 740)
end

-- Build the garden.
function Garden:build(ctx)
    State.refresh()
    if self.focus and self.focus ~= "book" and not State.entry(self.focus) then self.focus = nil end
    local tabs = TabBar.build(App.TABS, nil, function(id) App.go(id) end)
    local bar = Theme.get().size.tabbar + Theme.px(16)
    local scene = Scene.make(self.focus and "gardenfaded" or "garden", ctx.w, ctx.h - bar, Layout.HEIGHT)
    self.sprites = {}
    local show = self.showcase
    self.scene = scene
    GardenView.compose(scene, { showcase = show, faded = self.focus ~= nil, pose = self.pose, sprites = self.sprites, seed = self.seed, at = self.at,
        on_tap = not self.focus and function(id) if show then self:guide() else self.focus = id; App.update() end end or nil,
        on_book = not self.focus and function() if show then self:guide() else self.focus = "book"; App.update() end end or nil })
    self:heading(scene)
    if self.focus == "book" then self:book(scene) elseif self.focus then self:focused(scene) end
    self:schedule()
    self:waitForGuide()
    return LayoutUI.Column:new({ children = { scene, tabs } })
end

return Garden
