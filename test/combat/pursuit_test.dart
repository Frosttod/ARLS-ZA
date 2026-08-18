import 'package:arls_za/combat/pursuit.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// POŚCIG PRZERWANY WYJŚCIEM Z GRY (§5.6.2, §6.1a).
///
/// The hole this closes: closing the app was a perfect escape from anything.
/// Fire into a crowd, kill the process, come back to an empty street. Nothing
/// in §5 costs anything if the way out is free.
///
/// The enemies themselves are still never written down — §6.4 remakes the
/// population every run, and a Walker on disk would be yesterday's Walker on a
/// street the player has already left. What is written down is the *fight*:
/// when, where, and how many.
void main() {
  const square = GeoPoint(52.4064, 16.9252);
  final t0 = DateTime.utc(2026, 8, 16, 12);

  Pursuit hunt({int engaged = 4, DateTime? at}) =>
      stirredUp(at: square, now: at ?? t0, engaged: engaged);

  group('what is written down', () {
    test('the place, the moment and the number', () {
      final left = hunt();

      expect(left.at, square);
      expect(left.count, 4);
      expect(left.until, t0.add(kHuntLasts));
    });

    test('and never more than a handful', () {
      // §5.5.6 allows eight active. Putting eight back on somebody opening the
      // app is not a warning, it is a sentence.
      expect(hunt(engaged: 12).count, 6);
    });

    test('a quiet street writes nothing worth resuming', () {
      expect(hunt(engaged: 0).isWarmAt(t0), isFalse);
    });
  });

  group('how long it stays their problem', () {
    test('a quarter of an hour', () {
      expect(hunt().isWarmAt(t0.add(const Duration(minutes: 10))), isTrue);
      expect(hunt().isWarmAt(t0.add(const Duration(minutes: 16))), isFalse);
    });

    test('and only near where it happened', () {
      // Beyond this they are simply somewhere else, and §6.4's ordinary
      // population is what they meet.
      final near = square.offsetBy(metres: 200, bearingDeg: 0);
      final far = square.offsetBy(metres: 900, bearingDeg: 0);

      expect(hunt().followsTo(near, t0), isTrue);
      expect(hunt().followsTo(far, t0), isFalse);
    });
  });

  group('what comes back through the door', () {
    test('fewer than were on them — some wandered off', () {
      expect(hunt(engaged: 5).resumedAt(square, t0), lessThan(5));
      expect(hunt(engaged: 5).resumedAt(square, t0), greaterThan(0));
    });

    test('never more than four', () {
      // A fight the player can still choose to leave, rather than an ambush at
      // the loading screen.
      expect(hunt(engaged: 6).resumedAt(square, t0), lessThanOrEqualTo(4));
    });

    test('at least one, if it is warm at all', () {
      expect(hunt(engaged: 1).resumedAt(square, t0), 1);
    });

    test('and nothing once it has gone cold', () {
      expect(hunt().resumedAt(square, t0.add(const Duration(minutes: 20))), 0);
    });

    test('or once the player is genuinely somewhere else', () {
      // The escape is a walk, not a task manager.
      final away = square.offsetBy(metres: 900, bearingDeg: 90);

      expect(hunt().resumedAt(away, t0), 0);
    });
  });
}
