/// Where the player is, and what the phone currently claims (§3.2, §3.6).
///
/// ⚠️ **These are two different questions and this class exists because they
/// were one field apart.**
///
/// `snapshot.displayFix` is what the receiver has to say *this instant*, and
/// it is null all the time: indoors, in a shelter where §2.1a.4 turns the
/// receiver off, in a stairwell, under a bridge. [standingAt] is where the
/// character is, which does not become "nowhere" because a satellite went
/// behind a building.
///
/// Seven separate bugs in this project were one line reading the first when it
/// meant the second. Searching a room did nothing. Dropping an item destroyed
/// it. A marker measured its distance from null island. Every one of them was
/// found on a walk, by a person standing still and watching the game do
/// nothing.
///
/// So: **everything that measures, reaches, drops or searches reads
/// [standingAt]. Only things that draw the blue dot read the snapshot.** The
/// rule survives because the two live behind different names on one object
/// rather than beside each other in a six-thousand-line class.
library;

import 'package:flutter/foundation.dart';

import '../game/game_loop.dart';
import '../location/position_fix.dart';
import '../map/geometry.dart';

class PositionController {
  PositionController({GeoPoint? lastKnown})
    : standingAt = ValueNotifier(lastKnown);

  /// Where the character is, for everything that measures a distance.
  ///
  /// Sticky: it only ever moves to somewhere the receiver actually reported.
  /// A snapshot with nothing in it leaves this exactly where it was.
  final ValueNotifier<GeoPoint?> standingAt;

  /// What the phone says right now, for the things that draw it.
  ///
  /// Null before the first tick. Null `displayFix` inside it is ordinary and
  /// means "no signal at this instant", not "the player is gone".
  final ValueNotifier<GameSnapshot?> snapshot = ValueNotifier(null);

  /// Convenience for the many callers that want the position and nothing else.
  GeoPoint? get here => standingAt.value;

  /// Takes one tick from the loop. Plumbing; the rule is [follow].
  void accept(GameSnapshot next) {
    snapshot.value = next;
    follow(next.displayFix);
  }

  /// ⚠️ **The one rule, in one place.**
  ///
  /// The sticky position follows the fix when there is one, and is left alone
  /// when there is not. Written here so nobody downstream has to remember it,
  /// because for a year everybody had to and seven of them forgot.
  ///
  /// Separate from [accept] deliberately: a [GameSnapshot] has six required
  /// fields and nothing in this project's tests has ever built one, so a rule
  /// reachable only through it would be a rule with no tests — which is the
  /// state this extraction exists to end.
  void follow(PositionFix? fix) {
    if (fix == null) return;
    standingAt.value = GeoPoint(fix.latitude, fix.longitude);
  }

  /// Puts the character back where the save left them, before any fix arrives.
  ///
  /// §11.1.2: a session that resumes at null island replays the whole gap as
  /// somebody standing several thousand kilometres from their shelter.
  void seed(GeoPoint at) => standingAt.value = at;

  void dispose() {
    standingAt.dispose();
    snapshot.dispose();
  }
}
