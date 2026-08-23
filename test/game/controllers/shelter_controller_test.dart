import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/shelter_controller.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/shelter/shelter_store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

/// SCHRONY MAJĄ WŁAŚCICIELA (§8.2, §8.3, §18.2).
///
/// The shortest controller in the game, on purpose. A shelter is a row with a
/// clock on it, and almost everything a player *does* to one — starting it,
/// cancelling it, pulling a module down — is a question that has to be asked
/// out loud before it is answered. Those live where the words live.
///
/// What is here is the list, and the two questions everything else asks of it:
/// **am I at my own place**, and **can I reach the shelves**.
void main() {
  const home = GeoPoint(52.4064, 16.9252);
  final now = DateTime.utc(2026, 8, 10, 12);

  late SaveDatabase db;
  late ShelterController places;
  late int profileId;

  setUp(() async {
    db = SaveDatabase.memory();
    places = ShelterController(db);

    profileId = await db.createProfile(
      profile: ProfilesCompanion.insert(
        name: 'Ocalały',
        sex: 'M',
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        deathMode: 'hardcore',
        rngSeed: 1,
        createdAt: now,
      ),
      vitals: (id) => VitalsCompanion.insert(
        profileId: Value(id),
        lastUpdate: now,
        bloodMl: 5000,
        waterMl: 2500,
        caloriesKcal: 2500,
        heartRateBpm: 60,
      ),
    );
    places.bind(profileId: profileId);
  });

  tearDown(() async {
    places.dispose();
    await db.close();
  });

  Future<int> build(ShelterKind kind, GeoPoint at) => ShelterStore(
    db,
  ).begin(profileId, kind: kind, at: at, now: now, buildTime: Duration.zero);

  group('what is on disk is what is in the list', () {
    test('a reload finds what was built', () async {
      await build(ShelterKind.main, home);
      await places.reload(now);

      expect(places.places, hasLength(1));
      expect(places.home?.kind, ShelterKind.main);
    });

    test('and there is no home before one is built', () async {
      await places.reload(now);
      expect(places.home, isNull);
    });

    test(
      'nothing is read before anybody says whose shelters they are',
      () async {
        final loose = ShelterController(db);
        addTearDown(loose.dispose);

        await build(ShelterKind.main, home);
        expect(await loose.reload(now), isEmpty);
      },
    );

    test('the list handed on is not the list held', () async {
      // ⚠️ The caller hands the same places to the game loop. A list two
      // owners can both edit is a list neither of them owns.
      await build(ShelterKind.main, home);
      final handed = await places.reload(now);

      expect(identical(handed, places.places), isFalse);
    });
  });

  group('§8.2, §18.2: the two questions everything else asks', () {
    setUp(() async {
      await build(ShelterKind.main, home);
      await places.reload(now);
    });

    test('the shelves are in reach on the doorstep', () {
      expect(places.shelvesInReach(home), isTrue);
    });

    test('and not from down the road', () {
      expect(
        places.shelvesInReach(home.offsetBy(metres: 400, bearingDeg: 0)),
        isFalse,
      );
    });

    test('nowhere at all reaches nothing, rather than throwing', () {
      // §2.1a.4 switches the receiver off under a roof — which is exactly
      // where somebody stands when they reach for a shelf.
      expect(places.shelvesInReach(null), isFalse);
    });

    test('§2.1a: standing at home is standing where your things are', () {
      expect(places.atOwnPlace(home, now), isTrue);
      expect(places.atOwnPlace(null, now), isFalse);
    });
  });

  group('a camp is somewhere your things are, but has no shelves', () {
    setUp(() async {
      await build(ShelterKind.camp, home);
      await places.reload(now);
    });

    test('§8.5: making happens there', () {
      expect(places.atOwnPlace(home, now), isTrue);
    });

    test('§18.2: but the shelves belong to a building', () {
      expect(places.shelvesInReach(home), isFalse);
    });
  });

  test('a place goes back in the list by id, never by position', () async {
    // A reload can land between a build being worked on and the work being
    // written down, so an index would name somebody else's shelter.
    await build(ShelterKind.main, home);
    await build(ShelterKind.camp, home.offsetBy(metres: 900, bearingDeg: 90));
    await places.reload(now);

    final camp = places.places.firstWhere(
      (place) => place.kind == ShelterKind.camp,
    );
    final moved = Shelter(
      id: camp.id,
      kind: camp.kind,
      position: home,
      startedAt: camp.startedAt,
      buildTime: camp.buildTime,
    );
    places.replace(moved);

    expect(places.places, hasLength(2));
    expect(places.byId(camp.id)?.position, home);
    expect(
      places.home,
      isNotNull,
      reason: 'the house must still be in the list, untouched',
    );
  });
}
