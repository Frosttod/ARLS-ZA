/// Writes `item_base.md`: every item in the game, with what it costs to make
/// and what it gives back when taken apart.
///
///     dart run tool/item_base.dart
///
/// ⚠️ **Generated from the game's own code, never from a reading of the JSON.**
///
/// The point of the file is to check whether the numbers are *believable* — a
/// tin of meat that weighs four kilograms, a rifle that comes apart into more
/// metal than it contains. That check is worthless against a table somebody
/// transcribed by hand, because a transcription drifts and then the review is
/// of yesterday's game.
///
/// So this loads the same catalogue the game loads, and asks the same
/// functions the bench asks: [salvageOf] for what comes back, [materialContent]
/// for what a thing is made of, [salvageTime] for how long it takes. If §18.6's
/// arithmetic changes, the file changes with it on the next run.
library;

import 'dart:io';

import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';

const _out = 'item_base.md';

void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final recipes = RecipeBook.parse(File(kRecipesAsset).readAsStringSync());
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  final pl = names.forLanguage('pl');
  final en = names.forLanguage('en');

  String nameOf(String id, String? Function(String)? lookup) {
    final item = catalogue[id];
    if (item == null) return id;
    return item.name.resolve(language: 'pl', lookup: lookup);
  }

  final out = StringBuffer()
    ..writeln('# Baza przedmiotów')
    ..writeln()
    ..writeln(
      '> ⚠️ **Plik generowany.** `dart run tool/item_base.dart` — '
      'nie edytuj ręcznie, bo następne uruchomienie to nadpisze. '
      'Zmiany wprowadza się w `assets/data/*.json`.',
    )
    ..writeln()
    ..writeln(
      'Liczby pochodzą z tego samego kodu, którego używa gra: §18.6 pyta '
      '`salvageOf`, czas rozbiórki `salvageTime`, a zawartość materiałową '
      '`materialContent`. Jeśli arytmetyka się zmieni, ten plik zmieni się '
      'razem z nią przy następnym uruchomieniu.',
    )
    ..writeln();

  _writeLegend(out);
  _writeIndex(out, catalogue: catalogue, recipes: recipes, pl: pl);

  // Grouped by kind, because that is how somebody checking realism reads:
  // all the food together, all the weapons together.
  final byKind = <ItemKind, List<ItemDefinition>>{};
  for (final item in catalogue.all) {
    byKind.putIfAbsent(item.kind, () => []).add(item);
  }

  for (final kind in ItemKind.values) {
    final items = byKind[kind];
    if (items == null || items.isEmpty) continue;

    items.sort((a, b) => a.id.compareTo(b.id));

    out
      ..writeln()
      ..writeln('## ${_kindTitle(kind)}')
      ..writeln();

    for (final item in items) {
      _writeItem(
        out,
        item,
        catalogue: catalogue,
        recipes: recipes,
        pl: pl,
        en: en,
        nameOf: (id) => nameOf(id, pl),
      );
    }
  }

  _writeMaterialSummary(
    out,
    catalogue: catalogue,
    nameOf: (id) => nameOf(id, pl),
  );

  File(_out).writeAsStringSync(out.toString());

  stdout.writeln('$_out — ${catalogue.all.length} przedmiotow');
}

void _writeLegend(StringBuffer out) {
  out
    ..writeln('## Jak czytać')
    ..writeln()
    ..writeln('| Pole | Znaczenie |')
    ..writeln('| :--- | :--- |')
    ..writeln('| **Masa / objętość** | §18.1a — dwa limity, które gracz nosi |')
    ..writeln(
      '| **Zawartość** | z czego rzecz jest zrobiona, w jednostkach '
      'materiału (§18.4) |',
    )
    ..writeln(
      '| **Rozbiórka** | co faktycznie wraca przy 100% stanu, po '
      '§18.6 — jeden budżet na przedmiot, zaokrąglony raz |',
    )
    ..writeln(
      '| **Rozbiórka (warsztat)** | to samo przy warsztacie L2 i '
      'pełnej inżynierii — górna granica |',
    )
    ..writeln(
      '| **Czas rozbiórki** | §18.6: od trzech do piętnastu minut, '
      'wedle tego, ile jest do odkręcenia |',
    )
    ..writeln(
      '| **Wytwarzanie** | §18.4 — koszt, czas, narzędzia, poziom '
      'warsztatu |',
    )
    ..writeln()
    ..writeln(
      '⚠️ **Rozbiórka nigdy nie zwraca tyle, ile kosztowało wytworzenie.** '
      '§18.6 mówi wprost, że odzysk nie ma się opłacać *dla materiałów* — '
      'opłaca się, żeby pozbyć się czegoś, czego się nie użyje. Jeśli gdzieś '
      'zwrot równa się kosztowi, to jest błąd danych, nie cecha.',
    )
    ..writeln();
}

/// Everything in one table, heaviest first.
///
/// ⚠️ **This is the table the realism check actually happens in.** A tin of
/// meat that weighs four kilograms is invisible inside its own entry and
/// obvious in a column — and so is a knife that takes longer to dismantle than
/// a rifle. Sorted by mass because that is the figure a person has the best
/// intuition about: everybody knows roughly what a litre of water weighs.
void _writeIndex(
  StringBuffer out, {
  required ItemCatalogue catalogue,
  required RecipeBook recipes,
  required String? Function(String)? pl,
}) {
  final items = catalogue.all.toList()
    ..sort((a, b) => b.weightKg.compareTo(a.weightKg));

  out
    ..writeln('## Skorowidz')
    ..writeln()
    ..writeln('${items.length} przedmiotów, od najcięższego.')
    ..writeln()
    ..writeln('| Przedmiot | Rodzaj | Masa | Objętość | Rozbiórka | Czas |')
    ..writeln('| :--- | :--- | ---: | ---: | :--- | ---: |');

  for (final item in items) {
    final content = materialContent(item, recipes);
    final back = salvageOf(item, recipes, share: kSalvageReturn);

    // ⚠️ Named, not counted. "×2 ×3" answers nothing — two of *what* is the
    // whole question when the point is to spot a rifle that comes apart into
    // more metal than it contains.
    final gives = content.isEmpty
        ? '—'
        : back.isEmpty
        ? 'nic'
        : back.entries
              .map((entry) => '${_shortMaterial(entry.key)} ×${entry.value}')
              .join(', ');

    out.writeln(
      '| ${item.name.resolve(language: 'pl', lookup: pl)} `${item.id}` '
      '| ${_kindTitle(item.kind)} '
      '| ${item.weightKg.toStringAsFixed(2)} '
      '| ${item.volumeL.toStringAsFixed(2)} '
      '| $gives '
      '| ${content.isEmpty ? '—' : _minutes(salvageTime(content))} |',
    );
  }
  out.writeln();
}

void _writeItem(
  StringBuffer out,
  ItemDefinition item, {
  required ItemCatalogue catalogue,
  required RecipeBook recipes,
  required String? Function(String)? pl,
  required String? Function(String)? en,
  required String Function(String id) nameOf,
}) {
  final namePl = item.name.resolve(language: 'pl', lookup: pl);
  final nameEn = item.name.resolve(language: 'en', lookup: en);

  out
    ..writeln('### $namePl')
    ..writeln()
    ..writeln('`${item.id}` · $nameEn · ${_rarity(item.rarity)}')
    ..writeln();

  final facts = <String>[
    '**Masa** ${item.weightKg.toStringAsFixed(2)} kg',
    '**Objętość** ${item.volumeL.toStringAsFixed(2)} l',
    if (item.stackable) '**Stackowalny**',
    if (item.condition != null)
      '**Stan** ${item.condition!.toStringAsFixed(0)}%',
    if (item.conditionDecayPerUse != null)
      '**Zużycie** ${item.conditionDecayPerUse!.toStringAsFixed(2)}%/użycie',
  ];
  out
    ..writeln(facts.join(' · '))
    ..writeln();

  if (item.lootTags.isNotEmpty) {
    out
      ..writeln('Znajdowany: ${item.lootTags.join(', ')}')
      ..writeln();
  }

  final props = _interestingProps(item);
  if (props.isNotEmpty) {
    out
      ..writeln('| Parametr | Wartość |')
      ..writeln('| :--- | ---: |');
    for (final entry in props.entries) {
      out.writeln('| ${entry.key} | ${entry.value} |');
    }
    out.writeln();
  }

  _writeCrafting(out, item, recipes: recipes, nameOf: nameOf);
  _writeSalvage(out, item, recipes: recipes, nameOf: nameOf);
}

void _writeCrafting(
  StringBuffer out,
  ItemDefinition item, {
  required RecipeBook recipes,
  required String Function(String id) nameOf,
}) {
  final recipe = recipes.recipes
      .where((entry) => entry.output == item.id)
      .firstOrNull;

  if (recipe == null) {
    out
      ..writeln('**Wytwarzanie:** — (tylko znajdowane)')
      ..writeln();
    return;
  }

  final cost = recipe.materials.entries
      .map((entry) => '${nameOf(entry.key)} ×${entry.value}')
      .join(', ');

  final extras = <String>[
    if (recipe.count > 1) 'daje ${recipe.count} szt.',
    if (recipe.workshopLevel > 0) 'warsztat L${recipe.workshopLevel}',
    if (recipe.toolsAnyOf.isNotEmpty)
      'narzędzie: ${recipe.toolsAnyOf.map(nameOf).join(' / ')}',
  ];

  out
    ..writeln(
      '**Wytwarzanie:** $cost · ${_minutes(recipe.work)}'
      '${extras.isEmpty ? '' : ' · ${extras.join(' · ')}'}',
    )
    ..writeln();
}

void _writeSalvage(
  StringBuffer out,
  ItemDefinition item, {
  required RecipeBook recipes,
  required String Function(String id) nameOf,
}) {
  final content = materialContent(item, recipes);

  if (content.isEmpty) {
    out
      ..writeln('**Rozbiórka:** — (nie da się rozebrać)')
      ..writeln();
    return;
  }

  final made = content.entries
      .map((entry) => '${nameOf(entry.key)} ${entry.value.toStringAsFixed(2)}')
      .join(', ');

  // ⚠️ Both ends of §18.6's range, because the difference is the whole reason
  // to build a workshop — and because a row where they are equal is a row
  // where the bonus does nothing, which is worth seeing.
  final base = salvageOf(item, recipes, share: kSalvageReturn);
  final best = salvageOf(
    item,
    recipes,
    share: salvageShare(engineering: 1, workshopLevel: 2),
  );

  String said(Map<String, int> yields) => yields.isEmpty
      ? '**nic**'
      : yields.entries
            .map((entry) => '${nameOf(entry.key)} ×${entry.value}')
            .join(', ');

  out
    ..writeln('**Zawartość:** $made')
    ..writeln()
    ..writeln(
      '**Rozbiórka:** ${said(base)} · '
      'z warsztatem: ${said(best)} · '
      '${_minutes(salvageTime(content))}',
    )
    ..writeln();
}

/// §18.4: how much of each material the whole catalogue is made of.
///
/// ⚠️ Here because it is the fastest way to spot a number that is wrong by an
/// order of magnitude. A rifle made of forty units of metal stands out in a
/// column in a way it never does inside its own entry.
void _writeMaterialSummary(
  StringBuffer out, {
  required ItemCatalogue catalogue,
  required String Function(String id) nameOf,
}) {
  out
    ..writeln()
    ..writeln('---')
    ..writeln()
    ..writeln('## Jednostki materiałów (§18.2)')
    ..writeln()
    ..writeln(
      'Masy jednostkowe nie są wybrane — są rozwiązane z tabeli §18.2 i '
      'odtwarzają wszystkie trzynaście wierszy modułów co do kilograma. '
      'Zmiana jednej z nich przesuwa **każdy** koszt budowy w grze.',
    )
    ..writeln()
    ..writeln('| Materiał | Masa jednostki | Objętość |')
    ..writeln('| :--- | ---: | ---: |');

  final materials =
      catalogue.all.where((item) => item.kind == ItemKind.crafting).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  for (final material in materials) {
    out.writeln(
      '| ${nameOf(material.id)} `${material.id}` '
      '| ${material.weightKg.toStringAsFixed(2)} kg '
      '| ${material.volumeL.toStringAsFixed(2)} l |',
    );
  }
  out.writeln();
}

/// Everything in `props` worth a reviewer's eye, in a readable order.
///
/// ⚠️ A filter rather than a dump. `props` carries wiring as well as figures —
/// selectors, flags, keys — and a table with `build_material: true` in it is a
/// table somebody stops reading.
Map<String, String> _interestingProps(ItemDefinition item) {
  const skip = {'salvage', 'build_material', 'name_key'};

  const label = {
    'kcal': 'Kalorie',
    'perishable_hours': 'Psuje się po (h)',
    'needs_opener': 'Wymaga otwieracza',
    'alcohol': 'Alkohol',
    'caffeine_mg': 'Kofeina (mg)',
    'muzzle_energy_j': 'Energia wylotowa (J)',
    'moa': 'Rozrzut broni (MOA)',
    'recoil_moa': 'Odrzut (MOA)',
    'feed': 'Zasilanie',
    'fire_modes': 'Tryby ognia',
    'reload_note': 'Uwaga o przeładowaniu',
    'swing_seconds': 'Czas zamachu (s)',
    'stamina_cost': 'Koszt wysiłku',
    'insulation_clo': 'Izolacja (clo)',
    'water_resistance': 'Wodoodporność',
    'shelf_life_days': 'Termin (dni)',
    'spoiled_illness_chance': 'Ryzyko po terminie',
    'heal_hp': 'Leczy (HP)',
    'read_minutes': 'Czas czytania (min)',
    'battery_hours': 'Bateria (h)',
    'light_range_m': 'Zasięg światła (m)',
    'water_ml': 'Woda (ml)',
    'consume_seconds': 'Czas spożycia (s)',
    'use_seconds': 'Czas użycia (s)',
    'illness_chance': 'Ryzyko choroby',
    'damage': 'Obrażenia',
    'caliber': 'Kaliber',
    'magazine': 'Magazynek',
    'reload_seconds': 'Przeładowanie (s)',
    'effective_range_m': 'Zasięg skuteczny (m)',
    'noise_range_m': 'Hałas (m)',
    'attachment_slots': 'Gniazda dodatków',
    'capacity_kg': 'Pojemność (kg)',
    'capacity_l': 'Pojemność (l)',
    'clo': 'Ciepło (clo)',
    'armor_class': 'Klasa pancerza',
    'coverage': 'Pokrycie',
    'stops_bleeding_class': 'Tamuje krwawienie do',
    'pages': 'Strony',
    'rounds': 'Naboje',
  };

  final out = <String, String>{};
  for (final entry in item.props.entries) {
    if (skip.contains(entry.key)) continue;

    final value = entry.value;
    if (value == null) continue;
    if (value is bool && !value) continue;

    out[label[entry.key] ?? '`${entry.key}`'] = value is List
        ? value.join(', ')
        : '$value';
  }
  return out;
}

/// A material's name in one word, for a column that has to stay narrow.
String _shortMaterial(String id) => switch (id) {
  'mat_wood' => 'drewno',
  'mat_metal' => 'metal',
  'mat_plastic' => 'plastik',
  'mat_fabric' => 'tkanina',
  'mat_component' => 'komponent',
  _ => id.startsWith('mat_') ? id.substring(4) : id,
};

String _minutes(Duration work) {
  final minutes = work.inSeconds / 60;
  return minutes < 1
      ? '${work.inSeconds} s'
      : '${minutes.toStringAsFixed(minutes < 10 ? 1 : 0)} min';
}

String _rarity(Rarity rarity) => switch (rarity) {
  Rarity.common => 'pospolity',
  Rarity.uncommon => 'rzadszy',
  Rarity.rare => 'rzadki',
  Rarity.veryRare => 'bardzo rzadki',
};

String _kindTitle(ItemKind kind) => switch (kind) {
  ItemKind.firearm => 'Broń palna',
  ItemKind.melee => 'Broń biała',
  ItemKind.armor => 'Pancerz i odzież',
  ItemKind.backpack => 'Plecaki',
  ItemKind.food => 'Żywność i napoje',
  ItemKind.medical => 'Medykamenty',
  ItemKind.literature => 'Literatura',
  ItemKind.tool => 'Narzędzia',
  ItemKind.attachment => 'Dodatki do broni',
  ItemKind.crafting => 'Materiały',
  ItemKind.ammo => 'Amunicja',
  ItemKind.material => 'Surowce',
  ItemKind.misc => 'Pozostałe',
};
