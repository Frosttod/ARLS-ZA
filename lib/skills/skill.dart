/// The four skills, and the curve that turns experience into a level (§7).
///
/// ⚠️ **Eight functions in this codebase already take a skill and default it
/// to nought.** `skillMoa`, `targetSwitchTime`, `sprintBudget`,
/// `searchRadiusM`, `LootTable.roll`, `craftWork`, `salvageShare` and
/// `buildTime` were all written with the parameter in place and nothing to
/// fill it in — so every character in the game shoots, searches and builds
/// like somebody who has never done it before. This is the missing half.
///
/// Deliberately outside `lib/sim`. §7 is not physiology: it does not tick, it
/// does not belong in `advance()`, and a skill that could reach into the tick
/// would be a skill that changes how fast a day passes.
library;

import 'dart:convert';
import 'dart:math' as math;

/// §7: the four, named as the shipped data names them.
///
/// ⚠️ The wire names are not a choice. `assets/data/literature.json` has
/// tagged every book with one of these since stage 4, and that file is
/// shipped — renaming the enum would orphan eighteen titles on players'
/// phones. The words a player reads are in the translations.
enum Skill {
  /// Searching, finding, and not being seen doing it (§10.2, §6.2).
  scouting('scouting'),

  /// §5: the rifle, the reload, the settling sights.
  weapons('weapons'),

  /// §4.7, §2.6: bandages, and what a body does with a night's rest.
  medicine('medicine'),

  /// §8.3, §18.4, §18.6: building, making, taking apart.
  engineering('engineering');

  const Skill(this.wire);

  /// What the item data and the database call it.
  final String wire;

  static Skill? fromWire(String? value) {
    if (value == null) return null;
    for (final skill in values) {
      if (skill.wire == value) return skill;
    }
    return null;
  }
}

/// §7.2: the highest level there is.
const int kMaxSkillLevel = 100;

/// §7.2: what the next level costs, in experience.
///
/// A linearly rising cost: level 1 is 70, level 100 is 7 000. The ratio of a
/// hundred to one gives a progression that is felt without being a wall.
const int kXpPerLevelStep = 70;

/// §7.2: experience needed to *reach* [level] from nothing.
///
/// The sum of `70 × p` for p in 1..level, which closes to `35 × n × (n + 1)`.
/// Reaching 100 costs 353 500 — see [kXpToMaxSkill].
int xpForLevel(int level) {
  final capped = level.clamp(0, kMaxSkillLevel);
  return (kXpPerLevelStep ~/ 2) * capped * (capped + 1);
}

/// §7.2: the whole climb, 353 500.
final int kXpToMaxSkill = xpForLevel(kMaxSkillLevel);

/// §7.2: what [xp] is worth, as a level from 0 to 100.
///
/// The inverse of [xpForLevel], solved rather than searched: for
/// `xp = 35n(n+1)` the positive root is `(√(1 + 4·xp/35) − 1) / 2`.
int levelForXp(int xp) {
  if (xp <= 0) return 0;

  final n = (math.sqrt(1 + 4 * xp / (kXpPerLevelStep / 2)) - 1) / 2;
  final level = n.floor();

  return level > kMaxSkillLevel ? kMaxSkillLevel : level;
}

/// What one skill is worth right now.
class SkillProgress {
  const SkillProgress({required this.skill, required this.xp});

  final Skill skill;

  /// Everything earned in this skill, ever.
  final int xp;

  /// §7: 0 to 100.
  int get level => levelForXp(xp);

  /// ⚠️ **The number every hook in the game actually wants.**
  ///
  /// `skillMoa`, `craftWork` and the rest all take 0–1 and scale their own
  /// effect by it, so this is the single conversion between §7's hundred
  /// levels and everybody else's fraction. Doing it anywhere else would mean
  /// two places deciding what "half a skill" means.
  double get fraction => level / kMaxSkillLevel;

  /// How far into the current level, 0–1. For a bar that moves every page.
  double get intoLevel {
    if (level >= kMaxSkillLevel) return 1;

    final from = xpForLevel(level);
    final to = xpForLevel(level + 1);
    if (to <= from) return 1;

    return ((xp - from) / (to - from)).clamp(0.0, 1.0);
  }

  /// Experience still owed on this level.
  int get xpToNext => level >= kMaxSkillLevel ? 0 : xpForLevel(level + 1) - xp;
}

/// All four, and the only place the game reads a skill from.
///
/// Immutable, like everything else the game keeps state in: [awarded] returns
/// a new set rather than mutating, so a controller can publish it to a
/// `ValueNotifier` and nothing downstream has to guess whether it changed.
class SkillSet {
  const SkillSet(this._xp);

  const SkillSet.empty() : _xp = const {};

  final Map<Skill, int> _xp;

  static const SkillSet none = SkillSet.empty();

  int xpOf(Skill skill) => _xp[skill] ?? 0;

  SkillProgress operator [](Skill skill) =>
      SkillProgress(skill: skill, xp: xpOf(skill));

  int levelOf(Skill skill) => this[skill].level;

  /// §7: the 0–1 figure the rest of the game asks for.
  double fractionOf(Skill skill) => this[skill].fraction;

  /// Named getters, because every call site reads better for them and because
  /// `fractionOf(Skill.engineering)` at a bench is noise.
  double get scouting => fractionOf(Skill.scouting);
  double get weapons => fractionOf(Skill.weapons);
  double get medicine => fractionOf(Skill.medicine);
  double get engineering => fractionOf(Skill.engineering);

  /// Everything earned across all four. For the Chronicle (§13.1).
  int get totalXp => _xp.values.fold(0, (sum, xp) => sum + xp);

  /// §7.2.1: adds experience, and says whether that crossed a level.
  ///
  /// ⚠️ The level is returned rather than announced from here. Telling the
  /// player is §12's job and needs a `BuildContext`; this is a value type and
  /// must not know what a snack bar is.
  ({SkillSet set, bool levelled}) awarded(Skill skill, int xp) {
    if (xp <= 0) return (set: this, levelled: false);

    final before = levelOf(skill);
    final next = SkillSet({..._xp, skill: xpOf(skill) + xp});

    return (set: next, levelled: next.levelOf(skill) > before);
  }

  Map<String, Object?> toJson() => {
    for (final entry in _xp.entries) entry.key.wire: entry.value,
  };

  String encode() => jsonEncode(toJson());

  /// Reads a set back, and never throws on rubbish.
  ///
  /// A skill the running version does not know about is dropped rather than
  /// guessed at — the same rule the item catalogue keeps for an uninstalled
  /// content pack.
  static SkillSet fromJson(Object? raw) {
    if (raw is! Map) return none;

    final out = <Skill, int>{};
    for (final entry in raw.entries) {
      final skill = Skill.fromWire(entry.key as String?);
      final xp = entry.value;
      if (skill != null && xp is num && xp > 0) out[skill] = xp.toInt();
    }

    return SkillSet(out);
  }

  static SkillSet decode(String? raw) {
    if (raw == null || raw.isEmpty) return none;

    try {
      return fromJson(jsonDecode(raw));
    } on FormatException {
      return none;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SkillSet &&
      Skill.values.every((skill) => xpOf(skill) == other.xpOf(skill));

  @override
  int get hashCode =>
      Object.hashAll([for (final skill in Skill.values) xpOf(skill)]);

  @override
  String toString() => encode();
}
