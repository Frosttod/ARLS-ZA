/// The always-visible status bar (design doc §3.6).
///
/// Minimal on purpose. The player is walking down a street looking at a phone,
/// often in the dark, and §3.5 would rather they looked up. So: blood, the two
/// consumables, the active statuses, and nothing that needs reading twice.
///
/// Colour carries the same information as the number, but colour alone never
/// carries it — §12 asks for a high-contrast mode and screen-reader support,
/// and a bar that only turns red is unusable to a colour-blind player.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../sim/physiology.dart';
import '../sim/tick.dart';

/// Colours shared by the HUD, derived from the design of the project site.
abstract final class HudColors {
  static const ink = Color(0xFF14181A);
  static const paper = Color(0xFFE4E5DF);
  static const data = Color(0xFF17565C);
  static const alert = Color(0xFFA82D17);
  static const muted = Color(0xFF4A524F);
}

class Hud extends StatelessWidget {
  const Hud({
    required this.state,
    required this.status,
    required this.constants,
    this.signalWarning,
    this.carryComfortKg,
    this.carriedKg = 0,
    super.key,
  });

  final SimState state;
  final SimStatus status;
  final SimConstants constants;

  /// Set when the position layer has something to say (§3.2).
  final String? signalWarning;

  final double? carryComfortKg;
  final double carriedKg;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Material(
      color: HudColors.ink.withValues(alpha: 0.88),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _BloodReadout(status: status, label: l10n.hudBlood),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _ThinBar(
                          label: l10n.hudWater,
                          fraction: status.thirst.fraction,
                          warning: status.thirst.accuracyPenalty < 1,
                          critical: status.thirst.critical,
                        ),
                        const SizedBox(height: 4),
                        _ThinBar(
                          label: l10n.hudCalories,
                          fraction: status.hunger.fraction,
                          warning: status.hunger.precisionPenalty < 1,
                          critical: status.hunger.actionTimeMultiplier > 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _HeartRate(
                    bpm: state.heartRateBpm,
                    maxBpm: constants.maxHeartRate,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _StatusRow(status: status, signalWarning: signalWarning),
              if (carryComfortKg != null) ...[
                const SizedBox(height: 4),
                _CarryReadout(
                  label: l10n.hudCarry,
                  carriedKg: carriedKg,
                  comfortKg: carryComfortKg! * status.blood.carryPenalty,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Blood is the one figure shown as an absolute number as well as a share.
/// Millilitres are what every wound in §2.6 is measured in, and a player who
/// learns to read them can judge whether a fight is survivable.
class _BloodReadout extends StatelessWidget {
  const _BloodReadout({required this.status, required this.label});

  final SimStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final blood = status.blood;
    final colour = switch (blood.shockClass) {
      ShockClass.none => HudColors.paper,
      ShockClass.compensated => const Color(0xFFE8B33A),
      ShockClass.decompensated => const Color(0xFFE07B39),
      ShockClass.critical => HudColors.alert,
    };

    return Semantics(
      label: '$label ${(1 - blood.lossFraction) * 100 ~/ 1}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: HudColors.muted,
            ),
          ),
          Text(
            '${((1 - blood.lossFraction) * 100).round()}%',
            style: TextStyle(
              fontSize: 20,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: colour,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            '${blood.volumeMl.round()} ml',
            style: const TextStyle(
              fontSize: 10,
              color: HudColors.muted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinBar extends StatelessWidget {
  const _ThinBar({
    required this.label,
    required this.fraction,
    required this.warning,
    required this.critical,
  });

  final String label;
  final double fraction;
  final bool warning;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);
    final colour = critical
        ? HudColors.alert
        : warning
        ? const Color(0xFFE8B33A)
        : HudColors.data;

    return Semantics(
      label: '$label ${(clamped * 100).round()}%',
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: HudColors.muted,
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 5,
                backgroundColor: HudColors.muted.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation(colour),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text(
              '${(clamped * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                color: HudColors.paper,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Heart rate doubles as the stamina gauge the game does not have (§2.4), so
/// it is worth its own corner rather than a line in a list.
class _HeartRate extends StatelessWidget {
  const _HeartRate({required this.bpm, required this.maxBpm});

  final double bpm;
  final double maxBpm;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final ratio = maxBpm <= 0 ? 0.0 : bpm / maxBpm;
    final colour = switch (ratio) {
      < 0.60 => HudColors.paper,
      < 0.85 => const Color(0xFFE8B33A),
      _ => HudColors.alert,
    };

    return Semantics(
      label: '${l10n.hudHeartRate} ${bpm.round()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Icon(Icons.favorite, size: 12, color: HudColors.muted),
          Text(
            '${bpm.round()}',
            style: TextStyle(
              fontSize: 18,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: colour,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            'bpm',
            style: TextStyle(fontSize: 9, color: HudColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Active statuses as words rather than icons alone. An icon nobody has
/// learned yet is decoration; a word is readable on the first run and by a
/// screen reader (§12).
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, this.signalWarning});

  final SimStatus status;
  final String? signalWarning;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final chips = <String>[
      ?signalWarning,
      if (status.blood.shockClass != ShockClass.none) l10n.statusShock,
      if (status.thirst.accuracyPenalty < 1) l10n.statusDehydrated,
      if (status.hunger.actionTimeMultiplier > 1) l10n.statusStarving,
      if (status.sleep.extraMoa > 0) l10n.statusSleepDeprived,
    ];

    if (chips.isEmpty) return const SizedBox(height: 4);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final chip in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: HudColors.alert),
            ),
            child: Text(
              chip.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: HudColors.alert,
              ),
            ),
          ),
      ],
    );
  }
}

/// Carry load against the comfortable limit (§1.3, §18.1a).
///
/// Over the limit is not blocked — the game cannot slow a real person down —
/// so the readout says "you are paying more for this", not "you cannot".
class _CarryReadout extends StatelessWidget {
  const _CarryReadout({
    required this.label,
    required this.carriedKg,
    required this.comfortKg,
  });

  final String label;
  final double carriedKg;
  final double comfortKg;

  @override
  Widget build(BuildContext context) {
    final over = comfortKg > 0 && carriedKg > comfortKg;

    return Semantics(
      label:
          '$label ${carriedKg.toStringAsFixed(1)} '
          'of ${comfortKg.toStringAsFixed(1)} kilograms',
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              color: HudColors.muted,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${carriedKg.toStringAsFixed(1)} / ${comfortKg.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 10,
              color: over ? const Color(0xFFE8B33A) : HudColors.paper,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
