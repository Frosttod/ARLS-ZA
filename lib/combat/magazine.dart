/// What is actually in the weapon (§5.3, §5.5.4).
///
/// A round in the pack is not a round in the rifle, and the difference is the
/// whole of §5.5.4: reloading takes seconds a fight does not always have, and
/// **anything closing inside five metres stops it**. A magazine change with a
/// Walker at arm's length is not a thing that finishes, and letting it finish
/// would make the clinch a formality rather than the emergency it is.
///
/// The count is deliberately not persisted yet. A rifle that reloads itself
/// while the app is shut is a small lie; a save format that carries per-weapon
/// state is a schema change, and it belongs with the shelter's storage in
/// stage 8 rather than bolted on here.
library;

import '../items/item.dart';
import 'attachment.dart';

/// §5.5.4: closer than this and a reload does not finish.
const double kReloadBreakM = 5;

/// How long a magazine change takes, with whatever is on the weapon (§4.2).
/// §7: how much of a reload Weapons takes off the clock.
const double kWeaponsSpeed = 0.30;

Duration reloadTime(
  ItemDefinition weapon, {
  List<ItemDefinition> attachments = const [],
  double weapons = 0,
}) {
  final fitted = FittedWeapon(
    weapon: weapon,
    attachments: attachments,
  ).reloadTime;

  // §7: −30% at full mastery. §2.4's own reload penalty for a racing heart
  // multiplies on top of this, so a master out of breath is still slower than
  // a master standing still — which is the point of §2.4 having one at all.
  return Duration(
    milliseconds:
        (fitted.inMilliseconds * (1 - kWeaponsSpeed * weapons.clamp(0.0, 1.0)))
            .round(),
  );
}

/// How many rounds the weapon holds, extended magazine and all.
int magazineSize(
  ItemDefinition weapon, {
  List<ItemDefinition> attachments = const [],
}) => FittedWeapon(weapon: weapon, attachments: attachments).magazine;

/// A reload in progress, or the absence of one.
class Reload {
  const Reload({
    required this.weaponId,
    required this.readyAt,
    required this.total,
  });

  final String weaponId;

  /// When the magazine is in. §5.5.4 is about this moment never arriving.
  final DateTime readyAt;

  /// How long the whole thing takes.
  ///
  /// Carried here rather than recomputed by whoever draws the bar: the weapon
  /// can change under a running reload, and a bar whose denominator moves is
  /// worse than no bar.
  final Duration total;

  bool isDoneAt(DateTime now) => !now.isBefore(readyAt);

  /// 0–1, against the duration this reload was started with.
  double progress(DateTime now) => progressAt(now, total: total);

  /// How far through it is, 0–1, for a bar that means something.
  double progressAt(DateTime now, {required Duration total}) {
    if (total <= Duration.zero) return 1;

    final left = readyAt.difference(now).inMilliseconds;
    if (left <= 0) return 1;

    return (1 - left / total.inMilliseconds).clamp(0.0, 1.0);
  }
}

/// §5.5.4: whether anything is close enough to stop a magazine change.
///
/// Distance to the nearest of them, whatever it is doing. Something walking
/// past at four metres ruins a reload as surely as something charging: hands
/// stop when a body is that close, and the game is not going to argue about
/// intent.
bool reloadBrokenBy(Iterable<double> enemyDistancesM) {
  for (final distance in enemyDistancesM) {
    if (distance <= kReloadBreakM) return true;
  }
  return false;
}

/// What one reload takes out of the pack, given what is loaded and carried.
///
/// Whole magazine changes are not modelled: this is a survivor with loose
/// rounds and a pocket, so it tops up to whatever it can. Fewer rounds than
/// the magazine holds is a normal state to fight in.
int roundsToLoad({
  required ItemDefinition weapon,
  required int loaded,
  required int carried,
  List<ItemDefinition> attachments = const [],
}) {
  final room = magazineSize(weapon, attachments: attachments) - loaded;
  if (room <= 0 || carried <= 0) return 0;

  return room < carried ? room : carried;
}
