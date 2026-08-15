import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/search_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// PANEL PRZESZUKANIA (§10.3.5).
///
/// The three depths are all on screen at once because hiding the slow ones
/// would hide the decision. What changes as a place is worked over is which of
/// them the place still has room for — shown and refused rather than removed,
/// so a player who searched a shop thoroughly twice can see why the third pass
/// is gone.
void main() {
  Future<void> pump(WidgetTester tester, {required int left}) async {
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
            canSearchHere: true,
            searchUnitsLeft: left,
            onSearchArea: () {},
            onSearchHere: (_) {},
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String label) =>
      tester.widget<TextButton>(
        find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
      ).enabled;

  testWidgets('an untouched place offers all three depths', (tester) async {
    await pump(tester, left: kSearchBudget);

    expect(enabled(tester, 'Pobieżnie · 30 s'), isTrue);
    expect(enabled(tester, 'Dokładnie · 90 s'), isTrue);
    expect(enabled(tester, 'Gruntownie · 180 s'), isTrue);
  });

  testWidgets('one quick look later, the deep pass is gone', (tester) async {
    await pump(tester, left: kSearchBudget - SearchDepth.shallow.cost);

    expect(enabled(tester, 'Pobieżnie · 30 s'), isTrue);
    expect(enabled(tester, 'Dokładnie · 90 s'), isTrue);
    expect(enabled(tester, 'Gruntownie · 180 s'), isFalse);
  });

  testWidgets('two quick looks later, only a third quick one is left', (
    tester,
  ) async {
    await pump(tester, left: kSearchBudget - 2 * SearchDepth.shallow.cost);

    expect(enabled(tester, 'Pobieżnie · 30 s'), isTrue);
    expect(enabled(tester, 'Dokładnie · 90 s'), isFalse);
  });

  testWidgets('a stripped place still shows what it no longer offers', (
    tester,
  ) async {
    // The buttons stay on screen: a panel that quietly loses controls teaches
    // nothing about why.
    await pump(tester, left: 0);

    expect(find.text('Pobieżnie · 30 s'), findsOneWidget);
    expect(enabled(tester, 'Pobieżnie · 30 s'), isFalse);
  });

  testWidgets('four buttons and their times fit across a phone', (
    tester,
  ) async {
    // Found in a test at 800 px and true of every phone in the shop: the row
    // overflowed by 163 px, which on a device is a button nobody can press.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await pump(tester, left: kSearchBudget);

    expect(tester.takeException(), isNull);
  });
}
