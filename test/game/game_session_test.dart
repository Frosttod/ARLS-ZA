import 'dart:io';

import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/core/scaled_wall_clock.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/persistence/save_bootstrap.dart';
import 'package:arls_za/game/game_session.dart';
import 'package:arls_za/sim/body.dart';
import 'package:test/test.dart';

/// The composition root of §1.3: it is the only place that turns a character
/// sheet into rows on disk, and the only place that reads them back. If it
/// loses a field on the way through, the player wakes up as somebody else.
void main() {
  const spec = BodySpec(
    sex: Sex.female,
    ageYears: 34,
    heightCm: 168,
    weightKg: 62,
  );

  final t0 = DateTime.utc(2026, 8, 10, 12);

  late Directory tempDir;
  late SavePaths paths;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arls_session_');
    paths = SavePaths(tempDir);
    await paths.ensureExists();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<SaveSession> boot() {
    final clock = GameClock(
      wallClock: ScaledWallClock(base: ManualWallClock(t0)),
    );
    return SaveBootstrap(paths: paths, clock: clock).boot(now: t0);
  }

  test('a fresh install has nobody to resume', () async {
    final session = await boot();
    addTearDown(session.close);

    expect(await GameSessionFactory(session).loadActive(), isNull);
  });

  test('a created character comes back the same on the next boot', () async {
    final session = await boot();
    final created = await GameSessionFactory(
      session,
    ).create(name: 'Marta', spec: spec, deathMode: DeathMode.hardcore, now: t0);
    await session.close();

    final reopened = await boot();
    addTearDown(reopened.close);
    final loaded = await GameSessionFactory(reopened).loadActive();

    expect(loaded, isNotNull);
    expect(loaded!.profile.name, 'Marta');
    expect(loaded.profile.deathMode, DeathMode.hardcore.wire);

    // The body is derived, not stored: what has to survive is the sheet it is
    // derived from, so that Nadler and Mifflin–St Jeor land on the same
    // numbers they did in the creator (§2.1).
    expect(loaded.body.spec, created.body.spec);
    expect(loaded.constants.bloodMaxMl, created.constants.bloodMaxMl);
    expect(
      loaded.constants.caloriesDailyKcal,
      created.constants.caloriesDailyKcal,
    );
  });

  test(
    'the opening vitals are full and stamped with the creation time',
    () async {
      final session = await boot();
      addTearDown(session.close);

      final created = await GameSessionFactory(session).create(
        name: 'Marta',
        spec: spec,
        deathMode: DeathMode.softcore,
        now: t0,
      );

      expect(created.state.lastUpdate, t0);
      expect(created.state.bloodMl, created.constants.bloodMaxMl);
      expect(created.state.waterMl, created.constants.waterDailyMl);
      expect(created.state.caloriesKcal, created.constants.caloriesDailyKcal);
    },
  );

  test('the seed is drawn once and belongs to the character (§11)', () async {
    final session = await boot();
    addTearDown(session.close);

    final factory = GameSessionFactory(session);
    final first = await factory.create(
      name: 'Marta',
      spec: spec,
      deathMode: DeathMode.softcore,
      now: t0,
    );

    final reloaded = await factory.loadActive();

    expect(
      reloaded!.profile.rngSeed,
      first.profile.rngSeed,
      reason: 'a run that redraws its seed cannot be replayed',
    );
  });

  test('a release build has nothing to drive the position with yet', () {
    // Stage 3 brings the real source. Until then the honest answer is null,
    // rather than a simulator smuggled into a shipped build (§11.2).
    expect(buildPositionSource(null), isNull);
  });
}
