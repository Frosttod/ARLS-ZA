/// Loot tables and how a search draws from them (§10.3, §10.3.5).
///
/// A table is a weighted list tied to a kind of place. What a search actually
/// produces depends on how long the player stood there (§10.3.5): a shallow
/// look sees only common things, a thorough one reaches uncommon, and only a
/// deep search can turn up anything rare — at the price of three minutes
/// standing still, which §5.6 makes an expensive thing to do.
///
/// **Scouting raises the rare weight rather than the number of draws.** The
/// skill makes a search better, not faster; time is the cost the design keeps.
///
/// **Procedural points pay 55%.** §10.1 is explicit that a player who lives
/// where OSM knows nothing must not be punished for it — they get more points
/// more often instead. The same clause bars firearms and advanced books from
/// procedural tables entirely, which is checked rather than trusted.
library;

import 'dart:convert';
import 'dart:math';

import '../items/item.dart';
import '../items/item_catalogue.dart';
import 'obstacle.dart';

/// How much searching one place can absorb before there is nothing left to
/// find (§10.3.5).
///
/// Six is three quick passes, two thorough ones, or one deep one — the numbers
/// a player would guess from the times. It is one budget rather than three
/// counters so that mixing depths stays honest: a quick look followed by a
/// thorough one leaves a litre of shelf nobody has turned over, and a deep
/// search costs the lot, which is why it can only be the first thing done to a
/// place.
const int kSearchBudget = 6;

/// §10.3.5. Time is the cost, and the only one.
enum SearchDepth {
  shallow(
    seconds: 30,
    cost: 2,
    minDraws: 1,
    maxDraws: 2,
    tiers: {Rarity.common},
    rareWeightMultiplier: 0,
  ),
  thorough(
    seconds: 90,
    cost: 3,
    minDraws: 2,
    maxDraws: 4,
    tiers: {Rarity.common, Rarity.uncommon},
    rareWeightMultiplier: 1,
  ),
  deep(
    seconds: 180,
    cost: 6,
    minDraws: 3,
    maxDraws: 5,
    tiers: {Rarity.common, Rarity.uncommon, Rarity.rare, Rarity.veryRare},
    rareWeightMultiplier: 2,
  );

  const SearchDepth({
    required this.seconds,
    required this.cost,
    required this.minDraws,
    required this.maxDraws,
    required this.tiers,
    required this.rareWeightMultiplier,
  });

  final int seconds;

  /// What one pass at this depth takes out of [kSearchBudget].
  final int cost;

  final int minDraws;
  final int maxDraws;

  /// Which rarities are reachable at all. A tier outside this never appears,
  /// however lucky the roll.
  final Set<Rarity> tiers;

  final double rareWeightMultiplier;
}

/// Where a table's points come from. Decides the quality clause of §10.1.
enum LootSource {
  osm,
  procedural;

  static LootSource? fromWire(String value) =>
      values.where((source) => source.name == value).firstOrNull;

  /// §10.1: a procedural point is worth ~55% of a real one.
  double get rareWeightMultiplier => this == LootSource.procedural ? 0.55 : 1.0;
}

class LootEntry {
  const LootEntry({
    required this.itemId,
    required this.weight,
    required this.min,
    required this.max,
  });

  final String itemId;
  final double weight;
  final int min;
  final int max;
}

class LootTable {
  const LootTable({
    required this.id,
    required this.source,
    required this.match,
    required this.entries,
    this.generated = false,
    this.barrier,
  });

  final String id;
  final LootSource source;

  /// OpenMapTiles selectors, in the form `poi.subclass=pharmacy`. What a tile
  /// can actually be checked against — see `omt_schema.dart`, where the mapping
  /// from §10's OSM tags was measured against a built pack rather than
  /// remembered.
  final List<String> match;

  /// True where the tiles cannot produce this place at all and §10.1 has to
  /// generate it. The OpenMapTiles building layer carries no type, so a house,
  /// a barn and a hunting stand are unfindable however the selector is written.
  final bool generated;

  /// What shuts this kind of place (§19.3). Null where nothing does — a car
  /// park has no door to force.
  final Barrier? barrier;

  final List<LootEntry> entries;

  /// What one search produces: item id to count.
  ///
  /// [scouting] is 0–1. It raises the weight of rare entries by up to 30%
  /// (§10.3.5) and does nothing else — a skilled player finds better, not more.
  Map<String, int> roll(
    Random random, {
    required SearchDepth depth,
    required ItemCatalogue catalogue,
    double scouting = 0,
  }) {
    final weights = <LootEntry, double>{};
    for (final entry in entries) {
      final item = catalogue[entry.itemId];
      if (item == null) continue;
      if (!depth.tiers.contains(item.rarity)) continue;

      final isRare =
          item.rarity == Rarity.rare || item.rarity == Rarity.veryRare;
      final weight = isRare
          ? entry.weight *
                depth.rareWeightMultiplier *
                (1 + 0.30 * scouting) *
                source.rareWeightMultiplier
          : entry.weight;

      if (weight > 0) weights[entry] = weight;
    }
    if (weights.isEmpty) return const {};

    final total = weights.values.reduce((a, b) => a + b);
    final draws =
        depth.minDraws + random.nextInt(depth.maxDraws - depth.minDraws + 1);

    final result = <String, int>{};
    for (var draw = 0; draw < draws; draw++) {
      var roll = random.nextDouble() * total;
      for (final entry in weights.entries) {
        roll -= entry.value;
        if (roll > 0) continue;
        final spread = entry.key.max - entry.key.min + 1;
        final count = entry.key.min + random.nextInt(spread);
        result.update(
          entry.key.itemId,
          (existing) => existing + count,
          ifAbsent: () => count,
        );
        break;
      }
    }
    return result;
  }
}

class LootTableSet {
  const LootTableSet(this.tables, this.problems);

  final List<LootTable> tables;
  final List<String> problems;

  bool get isClean => problems.isEmpty;

  LootTable? operator [](String id) =>
      tables.where((table) => table.id == id).firstOrNull;

  /// Every table a place with these OSM tags could use.
  Iterable<LootTable> forTags(Iterable<String> tags) {
    final wanted = tags.toSet();
    return tables.where((table) => table.match.any(wanted.contains));
  }

  /// Reads the file. Faults are collected, exactly as for items (§4.1).
  factory LootTableSet.parse(String source, {String origin = 'loot_tables'}) {
    final problems = <String>[];

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      return LootTableSet(const [], ['$origin: not valid JSON: ${error.message}']);
    }
    if (decoded is! Map<String, Object?>) {
      return LootTableSet(const [], ['$origin: expected an object']);
    }

    final raw = decoded['tables'];
    if (raw is! List) {
      return LootTableSet(const [], ['$origin: "tables" must be a list']);
    }

    final tables = <LootTable>[];
    final seen = <String>{};

    for (var index = 0; index < raw.length; index++) {
      final entry = raw[index];
      if (entry is! Map<String, Object?>) {
        problems.add('$origin[$index]: not an object');
        continue;
      }

      final id = entry['id'];
      if (id is! String || id.isEmpty) {
        problems.add('$origin[$index]: missing "id"');
        continue;
      }
      if (!seen.add(id)) {
        problems.add('$id: duplicate table id');
        continue;
      }

      final source = entry['source'] is String
          ? LootSource.fromWire(entry['source']! as String)
          : null;
      if (source == null) {
        problems.add('$id: source must be osm or procedural');
        continue;
      }

      final entries = <LootEntry>[];
      final rawEntries = entry['entries'];
      if (rawEntries is! List || rawEntries.isEmpty) {
        // A place that produces nothing is a place a player walks to for
        // nothing, which is worse than one that does not exist.
        problems.add('$id: no entries');
        continue;
      }

      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map<String, Object?>) {
          problems.add('$id: an entry is not an object');
          continue;
        }
        final itemId = rawEntry['item'];
        final weight = (rawEntry['weight'] as num?)?.toDouble();
        final min = (rawEntry['min'] as num?)?.toInt();
        final max = (rawEntry['max'] as num?)?.toInt();

        if (itemId is! String || itemId.isEmpty) {
          problems.add('$id: an entry has no item');
          continue;
        }
        if (weight == null || weight <= 0) {
          problems.add('$id/$itemId: weight must be positive');
          continue;
        }
        if (min == null || max == null || min < 1 || max < min) {
          problems.add('$id/$itemId: min/max out of order');
          continue;
        }

        entries.add(
          LootEntry(itemId: itemId, weight: weight, min: min, max: max),
        );
      }

      if (entries.isEmpty) {
        problems.add('$id: every entry was rejected');
        continue;
      }

      tables.add(
        LootTable(
          id: id,
          source: source,
          match: [
            for (final tag in (entry['match'] as List? ?? const []))
              if (tag is String) tag,
          ],
          generated: entry['generated'] == true,
          barrier: Barrier.fromWire(entry['barrier'] as String?),
          entries: entries,
        ),
      );
    }

    return LootTableSet(tables, problems);
  }

  /// Checks the tables against the catalogue they draw from.
  ///
  /// Separate from parsing because a table file and an item file can be shipped
  /// by different content packs, and the pair is only wrong once both are read.
  List<String> validateAgainst(ItemCatalogue catalogue) {
    final faults = <String>[];

    for (final table in tables) {
      for (final entry in table.entries) {
        final item = catalogue[entry.itemId];
        if (item == null) {
          faults.add('${table.id}: no such item as ${entry.itemId}');
          continue;
        }
        if (table.source != LootSource.procedural) continue;

        // §10.1, stated as a rule rather than left to whoever edits the file.
        if (item.kind == ItemKind.firearm) {
          faults.add('${table.id}: procedural points may not hold firearms '
              '(${entry.itemId})');
        }
        final form = item.props['form'];
        if (item.kind == ItemKind.literature &&
            (form == 'textbook' || form == 'encyclopedia')) {
          faults.add('${table.id}: procedural points may not hold advanced '
              'literature (${entry.itemId})');
        }
      }
    }

    return faults;
  }
}
