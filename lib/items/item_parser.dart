/// Reading and checking item files (§4.1).
///
/// §4.1 says the JSON is validated against a schema at build time. This is that
/// validation, written in Dart rather than in a schema language for one
/// reason: the same code then runs in the game, and a content pack downloaded
/// after release gets checked exactly as strictly as the bundled files were
/// (§16.6's lesson, applied to data instead of maps).
///
/// **Every fault is collected, never thrown.** A file with eleven mistakes
/// should produce eleven lines, so somebody fixes them in one pass instead of
/// running the build eleven times.
///
/// **A rejected entry is dropped, not repaired.** An item with no weight is not
/// worth guessing at: it would end up in a loot table and in a player's hands,
/// weighing whatever the guess was.
library;

import 'dart:convert';

import 'item.dart';

/// What the app understands. A file declaring anything higher is refused whole
/// rather than half-read — a partly-parsed catalogue is a game quietly missing
/// items nobody can explain.
const int kItemSchemaVersion = 1;

/// The result of reading one file.
class ItemParseResult {
  const ItemParseResult({
    required this.items,
    required this.problems,
    required this.schemaVersion,
  });

  final List<ItemDefinition> items;
  final List<ItemProblem> problems;

  /// Null when the file did not declare one, which is itself a problem.
  final int? schemaVersion;

  bool get isClean => problems.isEmpty;
}

/// Parses an item file.
///
/// Shape: `{"schema": 1, "items": [ ... ]}`.
ItemParseResult parseItems(String source, {String origin = 'items'}) {
  final problems = <ItemProblem>[];

  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    return ItemParseResult(
      items: const [],
      problems: [ItemProblem(origin, 'not valid JSON: ${error.message}')],
      schemaVersion: null,
    );
  }

  if (decoded is! Map<String, Object?>) {
    return ItemParseResult(
      items: const [],
      problems: [ItemProblem(origin, 'expected an object at the top level')],
      schemaVersion: null,
    );
  }

  final schema = (decoded['schema'] as num?)?.toInt();
  if (schema == null) {
    return ItemParseResult(
      items: const [],
      problems: [ItemProblem(origin, 'no "schema" version declared')],
      schemaVersion: null,
    );
  }
  if (schema > kItemSchemaVersion) {
    // Newer than us. Reading what we recognise and ignoring the rest would
    // produce a catalogue missing exactly the things the new version added.
    return ItemParseResult(
      items: const [],
      problems: [
        ItemProblem(
          origin,
          'schema $schema is newer than this build understands '
          '($kItemSchemaVersion)',
        ),
      ],
      schemaVersion: schema,
    );
  }

  final raw = decoded['items'];
  if (raw is! List) {
    return ItemParseResult(
      items: const [],
      problems: [ItemProblem(origin, '"items" must be a list')],
      schemaVersion: schema,
    );
  }

  final items = <ItemDefinition>[];
  final seen = <String>{};

  for (var index = 0; index < raw.length; index++) {
    final entry = raw[index];
    if (entry is! Map<String, Object?>) {
      problems.add(ItemProblem('$origin[$index]', 'not an object'));
      continue;
    }

    final id = entry['id'];
    if (id is! String || id.isEmpty) {
      problems.add(ItemProblem('$origin[$index]', 'missing "id"'));
      continue;
    }
    if (!seen.add(id)) {
      // Ids are referenced by loot tables, recipes and save rows. A duplicate
      // means one of the two is unreachable and nobody can tell which.
      problems.add(ItemProblem(id, 'duplicate id'));
      continue;
    }

    final faults = <String>[];

    final weight = (entry['weight_kg'] as num?)?.toDouble();
    if (weight == null || weight < 0) {
      faults.add('weight_kg missing or negative');
    }

    final volume = (entry['volume_l'] as num?)?.toDouble();
    if (volume == null || volume < 0) {
      faults.add('volume_l missing or negative');
    }

    final rarityWire = entry['rarity'];
    final rarity = rarityWire is String ? Rarity.fromWire(rarityWire) : null;
    if (rarity == null) faults.add('rarity missing or unknown: $rarityWire');

    final kindWire = entry['type'];
    if (kindWire is! String) faults.add('type missing');

    final name = _nameOf(entry);
    if (name.isEmpty) {
      faults.add('no name_key and no inline name');
    }

    final condition = (entry['condition'] as num?)?.toDouble();
    if (condition != null && (condition < 0 || condition > 100)) {
      faults.add('condition outside 0-100');
    }

    final stackable = entry['stackable'] == true;
    if (stackable && condition != null) {
      // Two of them would have to share one condition value, and the first use
      // would wear down the whole pile.
      faults.add('stackable item cannot have a condition');
    }
    if (stackable && kindWire == 'literature') {
      // §4.6.3: every copy carries its own reading progress.
      faults.add('literature cannot stack');
    }

    if (faults.isNotEmpty) {
      for (final fault in faults) {
        problems.add(ItemProblem(id, fault));
      }
      continue;
    }

    items.add(
      ItemDefinition(
        id: id,
        kind: ItemKind.fromWire(kindWire! as String),
        name: name,
        weightKg: weight!,
        volumeL: volume!,
        rarity: rarity!,
        stackable: stackable,
        condition: condition,
        conditionDecayPerUse: (entry['condition_decay_per_use'] as num?)
            ?.toDouble(),
        lootTags: [
          for (final tag in (entry['loot_tags'] as List? ?? const []))
            if (tag is String) tag,
        ],
        props: (entry['props'] as Map<String, Object?>?) ?? const {},
      ),
    );
  }

  return ItemParseResult(
    items: items,
    problems: problems,
    schemaVersion: schema,
  );
}

ItemName _nameOf(Map<String, Object?> entry) {
  final key = entry['name_key'];
  final inline = entry['name'];

  return ItemName(
    key: key is String && key.isNotEmpty ? key : null,
    byLanguage: inline is Map<String, Object?>
        ? {
            for (final e in inline.entries)
              if (e.value is String && (e.value! as String).isNotEmpty)
                e.key: e.value! as String,
          }
        : const {},
  );
}
