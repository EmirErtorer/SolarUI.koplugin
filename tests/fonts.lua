-- Every font set loads and draws text in every kind of text, the way an
-- older KOReader would load it: Font:getFace is made to refuse an absolute
-- path (releases up to 2026.07 put their own fonts folder in front of every
-- name, which took KOReader down for CyberUI once), and the sample holds the
-- Turkish letters and marks every set must have a glyph for or draw safely.
-- Run: cd <emulator>/koreader && ./luajit <repo>/tests/fonts.lua <repo>

local REPO = arg[1] or "."
local Kit = dofile(REPO .. "/tests/kit.lua").boot(REPO)
local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local Registry = require("solarui/theme/registry")
local Settings = require("solarui/settings")
local Text = require("solarui/gfx/text")
local Theme = require("solarui/theme")

local SAMPLE = "Çağrı Şişli İıĞ ÖÜöü 0123 Hajime Nakamura - Budha (2012) \u{2013} \u{2026}"
local KINDS = { "display", "title", "heading", "body", "small", "label", "micro", "number", "clock", "hero" }

-- Font:getFace as releases up to 2026.07 have it: an absolute path is an error.
local real = Font.getFace
Font.getFace = function(self, name, size, ...)
    if type(name) == "string" and name:sub(1, 1) == "/" then error("absolute font path: " .. name) end
    return real(self, name, size, ...)
end

local bb = Blitbuffer.new(900, 120, Blitbuffer.TYPE_BBRGB32)
for _i, set in ipairs(Registry.fontSets()) do
    Settings.set("fontset", set.id)
    Theme.refresh()
    for _j, kind in ipairs(KINDS) do
        local ok, err = pcall(function()
            local f = Theme.text(kind, set.id)
            assert(f.height > 0 and f.ascent > 0, "no metrics")
            bb:fill(Blitbuffer.COLOR_WHITE)
            Text.draw(bb, 4, 4, kind, Text.fit(kind, SAMPLE, 880), Blitbuffer.COLOR_BLACK)
            assert(Text.width(kind, SAMPLE) > 0, "no width")
        end)
        Kit.ok(ok, set.id .. " / " .. kind .. " loads and draws: " .. tostring(err))
    end
end
-- a font that is not there falls back instead of failing
Settings.set("fontset", "device:/nowhere/Missing.ttf")
Theme.refresh()
Kit.ok(pcall(function() return Theme.text("body").height > 0 end), "a missing device font falls back to KOReader's")
Settings.set("fontset", Registry.fontSets()[1].id)
Theme.refresh()
Font.getFace = real
Kit.finish("fonts")
