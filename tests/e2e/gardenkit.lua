-- Helpers shared by the garden scenarios (gardenall*.lua): a garden in a known
-- state (fake clock and reading numbers, the hour, the season, the weather),
-- a step that does something and then saves a numbered screenshot, taps on a
-- plant or an animal in the poster, and the list of who is shown.
-- Use: local K = dofile(dir .. "/gardenkit.lua")(H)

return function(H)
    local K = {}
    local UIManager = require("ui/uimanager")
    local Cast = require("solarui/garden/cast")
    local Care = require("solarui/garden/care")
    local Season = require("solarui/garden/season")
    local Settings = require("solarui/settings")
    local State = require("solarui/garden/state")
    local Weather = require("solarui/garden/weather")

    -- the toasts, to check what was said
    K.toasts = {}
    local app = H.app()
    local toast = app.toast
    app.toast = function(text) K.toasts[#K.toasts + 1] = text; return toast(text) end
    function K.lastToast() return K.toasts[#K.toasts] end

    K.T0 = 1700000000
    K.t = K.T0
    K.weather = nil
    local real_weather = State.weather

    -- A fresh garden. o: { season, hour, total (pages), books, streak, dew, seeds, guide (seen, default true), weather ("clear".. or nil for none) }
    function K.reset(o)
        o = o or {}
        if H.app().overlay() then H.app().closeDialog() end   -- (nothing left open from before)
        Settings.set("garden", nil)
        State.unload()
        K.t = K.T0
        State.clock = function() return K.t end
        K.reading = { total = o.total or 400, pages = o.pages or {}, streak = o.streak or 0, books = o.books or 0, days = {}, year_books = o.year_books or 0 }
        State.source = function() return K.reading end
        Settings.set("garden_season", o.season or "spring")
        Settings.set("garden_hour", o.hour or 12)
        Settings.set("garden_weather", true)
        K.weather = o.weather or "clear"
        State.weather = function() return K.weather end
        local d = State.get()
        d.weather_day = require("solarui/garden/visits").day(K.t)   -- (no rain in the way of a plant that is meant to be thirsty)
        d.bonus = o.dew or 500
        d.collected = o.seeds or 4
        if o.guide ~= false then d.guide_seen = true end
        K.settle()
    end

    -- Every animal found (as in a garden with everything earned).
    function K.everyone()
        local d = State.get()
        for _, a in ipairs(Cast.ANIMALS) do d.animals[a.id] = d.animals[a.id] or { found = K.t, fed = K.t } end
        if not d.plants.three_sisters then d.plants.three_sisters = { stage = 4, grown = 0, at = K.t, watered = K.t, gen = 1 } end
    end

    -- Put every plant at `stage` and `state` ("fine", "thirsty", "wilted").
    function K.plants(stage, state)
        for _, p in ipairs(Cast.PLANTS) do
            local rec = State.get().plants[p.id]
            if rec then
                rec.stage, rec.grown, rec.at, rec.gen = stage, 0, K.t, rec.gen or 1
                local eff = require("solarui/garden/season").adjust(p)
                local i = eff.interval or 0
                rec.watered = state == "wilted" and (K.t - 3 * i) or state == "thirsty" and (K.t - 1.5 * i) or K.t
                rec.noted = nil
            end
        end
    end

    -- Every animal content, hungry or hiding.
    function K.animals(mood)
        for _, a in ipairs(Cast.ANIMALS) do
            local rec = State.get().animals[a.id]
            if rec then rec.fed = mood == "hiding" and (K.t - 3 * a.interval) or mood == "hungry" and (K.t - 1.5 * a.interval) or K.t; rec.noted = nil end
        end
    end

    -- Hold the clock and the season steady (no growth on its own).
    function K.settle()
        for _, rec in pairs(State.get().plants) do rec.at = K.t end
    end

    -- Do `fn`, wait, then save screenshot `name` and run `check`.
    function K.shot(name, fn, check)
        H.step(.3, function() if fn then fn() end end)
        H.step(.45, function()
            UIManager:forceRePaint()
            H.shot(name)
            if check then check() end
        end)
    end

    -- Do `fn` and nothing else (a pause for a repaint).
    function K.do_(fn, delay)
        H.step(delay or .3, fn)
    end

    -- Show the garden screen.
    function K.go()
        H.app().go("garden")
    end

    -- Re-show it after something changed.
    function K.update()
        H.app().update()
    end

    -- Who is in the garden now, in the order the card's arrows go: plants, then
    -- animals about (or hiding).
    function K.inhabitants()
        local out = {}
        for _, e in ipairs(State.plants()) do out[#out + 1] = e.def.id end
        for _, e in ipairs(State.animals()) do
            if e.here or e.mood == Care.HIDING then out[#out + 1] = e.def.id end
        end
        return out
    end

    -- The garden's touch areas in the order the poster makes them: who each is.
    function K.touchOrder()
        local ids = {}
        for _, e in ipairs(State.plants()) do ids[#ids + 1] = e.def.id end
        ids[#ids + 1] = "book"
        if State.peek() then ids[#ids + 1] = "peek" end
        for _, e in ipairs(State.animals()) do
            if e.here or e.mood == Care.HIDING or e.resting then ids[#ids + 1] = e.def.id end
        end
        return ids
    end

    -- The plain areas of the garden that answer a tap (not the buttons or pictures).
    function K.touches()
        local g = H.app().current()
        local out = {}
        for _, c in ipairs(g.scene and g.scene.children or {}) do
            if c.on_tap and c.x and not c.name and c.label == nil and c.text == nil and not c.children then out[#out + 1] = c end
        end
        return out
    end

    -- Tap the poster's plant, animal, the book or the peeking face by id.
    function K.tapOn(id)
        UIManager:forceRePaint()   -- (a rebuilt screen has no places until it is painted)
        local order, list = K.touchOrder(), K.touches()
        for i, who in ipairs(order) do
            if who == id then
                local el = list[i]
                if not el then H.check(false, "a touch area for " .. id); return false end
                H.tapAt(el.x + el.w / 2, el.y + el.h / 2)
                return true
            end
        end
        H.check(false, id .. " is in the garden to tap")
        return false
    end

    -- The plain areas of the dialog on screen that answer a tap, in the order they were made.
    function K.overlayTouches()
        UIManager:forceRePaint()
        local out = {}
        local function walk(el)
            if type(el) ~= "table" then return end
            if el.on_tap and el.x and not el.name and el.label == nil and el.text == nil and not el.children and not el.child then out[#out + 1] = el end
            for _, c in ipairs(el.children or {}) do walk(c) end
            if el.child then walk(el.child) end
        end
        walk(H.app().overlay())
        return out
    end

    -- Tap the heading button of the garden whose art is `art` (or whose icon is `icon`).
    function K.tapHeading(art, icon)
        UIManager:forceRePaint()
        local el = H.findWhere(function(e) return (art and e.art and e.art[1] == art) or (icon and e.icon == icon and e.variant == "icon") end)
        if not el then H.check(false, "the heading button " .. tostring(art or icon) .. " is there"); return false end
        H.tapAt(el.x + el.w / 2, el.y + el.h / 2)
        return true
    end

    function K.state() return State end
    function K.cast() return Cast end
    return K
end
