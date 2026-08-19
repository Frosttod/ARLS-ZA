import 'dart:math';

import 'package:arls_za/loot/loot_spawner.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// PAMIĘĆ MIEJSCA (§10.2.1).
///
/// A place the player emptied keeps its dot, in grey, for a week. It says "I
/// have been here" rather than "there is something here" — which is the
/// difference between a street they have worked and one they have not, and it
/// costs nothing to say.
///
/// ⚠️ Memory and contents are two different facts and the dot carries both.
/// The place itself refills in four to eight hours (§10) and goes back to
/// colour then; the week is only the outer bound on remembering, for a place
/// the player never returns to.
void main() {
  final t0 = DateTime.utc(2026, 8, 19, 12);
  const at = GeoPoint(52.4084, 16.9342);

  LootBox box({DateTime? looted, DateTime? respawn}) => LootBox(
    poiId: 'p1',
    position: at,
    tableId: 'poi_grocery',
    spawnedAt: t0,
    lootedAt: looted,
    respawnAt: respawn,
  );

  test('an untouched place holds something and is not a memory', () {
    final fresh = box();

    expect(fresh.isActiveAt(t0), isTrue);
    expect(fresh.isRememberedAt(t0), isFalse);
    expect(fresh.isKnownAt(t0), isTrue);
  });

  test('an emptied one stops holding and starts being remembered', () {
    final emptied = box(looted: t0, respawn: t0.add(const Duration(hours: 6)));

    expect(emptied.isActiveAt(t0), isFalse, reason: 'nothing in it');
    expect(emptied.isRememberedAt(t0), isTrue, reason: 'but you were here');
    expect(emptied.isKnownAt(t0), isTrue, reason: 'so it stays on the map');
  });

  test('and gets its colour back the moment it refills', () {
    final emptied = box(looted: t0, respawn: t0.add(const Duration(hours: 6)));

    final after = t0.add(const Duration(hours: 7));

    expect(after.isAfter(emptied.respawnAt!), isTrue);
    expect(emptied.isActiveAt(after), isTrue, reason: 'full again');
  });

  test('the memory runs out after a week', () {
    // The backstop, not the main mechanic: a place refills long before this.
    // It matters for one the player walked away from and never came back to.
    final emptied = box(looted: t0);

    expect(emptied.isRememberedAt(t0.add(const Duration(days: 6))), isTrue);
    expect(emptied.isRememberedAt(t0.add(const Duration(days: 8))), isFalse);
    expect(emptied.isKnownAt(t0.add(const Duration(days: 8))), isFalse);
    expect(kSearchedMemory, const Duration(days: 7));
  });

  test('a place emptied and never refilled is remembered, not offered', () {
    // ⚠️ The pair that matters. Drawn, so the player can see they did this
    // street; not active, so the search panel does not offer an empty shop.
    final emptied = box(looted: t0, respawn: t0.add(const Duration(days: 30)));
    final later = t0.add(const Duration(days: 2));

    expect(emptied.isActiveAt(later), isFalse);
    expect(emptied.isRememberedAt(later), isTrue);
  });

  test('emptying a place by searching it out starts the memory', () {
    // Through the real path: six units of budget, spent, which is what makes
    // a place looted rather than a flag set by hand.
    var place = box();
    final random = Random(4);

    place = place.searchedAt(SearchDepth.deep, t0, random);

    expect(place.lootedAt, isNotNull, reason: 'a deep pass costs the lot');
    expect(place.isActiveAt(t0), isFalse);
    expect(place.isRememberedAt(t0), isTrue);
  });
}
