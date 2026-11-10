#!/usr/bin/env bash
# Make SolarUI the start screen in a copied home folder: setup_start.sh <home>
set -euo pipefail
LC_ALL=C sed -i '' 's/\["start_with"\] = "[^"]*"/["start_with"] = "solarui"/' "$1/settings.reader.lua"
grep -q '"start_with"' "$1/settings.reader.lua" || { echo "no start_with setting to change" >&2; exit 1; }
