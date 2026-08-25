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

import '../combat/target_reading.dart';

import 'fonts.dart';
import '../combat/ballistics.dart';
import '../combat/enemy.dart';
import '../l10n/app_localizations.dart';
import 'effects.dart';
import 'hud.dart' show HudColors;

class CombatPanel extends StatelessWidget {
  const CombatPanel({
    required this.reading,
    required this.onFire,
    this.onStrike,
    this.onReload,
    super.key,
  });

  /// ⚠️ **One value, not forty arguments.** Everything drawn here is decided
  /// in [readTarget] and tested there: the distance, the odds, what can be
  /// fired or swung at, and why not. The panel used to be assembled inline in
  /// the largest build method in the codebase, recomputing the distance four
  /// times and the safe-zone rule three, which is four distances and three
  /// rules the next time one of them is edited.
  final TargetReading reading;

  /// §5.5.4: what pulling the trigger does. Null when it may not be pulled;
  /// the reason is in [TargetReading.refusal] rather than left to a dead
  /// button.
  final VoidCallback? onFire;

  /// §5.4: and what swinging does, inside §5.2's twenty metres.
  final VoidCallback? onStrike;

  /// §5.5.4: puts a magazine in, and can be interrupted by anything closing.
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);
    final odds = reading.chance;
    final percent = odds == null ? null : (odds * 100).round();

    // §12: never colour alone. The percentage is the information; the colour
    // only saves a moment reading it.
    final colour = percent == null
        ? colours.muted
        : percent >= 60
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
                    // What it is, how far, how hurt — and then what is in the
                    // player's own hands. What the Walker is *thinking* is
                    // already on the map as a glyph over its head (§6.1a), and
                    // saying it twice cost the line the weapon needed.
                    Text(
                      effects([
                        reading.targetName,
                        l10n.combatDistance(reading.distanceM.round()),
                        conditionName(l10n, reading.condition),
                        if (reading.bleeding) l10n.enemyBleeding,
                      ]),
                      style: TextStyle(fontSize: 12, color: colours.text),
                    ),
                    if (reading.weaponName != null)
                      Text(
                        effects([
                          reading.weaponName!,
                          if (reading.magazine > 0)
                            l10n.combatRounds(reading.loaded, reading.magazine),
                        ]),
                        style: TextStyle(fontSize: 12, color: colours.data),
                      ),
                    const SizedBox(height: 3),

                    // §2.6: what is left in it, which is the other half of
                    // "is this worth another round".
                    Row(
                      children: [
                        Text(
                          l10n.hudBlood,
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
                              value: reading.bloodLeft.clamp(0.0, 1.0),
                              backgroundColor: colours.muted.withValues(
                                alpha: 0.25,
                              ),
                              color: reading.bleeding
                                  ? colours.alert
                                  : colours.data,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

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
                              value: reading.sprintLeft.clamp(0.0, 1.0),
                              backgroundColor: colours.muted.withValues(
                                alpha: 0.25,
                              ),
                              color: reading.sprintLeft > 0.1
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
                          percent == null ? '—' : l10n.combatChance(percent),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colour,
                            fontFamily: kDataFont,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // §5.3: a number that climbs on its own needs
                          // saying, or it reads as the game changing its mind.
                          reading.settling
                              ? l10n.combatAiming
                              : l10n.combatOnTarget,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: reading.settling
                                ? colours.alert
                                : colours.data,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // What is costing the shot, so a miss can be
                          // answered rather than resented.
                          reading.dominant == null
                              ? ''
                              : errorName(l10n, reading.dominant!),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: colours.muted,
                          ),
                        ),
                      ],
                    ),
                    if (reading.refusal != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        refusalName(l10n, reading.refusal!),
                        style: TextStyle(fontSize: 11, color: colours.alert),
                      ),
                    ],
                  ],
                ),
              ),
              if (reading.reloading)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    l10n.combatReloading,
                    style: TextStyle(fontSize: 11, color: colours.muted),
                  ),
                )
              // ⚠️ Gated on the reading, never on the callback being null.
              // Whether a magazine may go in is §5.3's rule and it is decided
              // in [readTarget]; a widget that inferred it from an absent
              // callback would be a second copy of the rule, in the one place
              // it cannot be tested.
              else if (reading.canReload && onReload != null) ...[
                OutlinedButton(
                  onPressed: onReload,
                  child: Text(l10n.combatReload),
                ),
                const SizedBox(width: 8),
              ],
              if (reading.canStrike && onStrike != null) ...[
                OutlinedButton(
                  onPressed: onStrike,
                  child: Text(l10n.combatStrike),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(
                onPressed: reading.canFire ? onFire : null,
                child: Text(l10n.combatFire),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// §2.6, in the words a log needs.
String hitLocationName(L10n l10n, HitLocation location) => switch (location) {
  HitLocation.head => l10n.hitHead,
  HitLocation.torso => l10n.hitTorso,
  HitLocation.arms => l10n.hitArms,
  HitLocation.legs => l10n.hitLegs,
};

/// §6.1a, in the player's words rather than the machine's.
String stateName(L10n l10n, EnemyState state) => switch (state) {
  EnemyState.idle || EnemyState.returning => l10n.enemyCalm,
  EnemyState.alert => l10n.enemySearching,
  EnemyState.chase || EnemyState.spent => l10n.enemyHunting,
};

/// §6.2's three sorts, named.
String enemyKindName(L10n l10n, EnemyKind kind) => switch (kind) {
  EnemyKind.walker => l10n.enemyWalker,
  EnemyKind.leaper => l10n.enemyLeaper,
  EnemyKind.brute => l10n.enemyBrute,
};

/// §5.5.1's estimate, in words.
String conditionName(L10n l10n, EnemyCondition condition) =>
    switch (condition) {
      EnemyCondition.healthy => l10n.enemyHealthy,
      EnemyCondition.wounded => l10n.enemyWounded,
      EnemyCondition.critical => l10n.enemyCritical,
    };

/// §5.5.4, §8.1: why the trigger is not available, in the player's language.
///
/// ⚠️ Named here rather than decided here. Which refusal applies is a rule of
/// §5 and §8.1 and lives in [readTarget]; four localised strings chosen inline
/// put Polish in the middle of a decision about ammunition.
String refusalName(L10n l10n, CombatRefusal refusal) => switch (refusal) {
  CombatRefusal.insideOwnZone => l10n.shelterInside,
  CombatRefusal.grace => l10n.downGrace,
  CombatRefusal.noWeapon => l10n.combatNoWeapon,
  CombatRefusal.noAmmo => l10n.combatNoAmmo,
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
