import 'package:arls_za/location/movement_integrity.dart';
import 'package:test/test.dart';

/// §3.4. The rule has to be hard to trip by accident and impossible to miss on
/// purpose: a player on a bicycle keeps playing, a player in a car does not.
void main() {
  final t0 = DateTime.utc(2026, 8, 11, 12);

  double kmh(double value) => value * 1000 / 3600;

  test('a sprint is not a car', () {
    final integrity = MovementIntegrity();

    for (var second = 0; second < 300; second += 5) {
      integrity.observeSpeed(kmh(25), t0.add(Duration(seconds: second)));
    }

    expect(integrity.state, IntegrityState.ok);
  });

  test('over the threshold is suspect long before it is suspended', () {
    final integrity = MovementIntegrity();

    integrity.observeSpeed(kmh(60), t0);
    expect(integrity.state, IntegrityState.suspect);
    expect(integrity.isSuspended, isFalse);

    integrity.observeSpeed(kmh(60), t0.add(const Duration(seconds: 25)));
    expect(
      integrity.state,
      IntegrityState.suspect,
      reason: 'a single bad fix on a tram must not end the run',
    );
  });

  test('half a minute of car speed suspends the run', () {
    final integrity = MovementIntegrity();

    integrity.observeSpeed(kmh(60), t0);
    integrity.observeSpeed(kmh(60), t0.add(const Duration(seconds: 30)));

    expect(integrity.state, IntegrityState.suspended);
    expect(integrity.reason, IntegrityReason.vehicleSpeed);
  });

  test('slowing down lifts the suspension — nothing is confiscated', () {
    final integrity = MovementIntegrity();
    integrity.observeSpeed(kmh(60), t0);
    integrity.observeSpeed(kmh(60), t0.add(const Duration(seconds: 40)));
    expect(integrity.isSuspended, isTrue);

    integrity.observeSpeed(kmh(4), t0.add(const Duration(seconds: 45)));

    expect(integrity.state, IntegrityState.ok);
    expect(integrity.reason, IntegrityReason.none);
  });

  test('a gap under the threshold restarts the clock', () {
    final integrity = MovementIntegrity();

    integrity.observeSpeed(kmh(60), t0);
    integrity.observeSpeed(kmh(10), t0.add(const Duration(seconds: 20)));
    integrity.observeSpeed(kmh(60), t0.add(const Duration(seconds: 25)));
    integrity.observeSpeed(kmh(60), t0.add(const Duration(seconds: 50)));

    expect(
      integrity.state,
      IntegrityState.suspect,
      reason: 'the second burst has run for 25 s, not 50 s',
    );
  });

  group('mock provider', () {
    test('suspends immediately, with no half-minute of doubt', () {
      final integrity = MovementIntegrity();

      integrity.observeMocked(mocked: true);

      expect(integrity.state, IntegrityState.suspended);
      expect(integrity.reason, IntegrityReason.mockProvider);
    });

    test('is not forgiven by walking slowly', () {
      final integrity = MovementIntegrity();
      integrity.observeMocked(mocked: true);

      integrity.observeSpeed(kmh(4), t0);

      expect(
        integrity.isSuspended,
        isTrue,
        reason: 'only the provider going away clears a mock suspension',
      );
    });

    test('clears when the provider stops claiming mocked fixes', () {
      final integrity = MovementIntegrity();
      integrity.observeMocked(mocked: true);

      integrity.observeMocked(mocked: false);

      expect(integrity.state, IntegrityState.ok);
      expect(integrity.reason, IntegrityReason.none);
    });

    test('clearing a mock does not clear a car underneath it', () {
      final integrity = MovementIntegrity();
      integrity.observeSpeed(kmh(60), t0);
      integrity.observeMocked(mocked: true);

      integrity.observeMocked(mocked: false);

      expect(integrity.state, IntegrityState.suspect);
      expect(integrity.reason, IntegrityReason.vehicleSpeed);
    });
  });

  test('reset clears a suspension a new session has not earned', () {
    final integrity = MovementIntegrity();
    integrity.observeMocked(mocked: true);

    integrity.reset();

    expect(integrity.state, IntegrityState.ok);
    expect(integrity.reason, IntegrityReason.none);
  });
}
