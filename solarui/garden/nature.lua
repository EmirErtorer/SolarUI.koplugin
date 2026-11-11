-- Short lines about the season, written for the garden (not quoted from any
-- book), that are mixed in with the reader's own highlights in the book on
-- the table. Four seasons, twelve lines each; each is a plain observation
-- that is true of the northern hemisphere's year and gentle in tone.

local _ = require("solarui/gettext")

local Nature = {}

Nature.LINES = {
    spring = {
        _("The first crocuses open on the sunny side of the hedge, and by afternoon a few bees have found them."),
        _("Day by day the light stays a little longer. The blackbird sings before anyone is up to hear."),
        _("A tulip does not hurry. The leaves come first, then a bud held low and tight, then a week of colour."),
        _("After rain the ground smells sweet. Soil bacteria make the scent, and the damp air carries the scent up."),
        _("Dandelions are the first meal many bees find after winter, so leave a few in the grass."),
        _("Look for the pale new leaves on the maple: they are folded like small hands, and open within days."),
        _("The robin sings from the highest branch, which is how the neighbours learn whose ground this is."),
        _("Sparrows carry strands of dry grass back to the hedge. Every nest begins as a pile of small errands."),
        _("A snail leaves a trail of silver on the stones, and the rain wipes the trail away before supper."),
        _("Frogs gather in the pond on the first warm nights, and the spawn floats in a clear, trembling cloud."),
        _("Narcissus nods in the wind and holds on to the petals through all of April's rain."),
        _("At the equinox day and night are almost the same length everywhere on Earth, and from then on the light has the upper hand."),
    },
    summer = {
        _("At midsummer the sun barely sets in the north, and the last light lingers on the lawn long after supper."),
        _("The lily opens in the morning and closes in the afternoon, as regular as a clock with no hands."),
        _("A bee on a flower is doing a day's work. She may visit hundreds of blossoms before she turns for home."),
        _("The dragonfly hovers, darts, and returns to the same perch. Each of the four wings can move separately."),
        _("Sunflowers follow the sun when they are young. Once they flower, the big heads settle facing east."),
        _("At dusk the moths come out for the flowers that stayed open, and the garden begins the night shift."),
        _("The pond is quietest in the heat of the afternoon. By evening the frogs are ready to sing."),
        _("A poppy lasts a day or two, but the plant makes dozens of flowers, and thousands of seeds for the years ahead."),
        _("Shade is a gift in summer. Sit under the maple for ten minutes and notice how much cooler the air feels."),
        _("The ginkgo's leaves are a deep, glossy green now. In autumn they will turn gold and fall almost overnight."),
        _("Swifts scream across the sky in the warm evenings. They eat, drink and even sleep on the wing."),
        _("The bellflower trembles in the lightest breeze, and sheds tiny seeds from holes at the base of each capsule."),
    },
    autumn = {
        _("The maple turns first at the edges. The green fades as the tree takes back what the leaves can give before they fall."),
        _("Ivy flowers late, in the cool of October, and the bees that are still about are glad of the flowers."),
        _("A hedgehog needs to eat well now to last the winter. A pile of leaves in a quiet corner is a good place to sleep."),
        _("The ginkgo drops every leaf within a day or two of the first hard frost, and leaves a golden circle on the ground."),
        _("Spiders' webs show in the morning mist, every thread strung with a bead of water."),
        _("Honesty's flat pods turn silver and papery. Hold one up to the light and the seeds show through."),
        _("Geese fly south in loose skeins, calling to each other. Listen on a still evening and you will hear them before you see them."),
        _("The robin guards a patch of ground all winter, even from other robins, and sings from that patch in the cold."),
        _("The first frost does not kill the garden. The frost tells the plants that the time to rest has come."),
        _("Seeds are the garden's savings: tucked into the soil, they wait for the spring to come back."),
        _("At the equinox day and night are almost equal. From now on the dark has the upper hand until midwinter."),
        _("The pond grows quiet. The frog settles into the mud, and the dragonfly's eggs wait under the water."),
    },
    winter = {
        _("The year's shortest day is still a day. After that, the light comes back by a minute at a time."),
        _("The bare maple shows the bones of the tree: every branch that held a leaf in summer, drawn in ink against the sky."),
        _("A robin puffs up the feathers on a cold morning, and looks twice the size."),
        _("Frost writes on the window in ferns, and the ferns in the garden are waiting under the leaves."),
        _("The hedgehog sleeps in a nest of leaves. The heartbeat slows to a fraction of the summer rate, and the hedgehog wakes in spring."),
        _("Snow is a blanket. The soil beneath stays warmer than the air, and the bulbs sleep on."),
        _("The crocus corms are under the ground now, small and patient, waiting for the first warm day."),
        _("A fox's tracks cross the frosty lawn in a neat line, four toes and the marks of claws."),
        _("Ivy berries ripen in the cold, and are one of the last things the birds can find."),
        _("Seeds are not dead. They are asleep, and many of them need the cold to wake."),
        _("The pond may freeze over, but under the ice the fish drift slowly and the frogs lie in the mud."),
        _("The first snowdrop is a promise. The plant has been growing under the snow the whole time."),
    },
}

-- The lines of a season, as passages for the book: { text, title, author }.
function Nature.passages(season, name)
    local out = {}
    for _i, text in ipairs(Nature.LINES[season] or {}) do out[#out + 1] = { text = text, title = _("From the garden"), author = name } end
    return out
end

return Nature
