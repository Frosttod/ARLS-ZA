import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:arls_za/ui/hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The HUD of §3.6. It has to stay readable at a glance by someone walking
/// down a street, and every state it shows must be reachable through text as
/// well as colour (§12).
void main() {
  final profile = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );
  final constants = profile.toSimConstants();
  final t0 = DateTime.utc(2026, 8, 10, 12);

  SimState healthy() => SimState.fresh(at: t0, constants: constants);

  Future<void> pumpHud(
    WidgetTester tester,
    SimState state, {
    List<String> warnings = const [],
    double carriedKg = 0,
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
          body: Hud(
            state: state,
            status: statusOf(state: state, constants: constants),
            constants: constants,
            warnings: warnings,
            carryComfortKg: profile.carryComfortKg,
            carriedKg: carriedKg,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a healthy character shows full readings and no warnings', (
    tester,
  ) async {
    await pumpHud(tester, healthy());

    expect(find.text('100%'), findsNWidgets(3));
    expect(find.text('5319 ml'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('WSTRZĄS'), findsNothing);
    expect(find.text('ODWODNIENIE'), findsNothing);
  });

  testWidgets('blood is shown in millilitres as well as per cent', (
    tester,
  ) async {
    await pumpHud(
      tester,
      healthy().copyWith(bloodMl: constants.bloodMaxMl * 0.7),
    );

    expect(find.text('70%'), findsOneWidget);
    expect(
      find.text('${(constants.bloodMaxMl * 0.7).round()} ml'),
      findsOneWidget,
      reason: 'millilitres are the unit every wound in §2.6 is measured in',
    );
  });

  testWidgets('shock raises a named status, not just a colour (§12)', (
    tester,
  ) async {
    await pumpHud(
      tester,
      healthy().copyWith(bloodMl: constants.bloodMaxMl * 0.75),
    );

    expect(find.text('WSTRZĄS'), findsOneWidget);
  });

  testWidgets('dehydration and starvation each name themselves', (
    tester,
  ) async {
    await pumpHud(
      tester,
      healthy().copyWith(
        // 2% of body mass is the first threshold §2.3 defines, and the only
        // one reachable inside a single day's reserve.
        waterMl: constants.waterDailyMl - 1700,
        caloriesKcal: constants.caloriesDailyKcal * 0.1,
      ),
    );

    expect(find.text('ODWODNIENIE'), findsOneWidget);
    expect(find.text('GŁÓD'), findsOneWidget);
  });

  testWidgets('sleep deprivation appears once the debt bites', (tester) async {
    await pumpHud(
      tester,
      healthy().copyWith(sleepDebtSeconds: const Duration(hours: 6).inSeconds),
    );

    expect(find.text('NIEWYSPANIE'), findsOneWidget);
  });

  testWidgets('a signal warning is surfaced alongside the body statuses', (
    tester,
  ) async {
    await pumpHud(tester, healthy(), warnings: const ['BRAK SYGNAŁU']);

    expect(find.text('BRAK SYGNAŁU'), findsOneWidget);
  });

  testWidgets('warnings stack — a flat battery does not hide a lost signal', (
    tester,
  ) async {
    // §3.2, §3.3 and §3.4 can all be true at once, and each is a different
    // reason the game is not doing what the player expects.
    await pumpHud(
      tester,
      healthy().copyWith(bloodMl: constants.bloodMaxMl * 0.75),
      warnings: const ['ROZGRYWKA WSTRZYMANA', 'BRAK SYGNAŁU', 'BATERIA'],
    );

    expect(find.text('ROZGRYWKA WSTRZYMANA'), findsOneWidget);
    expect(find.text('BRAK SYGNAŁU'), findsOneWidget);
    expect(find.text('BATERIA'), findsOneWidget);
    expect(
      find.text('WSTRZĄS'),
      findsOneWidget,
      reason: 'the body statuses are not crowded out by the system ones',
    );
  });

  testWidgets('carry load is shown against the comfortable limit', (
    tester,
  ) async {
    await pumpHud(tester, healthy(), carriedKg: 18);

    expect(find.text('18.0 / 24.0 kg'), findsOneWidget);
  });

  testWidgets('shock lowers the carry limit it displays (§2.6)', (
    tester,
  ) async {
    await pumpHud(
      tester,
      healthy().copyWith(bloodMl: constants.bloodMaxMl * 0.75),
      carriedKg: 18,
    );

    // Class II costs a tenth of the carry load: 24 kg becomes 21.6 kg.
    expect(find.text('18.0 / 21.6 kg'), findsOneWidget);
  });

  testWidgets('every reading carries a screen-reader label (§12)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHud(tester, healthy(), carriedKg: 5);

    expect(find.bySemanticsLabel(RegExp('Krew')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Woda')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Kalorie')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Tętno')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Udźwig')), findsOneWidget);

    handle.dispose();
  });
}
