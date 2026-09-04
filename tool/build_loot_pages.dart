/// Builds the loot-table pages of the project site, from the game's own data.
///
/// A player who wants to know where the sewing kit lives should not have to
/// ask in a chat and wait for someone to read the JSON — the answer is
/// already in `assets/data/loot_tables.json`, the same file `LootTableSet`
/// reads at runtime. So this reads it the same way [items] does not: through
/// the actual game types (`LootTableSet`, `ItemCatalogue`, `Barrier`), so a
/// table that fails validation fails this build too, instead of shipping a
/// page that lies about a place that cannot actually produce what it lists.
///
/// Run it after changing loot tables or items:
///
/// ```
/// dart run tool/build_loot_pages.dart
/// ```
///
/// It writes `loot.html` and `pl/loot.html` into the site repository beside
/// this one, and links to `items.html#item-<id>` for every entry — run
/// `build_item_pages.dart` first, or the ids on the other end will be stale.
library;

import 'dart:io';

import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/obstacle.dart';

const String kSiteDir = '../ARLS-ZA-Game';
const String kLootTablesAsset = 'assets/data/loot_tables.json';

void main() {
  final root = Directory.current;
  final site = Directory('${root.path}/$kSiteDir');
  if (!site.existsSync()) {
    stderr.writeln('No site at ${site.path}');
    exitCode = 1;
    return;
  }

  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  if (catalogue.problems.isNotEmpty) {
    stderr.writeln(catalogue.problems.join('\n'));
    exitCode = 1;
    return;
  }

  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  final tables = LootTableSet.parse(File(kLootTablesAsset).readAsStringSync());
  if (!tables.isClean) {
    stderr.writeln(tables.problems.join('\n'));
    exitCode = 1;
    return;
  }
  final faults = tables.validateAgainst(catalogue);
  if (faults.isNotEmpty) {
    stderr.writeln(faults.join('\n'));
    exitCode = 1;
    return;
  }

  File('${site.path}/loot.html')
    ..createSync(recursive: true)
    ..writeAsStringSync(_page(tables, catalogue, names, language: 'en'));

  File('${site.path}/pl/loot.html')
    ..createSync(recursive: true)
    ..writeAsStringSync(_page(tables, catalogue, names, language: 'pl'));

  stdout.writeln('${tables.tables.length} tables written to ${site.path}');
}

// --------------------------------------------------------------- the page ---

String _page(
  LootTableSet tables,
  ItemCatalogue catalogue,
  ItemNames names, {
  required String language,
}) {
  final pl = language == 'pl';
  final root = pl ? '../' : '';
  final lookup = names.forLanguage(language);
  String nameOf(String id) {
    final item = catalogue[id];
    if (item == null) return id;
    return item.name.resolve(language: language, lookup: lookup);
  }

  final real = tables.tables.where((t) => t.source == LootSource.osm).toList()
    ..sort((a, b) => _title(a.id, pl).compareTo(_title(b.id, pl)));
  final procedural =
      tables.tables.where((t) => t.source == LootSource.procedural).toList()
        ..sort((a, b) => _title(a.id, pl).compareTo(_title(b.id, pl)));

  final uniqueItems = {
    for (final table in tables.tables)
      for (final entry in table.entries) entry.itemId,
  };

  final buffer = StringBuffer();

  buffer.writeln('<!doctype html>');
  buffer.writeln('<html lang="$language">');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="utf-8">');
  buffer.writeln(
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
  );
  buffer.writeln(
    '<title>${pl ? 'Gdzie czego szukać' : 'Where to find it'} — ARLS-ZA</title>',
  );
  buffer.writeln(
    '<meta name="description" content="${pl ? 'Każde miejsce do przeszukania w ARLS-ZA i co się w nim znajduje — prosto z tabel łupów gry.' : 'Every searchable place in ARLS-ZA and what it holds — straight from the game'
              "'"
              's own loot tables.'}">',
  );
  buffer.writeln('<meta name="color-scheme" content="light">');
  buffer.writeln('<link rel="stylesheet" href="${root}assets/site.css">');
  buffer.writeln('</head>');
  buffer.writeln('<body>');

  buffer.writeln('<header class="hero">');
  buffer.writeln('  <div class="hero__inner">');
  buffer.writeln('    <div class="hero__meta eyebrow">');
  buffer.writeln(
    '      <span><a href="${root}index.html">← ARLS-ZA</a></span>',
  );
  buffer.writeln(
    '      <span>${tables.tables.length} ${pl ? 'miejsc' : 'places'}</span>',
  );
  buffer.writeln('      <nav class="langs" aria-label="Language">');
  buffer.writeln(
    '        <a href="${pl ? '../loot.html' : 'loot.html'}"${pl ? '' : ' aria-current="true"'} hreflang="en">EN</a>',
  );
  buffer.writeln(
    '        <a href="${pl ? 'loot.html' : 'pl/loot.html'}"${pl ? ' aria-current="true"' : ''} hreflang="pl">PL</a>',
  );
  buffer.writeln('      </nav>');
  buffer.writeln('    </div>');
  buffer.writeln('    <h1><span class="hero__title">');
  buffer.writeln(pl ? 'Gdzie czego szukać' : 'Where to find it');
  buffer.writeln('    </span></h1>');
  buffer.writeln('    <p class="thesis">');
  buffer.writeln(
    pl
        ? '<strong>Każdy wpis tutaj to ten, który wczytuje przeszukanie w grze.</strong> Strona powstaje z <code>assets/data/loot_tables.json</code> przez te same klasy, których używa silnik gry — tabela, która nie przejdzie walidacji, nie trafi na stronę.'
        : '<strong>Every entry here is the one a search in the game actually rolls against.</strong> The page is generated from <code>assets/data/loot_tables.json</code> through the same classes the engine uses — a table that fails validation never reaches the page.',
  );
  buffer.writeln('    </p>');
  buffer.writeln('    <p class="thesis">');
  buffer.writeln(
    pl
        ? '<a href="${root}items.html">Pełny katalog przedmiotów →</a>'
        : '<a href="${root}items.html">The full item catalogue →</a>',
  );
  buffer.writeln('    </p>');
  buffer.writeln('  </div>');
  buffer.writeln('</header>');

  buffer.writeln('<div class="shell"><div class="layout"><main id="content">');

  buffer.writeln('<section class="sec">');
  buffer.writeln('  <div class="stats">');
  buffer.writeln(
    '    <div class="stat"><b>${real.length}</b><span>${_escape(pl ? 'realne miejsca (OSM)' : 'real places (OSM)')}</span></div>',
  );
  buffer.writeln(
    '    <div class="stat"><b>${procedural.length}</b><span>${_escape(pl ? 'punkty proceduralne' : 'procedural points')}</span></div>',
  );
  buffer.writeln(
    '    <div class="stat"><b>${uniqueItems.length}</b><span>${_escape(pl ? 'różnych przedmiotów w obiegu' : 'distinct items in circulation')}</span></div>',
  );
  buffer.writeln('  </div>');
  buffer.writeln('</section>');

  buffer.writeln('<section class="sec" id="real">');
  buffer.writeln('  <div class="sec__hd">');
  buffer.writeln(
    '    <span class="sec__no">${pl ? 'Realne miejsca' : 'Real places'}</span>',
  );
  buffer.writeln(
    '    <h2>${pl ? 'Znalezione na mapie, nie wymyślone' : 'Read off the map, not invented'}</h2>',
  );
  buffer.writeln(
    '    <p class="sec__lede">${_escape(pl ? 'Tabele powiązane z tagami OpenStreetMap. Apteka na mapie to apteka w grze.' : 'Tables tied to OpenStreetMap tags. A pharmacy on the map is a pharmacy in the game.')}</p>',
  );
  buffer.writeln('  </div>');
  buffer.writeln('  <div class="prose">');
  for (final table in real) {
    _writeTable(
      buffer,
      table,
      catalogue: catalogue,
      nameOf: nameOf,
      pl: pl,
      root: root,
    );
  }
  buffer.writeln('  </div>');
  buffer.writeln('</section>');

  buffer.writeln('<section class="sec" id="procedural">');
  buffer.writeln('  <div class="sec__hd">');
  buffer.writeln(
    '    <span class="sec__no">${pl ? 'Warstwa proceduralna' : 'Procedural layer'}</span>',
  );
  buffer.writeln(
    '    <h2>${pl ? 'Dla miast, których OSM nie zna' : 'For towns OSM does not know'}</h2>',
  );
  buffer.writeln(
    '    <p class="sec__lede">${_escape(pl ? 'Poniżej ośmiu punktów zainteresowania w promieniu 2 km ta warstwa zastępuje sklepy obiektami, które są wszędzie: samochodami, stodołami, śmietnikami. Płaci 55% wagi rzadkich przedmiotów i nie może wylosować broni palnej ani zaawansowanej literatury.' : 'Below eight points of interest within 2 km, this layer replaces shops with objects that exist everywhere: cars, barns, skips. It pays 55% weight on rare items and can never roll a firearm or advanced literature.')}</p>',
  );
  buffer.writeln('  </div>');
  buffer.writeln('  <div class="prose">');
  for (final table in procedural) {
    _writeTable(
      buffer,
      table,
      catalogue: catalogue,
      nameOf: nameOf,
      pl: pl,
      root: root,
    );
  }
  buffer.writeln('  </div>');
  buffer.writeln('</section>');

  buffer.writeln('<footer class="foot">');
  buffer.writeln('  <p class="foot__note">');
  buffer.writeln(
    pl
        ? 'Strona generowana z danych gry przez <code>tool/build_loot_pages.dart</code>, tymi samymi klasami, które waliduje test <code>test/loot/loot_table_test.dart</code>. Udział procentowy to surowa waga wpisu w tabeli, przed modyfikatorami głębokości przeszukania i wprawy (§10.3.5) — realny rozkład jest bliższy pospolitym pozycjom, niż sugeruje goły procent. Zasady opisuje <a href="https://github.com/Frosttod/ARLS-ZA/blob/main/ARLS-ZA_design_doc_v2.md">dokument projektowy</a> (§10).'
        : 'Generated from the game data by <code>tool/build_loot_pages.dart</code>, through the same classes <code>test/loot/loot_table_test.dart</code> validates against. The share is the entry\'s raw table weight, before the search-depth and scouting modifiers of §10.3.5 — the real distribution leans more common than the bare percentage suggests. The rules are in the <a href="https://github.com/Frosttod/ARLS-ZA/blob/main/ARLS-ZA_design_doc_v2.md">design document</a> (§10).',
  );
  buffer.writeln('  </p>');
  buffer.writeln('</footer>');

  buffer.writeln('</main></div></div>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  return buffer.toString();
}

void _writeTable(
  StringBuffer buffer,
  LootTable table, {
  required ItemCatalogue catalogue,
  required String Function(String id) nameOf,
  required bool pl,
  required String root,
}) {
  final entries = table.entries.toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));
  final total = entries.fold<double>(0, (sum, e) => sum + e.weight);

  buffer.writeln(
    '    <h3 id="${table.id}">${_escape(_title(table.id, pl))}</h3>',
  );

  final meta = <String>[
    if (table.barrier != null)
      '${pl ? 'Bariera' : 'Barrier'}: ${_barrierLabel(table.barrier!, pl)}'
          ' (${(table.barrier!.alreadyOpenShare * 100).round()}% '
          '${pl ? 'już otwarte' : 'already open'})'
    else
      '${pl ? 'Bariera' : 'Barrier'}: ${pl ? 'brak' : 'none'}',
    if (table.generated)
      pl
          ? 'wymyślone przez grę, nie z mapy'
          : 'invented by the game, not read off the map',
    if (table.hidden)
      pl
          ? 'widoczne dopiero po rozpoznaniu'
          : 'visible only after reconnaissance',
  ];
  buffer.writeln('    <p class="sec__lede">${_escape(meta.join(' · '))}</p>');

  buffer.writeln('    <div class="scroller">');
  buffer.writeln('      <table class="tbl">');
  buffer.write('        <thead><tr>');
  buffer.write('<th scope="col">${pl ? 'Przedmiot' : 'Item'}</th>');
  buffer.write('<th scope="col">${pl ? 'Rzadkość' : 'Rarity'}</th>');
  buffer.write('<th scope="col" class="n">${pl ? 'Ilość' : 'Qty'}</th>');
  buffer.write('<th scope="col" class="n">${pl ? 'Udział' : 'Share'}</th>');
  buffer.writeln('</tr></thead>');
  buffer.writeln('        <tbody>');
  for (final entry in entries) {
    final item = catalogue[entry.itemId];
    final share = total <= 0 ? 0.0 : entry.weight / total * 100;
    final qty = entry.min == entry.max
        ? '${entry.min}'
        : '${entry.min}–${entry.max}';
    buffer.write('          <tr>');
    buffer.write(
      '<th scope="row"><a href="${root}items.html#item-${entry.itemId}">${_escape(nameOf(entry.itemId))}</a></th>',
    );
    buffer.write(
      '<td>${item == null ? '—' : _rarityLabel(item.rarity, pl)}</td>',
    );
    buffer.write('<td class="n">×$qty</td>');
    buffer.write('<td class="n">${share.toStringAsFixed(1)}%</td>');
    buffer.writeln('</tr>');
  }
  buffer.writeln('        </tbody>');
  buffer.writeln('      </table>');
  buffer.writeln('    </div>');
}

// -------------------------------------------------------------- the pieces ---

const Map<String, String> _titlesEn = {
  'poi_pharmacy': 'Pharmacy',
  'poi_hardware': 'Hardware store',
  'poi_grocery': 'Grocery store',
  'poi_sports': 'Sports and outdoor shop',
  'poi_weapons': 'Gun shop',
  'poi_library': 'Library / bookshop',
  'poi_industrial': 'Industrial site',
  'poi_hospital': 'Hospital',
  'poi_military': 'Military site',
  'poi_school': 'School',
  'poi_warehouse': 'Warehouse',
  'proc_abandoned_car': 'Abandoned car',
  'proc_abandoned_house': 'Abandoned house',
  'proc_barn': 'Barn',
  'proc_garage': 'Garage',
  'proc_waste': 'Bin / skip',
  'proc_shelter': 'Shelter / lean-to',
  'proc_hunting_stand': 'Hunting stand',
  'proc_water_point': 'Water point',
  'proc_roadside': 'Roadside',
  'proc_ambulance': 'Ambulance',
  'proc_police_car': 'Police car',
};

const Map<String, String> _titlesPl = {
  'poi_pharmacy': 'Apteka',
  'poi_hardware': 'Sklep budowlany',
  'poi_grocery': 'Sklep spożywczy',
  'poi_sports': 'Sklep sportowy/outdoor',
  'poi_weapons': 'Sklep z bronią',
  'poi_library': 'Biblioteka/księgarnia',
  'poi_industrial': 'Zakład przemysłowy',
  'poi_hospital': 'Szpital',
  'poi_military': 'Obiekt wojskowy',
  'poi_school': 'Szkoła',
  'poi_warehouse': 'Magazyn',
  'proc_abandoned_car': 'Porzucony samochód',
  'proc_abandoned_house': 'Opuszczony dom',
  'proc_barn': 'Stodoła',
  'proc_garage': 'Garaż',
  'proc_waste': 'Śmietnik',
  'proc_shelter': 'Wiata/altana',
  'proc_hunting_stand': 'Ambona myśliwska',
  'proc_water_point': 'Punkt wodny',
  'proc_roadside': 'Pobocze',
  'proc_ambulance': 'Karetka',
  'proc_police_car': 'Radiowóz',
};

String _title(String id, bool pl) => (pl ? _titlesPl : _titlesEn)[id] ?? id;

String _barrierLabel(Barrier barrier, bool pl) => switch (barrier) {
  Barrier.door => pl ? 'drzwi' : 'door',
  Barrier.padlock => pl ? 'kłódka' : 'padlock',
  Barrier.window => pl ? 'okno' : 'window',
};

String _rarityLabel(Rarity rarity, bool pl) => switch (rarity) {
  Rarity.common => pl ? 'pospolity' : 'common',
  Rarity.uncommon => pl ? 'rzadszy' : 'uncommon',
  Rarity.rare => pl ? 'rzadki' : 'rare',
  Rarity.veryRare => pl ? 'bardzo rzadki' : 'very rare',
};

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
