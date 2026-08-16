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
    double carriedVolumeL = 0,
    double capacityL = 65,
    Brightness brightness = Brightness.dark,
      ThreatReading? threat,
}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
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
          threat: threat,
            carryComfortKg: profile.carryComfortKg,
            carryMaxKg: profile.carryMaxKg,
            carriedKg: carriedKg,
            carriedVolumeL: carriedVolumeL,
            capacityL: capacityL,
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

  testWidgets('a meal shows as a tick ahead of the bar, not as more bar', (
    tester,
  ) async {
    // §2.2, §2.3: the difference between what a player has and what is coming
    // is the whole reason absorption takes time. A fuller bar would hide it.
    final eaten = healthy().copyWith(
      caloriesKcal: constants.caloriesDailyKcal * 0.4,
      pendingKcal: 520,
    );

    await pumpHud(tester, eaten);

    expect(
      find.text('40%'),
      findsOneWidget,
      reason: 'the reading is what the body has, not what the stomach holds',
    );
  });

  testWidgets('what is coming is marked with a sign, not only a mark', (
    tester,
  ) async {
    // §12: a tick on the bar says something is on its way without saying
    // which way. The sign says it in one character.
    await pumpHud(
      tester,
      healthy().copyWith(
        caloriesKcal: constants.caloriesDailyKcal * 0.4,
        pendingKcal: 520,
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets('an empty stomach puts no sign on any bar', (tester) async {
    await pumpHud(tester, healthy());

    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets('a screen reader hears the same thing the eye does', (
    tester,
  ) async {
    await pumpHud(
      tester,
      healthy().copyWith(
        waterMl: constants.waterDailyMl * 0.5,
        pendingWaterMl: constants.waterDailyMl * 0.25,
      ),
    );

    expect(find.bySemanticsLabel(RegExp(r'50%, \+25%')), findsOneWidget);
  });

  group('both carry limits (§18.1a)', () {
    testWidgets('mass reads against the hard limit, not the comfortable one', (
      tester,
    ) async {
      // The bar has to run to the point where the game refuses to pick things
      // up. The comfortable load is a mark on it, not its end.
      await pumpHud(tester, healthy(), carriedKg: 18);

      expect(find.text('18.0 / 36 kg'), findsOneWidget);
    });

    testWidgets('bulk is shown beside it, because neither predicts the other', (
      tester,
    ) async {
      await pumpHud(tester, healthy(), carriedVolumeL: 40, capacityL: 65);

      expect(find.text('40 / 65 l'), findsOneWidget);
    });

    testWidgets('shock lowers the carry limit it displays (§2.6)', (
      tester,
    ) async {
      await pumpHud(
        tester,
        healthy().copyWith(bloodMl: constants.bloodMaxMl * 0.75),
        carriedKg: 18,
      );

      // Class II costs a tenth of the carry load: 36 kg becomes 32.4 kg.
      expect(find.text('18.0 / 32 kg'), findsOneWidget);
    });

    testWidgets('a pack with no room is legible without reading the colour', (
      tester,
    ) async {
      // §12: colour never carries information on its own.
      await pumpHud(tester, healthy(), carriedVolumeL: 65, capacityL: 65);

      expect(find.text('65 / 65 l'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('65 of 65 litres')),
        findsOneWidget,
      );
    });
  });

  group('both themes (§12)', () {
    Color panelOf(WidgetTester tester) =>
        tester.widget<Material>(find.byType(Material).first).color!;

    testWidgets('the panel behind the bars follows the theme', (tester) async {
      // The bug this replaces: a light interface with the HUD still painted
      // for night, which is unreadable in the daylight it was switched on for.
      await pumpHud(tester, healthy());
      final dark = panelOf(tester);

      await pumpHud(tester, healthy(), brightness: Brightness.light);
      final light = panelOf(tester);

      expect(dark, isNot(light));
      expect(dark.computeLuminance(), lessThan(0.2));
      expect(light.computeLuminance(), greaterThan(0.7));
    });

    testWidgets('readings stay legible against their own panel', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await pumpHud(tester, healthy(), brightness: brightness);

        final colours = brightness == Brightness.dark
            ? HudColors.dark
            : HudColors.light;
        final contrast =
            (colours.text.computeLuminance() - colours.panel.computeLuminance())
                .abs();

        expect(contrast, greaterThan(0.5), reason: '$brightness');
      }
    });

    test('the warning colour keeps its hue in both', () {
      // A red that becomes another colour in daylight is not a warning, it is
      // decoration.
      final dark = HSLColor.fromColor(HudColors.dark.alert);
      final light = HSLColor.fromColor(HudColors.light.alert);

      expect((dark.hue - light.hue).abs(), lessThan(15));
    });
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

  group('a fight, from the HUD (§5.5.2)', () {
    testWidgets('how many, and how far the nearest one is', (tester) async {
      await pumpHud(
        tester,
        healthy(),
        threat: const ThreatReading(
          count: 3,
          nearestM: 84,
          anySprinting: false,
        ),
      );

      expect(find.textContaining('3'), findsWidgets);
      expect(find.textContaining('84 m'), findsOneWidget);
    });

    testWidgets('whether any of them can still sprint', (tester) async {
      // §5.5.2 calls this the key tactical fact: one that has burned its
      // budget can be walked away from, one that has not cannot.
      await pumpHud(
        tester,
        healthy(),
        threat: const ThreatReading(
          count: 1,
          nearestM: 40,
          anySprinting: true,
        ),
      );

      expect(find.textContaining('ma jeszcze sprint'), findsOneWidget);
    });

    testWidgets('and it says so in words, not only in colour (§12)', (
      tester,
    ) async {
      await pumpHud(
        tester,
        healthy(),
        threat: const ThreatReading(
          count: 2,
          nearestM: 12,
          anySprinting: false,
        ),
      );

      // Twelve metres is the red band, and the twelve is on screen.
      expect(find.textContaining('12 m'), findsOneWidget);
    });

    testWidgets('an empty street says nothing at all', (tester) async {
      // A warning that never goes out is a warning nobody reads.
      await pumpHud(tester, healthy());

      expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
    });
  });

  testWidgets('a status says what it is costing, on a tap (§12)', (
    tester,
  ) async {
    // A status a player cannot ask about is a status they learn to ignore.
    await pumpHud(
      tester,
      healthy().copyWith(waterMl: constants.waterDailyMl * 0.2),
    );

    await tester.tap(find.text('ODWODNIENIE'));
    await tester.pumpAndSettle();

    // Four questions in the order a person asks them: how bad, what it costs,
    // what fixes it, where that is. No section numbers — the design document
    // is where the numbers are argued, not the rain.
    expect(find.textContaining('dobowej normy'), findsOneWidget);
    expect(find.text('WPŁYW'), findsOneWidget);
    expect(find.text('CO ZROBIĆ'), findsOneWidget);
    expect(find.text('GDZIE ZNALEŹĆ'), findsOneWidget);
    expect(find.textContaining('celność'), findsOneWidget);
    expect(find.textContaining('§'), findsNothing);
  });

  testWidgets('and the sheet closes again', (tester) async {
    await pumpHud(
      tester,
      healthy().copyWith(waterMl: constants.waterDailyMl * 0.2),
    );

    await tester.tap(find.text('ODWODNIENIE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('celność'), findsNothing);
  });
}
