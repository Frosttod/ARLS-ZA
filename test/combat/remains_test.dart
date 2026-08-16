import 'dart:math';

import 'package:arls_za/combat/combat_session.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/remains.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// CIAŁA (§10.3, §4.8).
///
/// A body is not a pile of loot. The point of keeping it as a body is that the
/// map says something died there and says nothing at all about what is in its
/// pockets — the walk over is the price of that answer.
void main() {
  Remains body({
    String id = 'walker.1',
    DateTime? diedAt,
  }) => Remains(
    id: id,
    kind: EnemyKind.walker,
    position: const GeoPoint(52.4, 16.9),
    diedAt: diedAt ?? DateTime.utc(2026, 8, 16, 12),
  );

  group('what is left where something fell', () {
    test('one body per body', () {
      // The kill can be reported from more than one place — a shot that
      // finishes it and the tick that sees it finished — and two skulls on one
      // corpse would be two walks to the same pocket.
      final once = addRemains(const [], body());
      final twice = addRemains(once, body());

      expect(twice, hasLength(1));
    });

    test('and it is not searched until somebody searches it', () {
      expect(body().searched, isFalse);
      expect(body().emptied.searched, isTrue);
    });

    test('turned-out pockets stay on the map', () {
      // Removing it would send the player back for a second look at nothing.
      expect(body().emptied.id, body().id);
      expect(body().emptied.position, body().position);
    });
  });

  group('how long it is worth coming back for (§4.8)', () {
    test('still there an hour later', () {
      final now = DateTime.utc(2026, 8, 16, 13);

      expect(sweepRemains([body()], now), hasLength(1));
      expect(body().isGoneAt(now), isFalse);
    });

    test('gone after six', () {
      final now = DateTime.utc(2026, 8, 16, 18, 1);

      expect(sweepRemains([body()], now), isEmpty);
      expect(body().isGoneAt(now), isTrue);
    });
  });

  group('a body is left wherever it falls', () {
    // Found on a phone: no skull after a kill. Most kills no longer happen at
    // the moment of the shot — §2.6's bleeding means a hit thing runs on and
    // falls over somewhere else, in the middle of a tick — and the tick simply
    // dropped it from the list without telling anybody.
    test('including one that bleeds out on the way', () {
      final walker = Enemy.spawn(
        id: 'walker.1',
        kind: EnemyKind.walker,
        at: const GeoPoint(52.4064, 16.9252),
        home: const GeoPoint(52.4064, 16.9252),
        random: Random(1),
      ).hit(0, bleeding: 400);

      final session = CombatSession(seed: 3, enemies: [walker]);

      final fallen = <Enemy>[];
      session.advance(
        playerAt: const GeoPoint(52.4064, 16.9252),
        elapsed: const Duration(seconds: 30),
        now: DateTime.utc(2026, 8, 16, 12),
        onDeath: fallen.add,
      );

      expect(fallen, hasLength(1));
      expect(fallen.single.id, 'walker.1');
    });

    test('and nothing is reported for one still on its feet', () {
      final walker = Enemy.spawn(
        id: 'walker.1',
        kind: EnemyKind.walker,
        at: const GeoPoint(52.4064, 16.9252),
        home: const GeoPoint(52.4064, 16.9252),
        random: Random(1),
      );

      final fallen = <Enemy>[];
      CombatSession(seed: 3, enemies: [walker]).advance(
        playerAt: const GeoPoint(52.4064, 16.9252),
        elapsed: const Duration(seconds: 5),
        now: DateTime.utc(2026, 8, 16, 12),
        onDeath: fallen.add,
      );

      expect(fallen, isEmpty);
    });
  });
}
