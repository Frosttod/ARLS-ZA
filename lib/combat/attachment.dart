/// What is bolted to the weapon, and what it changes (§5.1, §5.3, §5.6.3).
///
/// An attachment is not a tool: on its own it does nothing at all. Each one
/// moves a number the combat model already reads — minutes of angle off the
/// group, seconds off §5.3's settling, rounds onto the magazine, a multiplier
/// onto what §5.6.1 puts in the air.
///
/// They are the rarest things in the game deliberately. §5.6.3 calls the
/// suppressor a change in how the game is played rather than another
/// percentage, and the same is true of the rest: a laser is the difference
/// between shooting after two seconds of standing still and shooting after
/// one, which in §5.1.3's arithmetic is the difference between a shot and no
/// shot at all. Crafting one asks for a high Engineering skill (§7); the rest
/// of the time they are found, and hardly ever.
///
/// ⚠️ **Interim rule: an attachment that fits is treated as fitted.** Which
/// ones are actually on which weapon is per-weapon state, and per-weapon state
/// is a schema change — the same one the magazine is waiting for in stage 8.
/// Until then a player carrying a suppressor for their calibre is a player
/// with a suppressed weapon, which is what the game already assumed when the
/// suppressor was the only attachment in it.
library;

import '../items/item.dart';

/// Whether [attachment] goes on [weapon] (§10.3.3's calibre string, again).
///
/// `any` for the things that clamp to a rail and do not care what they are
/// clamped to: an optic is an optic.
bool fitsWeapon(ItemDefinition attachment, ItemDefinition weapon) {
  if (attachment.kind != ItemKind.attachment) return false;
  if (weapon.kind != ItemKind.firearm) return false;

  final accepts = attachment.props['attaches_to'];
  if (accepts is! List) return false;
  if (accepts.contains('any')) return true;

  return accepts.contains(weapon.props['caliber']);
}

/// A weapon with whatever is on it, as one set of numbers to shoot with.
class FittedWeapon {
  const FittedWeapon({required this.weapon, this.attachments = const []});

  /// Everything carried that fits this weapon (see the interim rule above).
  factory FittedWeapon.from({
    required ItemDefinition weapon,
    required Iterable<ItemDefinition> carried,
  }) => FittedWeapon(
    weapon: weapon,
    attachments: [
      for (final item in carried)
        if (fitsWeapon(item, weapon)) item,
    ],
  );

  final ItemDefinition weapon;
  final List<ItemDefinition> attachments;

  double _base(String prop, double fallback) =>
      (weapon.props[prop] as num?)?.toDouble() ?? fallback;

  double _sum(String prop) {
    var total = 0.0;
    for (final attachment in attachments) {
      total += (attachment.props[prop] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _product(String prop) {
    var factor = 1.0;
    for (final attachment in attachments) {
      factor *= (attachment.props[prop] as num?)?.toDouble() ?? 1;
    }
    return factor;
  }

  /// §5.1: the mechanical group, after optics and grips.
  ///
  /// Never below one: no clamp-on part makes a worn barrel into a match rifle,
  /// and a floor here is cheaper than discovering the day somebody stacks four
  /// of them that MOA can go negative.
  double get moa {
    final adjusted = _base('moa', 4) + _sum('moa_delta');
    return adjusted < 1 ? 1 : adjusted;
  }

  /// §5.3: how much of the settling time is left after a laser or a grip.
  double get settleMultiplier {
    final factor = _product('settle_multiplier');
    return factor < 0.35 ? 0.35 : factor;
  }

  /// §5.6.1: what it is heard from, with a suppressor's multiplier applied.
  double get noiseRangeM =>
      _base('noise_range_m', 700) * _product('noise_range_multiplier');

  /// §5.3: rounds, including whatever an extended magazine adds.
  int get magazine => (_base('magazine', 1) + _sum('magazine_bonus')).round();

  /// §5.3: seconds to change it. A longer magazine is slower to seat.
  Duration get reloadTime => Duration(
    milliseconds:
        ((_base('reload_seconds', 3) + _sum('reload_seconds_delta')) * 1000)
            .round(),
  );

  /// §14/§6.2: light thrown by anything clamped to the weapon.
  ///
  /// ⚠️ Light works both ways, exactly as the hand torch's own note says: it
  /// is seen further than it reaches. Nothing here uses it yet — the enemies
  /// of §6.2 notice by distance alone — and that is a debt, not a decision.
  double get lightRadiusM {
    var best = 0.0;
    for (final attachment in attachments) {
      final light = (attachment.props['light_radius_m'] as num?)?.toDouble();
      if (light != null && light > best) best = light;
    }
    return best;
  }
}
