import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:flutter_test/flutter_test.dart';

/// SCHRON I OBÓZ (§8).
///
/// The place you come back to, and the reason to come back. Everything here is
/// a number the design document argues for; the tests are so that changing one
/// of them is a decision rather than an accident.
void main() {
  const home = GeoPoint(52.4064, 16.9252);
  final t0 = DateTime.utc(2026, 8, 16, 12);

  Shelter built({
    ShelterKind kind = ShelterKind.main,
    GeoPoint at = home,
    Map<ShelterModule, int> modules = const {},
    DateTime? visitedAt,
  }) => Shelter(
    id: 1,
    kind: kind,
    position: at,
    startedAt: t0.subtract(const Duration(days: 1)),
    buildTime: kind.buildTime,
    modules: modules,
    visitedAt: visitedAt,
  );

  group('the two radii of §8.1', () {
    test('are one number, not two', () {
      // Two different numbers make a ring where the enemy can reach the player
      // and the player cannot answer, which punishes standing near your door.
      expect(ShelterKind.main.safeRadiusM, 50);
      expect(ShelterKind.camp.safeRadiusM, 20);
    });

    test('and cover the ground inside them', () {
      final shelter = built();
      final inside = GeoPoint(home.latitude + 0.0003, home.longitude);
      final outside = GeoPoint(home.latitude + 0.002, home.longitude);

      expect(shelter.coversAt(inside, t0), isTrue);
      expect(shelter.coversAt(outside, t0), isFalse);
    });

    test('but only once the building is finished', () {
      // A half-barricaded building keeps nothing out. Otherwise the three
      // hours would be free.
      final building = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: home,
        startedAt: t0,
        buildTime: kShelterBuildTime,
      );

      expect(
        building.coversAt(home, t0.add(const Duration(hours: 1))),
        isFalse,
      );
      expect(building.coversAt(home, t0.add(const Duration(hours: 4))), isTrue);
    });
  });

  group('how long it takes to put up (§8.3)', () {
    test('three hours with bare hands', () {
      expect(buildTimeFor(ShelterKind.main), kShelterBuildTime);
    });

    test('a third less with a hammer and an axe', () {
      expect(buildTimeFor(ShelterKind.main, hasTools: true).inMinutes, 117);
    });

    test('and about an hour twenty at the floor of both', () {
      // §8.3 names ~1 h 20 as the minimum achievable. It falls out of the two
      // discounts rather than out of a clamp pretending to be a rule.
      final best = buildTimeFor(
        ShelterKind.main,
        hasTools: true,
        engineering: 1,
      );

      expect(best.inMinutes, closeTo(82, 2));
    });

    test('a camp is an afternoon, not a day', () {
      expect(buildTimeFor(ShelterKind.camp), kCampBuildTime);
    });

    test('progress is read from the clock, not from screen time', () {
      final building = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: home,
        startedAt: t0,
        buildTime: kShelterBuildTime,
      );

      expect(
        building.progressAt(t0.add(const Duration(minutes: 90))),
        closeTo(0.5, 0.001),
      );
      expect(building.progressAt(t0.add(const Duration(days: 2))), 1);
    });
  });

  group('what the modules are worth (§8.4)', () {
    test('storage is the base plus fifty a level', () {
      expect(built().storageKg, 100);
      expect(built(modules: {ShelterModule.storage: 3}).storageKg, 250);
    });

    test('and bulk runs out at three litres to the kilogram (§18.1a)', () {
      expect(built().storageL, 300);
    });

    test('the lounge gives back an hour of the night', () {
      // §2.5.4: fewer hours needed asleep is more hours awake with a book,
      // which is what makes it a rival to storage rather than a nicety.
      expect(built().sleepRate, 1);
      expect(
        built(modules: {ShelterModule.lounge: 3}).sleepRate,
        closeTo(1.45, 0.001),
      );
    });

    test('the laboratory is three per cent a level of everything eaten', () {
      expect(
        built(modules: {ShelterModule.laboratory: 3}).nutritionRate,
        closeTo(1.09, 0.001),
      );
    });

    test('the workshop is access rather than a percentage', () {
      // Rebuilt from §8.4's own note: the 3%-a-level version is one nobody
      // would ever pay three levels for.
      expect(built().repairCeiling, 0);
      expect(built(modules: {ShelterModule.workshop: 1}).repairCeiling, 0.60);
      expect(built(modules: {ShelterModule.workshop: 2}).repairCeiling, 0.85);
      expect(built(modules: {ShelterModule.workshop: 3}).repairCeiling, 1.0);
    });
  });

  group('a camp is a worse shelter on purpose (§8.5.1)', () {
    test('a night in one is worth seven tenths of a night', () {
      expect(built(kind: ShelterKind.camp).sleepRate, closeTo(0.7, 0.001));
    });

    test(
      'its chest holds more than the shelter does bare, and never grows',
      () {
        expect(built(kind: ShelterKind.camp).storageKg, 30);
        expect(
          built(
            kind: ShelterKind.camp,
            modules: {ShelterModule.storage: 3},
          ).kind.modular,
          isFalse,
        );
      },
    );
  });

  group('where a camp may go (§8.5.2)', () {
    final far = GeoPoint(home.latitude + 0.02, home.longitude);

    test('not next door to the shelter', () {
      expect(
        campRefusalAt(
          GeoPoint(home.latitude + 0.001, home.longitude),
          existing: [built()],
        ),
        CampRefusal.tooCloseToShelter,
      );
    });

    test('not next door to the other camp', () {
      expect(
        campRefusalAt(
          GeoPoint(far.latitude + 0.001, far.longitude),
          existing: [built(kind: ShelterKind.camp, at: far)],
        ),
        CampRefusal.tooCloseToCamp,
      );
    });

    test('not in the middle of a hotspot', () {
      expect(
        campRefusalAt(
          far,
          existing: const [],
          hotspots: [GeoPoint(far.latitude + 0.001, far.longitude)],
        ),
        CampRefusal.tooCloseToHotspot,
      );
    });

    test('and never a third one', () {
      final second = GeoPoint(home.latitude + 0.04, home.longitude);

      expect(
        campRefusalAt(
          GeoPoint(home.latitude + 0.06, home.longitude),
          existing: [
            built(kind: ShelterKind.camp, at: far),
            built(kind: ShelterKind.camp, at: second),
          ],
        ),
        CampRefusal.tooMany,
      );
    });

    test('somewhere far enough from everything is fine', () {
      expect(campRefusalAt(far, existing: [built()]), isNull);
    });
  });

  group('a camp nobody comes back to (§8.5.2)', () {
    test('starts coming apart after a fortnight', () {
      final camp = built(
        kind: ShelterKind.camp,
        visitedAt: t0.subtract(const Duration(days: 15)),
      );

      expect(camp.isDecayingAt(t0), isTrue);
      expect(camp.isLostAt(t0), isFalse);
    });

    test('and is gone after three weeks, chest and all', () {
      final camp = built(
        kind: ShelterKind.camp,
        visitedAt: t0.subtract(const Duration(days: 22)),
      );

      expect(camp.isLostAt(t0), isTrue);
    });

    test('the shelter itself never falls down', () {
      // It is where the player lives. Losing it to a fortnight of not playing
      // would be the game punishing somebody for having a life.
      final home = built(visitedAt: t0.subtract(const Duration(days: 60)));

      expect(home.isDecayingAt(t0), isFalse);
      expect(home.isLostAt(t0), isFalse);
    });
  });

  group('which place the player is standing in', () {
    test('the open, when they are not in one', () {
      expect(
        shelterAt(GeoPoint(home.latitude + 0.02, home.longitude), [
          built(),
        ], now: t0),
        isNull,
      );
    });

    test('and the better one when both would do', () {
      // Only possible if a camp somehow went up inside the shelter, but the
      // shelter is better on every axis, so preferring it can never cost
      // anything.
      final place = shelterAt(home, [
        built(kind: ShelterKind.camp, at: home),
        built(),
      ], now: t0);

      expect(place?.kind, ShelterKind.main);
    });
  });

  group('work only happens on the site (§2.1a.3)', () {
    Shelter site() => Shelter(
      id: 1,
      kind: ShelterKind.main,
      position: home,
      startedAt: t0,
      buildTime: kShelterBuildTime,
      buildLeft: kShelterBuildTime,
    );

    test('a half-built place is still somewhere you can stand', () {
      // Not the same question as coverage: it keeps nothing out yet, but it is
      // where you have to be to go on nailing boards to it.
      expect(site().atSite(home), isTrue);
      expect(site().coversAt(home, t0), isFalse);
    });

    test('an hour there takes an hour off it', () {
      expect(
        site().worked(const Duration(hours: 1)).buildLeft,
        const Duration(hours: 2),
      );
    });

    test('and it is finished when the work is, not when the clock is', () {
      final done = site().worked(const Duration(hours: 3));

      expect(done.isReadyAt(t0), isTrue);
      expect(site().isReadyAt(t0.add(const Duration(days: 1))), isFalse);
    });

    test('the stamp moves even when nothing was earned', () {
      // Otherwise a walk to the shops and back would bank the whole walk.
      final away = site().worked(Duration.zero, at: t0);

      expect(away.workedAt, t0);
      expect(away.buildLeft, kShelterBuildTime);
    });

    test('never past done', () {
      expect(site().worked(const Duration(days: 2)).buildLeft, Duration.zero);
    });

    test('the place comes before the module it goes into', () {
      // A workshop cannot go up inside a building that is not up.
      final both = site().copyWith(buildingLeft: const Duration(hours: 4));
      final after = both.worked(const Duration(hours: 1));

      expect(after.buildLeft, const Duration(hours: 2));
      expect(after.buildingLeft, const Duration(hours: 4));
    });

    test('and takes its turn once the place is standing', () {
      final standing = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: home,
        startedAt: t0,
        buildTime: kShelterBuildTime,
        buildLeft: Duration.zero,
        buildingLeft: const Duration(hours: 4),
      );

      expect(
        standing.worked(const Duration(hours: 1)).buildingLeft,
        const Duration(hours: 3),
      );
    });

    test('a row written before the rule falls back to the clock', () {
      // An old save is not a save to break.
      final old = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: home,
        startedAt: t0,
        buildTime: kShelterBuildTime,
      );

      expect(old.isReadyAt(t0.add(const Duration(hours: 4))), isTrue);
      expect(old.worked(const Duration(hours: 1)).buildLeft, isNull);
    });
  });

  group('§8.3, §18.2: półki zaczynają się, kiedy schron stoi', () {
    test('gotowy schron stoi', () {
      expect(built().isBuilt, isTrue);
    });

    test('a plac budowy jeszcze nie', () {
      // ⚠️ Zgłoszone z terenu: „mam opcję przeniesienia do magazynu, choć nie
      // mam schronu". Wiersz istnieje od chwili wbicia pierwszej deski, więc
      // każde pytanie „czy jest schron" odpowiadało tak — a przedmiot szedł
      // na półki placu budowy i znikał graczowi z plecaka bez śladu.
      final going = built().copyWith(buildLeft: const Duration(hours: 2));

      expect(going.isBuilt, isFalse);
    });

    test('i przestaje nim być, kiedy praca się skończy', () {
      final going = built().copyWith(buildLeft: const Duration(minutes: 30));
      final done = going.worked(const Duration(hours: 1));

      expect(done.isBuilt, isTrue);
    });

    test('a wstrzymana budowa to dalej plac budowy', () {
      // Pauza zatrzymuje zegar, nie stawia ścian (§2.1a).
      final paused = built().copyWith(
        buildLeft: const Duration(hours: 2),
        paused: true,
      );

      expect(paused.isBuilt, isFalse);
    });
  });
}
