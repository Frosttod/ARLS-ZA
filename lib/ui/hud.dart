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
import 'status_notes.dart';
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
    this.threat,
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

  /// §5.5.2: how many are in the fight and how close the nearest is. Null when
  /// nothing has noticed the player, which is most of the time.
  final ThreatReading? threat;

  // ⚠️ No speedometer here, and there was one for a day.
  //
  // It read well and it was wrong for this game: a survivor with a phone and
  // no equipment does not know their own pace to a tenth of a kilometre an
  // hour. §0 says the body is the controller, and a body does not come with an
  // instrument panel. What speed does to the character is already visible —
  // through the heart rate, which is exactly how a person actually judges how
  // hard they are working.

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
                          // §2.3: what has been drunk and is still on its way.
                          incoming:
                              state.pendingWaterMl / constants.waterDailyMl,
                          warning: status.thirst.accuracyPenalty < 1,
                          critical: status.thirst.critical,
                        ),
                        const SizedBox(height: 4),
                        _ThinBar(
                          label: l10n.hudCalories,
                          fraction: status.hunger.fraction,
                          incoming:
                              state.pendingKcal / constants.caloriesDailyKcal,
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
              if (threat != null) ...[
                const SizedBox(height: 6),
                _Threat(reading: threat!, colours: colours),
              ],
              if (carryComfortKg != null) ...[
                const SizedBox(height: 6),
                _CarryReadout(
                  massLabel: l10n.hudCarry,
                  bulkLabel: l10n.hudBulk,
                  carriedKg: carriedKg,
                  // Blood loss costs carry capacity (§2.6): class II takes 10%.
                  comfortKg: carryComfortKg! * status.blood.carryPenalty,
                  maxKg:
                      (carryMaxKg ?? carryComfortKg! * 1.5) *
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
    this.incoming = 0,
  });

  final String label;
  final double fraction;

  /// Eaten or drunk and still being absorbed (§2.2, §2.3), as a share of the
  /// daily requirement.
  ///
  /// Drawn as a tick ahead of the bar rather than as more bar: the difference
  /// between what a player *has* and what is *coming* is the whole reason
  /// absorption takes time, and a fuller bar would hide it.
  final double incoming;

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

    final arriving = (clamped + incoming).clamp(0.0, 1.0);

    return Semantics(
      label: incoming.abs() > 0.001
          ? '$label ${(clamped * 100).round()}%, '
                '${incoming > 0 ? "+" : "-"}${(incoming.abs() * 100).round()}%'
          : '$label ${(clamped * 100).round()}%',
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
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    LinearProgressIndicator(
                      value: clamped,
                      minHeight: 5,
                      backgroundColor: colours.muted.withValues(alpha: 0.35),
                      valueColor: AlwaysStoppedAnimation(colour),
                    ),
                    if (incoming.abs() > 0.001)
                      Positioned(
                        left: (constraints.maxWidth * arriving - 1).clamp(
                          0.0,
                          constraints.maxWidth - 2,
                        ),
                        child: Container(
                          height: 5,
                          width: 2,
                          color: colours.text,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Which way the tick is going, in one character. §12: the mark alone
          // says there is something coming, the sign says what kind.
          SizedBox(
            width: 12,
            child: incoming.abs() > 0.001
                ? Icon(
                    incoming > 0 ? Icons.add : Icons.remove,
                    size: 11,
                    color: incoming > 0 ? colours.data : colours.alert,
                  )
                : const SizedBox.shrink(),
          ),
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

    // §12: a word for what is wrong, and — on a tap — what it is costing,
    // what fixes it, and where that is found. A status a player cannot ask
    // about is a status they learn to ignore.
    final chips = <({String label, StatusNote? note})>[
      for (final warning in warnings) (label: warning, note: null),
      for (final note in statusNotes(l10n, status))
        (label: note.name, note: note),
    ];

    if (chips.isEmpty) return const SizedBox(height: 4);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final chip in chips)
          GestureDetector(
            onTap: chip.note == null
                ? null
                : () => _explain(context, chip.note!, colours),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: colours.alert),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                // Upper case, as §3.6's HUD has always shown them: a status
                // is a stamp rather than a sentence.
                chip.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: colours.alert,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// What this status is: how bad, what it costs, what fixes it, and where
  /// that is found — always those four, always in that order.
  void _explain(BuildContext context, StatusNote note, HudColors colours) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final l10n = L10n.of(context);

        // Scrolls: four paragraphs at the largest accessible text size do not
        // fit a short phone, and §12 would rather they scrolled than shrank.
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.level == null
                        ? note.name
                        : '${note.name} — ${note.level}',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.bold,
                      color: colours.alert,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    heading: l10n.statusEffect,
                    body: note.effect,
                    colours: colours,
                  ),
                  _Section(
                    heading: l10n.statusFix,
                    body: note.fix,
                    colours: colours,
                  ),
                  _Section(
                    heading: l10n.statusWhere,
                    body: note.where,
                    colours: colours,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonOk),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One labelled paragraph of a status sheet.
class _Section extends StatelessWidget {
  const _Section({
    required this.heading,
    required this.body,
    required this.colours,
  });

  final String heading;
  final String body;
  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.5,
            color: colours.muted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: TextStyle(fontSize: 13, height: 1.4, color: colours.text),
        ),
      ],
    ),
  );
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
            value:
                '${carriedKg.toStringAsFixed(1)} / '
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
            value:
                '${volumeL.toStringAsFixed(0)} / '
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

/// §5.5.2: what the player has to know about a fight before looking at a map.
class ThreatReading {
  const ThreatReading({
    required this.count,
    required this.nearestM,
    required this.anySprinting,
  });

  /// How many are actually engaged — not how many exist in the district.
  final int count;

  final double nearestM;

  /// §5.5.2 calls this the key tactical fact: whether any of them still has
  /// sprint left. One that has burned its budget can be walked away from; one
  /// that has not cannot.
  final bool anySprinting;
}

class _Threat extends StatelessWidget {
  const _Threat({required this.reading, required this.colours});

  final ThreatReading reading;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final metres = reading.nearestM.round();

    // §5.5.2's colour code — and never colour alone (§12): the number of
    // metres is right there beside it.
    final colour = metres > 100
        ? colours.data
        : metres > 30
        ? const Color(0xFFE8B33A)
        : colours.alert;

    return Row(
      children: [
        Icon(Icons.warning_amber_outlined, size: 14, color: colour),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.hudThreat(reading.count, metres) +
                (reading.anySprinting ? ' · ${l10n.hudThreatSprint}' : ''),
            style: TextStyle(
              fontSize: 11,
              color: colour,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
