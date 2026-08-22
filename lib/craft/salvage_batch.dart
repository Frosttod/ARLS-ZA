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

/// One thing the disassembly screen offers, with what it gives and what it
/// costs.
class SalvageOffer {
  const SalvageOffer({
    required this.line,
    required this.takes,
    required this.yields,
    required this.fromShelf,
  });

  /// §11.1: the very piece, never the item id.
  final CarriedItem line;

  /// What is left to do on it, allowing for §18.6's partial progress.
  final Duration takes;

  /// What it gives back, at this player's share.
  final Map<String, int> yields;

  /// §18.2: on the shelves rather than in the pack.
  final bool fromShelf;

  SalvageStep toStep() => SalvageStep(
    uid: line.uid,
    itemId: line.itemId,
    condition: line.condition ?? 100,
    takes: takes,
    fromShelf: fromShelf,
  );
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
  );
}

/// Everything a set of offers comes to, added up.
///
/// The number the summary screen shows, and the one the player will count in
/// their pack afterwards.
Map<String, int> totalYield(Iterable<SalvageOffer> offers) {
  final out = <String, int>{};
  for (final offer in offers) {
    for (final entry in offer.yields.entries) {
      out[entry.key] = (out[entry.key] ?? 0) + entry.value;
    }
  }
  return out;
}
