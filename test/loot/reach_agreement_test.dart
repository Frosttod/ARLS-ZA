import 'dart:io';
import 'dart:math';

import 'package:arls_za/loot/loot_spawner.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// JEDEN PROMIEŃ NA JEDNO MIEJSCE (§10.2).
///
/// ⚠️ **Reported from a walk over a school.** Three separate numbers were
/// being used for one place: the search was cancelled by walking fifteen
/// metres, the find could only be picked up from fifteen metres, and the ring
/// drawn round it on the map said fifteen metres — while the place itself is
/// fifty, which is the whole reason §10.2 gives buildings their own figure.
///
/// The rule is one number per place, used everywhere: to decide whether it can
/// be searched, whether the player has walked off, how far the find reaches,
/// and what the ring says. Where they disagree, the player is being lied to by
/// at least two of them.
void main() {
  final main = File('lib/main.dart').readAsStringSync();

  String bodyOf(String signature) {
    final start = main.indexOf(signature);
    expect(start, greaterThan(0), reason: '$signature is gone');

    final end = main.indexOf('\n  /// ', start + signature.length);
    return main.substring(start, end < 0 ? main.length : end);
  }

  group('a place is as big as §10.2 says it is', () {
    test('a bin is reached by hand and a shop is not', () {
      expect(searchReachFor(PlaceSize.tiny), kNearReachM);
      expect(searchReachFor(PlaceSize.small), kNearReachM);
      expect(searchReachFor(PlaceSize.normal), kBuildingReachM);
    });

    test('and a car is reached from the road it is parked on', () {
      // ⚠️ Reported from a walk: fifteen metres is what an arm reaches, not
      // what a person stands at. A skip is approached from the yard gate.
      expect(kNearReachM, 30);
    });

    test('and a building is worth more than the stillness rule', () {
      // The whole bug in one line: if these were equal, nothing below would
      // matter.
      expect(kBuildingReachM, greaterThan(kStillnessM));
    });
  });

  group('walking about inside a place is not walking off', () {
    test('a search asks the place how far that is', () {
      // ⚠️ The parameter existed and nothing passed it. `advance` defaulted to
      // [kStillnessM] and so a fifty-metre school cancelled at fifteen.
      //
      // The work moved into `_advanceSearchStep` when `_advanceSearch` grew
      // its re-entrancy guard — see the feedback-loop budget.
      final advancing = bodyOf('Future<void> _advanceSearchStep(');

      expect(
        advancing.contains('boundaryRadiusM:'),
        isTrue,
        reason: 'a search of a shop is cancelled by crossing the shop',
      );
    });

    test('and a drift inside a shop keeps the clock running', () {
      final at = const GeoPoint(52.4064, 16.9252);
      final away = at.offsetBy(metres: 30, bearingDeg: 0);

      var search = Search.object(
        at: at,
        now: DateTime.utc(2026),
        poiId: 'school',
        depth: SearchDepth.shallow,
      );

      // Two readings thirty metres off — enough to cancel under the old rule
      // twice over.
      for (var i = 0; i < 2; i++) {
        search = search.advance(
          const Duration(seconds: 1),
          at: away,
          boundaryRadiusM: kBuildingReachM,
        );
      }

      expect(search.isRunning, isTrue);
      expect(search.elapsed, const Duration(seconds: 2));
    });

    test('but walking out of it still ends it', () {
      final at = const GeoPoint(52.4064, 16.9252);
      final gone = at.offsetBy(metres: 120, bearingDeg: 0);

      var search = Search.object(
        at: at,
        now: DateTime.utc(2026),
        poiId: 'school',
        depth: SearchDepth.shallow,
      );

      for (var i = 0; i < kStillnessStrikes; i++) {
        search = search.advance(
          const Duration(seconds: 1),
          at: gone,
          boundaryRadiusM: kBuildingReachM,
        );
      }

      expect(search.state, SearchState.cancelledByMovement);
    });
  });

  group('what a place drops is reachable from the place', () {
    test('the ground sheet gathers from the same reach the hand offered', () {
      // ⚠️ These disagreed. `_pilesInReach` asked the places how far they
      // reach — which is what decided the glyph was worth drawing — and then
      // the sheet gathered from fifteen metres and showed an empty floor.
      final opening = bodyOf('void _openGround() {');

      expect(opening.contains('_reachForPilesAt('), isTrue);
      expect(
        opening.contains('reachM: kStillnessM'),
        isFalse,
        reason: 'the hand and the list must agree about what is in reach',
      );
    });

    test('and the ring on the map says the same number', () {
      // A ring is a promise. One drawn tighter than the rule that actually
      // applies is a promise to refuse something that would in fact work.
      final markers = bodyOf('List<MapMarker> _lootMarkers() {');

      expect(
        markers.contains("id: 'dropped.\${item.id}'"),
        isTrue,
        reason: 'the dropped marker moved; check this test still looks at it',
      );
      expect(
        markers.contains('reachM: _reachForPilesAt(item.position)'),
        isTrue,
      );
    });
  });

  group('how much of a place there is to turn over (§19.3)', () {
    // Not a bug — a budget. Written down here because the field report read it
    // as one, and a number nobody can find is a number that gets reported
    // again.
    LootBox place() => LootBox(
      poiId: 'school',
      position: const GeoPoint(52.4064, 16.9252),
      tableId: 'school',
      size: PlaceSize.normal,
      spawnedAt: DateTime.utc(2026),
    );

    test('a fresh place will take any pass', () {
      final box = place();
      for (final depth in SearchDepth.values) {
        expect(box.canSearchAt(depth), isTrue, reason: depth.name);
      }
    });

    test('but one quick look costs the place its deep pass', () {
      // ⚠️ `deep` costs the whole budget, so it is only ever available on a
      // place nobody has touched. This is what "inne opcje nie są dostępne"
      // in the field report is: the option is greyed, not broken.
      final after = place().searchedAt(
        SearchDepth.shallow,
        DateTime.utc(2026),
        _fixed(),
      );

      expect(after.canSearchAt(SearchDepth.shallow), isTrue);
      expect(after.canSearchAt(SearchDepth.thorough), isTrue);
      expect(after.canSearchAt(SearchDepth.deep), isFalse);
    });

    test('and three quick looks empty it', () {
      var box = place();
      for (var i = 0; i < 3; i++) {
        box = box.searchedAt(SearchDepth.shallow, DateTime.utc(2026), _fixed());
      }

      expect(box.isActiveAt(DateTime.utc(2026)), isFalse);
      expect(
        box.isRememberedAt(DateTime.utc(2026)),
        isTrue,
        reason: 'emptied is a grey dot, not a place that never existed',
      );
    });

    test('two quick looks do not', () {
      var box = place();
      for (var i = 0; i < 2; i++) {
        box = box.searchedAt(SearchDepth.shallow, DateTime.utc(2026), _fixed());
      }

      expect(box.isActiveAt(DateTime.utc(2026)), isTrue);
      expect(box.canSearchAt(SearchDepth.shallow), isTrue);
    });
  });
}

/// Seeded, so the respawn window does not make the test flaky.
Random _fixed() => Random(1);
