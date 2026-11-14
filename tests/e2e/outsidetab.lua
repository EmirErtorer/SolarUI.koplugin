-- The Outside tab of the field notes with the new things: the garden's pick,
-- a ticked thing with a note, a first with last year's date, the firsts and
-- the log; and the almanac page that says who was seen outside.
local H = ...
local dir = os.getenv("SOLARUI_DRIVE_SCRIPT"):match("^(.*)/[^/]+$")
local K = dofile(dir .. "/gardenkit.lua")(H)
local State = K.state()
local Prompts = require("solarui/garden/prompts")
K.shot("t01-outside-garden-pick", function()
    K.reset({ season = "winter" }); K.everyone()
    -- a week in which the garden points at someone
    while not Prompts.gardenWeek(Prompts.week(K.t)) do K.t = K.t + 7 * 86400 end
    State.get().animals.robin = State.get().animals.robin or { found = K.t, fed = K.t }
    K.settle()
    H.app().go("garden"); H.app().push("gardennotes", { tab = "outside" })
end, function() H.check(State.outsideWeek()[1].who ~= nil, "the thing to look at is the garden's pick") end)
K.shot("t02-tick-pick-and-note", function()
    State.toggleOutside(1)
    State.noteOutside(1, "A robin on the fence, singing at me")
    local d = State.get()
    d.outside_log[#d.outside_log + 1] = { t = K.t - 330 * 86400, w = Prompts.week(K.t - 330 * 86400), s = "winter", i = 12, note = "Under the hedge by the gate" }
    d.outside_now = nil
    H.app().update()
end)
K.shot("t03-firsts-and-log", function() H.app().update() end, function()
    H.check(#State.outsideFirsts() == 1, "the first is kept")
end)
K.shot("t04-the-pick-in-the-almanac", function()
    local who
    for _, e in ipairs(State.outsideLog()) do who = who or e.who end
    H.check(who ~= nil, "the log says who was seen")
    H.app().push("gardenpage", { id = who or "robin" })
end)
