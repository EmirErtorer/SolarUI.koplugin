#!/usr/bin/env bash
# Set a copied KOReader home so SolarUI runs alone: CyberUI, SimpleUI, Bookshelf and ZenOS are
# switched off (ZEN=1 keeps ZenOS on), so a window is KOReader's own or SolarUI's and nobody else's.
home="$1"
python3 - "$home" "${ZEN:-}" <<'PY'
import os, re, sys
path = os.path.join(sys.argv[1], "settings.reader.lua")
off = ["CyberUI", "cyberui", "simpleui", "bookshelf"] + ([] if sys.argv[2] else ["zenos"])
block = '["plugins_disabled"] = {\n' + "".join('        ["%s"] = true,\n' % d for d in off) + "    },"
s = open(path, encoding="utf-8").read()
s, n = re.subn(r'\["plugins_disabled"\] = \{.*?\n    \},', block, s, count=1, flags=re.S)
if n == 0: s = s.replace("return {", "return {\n    " + block, 1)
open(path, "w", encoding="utf-8").write(s)
PY
