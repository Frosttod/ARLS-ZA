/// What has been left in a shelter (§18.2, §8.5.1).
///
/// The point of a shelter that is not a bed. §18.1a gives a character two hard
/// limits and no way to grow them beyond a better rucksack — so everything
/// found on a walk is a decision to carry it or leave it *on the ground*,
/// where §4.8 gives it a day before it is gone. A shelf changes that into a
/// decision to carry it or **keep** it, and keeping things is most of what
/// makes a base a base.
///
/// ⚠️ Deliberately not an [Inventory]. A pack has a body behind it — comfort,
/// a maximum, a surcharge for being over — and a shelf has none of that. It
/// holds what it holds and refuses the rest, which is a much simpler thing and
/// stays simpler by not sharing a class with the other one.
library;

import '../inventory/inventory.dart';
import '../items/item_catalogue.dart';

/// The contents of one shelter, and what it will take.
class Stash {
  const Stash({this.lines = const [], required this.capacityKg})
    : capacityL = capacityKg * 3;

  const Stash._({
    required this.lines,
    required this.capacityKg,
    required this.capacityL,
  });

  /// Everything on the shelves.
  ///
  /// The same [CarriedItem] the pack holds: a rifle on a shelf keeps what is
  /// bolted to it, a book keeps how far it has been read, and a bottle put
  /// down half drunk is still half drunk when it is picked up again.
  final List<CarriedItem> lines;

  /// §18.2, §8.4: twenty-five kilograms of barricaded house, thirty of camp
  /// chest, and fifty more for every level of Storage built onto it.
  final double capacityKg;

  /// §18.1a: bulk runs out before mass does, at three litres to the kilogram —
  /// the same ratio the pack is measured with.
  final double capacityL;

  double massKg(ItemCatalogue catalogue) {
    var total = 0.0;
    for (final line in lines) {
      final definition = catalogue[line.itemId];
      if (definition == null) continue;
      total += line.massKg(definition, catalogue: catalogue);
    }
    return total;
  }

  double volumeL(ItemCatalogue catalogue) {
    var total = 0.0;
    for (final line in lines) {
      final definition = catalogue[line.itemId];
      if (definition == null) continue;
      total += line.volumeL(definition, catalogue: catalogue);
    }
    return total;
  }

  double massShare(ItemCatalogue catalogue) =>
      capacityKg <= 0 ? 1 : massKg(catalogue) / capacityKg;

  double volumeShare(ItemCatalogue catalogue) =>
      capacityL <= 0 ? 1 : volumeL(catalogue) / capacityL;

  /// Whether one more of [line] would fit.
  ///
  /// Both limits, and either one refuses. §18.1a's asymmetry is the whole
  /// reason both exist: a shelf full of empty bottles has room by weight and
  /// none by bulk, and a shelf of ammunition is the other way round.
  bool fits(CarriedItem line, ItemCatalogue catalogue) {
    final definition = catalogue[line.itemId];
    if (definition == null) return false;

    return massKg(catalogue) + line.massKg(definition, catalogue: catalogue) <=
            capacityKg &&
        volumeL(catalogue) + line.volumeL(definition, catalogue: catalogue) <=
            capacityL;
  }

  /// Puts [line] on the shelf, or returns this unchanged if it will not fit.
  ///
  /// ⚠️ Stacked by everything that makes two pieces the same piece, not by id.
  /// A rifle with a suppressor is not interchangeable with one without, a book
  /// read to page forty is not the same object as an unread copy, and a
  /// half-drunk bottle must never merge into a stack of full ones — §4.7 is
  /// explicit about the last of those and the rest follow from it.
  StashChange put(CarriedItem line, ItemCatalogue catalogue) {
    if (!fits(line, catalogue)) return StashChange(stash: this, moved: false);

    final next = [...lines];
    final at = next.indexWhere((other) => _sameAs(other, line));

    if (at >= 0 && _stackable(line)) {
      next[at] = next[at].copyWith(count: next[at].count + line.count);
    } else {
      next.add(line);
    }

    return StashChange(stash: _with(next), moved: true);
  }

  /// Takes [count] of the line at [index] off the shelf.
  StashTake take(int index, {int count = 1}) {
    if (index < 0 || index >= lines.length) {
      return StashTake(stash: this, taken: null);
    }

    final line = lines[index];
    final wanted = count.clamp(1, line.count);
    final next = [...lines];

    if (wanted >= line.count) {
      next.removeAt(index);
    } else {
      next[index] = line.copyWith(count: line.count - wanted);
    }

    return StashTake(
      stash: _with(next),
      taken: line.copyWith(count: wanted),
    );
  }

  Stash _with(List<CarriedItem> next) =>
      Stash._(lines: next, capacityKg: capacityKg, capacityL: capacityL);

  /// A part-used piece is its own line for ever (§4.7), and so is anything
  /// carrying a history somebody could tell apart.
  static bool _stackable(CarriedItem line) =>
      line.portion >= 1 &&
      line.pagesTotal == null &&
      line.noteId == null &&
      line.attachments.isEmpty;

  static bool _sameAs(CarriedItem a, CarriedItem b) =>
      a.itemId == b.itemId &&
      a.condition == b.condition &&
      a.portion == b.portion &&
      a.pagesTotal == null &&
      b.pagesTotal == null &&
      a.noteId == null &&
      b.noteId == null &&
      a.attachments.isEmpty &&
      b.attachments.isEmpty;
}

/// The result of putting something down: what the shelf is now, and whether it
/// took it at all.
class StashChange {
  const StashChange({required this.stash, required this.moved});

  final Stash stash;

  /// False when the shelf was full. Nothing is silently dropped — the caller
  /// keeps whatever would not fit, and the player is told.
  final bool moved;
}

/// The result of picking something up: what is left, and what came off.
class StashTake {
  const StashTake({required this.stash, required this.taken});

  final Stash stash;

  /// Null when the index was not there.
  final CarriedItem? taken;
}
