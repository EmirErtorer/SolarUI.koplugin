-- The garden: a poster of everything growing and visiting, with the dew and
-- seeds earned by reading at the top. Tap a plant or an animal and it shows
-- large over a faded garden with its card.
-- The journal and the field notes are pages of their own.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Care = require("solarui/garden/care")
local GardenCard = require("solarui/ui/gardencard")
local GardenView = require("solarui/ui/gardenview")
local Label = require("solarui/ui/label")
local Layout = require("solarui/garden/layout")
local LayoutUI = require("solarui/ui/layout")
local Plaque = require("solarui/garden/plaque")
local Scene = require("solarui/ui/scene")
local Screen = require("solarui/screens/screen")
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
    self.pose = {}
    self.sprites = {}
    self.ticks = 0
    self.seed = os.time()   -- deals the animals a new place on every visit
end

-- Flip an animal between its two poses and repaint just its own patch.
function Garden:move(id)
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

-- Say what an action did, or why it could not be done.
local function say(ok, why, done)
    if ok then return App.toast(done) end
    App.toast(({ dew = _("Not enough dew. It comes from the pages you read."), dry = _("This one needs no watering."),
        fresh = _("It has only just had a drink."), full = _("It has only just eaten."),
        seed = _("No seeds. Finish a book, or cut back a plant that has gone to seed."), bloom = _("It is in bloom already."), none = _("Not in the garden.") })[why] or "")
end

-- The actions of the card for the picture `id`.
function Garden:actions(id)
    return {
        on_water = function() local ok, why = State.water(id); say(ok, why, string.format(_("%s has had a drink."), State.name(id))); App.update() end,
        on_feed = function() local ok, why = State.feed(id); say(ok, why, string.format(_("%s has eaten."), State.name(id))); App.update() end,
        on_collect = function() State.collect(id); App.toast(_("Cut back. You have a seed.")); App.update() end,
        on_rename = function() App.input(_("A name for it"), State.rec(id).nick or "", function(text) State.rename(id, text); App.update() end, _("Save")) end,
        on_sow = function() local ok, why = State.sow(id); say(ok, why, string.format(_("%s is in bloom."), State.name(id))); App.update() end,
        on_prev = function() self:step(-1) end, on_next = function() self:step(1) end,
        on_close = function() self.focus = nil; App.update() end,
    }
end

-- The heading row: the title, what is in hand and the two pages.
function Garden:heading(scene)
    local th = Theme.get()
    local unit = th.size.touch / scene.k
    scene:place(Label:new({ text = _("Garden"), kind = "display" }), 118, 38, 380)
    local x0 = 962 - 2 * unit - 12
    scene:place(Label:new({ text = string.format(_("Dew %d · Seeds %d"), State.dew(), State.seeds()), kind = "small", color = "muted", align = "right" }), x0 - 330, 52, 318)
    scene:place(Button:new({ icon = "notes", variant = "icon", width = th.size.touch, on_tap = function() App.push("gardenjournal") end }), x0, 34, unit, unit)
    scene:place(Button:new({ icon = "book", variant = "icon", width = th.size.touch, on_tap = function() App.push("gardennotes") end }), 962 - unit, 34, unit, unit)
end

-- The favourite passage on the plaque.
function Garden:plaque(scene)
    local q = Plaque.today()
    local b = Layout.at(Layout.PROPS.plaque, scene.vh)
    scene:place(Label:new({ text = q and ("\u{201C}" .. q.text .. "\u{201D}") or _("Highlight a passage in a book and it is carved here."), kind = "micro",
        color = "ink", align = "center", lines = math.max(1, math.floor(scene:px(b.h - 36) / Text.height("micro"))) }), b.x + 14, b.y + 30, b.w - 28, b.h - 36)
end

-- The big picture and its card over the faded garden.
function Garden:focused(scene)
    local oy = math.max(0, (scene.vh - Layout.HEIGHT) / 2)
    scene:backdrop("garden_arch", ARCH.x, ARCH.y + oy, ARCH.w, ARCH.h)
    local e, kind = State.entry(self.focus)
    local fit = { x = ARCH.x + 60, y = ARCH.y + oy + 100, w = ARCH.w - 120, h = ARCH.h - 110 }
    if kind == "plant" then
        scene:backdrop("plant_" .. self.focus, fit.x, fit.y, fit.w, fit.h, GardenView.plantParam(e))
    else
        local b = Layout.ANIMALS[self.focus]
        local flip = Layout.spread(self.seed)[self.focus].flip
        local k = math.min(fit.w / b.w, fit.h / b.h)
        local pic = scene:sprite("animal_" .. self.focus, fit.x + (fit.w - b.w * k) / 2, fit.y + (fit.h - b.h * k) / 2, b.w * k, b.h * k, nil,
            function() return GardenView.animalParam(self.pose[self.focus] or "1", flip) end)
        self.sprites[self.focus] = pic
        scene:touch(fit.x, fit.y, fit.w, fit.h, function() self:move(self.focus) end)
    end
    scene:place(GardenCard.build(self.focus, self:actions(self.focus)), CARD.x, CARD.y + oy, CARD.w, CARD.h)
end

-- Build the garden.
function Garden:build(ctx)
    State.refresh()
    if self.focus and not State.entry(self.focus) then self.focus = nil end
    local tabs = TabBar.build(App.TABS, nil, function(id) App.go(id) end)
    local bar = Theme.get().size.tabbar + Theme.px(16)
    local scene = Scene.make(self.focus and "gardenfaded" or "garden", ctx.w, ctx.h - bar, Layout.HEIGHT)
    self.sprites = {}
    GardenView.compose(scene, { faded = self.focus ~= nil, pose = self.pose, sprites = self.sprites, seed = self.seed,
        on_tap = not self.focus and function(id) self.focus = id; App.update() end or nil })
    self:heading(scene)
    if self.focus then self:focused(scene) else self:plaque(scene) end
    self:schedule()
    return LayoutUI.Column:new({ children = { scene, tabs } })
end

return Garden
