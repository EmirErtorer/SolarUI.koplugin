#!/usr/bin/env bash
# Show KOReader's own windows with SolarUI's skin off and on, side by side.
#   tools/skin-compare.sh [out_dir] [width height dpi]
# Writes <out_dir>/<name>-before.png, -after.png and <name>-both.png, and
# SKIN_CASES=notice,confirm limits which windows are shown.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$here/dist/skin-compare}"
shift || true
HOME_SETUP="$here/tests/e2e/setup_alone.sh" "$here/tests/e2e/run.sh" "$here/tests/e2e/skins.lua" "$out" "$@" | tail -40
for before in "$out"/*-before.png; do
    name="$(basename "$before" -before.png)"
    after="$out/$name-after.png"
    [ -f "$after" ] || continue
    magick "$before" "$after" +append -resize 1800x "$out/$name-both.png"
done
rm -rf "$out/home"
echo "side by side pictures in $out"
