import 'package:arls_za/location/position_source.dart';
import 'package:arls_za/location/sampling_policy.dart';
import 'package:test/test.dart';

/// §3.3. Continuous GPS costs a quarter of a battery an hour, and a session is
/// meant to last several. The rate has to follow the character, and the battery
/// has to be able to slow it down without ever changing what the game is.
void main() {
  SamplingDecision decide(
    SamplingPolicy policy, {
    required Activity activity,
    int battery = 80,
    bool charging = false,
  }) => policy.decide(
    activity: activity,
    batteryPercent: battery,
    charging: charging,
  );

  group('the rate follows the character', () {
    test('each activity gets the rate §3.3 names for it', () {
      final policy = SamplingPolicy();

      expect(
        decide(policy, activity: Activity.combat).cadence,
        PositionCadence.combat,
      );
      expect(
        decide(policy, activity: Activity.walking).cadence,
        PositionCadence.moving,
      );
      expect(
        decide(policy, activity: Activity.standing).cadence,
        PositionCadence.resting,
      );
      expect(
        decide(policy, activity: Activity.sheltered).cadence,
        PositionCadence.off,
        reason: 'the radio is the most expensive thing on the device',
      );
    });

    test('a pause at a kerb is not the end of walking', () {
      // Deliberately a lower bar than the stationary test in FixFilter: that
      // one decides what to credit, this one decides what to listen for. Miss
      // the restart and the first minutes of walking arrive at 0.05 Hz.
      expect(
        activityFrom(inCombat: false, sheltered: false, speedKmh: 0.8),
        Activity.walking,
      );
      expect(
        activityFrom(inCombat: false, sheltered: false, speedKmh: 0),
        Activity.standing,
      );
    });

    test('combat outranks everything, including the shelter', () {
      expect(
        activityFrom(inCombat: true, sheltered: true, speedKmh: 0),
        Activity.combat,
      );
    });
  });

  group('a battery that is running out', () {
    test('coarsens walking but never touches combat (§5.2)', () {
      final policy = SamplingPolicy();

      expect(
        decide(policy, activity: Activity.walking, battery: 15).cadence,
        PositionCadence.resting,
      );
      expect(
        decide(policy, activity: Activity.combat, battery: 15).cadence,
        PositionCadence.combat,
        reason: 'dying because the game was saving power is being cheated',
      );
    });

    test('turns on economy rendering as well as slower fixes', () {
      final policy = SamplingPolicy();

      expect(
        decide(policy, activity: Activity.walking, battery: 15).economy,
        isTrue,
      );
      expect(
        decide(policy, activity: Activity.walking, battery: 80).economy,
        isFalse,
      );
    });

    test('a charging phone is not a low battery', () {
      final policy = SamplingPolicy();

      final decision = decide(
        policy,
        activity: Activity.walking,
        battery: 5,
        charging: true,
      );

      expect(decision.cadence, PositionCadence.moving);
      expect(decision.economy, isFalse);
      expect(decision.warnLowBattery, isFalse);
    });
  });

  group('the warning', () {
    test('is given once on the crossing, not on every fix', () {
      final policy = SamplingPolicy();

      expect(
        decide(policy, activity: Activity.walking, battery: 19).warnLowBattery,
        isTrue,
      );
      for (var i = 0; i < 20; i++) {
        expect(
          decide(
            policy,
            activity: Activity.walking,
            battery: 18,
          ).warnLowBattery,
          isFalse,
          reason: 'a warning repeated every second is one nobody reads',
        );
      }
    });

    test('comes back after the phone has been charged', () {
      final policy = SamplingPolicy();
      decide(policy, activity: Activity.walking, battery: 15);

      decide(policy, activity: Activity.walking, battery: 90);

      expect(
        decide(policy, activity: Activity.walking, battery: 15).warnLowBattery,
        isTrue,
      );
    });

    test('fires exactly at the threshold §3.3 names', () {
      expect(
        decide(
          SamplingPolicy(),
          activity: Activity.walking,
          battery: kLowBatteryPercent,
        ).warnLowBattery,
        isTrue,
      );
      expect(
        decide(
          SamplingPolicy(),
          activity: Activity.walking,
          battery: kLowBatteryPercent + 1,
        ).warnLowBattery,
        isFalse,
      );
    });
  });
}
