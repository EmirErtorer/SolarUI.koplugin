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

## Fonts

The fonts are under the SIL Open Font License; the licence texts are in `fonts/`.
See NOTICE.md.
