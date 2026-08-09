import 'dart:io';
import 'dart:typed_data';

import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/db/snapshot_store.dart';
import 'package:arls_za/data/persistence/save_bootstrap.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

import 'db_fixture.dart';

/// The exit criterion of stage 0, written as a test: the save survives a
/// process kill and comes back with a catch-up, and a corrupt file is replaced
/// by a snapshot rather than losing the character.
void main() {
  late Directory tempDir;
  late SavePaths paths;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arls_boot_');
    paths = SavePaths(tempDir);
    await paths.ensureExists();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('first boot creates the database at the current schema', () async {
    final session = await SaveBootstrap(
      paths: paths,
    ).boot(now: DateTime.utc(2026, 8, 9, 12));
    addTearDown(session.close);

    expect(session.recovery.health, SaveHealth.absent);
    expect(session.migratedFrom, isNull);
    expect(await session.db.storedSchemaVersion(), kSchemaVersion);
    expect(await session.db.isHealthy(), isTrue);
  });

  test('second boot finds the existing save and does not migrate', () async {
    final first = await SaveBootstrap(
      paths: paths,
    ).boot(now: DateTime.utc(2026, 8, 9, 12));
    await insertProfile(first.db, name: 'Trwała');
    await first.close();

    final second = await SaveBootstrap(
      paths: paths,
    ).boot(now: DateTime.utc(2026, 8, 9, 13));
    addTearDown(second.close);

    expect(second.recovery.health, SaveHealth.ok);
    expect(second.migratedFrom, kSchemaVersion);
    expect(second.didMigrate, isFalse);
    expect((await second.db.allProfiles()).single.name, 'Trwała');
  });

  test('a corrupt database is replaced by a snapshot at boot', () async {
    final first = await SaveBootstrap(
      paths: paths,
    ).boot(now: DateTime.utc(2026, 8, 9, 12));
    await insertProfile(first.db, name: 'Uratowana');
    await first.snapshots.capture(first.db, now: DateTime.utc(2026, 8, 9, 12));
    await first.close();

    _corrupt(paths.databaseFile);

    final second = await SaveBootstrap(
      paths: paths,
    ).boot(now: DateTime.utc(2026, 8, 9, 12, 25));
    addTearDown(second.close);

    expect(second.recovery.health, SaveHealth.restored);
    expect(second.recovery.timeLost, const Duration(minutes: 25));
    expect((await second.db.allProfiles()).single.name, 'Uratowana');
  });

  group('clock survives a restart', () {
    test('the high-water mark is reinstated from the database', () async {
      final wall = ManualWallClock(DateTime.utc(2026, 8, 9, 12));
      final firstClock = GameClock(wallClock: wall);

      final first = await SaveBootstrap(
        paths: paths,
        clock: firstClock,
      ).boot(now: wall.nowUtc());
      wall.advance(const Duration(hours: 6));
      firstClock.advance(DateTime.utc(2026, 8, 9, 12));
      await persistClockMark(first.db, firstClock);
      await first.close();

      // Player winds the device clock back a day and restarts the app.
      final tamperedWall = ManualWallClock(DateTime.utc(2026, 8, 8, 12));
      final secondClock = GameClock(wallClock: tamperedWall);
      final second = await SaveBootstrap(
        paths: paths,
        clock: secondClock,
      ).boot(now: tamperedWall.nowUtc());
      addTearDown(second.close);

      final advance = secondClock.advance(DateTime.utc(2026, 8, 9, 12));

      expect(advance.elapsed, Duration.zero);
      expect(
        advance.rolledBack,
        isTrue,
        reason: 'restarting the app must not reset the rollback guard',
      );
    });
  });

  group('crash and catch-up', () {
    test('an unflushed minute is lost, the rest is caught up', () async {
      final start = DateTime.utc(2026, 8, 9, 12);

      // Session one: play, flush once, then die without flushing again.
      final first = await SaveBootstrap(paths: paths).boot(now: start);
      final profileId = await insertProfile(first.db, createdAt: start);
      first.writer.stageHot(
        vitalsFor(profileId, lastUpdate: start, waterMl: 2800),
      );
      await first.writer.flushHot(start);
      first.writer.stageHot(
        vitalsFor(
          profileId,
          lastUpdate: start.add(const Duration(seconds: 45)),
          waterMl: 2700,
        ),
      );
      // No flush. Process dies.
      await first.close();

      // Session two: three hours later.
      final resumeAt = start.add(const Duration(hours: 3));
      final second = await SaveBootstrap(paths: paths).boot(now: resumeAt);
      addTearDown(second.close);

      final stored = await second.db.vitalsFor(profileId);
      expect(
        stored!.lastUpdate,
        start,
        reason:
            'the staged 45 seconds never reached disk — that is the '
            'accepted worst case of §11.1.1',
      );
      expect(stored.waterMl, 2800);

      // Catch up from the stored timestamp.
      final clock = GameClock(wallClock: ManualWallClock(resumeAt));
      final advance = clock.advance(stored.lastUpdate);
      expect(advance.elapsed, const Duration(hours: 3));

      final outcome = advance_(stored.lastUpdate, advance.elapsed);
      expect(
        outcome.state.lastUpdate,
        resumeAt,
        reason: 'no gap in the simulation after a crash',
      );
    });

    test('replaying the same catch-up twice lands on the same state', () async {
      final start = DateTime.utc(2026, 8, 9, 12);
      const gap = Duration(hours: 8);

      final once = advance_(start, gap);
      final twice = advance_(start, gap);

      expect(once.state.sameValues(twice.state), isTrue);
      expect(once.state.lastUpdate, twice.state.lastUpdate);
    });
  });
}

/// Runs a catch-up over the reference character.
TickOutcome advance_(DateTime from, Duration elapsed) => advanceInChunks(
  state: SimState(
    lastUpdate: from,
    bloodMl: referenceConstants.bloodMaxMl,
    waterMl: referenceConstants.waterDailyMl,
    caloriesKcal: referenceConstants.caloriesDailyKcal,
    heartRateBpm: referenceConstants.restingHeartRate,
    sleepDebtSeconds: 0,
    zone: MetabolicZone.shelter,
    rngCursor: 0,
  ),
  constants: referenceConstants,
  elapsed: elapsed,
  offline: true,
);

void _corrupt(File file) {
  final bytes = Uint8List.fromList(file.readAsBytesSync());
  for (var i = 0; i < 64 && i < bytes.length; i++) {
    bytes[i] = 0x00;
  }
  file.writeAsBytesSync(bytes, flush: true);
}
