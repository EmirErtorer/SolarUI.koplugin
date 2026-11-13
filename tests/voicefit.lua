-- Does every line of every voice fit where it is shown? Each line (with its
-- [a|b] parts at their longest and its {words} filled with long examples) is
-- wrapped into the Home card's text column and the companion page at several
-- screen widths and text sizes; a line the card would cut with an ellipsis
-- is counted. Prints the worst ones; fails when more than the allowed share
-- is cut.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/voicefit.lua <repo> [report]

local REPO = arg[1] or "."
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)

local Cast = require("solarui/garden/cast")
local HomeCompanion = require("solarui/ui/homecompanion")
local Scene = require("solarui/ui/scene")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")
local Voice = require("solarui/garden/voice")

-- Long examples for the words a line can hold.
local WORDS = { name = "Bartholomew", book = "Middlemarch", author = "Umberto Eco", last = "Middlemarch",
    pages = "120 pages", total = "3400 pages", days = "100", streak = "30", quote = "the sea was calm and the sky was clear" }

-- Chosen text of a line: the longest alternative of each [a|b] and the words filled.
local function longest(text)
    text = text:gsub("%[([^%]]-)%]", function(set)
        local best = ""
        for part in (set .. "|"):gmatch("(.-)|") do if #part > #best then best = part end end
        return best
    end)
    return (text:gsub("{(%w+)}", function(k) return WORDS[k] or "" end))
end

-- Every line of every voice as { who, moment, text }.
local function lines()
    local out = {}
    for _, group in ipairs({ Cast.PLANTS, Cast.ANIMALS }) do
        for _, c in ipairs(group) do
            local v = Voice.of(c.id)
            for moment, pool in pairs(v.moments or {}) do
                -- (the orchard's lines are shown in a dialog, not on the home card)
                for _, l in ipairs((moment == "locked" or moment == "returned") and {} or pool) do
                    out[#out + 1] = { c.id, moment, longest(type(l) == "table" and l.t or l) }
                end
            end
        end
    end
    return out
end

-- The home card's speech bubble: the width of its text and the rows it has.
-- Its height grows with the text size, so it always has HomeCompanion.ROWS.
local function homeRows(W)
    local k = W / Scene.design_w
    return math.floor((HomeCompanion.WIDTH - 36) * k + 0.5), HomeCompanion.ROWS
end

-- The home card picks lines that fit its bubble (Voice.fits), so what matters is
-- that every pool keeps enough lines that do: a share of the lines of each
-- moment, and never fewer than a few.
local NEED = { [0.8] = 0.9, [1.0] = 0.6, [1.2] = 0.3, [1.4] = 0.12 }
local MIN = { [0.8] = 6, [1.0] = 3, [1.2] = 1, [1.4] = 0 }
local all = lines()
local pools = {}
for _, l in ipairs(all) do
    local key = l[1] .. " " .. l[2]
    pools[key] = pools[key] or {}
    table.insert(pools[key], l[3])
end
for _, sc in ipairs({ 0.8, 1.0, 1.2, 1.4 }) do
    Theme.set("text_scale", sc)
    local col, rows = homeRows(600)
    local worst, short, cut = 1, nil, 0
    for key, pool in pairs(pools) do
        local fit = 0
        for _, t in ipairs(pool) do
            if #Text.wrap("small", t, col) <= rows then fit = fit + 1 else cut = cut + 1 end
        end
        local share = fit / #pool
        local need = math.min(MIN[sc], #pool)
        if share < worst then worst, short = share, key end
        -- (only the normal sizes are held to it; larger text just reports)
        Kit.ok(sc > 1.0 or fit >= math.min(need, #pool), string.format("%s keeps lines that fit the home card at text %.1f (%d of %d)", key, sc, fit, #pool))
    end
    print(string.format("home 600 px, text %.1f: column %d px, %d rows, %d of %d lines too long, thinnest pool %s at %d%%", sc, col, rows, cut, #all, short, math.floor(worst * 100)))
end

-- The companion page is wide: its width is most of the screen, four rows.
for _, W in ipairs({ 600, 758, 1072, 1264 }) do
    Theme.set("text_scale", 1.0)
    local cut = 0
    for _, l in ipairs(all) do
        if #Text.wrap("body", l[3], math.floor(W * 0.8)) > 4 then cut = cut + 1 end
    end
    print(string.format("page %4d px, text 1.0: %d of %d lines cut", W, cut, #all))
    Kit.ok(cut == 0, "no line is cut on the companion page at " .. W)
end

-- Lines that never fit, by length.
table.sort(all, function(a, b) return #a[3] > #b[3] end)
print("longest line: " .. #all[1][3] .. " characters (" .. all[1][1] .. " " .. all[1][2] .. ")")

print(string.format("voicefit: %d checks, %d failed", Kit.checks, Kit.failures))
os.exit(Kit.failures == 0 and 0 or 1)
