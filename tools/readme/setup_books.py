#!/usr/bin/env python3
"""Give the README's emulator copy a library of the screenshot books only (EPUBs
and PDFs), a reading history, a few weeks of reading and eight Ink Away notebooks:
    setup_books.py <copied home>   (the books' folder in SOLARUI_SHOT_BOOKS)"""
import glob, os, re, shutil, sqlite3, sys, time
home = os.path.realpath(sys.argv[1])   # one spelling of every path, as on a reader
src = os.environ["SOLARUI_SHOT_BOOKS"]
lib = os.path.join(home, "Books")
shutil.rmtree(lib, ignore_errors=True)
os.makedirs(lib)
books = []
for f in sorted(glob.glob(os.path.join(src, "*.epub")) + glob.glob(os.path.join(src, "*.pdf"))):
    dst = os.path.join(lib, os.path.basename(f))
    try:
        os.system('cp -c "%s" "%s" 2>/dev/null || cp "%s" "%s"' % (f, dst, f, dst))   # (a clone on APFS: the bird plates are large)
    except OSError:
        shutil.copy(f, dst)
    books.append(dst)
# the reading order: Braiding Sweetgrass first (the book being read)
FIRST = ["Braiding Sweetgrass", "The Overstory", "A Psalm", "The Seed Keeper", "The Serviceberry", "Neither Wolf", "Our Land", "Audubon"]
books.sort(key=lambda p: next((i for i, t in enumerate(FIRST) if t in p), 99))
now = int(time.time())
with open(os.path.join(home, "history.lua"), "w") as h:
    h.write("return {\n" + "".join(
        f'    [{i + 1}] = {{ ["file"] = "{p}", ["time"] = {now - 3600 * (i * 9 + 2)} }},\n' for i, p in enumerate(books)) + "}\n")
s = open(os.path.join(home, "settings.reader.lua")).read()
s = re.sub(r'\["lastfile"\] = "[^"]*"', f'["lastfile"] = "{books[0]}"', s)
s = re.sub(r'\["home_dir"\] = "[^"]*"', f'["home_dir"] = "{lib}"', s)
s = re.sub(r'\["start_with"\] = "[^"]*"', '["start_with"] = "solarui"', s)
open(os.path.join(home, "settings.reader.lua"), "w").write(s)
# Ink Away's notebooks: eight from the emulator's library under gentle names,
# each in one of the eight boards (the first-page covers would show test pages)
emu = glob.glob(os.path.expanduser("~/koreader-emulator/koreader-emulator-*/koreader"))[0]
src_ink, ink = os.path.join(emu, "ink away"), os.path.join(home, "ink away")
shutil.rmtree(ink, ignore_errors=True)
os.makedirs(ink)
NOTEBOOKS = [("notebook-20260911-031348", "Garden journal", "verdure"), ("notebook-20260926-133148", "Reading notes", "tooled"),
             ("notebook-20260911-032709", "Seed list", "nasturtium"), ("notebook-20260913-050940", "Birds seen", "peacock"),
             ("notebook-20260910-180133", "Field sketches", "iris"), ("Notebook 2026-10-03 14.32", "Recipes", "poppy"),
             ("notebook-20260926-131215", "Pond diary", "dragonfly"), ("Notebook 2026-10-03 14.33", "Letters", "ginkgo")]
covers, order = [], []
for i, (f, name, look) in enumerate(NOTEBOOKS):
    if os.path.exists(os.path.join(src_ink, f + ".inkaway")):
        dst = os.path.join(ink, name + ".inkaway")
        shutil.copy(os.path.join(src_ink, f + ".inkaway"), dst)
        t = now - 86400 * (i + 1)
        os.utime(dst, (t, t))
        covers.append('["%s.inkaway"]={["solar_cover"]="%s",},' % (name, look))
        order.append('"%s.inkaway",' % name)
with open(os.path.join(ink, ".inkaway-folder"), "w") as h:
    h.write('return {["covers"]={%s},["colors"]={},["order"]={%s},["folders"]={},}' % ("".join(covers), "".join(order)))
# a week of reading, mostly the book on home
db = sqlite3.connect(os.path.join(home, "settings", "statistics.sqlite3"))
db.execute("DELETE FROM page_stat_data"); db.execute("DELETE FROM book")
titles = ["Braiding Sweetgrass", "The Overstory", "A Psalm for the Wild-Built", "The Seed Keeper"]
for i, t in enumerate(titles, 1):
    db.execute("INSERT INTO book (id, title, authors, pages, total_read_time, total_read_pages, md5) VALUES (?,?,?,?,?,?,?)",
               (i, t, "", 400, 0, 0, "md5-%d" % i))
midnight = now - now % 86400
for day in range(21):
    if day % 6 == 5:
        continue   # (a day off now and then, as in life)
    for k, (book, minutes) in enumerate([(1, 22 + (day * 7) % 25), (2 + day % 3, 8 + (day * 5) % 14)]):
        start = midnight - day * 86400 + 20 * 3600 + k * 3000
        for p in range(minutes // 2):
            db.execute("INSERT INTO page_stat_data (id_book, page, start_time, duration, total_pages) VALUES (?,?,?,?,?)",
                       (book, p + 1, start + p * 120, 120, 400))
db.commit()
print("library:", len(books), "books")
