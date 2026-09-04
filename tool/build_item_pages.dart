/// Builds the item catalogue pages of the project site, from the game's data.
///
/// The site is a summary of the design document, and until now the items on it
/// were a handful of examples typed by hand. Typed figures drift: the moment a
/// tin of beans is rebalanced the page is quietly wrong, and a page that is
/// quietly wrong is worse than no page. So it is generated — every number here
/// is read out of `assets/data/*.json`, the same files the game ships.
///
/// Run it after changing item data:
///
/// ```
/// dart run tool/build_item_pages.dart
/// ```
///
/// It writes `items.html` and `pl/items.html` into the site repository beside
/// this one. Nothing else on the site is touched.
library;

import 'dart:convert';
import 'dart:io';

import 'site_page.dart';

const String kSiteDir = '../ARLS-ZA-Game';

const List<String> kFiles = [
  'weapons',
  'ammo',
  'melee',
  'armor',
  'backpacks',
  'food',
  'medical',
  'literature',
  'tools',
  'attachments',
  'crafting',
];

void main(List<String> args) {
  final root = Directory.current;
  final site = Directory('${root.path}/$kSiteDir');
  if (!site.existsSync()) {
    stderr.writeln('No site at ${site.path}');
    exitCode = 1;
    return;
  }

  final names = _readNames();
  final items = <Map<String, dynamic>>[];
  for (final file in kFiles) {
    final data =
        jsonDecode(File('assets/data/$file.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final item in data['items'] as List<dynamic>) {
      items.add(item as Map<String, dynamic>);
    }
  }

  // A category with no table would vanish from the page silently, which is
  // exactly the drift this generator exists to prevent.
  final known = {for (final kind in _kinds) kind.type};
  final missing = {
    for (final item in items)
      if (!known.contains(item['type'])) '${item['type']}',
  };
  if (missing.isNotEmpty) {
    stderr.writeln('No table for: ${missing.join(', ')}');
    exitCode = 1;
    return;
  }

  File('${site.path}/items.html')
    ..createSync(recursive: true)
    ..writeAsStringSync(_page(items, names, language: 'en'));

  File('${site.path}/pl/items.html')
    ..createSync(recursive: true)
    ..writeAsStringSync(_page(items, names, language: 'pl'));

  stdout.writeln('${items.length} items written to ${site.path}');
}

Map<String, Map<String, String>> _readNames() {
  final raw =
      jsonDecode(File('assets/data/names.json').readAsStringSync())
          as Map<String, dynamic>;

  return {
    for (final entry in raw.entries)
      if (entry.value is Map<String, dynamic>)
        entry.key: {
          for (final language in (entry.value as Map<String, dynamic>).entries)
            language.key: '${language.value}',
        },
  };
}

// --------------------------------------------------------------- the page ---

String _page(
  List<Map<String, dynamic>> items,
  Map<String, Map<String, String>> names, {
  required String language,
}) {
  final pl = language == 'pl';
  final root = pl ? '../' : '';
  final buffer = StringBuffer();

  final present = [
    for (final kind in _kinds)
      if (items.any((item) => item['type'] == kind.type)) kind,
  ];

  buffer.write(
    sitePageOpen(
      pl: pl,
      pageFile: 'items.html',
      title: pl ? 'Katalog przedmiotów' : 'Item catalogue',
      subtitle: pl
          ? 'Masa, objętość i parametry · prosto z danych gry'
          : 'Mass, volume and figures · straight from the game data',
      description: pl
          ? 'Wszystkie przedmioty w ARLS-ZA z ich masą, objętością i parametrami — prosto z plików danych gry.'
          : 'Every item in ARLS-ZA with its mass, volume and figures — straight from the game data files.',
      eyebrow: '${items.length} ${pl ? 'przedmiotów' : 'items'}',
      thesis: [
        pl
            ? '<strong>Każda liczba tutaj jest tą, którą wczytuje gra.</strong> Ta strona powstaje z <code>assets/data/*.json</code> — plików, które trafiają do aplikacji — więc nie ma jak rozjechać się z rozgrywką.'
            : '<strong>Every figure here is the one the game loads.</strong> This page is generated from <code>assets/data/*.json</code>, the files that ship inside the app, so it cannot quietly drift out of step with play.',
        pl
            ? '<a href="${root}loot.html">Gdzie który przedmiot się znajduje →</a>'
            : '<a href="${root}loot.html">Where each item is actually found →</a>',
      ],
      railTitle: pl ? 'Kategorie' : 'Categories',
      rail: [
        for (final kind in present)
          RailEntry(anchor: kind.type, label: kind.title(pl)),
      ],
    ),
  );

  // A count per kind, so the shape of the catalogue is visible before the
  // tables are read.
  buffer.writeln('      <section class="sec">');
  buffer.writeln('        <div class="stats">');
  for (final kind in present) {
    final count = items.where((item) => item['type'] == kind.type).length;
    buffer.writeln(
      '          <div class="stat"><b>$count</b><span>${escapeHtml(kind.title(pl))}</span></div>',
    );
  }
  buffer.writeln('        </div>');
  buffer.writeln('      </section>');
  buffer.writeln();

  for (final kind in present) {
    final rows = items.where((item) => item['type'] == kind.type).toList()
      ..sort(
        (a, b) =>
            _name(a, names, language).compareTo(_name(b, names, language)),
      );

    buffer.writeln('      <section class="sec" id="${kind.type}">');
    buffer.writeln('        <div class="sec__hd">');
    buffer.writeln(
      '          <span class="sec__no">${escapeHtml(kind.title(pl))}</span>',
    );
    buffer.writeln('          <h2>${escapeHtml(kind.heading(pl))}</h2>');
    buffer.writeln(
      '          <p class="sec__lede">${escapeHtml(kind.lede(pl))}</p>',
    );
    buffer.writeln('        </div>');
    buffer.writeln('        <div class="scroller">');
    buffer.writeln('          <table class="tbl">');

    buffer.write('            <thead><tr>');
    buffer.write('<th scope="col">${pl ? 'Przedmiot' : 'Item'}</th>');
    for (final column in kind.columns) {
      buffer.write(
        '<th scope="col" class="n">${escapeHtml(column.title(pl))}</th>',
      );
    }
    buffer.write(
      '<th scope="col" class="n">${pl ? 'Masa' : 'Mass'}</th>'
      '<th scope="col" class="n">${pl ? 'Objętość' : 'Volume'}</th>'
      '<th scope="col">${pl ? 'Skąd' : 'Found in'}</th>',
    );
    buffer.writeln('</tr></thead>');

    buffer.writeln('            <tbody>');
    for (final item in rows) {
      final props = (item['props'] as Map<String, dynamic>?) ?? const {};
      buffer.write('              <tr id="item-${item['id']}">');
      buffer.write(
        '<th scope="row">${escapeHtml(_name(item, names, language))}</th>',
      );
      for (final column in kind.columns) {
        buffer.write(
          '<td class="n">${escapeHtml(column.read(item, props, pl))}</td>',
        );
      }
      buffer.write(
        '<td class="n">${_mass(item)}</td>'
        '<td class="n">${_volume(item)}</td>'
        '<td>${escapeHtml(_tags(item, pl))}</td>',
      );
      buffer.writeln('</tr>');
    }
    buffer.writeln('            </tbody>');
    buffer.writeln('          </table>');
    buffer.writeln('        </div>');
    buffer.writeln('      </section>');
    buffer.writeln();
  }

  buffer.write(
    sitePageClose(
      pl: pl,
      pageFile: 'items.html',
      note: pl
          ? 'Strona generowana z danych gry przez <code>tool/build_item_pages.dart</code>. Nazwy pochodzą z <code>names.json</code>, reszta z plików kategorii. Zasady, które te liczby obsługują, opisuje <a href="https://github.com/Frosttod/ARLS-ZA/blob/main/ARLS-ZA_design_doc_v2.md">dokument projektowy</a>.'
          : 'Generated from the game data by <code>tool/build_item_pages.dart</code>. Names come from <code>names.json</code>, everything else from the category files. The rules these figures feed are in the <a href="https://github.com/Frosttod/ARLS-ZA/blob/main/ARLS-ZA_design_doc_v2.md">design document</a>.',
    ),
  );

  return buffer.toString();
}

// ------------------------------------------------------------- the tables ---

/// One column of a table: what it is called, and how to read it off an item.
class _Column {
  const _Column(this._en, this._pl, this.read);

  final String _en;
  final String _pl;
  final String Function(
    Map<String, dynamic> item,
    Map<String, dynamic> props,
    bool pl,
  )
  read;

  String title(bool pl) => pl ? _pl : _en;
}

/// One kind of thing, and the columns worth showing for it.
class _Kind {
  const _Kind({
    required this.type,
    required this.titleEn,
    required this.titlePl,
    required this.headingEn,
    required this.headingPl,
    required this.ledeEn,
    required this.ledePl,
    required this.columns,
  });

  final String type;
  final String titleEn;
  final String titlePl;
  final String headingEn;
  final String headingPl;
  final String ledeEn;
  final String ledePl;
  final List<_Column> columns;

  String title(bool pl) => pl ? titlePl : titleEn;
  String heading(bool pl) => pl ? headingPl : headingEn;
  String lede(bool pl) => pl ? ledePl : ledeEn;
}

String _num(Object? value, {int decimals = 0, String unit = ''}) {
  if (value is! num) return '—';
  final text = value.toDouble().toStringAsFixed(decimals);
  return unit.isEmpty ? text : '$text $unit';
}

final List<_Kind> _kinds = [
  _Kind(
    type: 'firearm',
    titleEn: 'Firearms',
    titlePl: 'Broń palna',
    headingEn: 'What a shot costs',
    headingPl: 'Ile kosztuje strzał',
    ledeEn:
        'Muzzle energy drives the wound through a six-tenths power law, so a '
        'small calibre is never written off. What is heard is the other half '
        'of the price.',
    ledePl:
        'Energia wylotowa wchodzi do rany przez potęgę 0,6, więc mały kaliber '
        'nigdy nie jest bezwartościowy. Druga połowa ceny to hałas.',
    columns: [
      _Column('Calibre', 'Kaliber', (i, p, pl) => '${p['caliber'] ?? '—'}'),
      _Column(
        'Energy',
        'Energia',
        (i, p, pl) => _num(p['muzzle_energy_j'], unit: 'J'),
      ),
      _Column('MOA', 'MOA', (i, p, pl) => _num(p['moa'], decimals: 1)),
      _Column('Magazine', 'Magazynek', (i, p, pl) => _num(p['magazine'])),
      _Column(
        'Range',
        'Zasięg',
        (i, p, pl) => _num(p['effective_range_m'], unit: 'm'),
      ),
      _Column(
        'Heard',
        'Słychać z',
        (i, p, pl) => _num(p['noise_range_m'], unit: 'm'),
      ),
    ],
  ),
  _Kind(
    type: 'ammo',
    titleEn: 'Ammunition',
    titlePl: 'Amunicja',
    headingEn: 'The bottleneck',
    headingPl: 'Wąskie gardło',
    ledeEn:
        'A group of four Walkers costs a novice about thirty rounds — a whole '
        'magazine — which is what makes a knife a real alternative.',
    ledePl:
        'Grupa czterech Szwędaczy kosztuje nowicjusza około trzydziestu '
        'naboi, czyli cały magazynek. Dlatego nóż jest realną alternatywą.',
    columns: [
      _Column('Calibre', 'Kaliber', (i, p, pl) => '${p['caliber'] ?? '—'}'),
    ],
  ),
  _Kind(
    type: 'melee',
    titleEn: 'Melee',
    titlePl: 'Broń biała',
    headingEn: 'Quiet, and very close',
    headingPl: 'Cicho i bardzo blisko',
    ledeEn:
        'Twenty-five metres of noise against a rifle’s seven hundred — '
        'paid for by having to be within arm’s reach of the thing.',
    ledePl:
        'Dwadzieścia pięć metrów hałasu wobec siedmiuset karabinu — za cenę '
        'bycia na wyciągnięcie ręki od tego czegoś.',
    columns: [
      _Column(
        'Blood/hit',
        'Krew na cios',
        (i, p, pl) => _num(p['blood_ml_per_hit'], unit: 'ml'),
      ),
      _Column(
        'Swing',
        'Zamach',
        (i, p, pl) => _num(p['swing_seconds'], decimals: 1, unit: 's'),
      ),
      _Column(
        'Reach',
        'Zasięg',
        (i, p, pl) => _num(p['reach_m'], decimals: 1, unit: 'm'),
      ),
      _Column(
        'Heard',
        'Słychać z',
        (i, p, pl) => _num(p['noise_range_m'], unit: 'm'),
      ),
    ],
  ),
  _Kind(
    type: 'armor',
    titleEn: 'Clothing and armour',
    titlePl: 'Odzież i pancerz',
    headingEn: 'Two independent axes',
    headingPl: 'Dwie niezależne osie',
    ledeEn:
        'Insulation feeds the sweat model; protection and coverage reduce '
        'damage only for the location that was actually hit.',
    ledePl:
        'Izolacja wchodzi do modelu pocenia; ochrona i pokrycie zmniejszają '
        'obrażenia tylko dla trafionej lokalizacji.',
    columns: [
      _Column('Slot', 'Slot', (i, p, pl) => '${p['slot'] ?? '—'}'),
      _Column(
        'Insulation',
        'Izolacja',
        (i, p, pl) => _num(p['insulation_clo'], decimals: 2, unit: 'clo'),
      ),
      _Column(
        'Protection',
        'Ochrona',
        (i, p, pl) => _num(p['protection_level']),
      ),
      _Column(
        'Coverage',
        'Pokrycie',
        (i, p, pl) => _num(p['coverage_pct'], unit: '%'),
      ),
    ],
  ),
  _Kind(
    type: 'backpack',
    titleEn: 'Backpacks',
    titlePl: 'Plecaki',
    headingEn: 'Both limits at once',
    headingPl: 'Oba limity naraz',
    ledeEn:
        'A pack raises the carry load and the volume together, and weighs '
        'something itself. Swapping down leaves you over the limit rather '
        'than losing what did not fit.',
    ledePl:
        'Plecak podnosi udźwig i pojemność naraz, a sam też waży. Zamiana na '
        'mniejszy zostawia nadmiar, a nie zabiera tego, co się nie zmieściło.',
    columns: [
      _Column(
        'Capacity',
        'Pojemność',
        (i, p, pl) => _num(p['capacity_l'], unit: 'l'),
      ),
      _Column(
        'Carry',
        'Udźwig',
        (i, p, pl) => '+${_num(p['comfort_carry_bonus_kg'], unit: 'kg')}',
      ),
    ],
  ),
  _Kind(
    type: 'food',
    titleEn: 'Food and drink',
    titlePl: 'Żywność i napoje',
    headingEn: 'Swallowed, then absorbed',
    headingPl: 'Połknięte, potem wchłonięte',
    ledeEn:
        'Eating fills a stomach rather than a bar: about 8 kcal and 25 ml a '
        'minute reach the body, so food is carried and taken before it is '
        'needed.',
    ledePl:
        'Jedzenie napełnia żołądek, nie pasek: do ciała trafia około 8 kcal i '
        '25 ml na minutę, więc jedzenie nosi się i je, zanim będzie trzeba.',
    columns: [
      _Column(
        'Calories',
        'Kalorie',
        (i, p, pl) => _num(p['kcal'], unit: 'kcal'),
      ),
      _Column('Water', 'Woda', (i, p, pl) => _num(p['water_ml'], unit: 'ml')),
      _Column(
        'Time',
        'Czas',
        (i, p, pl) => _num(p['consume_seconds'], unit: 's'),
      ),
    ],
  ),
  _Kind(
    type: 'medical',
    titleEn: 'Medical',
    titlePl: 'Medykamenty',
    headingEn: 'What stops the bleeding',
    headingPl: 'Co zatrzymuje krwawienie',
    ledeEn:
        'A dressing answers what it is rated for and nothing worse: only a '
        'tourniquet answers an arterial bleed, which is what keeps it from '
        'being dead weight.',
    ledePl:
        'Opatrunek radzi sobie z tym, do czego jest przewidziany, i z niczym '
        'gorszym: krwawienie tętnicze zatrzymuje wyłącznie staza — dlatego '
        'nie jest martwym ciężarem.',
    columns: [
      _Column(
        'Stops',
        'Zatrzymuje',
        (i, p, pl) => '${p['stops_bleeding_class'] ?? '—'}',
      ),
      _Column('Uses', 'Użycia', (i, p, pl) => _num(p['uses'])),
      _Column('Time', 'Czas', (i, p, pl) => _num(p['use_seconds'], unit: 's')),
    ],
  ),
  _Kind(
    type: 'literature',
    titleEn: 'Literature',
    titlePl: 'Literatura',
    headingEn: 'Mass rolled per copy',
    headingPl: 'Masa losowana na egzemplarz',
    ledeEn:
        'Every copy rolls its own page count, and mass, reading time and '
        'experience all follow from it. Two copies of one manual can differ by '
        'a kilogram.',
    ledePl:
        'Każdy egzemplarz losuje własną liczbę stron, a z niej wynika masa, '
        'czas czytania i doświadczenie. Dwa egzemplarze jednego podręcznika '
        'mogą różnić się o kilogram.',
    columns: [
      _Column('Form', 'Forma', (i, p, pl) => '${p['form'] ?? '—'}'),
      _Column(
        'Pages',
        'Stron',
        (i, p, pl) => '${_num(p['pages_min'])}–${_num(p['pages_max'])}',
      ),
      _Column('XP/page', 'XP/stronę', (i, p, pl) => _num(p['xp_per_page'])),
    ],
  ),
  _Kind(
    type: 'tool',
    titleEn: 'Tools',
    titlePl: 'Narzędzia',
    headingEn: 'What a tool is for',
    headingPl: 'Do czego służy narzędzie',
    ledeEn:
        'A crowbar is not a recipe ingredient — it is the difference between '
        'a shop you can enter and one you cannot.',
    ledePl:
        'Łom nie jest składnikiem receptury — jest różnicą między sklepem, do '
        'którego wejdziesz, a takim, do którego nie.',
    columns: [
      _Column(
        'Light',
        'Światło',
        (i, p, pl) => _num(p['light_radius_m'], unit: 'm'),
      ),
      _Column(
        'Battery',
        'Bateria',
        (i, p, pl) => _num(p['battery_hours'], unit: 'h'),
      ),
      _Column(
        'Crafting',
        'Wytwarzanie',
        (i, p, pl) => p['craft_time_modifier'] is num
            ? '${(p['craft_time_modifier'] as num) > 0 ? '+' : ''}'
                  '${((p['craft_time_modifier'] as num) * 100).round()} %'
            : '—',
      ),
      _Column(
        'Search',
        'Przeszukanie',
        (i, p, pl) => _num(p['search_radius_bonus_m'], unit: 'm'),
      ),
    ],
  ),
  _Kind(
    type: 'attachment',
    titleEn: 'Attachments',
    titlePl: 'Dodatki do broni',
    headingEn: 'The rarest things in the game',
    headingPl: 'Najrzadsze rzeczy w grze',
    ledeEn:
        'Each one moves a number the combat model already reads. A suppressor '
        'is not a percentage - it is a change in how the game is played, and '
        'the same is true of the rest.',
    ledePl:
        'Każdy przesuwa liczbę, którą model walki i tak już czyta. Tłumik nie '
        'jest procentem - jest zmianą sposobu grania, i tak samo reszta.',
    columns: [
      _Column(
        'Fits',
        'Pasuje do',
        (i, p, pl) =>
            (p['attaches_to'] as List<dynamic>? ?? const []).join(', '),
      ),
      _Column('MOA', 'MOA', (i, p, pl) => _num(p['moa_delta'], decimals: 1)),
      _Column(
        'Settling',
        'Stabilizacja',
        (i, p, pl) => _num(p['settle_multiplier'], decimals: 2),
      ),
      _Column('Magazine', 'Magazynek', (i, p, pl) => _num(p['magazine_bonus'])),
      _Column(
        'Noise',
        'Hałas',
        (i, p, pl) => _num(p['noise_range_multiplier'], decimals: 2),
      ),
      _Column(
        'Craft skill',
        'Wprawa',
        (i, p, pl) => _num(p['craft_skill'], unit: '%'),
      ),
    ],
  ),
  _Kind(
    type: 'magazine',
    titleEn: 'Magazines',
    titlePl: 'Magazynki',
    headingEn: 'Rounds you already paid for',
    headingPl: 'Naboje, za które już zapłacono',
    ledeEn:
        'A magazine is the difference between a reload measured in seconds and '
        'one measured in rounds. Feed a revolver and you pay per round; change '
        'a magazine and you pay once - which is why an empty one is still '
        'worth carrying.',
    ledePl:
        'Magazynek to różnica między przeładowaniem liczonym w sekundach a '
        'liczonym w nabojach. Rewolwer ładuje się sztuka po sztuce, magazynek '
        'wymienia się raz - i dlatego pusty też warto nieść.',
    columns: [
      _Column(
        'Fits',
        'Pasuje do',
        (i, p, pl) =>
            (p['attaches_to'] as List<dynamic>? ?? const []).join(', '),
      ),
      _Column('Capacity', 'Pojemność', (i, p, pl) => _num(p['capacity'])),
      _Column('Calibre', 'Kaliber', (i, p, pl) => '${p['caliber'] ?? '—'}'),
    ],
  ),
  _Kind(
    type: 'crafting',
    titleEn: 'Materials',
    titlePl: 'Surowce',
    headingEn: 'Where the two limits bite',
    headingPl: 'Gdzie gryzą oba limity',
    ledeEn:
        'Metal is a mass problem, plastic and fabric fill the volume, and '
        'wood pinches on both axes at once.',
    ledePl:
        'Metal to problem masy, plastik i materiał zapychają objętość, a '
        'drewno uwiera na obu osiach naraz.',
    columns: [
      _Column(
        'Build material',
        'Materiał budowlany',
        (i, p, pl) => p['build_material'] == true ? (pl ? 'tak' : 'yes') : '—',
      ),
    ],
  ),
];

// -------------------------------------------------------------- the pieces ---

String _name(
  Map<String, dynamic> item,
  Map<String, Map<String, String>> names,
  String language,
) {
  final key = '${item['name_key']}';
  return names[key]?[language] ?? names[key]?['en'] ?? '${item['id']}';
}

String _mass(Map<String, dynamic> item) {
  final kg = (item['weight_kg'] as num?)?.toDouble() ?? 0;
  return kg < 1
      ? '${(kg * 1000).round()} g'
      : '${kg.toStringAsFixed(kg < 10 ? 1 : 0)} kg';
}

String _volume(Map<String, dynamic> item) {
  final litres = (item['volume_l'] as num?)?.toDouble() ?? 0;
  return litres < 1
      ? '${litres.toStringAsFixed(litres < 0.1 ? 3 : 2)} l'
      : '${litres.toStringAsFixed(1)} l';
}

String _tags(Map<String, dynamic> item, bool pl) {
  final tags = (item['loot_tags'] as List<dynamic>?) ?? const [];
  return tags.map((tag) => _tagName('$tag', pl)).join(', ');
}

String _tagName(String tag, bool pl) => pl
    ? const {
            'residential': 'mieszkania',
            'shop': 'sklepy',
            'pharmacy': 'apteki',
            'hospital': 'szpitale',
            'military': 'wojsko',
            'police': 'policja',
            'industrial': 'przemysł',
            'warehouse': 'magazyny',
            'garage': 'garaże',
            'vehicle': 'pojazdy',
            'hunting': 'łowiectwo',
            'rural': 'wieś',
            'forest': 'las',
            'garden': 'ogrody',
            'sport': 'sport',
            'school': 'szkoły',
            'library': 'biblioteki',
            'hardware': 'sklepy budowlane',
            'any': 'wszędzie',
          }[tag] ??
          tag
    : tag;
