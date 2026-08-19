/// Magazines as things, not as a number on a weapon (§5.5.4, §4.2).
///
/// The old model kept one integer — how many rounds were in the gun — and no
/// magazines at all. That made a reload an abstraction: press the button, wait
/// the seconds, be full. Everything §5.5.4 is *about* went missing with it.
/// There is nothing to run out of but loose rounds, no reason to walk away
/// from a fight to prepare, and no difference between a soldier with three
/// full magazines and one with three hundred loose rounds in a bag.
///
/// So a magazine is an item with a capacity and a count of what is in it, and
/// the two acts are separate:
///
/// - **Swapping** one in is fast, and is what §5.5.4's five metres interrupt.
/// - **Filling** an empty one is slow, and is what a player does somewhere
///   quiet, ahead of time, because it cannot be done with anything nearby.
///
/// ⚠️ Not every weapon has one. §4.2's own reload notes already said which:
/// the revolver, the pump shotgun and the Mosin are fed a round at a time, and
/// so is anything else that ever carries `feed: loose`. Those keep the old
/// behaviour, where rounds go straight from the pack into the gun.
library;

import '../items/item.dart';
import '../items/item_catalogue.dart';

/// How a weapon is fed (§4.2).
enum Feed {
  /// A box magazine, swapped as a unit.
  magazine,

  /// A round at a time: the revolver, the pump, the bolt gun, and the bow.
  loose;

  static Feed of(ItemDefinition weapon) =>
      (weapon.props['feed'] as String?) == 'loose' ? Feed.loose : Feed.magazine;
}

/// What a magazine holds, and what it is holding.
///
/// A value: filling one gives a new one back, exactly as everything else in
/// the simulation works.
class Magazine {
  const Magazine({
    required this.itemId,
    required this.capacity,
    required this.caliber,
    required this.rounds,
  });

  /// Reads a magazine out of the catalogue, or null for anything that is not
  /// one.
  static Magazine? of(ItemDefinition item, {int rounds = 0}) {
    if (item.props['capacity'] == null) return null;

    final capacity = (item.props['capacity'] as num).toInt();
    final caliber = item.props['caliber'] as String?;
    if (capacity <= 0 || caliber == null) return null;

    return Magazine(
      itemId: item.id,
      capacity: capacity,
      caliber: caliber,
      rounds: rounds.clamp(0, capacity),
    );
  }

  final String itemId;
  final int capacity;

  /// What it takes, matched against the weapon's own calibre.
  final String caliber;

  final int rounds;

  bool get isEmpty => rounds <= 0;
  bool get isFull => rounds >= capacity;
  int get room => capacity - rounds;

  double get fraction => capacity <= 0 ? 0 : rounds / capacity;

  /// §4.2: whether this magazine goes in that weapon.
  ///
  /// By calibre, which is the only thing that decides it. A pistol magazine
  /// and a submachine gun magazine in 9x19 are different items with different
  /// capacities, and both fit both — which is true, and is the sort of thing
  /// worth finding on a walk.
  bool fits(ItemDefinition weapon) =>
      Feed.of(weapon) == Feed.magazine && weapon.props['caliber'] == caliber;

  /// Puts [count] rounds in, and says how many actually went.
  MagazineFill fill(int count) {
    final took = count < room ? count : room;
    if (took <= 0) return MagazineFill(magazine: this, took: 0);

    return MagazineFill(magazine: _with(rounds + took), took: took);
  }

  /// One round out, for a shot.
  Magazine get fired => rounds <= 0 ? this : _with(rounds - 1);

  /// Everything out, for a player stripping it back into the pack.
  MagazineFill get emptied => MagazineFill(magazine: _with(0), took: rounds);

  Magazine _with(int next) => Magazine(
    itemId: itemId,
    capacity: capacity,
    caliber: caliber,
    rounds: next.clamp(0, capacity),
  );
}

/// The result of moving rounds into or out of a magazine.
class MagazineFill {
  const MagazineFill({required this.magazine, required this.took});

  final Magazine magazine;

  /// How many rounds actually moved. Zero when it was already full, or empty.
  final int took;
}

/// §4.2: how long it takes to put [count] rounds into a magazine by hand.
///
/// ⚠️ Deliberately slow, and deliberately not the reload of §5.5.4. Loading a
/// thirty-round magazine is about half a minute of thumbing rounds in, which
/// is why it is something done in a shelter rather than behind a car — and why
/// carrying a second full magazine is worth its two hundred grams.
Duration fillTime(int count) =>
    Duration(milliseconds: (count * kFillSecondsPerRound * 1000).round());

/// §4.2: a round a second, near enough, for a magazine filled by thumb.
const double kFillSecondsPerRound = 1.0;

/// Every round in [catalogue] that a weapon of [caliber] can fire.
///
/// ⚠️ Looked up, not derived from the id. `ammo_545x39` is `5.45x39` with the
/// dot taken out and `ammo_12ga_buck` is not that pattern at all — a
/// convention that happens to hold for five of eight rounds is a convention
/// that breaks on the sixth. The calibre is a field; this reads the field.
List<ItemDefinition> ammoFor(String caliber, ItemCatalogue catalogue) => [
  for (final item in catalogue.all)
    if (item.props['caliber'] == caliber && item.id.startsWith('ammo_')) item,
];
