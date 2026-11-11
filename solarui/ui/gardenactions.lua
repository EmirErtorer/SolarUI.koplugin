-- What the buttons of a plant's or animal's card do: water, feed, cut back,
-- bring into bloom, rename. Shared by the garden screen and the popup over
-- home. Each says what happened (or why it could not be done) in a notice,
-- then calls `after` so the screen shows the new state.

local App = require("solarui/app")
local State = require("solarui/garden/state")
local _ = require("solarui/gettext")

local GardenActions = {}

-- Say what an action did, or why it could not be done.
function GardenActions.say(ok, why, done)
    if ok then return App.toast(done) end
    App.toast(({ dew = _("Not enough dew. It comes from the pages you read."), dry = _("This one needs no watering."),
        fresh = _("It has only just had a drink."), full = _("It has only just eaten."),
        seed = _("No seeds. Finish a book, or cut back a plant that has gone to seed."), bloom = _("It is in bloom already."),
        none = _("Not in the garden.") })[why] or "")
end

-- The actions for the plant or animal `id`: { on_water, on_feed, on_collect,
-- on_rename, on_sow }.
function GardenActions.of(id, after)
    local say = GardenActions.say
    return {
        on_water = function() local ok, why = State.water(id); say(ok, why, string.format(_("%s has had a drink."), State.name(id))); after() end,
        on_feed = function() local ok, why = State.feed(id); say(ok, why, string.format(_("%s has eaten."), State.name(id))); after() end,
        on_collect = function() State.collect(id); App.toast(_("Cut back. You have a seed.")); after() end,
        on_rename = function() App.input(_("A name for it"), State.rec(id).nick or "", function(text) State.rename(id, text); after() end, _("Save")) end,
        on_sow = function() local ok, why = State.sow(id); say(ok, why, string.format(_("%s is in bloom."), State.name(id))); after() end,
    }
end

return GardenActions
