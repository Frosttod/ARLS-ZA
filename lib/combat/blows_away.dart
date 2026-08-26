/// What a clinch does to somebody who put the phone away (§5.5.3, §9.2, §11.1.2).
///
/// ⚠️ **Closing the app in the middle of a fight was a perfect escape.** The
/// blows of §5.5.3 were only ever applied on a live tick, so a player with
/// three Walkers at arm's length could lock the screen, walk home and come
/// back untouched. Nothing in §5 or §6 costs anything if the way out is free —
/// the whole economy of those two sections is that a fight has to be *left*.
///
/// **The window is the same five minutes that make a street forgettable**
/// (`kCombatGapForgotten`). Past that §11.1.2 says what a Walker did is not
/// knowable and the street is repopulated instead of guessed at; the first
/// five minutes of it are knowable enough — they were standing right there.
///
/// ⚠️ **And it never kills.** Five minutes of a crowd is arithmetically fatal
/// several times over, which is realistic and unplayable: a player who put
/// their phone in a pocket at the wrong moment would lose a month-long run to
/// something they never saw. So the total is clamped at the edge of §2.6's
/// class IV. In softcore that edge is where §9.2 takes over — they go down,
/// scatter half their kit and wake at 65%, which is a bad afternoon rather
/// than the end. In hardcore the same edge is death, so hardcore stops short
/// of it: badly hurt, still standing, and still holding the problem.
library;

import 'dart:math';

import 'ballistics.dart' show HitLocation, rollHitLocation;
import 'enemy.dart';
import 'engagement.dart' show flankingMultiplier, kMeleeM;
import '../map/geometry.dart';

/// §5.5.3: a gap longer than this was somebody standing there, not a tick.
///
/// ⚠️ Ten seconds, not one. A live tick already charges a swing through the
/// per-enemy cooldown; this exists for the gap a locked screen leaves, and a
/// hiccup in the frame loop is not that.
const Duration kAwayGap = Duration(seconds: 10);

/// §11.1.2: how much of a gap is charged for. The rest is not knowable.
const Duration kBlowsAwayWindow = Duration(minutes: 5);

/// §2.6: the loss at which class IV begins — death, or §9.2's unconsciousness.
const double kClassFourLoss = 0.40;

/// How close to that edge a run that must survive is allowed to come.
const double kSurvivableLoss = 0.38;

/// What was waiting when the screen came back on.
class BlowsAway {
  const BlowsAway({
    required this.bloodMl,
    required this.blows,
    required this.worst,
  });

  static const none = BlowsAway(bloodMl: 0, blows: 0, worst: null);

  /// Blood lost over the window, already clamped.
  final double bloodMl;

  /// How many landed. For the journal — "you were bitten eleven times" is a
  /// different sentence from "you were bitten".
  final int blows;

  /// §2.6: the worst place anything landed, which decides the bleed.
  final HitLocation? worst;

  bool get any => blows > 0 && bloodMl > 0;
}

/// §5.5.3: everything close enough to swing at somebody standing at [at].
///
/// ⚠️ One list, asked for by both the live tick and the gap. Two copies of
/// "who is in reach" is two answers the first time either is edited.
List<Enemy> enemiesInReach(List<Enemy> enemies, GeoPoint at) => [
  for (final enemy in enemies)
    if (!enemy.isDead && enemy.position.distanceTo(at) <= kMeleeM) enemy,
];

/// §2.6, §4.4: one swing landing on somebody.
///
/// ⚠️ One arithmetic, asked for by the live tick and by the gap. Teeth and
/// hands land where they land — a bite to the arm the player put up is not the
/// bite that takes them down — and armour reduces a blow only where it covers.
({double bloodMl, HitLocation where}) swingOf(
  Enemy enemy, {
  required double crowding,
  required double armour,
  required Random random,
}) {
  final where = rollHitLocation(random.nextDouble());

  return (
    bloodMl: enemy.kind.damageMl * crowding * where.multiplier * armour,
    where: where,
  );
}

/// §5.5.3: one swing each from everything that is due one.
///
/// The live tick's half of the same rule: who may swing is decided by the
/// cooldown the caller keeps, and what it costs is decided here.
BlowsAway oneSwingEach({
  required List<Enemy> swinging,
  required int crowdSize,
  required double protection,
  required Random random,
}) {
  if (swinging.isEmpty) return BlowsAway.none;

  final crowding = flankingMultiplier(crowdSize);
  final armour = 1 - protection.clamp(0.0, 1.0) / 5;

  var taken = 0.0;
  HitLocation? worst;

  for (final enemy in swinging) {
    final blow = swingOf(
      enemy,
      crowding: crowding,
      armour: armour,
      random: random,
    );
    if (worst == null || blow.where.multiplier > worst.multiplier) {
      worst = blow.where;
    }
    taken += blow.bloodMl;
  }

  return BlowsAway(bloodMl: taken, blows: swinging.length, worst: worst);
}

/// §10.3: anything that was standing here a moment ago and is gone now.
///
/// ⚠️ The safety net, and it exists because a death can be missed. The session
/// reports the ones it kills during a tick and the shot reports the one under
/// the sights — but a thing can also leave the list because the tick that
/// killed it ran while the fix was stale, or because two paths each thought
/// the other had it. Anything that vanished without walking out of range died,
/// and a death with no body is a kill the player has no evidence of.
List<Enemy> vanishedNear(
  List<Enemy> before,
  List<Enemy> after,
  GeoPoint at, {
  required double withinM,
}) {
  final left = {for (final enemy in after) enemy.id};

  return [
    for (final enemy in before)
      if (!enemy.isDead &&
          !left.contains(enemy.id) &&
          enemy.position.distanceTo(at) <= withinM)
        enemy,
  ];
}

/// §5.5.3: what [inReach] did over [away], for a body holding [bloodMl].
///
/// [protection] is §4.4's armour share, 0–1, taken once — the same plate was
/// on for the whole window.
///
/// [mayGoDown] is softcore. When it is false the total stops short of §2.6's
/// class IV, because in hardcore that line is the end of the run.
BlowsAway blowsWhileAway({
  required List<Enemy> inReach,
  required Duration away,
  required double bloodMl,
  required double bloodMaxMl,
  required double protection,
  required bool mayGoDown,
  required Random random,
}) {
  final window = away < kBlowsAwayWindow ? away : kBlowsAwayWindow;
  if (inReach.isEmpty || window <= Duration.zero || bloodMaxMl <= 0) {
    return BlowsAway.none;
  }

  // §5.5.3: the player answers one of them and the rest swing freely, which is
  // why letting a group close is very nearly a sentence — and why walking away
  // from a clinch is the only answer to one.
  final crowding = flankingMultiplier(inReach.length);
  final armour = 1 - protection.clamp(0.0, 1.0) / 5;

  var taken = 0.0;
  var blows = 0;
  HitLocation? worst;

  for (final enemy in inReach) {
    final swings =
        window.inMilliseconds ~/ enemy.kind.attackInterval.inMilliseconds;

    for (var swing = 0; swing < swings; swing++) {
      final blow = swingOf(
        enemy,
        crowding: crowding,
        armour: armour,
        random: random,
      );
      if (worst == null || blow.where.multiplier > worst.multiplier) {
        worst = blow.where;
      }

      taken += blow.bloodMl;
      blows++;
    }
  }

  // ⚠️ The clamp, and it is the whole of "never kills". Everything above is an
  // honest count of swings; five minutes of it is fatal several times over,
  // and a run lost to a pocket is a run nobody plays again.
  final floor =
      bloodMaxMl * (1 - (mayGoDown ? kClassFourLoss : kSurvivableLoss));
  final allowed = bloodMl - floor;

  return BlowsAway(
    bloodMl: taken < allowed ? taken : (allowed < 0 ? 0 : allowed),
    blows: blows,
    worst: worst,
  );
}
