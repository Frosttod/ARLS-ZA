import 'dart:convert';
import 'dart:io';

import 'package:arls_za/skills/skill.dart';
import 'package:test/test.dart';

/// CZTERY UMIEJĘTNOŚCI I KRZYWA (§7, §7.2).
///
/// ⚠️ **Eight functions in this game already took a skill and defaulted it to
/// nought.** `skillMoa`, `targetSwitchTime`, `sprintBudget`, `searchRadiusM`,
/// `LootTable.roll`, `craftWork`, `salvageShare` and `buildTime` were all
/// written with the parameter in place and nothing to fill it in, so every
/// character in the game shot, searched and built like somebody who had never
/// done it before. This is the missing half.
///
/// The curve is §7.2's own: `70 × p` per level, 353 500 for the climb. What is
/// tested here is that the two directions agree — a level asked for and a
/// level read back have to be the same level, or a page of reading could take
/// experience away.
void main() {
  group('§7.2: the curve, both ways', () {
    test('the whole climb is 353 500', () {
      expect(kXpToMaxSkill, 353500);
    });

    test('level one costs seventy, level a hundred costs seven thousand', () {
      expect(xpForLevel(1), 70);
      expect(xpForLevel(100) - xpForLevel(99), 7000);
    });

    test('every level round-trips', () {
      // ⚠️ The property the whole thing rests on. `levelForXp` solves the
      // quadratic rather than searching, and a solved inverse that is off by
      // one anywhere is a level a player loses on the next tick.
      for (var level = 0; level <= kMaxSkillLevel; level++) {
        expect(levelForXp(xpForLevel(level)), level, reason: 'at $level');
      }
    });

    test('and one experience short of a level is still the level below', () {
      for (var level = 1; level <= kMaxSkillLevel; level++) {
        expect(levelForXp(xpForLevel(level) - 1), level - 1, reason: '$level');
      }
    });

    test('nothing goes past a hundred', () {
      expect(levelForXp(kXpToMaxSkill * 10), 100);
      expect(xpForLevel(500), kXpToMaxSkill);
    });

    test('and nothing goes below nought', () {
      expect(levelForXp(-1), 0);
      expect(levelForXp(0), 0);
      expect(xpForLevel(-5), 0);
    });
  });

  group('§7: what the rest of the game asks for', () {
    test('a fraction, not a level', () {
      // ⚠️ Every hook takes 0–1 and scales its own effect by it. This is the
      // single conversion between §7's hundred levels and everybody else's
      // fraction — doing it anywhere else would mean two places deciding what
      // half a skill means.
      const set = SkillSet({Skill.weapons: 0});

      expect(set.weapons, 0);
      expect(SkillSet({Skill.weapons: xpForLevel(50)}).weapons, 0.50);
      expect(SkillSet({Skill.weapons: kXpToMaxSkill}).weapons, 1.0);
    });

    test('a skill nobody has earned is nought, not null', () {
      const set = SkillSet.empty();

      for (final skill in Skill.values) {
        expect(set.levelOf(skill), 0);
        expect(set.fractionOf(skill), 0);
      }
    });

    test('the bar moves within the level, not across the hundred', () {
      // §7.2: a page read at level 40 has to move something a player can see,
      // and 1/353500 of a bar is not something anybody can see.
      final start = SkillSet({Skill.medicine: xpForLevel(40)});
      final half = SkillSet({
        Skill.medicine: xpForLevel(40) + (xpForLevel(41) - xpForLevel(40)) ~/ 2,
      });

      expect(start[Skill.medicine].intoLevel, 0);
      expect(half[Skill.medicine].intoLevel, closeTo(0.5, 0.01));
      expect(half[Skill.medicine].level, 40, reason: 'not a level yet');
    });

    test('and it says what is still owed', () {
      final set = SkillSet({Skill.scouting: xpForLevel(10)});

      expect(set[Skill.scouting].xpToNext, 70 * 11);
      expect(
        SkillSet({Skill.scouting: kXpToMaxSkill})[Skill.scouting].xpToNext,
        0,
      );
    });
  });

  group('§7.2.1: paying experience in', () {
    test('a set is never mutated', () {
      const before = SkillSet({Skill.engineering: 100});
      final after = before.awarded(Skill.engineering, 50);

      expect(before.xpOf(Skill.engineering), 100);
      expect(after.set.xpOf(Skill.engineering), 150);
    });

    test('and it says when that crossed a level', () {
      // §12: the caller announces it. A value type must not know what a snack
      // bar is, so the fact travels back rather than the message going out.
      final justUnder = SkillSet({Skill.weapons: xpForLevel(5) - 1});

      expect(justUnder.awarded(Skill.weapons, 1).levelled, isTrue);
      expect(justUnder.awarded(Skill.weapons, 0).levelled, isFalse);
      expect(
        SkillSet({
          Skill.weapons: xpForLevel(5),
        }).awarded(Skill.weapons, 1).levelled,
        isFalse,
      );
    });

    test('nothing and less than nothing change nothing', () {
      const set = SkillSet({Skill.medicine: 500});

      expect(set.awarded(Skill.medicine, 0).set.xpOf(Skill.medicine), 500);
      expect(set.awarded(Skill.medicine, -9).set.xpOf(Skill.medicine), 500);
    });

    test('paying into one leaves the other three alone', () {
      const set = SkillSet({Skill.scouting: 100, Skill.weapons: 200});
      final after = set.awarded(Skill.scouting, 50).set;

      expect(after.xpOf(Skill.weapons), 200);
      expect(after.xpOf(Skill.medicine), 0);
    });
  });

  group('§11.1: reading it back', () {
    test('a set survives the round trip', () {
      const set = SkillSet({Skill.scouting: 1234, Skill.medicine: 99});

      expect(SkillSet.decode(set.encode()), set);
    });

    test('rubbish is a novice, never a crash', () {
      expect(SkillSet.decode('not json at all'), SkillSet.none);
      expect(SkillSet.decode(''), SkillSet.none);
      expect(SkillSet.decode(null), SkillSet.none);
      expect(SkillSet.fromJson(42), SkillSet.none);
    });

    test('a skill this version does not know is dropped, not guessed at', () {
      // The same rule the item catalogue keeps for an uninstalled content
      // pack: a name nobody recognises is a name nobody may act on.
      final set = SkillSet.fromJson({'scouting': 70, 'telepathy': 9000});

      expect(set.levelOf(Skill.scouting), 1);
      expect(set.totalXp, 70);
    });
  });

  test('§4.6: the shipped books name these four and nothing else', () {
    // ⚠️ The reason the wire names are not a choice. Every title in
    // `literature.json` has been tagged with one of these since stage 4, and
    // that file ships — renaming the enum would orphan eighteen books on
    // players' phones.
    final data =
        jsonDecode(File('assets/data/literature.json').readAsStringSync())
            as Map<String, Object?>;

    final tags = <String>{
      for (final item in data['items']! as List)
        if (((item as Map)['props'] as Map)['skill'] case final String tag) tag,
    };

    expect(tags, Skill.values.map((skill) => skill.wire).toSet());
  });

  test('§7.2: all the literature in the game is worth about level 31', () {
    // ⚠️ Not a balance complaint — a figure worth knowing. §13.1 wants the
    // maximum to be a myth rather than a target, and reading every title once
    // gets a third of the way to it. Practice (§7.2.1) fills in from there,
    // and cannot replace it: going 31 to 50 on kills alone is 3 635 of them.
    final data =
        jsonDecode(File('assets/data/literature.json').readAsStringSync())
            as Map<String, Object?>;

    final perSkill = <String, double>{};
    for (final raw in data['items']! as List) {
      final props = (raw as Map)['props'] as Map;
      final skill = props['skill'];
      if (skill is! String) continue;

      final pages =
          ((props['pages_min'] as num) + (props['pages_max'] as num)) / 2;
      final xp = (props['xp_per_page'] as num).toDouble();

      perSkill[skill] = (perSkill[skill] ?? 0) + pages * xp;
    }

    for (final entry in perSkill.entries) {
      expect(
        levelForXp(entry.value.round()),
        inInclusiveRange(25, 40),
        reason: '${entry.key} is worth ${entry.value.round()} XP',
      );
    }
  });
}
