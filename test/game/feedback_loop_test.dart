import 'dart:io';

import 'package:test/test.dart';

/// ZMIANA STANU NIE MOŻE ROZGŁASZAĆ STANU (§2.1a.3, §4.7).
///
/// ⚠️ **The field report was "klikam konserwa, interfejs nie reaguje" — and it
/// was a feedback loop, not a slow function.**
///
///     _advanceMeal → GameLoop.applyUse → _publish → snapshots listener
///       → _advanceSearch → _advanceMeal → applyUse → …
///
/// §4.7 feeds a meal across in mouthfuls once a second. The interface credited
/// the meal; the credit reached [GameLoop.applyUse]; that broadcast a
/// snapshot; the listener rides the tick and so credited the meal again. One
/// turn of that took a microsecond, and the guard on the way in only asked
/// whether *any* time had passed — so it went round as fast as the machine
/// allowed until the meal was gone.
///
/// The tell was in the report and not in any log: the tin went from 38% to 32%
/// **while the interface was frozen**. Dart was not stuck, it was busy — and
/// the platform thread, waiting on channel replies behind a wall of
/// microtasks, is what Android eventually called an application not
/// responding.
///
/// Held at source level for the same reason the one-action and sticky-position
/// budgets are: the shape is what matters, and the shape is easy to undo by
/// accident from either end.
void main() {
  final loop = File('lib/game/game_loop.dart').readAsStringSync();
  final main = File('lib/main.dart').readAsStringSync();

  // The guard moved onto the clock when the five timers became one — see the
  // migration. What it guards is still here.
  final clock = File(
    'lib/game/controllers/action_controller.dart',
  ).readAsStringSync();

  String bodyOf(String source, String signature) {
    final start = source.indexOf(signature);
    expect(start, greaterThan(0), reason: '$signature is gone');

    final end = source.indexOf('\n  /// ', start + signature.length);
    return source.substring(start, end < 0 ? source.length : end);
  }

  group('the loop stages what it is given and says nothing', () {
    test('applyUse does not publish', () {
      // ⚠️ The edge that closed the circuit. A method that changes state must
      // not broadcast state — the tick publishes a second later, and what goes
      // in here is §2.2's pending stomach, which nothing draws directly.
      final apply = bodyOf(loop, 'void applyUse({double kcal = 0');

      expect(
        apply.contains('_publish()'),
        isFalse,
        reason: 'crediting a meal broadcast a snapshot that credited the meal',
      );
      expect(
        apply.contains('stageHot'),
        isTrue,
        reason: 'it must still be written down',
      );
    });

    test('and neither does treating a wound', () {
      // §2.6 is reached from the same place by the same path.
      final treat = bodyOf(loop, 'void treatBleeding(');
      expect(treat.contains('_publish()'), isFalse);
    });
  });

  group('the tick everything rides on cannot arrive inside itself', () {
    test('it refuses to re-enter', () {
      final advancing = bodyOf(main, 'Future<void> _advanceSearch() async {');

      expect(
        advancing.contains('if (_clock.advancing) return;'),
        isTrue,
        reason: 'reached from the clock and from any future publisher',
      );
      expect(advancing.contains('_clock.advancing = true'), isTrue);
    });

    test('and the flag belongs to the clock, not to the screen', () {
      // ⚠️ Where it has to be. The screen is being taken apart a controller at
      // a time; a guard that lived on the widget would have to be carried
      // along by every phase, and one of them would drop it.
      expect(clock.contains('bool advancing = false;'), isTrue);
    });

    test('and the flag is always put back', () {
      // ⚠️ A guard that leaks on an exception is worse than none: the meal
      // would never advance again, and nothing would say why.
      final advancing = bodyOf(main, 'Future<void> _advanceSearch() async {');

      expect(advancing.contains('finally'), isTrue);
      expect(advancing.contains('_clock.advancing = false'), isTrue);
    });

    test('a call a fraction of a second after the last is not a tick', () {
      // The old guard was "has any time passed at all", and between two turns
      // of a feedback loop a microsecond has.
      final advancing = bodyOf(main, 'Future<void> _advanceSearch() async {');

      expect(
        advancing.contains('milliseconds: 200'),
        isTrue,
        reason: 'everything upstream of this runs on a one-second clock',
      );
      expect(
        advancing.contains('if (delta <= Duration.zero) return;'),
        isFalse,
        reason: 'that guard is what a microsecond got through',
      );
    });

    test('and the credit is owed rather than lost', () {
      // The clock only moves when the work is paid for, so a refused call
      // hands the whole span to the next one.
      final advancing = bodyOf(main, 'Future<void> _advanceSearch() async {');

      final floor = advancing.indexOf('milliseconds: 200');
      final paid = advancing.indexOf('_clock.tickedAt = now;');

      expect(floor, greaterThan(0));
      expect(
        paid,
        greaterThan(floor),
        reason: 'a refused tick must not advance the clock it is measured by',
      );
    });
  });
}
