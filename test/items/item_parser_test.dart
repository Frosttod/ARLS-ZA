import 'dart:convert';

import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_parser.dart';
import 'package:test/test.dart';

/// §4.1. The validation exists so that a broken entry is caught by a machine
/// before it is caught by a player holding a rifle that weighs nothing.
void main() {
  Map<String, Object?> validItem({
    String id = 'weapon_ak74',
    Map<String, Object?> overrides = const {},
  }) => {
    'id': id,
    'type': 'firearm',
    'name_key': 'item.$id.name',
    'weight_kg': 3.3,
    'volume_l': 4.2,
    'stackable': false,
    'rarity': 'uncommon',
    'loot_tags': ['military', 'police'],
    'props': {'caliber': '5.45x39'},
    ...overrides,
  };

  String file(List<Map<String, Object?>> items, {int schema = 1}) =>
      jsonEncode({'schema': schema, 'items': items});

  ItemParseResult parse(List<Map<String, Object?>> items, {int schema = 1}) =>
      parseItems(file(items, schema: schema));

  group('a well-formed file', () {
    test('reads the fields §4.1 fixes', () {
      final result = parse([validItem()]);

      expect(result.isClean, isTrue, reason: '${result.problems}');
      final item = result.items.single;
      expect(item.id, 'weapon_ak74');
      expect(item.kind, ItemKind.firearm);
      expect(item.weightKg, 3.3);
      expect(item.volumeL, 4.2);
      expect(item.rarity, Rarity.uncommon);
      expect(item.lootTags, ['military', 'police']);
      expect(item.props['caliber'], '5.45x39');
    });

    test('keeps props untyped, so a new kind needs no migration', () {
      final result = parse([
        validItem(
          id: 'book_survival',
          overrides: {
            'type': 'literature',
            'props': {'progress_pages': 240, 'title_id': 'survival_manual'},
          },
        ),
      ]);

      expect(result.items.single.props['progress_pages'], 240);
    });
  });

  group('what is refused', () {
    test('an item with no weight, rather than a guessed one', () {
      // A guess would end up in a loot table and in a player's hands.
      final result = parse([
        validItem(overrides: {'weight_kg': null}),
      ]);

      expect(result.items, isEmpty);
      expect(result.problems.single.message, contains('weight_kg'));
    });

    test('an item with no volume — mass alone is not a limit (§4.1)', () {
      final result = parse([
        validItem(overrides: {'volume_l': null}),
      ]);

      expect(result.items, isEmpty);
      expect(result.problems.single.message, contains('volume_l'));
    });

    test('an unknown rarity, because loot tables read it', () {
      final result = parse([
        validItem(overrides: {'rarity': 'legendary'}),
      ]);

      expect(result.items, isEmpty);
      expect(result.problems.single.message, contains('legendary'));
    });

    test('a duplicate id, because one of the two becomes unreachable', () {
      final result = parse([validItem(), validItem()]);

      expect(result.items, hasLength(1));
      expect(result.problems.single.message, contains('duplicate'));
    });

    test('an item with no name at all', () {
      final result = parse([
        validItem(overrides: {'name_key': null}),
      ]);

      expect(result.problems.single.message, contains('name'));
    });

    test('a stackable item that also wears out', () {
      // Two would share one condition and the first use would wear the pile.
      final result = parse([
        validItem(overrides: {'stackable': true, 'condition': 100}),
      ]);

      expect(result.problems.single.message, contains('stackable'));
    });

    test('stackable literature (§4.6.3)', () {
      // Every copy carries its own reading progress.
      final result = parse([
        validItem(overrides: {'type': 'literature', 'stackable': true}),
      ]);

      expect(result.problems.single.message, contains('literature'));
    });
  });

  group('the whole file', () {
    test('every fault is reported, not just the first', () {
      // Eleven mistakes should cost one pass, not eleven builds.
      final result = parse([
        validItem(id: 'a', overrides: {'weight_kg': null}),
        validItem(id: 'b', overrides: {'volume_l': null}),
        validItem(id: 'c', overrides: {'rarity': 'nope'}),
      ]);

      expect(result.problems, hasLength(3));
      expect(result.items, isEmpty);
    });

    test('one bad entry does not take the good ones with it', () {
      final result = parse([
        validItem(id: 'good'),
        validItem(id: 'bad', overrides: {'weight_kg': null}),
      ]);

      expect(result.items.single.id, 'good');
      expect(result.problems, hasLength(1));
    });

    test('a file with no schema version is refused', () {
      expect(
        parseItems(jsonEncode({'items': <Object>[]})).problems.single.message,
        contains('schema'),
      );
    });

    test('a newer schema is refused whole, not read in part', () {
      // Reading what we recognise would produce a catalogue missing exactly
      // what the new version added, and nothing would say so.
      final result = parse([validItem()], schema: kItemSchemaVersion + 1);

      expect(result.items, isEmpty);
      expect(result.problems.single.message, contains('newer'));
    });

    test('malformed JSON is one problem, not a crash', () {
      final result = parseItems('{"schema": 1, "items": [');

      expect(result.items, isEmpty);
      expect(result.problems.single.message, contains('JSON'));
    });
  });

  group('names', () {
    test('a key is used when the app can translate it', () {
      final name = parse([validItem()]).items.single.name;

      expect(
        name.resolve(
          language: 'pl',
          lookup: (key) => key == 'item.weapon_ak74.name' ? 'AK-74' : null,
        ),
        'AK-74',
      );
    });

    test('a content pack may name things the app has never heard of', () {
      // The whole point of a content pack is not needing a new build, and a
      // new localisation key needs one.
      final result = parse([
        validItem(
          id: 'weapon_new',
          overrides: {
            'name_key': null,
            'name': {'pl': 'Karabinek', 'en': 'Carbine'},
          },
        ),
      ]);

      expect(result.isClean, isTrue, reason: '${result.problems}');
      expect(result.items.single.name.resolve(language: 'pl'), 'Karabinek');
      expect(result.items.single.name.resolve(language: 'en'), 'Carbine');
    });

    test('a key wins over an inline name, having been reviewed', () {
      final result = parse([
        validItem(
          overrides: {
            'name': {'pl': 'Coś innego'},
          },
        ),
      ]);

      expect(
        result.items.single.name.resolve(
          language: 'pl',
          lookup: (_) => 'AK-74',
        ),
        'AK-74',
      );
    });

    test('an untranslated language falls back rather than showing nothing', () {
      final result = parse([
        validItem(
          id: 'x',
          overrides: {
            'name_key': null,
            'name': {'en': 'Carbine'},
          },
        ),
      ]);

      expect(result.items.single.name.resolve(language: 'pl'), 'Carbine');
    });
  });
}
