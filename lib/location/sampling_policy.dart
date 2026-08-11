/// How often to ask the chip where we are (design doc §3.3).
///
/// Continuous GPS costs 15–25% of a battery per hour. A session is meant to
/// last several hours, so the sampling rate is not a tuning detail — it decides
/// whether the game can be played at all on the way home.
///
/// The rule is that the rate follows what the character is doing, and the
/// battery can only ever slow it down, never speed it up:
///
/// | situation            | rate     |
/// | :------------------- | :------- |
/// | combat               | 1 Hz     |
/// | walking              | 0.2 Hz   |
/// | standing still       | 0.05 Hz  |
/// | shelter occupation   | off      |
///
/// Pure and Flutter-free: the battery level and the activity are handed in, and
/// the decision comes back. Nothing here reads a plugin.
library;

import 'position_source.dart';

/// The battery level below which the game says something (§3.3).
const int kLowBatteryPercent = 20;

/// What the character is doing, as far as sampling is concerned.
enum Activity {
  /// Distance decides everything. Pay for it (§5).
  combat,

  /// Moving under their own power.
  walking,

  /// Not moving, but outdoors and able to start at any moment.
  standing,

  /// A shelter occupation. The character is not going anywhere, and the radio
  /// is the single most expensive thing on the device (§2.1a.4).
  sheltered,
}

/// What the sampling policy decided, and what to tell the player about it.
class SamplingDecision {
  const SamplingDecision({
    required this.cadence,
    required this.economy,
    required this.warnLowBattery,
  });

  final PositionCadence cadence;

  /// Reduced map, no animations (§3.3). Distinct from the cadence because the
  /// renderer needs to know even when the sampling rate did not change.
  final bool economy;

  /// Whether to suggest heading back to the shelter. Only ever raised on the
  /// crossing, not on every fix — see [SamplingPolicy.decide].
  final bool warnLowBattery;
}

/// Chooses a cadence from the activity and the battery.
///
/// Holds one piece of state: whether the low-battery warning has already been
/// given. A warning repeated every second is noise the player learns to ignore,
/// which is the same as having no warning at all.
class SamplingPolicy {
  SamplingPolicy({this.lowBatteryPercent = kLowBatteryPercent});

  final int lowBatteryPercent;

  bool _warned = false;

  /// Resets the warning, so plugging in and unplugging again warns once more.
  void resetWarning() => _warned = false;

  SamplingDecision decide({
    required Activity activity,
    required int batteryPercent,
    required bool charging,
  }) {
    final low = !charging && batteryPercent <= lowBatteryPercent;

    final warn = low && !_warned;
    if (warn) _warned = true;
    if (!low) _warned = false;

    return SamplingDecision(
      cadence: _cadenceFor(activity, economy: low),
      economy: low,
      warnLowBattery: warn,
    );
  }

  PositionCadence _cadenceFor(Activity activity, {required bool economy}) {
    final base = switch (activity) {
      Activity.combat => PositionCadence.combat,
      Activity.walking => PositionCadence.moving,
      Activity.standing => PositionCadence.resting,
      Activity.sheltered => PositionCadence.off,
    };

    if (!economy) return base;

    // A flat battery ends the session; a slow fix only makes it coarser. But
    // combat is not negotiable — the whole encounter is decided on distance,
    // and a player who dies because the game was saving power has been cheated
    // (§5.2).
    return switch (base) {
      PositionCadence.combat => PositionCadence.combat,
      PositionCadence.moving => PositionCadence.resting,
      PositionCadence.resting => PositionCadence.resting,
      PositionCadence.off => PositionCadence.off,
    };
  }
}

/// Reads the activity off the things the loop already knows.
///
/// Kept beside the policy rather than inside the loop so the mapping is visible
/// in one place: this is where "is the character walking" is actually decided,
/// and it is a lower bar than the stationary test in `FixFilter` on purpose.
/// Sampling that drops to 0.05 Hz the moment someone pauses at a kerb would
/// miss them starting again.
Activity activityFrom({
  required bool inCombat,
  required bool sheltered,
  required double speedKmh,
}) {
  if (inCombat) return Activity.combat;
  if (sheltered) return Activity.sheltered;
  return speedKmh > 0.5 ? Activity.walking : Activity.standing;
}
