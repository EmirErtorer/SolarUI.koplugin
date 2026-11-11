-- What to know about each plant and animal of the garden, in a few plain
-- sentences each, shown under the big picture when one is tapped.

local _ = require("solarui/gettext")

local Lore = {}

local TEXT = {
    narcissus = _("The poet's narcissus flowers late in spring and grows wild in the mountain meadows of southern Europe. Their scent is heavy and sweet. Every part of the plant is poisonous, the bulb most of all."),
    crocus = _("The spring crocus grows from a small corm and often flowers through the last snow in the mountains of Europe. Their petals open in the sun and close at dusk. Saffron comes from a different crocus."),
    pansy = _("The garden pansy was bred in the nineteenth century from the wild heartsease. The name comes from the French word for a thought. Pansies like cool weather, and their flowers can be eaten."),
    lily = _("The Madonna lily is one of the oldest garden plants there is, painted on Minoan walls more than three thousand years ago. They flower in early summer and smell strongly. Lilies of this kind are dangerous to cats."),
    chamomile = _("Chamomile is a small annual cousin of the daisy. Dried, the flower heads make a calming tea. The cone in the middle of each flower is hollow, which tells chamomile from similar plants."),
    dandelion = _("Each dandelion flower is a head of many tiny flowers. When they have set seed, every seed carries a parachute of fluff. The long taproot reaches deep, and the early blooms feed bees after winter."),
    maple = _("The Norway maple has leaves with pointed lobes, and a torn stalk bleeds a milky sap. Their seeds are paired wings that spin down like small helicopters. In autumn the leaves turn yellow."),
    rose = _("The damask rose is an old hybrid, grown for rose water and rose oil. Isparta in Turkey and the Rose Valley in Bulgaria are famous for roses. The petals are picked at dawn, before the sun draws out the scent."),
    tulip = _("The tulip came from the mountains of Central Asia. The Ottomans prized tulips so much that one age of their court is called the Tulip Era. Dutch growers later paid fortunes for single bulbs."),
    ginkgo = _("The ginkgo is the last survivor of a family of trees more than two hundred million years old. Their fan-shaped leaves have veins that fork and never join. In autumn the leaves turn gold and fall almost all at once."),
    bracken = _("Bracken is a fern, so bracken grows from spores and never makes a flower or a seed. The young fronds unroll slowly from tight coils. Bracken spreads underground and is one of the most widespread ferns on Earth."),
    honesty = _("Honesty gets the name from the seed pods, which are round, papery and so thin that the seeds show through. They shine like silver coins. The plant flowers purple in spring and lives for two years."),
    sunflower = _("The sunflower came from North America. Young flower heads turn to follow the sun across the sky. The big head is really hundreds of small flowers, set in spirals that are counted by Fibonacci numbers."),
    water_lily = _("The white water lily roots in the mud and sends up long stalks so the round leaves can float. The flowers open in the morning and close again in the afternoon. Water lilies need no watering."),
    bellflower = _("The harebell has slender stems that tremble in the lightest wind. Small blue bells nod on them through summer. Harebells grow on dry grassland and dunes across the northern half of the world."),
    iris = _("The bearded iris is named after the Greek goddess of the rainbow. The fuzzy beard on the lower petals guides insects in. Irises grow from thick roots called rhizomes, which are dried for perfume."),
    poppy = _("The seeds of the corn poppy can sleep in the soil for decades and wake when the ground is turned. That is why poppies covered the churned fields of old battlefields. Each flower lasts only a day or two."),
    ivy = _("Ivy climbs by tiny rootlets, not by tendrils, and stays green through winter. The flowers open late in autumn when little else does, so they feed insects, and the berries feed birds through the cold months."),
    three_sisters = _("Maize, climbing beans and squash are grown together in one mound by many Native peoples of the Americas, and the three plants are called the Three Sisters. The maize holds up the beans, the beans feed the soil with nitrogen, and the broad squash leaves shade the ground. Planted together, each helps the others."),
    bee = _("A honey bee tells the hive where the flowers are by dancing. The angle of the dance shows the direction and the length of the dance shows the distance. A worker lives only a few weeks in summer."),
    ladybug = _("The seven-spot ladybird's bright red warns birds of a bad taste. Both the adults and their spiky larvae eat aphids, and a single ladybird can eat hundreds in a life. Ladybirds sleep through winter in a sheltered crack."),
    snail = _("A garden snail glides on one muscular foot over a trail of slime. Their tongues are covered with thousands of tiny teeth. In dry weather a snail seals the shell shut and waits for the rain."),
    butterfly = _("The swallowtail's caterpillars eat fennel and other plants of the carrot family. The adults taste with their feet and drink nectar through a long tongue kept rolled up. The tails on the hind wings give the swallowtail the name."),
    robin = _("The European robin sings nearly all year round, and sometimes at night near a lamp. Each robin guards a patch of ground, even in winter. Robins often follow a gardener who is digging, for the worms that turn up."),
    dragonfly = _("The emperor dragonfly spends the first year or two as a hunter under the water. The adults hunt on the wing and can move each of the four wings separately. The family has been flying for more than three hundred million years."),
    frog = _("The marsh frog is the largest green frog of Europe. The eyes sit high on the head so a frog can watch from the water with only the face showing. In summer the males sing in loud choirs, with a balloon on each cheek."),
    koi = _("Koi are carp that were bred in Japan for their colours. They live for decades, and they learn to know the person who feeds them. In winter they slow down and rest near the bottom of the pond."),
    hedgehog = _("A hedgehog has five to seven thousand spines, and rolls into a ball when afraid. Hedgehogs wander at night looking for beetles and slugs. In winter they sleep in a nest of leaves until spring."),
    moth = _("The elephant hawk-moth is pink and olive green. At dusk the moths hover at flowers like tiny hummingbirds, drinking nectar. The caterpillar has a trunk-like front end, which is how the moth got the name."),
    fox = _("The red fox listens for mice under the grass, then leaps and pounces from above. Foxes are mostly active at night and sleep in a den by day. In midwinter the vixen calls with a strange scream."),
    peacock = _("What looks like the peacock's tail is a train of long feathers growing from the back, over the real tail. Every feather carries an eye. The train is shed each year after summer and grown again by spring."),
}

-- The lore of the plant or animal with this id ("" when it has none).
function Lore.get(id)
    return TEXT[id] or ""
end

return Lore
