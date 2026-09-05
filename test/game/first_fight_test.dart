import 'package:arls_za/game/first_fight.dart';
import 'package:test/test.dart';

/// §15.6: the only scripted thing in the game, and the two lines it exists for.
void main() {
  FirstFightStep? due(
    FirstFight fight, {
    bool enemyAlive = true,
    bool noticed = true,
    bool targeted = false,
    bool standing = true,
    bool magazineEmpty = false,
    bool shotFired = false,
  }) => fight.due(
    enemyAlive: enemyAlive,
    noticed: noticed,
    targeted: targeted,
    standing: standing,
    magazineEmpty: magazineEmpty,
    shotFired: shotFired,
  );

  group('the sequence follows the fight, not a timer', () {
    test('nothing is said until something has noticed', () {
      expect(due(const FirstFight(), noticed: false), isNull);
      expect(due(const FirstFight()), FirstFightStep.spotted);
    });

    test('and each line is said once', () {
      final after = const FirstFight().take(FirstFightStep.spotted);

      expect(due(after), isNull, reason: 'nothing new has happened yet');
      expect(due(after, targeted: true), FirstFightStep.aim);
    });

    test('stand still is only owed to somebody who is not', () {
      // ⚠️ Told to a player already standing still it is a correction of
      // something they did right.
      final aimed = const FirstFight()
          .take(FirstFightStep.spotted)
          .take(FirstFightStep.aim);

      expect(due(aimed, targeted: true), isNull);
      expect(
        due(aimed, targeted: true, standing: false),
        FirstFightStep.standStill,
      );
    });

    test('and not after the shooting has started', () {
      // Somebody who fired on the move learned it the hard way, and does not
      // need to be told afterwards.
      final firing = const FirstFight()
          .take(FirstFightStep.spotted)
          .take(FirstFightStep.aim)
          .fired();

      expect(due(firing, targeted: true, standing: false), isNull);
    });
  });

  group('§15.6: the two lines that matter', () {
    final aimed = const FirstFight()
        .take(FirstFightStep.spotted)
        .take(FirstFightStep.aim);

    test('the noise ring comes with the first shot', () {
      expect(due(aimed.fired(), shotFired: true), FirstFightStep.noise);
    });

    test('and the bill comes when it is over, with the count', () {
      var fight = aimed.take(FirstFightStep.noise);
      for (var shot = 0; shot < 7; shot++) {
        fight = fight.fired();
      }

      expect(due(fight, enemyAlive: false), FirstFightStep.bill);
      expect(fight.shots, 7, reason: 'the line is a number, so it is counted');
    });

    test('but never for a fight nobody had', () {
      // Walked away, or it bled out from an earlier wound: no shots, no bill.
      expect(due(aimed, enemyAlive: false), isNull);
    });
  });

  group('§15.6: it cannot kill', () {
    const maxMl = 5000.0;

    test('a swing is a quarter of a swing', () {
      expect(
        FirstFight.tame(blowMl: 400, bloodMl: maxMl, maxMl: maxMl),
        closeTo(100, 0.001),
      );
    });

    test('and stops entirely at the floor', () {
      // ⚠️ Both halves are needed: cutting the blow alone still kills somebody
      // who walked into the script already bleeding.
      final atFloor = maxMl * kFirstFightFloor;

      expect(FirstFight.tame(blowMl: 400, bloodMl: atFloor, maxMl: maxMl), 0);
      expect(
        FirstFight.tame(blowMl: 400, bloodMl: atFloor - 200, maxMl: maxMl),
        0,
      );
    });

    test('and never takes more than the room that is left', () {
      final justAbove = maxMl * kFirstFightFloor + 30;
      final taken = FirstFight.tame(
        blowMl: 4000,
        bloodMl: justAbove,
        maxMl: maxMl,
      );

      expect(taken, closeTo(30, 0.001));
      expect(justAbove - taken, closeTo(maxMl * kFirstFightFloor, 0.001));
    });
  });

  test('it survives the app being closed mid-fight (§11.1)', () {
    final fight = const FirstFight()
        .take(FirstFightStep.spotted)
        .take(FirstFightStep.aim)
        .fired()
        .fired()
        .ended();

    final back = FirstFight.parse(fight.wire);

    expect(back.said, {FirstFightStep.spotted, FirstFightStep.aim});
    expect(back.shots, 2);
    expect(back.over, isTrue);
    expect(FirstFight.parse(null).said, isEmpty);
    expect(FirstFight.parse('nonsense').shots, 0);
  });
}
