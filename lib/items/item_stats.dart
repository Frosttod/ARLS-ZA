/// What is worth knowing about an item, and which way is better (§4.2–§4.7).
///
/// Every kind keeps its own numbers in [ItemDefinition.props], and a player
/// choosing between two vests needs those numbers side by side rather than a
/// verdict. This turns the untyped bag into an ordered list of readings, with
/// one extra thing the props do not carry: which direction is an improvement.
///
/// **That direction is the whole point.** Two hundred grams more is worse and
/// two hundred joules more is better, and nothing in the data says so. Without
/// it a comparison can show both columns and still leave somebody counting on
/// their fingers in a street.
library;

import 'item.dart';

/// One reading about an item.
class ItemStat {
  const ItemStat({
    required this.key,
    required this.value,
    required this.unit,
    required this.higherIsBetter,
    this.decimals = 0,
  });

  /// Localisation key suffix, resolved by the UI (§1.1).
  final String key;

  final double value;
  final String unit;

  /// Null where neither direction is an improvement — a calibre is not better
  /// or worse, it is a different resource (§10.3.3).
  final bool? higherIsBetter;

  final int decimals;

  String get formatted => '${value.toStringAsFixed(decimals)} $unit'.trim();
}

/// The readings for an item, in the order they are worth reading.
///
/// Mass and bulk come last on purpose. They are the same two numbers for every
/// item and they are already on the row the player tapped; what they came here
/// for is what makes this vest different from that one.
List<ItemStat> statsOf(ItemDefinition item, {double? condition}) {
  double? prop(String name) => (item.props[name] as num?)?.toDouble();

  ItemStat? stat(
    String key,
    String name,
    String unit, {
    bool? higherIsBetter = true,
    int decimals = 0,
  }) {
    final value = prop(name);
    return value == null
        ? null
        : ItemStat(
            key: key,
            value: value,
            unit: unit,
            higherIsBetter: higherIsBetter,
            decimals: decimals,
          );
  }

  final specific = switch (item.kind) {
    ItemKind.firearm => [
      stat('energy', 'muzzle_energy_j', 'J'),
      // Fewer minutes of angle is a tighter group (§5.1.1), so down is up.
      stat('moa', 'moa', 'MOA', higherIsBetter: false, decimals: 1),
      stat('magazine', 'magazine', ''),
      stat('reload', 'reload_seconds', 's', higherIsBetter: false, decimals: 1),
      stat('range', 'effective_range_m', 'm'),
      // §5.6.2: noise is what walks towards you.
      stat('noise', 'noise_range_m', 'm', higherIsBetter: false),
    ],
    ItemKind.melee => [
      stat('bleed', 'blood_ml_per_hit', 'ml'),
      stat('swing', 'swing_seconds', 's', higherIsBetter: false, decimals: 1),
      stat('reach', 'reach_m', 'm', decimals: 1),
      // `strength_required` is in the data and stays there for §7's skills,
      // but it is not shown: a blade in the pack is a blade the character is
      // already carrying, so a number saying they might not manage to swing
      // it answers a question nobody asked.
      stat('noise', 'noise_range_m', 'm', higherIsBetter: false),
    ],
    ItemKind.armor => [
      stat('insulation', 'insulation_clo', 'clo', decimals: 2),
      stat('protection', 'protection_level', ''),
      stat('coverage', 'coverage_pct', '%'),
    ],
    ItemKind.backpack => [
      stat('capacity', 'capacity_l', 'l'),
      stat('carry', 'comfort_carry_bonus_kg', 'kg'),
    ],
    ItemKind.food => [
      stat('kcal', 'kcal', 'kcal'),
      stat('water', 'water_ml', 'ml'),
      stat('eatTime', 'consume_seconds', 's', higherIsBetter: false),
    ],
    ItemKind.medical => [
      stat('useTime', 'use_seconds', 's', higherIsBetter: false),
      stat('uses', 'uses', ''),
      stat('blood', 'restores_blood_ml', 'ml'),
    ],
    ItemKind.literature => [
      stat('pagesMin', 'pages_min', ''),
      stat('pagesMax', 'pages_max', ''),
      stat('xpPerPage', 'xp_per_page', ''),
    ],
    // §5.1, §5.6.3: what it does to the weapon it is on, and every one of
    // these reads as a plus even when the number goes down — a tighter group
    // is fewer minutes of angle.
    ItemKind.attachment => [
      stat('moa', 'moa_delta', 'MOA', higherIsBetter: false, decimals: 1),
      stat('settle', 'settle_multiplier', '×',
          higherIsBetter: false, decimals: 2),
      stat('magazine', 'magazine_bonus', ''),
      stat('noise', 'noise_range_multiplier', '×',
          higherIsBetter: false, decimals: 2),
      stat('light', 'light_radius_m', 'm'),
      stat('battery', 'battery_hours', 'h'),
      stat('craftSkill', 'craft_skill', '%', higherIsBetter: false),
    ],

    ItemKind.tool => [
      stat('light', 'light_radius_m', 'm'),
      stat('battery', 'battery_hours', 'h'),
      stat(
        'craftTime',
        'craft_time_modifier',
        '',
        higherIsBetter: false,
        decimals: 2,
      ),
      stat('searchBonus', 'search_radius_bonus_m', 'm'),
    ],
    ItemKind.ammo || ItemKind.crafting || ItemKind.material || ItemKind.misc =>
      const <ItemStat?>[],
  };

  return [
    // How worn this copy is comes first: with two of a kind in the pack it is
    // often the only reading that differs, and it is the whole decision.
    if (condition != null)
      ItemStat(
        key: 'condition',
        value: condition,
        unit: '%',
        higherIsBetter: true,
      ),
    for (final reading in specific) ?reading,
    ItemStat(
      key: 'mass',
      value: item.weightKg,
      unit: 'kg',
      higherIsBetter: false,
      decimals: 2,
    ),
    ItemStat(
      key: 'bulk',
      value: item.volumeL,
      unit: 'l',
      higherIsBetter: false,
      decimals: 1,
    ),
  ];
}

/// The kinds where "which of these two" is a real question.
///
/// A tin of beans against another tin of beans is not a decision — both are
/// eaten, and the calories are on the row already. What is worth laying out
/// side by side is what gets *kept*: the vest that displaces a vest, the pack
/// that changes both carry limits, the rifle that will be the one fired.
const Set<ItemKind> _worthComparing = {
  ItemKind.firearm,
  ItemKind.melee,
  ItemKind.armor,
  ItemKind.backpack,
  ItemKind.tool,
  ItemKind.attachment,
};

/// Whether two items are worth putting side by side.
///
/// The same slot for anything worn — a vest against a vest, not a vest against
/// a coat — and the same kind for everything else, which is what a player
/// means by "should I swap this".
///
/// Two copies of one item *do* compare: found kit is worn kit, and 90% against
/// 40% is a real difference. Telling one copy from another is the caller's
/// job, since two entries of the same id are two different things to own.
bool comparable(ItemDefinition a, ItemDefinition b) {
  if (a.kind != b.kind) return false;
  if (!_worthComparing.contains(a.kind)) return false;

  final slotA = a.props['slot'];
  final slotB = b.props['slot'];
  if (slotA != null || slotB != null) return slotA == slotB;

  return true;
}

/// How [candidate] compares with [against] on one reading.
///
/// Positive is an improvement, negative is a loss, and zero is either equal or
/// a reading where neither direction means anything.
double improvement(ItemStat candidate, ItemStat against) {
  final better = candidate.higherIsBetter;
  if (better == null) return 0;

  final difference = candidate.value - against.value;
  return better ? difference : -difference;
}
