/// What a player is carrying, and the two limits on it (§18.1a).
///
/// **No stack-count limit anywhere.** §18.1a is explicit: a hard cap on pieces
/// would break the game's own recipes — Store L3 wants 36 wood, Workshop L3
/// wants 42 metal — and would never bind in practice, because mass or bulk
/// binds first. Twelve pieces of wood is 24 kg, and that is the whole limit.
///
/// **Two limits that behave differently.** Mass has a comfortable figure and a
/// hard one (§1.3: 0.30 and 0.45 of body mass). Going over the comfortable one
/// is allowed — §1.3 forbids slowing a real walking player, so the price is
/// metabolic (§2.3) and never a block. Going over the hard one is refused: the
/// player physically cannot lift it. Volume has one limit and it is hard.
///
/// **Worn clothing costs mass but not volume**, and neither does the pack
/// itself. A coat on your back does not fill your rucksack. This is the whole
/// reason §10.3.4's combat kit fits: half of it is being worn.
library;

import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../combat/attachment.dart';
import '../combat/magazine_item.dart';
import 'body_slots.dart';
import '../sim/body.dart';

/// Pockets. §18.1a's floor for a player with no bag at all.
const double kPocketCapacityL = 12;

/// §18.1a: the shelter store has both limits too, three litres per kilogram.
/// Without it 312 pieces of plastic fit by mass and would need 624 litres.
const double kStoreLitresPerKg = 3;

/// One line in the inventory.
///
/// A stackable item is one entry with a count. Anything carrying its own state
/// — a worn rifle, a part-read book (§4.6.3) — is one entry per piece, because
/// two of them are not interchangeable.
/// Where a piece of kit goes on a person, by what it is (§4.4, §5.5.1).
///
/// Garments carry their own `slot`; nothing else does. A weapon is not a
/// garment and §4.4 never gave it a place, but the game has to know which one
/// is in the hand — it is the one that fires, and the one a clinch is fought
/// with — so a firearm or a blade goes to the hand and displaces whatever was
/// there. Two knives are not held at once for two knives' worth of reach.
String? wearSlotOf(ItemDefinition definition) {
  final named = definition.props['slot'];
  if (named is String) return named;

  return switch (definition.kind) {
    ItemKind.firearm || ItemKind.melee => BodySlot.hand.wire,
    ItemKind.backpack => 'backpack',
    _ => null,
  };
}

/// Less of a piece than this is nothing (§4.7).
///
/// A last two per cent of a bottle is a line in the pack that costs a tap to
/// be rid of and gives back a mouthful. Below this it is simply finished.
const double kPortionCrumb = 0.05;

class CarriedItem {
  const CarriedItem({
    required this.itemId,
    this.count = 1,
    this.condition,
    this.pagesTotal,
    this.pagesRead = 0,
    this.noteId,
    this.portion = 1,
    this.attachments = const [],
    this.rounds,
    this.salvageSeconds,
  });

  final String itemId;
  final int count;

  /// 0–100 for anything that wears out, null for anything that does not.
  final double? condition;

  /// Rolled per copy at generation (§4.6.4), so two copies of one title differ
  /// in mass, reading time and XP.
  final int? pagesTotal;
  final int pagesRead;

  /// Which note this copy is (§19.1). Null for everything that is not one.
  final String? noteId;

  /// §5.6.3: what is bolted to this particular weapon, by item id.
  ///
  /// On the piece rather than on the player, because two rifles in one pack
  /// are two rifles: the one with the suppressor is the one worth carrying to
  /// a town, and the other is the one to leave.
  final List<String> attachments;

  /// §5.3: how many rounds are in this piece, or null for anything that does
  /// not hold any.
  ///
  /// ⚠️ On the piece, because that is where they are. It was one integer in
  /// the interface — what is in the gun — and nothing ever wrote it down:
  /// reloading took thirty rounds out of the pack, put them in a field in
  /// memory, and closing the app destroyed them. A player lost a magazine
  /// every restart.
  ///
  /// It also means a loaded rifle stays loaded through being put on a shelf,
  /// dropped on the pavement and picked up again, because all three carry the
  /// line rather than the id.
  final int? rounds;

  /// §18.6: how many seconds of taking-apart this piece has already had.
  ///
  /// ⚠️ Null means untouched. **Anything else means opened up, and a thing
  /// that has been opened up does not work any more** — half a rifle is not a
  /// rifle, and half a coat does not keep the rain off. That is what makes
  /// stopping half way a real decision rather than a free look inside.
  ///
  /// On the piece rather than on the job, so the bench is free while a
  /// half-finished rifle sits in the pack waiting to be gone back to. A job is
  /// one pair of hands; this is a thing on a shelf.
  final int? salvageSeconds;

  /// §18.6: whether this piece has been opened up and not finished.
  bool get isPartlyDismantled => (salvageSeconds ?? 0) > 0;

  /// How much of this piece is left, 0–1 (§4.7).
  ///
  /// A bottle put down half way through is half a bottle, not a wasted one and
  /// not a full one. Only ever below 1 on a line of exactly one piece: what is
  /// part-used is split off from the stack it came from, because a stack of
  /// three where one of them is half drunk is not a stack of three.
  final double portion;

  CarriedItem copyWith({
    int? count,
    double? condition,
    int? pagesRead,
    double? portion,
    List<String>? attachments,
    int? rounds,
    int? salvageSeconds,
  }) => CarriedItem(
    itemId: itemId,
    count: count ?? this.count,
    condition: condition ?? this.condition,
    pagesTotal: pagesTotal,
    pagesRead: pagesRead ?? this.pagesRead,
    noteId: noteId,
    portion: portion ?? this.portion,
    attachments: attachments ?? this.attachments,
    rounds: rounds ?? this.rounds,
    salvageSeconds: salvageSeconds ?? this.salvageSeconds,
  );

  /// Mass of this line, using the rolled page count where there is one.
  /// What this piece weighs, in kilograms.
  ///
  /// ⚠️ Pass the catalogue for anything that can carry attachments. A rifle
  /// with a suppressor, an optic and a long magazine is nearly a kilogram
  /// heavier than the same rifle bare, and §18.1a's whole point is that mass
  /// is the thing a player runs out of — a bolt-on that costs nothing to carry
  /// is a bolt-on nobody would ever leave behind.
  double massKg(ItemDefinition definition, {ItemCatalogue? catalogue}) {
    final pages = pagesTotal;
    if (pages != null) {
      final perPage = (definition.props['g_per_page'] as num?)?.toDouble() ?? 0;
      final cover = (definition.props['cover_g'] as num?)?.toDouble() ?? 0;
      return (pages * perPage + cover) / 1000 * count;
    }

    // Half a bottle weighs half. The bulk does not follow, because the bottle
    // is the same bottle either way — which is the honest asymmetry between
    // §18.1a's two limits.
    return (definition.weightKg + _fittedMassKg(catalogue)) * count * portion;
  }

  double volumeL(ItemDefinition definition, {ItemCatalogue? catalogue}) {
    final pages = pagesTotal;
    if (pages != null) {
      final perPage = (definition.props['l_per_page'] as num?)?.toDouble() ?? 0;
      return pages * perPage * count;
    }
    return (definition.volumeL + _fittedVolumeL(catalogue)) * count;
  }

  double _fittedMassKg(ItemCatalogue? catalogue) {
    if (catalogue == null || attachments.isEmpty) return 0;

    var total = 0.0;
    for (final id in attachments) {
      total += catalogue[id]?.weightKg ?? 0;
    }
    return total;
  }

  double _fittedVolumeL(ItemCatalogue? catalogue) {
    if (catalogue == null || attachments.isEmpty) return 0;

    var total = 0.0;
    for (final id in attachments) {
      total += catalogue[id]?.volumeL ?? 0;
    }
    return total;
  }
}

/// Why something would not go in.
enum RefusalReason {
  /// Over the hard carry limit of §1.3. Not a warning — it cannot be lifted.
  tooHeavy,

  /// The pack is full. §18.1a's second axis, and the one that catches plastic
  /// and fabric long before their mass does.
  noRoom,

  /// No such item in the catalogue. A content pack that was removed, usually.
  unknownItem,
}

class InventoryChange {
  const InventoryChange.accepted(this.inventory)
    : refusal = null,
      acceptedCount = null;
  const InventoryChange.partial(
    this.inventory,
    this.acceptedCount,
    this.refusal,
  );
  const InventoryChange.refused(this.inventory, this.refusal)
    : acceptedCount = 0;

  final Inventory inventory;
  final RefusalReason? refusal;

  /// How many pieces fitted, when not all of them did. Null when everything did.
  final int? acceptedCount;

  bool get isAccepted => refusal == null;
}

/// The limits in force right now: body plus whatever is on the player's back.
class CarryLimits {
  const CarryLimits({
    required this.comfortKg,
    required this.maxKg,
    required this.capacityL,
  });

  final double comfortKg;
  final double maxKg;
  final double capacityL;

  factory CarryLimits.of(BodyProfile body, ItemDefinition? pack) {
    final comfortBonus =
        (pack?.props['comfort_carry_bonus_kg'] as num?)?.toDouble() ?? 0;
    final maxBonus =
        (pack?.props['max_carry_bonus_kg'] as num?)?.toDouble() ?? 0;

    return CarryLimits(
      comfortKg: body.carryComfortKg + comfortBonus,
      maxKg: body.carryMaxKg + maxBonus,
      capacityL:
          (pack?.props['capacity_l'] as num?)?.toDouble() ?? kPocketCapacityL,
    );
  }
}

class Inventory {
  const Inventory({this.carried = const [], this.worn = const [], this.packId});

  /// In the pack. Costs mass and volume.
  final List<CarriedItem> carried;

  /// On the body: clothing, armour, a weapon in hand. Costs mass only.
  final List<CarriedItem> worn;

  /// The pack itself. Costs mass, and is what sets [CarryLimits.capacityL].
  final String? packId;

  double massKg(ItemCatalogue catalogue) {
    var total = 0.0;
    for (final line in [...carried, ...worn]) {
      final definition = catalogue[line.itemId];
      if (definition != null) {
        total += line.massKg(definition, catalogue: catalogue);
      }
    }
    final pack = packId == null ? null : catalogue[packId!];
    return total + (pack?.weightKg ?? 0);
  }

  /// Only what is inside the pack. A coat on your back does not fill it, and
  /// neither does the pack.
  double volumeL(ItemCatalogue catalogue) {
    var total = 0.0;
    for (final line in carried) {
      final definition = catalogue[line.itemId];
      if (definition != null) {
        total += line.volumeL(definition, catalogue: catalogue);
      }
    }
    return total;
  }

  CarryLimits limits(BodyProfile body, ItemCatalogue catalogue) =>
      CarryLimits.of(body, packId == null ? null : catalogue[packId!]);

  /// True when the load is past comfortable. Never blocks anything — it raises
  /// the metabolic cost of walking (§2.3), which is the only lever §1.3 allows.
  bool isOverComfort(BodyProfile body, ItemCatalogue catalogue) =>
      massKg(catalogue) > limits(body, catalogue).comfortKg;

  /// How loaded the player is, as a fraction of the hard limit. Feeds the
  /// accuracy penalty of §5.1.5 and both HUD bars.
  double loadFraction(BodyProfile body, ItemCatalogue catalogue) =>
      massKg(catalogue) / limits(body, catalogue).maxKg;

  double fillFraction(BodyProfile body, ItemCatalogue catalogue) =>
      volumeL(catalogue) / limits(body, catalogue).capacityL;

  /// Puts [count] of an item in the pack, taking as many as fit.
  ///
  /// Partial acceptance is deliberate: a player standing over forty rounds of
  /// ammunition with room for twelve should get twelve, not a refusal.
  InventoryChange add(
    String itemId,
    ItemCatalogue catalogue, {
    required BodyProfile body,
    int count = 1,
    double? condition,
    int? pagesTotal,
    int pagesRead = 0,
    String? noteId,
    double portion = 1,
    List<String> attachments = const [],
    int? rounds,
    int? salvageSeconds,
  }) {
    final definition = catalogue[itemId];
    if (definition == null) {
      return InventoryChange.refused(this, RefusalReason.unknownItem);
    }

    final limit = limits(body, catalogue);
    final one = CarriedItem(
      itemId: itemId,
      condition: condition,
      pagesTotal: pagesTotal,
      pagesRead: pagesRead,
      noteId: noteId,
      // ⚠️ §4.7: how much of it is left comes back with it. Without this a
      // half-drunk bottle put on a shelf and picked up again was full, which
      // is unlimited water for the price of two taps.
      portion: portion,
      // §5.6.3: picking a rifle up off the pavement gives it back with what
      // was on it. Putting one down used to strip it.
      attachments: attachments,
      // ⚠️ §5.3, §18.6: and with what is in it, and how far somebody got
      // taking it apart. Both were silently dropped here, so a loaded rifle
      // put on the pavement came back empty — the same thirty rounds that
      // went missing across a restart, going missing a different way.
      rounds: rounds,
      salvageSeconds: salvageSeconds,
    );
    final massEach = one.massKg(definition, catalogue: catalogue);
    final volumeEach = one.volumeL(definition, catalogue: catalogue);

    final massRoom = limit.maxKg - massKg(catalogue);
    final volumeRoom = limit.capacityL - volumeL(catalogue);

    var fits = count;
    var reason = RefusalReason.tooHeavy;
    if (massEach > 0) {
      final byMass = (massRoom / massEach).floor();
      if (byMass < fits) {
        fits = byMass;
        reason = RefusalReason.tooHeavy;
      }
    }
    if (volumeEach > 0) {
      final byVolume = (volumeRoom / volumeEach).floor();
      if (byVolume < fits) {
        fits = byVolume;
        reason = RefusalReason.noRoom;
      }
    }

    if (fits <= 0) return InventoryChange.refused(this, reason);

    final next = _withAdded(
      definition,
      CarriedItem(
        itemId: itemId,
        count: fits,
        condition: condition,
        pagesTotal: pagesTotal,
        pagesRead: pagesRead,
        noteId: noteId,
        portion: portion,
        attachments: attachments,
        rounds: rounds,
        salvageSeconds: salvageSeconds,
      ),
    );

    return fits == count
        ? InventoryChange.accepted(next)
        : InventoryChange.partial(next, fits, reason);
  }

  Inventory _withAdded(ItemDefinition definition, CarriedItem line) {
    final lines = [...carried];

    // A note never stacks: two notes are two different people's messages.
    if (definition.stackable &&
        !definition.hasInstanceState &&
        line.noteId == null) {
      // Never into a part-used piece: half a bottle and a full one are not
      // two of the same thing.
      final index = lines.indexWhere(
        (entry) => entry.itemId == line.itemId && entry.portion >= 1,
      );
      if (index >= 0) {
        lines[index] = lines[index].copyWith(
          count: lines[index].count + line.count,
        );
        return Inventory(carried: lines, worn: worn, packId: packId);
      }
    } else if (line.count > 1) {
      // One entry per piece: each has its own condition or its own pages.
      for (var i = 0; i < line.count; i++) {
        lines.add(line.copyWith(count: 1));
      }
      return Inventory(carried: lines, worn: worn, packId: packId);
    }

    lines.add(line);
    return Inventory(carried: lines, worn: worn, packId: packId);
  }

  /// Takes [fraction] out of one piece of [line] (§4.7).
  ///
  /// A bottle put down half way through is half a bottle. The piece being used
  /// is split off from whatever stack it sat in first, because a stack of
  /// three where one is half drunk is not a stack of three — and what is left
  /// below a mouthful is gone rather than kept as a rounding error.
  Inventory consumePortion(CarriedItem line, double fraction) {
    final index = carried.indexWhere((entry) => identical(entry, line));
    if (index < 0) return this;

    final left = line.portion * (1 - fraction.clamp(0.0, 1.0));
    final lines = [...carried];

    if (line.count > 1) {
      lines[index] = line.copyWith(count: line.count - 1, portion: 1);
      if (left >= kPortionCrumb) {
        lines.insert(index + 1, line.copyWith(count: 1, portion: left));
      }
    } else if (left >= kPortionCrumb) {
      lines[index] = line.copyWith(portion: left);
    } else {
      lines.removeAt(index);
    }

    return Inventory(carried: lines, worn: worn, packId: packId);
  }

  /// §5.6.3: bolts [attachment] onto [line], out of the pack.
  ///
  /// Refused where it does not fit the weapon, where there is no rail left, or
  /// where one of the same is already on — a second red dot on one rifle is
  /// not a thing, and the arithmetic would happily stack it.
  /// Replaces [line] with [next], wherever it is.
  ///
  /// ⚠️ Both lists, because the one weapon whose state changes most is the one
  /// in the hand, and the hand is `worn`. The same trap [attach] documents.
  Inventory withLine(CarriedItem line, CarriedItem next) => Inventory(
    carried: [
      for (final entry in carried) identical(entry, line) ? next : entry,
    ],
    worn: [for (final entry in worn) identical(entry, line) ? next : entry],
    packId: packId,
  );

  Inventory attach(
    CarriedItem line,
    CarriedItem attachment,
    ItemCatalogue catalogue,
  ) {
    // ⚠️ The rule itself lives outside this class now, because the shelves
    // need it too: a rifle kept on a shelf takes a scope out of the pack
    // without either of them moving anywhere. One copy of §5.6.3's rules, two
    // places that ask about them.
    final fitted = fittedWith(line, attachment, catalogue);
    if (fitted == null) return this;

    // ⚠️ The weapon may be in the pack **or** in the hand, and the hand is
    // `worn`. Found on a phone: fitting anything to the rifle actually being
    // carried did nothing at all, because this only ever looked in `carried` —
    // and the one weapon a player wants a light on is the one they are holding.

    // Off the pack and onto the weapon: it is in one place or the other.
    final without = removeLine(attachment) ?? this;

    final lines = [
      for (final entry in without.carried)
        identical(entry, line) ? fitted : entry,
    ];
    final dressed = [
      for (final entry in without.worn) identical(entry, line) ? fitted : entry,
    ];

    // Neither list holds this very piece: it came from somewhere that is no
    // longer part of this inventory, and quietly bolting the part onto a copy
    // would lose it.
    final placed =
        lines.any((entry) => identical(entry, fitted)) ||
        dressed.any((entry) => identical(entry, fitted));
    if (!placed) return this;

    return Inventory(carried: lines, worn: dressed, packId: packId);
  }

  /// Takes one off again, back into the pack.
  Inventory detach(
    CarriedItem line,
    String attachmentId,
    ItemCatalogue catalogue, {
    required BodyProfile body,
  }) {
    if (!line.attachments.contains(attachmentId)) return this;

    // §5.3: what was in it goes with it.
    final part = catalogue[attachmentId];
    final magazine = part == null ? null : Magazine.of(part);
    final stripped = line.copyWith(
      attachments: [
        for (final id in line.attachments)
          if (id != attachmentId) id,
      ],
      rounds: magazine == null ? null : 0,
    );

    final lines = [
      for (final entry in carried) identical(entry, line) ? stripped : entry,
    ];
    final worn = [
      for (final entry in this.worn) identical(entry, line) ? stripped : entry,
    ];

    // Never destroyed for want of room: §18.1a's overflow is a state, not a
    // reason to lose something.
    return Inventory(
      carried: [
        ...lines,
        CarriedItem(
          itemId: attachmentId,
          rounds: magazine == null ? null : (line.rounds ?? 0),
        ),
      ],
      worn: worn,
      packId: packId,
    );
  }

  /// Removes pieces of one particular entry.
  ///
  /// Which entry matters as soon as a player carries two of a kind: a knife at
  /// 30% and a knife at 80% are one item id and two different things to own,
  /// and dropping "the knife" has to drop the one that was pointed at. Falls
  /// back to [remove] for a line that is no longer in the pack, so a stale tap
  /// still does something sensible rather than nothing.
  Inventory? removeLine(CarriedItem line, {int count = 1}) {
    final index = carried.indexWhere((entry) => identical(entry, line));
    if (index < 0) return remove(line.itemId, count: count);
    if (carried[index].count < count) return null;

    final lines = [...carried];
    if (lines[index].count == count) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(count: lines[index].count - count);
    }

    return Inventory(carried: lines, worn: worn, packId: packId);
  }

  /// Removes pieces of an item. Returns the inventory unchanged if there were
  /// not that many — dropping what you do not have is a bug, not a partial.
  Inventory? remove(String itemId, {int count = 1}) {
    final lines = [...carried];
    var left = count;

    for (var i = lines.length - 1; i >= 0 && left > 0; i--) {
      if (lines[i].itemId != itemId) continue;
      final taken = lines[i].count <= left ? lines[i].count : left;
      left -= taken;
      if (taken == lines[i].count) {
        lines.removeAt(i);
      } else {
        lines[i] = lines[i].copyWith(count: lines[i].count - taken);
      }
    }

    if (left > 0) return null;
    return Inventory(carried: lines, worn: worn, packId: packId);
  }

  /// Swaps the pack. The old one goes into the new one's contents by mass, so
  /// a downgrade can leave the player over the volume limit — which is allowed
  /// here and reported by [overflowL], because the alternative is the game
  /// deciding on its own what to throw away.
  Inventory withPack(String? newPackId) =>
      Inventory(carried: carried, worn: worn, packId: newPackId);

  /// Puts a pack on, with the old one inside it.
  ///
  /// Found on a phone: a 45 l daypack swapped for a 30 l shopping bag simply
  /// vanished, because the old pack was offered to the new one through [add]
  /// and a bag with no room for it refused. Nothing a player owns is destroyed
  /// by an action they took to keep it — the swap is never refused, and the
  /// state it leaves is over the limit rather than short of a pack, which is
  /// exactly what [overflowL] is for.
  Inventory wearPack(CarriedItem line) {
    final previous = packId;
    final lines = [...carried]..removeWhere((entry) => identical(entry, line));

    return Inventory(
      carried: [
        ...lines,
        if (previous != null) CarriedItem(itemId: previous),
      ],
      worn: worn,
      packId: line.itemId,
    );
  }

  /// How many litres past the limit the pack is. Zero unless a pack was
  /// swapped for a smaller one.
  double overflowL(BodyProfile body, ItemCatalogue catalogue) {
    final over = volumeL(catalogue) - limits(body, catalogue).capacityL;
    return over > 0 ? over : 0;
  }

  /// Puts something on the body. Worn items cost mass but not volume.
  ///
  /// One thing per slot (§4.4). A second coat does not go over the first: it
  /// comes off and goes in the pack, which is what happens in life and what
  /// stops a player from wearing four vests for four times the protection.
  ///
  /// [catalogue] is optional only so a test can dress a character without one;
  /// without it nothing knows what a garment covers and the piece is simply
  /// added.
  Inventory wear(String itemId, [ItemCatalogue? catalogue]) =>
      wearLine(CarriedItem(itemId: itemId), catalogue);

  /// Puts on one particular piece, keeping what that piece is.
  ///
  /// A vest worn out to 40% does not become a new vest by being put on, and
  /// with two of a kind in the pack the difference between the copies is the
  /// entire decision (§4.4).
  Inventory wearLine(CarriedItem line, [ItemCatalogue? catalogue]) {
    // A pack is worn on the back but is not a garment: it is the thing that
    // holds everything else, and it lives in [packId] rather than in [worn].
    if (catalogue?[line.itemId]?.kind == ItemKind.backpack) {
      return wearPack(line);
    }

    final itemId = line.itemId;
    final piece = line.copyWith(count: 1);
    final definition = catalogue?[itemId];
    final slot = definition == null ? null : wearSlotOf(definition);

    if (slot == null) {
      return Inventory(
        carried: carried,
        worn: [...worn, piece],
        packId: packId,
      );
    }

    final displaced = <CarriedItem>[];
    final remaining = <CarriedItem>[];
    for (final line in worn) {
      final other = catalogue?[line.itemId];
      if (other != null && wearSlotOf(other) == slot) {
        displaced.add(line);
      } else {
        remaining.add(line);
      }
    }

    // The displaced piece goes into the pack over its volume limit if it has
    // to. Taking a coat off cannot be refused, and [overflowL] is what reports
    // the state that leaves.
    return Inventory(
      carried: [...carried, ...displaced],
      worn: [...remaining, piece],
      packId: packId,
    );
  }

  /// Takes a worn piece off and puts it in the pack.
  ///
  /// Never refused. A coat comes off whether or not there is room for it —
  /// the same reasoning as [wear] displacing what was in the slot — and the
  /// overflow it may leave is reported by [overflowL] rather than being a
  /// reason to make somebody keep wearing something.
  Inventory takeOff(String itemId) {
    // The pack is worn on the back but does not live in [worn], so taking it
    // off is its own move.
    if (itemId == packId) return takeOffPack();

    final index = worn.indexWhere((line) => line.itemId == itemId);
    if (index < 0) return this;

    final remaining = [...worn]..removeAt(index);
    return Inventory(
      carried: [...carried, worn[index]],
      worn: remaining,
      packId: packId,
    );
  }

  /// Takes the pack off. What was in it stays in hand.
  ///
  /// Without a pack §18.1a leaves twelve litres of pockets, so this usually
  /// ends over the volume limit — which is the honest outcome, reported by
  /// [overflowL], and the same rule as swapping a big pack for a small one:
  /// the game never decides on its own what a player throws away.
  Inventory takeOffPack() {
    final pack = packId;
    if (pack == null) return this;

    return Inventory(
      carried: [
        ...carried,
        CarriedItem(itemId: pack),
      ],
      worn: worn,
      packId: null,
    );
  }

  int countOf(String itemId) => carried
      .where((line) => line.itemId == itemId)
      .fold(0, (sum, line) => sum + line.count);

  /// Total insulation on the body, in clo (§4.4). Feeds the sweat model of
  /// §2.3; a garment not worn insulates nobody.
  double insulationClo(ItemCatalogue catalogue) {
    var total = 0.0;
    for (final line in worn) {
      final value = catalogue[line.itemId]?.props['insulation_clo'];
      if (value is num) total += value.toDouble();
    }
    return total;
  }

  /// Ballistic protection for one hit, given where it landed.
  ///
  /// §4.4: coverage and protection are separate, and a hit outside the covered
  /// fraction ignores both. Blunt damage bypasses half of a vest's protection.
  double protectionAgainst({
    required ItemCatalogue catalogue,
    required String slot,
    required double hitRoll,
    bool blunt = false,
  }) {
    var best = 0.0;
    for (final line in worn) {
      final piece = catalogue[line.itemId];
      if (piece == null || piece.props['slot'] != slot) continue;

      final coverage = (piece.props['coverage_pct'] as num?)?.toDouble() ?? 0;
      if (hitRoll * 100 > coverage) continue;

      var level = (piece.props['protection_level'] as num?)?.toDouble() ?? 0;
      if (blunt) {
        final bypass =
            (piece.props['blunt_bypass_pct'] as num?)?.toDouble() ?? 0;
        level *= 1 - bypass / 100;
      }
      if (level > best) best = level;
    }
    return best;
  }
}

/// The shelter store (§18.1a): both limits, three litres per kilogram.
class StoreLimits {
  const StoreLimits(this.capacityKg);

  final double capacityKg;

  double get capacityL => capacityKg * kStoreLitresPerKg;
}

/// §5.6.3: [line] with [attachment] on it, or null where it will not go.
///
/// Every rule that decides whether a part goes on a weapon, in one place and
/// with no inventory around it. [Inventory.attach] uses it for a weapon in the
/// pack or in the hand; the shelves use it for one that never leaves the shelf.
///
/// Refused where the part does not fit the calibre, where one of the same is
/// already on — a second red dot on one rifle is not a thing, and the
/// arithmetic would happily stack it — where the place is taken, and where
/// there is no rail left.
CarriedItem? fittedWith(
  CarriedItem line,
  CarriedItem attachment,
  ItemCatalogue catalogue,
) {
  final weapon = catalogue[line.itemId];
  final part = catalogue[attachment.itemId];
  if (weapon == null || part == null) return null;
  if (!partFitsWeapon(part, weapon)) return null;
  if (line.attachments.contains(part.id)) return null;

  final used = slotsUsedBy([for (final id in line.attachments) ?catalogue[id]]);
  final place = slotOf(part);

  if (place != AttachmentSlot.magazine && used >= attachmentSlots(weapon)) {
    return null;
  }

  // §5.6.3: one thing per place. Fitting one where something already sits is
  // a swap, and a swap is the caller's decision to make, not a silent one to
  // make here.
  if (place != null) {
    for (final id in line.attachments) {
      final fittedPart = catalogue[id];
      if (fittedPart != null && slotOf(fittedPart) == place) return null;
    }
  }

  // ⚠️ §5.3: a magazine brings its rounds with it.
  //
  // Everywhere else an attachment is a name on a list. A magazine is a name on
  // a list *and* a number, and the number lives on whatever is holding it — so
  // seating one has to carry the rounds across, and taking one off has to carry
  // them back. Without this, fitting a full magazine gave a rifle with nothing
  // in it and threw thirty rounds away.
  final magazine = Magazine.of(part);

  return line.copyWith(
    attachments: [...line.attachments, part.id],
    rounds: magazine == null ? null : (attachment.rounds ?? 0),
  );
}
