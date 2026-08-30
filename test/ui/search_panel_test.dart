import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/obstacle.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/search_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// PANEL PRZESZUKANIA (§10.3.5, §19.3).
///
/// Every action here is a glyph with its cost under it. The glyph says what
/// kind of thing it is; the caption says what it takes, because both choices
/// on this panel are between time and attention — thirty seconds or a hundred
/// and eighty, twenty metres of noise or a hundred and fifty — and an icon
/// cannot carry that.
///
/// What changes as a place is worked over is which depths it still has room
/// for. Those are shown and refused rather than removed, so a player who
/// searched a shop thoroughly twice can see why the third pass is gone.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    int left = kSearchBudget,
    bool canSearchHere = true,
    Barrier? barrier,
    Set<String> carried = const {},
    String? droppedLabel,
    VoidCallback? onTakeDropped,
    Search? search,
    String? weapon,
    int? rounds,
    int? capacity,
  }) async {
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
        home: Scaffold(
          body: SearchPanel(
            search: search,
            targetName: 'Apteka',
            canSearchHere: canSearchHere,
            searchUnitsLeft: left,
            barrier: barrier,
            carried: carried,
            toolName: (id) => switch (id) {
              'tool_lockpicks' => 'Wytrychy',
              'melee_crowbar' => 'Łom',
              'melee_axe' => 'Siekiera',
              _ => id,
            },
            onBreach: (_) {},
            onSearchArea: () {},
            onSearchHere: (_) {},
            onCancel: () {},
            droppedLabel: droppedLabel,
            onTakeDropped: onTakeDropped,
            weapon: weapon,
            rounds: rounds,
            capacity: capacity,
            onReload: weapon == null ? null : () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Whether the control behind an icon can be pressed at all.
  bool enabled(WidgetTester tester, IconData icon) {
    final inkWell = find.ancestor(
      of: find.byIcon(icon),
      matching: find.byType(InkWell),
    );
    return tester.widget<InkWell>(inkWell.first).onTap != null;
  }

  group('searching a place (§10.3.5)', () {
    testWidgets('an untouched place offers all three depths', (tester) async {
      await pump(tester);

      expect(enabled(tester, Icons.search), isTrue);
      expect(enabled(tester, Icons.manage_search), isTrue);
      expect(enabled(tester, Icons.pageview_outlined), isTrue);
    });

    testWidgets('each one says what it costs, since the glyph cannot', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('30 s'), findsOneWidget);
      expect(find.text('90 s'), findsOneWidget);
      expect(find.text('180 s'), findsOneWidget);
    });

    testWidgets('one quick look later, the deep pass is gone', (tester) async {
      await pump(tester, left: kSearchBudget - SearchDepth.shallow.cost);

      expect(enabled(tester, Icons.search), isTrue);
      expect(enabled(tester, Icons.manage_search), isTrue);
      expect(enabled(tester, Icons.pageview_outlined), isFalse);
    });

    testWidgets('two quick looks later, only a third quick one is left', (
      tester,
    ) async {
      await pump(tester, left: kSearchBudget - 2 * SearchDepth.shallow.cost);

      expect(enabled(tester, Icons.search), isTrue);
      expect(enabled(tester, Icons.manage_search), isFalse);
    });

    testWidgets('a stripped place still shows what it no longer offers', (
      tester,
    ) async {
      // A panel that quietly loses controls teaches nothing about why.
      await pump(tester, left: 0);

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(enabled(tester, Icons.search), isFalse);
    });

    testWidgets('a screen reader hears the name and the cost (§12)', (
      tester,
    ) async {
      // The glyph is not information on its own, which §12 forbids.
      await pump(tester);

      expect(find.bySemanticsLabel(RegExp('Pobieżnie.*30 s')), findsOneWidget);
    });

    testWidgets('reconnaissance is its own glass, apart from the three', (
      tester,
    ) async {
      // §10.2.1: it has no cooldown, only a cost, and it looks at the area
      // rather than at this place.
      await pump(tester);

      expect(find.byIcon(Icons.travel_explore), findsOneWidget);
    });
  });

  group('a shut place (§19.3)', () {
    testWidgets('the ways through are glyphs with their noise on them', (
      tester,
    ) async {
      await pump(tester, barrier: Barrier.door, carried: {'tool_lockpicks'});

      expect(find.byIcon(Icons.vpn_key_outlined), findsOneWidget);
      expect(find.byIcon(Icons.front_hand_outlined), findsOneWidget);

      // ⚠️ Sekundy i metry na podpisie — bo to jest cała decyzja §19.3, i
      // żadna ikona nie uniesie jej sama. Wytrychy: minuta i dwadzieścia
      // metrów. Ramię: półtorej minuty i dwieście.
      expect(find.textContaining('60 s'), findsOneWidget);
      expect(find.textContaining('90 s'), findsOneWidget);
      expect(find.textContaining('200 m'), findsOneWidget);
    });

    testWidgets('a crowbar is a third way, faster and loud', (tester) async {
      await pump(tester, barrier: Barrier.door, carried: {'melee_crowbar'});

      expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key_outlined), findsNothing);
    });

    testWidgets('i każda droga mówi, czym się ją przechodzi', (tester) async {
      // ⚠️ **Zgłoszone z terenu: „to niewiele mówi".** Trzy glify z sekundami
      // pod spodem mówiły, że coś kosztuje dwanaście sekund, ale nie mówiły
      // czym się to robi ani czego brakuje.
      await pump(
        tester,
        barrier: Barrier.door,
        carried: {'tool_lockpicks', 'melee_crowbar'},
      );

      expect(find.text('Wytrychy'), findsOneWidget);
      expect(find.text('Łom'), findsOneWidget);
      expect(find.text('Gołe ręce'), findsOneWidget);
    });

    testWidgets('a siekiera nazywa się siekierą, nie łomem', (tester) async {
      // ⚠️ Drzwi podważa łom **albo** siekiera, i panel pokazujący jedno,
      // a zużywający drugie, byłby gorszy od milczącego: gracz zapamiętałby
      // cenę, której nie zapłacił. Ta sama kolejność co w `useTool`.
      await pump(tester, barrier: Barrier.door, carried: {'melee_axe'});

      expect(find.text('Siekiera'), findsOneWidget);
      expect(find.text('Łom'), findsNothing);
    });

    testWidgets('a nazwa stoi obok swojej ceny', (tester) async {
      await pump(tester, barrier: Barrier.door, carried: {'melee_crowbar'});

      final row = find.ancestor(
        of: find.text('Łom'),
        matching: find.byType(Row),
      );

      expect(
        find.descendant(of: row.first, matching: find.textContaining('12 s')),
        findsOneWidget,
      );
    });

    testWidgets('empty-handed, a door still gives way to shoulders', (
      tester,
    ) async {
      await pump(tester, barrier: Barrier.door);

      expect(find.byIcon(Icons.front_hand_outlined), findsOneWidget);
    });

    testWidgets('a padlock empty-handed says so rather than showing nothing', (
      tester,
    ) async {
      // §19.3 names the padlock as the barrier that needs a tool; softening
      // that would make every tool in the catalogue optional.
      await pump(tester, barrier: Barrier.padlock);

      expect(find.byIcon(Icons.front_hand_outlined), findsNothing);
      expect(
        find.text('Brak narzędzia — kłódki nie otworzysz gołymi rękami.'),
        findsOneWidget,
      );
    });

    testWidgets('and there is no searching a place not yet open', (
      tester,
    ) async {
      await pump(tester, barrier: Barrier.door);

      expect(find.byIcon(Icons.manage_search), findsNothing);
    });
  });

  group('only what is within reach (§10.2, §19.3)', () {
    testWidgets('an empty street offers reconnaissance and nothing else', (
      tester,
    ) async {
      // A panel of controls that cannot be used is a menu to read rather than
      // a list of what is possible.
      await pump(tester, canSearchHere: false);

      expect(find.byIcon(Icons.travel_explore), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byIcon(Icons.manage_search), findsNothing);
      expect(find.byIcon(Icons.back_hand_outlined), findsNothing);
    });

    testWidgets('a place in reach brings its depths with it', (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('a shut place offers ways in instead of depths', (
      tester,
    ) async {
      // There is nothing to search until there is a way in.
      await pump(tester, barrier: Barrier.door);

      expect(find.byIcon(Icons.front_hand_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('and a barrier out of reach concerns nobody', (tester) async {
      await pump(tester, canSearchHere: false, barrier: Barrier.padlock);

      expect(find.byIcon(Icons.vpn_key_outlined), findsNothing);
      expect(
        find.text('Brak narzędzia — kłódki nie otworzysz gołymi rękami.'),
        findsNothing,
      );
    });
  });

  group('what is lying here (§4.8)', () {
    testWidgets('nothing underfoot, no hand on the panel', (tester) async {
      // Found on a walk: the glyph stayed from anywhere, so "can I reach that
      // from here" was answered by pressing it and finding out.
      await pump(tester, droppedLabel: 'Nóż', onTakeDropped: null);

      expect(find.byIcon(Icons.back_hand_outlined), findsNothing);
    });

    testWidgets('picking it up is a glyph and nothing else', (tester) async {
      // What is down there belongs to the list this opens. Spelling it out on
      // the panel as well cost a line of the map for something the player is
      // about to be shown properly.
      await pump(tester, droppedLabel: 'Nóż  +2', onTakeDropped: () {});

      expect(find.byIcon(Icons.back_hand_outlined), findsOneWidget);
      expect(find.textContaining('Nóż'), findsNothing);
    });

    testWidgets('but a long press and a screen reader still name it', (
      tester,
    ) async {
      await pump(tester, droppedLabel: 'Nóż  +2', onTakeDropped: () {});

      final tooltip = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.back_hand_outlined),
          matching: find.byType(IconButton),
        ),
      );

      expect(tooltip.tooltip, contains('Nóż'));
    });

    testWidgets('and it does what it says', (tester) async {
      var taken = 0;
      await pump(tester, droppedLabel: 'Nóż', onTakeDropped: () => taken++);
      await tester.tap(find.byIcon(Icons.back_hand_outlined));
      await tester.pumpAndSettle();

      expect(taken, 1);
    });

    testWidgets('an empty street offers nothing to pick up', (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.back_hand_outlined), findsNothing);
    });
  });

  testWidgets('everything fits across a phone', (tester) async {
    // Found at 800 px and true of every phone in the shop: the row overflowed
    // by 163 px, which on a device is a button nobody can press.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await pump(tester);

    expect(tester.takeException(), isNull);
  });

  group('while something is already running (§10.2)', () {
    testWidgets('nothing here can be started twice', (tester) async {
      // The glyphs stay where they are and go grey rather than vanishing: a
      // panel that reshuffles under a thumb halfway to a button is worse than
      // a button that refuses.
      await tester.pumpWidget(const SizedBox());
      await pump(
        tester,
        search: Search.area(
          at: const GeoPoint(52.4, 16.9),
          now: DateTime.utc(2026, 8, 16, 12),
        ),
      );

      final buttons = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(buttons, isNotEmpty);
      expect(buttons.every((button) => button.onTap == null), isTrue);
    });

    testWidgets('and the bar for it is not down here (§4.6)', (tester) async {
      // It lives under the stats bar instead. Found on a phone: a tin of stew
      // eaten with a Walker in the sights put the bar under the combat panel.
      await pump(
        tester,
        search: Search.area(
          at: const GeoPoint(52.4, 16.9),
          now: DateTime.utc(2026, 8, 16, 12),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('the bar that moved to the top (§4.6, §10.2)', () {
    testWidgets('says what is running, how long, and how to stop', (
      tester,
    ) async {
      var cancelled = false;
      final search = Search.area(
        at: const GeoPoint(52.4, 16.9),
        now: DateTime.utc(2026, 8, 16, 12),
      );

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
          home: Scaffold(
            body: ActionProgress(
              search: search,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('s'), findsWidgets);

      await tester.tap(find.byType(TextButton));
      expect(cancelled, isTrue);
    });
  });
  group('the weapon in hand (§5.3, §4.2)', () {
    // ⚠️ The weapon used to appear only beside a target, so there was nowhere
    // to see what was in it and nowhere to reload — and §4.2's whole point is
    // that a magazine is filled and swapped *before* anything is in front of
    // you. A panel that only exists during a fight arrives too late.
    testWidgets('says what is in it, with nothing in front of you', (
      tester,
    ) async {
      await pump(tester, weapon: 'Karabinek 5,45 mm', rounds: 12, capacity: 30);

      expect(find.text('Karabinek 5,45 mm'), findsOneWidget);
      expect(find.text('12 / 30'), findsOneWidget);
    });

    testWidgets('and says "no magazine" rather than "nought"', (tester) async {
      // Two different sentences, and the first is the one that tells a player
      // what to go and find.
      await pump(tester, weapon: 'Karabinek 5,45 mm', rounds: 0);

      expect(find.text('0 / 30'), findsNothing);
      expect(find.textContaining('magazynka'), findsOneWidget);
    });

    testWidgets('with empty hands it says nothing at all', (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.gps_fixed), findsNothing);
    });
  });
}
