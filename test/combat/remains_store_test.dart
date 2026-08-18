import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/remains.dart';
import 'package:arls_za/combat/remains_store.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// ZAPIS CIAŁ (§10.3, §11.1).
///
/// The one part of a fight that is written down. §6.4 remakes the living every
/// run — a Walker is not a place — but a body is: the player put it there,
/// remembered where, and is entitled to walk back for the pockets.
void main() {
  late SaveDatabase db;
  late RemainsStore store;
  late int profileId;

  const street = GeoPoint(52.4064, 16.9252);
  final t0 = DateTime.utc(2026, 8, 16, 12);

  setUp(() async {
    db = SaveDatabase.memory();
    profileId = await insertProfile(db);
    store = RemainsStore(db);
  });

  tearDown(() => db.close());

  Remains body({String id = 'walker.1', DateTime? diedAt}) => Remains(
    id: id,
    kind: EnemyKind.walker,
    position: street,
    diedAt: diedAt ?? t0,
  );

  test('a body is still there after a restart', () async {
    await store.add(profileId, body());

    final loaded = await store.load(profileId, t0);

    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'walker.1');
    expect(loaded.single.kind, EnemyKind.walker);
    expect(loaded.single.position.distanceTo(street), lessThan(1));
    expect(loaded.single.searched, isFalse);
  });

  test('and the same one cannot fall twice', () async {
    // A kill is noticed by the shot that finished it and again by the tick
    // that saw it finished.
    await store.add(profileId, body());
    await store.add(profileId, body());

    expect(await store.load(profileId, t0), hasLength(1));
  });

  test('turned-out pockets survive too', () async {
    await store.add(profileId, body());
    await store.searched(profileId, 'walker.1');

    final loaded = await store.load(profileId, t0);

    expect(loaded.single.searched, isTrue);
    expect(
      loaded,
      hasLength(1),
      reason: 'the mark stays on the map, or the player walks back twice',
    );
  });

  test('one nobody came back for goes cold (§10.3)', () async {
    await store.add(
      profileId,
      body(diedAt: t0.subtract(const Duration(hours: 13))),
    );

    // Swept on read: one that went cold with the app closed went cold all the
    // same, and a timer with the process dead is a timer that never fires.
    expect(await store.load(profileId, t0), isEmpty);
    expect(await db.remainsFor(profileId), isEmpty);
  });

  test('and one from an hour ago does not', () async {
    await store.add(
      profileId,
      body(diedAt: t0.subtract(const Duration(hours: 1))),
    );

    expect(await store.load(profileId, t0), hasLength(1));
  });
}
