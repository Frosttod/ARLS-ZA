import 'dart:io';

import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/sim/penalty_ladder.dart';
import 'package:arls_za/ui/vital_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// CENA WIDZIANA PRZED DECYZJĄ (§2.3, §2.5.4, §12).
///
/// ⚠️ **Gra karała za wodę, jedzenie i sen, i nigdzie nie mówiła jak.** Profil
/// pokazywał karę dopiero wtedy, gdy już bolała — więc „zostało mi pół butelki"
/// było liczbą bez ceny, a decyzja „wracam po wodę czy idę dalej" nie miała się
/// o co oprzeć.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VitalKind kind,
    required PenaltyLadder ladder,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
        home: VitalSheet(kind: kind, ladder: ladder, now: 'teraz'),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('§2.3: woda mówi, ile kosztuje', () {
    testWidgets('cała drabinka jest widoczna, zanim zaboli', (tester) async {
      // §12: to jest cały sens tego ekranu — gracz z pełną butelką ma wiedzieć,
      // co go czeka, jeśli jej nie znajdzie.
      await pump(
        tester,
        kind: VitalKind.water,
        ladder: waterLadder(waterMl: 2905, dailyMl: 2905, bodyMassKg: 83),
      );

      expect(find.text('Na razie nic to nie kosztuje.'), findsOneWidget);

      // ⚠️ Każdy szczebel mówi **cały** stan, nie samą różnicę: przy pięciu
      // procentach celność dalej jest niższa o piętnaście, i gracz musi to
      // widzieć na tym wierszu, a nie składać z dwóch.
      expect(find.textContaining('celność −15%'), findsNWidgets(3));
      expect(find.textContaining('o 30% dłużej'), findsOneWidget);
      expect(find.textContaining('o 60% dłużej'), findsOneWidget);
    });

    testWidgets('a odwodniony widzi, na którym szczeblu stoi', (tester) async {
      await pump(
        tester,
        kind: VitalKind.water,
        ladder: waterLadder(waterMl: 0, dailyMl: 4150, bodyMassKg: 83),
      );

      expect(find.text('Na razie nic to nie kosztuje.'), findsNothing);
      // Nagłówek arkusza powtarza to, co obowiązuje teraz — i to jest ta sama
      // liczba, którą niesie szczebel.
      expect(find.textContaining('o 30% dłużej'), findsNWidgets(2));
    });

    testWidgets('progi są w procentach masy ciała, tak jak §2.3 je mierzy', (
      tester,
    ) async {
      await pump(
        tester,
        kind: VitalKind.water,
        ladder: waterLadder(waterMl: 2905, dailyMl: 2905, bodyMassKg: 83),
      );

      expect(find.text('−2% masy'), findsOneWidget);
      expect(find.text('−5% masy'), findsOneWidget);
      expect(find.text('−10% masy'), findsOneWidget);
    });
  });

  group('§2.5.4: sen', () {
    testWidgets('trzy godziny długu nie kosztują jeszcze nic', (tester) async {
      // Dokładnie przypadek ze zgłoszenia z terenu: pasek pokazywał dług, a
      // profil mówił „nic Cię nie kosztuje". To była prawda — tylko nie dało
      // się jej sprawdzić.
      await pump(
        tester,
        kind: VitalKind.sleep,
        ladder: sleepLadder(const Duration(hours: 3)),
      );

      expect(find.text('Na razie nic to nie kosztuje.'), findsOneWidget);
      expect(find.text('od 4 h długu'), findsOneWidget);
      expect(find.textContaining('rozrzut +1 MOA'), findsOneWidget);
    });

    testWidgets('a dwanaście to trzy MOA, połowa czasu i wolniejsza nauka', (
      tester,
    ) async {
      await pump(
        tester,
        kind: VitalKind.sleep,
        ladder: sleepLadder(const Duration(hours: 13)),
      );

      expect(find.textContaining('rozrzut +3 MOA'), findsNWidgets(2));
      expect(find.textContaining('nauka −20%'), findsNWidgets(2));
    });
  });

  testWidgets('§2.3: a jedzenie mierzy się zapasem dobowym', (tester) async {
    await pump(
      tester,
      kind: VitalKind.food,
      ladder: foodLadder(caloriesKcal: 2413, dailyKcal: 2413),
    );

    expect(find.text('poniżej 50%'), findsOneWidget);
    expect(find.text('poniżej 20%'), findsOneWidget);
    expect(find.textContaining('celność −10%'), findsNWidgets(2));
  });

  test('§12: i profil naprawdę te drzwi ma', () {
    // ⚠️ Test źródłowy: arkusz może być doskonały i nieosiągalny. Ta gra
    // złapała już siedemnaście takich.
    final profile = File('lib/ui/profile_screen.dart').readAsStringSync();

    expect(profile.contains('showVitalSheet('), isTrue);
    expect(
      profile.contains('VitalKind.water') &&
          profile.contains('VitalKind.food') &&
          profile.contains('VitalKind.sleep'),
      isTrue,
      reason: 'wszystkie trzy wiersze stanu ciała, nie jeden',
    );
  });
}
