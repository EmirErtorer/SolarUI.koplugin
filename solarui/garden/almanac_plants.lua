-- The almanac pages of the garden's plants, written by hand. Each has: where
-- the name comes from (`name`), where it grows in the wild (`habitat`), the
-- months it flowers or shows its best in the northern hemisphere (`months`,
-- from and to), a short story of how people have lived with it (`story`) and
-- something to look for outdoors (`look`). Facts to check before release are
-- ordinary reference knowledge (botanical floras, the Oxford dictionary of
-- plant names); nothing here is quoted.

local _ = require("solarui/gettext")

return {
    crocus = {
        name = _("From the Greek krokos, the old word for saffron."),
        habitat = _("Mountain meadows and open woods of Europe, often where snow has just melted."),
        months = { 2, 4 },
        story = _("Saffron, the most costly spice by weight, is made from the red threads of a different crocus. Each flower gives only three, and they are picked by hand."),
        look = _("Look on a sunny day in late winter for crocuses open wide, and on a dull day for the same flowers shut tight."),
    },
    pansy = {
        name = _("From the French pensée, a thought, because the flower seems to nod as if thinking."),
        habitat = _("The wild heartsease grows on grassland and field edges across Europe. Garden pansies were bred from heartsease."),
        months = { 3, 10 },
        story = _("Heartsease was once a folk remedy and a love charm. Breeders in England in the early 1800s crossed heartsease with other violas to make the large pansy."),
        look = _("Look at one pansy closely: the dark lines on the lower petals point towards the middle, guiding insects in."),
    },
    chamomile = {
        name = _("From the Greek for ground apple, because the leaves smell of apples when crushed."),
        habitat = _("Fields, roadsides and waste ground across Europe and western Asia."),
        months = { 6, 8 },
        story = _("Chamomile tea is one of the oldest herbal drinks, used in ancient Egypt and Rome."),
        look = _("Crush a leaf between your fingers and smell the apple, then look for the hollow cone in the middle of the flower."),
    },
    dandelion = {
        name = _("From the French dent-de-lion, a lion's tooth, for the toothed edges of the leaves."),
        habitat = _("Almost anywhere there is open ground: lawns, verges, meadows and cracks in paving."),
        months = { 3, 10 },
        story = _("Every part can be eaten, and roasted roots have stood in for coffee in hard times. The first flowers of spring are one of the few meals bees can find then."),
        look = _("Look for a seed head, called a clock, and watch where the wind takes a few of the seeds."),
    },
    tulip = {
        name = _("Probably from a Persian word for turban, which the flower was said to resemble."),
        habitat = _("The wild species grow on the dry mountains and steppes of Central Asia."),
        months = { 4, 5 },
        story = _("Ottoman gardeners made the tulip a symbol of the court, and in the 1600s Dutch buyers paid very high prices for single bulbs. The famous boom and crash is told often, though historians now think the legend is bigger than what happened."),
        look = _("Look at a tulip at midday and again in the evening: many open in warmth and close in the cold."),
    },
    bracken = {
        name = _("From an old Scandinavian word for fern, still found in Swedish as bräken."),
        habitat = _("Open woods, heaths and hillsides, mostly on acid soil, on almost every continent."),
        months = { 4, 10 },
        story = _("People cut bracken for bedding and for roofing, and burned the fronds for the potash in the ashes. The young shoots are eaten in some places, but they are poisonous raw and are not safe to eat in quantity."),
        look = _("Look in spring for a young frond unrolling from a tight coil, shaped like a bishop's crook."),
    },
    narcissus = {
        name = _("From the Greek myth of a youth called Narcissus. Some ancient writers linked the name to a word for numbness, for the heavy scent."),
        habitat = _("Damp mountain meadows in southern Europe, from Spain to Greece."),
        months = { 4, 5 },
        story = _("The poet's narcissus has been grown since antiquity, and the flowers are used in perfumery. All parts are poisonous, so gardeners are careful not to mix the bulbs with food."),
        look = _("Look for the small red-edged cup in the middle of the white petals, and smell the flower from a short way off."),
    },
    lily = {
        name = _("From the Latin lilium, which came from a Greek word for the flower."),
        habitat = _("Probably from the eastern Mediterranean or the Balkans. The Madonna lily has been grown for so long that nobody is sure."),
        months = { 6, 7 },
        story = _("The Madonna lily appears on Minoan wall paintings more than three thousand years old, and later in paintings of the Annunciation. White, the flower came to stand for purity."),
        look = _("Look inside the flower for the six golden anthers that dust anything touching them with orange pollen."),
    },
    rose = {
        name = _("The name is Latin, rosa, and has passed with little change into most European languages."),
        habitat = _("The damask rose is a garden hybrid. The wild ancestors come from western Asia."),
        months = { 6, 7 },
        story = _("Roses have been grown for scent and for rose water for centuries. In Bulgaria and in Isparta in Turkey, the petals are picked by hand at dawn."),
        look = _("Look at the stem for the sharp points. Botanists call them prickles and not thorns, because they come off the skin of the stem and not from the wood."),
    },
    sunflower = {
        name = _("The Latin name Helianthus is from the Greek for sun and flower."),
        habitat = _("The prairies of North America, where wild sunflowers still grow."),
        months = { 7, 9 },
        story = _("Native peoples of North America grew sunflowers for seed and oil for thousands of years before Europeans carried them home. In Russia the plant became a major crop in the 1800s."),
        look = _("Look at the middle of the head and count the spirals of seeds in both directions: the two numbers are neighbours in the Fibonacci series."),
    },
    iris = {
        name = _("Iris is the Greek word for rainbow, and the name of the goddess who walked the rainbow."),
        habitat = _("Dry, sunny slopes around the Mediterranean and in western Asia."),
        months = { 5, 6 },
        story = _("Dried iris roots, called orris, were used to make perfume and to scent linen. The iris is also the flower of Florence, whose name is sometimes said to mean the city of flowers."),
        look = _("Look for the fuzzy beard on the lower petals, which works as a landing strip for bees."),
    },
    poppy = {
        name = _("From the Old English popæg, which came from the Latin papaver."),
        habitat = _("Fields and disturbed ground, and wherever soil has been turned, across Europe and western Asia."),
        months = { 6, 8 },
        story = _("After the First World War the red poppy that bloomed on the churned battlefields of Flanders became a symbol of remembrance. The seeds can lie in the soil for many years waiting for the ground to be disturbed."),
        look = _("Look for the seed capsule after the petals fall, with small holes at the top, like a pepper pot."),
    },
    bellflower = {
        name = _("Campanula, the botanical name, is Latin for little bell."),
        habitat = _("Dry grassland, dunes and rocky ground across the northern half of the world, where the plant is called the harebell, or the bluebell of Scotland."),
        months = { 7, 9 },
        story = _("The harebell is the flower the Scots call a bluebell, which is why two quite different plants share a name. Harebells tolerate thin, dry soils where little else flowers."),
        look = _("Look at how the thin stem bends in even a light wind, and the flowers nod and swing."),
    },
    honesty = {
        name = _("Honesty is for the pods, which hide nothing. The Latin Lunaria is from luna, the moon, for their round shape."),
        habitat = _("Hedgerows and waste ground in Europe, escaped from gardens."),
        months = { 4, 6 },
        story = _("The silver pods have long been dried for winter arrangements. They are also called the money plant, for the coin-like discs."),
        look = _("Look for the papery pods in late summer: rub off the outer layers and the pale disc left behind is the wall between the seeds."),
    },
    maple = {
        name = _("Maple is from the Old English mapol. Acer is the Latin for maple, and platanoides means like a plane tree."),
        habitat = _("Woods and hedgerows of Europe and western Asia, from the lowlands up into the hills."),
        months = { 4, 5 },
        story = _("Maple wood is hard and has been used for instruments, and the sap of some maples is boiled down into syrup. The Norway maple is also planted widely as a street tree."),
        look = _("Look for a pair of winged seeds, throw them up, and watch them spin as they fall."),
    },
    ginkgo = {
        name = _("From the Japanese for silver apricot. A European botanist wrote the name down as ginkgo in the 1700s, and the odd spelling stayed."),
        habitat = _("Wild only in a small part of China, though ginkgo has been grown in temple gardens for centuries."),
        months = { 10, 11 },
        story = _("Ginkgo is often called a living fossil, with relatives in the rocks of the age of the dinosaurs. A few trees in Hiroshima survived the bombing in 1945 and are still alive."),
        look = _("Look for the fan-shaped leaf with veins that fork and never join. Where the leaves fall in autumn, they often fall in one night."),
    },
    ivy = {
        name = _("From the Old English ifig. The Latin name Hedera is much older."),
        habitat = _("Woods, walls and rocks across Europe and western Asia."),
        months = { 9, 11 },
        story = _("Ivy was sacred to Dionysus in Greece and to the old holly and ivy of the winter festivals in northern Europe. The flowers are among the last of the year to feed insects."),
        look = _("Look for the two kinds of leaves, lobed ones low down on climbing stems and plain ones on the flowering branches high up."),
    },
    water_lily = {
        name = _("Nymphaea is from the Greek for nymph, because the flowers grow where water spirits live in the old stories."),
        habitat = _("Still, shallow ponds and slow rivers across Europe, rooted in the mud."),
        months = { 6, 9 },
        story = _("Painters have returned to the water lily again and again. Monet painted his own pond at Giverny for most of the last thirty years of his life."),
        look = _("Look at the floating leaf and the cut from the edge to the middle, and watch the flower open late in the morning and close by evening."),
    },
}
