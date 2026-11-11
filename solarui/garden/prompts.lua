-- A small thing to do outdoors each week, six for each season, written for the
-- garden. Nothing is recorded but a tick the reader gives, and nothing is
-- earned by it: it is only a reason to go outside and look.

local Season = require("solarui/garden/season")
local _ = require("solarui/gettext")

local Prompts = {}

Prompts.LIST = {
    spring = {
        _("Find three leaves with different edges: one smooth, one toothed and one lobed."),
        _("Listen before sunrise for a bird singing, and count how many different songs you can pick out."),
        _("Find a flower that opened this week and look closely. How many petals does the flower have?"),
        _("Turn over a leaf and look underneath for tiny eggs or insects, then put the leaf back."),
        _("Look at a tree you pass every day and find the buds on the end of a twig."),
        _("Go outside after rain and smell the ground."),
    },
    summer = {
        _("Find a flower with a bee on the petals and watch how long the bee stays."),
        _("Sit in the shade for ten minutes and notice everything that moves."),
        _("Look early in the morning for a spider's web, when the dew makes the threads show."),
        _("Find three different kinds of seeds."),
        _("Watch the sky at dusk for swifts, bats or moths."),
        _("Lie on the grass and look up through the branches of a tree."),
    },
    autumn = {
        _("Gather leaves of three colours and set them in a line from green to red."),
        _("Look for a bird eating berries, and see how many berries are taken."),
        _("Find one seed that flies on the wind, one that sticks to clothes and one that animals eat."),
        _("Look for mushrooms growing in the leaf litter. Look, and do not touch or taste."),
        _("Find a sheltered corner where a hedgehog or a mouse might sleep through the winter."),
        _("Notice which trees have kept their leaves, and which have let them go."),
    },
    winter = {
        _("Look for tracks in frost, mud or snow."),
        _("Find the bud at the end of a bare branch, small and tightly closed."),
        _("Count the birds in a hedge or at a feeder for five minutes."),
        _("Find something green in the middle of winter."),
        _("Look at the stars on a clear night and find one constellation."),
        _("Stand outside after snow and listen to how quiet the world has become."),
    },
}

-- A number for the week of `t` that changes once a week.
function Prompts.week(t)
    local d = os.date("*t", t)
    return d.year * 60 + math.floor((d.yday - 1) / 7)
end

-- This week's prompt: { week, text }.
function Prompts.of(t, season)
    local list = Prompts.LIST[season or Season.now()]
    local week = Prompts.week(t)
    return { week = week, text = list[week % #list + 1] }
end

return Prompts
