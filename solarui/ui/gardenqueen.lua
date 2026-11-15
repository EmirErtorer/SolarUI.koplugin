-- What the reader can do with Yüzsüz The Magnificent from her card: pat her
-- left side, pat her right side, rub her belly, and feed her from her menu.
-- Each answer is a line in her own voice, shown in a notice, and she takes up
-- the pose that goes with it (see garden/yuzsuz.lua).

local App = require("solarui/app")
local Button = require("solarui/ui/button")
local Dialog = require("solarui/ui/dialog")
local GardenActions = require("solarui/ui/gardenactions")
local State = require("solarui/garden/state")
local Voice = require("solarui/garden/voice")
local Yuzsuz = require("solarui/garden/yuzsuz")
local _ = require("solarui/gettext")

local GardenQueen = {}

local said = 0   -- touches answered, so quick ones do not repeat a line

-- Say her line for `moment`, with {n} the count, then run `after`.
local function answer(moment, n, after)
    said = said + 1
    local line = Voice.say(Yuzsuz.ID, moment, { n = n, name = State.name(Yuzsuz.ID), salt = said })
    if line then App.toast(line) end
    if after then after() end
end

-- The actions on her card: { on_left, on_right, on_rub, on_feed }.
function GardenQueen.actions(after)
    return {
        on_left = function() local m, n = Yuzsuz.patLeft(); answer(m, n, after) end,
        on_right = function() local m, n = Yuzsuz.patRight(); answer(m, n, after) end,
        on_rub = function() local m, n = Yuzsuz.rub(); answer(m, n, after) end,
        on_feed = function() GardenQueen.menu(after) end,
    }
end

-- Feed her `food`: a meal costs dew like anyone's, and she answers about the food.
local function feed(food, after)
    App.closeDialog()
    local ok, why = State.feed(Yuzsuz.ID)
    if ok then return answer(Yuzsuz.ate(food), nil, after) end
    if why == "full" then return answer("food_full", nil, after) end
    GardenActions.say(false, why)
    if after then after() end
end

-- Open her menu: one button for each food, salami first.
function GardenQueen.menu(after)
    App.dialog(function(_close, w)
        local rows = {}
        for i, f in ipairs(Yuzsuz.FOODS) do
            rows[#rows + 1] = Button:new({ label = f.label, sub = f.sub, variant = i == 1 and "primary" or nil, on_tap = function() feed(f.id, after) end })
        end
        rows[#rows + 1] = Button:new({ label = _("Not now"), on_tap = function() App.closeDialog() end })
        return Dialog.card({ title = string.format(_("What does %s wish to eat?"), State.name(Yuzsuz.ID)),
            text = string.format(_("A meal is %d dew. She will eat anything on the menu, but she will remember what you chose."), State.FEED), lines = 3, rows = rows }, w)
    end)
end

return GardenQueen
