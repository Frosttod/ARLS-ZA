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
import '../../combat/enemy.dart';
import '../../combat/hotspot_store.dart';
import '../../data/db/database.dart';
import '../../map/geometry.dart';
import '../../safety/spawn_exclusion.dart';
import '../../shelter/shelter.dart';
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

  /// §6.5.1: the same, from the two things the game already has to hand.
  ///
  /// ⚠️ Anchored to the shelter, so nothing is placed until there is one — a
  /// pressure point measured from nowhere would move the first time the player
  /// built a door. And never on a motorway, a railway, private land or a
  /// hospital car park: §3.5's exclusions exist because this game sends real
  /// people to real places, and the same filter the loot and the bodies use
  /// answers it here.
  Future<void> reloadFor({
    required DateTime now,
    required List<Shelter> shelters,
    required List<MapFeature> obstacles,
  }) {
    final home = shelters
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;

    final filter = SpawnFilter(obstacles);

    return reload(
      now: now,
      // §16.4: the world grows at the pace this player actually plays at.
      //
      // ⚠️ Not measured yet — §16.4's daily figure has nowhere on disk to live
      // (stage 6, faza B). An empty habit reads as the floor, which is the
      // slow end: a world that grows too slowly is one somebody can still
      // play, and one that grows too fast is not.
      habit: const PlayHabit([]),
      shelterAt: home?.position,
      allows: (at) => filter.refuse(at) == null,
    );
  }

  /// §6.5.4: one of theirs went down, and the ground it came from pays.
  ///
  /// ⚠️ Matched by where the body **came from**, never by where it fell. The
  /// spawner stamps a hotspot's centre onto everything it makes as that
  /// enemy's home, so a Leaper lured three streets away still belongs to the
  /// circle that produced it — which is the whole of §6.5.4's trade: pulling
  /// them out is safer and pays exactly half.
  Future<void> killed(Enemy enemy, {required DateTime now}) async {
    final owner = _slots.entries
        .where(
          (entry) =>
              !entry.value.isResting &&
              entry.value.centre.distanceTo(enemy.home) < 1,
        )
        .firstOrNull;
    if (owner == null) return;

    final hurt = owner.value.damagedBy(enemy.kind, at: enemy.position);

    // §6.5.4: through the wall. One level off, the fury that comes with it,
    // and a rest for the slot if that was the last one.
    final after = hurt.integrity <= 0
        ? hurt.demoted(at: now, restFor: _restFor(owner.key))
        : hurt;

    await _write(owner.key, after);
  }

  /// §6.5.4: what the clock does to them, called once a tick.
  ///
  /// ⚠️ Two rules, and neither is about the player doing anything. Integrity
  /// comes back at five per cent an hour — walking away half way through a
  /// hotspot is possible and expensive, which is the point — and fury does not
  /// follow somebody who left (§6.5.4's own valve, the one rule there that
  /// exists to let a player lose).
  Future<void> settle({required DateTime now, GeoPoint? playerAt}) async {
    final since = _settledAt;
    _settledAt = now;
    if (since == null || !now.isAfter(since)) return;

    final elapsed = now.difference(since);
    for (final entry in _slots.entries.toList()) {
      final before = entry.value;

      var spot = before.regenerated(elapsed);
      if (playerAt != null) spot = spot.settledIfAbandoned(playerAt);

      // ⚠️ **Only when it is worth a write.** Regeneration is five per cent an
      // hour, so a per-tick comparison by reference is always "changed" — and
      // three hotspots written to flash once a second for the length of a walk
      // is the same mistake §8.3's build progress made and fixed.
      //
      // A whole point of integrity, or the fury going out. Both are things the
      // player can see; anything smaller is arithmetic nobody is watching.
      final moved = (spot.integrity - before.integrity).abs() >= 1;
      final calmed = before.agitatedUntil != null && spot.agitatedUntil == null;

      if (!moved && !calmed) continue;

      _slots[entry.key] = spot;
      hotspots.value = live;
      notifyListeners();

      final profileId = _profileId;
      if (profileId != null) {
        await HotspotStore(_db).save(profileId, entry.key, spot);
      }
    }
  }

  DateTime? _settledAt;

  /// §6.5.4: how long a cleared slot stays empty, drawn from its own seed so
  /// the same run rests for the same time.
  Duration _restFor(int slot) {
    final (low, high) = kRestAfterClearing;
    final random = Random(_seed ^ (slot * 40503));

    return low + (high - low) * random.nextDouble();
  }

  Future<void> _write(int slot, Hotspot spot) async {
    _slots[slot] = spot;
    hotspots.value = live;
    notifyListeners();

    final profileId = _profileId;
    if (profileId != null) {
      await HotspotStore(_db).save(profileId, slot, spot);
    }
  }

  /// Replaces one slot and writes it down.
  Future<void> replace(Hotspot spot) async {
    final slot = _slots.entries
        .where((entry) => entry.value.id == spot.id)
        .map((entry) => entry.key)
        .firstOrNull;
    if (slot == null) return;

    await _write(slot, spot);
  }

  /// Sets one hotspot's level outright. Development only (§15.3).
  ///
  /// ⚠️ §6.5.3's growth is measured in real days, so without this the whole of
  /// stage 6 would be untestable in the field until somebody had played for a
  /// week — and a level-one hotspot is one Walker, which is not a thing
  /// anybody can tell apart from §6.4's ordinary street.
  Future<void> setLevel(int slot, int level, DateTime now) async {
    final spot = _slots[slot];
    if (spot == null) return;

    await _write(
      slot,
      spot.copyWith(
        level: level.clamp(1, kHotspotLevels.length),
        integrity: integrityMaxAt(
          level.clamp(1, kHotspotLevels.length),
        ).toDouble(),
        nextLevelAt: now.add(const Duration(hours: 8)),
        clearResting: true,
      ),
    );
  }

  @override
  void dispose() {
    hotspots.dispose();
    super.dispose();
  }
}
