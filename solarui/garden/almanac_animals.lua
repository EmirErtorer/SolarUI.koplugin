-- The almanac pages of the garden's animals, written by hand, with the same
-- fields as the plants' (see almanac_plants.lua): where the name comes from,
-- where they live in the wild, a short story of how people have lived with
-- them, and something to look for outdoors.

local _ = require("solarui/gettext")

return {
    bee = {
        name = _("From the Old English bēo. The Latin name Apis mellifera means the bee that carries honey."),
        habitat = _("Wild colonies live in hollow trees, and most honey bees now live in hives kept by people, across the world."),
        story = _("People have kept bees for thousands of years, and robbed wild nests before that. A hive is one family: a single queen and tens of thousands of her daughters."),
        look = _("Look at a bee on a flower and notice the yellow baskets of pollen packed on the hind legs."),
    },
    ladybug = {
        name = _("Ladybird is for Our Lady, the Virgin Mary: medieval farmers are said to have thanked her when the beetles ate the pests on their crops."),
        habitat = _("Gardens, hedges, grassland and farmland, anywhere that aphids live, across Europe."),
        story = _("Gardeners have welcomed ladybirds for centuries, and growers now release them to control aphids instead of spraying. The black spots do not tell the age, as the story goes."),
        look = _("Look on the new growth of roses and nettles, where aphids gather, for ladybirds and their spiky larvae."),
    },
    snail = {
        name = _("Snail is from the Old English snægl, related to a word for creeping. Cornu is Latin for horn, for the horns on the head."),
        habitat = _("Gardens, hedges and woodland edges, in damp places, native to the Mediterranean and spread by people to much of the world."),
        story = _("The Romans kept snails for the table, and snails are still eaten in several countries. Every snail is both male and female, and a pair can swap eggs."),
        look = _("Look after rain, or at dusk, and follow a silver trail to find where a snail has been."),
    },
    butterfly = {
        name = _("From the Old English butorfleoge, possibly for the yellow of the first butterflies of spring. The swallowtail is named for the tails, like those of a swallow."),
        habitat = _("Fens and wet meadows in Britain, and warm open country across Europe, where the caterpillar's food plants grow."),
        story = _("The British swallowtail is a rare butterfly that lives only in the Norfolk Broads. The caterpillar eats milk-parsley, and conservationists work to keep the fens from drying out."),
        look = _("Look for the caterpillar on a fennel or carrot plant: green with black bands and orange spots, and puts out a smelly orange horn when disturbed."),
    },
    robin = {
        name = _("Called redbreast at first. Robin is a pet form of the name Robert, and the pet name won."),
        habitat = _("Woodland, hedges and gardens across Europe. In Britain robins are tame and sing near people."),
        story = _("The robin is a favourite of British gardens, and was chosen as the national bird of Britain in a vote in 2015. The red breast gave rise to many folk tales."),
        look = _("Look at the red on the breast and face, and listen for a thin, wistful song on winter mornings."),
    },
    dragonfly = {
        name = _("A dragon among flies, for the fierce hunter. Anax is Greek for lord and imperator is Latin for emperor."),
        habitat = _("Still, open water with plenty of plants, such as ponds, lakes and slow rivers, across Europe, Asia and Africa."),
        story = _("Dragonflies were flying before the dinosaurs, and some ancient ones had wings seventy centimetres across. In Japan the dragonfly is a symbol of strength and success."),
        look = _("Look beside a pond in summer for a dragonfly that hovers, darts and returns to the same perch."),
    },
    frog = {
        name = _("Frog is from the Old English frogga. Pelophylax is Greek for mud guard, and ridibundus is Latin for laughing."),
        habitat = _("Ponds, lakes and slow rivers with plenty of plants, across Europe and western Asia."),
        story = _("Frogs have been used in laboratories since the 1700s, and the study of frog legs helped lead to the discovery of electricity in nerves. Frog populations are now falling in many places."),
        look = _("Look at the water's edge on a warm summer evening, and listen for the loud laughing chorus."),
    },
    koi = {
        name = _("Koi is the Japanese word for carp. The word sounds like another that means affection, so koi stand for love."),
        habitat = _("Koi were bred from the common carp in Japan, and live in ornamental ponds around the world."),
        story = _("Rice farmers in Niigata first bred carp with red and white patterns in the 1800s. A koi may live for decades; one in Japan was said to have reached two hundred years, though that is not proven."),
        look = _("Look at the mouth of a koi for the small whiskers, used to feel for food in the mud."),
    },
    hedgehog = {
        name = _("Hedge for where they look for food, and hog for the pig-like snout."),
        habitat = _("Gardens, hedgerows, woods and meadows across Europe, wherever they can find cover."),
        story = _("Hedgehogs are in decline across Britain and Europe, and gardens with small gaps in the fences are one of the things that help. They have been in folk tales for centuries."),
        look = _("Look at dusk, or listen for snuffling in the leaves, and leave a gap under the fence for passing hedgehogs."),
    },
    moth = {
        name = _("From the Old English moððe. The elephant hawk-moth is named for the caterpillar, which looks a little like an elephant's trunk."),
        habitat = _("Waste ground, gardens, woodland edges and railway banks, anywhere willowherb or bedstraw grows, across Europe and Asia."),
        story = _("Moths do much of the pollination of flowers at night, a job that we mostly notice only in butterflies. The caterpillar can swell the front end to look like a snake."),
        look = _("Look at honeysuckle or phlox after dusk, and wait for a pink moth to hover and drink."),
    },
    fox = {
        name = _("Fox is the Old English fox, related to a word for tail. Vulpes is Latin for fox."),
        habitat = _("Woods, farmland, hedgerows and towns across the northern hemisphere. Red foxes have moved into many cities."),
        story = _("The fox appears in folk tales across Europe and Asia as a trickster. Foxes have lived beside people for so long that they now share many cities with them."),
        look = _("Look at the ground at dawn or dusk for a track of four toes with claw marks, laid in a neat line."),
    },
    peacock = {
        name = _("Pea is from the Latin pavo, the peafowl, and the cock is for the male. The female is a peahen."),
        habitat = _("Indian peafowl are wild in forests and farmland in India and Sri Lanka, and are kept in parks around the world."),
        story = _("Peafowl have been kept in gardens since antiquity. The peacock is the national bird of India. The long train of feathers is used to attract mates, not to fly."),
        look = _("Look at the eye on each long feather and count how many there are on a full train."),
    },
    yuzsuz = {
        name = _("Yüzsüz is Turkish for shameless, literally without a face: one who does exactly as she likes and is never sorry. She is known by many, many names across the multiverse. This is the one that stuck."),
        habitat = _("The known and unknown universe, which she rules. Most often found in a patch of sun on a bed, or on whichever cushion you were about to sit on."),
        story = _("Cats have lived with people for some ten thousand years, since the first grain stores drew mice. Yüzsüz took the arrangement further: the people live with her. She hates lizards above all things and other cats only slightly less, and she sprints out of the litter box every time, as if something were after her."),
        look = _("Look for a cat outdoors watching one spot without moving, for a very long time. Do not ask what is there. Nobody knows."),
    },
}
