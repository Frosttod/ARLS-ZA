import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// §10.2, §19.3. Searching is the only way anything is picked up, and the only
/// thing it costs is time standing still — so what is tested is that the cost
/// is real: movement ends it, the app going away ends it, and nothing is
/// awarded for a search that did not finish.
void main() {
  const here = GeoPoint(52.4084, 16.9342);
  final now = DateTime.utc(2026, 8, 14, 12);

  GeoPoint metresNorth(double metres) =>
      GeoPoint(here.latitude + metres / metresPerDegreeLat, here.longitude);

  /// Runs a search second by second, as the game loop does.
  Search run(
    Search search, {
    required int seconds,
    GeoPoint? at,
    bool present = true,
  }) {
    var current = search;
    for (var i = 0; i < seconds && current.isRunning; i++) {
      current = current.advance(
        const Duration(seconds: 1),
        at: at ?? here,
        present: present,
      );
    }
    return current;
  }

  group('reconnaissance (§10.2)', () {
    test('takes forty-five seconds of standing still', () {
      final search = Search.area(at: here, now: now);

      expect(run(search, seconds: 44).state, SearchState.running);
      expect(run(search, seconds: 45).state, SearchState.done);
    });

    test('walking away cancels it', () {
      // §10.2.1: the cost is stillness. Forty-five seconds is sixty metres not
      // covered, and a player who covers them has chosen not to look.
      final search = run(
        Search.area(at: here, now: now),
        seconds: 20,
        at: metresNorth(20),
      );

      expect(search.state, SearchState.cancelledByMovement);
      expect(search.progress, lessThan(1));
    });

    test('GPS scatter does not cancel it', () {
      // The dead zone is the filter's own (§3.2), so standing still in the game
      // means what standing still means to the receiver.
      final search = run(
        Search.area(at: here, now: now),
        seconds: 45,
        at: metresNorth(7),
      );

      expect(search.state, SearchState.done);
    });

    test('the app going away ends it (§2.1a)', () {
      // A search that ran in a pocket would be a search the player did not
      // make.
      final search = run(
        Search.area(at: here, now: now),
        seconds: 10,
        present: false,
      );

      expect(search.state, SearchState.lostPresence);
    });

    test('an untrusted position ends it too', () {
      final search = Search.area(
        at: here,
        now: now,
      ).advance(const Duration(seconds: 1), at: null);

      expect(search.state, SearchState.lostPresence);
    });

    test('a cancelled search cannot be resumed by advancing it', () {
      final cancelled = Search.area(at: here, now: now).cancel();

      expect(
        run(cancelled, seconds: 45).state,
        SearchState.cancelled,
        reason: 'nothing awards a search that was abandoned',
      );
    });
  });

  group('the radius (§10.2.2)', () {
    test('reproduces every row of the doc\'s table', () {
      expect(searchRadiusM(), 100);
      expect(searchRadiusM(scouting: 1), 200);
      expect(searchRadiusM(binoculars: true), 150);
      expect(searchRadiusM(scouting: 1, binoculars: true), 300);
      expect(
        searchRadiusM(scouting: 1, binoculars: true, darkness: 0.8),
        closeTo(180, 0.001),
        reason: 'a winter night',
      );
    });

    test('weather narrows it', () {
      expect(searchRadiusM(weather: 0.6), closeTo(60, 0.001), reason: 'fog');
      expect(searchRadiusM(weather: 0.8), closeTo(80, 0.001), reason: 'rain');
    });

    test('binoculars alone never triple it', () {
      // §10.2.2 warns that 100 -> 300 m from one item multiplies the searched
      // area ninefold, and the game feels broken until it is found.
      expect(searchRadiusM(binoculars: true) / searchRadiusM(), 1.5);
    });
  });

  group('searching a place (§19.3)', () {
    test('costs the time its depth says (§10.3.5)', () {
      for (final depth in SearchDepth.values) {
        final search = Search.object(
          at: here,
          now: now,
          poiId: 'apteka',
          depth: depth,
        );

        expect(run(search, seconds: depth.seconds - 1).state, SearchState.running);
        expect(run(search, seconds: depth.seconds).state, SearchState.done);
      }
    });

    test('thirty, ninety and a hundred and eighty seconds', () {
      expect(SearchDepth.shallow.seconds, 30);
      expect(SearchDepth.thorough.seconds, 90);
      expect(SearchDepth.deep.seconds, 180);
    });

    test('can be broken off part-way, and gives nothing', () {
      // The decision §19.3 wants: take a little and leave, or risk the three
      // minutes. Interrupting has to actually cost the time already spent.
      var search = run(
        Search.object(
          at: here,
          now: now,
          poiId: 'apteka',
          depth: SearchDepth.deep,
        ),
        seconds: 120,
      );
      search = search.cancel();

      expect(search.state, SearchState.cancelled);
      expect(search.progress, closeTo(0.66, 0.01));
    });

    test('walking off mid-search abandons it', () {
      final search = run(
        Search.object(
          at: here,
          now: now,
          poiId: 'apteka',
          depth: SearchDepth.thorough,
        ),
        seconds: 30,
        at: metresNorth(15),
      );

      expect(search.state, SearchState.cancelledByMovement);
    });

    test('knows which place it is emptying', () {
      final search = Search.object(
        at: here,
        now: now,
        poiId: 'apteka',
        depth: SearchDepth.shallow,
      );

      expect(search.targetPoiId, 'apteka');
      expect(search.isArea, isFalse);
    });
  });

  group('looking twice (§10.2.1)', () {
    final knowledge = AreaKnowledge(
      at: here,
      radiusM: 200,
      completedAt: now,
      revealedPoiIds: const {'a', 'b'},
    );

    test('the same spot tells you nothing new for ten minutes', () {
      expect(knowledge.covers(here, now.add(const Duration(minutes: 5))), isTrue);
    });

    test('ten minutes later it does', () {
      expect(
        knowledge.covers(here, now.add(const Duration(minutes: 11))),
        isFalse,
      );
    });

    test('and neither does a spot mostly inside the last one', () {
      expect(
        knowledge.covers(metresNorth(50), now.add(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('but walking out of it is a new place to look', () {
      expect(
        knowledge.covers(metresNorth(150), now.add(const Duration(minutes: 1))),
        isFalse,
      );
    });

    test('there is no cooldown — the search runs, it just adds nothing', () {
      // §10.2.1 is explicit: a timer that costs nothing is an alarm clock, not
      // a decision. The player may always look again; the map may have nothing
      // to add.
      final search = run(Search.area(at: here, now: now), seconds: 45);

      expect(search.state, SearchState.done);
    });
  });
}
