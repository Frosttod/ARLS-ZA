/// What doing something is worth (§7.2.1).
///
/// ⚠️ **Four skills were fully wired and none of them could ever grow.**
/// `skillMoa`, `searchRadiusM`, `craftWork`, `buildTime` and the rest have all
/// taken a skill since stage A, `SkillController.award` has been able to pay
/// experience into one since the same day, and nothing in the game ever called
/// it. Every character shot, searched and built like somebody who had never
/// done any of it before, for ever.
///
/// ⚠️ **And practice is deliberately not the way up.** §7.2.1 is explicit:
/// 353 500 experience at fifteen a kill is twenty-three thousand bodies. These
/// figures exist to reward a style of play and to make the first levels arrive
/// while somebody is playing rather than reading — the climb itself is
/// literature (§4.6), and §7.2.2 puts that at about five hundred hours for one
/// skill. A player who never opens a book should feel the difference.
library;

import 'skill.dart';

/// One thing a character can do that teaches them something.
enum Practice {
  /// §5: every trigger pull, and what it was pulled at.
  shot(Skill.weapons, 1),
  kill(Skill.weapons, 15),

  /// §4.7: a dressing, a tourniquet, a suture.
  dressing(Skill.medicine, 25),

  /// §18.4, §8.3: what came off a bench, and what went up on a wall.
  ///
  /// A module is worth more than thirteen crafted items because it is days of
  /// a run rather than minutes of one (§8.3).
  crafted(Skill.engineering, 30),
  moduleBuilt(Skill.engineering, 400),

  /// §10.2: a place turned over, and each thing carried away from it.
  searched(Skill.scouting, 8),
  looted(Skill.scouting, 3);

  const Practice(this.skill, this.xp);

  /// Which of the four this teaches.
  final Skill skill;

  /// §7.2.1's own figure. Not a knob: the whole table is balanced against
  /// [kXpToMaxSkill] and against literature being the real path.
  final int xp;
}

/// What the whole of §7.2.1 is worth in one day of hard play, for the balance
/// tests: a hundred shots, ten kills, twenty searches and sixty things picked
/// up is a long walk, and it must stay a rounding error against the climb.
int practiceIn(Map<Practice, int> counts) =>
    counts.entries.fold(0, (sum, entry) => sum + entry.key.xp * entry.value);
