import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/remains.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/loot_controller.dart';
import 'package:arls_za/loot/loot_spawner.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// ŁUP MA WŁAŚCICIELA, I JEDEN PROMIEŃ NA JEDNO MIEJSCE (§10, §10.2, §4.8).
///
/// ⚠️ **This is the phase where the state stopped being invisible.**
///
/// The pack and the shelves were already notifiers; the places and the bodies
/// were plain fields, changed inside a `setState` on a six-thousand-line
/// widget. Nothing outside that widget could ask about them, which is how one
/// school ended up with three different radii — one for searching it, one for
/// picking up what it dropped, one for the ring on the map. Nobody could put
/// those three side by side, because there was nowhere to stand.
///
/// Here is the somewhere to stand.
void main() {
  const here = GeoPoint(52.4064, 16.9252);

  LootBox place(String id, GeoPoint at, {String table = 'shop'}) => LootBox(
    poiId: id,
    position: at,
    tableId: table,
    spawnedAt: DateTime.utc(2026),
  );

  late SaveDatabase db;
  late LootController loot;

  setUp(() {
    db = SaveDatabase.memory();
    loot = LootController(db);
  });

  tearDown(() async {
    loot.dispose();
    await db.close();
  });

  group('with no tables, everything behaves as it did before', () {
    // ⚠️ The world opens while the intro film plays and the character arrives
    // some way after. Null tables must therefore be exactly the old default —
    // every place normal-sized, every place visible — or the first seconds of
    // a session would behave differently from the rest of it.
    test('a place is a building-sized place', () {
      expect(loot.reachOf(place('a', here)), kBuildingReachM);
    });

    test('and every place can be seen', () {
      expect(loot.isVisible(place('a', here)), isTrue);
    });
  });

  group('§10.2: one radius, asked three ways', () {
    test('the place in reach is the nearest one that covers you', () {
      final near = place('near', here.offsetBy(metres: 20, bearingDeg: 0));
      final far = place('far', here.offsetBy(metres: 45, bearingDeg: 0));

      loot.boxes.value = [far, near];

      expect(loot.boxInReach(here, DateTime.utc(2026))?.poiId, 'near');
    });

    test('and standing outside every place reaches none of them', () {
      loot.boxes.value = [
        place('far', here.offsetBy(metres: 400, bearingDeg: 0)),
      ];

      expect(loot.boxInReach(here, DateTime.utc(2026)), isNull);
    });

    test('nowhere at all reaches nothing, rather than throwing', () {
      // §2.1a.4 switches the receiver off under a roof. This line has been the
      // bug six times.
      loot.boxes.value = [place('a', here)];
      expect(loot.boxInReach(null, DateTime.utc(2026)), isNull);
    });

    test('what a place drops is reachable from that place', () {
      // ⚠️ The school. §10.2 gives a building fifty metres because its door is
      // not where the dot is — and a search drops what it found *at the dot*.
      loot.boxes.value = [place('school', here)];

      expect(loot.reachForPilesAt(here), kBuildingReachM);
    });

    test('and a pavement away from anywhere keeps arm\'s length', () {
      // §4.8: what the player dropped themselves really is at their feet.
      loot.boxes.value = [
        place('school', here.offsetBy(metres: 500, bearingDeg: 0)),
      ];

      expect(loot.reachForPilesAt(here), kStillnessM);
    });

    test('the widest place wins where two overlap', () {
      loot.boxes.value = [
        place('bin', here, table: 'bin'),
        place('school', here),
      ];

      expect(loot.reachForPilesAt(here), kBuildingReachM);
    });
  });

  group('the list changes by name, never by position', () {
    test('a searched place goes back where it was', () {
      // ⚠️ By poi id rather than by index: a plan can arrive between a search
      // starting and finishing, and an index would then name somebody else's
      // shop.
      loot.boxes.value = [place('a', here), place('b', here)];

      final searched = place('b', here).openedAtTime(DateTime.utc(2026));
      loot.replace(searched);

      expect(loot.boxes.value.map((box) => box.poiId), ['a', 'b']);
      expect(loot.byPoi('b')?.isOpen, isTrue);
      expect(loot.byPoi('a')?.isOpen, isFalse);
    });

    test('a place nobody has is left alone rather than added', () {
      loot.boxes.value = [place('a', here)];
      loot.replace(place('ghost', here));

      expect(loot.boxes.value, hasLength(1));
      expect(loot.byPoi('ghost'), isNull);
    });

    test('reconnaissance adds a place and remembers it was found', () {
      // §10.2.1: a house that might or might not be abandoned is exactly what
      // looking around is for.
      loot.reveal(place('house', here));

      expect(loot.byPoi('house'), isNotNull);
      expect(loot.revealed, contains('house'));
    });
  });

  group('§10.3: bodies stop being worth walking back to', () {
    test('a sweep drops what has run out and keeps what has not', () {
      final now = DateTime.utc(2026, 8, 10, 12);

      loot.remains.value = [
        Remains(
          id: 'a',
          kind: EnemyKind.walker,
          position: here,
          diedAt: now.subtract(const Duration(hours: 1)),
        ),
        Remains(
          id: 'b',
          kind: EnemyKind.walker,
          position: here,
          diedAt: now.subtract(const Duration(hours: 20)),
        ),
      ];

      loot.sweep(now);

      expect(loot.remains.value.map((body) => body.id), ['a']);
    });

    test('a sweep that changes nothing does not say anything', () {
      // ⚠️ It runs on the tick. A notifier that fires every second whether or
      // not anything moved is a rebuild of the map every second.
      final now = DateTime.utc(2026, 8, 10, 12);
      loot.remains.value = [
        Remains(id: 'a', kind: EnemyKind.walker, position: here, diedAt: now),
      ];

      var told = 0;
      loot.remains.addListener(() => told++);

      loot.sweep(now);
      loot.sweep(now);

      expect(told, 0);
    });
  });

  test('nothing is written before anybody says whose loot it is', () async {
    // The notifiers exist from the first frame so the map can be handed them
    // before a character is loaded.
    await loot.loadBoxes();
    await loot.reloadDropped(DateTime.utc(2026));
    await loot.reloadRemains(DateTime.utc(2026));

    expect(loot.boxes.value, isEmpty);
    expect(loot.dropped.value, isEmpty);
    expect(loot.remains.value, isEmpty);
  });
}
