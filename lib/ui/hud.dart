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

import '../inventory/inventory.dart' show kPocketCapacityL;
import '../l10n/app_localizations.dart';
import '../sim/physiology.dart';
import '../sim/tick.dart';

/// Colours the HUD reads in, in both themes (§12).
///
/// Named for their job rather than their shade, because the shades swap: what
/// is nearly black behind the bars at night is nearly white at noon, and the
/// text goes the other way. Naming them ink and paper survived exactly as long
/// as there was one palette.
///
/// [alert] keeps its hue in both — a red that turns into a different colour in
/// daylight is not a warning, it is decoration.
class HudColors {
  const HudColors({
    required this.panel,
    required this.text,
    required this.data,
    required this.alert,
    required this.muted,
  });

  /// Night, and the design the project site was drawn in.
  static const HudColors dark = HudColors(
    panel: Color(0xFF14181A),
    text: Color(0xFFE4E5DF),
    data: Color(0xFF17565C),
    alert: Color(0xFFA82D17),
    muted: Color(0xFF4A524F),
  );

  /// Daylight. The data and muted tones are darkened rather than mirrored: a
  /// teal that reads well on near-black is invisible on near-white.
  static const HudColors light = HudColors(
    panel: Color(0xFFF2EFEA),
    text: Color(0xFF14181A),
    data: Color(0xFF0E4249),
    alert: Color(0xFF8E2412),
    muted: Color(0xFF6B726E),
  );

  /// The panel behind the bars, and the surface everything else sits on.
  final Color panel;

  /// Readings and labels.
  final Color text;

  /// The bars themselves.
  final Color data;

  /// Warnings, and blood past a shock class.
  final Color alert;

  /// Secondary labels and the unfilled part of a bar.
  final Color muted;

  static HudColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class Hud extends StatelessWidget {
  const Hud({
    required this.state,
    required this.status,
    required this.constants,
    this.warnings = const [],
    this.carryComfortKg,
    this.carryMaxKg,
    this.carriedKg = 0,
    this.carriedVolumeL = 0,
    this.capacityL = kPocketCapacityL,
    super.key,
  });

  final SimState state;
  final SimStatus status;
  final SimConstants constants;

  /// What the systems layer wants said in words: no signal, a flat battery,
  /// a suspended run (§3.2, §3.3, §3.4). Shown alongside the body statuses,
  /// because from the player's side they are the same kind of thing — a reason
  /// the game is not behaving as they expect.
  final List<String> warnings;

  /// §1.3's two thresholds. The comfortable one costs calories to exceed, the
  /// hard one cannot be exceeded at all.
  final double? carryComfortKg;
  final double? carryMaxKg;

  final double carriedKg;

  /// §18.1a's second limit. Without it a pocket holds a wardrobe.
  final double carriedVolumeL;
  final double capacityL;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);

    return Material(
      color: colours.panel.withValues(alpha: 0.88),
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
              _StatusRow(status: status, warnings: warnings),
              if (carryComfortKg != null) ...[
                const SizedBox(height: 6),
                _CarryReadout(
                  massLabel: l10n.hudCarry,
                  bulkLabel: l10n.hudBulk,
                  carriedKg: carriedKg,
                  // Blood loss costs carry capacity (§2.6): class II takes 10%.
                  comfortKg: carryComfortKg! * status.blood.carryPenalty,
                  maxKg: (carryMaxKg ?? carryComfortKg! * 1.5) *
                      status.blood.carryPenalty,
                  volumeL: carriedVolumeL,
                  capacityL: capacityL,
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
    final colours = HudColors.of(context);
    final blood = status.blood;
    final colour = switch (blood.shockClass) {
      ShockClass.none => colours.text,
      ShockClass.compensated => const Color(0xFFE8B33A),
      ShockClass.decompensated => const Color(0xFFE07B39),
      ShockClass.critical => colours.alert,
    };

    return Semantics(
      label: '$label ${(1 - blood.lossFraction) * 100 ~/ 1}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: colours.muted,
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
            style: TextStyle(
              fontSize: 10,
              color: colours.muted,
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
    final colours = HudColors.of(context);
    final clamped = fraction.clamp(0.0, 1.0);
    final colour = critical
        ? colours.alert
        : warning
        ? const Color(0xFFE8B33A)
        : colours.data;

    return Semantics(
      label: '$label ${(clamped * 100).round()}%',
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: colours.muted,
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 5,
                backgroundColor: colours.muted.withValues(alpha: 0.35),
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
              style: TextStyle(
                fontSize: 10,
                color: colours.text,
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
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);
    final ratio = maxBpm <= 0 ? 0.0 : bpm / maxBpm;
    final colour = switch (ratio) {
      < 0.60 => colours.text,
      < 0.85 => const Color(0xFFE8B33A),
      _ => colours.alert,
    };

    return Semantics(
      label: '${l10n.hudHeartRate} ${bpm.round()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.favorite, size: 12, color: colours.muted),
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
          Text('bpm', style: TextStyle(fontSize: 9, color: colours.muted)),
        ],
      ),
    );
  }
}

/// Active statuses as words rather than icons alone. An icon nobody has
/// learned yet is decoration; a word is readable on the first run and by a
/// screen reader (§12).
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, this.warnings = const []});

  final SimStatus status;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);
    final chips = <String>[
      ...warnings,
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
            decoration: BoxDecoration(border: Border.all(color: colours.alert)),
            child: Text(
              chip.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: colours.alert,
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
/// Both carry limits, side by side (§18.1a).
///
/// They are shown together because they fail differently and a player has to
/// see which one is about to stop them: mass is what a rucksack of metal runs
/// into, bulk is what a rucksack of plastic runs into, and neither figure
/// predicts the other.
///
/// Mass has two thresholds. Past the comfortable one the bar turns amber and
/// nothing else happens — §1.3 forbids slowing a real walking player, so the
/// price is metabolic. The hard limit is the end of the bar, and there the
/// game refuses to pick things up.
class _CarryReadout extends StatelessWidget {
  const _CarryReadout({
    required this.massLabel,
    required this.bulkLabel,
    required this.carriedKg,
    required this.comfortKg,
    required this.maxKg,
    required this.volumeL,
    required this.capacityL,
  });

  final String massLabel;
  final String bulkLabel;
  final double carriedKg;
  final double comfortKg;
  final double maxKg;
  final double volumeL;
  final double capacityL;

  @override
  Widget build(BuildContext context) {
    final overComfort = comfortKg > 0 && carriedKg > comfortKg;

    return Row(
      children: [
        Expanded(
          child: _LimitBar(
            label: massLabel,
            value: '${carriedKg.toStringAsFixed(1)} / '
                '${maxKg.toStringAsFixed(0)} kg',
            fraction: maxKg > 0 ? carriedKg / maxKg : 0,
            // Where the load stops being free. Drawn rather than described,
            // because the number moves with the pack and with blood loss.
            markAt: maxKg > 0 ? comfortKg / maxKg : null,
            warning: overComfort,
            semantics:
                '$massLabel ${carriedKg.toStringAsFixed(1)} of '
                '${maxKg.toStringAsFixed(0)} kilograms',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LimitBar(
            label: bulkLabel,
            value: '${volumeL.toStringAsFixed(0)} / '
                '${capacityL.toStringAsFixed(0)} l',
            fraction: capacityL > 0 ? volumeL / capacityL : 0,
            warning: capacityL > 0 && volumeL > capacityL * 0.9,
            semantics:
                '$bulkLabel ${volumeL.toStringAsFixed(0)} of '
                '${capacityL.toStringAsFixed(0)} litres',
          ),
        ),
      ],
    );
  }
}

class _LimitBar extends StatelessWidget {
  const _LimitBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.warning,
    required this.semantics,
    this.markAt,
  });

  final String label;
  final String value;
  final double fraction;

  /// Where to draw the comfortable-load tick, as a share of the bar. Null on a
  /// limit that has only one threshold.
  final double? markAt;

  final bool warning;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final clamped = fraction.clamp(0.0, 1.0);
    final full = fraction >= 0.999;
    final colour = full
        ? colours.alert
        : warning
        ? const Color(0xFFE8B33A)
        : colours.data;

    return Semantics(
      label: semantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: colours.muted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 10,
                  color: warning || full ? colour : colours.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: colours.muted.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: constraints.maxWidth * clamped,
                  decoration: BoxDecoration(
                    color: colour,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (markAt != null && markAt! < 1)
                  Positioned(
                    left: constraints.maxWidth * markAt!.clamp(0.0, 1.0) - 0.5,
                    child: Container(
                      height: 4,
                      width: 1,
                      color: colours.text.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
