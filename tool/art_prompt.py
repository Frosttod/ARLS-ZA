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


# Rzeczy, ktore nie sa przedmiotami, ale maja folder i sa widoczne w grze.
WORLD = [
    ('zombies/walker', 'Walker',
     'a shambling infected human, ragged clothing, grey mottled skin, '
     'slack posture, head slightly down'),
    ('zombies/runner', 'Runner',
     'a lean infected human caught mid-stride, taut sinew, torn clothing, '
     'head forward, unnaturally fast posture'),
    ('zombies/brute', 'Brute',
     'a massively built infected human, swollen shoulders and arms, '
     'thickened hide, slow and heavy stance'),

    ('lootplaces/poi_pharmacy', 'Pharmacy', 'a looted small-town pharmacy shopfront'),
    ('lootplaces/poi_hardware', 'Hardware shop', 'a ransacked hardware shop entrance'),
    ('lootplaces/poi_grocery', 'Grocery shop', 'an emptied corner grocery shopfront'),
    ('lootplaces/poi_sports', 'Sports shop', 'a broken-into sports shop window'),
    ('lootplaces/poi_weapons', 'Gun shop', 'a gun shop with a shuttered, forced door'),
    ('lootplaces/poi_library', 'Library', 'a dim public library reading room, shelves disturbed'),
    ('lootplaces/poi_industrial', 'Industrial site', 'a dead industrial yard, rusted plant'),
    ('lootplaces/poi_hospital', 'Hospital', 'a hospital entrance, gurneys abandoned outside'),
    ('lootplaces/poi_military', 'Military site', 'a small abandoned military checkpoint'),
    ('lootplaces/poi_school', 'School', 'an empty school corridor seen from a doorway'),
    ('lootplaces/poi_warehouse', 'Warehouse', 'a dark warehouse interior, pallets toppled'),
    ('lootplaces/proc_abandoned_car', 'Abandoned car', 'a stripped car at a kerb, doors open'),
    ('lootplaces/proc_abandoned_house', 'Abandoned house', 'a boarded suburban house front'),
    ('lootplaces/proc_barn', 'Barn', 'a leaning timber barn, doors ajar'),
    ('lootplaces/proc_garage', 'Garage', 'a domestic garage with the door half up'),
    ('lootplaces/proc_waste', 'Waste bins', 'overflowing municipal bins in an alley'),
    ('lootplaces/proc_shelter', 'Bus shelter', 'a bus shelter with broken glass'),
    ('lootplaces/proc_hunting_stand', 'Hunting stand', 'a wooden hunting stand at a field edge'),
    ('lootplaces/proc_water_point', 'Water point', 'a rural standpipe and trough'),
    ('lootplaces/proc_roadside', 'Roadside', 'a verge with scattered spilled luggage'),
    ('lootplaces/proc_ambulance', 'Ambulance', 'an abandoned ambulance, rear doors open'),
    ('lootplaces/proc_police_car', 'Police car', 'an abandoned police car, one door open'),

    ('shelter/shelter', 'Shelter', 'the inside of a barricaded flat, boards over the windows'),
    ('shelter/storage', 'Storage module', 'shelving of salvaged timber, crates stacked'),
    ('shelter/workshop', 'Workshop module', 'a workbench with a vice and hand tools'),
    ('shelter/lounge', 'Lounge module', 'a mattress, blankets and a curtained corner'),
    ('shelter/lab', 'Lab module', 'improvised sealed containers and glassware on a bench'),

    ('skills/scout', 'Scouting', 'a figure crouched at a corner, watching a street'),
    ('skills/weapon', 'Weapon handling', 'hands checking over a rifle at a bench'),
    ('skills/medic', 'Medicine', 'hands winding a bandage over a forearm'),
    ('skills/crafting', 'Engineering', 'hands shaping metal at a vice'),
]


def world_prompt(path, name, look):
    scene = not path.startswith('zombies/')

    lines = [
        '=' * 72,
        path,
        'zapisz jako:  images/%s.jpg' % path,
        'rozdzielczosc: 1024 x 1024  (kwadrat, bez wyjatkow)',
        '=' * 72,
        '',
        'PROMPT',
        '------',
        '%s. %s.' % (name, look[0].upper() + look[1:]),
        ('Post-apocalyptic survival game art. Photorealistic, overcast '
         'daylight, muted desaturated palette, nothing glamorous.'),
    ]

    if scene:
        lines += [
            ('Deserted. No people, no bodies, no blood. Quiet and ordinary, '
             'as if everyone left in a hurry some months ago.'),
            'Composed square, subject centred, mid distance.',
        ]
    else:
        lines += [
            ('Full figure, centred, plain flat dark warm grey background '
             '(#2A2724), no scene, no floor, no horizon.'),
            ('Grounded and believable, not a monster: a person this happened '
             'to. No glowing eyes, no fangs, no claws, no gore.'),
        ]

    lines += [
        'No text, no logos, no watermarks, no UI.',
        'Square 1:1 composition. 1024x1024.',
        '',
        'NEGATIVE PROMPT',
        '---------------',
        ('text, letters, numbers, logo, watermark, signature, frame, border, '
         'UI, HUD, cartoon, anime, cel shading, neon, glowing eyes, fangs, '
         'claws, gore, blood, dismemberment, horror poster, cinematic '
         'lighting, lens flare, bokeh, vignette, oversaturated'),
        '',
    ]

    return chr(10).join(lines)

# ⚠️ Rodzaj to za grube sito dla czesci katalogu. `armor` obejmuje T-shirt i
# kamizelke z plytami; jedno zdanie dla obu daje dwa razy to samo zdjecie.
# Prefiks id jest tym, co je rozroznia, i jest juz w danych.
LOOK_BY_PREFIX = [
    ('cloth_', 'ordinary worn civilian clothing, faded and mended, '
               'no military look'),
    ('armor_', 'improvised or surplus body protection, scuffed panels, '
               'webbing straps'),
    ('med_', 'medical supplies, packaging creased, partly used'),
    ('mat_', 'a small pile of salvaged raw material, dirty and irregular'),
    ('tool_light', 'a battery lamp, lens scratched, casing scuffed'),
    ('lit_', 'a battered paperback or manual, cover creased, pages foxed'),
    ('pack_', 'a scuffed pack, webbing worn, one strap repaired'),
    ('mag_', 'a detached box magazine, scratched steel or polymer'),
    ('att_', 'a small clamp-on weapon sight or light, matte finish'),
    ('melee_', 'a worn hand tool pressed into use as a weapon, '
               'chipped edge, taped grip'),
    ('food_', 'salvaged food, dented tin or crumpled wrapper, label faded'),
]


def look_for(item):
    """The one sentence that makes this thing not the thing beside it."""
    for prefix, said in LOOK_BY_PREFIX:
        if item['id'].startswith(prefix):
            return said
    return LOOK.get(item.get('type', 'misc'), 'a salvaged object')


STYLE = """STYL — obowiazuje kazda grafike w tej liscie
============================================

Post-apocalyptic survival game art. Photorealistic. Overcast daylight,
soft and even, no cinematic contrast. Muted desaturated palette: greys,
browns, faded olive. Nothing glamorous, nothing heroic, nothing shiny.

Everything is used. Objects are worn, scratched, faded, repaired — not
new and not destroyed. This is a world people left a few months ago, not
a battlefield.

KADR: kwadrat 1:1, 1024 x 1024. Bez wyjatkow.
  Ikona w plecaku to kwadrat 40 px, a kwadratowy wycinek z panoramy albo
  przecina przedmiot, albo zostawia dwa pasy tla. Kwadrat u zrodla znaczy,
  ze ten sam plik obsluguje ikone 96 px i karte 512 px.

TLO PRZEDMIOTOW I POSTACI: plaskie, rowno oswietlone, ciemny cieply szary
  #2A2724. Bez sceny, bez podlogi, bez horyzontu, bez rekwizytow, bez
  cienia rzucanego na cokolwiek.
  JPG nie ma kanalu alfa, wiec jednolite tlo mozna wyciac albo zostawic w
  kolorze panelu. Sceny nie da sie ani jedno, ani drugie.

TLO MIEJSC: prawdziwa scena, mid distance, pusto. Bez ludzi, bez zwlok,
  bez krwi.

NIGDY: tekst, cyfry, logo, znak wodny, podpis, ramka, UI, HUD, kolaz,
  wiele obiektow w kadrze, cartoon, anime, cel shading, neon, swiecace
  oczy, kly, pazury, gore, lens flare, bokeh, winieta, przesycone kolory.

NAZWY PLIKOW: dokladnie tak, jak podano przy kazdej pozycji. Nazwa pliku
  jest identyfikatorem przedmiotu w grze i kod znajduje grafike po niej.
"""


def brief_line(item, table):
    """One line per item: where it goes, what it is, what it must not deny."""
    kind = item.get('type', 'misc')
    folder = FOLDERS.get(kind, 'items/misc')
    look = look_for(item)
    numbers = facts(item)

    said = '%-34s | %s' % ('%s/%s.jpg' % (folder, item['id']),
                           english(item, table))
    said += ' — %s' % look
    if numbers:
        said += '  [%s]' % numbers
    return said


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

    if argv[0] == '--brief':
        print(STYLE)
        print()
        print('PRZEDMIOTY  (%d)' % len(items))
        print('=' * 72)

        seen = None
        for item in items:
            kind = item.get('type')
            if kind != seen:
                seen = kind
                print()
                print('-- %s' % kind)
            print('  ' + brief_line(item, table))

        print()
        print()
        print('SWIAT  (%d)' % len(WORLD))
        print('=' * 72)

        group = None
        for path, name, look in WORLD:
            head = path.split('/')[0]
            if head != group:
                group = head
                print()
                print('-- %s' % head)
            print('  %-34s | %s — %s' % ('%s.jpg' % path, name, look))

        print()
        return 0

    if argv[0] == '--world':
        for path, name, look in WORLD:
            print(world_prompt(path, name, look))
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
