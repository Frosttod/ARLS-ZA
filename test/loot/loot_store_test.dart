import 'dart:math';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/loot/loot_spawner.dart';
import 'package:arls_za/loot/loot_store.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// §10, §11.1. A player who walks twenty minutes towards a marker and finds it
/// gone has been lied to, and will not walk twenty minutes again. Everything
/// here is about that promise surviving the app being closed.
void main() {
  late SaveDatabase db;
  late LootStore store;
  late int profileId;

  const centre = GeoPoint(52.4084, 16.9342);
  final now = DateTime.utc(2026, 8, 13, 12);

  LootBox boxAt(String id, {DateTime? looted, DateTime? respawn}) => LootBox(
    poiId: id,
    position: centre,
    tableId: 'poi_pharmacy',
    name: 'Apteka',
    spawnedAt: now,
    lootedAt: looted,
    respawnAt: respawn,
  );

  setUp(() async {
    db = SaveDatabase.memory();
    store = LootStore(db);
    profileId = await insertProfile(db);
  });

  tearDown(() async => db.close());

  test('a box is in the same place when the game reopens', () async {
    await store.save(
      profileId,
      SpawnPlan(boxes: [boxAt('apteka')], added: const [], forgotten: const []),
    );

    final loaded = (await store.load(profileId)).single;

    expect(loaded.poiId, 'apteka');
    expect(loaded.position.latitude, closeTo(centre.latitude, 1e-9));
    expect(loaded.position.longitude, closeTo(centre.longitude, 1e-9));
    expect(loaded.tableId, 'poi_pharmacy');
    expect(loaded.name, 'Apteka');
  });

  test('an emptied box stays empty across a restart', () async {
    // Otherwise closing the app is a way to refill the shop next door.
    final looted = boxAt('apteka').lootedAtTime(now, Random(3));
    await store.saveOne(profileId, looted);

    final loaded = (await store.load(profileId)).single;

    expect(loaded.isActiveAt(now.add(const Duration(hours: 1))), isFalse);
    expect(loaded.respawnAt, isNotNull);
  });

  test('the same place is never stored twice', () async {
    // One box per place (§10), enforced by the database and not only by the
    // spawner — two rows would draw two markers on one shop.
    await store.save(
      profileId,
      SpawnPlan(boxes: [boxAt('apteka')], added: const [], forgotten: const []),
    );
    await store.save(
      profileId,
      SpawnPlan(boxes: [boxAt('apteka')], added: const [], forgotten: const []),
    );

    expect(await store.load(profileId), hasLength(1));
  });

  test('what the spawner forgot is deleted', () async {
    await store.save(
      profileId,
      SpawnPlan(
        boxes: [boxAt('bliska')],
        added: const [],
        forgotten: [boxAt('daleka')],
      ),
    );
    await store.save(
      profileId,
      SpawnPlan(
        boxes: const [],
        added: const [],
        forgotten: [boxAt('bliska')],
      ),
    );

    expect(await store.load(profileId), isEmpty);
  });

  test('deleting the character clears the map with it', () async {
    await store.save(
      profileId,
      SpawnPlan(boxes: [boxAt('apteka')], added: const [], forgotten: const []),
    );

    await (db.delete(db.profiles)..where((t) => t.id.equals(profileId))).go();

    expect(await store.load(profileId), isEmpty);
  });
}
