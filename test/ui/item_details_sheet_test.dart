import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/item_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arls_za/sim/body.dart';
import 'package:flutter_test/flutter_test.dart';

/// SZCZEGÓŁY PRZEDMIOTU (§4.2–§4.7).
///
/// A player standing over a second vest is not asking what it does, they are
/// asking whether to swap. Both answers have to be in one window, with the
/// direction marked, because "protection 4 against protection 2, coverage 40
/// against 55" is arithmetic nobody does in a street in the rain.
void main() {
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  // ⚠️ Obie tabele, tak jak w grze: nazwy i zdania są jednym lookupem, więc
  // arkusz karmiony samymi nazwami byłby arkuszem, którego gracz nie widzi.
  final names = ItemNames.merged([
    ItemNames.parse(File(kItemNamesAsset).readAsStringSync()),
    ItemNames.parse(File(kItemDescriptionsAsset).readAsStringSync()),
  ]);
  final recipes = RecipeBook.parse(File(kRecipesAsset).readAsStringSync());

  /// A bench with nothing learned: §18.6's floor share, which is what most
  /// players read most of the time.
  const plain = CraftBench(
    atShelter: true,
    workshopLevel: 0,
    atHand: {'tool_multitool'},
    materials: {},
  );

  Future<void> open(
    WidgetTester tester, {
    String? itemId,
    CarriedItem? line,
    required Inventory inventory,
    VoidCallback? onWear,
    String? wearLabel,
    void Function(CarriedItem line, CarriedItem attachment)? onAttach,
    bool fromPack = true,
    CraftBench? bench,
  }) async {
    final entry = line ?? CarriedItem(itemId: itemId!);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showItemDetails(
              context,
              line: entry,
              inventory: ValueNotifier(inventory),
              catalogue: catalogue,
              names: names,
              onWear: onWear,
              wearLabel: wearLabel,
              onAttach: onAttach,
              bench: bench,
              book: bench == null ? null : recipes,
              fromPack: fromPack,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Which way the row is marked, read off the row rather than off the screen:
  /// several rows carry an icon and only one of them is this reading's.
  IconData? markOn(WidgetTester tester, String label) {
    final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
    final icons = find.descendant(of: row.first, matching: find.byType(Icon));
    if (icons.evaluate().isEmpty) return null;
    return tester.widget<Icon>(icons.first).icon;
  }

  testWidgets('an item alone is just its own numbers', (tester) async {
    await open(tester, itemId: 'armor_vest_soft', inventory: const Inventory());

    expect(find.text('Ochrona'), findsOneWidget);
    expect(find.text('Pokrycie'), findsOneWidget);
    // Nothing to compare with, so nothing claims to be better or worse.
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets('mass and bulk are on it, being what everything costs', (
    tester,
  ) async {
    await open(tester, itemId: 'mat_wood', inventory: const Inventory());

    expect(find.text('Masa'), findsOneWidget);
    expect(find.text('Objętość'), findsOneWidget);
  });

  group('a second vest, against the one being worn', () {
    // §4.4: soft vest is protection 2 over 55% of the torso at 2.6 kg; the
    // plate carrier is protection 4 over 40% at 8.5 kg. Neither is simply
    // better, which is exactly why the screen exists.
    final wearingSoft = const Inventory().wear('armor_vest_soft');

    testWidgets('it says what it is being compared with', (tester) async {
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(find.textContaining('Porównanie z'), findsOneWidget);
      expect(find.textContaining('na sobie'), findsOneWidget);
    });

    testWidgets('more protection is a plus', (tester) async {
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Ochrona'), Icons.add);
    });

    testWidgets('less coverage is a minus', (tester) async {
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Pokrycie'), Icons.remove);
    });

    testWidgets('six kilograms more is a minus, not a plus', (tester) async {
      // The reading that is easiest to get backwards: the number goes up and
      // the player is worse off.
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Masa'), Icons.remove);
    });

    testWidgets('and the other way round, from the plate to the soft', (
      tester,
    ) async {
      await open(
        tester,
        itemId: 'armor_vest_soft',
        inventory: const Inventory().wear('armor_vest_plate'),
      );

      expect(markOn(tester, 'Ochrona'), Icons.remove);
      expect(markOn(tester, 'Masa'), Icons.add);
    });

    testWidgets('a reading that is identical is marked neither way', (
      tester,
    ) async {
      // Both vests insulate 0.3 clo. An arrow there would be noise.
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Izolacja'), isNull);
    });
  });

  testWidgets('a jacket is not compared with a vest', (tester) async {
    // Different slots, so one never displaces the other (§4.4).
    await open(
      tester,
      itemId: 'cloth_winter_jacket',
      inventory: const Inventory().wear('armor_vest_soft'),
    );

    expect(find.textContaining('Porównanie z'), findsNothing);
  });

  testWidgets('two in the pack are not compared with each other', (
    tester,
  ) async {
    // The question a player is actually asking is "is this better than mine".
    // Two things in the same pack answer a question nobody has — neither of
    // them is doing anything for the character yet.
    await open(
      tester,
      itemId: 'armor_vest_plate',
      inventory: const Inventory(
        carried: [CarriedItem(itemId: 'armor_vest_soft')],
      ),
    );

    expect(find.textContaining('Porównanie z'), findsNothing);
  });

  testWidgets('the swap can be made from here, without going back', (
    tester,
  ) async {
    var worn = 0;

    await open(
      tester,
      itemId: 'armor_vest_plate',
      inventory: const Inventory().wear('armor_vest_soft'),
      onWear: () => worn++,
      wearLabel: 'Załóż',
    );
    await tester.tap(find.text('Załóż'));
    await tester.pumpAndSettle();

    expect(worn, 1);
    // And the sheet gets out of the way, since the screen behind it changed.
    expect(find.text('Ochrona'), findsNothing);
  });

  testWidgets('what is already worn offers no way to put it on again', (
    tester,
  ) async {
    await open(
      tester,
      itemId: 'armor_vest_soft',
      inventory: const Inventory().wear('armor_vest_soft'),
    );

    expect(find.text('Załóż'), findsNothing);
  });

  group('two copies of one vest, which is the case a player hits', () {
    // Found on a phone: "found a new vest, I have an old one" is usually the
    // same model twice, and comparing an item with itself was refused, so the
    // screen said nothing at all.
    const battered = CarriedItem(itemId: 'armor_vest_soft', condition: 40);
    const found = CarriedItem(itemId: 'armor_vest_soft', condition: 90);

    testWidgets('the worn copy is what the found one is measured against', (
      tester,
    ) async {
      await open(
        tester,
        line: found,
        inventory: const Inventory(worn: [battered], carried: [found]),
      );

      expect(find.textContaining('Porównanie z'), findsOneWidget);
      expect(find.textContaining('na sobie'), findsOneWidget);
    });

    testWidgets('and the difference between them is how worn each is', (
      tester,
    ) async {
      await open(
        tester,
        line: found,
        inventory: const Inventory(worn: [battered], carried: [found]),
      );

      expect(find.text('Stan'), findsOneWidget);
      expect(markOn(tester, 'Stan'), Icons.add);
    });

    testWidgets(
      'the battered one, held against the good one, reads as a loss',
      (tester) async {
        await open(
          tester,
          line: battered,
          inventory: const Inventory(worn: [found], carried: [battered]),
        );

        expect(markOn(tester, 'Stan'), Icons.remove);
      },
    );

    testWidgets('a copy is never compared with itself', (tester) async {
      await open(
        tester,
        line: found,
        inventory: const Inventory(carried: [found]),
      );

      expect(find.textContaining('Porównanie z'), findsNothing);
    });

    testWidgets('and two worn copies compare against nothing either', (
      tester,
    ) async {
      // The one on the body is the baseline. Comparing it against itself, or
      // against the spare in the pack, reads backwards.
      await open(
        tester,
        line: found,
        inventory: const Inventory(worn: [found], carried: [battered]),
      );

      expect(find.textContaining('Porównanie z'), findsNothing);
    });
  });

  group('what is bolted on (§5.6.3)', () {
    testWidgets('the sheet hands back the piece it is showing, not the one it '
        'was opened with', (tester) async {
      // Found on a phone: fitting anything did nothing. Two reasons, and this
      // is the second — the sheet outlives the object it was opened with, so a
      // callback closing over that object bolts parts onto a piece the pack no
      // longer has. The weapon here is in the hand, which is `worn`.
      final pack = const Inventory()
          .withPack('pack_daypack')
          .wear('weapon_rifle_545')
          .add('att_red_dot', catalogue, body: body)
          .inventory;

      CarriedItem? reported;
      await open(
        tester,
        line: CarriedItem(itemId: 'weapon_rifle_545'),
        inventory: pack,
        onAttach: (line, _) => reported = line,
      );

      await tester.tap(
        find.text(
          L10n.of(tester.element(find.byType(TextButton).first)).attachmentFit,
        ),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(
        identical(
          reported,
          pack.worn.firstWhere((l) => l.itemId == 'weapon_rifle_545'),
        ),
        isTrue,
        reason: 'the live piece out of the pack, not the copy passed in',
      );
    });

    testWidgets('and offers the free rails it actually has', (tester) async {
      await open(
        tester,
        line: CarriedItem(itemId: 'weapon_rifle_545'),
        inventory: const Inventory()
            .withPack('pack_daypack')
            .wear('weapon_rifle_545')
            .add('att_red_dot', catalogue, body: body)
            .inventory,
        onAttach: (_, _) {},
      );

      // Three rails on a 5.45 carbine, none of them used yet.
      expect(find.textContaining('3'), findsWidgets);
    });
  });

  group('something on the ground is not something in the pack (§4.8)', () {
    testWidgets('it does not borrow the sights off the rifle in your hands', (
      tester,
    ) async {
      // Found on a phone: a rifle lying on the pavement showed the attachments
      // of the rifle the player was carrying, and taking one off the ground
      // copy took it off theirs. The sheet was matching by item id, and a
      // thing on the ground has no counterpart in the pack to match against.
      final mine = const Inventory()
          .withPack('pack_daypack')
          .wear('weapon_rifle_545')
          .add('att_red_dot', catalogue, body: body)
          .inventory;

      final fitted = mine.attach(
        mine.worn.firstWhere((l) => l.itemId == 'weapon_rifle_545'),
        mine.carried.firstWhere((l) => l.itemId == 'att_red_dot'),
        catalogue,
      );

      await open(
        tester,
        line: const CarriedItem(itemId: 'weapon_rifle_545'),
        inventory: fitted,
        fromPack: false,
      );

      // The magazine well is on every magazine-fed weapon whether or not
      // anything is in it — a rifle with no magazine is the most important
      // thing this sheet can say. What must be absent is the *player's* optic.
      expect(
        find.text(names.lookup('item.att_red_dot.name', language: 'pl')!),
        findsNothing,
        reason: 'the one on the ground is bare, whatever the player is holding',
      );
    });

    testWidgets('and the one in the pack still does', (tester) async {
      final mine = const Inventory()
          .withPack('pack_daypack')
          .wear('weapon_rifle_545')
          .add('att_red_dot', catalogue, body: body)
          .inventory;

      final fitted = mine.attach(
        mine.worn.firstWhere((l) => l.itemId == 'weapon_rifle_545'),
        mine.carried.firstWhere((l) => l.itemId == 'att_red_dot'),
        catalogue,
      );

      await open(
        tester,
        line: fitted.worn.firstWhere((l) => l.itemId == 'weapon_rifle_545'),
        inventory: fitted,
      );

      expect(
        find.text(
          L10n.of(
            tester.element(find.byType(TextButton).first),
          ).attachmentsNone,
        ),
        findsNothing,
        reason: 'their own rifle is wearing it',
      );
    });
  });

  group('§18.6: co z tego zostanie', () {
    testWidgets('rzecz warta rozebrania mówi, co odda i ile to zajmie', (
      tester,
    ) async {
      // ⚠️ Zgłoszone jako „skąd mam wiedzieć, czy opłaca się to rozbierać".
      // Ekran rozbiórki znał odpowiedź, ale dopiero po wejściu w niego z
      // konkretnym przedmiotem — czyli po decyzji, której miała dotyczyć.
      await open(
        tester,
        itemId: 'melee_crowbar',
        inventory: const Inventory(),
        bench: plain,
      );

      expect(find.text('PO ROZEBRANIU'), findsOneWidget);
      expect(find.textContaining('min'), findsWidgets);
      expect(find.textContaining('Złom metalowy'), findsWidgets);
    });

    testWidgets('a kanapka nie mówi nic, bo nikt jej nie rozbiera', (
      tester,
    ) async {
      // Wiersz „nic by z tego nie zostało" pod każdą konserwą to szum, a szum
      // jest tym, przez co gracz przestaje czytać wiersze, które coś znaczą.
      await open(
        tester,
        itemId: 'food_canned_meat',
        inventory: const Inventory(),
        bench: plain,
      );

      expect(find.text('PO ROZEBRANIU'), findsNothing);
    });

    testWidgets('bez warsztatu w zasięgu arkusz o tym milczy', (tester) async {
      // Stos na chodniku ogląda się, nie wycenia.
      await open(tester, itemId: 'melee_crowbar', inventory: const Inventory());

      expect(find.text('PO ROZEBRANIU'), findsNothing);
    });
  });

  group('§12: co to w ogóle jest', () {
    testWidgets('arkusz mówi jednym zdaniem, do czego rzecz służy', (
      tester,
    ) async {
      // Tabela odpowiada „czy ta jest lepsza". Zdanie odpowiada „co to jest",
      // a to jest pytanie, które ktoś ma raz — przy pierwszym podniesieniu.
      await open(
        tester,
        itemId: 'tool_lockpicks',
        inventory: const Inventory(),
      );

      expect(find.textContaining('kłódkę'), findsOneWidget);
    });

    testWidgets('i jest po polsku, kiedy gra jest po polsku', (tester) async {
      await open(tester, itemId: 'melee_spear', inventory: const Inventory());

      expect(find.textContaining('Sięga dalej'), findsOneWidget);
    });
  });
}
