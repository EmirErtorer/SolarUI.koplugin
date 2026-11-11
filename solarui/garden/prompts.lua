-- Three small things to do outdoors each week, twelve to choose from for each
-- season, written for the garden. The reader ticks them off and the ticks are
-- kept as a log (see State.outsideLog); nothing is earned by them, they are
-- only a reason to go outside and look.

local Season = require("solarui/garden/season")
local _ = require("solarui/gettext")

local Prompts = {}

Prompts.PER_WEEK = 3   -- things to do each week: one to look at, one to listen to and one to do

-- Twelve for each season, in threes of look, listen and do.
Prompts.LIST = {
    spring = {
        _("Find three leaves with different edges: smooth, toothed and lobed. Lay them side by side."),
        _("Step outside around sunrise and count how many different bird songs you can tell apart."),
        _("Sow one seed, even in a pot on a windowsill, and water the seed."),
        _("Find a flower that opened this week. Count the petals, then watch for who visits."),
        _("Stand under a tree on a breezy day and listen to the leaves."),
        _("Walk somewhere you usually ride or drive, and notice what has changed since last week."),
        _("Turn over a leaf gently and look underneath for tiny eggs or insects, then put the leaf back."),
        _("Find a place near water and listen for frogs, ducks or running water."),
        _("Smell the ground after rain, then crouch down and look closely at the soil."),
        _("Pick a tree you pass every day and find the buds at the end of a twig. Look again in a week."),
        _("Sit still for five minutes and count the sounds you hear that people did not make."),
        _("Pick up three pieces of litter on a walk and put them in a bin."),
    },
    summer = {
        _("Find a flower with a bee on the petals and watch how long the bee stays and where the bee goes next."),
        _("Listen at dusk for crickets, grasshoppers or birds settling for the night."),
        _("Sit in the shade for ten minutes without your phone and notice everything that moves."),
        _("Find three kinds of seeds and compare how each one is made to travel."),
        _("Close your eyes in a park or garden and listen for the nearest bird, then the next nearest."),
        _("Leave a shallow dish of water out for birds and insects, and see who comes."),
        _("Look early in the morning for a spider's web, when the dew makes every thread show."),
        _("Stand still near flowers and listen for the hum of bees."),
        _("Lie on the grass and look up through the branches of a tree for a few minutes."),
        _("Watch the sky at dusk for swifts, swallows, bats or moths."),
        _("Find the tallest tree near you and listen to the wind in the top."),
        _("Walk barefoot on grass, sand or soil for a few minutes, if the ground is safe."),
    },
    autumn = {
        _("Gather leaves of three colours and set them in a line from green to red."),
        _("Listen for geese, starlings or other flocks passing overhead."),
        _("Leave a pile of leaves in a quiet corner, where a hedgehog or a beetle might shelter."),
        _("Look for a bird eating berries and notice which berries are chosen."),
        _("Walk on dry leaves and listen to how each kind crunches."),
        _("Collect three seeds or nuts, such as acorns, conkers or maple keys, and look at how each is made."),
        _("Look for mushrooms in the leaf litter. Look closely, and do not touch or taste."),
        _("On a still evening, listen for an owl or a robin singing in the dusk."),
        _("Watch a sunset and notice how early the sun goes down now."),
        _("Find one seed that flies on the wind, one that sticks to clothes and one that animals eat."),
        _("Stand under a tree as the leaves fall and listen for the small sound of each one landing."),
        _("Notice which trees have kept their leaves and which have let them go, and think about why."),
    },
    winter = {
        _("Look for tracks in frost, mud or snow, and follow one set for as far as the tracks go."),
        _("Stand outside after snow and listen to how quiet the world has become."),
        _("Hang up food for the birds, or put out fresh water, and watch who comes."),
        _("Find the bud at the end of a bare branch, small and tightly closed."),
        _("Listen for a robin or a wren singing in the cold."),
        _("Go out on a clear night, let your eyes adjust for ten minutes, and find one constellation."),
        _("Find something green in the middle of winter, and ask what the plant is doing."),
        _("Listen to your own footsteps on frost, leaves or snow."),
        _("Walk for twenty minutes in daylight, however cold, and notice how long the shadows are."),
        _("Count the birds in a hedge or at a feeder for five minutes."),
        _("Stand by a frozen puddle or pond and listen for the ice creaking."),
        _("Look for the first snowdrop or catkin of the year, and remember the date."),
    },
}

-- A number for the week of `t` that changes once a week.
function Prompts.week(t)
    local d = os.date("*t", t)
    return d.year * 60 + math.floor((d.yday - 1) / 7)
end

-- This week's things to do: { week, items = { { i (its place in the season's list), text } x PER_WEEK } }.
-- They go round the list three at a time, so each week has one of each kind.
function Prompts.of(t, season)
    season = season or Season.now()
    local list = Prompts.LIST[season]
    local week = Prompts.week(t)
    local items = {}
    for k = 0, Prompts.PER_WEEK - 1 do
        local i = (week * Prompts.PER_WEEK + k) % #list + 1
        items[#items + 1] = { i = i, text = list[i] }
    end
    return { week = week, season = season, items = items }
end

-- The text of one thing, by season and place in the list, or nil.
function Prompts.text(season, i)
    return Prompts.LIST[season] and Prompts.LIST[season][i]
end

return Prompts
