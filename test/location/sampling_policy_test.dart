import 'package:arls_za/location/position_source.dart';
import 'package:arls_za/location/sampling_policy.dart';
import 'package:test/test.dart';

/// §3.3. Continuous GPS costs a quarter of a battery an hour, and a session is
/// meant to last several. The rate has to follow the character, and the battery
/// has to be able to slow it down without ever changing what the game is.
void main() {
  final t0 = DateTime.utc(2026, 8, 13, 12);

  SamplingDecision decide(
    SamplingPolicy policy, {
    required Activity activity,
    int battery = 80,
    bool charging = false,
    Duration after = Duration.zero,
  }) => policy.decide(
    activity: activity,
    batteryPercent: battery,
    charging: charging,
    at: t0.add(after),
  );

  /// Lets a wanted rate settle, so tests about *what* rate is chosen are not
  /// also tests about how long it takes.
  ///
  /// Ends at [settledAt], and anything a test does afterwards has to be later
  /// than that — the hold is measured on the clock it is handed.
  const settledAt = Duration(seconds: 61);

  SamplingDecision settled(
    SamplingPolicy policy, {
    required Activity activity,
    int battery = 80,
    bool charging = false,
  }) {
    decide(policy, activity: activity, battery: battery, charging: charging);
    return decide(
      policy,
      activity: activity,
      battery: battery,
      charging: charging,
      after: settledAt,
    );
  }

  group('the rate follows the character', () {
    test('each activity gets the rate §3.3 names for it', () {
      final policy = SamplingPolicy();

      expect(
        decide(policy, activity: Activity.combat).cadence,
        PositionCadence.combat,
      );
      expect(
        settled(policy, activity: Activity.walking).cadence,
        PositionCadence.moving,
      );
      expect(
        settled(policy, activity: Activity.standing).cadence,
        PositionCadence.resting,
      );
      expect(
        decide(policy, activity: Activity.sheltered).cadence,
        PositionCadence.sheltered,
        reason:
            'the radio is the most expensive thing on the device — but a '
            'radio that is off can never notice the door being opened',
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
        settled(policy, activity: Activity.walking, battery: 15).cadence,
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

      expect(
        settled(
          policy,
          activity: Activity.walking,
          battery: 5,
          charging: true,
        ).cadence,
        PositionCadence.moving,
      );
      expect(decision.economy, isFalse);
      expect(decision.warnLowBattery, isFalse);
    });
  });

  group('a pause at a crossing is not a change of pace (§3.3)', () {
    test('the rate is held until the new one has lasted a minute', () async {
      // Changing the rate restarts the platform's location request, and a
      // fresh request takes seconds to produce a fix. Thrashing it at every
      // kerb is what makes a walk look like a permanently weak signal.
      final policy = SamplingPolicy();
      settled(policy, activity: Activity.walking);

      expect(
        decide(
          policy,
          activity: Activity.standing,
          after: settledAt + const Duration(seconds: 20),
        ).cadence,
        PositionCadence.moving,
        reason: 'twenty seconds at a light is not standing still',
      );
      expect(
        decide(
          policy,
          activity: Activity.standing,
          after: settledAt + const Duration(seconds: 90),
        ).cadence,
        PositionCadence.resting,
      );
    });

    test('stepping off again before the hold expires changes nothing', () {
      final policy = SamplingPolicy();
      settled(policy, activity: Activity.walking);

      decide(
        policy,
        activity: Activity.standing,
        after: settledAt + const Duration(seconds: 30),
      );
      final resumed = decide(
        policy,
        activity: Activity.walking,
        after: settledAt + const Duration(seconds: 40),
      );

      expect(resumed.cadence, PositionCadence.moving);
    });

    test('speeding up is immediate — only slowing down waits', () {
      // A session opens with the first fix reported as stationary. A symmetric
      // hold would start every walk at 0.05 Hz and take a minute to notice.
      final policy = SamplingPolicy();
      settled(policy, activity: Activity.standing);

      expect(
        decide(
          policy,
          activity: Activity.walking,
          after: settledAt + const Duration(seconds: 1),
        ).cadence,
        PositionCadence.moving,
      );
    });

    test('combat is exempt in both directions (§5.2)', () {
      // Waiting a minute for the rate to catch up would be the same as not
      // having it.
      final policy = SamplingPolicy();
      settled(policy, activity: Activity.standing);

      expect(
        decide(policy, activity: Activity.combat).cadence,
        PositionCadence.combat,
      );
      expect(
        decide(
          policy,
          activity: Activity.walking,
          after: settledAt + const Duration(seconds: 1),
        ).cadence,
        PositionCadence.moving,
      );
    });

    test('going quiet for a shelter occupation is immediate', () {
      final policy = SamplingPolicy();
      settled(policy, activity: Activity.walking);

      expect(
        decide(policy, activity: Activity.sheltered).cadence,
        PositionCadence.sheltered,
      );
    });

    test('and coming back out of one is immediate as well', () {
      // ⚠️ The half that matters more. A minute of hysteresis on the way *out*
      // is a minute of a player walking down a street while the game still
      // believes they are sitting at home — which is every rule in §10.2 and
      // §5 answering the wrong question.
      final policy = SamplingPolicy();
      settled(policy, activity: Activity.sheltered);

      expect(
        decide(policy, activity: Activity.walking).cadence,
        PositionCadence.moving,
      );
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
