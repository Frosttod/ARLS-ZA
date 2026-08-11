import 'dart:io';

import 'package:arls_za/core/deterministic_rng.dart';
import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/core/scaled_wall_clock.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/persistence/save_bootstrap.dart';
import 'package:arls_za/devtools/simulated_position_source.dart';
import 'package:arls_za/game/game_loop.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/occupation.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

/// The exit criterion of stage 2, written as a test.
///
/// The loop is the first thing that joins the three layers stages 0 and 1 left
/// standing apart: the simulated GPS produces movement, the tick turns it into
/// physiology, and the writer puts it on disk at the cadence of §11.1.1.
void main() {
  final constants = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  ).toSimConstants();

  final t0 = DateTime.utc(2026, 8, 10, 12);

  /// Lets the broadcast streams deliver. Fixes reach the loop through a
  /// StreamController, which is asynchronous by contract, so a test that steps
  /// the simulator and reads immediately would see nothing.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  late Directory tempDir;
  late SavePaths paths;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arls_loop_');
    paths = SavePaths(tempDir);
    await paths.ensureExists();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Builds a loop over a real on-disk save and a simulated GPS, both driven
  /// by a clock the test advances by hand.
  Future<
    ({
      GameLoop loop,
      SaveSession session,
      SimulatedPositionSource source,
      ManualWallClock wall,
      int profileId,
    })
  >
  buildLoop({SimState? initial}) async {
    final wall = ManualWallClock(t0);
    final scaled = ScaledWallClock(base: wall);
    final clock = GameClock(wallClock: scaled);

    final session = await SaveBootstrap(
      paths: paths,
      clock: clock,
    ).boot(now: t0);

    final profileId = await session.db.createProfile(
      profile: ProfilesCompanion.insert(
        name: 'Ocalały',
        sex: 'M',
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        deathMode: 'hardcore',
        rngSeed: 4242,
        createdAt: t0,
        isActive: const Value(true),
      ),
      vitals: (id) => VitalsCompanion.insert(
        profileId: Value(id),
        lastUpdate: t0,
        bloodMl: constants.bloodMaxMl,
        waterMl: constants.waterDailyMl,
        caloriesKcal: constants.caloriesDailyKcal,
        heartRateBpm: constants.restingHeartRate,
      ),
    );

    final source = SimulatedPositionSource(
      clock: scaled,
      rng: DeterministicRng(seed: 1),
    )..noiseEnabled = false;

    final loop = GameLoop(
      session: session,
      source: source,
      profileId: profileId,
      constants: constants,
      initialState: initial ?? SimState.fresh(at: t0, constants: constants),
      clock: clock,
    );

    return (
      loop: loop,
      session: session,
      source: source,
      wall: wall,
      profileId: profileId,
    );
  }

  group('wiring', () {
    test('a walk turns into calories on disk', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.route
        ..speedMps = SimSpeedPreset.briskWalk.mps;

      await rig.loop.start();

      // Two fixes a minute apart give the loop something to derive speed from.
      rig.source.step();
      await pump();
      rig.wall.advance(const Duration(minutes: 1));
      rig.source.step();
      await pump();
      rig.wall.advance(const Duration(minutes: 1));
      rig.source.step();
      await pump();

      // Let the loop catch up and flush.
      await rig.loop.onPaused(rig.wall.nowUtc());

      final stored = await rig.session.db.vitalsFor(rig.profileId);

      expect(stored, isNotNull);
      expect(
        stored!.caloriesKcal,
        lessThan(constants.caloriesDailyKcal),
        reason: 'two minutes of walking has to cost something',
      );
      expect(
        stored.speedKmh,
        greaterThan(0),
        reason: 'speed derived from consecutive fixes must reach the save',
      );
    });

    test('the position and its accuracy are persisted', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.step();
      await pump();
      rig.wall.advance(const Duration(seconds: 30));
      rig.source.step();
      await pump();
      await rig.loop.onPaused(rig.wall.nowUtc());

      final stored = await rig.session.db.vitalsFor(rig.profileId);

      expect(stored!.latitude, isNotNull);
      expect(stored.longitude, isNotNull);
      expect(stored.accuracyM, isNotNull);
    });

    test('a lost signal stops movement being counted (§3.2)', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.route
        ..speedMps = SimSpeedPreset.run.mps;

      await rig.loop.start();
      rig.source.step();
      await pump();
      rig.wall.advance(const Duration(minutes: 1));
      rig.source.step();
      await pump();

      // Walk into a building.
      rig.source.setQuality(SimSignalQuality.none);
      rig.wall.advance(const Duration(minutes: 30));

      await rig.loop.onPaused(rig.wall.nowUtc());
      final stored = await rig.session.db.vitalsFor(rig.profileId);

      // Half an hour of resting metabolism is roughly 51 kcal; half an hour of
      // running would be an order of magnitude more.
      final burned = constants.caloriesDailyKcal - stored!.caloriesKcal;
      expect(
        burned,
        lessThan(200),
        reason:
            'the game must not charge the player for a position it does '
            'not trust',
      );
    });
  });

  group('occupations (§2.1a)', () {
    test('starting one cancels the previous and says so', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.loop.setZone(MetabolicZone.shelter);

      final firstEnd = rig.loop.beginOccupation(
        Occupation(
          kind: OccupationKind.reading,
          startedAt: t0,
          requiredWork: const Duration(hours: 3),
        ),
      );
      expect(firstEnd, isNull);

      final secondEnd = rig.loop.beginOccupation(
        Occupation(
          kind: OccupationKind.building,
          startedAt: t0,
          requiredWork: const Duration(hours: 3),
        ),
      );

      expect(secondEnd, OccupationEndReason.replaced);
      expect(rig.loop.occupation?.kind, OccupationKind.building);
    });

    test('leaving the shelter cancels a shelter occupation', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.setZone(MetabolicZone.shelter);
      rig.loop.beginOccupation(
        Occupation(
          kind: OccupationKind.reading,
          startedAt: t0,
          requiredWork: const Duration(hours: 5),
        ),
      );

      rig.loop.setZone(MetabolicZone.open);
      rig.wall.advance(const Duration(minutes: 5));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(
        rig.loop.occupation,
        isNull,
        reason: 'reading in the street is not reading (§2.1a.4)',
      );
    });

    test('sleeping in the shelter pays down the debt', () async {
      final tired = SimState.fresh(at: t0, constants: constants).copyWith(
        zone: MetabolicZone.shelter,
        sleepDebtSeconds: const Duration(hours: 5).inSeconds,
      );

      final rig = await buildLoop(initial: tired);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.beginOccupation(
        Occupation(
          kind: OccupationKind.sleep,
          startedAt: t0,
          requiredWork: const Duration(hours: 8),
        ),
      );

      rig.wall.advance(const Duration(hours: 4));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(
        rig.loop.state.sleepDebt,
        lessThan(const Duration(hours: 5)),
        reason: 'four hours asleep must reduce a five-hour debt',
      );
    });
  });

  group('lifecycle (§11.1.1, §11.1.5)', () {
    test('pausing flushes everything to disk', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.wall.advance(const Duration(minutes: 5));

      await rig.loop.onPaused(rig.wall.nowUtc());

      final stored = await rig.session.db.vitalsFor(rig.profileId);
      expect(
        stored!.lastUpdate,
        rig.loop.state.lastUpdate,
        reason: 'onPause is the moment the process is most likely to be killed',
      );
    });

    test('the clock mark survives a pause', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.wall.advance(const Duration(hours: 2));
      await rig.loop.onPaused(rig.wall.nowUtc());

      final mark = await rig.session.db.readMetaTimestamp(
        MetaKeys.clockHighWaterMark,
      );

      expect(mark, isNotNull);
      expect(mark!.isAfter(t0), isTrue);
    });

    test('resuming catches up the time spent away', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await rig.loop.onPaused(rig.wall.nowUtc());
      final before = rig.loop.state.lastUpdate;

      rig.wall.advance(const Duration(hours: 6));
      await rig.loop.onResumed();

      expect(
        rig.loop.state.lastUpdate.difference(before),
        const Duration(hours: 6),
        reason: 'no gap in the simulation across a background spell',
      );
    });

    test('a fortnight away leaves the character alive (§2.1.1)', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.loop.setZone(MetabolicZone.shelter);
      await rig.loop.start();
      await rig.loop.onPaused(rig.wall.nowUtc());

      rig.wall.advance(const Duration(days: 14));
      await rig.loop.onResumed();

      final status = rig.loop.status();

      expect(status.isIncapacitated, isFalse);
      expect(
        rig.loop.state.caloriesKcal,
        closeTo(constants.caloriesDailyKcal * 0.10, 1),
      );
    });
  });

  group('anti-cheat (§2.1.1)', () {
    test('winding the device clock back yields no free time', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.wall.advance(const Duration(hours: 3));
      await rig.loop.onPaused(rig.wall.nowUtc());
      final honest = rig.loop.state;

      // Player winds the clock back a day and reopens the app.
      rig.wall.advance(const Duration(days: -1));
      await rig.loop.onResumed();

      expect(rig.loop.state.lastUpdate, honest.lastUpdate);
      expect(rig.loop.state.caloriesKcal, honest.caloriesKcal);
    });
  });
}

extension on GameLoop {
  SimStatus status() => statusOf(
    state: state,
    constants: BodyProfile.from(
      const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
    ).toSimConstants(),
  );
}
