-- Who depends on whom in the garden: pairs of plants and animals with the
-- plain fact that links them. A link is shown only when both are in the
-- garden, so the web grows as the garden does. Written by hand.

local _ = require("solarui/gettext")

local Web = {}

Web.LINKS = {
    { "bee", "crocus", _("Crocuses flower in late winter and give bees one of their first meals of the year.") },
    { "bee", "dandelion", _("Dandelions open early in spring, when few other flowers do, and feed bees after the winter.") },
    { "bee", "ivy", _("Ivy flowers in autumn, when most other flowers are over, and bees and hoverflies feed on the flowers.") },
    { "bee", "sunflower", _("Bees gather pollen and nectar from the many small flowers of a sunflower head.") },
    { "butterfly", "bellflower", _("Butterflies sip nectar from harebells and other summer flowers.") },
    { "butterfly", "iris", _("Butterflies drink nectar from irises and look for warm, sheltered beds.") },
    { "ladybug", "rose", _("Roses attract aphids, and ladybirds and their larvae eat the aphids.") },
    { "moth", "lily", _("Strongly scented flowers that stay open into the evening feed the moths that come after the bees have gone.") },
    { "moth", "bee", _("Bees work the flowers by day and moths by night, so the flowers are visited round the clock.") },
    { "dragonfly", "water_lily", _("Dragonflies rest on lily leaves, and lay their eggs in the water among the stems.") },
    { "frog", "water_lily", _("Frogs sit on lily leaves, with only the face above the water.") },
    { "frog", "dragonfly", _("Dragonfly larvae eat tadpoles, and frogs catch adult dragonflies.") },
    { "koi", "water_lily", _("Lily leaves shade the pond, which keeps the water cooler for the fish.") },
    { "hedgehog", "snail", _("Hedgehogs eat snails and slugs, and gardens with hedgehogs have fewer of them.") },
    { "robin", "ivy", _("Ivy berries ripen in late winter and feed birds when other food is scarce.") },
    { "bee", "three_sisters", _("Squash flowers open early in the morning, and bees gather their pollen before the heat of the day.") },
    { "peacock", "sunflower", _("Peafowl eat seeds, and will take the seeds from the heads of fallen sunflowers.") },
    { "yuzsuz", "robin", _("She watches the robin for hours, and answers the robin's song with a chattering version of her own.") },
    { "yuzsuz", "peacock", _("The peacock believes he is the most magnificent creature in the garden. Nobody has told him about Yüzsüz yet.") },
}

-- The links whose two members are both in `present` (a set of ids): { a, b, text }.
function Web.links(present)
    local out = {}
    for _i, l in ipairs(Web.LINKS) do
        if present[l[1]] and present[l[2]] then out[#out + 1] = l end
    end
    return out
end

-- The links that involve one id, among those present.
function Web.of(id, present)
    local out = {}
    for _i, l in ipairs(Web.links(present)) do
        if l[1] == id or l[2] == id then out[#out + 1] = l end
    end
    return out
end

return Web
