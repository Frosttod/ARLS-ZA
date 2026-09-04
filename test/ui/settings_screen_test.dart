import 'package:arls_za/devtools/dev_mode.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/app_settings.dart';
import 'package:arls_za/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// USTAWIENIA, the fourth entry of §3.6. Everything here is a choice about the
/// app rather than the character, and every one of them has to survive being
/// closed — a setting that forgets itself is worse than one that does not
/// exist.
void main() {
  late MemorySettingsStore store;
  late AppSettings settings;

  setUp(() async {
    // In memory on purpose: a real database write inside a pump loop never
    // completes under the test binding's clock, so the test would hang rather
    // than fail.
    store = MemorySettingsStore();
    settings = AppSettings(store);
    await settings.load();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    VoidCallback? onOpenMaps,
    bool simulator = false,
    void Function(bool)? onSimulator,
  }) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
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
        home: AnimatedBuilder(
          animation: settings,
          builder: (context, _) => SettingsScreen(
            settings: settings,
            onOpenMaps: onOpenMaps ?? () {},
            simulatorEnabled: simulator,
            onSimulatorChanged: onSimulator,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers both game languages, each named in itself', (
    tester,
  ) async {
    await pumpSettings(tester);

    // Translating a language list defeats it: somebody looking for their own
    // language is looking for the word they know.
    expect(find.text('Polski'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('choosing a language writes it down', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(settings.locale?.languageCode, 'en');
    expect(await store.read(kLocaleSettingKey), 'en');
  });

  testWidgets('offers the three appearances, dark selected by default', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Ciemny'), findsOneWidget);
    expect(find.text('Jasny'), findsOneWidget);
    expect(find.text('Jak w systemie'), findsOneWidget);
    expect(
      settings.themeMode,
      ThemeMode.dark,
      reason: 'the game is designed to be read at night',
    );
  });

  testWidgets('choosing the light theme survives being closed', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Jasny'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.light);

    // What the next launch will read.
    final reloaded = AppSettings(store);
    await reloaded.load();
    expect(reloaded.themeMode, ThemeMode.light);
  });

  testWidgets('the maps entry hands over to the region screen', (tester) async {
    var opened = false;
    await pumpSettings(tester, onOpenMaps: () => opened = true);

    await tester.tap(find.text('Mapy offline'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('the simulator switch exists only in a developer build', (
    tester,
  ) async {
    await pumpSettings(tester, onSimulator: (_) {});

    expect(
      find.text('Symulator GPS'),
      kDevTools ? findsOneWidget : findsNothing,
      reason: 'a release build has no simulator to switch on (§11.2)',
    );
  });

  testWidgets('§15.7: the three rules are findable again from the menu', (
    tester,
  ) async {
    await pumpSettings(tester);

    // ⚠️ The test exists because of what this project keeps finding: a screen
    // that is written, correct, and reachable from nowhere.
    await tester.tap(find.text('Zasady przetrwania'));
    await tester.pumpAndSettle();

    expect(find.text('1. Stój, żeby strzelać.'), findsOneWidget);
    expect(find.text('2. Nie przed wszystkim uciekniesz.'), findsOneWidget);
    expect(find.text('3. Twoje ciało jest kontrolerem.'), findsOneWidget);
  });

  testWidgets('§16.5: the privacy answer is stated, not offered as a switch', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Brak telemetrii'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SwitchListTile && widget.value == true,
      ),
      findsNothing,
      reason: 'nothing is collected, so there is nothing to opt out of',
    );
  });
}
