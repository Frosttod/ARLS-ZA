# -*- coding: utf-8 -*-
"""Robi z grafiki zrodlowej to, co wchodzi do gry.

    python tool/build_art.py            # przetwarza wszystko
    python tool/build_art.py --check    # tylko raport, nic nie zapisuje

images/**.jpg  ->  assets/images/**/{id}_96.webp  +  {id}_512.webp

⚠️ Zrodla nigdy nie trafiaja do APK. Trzydziesci piec plikow to 66 MB, a
katalog ma sto trzydziesci cztery przedmioty — ekstrapolacja to okolo 380 MB
przy limicie 200 MB na modul bazowy AAB w Google Play. Do tego JPG 1408x768
zdekodowany zajmuje 4,3 MB RAM, wiec dziesiec wierszy plecaka na ekranie to
43 MB.

Przetworzone: te same 66 MB to okolo 1,3 MB.

Dwa rozmiary, bo dwa zastosowania:

  96 px   wiersz plecaka, polki, ziemi. Rysowany jako 40 px z cacheWidth.
  512 px  karta przedmiotu, ekran schronu, panel miejsca.

Uruchamiane recznie, nie w buildzie. Grafiki zmieniaja sie rzadko, a build
ma byc powtarzalny — krok, ktory przy kazdym uruchomieniu produkuje pliki
odrobine innej wielkosci, to build, ktory nie jest.
"""

import io
import json
import glob
import os
import sys

from PIL import Image

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

SOURCE = 'images'
TARGET = os.path.join('assets', 'images')

ICON = 96
CARD = 512

# ⚠️ Nie 100. WebP przy 100 przestaje kompresowac i zaczyna zapisywac szum
# JPEG-a ze zrodla, ktory i tak juz tam jest — plik rosnie, obraz nie.
ICON_QUALITY = 82
CARD_QUALITY = 80

# ⚠️ Grafika, która jest żarłoczna, a nie używana.
#
# `placeholders/<kind>.jpg` to środkowy szczebel łańcucha zapasowego:
# id przedmiotu → rodzaj → ikona Material. Grafika "narzędzia" pod każde
# narzędzie, które jeszcze nie ma własnej, czyta się lepiej niż szara ikonka.
#
# `_unused/` to czyjaś praca, której gra jeszcze nie ma gdzie użyć. Odkładana,
# nie kasowana — i nie zgłaszana jako błąd, bo nie jest błędem.
UNUSED = '_unused'

DATA = os.path.join('assets', 'data')
SKIP_DATA = {'names.json', 'loot_tables.json', 'notes.json', 'recipes.json'}


def item_ids():
    """Every id the game knows, so a stray filename can be reported."""
    ids = set()
    for path in sorted(glob.glob(os.path.join(DATA, '*.json'))):
        if os.path.basename(path) in SKIP_DATA:
            continue

        data = json.loads(io.open(path, encoding='utf-8').read())
        items = data.get('items') if isinstance(data, dict) else None
        if not items:
            continue

        for item in items:
            ids.add(item['id'])
    return ids


def square(image):
    """A centred square crop, because a pack row is a square.

    ⚠️ Crop rather than letterbox. The art that exists is 1408x768 and
    848x1264 — scene framing — and padding it to a square would give every
    icon two bands of background where the panel should be. Cropping loses
    the edges of a scene and keeps the subject, which is what an icon is for.

    New art is generated square (see ART_BRIEF.txt), so this does nothing to
    it.
    """
    width, height = image.size
    side = min(width, height)

    left = (width - side) // 2
    top = (height - side) // 2

    return image.crop((left, top, left + side, top + side))


def convert(source, target, size, quality):
    image = Image.open(source).convert('RGB')
    image = square(image)
    image = image.resize((size, size), Image.LANCZOS)

    os.makedirs(os.path.dirname(target), exist_ok=True)
    image.save(target, 'WEBP', quality=quality, method=6)

    return os.path.getsize(target)


def main(argv):
    check = '--check' in argv
    known = item_ids()

    sources = sorted(
        p.replace(os.sep, '/')
        for p in glob.glob(os.path.join(SOURCE, '**', '*.jpg'), recursive=True)
    )

    if not sources:
        print('Nie ma nic w %s/' % SOURCE)
        return 1

    unmatched = []
    total_in = total_out = 0
    built = 0

    for source in sources:
        relative = source[len(SOURCE) + 1:]
        folder, name = os.path.split(relative)
        stem = os.path.splitext(name)[0]

        # ⚠️ Only the items/ tree has to match an id. Zombies, places, shelter
        # modules and skills are named by what they are, and the code looks
        # them up the same way.
        if folder.split('/')[0] == UNUSED:
            continue

        if folder.startswith('items/') and stem not in known:
            unmatched.append(relative)

        size_in = os.path.getsize(source)
        total_in += size_in
        built += 1

        if check:
            continue

        out = 0
        for suffix, side, quality in (
            ('_%d' % ICON, ICON, ICON_QUALITY),
            ('_%d' % CARD, CARD, CARD_QUALITY),
        ):
            target = os.path.join(TARGET, folder, '%s%s.webp' % (stem, suffix))
            out += convert(source, target, side, quality)

        total_out += out
        print('%-46s %7.0f kB -> %5.0f kB' %
              (relative, size_in / 1024.0, out / 1024.0))

    print()
    if check:
        print('Zrodla: %d plikow, %.1f MB' % (len(sources), total_in / 1048576.0))
    else:
        print('%d plikow: %.1f MB -> %.0f kB  (%.1f%% oryginalu)' %
              (built, total_in / 1048576.0, total_out / 1024.0,
               100.0 * total_out / total_in))

        spare = len(sources) - built
        if spare:
            print('%d w %s/ — pominiete' % (spare, UNUSED))

    if unmatched:
        print()
        print('⚠️ NIE PASUJE DO ZADNEGO ID (%d):' % len(unmatched))
        for name in unmatched:
            print('   %s' % name)
        print()
        print('   Nazwa pliku jest identyfikatorem przedmiotu — kod szuka')
        print('   grafiki po niej. Zmien nazwe na id z katalogu albo')
        print('   sprawdz, czy przedmiot w ogole istnieje.')
        print('   Lista id: python tool/art_prompt.py --missing')

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
