-- Things to do outdoors each week, for the garden: three a week, one to look
-- at, one to listen to and one to do, chosen from 37 for each season. The
-- reader ticks them off and the ticks are kept as a log (see State.outsideLog);
-- nothing is earned by them, they are only a reason to go outside and look.
-- The thing to look at is often the garden's own pick: a plant or an animal
-- of the garden to look for in the real world (see State.outsideWeek).
--
-- A week's three are not a formula: the one of each kind that was offered
-- longest ago is taken, so a thing is not offered again for a season or more.
-- The first twelve of each season are the original ones (a log keeps a thing as
-- its season and place in the list, so they must stay where they are).
-- A "first" is something that happens once a year, and the reader is asked to
-- remember the date of it (the garden says last year's date when it comes round).

local _ = require("solarui/gettext")

local Prompts = {}

Prompts.PER_WEEK = 3                           -- things to do each week
Prompts.KINDS = { "look", "listen", "do" }     -- one of each
Prompts.GARDEN_EVERY = 3                       -- the garden's pick is the thing to look at in two weeks of three

-- { kind, text, first = what to remember the date of }, by season, in the order that logs rely on.
Prompts.POOL = {
    spring = {
        { "look", _("Find three leaves with different edges: smooth, toothed and lobed. Lay them side by side.") },
        { "listen", _("Step outside around sunrise and count how many different bird songs you can tell apart.") },
        { "do", _("Sow one seed, even in a pot on a windowsill, and water the seed.") },
        { "look", _("Find a flower that opened this week. Count the petals, then watch for who visits.") },
        { "listen", _("Stand under a tree on a breezy day and listen to the leaves.") },
        { "do", _("Walk somewhere you usually ride or drive, and notice what has changed since last week.") },
        { "look", _("Turn over a leaf gently and look underneath for tiny eggs or insects, then put the leaf back.") },
        { "listen", _("Find a place near water and listen for frogs, ducks or running water.") },
        { "do", _("Smell the ground after rain, then crouch down and look closely at the soil.") },
        { "look", _("Pick a tree you pass every day and find the buds at the end of a twig. Look again in a week.") },
        { "listen", _("Sit still for five minutes and count the sounds you hear that people did not make.") },
        { "do", _("Pick up three pieces of litter on a walk and put them in a bin.") },
        { "look", _("Find a puddle after rain and look at the sky reflected there, then at who comes to drink.") },
        { "look", _("Look for the first butterfly of the year and notice the colours of the wings."), first = _("the first butterfly") },
        { "look", _("Find a bud that has just burst and look at how the new leaf is folded.") },
        { "look", _("Find moss on a wall or a tree and look at the moss up close, as if the moss were a tiny forest.") },
        { "look", _("Look at the light through new leaves and notice how green the light has become.") },
        { "look", _("Find a daisy and see whether the flower closes towards dusk.") },
        { "look", _("Look for a bee at a flower early in the day, when the bees are slow with cold."), first = _("the first bee") },
        { "look", _("Watch a hedge from a distance for a bird carrying twigs, and leave any nest alone.") },
        { "listen", _("Listen for a bird singing before dawn, and count the singers.") },
        { "listen", _("Listen to rain on leaves, on a roof and on the ground, and notice how each sounds different.") },
        { "listen", _("Stand quietly near blossom and listen for the buzz of insects.") },
        { "listen", _("Listen to the wind in new leaves, and compare the sound with the wind in bare branches.") },
        { "listen", _("Listen for a woodpecker drumming on a tree.") },
        { "listen", _("Listen at dusk for the last bird to stop singing.") },
        { "listen", _("Listen at a pond or a ditch for the first frog calling, and remember the day."), first = _("the first frog calling") },
        { "listen", _("Listen at a hedge for the rustle and chirps of birds looking for nest material.") },
        { "do", _("Plant a seed or a bulb in a pot and write the date on a label beside the pot.") },
        { "do", _("Take your book outside and read one page under the open sky.") },
        { "do", _("Walk a path near where you live that you have never taken.") },
        { "do", _("Water a plant outdoors or on a sill and watch the water sink into the soil.") },
        { "do", _("Put out a bowl of water for the birds and keep the bowl full for a week.") },
        { "do", _("Take a photograph of the same tree each week, starting now.") },
        { "do", _("Spend a quarter of an hour outside without your phone.") },
        { "do", _("Sit on the ground and look closely at everything at the height of your hand.") },
        { "do", _("Take a deep breath outside and name three smells.") },
    },
    summer = {
        { "look", _("Find a flower with a bee on the petals and watch how long the bee stays and where the bee goes next.") },
        { "listen", _("Listen at dusk for crickets, grasshoppers or birds settling for the night.") },
        { "do", _("Sit in the shade for ten minutes without your phone and notice everything that moves.") },
        { "look", _("Find three kinds of seeds and compare how each one is made to travel.") },
        { "listen", _("Close your eyes in a park or garden and listen for the nearest bird, then the next nearest.") },
        { "do", _("Leave a shallow dish of water out for birds and insects, and see who comes.") },
        { "look", _("Look early in the morning for a spider's web, when the dew makes every thread show.") },
        { "listen", _("Stand still near flowers and listen for the hum of bees.") },
        { "do", _("Lie on the grass and look up through the branches of a tree for a few minutes.") },
        { "look", _("Watch the sky at dusk for swifts, swallows, bats or moths.") },
        { "listen", _("Find the tallest tree near you and listen to the wind in the top.") },
        { "do", _("Walk barefoot on grass, sand or soil for a few minutes, if the ground is safe.") },
        { "look", _("Find a butterfly resting with closed wings and look at the underside, then wait for the wings to open.") },
        { "look", _("Look at the sky and name the clouds: high wisps, fluffy heaps or a flat grey sheet.") },
        { "look", _("Mark the shadow of a tree at noon and again two hours later, and see how far the shadow has moved.") },
        { "look", _("Look closely at a daisy or a dandelion and see that the one flower is really many small flowers.") },
        { "look", _("Find a snail or a slug on a damp morning and follow the trail.") },
        { "look", _("Find the spot where a flower has fallen and a fruit is starting to form.") },
        { "look", _("Watch an ant trail for a minute and see what the ants are carrying.") },
        { "look", _("Look for the first ripe berry of the summer and remember the day."), first = _("the first ripe berry") },
        { "listen", _("Listen to a hot afternoon: what has gone quiet, and what has not?") },
        { "listen", _("Listen for a bird that sounds like a question, and try to find the singer.") },
        { "listen", _("Listen to water: a stream, a fountain, a tap or a puddle. Which is the gentlest?") },
        { "listen", _("Sit near a hedge and listen for the small rustles of wrens and sparrows.") },
        { "listen", _("Listen for the first swift screaming overhead, and remember the day."), first = _("the first swift") },
        { "listen", _("Listen to a storm arriving: the wind first, then the hush, then the rain.") },
        { "listen", _("Listen at the edge of a field to the dry whisper of long grass.") },
        { "listen", _("Listen at night through an open window to the sounds of the dark.") },
        { "do", _("Water a thirsty plant in the cool of the evening, and watch the leaves lift.") },
        { "do", _("Pick up a smooth stone and carry the stone for a day, then return the stone to where you found the stone.") },
        { "do", _("Eat something outside, a piece of fruit if you can, and notice every taste.") },
        { "do", _("Leave a patch of lawn unmown or a corner of a window box wild, and see who moves in.") },
        { "do", _("Take your book outside and read in the shade for twenty minutes.") },
        { "do", _("Go out an hour before sunset and walk until the light turns gold.") },
        { "do", _("Sit by water and put a hand in the water.") },
        { "do", _("Press a flower or a leaf between the pages of a heavy book.") },
        { "do", _("Draw a plant you can see, even badly, and put the date on the drawing.") },
    },
    autumn = {
        { "do", _("Gather leaves of three colours and set them in a line from green to red.") },
        { "listen", _("Listen for geese, starlings or other flocks passing overhead.") },
        { "do", _("Leave a pile of leaves in a quiet corner, where a hedgehog or a beetle might shelter.") },
        { "look", _("Look for a bird eating berries and notice which berries are chosen.") },
        { "listen", _("Walk on dry leaves and listen to how each kind crunches.") },
        { "do", _("Collect three seeds or nuts, such as acorns, conkers or maple keys, and look at how each is made.") },
        { "look", _("Look for mushrooms in the leaf litter. Look closely, and do not touch or taste.") },
        { "listen", _("On a still evening, listen for an owl or a robin singing in the dusk.") },
        { "look", _("Watch a sunset and notice how early the sun goes down now.") },
        { "look", _("Find one seed that flies on the wind, one that sticks to clothes and one that animals eat.") },
        { "listen", _("Stand under a tree as the leaves fall and listen for the small sound of each one landing.") },
        { "look", _("Notice which trees have kept their leaves and which have let them go, and think about why.") },
        { "look", _("Find a spider's web with the spider still at home, and look at how the threads are laid.") },
        { "look", _("Look at a leaf that is half green and half red, and find where the colours meet.") },
        { "look", _("Look at what the first frost or the first fog of the season has covered, and remember the day."), first = _("the first frost") },
        { "look", _("Look for a squirrel or a jay burying food, and notice where.") },
        { "look", _("Look at how high the midday sun is, and compare the height with the summer sun.") },
        { "look", _("Find a hedge full of berries and count the colours.") },
        { "look", _("Look up at a flock leaving or arriving, and count them in tens.") },
        { "listen", _("Listen for an owl or another night bird after dark.") },
        { "listen", _("Listen to the wind shaking seed pods and dry stems.") },
        { "listen", _("Listen for the last cricket of the year, and remember the day."), first = _("the last cricket") },
        { "listen", _("Listen for the call of a bird that has just arrived for the winter.") },
        { "listen", _("Listen to rain on fallen leaves.") },
        { "listen", _("Listen to your own steps on a muddy path, then on a dry one.") },
        { "listen", _("Listen at dusk as the garden gets ready for night, and notice what goes quiet first.") },
        { "listen", _("Stand still and follow the faintest sound you can hear for a full minute.") },
        { "do", _("Rake a few leaves into a heap and walk through the heap.") },
        { "do", _("Plant a bulb for the spring, and mark the place.") },
        { "do", _("Save the seeds of a flower you like in a paper envelope, and write the name on the envelope.") },
        { "do", _("Take a walk after rain with a bag for leaves and seeds.") },
        { "do", _("Note the date the first tree in your street turns.") },
        { "do", _("Take your book outside and read in the last warm sun.") },
        { "do", _("Buy or gather something of the season, such as apples, pumpkins or nuts, and taste the first bite outdoors.") },
        { "do", _("Cut back what has finished in your pots or window box, and leave what is still flowering.") },
        { "do", _("Go outside at dusk with a hot drink and watch the light go.") },
        { "do", _("Take a leaf from a tree and find out the name of the tree.") },
    },
    winter = {
        { "look", _("Look for tracks in frost, mud or snow, and follow one set for as far as the tracks go.") },
        { "listen", _("Stand outside after snow and listen to how quiet the world has become.") },
        { "do", _("Hang up food for the birds, or put out fresh water, and watch who comes.") },
        { "look", _("Find the bud at the end of a bare branch, small and tightly closed.") },
        { "listen", _("Listen for a robin or a wren singing in the cold.") },
        { "look", _("Go out on a clear night, let your eyes adjust for ten minutes, and find one constellation.") },
        { "look", _("Find something green in the middle of winter, and ask what the plant is doing.") },
        { "listen", _("Listen to your own footsteps on frost, leaves or snow.") },
        { "do", _("Walk for twenty minutes in daylight, however cold, and notice how long the shadows are.") },
        { "look", _("Count the birds in a hedge or at a feeder for five minutes.") },
        { "listen", _("Stand by a frozen puddle or pond and listen for the ice creaking.") },
        { "look", _("Look for the first snowdrop or catkin of the year, and remember the date."), first = _("the first snowdrop or catkin") },
        { "look", _("Look at your breath in the cold air and watch where the breath goes.") },
        { "look", _("Find an icicle or a pattern of frost and look closely at the shape.") },
        { "look", _("Look for a bird's nest in a bare tree, where the nest can now be seen, and leave the nest alone.") },
        { "look", _("Look at the stars and find the brightest one. Does the star twinkle?") },
        { "look", _("Watch a sunrise or a sunset and notice where the sun comes up or goes down compared with last month.") },
        { "look", _("Find a plant that has kept the berries and see who comes to eat them.") },
        { "listen", _("Listen for the sound of snow falling, or for the quiet that comes with the snow.") },
        { "listen", _("Listen for a bird calling on a frosty morning and try to find the singer.") },
        { "listen", _("Listen for geese or other winter birds overhead at dusk.") },
        { "listen", _("Listen to the wind on a cold night from indoors, and think where the wind has been.") },
        { "listen", _("Listen to wet leaves underfoot, and compare them with dry ones.") },
        { "listen", _("Listen for tits and finches moving through the garden in a flock.") },
        { "listen", _("Listen at a window to the dawn and notice how late the first song starts now.") },
        { "listen", _("Listen for the first song of any bird other than a robin, and remember the day."), first = _("the first new birdsong") },
        { "do", _("Fill a bird feeder and keep the feeder full for a week.") },
        { "do", _("Press a finger into frost or snow and look at the mark left behind.") },
        { "do", _("Take your book outside, wrapped up warm, and read one page in the cold.") },
        { "do", _("Sow a seed on a windowsill and watch for the first green.") },
        { "do", _("Put a pine cone, a seed head or a twig on a windowsill and draw the shape.") },
        { "do", _("Go out at first light and be there for the sunrise.") },
        { "do", _("Walk to a place where you can see far, and look at the shape of the land.") },
        { "do", _("Warm your hands round a hot drink while standing outside.") },
        { "do", _("Check on a plant you left outside and look for green at the base.") },
        { "do", _("Leave a shallow dish of water out on a freezing day and see how thick the ice is in the morning.") },
        { "do", _("Take a photograph of a tree in winter, and take the same one again in summer.") },
    },
}

-- The texts alone, by season (LIST[season][i]).
Prompts.LIST = {}
for season, items in pairs(Prompts.POOL) do
    Prompts.LIST[season] = {}
    for i, e in ipairs(items) do Prompts.LIST[season][i] = e[2] end
end

-- A number for the week of `t` that changes once a week.
function Prompts.week(t)
    local d = os.date("*t", t)
    return d.year * 60 + math.floor((d.yday - 1) / 7)
end

-- The text of one thing, by season and place in the list, or nil.
function Prompts.text(season, i)
    return Prompts.LIST[season] and Prompts.LIST[season][i]
end

-- Its kind ("look", "listen" or "do"), or nil.
function Prompts.kind(season, i)
    local e = Prompts.POOL[season] and Prompts.POOL[season][i]
    return e and e[1]
end

-- What to remember the date of ("the first swift"), or nil when it is not a first.
function Prompts.first(season, i)
    local e = Prompts.POOL[season] and Prompts.POOL[season][i]
    return e and e.first
end

-- Does the garden's pick take the thing to look at in this week?
function Prompts.gardenWeek(week)
    return week % Prompts.GARDEN_EVERY ~= 0
end

-- The place in the season's list of the thing of `kind` for `week`: the one
-- offered longest ago (`offered` maps "season:i" to the week it was last
-- offered; never offered comes first), and among equals a stable shuffle by
-- the week. `skip` holds places already taken this week.
function Prompts.choose(season, week, kind, offered, skip)
    local best, best_at, best_tie
    for i, e in ipairs(Prompts.POOL[season] or {}) do
        if e[1] == kind and not (skip and skip[i]) then
            local at = offered[season .. ":" .. i] or -1
            local tie = (week * 31 + i * 17) % 101
            if not best or at < best_at or (at == best_at and tie < best_tie) then best, best_at, best_tie = i, at, tie end
        end
    end
    return best
end

return Prompts
