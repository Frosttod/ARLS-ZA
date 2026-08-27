/// The kit a developer build starts with, so §4, §5 and §8 can be looked at on
/// a phone before §10 has given the game a way to find anything.
///
/// ⚠️ Not shipped content. Nothing here is balance — it is the shortest list
/// that makes each system reachable from the first screen, and it lives out of
/// `main.dart` because it is a table, not behaviour.
library;

import '../inventory/inventory.dart';
import '../items/item_catalogue.dart';
import '../sim/body.dart';

/// What is worn: §6.2's cold, §4.4's armour, and boots to walk in.
const List<String> _worn = [
  'cloth_winter_jacket',
  'cloth_boots',
  'armor_vest_soft',
];

/// What is carried, and why each line is here.
const List<(String, int)> _carried = [
  // Something to fire and something to fire from it: §5 cannot be tried on a
  // phone without both.
  ('weapon_rifle_545', 1),
  ('ammo_545x39', 60),
  ('att_red_dot', 1),

  // §4.2: and something to put the rounds in. A magazine-fed rifle with no
  // magazine cannot be fired at all, and §10 only drops these on military
  // ground — which is not somewhere every tester has to hand.
  ('mag_rifle_545', 2),

  // §18.3: the tool every shelter module asks for. Same reason: a walk that
  // has to find a hammer before any of §8.4 can be looked at is a walk, not a
  // test.
  ('melee_hammer', 1),
  ('tool_multitool', 1),
  ('food_canned_meat', 2),
  ('drink_water_bottle_500', 2),
  ('med_bandage', 3),
  ('melee_knife', 1),
  ('mat_wood', 4),
  ('tool_flashlight', 1),
];

/// [now] with the tester's kit in it, worn and packed.
Inventory testerKit(
  Inventory now,
  ItemCatalogue catalogue, {
  required BodyProfile body,
}) {
  var next = now.packId == null ? now.withPack('pack_daypack') : now;

  for (final id in _worn) {
    next = next.wear(id, catalogue);
  }
  for (final line in _carried) {
    next = next.add(line.$1, catalogue, body: body, count: line.$2).inventory;
  }

  // §4.6.4: a copy of its own length, so the reading path has something to
  // open without walking to a library first.
  return next
      .add('lit_guide_survival', catalogue, body: body, pagesTotal: 160)
      .inventory;
}
