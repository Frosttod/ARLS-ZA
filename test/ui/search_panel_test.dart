import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/obstacle.dart';
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
            search: null,
            targetName: 'Apteka',
            canSearchHere: canSearchHere,
            searchUnitsLeft: left,
            barrier: barrier,
            carried: carried,
            onBreach: (_) {},
            onSearchArea: () {},
            onSearchHere: (_) {},
            onCancel: () {},
            droppedLabel: droppedLabel,
            onTakeDropped: onTakeDropped,
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

      expect(
        find.bySemanticsLabel(RegExp('Pobieżnie.*30 s')),
        findsOneWidget,
      );
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
      expect(find.textContaining('60 s'), findsOneWidget);
      expect(find.textContaining('150 m'), findsOneWidget);
    });

    testWidgets('a crowbar is a third way, faster and loud', (tester) async {
      await pump(tester, barrier: Barrier.door, carried: {'melee_crowbar'});

      expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key_outlined), findsNothing);
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
      expect(find.byIcon(Icons.backpack_outlined), findsNothing);
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

    testWidgets('and a barrier out of reach concerns nobody', (
      tester,
    ) async {
      await pump(tester, canSearchHere: false, barrier: Barrier.padlock);

      expect(find.byIcon(Icons.vpn_key_outlined), findsNothing);
      expect(find.text('Brak narzędzia — kłódki nie otworzysz gołymi rękami.'),
          findsNothing);
    });
  });

  group('what is lying here (§4.8)', () {
    testWidgets('picking it up is a glyph and nothing else', (tester) async {
      // What is down there belongs to the list this opens. Spelling it out on
      // the panel as well cost a line of the map for something the player is
      // about to be shown properly.
      await pump(tester, droppedLabel: 'Nóż  +2', onTakeDropped: () {});

      expect(find.byIcon(Icons.backpack_outlined), findsOneWidget);
      expect(find.textContaining('Nóż'), findsNothing);
    });

    testWidgets('but a long press and a screen reader still name it', (
      tester,
    ) async {
      await pump(tester, droppedLabel: 'Nóż  +2', onTakeDropped: () {});

      final tooltip = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.backpack_outlined),
          matching: find.byType(IconButton),
        ),
      );

      expect(tooltip.tooltip, contains('Nóż'));
    });

    testWidgets('and it does what it says', (tester) async {
      var taken = 0;
      await pump(
        tester,
        droppedLabel: 'Nóż',
        onTakeDropped: () => taken++,
      );
      await tester.tap(find.byIcon(Icons.backpack_outlined));
      await tester.pumpAndSettle();

      expect(taken, 1);
    });

    testWidgets('an empty street offers nothing to pick up', (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.backpack_outlined), findsNothing);
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
}
