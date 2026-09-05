import 'package:arls_za/game/away_summary.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/away_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// §16.3. The page a player meets after a day away — so what it says has to be
/// readable before they have remembered what they were doing.
void main() {
  Future<void> show(WidgetTester tester, AwaySummary summary) async {
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
            onPressed: () => showAwaySummary(context, summary),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('says how long, what it cost, and what grew', (tester) async {
    await show(
      tester,
      const AwaySummary(
        away: Duration(hours: 9),
        waterLostMl: 1050,
        kcalLost: 900,
        sleepOwed: Duration(hours: 3),
        zonesGrown: 2,
        highestZone: 4,
      ),
    );

    expect(find.text('Pod twoją nieobecność'), findsOneWidget);
    expect(find.textContaining('1050'), findsOneWidget);
    expect(find.textContaining('900'), findsOneWidget);
    expect(find.textContaining('poziom 4'), findsOneWidget);
  });

  testWidgets('and a night that paid the debt down says that instead', (
    tester,
  ) async {
    // ⚠️ The sleep line moves both ways. A summary that only ever reports
    // losses is one a player reads as the game being unfair rather than as an
    // account of what happened.
    await show(
      tester,
      const AwaySummary(
        away: Duration(hours: 8),
        waterLostMl: 400,
        kcalLost: 300,
        sleepOwed: Duration(hours: -5),
        zonesGrown: 0,
        highestZone: 0,
      ),
    );

    expect(find.textContaining('spłacone'), findsOneWidget);
    expect(
      find.text('Nic tam nie urosło pod twoją nieobecność.'),
      findsOneWidget,
    );
  });
}
