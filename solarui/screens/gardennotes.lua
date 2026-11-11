-- The field notes: the garden's almanac in five tabs. Meet lists everyone the
-- garden can have and opens a page for each one met; Year goes month by
-- month through what flowers and who sleeps; Links shows who depends on
-- whom among those in the garden; Outside gives a thing to do outdoors each
-- week; About holds the count of seeds given back,
-- why the garden says "they", and a book to read.

local Almanac = require("solarui/garden/almanac")
local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Cast = require("solarui/garden/cast")
local Frame = require("solarui/screens/frame")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local ListRow = require("solarui/ui/listrow")
local Screen = require("solarui/screens/screen")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local Visitors = require("solarui/garden/visitors")
local _ = require("solarui/gettext")

local GardenNotes = Screen:extend()

local TABS = { { "meet", _("Meet") }, { "calendar", _("Year") }, { "links", _("Links") }, { "outside", _("Outside") }, { "about", _("About") } }

-- Start on the first page of the first tab.
function GardenNotes:init() self.page, self.tab = 1, "meet" end

-- How well someone is known, in a word.
local function knowing(tier)
    return ({ _("Not met"), _("Seen"), _("Known"), _("A friend") })[tier + 1]
end

-- A row for each plant and animal; a tap opens the page of anyone met.
local function meet()
    local items = {}
    for _i, def in ipairs(Cast.ids()) do
        local d = Cast.find(def)
        local tier = Almanac.tier(d.id)
        items[#items + 1] = ListRow.build({ title = tier > 0 and State.name(d.id) or d.en, meta = tier > 0 and d.latin or Visitors.hint(d),
            value = knowing(tier), dim = tier == 0, on_tap = tier > 0 and function() App.push("gardenpage", { id = d.id }) end or nil })
    end
    return items
end

-- A list of names as a sentence ("Crocus, Pansy"), or "-" when empty.
local function names(ids)
    local out = {}
    for _i, id in ipairs(ids) do out[#out + 1] = Cast.find(id).en end
    return #out > 0 and table.concat(out, ", ") or "-"
end

-- One block for each month: what flowers and who sleeps.
local function calendar()
    local items, th = {}, Theme.get()
    local now = tonumber(os.date("%m")) or 1
    for m = 1, 12 do
        local flowers, asleep = Almanac.month(m)
        local name = os.date("%B", os.time({ year = 2001, month = m, day = 1 }))
        items[#items + 1] = Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
            Label:new({ text = m == now and (name .. " · " .. _("now")) or name, kind = "heading" }),
            Label:new({ text = _("In flower: ") .. names(flowers), kind = "small", lines = 3 }),
            Label:new({ text = _("Asleep: ") .. names(asleep), kind = "small", color = "muted", lines = 2 }),
        } })
    end
    return items
end

-- A block for each link between two in the garden.
local function links()
    local items, th = {}, Theme.get()
    for _i, l in ipairs(Almanac.web()) do
        items[#items + 1] = Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
            Label:new({ text = Cast.find(l[1]).en .. " · " .. Cast.find(l[2]).en, kind = "heading" }),
            Label:new({ text = l[3], kind = "small", lines = 3 }),
        } })
    end
    if #items == 0 then items[1] = Label:new({ text = _("Nothing is linked yet. As more arrive, the web grows."), kind = "body", color = "muted", lines = 2 }) end
    return items
end

-- A line for how many things have been done outdoors: the highest milestone passed.
local function milestone(done)
    local lines = { { 100, _("A hundred. The outdoors knows you by now.") }, { 50, _("Fifty things noticed and done. That is a lot of looking.") },
        { 25, _("Twenty-five. You are really looking now.") }, { 10, _("Ten things done outside. That is a habit starting.") }, { 1, _("The first one is in the log.") } }
    for _i, m in ipairs(lines) do
        if done >= m[1] then return m[2] end
    end
end

-- One thing to do this week: a round box to tick and the words beside it.
local function thing(k, item)
    local th = Theme.get()
    return Layout.Row:new({ gap = th.space.m, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
        Button:new({ variant = "icon", icon = item.done and "check" or nil, label = item.done and nil or " ", width = th.size.touch,
            on_tap = function()
                local on = State.toggleOutside(k)
                App.toast(on and _("Ticked off, and kept in your log.") or _("Unticked."))
                App.update()
            end }),
        Label:new({ text = item.text, kind = "body", lines = 4, grow = true, color = item.done and "muted" or nil }),
    } })
end

-- The Outside tab: this week's three things with a box to tick each, then
-- the log of everything ever done outdoors, kept for good.
local function outside()
    local th = Theme.get()
    local items = { Layout.Column:new({ gap = th.space.xs, pad = { 0, 0, th.space.s, 0 }, children = {
        Label:new({ text = _("This week"), kind = "heading" }),
        Label:new({ text = _("Three small things to do outdoors: one to look at, one to listen to and one to do. Tick each one when done. Nothing is earned, and nothing is lost if you skip a week."), kind = "small", color = "muted", lines = 4 }),
    } }) }
    for k, item in ipairs(State.outsideWeek()) do items[#items + 1] = thing(k, item) end
    local totals, log = State.outsideTotals(), State.outsideLog()
    local head = { Label:new({ text = _("Your log"), kind = "heading" }) }
    if totals.done == 0 then
        head[#head + 1] = Label:new({ text = _("Nothing here yet. Everything you tick off this week is kept here, so you can look back on everything."), kind = "small", color = "muted", lines = 3 })
    else
        head[#head + 1] = Label:new({ text = string.format(_.n("%d thing done outdoors since %s.", "%d things done outdoors since %s.", totals.done), totals.done, os.date("%d %b %Y", totals.since))
            .. (totals.full_weeks > 0 and (" " .. string.format(_.n("%d week with all three done.", "%d weeks with all three done.", totals.full_weeks), totals.full_weeks)) or ""), kind = "small", lines = 3 })
        head[#head + 1] = Label:new({ text = milestone(totals.done), kind = "small", color = "muted", lines = 2 })
    end
    items[#items + 1] = Layout.Column:new({ gap = th.space.xs, pad = { th.space.m, 0, th.space.xs, 0 }, children = head })
    for _i, e in ipairs(log) do
        items[#items + 1] = Layout.Row:new({ gap = th.space.m, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
            Label:new({ text = os.date("%d %b", e.t), kind = "small", color = "muted", width = Theme.px(64) }),
            Label:new({ text = e.text, kind = "body", lines = 3, grow = true }),
        } })
    end
    return items
end

-- The About tab: seeds given back, why "they", and a book to read.
local function about()
    local th = Theme.get()
    local function block(title, text)
        return Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.s, 0 }, children = {
            Label:new({ text = title, kind = "heading" }),
            Label:new({ text = text, kind = "body", lines = 10 }),
        } })
    end
    return {
        block(_("Given back"), string.format(_.n("%d seed left in the wild edge.", "%d seeds left in the wild edge.", State.given()), State.given())),
        block(_("Why \"they\""), _("Plants and animals here are \"they\" and \"who\", never \"it\". Words steer attention. Call a robin a thing and the robin turns into scenery; call the robin someone and you start to notice where they are going and what they want. The garden speaks about the neighbours the way you would speak about people you are fond of.")),
        block(_("A book to read"), _("Braiding Sweetgrass, by Robin Wall Kimmerer. She is a botanist and a member of the Citizen Potawatomi Nation, and she writes about strawberries, maples, sweetgrass, black ash, beans and squash with a scientist's eye and the warmth of someone who has loved these plants all her life. The book is about gratitude, about taking only what you need and giving something back, and about the living world as a gift and not a stockpile. Read a chapter by a window with something green in sight, and the lawn outside will never look quite the same.")),
    }
end

-- The items of a tab. A tab that fails to build shows a plain note instead of
-- taking the screen down, and the error goes to the log.
local function safely(tab, build)
    local ok, items = pcall(build)
    if ok then return items end
    require("logger").warn("SolarUI field notes, tab " .. tab .. ": " .. tostring(items))
    return { Label:new({ text = _("Something went wrong showing this page. Please try another tab."), kind = "body", color = "muted", lines = 3 }) }
end

-- Build the page.
function GardenNotes:build()
    State.refresh()
    local th = Theme.get()
    local chips = {}
    for _i, t in ipairs(TABS) do
        chips[#chips + 1] = Button:new({ label = t[2], variant = self.tab == t[1] and "chip_on" or "chip", grow = true,
            on_tap = function() self.tab, self.page = t[1], 1; App.update() end })
    end
    local build = ({ meet = meet, calendar = calendar, links = links, outside = outside, about = about })[self.tab]
    local items = safely(self.tab, build)
    local body = Layout.Column:new({ gap = th.space.s, children = { Layout.Row:new({ gap = th.space.s, children = chips }), Frame.paged(self, items, _("Page")) } })
    return Frame.page({ screen = self, title = _("Field notes"), plant = "highlights", body = body })
end

return GardenNotes
