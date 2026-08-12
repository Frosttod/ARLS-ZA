import 'dart:io';

import 'package:arls_za/core/deterministic_rng.dart';
import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/core/scaled_wall_clock.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/persistence/save_bootstrap.dart';
import 'package:arls_za/devtools/simulated_position_source.dart';
import 'package:arls_za/game/game_loop.dart';
import 'package:arls_za/location/movement_integrity.dart';
import 'package:arls_za/location/position_source.dart';
import 'package:arls_za/location/power_source.dart';
import 'package:arls_za/safety/player_safety.dart';
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
  buildLoop({SimState? initial, PowerSource? power}) async {
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
      power: power,
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

  group('movement the game refuses to believe (§3.2, §3.4)', () {
    test('a phone lying still burns nothing but resting metabolism', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      // Standing still with the error model on — the rig runs without noise by
      // default, and a noiseless stationary source would prove nothing. The
      // reported position now wanders inside its accuracy circle all night.
      // None of that is walking.
      rig.source
        ..mode = SimMovementMode.stationary
        ..noiseEnabled = true;

      await rig.loop.start();

      // Twenty minutes at the walking cadence of 0.2 Hz. The interval matters:
      // five metres of scatter over five seconds is a metre a second, which is
      // a walk. Over a minute it is nothing, so a test that sampled slowly
      // would pass no matter what the filter did.
      for (var step = 0; step < 240; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 5));
      }
      await rig.loop.onPaused(rig.wall.nowUtc());

      final stored = await rig.session.db.vitalsFor(rig.profileId);
      final burned = constants.caloriesDailyKcal - stored!.caloriesKcal;

      // Twenty minutes of resting metabolism for this body is about 34 kcal.
      // The same twenty minutes credited as walking is three times that.
      expect(burned, lessThan(50), reason: 'GPS scatter is not exercise');
      expect(stored.speedKmh, 0);
    });

    test('a mocked provider suspends the run at once (§3.4)', () async {
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

      rig.source.reportMocked = true;
      rig.wall.advance(const Duration(minutes: 1));
      rig.source.step();
      await pump();

      final snapshot = await rig.loop.snapshots.first;
      expect(snapshot.integrity, IntegrityState.suspended);
      expect(snapshot.integrityReason, IntegrityReason.mockProvider);
    });

    test('a mocked position never reaches the simulation', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.route
        ..speedMps = SimSpeedPreset.run.mps
        ..reportMocked = true;

      await rig.loop.start();
      for (var minute = 0; minute < 10; minute++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(minutes: 1));
      }
      await rig.loop.onPaused(rig.wall.nowUtc());

      final stored = await rig.session.db.vitalsFor(rig.profileId);
      expect(
        stored!.latitude,
        isNull,
        reason: 'a fix from a mock provider must not be saved as a position',
      );
      expect(stored.speedKmh, 0);
    });

    test('a car suspends the run after half a minute (§3.4)', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.route
        // 72 km/h. Well past the 40 km/h threshold, well past any sprint.
        ..speedMps = 20;

      await rig.loop.start();
      for (var step = 0; step < 6; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 10));
      }

      final snapshot = await rig.loop.snapshots.first;
      expect(snapshot.integrity, IntegrityState.suspended);
      expect(snapshot.integrityReason, IntegrityReason.vehicleSpeed);
    });
  });

  group('sampling and the battery (§3.3)', () {
    test('walking is sampled at 0.2 Hz and standing still at 0.05', () async {
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
      for (var step = 0; step < 10; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 5));
      }
      await pump();

      expect(rig.source.currentCadence, PositionCadence.moving);

      // Stop dead. The rate should follow within a tick or two.
      rig.source.mode = SimMovementMode.stationary;
      for (var step = 0; step < 10; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 5));
      }
      await pump();

      expect(rig.source.currentCadence, PositionCadence.resting);
    });

    test('a low battery coarsens the sampling of a walk (§3.3)', () async {
      final rig = await buildLoop(
        power: const ConstantPowerSource(
          PowerState(percent: 12, charging: false),
        ),
      );
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.route
        ..speedMps = SimSpeedPreset.briskWalk.mps;

      await rig.loop.start();
      for (var step = 0; step < 10; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 5));
      }
      await pump();

      expect(
        rig.source.currentCadence,
        PositionCadence.resting,
        reason: 'a flat battery ends the session; a coarse fix only blurs it',
      );

      final snapshot = await rig.loop.snapshots.first;
      expect(snapshot.economy, isTrue);
      expect(snapshot.batteryPercent, 12);
    });

    test('a charged phone never enters economy mode', () async {
      final rig = await buildLoop(
        power: const ConstantPowerSource(
          PowerState(percent: 90, charging: false),
        ),
      );
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.route
        ..speedMps = SimSpeedPreset.briskWalk.mps;

      await rig.loop.start();
      for (var step = 0; step < 10; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 5));
      }

      final snapshot = await rig.loop.snapshots.first;
      expect(snapshot.economy, isFalse);
      expect(rig.source.currentCadence, PositionCadence.moving);
    });
  });

  group('player safety (§3.5)', () {
    test('a fight is refused above fifteen km/h', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.route
        // 25 km/h. A bicycle, not a sprint.
        ..speedMps = 7;

      await rig.loop.start();
      for (var step = 0; step < 6; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 5));
      }

      final snapshot = await rig.loop.snapshots.first;
      expect(snapshot.combatBlocked, CombatBlock.movingTooFast);
    });

    test('a fight is allowed at walking pace', () async {
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
      for (var step = 0; step < 6; step++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(seconds: 5));
      }

      final snapshot = await rig.loop.snapshots.first;
      expect(snapshot.combatBlocked, CombatBlock.none);
    });

    test('a suspended run blocks a fight even standing still', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.source
        ..mode = SimMovementMode.stationary
        ..reportMocked = true;

      await rig.loop.start();
      rig.source.step();
      await pump();

      final snapshot = await rig.loop.snapshots.first;
      expect(snapshot.combatBlocked, CombatBlock.runSuspended);
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

  group('a walk with the screen off (§3.3)', () {
    test('keeps counting while the source is still delivering fixes', () async {
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
      await rig.loop.onPaused(rig.wall.nowUtc());

      // Ten minutes of walking with the phone in a pocket, stepped in
      // one-minute pieces so no single advance looks like an unobserved gap.
      final before = rig.loop.state.caloriesKcal;
      for (var minute = 0; minute < 10; minute++) {
        rig.source.step();
        await pump();
        rig.wall.advance(const Duration(minutes: 1));
        rig.source.step();
        await pump();
        await rig.loop.onPaused(rig.wall.nowUtc());
      }

      final burned = before - rig.loop.state.caloriesKcal;
      expect(
        burned,
        greaterThan(35),
        reason: 'ten minutes of walking costs more than resting metabolism',
      );
    });

    test('an unobserved gap is offline however the source boasts', () async {
      // The simulator always claims to track in the background, and a real
      // foreground service can be killed without saying so. What settles it is
      // the size of the step: nothing observes a fortnight in one advance.
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

      expect(rig.loop.status().isIncapacitated, isFalse);
      expect(
        rig.loop.state.caloriesKcal,
        closeTo(constants.caloriesDailyKcal * 0.10, 1),
        reason: 'the offline floor of §2.1.1 still catches it',
      );
    });

    test('a source that stops at the screen makes the time offline', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.loop.setZone(MetabolicZone.shelter);
      await rig.loop.start();

      // Foreground-only permission: Android stops the stream with the screen.
      rig.source.setQuality(SimSignalQuality.none);
      await rig.loop.onPaused(rig.wall.nowUtc());

      rig.wall.advance(const Duration(hours: 20));
      await rig.loop.onResumed();

      expect(
        rig.loop.state.caloriesKcal,
        greaterThanOrEqualTo(constants.caloriesDailyKcal * 0.10 - 1),
      );
    });
  });

  group('waking up somewhere else (§16.6)', () {
    test('a journey between sessions is not credited as walking', () async {
      // The design promise: the app was shut, so nothing measured the 350 km,
      // and nothing may charge for it. This is what keeps it true.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.step();
      await pump();
      await rig.loop.onPaused(rig.wall.nowUtc());
      final before = rig.loop.state.caloriesKcal;

      // Eight hours away, and the world moved 350 km underneath them.
      rig.wall.advance(const Duration(hours: 8));
      rig.source.jumpTo(50.0647, 19.9450);
      await rig.loop.onResumed();
      rig.source.step();
      await pump();
      await rig.loop.onPaused(rig.wall.nowUtc());

      final burned = before - rig.loop.state.caloriesKcal;
      expect(
        burned,
        lessThan(900),
        reason: 'eight hours of resting metabolism, not a march to Kraków',
      );
      expect(rig.loop.state.caloriesKcal, greaterThan(0));
    });

    test('the position after the jump is the new one', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(50.0647, 19.9450);
      rig.source.step();
      await pump();

      // The clock has to move, or the tick has nothing to advance and never
      // stages a row — the hot layer writes what the tick produced (§11.1.1).
      rig.wall.advance(const Duration(minutes: 1));
      await rig.loop.onPaused(rig.wall.nowUtc());

      final stored = await rig.session.db.vitalsFor(rig.profileId);
      expect(stored!.latitude, closeTo(50.0647, 0.01));
      expect(stored.longitude, closeTo(19.9450, 0.01));
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
