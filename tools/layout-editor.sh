#!/usr/bin/env bash
# The layout editor: renders a screen in the real emulator at several screen
# sizes, then serves a page where each named part can be dragged, stretched or
# hidden, and the result copied back as placement tweaks.
#   tools/layout-editor.sh [screen]          render (default home), then serve
#   tools/layout-editor.sh --serve           serve what was rendered before
# KO_DIR points at the KOReader checkout (default ~/koreader-emulator).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
site="$here/dist/layout-editor"
port="${PORT:-8765}"
# name, emulator window width and height, dpi. The emulator draws everything
# twice as large as its window, so these are half the device's pixels.
PROFILES=(
    "emulator 600 800 167 Emulator window (what tools/emulator.sh shows)"
    "kindle-basic 300 400 167 600x800, 167 dpi"
    "paperwhite 379 512 212 758x1024, 212 dpi"
    "paperwhite-3 536 724 300 1072x1448, 300 dpi"
    "libra 632 840 300 1264x1680, 300 dpi"
    "landscape 724 536 300 1448x1072 on its side, 300 dpi"
)

# Render one screen at every size into $site/<screen>/<profile>.
render() {
    local screen="$1"
    mkdir -p "$site"
    for line in "${PROFILES[@]}"; do
        read -r name w h dpi label <<<"$line"
        echo "== $screen at $name ($label)"
        SOLARUI_EXPORT_SCREEN="$screen" "$here/tests/e2e/run.sh" "$here/tests/e2e/layoutexport.lua" "$site/$screen/$name" "$w" "$h" "$dpi" | tail -2
        rm -rf "$site/$screen/$name/home" "$site/$screen/$name/emulator.log"
        python3 - "$site/$screen/$name/layout.json" "$name" "$label" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["profile"], d["label"] = sys.argv[2], sys.argv[3]
json.dump(d, open(p, "w"))
PY
    done
}

# List what has been rendered, for the page.
manifest() {
    python3 - "$site" <<'PY'
import json, os, sys
site = sys.argv[1]
out = {}
for screen in sorted(os.listdir(site)):
    d = os.path.join(site, screen)
    if not os.path.isdir(d): continue
    profiles = []
    for name in os.listdir(d):
        p = os.path.join(d, name, "layout.json")
        if os.path.exists(p):
            j = json.load(open(p))
            profiles.append({"id": name, "label": j.get("label", name), "w": j["w"], "h": j["h"], "dpi": j["dpi"], "order": os.path.getmtime(p)})
    profiles.sort(key=lambda x: x["order"])
    out[screen] = profiles
json.dump(out, open(os.path.join(site, "manifest.json"), "w"))
PY
}

if [ "${1:-}" != "--serve" ]; then render "${1:-home}"; fi
cp "$here/tools/layout-editor/index.html" "$site/index.html"
manifest
echo "Layout editor: http://localhost:$port/   (Ctrl+C to stop)"
if [ -z "${NO_OPEN:-}" ]; then ( sleep 1; open "http://localhost:$port/" 2>/dev/null || true ) & fi
cd "$site" && exec python3 -m http.server "$port" --bind 127.0.0.1
