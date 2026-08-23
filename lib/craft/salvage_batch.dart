/// Several things taken apart in one sitting (§18.6, §2.1a).
///
/// ⚠️ **One action, not a queue.** §2.1a gives the character one pair of hands
/// and the job table holds one row per profile, so a sitting is one job with
/// one bar — not five jobs waiting their turn. What makes that honest is that
/// the pieces come apart *in order*: the rifle first, then the vest, then the
/// pack. Half way through, the rifle is gone and the vest is untouched.
///
/// That ordering is the whole model. It means:
///
///   - stopping never leaves a thing in an ambiguous state — each piece is
///     either finished or exactly as it was;
///   - what arrives is what the finished pieces gave, which is a number the
///     player can check against the summary they agreed to;
///   - and the summary can be honest about the order, so somebody with twenty
///     minutes knows which two of their five will be done.
library;

import 'dart:convert';

import '../inventory/inventory.dart';
import '../items/item_catalogue.dart';
import 'craft_job.dart';
import 'item_recipe.dart';

/// One piece of a sitting, as the row remembers it.
///
/// ⚠️ Deliberately not a [CarriedItem]. The row has to survive a restart, and
/// what it needs to find the piece again is a uid (§11.1) — not a copy of the
/// piece, which would go stale the moment anything else touched the pack.
class SalvageStep {
  const SalvageStep({
    required this.itemId,
    required this.condition,
    required this.takes,
    this.uid,
    this.fromShelf = false,
  });

  /// §11.1: the very piece, so two of the same rifle stay separate.
  final String? uid;

  final String itemId;

  /// §18.6: the return is scaled by it, and the piece may be gone by then.
  final double condition;

  /// What is left to do on this one, after whatever it has already had.
  final Duration takes;

  /// §18.2: whether it is on the shelves rather than in the pack.
  final bool fromShelf;

  Map<String, Object?> toJson() => {
    if (uid != null) 'uid': uid,
    'id': itemId,
    'cond': condition,
    'takes': takes.inSeconds,
    if (fromShelf) 'shelf': true,
  };

  static SalvageStep? fromJson(Object? raw) {
    if (raw is! Map) return null;

    final itemId = raw['id'];
    if (itemId is! String) return null;

    final condition = raw['cond'];
    final takes = raw['takes'];
    final uid = raw['uid'];

    return SalvageStep(
      uid: uid is String ? uid : null,
      itemId: itemId,
      condition: condition is num ? condition.toDouble() : 100,
      takes: Duration(seconds: takes is num ? takes.toInt() : 0),
      fromShelf: raw['shelf'] == true,
    );
  }
}

/// A whole sitting, and the arithmetic of stopping half way through it.
class SalvageBatch {
  const SalvageBatch(this.steps);

  static const SalvageBatch empty = SalvageBatch([]);

  final List<SalvageStep> steps;

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;
  int get length => steps.length;

  /// The one actually under the multitool, or null. Only this one gets a bar.
  SalvageStep? get head => steps.isEmpty ? null : steps.first;

  /// Every minute of it.
  Duration get total =>
      steps.fold(Duration.zero, (sum, step) => sum + step.takes);

  /// §18.6: what has actually happened by [credited] of work.
  ///
  /// ⚠️ In order, and whole pieces only. Stopping half way through the vest
  /// leaves the vest untouched rather than partly ruined. The partial progress
  /// of a single piece is §18.6's `salvageSeconds` and belongs to the piece —
  /// [creditedOn] hands it back so the caller can write it there.
  ({List<SalvageStep> done, List<SalvageStep> left}) settledAt(
    Duration credited,
  ) {
    final done = <SalvageStep>[];
    final left = <SalvageStep>[];

    var spent = Duration.zero;
    for (final step in steps) {
      if (left.isEmpty && spent + step.takes <= credited) {
        spent += step.takes;
        done.add(step);
      } else {
        left.add(step);
      }
    }

    return (done: done, left: left);
  }

  /// How much of [credited] went into the piece that did not finish.
  ///
  /// Zero when the sitting ran out exactly on a boundary, which is the honest
  /// answer: nothing was started on the next one.
  Duration creditedOn(Duration credited) {
    var spent = Duration.zero;
    for (final step in steps) {
      if (spent + step.takes > credited) {
        final into = credited - spent;
        return into.isNegative ? Duration.zero : into;
      }
      spent += step.takes;
    }
    return Duration.zero;
  }

  /// §18.6, §12: where every piece of the sitting stands, right now.
  ///
  /// ⚠️ **One bar per piece, and each one tells the truth about itself.**
  ///
  /// A single bar across the whole sitting answers the wrong question. What a
  /// player wants to know, standing at a bench with twenty minutes to spare,
  /// is *which of these will be finished* — and a bar at 40% of an hour does
  /// not say that. So each piece gets its own: finished ones are full, the one
  /// under the multitool is where it actually is, and the ones waiting are at
  /// nought with the time **their own turn** ends.
  ///
  /// The waiting ones are deliberately not left blank. Nought with a clock on
  /// it is information — "yours starts in five minutes" — where a blank row is
  /// only an absence.
  List<SalvageProgress> progressAt(Duration credited) {
    final out = <SalvageProgress>[];

    var before = Duration.zero;
    for (final step in steps) {
      final into = credited - before;
      final done = into >= step.takes;

      // Everything ahead of this one that has not been paid for yet.
      final startsIn = before - credited;

      out.add(
        SalvageProgress(
          step: step,
          done: done,
          // Clamped at both ends: a piece nobody has started on is at nought,
          // never at a negative fraction of itself.
          fraction: step.takes <= Duration.zero
              ? 1
              : (into.inMilliseconds / step.takes.inMilliseconds).clamp(
                  0.0,
                  1.0,
                ),
          // What is left of *this* piece, at full rate.
          left: done || into.isNegative
              ? (done ? Duration.zero : step.takes)
              : step.takes - into,
          // ⚠️ **From now, and to the moment it STARTS.**
          //
          // Measured from the start of the sitting this read as an absurd
          // number and was reported as one: the figure against a waiting
          // piece included every minute already spent, so the third of four
          // said eighteen minutes when the thing in front of it had two and
          // three quarters left. Both of those minutes were in the past.
          //
          // What somebody watching the queue is asking is "when does mine
          // begin" — which is what is left of everything ahead of it, and
          // nothing else.
          startsIn: startsIn.isNegative ? Duration.zero : startsIn,
        ),
      );

      before += step.takes;
    }

    return out;
  }

  String encode() => jsonEncode([for (final step in steps) step.toJson()]);

  /// Reads a batch back off a row, and never throws on rubbish.
  ///
  /// A row written by a version that did not know about batches has null here,
  /// which is the same as a sitting of one — the caller keeps its old path.
  static SalvageBatch decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;

    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      return empty;
    }
    if (parsed is! List) return empty;

    return SalvageBatch([
      for (final entry in parsed) ?SalvageStep.fromJson(entry),
    ]);
  }
}

/// Why a piece is on the list but cannot go into a sitting yet.
///
/// ⚠️ **On the list, not missing from it.** A control that disappears cannot
/// explain itself — this codebase has now written that sentence three times,
/// about the fire-away button, about the dismantle glyph, and here. A rifle
/// that is worth taking apart and happens to be in the player's hands is not
/// an absent option; it is an option with one step in front of it.
enum SalvageBlock {
  /// §18.1a: it is on the body. Take it off first.
  ///
  /// Deliberately not done for the player. A sitting that undressed somebody
  /// on its own would be a second action inside the first (§2.1a) — and the
  /// bad case is not hypothetical: the third piece of a sitting could be the
  /// rucksack, which takes the carry limits down with it while the rest of the
  /// pieces are still standing in it.
  worn,
}

/// Where one piece of a running sitting stands.
class SalvageProgress {
  const SalvageProgress({
    required this.step,
    required this.done,
    required this.fraction,
    required this.left,
    required this.startsIn,
  });

  final SalvageStep step;

  /// Whether this one is already apart.
  final bool done;

  /// 0–1 of **this piece**, not of the sitting.
  final double fraction;

  /// What is left of this piece at full rate — its whole time while it waits.
  final Duration left;

  /// §12: how long until this piece's own turn **begins**, from now.
  ///
  /// ⚠️ Zero for the one under the multitool and for anything already apart.
  /// For a piece still waiting it is whatever is left of everything in front
  /// of it — which is the only figure that answers "when does mine begin".
  final Duration startsIn;

  /// Whether this is the one actually under the multitool.
  bool get running => !done && fraction > 0;

  /// Whether nobody has started on it yet.
  bool get waiting => !done && fraction <= 0;
}

/// One thing the disassembly screen offers, with what it gives and what it
/// costs.
class SalvageOffer {
  const SalvageOffer({
    required this.line,
    required this.takes,
    required this.yields,
    required this.fromShelf,
    this.blocked,
  });

  /// §11.1: the very piece, never the item id.
  final CarriedItem line;

  /// What is left to do on it, allowing for §18.6's partial progress.
  final Duration takes;

  /// What it gives back, at this player's share.
  final Map<String, int> yields;

  /// §18.2: on the shelves rather than in the pack.
  final bool fromShelf;

  /// Why it cannot be picked right now, or null when it can.
  final SalvageBlock? blocked;

  bool get isBlocked => blocked != null;

  /// §18.6: how many of this line a sitting may be given.
  ///
  /// ⚠️ **A stack is several pieces, and the screen used to offer one.**
  /// Reported from a walk: three improvised tourniquets are one row reading
  /// "×3", the row quoted the time for one, and there was no way to ask for
  /// the other two. So the row now carries how many there are, and the picker
  /// asks how many of them to open.
  ///
  /// Capped at one where somebody has already started on the line. §18.6's
  /// partial progress is written on the *line*, not on a piece of it, so a
  /// stack that is half undone cannot say which of its three is the half —
  /// and the honest answer is to finish the one that is open before splitting
  /// hairs about the rest.
  int get available =>
      line.isPartlyDismantled ? 1 : (line.count < 1 ? 1 : line.count);

  SalvageStep toStep() => SalvageStep(
    uid: line.uid,
    itemId: line.itemId,
    condition: line.condition ?? 100,
    takes: takes,
    fromShelf: fromShelf,
  );

  /// [count] pieces of this line, in the order they come apart.
  ///
  /// ⚠️ They share a uid, because they share a row: the pack holds one entry
  /// with a count, not three entries. Each step takes one off that entry as
  /// its turn finishes, which is what [SalvageBatch]'s ordering already
  /// promises — half way through, one is gone and two are exactly as they
  /// were.
  List<SalvageStep> toSteps(int count) => [
    for (var i = 0; i < count.clamp(1, available); i++) toStep(),
  ];
}

/// §18.6: what one piece is worth to this player, or null when it is worth
/// nothing.
///
/// The same call the single-item glyph makes, so the summary screen and the
/// pack row can never disagree about whether a thing is worth opening.
SalvageOffer? offerFor(
  CarriedItem line, {
  required CraftBench bench,
  required ItemCatalogue catalogue,
  required RecipeBook book,
  required bool fromShelf,
  SalvageBlock? blocked,
}) {
  final item = catalogue[line.itemId];
  if (item == null) return null;

  final condition = line.condition ?? 100;
  final yields = salvagePreview(
    line.itemId,
    bench,
    catalogue: catalogue,
    book: book,
    condition: condition,
  );
  if (yields.isEmpty) return null;

  final whole = salvageTime(materialContent(item, book));

  // §18.6: a piece somebody already started on has less left to do.
  final already = Duration(seconds: line.salvageSeconds ?? 0);
  final takes = whole - already;

  return SalvageOffer(
    line: line,
    takes: takes.isNegative ? Duration.zero : takes,
    yields: yields,
    fromShelf: fromShelf,
    blocked: blocked,
  );
}

/// §18.6, §18.2: everything the disassembly screen should offer, in order.
///
/// Three piles, and they are not interchangeable:
///
///   - the **pack**, which is what a bench is normally fed from;
///   - what is **on the body**, offered but blocked — see below;
///   - the **shelves**, because §18.2 makes those one pile with the pack at a
///     bench, and making somebody carry their own scrap off their own shelf
///     before it can be opened is bookkeeping rather than a decision.
///
/// ⚠️ **What is worn is shown and refused, never left out.**
///
/// The rifle is the one thing in this game most worth taking apart, and it is
/// almost always in the player's hands rather than stowed — so a list that
/// asked only the pack and the shelves did not work for the case it exists
/// for. A control that disappears cannot explain itself; this codebase has now
/// written that sentence three times.
///
/// It is not taken off automatically. A sitting that undressed somebody would
/// be a second action inside the first (§2.1a), and the bad case is not
/// hypothetical: the third piece could be the rucksack, which takes §18.1a's
/// carry limits down with it while the rest of the sitting is still standing
/// in it.
List<SalvageOffer> offersFrom({
  required Iterable<CarriedItem> carried,
  required Iterable<CarriedItem> worn,
  required Iterable<CarriedItem> shelved,
  required CraftBench bench,
  required ItemCatalogue catalogue,
  required RecipeBook book,
}) {
  SalvageOffer? one(
    CarriedItem line, {
    required bool fromShelf,
    SalvageBlock? blocked,
  }) {
    // ⚠️ Only pieces with a name of their own (§11.1). A sitting is written
    // down and read back after a restart, and a piece it cannot name again is
    // a piece it would find by guessing. The single-item path still opens
    // those, and does not have to survive anything.
    if (line.uid == null) return null;

    return offerFor(
      line,
      bench: bench,
      catalogue: catalogue,
      book: book,
      fromShelf: fromShelf,
      blocked: blocked,
    );
  }

  return [
    for (final line in carried) ?one(line, fromShelf: false),
    for (final line in worn)
      ?one(line, fromShelf: false, blocked: SalvageBlock.worn),
    for (final line in shelved) ?one(line, fromShelf: true),
  ];
}

/// §18.6: what one step of a sitting gives back, at this player's share.
///
/// The step-shaped face of [salvagePreview]. A running sitting knows its
/// pieces as [SalvageStep]s — that is what the row on disk holds — and asking
/// the same question about them should not mean unpacking one at every call
/// site.
Map<String, int> yieldOf(
  SalvageStep step, {
  required CraftBench bench,
  required ItemCatalogue catalogue,
  required RecipeBook book,
}) => salvagePreview(
  step.itemId,
  bench,
  catalogue: catalogue,
  book: book,
  condition: step.condition,
);

/// One line of a sitting as it was picked: the thing, and how many of it.
///
/// ⚠️ **How many, because a stack is not a piece.** Everything downstream —
/// the running total, the summary, the batch itself — has to multiply by this
/// or it quotes the price of one and destroys three.
class SalvagePick {
  const SalvagePick(this.offer, this.count);

  final SalvageOffer offer;

  /// How many of [SalvageOffer.line] go into the sitting. Never above
  /// [SalvageOffer.available].
  final int count;

  /// What these pieces cost, all of them.
  Duration get takes => offer.takes * count;

  /// What these pieces give back, all of them.
  Map<String, int> get yields => {
    for (final entry in offer.yields.entries) entry.key: entry.value * count,
  };
}

/// Everything a set of picks comes to, added up.
///
/// The number the summary screen shows, and the one the player will count in
/// their pack afterwards.
Map<String, int> totalYield(Iterable<SalvagePick> picks) {
  final out = <String, int>{};
  for (final pick in picks) {
    for (final entry in pick.yields.entries) {
      out[entry.key] = (out[entry.key] ?? 0) + entry.value;
    }
  }
  return out;
}

/// Every minute of a sitting, all pieces of every line.
Duration totalTime(Iterable<SalvagePick> picks) =>
    picks.fold(Duration.zero, (sum, pick) => sum + pick.takes);

/// §18.6: the sitting a set of picks becomes, in the order it was agreed to.
SalvageBatch batchOf(Iterable<SalvagePick> picks) =>
    SalvageBatch([for (final pick in picks) ...pick.offer.toSteps(pick.count)]);

/// Where a step's piece actually is: the row, which pile, and where in it.
typedef SalvagePiece = ({CarriedItem line, bool fromShelf, int index});

/// §11.1: finds the very piece a step names, in the pack or on the shelves.
///
/// ⚠️ By uid first, because that is what a step stores and what survives a
/// restart. The fall back to the item id is for rows written before uids
/// existed: two of a thing are interchangeable until one is worn or partly
/// undone, and a partly undone one is never interchangeable — which is why the
/// fall back looks for the most-undone one rather than the first.
SalvagePiece? pieceOf(
  SalvageStep step, {
  required List<CarriedItem> carried,
  required List<CarriedItem> shelved,
}) {
  final uid = step.uid;

  if (uid != null) {
    for (final line in carried) {
      if (line.uid == uid) return (line: line, fromShelf: false, index: -1);
    }
    for (final (index, line) in shelved.indexed) {
      if (line.uid == uid) return (line: line, fromShelf: true, index: index);
    }
    return null;
  }

  final matches = carried.where((line) => line.itemId == step.itemId).toList()
    ..sort((a, b) => (b.salvageSeconds ?? 0).compareTo(a.salvageSeconds ?? 0));

  final line = matches.firstOrNull;
  return line == null ? null : (line: line, fromShelf: false, index: -1);
}

/// §18.6: the pack rows a running sitting has locked, one entry each.
///
/// ⚠️ **One entry per row, not per step.** A stack of three asked for whole is
/// three steps sharing one uid, and three copies of the same row would draw
/// three bars under one line — which is the shape of a bug this project has
/// already had once, with three knives sharing a name between them.
///
/// Only the pack, deliberately. A piece waiting its turn on a shelf is locked
/// by the shelf refusing to hand it over; putting it in this list would draw a
/// bar under a row on a screen it does not belong to.
List<CarriedItem> lockedByBatch(
  SalvageBatch batch, {
  required List<CarriedItem> carried,
  required List<CarriedItem> shelved,
}) {
  final locked = <String, CarriedItem>{};

  for (final step in batch.steps) {
    final piece = pieceOf(step, carried: carried, shelved: shelved);
    if (piece == null || piece.fromShelf) continue;

    locked[piece.line.uid ?? piece.line.itemId] = piece.line;
  }

  return locked.values.toList();
}
