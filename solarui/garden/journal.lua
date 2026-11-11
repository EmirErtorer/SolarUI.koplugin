-- The garden journal in words: each saved event (see State.journal) becomes
-- one dated line in a plain, slightly dry voice, with a few ways of saying
-- it chosen by the event's time so the page does not repeat itself.

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
    back = { _("%s came back out for a meal."), _("%s was fed and showed up at once."), _("%s is back, and no questions asked.") },
}

-- One journal line for an event { t, k, id }: { date, text }.
function Journal.line(e)
    local ways = LINES[e.k] or LINES.bloom
    local text = ways[(e.t + #e.id) % #ways + 1]
    return { date = os.date("%d %b", e.t), text = string.format(text, State.name(e.id)) }
end

-- Every line, newest first.
function Journal.lines()
    local out = {}
    for _i, e in ipairs(State.journal()) do out[#out + 1] = Journal.line(e) end
    return out
end

return Journal
