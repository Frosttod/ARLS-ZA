/// What the character has learned, and the only place that answer lives (§7).
///
/// ⚠️ **Not a controller that ticks.** Skills are the one long-term axis in
/// this game that owes nothing to the clock: they move when something happens
/// — a page read, a shot fired, a module finished — and never on their own.
/// So this holds no timer, registers no ticker, and is not consulted by
/// `advance()`. A skill that could reach into the tick would be a skill that
/// changes how fast a day passes.
///
/// Everything downstream asks for a fraction of one. §7's hundred levels turn
/// into the 0–1 that `skillMoa`, `craftWork` and the rest were written to
/// take, and that conversion happens in exactly one place — [SkillProgress].
library;

import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../skills/skill.dart';

class SkillController extends ChangeNotifier {
  SkillController(this._db);

  final SaveDatabase _db;

  /// ⚠️ Created here and never replaced, so a screen that took a reference at
  /// boot still has the right one an hour later — the same rule every other
  /// controller in this directory keeps.
  final ValueNotifier<SkillSet> skills = ValueNotifier(SkillSet.none);

  int? _profileId;

  SkillSet get set => skills.value;

  /// §7: the 0–1 figure every hook in the game asks for.
  double fractionOf(Skill skill) => set.fractionOf(skill);

  double get scouting => set.scouting;
  double get weapons => set.weapons;
  double get medicine => set.medicine;
  double get engineering => set.engineering;

  /// Reads what this character already knows.
  Future<void> load(int profileId) async {
    _profileId = profileId;

    final rows = await _db.skillsFor(profileId);
    skills.value = SkillSet.fromJson(rows);

    notifyListeners();
  }

  /// §7.2.1: pays experience into one skill.
  ///
  /// Returns true when that crossed a level, so the caller can say so out loud
  /// (§12). Telling the player is not this class's job — it has no
  /// `BuildContext` and must not grow one.
  ///
  /// ⚠️ Written to disk before this returns. §7.2's whole climb is 353 500
  /// experience earned a page and a shot at a time, and a level lost to a
  /// process kill is hours of walking a player will never get back.
  Future<bool> award(Skill skill, int xp) async {
    if (xp <= 0) return false;

    final result = set.awarded(skill, xp);
    if (identical(result.set, set)) return false;

    skills.value = result.set;
    notifyListeners();

    final profileId = _profileId;
    if (profileId != null) {
      await _db.writeSkill(profileId, skill.wire, result.set.xpOf(skill));
    }

    return result.levelled;
  }

  /// Sets a skill outright. Development only (§15.3).
  ///
  /// ⚠️ Exists so that stage A can be walked before stage C. Everything §7
  /// does is wired up now and nothing yet grants meaningful experience, so
  /// without a way to say "make me a master engineer" the entire feature would
  /// be untestable in the field until reading lands.
  Future<void> setLevel(Skill skill, int level) async {
    final xp = xpForLevel(level.clamp(0, kMaxSkillLevel));

    skills.value = SkillSet({
      for (final each in Skill.values)
        each: each == skill ? xp : set.xpOf(each),
    });
    notifyListeners();

    final profileId = _profileId;
    if (profileId != null) await _db.writeSkill(profileId, skill.wire, xp);
  }

  @override
  void dispose() {
    skills.dispose();
    super.dispose();
  }
}
