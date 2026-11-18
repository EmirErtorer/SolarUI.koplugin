-- The garden: a poster of everything growing and visiting, with the dew and
-- seeds earned by reading at the top. Tap a plant or an animal and it shows
-- large over a faded garden with its card; tap the book on the table and it
-- opens large with a passage from your own books written in it. The journal
-- and the field notes are pages of their own.

local App = require("solarui/app")
local ArtView = require("solarui/ui/artview")
local Button = require("solarui/ui/button")
local Care = require("solarui/garden/care")
local GardenActions = require("solarui/ui/gardenactions")
local GardenBook = require("solarui/ui/gardenbook")
local GardenCard = require("solarui/ui/gardencard")
local Yuzsuz = require("solarui/garden/yuzsuz")
local GardenClock = require("solarui/ui/gardenclock")
local GardenGive = require("solarui/ui/gardengive")
local GardenGuide = require("solarui/ui/gardenguide")
local GardenPopup = require("solarui/ui/gardenpopup")
local GardenSeason = require("solarui/ui/gardenseason")
local GardenSit = require("solarui/ui/gardensit")
local Season = require("solarui/garden/season")
local GardenView = require("solarui/ui/gardenview")
local Label = require("solarui/ui/label")
local Layout = require("solarui/garden/layout")
local Plaque = require("solarui/garden/plaque")
local LayoutUI = require("solarui/ui/layout")
local Scene = require("solarui/ui/scene")
local SceneEdit = require("solarui/ui/sceneedit")
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
local CARD = { x = 166, y = 640, w = 740, h = 710 }   -- the card under it

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
    self.pose.yuzsuz = Yuzsuz.next(nil, self:queenMood())
    self.quote_at = {}
    self.part = nil   -- the book's part shown: Plaque.HIGHLIGHTS or Plaque.GARDEN (highlights first, when there are any)
end

-- The passages of the book's part shown, dealt once a visit.
function Garden:passages()
    self.quotes = self.quotes or {}
    if not self.part then
        self.quotes[Plaque.HIGHLIGHTS] = Plaque.deal(self.seed, Plaque.HIGHLIGHTS)
        self.part = #self.quotes[Plaque.HIGHLIGHTS] > 0 and Plaque.HIGHLIGHTS or Plaque.GARDEN
    end
    self.quotes[self.part] = self.quotes[self.part] or Plaque.deal(self.seed, self.part)
    return self.quotes[self.part]
end

-- Where the reader is in the part shown: 1 for the first passage.
function Garden:quoteAt()
    self:passages()
    return self.quote_at[self.part] or 1
end

-- The passage shown in the book now, or nil when there are none: the first
-- of this visit's order, or the one the reader moved on to.
function Garden:quote()
    local list = self:passages()
    return list[(self:quoteAt() - 1) % math.max(1, #list) + 1]
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
    -- the garden is spread to the borders and may be stretched by a tweak (layout editor)
    local tweak = SceneEdit.lookup("garden", "garden.field")
    local k = tweak and tweak.sx or 1
    local fx = (scene.spread_by or 1) * k
    App.repaintMoved(el, scene:px((now.x - was.x) * fx), scene:px((now.y - was.y) * k))
end

-- What the queen's next pose depends on: the hour, her hunger and whether
-- the robin is about.
function Garden:queenMood()
    local ctx = { phase = Sky.now() }
    for _i, a in ipairs(State.animals()) do
        if a.def.id == "yuzsuz" then ctx.mood = a.mood end
        if a.def.id == "robin" and a.here then ctx.robin = true end
    end
    return ctx
end

-- Make a small movement: flip an animal between its two poses and repaint
-- just its own patch, or (in the pond) swim or hop it on. The queen chooses
-- her own next pose.
function Garden:move(id)
    local e = State.entry(id)
    if e and e.here == false and (e.resting or e.mood ~= "hiding") then return end   -- asleep: left in peace
    if Layout.PATHS[id] then return self:hop(id) end
    local el = self.sprites[id]
    if not el then return end
    if Yuzsuz.is(id) then self.pose[id] = Yuzsuz.next(self.pose[id], self:queenMood())
    else self.pose[id] = self.pose[id] == "2" and "1" or "2" end
    App.repaint(el)
end

-- A slow tick: one or two of the animals about make a small movement. Every
-- few ticks the screen is redrawn whole to clear the ghosts. It goes on only
-- while the garden is the screen in front.
function Garden:tick()
    self.timer = false
    if not (App.isOpen() and App.current() == self) then return end
    self.ticks = self.ticks + 1
    if self.focus or self.sitting then return self:schedule() end
    local ids = {}
    for id in pairs(self.sprites) do ids[#ids + 1] = id end
    table.sort(ids)
    local moved = {}
    for i = 0, math.min(1, #ids - 1) do
        local id = ids[(self.ticks + i * 3) % #ids + 1]
        moved[id] = true
        self:move(id)
    end
    -- her tail is never still: she moves on every tick
    if self.sprites.yuzsuz and not moved.yuzsuz then self:move("yuzsuz") end
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
    end, function() self:sit() end)
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

-- Sit in the garden: only the garden shows, nothing moves, for a few minutes.
-- A tap ends it early; at the end the reader is asked what next.
function Garden:sit()
    self.sitting = true
    self.sit_id = (self.sit_id or 0) + 1
    local id = self.sit_id
    UIManager:scheduleIn(GardenSit.SECONDS, function()
        if self.sitting and self.sit_id == id then self:endSit(true) end
    end)
    App.update()
end

-- Stop sitting; when the time was up (`done`) ask what next.
function Garden:endSit(done)
    self.sitting = false
    App.update()
    if done and App.isOpen() and App.current() == self then GardenSit.ask(function() self:sit() end) end
end

-- The face in the grass was tapped: say who it was, and what it was worth.
function Garden:peeked()
    local who = State.claimPeek()
    if who then App.toast(string.format(_("%s was peeking out of the grass. A drop of dew for the sharp eyes."), State.name(who))) end
    App.update()
end

-- Once a visit, after the guide is out of the way, ask about a finished book.
function Garden:askAboutBooks()
    if self.asked or self.showcase or self.focus or State.owed() < 1 then return end
    self.asked = true
    UIManager:scheduleIn(.5, function()
        if App.isOpen() and App.current() == self then GardenGive.ask(function() App.update() end) end
    end)
end

-- The heading row: the title, what is in hand and the buttons, from the right:
-- field notes, journal, the clock, the seasons and the guide.
function Garden:heading(scene)
    local th = Theme.get()
    -- the buttons sit in the band between the border and the sky's arch, clear of both
    local top, bottom = Layout.HEAD.top, Layout.HEAD.bottom
    local unit = math.min(th.size.touch / scene.k, bottom - top - 2 * Layout.HEAD.clear)
    local gap = 18
    local y = (top + bottom - unit) / 2
    local function button(id, label, spec, x, on_tap)
        spec.variant, spec.width, spec.on_tap = "icon", scene:px(unit), on_tap
        scene:group("garden." .. id, label, function() scene:place(Button:new(spec), x, y, unit, unit) end)
        return x - unit - gap
    end
    local x = 1017 - unit
    x = button("btn_notes", "Field notes button", { icon = "book" }, x, function() App.push("gardennotes") end)
    x = button("btn_journal", "Journal button", { icon = "notes" }, x, function() App.push("gardenjournal") end)
    x = button("btn_clock", "Clock button", { art = { "garden_clock_icon", tostring(Sky.hour()) }, icon_size = 30 }, x,
        function() GardenClock.open(nil, function() App.update() end) end)
    x = button("btn_season", "Season button", { art = { "garden_season_icon", Season.now() }, icon_size = 30 }, x,
        function() GardenSeason.open(function() App.update() end) end)
    x = button("btn_guide", "Guide button", { label = "?" }, x, function() self:guide() end)
    -- the title, and the dew and seeds beside the buttons, all on the buttons' middle line
    local mid = (top + bottom) / 2
    local title_h = Text.height("display") / scene.k
    scene:group("garden.title", "Garden title", function()
        scene:place(Label:new({ text = _("Garden"), kind = "display" }), 84, mid - title_h / 2, 260)
    end)
    local line = Text.height("small") / scene.k
    local label_w = 130
    local right = x + unit   -- a gap left of the leftmost button
    scene:group("garden.dew", "Dew count", function()
        scene:place(Label:new({ text = string.format(_("Dew %d"), State.dew()), kind = "small", color = "muted", align = "right" }),
            right - label_w, mid - line, label_w)
    end)
    scene:group("garden.seeds", "Seed count", function()
        scene:place(Label:new({ text = string.format(_("Seeds %d"), State.seeds()), kind = "small", color = "muted", align = "right" }),
            right - label_w, mid, label_w)
    end)
end

-- The big picture and its card over the faded garden.
function Garden:focused(scene)
    local oy = math.max(0, (scene.vh - Layout.HEIGHT) / 2)
    scene:backdrop("garden_arch", ARCH.x, ARCH.y + oy, ARCH.w, ARCH.h)
    local e, kind = State.entry(self.focus)
    local ArchFit = require("solarui/ui/archfit")
    local ax, ay = ARCH.x, ARCH.y + oy
    if kind == "plant" then
        local param = GardenView.plantParam(e, false, Sky.now())
        local bx, by, bw, bh = ArchFit.box("plant_" .. self.focus, Layout.PLANTS[self.focus], { param }, ARCH.w, ARCH.h)
        scene:sprite("plant_" .. self.focus, ax + bx, ay + by, bw, bh, param)   -- (over the fade, so the plant is clear)
    else
        local b = Layout.ANIMALS[self.focus]
        local flip = Layout.spread(self.seed)[self.focus].flip
        local function param()
            local pose = self.pose[self.focus] or GardenView.stillPose(State.entry(self.focus))
            return GardenView.animalParam(GardenView.posed(self.focus, pose), flip, false, Sky.now())
        end
        -- (sized for the pose shown and the two the animal moves between, so a step never reaches the arch)
        local poses = { param(), GardenView.animalParam("1", flip, false, Sky.now()), GardenView.animalParam("2", flip, false, Sky.now()) }
        local bx, by, bw, bh = ArchFit.box("animal_" .. self.focus, b, poses, ARCH.w, ARCH.h)
        local fit = { x = ax + bx, y = ay + by, w = bw, h = bh }
        local pic = scene:sprite("animal_" .. self.focus, fit.x, fit.y, fit.w, fit.h, nil, param)
        self.sprites[self.focus] = pic
        scene:touch(fit.x, fit.y, fit.w, fit.h, function()
            -- a tap on the queen's picture shows her in another pose, chosen at random
            if Yuzsuz.is(self.focus) then
                self.pose.yuzsuz = Yuzsuz.shuffle(self.pose.yuzsuz)
                return App.repaint(pic)
            end
            self:move(self.focus)
        end)
    end
    scene:place(GardenCard.build(self.focus, self:actions(self.focus)), CARD.x, CARD.y + oy, CARD.w, CARD.h)
end

-- The open book over the faded garden (see ui/gardenbook.lua): the pages
-- turn through this visit's passages, and "Read on" opens the passage's
-- book at the highlight.
function Garden:book(scene)
    local q = self:quote()
    local count = #self:passages()
    local function turn(by) return function() self.quote_at[self.part] = self:quoteAt() + by; App.update() end end
    GardenBook.place(scene, {
        part = self.part, on_part = function(part) self.part = part; App.update() end,
        quote = q, at = (self:quoteAt() - 1) % math.max(1, count) + 1, count = count,
        on_prev = turn(-1), on_next = turn(1), on_close = function() self.focus = nil; App.update() end,
        on_read = q and q.path and function() require("solarui/actions").openAt(q.path, q) end or nil,
    })
end

-- The garden alone, filling the screen: no heading, no tab bar, nothing
-- animated, and a tap anywhere ends it.
function Garden:stillness(ctx)
    local scene = Scene.make("gardenstill", ctx.w, ctx.h, Layout.HEIGHT)
    scene.screen = "garden"
    self.scene, self.sprites = scene, {}
    GardenView.compose(scene, { seed = self.seed, at = self.at, pose = self.pose })
    scene:touch(0, 0, Layout.WIDTH, scene.vh, function() self:endSit(false) end)
    return scene
end

-- The garden's scene as it will be built on this screen, only to draw its
-- backdrop ahead of time (nil when the first-visit guide has not been seen:
-- that garden looks different). Nothing is shown and no timer is started.
function Garden.warmScene(ctx)
    State.refresh()
    if not State.guideSeen() then return nil end
    local bar = Theme.get().size.tabbar + Theme.px(16)
    local scene = Scene.make("garden", ctx.w, ctx.h - bar, Layout.HEIGHT)
    scene.screen = "garden"
    GardenView.compose(scene, {})
    local g = Garden:new({})
    g.scene = scene
    g:heading(scene)
    local tabs = TabBar.build(App.TABS, nil, function() end)
    local root = LayoutUI.Column:new({ children = { scene, tabs } })
    root:layout(ctx.w, ctx.h)
    -- the vine under the tab bar, which the bar lays out only when it is shown
    local vine = ArtView:new({ name = "root", height = Theme.px(16) })
    vine.w, vine.h = ctx.w, Theme.px(16)
    return scene, { children = { root, vine } }
end

-- What the garden's picture depends on: when it is the same as at the last
-- build, the screen is shown again as it was (the app checks this before building). The minute is in
-- it because plants get thirsty with time.
function Garden:cacheKey(ctx)
    local pose, at = {}, {}
    for id, v in pairs(self.pose) do pose[#pose + 1] = id .. v end
    for id, v in pairs(self.at) do at[#at + 1] = id .. tostring(v) end
    table.sort(pose); table.sort(at)
    return table.concat({ State.version, math.floor(State.clock() / 60), Sky.phase(Sky.hour()), Season.now(), State.weather(), Theme.get().version,
        ctx.w, ctx.h, tostring(self.focus), tostring(self.showcase), tostring(self.sitting), tostring(self.seed), table.concat(pose, ","), table.concat(at, ","),
        tostring(self.part), tostring(self.part and self.quote_at[self.part]), State.owed(), tostring(self.asked), State.dew(), State.progress().vine.days, State.progress().year.books }, "|")
end

-- Build the garden.
function Garden:build(ctx)
    State.refresh()
    if self.focus and self.focus ~= "book" and not State.entry(self.focus) then self.focus = nil end
    if self.sitting then return self:stillness(ctx) end
    local tabs = TabBar.build(App.TABS, nil, function(id) App.go(id) end)
    local bar = Theme.get().size.tabbar + Theme.px(16)
    local scene = Scene.make(self.focus and "gardenfaded" or "garden", ctx.w, ctx.h - bar, Layout.HEIGHT)
    scene.screen = "garden"   -- the faded garden keeps the same tweaks
    self.sprites = {}
    local show = self.showcase
    self.scene = scene
    GardenView.compose(scene, { showcase = show, season = show and "summer" or nil, faded = self.focus ~= nil, pose = self.pose, sprites = self.sprites, seed = self.seed, at = self.at,
        on_tap = not self.focus and function(id) if show then self:guide() else GardenPopup.open(id, inhabitants) end end or nil,
        on_peek = not (self.focus or show) and function() self:peeked() end or nil,
        on_book = not self.focus and function() if show then self:guide() else self.focus = "book"; App.update() end end or nil })
    self:heading(scene)
    if self.focus == "book" then self:book(scene) elseif self.focus then self:focused(scene) end
    self:schedule()
    self:waitForGuide()
    self:askAboutBooks()
    return LayoutUI.Column:new({ children = { scene, tabs } })
end

return Garden
