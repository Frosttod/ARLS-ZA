/// The character, and what they have done (§13.1, §15.4).
///
/// Four questions, in the order somebody asks them about their own survivor:
/// how long have I lasted, what is this body, what is currently making me
/// miss, and what have I actually done out there.
///
/// The third one earns its place. §5.1.4 already names the largest source of
/// spread beside the hit chance during a fight, but a fight is a bad moment to
/// study a table — this is where a player can see the whole budget at rest and
/// work out that it is their own pulse rather than the rifle.
library;

import 'package:flutter/material.dart';

import 'fonts.dart';
import 'units.dart';
import '../combat/ballistics.dart';
import '../l10n/app_localizations.dart';
import '../sim/body.dart';
import '../sim/player_stats.dart';
import '../sim/tick.dart';
import 'combat_panel.dart' show errorName, hitLocationName;
import 'hud.dart' show HudColors;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.name,
    required this.body,
    required this.status,
    required this.stats,
    required this.aliveFor,
    required this.weaponMoa,
    super.key,
  });

  final String name;
  final BodyProfile body;
  final SimStatus status;
  final PlayerStats stats;

  /// §13.1: the survival streak, which is the one number a run is about.
  final Duration aliveFor;

  /// §5.1.1: what the weapon in hand contributes, or null with empty hands.
  final double? weaponMoa;

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
          _Section(label: l10n.profileAim, colours: colours),
          _AimBudget(
            status: status,
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
                : '${stats.swings} · '
                      '${(stats.meleeAccuracy! * 100).round()}%',
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

          const SizedBox(height: 20),
          _Section(label: l10n.profileSkills, colours: colours),
          Text(
            l10n.profileSkillsSoon,
            style: TextStyle(fontSize: 12, height: 1.4, color: colours.muted),
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

/// §5.1.1: the whole error budget, at rest.
///
/// The point of showing it here rather than only in a fight: the largest row
/// is nearly always the pulse or the legs, and both are things a player can do
/// something about by standing still — a lesson better learned in a quiet
/// moment than in front of a Walker.
class _AimBudget extends StatelessWidget {
  const _AimBudget({
    required this.status,
    required this.weaponMoa,
    required this.colours,
    required this.l10n,
  });

  final SimStatus status;
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
      skill: skillMoa(0),
      heart: 0,
      movement: 0,
      target: 0,
      condition: status.totalExtraMoa,
    );

    return Column(
      children: [
        for (final source in ErrorSource.values)
          if (error.get(source) > 0)
            _Line(
              label: errorName(l10n, source),
              value: '${error.get(source).toStringAsFixed(1)} MOA',
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
              '$hits · ${(share * 100).round()}%',
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
