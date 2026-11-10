-- SolarUI in the language KOReader is set to (setup_language.py): the home screen
-- and the log in that language, days and months in it too, and a translated text
-- reaching the real screen. SOLARUI_LANG says which.
local H = ...
local lang = os.getenv("SOLARUI_LANG") or "de"
local I18n = require("solarui/gettext")

H.step(3, function()
    H.check(I18n.language() == lang, "SolarUI took KOReader's language: " .. tostring(I18n.language()))
    H.check(H.find(I18n("Your reading")) ~= nil, "the home screen has the translated reading heading")
    H.shot("home-" .. lang)
    H.app().go("history")
end)
H.step(1, function()
    H.shot("log-" .. lang)
    H.app().go("settings")
    H.app().current().section = "about"
    H.app().update()
end)
H.step(1, function()
    H.check(H.find(I18n("Language")) ~= nil, "the About page names the language")
    H.shot("about-" .. lang)
end)
