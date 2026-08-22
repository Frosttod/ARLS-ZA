import 'package:arls_za/game/position_controller.dart';
import 'package:arls_za/location/position_fix.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// LEPKA POZYCJA (§3.2, §3.6).
///
/// ⚠️ **The rule that was wrong seven times.** `displayFix` is what the
/// receiver has to say this instant and it is null constantly — indoors, in a
/// shelter where §2.1a.4 switches the receiver off, in a stairwell, under a
/// bridge. Where the character *is* does not become "nowhere" because a
/// satellite went behind a building.
///
/// Every one of the seven was one line reading the first where it meant the
/// second, and every one was found by a person standing in the street watching
/// the game do nothing. Searching a room did nothing. Dropping something
/// destroyed it. A marker measured its distance from null island.
///
/// These are the first tests the rule has ever had. It could not have them
/// while it lived as two adjacent fields in a six-thousand-line widget.
void main() {
  const home = GeoPoint(52.4064, 16.9252);
  const away = GeoPoint(52.4100, 16.9300);

  final t0 = DateTime.utc(2026, 8, 20, 12);

  PositionFix fixAt(GeoPoint at) => PositionFix(
    latitude: at.latitude,
    longitude: at.longitude,
    accuracyM: 8,
    timestamp: t0,
  );

  group('what a fix does', () {
    test('the first one puts the character on the map', () {
      final position = PositionController();

      expect(position.here, isNull);
      position.follow(fixAt(home));

      expect(position.here?.latitude, closeTo(home.latitude, 1e-9));
    });

    test('and a later one moves them', () {
      final position = PositionController();

      position.follow(fixAt(home));
      position.follow(fixAt(away));

      expect(position.here?.latitude, closeTo(away.latitude, 1e-9));
    });
  });

  group('what no fix does — which is nothing', () {
    test('a blank snapshot leaves the character where they were', () {
      // ⚠️ The whole bug, in three lines. A single empty frame used to put
      // every enemy and every lootbox off the map for as long as it lasted.
      final position = PositionController();

      position.follow(fixAt(home));
      position.follow(null);

      expect(position.here?.latitude, closeTo(home.latitude, 1e-9));
    });

    test('and a hundred of them still leave them there', () {
      // What a shelter looks like: §2.1a.4 turns the receiver off for as long
      // as the character is indoors, which is all night.
      final position = PositionController();
      position.follow(fixAt(home));

      for (var i = 0; i < 100; i++) {
        position.follow(null);
      }

      expect(position.here?.latitude, closeTo(home.latitude, 1e-9));
    });

    test('and the drawing is not sticky, only the measuring', () {
      // The blue dot has to know there is no signal — §3.6 draws it faded.
      // What must not go away is the answer to "where is the character",
      // which is a different question the same tick answers.
      final position = PositionController();

      position.follow(fixAt(home));
      position.follow(null);

      expect(position.here, isNotNull, reason: 'measuring survives');
    });
  });

  group('coming back to a save (§11.1.2)', () {
    test('the character starts where they were left', () {
      // Without this the replay of the gap runs as somebody standing at 0°N
      // 0°E — several thousand kilometres from their own shelter, which is a
      // night credited as a night outdoors.
      final position = PositionController(lastKnown: home);

      expect(position.here?.latitude, closeTo(home.latitude, 1e-9));
    });

    test('and seeding after the fact works too', () {
      final position = PositionController();
      position.seed(home);

      expect(position.here?.latitude, closeTo(home.latitude, 1e-9));
    });

    test('a real fix overrides what the save remembered', () {
      final position = PositionController(lastKnown: home);
      position.follow(fixAt(away));

      expect(position.here?.latitude, closeTo(away.latitude, 1e-9));
    });
  });

  test('listeners hear the position move, and only when it does', () {
    // The pack screen, the ground list and the search panel all rebuild from
    // this. A notifier that fired on every blank tick would rebuild them
    // several times a second for nothing.
    final position = PositionController();
    var heard = 0;
    position.standingAt.addListener(() => heard++);

    position.follow(fixAt(home));
    expect(heard, 1);

    position.follow(null);
    position.follow(null);
    expect(heard, 1, reason: 'a blank tick is not a move');

    position.follow(fixAt(away));
    expect(heard, 2);
  });
}
