/// Using something, and how long it takes (§4.7, §2.1a).
///
/// §4.7 gives realistic times and they are the point: a sandwich is sixty to
/// ninety seconds, half a litre of water twenty-five, a tourniquet forty-five,
/// suturing twelve to twenty minutes. §2.1a calls these actions rather than
/// occupations — they suspend whatever is running and resume it afterwards —
/// and the reason they matter is that every one of them is time spent standing
/// somewhere, which is the only currency this game charges in.
///
/// **Effects come from the item's own data.** Calories and water are on the
/// food, the bleeding grade is on the dressing. Nothing here knows about
/// particular items, so an item added by a content pack (§4.1) can be eaten
/// without a new build.
library;

import '../items/item.dart';
import '../sim/occupation.dart';
import '../sim/physiology.dart';

/// What using one of something does.
class ItemUse {
  const ItemUse({
    required this.action,
    required this.duration,
    this.kcal = 0,
    this.waterMl = 0,
    this.stopsBleedingTo,
    this.consumesItem = true,
    this.requiresStationary = false,
    this.illnessChance = 0,
  });

  /// Which of §2.1a's actions this is, for the label and for what it suspends.
  final ActionKind action;

  final Duration duration;

  final double kcal;
  final double waterMl;

  /// The worst grade of bleeding this brings the character down to (§2.6).
  /// Null for anything that is not first aid.
  final BleedTier? stopsBleedingTo;

  /// False for something with uses left in it — a first aid kit holds four.
  final bool consumesItem;

  /// §4.7: suturing and a drip are not done while walking.
  final bool requiresStationary;

  /// Untreated water (§4.7). Carried here so the caller can roll it; this
  /// class stays a description rather than a decision.
  final double illnessChance;
}

/// Reads what using [item] would do, or null for something that is not used.
///
/// Deliberately data-driven: the props were written in stage 4.1 with these
/// figures in them, and reading them back is what makes a content pack's
/// tinned soup as edible as the bundled one.
ItemUse? useOf(ItemDefinition item) {
  final seconds = (item.props['use_seconds'] as num?)?.toDouble();
  final consumeSeconds = (item.props['consume_seconds'] as num?)?.toDouble();

  switch (item.kind) {
    case ItemKind.food:
      if (consumeSeconds == null) return null;
      final water = (item.props['water_ml'] as num?)?.toDouble() ?? 0;
      final kcal = (item.props['kcal'] as num?)?.toDouble() ?? 0;

      return ItemUse(
        // §4.7 separates them because they take different times, and because
        // "drinking" is what a player looks for when the water bar is low.
        action: water > kcal ? ActionKind.drinking : ActionKind.eating,
        duration: Duration(seconds: consumeSeconds.round()),
        kcal: kcal,
        waterMl: water,
        illnessChance: (item.props['illness_chance'] as num?)?.toDouble() ?? 0,
      );

    case ItemKind.medical:
      if (seconds == null) return null;
      final stops = item.props['stops_bleeding_class'];

      return ItemUse(
        action: switch (stops) {
          'arterial' => ActionKind.tourniquet,
          'strong' => ActionKind.suturing,
          _ => ActionKind.dressing,
        },
        duration: Duration(seconds: seconds.round()),
        // A dressing that handles moderate bleeding brings anything worse down
        // to what it can hold, and anything lighter to none at all (§2.6).
        stopsBleedingTo: stops is String ? BleedTier.none : null,
        waterMl: (item.props['restores_blood_ml'] as num?)?.toDouble() ?? 0,
        // A kit has four uses in it; a bandage has one.
        consumesItem: (item.props['uses'] as num?) == null,
        requiresStationary: item.props['requires_stationary'] == true,
      );

    // Everything else is carried, worn, read or built with. Nothing to use.
    case ItemKind.firearm:
    case ItemKind.melee:
    case ItemKind.armor:
    case ItemKind.backpack:
    case ItemKind.literature:
    case ItemKind.attachment:
    case ItemKind.tool:
    case ItemKind.crafting:
    case ItemKind.ammo:
    case ItemKind.material:
    case ItemKind.misc:
      return null;
  }
}

/// The worst bleeding a dressing can handle, from its own data (§2.6).
///
/// A pressure dressing stops a moderate bleed and does nothing useful against
/// an arterial one — §2.6 is explicit that only a tourniquet answers 350 ml a
/// minute, and pretending otherwise would make the tourniquet dead weight.
BleedTier handledBy(ItemDefinition item) =>
    switch (item.props['stops_bleeding_class']) {
      'superficial' => BleedTier.superficial,
      'moderate' => BleedTier.moderate,
      'strong' => BleedTier.severe,
      'arterial' => BleedTier.arterial,
      _ => BleedTier.none,
    };
