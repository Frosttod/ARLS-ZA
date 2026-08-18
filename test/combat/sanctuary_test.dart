import 'dart:math';

import 'package:arls_za/combat/combat_session.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/sanctuary.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:flutter_test/flutter_test.dart';

/// STREFA SCHRONU (§8.1).
///
/// One radius for both halves of the rule. Two numbers would leave a ring in
/// which something can reach the player and the player cannot answer — which
/// punishes standing near your own front door, and is the one thing §8.1 puts
/// in bold.
void main() {
  const home = GeoPoint(52.4064, 16.9252);
  final t0 = DateTime.utc(2026, 8, 16, 12);

  const shelter = Sanctuary(at: home, radiusM: 50);

  group('what the circle is', () {
    test('the same radius the shelter keeps out with', () {
      expect(ShelterKind.main.safeRadiusM, shelter.radiusM);
    });

    test('inside is inside, outside is outside', () {
      expect(inSanctuary(home, const [shelter]), isTrue);
      expect(
        inSanctuary(home.offsetBy(metres: 80, bearingDeg: 90), const [shelter]),
        isFalse,
      );
    });
  });

  group('they wait at the edge (§8.1)', () {
    test('something that walks in is put back on the boundary', () {
      final walkedIn = home.offsetBy(metres: 10, bearingDeg: 45);
      final held = keepOut(walkedIn, const [shelter]);

      expect(home.distanceTo(held), closeTo(50, 1));
      // Out along the line it came in on: it ends up standing at the boundary
      // facing the shelter, rather than teleported round the back of it.
      expect(home.bearingTo(held), closeTo(45, 2));
    });

    test('and something outside is left exactly where it was', () {
      final outside = home.offsetBy(metres: 120, bearingDeg: 200);

      expect(keepOut(outside, const [shelter]), outside);
    });

    test('a walker that reached the door is standing outside it', () async {
      final session = CombatSession(
        seed: 7,
        enemies: [
          Enemy.spawn(
            id: 'walker.1',
            kind: EnemyKind.walker,
            at: home,
            home: home,
            random: Random(1),
          ).copyWith(state: EnemyState.chase),
        ],
      );

      final after = session.advance(
        playerAt: home,
        elapsed: const Duration(seconds: 5),
        now: t0,
        sanctuaries: const [shelter],
      );

      final held = after.enemies.firstWhere((e) => e.id == 'walker.1');
      expect(home.distanceTo(held.position), greaterThanOrEqualTo(49));
    });
  });
}
