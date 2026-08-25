import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/ui/shelter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arls_za/craft/craft_job.dart';
import 'package:flutter/foundation.dart';
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
          shelters: ValueNotifier(shelters),
          standingAt: ValueNotifier(at),
          carried: carried,
          itemNameOf: (id) => id,
          hasTools: hasTools,
          hasHammer: hasTools,
          hasMultitool: false,
          onBuild: (_) {},
          onBuildModule: (_) {},
          onShelves: (_) {},
          onCraft: () {},
          craftJob: const _NoJob(),
          shelved: const {},
          shelvedMassKg: 0,
          shelvedVolumeL: 0,
          onCancelBuild: (_) {},
        ),
      ),
    );
    // A one-second ticker keeps the counters honest, so the tree never settles.
    await tester.pump(const Duration(milliseconds: 50));
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
      expect(find.textContaining('1:57'), findsOneWidget);
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
      // §12: a multiplier, not a percentage. The module cards say ×1,15 and
      // the summary has to say the same thing the same way — "115%" and
      // "×1.15" on one screen are two units for one figure.
      expect(find.text('×1.00'), findsOneWidget);
      // The shelves row carries it now, with how much is used.
      expect(find.textContaining('/ 100.00 kg'), findsOneWidget);
    });

    testWidgets('every module is shown, built or not (§8.4)', (tester) async {
      await pump(tester, shelters: [built()]);

      for (final module in ShelterModule.values) {
        expect(
          find.text(
            moduleName(
              L10n.of(tester.element(find.byType(ShelterScreen))),
              module,
            ),
          ),
          findsOneWidget,
        );
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

      expect(find.textContaining('/ 150.00 kg'), findsOneWidget);

      // §2.5, §4.6: the Lounge buys time back twice — a shorter night, and a
      // faster evening in a chair with a lamp.
      expect(find.textContaining('×1.15'), findsWidgets);
      expect(
        find.textContaining('-4%'),
        findsWidgets,
        reason: 'twelve per cent off reading at the third level (§8.4)',
      );

      // §8.4, §12: and the card says what the next level makes it, which is
      // the question "ile bonusu daje salon" was actually asking.
      expect(find.textContaining('×1.15'), findsWidgets);
      expect(find.textContaining('×1.30'), findsWidgets);
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
      // ⚠️ Scrolled to first. The screen is a ListView and a ListView builds
      // what it can see; the camps live below a shelter with its shelves and
      // three modules on it, which is off the bottom of a test surface.
      // ⚠️ Dragged by hand rather than with scrollUntilVisible, which cannot
      // do this at all: `.first` on the target throws "No element" while
      // nothing matches yet, and a bare finder throws "Too many elements" the
      // moment both matches appear. Two of them is the thing being asserted.
      for (var i = 0; i < 12; i++) {
        if (find.textContaining('800 m').evaluate().isNotEmpty) break;
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
      }

      expect(find.textContaining('800 m'), findsNWidgets(2));

      final camp = tester
          .widgetList<FilledButton>(find.byType(FilledButton))
          .last;
      expect(camp.onPressed, isNull);
    });
  });

  group('the counter starts the moment the work does', () {
    testWidgets('a build under way is counted down, not left at zero', (
      tester,
    ) async {
      // Found on a phone: starting a build left this screen showing nothing
      // until somebody backed out and came in again — it is a pushed route,
      // and it was handed a list rather than listening to one.
      final shelters = ValueNotifier<List<Shelter>>(const []);
      addTearDown(shelters.dispose);

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
            standingAt: ValueNotifier<GeoPoint?>(home),
            carried: const {},
            itemNameOf: (id) => id,
            hasTools: true,
            hasHammer: true,
            hasMultitool: false,
            onBuild: (_) {},
            onBuildModule: (_) {},
            onShelves: (_) {},
            onCraft: () {},
            craftJob: const _NoJob(),
            shelved: const {},
            shelvedMassKg: 0,
            shelvedVolumeL: 0,
            onCancelBuild: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Zostało'), findsNothing);

      shelters.value = [
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: home,
          startedAt: DateTime.now().toUtc(),
          buildTime: kShelterBuildTime,
          buildLeft: kShelterBuildTime,
        ),
      ];
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Zostało'), findsOneWidget);
    });
  });

  group('the bar on the map (§8.3)', () {
    testWidgets('is there while something is going up on this site', (
      tester,
    ) async {
      final site = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: home,
        startedAt: t0,
        buildTime: kShelterBuildTime,
        buildLeft: const Duration(hours: 1),
      );

      expect(BuildProgress.of([site], home, t0), isNotNull);
    });

    testWidgets('and nowhere near it when the player has walked off', (
      tester,
    ) async {
      // The work is not happening off the site, so a bar creeping along on a
      // bus would be a lie about the one rule this system has.
      final site = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: home,
        startedAt: t0,
        buildTime: kShelterBuildTime,
        buildLeft: const Duration(hours: 1),
      );

      expect(
        BuildProgress.of(
          [site],
          GeoPoint(home.latitude + 0.02, home.longitude),
          t0,
        ),
        isNull,
      );
    });

    testWidgets('and gone once everything is finished', (tester) async {
      final done = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: home,
        startedAt: t0,
        buildTime: kShelterBuildTime,
        buildLeft: Duration.zero,
      );

      expect(BuildProgress.of([done], home, t0), isNull);
    });
  });

  group('giving up on a build (§8.3)', () {
    Shelter half() => Shelter(
      id: 1,
      kind: ShelterKind.main,
      position: home,
      startedAt: t0,
      buildTime: kShelterBuildTime,
      buildLeft: const Duration(hours: 2),
    );

    testWidgets('is offered while something is going up', (tester) async {
      await pump(tester, shelters: [half()]);

      expect(find.text('Przerwij'), findsWidgets);
    });

    testWidgets('and not once the place is standing', (tester) async {
      // There is nothing to give up on: the hours are already in the walls.
      await pump(tester, shelters: [built()]);

      expect(find.text('Przerwij'), findsNothing);
    });

    testWidgets('says it cannot be undone before it happens', (tester) async {
      Shelter? cancelled;

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
            shelters: ValueNotifier([half()]),
            standingAt: ValueNotifier<GeoPoint?>(home),
            carried: const {},
            itemNameOf: (id) => id,
            hasTools: true,
            hasHammer: true,
            hasMultitool: false,
            onBuild: (_) {},
            onBuildModule: (_) {},
            onShelves: (_) {},
            onCraft: () {},
            craftJob: const _NoJob(),
            shelved: const {},
            shelvedMassKg: 0,
            shelvedVolumeL: 0,
            onCancelBuild: (place) => cancelled = place,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Przerwij').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('nie da się cofnąć'), findsOneWidget);
      expect(cancelled, isNull, reason: 'nothing until it is confirmed');

      await tester.tap(find.text('Buduj dalej'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(cancelled, isNull, reason: 'backing out changes nothing');

      await tester.tap(find.text('Przerwij').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, 'Przerwij'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(cancelled, isNotNull);
    });
  });
  group('a tool is kept, a material is spent (§18.3)', () {
    testWidgets('the hammer is a tick, not a count', (tester) async {
      // ⚠️ It read "1 / 1 Młotek", which says the hammer is about to be used
      // up by the wall — and sent a player looking for a second one. A
      // material is spent and a tool is not; the only thing worth saying
      // about a tool is whether it is to hand.
      await pump(tester, shelters: [built()], hasTools: false);

      expect(find.textContaining('1 / 1'), findsNothing);
      expect(find.text('—'), findsWidgets, reason: 'not held, so a dash');
    });

    testWidgets('and a tick once it is to hand', (tester) async {
      await pump(tester, shelters: [built()], hasTools: true);

      expect(find.text('✓'), findsWidgets);
    });
  });
  group('a met requirement says it is met (§12)', () {
    // ⚠️ Reported from a screenshot: with fourteen scrap on the shelf, one
    // module read "14 / 6" in grey and another "14 / 20" in amber, and the
    // grey one was taken for an error. The arithmetic was right — different
    // modules want different amounts — but grey alone reads as *disabled*
    // rather than *satisfied*, and nothing on the row said which.
    testWidgets('enough of something is ticked, not just dimmed', (
      tester,
    ) async {
      await pump(
        tester,
        shelters: [built()],
        carried: const {'mat_wood': 999, 'mat_metal': 999},
        hasTools: true,
      );

      // Every material on every module is covered by that, so every row is a
      // tick — and the amber shortfall figure appears nowhere.
      expect(find.text('✓'), findsWidgets);
    });

    testWidgets('and what is short still shows how short', (tester) async {
      await pump(tester, shelters: [built()], carried: const {});

      // The storage module wants twenty planks; nothing is carried.
      expect(find.text('0 / 20'), findsWidgets);
    });
  });
}

/// A bench with nothing on it, for every test that predates §18.4.
class _NoJob implements ValueListenable<CraftJob?> {
  const _NoJob();

  @override
  CraftJob? get value => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
