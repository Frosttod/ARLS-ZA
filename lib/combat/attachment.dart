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

import 'dart:math' as math;

import '../inventory/inventory.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import 'magazine_item.dart';

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

/// Where on the weapon a part goes (§5.6.3).
///
/// A weapon is not a bag with a number of pockets. It has a barrel, a rail, a
/// grip and a magazine well, and each of them holds one thing — which is why
/// the interface offers a button per place rather than a list of everything
/// that fits. A player fitting an optic is choosing what goes *on the rail*,
/// not spending an abstract slot.
enum AttachmentSlot {
  /// The magazine well. Not a rail, but the same rule: one at a time.
  magazine,

  /// On top. Optics.
  optic,

  /// The muzzle. A suppressor and nothing else.
  barrel,

  /// Under the handguard.
  grip,

  /// The side rail: a laser or a light, and only one of them.
  ///
  /// ⚠️ Real rifles carry both. This game gives one, deliberately: both run
  /// on batteries and both are seen by things that should not see you
  /// (§6.2), so choosing which is a decision worth having.
  rail,
}

/// Which place [item] goes in, or null for anything that is not a part.
///
/// ⚠️ The property is `mount`, not `slot`. `slot` was taken: it is where a
/// garment sits on the *body* (§4.4), and naming this one the same made every
/// attachment look like a piece of clothing for a body part that does not
/// exist.
AttachmentSlot? slotOf(ItemDefinition item) => switch (item.props['mount']) {
  'magazine' => AttachmentSlot.magazine,
  'optic' => AttachmentSlot.optic,
  'barrel' => AttachmentSlot.barrel,
  'grip' => AttachmentSlot.grip,
  'rail' => AttachmentSlot.rail,
  _ => null,
};

/// Whether [part] goes on [weapon] at all — magazines included.
///
/// ⚠️ [fitsWeapon] asks for [ItemKind.attachment], and a magazine is not one:
/// the catalogue calls its type `magazine`, which no kind matches, so every
/// magazine in the game is an [ItemKind.misc]. The weapon sheet asked
/// [fitsWeapon] and was told no, every time — so the magazine well never
/// appeared, and the only way to seat a magazine was the reload button.
///
/// Kept separate from [fitsWeapon] deliberately. That one also decides what
/// counts as *fitted* for the interim rule above, and a bag of spare magazines
/// is not a rifle with five magazines in it.
bool partFitsWeapon(ItemDefinition part, ItemDefinition weapon) {
  if (fitsWeapon(part, weapon)) return true;

  final magazine = Magazine.of(part);
  return magazine != null && magazine.fits(weapon);
}

/// §5.6.3: how many things this weapon can carry at once.
///
/// Rails, a barrel thread, a magazine well — a revolver has less to bolt
/// anything to than a carbine, and the data says which is which.
int attachmentSlots(ItemDefinition weapon) =>
    (weapon.props['attachment_slots'] as num?)?.toInt() ?? 0;

/// How many of [attachments] count against those slots.
///
/// ⚠️ The magazine well is not a rail. Counting the magazine as a slot meant
/// seating one cost an optic, which is nonsense on a rifle that cannot fire
/// without it — the well is part of the weapon, not something bolted to it.
int slotsUsedBy(Iterable<ItemDefinition> attachments) {
  var used = 0;
  for (final part in attachments) {
    if (slotOf(part) != AttachmentSlot.magazine) used++;
  }
  return used;
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

/// What one part does, in the units it is measured in (§5.1, §5.6.1).
///
/// One short string per place on the weapon, so the HUD can say `Kolimator
/// −1.2 MOA` rather than making a player open a sheet to find out whether the
/// thing bolted to their rifle is doing anything.
///
/// ⚠️ The suppressor is given in decibels because that is how anybody talks
/// about one, but the number is **derived from the range multiplier in the
/// data**, not typed in beside it: sound falls off with distance, so cutting
/// the range something is heard from to 0.29 of it is about eleven decibels,
/// not the thirty-five a catalogue would claim. One number, one source. If the
/// suppression should be stronger, the multiplier is the thing to change.
String? attachmentEffect(ItemDefinition part, {int? rounds, int? capacity}) {
  final parts = <String>[];

  if (capacity != null) parts.add('${rounds ?? 0} / $capacity');

  final moa = (part.props['moa_delta'] as num?)?.toDouble();
  if (moa != null && moa != 0) {
    parts.add('${moa < 0 ? '−' : '+'}${moa.abs().toStringAsFixed(1)} MOA');
  }

  final noise = (part.props['noise_range_multiplier'] as num?)?.toDouble();
  if (noise != null && noise > 0 && noise != 1) {
    // Range to decibels: intensity goes with the square of distance, so a
    // range ratio r is 20·log₁₀(r) decibels.
    final db = 20 * (math.log(noise) / math.ln10);
    parts.add('${db < 0 ? '−' : '+'}${db.abs().round()} dB');
  }

  final settle = (part.props['settle_multiplier'] as num?)?.toDouble();
  if (settle != null && settle != 1) {
    parts.add('−${((1 - settle) * 100).round()}% s');
  }

  final light = (part.props['light_radius_m'] as num?)?.toDouble();
  if (light != null && light > 0) parts.add('${light.round()} m');

  return parts.isEmpty ? null : parts.join(' · ');
}

/// Ta broń, którą postać trzyma, a nie jej definicja (§5.3, §5.6.3).
///
/// ⚠️ **Sztuka, nie wpis w katalogu.** Dwa karabiny w jednym plecaku to dwa
/// karabiny: ten z tłumikiem jest tym, który warto nieść do miasta, i tylko
/// egzemplarz wie, co ma na sobie.
CarriedItem? wieldedFirearm(Inventory inventory, ItemCatalogue catalogue) {
  for (final line in inventory.worn) {
    if (catalogue[line.itemId]?.kind == ItemKind.firearm) return line;
  }
  return null;
}

/// §5.6.3: co siedzi na broni w ręce.
List<ItemDefinition> attachmentsInHand(
  Inventory inventory,
  ItemCatalogue catalogue,
) {
  final line = wieldedFirearm(inventory, catalogue);
  if (line == null) return const [];

  return [
    for (final id in line.attachments)
      if (catalogue[id] != null) catalogue[id]!,
  ];
}
