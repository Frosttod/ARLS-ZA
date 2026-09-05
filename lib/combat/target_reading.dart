/// What the fight panel says, worked out once (§5.1.4, §5.5.1).
///
/// ⚠️ **Forty arguments, assembled in a build method.** The panel was
/// constructed inline in the largest widget tree in the codebase, and the
/// facts behind it were recomputed on the spot: the distance to the target
/// four times over, the magazine size twice, "am I in my own safe zone" three
/// times, "am I inside the grace window" three times. Every one of those is a
/// rule of §5 or §8.1, and a rule written four times in a build method is a
/// rule that will be four different rules the next time one of them is edited.
///
/// So the panel is handed one value instead. What can be fired, reloaded or
/// swung at is decided here and tested here; the widget draws it.
///
/// **The refusal is an enum and not a sentence.** Four localised strings were
/// being chosen between inline, which puts Polish in the middle of a decision
/// about ammunition — §1.1 says the words go on at the edge.
library;

import 'ballistics.dart';
import 'awareness.dart';
import 'enemy.dart';
import 'engagement.dart' show kMeleeM;
import '../map/geometry.dart';

/// §5.5.4, §8.1: why the trigger is not available.
enum CombatRefusal {
  /// §8.1: the same fifty metres that keeps them out keeps the player's fire
  /// in. Two different numbers would make a ring nobody can win in.
  insideOwnZone,

  /// §9.2: the grace window cuts both ways.
  grace,

  noWeapon,
  noAmmo,

  /// §5.5.3: a blade is a blade at arm's length and a paperweight at thirty
  /// metres. Its own refusal, because "no ammunition" is nonsense about an axe
  /// and "nothing in hand" is a lie about one.
  outOfReach,
}

class TargetReading {
  const TargetReading({
    required this.targetName,
    required this.state,
    required this.condition,
    required this.distanceM,
    required this.sprintLeft,
    required this.bloodLeft,
    required this.bleeding,
    required this.weaponName,
    required this.chance,
    required this.dominant,
    required this.settling,
    required this.loaded,
    required this.magazine,
    required this.reloading,
    required this.refusal,
    required this.canFire,
    required this.canReload,
    required this.canStrike,
    required this.canTakeDown,
  });

  /// §5.5.1: what is being aimed at, in the player's language. Resolved by the
  /// caller — this file has no business knowing what language anybody reads.
  final String targetName;

  final EnemyState state;
  final EnemyCondition condition;

  /// Worked out once. It decides the hit chance, whether anything can be
  /// swung at, and what the panel prints.
  final double distanceM;

  final double sprintLeft;
  final double bloodLeft;
  final bool bleeding;

  /// §5.5.4: what is in the hands, by name. Null with empty ones.
  final String? weaponName;

  /// §5.1.4: 0–1, or null with nothing to fire — a number about a shot nobody
  /// can take is worse than no number.
  final double? chance;
  final ErrorSource? dominant;

  /// §5.1.3: the sights have not come back yet.
  final bool settling;

  final int loaded;
  final int magazine;
  final bool reloading;

  /// Why not, or null when the trigger is live.
  final CombatRefusal? refusal;

  final bool canFire;
  final bool canReload;
  final bool canStrike;

  /// §5.5.1: cios w plecy czegoś, co nie wie. Jeden ruch, nie walka.
  final bool canTakeDown;
}

/// Everything the panel needs, from what the game already knows.
///
/// [error] is null with nothing in hand — §5.1 has no spread to state for a
/// shot that cannot be taken, and the chance follows it.
TargetReading readTarget({
  required Enemy target,
  required GeoPoint from,
  required String targetName,
  required ShotError? error,
  required String? weaponName,
  required int magazine,
  required int loaded,
  required bool hasRound,
  required bool reloading,
  required bool settling,
  required bool inOwnZone,
  required bool inGrace,

  /// Whether what is in hand is fired. False for a blade, and for bare hands.
  ///
  /// ⚠️ Not the same question as `reach_m`. That figure (0,3–1,8 m) is how a
  /// swing goes in a crowd (§5.5.3); what decides whether a blade is any use
  /// at all against *this* target is [kMeleeM], the same twenty metres
  /// [canStrike] has always used.
  bool ranged = true,
}) {
  final metres = target.position.distanceTo(from);
  final armed = weaponName != null;

  // ⚠️ In this order, and the order is the rule. Standing in your own zone is
  // why you cannot fire even with a full magazine; being out of ammunition is
  // only the answer once none of the others is.
  //
  // ⚠️ **And the last two are about ranged weapons only.** Reported from the
  // field: an axe in hand read as "nothing in hand", because the only thing
  // this function counted as a weapon was a firearm — so a player holding two
  // kilograms of steel was told they were empty-handed, and the silent
  // takedown of §5.5.1 was refused for the same reason.
  final refusal = inOwnZone
      ? CombatRefusal.insideOwnZone
      : inGrace
      ? CombatRefusal.grace
      : !armed
      ? CombatRefusal.noWeapon
      : ranged && loaded <= 0 && !hasRound
      ? CombatRefusal.noAmmo
      : !ranged && metres > kMeleeM
      ? CombatRefusal.outOfReach
      : null;

  return TargetReading(
    targetName: targetName,
    state: target.state,
    condition: target.condition,
    distanceM: metres,
    sprintLeft: target.sprintLeftFraction,
    bloodLeft: target.bloodLeft,
    bleeding: target.isBleeding,
    weaponName: weaponName,
    chance: error == null
        ? null
        : hitChance(moa: error.total, distanceM: metres),
    dominant: error?.dominant,
    settling: settling,
    loaded: loaded,
    magazine: magazine,
    reloading: reloading,
    refusal: refusal,
    canFire:
        armed && ranged && loaded > 0 && !reloading && !inGrace && !inOwnZone,

    // ⚠️ Nothing to do is not the same as nothing to load: §5.3's seconds are
    // for filling a magazine, and a full one has no room to fill.
    canReload: armed && ranged && hasRound && !reloading && loaded < magazine,

    // §5.2: below twenty metres the receiver has nothing useful to say about
    // anybody's position, so the fight stops being about distance and becomes
    // about what is in your hands — and bare hands count.
    canStrike: !inOwnZone && !inGrace && metres <= kMeleeM,

    // §5.5.1: i czy to jest już nie walka, tylko jeden ruch. Osobno od
    // [canStrike], bo przycisk ma powiedzieć **co się stanie**, a nie zostawić
    // gracza z domysłem, czy akurat stoi wystarczająco dokładnie za nim.
    canTakeDown: !inOwnZone && !inGrace && armed && canTakeDown(target, from),
  );
}
