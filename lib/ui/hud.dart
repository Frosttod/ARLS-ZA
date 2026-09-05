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

import 'fonts.dart';
import '../combat/awareness.dart';
import 'units.dart';
import '../inventory/inventory.dart' show kPocketCapacityL;
import '../l10n/app_localizations.dart';
import 'effects.dart';
import 'status_notes.dart';
import 'ticking.dart';
import '../sim/physiology.dart';
import '../sim/tick.dart';
import '../game/game_loop.dart' show GameSnapshot;
import '../location/location_access.dart';
import '../location/movement_integrity.dart';
import '../location/position_fix.dart' show PositionSignal;
import '../safety/player_safety.dart' show CombatBlock;

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
  ///
  /// ⚠️ **Three of these were unreadable and it took a field report to say so.**
  /// The teal, the red and the muted grey were lifted straight off the project
  /// site, where they sit on a page at reading distance in a room. Measured
  /// against the panel they were 2.15, 2.60 and 2.22 to one — every one of them
  /// below even the 3:1 that graphics get, on the surface a player reads at
  /// arm's length in the street. The light palette, drawn later and by eye,
  /// happened to land at 9.67, 7.59 and 4.30.
  ///
  /// Hue and saturation kept, lightness raised until each clears 5:1 — which
  /// leaves ~4.6 once the panel's own 0.88 alpha lets the map through. What
  /// changed is that the bars can be seen; what did not is which colour means
  /// what.
  static const HudColors dark = HudColors(
    panel: Color(0xFF14181A),
    text: Color(0xFFE4E5DF),
    data: Color(0xFF2895A0),
    alert: Color(0xFFE55B42),
    muted: Color(0xFF7E8A86),
  );

  /// Daylight. The data and muted tones are darkened rather than mirrored: a
  /// teal that reads well on near-black is invisible on near-white.
  /// Daylight. The panel, the map ground and the menus are one colour on
  /// purpose — see `kPaper`.
  static const HudColors light = HudColors(
    panel: Color(0xFFF2EFEA),
    text: Color(0xFF14181A),
    data: Color(0xFF0E4249),
    alert: Color(0xFF8E2412),
    // 4.30 to one against the panel, which is under AA by a hair. Darkened
    // until it clears — a secondary label is still a label.
    muted: Color(0xFF636A66),
  );

  /// §12, high contrast, night.
  ///
  /// ⚠️ **The HUD does not inherit the theme's contrast level, and this is why
  /// it needs its own pair.** Every colour above is a literal, chosen against
  /// a near-black panel — so a player who turns on high contrast would get a
  /// crisper *menu* and exactly the same unreadable bar over the map, which is
  /// the surface they actually read while walking.
  ///
  /// True black behind pure white, and the muted tone lifted until it is a
  /// colour rather than a suggestion: an empty bar has to be visible as an
  /// empty bar.
  static const HudColors contrastDark = HudColors(
    panel: Color(0xFF000000),
    text: Color(0xFFFFFFFF),
    data: Color(0xFF3FD0DC),
    alert: Color(0xFFFF6A4D),
    muted: Color(0xFFA8B0AC),
  );

  /// §12, high contrast, daylight. Pure white ground, near-black ink, and both
  /// accents darkened until they carry on white rather than glow on it.
  static const HudColors contrastLight = HudColors(
    panel: Color(0xFFFFFFFF),
    text: Color(0xFF000000),
    data: Color(0xFF06343A),
    alert: Color(0xFF7A1B0C),
    muted: Color(0xFF3D4442),
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

  /// The pair this screen should be drawn in.
  ///
  /// Reads `MediaQuery.highContrastOf`, which carries both the system's
  /// accessibility flag and the game's own switch — `main.dart` folds the
  /// setting into the same channel so that nothing downstream has to ask two
  /// questions to get one answer (§12).
  static HudColors of(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    if (!MediaQuery.highContrastOf(context)) return night ? dark : light;
    return night ? contrastDark : contrastLight;
  }
}

class Hud extends StatelessWidget {
  const Hud({
    required this.state,
    required this.status,
    required this.constants,
    this.warnings = const [],
    this.bleeding = BleedTier.none,
    this.threat,
    this.carryComfortKg,
    this.carryMaxKg,
    this.carriedKg = 0,
    this.carriedVolumeL = 0,
    this.capacityL = kPocketCapacityL,
    this.sky = const (dusk: null, dawn: null),
    this.noiseM = 0,
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

  /// §17.2: when the light goes and when it comes back, as clock times.
  ///
  /// ⚠️ Moments, never durations. A countdown drawn from a duration is a
  /// second out the instant it is read, and the widget would have to be handed
  /// a fresh one on every tick of its own clock — which is two clocks that
  /// disagree. Given the moment, it subtracts for itself and stays exact.
  final ({DateTime? dusk, DateTime? dawn}) sky;

  /// §5.6.1: jak daleko słychać teraz kroki gracza.
  ///
  /// ⚠️ **Bez tego skradanka jest zgadywanką.** Prędkość decyduje o tym, kto
  /// usłyszy — a gracz nie ma jak zobaczyć, po której stronie progu właśnie
  /// idzie. Metry, nie „cicho/głośno": promienie wykrycia też są w metrach, a
  /// dwie liczby w tych samych jednostkach da się porównać jednym spojrzeniem.
  final double noiseM;

  /// §2.6: what is still open. Its own chip rather than part of the blood
  /// readout, because it is the only status on the HUD with a clock on it —
  /// everything else gets worse over hours, this one over minutes.
  final BleedTier bleeding;

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
                  Expanded(
                    child: Column(
                      children: [
                        // ⚠️ Every bar carries its own figure as well as
                        // its percentage. A share tells a player how close to
                        // empty they are; only the number tells them whether
                        // the bottle in their pack closes the gap, and that is
                        // the decision they are actually making in a shop.
                        _ThinBar(
                          label: l10n.hudWater,
                          fraction: status.thirst.fraction,
                          amount: '${_grouped(state.waterMl)} ml',
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
                          amount: '${_grouped(state.caloriesKcal)} kcal',
                          incoming:
                              state.pendingKcal / constants.caloriesDailyKcal,
                          warning: status.hunger.precisionPenalty < 1,
                          critical: status.hunger.actionTimeMultiplier > 1,
                        ),
                        const SizedBox(height: 4),

                        // §2.5: rest, on the same scale as the other two —
                        // full is a night owed nothing, and the bar empties as
                        // the debt grows against the eight hours §2.5.3 wants.
                        // Beside them because it fails the same way: slowly,
                        // predictably, and entirely by choice.
                        _ThinBar(
                          label: l10n.hudSleep,
                          fraction:
                              1 -
                              state.sleepDebt.inSeconds /
                                  kDailySleepNeed.inSeconds,
                          amount: _sleepOwed(state.sleepDebt),
                          incoming: _sleepIncoming(state),
                          warning: status.sleep.extraMoa > 0,
                          critical: status.sleep.microsleeps,
                        ),
                        const SizedBox(height: 4),

                        // §2.6: and blood, on the same scale as the rest of
                        // them. It used to be a big number off to one side,
                        // which said "this one is different" — and it is not.
                        // It empties like the others and is read like the
                        // others; the only thing that sets it apart is how
                        // fast it can go, and a bar shows that better than a
                        // figure standing on its own.
                        _ThinBar(
                          label: l10n.hudBlood,
                          fraction: 1 - status.blood.lossFraction,
                          amount: '${_grouped(status.blood.volumeMl)} ml',
                          incoming: _bloodIncoming(state, constants, bleeding),
                          warning: status.blood.shockClass != ShockClass.none,
                          critical: status.blood.isFatal,
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
              _Noise(metres: noiseM, colours: colours, l10n: l10n),
              const SizedBox(height: 6),
              _Sky(sky: sky, colours: colours),
              const SizedBox(height: 6),
              _StatusRow(
                status: status,
                warnings: warnings,
                bleeding: bleeding,
              ),
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

/// §17.2, §12: the time, and how long the sky has left.
///
/// ⚠️ **The night rules arrive all at once and a map cannot show them
/// coming.** §10.2.2 halves the reconnaissance radius, §17.4 gives every
/// Walker a fifth more reach and §5.6.1 carries a shot a third further — none
/// of it is visible until it has already happened. An hour and a half of
/// warning is the difference between walking home and being caught out.
///
/// The clock is local and the run is real time (§16.4), so this is the
/// player's own watch — which is the point. It is their evening being spent.
/// §5.6.1, §12: ile słychać kroki, w metrach.
class _Noise extends StatelessWidget {
  const _Noise({
    required this.metres,
    required this.colours,
    required this.l10n,
  });

  final double metres;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        l10n.hudNoise.toUpperCase(),
        style: TextStyle(fontSize: 9, letterSpacing: 1.1, color: colours.muted),
      ),
      const SizedBox(width: 8),
      Text(
        metres <= 0 ? l10n.hudNoiseQuiet : '${metres.round()} m',
        style: TextStyle(
          fontSize: 12,
          fontFamily: kDataFont,
          fontFeatures: const [FontFeature.tabularFigures()],
          // Cisza jest osiągnięciem, nie stanem domyślnym: kolor danych, kiedy
          // nic nie słychać, i ostrzeżenia, kiedy słychać z czterdziestu.
          color: metres <= 0
              ? colours.data
              : metres >= 40
              ? colours.alert
              : colours.text,
        ),
      ),
    ],
  );
}

class _Sky extends StatefulWidget {
  const _Sky({required this.sky, required this.colours});

  final ({DateTime? dusk, DateTime? dawn}) sky;
  final HudColors colours;

  @override
  State<_Sky> createState() => _SkyState();
}

class _SkyState extends State<_Sky> with WidgetsBindingObserver, Ticking {
  /// ⚠️ **The device clock, not `state.lastUpdate`.** The simulation's stamp
  /// is the last *trusted* tick: §2.1.1 clamps an absurd gap and holds the
  /// stamp outright when the system clock goes backwards, and §3.3 throttles
  /// the cadence to a minute in economy mode. All three are right for
  /// physiology and all three make a wall clock wrong — a panel reading it
  /// drifted behind the phone's own clock and never caught up.
  ///
  /// So the time of day is read straight off the device, on its own tick.
  @override
  bool get ticking => true;

  /// A minute is the resolution on screen, so twenty seconds keeps the clock
  /// close enough to the phone without waking the app for a digit that moves
  /// once in sixty.
  ///
  /// ⚠️ **A second, but only inside the last half hour.** §17.2's rules all
  /// arrive at one moment, and the half hour before it is the window where a
  /// player is deciding whether to start the walk home — that is worth a
  /// second hand. The other twenty-three and a half hours are not, and a
  /// panel that ticked every second all day would be §3.3's own example of
  /// what not to do.
  @override
  Duration get tickEvery =>
      _soon() ? const Duration(seconds: 1) : const Duration(seconds: 20);

  /// §12: when the sky is close enough that seconds matter.
  static const Duration kCountdownFrom = Duration(minutes: 30);

  bool _soon() {
    final left = _leftOf(_next()?.at);
    return left != null && left <= kCountdownFrom;
  }

  /// Whichever of the two comes first, and which one it is.
  ///
  /// ⚠️ **Only moments still ahead.** Reported from a walk: the countdown
  /// reached 00:00 and stayed there. A moment that has passed clamped to zero,
  /// zero is inside the half-hour window, and so the panel went on offering a
  /// countdown to something that had already happened — until the loop next
  /// recomputed the pair, which on a throttled cadence (§3.3) is not soon.
  ///
  /// Dropping a passed moment here makes the panel right whatever the snapshot
  /// says: the dusk countdown disappears the second dusk arrives, and the dawn
  /// one appears on its own half hour later.
  ({DateTime at, bool dusk})? _next() {
    final dusk = _leftOf(widget.sky.dusk) == null ? null : widget.sky.dusk;
    final dawn = _leftOf(widget.sky.dawn) == null ? null : widget.sky.dawn;

    if (dusk == null && dawn == null) return null;
    if (dawn == null) return (at: dusk!, dusk: true);
    if (dusk == null) return (at: dawn, dusk: false);

    return dusk.isBefore(dawn)
        ? (at: dusk, dusk: true)
        : (at: dawn, dusk: false);
  }

  /// How long until [at], or null when it is null or already behind us.
  Duration? _leftOf(DateTime? at) {
    if (at == null) return null;

    final left = at.difference(DateTime.now().toUtc());
    return left <= Duration.zero ? null : left;
  }

  /// A clock time, in the player's own local time.
  String _clock(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colours = widget.colours;
    final l10n = L10n.of(context);
    final now = DateTime.now();

    final next = _next();
    final left = _leftOf(next?.at);
    final soon = left != null && left <= kCountdownFrom;

    return Row(
      children: [
        Icon(
          next == null || next.dusk
              ? Icons.wb_sunny_outlined
              : Icons.nightlight_outlined,
          size: 13,
          color: colours.muted,
        ),
        const SizedBox(width: 6),
        _Figure(
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}',
          colour: colours.text,
        ),

        const Spacer(),

        // ⚠️ Both times, always, and the countdown beside the one it counts
        // to. A player at four in the afternoon wants tonight's dusk *and*
        // tomorrow's dawn — "the next change" answers half the question and
        // leaves the other half to be guessed at. A timer floating at the end
        // of the row would leave a third half.
        if (widget.sky.dawn case final dawn?)
          _Moment(
            label: l10n.hudSunrise,
            clock: _clock(dawn),
            left: next != null && !next.dusk && soon ? left : null,
            colours: colours,
          ),
        if (widget.sky.dusk case final dusk?) ...[
          const SizedBox(width: 12),
          _Moment(
            label: l10n.hudSunset,
            clock: _clock(dusk),
            left: next != null && next.dusk && soon ? left : null,
            colours: colours,
          ),
        ],
      ],
    );
  }
}

/// §17.2, §12: one of the two moments an evening is planned against.
///
/// The clock time always; the seconds only while [left] is given, which is the
/// half hour before it (§12) — the window where a player is deciding whether
/// to start the walk home.
class _Moment extends StatelessWidget {
  const _Moment({
    required this.label,
    required this.clock,
    required this.left,
    required this.colours,
  });

  final String label;
  final String clock;
  final Duration? left;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final soon = left != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: soon ? colours.alert : colours.muted,
          ),
        ),
        const SizedBox(width: 4),
        _Figure(clock, colour: soon ? colours.alert : colours.data),
        if (soon) ...[
          const SizedBox(width: 6),
          _Figure(span(left!, seconds: true), colour: colours.alert),
        ],
      ],
    );
  }
}

/// A number on the panel: tabular, so a countdown does not shuffle its own
/// digits sideways once a second.
class _Figure extends StatelessWidget {
  const _Figure(this.text, {required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      color: colour,
      fontFamily: kDataFont,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

/// §2.5: an hour of sleep ahead, as a share of the night §2.5.3 wants.
///
/// ⚠️ An hour rather than a queue. Water and food have something actually in
/// the stomach to point at (§2.2, §2.3); rest and blood have only a rate, so
/// the tick shows where one hour at the current rate lands. Same mark, same
/// meaning — something is coming — and the same hour for both, so the two can
/// be read against each other.
///
/// Nothing while awake. The debt grows every waking hour and a mark that is
/// always there says nothing at all; the point of it is that *right now*
/// something is going the other way.
double _sleepIncoming(SimState state) {
  if (state.zone != MetabolicZone.sleep) return 0;
  if (state.sleepDebt <= Duration.zero) return 0;

  final ahead = state.sleepDebt < const Duration(hours: 1)
      ? state.sleepDebt
      : const Duration(hours: 1);
  return ahead.inSeconds / kDailySleepNeed.inSeconds;
}

/// §2.6: an hour of blood, either way.
///
/// Negative while something is open, and at the rate the wound is *actually*
/// losing it — §2.6 multiplies by the pulse, so the same cut costs twice as
/// much running as standing, and a bar that ignored that would be reassuring
/// at exactly the wrong moment.
///
/// Positive while it is being rebuilt, at what the body can pay for: blood is
/// made out of what was eaten and drunk (§2.2, §2.3), so a starving character
/// shows no mark at all, which is the honest answer.
double _bloodIncoming(SimState state, SimConstants constants, BleedTier tier) {
  if (constants.bloodMaxMl <= 0) return 0;

  if (tier != BleedTier.none) {
    return -bleedMlPerMinute(
          tier: tier,
          currentHr: state.heartRateBpm,
          restingHr: constants.restingHeartRate,
        ) *
        60 /
        constants.bloodMaxMl;
  }

  if (state.bloodMl >= constants.bloodMaxMl) return 0;

  final room = constants.bloodMaxMl - state.bloodMl;
  final hour = kBloodRegenMlPerHour * nourishment(state, constants);
  return (hour < room ? hour : room) / constants.bloodMaxMl;
}

class _ThinBar extends StatelessWidget {
  const _ThinBar({
    required this.label,
    required this.fraction,
    required this.amount,
    required this.warning,
    required this.critical,
    this.incoming = 0,
  });

  final String label;
  final double fraction;

  /// The figure itself, in the unit the thing is measured in: millilitres,
  /// kilocalories, hours. A share says how close to empty; only the number
  /// says whether what is in the pack closes the gap.
  final String amount;

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
          ? '$label $amount, ${(clamped * 100).round()}%, '
                '${incoming > 0 ? "+" : "-"}${(incoming.abs() * 100).round()}%'
          : '$label $amount, ${(clamped * 100).round()}%',
      child: Row(
        children: [
          // ⚠️ Condensed, and never wrapped.
          //
          // KALORIE is a letter longer than the three labels beside it and
          // CALORIES is two, and Plex is a wider face than the one this box
          // was measured against — so the longest label broke onto a second
          // line and shoved the bar out of its own row. The width axis of the
          // variable file is exactly what this is for: the same face made
          // narrower, rather than a smaller size that would not match the
          // labels above and below it.
          //
          // The FittedBox is the guard behind that, not the plan. It catches
          // a translation longer than either of these and a system text scale
          // turned up for §12 — cases where the right answer is a slightly
          // smaller label rather than a broken row.
          SizedBox(
            width: 56,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: colours.muted,
                  fontVariations: const [FontVariation('wdth', 85)],
                ),
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
            width: 60,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                color: colours.muted,
                fontFamily: kDataFont,
                fontFeatures: const [FontFeature.tabularFigures()],
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
                fontFamily: kDataFont,
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
              fontFamily: kDataFont,
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
  const _StatusRow({
    required this.status,
    this.warnings = const [],
    this.bleeding = BleedTier.none,
  });

  final SimStatus status;
  final List<String> warnings;
  final BleedTier bleeding;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);
    final l10n = L10n.of(context);

    // §12: a word for what is wrong, and — on a tap — what it is costing,
    // what fixes it, and where that is found. A status a player cannot ask
    // about is a status they learn to ignore.
    final chips = <({String label, StatusNote? note})>[
      for (final warning in warnings) (label: warning, note: null),
      for (final note in statusNotes(l10n, status, bleeding: bleeding))
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
            value: outOfKg(carriedKg, maxKg),
            fraction: maxKg > 0 ? carriedKg / maxKg : 0,
            // Where the load stops being free. Drawn rather than described,
            // because the number moves with the pack and with blood loss.
            markAt: maxKg > 0 ? comfortKg / maxKg : null,
            warning: overComfort,
            semantics:
                '$massLabel ${amount(carriedKg)} of '
                '${amount(maxKg)} kilograms',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LimitBar(
            label: bulkLabel,
            value: outOfL(volumeL, capacityL),
            fraction: capacityL > 0 ? volumeL / capacityL : 0,
            warning: capacityL > 0 && volumeL > capacityL * 0.9,
            semantics:
                '$bulkLabel ${amount(volumeL)} of '
                '${amount(capacityL)} litres',
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
          // ⚠️ Both halves bend, because on a 320 px phone they do not fit.
          //
          // Found by the test written for the labels above rather than on a
          // phone, and it was there before the face changed — OBJĘTOŚĆ beside
          // a figure like "18,4 / 27,0 kg" is simply wider than a small screen
          // in Polish. The label narrows first, since a word can be read
          // condensed; the figure only shrinks, since §18.1a is the number the
          // player is deciding on and it must stay a number.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: colours.muted,
                      fontVariations: const [FontVariation('wdth', 85)],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10,
                      color: warning || full ? colour : colours.text,
                      fontFamily: kDataFont,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
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
    required this.nearby,
    required this.nearestM,
    required this.anySprinting,
  });

  /// Ilu ich w ogóle jest w zasięgu ostrzeżenia, świadomych czy nie.
  final int nearby;

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
    //
    // ⚠️ Trzy progi zamiast dwóch, i liczone od stu siedemdziesięciu pięciu, a
    // nie od stu. Zgłoszone z terenu: pasek zapalał się dopiero wtedy, gdy coś
    // już szło — czyli w chwili, w której zostawał sam bieg.
    final colour = switch (ThreatBand.of(reading.nearestM)) {
      ThreatBand.none || ThreatBand.watch => colours.data,
      ThreatBand.close => const Color(0xFFE8B33A),
      ThreatBand.onYou => colours.alert,
    };

    return Row(
      children: [
        Icon(Icons.warning_amber_outlined, size: 14, color: colour),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            effects([
              // Zero ściganych to inna wiadomość niż trzech biegnących: „są,
              // ale jeszcze nie wiedzą" jest zaproszeniem do obejścia.
              if (reading.count == 0)
                l10n.hudThreatQuiet(reading.nearby)
              else
                l10n.hudThreat(reading.count, metres),
              if (reading.anySprinting) l10n.hudThreatSprint,
            ]),
            style: TextStyle(
              fontSize: 11,
              color: colour,
              fontFamily: kDataFont,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// A figure with its thousands set apart, because 2800 and 280 are one glance
/// apart otherwise. A thin space, which does not wrap and is not a comma
/// somebody could read as a decimal point.
String _grouped(double value) {
  final digits = value.round().abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('\u202f');
    out.write(digits[i]);
  }
  return out.toString();
}

/// §2.5: rest still in the tank, against the eight hours §2.5.3 asks for.
/// §2.5: what the sleep bar's figure says.
///
/// ⚠️ The debt, not the hours left, and this is the whole of a bug reported
/// three times as "sleep does not regenerate". The bar is a fraction of one
/// night, so any debt past eight hours pins it at empty; the figure beside it
/// said "0.0 h", which reads as *nothing owed*. A character forty hours down
/// could sleep all night and every pixel on the screen would stay where it
/// was.
///
/// So the number is what is owed, and it moves the moment sleep starts.
/// ⚠️ A clock, not a decimal. "11.8 h" is a figure nobody can act on —
/// eleven hours and how many minutes? — and it sat on the screen for weeks.
String _sleepOwed(Duration debt) => owed(debt);

/// §12: everything the strip under the bars has to say right now.
///
/// ⚠️ A free function rather than a method, because none of it is about the
/// screen: every row is a rule from somewhere else — §3.2's signal, §3.3's
/// battery, §1.2's speed block, Android's own permission state — and reading
/// them is the kind of thing that quietly grows a God class a line at a time.
List<String> hudWarnings(
  L10n l10n,
  GameSnapshot snapshot, {
  LocationAccess? location,
}) => [
  ?switch (snapshot.integrityReason) {
    IntegrityReason.mockProvider => l10n.integritySuspendedMock,
    IntegrityReason.vehicleSpeed
        when snapshot.integrity == IntegrityState.suspended =>
      l10n.integritySuspendedVehicle,
    _ => null,
  },
  // ⚠️ Nothing about the signal while the character is under a roof.
  //
  // §2.1a.4 switches the receiver off in a shelter on purpose — the
  // character is not moving, so the position is not needed and the battery
  // is better spent elsewhere. The watchdog then reports no fixes, which is
  // true and useless: the game was warning the player about a decision the
  // game had just made, on the one screen where nothing is wrong.
  ?switch (snapshot.state.zone.isSheltered
      ? PositionSignal.good
      : snapshot.signal) {
    PositionSignal.lost || PositionSignal.unavailable => l10n.hudNoSignal,
    PositionSignal.degraded => l10n.hudWeakSignal,
    // Not a warning. The receiver is doing what a receiver does, and saying
    // so is what stops the player reading a cold start as a fault.
    PositionSignal.acquiring => l10n.hudAcquiring,
    PositionSignal.good => null,
  },
  if (snapshot.economy) l10n.hudLowBattery,
  if (location == LocationAccess.foregroundOnly) l10n.permLocationForeground,
  if (snapshot.combatBlocked == CombatBlock.movingTooFast)
    l10n.safetyNoCombatMoving,
];
