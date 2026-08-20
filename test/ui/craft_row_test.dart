import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/ui/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ROZBIÓRKA W WIERSZU (§18.6, §2.1a.3).
///
/// The bar belongs under the row somebody tapped, and while it runs that row
/// is the one thing on the screen that can do nothing else. Both halves are
/// the same rule: a piece on the bench is a piece already spent.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  final now = DateTime.now().toUtc();

  Future<void> open(
    WidgetTester tester, {
    required Inventory pack,
    CraftJob? job,
    CarriedItem? busy,
    void Function(CarriedItem)? onStash,
    VoidCallback? onStop,
    String? Function(CarriedItem, PackAction)? refusalOf,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('pl'),
        home: InventoryScreen(
          inventory: ValueNotifier(pack),
          order: ValueNotifier(PackOrder.name),
          catalogue: catalogue,
          names: names,
          body: body,
          craftJob: ValueNotifier(job),
          craftLine: ValueNotifier(busy),
          onDismantle: (_) {},
          canDismantle: (_) => true,
          onStash: onStash,
          onStopDismantle: onStop,
          refusalOf: refusalOf,
          onDrop: (_, _) {},
        ),
      ),
    );
    await tester.pump();

    // ⚠️ Scrolled to. The pack list sits under the worn figure and the two
    // carry bars, which is off the bottom of a test surface — a ListView
    // builds what it can see, so a row nobody scrolled to is a row that does
    // not exist to a finder.
    for (var i = 0; i < 14; i++) {
      if (find.textContaining('Karabinek 5,45').evaluate().isNotEmpty) break;
      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pump();
    }
  }

  testWidgets('nothing is drawn under a row with no job on it', (tester) async {
    final pack = Inventory(
      carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
    );

    await open(tester, pack: pack);

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('the bar sits under the piece being taken apart', (tester) async {
    final pack = Inventory(
      carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
    );

    await open(
      tester,
      pack: pack,
      busy: pack.carried.single,
      job: CraftJob(
        salvageItemId: 'weapon_rifle_545',
        salvageCondition: 100,
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 6)),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('and under that one only, with two the same', (tester) async {
    // ⚠️ The piece, not the item id. Two rifles in one pack are two rifles,
    // and §4.7's half-eaten tin taught this screen the same lesson once
    // already: matching by id drew the bar under both rows.
    // ⚠️ copyWith, not two consts. Dart hands out one instance for identical
    // const objects, so a const pair would be the same rifle twice and prove
    // nothing. Rows read from the database are distinct objects, which is what
    // this imitates.
    final pack = Inventory(
      carried: [
        const CarriedItem(itemId: 'weapon_rifle_545').copyWith(count: 1),
        const CarriedItem(itemId: 'weapon_rifle_545').copyWith(count: 1),
      ],
    );

    await open(
      tester,
      pack: pack,
      busy: pack.carried.last,
      job: CraftJob(
        salvageItemId: 'weapon_rifle_545',
        salvageCondition: 100,
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 6)),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('a piece on the bench offers nothing else', (tester) async {
    // The other half of the same rule. A row that could still be dropped or
    // shelved while it is being taken apart is a thing the player can spend
    // twice.
    final pack = Inventory(
      carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
    );

    await open(tester, pack: pack, onStash: (_) {});
    final free = find.byType(IconButton).evaluate().length;

    await open(
      tester,
      pack: pack,
      onStash: (_) {},
      busy: pack.carried.single,
      job: CraftJob(
        salvageItemId: 'weapon_rifle_545',
        salvageCondition: 100,
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 6)),
      ),
    );
    final busy = find.byType(IconButton).evaluate().length;

    expect(busy, lessThan(free));
  });

  testWidgets('the shelf glyph is absent away from the shelves', (
    tester,
  ) async {
    // An absent control beats a dead one: the shelves are either within reach
    // or they are somewhere else entirely, and there is nothing to explain.
    final pack = Inventory(
      carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
    );

    await open(tester, pack: pack, onStash: (_) {});
    final near = find.byType(IconButton).evaluate().length;

    await open(tester, pack: pack);
    final away = find.byType(IconButton).evaluate().length;

    expect(away, near - 1);
  });

  testWidgets('a piece already opened offers only finishing it', (
    tester,
  ) async {
    // §18.6: half a rifle is not a rifle. Everything else that could be done
    // with it is gone; going back to the multitool is the one thing left.
    final whole = Inventory(
      carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
    );
    await open(tester, pack: whole, onStash: (_) {});
    final before = find.byType(IconButton).evaluate().length;

    final opened = Inventory(
      carried: [
        const CarriedItem(
          itemId: 'weapon_rifle_545',
        ).copyWith(salvageSeconds: 90),
      ],
    );
    await open(tester, pack: opened, onStash: (_) {});
    final after = find.byType(IconButton).evaluate().length;

    expect(after, lessThan(before));
    expect(find.textContaining('częściowo rozebrany'), findsOneWidget);
  });

  testWidgets('and the running bar offers a way to stop', (tester) async {
    final pack = Inventory(
      carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
    );

    var stopped = false;
    await open(
      tester,
      pack: pack,
      busy: pack.carried.single,
      onStop: () => stopped = true,
      job: CraftJob(
        salvageItemId: 'weapon_rifle_545',
        salvageCondition: 100,
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 6)),
      ),
    );

    await tester.tap(find.byIcon(Icons.stop_circle_outlined));
    expect(stopped, isTrue);
  });

  group('an action that cannot happen yet (§12)', () {
    testWidgets('greys rather than vanishes, and says why when pressed', (
      tester,
    ) async {
      // ⚠️ The second kind of "no". "The shelves are full" is something the
      // player can go and answer; hiding the glyph would leave them hunting
      // for a control that was there a minute ago.
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
      );

      await open(
        tester,
        pack: pack,
        onStash: (_) {},
        refusalOf: (_, action) =>
            action == PackAction.stash ? 'Na półkach nie ma miejsca.' : null,
      );

      // Still there, and still pressable.
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.textContaining('nie ma miejsca'), findsNothing);

      await tester.tap(find.byIcon(Icons.inventory_2));
      await tester.pump();

      expect(find.textContaining('nie ma miejsca'), findsOneWidget);
    });

    testWidgets('and a refused tap does not do the thing', (tester) async {
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
      );

      var shelved = false;
      await open(
        tester,
        pack: pack,
        onStash: (_) => shelved = true,
        refusalOf: (_, action) =>
            action == PackAction.stash ? 'Na półkach nie ma miejsca.' : null,
      );

      await tester.tap(find.byIcon(Icons.inventory_2));
      await tester.pump();

      expect(shelved, isFalse);
    });

    testWidgets('an action with nothing against it stays live', (tester) async {
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'weapon_rifle_545')],
      );

      var shelved = false;
      await open(tester, pack: pack, onStash: (_) => shelved = true);

      await tester.tap(find.byIcon(Icons.inventory_2));
      await tester.pump();

      expect(shelved, isTrue);
      expect(find.byIcon(Icons.block), findsNothing);
    });
  });
}
