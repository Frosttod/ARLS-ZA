/// Loading a weapon, as moving things rather than as raising a number
/// (§5.3, §5.5.4, §4.2).
///
/// Everything here is a pure function over an [Inventory]: it takes a pack and
/// a weapon and gives back a pack. The interface calls it and saves the
/// result, which is what keeps the one part of this with real consequences —
/// rounds moving between a pack, a magazine and a chamber — out of a widget.
///
/// The two acts §4.2 separates:
///
/// - **[swapMagazine]** takes the magazine out and puts a fuller one in. Fast,
///   and what §5.5.4's five metres interrupt.
/// - **[fillMagazine]** thumbs loose rounds into one. Slow, and done somewhere
///   quiet — which is what makes carrying a second full magazine worth its two
///   hundred grams.
///
/// ⚠️ A weapon fed loose (§4.2: the revolver, the pump, the Mosin) has no
/// magazine to swap. Rounds go from the pack into the gun a round at a time,
/// which is what [loadLoose] does and what the old model did for everything.
library;

import '../inventory/inventory.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import 'attachment.dart';
import 'magazine_item.dart';

/// What is in the weapon, and what it could hold.
class WeaponLoad {
  const WeaponLoad({
    required this.line,
    required this.weapon,
    required this.rounds,
    required this.capacity,
    required this.magazine,
  });

  /// Reads the weapon in hand, or null for anything that is not a firearm.
  static WeaponLoad? of(CarriedItem line, ItemCatalogue catalogue) {
    final weapon = catalogue[line.itemId];
    if (weapon == null || weapon.kind != ItemKind.firearm) return null;

    final fitted = _fittedMagazine(line, catalogue);

    return WeaponLoad(
      line: line,
      weapon: weapon,
      rounds: line.rounds ?? 0,
      // ⚠️ The fitted magazine decides the capacity, not the weapon. That is
      // the whole point of magazines being things: a rifle with a thirty-round
      // box and the same rifle with a sixty-round drum are the same rifle.
      capacity: fitted?.capacity ?? _looseCapacity(weapon),
      magazine: fitted,
    );
  }

  final CarriedItem line;
  final ItemDefinition weapon;
  final int rounds;
  final int capacity;

  /// The magazine in the weapon, or null for one fed loose — or for a
  /// magazine-fed weapon somebody is carrying without one.
  final Magazine? magazine;

  Feed get feed => Feed.of(weapon);
  bool get isEmpty => rounds <= 0;
  bool get isFull => rounds >= capacity;
  int get room => capacity - rounds;

  /// §4.2: a magazine-fed weapon with nothing in it is not a club, it is a
  /// weapon waiting for a magazine — and saying which is the difference
  /// between "reload" and "you have no magazines".
  bool get needsMagazine => feed == Feed.magazine && magazine == null;

  static Magazine? _fittedMagazine(CarriedItem line, ItemCatalogue catalogue) {
    for (final id in line.attachments) {
      final item = catalogue[id];
      if (item == null) continue;

      final magazine = Magazine.of(item, rounds: line.rounds ?? 0);
      if (magazine != null) return magazine;
    }
    return null;
  }

  /// What a weapon fed a round at a time holds: §4.2's own figure, with
  /// whatever is clamped to it.
  static int _looseCapacity(ItemDefinition weapon) =>
      FittedWeapon(weapon: weapon).magazine;
}

/// The result of moving rounds about.
class LoadOutcome {
  const LoadOutcome({
    required this.inventory,
    required this.moved,
    this.line,
    this.refusal,
  });

  const LoadOutcome.refused(this.inventory, LoadRefusal this.refusal)
    : moved = 0,
      line = null;

  final Inventory inventory;

  /// How many rounds actually moved. Zero on a refusal.
  final int moved;

  /// The line as it now is, for whoever is going to move more rounds into it.
  ///
  /// ⚠️ Handed back rather than looked up again. A fill happens a round at a
  /// time (§4.2), and finding "the magazine" by item id between rounds picks
  /// the wrong one as soon as a player owns two — they are separate lines
  /// precisely so a half-full one stays half full.
  final CarriedItem? line;

  final LoadRefusal? refusal;

  bool get isDone => refusal == null;
}

/// True when [line] is one of the pieces [pack] actually holds.
///
/// ⚠️ Kept after §11.1's line names arrived, and deliberately. A name makes a
/// *rebuilt* copy findable again — which is what it was for — but it does not
/// make a piece that has been dropped, shelved or eaten reappear. This still
/// answers the question that matters here: is the thing about to be spent
/// still in the bag.
///
/// ⚠️ Everything here finds its line by identity, and [Inventory.withLine]
/// quietly returns an unchanged copy when it finds nothing. Handed a stale
/// handle — one captured before something else rebuilt the pack — a fill spent
/// the loose rounds and put them nowhere: they left the pack, never reached the
/// magazine, and were gone by the next save. Asked first, and refused out loud.
bool _holds(Inventory pack, CarriedItem line) {
  for (final entry in pack.carried) {
    if (entry.isSame(line)) return true;
  }
  for (final entry in pack.worn) {
    if (entry.isSame(line)) return true;
  }
  return false;
}

/// Why nothing happened, so the interface can say it out loud rather than
/// leaving a dead button.
enum LoadRefusal {
  /// The thing in hand is not a firearm.
  notAWeapon,

  /// Nothing in the pack fits it.
  noMagazine,

  /// There is a magazine, and it is no fuller than the one already in.
  nothingFuller,

  /// Nothing loose of the right calibre.
  noRounds,

  /// It is already full.
  full,

  /// The very piece is not in this pack any more — a handle went stale.
  ///
  /// Not a sentence a player should ever read: it means something moved under
  /// the action, and the right answer is to do nothing rather than to spend
  /// rounds into thin air.
  gone,
}

/// §5.5.4: takes the magazine out and puts the fullest fitting one in.
///
/// ⚠️ The one that comes out goes back in the pack **with what was left in
/// it**, which is the whole reason this is not "set rounds to thirty". A
/// player who swaps at half empty keeps that half, and finds it again as a
/// half-full magazine later — that is the bookkeeping §5.5.4 is asking for and
/// the reason a fight leaves you with something to do afterwards.
LoadOutcome swapMagazine(
  Inventory pack,
  CarriedItem weaponLine,
  ItemCatalogue catalogue,
) {
  if (!_holds(pack, weaponLine)) {
    return LoadOutcome.refused(pack, LoadRefusal.gone);
  }
  final load = WeaponLoad.of(weaponLine, catalogue);
  if (load == null) return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);
  if (load.feed == Feed.loose) {
    return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);
  }

  // The fullest one that fits. Ties go to the first, which keeps the choice
  // stable rather than shuffling identical magazines about.
  ({CarriedItem line, Magazine magazine})? best;

  for (final line in pack.carried) {
    final item = catalogue[line.itemId];
    if (item == null) continue;

    final magazine = Magazine.of(item, rounds: line.rounds ?? 0);
    if (magazine == null || !magazine.fits(load.weapon)) continue;
    if (best == null || magazine.rounds > best.magazine.rounds) {
      best = (line: line, magazine: magazine);
    }
  }

  if (best == null) return LoadOutcome.refused(pack, LoadRefusal.noMagazine);

  // Swapping a magazine for one that is no better is a way to waste §5.5.4's
  // seconds and nothing else.
  if (load.magazine != null && best.magazine.rounds <= load.rounds) {
    return LoadOutcome.refused(pack, LoadRefusal.nothingFuller);
  }

  var next = pack.removeLine(best.line, count: 1) ?? pack;

  // What came out, with what was left in it.
  //
  // ⚠️ Appended rather than added through the stacking path, and deliberately:
  // a magazine with nine rounds in it must never merge into a stack of full
  // ones. §4.7 makes the same rule for a half-drunk bottle, and for the same
  // reason — a stack of three where one is half empty is not a stack of three.
  final old = load.magazine;
  if (old != null) {
    next = Inventory(
      carried: [
        ...next.carried,
        CarriedItem(itemId: old.itemId, rounds: load.rounds),
      ],
      worn: next.worn,
      packId: next.packId,
    );
  }

  final fitted = weaponLine.copyWith(
    attachments: [
      for (final id in weaponLine.attachments)
        if (Magazine.of(catalogue[id]!) == null) id,
      best.magazine.itemId,
    ],
    rounds: best.magazine.rounds,
  );

  return LoadOutcome(
    inventory: next.withLine(weaponLine, fitted),
    moved: best.magazine.rounds,
  );
}

/// §4.2: thumbs loose rounds into a magazine in the pack.
/// [limit] caps how many rounds move, for §4.2's thumb: a fill is applied a
/// round at a time while the bar crosses, not in one lump at the end.
LoadOutcome fillMagazine(
  Inventory pack,
  CarriedItem magazineLine,
  ItemCatalogue catalogue, {
  int? limit,
}) {
  if (!_holds(pack, magazineLine)) {
    return LoadOutcome.refused(pack, LoadRefusal.gone);
  }
  final item = catalogue[magazineLine.itemId];
  if (item == null) return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);

  final magazine = Magazine.of(item, rounds: magazineLine.rounds ?? 0);
  if (magazine == null) {
    return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);
  }
  if (magazine.isFull) return LoadOutcome.refused(pack, LoadRefusal.full);

  final loose = _looseRounds(pack, magazine.caliber, catalogue);
  if (loose == 0) return LoadOutcome.refused(pack, LoadRefusal.noRounds);

  final rounds = limit == null || limit >= loose ? loose : limit;
  final filled = magazine.fill(rounds);
  if (filled.took <= 0) return LoadOutcome.refused(pack, LoadRefusal.full);

  final fuller = magazineLine.copyWith(rounds: filled.magazine.rounds);

  return LoadOutcome(
    inventory: _spendRounds(
      pack,
      magazine.caliber,
      filled.took,
      catalogue,
    ).withLine(magazineLine, fuller),
    moved: filled.took,
    line: fuller,
  );
}

/// §4.2: puts loose rounds straight into a weapon that has no magazine.
LoadOutcome loadLoose(
  Inventory pack,
  CarriedItem weaponLine,
  ItemCatalogue catalogue,
) {
  if (!_holds(pack, weaponLine)) {
    return LoadOutcome.refused(pack, LoadRefusal.gone);
  }
  final load = WeaponLoad.of(weaponLine, catalogue);
  if (load == null) return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);
  if (load.isFull) return LoadOutcome.refused(pack, LoadRefusal.full);

  final caliber = load.weapon.props['caliber'] as String?;
  if (caliber == null) {
    return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);
  }

  final available = _looseRounds(pack, caliber, catalogue);
  if (available == 0) return LoadOutcome.refused(pack, LoadRefusal.noRounds);

  final took = available < load.room ? available : load.room;

  return LoadOutcome(
    inventory: _spendRounds(
      pack,
      caliber,
      took,
      catalogue,
    ).withLine(weaponLine, weaponLine.copyWith(rounds: load.rounds + took)),
    moved: took,
  );
}

int _looseRounds(Inventory pack, String caliber, ItemCatalogue catalogue) {
  var rounds = 0;
  for (final line in pack.carried) {
    final item = catalogue[line.itemId];
    if (item?.kind == ItemKind.ammo && item?.props['caliber'] == caliber) {
      rounds += line.count;
    }
  }
  return rounds;
}

Inventory _spendRounds(
  Inventory pack,
  String caliber,
  int count,
  ItemCatalogue catalogue,
) {
  var next = pack;
  var left = count;

  while (left > 0) {
    final line = next.carried
        .where(
          (line) =>
              catalogue[line.itemId]?.kind == ItemKind.ammo &&
              catalogue[line.itemId]?.props['caliber'] == caliber,
        )
        .firstOrNull;
    if (line == null) break;

    final took = line.count < left ? line.count : left;
    next = next.removeLine(line, count: took) ?? next;
    left -= took;
  }

  return next;
}

/// §4.2: tips the rounds out of a magazine and back into the pack.
///
/// The mirror of [fillMagazine], and the reason both exist: a magazine is
/// emptied to put its rounds into a different one, or to leave the weight
/// behind. Same clock, same thumb.
LoadOutcome emptyMagazine(
  Inventory pack,
  CarriedItem magazineLine,
  ItemCatalogue catalogue, {
  int? limit,
}) {
  if (!_holds(pack, magazineLine)) {
    return LoadOutcome.refused(pack, LoadRefusal.gone);
  }
  final item = catalogue[magazineLine.itemId];
  if (item == null) return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);

  final magazine = Magazine.of(item, rounds: magazineLine.rounds ?? 0);
  if (magazine == null) {
    return LoadOutcome.refused(pack, LoadRefusal.notAWeapon);
  }
  if (magazine.isEmpty) return LoadOutcome.refused(pack, LoadRefusal.noRounds);

  final rounds = limit == null || limit >= magazine.rounds
      ? magazine.rounds
      : limit;
  if (rounds <= 0) return LoadOutcome.refused(pack, LoadRefusal.noRounds);

  // What the rounds become again: the catalogue decides which, because a
  // calibre can have more than one (§10.3.3 gives 12 ga two).
  final ammo = ammoFor(magazine.caliber, catalogue).firstOrNull;
  if (ammo == null) return LoadOutcome.refused(pack, LoadRefusal.noRounds);

  final emptied = magazineLine.copyWith(rounds: magazine.rounds - rounds);

  // ⚠️ Into the stack that is already there, not a new line each time.
  //
  // This is called once per round while the bar crosses (§4.2), so appending
  // would turn one magazine into thirty rows of a single round — which is
  // both wrong and unreadable. Loose ammunition stacks; that is what makes it
  // loose.
  var merged = false;
  final lines = <CarriedItem>[
    for (final line in pack.carried)
      if (line.isSame(magazineLine))
        emptied
      else if (!merged && line.itemId == ammo.id && line.rounds == null) ...[
        () {
          merged = true;
          return line.copyWith(count: line.count + rounds);
        }(),
      ] else
        line,
  ];

  if (!merged) lines.add(CarriedItem(itemId: ammo.id, count: rounds));

  return LoadOutcome(
    inventory: Inventory(carried: lines, worn: pack.worn, packId: pack.packId),
    moved: rounds,
    line: emptied,
  );
}
