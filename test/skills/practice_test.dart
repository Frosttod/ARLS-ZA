import 'dart:io';

import 'package:arls_za/skills/practice.dart';
import 'package:arls_za/skills/skill.dart';
import 'package:test/test.dart';

/// DOŚWIADCZENIE Z PRAKTYKI (§7.2.1, §7.2.2).
///
/// ⚠️ **Four skills were fully wired and none of them could ever grow.**
/// `skillMoa`, `searchRadiusM`, `craftWork`, `buildTime` and the rest have all
/// taken a skill since stage A; `SkillController.award` has been able to pay
/// experience into one since the same day; and nothing in the game ever called
/// it. Every character shot, searched and built like somebody who had never
/// done any of it before, for ever.
///
/// The second thing these hold is the balance §7.2.1 is explicit about:
/// practice rewards a style of play, it does not replace literature.
void main() {
  group('§7.2.1: the table, exactly as the design doc gives it', () {
    test('every row is where it belongs', () {
      expect(Practice.shot.skill, Skill.weapons);
      expect(Practice.kill.skill, Skill.weapons);
      expect(Practice.dressing.skill, Skill.medicine);
      expect(Practice.crafted.skill, Skill.engineering);
      expect(Practice.moduleBuilt.skill, Skill.engineering);
      expect(Practice.searched.skill, Skill.scouting);
      expect(Practice.looted.skill, Skill.scouting);
    });

    test('and worth what it says', () {
      expect(Practice.shot.xp, 1);
      expect(Practice.kill.xp, 15);
      expect(Practice.dressing.xp, 25);
      expect(Practice.crafted.xp, 30);
      expect(Practice.moduleBuilt.xp, 400);
      expect(Practice.searched.xp, 8);
      expect(Practice.looted.xp, 3);
    });

    test('nothing pays nothing', () {
      for (final what in Practice.values) {
        expect(what.xp, greaterThan(0), reason: what.name);
      }
    });

    test('all four skills can be earned by doing something', () {
      // ⚠️ A skill nothing in the table teaches is a skill that can only ever
      // come from a book — which is a design decision, not an oversight, and
      // §7.2.1 does not make it for any of the four.
      expect(
        Practice.values.map((each) => each.skill).toSet(),
        Skill.values.toSet(),
      );
    });
  });

  group('§7.2.1: practice is not the way up', () {
    test('a hard day of it is a rounding error against the climb', () {
      // A hundred shots, ten kills, twenty places turned over and sixty things
      // carried home is a very long walk indeed.
      final day = practiceIn({
        Practice.shot: 100,
        Practice.kill: 10,
        Practice.searched: 20,
        Practice.looted: 60,
        Practice.dressing: 4,
      });

      expect(day / kXpToMaxSkill, lessThan(0.005));
    });

    test('and §7.2.1 says so in bodies: twenty thousand of them', () {
      // The doc's own arithmetic, held here so a generous edit to the table
      // fails a test rather than quietly turning a myth into a target.
      expect(kXpToMaxSkill / Practice.kill.xp, greaterThan(20000));
    });

    test('but the first levels arrive while somebody is playing', () {
      // The other half of the balance. If practice bought nothing at all for
      // weeks it would be the same as not existing — a player must feel the
      // first level or two without ever opening a book.
      final week = practiceIn({
        Practice.shot: 300,
        Practice.kill: 40,
        Practice.searched: 90,
        Practice.looted: 250,
      });

      expect(levelForXp(week), greaterThanOrEqualTo(2));
      expect(levelForXp(week), lessThan(10));
    });

    test('a module is worth more than a walk home with a full pack', () {
      // §8.3: days of a run, against minutes of one.
      expect(
        Practice.moduleBuilt.xp,
        greaterThan(practiceIn({Practice.looted: 60})),
      );
    });
  });

  test('§7.2.1: and the game actually pays it', () {
    // ⚠️ Source-level, because this whole file could be perfect and no
    // character ever earn a thing — which is precisely the state §7 was in
    // between stage A and this one: a complete model, wired into every
    // consumer, that nothing ever called.
    final main = File('lib/main.dart').readAsStringSync();

    for (final hook in [
      'Practice.shot', // §5.1
      'Practice.kill', // §6.2
      'Practice.dressing', // §4.7
      'Practice.crafted', // §18.4
      'Practice.moduleBuilt', // §8.3
      'Practice.searched', // §10.2
      'Practice.looted', // §4.8
    ]) {
      expect(
        main.contains(hook),
        isTrue,
        reason: '$hook earns nothing — that row of §7.2.1 is decoration',
      );
    }

    // And a level is worth saying out loud, once, from one place. Seven call
    // sites each deciding how to announce one is seven chances for one of them
    // not to.
    expect(main.contains('Future<void> _practise(Practice what)'), isTrue);
    expect(
      '_learned.practised('.allMatches(main).length,
      1,
      reason: 'something is paying experience around the funnel',
    );
    expect(main.contains('JournalKind.learned'), isTrue);
  });
}
