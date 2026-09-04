/// What the crafting bench is made of (§18.4), kept out of the entry point.
///
/// Nothing here is a decision — it is the cache key `main.dart` compares to
/// decide whether last second's bench still describes the world. It lives in
/// its own file because a value class with seven fields and an `operator ==`
/// is exactly the kind of weight that made `main.dart` seven thousand lines.
library;

import '../combat/magazine.dart';
import '../craft/craft_job.dart';
import '../inventory/inventory.dart';
import '../loot/search.dart';
import '../map/geometry.dart';
import '../shelter/shelter.dart';
import '../shelter/stash.dart';

/// What the crafting bench is made of, for deciding whether to make it again.
///
/// Every field is an immutable value replaced wholesale when it changes, so
/// reference equality is exact: two of these are equal precisely when nothing
/// the bench reads has moved.
///
/// ⚠️ The clock is deliberately not in here. Only one thing the bench reads
/// depends on it — whether a shelter is finished (§8.3) — and that changes at
/// most once in three hours. A cache entry is held for a second so that a
/// build finishing is noticed promptly without making the clock an input, and
/// a second is far below anything a player can act on.
class BenchInputs {
  const BenchInputs({
    required this.shelters,
    required this.standingAt,
    required this.inventory,
    required this.stash,
    required this.search,
    required this.reload,
    required this.job,
  });

  final List<Shelter> shelters;
  final GeoPoint? standingAt;
  final Inventory inventory;
  final Stash stash;
  final Search? search;
  final Reload? reload;
  final CraftJob? job;

  @override
  bool operator ==(Object other) =>
      other is BenchInputs &&
      identical(other.shelters, shelters) &&
      identical(other.standingAt, standingAt) &&
      identical(other.inventory, inventory) &&
      identical(other.stash, stash) &&
      identical(other.search, search) &&
      identical(other.reload, reload) &&
      identical(other.job, job);

  @override
  int get hashCode => Object.hash(
    identityHashCode(shelters),
    identityHashCode(standingAt),
    identityHashCode(inventory),
    identityHashCode(stash),
    identityHashCode(search),
    identityHashCode(reload),
    identityHashCode(job),
  );
}

extension BenchCacheEntry
    on ({BenchInputs inputs, CraftBench bench, DateTime madeAt}) {
  /// Whether this entry is young enough to trust. See [BenchInputs].
  bool freshAt(DateTime now) =>
      now.difference(madeAt) < const Duration(seconds: 1);
}
