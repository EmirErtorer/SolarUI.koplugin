#!/usr/bin/env bash
# Take the README's screenshots in the emulator at 640x864 (the shape of a 1072x1448 Kindle; a Retina Mac captures it at twice that) and put them in
# assets/screenshots:
#   SOLARUI_SHOT_BOOKS=<folder of the books to show> tools/readme/shots.sh
set -euo pipefail
repo="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
E2E_NO_DIR=1 HOME_SETUP="$repo/tools/readme/setup_books.py" TIMEOUT=400 "$repo/tests/e2e/run.sh" "$repo/tools/readme/shots.lua" "$tmp/p" 640 864 180 >/dev/null
mkdir -p "$repo/assets/screenshots"
rm -f "$repo/assets/screenshots/"*.png
cp "$tmp"/p/0[0-9]-*.png "$repo/assets/screenshots/"
grep -E "^(FAIL|ERROR)" "$tmp/p/drive.log" || true
# home in every colour scheme, light and dark, as one collage
E2E_NO_DIR=1 HOME_SETUP="$repo/tools/readme/setup_books.py" TIMEOUT=300 "$repo/tests/e2e/run.sh" "$repo/tools/readme/schemes.lua" "$tmp/s" 640 864 180 >/dev/null
python3 "$repo/tools/readme/schemes.py" "$tmp/s" "$repo/assets/screenshots/10-schemes.png"
ls "$repo/assets/screenshots"
