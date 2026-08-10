import 'package:arls_za/sim/physiology.dart';
import 'package:test/test.dart';

/// Thresholds from §2.3, §2.5.4 and §2.6. These are clinical numbers, not
/// tuned ones — a failure means the code drifted from the document.
void main() {
  const dailyKcal = 2450.0;
  const dailyMl = 2800.0;
  const bodyMassKg = 80.0;
  const bloodMaxMl = 5319.0;

  group('hunger (§2.3)', () {
    HungerState at(double fraction) =>
        hungerState(caloriesKcal: dailyKcal * fraction, dailyKcal: dailyKcal);

    test('a full reserve carries no penalty', () {
      expect(at(1.0).precisionPenalty, 1.0);
      expect(at(1.0).actionTimeMultiplier, 1.0);
    });

    test('below half, the hands start to shake', () {
      expect(at(0.51).precisionPenalty, 1.0);
      expect(at(0.49).precisionPenalty, closeTo(0.90, 1e-9));
    });

    test('below a fifth, everything takes longer', () {
      expect(at(0.21).actionTimeMultiplier, 1.0);
      expect(at(0.19).actionTimeMultiplier, closeTo(1.20, 1e-9));
    });

    test('consciousness goes only after a day at zero', () {
      expect(
        hungerState(
          caloriesKcal: 0,
          dailyKcal: dailyKcal,
          timeAtZero: const Duration(hours: 23),
        ).losingConsciousness,
        isFalse,
      );
      expect(
        hungerState(
          caloriesKcal: 0,
          dailyKcal: dailyKcal,
          timeAtZero: const Duration(hours: 25),
        ).losingConsciousness,
        isTrue,
      );
    });
  });

  group('thirst (§2.3)', () {
    ThirstState withDeficit(double ml) => thirstState(
      waterMl: dailyMl - ml,
      dailyMl: dailyMl,
      bodyMassKg: bodyMassKg,
    );

    test('a full reserve carries no penalty', () {
      expect(withDeficit(0).accuracyPenalty, 1.0);
      expect(withDeficit(0).severelyWeakened, isFalse);
    });

    test('two per cent of body mass costs fifteen per cent of accuracy', () {
      // 2% of 80 kg is 1.6 kg, so 1600 ml.
      expect(withDeficit(1500).accuracyPenalty, 1.0);
      expect(withDeficit(1700).accuracyPenalty, closeTo(0.85, 1e-9));
    });

    test('five per cent is severe weakness', () {
      expect(withDeficit(3900).severelyWeakened, isFalse);
      expect(withDeficit(4100).severelyWeakened, isTrue);
    });

    test('ten per cent is critical', () {
      expect(withDeficit(7900).critical, isFalse);
      expect(withDeficit(8100).critical, isTrue);
    });

    test('thirst bites harder than hunger, as the document insists', () {
      // Both down to 40% of their daily reserve, which is the first level at
      // which each has crossed its own first threshold.
      final hunger = hungerState(
        caloriesKcal: dailyKcal * 0.4,
        dailyKcal: dailyKcal,
      );
      final thirst = thirstState(
        waterMl: dailyMl * 0.4,
        dailyMl: dailyMl,
        bodyMassKg: bodyMassKg,
      );

      expect(hunger.precisionPenalty, closeTo(0.90, 1e-9));
      expect(thirst.accuracyPenalty, closeTo(0.85, 1e-9));
      expect(
        thirst.accuracyPenalty,
        lessThan(hunger.precisionPenalty),
        reason: '§2.3 is explicit that water must be the harsher of the two',
      );
    });

    test('at half the reserve neither penalty has started yet', () {
      // Worth pinning down: 50% of the water reserve is only a 1.75% deficit
      // against body mass, below the 2% threshold. The two scales are not
      // interchangeable, and reading one as the other is an easy mistake.
      final thirst = thirstState(
        waterMl: dailyMl * 0.5,
        dailyMl: dailyMl,
        bodyMassKg: bodyMassKg,
      );

      expect(thirst.deficitFractionOfBodyMass, closeTo(0.0175, 1e-4));
      expect(thirst.accuracyPenalty, 1.0);
    });

    test('forty-eight hours dry under exertion is fatal', () {
      expect(
        thirstState(
          waterMl: 0,
          dailyMl: dailyMl,
          bodyMassKg: bodyMassKg,
          timeWithoutWater: const Duration(hours: 47),
          underExertion: true,
        ).lethal,
        isFalse,
      );
      expect(
        thirstState(
          waterMl: 0,
          dailyMl: dailyMl,
          bodyMassKg: bodyMassKg,
          timeWithoutWater: const Duration(hours: 49),
          underExertion: true,
        ).lethal,
        isTrue,
      );
    });
  });

  group('sleep debt (§2.5.4)', () {
    test('under four hours costs nothing', () {
      expect(sleepState(const Duration(hours: 3)).extraMoa, 0);
      expect(sleepState(const Duration(hours: 3)).readingTimeMultiplier, 1.0);
    });

    test('four to twelve hours: slower reading, one MOA', () {
      final state = sleepState(const Duration(hours: 8));

      expect(state.readingTimeMultiplier, closeTo(1.20, 1e-9));
      expect(state.extraMoa, 1.0);
      expect(state.actionTimeMultiplier, 1.0);
    });

    test('twelve to twenty-four: half again on everything, three MOA', () {
      final state = sleepState(const Duration(hours: 18));

      expect(state.actionTimeMultiplier, closeTo(1.50, 1e-9));
      expect(state.extraMoa, 3.0);
      expect(state.learningRateMultiplier, closeTo(0.80, 1e-9));
      expect(state.microsleeps, isFalse);
    });

    test('past a day, microsleeps begin', () {
      expect(sleepState(const Duration(hours: 25)).microsleeps, isTrue);
    });

    test('a summer night in Poznań builds debt (§2.5.3)', () {
      // 7.4 h of night against an 8 h requirement leaves 36 minutes short.
      final shortfall = const Duration(hours: 8) - const Duration(minutes: 444);

      expect(shortfall, const Duration(minutes: 36));
      expect(
        sleepState(shortfall).extraMoa,
        0,
        reason: 'one night is not enough to hurt',
      );

      // Two weeks of the same is another matter.
      expect(sleepState(shortfall * 14).extraMoa, greaterThan(0));
    });
  });

  group('blood and shock (§2.6)', () {
    BloodState afterLosing(double fraction) =>
        bloodState(volumeMl: bloodMaxMl * (1 - fraction), maxMl: bloodMaxMl);

    test('under fifteen per cent there are no symptoms', () {
      expect(afterLosing(0.10).shockClass, ShockClass.none);
      expect(afterLosing(0.10).extraMoa, 0);
    });

    test('class II: tachycardia, two MOA, a tenth of the carry load', () {
      final state = afterLosing(0.20);

      expect(state.shockClass, ShockClass.compensated);
      expect(state.extraMoa, 2.0);
      expect(state.carryPenalty, closeTo(0.90, 1e-9));
      expect(state.canRunWithoutDizziness, isTrue);
    });

    test('class III: five MOA and no running', () {
      final state = afterLosing(0.35);

      expect(state.shockClass, ShockClass.decompensated);
      expect(state.extraMoa, 5.0);
      expect(state.canRunWithoutDizziness, isFalse);
    });

    test('class IV is fatal without help', () {
      final state = afterLosing(0.45);

      expect(state.shockClass, ShockClass.critical);
      expect(state.isFatal, isTrue);
    });

    test('the class boundaries sit exactly where the document puts them', () {
      expect(afterLosing(0.149).shockClass, ShockClass.none);
      expect(afterLosing(0.151).shockClass, ShockClass.compensated);
      expect(afterLosing(0.299).shockClass, ShockClass.compensated);
      expect(afterLosing(0.301).shockClass, ShockClass.decompensated);
      expect(afterLosing(0.399).shockClass, ShockClass.decompensated);
      expect(afterLosing(0.401).shockClass, ShockClass.critical);
    });
  });

  group('bleeding (§2.6)', () {
    test('the published rates', () {
      expect(BleedTier.superficial.mlPerMinute, 3);
      expect(BleedTier.moderate.mlPerMinute, 25);
      expect(BleedTier.severe.mlPerMinute, 90);
      expect(BleedTier.arterial.mlPerMinute, 350);
    });

    test('only a superficial wound closes on its own', () {
      expect(BleedTier.superficial.stopsOnItsOwn, isTrue);
      expect(BleedTier.moderate.stopsOnItsOwn, isFalse);
      expect(BleedTier.arterial.stopsOnItsOwn, isFalse);
    });

    test('running with a wound bleeds 2.3 times faster', () {
      final resting = bleedMlPerMinute(
        tier: BleedTier.moderate,
        currentHr: 70,
        restingHr: 70,
      );
      final running = bleedMlPerMinute(
        tier: BleedTier.moderate,
        currentHr: 160,
        restingHr: 70,
      );

      expect(resting, 25);
      expect(running / resting, closeTo(2.29, 0.01));
    });

    test('a calm heart never bleeds slower than the base rate', () {
      expect(
        bleedMlPerMinute(tier: BleedTier.severe, currentHr: 40, restingHr: 70),
        90,
        reason: 'the modifier only ever accelerates',
      );
    });

    test('an untreated arterial bleed empties a person in minutes', () {
      final lost = bleedOver(
        tier: BleedTier.arterial,
        currentHr: 140,
        restingHr: 70,
        elapsed: const Duration(minutes: 4),
      );

      expect(
        lost,
        greaterThan(bloodMaxMl * 0.40),
        reason: 'four minutes of arterial bleeding must reach class IV',
      );
    });

    test('no wound loses no blood', () {
      expect(
        bleedOver(
          tier: BleedTier.none,
          currentHr: 180,
          restingHr: 70,
          elapsed: const Duration(hours: 1),
        ),
        0,
      );
    });

    test('loss is linear in time', () {
      double lost(Duration d) => bleedOver(
        tier: BleedTier.moderate,
        currentHr: 70,
        restingHr: 70,
        elapsed: d,
      );

      expect(
        lost(const Duration(minutes: 2)),
        closeTo(lost(const Duration(minutes: 1)) * 2, 1e-9),
      );
    });
  });
}
