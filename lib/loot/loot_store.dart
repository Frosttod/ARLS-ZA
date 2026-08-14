/// Keeping lootboxes between sessions (§10, §11.1).
///
/// A box has to be the same box when the player comes back to it. Somebody who
/// walks twenty minutes towards a marker and finds it gone — or finds a
/// different one, in a slightly different place — has been lied to by the game,
/// and will not walk twenty minutes again.
///
/// So rows are keyed by the place rather than by a row id, positions are stored
/// rather than recomputed, and the spawner only ever adds, refills and forgets.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../map/geometry.dart';
import 'loot_spawner.dart';

class LootStore {
  const LootStore(this.db);

  final SaveDatabase db;

  Future<List<LootBoxe>> _rows(int profileId) => db.lootBoxesFor(profileId);

  Future<List<LootBox>> load(int profileId) async => [
    for (final row in await _rows(profileId))
      LootBox(
        poiId: row.poiId,
        position: GeoPoint(row.latitude, row.longitude),
        tableId: row.tableId,
        name: row.name,
        spawnedAt: row.spawnedAt,
        lootedAt: row.lootedAt,
        respawnAt: row.respawnAt,
        openedAt: row.openedAt,
      ),
  ];

  /// Writes a plan: everything it decided should exist, and the ids it decided
  /// to forget.
  Future<void> save(int profileId, SpawnPlan plan) => db.writeLootBoxes(
    profileId,
    boxes: [for (final box in plan.boxes) _companion(profileId, box)],
    forgotten: [for (final box in plan.forgotten) box.poiId],
  );

  /// Records one box being emptied, without touching the rest.
  Future<void> saveOne(int profileId, LootBox box) =>
      db.writeLootBoxes(profileId, boxes: [_companion(profileId, box)]);

  LootBoxesCompanion _companion(int profileId, LootBox box) =>
      LootBoxesCompanion.insert(
        profileId: profileId,
        poiId: box.poiId,
        latitude: box.position.latitude,
        longitude: box.position.longitude,
        tableId: box.tableId,
        spawnedAt: box.spawnedAt,
      ).copyWith(
        name: Value(box.name),
        lootedAt: Value(box.lootedAt),
        respawnAt: Value(box.respawnAt),
        openedAt: Value(box.openedAt),
      );
}
