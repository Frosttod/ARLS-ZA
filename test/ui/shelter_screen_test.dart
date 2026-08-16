import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/ui/shelter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// EKRAN SCHRONU (§8, §18.2).
///
/// The screen shows what could be here as well as what is, with what is
/// missing named. A locked row reading "6 more planks" is a reason to go out;
/// a hidden row is nothing at all.
void main() {
  const home = GeoPoint(52.4064, 16.9252);
  final t0 = DateTime.utc(2026, 8, 16, 12);

  Future<void> pump(
    WidgetTester tester, {
    List<Shelter> shelters = const [],
    Map<String, int> carried = const {},
    bool hasTools = true,
    GeoPoint? at = home,
  }) async {
    // A tall surface, so the whole list is built: the screen is one column of
    // cards and the point of the tests is what it says, not what scrolls.
    tester.view.physicalSize = const Size(1080, 4200);
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
        home: ShelterScreen(
          shelters: shelters,
          at: at,
          now: t0,
          carried: carried,
          itemNameOf: (id) => id,
          hasTools: hasTools,
          hasHammer: hasTools,
          hasMultitool: false,
          onBuild: (_) {},
          onBuildModule: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Shelter built({
    Map<ShelterModule, int> modules = const {},
    ShelterKind kind = ShelterKind.main,
  }) => Shelter(
    id: 1,
    kind: kind,
    position: home,
    startedAt: t0.subtract(const Duration(days: 1)),
    buildTime: kind.buildTime,
    modules: modules,
  );

  group('with nothing built yet', () {
    testWidgets('the offer says what it costs in time', (tester) async {
      await pump(tester);

      // With a hammer: three hours less thirty-five per cent.
      expect(find.textContaining('1 h 57 min'), findsOneWidget);
    });

    testWidgets('and nothing can be started without a position', (
      tester,
    ) async {
      // A shelter goes where you are standing, so without a fix there is
      // nowhere to put it.
      await pump(tester, at: null);

      final buttons = tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      );
      expect(buttons.every((button) => button.onPressed == null), isTrue);
    });
  });

  group('with a shelter standing', () {
    testWidgets('it says the radius, the sleep and the storage', (
      tester,
    ) async {
      await pump(tester, shelters: [built()]);

      expect(find.text('50 m'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('25 kg'), findsOneWidget);
    });

    testWidgets('every module is shown, built or not (§8.4)', (tester) async {
      await pump(tester, shelters: [built()]);

      for (final module in ShelterModule.values) {
        expect(find.text(moduleName(L10n.of(tester.element(
          find.byType(ShelterScreen),
        )), module)), findsOneWidget);
      }
    });

    testWidgets('what is missing is named rather than hidden (§18.2)', (
      tester,
    ) async {
      await pump(
        tester,
        shelters: [built()],
        carried: {'mat_wood': 14, 'mat_metal': 6},
      );

      // Storage L1 is 20 wood and 6 metal; six planks short of it.
      expect(find.textContaining('mat_wood ×6'), findsOneWidget);
    });

    testWidgets('and with the lot carried the button is live', (tester) async {
      await pump(
        tester,
        shelters: [built()],
        carried: {'mat_wood': 40, 'mat_metal': 20},
      );

      final buttons = tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      );
      expect(buttons.any((button) => button.onPressed != null), isTrue);
    });

    testWidgets('a built module moves its own numbers', (tester) async {
      await pump(
        tester,
        shelters: [
          built(modules: {ShelterModule.storage: 1, ShelterModule.lounge: 1}),
        ],
      );

      expect(find.textContaining('75 kg'), findsOneWidget);
      expect(find.text('115%'), findsOneWidget);
    });
  });

  group('camps (§8.5.2)', () {
    testWidgets('one too close to the shelter is refused, with a reason', (
      tester,
    ) async {
      await pump(
        tester,
        shelters: [built()],
        carried: {'mat_wood': 20, 'mat_metal': 10, 'mat_fabric': 10},
      );

      // Named, not just greyed: "under 800 m from the shelter" is something
      // a player can act on, and "no" is not. The camp's own description
      // mentions the distance too, hence two.
      expect(find.textContaining('800 m'), findsNWidgets(2));

      final camp = tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      ).last;
      expect(camp.onPressed, isNull);
    });
  });
}
