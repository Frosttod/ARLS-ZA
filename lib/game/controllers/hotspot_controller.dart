/// §6.5's three pressure points, and who owns the answer.
///
/// ⚠️ **The one thing in this game that happens without the player.**
///
/// Everything else is something they do: a search, a shot, a build. A hotspot
/// grows on a clock that runs with the app shut, and §6.4's ambient trickle —
/// two Walkers to a square kilometre — is deliberately not enough to make a
/// fight out of. Without this the combat model, the loot economy and the
/// shelter have each been tested alone and never once under the pressure they
/// were all built for.
///
/// Settled on read, never on a timer. A hotspot that grew twice while the
/// phone was in a pocket arrives already grown (§6.5.3), which is the same
/// rule the shelter builds and the bench keep.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../combat/enemy_spawner.dart';
import '../../combat/hotspot.dart';
import '../../combat/hotspot_store.dart';
import '../../data/db/database.dart';
import '../../map/geometry.dart';
import '../../sim/play_habit.dart';

class HotspotController extends ChangeNotifier {
  HotspotController(this._db);

  final SaveDatabase _db;

  /// ⚠️ Created here and never replaced, so a screen that took a reference at
  /// boot still has the right one an hour later.
  final ValueNotifier<List<Hotspot>> hotspots = ValueNotifier(const []);

  final Map<int, Hotspot> _slots = {};
  int? _profileId;

  /// §11: the character's own seed, so the same run makes the same world.
  int _seed = 0;

  void bind({required int profileId, required int seed}) {
    _profileId = profileId;
    _seed = seed;
  }

  List<Hotspot> get live => [
    for (final spot in _slots.values)
      if (!spot.isResting) spot,
  ];

  /// §6.5.6: the circle the player is standing in, or null.
  Hotspot? covering(GeoPoint at) {
    for (final spot in live) {
      if (spot.covers(at)) return spot;
    }
    return null;
  }

  /// §6.5.2: what each live hotspot is sending out right now.
  ///
  /// ⚠️ Never the whole population. §6.4's ambient trickle exists alongside
  /// these and is what makes an empty street not *quite* empty — the caller
  /// adds it, because only the caller knows where the player is standing.
  List<SpawnOrigin> originsAt(DateTime now) => [
    for (final spot in live)
      SpawnOrigin(
        id: spot.id,
        centre: spot.centre,
        radiusM: spot.radiusM,
        kinds: spot.compositionNow(now),
        capacity: spot.enemyCapAt(now),
      ),
  ];

  /// Reads the three slots and brings them up to date (§6.5.3).
  ///
  /// [shelterAt] is where §6.5.1 measures from. Null — no shelter yet — means
  /// nothing is placed: a hotspot anchored to nowhere is a hotspot that would
  /// move the first time the player built a door.
  Future<void> reload({
    required DateTime now,
    required PlayHabit habit,
    GeoPoint? shelterAt,
    bool Function(GeoPoint at)? allows,
  }) async {
    final profileId = _profileId;
    if (profileId == null) return;

    final store = HotspotStore(_db);
    final stored = await store.load(profileId);

    // ⚠️ Seeded from the character and the slot, never from `Random()`. §11
    // wants a run to be replayable, and a world that reshuffled itself on
    // every boot would make the Chronicle a work of fiction.
    Random randomFor(int slot) => Random(_seed ^ (slot * 2654435761));

    final settled = <int, Hotspot>{};
    for (var slot = 0; slot < kMaxHotspots; slot++) {
      final random = randomFor(slot);
      final existing = stored[slot];

      if (existing != null) {
        final after = settleHotspot(
          existing,
          now: now,
          random: random,
          habit: habit,
          shelterAt: shelterAt,
          allows: allows,
        );

        settled[slot] = after;
        if (after != existing) await store.save(profileId, slot, after);
        continue;
      }

      // An empty slot with nowhere to put anything stays empty, and is not
      // written down: tomorrow, with a shelter, it will fill.
      if (shelterAt == null) continue;

      final where = placeHotspot(
        shelterAt: shelterAt,
        taken: [for (final spot in settled.values) spot.centre],
        random: random,
        allows: allows,
      );
      if (where == null) continue;

      final born = Hotspot.born(
        id: '$profileId.$slot',
        seed: random.nextInt(1 << 30),
        centre: where,
        at: now,
        until: promotionDelay(survivalDay: 1, habit: habit, random: random),
      );

      settled[slot] = born;
      await store.save(profileId, slot, born);
    }

    _slots
      ..clear()
      ..addAll(settled);

    hotspots.value = live;
    notifyListeners();
  }

  /// Replaces one slot and writes it down.
  Future<void> replace(Hotspot spot) async {
    final slot = _slots.entries
        .where((entry) => entry.value.id == spot.id)
        .map((entry) => entry.key)
        .firstOrNull;
    if (slot == null) return;

    _slots[slot] = spot;
    hotspots.value = live;
    notifyListeners();

    final profileId = _profileId;
    if (profileId != null) {
      await HotspotStore(_db).save(profileId, slot, spot);
    }
  }

  @override
  void dispose() {
    hotspots.dispose();
    super.dispose();
  }
}
