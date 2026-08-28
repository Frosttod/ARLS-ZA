import 'dart:io';

import 'package:arls_za/inventory/body_slots.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/ui/inventory_screen.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// EKWIPUNEK (§3.6, §18.1a). The screen exists to answer "what am I carrying
/// and what is it costing me", so what is tested is that both costs are on it
/// — per item, not only as a total.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  Future<void> pump(
    WidgetTester tester,
    Inventory inventory, {
    void Function(CarriedItem, int)? onDrop,
    void Function(CarriedItem)? onTakeOff,
    void Function(CarriedItem)? onWear,
    void Function(CarriedItem)? onUse,
    void Function(CarriedItem)? onDetails,
    void Function(CarriedItem)? onRead,
    ValueListenable<Search?>? action,
    ValueListenable<CarriedItem?>? usingLine,
  }) async {
    // A phone, rather than the 800×600 the test binding defaults to: the worn
    // figure is eleven rows and the pack starts below anything shorter, which
    // makes every test about the pack a test about scrolling.
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
        home: InventoryScreen(
          inventory: ValueNotifier(inventory),
          // Heaviest first, which is the order these tests were written
          // against — the screen's default is now by kind.
          order: ValueNotifier(PackOrder.mass),
          catalogue: catalogue,
          names: names,
          body: body,
          onDrop: onDrop,
          onTakeOff: onTakeOff,
          onWear: onWear,
          onUse: onUse,
          onDetails: onDetails,
          onRead: onRead,
          action: action,
          usingLine: usingLine,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The worn figure is ten rows tall, so the pack sits below the fold on a
  /// test-sized screen. Nothing about the layout is wrong; the finger has to
  /// get there, and so does the test.
  /// A ListView builds lazily, so something below the fold does not exist for
  /// a finder until it has been scrolled to. Scroll first to build it, then
  /// align it, then touch it.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target.first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
    }
    // The first of them: several rows carry the same glyph, and aligning one
    // of them is all this is for.
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
  }

  Future<void> tapInPack(WidgetTester tester, Finder target) async {
    await reveal(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('an empty pack says so rather than showing an empty list', (
    tester,
  ) async {
    await pump(tester, const Inventory());

    expect(find.text('Plecak jest pusty.'), findsOneWidget);
    // §4.4's back slot, empty like the rest of the figure.
    expect(find.text('PLECY'), findsOneWidget);
  });

  testWidgets('both limits are at the top, in their own units', (tester) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('mat_wood', catalogue, body: body, count: 4)
        .inventory;

    await pump(tester, inventory);

    // 4 x 2.0 kg plus the 0.9 kg pack, against 44 kg of limit; 16 l of 45.
    expect(find.text('8.90 / 44.00 kg'), findsOneWidget);
    expect(find.text('16.00 / 45.00 l'), findsOneWidget);
  });

  testWidgets('every line carries its own mass and bulk', (tester) async {
    // A total alone says something has to go without saying what.
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('food_canned_meat', catalogue, body: body, count: 2)
        .inventory;

    await pump(tester, inventory);

    expect(find.text('Konserwa mięsna  ×2'), findsOneWidget);
    expect(find.text('0.80 kg  ·  0.80 l'), findsOneWidget);
  });

  testWidgets('worn kit is listed apart from packed kit (§18.1a)', (
    tester,
  ) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .wear('cloth_winter_jacket');

    await pump(tester, inventory);

    expect(find.text('NA SOBIE'), findsOneWidget);
    expect(find.text('Kurtka zimowa'), findsOneWidget);
    // Worn, so it is not in the pack and the bulk gauge stays at zero.
    expect(find.text('0.00 / 45.00 l'), findsOneWidget);
  });

  testWidgets('an overloaded pack says what it costs, not just in colour', (
    tester,
  ) async {
    // §12: colour never carries information on its own.
    //
    // Thirty-six pieces at 0.75 kg is 27 kg, over a comfortable 24 with no
    // pack (§18.1a). It took eighteen when a piece was 1.5 kg.
    final inventory = const Inventory()
        .add('mat_metal', catalogue, body: body, count: 36)
        .inventory;

    await pump(tester, inventory);

    expect(
      find.text(
        'Powyżej komfortowego obciążenia — każdy krok kosztuje więcej.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the heaviest thing is at the top, being the one to leave', (
    tester,
  ) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('med_bandage', catalogue, body: body)
        .inventory
        .add('mat_wood', catalogue, body: body)
        .inventory;

    await pump(tester, inventory);

    await reveal(tester, find.text('Bandaż'));

    final wood = tester.getTopLeft(find.text('Drewno'));
    final bandage = tester.getTopLeft(find.text('Bandaż'));
    expect(wood.dy, lessThan(bandage.dy));
  });

  testWidgets('a book shows how far through it the player is (§4.6.3)', (
    tester,
  ) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('lit_guide_survival', catalogue, body: body, pagesTotal: 160)
        .inventory;

    await pump(tester, inventory);

    expect(find.textContaining('0 / 160'), findsOneWidget);
  });

  group('a stack is thinned, not emptied (§18.1a)', () {
    // Found on a phone: the only button dropped the whole pile, so a player
    // who wanted to shed one kilogram of wood lost six.
    final threeLogs = const Inventory()
        .withPack('pack_daypack')
        .add('mat_wood', catalogue, body: body, count: 3)
        .inventory;

    testWidgets('the plain button drops one', (tester) async {
      var count = 0;
      String? itemId;

      await pump(
        tester,
        threeLogs,
        onDrop: (line, dropped) {
          itemId = line.itemId;
          count = dropped;
        },
      );
      await tapInPack(tester, find.byIcon(Icons.delete_outline));

      expect(itemId, 'mat_wood');
      expect(count, 1);
    });

    testWidgets('the stepper says how many, up to the whole stack', (
      tester,
    ) async {
      var count = 0;

      await pump(tester, threeLogs, onDrop: (_, dropped) => count = dropped);
      await tapInPack(tester, find.byIcon(Icons.add));
      await tapInPack(tester, find.byIcon(Icons.delete_outline));

      expect(count, 2);
    });

    testWidgets('and never past it', (tester) async {
      var count = 0;

      await pump(tester, threeLogs, onDrop: (_, dropped) => count = dropped);
      for (var i = 0; i < 6; i++) {
        await tapInPack(tester, find.byIcon(Icons.add));
      }
      await tapInPack(tester, find.byIcon(Icons.delete_outline));

      expect(count, 3);
    });

    testWidgets('a single item is not asked how many', (tester) async {
      // A stepper beside one bandage is a control with one setting.
      final one = const Inventory()
          .withPack('pack_daypack')
          .add('mat_wood', catalogue, body: body)
          .inventory;

      await pump(tester, one, onDrop: (_, _) {});

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });
  });

  group('the worn figure (§4.4)', () {
    testWidgets('every slot is a row, filled or not', (tester) async {
      // The gap is the information: a list of only what exists cannot tell
      // somebody they have no gloves.
      await pump(tester, const Inventory());

      expect(find.text('GŁOWA'), findsOneWidget);
      expect(find.text('PANCERZ'), findsOneWidget);
      expect(find.text('STOPY'), findsOneWidget);
      expect(find.text('puste'), findsNWidgets(11));
    });

    test('every slot in the data has a place on the figure', () {
      // A garment whose slot the figure does not know would be worn and
      // invisible.
      for (final item in catalogue.all) {
        final slot = item.props['slot'] as String?;
        if (slot == null) continue;
        expect(BodySlot.fromWire(slot), isNotNull, reason: item.id);
      }
    });

    testWidgets('what is worn shows in its own slot', (tester) async {
      await pump(tester, const Inventory().wear('armor_vest_soft', catalogue));

      expect(find.text('Kamizelka kuloodporna'), findsOneWidget);
      expect(find.text('puste'), findsNWidgets(10));
    });
  });

  group('putting things on and using them', () {
    testWidgets('a vest in the pack can be put back on', (tester) async {
      // The bug this exists for: taking a vest off left no way to wear it
      // again, so the first mistake was permanent.
      CarriedItem? worn;
      final packed = const Inventory()
          .withPack('pack_daypack')
          .add('armor_vest_soft', catalogue, body: body)
          .inventory;

      await pump(tester, packed, onWear: (line) => worn = line);
      await tapInPack(tester, find.byIcon(Icons.checkroom));

      expect(worn?.itemId, 'armor_vest_soft');
    });

    testWidgets('food and water can be used, wood cannot', (tester) async {
      final mixed = const Inventory()
          .withPack('pack_daypack')
          .add('drink_water_bottle_500', catalogue, body: body)
          .inventory
          .add('mat_wood', catalogue, body: body)
          .inventory;

      await pump(tester, mixed, onUse: (_) {});
      await reveal(tester, find.text('Drewno'));

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });
  });

  group('worn kit comes off', () {
    final dressed = const Inventory()
        .withPack('pack_daypack')
        .wear('armor_vest_soft');

    testWidgets('there is a way to take it off at all (§4.4)', (tester) async {
      CarriedItem? taken;

      await pump(tester, dressed, onTakeOff: (line) => taken = line);
      // The vest's own button: the figure is dressed from the head down, so
      // the torso comes before the pack on the back.
      await tester.tap(find.text('Zdejmij').first);
      await tester.pump();

      expect(taken?.itemId, 'armor_vest_soft');
    });

    testWidgets('and it is the only thing offered for worn kit', (
      tester,
    ) async {
      // Taking a vest off and throwing it on the ground are different
      // decisions, and only one belongs a tap away on a screen read in the
      // dark.
      await pump(tester, dressed, onDrop: (_, _) {}, onTakeOff: (_) {});

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });

  testWidgets('the list follows the inventory, not the moment it opened', (
    tester,
  ) async {
    // ⚠️ The bug this exists for: the screen is a pushed route, its builder
    // runs once, and handed a plain value it kept showing what it opened with.
    // Dropping something looked like nothing had happened, so the same item
    // could be dropped over and over against a list already out of date.
    final inventory = ValueNotifier(
      const Inventory()
          .withPack('pack_daypack')
          .add('mat_wood', catalogue, body: body, count: 3)
          .inventory,
    );

    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
        home: InventoryScreen(
          inventory: inventory,
          order: ValueNotifier(PackOrder.mass),
          catalogue: catalogue,
          names: names,
          body: body,
          onDrop: (line, count) => inventory.value = inventory.value.remove(
            line.itemId,
            count: count,
          )!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await reveal(tester, find.text('Drewno  ×3'));
    expect(find.text('Drewno  ×3'), findsOneWidget);

    // Three taps of the plus, then drop: the whole stack, one deliberate
    // action rather than one careless one.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Drewno  ×3'), findsNothing);
    expect(
      find.byIcon(Icons.delete_outline),
      findsNothing,
      reason: 'nothing left to drop, so no button to press again',
    );
    expect(find.text('Plecak jest pusty.'), findsOneWidget);
  });

  group('a running use is drawn under the thing being used', () {
    // Found on a phone: the bar sat at the top of the screen, so drinking from
    // one of three bottles said something was happening without saying what.
    final pack = const Inventory()
        .withPack('pack_daypack')
        .add('drink_water_bottle_500', catalogue, body: body)
        .inventory
        .add('food_canned_meat', catalogue, body: body)
        .inventory;

    Search drinking() => Search.using(
      at: const GeoPoint(52.4, 16.9),
      now: DateTime.utc(2026, 8, 15, 12),
      itemId: 'drink_water_bottle_500',
      duration: const Duration(seconds: 20),
      label: 'Picie',
    );

    testWidgets('the bar is below the item it belongs to', (tester) async {
      await pump(tester, pack, action: ValueNotifier<Search?>(drinking()));

      await reveal(tester, find.text('Picie'));

      final bottle = tester.getBottomLeft(find.text('Woda 0,5 l'));
      final bar = tester.getTopLeft(find.text('Picie'));
      expect(bar.dy, greaterThan(bottle.dy));
    });

    testWidgets('and not under anything else in the pack', (tester) async {
      await pump(tester, pack, action: ValueNotifier<Search?>(drinking()));

      await reveal(tester, find.text('Picie'));
      final tin = tester.getTopLeft(find.text('Konserwa mięsna'));
      final bar = tester.getTopLeft(find.text('Picie'));

      // One bar, and it is not the tin's.
      expect(find.text('Picie'), findsOneWidget);
      expect(bar.dy, isNot(closeTo(tin.dy, 40)));
    });

    testWidgets('nothing running, nothing drawn', (tester) async {
      await pump(tester, pack, action: ValueNotifier<Search?>(null));

      expect(find.text('Picie'), findsNothing);
    });
  });

  group('the numbers behind an item', () {
    testWidgets('a line can be asked what it actually is', (tester) async {
      String? asked;
      final pack = const Inventory()
          .withPack('pack_daypack')
          .add('armor_vest_soft', catalogue, body: body)
          .inventory;

      await pump(tester, pack, onDetails: (line) => asked = line.itemId);

      // ⚠️ `.last`, because the figure above the list now carries the same
      // glyph on every filled slot — including the pack itself, which is worn.
      // That is the point of this change, and it is why the pack's own row is
      // no longer the only one on screen with a way in.
      await tapInPack(tester, find.byIcon(Icons.info_outline).last);

      expect(asked, 'armor_vest_soft');
    });

    testWidgets('a book part-read says which page, one finished says so', (
      tester,
    ) async {
      // §4.6.1: "160 / 160" is a sum the player has to do to learn the one
      // thing they wanted to know, on a shelf of books that all end in a
      // number.
      final half = const Inventory()
          .withPack('pack_daypack')
          .add(
            'lit_guide_survival',
            catalogue,
            body: body,
            pagesTotal: 160,
            pagesRead: 40,
          )
          .inventory;

      await pump(tester, half);

      expect(find.textContaining('40 / 160'), findsOneWidget);
      expect(find.textContaining('ukończona'), findsNothing);
    });

    testWidgets('and a finished one is not offered for reading (§12)', (
      tester,
    ) async {
      final done = const Inventory()
          .withPack('pack_daypack')
          .add(
            'lit_guide_survival',
            catalogue,
            body: body,
            pagesTotal: 160,
            pagesRead: 160,
          )
          .inventory;

      await pump(tester, done, onRead: (_) {});

      expect(find.textContaining('ukończona'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsNothing);
    });

    testWidgets('and the glyph is on the worn row, not only the tap', (
      tester,
    ) async {
      // ⚠️ Reported as "how do I see what my vest is doing". The name on a
      // slot row has opened the numbers for a long time, and nothing said so:
      // the pack row had the glyph and the figure did not, so the pieces
      // somebody is actually wearing were the ones they had to guess about.
      String? asked;

      await pump(
        tester,
        const Inventory().wear('armor_vest_soft'),
        onDetails: (line) => asked = line.itemId,
      );

      await tapInPack(tester, find.byIcon(Icons.info_outline).first);

      expect(asked, 'armor_vest_soft');
    });

    testWidgets('an empty slot offers nothing to look at', (tester) async {
      // An absent control, never a dead one: there is no vest to explain.
      await pump(tester, const Inventory(), onDetails: (_) {});

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('so can something being worn, which is the one to beat', (
      tester,
    ) async {
      String? asked;

      await pump(
        tester,
        const Inventory().wear('armor_vest_soft'),
        onDetails: (line) => asked = line.itemId,
      );
      await tester.tap(find.text('Kamizelka kuloodporna'));
      await tester.pumpAndSettle();

      expect(asked, 'armor_vest_soft');
    });
  });

  group('two of a kind in one pack (§4.4)', () {
    // Found on a phone, twice over: a second vest crashed the screen outright
    // with 'child == null || indexOf(child) > index', because both rows were
    // keyed by item id and a list cannot hold two children under one key.
    final duplicates = const Inventory(
      packId: 'pack_daypack',
      carried: [
        CarriedItem(itemId: 'armor_vest_soft', condition: 90),
        CarriedItem(itemId: 'armor_vest_soft', condition: 40),
        CarriedItem(itemId: 'melee_knife', condition: 80),
        CarriedItem(itemId: 'melee_knife', condition: 30),
      ],
    );

    testWidgets('both copies are on the screen at once', (tester) async {
      await pump(tester, duplicates);

      await reveal(tester, find.text('Kamizelka kuloodporna'));
      expect(find.text('Kamizelka kuloodporna'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('and each says how worn it is', (tester) async {
      await pump(tester, duplicates);

      await reveal(tester, find.textContaining('90%'));
      expect(find.textContaining('90%'), findsOneWidget);
      expect(find.textContaining('40%'), findsOneWidget);
    });

    testWidgets('dropping one leaves the other standing', (tester) async {
      final inventory = ValueNotifier(duplicates);

      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

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
          home: InventoryScreen(
            inventory: inventory,
            order: ValueNotifier(PackOrder.mass),
            catalogue: catalogue,
            names: names,
            body: body,
            onDrop: (line, count) => inventory.value = inventory.value
                .removeLine(line, count: count)!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapInPack(tester, find.byIcon(Icons.delete_outline).first);

      expect(tester.takeException(), isNull);
      expect(inventory.value.carried, hasLength(3));
    });

    testWidgets('the copy that was tapped is the copy that goes', (
      tester,
    ) async {
      // Dropping "the vest" when there are two is how a player loses the good
      // one by pointing at the ruined one.
      CarriedItem? dropped;
      await pump(tester, duplicates, onDrop: (line, _) => dropped = line);

      await reveal(tester, find.textContaining('40%'));

      // The drop glyph inside that row's own frame, which is what a finger
      // aiming at the battered vest actually hits.
      final row = find
          .ancestor(
            of: find.textContaining('40%'),
            matching: find.byType(Container),
          )
          .first;

      await tester.tap(
        find.descendant(of: row, matching: find.byIcon(Icons.delete_outline)),
      );
      await tester.pumpAndSettle();

      expect(dropped?.condition, 40);
    });
  });

  testWidgets('the pack comes off like anything else worn', (tester) async {
    // Found on a phone: every slot on the figure had a way out except the one
    // holding everything.
    CarriedItem? removed;

    await pump(
      tester,
      const Inventory().withPack('pack_daypack'),
      onTakeOff: (line) => removed = line,
    );
    await tester.tap(find.text('Zdejmij'));
    await tester.pumpAndSettle();

    expect(removed?.itemId, 'pack_daypack');
  });

  group('one tin out of four (§4.7)', () {
    // Found on a phone: opening one tin from a stack of four leaves a
    // part-eaten tin beside three whole ones — two rows, one item id — and the
    // bar was drawn under both of them.
    const partly = CarriedItem(itemId: 'food_canned_meat', portion: 0.67);
    const whole = CarriedItem(itemId: 'food_canned_meat', count: 3);

    final pack = const Inventory(
      packId: 'pack_daypack',
      carried: [whole, partly],
    );

    Search eating() => Search.using(
      at: const GeoPoint(52.4, 16.9),
      now: DateTime.utc(2026, 8, 15, 12),
      itemId: 'food_canned_meat',
      duration: const Duration(seconds: 60),
      label: 'jedzenie',
    );

    testWidgets('one bar, under the piece actually being eaten', (
      tester,
    ) async {
      await pump(
        tester,
        pack,
        action: ValueNotifier<Search?>(eating()),
        usingLine: ValueNotifier<CarriedItem?>(pack.carried[1]),
      );

      await reveal(tester, find.text('jedzenie'));
      expect(find.text('jedzenie'), findsOneWidget);

      final bar = tester.getTopLeft(find.text('jedzenie')).dy;
      final part = tester.getTopLeft(find.textContaining('zostało 67%')).dy;
      expect(bar, greaterThan(part));
    });

    testWidgets('and the whole ones carry no bar at all', (tester) async {
      await pump(
        tester,
        pack,
        action: ValueNotifier<Search?>(eating()),
        usingLine: ValueNotifier<CarriedItem?>(pack.carried[1]),
      );

      await reveal(tester, find.text('jedzenie'));
      final stack = tester.getTopLeft(find.text('Konserwa mięsna  ×3')).dy;
      final bar = tester.getTopLeft(find.text('jedzenie')).dy;

      // The stack is above the part-eaten tin, so its own bar would be above
      // this one — there is only one, and it is below both rows' titles.
      expect(bar, greaterThan(stack));
      expect(find.text('jedzenie'), findsOneWidget);
    });

    testWidgets('eating from the stack puts the bar on the stack', (
      tester,
    ) async {
      await pump(
        tester,
        pack,
        action: ValueNotifier<Search?>(eating()),
        usingLine: ValueNotifier<CarriedItem?>(pack.carried[0]),
      );

      await reveal(tester, find.text('jedzenie'));
      final bar = tester.getTopLeft(find.text('jedzenie')).dy;
      final part = tester.getTopLeft(find.textContaining('zostało 67%')).dy;

      expect(find.text('jedzenie'), findsOneWidget);
      expect(bar, lessThan(part));
    });

    testWidgets('nothing in hand, nothing drawn', (tester) async {
      await pump(
        tester,
        pack,
        action: ValueNotifier<Search?>(eating()),
        usingLine: ValueNotifier<CarriedItem?>(null),
      );

      expect(find.text('jedzenie'), findsNothing);
    });
  });
}
