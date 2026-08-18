import 'package:arls_za/combat/engagement.dart';
import 'package:test/test.dart';

/// §5.2, §5.4, §5.5. Where a fight happens and what it costs.
///
/// The distances come out of the receiver rather than out of taste: a fix is
/// good to five or fifteen metres, so a fight at twenty is a fight against GPS
/// noise. Everything here exists to keep the game from pretending to know
/// where two bodies are standing when it does not.
void main() {
  group('the bands of §5.2', () {
    test('a shot belongs between fifty and two hundred and fifty metres', () {
      expect(bandAt(50), EngagementBand.ranged);
      expect(bandAt(150), EngagementBand.ranged);
      expect(bandAt(250), EngagementBand.ranged);
    });

    test('past that there is nothing to shoot at yet', () {
      expect(bandAt(400), EngagementBand.none);
    });

    test('between twenty and fifty it is too close to shoot well', () {
      expect(bandAt(30), EngagementBand.closing);
    });

    test('and under twenty the receiver has nothing useful to say', () {
      expect(bandAt(20), EngagementBand.melee);
      expect(bandAt(3), EngagementBand.melee);
    });

    test('nothing is ever noticed inside the distance worth shooting at', () {
      // §5.2: a Walker that appeared at eighty metres appeared out of nothing.
      expect(kDetectionMinM, greaterThanOrEqualTo(kRangedMinM));
      expect(bandAt(kDetectionMinM), EngagementBand.ranged);
    });
  });

  group('changing target (§5.5.1)', () {
    test('a novice pays 1.2 s and a master 0.85', () {
      expect(targetSwitchTime(0).inMilliseconds, 1200);
      expect(targetSwitchTime(1).inMilliseconds, 840);
    });

    test('it is never free, however practised', () {
      // §5.5.1 charges the same for the "nearest threat" button on purpose:
      // automation would turn a group fight into tapping.
      expect(targetSwitchTime(2).inMilliseconds, greaterThan(0));
    });

    test('and the sights are at their widest while it happens', () {
      expect(kSwitchingSpreadMultiplier, 2.5);
    });
  });

  group('hands (§5.4)', () {
    test(
      'a rested novice with an empty pack hits about two swings in three',
      () {
        expect(
          meleeHitChance(skill: 0, carriedKg: 0, maxCarryKg: 36),
          closeTo(0.65, 0.001),
        );
      },
    );

    test('mastery is worth thirty points of it', () {
      expect(
        meleeHitChance(skill: 1, carriedKg: 0, maxCarryKg: 36),
        closeTo(0.95, 0.001),
      );
    });

    test('a full pack costs a quarter of the swing', () {
      // §18.1a's two limits reach into the fight: what you carried there is
      // what you fight with on your back.
      expect(
        meleeHitChance(skill: 0, carriedKg: 36, maxCarryKg: 36),
        closeTo(0.40, 0.001),
      );
    });

    test('half a pack costs half of that', () {
      expect(
        meleeHitChance(skill: 0, carriedKg: 18, maxCarryKg: 36),
        closeTo(0.525, 0.001),
      );
    });

    test('exhaustion takes its own share', () {
      final rested = meleeHitChance(skill: 0.5, carriedKg: 0, maxCarryKg: 36);
      final spent = meleeHitChance(
        skill: 0.5,
        carriedKg: 0,
        maxCarryKg: 36,
        fatigue: 1,
      );

      expect(spent, lessThan(rested));
      expect(rested - spent, closeTo(0.25, 0.001));
    });

    test('a loaded, exhausted novice still sometimes connects', () {
      final chance = meleeHitChance(
        skill: 0,
        carriedKg: 36,
        maxCarryKg: 36,
        fatigue: 1,
      );

      expect(chance, greaterThan(0));
      expect(chance, lessThan(0.2));
    });

    test('nothing takes it outside nought to one', () {
      expect(
        meleeHitChance(skill: 5, carriedKg: 0, maxCarryKg: 36),
        lessThanOrEqualTo(1),
      );
      expect(
        meleeHitChance(skill: 0, carriedKg: 900, maxCarryKg: 36, fatigue: 9),
        greaterThanOrEqualTo(0),
      );
    });

    test('a character with no carry limit at all does not divide by zero', () {
      expect(meleeHitChance(skill: 0, carriedKg: 5, maxCarryKg: 0), 0.65);
    });
  });

  group('being surrounded (§5.5.3)', () {
    test('the table, as written', () {
      expect(flankingMultiplier(1), 1.00);
      expect(flankingMultiplier(2), 1.30);
      expect(flankingMultiplier(3), 1.55);
      expect(flankingMultiplier(4), 1.75);
    });

    test('a crowd is no worse than four of them', () {
      expect(flankingMultiplier(9), 1.75);
    });

    test('nobody in reach is nobody swinging', () {
      expect(flankingMultiplier(0), 1.00);
    });

    test('letting a group close is very nearly a sentence', () {
      // §5.5.5's whole tactical loop rests on this being steep.
      expect(flankingMultiplier(4) / flankingMultiplier(1), greaterThan(1.5));
    });
  });
}
