-- What every flower and plant of the garden is in life: its common name in
-- English, its Latin name and its Turkish name, kept with the drawing that
-- shows it. Menus and the flower chooser read the names from here; the home
-- screen does not print them. Latin names are never translated.

local _ = require("solarui/gettext")

local Species = {}

-- Every species: id, the dock drawing that shows it (nil when it only grows
-- elsewhere on the home screen), English name, Latin name, Turkish name.
Species.LIST = {
    { id = "narcissus", dock = "dock_library", en = _("Poet's narcissus"), latin = "Narcissus poeticus", tr = "Nergis" },
    { id = "crocus", dock = "dock_history", en = _("Spring crocus"), latin = "Crocus vernus", tr = "Çiğdem" },
    { id = "pansy", dock = "dock_search", en = _("Garden pansy"), latin = "Viola \u{D7} wittrockiana", tr = "Hercai menekşe" },
    { id = "lily", dock = "dock_inkaway", en = _("Madonna lily"), latin = "Lilium candidum", tr = "Beyaz zambak" },
    { id = "chamomile", dock = "dock_settings", en = _("Chamomile"), latin = "Matricaria chamomilla", tr = "Papatya" },
    { id = "posy", dock = "dock_collections", en = _("Rose, daisy and tulip posy"), latin = "Rosa, Bellis, Tulipa", tr = "Gül, papatya ve lale demeti" },
    { id = "dandelion", dock = "dock_karahindiba", en = _("Dandelion"), latin = "Taraxacum officinale", tr = "Karahindiba" },
    { id = "maple", dock = "dock_maple", en = _("Norway maple leaf"), latin = "Acer platanoides", tr = "Akçaağaç yaprağı" },
    { id = "rose", dock = "dock_rose", en = _("Garden rose"), latin = "Rosa \u{D7} damascena", tr = "Gül" },
    { id = "tulip", dock = "dock_tulip", en = _("Garden tulip"), latin = "Tulipa gesneriana", tr = "Lale" },
    { id = "ginkgo", dock = "dock_ginkgo", en = _("Ginkgo"), latin = "Ginkgo biloba", tr = "Ginkgo" },
    { id = "bracken", dock = "dock_fern", en = _("Bracken fern"), latin = "Pteridium aquilinum", tr = "Eğrelti otu" },
    { id = "dandelion_clock", dock = "dock_clock", en = _("Dandelion seed head"), latin = "Taraxacum officinale", tr = "Karahindiba tohumu" },
    { id = "honesty", dock = "dock_medallion", en = _("Honesty seed pod"), latin = "Lunaria annua", tr = "Ay çiçeği tohum kabuğu" },
    { id = "sunflower", en = _("Sunflower"), latin = "Helianthus annuus", tr = "Ayçiçeği" },
    { id = "water_lily", en = _("White water lily"), latin = "Nymphaea alba", tr = "Beyaz nilüfer" },
    { id = "bellflower", en = _("Harebell"), latin = "Campanula rotundifolia", tr = "Çan çiçeği" },
    { id = "iris", en = _("Bearded iris"), latin = "Iris germanica", tr = "Süsen" },
    { id = "poppy", en = _("Corn poppy"), latin = "Papaver rhoeas", tr = "Gelincik" },
    { id = "ivy", en = _("Common ivy"), latin = "Hedera helix", tr = "Sarmaşık" },
}

-- The species with this id, or nil.
function Species.get(id)
    for _i, s in ipairs(Species.LIST) do
        if s.id == id then return s end
    end
end

-- The species a dock drawing shows, or nil.
function Species.ofDock(drawing)
    for _i, s in ipairs(Species.LIST) do
        if s.dock == drawing then return s end
    end
end

-- The species a launcher button can grow as, in order.
function Species.plants()
    local out = {}
    for _i, s in ipairs(Species.LIST) do
        if s.dock then out[#out + 1] = s end
    end
    return out
end

return Species
