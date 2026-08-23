import 'dart:io';

import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// MODUŁY MUSZĄ COŚ ROBIĆ (§8.4, §8.5.1, §2.5.3).
///
/// ⚠️ **The Lounge and the Laboratory did nothing at all.**
///
/// `Shelter.sleepRate` and `Shelter.nutritionRate` were computed on every
/// read, one of them was drawn on the shelter screen as a percentage, and no
/// clock ever consulted either. So a player could spend two days and eighty
/// kilograms of material on a Lounge, watch the screen say 115%, and sleep
/// exactly as fast as before.
///
/// The same getter also carries §8.5.1's rule that a night in a camp is worth
/// seven tenths of a night, so that was a decoration too — three rules, three
/// decorations, and the interface asserting all three.
///
/// Found by asking the question the interface should already have answered:
/// *how much does the Lounge actually give me?*
void main() {
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 35, heightCm: 180, weightKg: 80),
  );
  final constants = body.toSimConstants();

  SimState fresh() =>
      SimState.fresh(at: DateTime.utc(2026), constants: constants, massKg: 80);

  group('§8.4: the Lounge buys hours of the night back', () {
    /// Runs a night's sleep against a debt and says what is left of it.
    Duration debtAfter(double sleepRate) => advanceInChunks(
      state: fresh().copyWith(
        sleepDebtSeconds: const Duration(hours: 12).inSeconds,
      ),
      constants: constants,
      input: TickInput(sleeping: true, sleepRate: sleepRate),
      elapsed: const Duration(hours: 6),
    ).state.sleepDebt;

    test('a night under a Lounge pays down more of it (§2.5.4)', () {
      expect(debtAfter(1.45), lessThan(debtAfter(1.0)));
    });

    test('and the figure is §8.4\'s own fifteen per cent a level', () {
      final plain = const Duration(hours: 12) - debtAfter(1.0);
      final lounged = const Duration(hours: 12) - debtAfter(1.45);

      expect(
        lounged.inSeconds / plain.inSeconds,
        closeTo(1.45, 0.01),
        reason: 'three levels of Lounge',
      );
    });

    test('§2.5.5: and it clears the long clock faster too', () {
      // ⚠️ Both clocks, or the module would fix last night and do nothing
      // about the three weeks behind it — which is the half a player feels.
      double strainAfter(double sleepRate) => advanceInChunks(
        state: fresh().copyWith(sleepStrain: 4),
        constants: constants,
        input: TickInput(sleeping: true, sleepRate: sleepRate),
        elapsed: const Duration(hours: 8),
      ).state.sleepStrain;

      expect(strainAfter(1.45), lessThan(strainAfter(1.0)));
    });

    test('§8.5.1: a camp is worth seven tenths of a night', () {
      // The same getter, and it was just as dead.
      expect(
        Shelter(
          id: 1,
          kind: ShelterKind.camp,
          position: const GeoPoint(52.4, 16.9),
          startedAt: DateTime.utc(2026),
          buildTime: ShelterKind.camp.buildTime,
        ).sleepRate,
        closeTo(0.7, 0.001),
      );

      expect(debtAfter(0.7), greaterThan(debtAfter(1.0)));
    });

    test('and a rate nobody sanitised can never add debt', () {
      // ⚠️ A rate arriving from a module table is a number somebody can get
      // wrong, and a negative one would make sleeping *add* debt — which
      // reads exactly like the game being broken.
      expect(
        debtAfter(-5).inSeconds,
        lessThanOrEqualTo(const Duration(hours: 12).inSeconds),
      );
    });
  });

  group('§8.4: the Laboratory gets more out of a meal', () {
    double kcalAfter(double nutritionRate) => advanceInChunks(
      state: fresh().copyWith(caloriesKcal: 0, pendingKcal: 1000),
      constants: constants,
      input: TickInput(sleeping: true, nutritionRate: nutritionRate),
      elapsed: const Duration(hours: 3),
    ).state.caloriesKcal;

    test('a tin is worth more under a Laboratory', () {
      expect(kcalAfter(1.09), greaterThan(kcalAfter(1.0)));
    });

    test('and the stomach still empties at its own rate (§2.2)', () {
      // ⚠️ §8.4 says "more out of every meal", not "faster". The pending pool
      // drains at §2.2's rate and credits a little more than it loses — which
      // is also the only reading that works for something eaten before the
      // module was finished.
      double pendingAfter(double rate) => advanceInChunks(
        state: fresh().copyWith(caloriesKcal: 0, pendingKcal: 1000),
        constants: constants,
        input: TickInput(sleeping: true, nutritionRate: rate),
        elapsed: const Duration(minutes: 30),
      ).state.pendingKcal;

      expect(pendingAfter(1.09), closeTo(pendingAfter(1.0), 0.001));
    });

    test('a shelter without one changes nothing', () {
      expect(kcalAfter(1.0), closeTo(kcalAfter(1.0), 0.001));
    });
  });

  test('§8.4, §12: the figures on screen come from the model', () {
    // ⚠️ Source-level. The interface has to quote these (§12), and a figure
    // the screen works out for itself is a figure that drifts from the one the
    // simulation uses — which is precisely how a Lounge came to say 115% while
    // doing nothing.
    final screen = File('lib/ui/shelter_screen.dart').readAsStringSync();

    for (final constant in [
      'kStorageKgPerLevel',
      'kLoungeSleepPerLevel',
      'kLabNutritionPerLevel',
    ]) {
      expect(
        screen.contains(constant),
        isTrue,
        reason: '$constant is written out by hand somewhere',
      );
    }

    final loop = File('lib/game/game_loop.dart').readAsStringSync();
    expect(loop.contains('sleepRate: _inside?.sleepRate'), isTrue);
    expect(loop.contains('nutritionRate: _inside?.nutritionRate'), isTrue);
  });
}
