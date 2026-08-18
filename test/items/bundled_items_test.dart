import 'dart:convert';
import 'dart:io';

import 'package:arls_za/inventory/body_slots.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/inventory/item_use.dart';
import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:test/test.dart';

/// The bundled catalogue, checked as data rather than as code.
///
/// §4.1 says the JSON is validated at build time. This is that check, and it
/// reads the real shipped files — a rifle that weighs nothing, an id that two
/// files both claim, or a calibre no weapon fires fails here rather than in a
/// player's hands.
///
/// It also holds the balance tables to their sources. §10.3.1 and §10.3.2 are
/// not decoration: the muzzle energies decide how many rounds an enemy takes
/// and the melee figures decide whether a clinch is survivable, so an edit to
/// one of those numbers has to be a deliberate act with the table redone, not
/// a quiet tweak in a JSON file.
void main() {
  ItemCatalogue read() => ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  final catalogue = read();

  group('the shipped files', () {
    test('every one of them is valid', () {
      expect(
        catalogue.problems,
        isEmpty,
        reason: catalogue.problems.join('\n'),
      );
    });

    test('no id is claimed by two files', () {
      // Ids are what loot tables, recipes and save rows reference. A clash
      // means one definition is unreachable and nothing says which.
      expect(
        catalogue.replacements,
        isEmpty,
        reason: 'overwritten: ${catalogue.replacements}',
      );
    });

    test('everything bundled names itself with a key, not inline text', () {
      // Inline names exist for content packs, which cannot add a translation
      // key without a new build. Anything shipped with the app can.
      final inline = catalogue.all.where((item) => item.name.key == null);

      expect(inline.map((item) => item.id), isEmpty);
    });

    test('everything can be produced by somewhere', () {
      final orphans = catalogue.all.where((item) => item.lootTags.isEmpty);

      expect(
        orphans.map((item) => item.id),
        isEmpty,
        reason: 'no loot tag means the item exists but never appears',
      );
    });
  });

  group('the balance tables', () {
    test('firearm muzzle energies are §10.3.1\'s', () {
      const expected = {
        'weapon_rifle_22lr': 160,
        'weapon_revolver_38': 420,
        'weapon_pistol_9mm': 500,
        'weapon_smg_9mm': 560,
        'weapon_rifle_545': 1350,
        'weapon_rifle_762x39': 2000,
        'weapon_shotgun_pump': 2400,
        'weapon_rifle_mosin': 3600,
      };

      for (final entry in expected.entries) {
        expect(
          catalogue[entry.key]?.props['muzzle_energy_j'],
          entry.value,
          reason: '${entry.key} — §10.3.1 balanced the damage model on this',
        );
      }
    });

    test('melee blood loss and swing times are §10.3.2\'s', () {
      const expected = {
        'melee_knife': (180, 0.9),
        'melee_machete': (310, 1.3),
        'melee_axe': (430, 1.9),
        'melee_crowbar': (330, 1.7),
      };

      for (final entry in expected.entries) {
        final item = catalogue[entry.key]!;
        expect(item.props['blood_ml_per_hit'], entry.value.$1);
        expect(item.props['swing_seconds'], entry.value.$2);
      }
    });

    test('build materials reproduce every row of §18.2', () {
      // The five unit masses are solved out of that table, not chosen. If one
      // of them moves, every shelter module costs something different.
      double kg(String id) => catalogue[id]!.weightKg;
      final wood = kg('mat_wood');
      final metal = kg('mat_metal');
      final plastic = kg('mat_plastic');
      final fabric = kg('mat_fabric');
      final component = kg('mat_component');

      double module({int w = 0, int m = 0, int p = 0, int f = 0, int c = 0}) =>
          w * wood + m * metal + p * plastic + f * fabric + c * component;

      expect(module(w: 12, m: 4, f: 6), closeTo(31.8, 0.05), reason: 'camp');
      expect(module(w: 20, m: 6), closeTo(49.0, 0.05), reason: 'store L1');
      expect(module(w: 28, m: 12, p: 6), closeTo(76.4, 0.05));
      expect(module(w: 36, m: 18, p: 10), closeTo(103.0, 0.05));
      expect(module(w: 15, m: 20, c: 2), closeTo(61.6, 0.05));
      expect(module(w: 18, m: 30, p: 10, c: 5), closeTo(89.0, 0.05));
      expect(module(w: 22, m: 42, p: 16, c: 10), closeTo(121.4, 0.05));
      expect(module(w: 12, f: 15), closeTo(28.5, 0.05));
      expect(module(w: 16, p: 6, f: 22), closeTo(41.0, 0.05));
      expect(module(w: 20, p: 10, f: 30), closeTo(53.0, 0.05));
      expect(module(m: 10, p: 14, c: 4), closeTo(23.8, 0.05));
      expect(module(m: 14, p: 20, c: 8), closeTo(35.4, 0.05));
      expect(module(m: 18, p: 28, c: 14), closeTo(49.4, 0.05));
    });

    test('a full combat kit leaves room for loot (§10.3.4)', () {
      // §10.3.4 puts the kit at 14.8 kg against a 36 kg limit and expects
      // ~21 kg left for loot. The exact figure depends on which coat the doc
      // had in mind, so what is checked is the invariant it was making: the
      // kit takes well under half the carry, or the game is a rucksack sim.
      const kit = {
        'weapon_rifle_545': 1,
        'ammo_545x39': 60,
        'melee_machete': 1,
        'cloth_winter_jacket': 1,
        'cloth_winter_trousers': 1,
        'cloth_boots': 1,
        'armor_helmet_ballistic': 1,
        'drink_water_bottle_1500': 1,
        'food_canned_meat': 2,
        'food_energy_bar': 3,
        'med_first_aid_kit': 1,
        'med_tourniquet': 1,
        'tool_multitool': 1,
        'tool_flashlight': 1,
        'tool_binoculars': 1,
        'pack_trekking': 1,
      };

      var mass = 0.0;
      for (final entry in kit.entries) {
        final item = catalogue[entry.key];
        expect(item, isNotNull, reason: '${entry.key} is missing');
        mass += item!.weightKg * entry.value;
      }

      expect(mass, lessThan(18.0), reason: 'kit mass = $mass kg of 36 kg');
      expect(
        catalogue['pack_trekking']!.props['comfort_carry_bonus_kg'],
        12,
        reason: '§10.3.4: the trekking pack lifts comfort carry 24 -> 36 kg',
      );
    });
  });

  group('the rules items have to obey', () {
    test('every calibre that is fired can be found, and the reverse', () {
      final fired = {
        for (final gun in catalogue.ofKind(ItemKind.firearm))
          gun.props['caliber'] as String,
      };
      final found = {
        for (final item in catalogue.all)
          if (item.kind == ItemKind.ammo && item.props['caliber'] != null)
            item.props['caliber'] as String,
      };

      // A calibre with no ammunition is a weapon that cannot be used; ammunition
      // with no weapon is weight a player carries for nothing.
      expect(fired.difference(found), isEmpty, reason: 'no ammunition for');
      expect(found.difference(fired), isEmpty, reason: 'nothing fires');
    });

    test('a suppressor only fits calibres that exist', () {
      final fired = {
        for (final gun in catalogue.ofKind(ItemKind.firearm))
          gun.props['caliber'] as String,
      };
      final fits = (catalogue['tool_suppressor']!.props['attaches_to']! as List)
          .cast<String>();

      expect(fired.containsAll(fits), isTrue);
    });

    test('no book stacks, and each rolls a sane page count (§4.6.4)', () {
      for (final book in catalogue.ofKind(ItemKind.literature)) {
        expect(book.stackable, isFalse, reason: book.id);
        final min = book.props['pages_min']! as int;
        final max = book.props['pages_max']! as int;
        expect(min, greaterThan(0), reason: book.id);
        expect(max, greaterThanOrEqualTo(min), reason: book.id);
        expect(book.props['xp_per_page'], isA<int>(), reason: book.id);
        expect(book.props['g_per_page'], isA<num>(), reason: book.id);
      }
    });

    test('a book\'s stated mass is one its page count could produce', () {
      // weight_kg is the mid-length copy; the real one is rolled per instance.
      // If the two disagree, inventory previews lie about what a book costs.
      for (final book in catalogue.ofKind(ItemKind.literature)) {
        final min = book.props['pages_min']! as int;
        final max = book.props['pages_max']! as int;
        final perPage = (book.props['g_per_page']! as num).toDouble();
        final cover = (book.props['cover_g']! as num).toDouble();

        final lightest = (min * perPage + cover) / 1000;
        final heaviest = (max * perPage + cover) / 1000;

        expect(
          book.weightKg,
          inInclusiveRange(lightest, heaviest),
          reason: '${book.id}: $lightest-$heaviest kg',
        );
      }
    });

    test('armour protects a location or insulates, and says which', () {
      for (final piece in catalogue.ofKind(ItemKind.armor)) {
        final coverage = (piece.props['coverage_pct']! as num).toDouble();
        final level = (piece.props['protection_level']! as num).toDouble();
        // §4.4: the two axes are independent, but protection with no coverage
        // reduces damage nowhere, and coverage with no protection reduces none.
        expect(
          coverage > 0,
          level > 0,
          reason: '${piece.id} has one half of §4.4 and not the other',
        );
        expect(piece.props['insulation_clo'], isA<num>(), reason: piece.id);
      }
    });

    test('every garment names a place on the body the game knows', () {
      // §4.4's slots are the data's own values, and the figure on the
      // inventory screen is built from them. A slot spelled any other way is
      // a garment that cannot be put on at all.
      for (final piece in catalogue.ofKind(ItemKind.armor)) {
        expect(
          BodySlot.fromWire(piece.props['slot'] as String?),
          isNotNull,
          reason: '${piece.id} says slot=${piece.props['slot']}',
        );
      }
    });

    test('a weapon has a place to go, without the data naming one', () {
      // §5.5.1: the game has to know which weapon is out — it is the one that
      // fires and the one a clinch is fought with — and §4.4 never gave a
      // blade a slot, because §4.4 only dresses a body.
      for (final kind in [ItemKind.firearm, ItemKind.melee]) {
        for (final weapon in catalogue.ofKind(kind)) {
          expect(
            BodySlot.fromWire(wearSlotOf(weapon)),
            BodySlot.hand,
            reason: weapon.id,
          );
        }
      }
    });

    test('and nothing else names one', () {
      // A slot on a crowbar would put it on the figure and take it out of the
      // pack. Everything that is not a garment is worn by kind or not at all.
      final strays = catalogue.all
          .where((item) => item.kind != ItemKind.armor)
          .where((item) => item.props['slot'] != null);

      expect(strays.map((item) => item.id), isEmpty);
    });

    test('every place on the body has something to put in it', () {
      // An empty slot on the figure that no item in the game can ever fill is
      // a promise the catalogue does not keep.
      for (final slot in BodySlot.values) {
        // The back holds packs and the hand holds weapons; neither is a
        // garment slot, and neither is named by a `slot` prop (§4.4, §5.5.1).
        if (slot == BodySlot.back || slot == BodySlot.hand) continue;

        expect(
          catalogue
              .ofKind(ItemKind.armor)
              .where((piece) => piece.props['slot'] == slot.wire),
          isNotEmpty,
          reason: 'nothing goes on ${slot.wire}',
        );
      }
    });

    test('the back is filled by packs, which name no slot of their own', () {
      // §4.5: a pack is worn but is not a garment — it lives in packId, which
      // is why it is the one slot read from the kind rather than from a prop.
      final packs = catalogue.ofKind(ItemKind.backpack);

      expect(packs, isNotEmpty);
      for (final pack in packs) {
        expect(pack.props['slot'], isNull, reason: pack.id);
        expect(pack.props['capacity_l'], isA<num>(), reason: pack.id);
        expect(
          pack.props['comfort_carry_bonus_kg'],
          isA<num>(),
          reason: pack.id,
        );
      }
    });

    test('everything edible or medical can actually be used (§4.7)', () {
      // The inventory offers "use" from useOf, so a tin with no consume time
      // is a tin nobody can open.
      for (final item in catalogue.all) {
        final usable = useOf(item) != null;
        final shouldBe =
            item.kind == ItemKind.food || item.kind == ItemKind.medical;

        expect(usable, shouldBe, reason: '${item.id} (${item.kind.name})');
      }
    });

    test('nothing wearable weighs more than a plate carrier', () {
      // A sanity bound. Something that costs a quarter of the carry limit to
      // wear should be a deliberate choice, and there is exactly one.
      final heavy = catalogue
          .ofKind(ItemKind.armor)
          .where((piece) => piece.weightKg > 9);

      expect(heavy.map((piece) => piece.id), isEmpty);
    });

    test('a backpack that holds more also weighs more', () {
      // A bag is exempt: it holds more than a schoolbag and weighs less,
      // because what it costs is a hand rather than mass (occupies_hands).
      final packs =
          catalogue
              .ofKind(ItemKind.backpack)
              .where((pack) => pack.props['occupies_hands'] != true)
              .toList()
            ..sort(
              (a, b) => (a.props['capacity_l']! as int).compareTo(
                b.props['capacity_l']! as int,
              ),
            );

      for (var i = 1; i < packs.length; i++) {
        expect(
          packs[i].weightKg,
          greaterThan(packs[i - 1].weightKg),
          reason:
              '${packs[i].id} holds more than ${packs[i - 1].id} '
              'and must not be lighter as well',
        );
      }
    });

    test('food gives calories or water, never neither', () {
      for (final item in catalogue.ofKind(ItemKind.food)) {
        final kcal = (item.props['kcal']! as num).toDouble();
        final water = (item.props['water_ml']! as num).toDouble();
        expect(kcal + water, greaterThan(0), reason: item.id);
        expect(item.props['consume_seconds'], isA<num>(), reason: item.id);
      }
    });

    test('every grade of bleeding in §2.6 has something that stops it', () {
      final treated = {
        for (final item in catalogue.ofKind(ItemKind.medical))
          item.props['stops_bleeding_class'],
      };

      expect(
        treated,
        containsAll(['superficial', 'moderate', 'strong', 'arterial']),
        reason: 'a bleed with no answer is a death with no decision',
      );
    });

    test('anything that wears out starts whole and wears at a rate', () {
      for (final item in catalogue.all) {
        if (item.condition == null) continue;
        expect(item.condition, 100, reason: '${item.id} starts used');
        expect(
          item.conditionDecayPerUse,
          isNotNull,
          reason: '${item.id} wears out but never wears',
        );
      }
    });
  });

  group('names', () {
    final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

    test('every bundled item has a name in every language', () {
      final missing = <String>[];
      for (final item in catalogue.all) {
        for (final language in const ['pl', 'en']) {
          final key = item.name.key!;
          if (names.lookup(key, language: language) == null) {
            missing.add('$key ($language)');
          }
        }
      }

      expect(missing, isEmpty, reason: missing.join(', '));
    });

    test('every Polish name is written, not inherited from English', () {
      // lookup falls back to English, which would hide a missing translation
      // behind a plausible-looking name.
      final table = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());
      final source =
          jsonDecode(File(kItemNamesAsset).readAsStringSync())
              as Map<String, Object?>;
      final raw = source['names']! as Map<String, Object?>;

      final untranslated = [
        for (final item in catalogue.all)
          if ((raw[item.name.key!]! as Map<String, Object?>)['pl'] == null)
            item.id,
      ];

      expect(untranslated, isEmpty);
      expect(table.keys, isNotEmpty);
    });

    test('the table has no names for items that do not exist', () {
      final keys = {for (final item in catalogue.all) item.name.key};

      expect(names.keys.toSet().difference(keys.cast<String>()), isEmpty);
    });

    test('an item resolves through the table the way the UI will', () {
      final axe = catalogue['melee_axe']!;

      expect(
        axe.name.resolve(language: 'pl', lookup: names.forLanguage('pl')),
        'Siekiera',
      );
      expect(
        axe.name.resolve(language: 'en', lookup: names.forLanguage('en')),
        'Axe',
      );
    });
  });

  group('content packs', () {
    test('a pack adds items without a new build', () {
      final extended = ItemCatalogue.load([
        for (final asset in kBundledItemAssets)
          ItemSource(asset, File(asset).readAsStringSync()),
        const ItemSource('extra.items.json', '''
          {"schema": 1, "items": [{
            "id": "weapon_crossbow",
            "type": "melee",
            "name": {"pl": "Kusza", "en": "Crossbow"},
            "weight_kg": 2.8,
            "volume_l": 5.0,
            "rarity": "rare",
            "loot_tags": ["sport", "hunting"],
            "props": {"blood_ml_per_hit": 400}
          }]}
        '''),
      ]);

      expect(extended.problems, isEmpty, reason: '${extended.problems}');
      expect(extended.length, catalogue.length + 1);
      expect(
        extended['weapon_crossbow']!.name.resolve(language: 'pl'),
        'Kusza',
      );
    });

    test('a pack that replaces a bundled item is recorded, not silent', () {
      final patched = ItemCatalogue.load([
        for (final asset in kBundledItemAssets)
          ItemSource(asset, File(asset).readAsStringSync()),
        const ItemSource('patch.items.json', '''
          {"schema": 1, "items": [{
            "id": "melee_knife",
            "type": "melee",
            "name_key": "item.melee_knife.name",
            "weight_kg": 0.2,
            "volume_l": 0.3,
            "rarity": "common",
            "loot_tags": ["residential"],
            "props": {"blood_ml_per_hit": 999}
          }]}
        '''),
      ]);

      expect(patched.replacements, {'melee_knife': 'patch.items.json'});
      expect(patched['melee_knife']!.props['blood_ml_per_hit'], 999);
    });

    test('a malformed pack cannot take the bundled catalogue with it', () {
      final broken = ItemCatalogue.load([
        for (final asset in kBundledItemAssets)
          ItemSource(asset, File(asset).readAsStringSync()),
        const ItemSource('broken.items.json', '{"schema": 1, "items": ['),
      ]);

      expect(broken.length, catalogue.length);
      expect(broken.problems.single.itemId, 'broken.items.json');
    });
  });
}
