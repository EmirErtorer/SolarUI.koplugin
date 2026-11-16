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
local OutsideCard = require("solarui/ui/outsidecard")
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
function GardenNotes:init(params) self.page, self.tab = 1, params and params.tab or "meet" end

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
        local name = require("solarui/format").date("%B", os.time({ year = 2001, month = m, day = 1 }))
        items[#items + 1] = Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
            Label:new({ text = m == now and string.format(_("%s · now"), name) or name, kind = "heading" }),
            Label:new({ text = string.format(_("In flower: %s"), names(flowers)), kind = "small", lines = 3 }),
            Label:new({ text = string.format(_("Asleep: %s"), names(asleep)), kind = "small", color = "muted", lines = 2 }),
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

local KIND = OutsideCard.KIND

-- One thing to do this week: a round box to tick, its kind and the words beside it,
-- and under a ticked one the reader's own line (or a button to add one).
local function thing(k, item)
    local th = Theme.get()
    local words = { Label:new({ text = KIND[item.kind] or "", kind = "micro", color = "muted" }),
        Label:new({ text = item.text, kind = "body", lines = 5, color = item.done and "muted" or nil }) }
    if item.first and item.last then
        words[#words + 1] = Label:new({ text = string.format(_("Last year: %s."), os.date("%d %B", item.last)), kind = "small", lines = 2 })
    elseif item.first then
        words[#words + 1] = Label:new({ text = string.format(_("Remember the date of %s."), item.first), kind = "small", color = "muted", lines = 2 })
    end
    if item.done then
        words[#words + 1] = OutsideCard.noteButton(item, function() OutsideCard.writeNote(k, item, App.update) end)
        if item.note then words[#words + 1] = Label:new({ text = "\u{201C}" .. item.note .. "\u{201D}", kind = "small", lines = 3 }) end
    end
    return Layout.Row:new({ gap = th.space.m, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
        Button:new({ variant = "icon", icon = item.done and "check" or nil, label = item.done and nil or " ", width = th.size.touch,
            on_tap = function() OutsideCard.tick(k, App.update) end }),
        Layout.Column:new({ gap = th.space.xs, grow = true, children = words }),
    } })
end

-- The Outside tab: this week's three things with a box to tick each, the
-- firsts of the year, then the log of everything ever done outdoors, kept for good.
local function outside()
    local th = Theme.get()
    local items = { Layout.Column:new({ gap = th.space.xs, pad = { 0, 0, th.space.s, 0 }, children = {
        Label:new({ text = _("This week"), kind = "heading" }),
        Label:new({ text = _("Three small things to do outdoors: one to look at, one to listen to and one to do. Tick each one when done. Nothing is earned, and nothing is lost if you skip a week."), kind = "small", color = "muted", lines = 4 }),
    } }) }
    for k, item in ipairs(State.outsideWeek()) do items[#items + 1] = thing(k, item) end
    local firsts = State.outsideFirsts()
    if #firsts > 0 then
        items[#items + 1] = Layout.Column:new({ gap = th.space.xs, pad = { th.space.m, 0, th.space.xs, 0 }, children = {
            Label:new({ text = _("Firsts"), kind = "heading" }),
            Label:new({ text = _("The dates you saw or heard something for the first time that year. Next year the garden will remind you."), kind = "small", color = "muted", lines = 3 }),
        } })
        for _i, f in ipairs(firsts) do
            -- (the first letter in capitals, whole even when it takes several bytes)
            local first, rest = f.label:match("^([%z\1-\127\194-\244][\128-\191]*)(.*)$")
            local words = { Label:new({ text = require("solarui/i18n/case").upper(first or "", require("solarui/gettext").language()) .. (rest or ""), kind = "body", lines = 2 }) } -- i18n: keep
            if f.note then words[#words + 1] = Label:new({ text = "\u{201C}" .. f.note .. "\u{201D}", kind = "small", lines = 2 }) end
            items[#items + 1] = Layout.Row:new({ gap = th.space.m, pad = { th.space.xs, 0, th.space.xs, 0 }, children = {
                Label:new({ text = os.date("%d %b %Y", f.t), kind = "small", color = "muted", width = Theme.px(96) }),
                Layout.Column:new({ gap = 0, grow = true, children = words }),
            } })
        end
    end
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
            Layout.Column:new({ gap = 0, grow = true, children = e.note and {
                Label:new({ text = e.text, kind = "body", lines = 3 }),
                Label:new({ text = "\u{201C}" .. e.note .. "\u{201D}", kind = "small", lines = 2 }),
            } or { Label:new({ text = e.text, kind = "body", lines = 3 }) } }),
        } })
    end
    return items
end

-- The About tab: seeds given back, why "they", and two books to read.
local function about()
    local th = Theme.get()
    local function block(title, text)
        return Layout.Column:new({ gap = 0, pad = { th.space.xs, 0, th.space.s, 0 }, children = {
            Label:new({ text = title, kind = "heading_bold" }),
            Label:new({ text = text, kind = "body", lines = 10 }),
        } })
    end
    return {
        block(_("Given back"), string.format(_.n("%d seed left in the wild edge.", "%d seeds left in the wild edge.", State.given()), State.given())),
        block(_("Why \"they\""), _("Plants and animals here are \"they\" and \"who\", never \"it\". Words steer attention. Call a robin a thing and the robin turns into scenery; call the robin someone and you start to notice where they are going and what they want. The garden speaks about the neighbours the way you would speak about people you are fond of.")),
        block(_("A book to read"), _("Braiding Sweetgrass, by Robin Wall Kimmerer. She is a botanist and a member of the Citizen Potawatomi Nation, and she writes about strawberries, maples, sweetgrass, black ash, beans and squash with a scientist's eye and the warmth of someone who has loved these plants all her life. The book is about gratitude, about taking only what you need and giving something back, and about the living world as a gift and not a stockpile. Read a chapter by a window with something green in sight, and the lawn outside will never look quite the same.")),
        block(_("Another book to read"), _("The Overstory, by Richard Powers. A novel in which trees are the main characters and people only slowly learn to notice them: nine lives that a chestnut, a mulberry, a banyan and a redwood quietly bend toward one another, until they meet in the fight for the last old forests. The novel won the Pulitzer Prize, and the story does what this garden tries to do in a small way: the living world becomes someone rather than scenery. Trees here talk to each other through their roots, remember, and take their time; you may never walk under one again without wondering what they are saying.")),
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
