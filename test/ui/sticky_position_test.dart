import 'dart:io';

import 'package:test/test.dart';

/// LEPKA POZYCJA, JEDNA ODPOWIEDŹ (§3.2, §2.1a.4).
///
/// ⚠️ This test reads source rather than behaviour, which is unusual and is
/// here because the same mistake has now been made **seven times** in one
/// file. Every occurrence was a different function; every occurrence was found
/// on a walk rather than by a test; and three of them were found *twice*,
/// because the first fix patched the handler while the thing that gated it
/// still read the fix.
///
/// The mistake: reading `snapshot.displayFix` to answer "where is the player".
/// It is null exactly when it matters — §3.2's accuracy gate has nothing to
/// pass indoors, and §2.1a.4 switches the receiver off entirely under a roof.
/// So a shelter, the one place a player stands still and does things, was the
/// one place searching, breaching, dropping, tapping a marker, eating and
/// sleeping all silently failed.
///
/// The rule: **there is one answer to where the player is**, `_standingAt`,
/// and anything that decides what the player may *do* reads that. `displayFix`
/// is for drawing and for measuring what the phone can currently see.
///
/// This is a budget, not a ban. When it fails, do not raise the number to make
/// it pass — look at the new occurrence and ask whether it is deciding an
/// action. If it is drawing, add it to the count with a note. If it is gating,
/// it wants `_standingAt`.
void main() {
  test('nothing new reads displayFix to decide what the player may do', () {
    final source = File('lib/main.dart').readAsStringSync();
    final uses = 'displayFix'.allMatches(source).length;

    // The sixteen that remain, and what each is for:
    //
    //   1  seeding the sticky position itself, which is where it comes from
    //   1  the combat tick, which needs a *current* reading by definition
    //   2  firing and striking, which §3.5 refuses without a trusted position
    //   1  scattering a dead character's kit (§9.2)
    //   1  the threat reading, which is about what the phone can see
    //   1  handing the raw fix to the map for drawing
    //   9  drawing the combat panel and its distances
    //
    // Four comments naming it are counted here too, which is why this is a
    // budget rather than a list: a comment explaining the trap is worth more
    // than a number that is exactly right.
    expect(
      uses,
      lessThanOrEqualTo(20),
      reason:
          'a new displayFix in main.dart. If it decides whether something can '
          'be done — searched, opened, dropped, built, slept in — it must read '
          '_standingAt instead: displayFix is null indoors, which is where the '
          'player does most of these things.',
    );
  });

  test('and the loop is told where the player is, rather than guessing', () {
    // §2.5.1's zone used to be worked out from the loop's own last gated fix,
    // which is a second answer to the same question — and under a roof it was
    // the wrong one, so sleep never began.
    final loop = File('lib/game/game_loop.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(
      loop,
      contains('void setStandingAt('),
      reason: 'the loop must be able to be told',
    );
    expect(
      main,
      contains('_loop?.setStandingAt('),
      reason: 'and something must actually tell it',
    );
  });
}
