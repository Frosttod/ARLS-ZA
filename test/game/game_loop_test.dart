import 'dart:io';

import 'package:arls_za/core/deterministic_rng.dart';
import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/core/scaled_wall_clock.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/persistence/save_bootstrap.dart';
import 'package:arls_za/devtools/simulated_position_source.dart';
import 'package:arls_za/game/game_loop.dart';
import 'package:arls_za/game/game_session.dart';
import 'package:arls_za/sim/death.dart';
import 'package:arls_za/sim/physiology.dart';
import 'package:arls_za/location/movement_integrity.dart';
import 'package:arls_za/location/position_source.dart';
import 'package:arls_za/location/power_source.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
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

  /// Two in the morning in Poznań, which §2.5.1 calls night by the sun rather
  /// than by a clock rule.
  final midnight = DateTime.utc(2026, 8, 10, 0, 30);

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
  buildLoop({SimState? initial, PowerSource? power, DateTime? startAt}) async {
    final wall = ManualWallClock(startAt ?? t0);
    final scaled = ScaledWallClock(base: wall);
    final clock = GameClock(wallClock: scaled);

    final session = await SaveBootstrap(
      paths: paths,
      clock: clock,
    ).boot(now: startAt ?? t0);

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
      initialState:
          initial ?? SimState.fresh(at: t0, constants: constants, massKg: 80),
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

      // Stop dead. Slowing down is held for a minute on purpose — a pause at
      // a crossing must not restart the platform's location request — so this
      // has to stand still for longer than that before the rate follows.
      rig.source.mode = SimMovementMode.stationary;
      for (var step = 0; step < 20; step++) {
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

    test('sleeping under a roof at night pays the debt down (§2.5.1)', () async {
      // Nobody presses anything. Sleep is the default state of somebody who is
      // in their shelter in the dark with nothing else on — which is exactly
      // what a phone on a bedside table has actually done.
      final tired = SimState.fresh(
        at: midnight,
        constants: constants,
        massKg: 80,
      ).copyWith(sleepDebtSeconds: const Duration(hours: 5).inSeconds);

      final rig = await buildLoop(initial: tired, startAt: midnight);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: midnight.subtract(const Duration(days: 1)),
          buildTime: kShelterBuildTime,
        ),
      ]);

      expect(rig.loop.state.zone, MetabolicZone.sleep);

      rig.wall.advance(const Duration(hours: 4));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(
        rig.loop.state.sleepDebt,
        lessThan(const Duration(hours: 5)),
        reason: 'four hours asleep must reduce a five-hour debt',
      );
    });

    test('a night spent at home after the app died in the street', () async {
      // ⚠️ **Zgłoszone z terenu: „noc 100% w schronie, a dług senny został".**
      // Gracz wyszedł ze schronu wieczorem, aplikacja zgasła na ulicy, wrócił
      // do domu i przespał noc z telefonem na szafce. Odtworzenie przerwy brało
      // **ostatnią zapisaną pozycję** — czyli tę ulicę — więc osiem godzin snu
      // wracało jako osiem godzin czuwania na dworze i dług rósł zamiast maleć.
      //
      // Pozycja sprzed ośmiu godzin nie mówi nic o tym, gdzie postać jest
      // teraz. Pierwszy świeży odczyt mówi, i to on rozstrzyga.
      final tired = SimState.fresh(
        at: midnight,
        constants: constants,
        massKg: 80,
      ).copyWith(sleepDebtSeconds: const Duration(hours: 9).inSeconds);

      final rig = await buildLoop(initial: tired, startAt: midnight);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: midnight.subtract(const Duration(days: 1)),
          buildTime: kShelterBuildTime,
        ),
      ]);

      // Ostatnie, co gra widziała: gracz dwieście metrów od domu, na ulicy.
      rig.loop.setStandingAt(const GeoPoint(52.4082, 16.9252));

      rig.wall.advance(const Duration(hours: 8));
      await rig.loop.start();

      // I dopiero teraz odbiornik łapie pierwszy odczyt — z sypialni.
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      // Przerwa dolicza się na najbliższym ticku.
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(
        rig.loop.state.sleepDebt,
        lessThan(const Duration(hours: 2)),
        reason: 'osiem godzin w schronie spłaca dziewięciogodzinny dług',
      );
    });

    test('but a fix that is still in the street corrects nothing', () async {
      // ⚠️ Poprawka jest odpowiedzią na „wróciłem do domu", nie amnestią dla
      // każdego, kto wyłączył aplikację. Kto rano stoi tam, gdzie stał
      // wieczorem, ten spędził tę noc na dworze i tak ma to policzone.
      final tired = SimState.fresh(
        at: midnight,
        constants: constants,
        massKg: 80,
      ).copyWith(sleepDebtSeconds: const Duration(hours: 9).inSeconds);

      final rig = await buildLoop(initial: tired, startAt: midnight);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: midnight.subtract(const Duration(days: 1)),
          buildTime: kShelterBuildTime,
        ),
      ]);
      rig.loop.setStandingAt(const GeoPoint(52.4082, 16.9252));

      rig.wall.advance(const Duration(hours: 8));
      await rig.loop.start();

      // Dwieście metrów od domu, czyli tam, gdzie był wieczorem.
      rig.source.jumpTo(52.4082, 16.9252);
      rig.source.step();
      await pump();

      // Przerwa dolicza się na najbliższym ticku.
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(
        rig.loop.state.sleepDebt,
        greaterThan(const Duration(hours: 9)),
        reason: 'noc na dworze nie spłaca długu, tylko go powiększa',
      );
    });

    test(
      'a night replayed on waking is a night asleep, not a night out',
      () async {
        // ⚠️ Reported from a walk: "after a night in the shelter the sleep debt
        // grew to over thirteen hours instead of falling". It did. start()
        // replays the whole gap since the save was written (§11.1.2), and the
        // interface told the loop about the shelter two awaits *later* — so the
        // night was replayed by a loop that believed the character was standing
        // outdoors, awake.
        final tired = SimState.fresh(
          at: midnight,
          constants: constants,
          massKg: 80,
        ).copyWith(sleepDebtSeconds: const Duration(hours: 9).inSeconds);

        final rig = await buildLoop(initial: tired, startAt: midnight);
        addTearDown(() async {
          await rig.loop.dispose();
          await rig.source.dispose();
          await rig.session.close();
        });

        // Everything the loop needs, before the replay — which is the fix.
        rig.loop.setShelters([
          Shelter(
            id: 1,
            kind: ShelterKind.main,
            position: const GeoPoint(52.4064, 16.9252),
            startedAt: midnight.subtract(const Duration(days: 1)),
            buildTime: kShelterBuildTime,
          ),
        ]);
        rig.loop.setStandingAt(const GeoPoint(52.4064, 16.9252));

        await rig.loop.start();

        // Eight hours with the app shut, exactly as a night is.
        rig.wall.advance(const Duration(hours: 8));
        await rig.loop.onPaused(rig.wall.nowUtc());

        expect(
          rig.loop.state.sleepDebt,
          lessThan(const Duration(hours: 9)),
          reason: 'a night under a roof pays the debt down, it does not add',
        );
      },
    );

    test('minute by minute, exactly as the app ticks it', () async {
      // ⚠️ Reported three times from a walk: sitting in a shelter with the app
      // open and nothing running, and the sleep bar not moving. The existing
      // test advances the clock in one jump and passes, so whatever is wrong
      // is in the stepping rather than in the arithmetic.
      final tired = SimState.fresh(
        at: t0,
        constants: constants,
        massKg: 80,
      ).copyWith(sleepDebtSeconds: const Duration(hours: 5).inSeconds);

      final rig = await buildLoop(initial: tired, startAt: t0);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: t0.subtract(const Duration(days: 1)),
          buildTime: kShelterBuildTime,
        ),
      ]);
      rig.loop.setStandingAt(const GeoPoint(52.4064, 16.9252));

      // Thirty minutes, a minute at a time, with the receiver quiet — which
      // is what §2.1a.4 does under a roof.
      for (var i = 0; i < 30; i++) {
        rig.wall.advance(const Duration(minutes: 1));
        await rig.loop.onPaused(rig.wall.nowUtc());
      }

      expect(rig.loop.state.zone, MetabolicZone.sleep);
      expect(
        rig.loop.state.sleepDebt,
        lessThan(const Duration(hours: 5)),
        reason: 'thirty quiet minutes under a roof must pay something down',
      );
    });

    test('and ten quiet minutes in the daytime do the same (§2.5.1)', () async {
      // The other half of §2.5.1, and the one reported broken from a walk:
      // somebody sitting in their own shelter at noon with nothing on is not
      // "awake and idle", they are asleep in a chair.
      final tired = SimState.fresh(
        at: t0,
        constants: constants,
        massKg: 80,
      ).copyWith(sleepDebtSeconds: const Duration(hours: 5).inSeconds);

      final rig = await buildLoop(initial: tired, startAt: t0);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: t0.subtract(const Duration(days: 1)),
          buildTime: kShelterBuildTime,
        ),
      ]);

      // Not yet: the ten minutes have not passed.
      expect(rig.loop.state.zone, MetabolicZone.shelter);

      final before = rig.loop.state.sleepDebt;

      rig.wall.advance(const Duration(hours: 4));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.zone, MetabolicZone.sleep);
      expect(
        rig.loop.state.sleepDebt,
        lessThan(before),
        reason: 'four quiet hours under a roof must pay some of it down',
      );
    });

    test(
      'and reading at midnight is reading, not sleeping (§2.1a.1)',
      () async {
        // Something the player deliberately started outranks the default state.
        final rig = await buildLoop(
          initial: SimState.fresh(
            at: midnight,
            constants: constants,
            massKg: 80,
          ),
          startAt: midnight,
        );
        addTearDown(() async {
          await rig.loop.dispose();
          await rig.source.dispose();
          await rig.session.close();
        });

        await rig.loop.start();
        rig.source.jumpTo(52.4064, 16.9252);
        rig.source.step();
        await pump();

        rig.loop.beginOccupation(
          Occupation(
            kind: OccupationKind.reading,
            startedAt: midnight,
            requiredWork: const Duration(hours: 3),
          ),
        );
        rig.loop.setShelters([
          Shelter(
            id: 1,
            kind: ShelterKind.main,
            position: const GeoPoint(52.4064, 16.9252),
            startedAt: midnight.subtract(const Duration(days: 1)),
            buildTime: kShelterBuildTime,
          ),
        ]);

        expect(rig.loop.state.zone, MetabolicZone.shelter);
      },
    );

    test('a half-built shelter keeps nothing out (§8.3)', () async {
      final rig = await buildLoop(
        initial: SimState.fresh(at: midnight, constants: constants, massKg: 80),
        startAt: midnight,
      );
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: midnight,
          buildTime: kShelterBuildTime,
        ),
      ]);

      expect(rig.loop.state.zone, MetabolicZone.open);
      expect(rig.loop.insideShelter, isNull);
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

    test(
      'a drink absorbs while the app is closed, not only while open (§2.2)',
      () async {
        // ⚠️ Zgłoszenie: „po dwudziestu minutach woda powinna już być
        // wchłonięta". Dwadzieścia pięć mililitrów na minutę (§2.2) razy
        // dwadzieścia minut to dokładnie pięćset — cała butelka. Test świadomie
        // sprawdza to zamkniętą aplikacją, bo to jest cała treść zgłoszenia:
        // nie „czy wchłanianie działa", tylko „czy działa, gdy nikt nie patrzy".
        final thirsty = SimState.fresh(
          at: t0,
          constants: constants,
          massKg: 80,
        ).copyWith(waterMl: constants.waterDailyMl - 1000);

        final rig = await buildLoop(initial: thirsty);
        addTearDown(() async {
          await rig.loop.dispose();
          await rig.source.dispose();
          await rig.session.close();
        });

        await rig.loop.start();
        final before = rig.loop.state.waterMl;

        // Wypija butelkę — trafia do żołądka, nie od razu do bilansu.
        rig.loop.applyUse(waterMl: 500);
        expect(rig.loop.state.pendingWaterMl, 500);
        expect(
          rig.loop.state.waterMl,
          before,
          reason: 'jeszcze nic nie wchłonięte w chwili wypicia',
        );

        // Zamyka aplikację na dwadzieścia minut.
        await rig.loop.onPaused(rig.wall.nowUtc());
        rig.wall.advance(const Duration(minutes: 20));
        await rig.loop.onResumed();

        expect(
          rig.loop.state.pendingWaterMl,
          0,
          reason: 'dwadzieścia minut przy 25 ml/min to cała butelka',
        );
        // Nie dokładnie +500: te same dwadzieścia minut to też dwadzieścia
        // minut normalnego bilansu podstawowego (§2.1), który i tak by
        // upłynął, z aplikacją otwartą czy nie. Wchłonięcie liczy się na to
        // samo konto, nie osobno — stąd „prawie +500", a nie „dokładnie".
        expect(
          rig.loop.state.waterMl,
          greaterThan(before + 460),
          reason:
              'wchłanianie liczy się przy zamkniętej aplikacji, nie tylko '
              'przy otwartej',
        );
      },
    );

    test('a big meal is still absorbing after twenty minutes, and that is '
        'correct (§2.2)', () async {
      // ⚠️ **Nie każde „jeszcze nie w pełni" jest usterką.** Osiemset
      // kilokalorii przy ośmiu na minutę to sto minut do wchłonięcia —
      // dwadzieścia minut daje sto sześćdziesiąt, nie osiemset. To jest
      // model, nie błąd: §4.7 mówi wprost, że wielki posiłek to coś, co
      // się je przed potrzebą, a nie w jej trakcie.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.applyUse(kcal: 800);

      await rig.loop.onPaused(rig.wall.nowUtc());
      rig.wall.advance(const Duration(minutes: 20));
      await rig.loop.onResumed();

      expect(rig.loop.state.pendingKcal, closeTo(640, 1));
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

    test('a night asleep is paid off across a closed app (§2.5.1)', () async {
      // The field report: "ostatnia akcja to Sen 18:39" and the game comes
      // back holding the same figure. §2.1a.3 says a shelter occupation ticks
      // with the app shut, and sleep is the default one of them — so the whole
      // of a night away has to arrive already slept.
      // Six hours owed, and the phone goes in a drawer for eight of night.
      final tired = SimState.fresh(
        at: midnight,
        constants: constants,
        massKg: 80,
      ).copyWith(sleepDebtSeconds: const Duration(hours: 6).inSeconds);

      final rig = await buildLoop(initial: tired, startAt: midnight);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();

      // In their own doorway, in the dark: §2.5.1's conditions, met.
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();
      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: midnight.subtract(const Duration(days: 1)),
          buildTime: kShelterBuildTime,
          buildLeft: Duration.zero,
        ),
      ]);
      expect(rig.loop.state.zone, MetabolicZone.sleep);

      await rig.loop.onPaused(rig.wall.nowUtc());

      rig.wall.advance(const Duration(hours: 8));
      await rig.loop.onResumed();

      expect(
        rig.loop.state.sleepDebt,
        Duration.zero,
        reason: 'eight hours of night pays off six hours of debt',
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

  group('a wound is open until something closes it (§2.6)', () {
    test('a bite starts a bleed the tick can see', () async {
      // Found on a phone: the loop still had `bleedTier: none` hard-wired from
      // before stage 5, so a character came out of a fight at 40% blood with
      // nothing bleeding — and every bandage in the pack refused, because
      // there was nothing to treat.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.applyWound(200, bleeding: BleedTier.moderate);

      expect(rig.loop.bleeding, BleedTier.moderate);

      final before = rig.loop.state.bloodMl;
      rig.wall.advance(const Duration(minutes: 10));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(
        rig.loop.state.bloodMl,
        lessThan(before),
        reason: 'twenty-five millilitres a minute has to actually leave',
      );
    });

    test('a dressing takes it down to what it can handle', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.applyWound(200, bleeding: BleedTier.severe);
      rig.loop.treatBleeding(BleedTier.superficial);

      expect(rig.loop.bleeding, BleedTier.superficial);
    });

    test('and never upwards — a bandage cannot make it worse', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.applyWound(50, bleeding: BleedTier.superficial);
      rig.loop.treatBleeding(BleedTier.moderate);

      expect(rig.loop.bleeding, BleedTier.superficial);
    });

    test('the worse of two wounds is the one that counts', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.applyWound(50, bleeding: BleedTier.moderate);
      rig.loop.applyWound(50, bleeding: BleedTier.superficial);

      expect(rig.loop.bleeding, BleedTier.moderate);
    });

    test('and it is still open after the app is closed', () async {
      // A bleed that ends every time somebody locks the screen is not a bleed.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.loop.applyWound(200, bleeding: BleedTier.moderate);
      await rig.loop.onPaused(rig.wall.nowUtc());
      await rig.loop.dispose();

      final reopened = await GameSessionFactory(rig.session).loadActive();
      expect(reopened?.bleeding, BleedTier.moderate);
    });
  });

  group('when the body gives out (§9)', () {
    // Found in the field: a character with no blood left went on looting shops
    // while a Walker chewed on them. Nothing had ever asked whether they were
    // alive, so nothing behaved as though they were not.
    test('softcore goes down rather than dying', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.applyWound(constants.bloodMaxMl * 0.5);
      rig.wall.advance(const Duration(seconds: 5));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.down, DownState.unconscious);
      expect(rig.loop.canAct, isFalse);
      expect(rig.loop.deathCause, DeathCause.bloodLoss);
    });

    test('and comes round an hour later, badly off (§9.2)', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.applyWound(constants.bloodMaxMl * 0.5);
      rig.wall.advance(const Duration(seconds: 5));
      await rig.loop.onPaused(rig.wall.nowUtc());

      rig.wall.advance(const Duration(minutes: 61));
      await rig.loop.onResumed();
      rig.source.step();
      await pump();
      await rig.loop.onPaused(rig.wall.nowUtc());

      // §9.2: up, and still being taken for dead for another ten minutes.
      expect(rig.loop.down, DownState.grace);
      expect(rig.loop.canAct, isTrue);
      expect(rig.loop.state.bloodMl / constants.bloodMaxMl, greaterThan(0.2));
    });

    test('nothing dies asleep (§9.1)', () async {
      // Permadeath caused by a phone on a bedside table is a one-star review.
      final rig = await buildLoop(
        initial: SimState.fresh(at: midnight, constants: constants, massKg: 80),
        startAt: midnight,
      );
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.setShelters([
        Shelter(
          id: 1,
          kind: ShelterKind.main,
          position: const GeoPoint(52.4064, 16.9252),
          startedAt: midnight.subtract(const Duration(days: 1)),
          buildTime: kShelterBuildTime,
          buildLeft: Duration.zero,
        ),
      ]);
      expect(rig.loop.state.zone, MetabolicZone.sleep);

      rig.loop.applyWound(constants.bloodMaxMl * 0.6);
      rig.wall.advance(const Duration(seconds: 5));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.down, DownState.none);
    });

    test('and nobody wakes up twice from one blackout (§9.2)', () async {
      // Found on a phone, and it corrupted the save: "already woken" was a
      // flag in memory, so reopening the app ran the waking again — back to a
      // quarter of the blood, the caches announced a second time, and the meal
      // eaten in between simply undone.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.applyWound(constants.bloodMaxMl * 0.5);
      rig.wall.advance(const Duration(seconds: 5));
      await rig.loop.onPaused(rig.wall.nowUtc());

      rig.wall.advance(const Duration(minutes: 61));
      await rig.loop.onResumed();
      rig.source.step();
      await pump();
      await rig.loop.onPaused(rig.wall.nowUtc());

      // Awake, and now eating: the reserves climb.
      rig.loop.applyUse(kcal: 800, waterMl: 900);
      rig.wall.advance(const Duration(minutes: 30));
      await rig.loop.onPaused(rig.wall.nowUtc());

      final fed = rig.loop.state.waterMl;
      expect(fed, greaterThan(constants.waterDailyMl * 0.15));
      await rig.loop.dispose();

      // The process dies and comes back.
      final reopened = await GameSessionFactory(rig.session).loadActive();
      expect(reopened, isNotNull);
      expect(reopened!.downUntil, isNull, reason: 'the hour is over');
      expect(
        reopened.state.waterMl,
        closeTo(fed, 1),
        reason: 'the meal is not undone by opening the app',
      );
    });

    test('and the hour survives the app being closed', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();

      rig.loop.applyWound(constants.bloodMaxMl * 0.5);
      rig.wall.advance(const Duration(seconds: 5));
      await rig.loop.onPaused(rig.wall.nowUtc());
      await rig.loop.dispose();

      final reopened = await GameSessionFactory(rig.session).loadActive();
      expect(reopened?.downUntil, isNotNull);
    });
  });

  group('settling in by daylight (§2.5.1)', () {
    Shelter home() => Shelter(
      id: 1,
      kind: ShelterKind.main,
      position: const GeoPoint(52.4064, 16.9252),
      startedAt: t0.subtract(const Duration(days: 1)),
      buildTime: kShelterBuildTime,
      buildLeft: Duration.zero,
    );

    /// Puts the player in their own doorway. The simulator walks a route when
    /// it is stepped, so a test about standing still steps it once and then
    /// leaves it alone.
    Future<void> arrive(
      ({GameLoop loop, SimulatedPositionSource source, dynamic wall}) rig,
    ) async {
      rig.source.jumpTo(52.4064, 16.9252);
      rig.source.step();
      await pump();
      rig.loop.setShelters([home()]);
    }

    test('ten minutes of nothing under a roof is sleep', () async {
      // Sitting in your own shelter doing nothing at all since before the news
      // started is not "awake and idle" — it is asleep in a chair. Noon, so
      // nothing here can be the night rule doing the work.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await arrive((loop: rig.loop, source: rig.source, wall: rig.wall));

      expect(rig.loop.state.zone, MetabolicZone.shelter);

      rig.wall.advance(const Duration(minutes: 11));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.zone, MetabolicZone.sleep);
    });

    test('and it pays the debt down', () async {
      final tired = SimState.fresh(
        at: t0,
        constants: constants,
        massKg: 80,
      ).copyWith(sleepDebtSeconds: const Duration(hours: 5).inSeconds);

      final rig = await buildLoop(initial: tired);
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await arrive((loop: rig.loop, source: rig.source, wall: rig.wall));

      rig.wall.advance(const Duration(minutes: 11));
      await rig.loop.onPaused(rig.wall.nowUtc());

      final settled = rig.loop.state.sleepDebt;
      rig.wall.advance(const Duration(hours: 2));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.sleepDebt, lessThan(settled));
    });

    test('anything the player starts wakes them up (§2.1a.1)', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await arrive((loop: rig.loop, source: rig.source, wall: rig.wall));

      rig.wall.advance(const Duration(minutes: 11));
      await rig.loop.onPaused(rig.wall.nowUtc());
      expect(rig.loop.state.zone, MetabolicZone.sleep);

      rig.loop.beginOccupation(
        Occupation(
          kind: OccupationKind.building,
          startedAt: rig.wall.nowUtc(),
          requiredWork: const Duration(hours: 3),
        ),
      );
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.zone, MetabolicZone.shelter);
    });

    test(
      'and sleep comes back the moment the meal is over, at night',
      () async {
        // Found on a phone: eating at two in the morning stopped the sleep and
        // it never came back. Night is §2.5.1's own condition and has no ten
        // minutes attached to it — swallowing should put them straight back.
        final rig = await buildLoop(
          initial: SimState.fresh(
            at: midnight,
            constants: constants,
            massKg: 80,
          ),
          startAt: midnight,
        );
        addTearDown(() async {
          await rig.loop.dispose();
          await rig.source.dispose();
          await rig.session.close();
        });

        await rig.loop.start();
        rig.source.jumpTo(52.4064, 16.9252);
        rig.source.step();
        await pump();
        rig.loop.setShelters([
          Shelter(
            id: 1,
            kind: ShelterKind.main,
            position: const GeoPoint(52.4064, 16.9252),
            startedAt: midnight.subtract(const Duration(days: 1)),
            buildTime: kShelterBuildTime,
            buildLeft: Duration.zero,
          ),
        ]);
        expect(rig.loop.state.zone, MetabolicZone.sleep);

        rig.loop.setActing(acting: true);
        expect(rig.loop.state.zone, MetabolicZone.shelter);

        rig.loop.setActing(acting: false);
        expect(
          rig.loop.state.zone,
          MetabolicZone.sleep,
          reason: 'night needs no ten minutes',
        );
      },
    );

    test('and so does long work, for as long as it runs (§18.6)', () async {
      // ⚠️ Reported from the field: "robię demontaż i widzę + przy poziomie
      // snu". §4.7's five-minute guard on [setActing] exists so a stuck flag
      // cannot keep somebody awake for ever — and a dismantling runs half an
      // hour by design, so the guard turned a character at their own vice into
      // a character asleep in front of it, paying off sleep debt while it
      // turned. Long work is reported separately and is not guarded, because
      // the interface recomputes it from live state on every tick.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await arrive((loop: rig.loop, source: rig.source, wall: rig.wall));
      rig.loop.setWorking(working: true);

      rig.wall.advance(const Duration(minutes: 40));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(
        rig.loop.state.zone,
        MetabolicZone.shelter,
        reason: 'forty minutes at a vice is not a nap',
      );

      rig.loop.setWorking(working: false);
      rig.wall.advance(const Duration(minutes: 11));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.zone, MetabolicZone.sleep);
    });

    test('a shelter slows the receiver and never stops it (§2.1a.4)', () async {
      // ⚠️ **The deadlock reported from a walk.** §2.1a.4 asks for the radio
      // to stop while a character stands still under their own roof, and it
      // was taken literally. But the zone is decided *from* the position: with
      // the receiver off no fix ever arrived, nothing could observe the player
      // leaving, the cadence stayed off and the pin sat on the shelter for the
      // rest of the session. Opening the door could not fix it, because
      // opening the door is a thing only a fix can report.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await arrive((loop: rig.loop, source: rig.source, wall: rig.wall));

      rig.wall.advance(const Duration(minutes: 1));
      rig.source.step();
      await pump();

      expect(rig.loop.state.zone.isSheltered, isTrue);
      expect(
        rig.source.currentCadence,
        PositionCadence.sheltered,
        reason: 'slow, and never off - off is a door nobody can walk out of',
      );
      expect(
        rig.source.currentCadence.interval,
        greaterThan(Duration.zero),
        reason: 'a radio that is off can never notice the door being opened',
      );
    });

    test('a short action keeps them awake too (§2.1a.2)', () async {
      // Somebody halfway through a bandage is not somebody who has been
      // sitting in a chair doing nothing. Actions live in the interface, so
      // the loop has to be told about them.
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await arrive((loop: rig.loop, source: rig.source, wall: rig.wall));
      rig.loop.setActing(acting: true);

      rig.wall.advance(const Duration(minutes: 11));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.zone, MetabolicZone.shelter);

      // And the ten minutes begin again once it is finished, rather than the
      // character dropping off the moment they swallow.
      rig.loop.setActing(acting: false);
      expect(rig.loop.state.zone, MetabolicZone.shelter);

      rig.wall.advance(const Duration(minutes: 11));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.zone, MetabolicZone.sleep);
    });

    test('and being out of the zone starts the ten minutes again', () async {
      final rig = await buildLoop();
      addTearDown(() async {
        await rig.loop.dispose();
        await rig.source.dispose();
        await rig.session.close();
      });

      await rig.loop.start();
      await arrive((loop: rig.loop, source: rig.source, wall: rig.wall));

      rig.wall.advance(const Duration(minutes: 6));
      await rig.loop.onPaused(rig.wall.nowUtc());

      // Out of any zone and back into one: the clock does not carry over.
      rig.loop.setShelters(const []);
      expect(rig.loop.state.zone, MetabolicZone.open);
      rig.loop.setShelters([home()]);

      rig.wall.advance(const Duration(minutes: 6));
      await rig.loop.onPaused(rig.wall.nowUtc());

      expect(rig.loop.state.zone, MetabolicZone.shelter);
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
