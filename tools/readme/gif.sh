#!/usr/bin/env bash
# Make one of the README's moving pictures in the emulator (640x864, captured
# at twice that on a Retina Mac): companions, garden or twin.
#   SOLARUI_SHOT_BOOKS=<folder of the books> tools/readme/gif.sh <scene> <out.gif> [gif.py options]
set -euo pipefail
repo="$(cd "$(dirname "$0")/../.." && pwd)"
scene="$1"; out="$2"; shift 2
tmp="$(mktemp -d)"
E2E_NO_DIR=1 HOME_SETUP="$repo/tools/readme/setup_books.py" TIMEOUT=500 "$repo/tests/e2e/run.sh" "$repo/tools/readme/gif_$scene.lua" "$tmp/p" 640 864 180 >/dev/null || true
grep -E "^(FAIL|ERROR|SCENE)" "$tmp/p/drive.log" || true
python3 "$repo/tools/readme/gif/gif.py" "$tmp/p/$scene" "$out" "$@"
