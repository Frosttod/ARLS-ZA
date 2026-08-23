import 'dart:io';

import 'package:test/test.dart';

/// JEDNA PARA RĄK, PILNOWANA W ŹRÓDLE (§2.1a).
///
/// ⚠️ A walk came back with a photograph of somebody eating a tin of meat and
/// taking a pair of boots apart at the same time. Each half checked its own
/// clock and neither asked about the other's.
///
/// `_alreadyBusy()` is the answer, and it is a list — which means it is a bug
/// waiting for the next clock somebody adds and forgets to name. These tests
/// hold the list against the clocks that exist, in the same spirit as the
/// action-strip and sticky-position budgets.
///
/// The real fix is that the actions table can hold one row per profile, so
/// the rule becomes impossible to forget rather than merely tested. That is
/// finished for uses and still outstanding for craft jobs and shelter builds,
/// which keep their own records — see the note on ActiveActions.
void main() {
  final main = File('lib/main.dart').readAsStringSync();

  String bodyOf(String signature) {
    final start = main.indexOf(signature);
    expect(start, greaterThan(0), reason: '$signature is gone');

    // To the next method at the same indentation, which is close enough to a
    // body for a source-level budget and far cheaper than a parser.
    final end = main.indexOf('\n  /// ', start + signature.length);
    return main.substring(start, end < 0 ? main.length : end);
  }

  test('every clock in the game is named in the busy check', () {
    // If a new one appears and is not here, two things can run at once and
    // nobody finds out until a walk.
    final busy = bodyOf('String? _alreadyBusy()');

    for (final clock in [
      '_actions?.current', // §11.1: the one that survives a restart
      '_search.value', // eating, searching, forcing a door
      '_reload', // §5.5.4
      '_craftJob.value', // §18.4, §18.6
      '_shelters.value', // §8.3
    ]) {
      expect(
        busy.contains(clock),
        isTrue,
        reason: '$clock can run without the busy check noticing',
      );
    }
  });

  test('and the stored row is asked about first', () {
    // ⚠️ It is the only one that outlives a restart. A use the operating
    // system interrupted is still on the row until the boot settles it, and
    // asking the in-memory ones first would let something start on top of it.
    final busy = bodyOf('String? _alreadyBusy()');

    expect(
      busy.indexOf('_actions?.current'),
      lessThan(busy.indexOf('_search.value')),
      reason: 'the row must be checked before the notifiers',
    );
  });

  test('every way of starting something asks first', () {
    // The list of starts, held against the guard. A start that does not ask
    // is the photograph from that walk.
    for (final start in [
      'Future<void> _use(CarriedItem line)',
      'Future<void> _fillMagazine(CarriedItem line)',
      'Future<void> _emptyMagazine(CarriedItem line)',
      'void _startReload()',
      'void _startAreaSearch()',
      'void _startObjectSearch(SearchDepth depth)',
      // ⚠️ §19.3. Reported from a walk: a dismantling at the bench refused a
      // quick search and waved a locked car straight through, because this
      // one asked whether another *search* was running and nothing else.
      // Forcing a door is not a lesser act than looking in a bin — it is
      // twenty seconds of both hands on a crowbar.
      'void _startBreach(BarrierBreach breach)',
    ]) {
      expect(
        bodyOf(start).contains('_alreadyBusy()'),
        isTrue,
        reason: '$start starts without asking whether the hands are free',
      );
    }
  });

  test('and none of them settles for asking about its own clock', () {
    // ⚠️ The shape of the reported bug, held rather than described. Every
    // start below used to have a private version of the rule — "is another
    // search running", "is another job on the bench" — and a private version
    // of a shared rule is a rule with holes in it. The holes are not
    // hypothetical: forcing a door had one for as long as the check existed.
    for (final start in [
      'void _startAreaSearch()',
      'void _startObjectSearch(SearchDepth depth)',
      'void _startBreach(BarrierBreach breach)',
    ]) {
      final body = bodyOf(start);

      expect(
        body.contains('_search.value != null) return'),
        isFalse,
        reason: '$start still has its own private idea of busy',
      );
    }
  });

  test('a use is written down before its bar is drawn (§11.1)', () {
    // The order matters and is the whole of the reported bug: a process can
    // be killed in the first second as easily as the last, so the row has to
    // exist before anything else does.
    final use = bodyOf('Future<void> _use(CarriedItem line)');

    expect(use.contains('_actions?.start('), isTrue);
    expect(
      use.indexOf('_actions?.start('),
      lessThan(use.indexOf('Search.using(')),
      reason: 'the bar was drawn before the row was written',
    );
  });
}
