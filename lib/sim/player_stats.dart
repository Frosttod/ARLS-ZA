/// What a character has done, counted (§13.1).
///
/// A tally, not a state. Everything here only ever grows, which is what makes
/// it worth keeping apart from the vitals: one is rewritten every minute with
/// the state of a body, the other is a history.
///
/// ⚠️ None of it leaves the phone. §16.5 permits aggregated telemetry, off by
/// default and with explicit consent, and this is not that — it is the
/// player's own record for the player's own screen.
library;

import '../combat/ballistics.dart';

class PlayerStats {
  const PlayerStats({
    this.shotsFired = 0,
    this.shotsHit = 0,
    this.swings = 0,
    this.swingsHit = 0,
    this.hitsHead = 0,
    this.hitsTorso = 0,
    this.hitsArms = 0,
    this.hitsLegs = 0,
    this.kills = 0,
    this.bloodDealtMl = 0,
    this.bloodLostMl = 0,
    this.searches = 0,
    this.blackouts = 0,
  });

  static const empty = PlayerStats();

  final int shotsFired;
  final int shotsHit;
  final int swings;
  final int swingsHit;

  final int hitsHead;
  final int hitsTorso;
  final int hitsArms;
  final int hitsLegs;

  final int kills;
  final double bloodDealtMl;
  final double bloodLostMl;

  final int searches;
  final int blackouts;

  /// §5.1: what the shooting is actually worth, 0–1, or null before the first
  /// trigger pull.
  ///
  /// Null rather than nought: a player who has not fired has no accuracy, and
  /// showing them 0% would be the game telling them they are bad at something
  /// they have not done.
  double? get accuracy => shotsFired == 0 ? null : shotsHit / shotsFired;

  double? get meleeAccuracy => swings == 0 ? null : swingsHit / swings;

  /// §5.1.5: how many rounds it takes, on the player's own evidence.
  ///
  /// The figure §10.3.3 calibrates against — about three of 5.45 for a Walker
  /// — measured rather than promised.
  double? get shotsPerKill => kills == 0 ? null : shotsFired / kills;

  int hitsAt(HitLocation where) => switch (where) {
    HitLocation.head => hitsHead,
    HitLocation.torso => hitsTorso,
    HitLocation.arms => hitsArms,
    HitLocation.legs => hitsLegs,
  };

  int get hitsCounted => hitsHead + hitsTorso + hitsArms + hitsLegs;

  /// A shot, and where it went. [where] is null for a miss.
  PlayerStats fired({HitLocation? where, double bloodMl = 0}) => _with(
    shotsFired: shotsFired + 1,
    shotsHit: where == null ? shotsHit : shotsHit + 1,
    where: where,
    bloodDealtMl: bloodDealtMl + bloodMl,
  );

  /// A swing, and where it went.
  PlayerStats swung({HitLocation? where, double bloodMl = 0}) => _with(
    swings: swings + 1,
    swingsHit: where == null ? swingsHit : swingsHit + 1,
    where: where,
    bloodDealtMl: bloodDealtMl + bloodMl,
  );

  PlayerStats killed() => _with(kills: kills + 1);

  PlayerStats hurt(double ml) => _with(bloodLostMl: bloodLostMl + ml);

  PlayerStats searchedSomething() => _with(searches: searches + 1);

  PlayerStats wentDown() => _with(blackouts: blackouts + 1);

  PlayerStats _with({
    int? shotsFired,
    int? shotsHit,
    int? swings,
    int? swingsHit,
    HitLocation? where,
    int? kills,
    double? bloodDealtMl,
    double? bloodLostMl,
    int? searches,
    int? blackouts,
  }) => PlayerStats(
    shotsFired: shotsFired ?? this.shotsFired,
    shotsHit: shotsHit ?? this.shotsHit,
    swings: swings ?? this.swings,
    swingsHit: swingsHit ?? this.swingsHit,
    hitsHead: hitsHead + (where == HitLocation.head ? 1 : 0),
    hitsTorso: hitsTorso + (where == HitLocation.torso ? 1 : 0),
    hitsArms: hitsArms + (where == HitLocation.arms ? 1 : 0),
    hitsLegs: hitsLegs + (where == HitLocation.legs ? 1 : 0),
    kills: kills ?? this.kills,
    bloodDealtMl: bloodDealtMl ?? this.bloodDealtMl,
    bloodLostMl: bloodLostMl ?? this.bloodLostMl,
    searches: searches ?? this.searches,
    blackouts: blackouts ?? this.blackouts,
  );
}
