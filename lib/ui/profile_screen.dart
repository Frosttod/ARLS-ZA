/// The character, and what they have done (§13.1, §15.4).
///
/// Six questions, in the order somebody asks them about their own survivor:
/// how long have I lasted, what is this body, **how is it doing**, **what is
/// that costing me**, what have I learned, what is making me miss, and what
/// have I actually done out there.
///
/// ⚠️ The middle two are the ones the HUD cannot answer. A bar says *how much
/// water is left*; it cannot say that being two days behind on sleep is what
/// makes every search take half as long again, and it certainly cannot say
/// that the reason is three weeks of six-hour nights rather than last night.
/// A penalty a player can see but not account for reads as a bug — this is
/// where it is accounted for.
///
/// The aim budget earns its place for the same reason. §5.1.4 already names
/// the largest source of spread beside the hit chance during a fight, but a
/// fight is a bad moment to study a table.
library;

import 'package:flutter/material.dart';

import 'fonts.dart';
import 'units.dart';
import '../combat/ballistics.dart';
import '../combat/enemy.dart' show kScoutingStealth;
import '../combat/magazine.dart' show kWeaponsSpeed;
import '../craft/item_recipe.dart' show kSalvageReturn, kSalvageReturnSkilled;
import '../inventory/item_use.dart' show kMedicineSpeed;
import '../loot/search.dart' show kScoutingSpeed;
import '../sim/physiology.dart';
import '../l10n/app_localizations.dart';
import '../skills/skill.dart';
import 'effects.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../journal/journal.dart';
import '../sim/body.dart';
import '../sim/player_stats.dart';
import '../sim/tick.dart';
import 'combat_panel.dart' show errorName, hitLocationName;
import 'hud.dart' show HudColors;
import 'journal_view.dart';
import 'names.dart';

/// Opens it as a pushed route.
///
/// ⚠️ The route belongs here rather than on the screen that calls it, for the
/// same reason every sheet's does: how the profile is presented is a fact
/// about the profile, and the caller's only business is what to put in it.
Future<void> showProfile(
  BuildContext context, {
  required String name,
  required BodyProfile body,
  required SimState state,
  required SimStatus status,
  required SkillSet skills,
  required PlayerStats stats,
  required Duration aliveFor,
  required double? weaponMoa,
  required List<JournalEntry> journal,
  required DateTime startedAt,
  required ItemCatalogue? catalogue,
  required ItemNames names,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ProfileScreen(
      name: name,
      body: body,
      state: state,
      status: status,
      skills: skills,
      stats: stats,
      aliveFor: aliveFor,
      weaponMoa: weaponMoa,
      journal: journal,
      startedAt: startedAt,
      catalogue: catalogue,
      names: names,
    ),
  ),
);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.name,
    required this.body,
    required this.state,
    required this.status,
    required this.skills,
    required this.stats,
    required this.aliveFor,
    required this.weaponMoa,
    required this.journal,
    required this.startedAt,
    required this.catalogue,
    required this.names,
    super.key,
  });

  final String name;
  final BodyProfile body;

  /// §2: the raw figures, so the screen can show millilitres and hours rather
  /// than only the tier they fall into.
  final SimState state;

  final SimStatus status;

  /// §7: what this character has learned.
  final SkillSet skills;

  final PlayerStats stats;

  /// §13.1: the survival streak, which is the one number a run is about.
  final Duration aliveFor;

  /// §5.1.1: what the weapon in hand contributes, or null with empty hands.
  final double? weaponMoa;

  /// §3.6.1: what the character did, newest first.
  final List<JournalEntry> journal;

  /// When the run began, so an entry knows which day it fell on.
  final DateTime startedAt;

  /// ⚠️ Nullable, because the profile opens before the catalogue is loaded on
  /// a cold start and an entry named by its raw item id is still a true entry.
  final ItemCatalogue? catalogue;

  final ItemNames names;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _Streak(name: name, aliveFor: aliveFor, colours: colours),
          const SizedBox(height: 20),

          // ⚠️ §1.3's four inputs, first. Everything below is derived from
          // them, and a player looking at a blood volume of 5 319 ml deserves
          // to see the height and weight it came out of.
          _Section(label: l10n.profileSheet, colours: colours),
          _Line(
            label: l10n.profileSex,
            value: body.spec.sex == Sex.male
                ? l10n.profileSexMale
                : l10n.profileSexFemale,
            colours: colours,
          ),
          _Line(
            label: l10n.profileAge,
            value: '${body.spec.ageYears}',
            colours: colours,
          ),
          _Line(
            label: l10n.profileHeight,
            value: '${body.spec.heightCm} cm',
            colours: colours,
          ),
          _Mass(body: body, state: state, colours: colours, l10n: l10n),
          _Line(
            label: l10n.profileBmi,
            value:
                (state.bodyMassKg /
                        ((body.spec.heightCm / 100) *
                            (body.spec.heightCm / 100)))
                    .toStringAsFixed(1),
            colours: colours,
          ),

          const SizedBox(height: 20),
          _Section(label: l10n.profileBody, colours: colours),
          _Line(
            label: l10n.profileBlood,
            value: '${body.bloodVolumeMl.round()} ml',
            colours: colours,
          ),
          _Line(
            label: l10n.profileEnergy,
            value: '${body.dailyEnergyKcal.round()} kcal',
            colours: colours,
          ),
          _Line(
            label: l10n.profileWater,
            value: '${body.baseWaterMlPerDay.round()} ml',
            colours: colours,
          ),
          _Line(
            label: l10n.profileCarry,
            value: outOfKg(body.carryComfortKg, body.carryMaxKg),
            colours: colours,
          ),
          _Line(
            label: l10n.profileHeart,
            value:
                '${body.restingHeartRate.round()} – '
                '${body.maxHeartRate.round()} bpm',
            colours: colours,
          ),

          const SizedBox(height: 20),
          _Section(label: l10n.profileState, colours: colours),
          _StateLines(
            body: body,
            state: state,
            status: status,
            colours: colours,
            l10n: l10n,
          ),

          const SizedBox(height: 20),
          _Section(label: l10n.profileWhy, colours: colours),
          _Why(state: state, status: status, colours: colours, l10n: l10n),

          const SizedBox(height: 20),
          _Section(label: l10n.profileSkills, colours: colours),
          for (final skill in Skill.values)
            _SkillRow(progress: skills[skill], colours: colours, l10n: l10n),

          const SizedBox(height: 20),
          _Section(label: l10n.profileAim, colours: colours),
          _AimBudget(
            status: status,
            weapons: skills.weapons,
            weaponMoa: weaponMoa,
            colours: colours,
            l10n: l10n,
          ),

          const SizedBox(height: 20),
          _Section(label: l10n.profileFighting, colours: colours),
          _Line(
            label: l10n.profileShots,
            value: '${stats.shotsFired}',
            colours: colours,
          ),
          _Line(
            label: l10n.profileAccuracy,
            value: stats.accuracy == null
                ? '—'
                : '${(stats.accuracy! * 100).round()}%',
            colours: colours,
          ),
          _Line(
            label: l10n.profileSwings,
            value: stats.meleeAccuracy == null
                ? '${stats.swings}'
                : effects([
                    '${stats.swings}',
                    '${(stats.meleeAccuracy! * 100).round()}%',
                  ]),
            colours: colours,
          ),
          _Line(
            label: l10n.profileKills,
            value: '${stats.kills}',
            colours: colours,
          ),
          _Line(
            label: l10n.profileShotsPerKill,
            value: stats.shotsPerKill == null
                ? '—'
                : stats.shotsPerKill!.toStringAsFixed(1),
            colours: colours,
          ),
          _Line(
            label: l10n.profileBloodDealt,
            value: '${stats.bloodDealtMl.round()} ml',
            colours: colours,
          ),
          _Line(
            label: l10n.profileBloodLost,
            value: '${stats.bloodLostMl.round()} ml',
            colours: colours,
          ),
          _Line(
            label: l10n.profileSearches,
            value: '${stats.searches}',
            colours: colours,
          ),
          _Line(
            label: l10n.profileBlackouts,
            value: '${stats.blackouts}',
            colours: colours,
          ),

          const SizedBox(height: 20),
          _Section(label: l10n.profileWhereTheyLand, colours: colours),
          if (stats.hitsCounted == 0)
            Text(
              l10n.profileNothingYet,
              style: TextStyle(fontSize: 12, color: colours.muted),
            )
          else
            for (final where in HitLocation.values)
              _HitBar(
                label: hitLocationName(l10n, where),
                hits: stats.hitsAt(where),
                total: stats.hitsCounted,
                colours: colours,
              ),

          // §3.6.1: and what that actually looked like, hour by hour. The
          // tally above says how many; this says what happened, which is the
          // question a player asks after a walk and the one a counter cannot
          // answer.
          const SizedBox(height: 20),
          _Section(label: l10n.journalTitle, colours: colours),
          ...journalRows(
            context,
            entries: journal,
            startedAt: startedAt,
            catalogue: catalogue,
            names: names,
          ),
        ],
      ),
    );
  }
}

/// §13.1: how long this one has lasted. The number a run is about.
class _Streak extends StatelessWidget {
  const _Streak({
    required this.name,
    required this.aliveFor,
    required this.colours,
  });

  final String name;
  final Duration aliveFor;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final days = aliveFor.inDays;
    final hours = aliveFor.inHours % 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colours.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          days > 0
              ? l10n.profileAliveDays(days, hours)
              : l10n.profileAliveHours(hours),
          style: TextStyle(fontSize: 14, color: colours.data),
        ),
      ],
    );
  }
}

/// §2.3.1: what the character weighs, and what they weighed.
///
/// ⚠️ Two numbers rather than one, once any of it is gone. Mass is a state
/// now, and "78 kg" tells a starving player nothing at all — "78 kg (start
/// 84 kg, −7%)" is the sentence that explains why the carry bar shrank.
class _Mass extends StatelessWidget {
  const _Mass({
    required this.body,
    required this.state,
    required this.colours,
    required this.l10n,
  });

  final BodyProfile body;
  final SimState state;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final start = body.startingMassKg;
    final now = state.bodyMassKg;
    final lost = start <= 0 ? 0.0 : (start - now) / start;

    return _Line(
      label: l10n.profileMass,
      value: lost < 0.005
          ? kilograms(now)
          : l10n.profileMassLost(
              now.toStringAsFixed(1),
              start.toStringAsFixed(1),
              (lost * 100).round(),
            ),
      colours: colours,
    );
  }
}

/// §2: the reserves, as figures rather than as bars.
///
/// The HUD draws these every second and a bar is the right shape there. Here
/// the question is different — *how much, exactly, and out of what* — because
/// this is the screen somebody opens to work out whether a litre is enough.
class _StateLines extends StatelessWidget {
  const _StateLines({
    required this.body,
    required this.state,
    required this.status,
    required this.colours,
    required this.l10n,
  });

  final BodyProfile body;
  final SimState state;
  final SimStatus status;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final constants = body.toSimConstants();

    return Column(
      children: [
        _Line(
          label: l10n.profileStateWater,
          value: l10n.profileOfDaily(
            '${state.waterMl.round()} ml',
            '${constants.waterDailyMl.round()} ml',
          ),
          colours: colours,
        ),
        _Line(
          label: l10n.profileStateCalories,
          value: l10n.profileOfDaily(
            '${state.caloriesKcal.round()} kcal',
            '${constants.caloriesDailyKcal.round()} kcal',
          ),
          colours: colours,
        ),
        _Line(
          label: l10n.profileStateSleep,
          value: l10n.profileDebtHours(state.sleepDebt.inHours),
          colours: colours,
        ),
        // §2.5.5: the figure the sleep bar cannot show, which is exactly why
        // it belongs on a screen that has room for words.
        _Line(
          label: l10n.profileStateStrain,
          value: l10n.profileNightsBehind(status.chronicSleep.strain.round()),
          colours: colours,
        ),
        _Line(
          label: l10n.profileStateBlood,
          value: l10n.profileOfDaily(
            '${state.bloodMl.round()} ml',
            '${constants.bloodMaxMl.round()} ml',
          ),
          colours: colours,
        ),
      ],
    );
  }
}

/// §12: every penalty the character is carrying, in sentences.
///
/// ⚠️ **The half of this screen the HUD cannot do.** A bar can say the sleep
/// reserve is low. It cannot say that the reason searching feels slow is
/// twelve hours of debt, that the reason wounds are not closing is three weeks
/// of six-hour nights, or that one good night will fix the first and not the
/// second. Those are the sentences a player needs and the HUD has no room for.
class _Why extends StatelessWidget {
  const _Why({
    required this.state,
    required this.status,
    required this.colours,
    required this.l10n,
  });

  final SimState state;
  final SimStatus status;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (status.sleep.extraMoa > 0)
        l10n.profileWhySleepDebt(
          state.sleepDebt.inHours,
          ((status.sleep.actionTimeMultiplier - 1) * 100).round(),
          status.sleep.extraMoa.toStringAsFixed(0),
        ),
      if (status.chronicSleep.strain >= 1)
        l10n.profileWhyStrain(
          status.chronicSleep.strain.round(),
          ((1 - status.chronicSleep.healingMultiplier) * 100).round(),
        ),
      if (status.thirst.accuracyPenalty < 1)
        l10n.profileWhyThirst(
          (status.thirst.deficitFractionOfBodyMass * 100).round(),
          ((status.thirst.actionTimeMultiplier - 1) * 100).round(),
          ((1 - status.thirst.accuracyPenalty) * 100).round(),
        ),
      if (status.hunger.precisionPenalty < 1)
        l10n.profileWhyHunger((status.hunger.fraction * 100).round()),
      if (status.wasting.lostFraction >= 0.05)
        l10n.profileWhyWasting((status.wasting.lostFraction * 100).round()),
      if (status.blood.shockClass != ShockClass.none)
        l10n.profileWhyBlood(
          _shockRoman(status.blood.shockClass),
          status.blood.shockClass.label,
        ),
    ];

    if (lines.isEmpty) {
      return Text(
        l10n.profileWhyNothing,
        style: TextStyle(fontSize: 12, height: 1.5, color: colours.muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              line,
              style: TextStyle(fontSize: 12, height: 1.5, color: colours.text),
            ),
          ),
      ],
    );
  }
}

String _shockRoman(ShockClass shock) => switch (shock) {
  ShockClass.none => '—',
  ShockClass.compensated => 'II',
  ShockClass.decompensated => 'III',
  ShockClass.critical => 'IV',
};

/// §7: one skill, what it is worth, and what it is actually doing.
///
/// ⚠️ The second line is the whole point. "Scouting 40 / 100" is a number
/// nobody can act on; "search radius +40%, noticed 12% later" is the same
/// number in the units the player plays in — and it is the only way to see
/// what Scouting bought, because the fight it prevented never happened.
class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.progress,
    required this.colours,
    required this.l10n,
  });

  final SkillProgress progress;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.fraction;

    final name = skillName(l10n, progress.skill);

    // §12: the same shape the shelter modules use — a label, a number, one
    // separator. Three screens were each inventing their own.
    final what = effects(switch (progress.skill) {
      // §10.2.2 doubles the radius at full mastery; §10.3.5 gives the rare
      // share; the other two are §7's own thirty per cent.
      Skill.scouting => [
        effect(l10n.effectRadius, plusPercent(fraction)),
        effect(l10n.effectRare, plusPercent(0.30 * fraction)),
        effect(l10n.effectSearch, plusPercent(-kScoutingSpeed * fraction)),
        effect(l10n.effectStealth, times(1 - kScoutingStealth * fraction)),
      ],
      // §5.1.1: 25 MOA at nothing, 4 at everything.
      Skill.weapons => [
        effect(
          l10n.effectSpread,
          '${skillMoa(fraction).toStringAsFixed(1)} MOA',
        ),
        effect(l10n.effectReload, plusPercent(-kWeaponsSpeed * fraction)),
      ],
      Skill.medicine => [
        effect(l10n.effectDressing, plusPercent(-kMedicineSpeed * fraction)),
        effect(l10n.effectHealing, times(1 + kMedicineHealing * fraction)),
      ],
      Skill.engineering => [
        effect(l10n.effectWork, plusPercent(-0.30 * fraction)),
        effect(
          l10n.effectSalvage,
          percent(
            kSalvageReturn +
                (kSalvageReturnSkilled - kSalvageReturn) * fraction,
          ),
        ),
      ],
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 14, color: colours.text),
                ),
              ),
              Text(
                l10n.profileSkillLevel(progress.level),
                style: TextStyle(
                  fontSize: 13,
                  color: colours.data,
                  fontFamily: kDataFont,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            // §7.2: the bar moves within the level, not across the hundred —
            // otherwise a page read at level 40 moves nothing anybody can see.
            value: progress.intoLevel,
            minHeight: 4,
            backgroundColor: colours.muted.withValues(alpha: 0.25),
            color: colours.data,
          ),
          const SizedBox(height: 4),
          Text(
            what,
            style: TextStyle(fontSize: 11, height: 1.4, color: colours.muted),
          ),
        ],
      ),
    );
  }
}

/// §5.1.1: the whole error budget, at rest.
///
/// The point of showing it here rather than only in a fight: the largest row
/// is nearly always the pulse or the legs, and both are things a player can do
/// something about by standing still — a lesson better learned in a quiet
/// moment than in front of a Walker.
///
/// ⚠️ **These do not add up, and the screen used to pretend they might.**
///
/// Reported from a walk as "the total does not agree". It did agree — with
/// §5.1, which combines the sources in quadrature: 4 MOA of rifle, 25 of a
/// novice's hands and 3 of a wrecked body come to 25.5, not to 32. That is
/// correct and it is not what a column of numbers over a rule says. A list
/// with a divider under it is the universal shape of an addition, and a player
/// who reads it as one and gets a smaller answer has found a bug, whatever the
/// arithmetic is doing.
///
/// So the addition is not drawn any more. Each row now carries **its share of
/// the group**, which is what quadrature actually means — the share is the
/// square of the row over the square of the total, so the largest source
/// dominates and the small ones nearly vanish. For the figures above: skill
/// 96%, weapon 2%, condition 1%. That is the sentence §5.1.4 has been trying
/// to say beside the hit chance all along, and it is far more use than a sum.
class _AimBudget extends StatelessWidget {
  const _AimBudget({
    required this.status,
    required this.weapons,
    required this.weaponMoa,
    required this.colours,
    required this.l10n,
  });

  final SimStatus status;

  /// §7: the Weapons skill, 0–1.
  final double weapons;

  final double? weaponMoa;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    // §7 has no skills yet, so everybody shoots like a novice. Written as the
    // model writes it rather than as a guess, so this screen cannot drift
    // away from what the shot actually does.
    final error = ShotError(
      weapon: weaponMoa ?? 0,
      // §7: what this character's hands are worth. 25 MOA at nothing, 4 at
      // everything (§5.1.1) — and until skills existed this line read
      // `skillMoa(0)`, so the screen told every player they were a novice
      // whatever they had learned.
      skill: skillMoa(weapons),
      heart: 0,
      movement: 0,
      target: 0,
      condition: status.totalExtraMoa,
    );

    // The share of the group each source owns, which for a sum of squares is
    // its square over the total's. Guarded, because a character with a bare
    // hand and no penalties has a total of nought and nothing to divide by.
    final variance = error.total * error.total;

    return Column(
      children: [
        for (final source in ErrorSource.values)
          if (error.get(source) > 0)
            _Line(
              label: errorName(l10n, source),
              value: effects([
                '${error.get(source).toStringAsFixed(1)} MOA',
                l10n.profileAimShare(
                  variance <= 0
                      ? 0
                      : (100 * error.get(source) * error.get(source) / variance)
                            .round(),
                ),
              ]),
              colours: colours,
            ),
        const Divider(height: 18),
        _Line(
          label: l10n.profileTotalSpread,
          value: '${error.total.toStringAsFixed(1)} MOA',
          colours: colours,
          strong: true,
        ),
        const SizedBox(height: 6),
        // ⚠️ Said out loud, because the shape of the list promises an addition
        // and the arithmetic is not one. Reported from a walk as exactly that.
        Text(
          l10n.profileAimQuadrature,
          style: TextStyle(fontSize: 11, height: 1.4, color: colours.muted),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.profileAimWhat,
          style: TextStyle(fontSize: 11, height: 1.4, color: colours.muted),
        ),
      ],
    );
  }
}

/// Where the player's own rounds have been landing, against §2.6's shares.
/// ⚠️ No mark on the bar, and there was §2.6's expected share on it for a day.
///
/// It was the same mark the HUD uses for water and food, where it means
/// *something is on its way* — and read as exactly that here, on bars where
/// nothing is coming at all. A tally of what has already happened has no room
/// for a promise about what has not.
class _HitBar extends StatelessWidget {
  const _HitBar({
    required this.label,
    required this.hits,
    required this.total,
    required this.colours,
  });

  final String label;
  final int hits;
  final int total;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : hits / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colours.muted),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, _) => LinearProgressIndicator(
                  value: share,
                  minHeight: 5,
                  backgroundColor: colours.muted.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(colours.data),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              effects(['$hits', '${(share * 100).round()}%']),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: colours.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.colours});

  final String label;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: colours.muted),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.colours,
    this.strong = false,
  });

  final String label;
  final String value;
  final HudColors colours;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colours.muted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: colours.text,
            fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            fontFamily: kDataFont,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
