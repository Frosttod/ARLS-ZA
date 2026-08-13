import 'dart:io';
import 'dart:math';

import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:test/test.dart';

/// §10.3, §10.3.5. The tables decide what a player walks two kilometres for,
/// so the checks here are about the promises the design makes them keep: every
/// entry names an item that exists, a procedural point never pays like a real
/// one, and depth — the only cost a search has — actually changes the result.
void main() {
  const tablesAsset = 'assets/data/loot_tables.json';

  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final tables = LootTableSet.parse(File(tablesAsset).readAsStringSync());

  group('the shipped tables', () {
    test('parse without a fault', () {
      expect(tables.problems, isEmpty, reason: tables.problems.join('\n'));
    });

    test('are the twenty §10.3 asks for: 11 from OSM, 9 procedural', () {
      final osm = tables.tables.where((t) => t.source == LootSource.osm);
      final procedural = tables.tables.where(
        (t) => t.source == LootSource.procedural,
      );

      expect(osm, hasLength(11));
      expect(procedural, hasLength(9));
    });

    test('every entry names an item that exists', () {
      // A typo here is a loot box that opens onto nothing.
      expect(
        tables.validateAgainst(catalogue),
        isEmpty,
        reason: tables.validateAgainst(catalogue).join('\n'),
      );
    });

    test('every table can be reached from a tag', () {
      final unreachable = tables.tables.where((t) => t.match.isEmpty);

      expect(unreachable.map((t) => t.id), isEmpty);
    });

    test('no two tables claim the same tag', () {
      // Two tables on one tag means the loot at that place depends on which
      // was listed first, which is not a decision anybody made.
      final owner = <String, String>{};
      final clashes = <String>[];
      for (final table in tables.tables) {
        for (final tag in table.match) {
          final previous = owner[tag];
          if (previous != null) clashes.add('$tag: $previous and ${table.id}');
          owner[tag] = table.id;
        }
      }

      expect(clashes, isEmpty);
    });

    test('every kind of item a player needs is findable somewhere', () {
      final produced = {
        for (final table in tables.tables)
          for (final entry in table.entries) catalogue[entry.itemId]!.kind,
      };

      expect(
        produced,
        containsAll([
          ItemKind.firearm,
          ItemKind.melee,
          ItemKind.armor,
          ItemKind.backpack,
          ItemKind.food,
          ItemKind.medical,
          ItemKind.literature,
          ItemKind.tool,
          ItemKind.crafting,
          ItemKind.material,
        ]),
      );
    });

    test('nothing in the catalogue exists that can never be found', () {
      final produced = {
        for (final table in tables.tables)
          for (final entry in table.entries) entry.itemId,
      };
      final unreachable = catalogue.all
          .map((item) => item.id)
          .where((id) => !produced.contains(id));

      expect(unreachable, isEmpty, reason: 'defined but never dropped');
    });
  });

  group('the §10.1 clause about small towns', () {
    test('no procedural point holds a firearm or an advanced book', () {
      // The rule the doc gives: a player who lives where OSM is thin gets more
      // points more often, not a different game.
      for (final table in tables.tables) {
        if (table.source != LootSource.procedural) continue;
        for (final entry in table.entries) {
          final item = catalogue[entry.itemId]!;
          expect(item.kind, isNot(ItemKind.firearm), reason: table.id);
          expect(
            item.props['form'],
            isNot(anyOf('textbook', 'encyclopedia')),
            reason: '${table.id}/${entry.itemId}',
          );
        }
      }
    });

    test('the same contents pay 55% at a procedural point', () {
      // Two tables identical but for their source, so the only thing being
      // measured is §10.1's multiplier and not which items each happens to
      // list.
      const entries = [
        LootEntry(itemId: 'mat_metal', weight: 20, min: 1, max: 1),
        LootEntry(itemId: 'tool_binoculars', weight: 20, min: 1, max: 1),
      ];

      final osm = _rareShare(
        const LootTable(
          id: 'a',
          source: LootSource.osm,
          match: [],
          entries: entries,
        ),
        catalogue,
        SearchDepth.deep,
      );
      final procedural = _rareShare(
        const LootTable(
          id: 'b',
          source: LootSource.procedural,
          match: [],
          entries: entries,
        ),
        catalogue,
        SearchDepth.deep,
      );

      // The multiplier is exact; the sampled share only has to move the right
      // way. A drop is a map keyed by item, so repeat draws of the same thing
      // collapse into one entry and the measured share is compressed towards
      // even — enough to show the direction, not enough to read 0.55 off.
      expect(LootSource.procedural.rareWeightMultiplier, 0.55);
      expect(LootSource.osm.rareWeightMultiplier, 1.0);
      expect(procedural, lessThan(osm), reason: '$osm -> $procedural');
    });
  });

  group('depth is the whole cost of a search (§10.3.5)', () {
    test('a shallow search never reaches past common', () {
      final random = Random(7);
      final table = tables['poi_weapons']!;

      for (var attempt = 0; attempt < 400; attempt++) {
        final drop = table.roll(
          random,
          depth: SearchDepth.shallow,
          catalogue: catalogue,
        );
        for (final id in drop.keys) {
          expect(catalogue[id]!.rarity, Rarity.common, reason: id);
        }
      }
    });

    test('a thorough search reaches uncommon and stops there', () {
      final random = Random(11);
      final table = tables['poi_weapons']!;
      final seen = <Rarity>{};

      for (var attempt = 0; attempt < 400; attempt++) {
        final drop = table.roll(
          random,
          depth: SearchDepth.thorough,
          catalogue: catalogue,
        );
        seen.addAll(drop.keys.map((id) => catalogue[id]!.rarity));
      }

      expect(seen, contains(Rarity.uncommon));
      expect(seen, isNot(contains(Rarity.rare)));
      expect(seen, isNot(contains(Rarity.veryRare)));
    });

    test('only a deep search finds anything rare', () {
      final random = Random(3);
      final table = tables['poi_military']!;
      var rares = 0;

      for (var attempt = 0; attempt < 600; attempt++) {
        final drop = table.roll(
          random,
          depth: SearchDepth.deep,
          catalogue: catalogue,
        );
        rares += drop.keys
            .where(
              (id) =>
                  catalogue[id]!.rarity == Rarity.rare ||
                  catalogue[id]!.rarity == Rarity.veryRare,
            )
            .length;
      }

      expect(rares, greaterThan(0));
    });

    test('the three depths cost 30, 90 and 180 seconds', () {
      expect(SearchDepth.shallow.seconds, 30);
      expect(SearchDepth.thorough.seconds, 90);
      expect(SearchDepth.deep.seconds, 180);
    });
  });

  group('Scouting', () {
    test('makes a search better, not faster', () {
      // §10.3.5 raises the rare weight by 1 + 0.30 x level and touches nothing
      // else. The number of draws is depth's business.
      final table = tables['poi_military']!;

      int raresWith(double scouting, int seed) {
        final random = Random(seed);
        var rares = 0;
        for (var attempt = 0; attempt < 800; attempt++) {
          final drop = table.roll(
            random,
            depth: SearchDepth.deep,
            catalogue: catalogue,
            scouting: scouting,
          );
          rares += drop.keys
              .where((id) => catalogue[id]!.rarity != Rarity.common)
              .length;
        }
        return rares;
      }

      expect(raresWith(1.0, 5), greaterThan(raresWith(0.0, 5)));
    });

    test('cannot open a tier that the depth closed', () {
      final random = Random(19);
      final table = tables['poi_military']!;

      for (var attempt = 0; attempt < 400; attempt++) {
        final drop = table.roll(
          random,
          depth: SearchDepth.shallow,
          catalogue: catalogue,
          scouting: 1.0,
        );
        for (final id in drop.keys) {
          expect(catalogue[id]!.rarity, Rarity.common);
        }
      }
    });
  });

  group('a search behaves', () {
    test('the same seed gives the same search', () {
      // §11's determinism clause: a session replays from its seed, and loot is
      // part of the session.
      final table = tables['poi_pharmacy']!;
      Map<String, int> once() => table.roll(
        Random(42),
        depth: SearchDepth.deep,
        catalogue: catalogue,
      );

      expect(once(), once());
    });

    test('a search always produces something', () {
      final random = Random(1);
      for (final table in tables.tables) {
        final drop = table.roll(
          random,
          depth: SearchDepth.thorough,
          catalogue: catalogue,
        );
        expect(drop, isNotEmpty, reason: table.id);
      }
    });

    test('counts stay inside what the entry allows', () {
      final random = Random(2);
      final table = tables['poi_grocery']!;
      final bounds = {
        for (final entry in table.entries) entry.itemId: (entry.min, entry.max),
      };

      for (var attempt = 0; attempt < 200; attempt++) {
        final drop = table.roll(
          random,
          depth: SearchDepth.shallow,
          catalogue: catalogue,
        );
        for (final item in drop.entries) {
          // One draw at least, so the low bound is the entry's own; the high
          // bound allows for the same item coming up in both draws.
          expect(item.value, greaterThanOrEqualTo(bounds[item.key]!.$1));
          expect(item.value, lessThanOrEqualTo(bounds[item.key]!.$2 * 2));
        }
      }
    });
  });

  group('what the parser refuses', () {
    LootTableSet parse(String body) => LootTableSet.parse(body);

    test('a table with no entries — a place that pays nothing', () {
      final result = parse(
        '{"schema":1,"tables":[{"id":"t","source":"osm","entries":[]}]}',
      );

      expect(result.tables, isEmpty);
      expect(result.problems.single, contains('no entries'));
    });

    test('a weight of zero, which would silently never appear', () {
      final result = parse(
        '{"schema":1,"tables":[{"id":"t","source":"osm","entries":'
        '[{"item":"med_bandage","weight":0,"min":1,"max":1}]}]}',
      );

      expect(result.problems.first, contains('weight'));
    });

    test('a count range the wrong way round', () {
      final result = parse(
        '{"schema":1,"tables":[{"id":"t","source":"osm","entries":'
        '[{"item":"med_bandage","weight":5,"min":4,"max":2}]}]}',
      );

      expect(result.problems.first, contains('min/max'));
    });

    test('an unknown source, because §10.1 keys quality off it', () {
      final result = parse(
        '{"schema":1,"tables":[{"id":"t","source":"somewhere","entries":'
        '[{"item":"med_bandage","weight":5,"min":1,"max":1}]}]}',
      );

      expect(result.problems.single, contains('source'));
    });

    test('an item no catalogue has, once both are read', () {
      final result = parse(
        '{"schema":1,"tables":[{"id":"t","source":"osm","entries":'
        '[{"item":"weapon_railgun","weight":5,"min":1,"max":1}]}]}',
      );

      expect(result.isClean, isTrue);
      expect(result.validateAgainst(catalogue).single, contains('no such item'));
    });

    test('a procedural table holding a rifle', () {
      final result = parse(
        '{"schema":1,"tables":[{"id":"t","source":"procedural","entries":'
        '[{"item":"weapon_rifle_545","weight":5,"min":1,"max":1}]}]}',
      );

      expect(
        result.validateAgainst(catalogue).single,
        contains('may not hold firearms'),
      );
    });
  });
}

/// Share of draws that came out rare, over enough rolls to be worth comparing.
double _rareShare(LootTable table, ItemCatalogue catalogue, SearchDepth depth) {
  final random = Random(99);
  var rare = 0;
  var total = 0;

  for (var attempt = 0; attempt < 600; attempt++) {
    final drop = table.roll(random, depth: depth, catalogue: catalogue);
    for (final id in drop.keys) {
      total++;
      if (catalogue[id]!.rarity != Rarity.common) rare++;
    }
  }

  return total == 0 ? 0 : rare / total;
}
