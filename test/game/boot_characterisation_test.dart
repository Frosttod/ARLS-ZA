import 'dart:io';

import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/db/snapshot_store.dart';
import 'package:arls_za/data/persistence/save_bootstrap.dart';
import 'package:arls_za/data/persistence/save_writer.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/location/location_access.dart';
import 'package:arls_za/location/system_permissions.dart';
import 'package:arls_za/main.dart';
import 'package:arls_za/ui/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// URUCHOMIENIE GRY, JAKO SIATKA POD REFAKTOR (§16.1, §11.1).
///
/// ⚠️ **The first test this screen has ever had.** `_TitleScreenState` is six
/// thousand lines in one class and about to be cut into controllers; these
/// tests are the net under that. They assert what the boot *does today*,
/// right or wrong, so that a cut which changes it goes red.
///
/// They stop at the game screen, and that limit is itself a finding. Two
/// things weld the boot to a device:
///
/// 1. **Permissions.** `_boot` awaits two platform channels. In a test they
///    never answer and the screen stayed blank for ever. Fixed here by
///    [SystemProbe] — a seam, not a mock framework.
/// 2. **A map pack.** The game screen renders only once a PMTiles pack has
///    resolved, and the smallest real one is 235 MB. Nothing short of
///    injecting the tile source will get a test past this, and until that
///    exists the walk-eat-restart flow cannot be characterised at all.
///
/// The second is why this file covers the boot and not the game. Making
/// `_mapSource` injectable is the next step, and it is worth doing before any
/// controller is extracted.
void main() {
  /// A device that says yes to everything, instantly.
  Future<({SaveSession session, AppSettings settings, Directory dir})> save({
    SaveDatabase? reuse,
    Directory? into,
  }) async {
    final db = reuse ?? SaveDatabase.memory();
    final dir = into ?? Directory.systemTemp.createTempSync('arls_boot');

    final session = SaveSession(
      db: db,
      writer: SaveWriter(db),
      snapshots: SnapshotStore(SavePaths(dir)),
      clock: GameClock(),
      recovery: const SaveRecovery(health: SaveHealth.ok),
      migratedFrom: null,
    );

    final settings = AppSettings(DatabaseSettingsStore(db));
    await settings.load();

    return (session: session, settings: settings, dir: dir);
  }

  Future<void> open(
    WidgetTester tester, {
    required SaveSession session,
    required AppSettings settings,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('pl'),
        home: TitleScreen(
          session: session,
          settings: settings,
          probe: const _AllowingProbe(),
        ),
      ),
    );

    // ⚠️ Never pumpAndSettle. The game screen carries periodic timers by
    // design (§2.1a.3), so nothing on this route ever settles — an earlier
    // attempt at this test hung on exactly that.
    await beat(tester);
  }

  testWidgets('a fresh install asks for a language first', (tester) async {
    // Before anything else, and before any text the player would have to read
    // in a language they did not choose.
    final it = await save();
    addTearDown(it.session.close);
    addTearDown(() => it.dir.deleteSync(recursive: true));

    await open(tester, session: it.session, settings: it.settings);

    expect(find.text('Polski'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('then the safety briefing, before the game (§16.1)', (
    tester,
  ) async {
    // ⚠️ The order is the point. §16.1 makes this a condition of playing at
    // all — the game moves a real person around a real city — so it comes
    // before the character, before the map and before anything tappable.
    final it = await save();
    addTearDown(it.session.close);
    addTearDown(() => it.dir.deleteSync(recursive: true));

    await open(tester, session: it.session, settings: it.settings);
    await tester.tap(find.text('Polski'));
    await beat(tester);

    expect(find.textContaining('Zanim wyjdziesz'), findsOneWidget);
    expect(find.textContaining('Patrz na drogę'), findsOneWidget);
  });

  testWidgets('and both choices survive a restart (§11.1)', (tester) async {
    // The whole point of asking once. A briefing shown twice reads as a bug,
    // and a language question after the language was chosen reads as amnesia.
    final db = SaveDatabase.memory();
    addTearDown(db.close);

    final first = await save(reuse: db);
    addTearDown(() => first.dir.deleteSync(recursive: true));

    await open(tester, session: first.session, settings: first.settings);
    await tester.tap(find.text('Polski'));
    await beat(tester);
    await tester.tap(find.text('Rozumiem i biorę to na siebie'));
    await beat(tester);

    // Same database, new session and new settings: a restart.
    final again = await save(reuse: db, into: first.dir);
    await open(tester, session: again.session, settings: again.settings);

    expect(find.text('Polski'), findsNothing, reason: 'asked twice');
    expect(find.textContaining('Zanim wyjdziesz'), findsNothing);
  });

  testWidgets('with no map pack the game screen does not appear', (
    tester,
  ) async {
    // ⚠️ Characterising the limit rather than pretending it is not there.
    // §16.6 makes the pack a precondition, and the screen honours it by
    // rendering nothing — which is also why the walk-eat-restart flow has no
    // test yet.
    final it = await save();
    addTearDown(it.session.close);
    addTearDown(() => it.dir.deleteSync(recursive: true));

    await open(tester, session: it.session, settings: it.settings);
    await tester.tap(find.text('Polski'));
    await beat(tester);
    await tester.tap(find.text('Rozumiem i biorę to na siebie'));
    await beat(tester);

    // ⚠️ **A blank page.** Not a message, not a region picker, not an
    // explanation — the boot gets past the briefing, finds no map pack, and
    // renders a Scaffold with nothing in it.
    //
    // Written down as it is rather than as it should be. That is what a
    // characterisation test is for: the decomposition must not change this by
    // accident, and when somebody does fix it, this test is the one that says
    // the fix landed.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .where((text) => (text.data ?? '').isNotEmpty),
      isEmpty,
      reason: 'the player is shown nothing at all',
    );
  });

  testWidgets('permissions are not asked before the briefing is accepted', (
    tester,
  ) async {
    // ⚠️ I expected the opposite and the test corrected me, which is the
    // point of writing one first. `_boot` returns at the language gate, so
    // nothing touches the system until the player has read §16.1's page and
    // said yes — and that ordering is right: a permission dialog before the
    // safety briefing would be the game asking for something before saying
    // what it is for.
    final it = await save();
    addTearDown(it.session.close);
    addTearDown(() => it.dir.deleteSync(recursive: true));

    final probe = _CountingProbe();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('pl'),
        home: TitleScreen(
          session: it.session,
          settings: it.settings,
          probe: probe,
        ),
      ),
    );
    await beat(tester);

    expect(probe.reads, 0, reason: 'asked before the briefing');
  });
}

/// Six frames, sixty milliseconds apart. Enough for a boot to finish its
/// awaits without waiting on timers that never stop.
Future<void> beat(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

class _AllowingProbe extends SystemProbe {
  const _AllowingProbe();

  @override
  Future<SystemPermissions> read() async => const SystemPermissions(
    location: LocationAccess.granted,
    batteryOptimised: false,
  );
}

class _CountingProbe extends SystemProbe {
  int reads = 0;

  @override
  Future<SystemPermissions> read() async {
    reads++;
    return const SystemPermissions(
      location: LocationAccess.granted,
      batteryOptimised: false,
    );
  }
}
