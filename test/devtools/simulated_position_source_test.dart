import 'package:arls_za/core/deterministic_rng.dart';
import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/core/scaled_wall_clock.dart';
import 'package:arls_za/devtools/gpx.dart';
import 'package:arls_za/devtools/simulated_position_source.dart';
import 'package:arls_za/location/position_fix.dart';
import 'package:arls_za/location/position_source.dart';
import 'package:test/test.dart';

/// The simulator has to behave like the real chip, not like an idealised one
/// (§11.2). These tests are about the ways it is allowed to be inconvenient.
void main() {
  final t0 = DateTime.utc(2026, 8, 10, 12);

  SimulatedPositionSource build({
    ManualWallClock? base,
    GpxTrack? track,
    int seed = 1,
  }) => SimulatedPositionSource(
    clock: base ?? ManualWallClock(t0),
    track: track,
    rng: DeterministicRng(seed: seed),
  );

  group('interface', () {
    test('is a PositionSource and admits to being simulated', () {
      final source = build();
      addTearDown(source.dispose);

      expect(source, isA<PositionSource>());
      expect(
        source.isSimulated,
        isTrue,
        reason: 'the HUD must be able to say the movement is fake',
      );
    });

    test('starts with no fix and an unavailable signal', () {
      final source = build();
      addTearDown(source.dispose);

      expect(source.lastFix, isNull);
      expect(source.currentSignal, PositionSignal.unavailable);
    });
  });

  group('movement', () {
    test('walking a route covers the expected ground', () async {
      final base = ManualWallClock(t0);
      final source = build(base: base)
        ..mode = SimMovementMode.route
        ..speedMps = SimSpeedPreset.walk.mps
        ..noiseEnabled = false;
      addTearDown(source.dispose);

      source.step(); // anchor
      final start = source.truth;

      base.advance(const Duration(minutes: 1));
      source.step();
      final after = source.truth;

      final startFix = PositionFix(
        latitude: start.latitude,
        longitude: start.longitude,
        accuracyM: 0,
        timestamp: t0,
      );
      final afterFix = PositionFix(
        latitude: after.latitude,
        longitude: after.longitude,
        accuracyM: 0,
        timestamp: t0,
      );

      // A minute at 1.3 m/s is 78 m; the route bends, so allow slack.
      expect(startFix.distanceTo(afterFix), closeTo(78, 6));
    });

    test('standing still does not move the true position', () {
      final base = ManualWallClock(t0);
      final source = build(base: base)..mode = SimMovementMode.stationary;
      addTearDown(source.dispose);

      source.step();
      final before = source.truth;
      base.advance(const Duration(minutes: 30));
      source.step();

      expect(source.truth.latitude, before.latitude);
      expect(source.truth.longitude, before.longitude);
    });

    test('manual steering walks along the chosen heading', () {
      final base = ManualWallClock(t0);
      final source = build(base: base)
        ..noiseEnabled = false
        ..mode = SimMovementMode.manual
        ..speedMps = 1.0;
      addTearDown(source.dispose);

      source
        ..step()
        ..steer(90); // due east
      final before = source.truth;

      base.advance(const Duration(seconds: 100));
      source.step();

      expect(
        source.truth.latitude,
        closeTo(before.latitude, 1e-6),
        reason: 'heading east should not change latitude',
      );
      expect(source.truth.longitude, greaterThan(before.longitude));
    });

    test('steering wraps the heading into 0–360', () {
      final source = build();
      addTearDown(source.dispose);

      source.steer(-30);
      expect(source.headingDeg, 330);

      source.steer(60);
      expect(source.headingDeg, 30);
    });

    test('jumpTo teleports — the one thing real GPS cannot do', () {
      final source = build();
      addTearDown(source.dispose);

      source.jumpTo(52.2297, 21.0122);

      expect(source.truth.latitude, 52.2297);
      expect(source.truth.longitude, 21.0122);
      expect(source.mode, SimMovementMode.manual);
    });

    test('time acceleration multiplies the ground covered', () {
      final base = ManualWallClock(t0);
      final scaled = ScaledWallClock(base: base, scale: TimeScale.fast);
      final source =
          SimulatedPositionSource(clock: scaled, rng: DeterministicRng(seed: 1))
            ..noiseEnabled = false
            ..mode = SimMovementMode.route
            ..speedMps = 1.0;
      addTearDown(source.dispose);

      source.step();
      base.advance(const Duration(seconds: 1)); // 60 simulated seconds
      source.step();

      // 60 m of route walked in one real second.
      expect(source.track.lengthM, greaterThan(60));
    });
  });

  group('error model (§3.2)', () {
    test('the reported position is not the true one', () {
      final base = ManualWallClock(t0);
      final source = build(base: base)..mode = SimMovementMode.stationary;
      addTearDown(source.dispose);

      source.step();
      final fix = source.lastFix!;

      expect(fix.latitude, isNot(source.truth.latitude));
      expect(
        fix.accuracyM,
        inInclusiveRange(
          SimSignalQuality.open.minAccuracyM,
          SimSignalQuality.open.maxAccuracyM,
        ),
      );
    });

    test('a stationary player still drifts', () {
      final base = ManualWallClock(t0);
      final source = build(base: base)..mode = SimMovementMode.stationary;
      addTearDown(source.dispose);

      final seen = <PositionFix>[];
      for (var i = 0; i < 20; i++) {
        source.step();
        seen.add(source.lastFix!);
        base.advance(const Duration(seconds: 5));
      }

      final spread = seen.first.distanceTo(seen.last);
      expect(
        spread,
        greaterThan(0),
        reason: 'without drift the dead-zone filter of §3.2 is untestable',
      );
    });

    test('scatter stays inside the reported accuracy circle', () {
      final base = ManualWallClock(t0);
      final source = build(base: base)..mode = SimMovementMode.stationary;
      addTearDown(source.dispose);

      for (var i = 0; i < 200; i++) {
        source.step();
        final fix = source.lastFix!;
        final truth = PositionFix(
          latitude: source.truth.latitude,
          longitude: source.truth.longitude,
          accuracyM: 0,
          timestamp: fix.timestamp,
        );
        expect(
          truth.distanceTo(fix),
          lessThanOrEqualTo(fix.accuracyM + 0.01),
          reason: 'accuracy must mean what it says',
        );
        base.advance(const Duration(seconds: 1));
      }
    });

    test('noise can be switched off to isolate a logic bug', () {
      final base = ManualWallClock(t0);
      final source = build(base: base)
        ..mode = SimMovementMode.stationary
        ..noiseEnabled = false;
      addTearDown(source.dispose);

      source.step();

      expect(source.lastFix!.latitude, source.truth.latitude);
      expect(source.lastFix!.longitude, source.truth.longitude);
    });

    test('the canyon preset produces fixes above the 25 m gate', () {
      final base = ManualWallClock(t0);
      final source = build(base: base)
        ..mode = SimMovementMode.stationary
        ..setQuality(SimSignalQuality.canyon);
      addTearDown(source.dispose);

      // What this test is named after: the gate, not the warning.
      //
      // It used to count how often the signal read "weak", which stopped
      // working once that warning was made slow on purpose — and rightly so.
      // A canyon is 20-35 m, so about half its fixes land inside the 25 m gate
      // and the other half do not. Fixes being thrown away is the thing worth
      // asserting; a player getting a good fix every other second does not
      // have a weak signal, whatever the wide ones look like.
      var wide = 0;
      for (var i = 0; i < 60; i++) {
        source.step();
        final fix = source.lastFix;
        if (fix != null && fix.accuracyM > 25) wide++;
        base.advance(const Duration(seconds: 1));
      }

      expect(
        wide,
        greaterThan(0),
        reason: 'a street canyon has to be able to defeat the accuracy gate',
      );
    });

    test('walking indoors stops the fixes and loses the signal', () {
      final base = ManualWallClock(t0);
      final source = build(base: base);
      addTearDown(source.dispose);

      source.step();
      expect(source.currentSignal, PositionSignal.good);
      final lastOutdoors = source.lastFix;

      source.setQuality(SimSignalQuality.none);
      base.advance(const Duration(seconds: 30));
      source.step();

      expect(source.currentSignal, PositionSignal.lost);
      expect(
        source.lastFix,
        same(lastOutdoors),
        reason: 'no new fix may appear while the signal is gone',
      );
    });

    test('the same seed reproduces the same noise', () {
      List<PositionFix> run(int seed) {
        final base = ManualWallClock(t0);
        final source = build(base: base, seed: seed)
          ..mode = SimMovementMode.stationary;
        final out = <PositionFix>[];
        for (var i = 0; i < 10; i++) {
          source.step();
          out.add(source.lastFix!);
          base.advance(const Duration(seconds: 1));
        }
        source.dispose();
        return out;
      }

      final a = run(4242);
      final b = run(4242);
      final c = run(9999);

      for (var i = 0; i < a.length; i++) {
        expect(a[i].latitude, b[i].latitude);
        expect(a[i].accuracyM, b[i].accuracyM);
      }
      expect(a.first.latitude, isNot(c.first.latitude));
    });
  });

  group('cadence', () {
    test('shelter occupations turn the source off entirely', () async {
      final source = build();
      addTearDown(source.dispose);

      await source.start(cadence: PositionCadence.off);

      expect(
        source.currentSignal,
        PositionSignal.unavailable,
        reason: 'GPS off during shelter work is a battery decision (§2.1a.4)',
      );
    });

    test('stop marks the source unavailable', () async {
      final source = build();
      addTearDown(source.dispose);

      source.step();
      await source.stop();

      expect(source.currentSignal, PositionSignal.unavailable);
    });
  });
}
