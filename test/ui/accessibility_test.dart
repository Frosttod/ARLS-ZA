import 'dart:math' as math;

import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/map/map_style.dart';
import 'package:arls_za/ui/app_settings.dart';
import 'package:arls_za/ui/haptics.dart';
import 'package:arls_za/ui/hud.dart';
import 'package:arls_za/ui/safety_briefing.dart';
import 'package:arls_za/ui/settings_screen.dart';
import 'package:arls_za/ui/survival_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// §12. Four things the section asks for, and the three that can be proved by
/// a machine: contrast, font scaling, and the motor. Screen readers are the
/// fourth — what is checkable there is that every control has a name, which is
/// tested where the controls are.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    double scale = 1.0,
    bool contrast = false,
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
        theme: buildTheme(Brightness.dark, contrast: contrast),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              highContrast: contrast,
            ),
            child: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('§12: the font scales, and the screens survive it', () {
    // ⚠️ **Two, not 1.3.** Android's accessibility slider goes to 200% and the
    // people who move it are the ones this section exists for. A layout that
    // only survives a polite increase has not been made accessible, it has
    // been made slightly larger.
    const huge = 2.0;

    testWidgets('the safety briefing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pump(tester, SafetyBriefingScreen(onAccept: () {}), scale: huge);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Patrz na drogę'), findsOneWidget);
    });

    testWidgets('the three rules', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pump(tester, const SurvivalRulesScreen(), scale: huge);

      expect(tester.takeException(), isNull);
    });

    testWidgets('and the settings, which is where the switch is', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final settings = AppSettings(MemorySettingsStore());
      await settings.load();

      await pump(
        tester,
        SettingsScreen(
          settings: settings,
          onOpenMaps: () {},
          simulatorEnabled: false,
          onSimulatorChanged: null,
        ),
        scale: huge,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Wysoki kontrast'), findsOneWidget);
    });
  });

  group('§12: high contrast reaches the bar over the map', () {
    testWidgets('the HUD reads the same flag the system sets', (tester) async {
      late HudColors ordinary;
      late HudColors strong;

      await pump(
        tester,
        Builder(
          builder: (context) {
            ordinary = HudColors.of(context);
            return const SizedBox.shrink();
          },
        ),
      );
      await pump(
        tester,
        Builder(
          builder: (context) {
            strong = HudColors.of(context);
            return const SizedBox.shrink();
          },
        ),
        contrast: true,
      );

      expect(ordinary, HudColors.dark);
      expect(strong, HudColors.contrastDark);
    });

    test('the ordinary palettes clear AA, which they did not', () {
      // ⚠️ **Reported from the field as "dark mode is hard to read", and it
      // was measurable.** The night palette's teal, red and grey came off the
      // project site, where they sit on a page in a room; against the panel
      // they were 2.15, 2.60 and 2.22 to one — every one below even the 3:1
      // that graphics get, on the surface a player reads in the street. The
      // daylight palette, drawn later, had happened to land at 9.67 and 7.59.
      //
      // Nobody had ever measured them, which is why this test exists at all.
      for (final pair in [HudColors.dark, HudColors.light]) {
        expect(_ratio(pair.text, pair.panel), greaterThanOrEqualTo(7.0));
        expect(
          _ratio(pair.data, pair.panel),
          greaterThanOrEqualTo(4.5),
          reason: 'the bars are the reading, not decoration',
        );
        expect(_ratio(pair.alert, pair.panel), greaterThanOrEqualTo(4.5));
        expect(
          _ratio(pair.muted, pair.panel),
          greaterThanOrEqualTo(4.5),
          reason: 'a label nobody can read is a label nobody reads',
        );
      }
    });

    test('§12: the light theme is one paper, not three', () {
      // ⚠️ Reported from a screenshot: a warm cream map under a pinkish menu
      // bar under an off-white panel. Each was defensible on its own and
      // together they read as three screens glued into one.
      expect(HudColors.light.panel, kPaper);
      expect(MapPalette.light.background.toUpperCase(), '#F2EFEA');
      expect(buildTheme(Brightness.light).scaffoldBackgroundColor, kPaper);
    });

    test('and the strong palettes actually clear AAA', () {
      // ⚠️ Measured, not asserted by eye. A "high contrast" mode that fails
      // WCAG is a setting that lies to the person who most needed it to be
      // true. 7:1 is AAA for body text.
      for (final pair in [HudColors.contrastDark, HudColors.contrastLight]) {
        expect(
          _ratio(pair.text, pair.panel),
          greaterThanOrEqualTo(7.0),
          reason: 'readings against their panel',
        );
        expect(
          _ratio(pair.data, pair.panel),
          greaterThanOrEqualTo(4.5),
          reason: 'the bars themselves, at least AA',
        );
        expect(
          _ratio(pair.alert, pair.panel),
          greaterThanOrEqualTo(4.5),
          reason: 'warnings, at least AA',
        );
        expect(
          _ratio(pair.muted, pair.panel),
          greaterThanOrEqualTo(4.5),
          reason: 'an empty bar has to be visible as an empty bar',
        );
      }
    });
  });

  group('§12: the motor is a channel, and it can be switched off', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('a hit is felt through a coat', (tester) async {
      const Haptics(_yes)(Buzz.hit);
      await tester.pump();

      expect(calls.single.method, 'HapticFeedback.vibrate');
      expect(calls.single.arguments, 'HapticFeedbackType.heavyImpact');
    });

    testWidgets('and going down is not the same buzz as being hit', (
      tester,
    ) async {
      const Haptics(_yes)(Buzz.down);
      const Haptics(_yes)(Buzz.hunted);
      await tester.pump();

      expect(calls.map((call) => call.arguments), [
        null,
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    testWidgets('switched off, the phone stays still', (tester) async {
      for (final what in Buzz.values) {
        Haptics.off(what);
      }
      await tester.pump();

      expect(calls, isEmpty);
    });
  });

  group('§12: both switches survive being closed', () {
    test('contrast is off until asked for, haptics on until refused', () async {
      final store = MemorySettingsStore();
      final settings = AppSettings(store);
      await settings.load();

      expect(settings.contrast, isFalse);
      expect(
        settings.haptics,
        isTrue,
        reason: 'a row never written is a player never asked',
      );

      await settings.setContrast(true);
      await settings.setHaptics(false);

      final reloaded = AppSettings(store);
      await reloaded.load();

      expect(reloaded.contrast, isTrue);
      expect(reloaded.haptics, isFalse);
    });
  });
}

bool _yes() => true;

/// WCAG 2.1 relative luminance, and the contrast ratio built from it.
double _luminance(Color colour) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}

double _ratio(Color a, Color b) {
  final first = _luminance(a);
  final second = _luminance(b);
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}
