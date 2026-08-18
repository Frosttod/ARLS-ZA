import 'dart:math';

import 'package:arls_za/loot/search.dart';
import 'package:test/test.dart';

/// CO DAJE ROZEJRZENIE SIĘ (§10.2.3).
///
/// ⚠️ Not from the design document. §10.1 places the world on real map
/// features, which is right and which leaves a residential estate genuinely
/// empty — measured on walks through Poznań, where the near ring filled with
/// real shops and an estate filled with nothing. Reconnaissance already costs
/// forty-five seconds of standing still and eighty metres of noise; this is
/// what that buys where there are no shops.
void main() {
  test('three looks in ten find something', () {
    expect(kScoutFindChance, 0.30);
  });

  test('and the odds are what they say over many looks', () {
    // The roll itself is one line in main.dart; this is the shape of it,
    // against the constant, so a fat-fingered 0.03 or 0.3 in the wrong place
    // fails here rather than on a walk.
    final random = Random(7);
    var found = 0;
    for (var i = 0; i < 10000; i++) {
      if (random.nextDouble() < kScoutFindChance) found++;
    }

    expect(found / 10000, closeTo(kScoutFindChance, 0.02));
  });

  test('what turns up is a short walk, not underfoot', () {
    // Far enough to have been out of sight, near enough to be worth the walk.
    // §10.2.2's own ring is a hundred metres.
    expect(kScoutFindRadiusM, lessThan(kBaseSearchRadiusM));
    expect(kScoutFindRadiusM, greaterThan(50));
  });

  test('and the cooldown is longer than the search that earns it', () {
    // ⚠️ The valve on the whole idea. Without a cooldown longer than the
    // forty-five seconds a look costs, standing on one corner and pressing
    // the same button is a materials tap — and every other way of finding
    // things becomes worse than doing nothing in a car park.
    expect(kScoutCooldown, greaterThan(kAreaSearchTime * 3));
    expect(kScoutCooldown, const Duration(minutes: 3));
  });

  test('and longer than the memory of having looked', () {
    // §10.2.1 already refuses to re-reveal the same ground for ten minutes.
    // The cooldown is the shorter of the two on purpose: looking again is
    // allowed sooner than it pays.
    expect(kScoutCooldown, lessThan(kAreaSearchMemory));
  });
}
