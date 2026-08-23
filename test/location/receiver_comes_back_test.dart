import 'dart:io';

import 'package:arls_za/location/position_source.dart';
import 'package:test/test.dart';

/// ODBIORNIK WRACA (§2.1a.4, §3.3, §3.2).
///
/// ⚠️ **Reported from a walk: "even standing still I get *no certain
/// position*".** The player was in the middle of a street with a pin on the
/// map, and every search was refused.
///
/// §2.1a.4 turns the receiver off entirely for a shelter occupation — the
/// character is not moving, the position is not needed, and the radio is the
/// most expensive thing on the phone. That is right, and it leaves no stream
/// subscription behind.
///
/// The bug was what happened next. `setCadence` decided whether to reconnect
/// by asking `_sub == null`, which cannot tell *never started* from *we
/// switched it off ourselves a minute ago*. So walking back out of the shelter
/// set the field, noted the cadence, and returned before reconnecting. The
/// receiver stayed off for the rest of the session, the signal stayed
/// `unavailable`, and everything that needs to know where the player is
/// stopped working — searching, reconnaissance, forcing a door.
///
/// One state, off for one reason, and nothing to switch it back.
///
/// Held at source level for the same reason the sticky-position and one-action
/// budgets are: the device source needs a real radio to run, and the shape is
/// what matters. It is a shape that reads like a sensible null check.
void main() {
  final source = File(
    'lib/location/device_position_source.dart',
  ).readAsStringSync();

  String bodyOf(String signature) {
    final start = source.indexOf(signature);
    expect(start, greaterThan(0), reason: '$signature is gone');

    final end = source.indexOf('\n  Future<', start + signature.length);
    return source.substring(start, end < 0 ? source.length : end);
  }

  group('turning the receiver off is not the same as being done with it', () {
    test('the cadence never decides by asking whether a stream exists', () {
      // ⚠️ The bug, in one line. `_sub == null` is true both before the source
      // has ever started and after §2.1a.4 switched it off, and those two want
      // opposite answers.
      final cadence = bodyOf(
        'Future<void> setCadence(PositionCadence cadence)',
      );

      expect(
        cadence.contains('if (_sub == null) return;'),
        isFalse,
        reason: 'that test cannot tell "never started" from "we turned it off"',
      );
    });

    test('it asks whether the game still wants a position', () {
      final cadence = bodyOf(
        'Future<void> setCadence(PositionCadence cadence)',
      );

      expect(cadence.contains('if (!_wanted) return;'), isTrue);
    });

    test('and a cadence of off keeps wanting one', () {
      // Off, but still wanted: walking back out has to bring it on again.
      final cadence = bodyOf(
        'Future<void> setCadence(PositionCadence cadence)',
      );

      expect(
        cadence.contains('_wanted = false'),
        isFalse,
        reason: 'a shelter must not be a one-way door for the receiver',
      );
      expect(
        cadence.contains('markUnavailable()'),
        isTrue,
        reason: 'the signal still has to say the radio is off',
      );
    });
  });

  group('the two ways the receiver goes quiet', () {
    test('starting says the game wants a position', () {
      expect(
        bodyOf('Future<void> start({').contains('_wanted = true;'),
        isTrue,
      );
    });

    test('and stopping is the owner saying it does not', () {
      // ⚠️ This one *is* a one-way door, and should be: it is the lifecycle
      // shutting the source down, not a shelter.
      expect(
        bodyOf('Future<void> stop()').contains('_wanted = false;'),
        isTrue,
      );
    });
  });

  test('a shelter is the only activity that turns the radio off (§3.3)', () {
    // The cost of getting this wrong is the whole bug: everything downstream
    // treats `unavailable` as "we do not know where you are", so any activity
    // that reached for `off` by mistake would refuse every action in the game.
    final policy = File('lib/location/sampling_policy.dart').readAsStringSync();

    final offRows = RegExp(
      r'Activity\.(\w+) => PositionCadence\.off',
    ).allMatches(policy).map((m) => m.group(1)).toList();

    expect(offRows, ['sheltered']);
  });

  test('and only a zero interval means off at all', () {
    // §3.3's own figures: one second in a fight, five walking, ten standing
    // still. None of those is off, and standing still must not be — that is
    // exactly when somebody searches.
    expect(PositionCadence.combat.interval, const Duration(seconds: 1));
    expect(PositionCadence.moving.interval, const Duration(seconds: 5));
    expect(PositionCadence.resting.interval, const Duration(seconds: 10));
    expect(PositionCadence.off.interval, Duration.zero);

    for (final cadence in PositionCadence.values) {
      expect(
        cadence.interval <= Duration.zero,
        cadence == PositionCadence.off,
        reason: '${cadence.name} would switch the radio off',
      );
    }
  });
}
