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
  Remains body({String id = 'walker.1', DateTime? diedAt}) => Remains(
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

    test('and a second report of the same fall is not a second body', () {
      // ⚠️ Found on a phone as two skulls for one Walker. A kill is noticed
      // from more than one place: the shot that finished it, the tick that saw
      // it finished, and the sweep that compares one list against the next.
      final shot = addRemains(const [], body());
      final tick = addRemains(shot, body(id: 'walker.1'));

      expect(tick, hasLength(1));
    });

    test('but two that fell within arm reach are two bodies', () {
      // ⚠️ There was a five-metre rule here, and it cost a walk. It was put in
      // to stop one Walker leaving two skulls — which was really two Walkers
      // sharing an id, fixed in the spawner. What the metres did meanwhile was
      // eat the second body of every pair that fell close together, and a
      // melee kill happens at arm's length: six down, two skulls.
      final first = addRemains(const [], body());
      final again = addRemains(
        first,
        Remains(
          id: 'walker.2',
          kind: EnemyKind.walker,
          position: const GeoPoint(
            52.4,
            16.9,
          ).offsetBy(metres: 3, bearingDeg: 90),
          diedAt: DateTime.utc(2026, 8, 16, 12),
        ),
      );

      expect(again, hasLength(2));
    });

    test('but one across the street is its own', () {
      final first = addRemains(const [], body());
      final other = addRemains(
        first,
        Remains(
          id: 'walker.2',
          kind: EnemyKind.walker,
          position: const GeoPoint(
            52.4,
            16.9,
          ).offsetBy(metres: 40, bearingDeg: 90),
          diedAt: DateTime.utc(2026, 8, 16, 12),
        ),
      );

      expect(other, hasLength(2));
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

    test('and gone after twelve', () {
      // ⚠️ Twelve, up from six. Six was measured against a play session; a
      // walk is not a session. Something shot on the way to work has to still
      // be there on the way home, or "come back for it later" is a promise
      // the game does not keep.
      final now = DateTime.utc(2026, 8, 17, 0, 1);

      expect(sweepRemains([body()], now), isEmpty);
      expect(body().isGoneAt(now), isTrue);
    });

    test('but still there after eleven', () {
      final now = DateTime.utc(2026, 8, 16, 23);

      expect(sweepRemains([body()], now), hasLength(1));
      expect(body().isGoneAt(now), isFalse);
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
