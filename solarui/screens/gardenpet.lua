-- The page of the companion for life: their picture, name and what they are
-- saying, the bond and how far it has come, their memories (told as pages are
-- read together, the next one hidden), the diary of what they shared, and the
-- buttons to rename them or say goodbye. When there is no companion, the page
-- shows the orchard (who lived with the reader before) and how to choose one.

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Frame = require("solarui/screens/frame")
local GardenAdopt = require("solarui/ui/gardenadopt")
local GardenPopup = require("solarui/ui/gardenpopup")
local Label = require("solarui/ui/label")
local Layout = require("solarui/ui/layout")
local Pet = require("solarui/garden/pet")
local Progress = require("solarui/ui/progress")
local Screen = require("solarui/screens/screen")
local State = require("solarui/garden/state")
local Theme = require("solarui/theme")
local Voice = require("solarui/garden/voice")
local _ = require("solarui/gettext")

local GardenPet = Screen:extend()

-- Start on the first page.
function GardenPet:init() self.page = 1 end

-- A short date as "13 Nov".
local function date(t)
    return os.date("%d %b", t)
end

-- A small heading over a part of the page.
local function heading(text)
    return Label:new({ text = text, kind = "label", color = "muted" })
end

-- The bond: its level name, how far the next level is, and the pages together.
local function bond()
    local th = Theme.get()
    local pages = Pet.pages()
    local level, into, need = Pet.level(pages)
    local note = need and string.format(_("%d pages to %s"), need - into, Pet.LEVEL_NAMES[level + 1]) or _("The bond cannot go deeper.")
    return Layout.Column:new({ gap = th.space.xs, children = {
        Label:new({ text = string.format(_("Level %d: %s"), level, Pet.LEVEL_NAMES[level]), kind = "heading" }),
        Progress:new({ value = need and into / need or 1 }),
        Label:new({ text = string.format("%s \u{B7} %s", string.format(_.n("%d page together", "%d pages together", pages), pages),
            string.format(_.n("%d day", "%d days", Pet.days()), Pet.days())), kind = "small", color = "muted" }),
        Label:new({ text = note, kind = "small", color = "muted" }),
    } })
end

-- The memories: the ones told, then the next one hidden with the pages it asks.
local function memories(p)
    local th = Theme.get()
    local rows = {}
    local pages = Pet.pages()
    local nexts
    for _i, b in ipairs(Voice.beats(p.id)) do
        if p.beats[b.id] then
            rows[#rows + 1] = Layout.Column:new({ gap = 2, children = {
                Label:new({ text = b.title, kind = "body" }),
                Label:new({ text = Voice.render(b.text), kind = "small", color = "muted", lines = 4 }),
            } })
        elseif not nexts then
            nexts = b
        end
    end
    if nexts then
        rows[#rows + 1] = Label:new({ text = string.format(_("Another memory in %d pages."), math.max(1, nexts.at - pages)), kind = "small", color = "muted" })
    end
    if #rows == 0 then rows[1] = Label:new({ text = _("Memories come as you read together."), kind = "small", color = "muted" }) end
    return Layout.Column:new({ gap = th.space.s, children = rows })
end

-- The diary: newest first, a date and a line each.
local function diary(p)
    local th = Theme.get()
    local rows = {}
    for i = #p.diary, math.max(1, #p.diary - 11), -1 do
        local d = p.diary[i]
        rows[#rows + 1] = Layout.Row:new({ gap = th.space.m, children = {
            Label:new({ text = date(d.at), kind = "small", color = "muted", width = Theme.px(64) }),
            Label:new({ text = d.text, kind = "small", lines = 2, grow = true }),
        } })
    end
    return Layout.Column:new({ gap = th.space.xs, children = rows })
end

-- The orchard: those who lived with the reader before, who and for how long.
local function orchard()
    local th = Theme.get()
    local rows = {}
    for _i, o in ipairs(Pet.orchard()) do
        rows[#rows + 1] = Layout.Row:new({ gap = th.space.m, on_tap = function() require("solarui/ui/gardenreturn").ask(o.id, function() App.update() end) end, children = {
            Label:new({ text = o.name, kind = "body", grow = true }),
            Label:new({ text = string.format("%s \u{B7} %s", string.format(_.n("%d day", "%d days", o.days), o.days),
                string.format(_.n("%d page", "%d pages", o.pages), o.pages)), kind = "small", color = "muted" }),
        } })
    end
    return Layout.Column:new({ gap = th.space.xs, children = rows })
end

-- Build the page.
function GardenPet:build()
    State.refresh()
    local th = Theme.get()
    local p = Pet.get()
    local body = {}
    if p then
        local e, kind = State.entry(p.id)
        Pet.refresh(Voice.beats(p.id))
        local line = Voice.current()
        body[#body + 1] = Layout.Column:new({ align = "center", gap = th.space.s, children = {
            e and GardenPopup.picture(p.id, e, kind) or Layout.Spacer:new({}),
            Label:new({ text = State.name(p.id), kind = "display", align = "center" }),
            line and Label:new({ text = line, kind = "body", align = "center", lines = 4 }) or Layout.Spacer:new({}),
        } })
        body[#body + 1] = bond()
        local row = {}
        -- the queen's name cannot be changed
        if p.id ~= "yuzsuz" then
            row[#row + 1] = Button:new({ label = _("Rename"), icon = "edit", icon_size = 18, grow = true, on_tap = function()
                App.input(_("Choose a name"), State.rec(p.id).nick or "", function(text) Pet.rename(text); App.update() end, _("Save"))
            end })
        end
        row[#row + 1] = Button:new({ label = _("Say goodbye"), grow = true, on_tap = function() GardenAdopt.goodbye(function() App.update() end) end })
        body[#body + 1] = Layout.Row:new({ gap = th.space.s, children = row })
        if Pet.talks() then
            body[#body + 1] = heading(_("Memories"))
            body[#body + 1] = memories(p)
        end
        body[#body + 1] = heading(_("Diary"))
        body[#body + 1] = diary(p)
    else
        body[#body + 1] = Label:new({ text = _("No companion yet. Open a plant or an animal in the garden and choose Make them my companion. A companion stays for life."),
            kind = "body", lines = 4 })
    end
    if #Pet.orchard() > 0 then
        body[#body + 1] = heading(_("The orchard"))
        body[#body + 1] = Label:new({ text = _("Tap one to ask them to come back."), kind = "small", color = "muted" })
        body[#body + 1] = orchard()
    end
    return Frame.page({ screen = self, title = p and State.name(p.id) or _("Companion"), plant = "sprout", tab = "garden",
        body = Frame.paged(self, body, _("Page")) })
end

return GardenPet
