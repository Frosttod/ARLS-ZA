import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/shelter/shelter_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// ZAPIS SCHRONU (§8.2, §11.1).
///
/// The one record in the save that is somebody's home address. It stays on the
/// phone, and it outlives every session — a shelter that forgot itself over
/// lunch would be three hours of work thrown away.
void main() {
  late SaveDatabase db;
  late ShelterStore store;
  late int profileId;

  const home = GeoPoint(52.4064, 16.9252);
  final t0 = DateTime.utc(2026, 8, 16, 12);

  setUp(() async {
    db = SaveDatabase.memory();
    profileId = await insertProfile(db);
    store = ShelterStore(db);
  });

  tearDown(() => db.close());

  test('what was begun is still there next time', () async {
    await store.begin(
      profileId,
      kind: ShelterKind.main,
      at: home,
      now: t0,
      buildTime: kShelterBuildTime,
    );

    final loaded = await store.load(profileId, t0);

    expect(loaded, hasLength(1));
    expect(loaded.single.kind, ShelterKind.main);
    expect(loaded.single.position.distanceTo(home), lessThan(1));
    expect(loaded.single.readyAt, t0.add(kShelterBuildTime));
  });

  test('and it is not finished the moment it is begun (§8.3)', () async {
    await store.begin(
      profileId,
      kind: ShelterKind.main,
      at: home,
      now: t0,
      buildTime: kShelterBuildTime,
    );

    final half = await store.load(profileId, t0.add(const Duration(hours: 1)));
    expect(half.single.isReadyAt(t0.add(const Duration(hours: 1))), isFalse);

    final done = await store.load(profileId, t0.add(const Duration(hours: 4)));
    expect(done.single.isReadyAt(t0.add(const Duration(hours: 4))), isTrue);
  });

  test('modules survive the round trip (§8.4)', () async {
    final id = await store.begin(
      profileId,
      kind: ShelterKind.main,
      at: home,
      now: t0,
      buildTime: kShelterBuildTime,
    );

    await store.setModules(id, {
      ShelterModule.storage: 2,
      ShelterModule.lounge: 1,
    });

    final loaded = await store.load(profileId, t0);
    expect(loaded.single.levelOf(ShelterModule.storage), 2);
    expect(loaded.single.levelOf(ShelterModule.lounge), 1);
    expect(loaded.single.levelOf(ShelterModule.workshop), 0);
  });

  test('a camp nobody came back to is gone, chest and all (§8.5.2)', () async {
    await store.begin(
      profileId,
      kind: ShelterKind.camp,
      at: home,
      now: t0.subtract(const Duration(days: 30)),
      buildTime: kCampBuildTime,
    );

    // Swept on read: a camp that fell down with the app closed fell down all
    // the same, and a timer with the process dead is a timer that never fires.
    expect(await store.load(profileId, t0), isEmpty);
    expect(await db.sheltersFor(profileId), isEmpty);
  });

  test('and one visited yesterday is not', () async {
    final id = await store.begin(
      profileId,
      kind: ShelterKind.camp,
      at: home,
      now: t0.subtract(const Duration(days: 30)),
      buildTime: kCampBuildTime,
    );
    await store.visited(id, t0.subtract(const Duration(days: 1)));

    expect(await store.load(profileId, t0), hasLength(1));
  });

  test('the shelter itself never falls down', () async {
    // It is where the player lives. Losing it to a fortnight away would be
    // the game punishing somebody for having a life.
    await store.begin(
      profileId,
      kind: ShelterKind.main,
      at: home,
      now: t0.subtract(const Duration(days: 90)),
      buildTime: kShelterBuildTime,
    );

    expect(await store.load(profileId, t0), hasLength(1));
  });

  test('moving house costs the full rebuild (§8.2)', () async {
    final id = await store.begin(
      profileId,
      kind: ShelterKind.main,
      at: home,
      now: t0,
      buildTime: kShelterBuildTime,
    );

    final elsewhere = GeoPoint(home.latitude + 0.05, home.longitude);
    final later = t0.add(const Duration(days: 2));
    await store.moveTo(
      id,
      at: elsewhere,
      now: later,
      buildTime: kShelterBuildTime,
    );

    final loaded = await store.load(profileId, later);
    expect(loaded.single.position.distanceTo(elsewhere), lessThan(1));
    expect(loaded.single.isReadyAt(later), isFalse);
  });
}
