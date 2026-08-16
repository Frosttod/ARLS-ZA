/// The trigger, and the odds beside it (§5.1.4, §5.5.2).
///
/// ⚠️ §5.1.4 makes the number compulsory, and it is worth restating why: with
/// a model this unforgiving, a player who misses five times at 26% will decide
/// the game is broken. Shown the 26% first, they spend the round knowing what
/// they are buying. **The model may be as merciless as it is legible**, and no
/// more.
///
/// Beside the percentage is the largest single source of error, because that
/// is the part the player can do something about: stand still, wait for the
/// pulse, or not take the shot.
library;

import 'package:flutter/material.dart';

import '../combat/ballistics.dart';
import '../combat/enemy.dart';
import '../l10n/app_localizations.dart';
import 'hud.dart' show HudColors;

class CombatPanel extends StatelessWidget {
  const CombatPanel({
    required this.targetName,
    required this.distanceM,
    required this.chance,
    required this.dominant,
    required this.condition,
    required this.sprintLeft,
    required this.onFire,
    this.onStrike,
    this.refusal,
    super.key,
  });

  /// What is being aimed at, in words (§5.5.1).
  final String targetName;

  final double distanceM;

  /// §5.1.4: 0–1, and shown as a whole percentage.
  final double chance;

  /// §5.1.4: the largest component of the error.
  final ErrorSource dominant;

  /// §5.5.1: how badly hurt it looks. Three words, because that is all anybody
  /// could honestly tell at two hundred metres.
  final EnemyCondition condition;

  /// §5.5.2: how much sprint it has left, 0–1. The tactical fact of a group
  /// fight — one that has burned its budget can be walked away from.
  final double sprintLeft;

  /// Null while there is nothing to fire — no weapon in hand, or no round for
  /// it. The reason is said in [refusal] rather than left to a dead button.
  final VoidCallback? onFire;

  /// §5.2, §5.4: hands, once something is inside twenty metres. Null while it
  /// is further off than a person can reach.
  final VoidCallback? onStrike;

  final String? refusal;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);
    final percent = (chance * 100).round();

    // §12: never colour alone. The percentage is the information; the colour
    // only saves a moment reading it.
    final colour = percent >= 60
        ? colours.data
        : percent >= 25
        ? const Color(0xFFE8B33A)
        : colours.alert;

    return Material(
      color: colours.panel.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$targetName · ${l10n.combatDistance(distanceM.round())}'
                      ' · ${conditionName(l10n, condition)}',
                      style: TextStyle(fontSize: 12, color: colours.text),
                    ),
                    const SizedBox(height: 3),

                    // §5.5.2: what it has left in its legs, as a bar rather
                    // than a number — the question is "can it still catch me",
                    // not "how many seconds".
                    Row(
                      children: [
                        Text(
                          l10n.enemySprint,
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.1,
                            color: colours.muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: sprintLeft.clamp(0.0, 1.0),
                              backgroundColor: colours.muted.withValues(
                                alpha: 0.25,
                              ),
                              color: sprintLeft > 0.1
                                  ? colours.alert
                                  : colours.data,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          l10n.combatChance(percent),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colour,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // What is costing the shot, so a miss can be
                          // answered rather than resented.
                          errorName(l10n, dominant),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: colours.muted,
                          ),
                        ),
                      ],
                    ),
                    if (refusal != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        refusal!,
                        style: TextStyle(
                          fontSize: 11,
                          color: colours.alert,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onStrike != null) ...[
                OutlinedButton(
                  onPressed: onStrike,
                  child: Text(l10n.combatStrike),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(
                onPressed: onFire,
                child: Text(l10n.combatFire),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// §5.5.1's estimate, in words.
String conditionName(L10n l10n, EnemyCondition condition) => switch (condition) {
  EnemyCondition.healthy => l10n.enemyHealthy,
  EnemyCondition.wounded => l10n.enemyWounded,
  EnemyCondition.critical => l10n.enemyCritical,
};

/// §5.1.4's word beside the percentage.
String errorName(L10n l10n, ErrorSource source) => switch (source) {
  ErrorSource.weapon => l10n.errorWeapon,
  ErrorSource.skill => l10n.errorSkill,
  ErrorSource.heart => l10n.errorHeart,
  ErrorSource.movement => l10n.errorMovement,
  ErrorSource.target => l10n.errorTarget,
  ErrorSource.condition => l10n.errorCondition,
};
