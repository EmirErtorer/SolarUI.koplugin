-- The garden journal in words: each saved event (see State.journal) becomes
-- one dated line in a plain, slightly dry voice, with a few ways of saying
-- it chosen by the event's time so the page does not repeat itself.

local Cast = require("solarui/garden/cast")
local Season = require("solarui/garden/season")
local State = require("solarui/garden/state")
local _ = require("solarui/gettext")

local Journal = {}

-- The ways to say each event; %s is the name of the plant or animal.
local LINES = {
    sown = { _("%s was coaxed into bloom with a seed."), _("A seed was spent on %s, and the flowers came at once."), _("%s took the hint and bloomed.") },
    sprout = { _("%s came up."), _("%s put out the first leaves."), _("%s sprouted, with no fuss.") },
    bud = { _("%s made a bud."), _("%s is thinking about flowering."), _("%s has a bud and a plan.") },
    bloom = { _("%s bloomed."), _("%s opened, and looked pleased."), _("%s is in flower.") },
    seedhead = { _("%s has gone to seed."), _("%s let the seeds ripen."), _("%s is done flowering, and can be cut back.") },
    wilt = { _("%s wilted from thirst."), _("%s drooped, plainly and on purpose."), _("%s ran dry and gave up for now.") },
    found = { _("%s found the garden."), _("%s arrived, uninvited and welcome."), _("%s turned up, as if the garden had always been home.") },
    hide = { _("%s went into hiding, hungry."), _("%s was not seen all day, and is hungry."), _("%s has hidden away until someone brings a meal.") },
    visit = { _("%s visited %s."), _("%s spent the afternoon at %s."), _("%s called on %s, and left pollen behind.") },
    thanks = { _("You read %d pages. %s drank from them."), _("%d pages came in, and %s was watered by them."), _("%d pages today, and %s has them to thank.") },
    back_seeds = { _("%s was cut back, and the seeds were kept."), _("%s was tidied, and a seed saved."), _("%s was cut back, and the seeds went into the jar.") },
    birds = { _("The seeds of %s were left for the birds."), _("%s was left standing for the birds."), _("The birds found the seeds of %s.") },
    scatter = { _("The seeds of %s were scattered in the beds."), _("%s dropped a few seeds a little further along."), _("Some seeds of %s were thrown to the wind.") },
    gave = { _("A seed was left in the wild edge."), _("A seed went back to the wild."), _("Something was given back to the wild edge.") },
    rain = { _("Rain came in the night, and the beds drank."), _("Rain fell, and the watering can stayed in the shed."), _("A day of rain. Everything was given half a drink.") },
    snow = { _("Snow lay on the beds."), _("Snow came, and the garden went quiet."), _("The first snow settled on the lawn.") },
    outside = { _("You went outside and looked, and ticked the week off."), _("A week's walk was ticked off."), _("The garden was glad to hear you went out.") },
    peek = { _("%s peeked out of the grass, and you saw."), _("You spotted %s watching from the grass."), _("%s was hiding in plain sight, and you found the spot.") },
    planted = { _("A new bed was laid out: %s."), _("%s was planted in the corner of the lawn."), _("The ground was ready, and %s went in.") },
    share = { _("The harvest of %s was shared round the garden."), _("%s was picked, and nobody went hungry."), _("The harvest from %s fed the garden's visitors.") },
    season = { _("%s began."), _("The garden turned to %s."), _("%s came round again, on time.") },
    queen = { _("%s was here all along. The garden has only now noticed."), _("%s has always ruled this garden, and today the garden said so."),
        _("%s looked the garden over and allowed the garden to go on.") },
    demand = { _("%s is hungry and is not hiding. She is demanding."), _("%s waited by the dish, and the waiting had teeth."), _("%s stared at the kitchen door until somebody felt guilty.") },
    bite = { _("%s bit someone. There was blood."), _("%s drew blood, and regrets nothing."), _("A hand went too far, and %s answered with teeth.") },
    back = { _("%s came back out for a meal."), _("%s was fed and showed up at once."), _("%s is back, and no questions asked.") },
}

-- A name to use in the middle of a sentence: the nickname, else the common
-- name with "the" in front. `lead` makes the "The" a capital.
function Journal.who(id, lead)
    local rec = State.rec(id)
    if rec and rec.nick then return rec.nick end
    local found = Cast.find(id)
    return (lead and "The " or "the ") .. (found and found.en or id)
end

-- One journal line for an event { t, k, id }: { date, text }.
function Journal.line(e)
    local ways = LINES[e.k] or LINES.bloom
    local text = ways[(e.t + #e.id) % #ways + 1]
    local line
    if e.k == "visit" then line = string.format(text, State.name(e.id), Journal.who(e.with, false))
    elseif e.k == "thanks" then line = string.format(text, e.n or 0, Journal.who(e.id, text:find("^%%s") and true or false))
    elseif e.k == "season" then line = string.format(text, Season.NAMES[e.with])
    elseif e.k == "gave" or e.k == "rain" or e.k == "snow" or e.k == "outside" then line = text
    else line = string.format(text, State.name(e.id)) end
    return { date = os.date("%d %b", e.t), text = line }
end

-- Every line, newest first.
function Journal.lines()
    local out = {}
    for _i, e in ipairs(State.journal()) do out[#out + 1] = Journal.line(e) end
    return out
end

return Journal
