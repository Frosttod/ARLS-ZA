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

import 'fonts.dart';
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
    required this.state,
    this.weaponName,
    this.settling = false,
    required this.condition,
    required this.sprintLeft,
    required this.bloodLeft,
    this.bleeding = false,
    required this.onFire,
    this.onStrike,
    this.onReload,
    this.loaded = 0,
    this.magazine = 0,
    this.reloading = false,
    this.refusal,
    super.key,
  });

  /// What is being aimed at, in words (§5.5.1).
  final String targetName;

  final double distanceM;

  /// §5.1.4: 0–1, and shown as a whole percentage. Null with nothing in hand
  /// to fire — there is no chance to state, and stating one anyway would be a
  /// number about a shot nobody can take.
  final double? chance;

  /// §5.1.4: the largest component of the error. Null for the same reason.
  final ErrorSource? dominant;

  /// §6.1a, in the player's words: it has not seen you, it is looking for
  /// you, or it is coming.
  ///
  /// ⚠️ Not drawn any more. §12 already carries it twice — the `?` or `!` over
  /// the dot and the threat line on the HUD — and a third copy pushed the one
  /// thing the panel was missing off the row. Kept on the widget because the
  /// screen reader still reads it (§12) and because removing a field to save a
  /// line is how a state stops being modelled at all.
  final EnemyState state;

  /// §5.5.4: what is in the player's hands, by name. Null with empty hands.
  final String? weaponName;

  /// §5.5.1: how badly hurt it looks. Three words, because that is all anybody
  /// could honestly tell at two hundred metres.
  final EnemyCondition condition;

  /// §2.6: how much blood it has left against what kills it, 0–1.
  final double bloodLeft;

  /// §2.6: whether something opened is still costing it.
  final bool bleeding;

  /// §5.5.2: how much sprint it has left, 0–1. The tactical fact of a group
  /// fight — one that has burned its budget can be walked away from.
  final double sprintLeft;

  /// Null while there is nothing to fire — no weapon in hand, or no round for
  /// it. The reason is said in [refusal] rather than left to a dead button.
  final VoidCallback? onFire;

  /// §5.2, §5.4: hands, once something is inside twenty metres. Null while it
  /// is further off than a person can reach.
  final VoidCallback? onStrike;

  /// §5.5.4: puts a magazine in, and can be interrupted by anything closing
  /// inside five metres. Null while there is nothing to load or no room.
  final VoidCallback? onReload;

  /// §5.3: what is in the weapon against what it holds.
  final int loaded;
  final int magazine;

  /// True while a magazine is going in — the trigger is not available and the
  /// panel says why.
  final bool reloading;

  /// §5.5.1, §5.3: true while the sight picture is still being recovered, so
  /// the rising percentage beside it is explained rather than mysterious.
  final bool settling;

  final String? refusal;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);
    final odds = chance;
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
                      '$targetName · ${l10n.combatDistance(distanceM.round())}'
                      ' · ${conditionName(l10n, condition)}'
                      '${bleeding ? ' · ${l10n.enemyBleeding}' : ''}',
                      style: TextStyle(fontSize: 12, color: colours.text),
                    ),
                    if (weaponName != null)
                      Text(
                        '$weaponName'
                        '${magazine > 0 ? ' · ${l10n.combatRounds(loaded, magazine)}' : ''}',
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
                              value: bloodLeft.clamp(0.0, 1.0),
                              backgroundColor: colours.muted.withValues(
                                alpha: 0.25,
                              ),
                              color: bleeding ? colours.alert : colours.data,
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
                          settling ? l10n.combatAiming : l10n.combatOnTarget,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: settling ? colours.alert : colours.data,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // What is costing the shot, so a miss can be
                          // answered rather than resented.
                          dominant == null ? '' : errorName(l10n, dominant!),
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
                        style: TextStyle(fontSize: 11, color: colours.alert),
                      ),
                    ],
                  ],
                ),
              ),
              if (reloading)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    l10n.combatReloading,
                    style: TextStyle(fontSize: 11, color: colours.muted),
                  ),
                )
              else if (onReload != null) ...[
                OutlinedButton(
                  onPressed: onReload,
                  child: Text(l10n.combatReload),
                ),
                const SizedBox(width: 8),
              ],
              if (onStrike != null) ...[
                OutlinedButton(
                  onPressed: onStrike,
                  child: Text(l10n.combatStrike),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(onPressed: onFire, child: Text(l10n.combatFire)),
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

/// §5.1.4's word beside the percentage.
String errorName(L10n l10n, ErrorSource source) => switch (source) {
  ErrorSource.weapon => l10n.errorWeapon,
  ErrorSource.skill => l10n.errorSkill,
  ErrorSource.heart => l10n.errorHeart,
  ErrorSource.movement => l10n.errorMovement,
  ErrorSource.target => l10n.errorTarget,
  ErrorSource.condition => l10n.errorCondition,
};
