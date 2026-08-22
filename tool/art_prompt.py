# -*- coding: utf-8 -*-
"""Wypisuje prompt dla generatora grafiki AI dla jednego przedmiotu z katalogu.

    python tool/art_prompt.py weapon_rifle_545
    python tool/art_prompt.py --all firearm
    python tool/art_prompt.py --missing

⚠️ Prompt jest budowany z katalogu, nie pisany ręcznie. Nazwa, masa, kaliber i
pojemność magazynka to liczby, na których stoi §10.3.1 — a grafika, która
pokazuje karabinek z magazynkiem na 5 naboi tam, gdzie gra mówi 30, jest
grafiką kłamiącą o mechanice.

Rozdzielczość: **1024x1024, kwadrat**. Nie 16:9 i nie 2:3.

Grafiki, które już są, mają 1408x768 i 848x1264 — to kadry sceniczne. Ikona w
wierszu plecaka jest kwadratem 40x40, a kwadratowy kadr z panoramy albo obcina
przedmiot, albo zostawia dwa pasy tła. Kwadrat u źródła znaczy, że ten sam plik
działa jako ikona 96 px i jako karta 512 px.
"""

import io
import json
import glob
import os
import sys

# Windows consoles default to cp1252 and this file speaks Polish and uses ⚠.
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

DATA = 'assets/data'
SKIP = {'names.json', 'loot_tables.json', 'notes.json', 'recipes.json'}

# Gdzie generator ma położyć wynik. Ta sama konwencja, której szuka kod:
# ścieżka wynika z tego, czym rzecz jest, a nie z rejestru do utrzymywania.
FOLDERS = {
    'firearm': 'items/weapons',
    'melee': 'items/weapons',
    'magazine': 'items/weapons',
    'attachment': 'items/weapons',
    'ammo': 'items/weapons',
    'armor': 'items/armors',
    'backpack': 'items/backpacks',
    'food': 'items/food',
    'medical': 'items/medical',
    'tool': 'items/tools',
    'crafting': 'items/crafting',
    'literature': 'items/literature',
}

# Co odróżnia rodzaj od rodzaju na obrazku. Jedno zdanie, nie akapit —
# generatory gubią szczegóły z długich list.
LOOK = {
    'firearm': 'a used but serviceable firearm, worn bluing, scuffed furniture',
    'melee': 'an improvised or worn hand weapon, chipped edge, taped grip',
    'magazine': 'a detached box magazine, scratched steel or polymer',
    'attachment': 'a small weapon accessory, matte finish',
    'ammo': 'a small heap of loose cartridges, brass dulled',
    'armor': 'worn protective clothing, frayed straps, faded fabric',
    'backpack': 'a scuffed pack, webbing worn, one strap repaired',
    'food': 'salvaged food, dented tin or crumpled wrapper, label faded',
    'medical': 'medical supplies, packaging creased, partly used',
    'tool': 'a working tool, handle worn smooth, metal scratched',
    'crafting': 'salvaged raw material, dirty and irregular',
    'literature': 'a battered book or manual, cover creased, pages foxed',
}


def catalogue():
    """Every item, as (id, type, props), from the shipped files."""
    out = []
    for path in sorted(glob.glob(os.path.join(DATA, '*.json'))):
        if os.path.basename(path) in SKIP:
            continue

        data = json.loads(io.open(path, encoding='utf-8').read())
        items = data.get('items') if isinstance(data, dict) else None
        if not items:
            continue

        for item in items:
            out.append(item)
    return out


def names():
    raw = json.loads(io.open(os.path.join(DATA, 'names.json'),
                             encoding='utf-8').read())
    return raw['names']


def english(item, table):
    key = 'item.%s.name' % item['id']
    return table.get(key, {}).get('en', item['id'])


def facts(item):
    """The numbers the picture must not contradict."""
    props = item.get('props', {})
    said = []

    weight = item.get('weight_kg')
    if weight:
        said.append('%s kg' % weight)

    for key, label in (('caliber', 'calibre'), ('magazine', 'magazine'),
                       ('capacity', 'capacity'), ('capacity_l', 'litres'),
                       ('reach_m', 'reach'), ('protection', 'protection')):
        if props.get(key) is not None:
            said.append('%s %s' % (label, props[key]))

    return ', '.join(said)


def prompt(item, table):
    kind = item.get('type', 'misc')
    name = english(item, table)
    folder = FOLDERS.get(kind, 'items/misc')
    look = LOOK.get(kind, 'a salvaged object')
    numbers = facts(item)

    lines = [
        '=' * 72,
        '%s   (%s)' % (item['id'], kind),
        'zapisz jako:  images/%s/%s.jpg' % (folder, item['id']),
        'rozdzielczosc: 1024 x 1024  (kwadrat, bez wyjatkow)',
        '=' * 72,
        '',
        'PROMPT',
        '------',
        ('Single %s, centred, filling most of the frame, seen from a '
         'three-quarter angle slightly above.' % name),
        '',
        look[0].upper() + look[1:] + '.',
        ('Post-apocalyptic survival game item icon. Photorealistic, '
         'natural materials, no gloss, no chrome, no glow.'),
        ('Flat neutral background, dark warm grey (#2A2724), completely '
         'plain and evenly lit — no scene, no floor, no horizon, no props, '
         'no shadow cast onto anything.'),
        ('Soft even light from the upper left. Muted desaturated palette. '
         'The object is worn and used, not new and not broken.'),
        'No text, no logos, no watermarks, no hands, no people.',
        'Square 1:1 composition. 1024x1024.',
        '',
    ]

    if numbers:
        lines += [
            'ZGODNOSC Z MECHANIKA (nie negocjowalne)',
            '---------------------------------------',
            numbers,
            ('⚠️ Grafika nie moze przeczyc tym liczbom. Karabinek z '
             'magazynkiem na 5 naboi tam, gdzie gra mowi 30, jest grafika '
             'klamiaca o mechanice — gracz podejmuje decyzje na podstawie '
             'obrazka szybciej niz na podstawie liczby.'),
            '',
        ]

    lines += [
        'NEGATIVE PROMPT',
        '---------------',
        ('scene, background objects, floor, table, ground, horizon, '
         'landscape, room, person, hand, text, letters, numbers, logo, '
         'watermark, signature, frame, border, collage, multiple objects, '
         'gradient background, vignette, bokeh, lens flare, cartoon, anime, '
         'cel shading, neon, glowing, pristine, brand new, shiny plastic'),
        '',
    ]

    return '\n'.join(lines)


def art_path(item):
    folder = FOLDERS.get(item.get('type', 'misc'), 'items/misc')
    return os.path.join('images', folder, '%s.jpg' % item['id'])


def main(argv):
    table = names()
    items = catalogue()

    if not argv:
        print(__doc__)
        return 1

    if argv[0] == '--missing':
        gone = [i for i in items if not os.path.exists(art_path(i))]
        print('Bez grafiki: %d z %d' % (len(gone), len(items)))
        for item in gone:
            print('  %-28s %s' % (item['id'], item.get('type')))
        return 0

    if argv[0] == '--all':
        wanted = argv[1] if len(argv) > 1 else None
        for item in items:
            if wanted and item.get('type') != wanted:
                continue
            print(prompt(item, table))
        return 0

    for wanted in argv:
        found = [i for i in items if i['id'] == wanted]
        if not found:
            print('Nie ma takiego przedmiotu: %s' % wanted)
            return 1
        print(prompt(found[0], table))

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
