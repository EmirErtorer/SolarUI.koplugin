# SolarUI

SolarUI is an Art Nouveau garden of a home screen for KOReader. The book you are
reading stands in front of a halo of roses, with a progress vine growing along
it. Your reading is shown as three flowers (today, the week and the year), the
books you opened last stand on a shelf, and a dock of plants along the bottom
takes you to the rest. Behind home are a library browser, collections, a reading
log, and settings for colours, fonts and more.

## Install

1. Download SolarUI, or copy this folder.
2. Put the folder in KOReader's `plugins` folder and name it `SolarUI.koplugin`.
3. Restart KOReader.
4. Open SolarUI with Settings > Home > Start with SolarUI, or from the Tools menu
   entry.

## Development

- `tests/run.sh` runs the lint, luacheck and the headless test suites on
  KOReader's real drawing code. It needs a KOReader emulator build (set `KO_DIR`
  if it is not in `~/koreader-emulator`). Add `--e2e` to also run the scenarios
  in the visible emulator.
- `tools/emulator.sh` copies the plugin into the emulator build and starts it.
- `tools/layout-editor.sh` renders the home and garden screens in the emulator
  at six screen sizes and opens a page where every named part (`home.cover`,
  `garden.btn_season`...) can be dragged, stretched or hidden, or changed by
  typing its name. The result is saved in `solarui/data/layout_overrides.lua`,
  in the poster's units, so one tweak fits every screen size. Parts are named
  in code with `scene:group(id, label, add)`.

## Fonts

The fonts are under the SIL Open Font License; the licence texts are in `fonts/`.
See NOTICE.md.
