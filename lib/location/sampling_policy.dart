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

  /// Under their own roof and staying there — reading, building, sitting.
  settled,

  /// Asleep (§2.5.1). The longest state in the game and the stillest.
  asleep,

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
  SamplingPolicy({
    this.lowBatteryPercent = kLowBatteryPercent,
    this.settleFor = const Duration(seconds: 60),
  });

  final int lowBatteryPercent;

  /// How long a new rate has to be wanted before it is adopted.
  ///
  /// Changing the rate restarts the platform's location request, and a fresh
  /// request takes seconds to produce its first fix. Without this, a player
  /// waiting at a crossing flips walking-standing-walking and the stream is
  /// torn down each time: the fixes never settle, the accuracy never improves,
  /// and the HUD spends the walk saying the signal is weak. The battery saving
  /// of §3.3 is meant for someone who has genuinely stopped, not for someone
  /// pausing at a kerb.
  final Duration settleFor;

  bool _warned = false;

  PositionCadence? _pending;
  DateTime? _pendingSince;
  PositionCadence? _current;

  /// Resets the warning, so plugging in and unplugging again warns once more.
  void resetWarning() => _warned = false;

  SamplingDecision decide({
    required Activity activity,
    required int batteryPercent,
    required bool charging,
    DateTime? at,
  }) {
    final low = !charging && batteryPercent <= lowBatteryPercent;

    final warn = low && !_warned;
    if (warn) _warned = true;
    if (!low) _warned = false;

    final now = at ?? DateTime.now().toUtc();

    return SamplingDecision(
      cadence: _settled(
        _cadenceFor(_staying(activity, now), economy: low),
        now,
      ),
      economy: low,
      warnLowBattery: warn,
    );
  }

  /// §3.3: two minutes under a roof and the character is staying.
  ///
  /// ⚠️ Timed here rather than in the loop, because the clock this needs is
  /// the one this class already keeps. The first two minutes indoors are
  /// somebody who may be about to walk out again — a search finished, a bag
  /// dropped, straight back to the street — and noticing that within fifteen
  /// seconds is worth the battery. Past that they are asleep, reading or
  /// building, and half the rate is plenty.
  Activity _staying(Activity activity, DateTime now) {
    // Sleep is already the final answer: nothing is stiller and nothing lasts
    // longer, so there is no promotion left to make.
    if (activity == Activity.asleep) {
      _indoorsSince ??= now;
      return activity;
    }

    if (activity != Activity.sheltered && activity != Activity.settled) {
      _indoorsSince = null;
      return activity;
    }

    _indoorsSince ??= now;
    return now.difference(_indoorsSince!) >= kSettledAfter
        ? Activity.settled
        : Activity.sheltered;
  }

  DateTime? _indoorsSince;

  /// Holds a *slower* rate until it has been wanted for [settleFor]. Speeding
  /// up is immediate.
  ///
  /// The asymmetry is the whole point. Slowing down is the battery saving of
  /// §3.3, and it is worth waiting a minute to be sure the player has really
  /// stopped rather than paused at a kerb — each change restarts the platform's
  /// location request, and a fresh request takes seconds to produce a fix.
  /// Speeding up is responsiveness, and delaying it would cost exactly what the
  /// hold was meant to save: a session opens with the first fix reported as
  /// stationary, so a symmetric hold would start every walk at 0.05 Hz and take
  /// a minute to notice it was a walk.
  PositionCadence _settled(PositionCadence wanted, DateTime now) {
    _current ??= wanted;
    if (wanted == _current) {
      _pending = null;
      _pendingSince = null;
      return _current!;
    }

    // Two deliberate acts, exempt in both directions. A shelter occupation is
    // a commitment to standing still, not a pause at a kerb (§2.1a.4), and
    // combat is decided on distance — waiting a minute either to reach 1 Hz or
    // to leave it would be the same as not having the rate at all (§5.2).
    final deliberate =
        wanted == PositionCadence.sheltered ||
        wanted == PositionCadence.settled ||
        wanted == PositionCadence.asleep ||
        wanted == PositionCadence.off ||
        wanted == PositionCadence.combat ||
        _current == PositionCadence.combat;

    if (deliberate || !_isSlower(wanted, than: _current!)) {
      _current = wanted;
      _pending = null;
      _pendingSince = null;
      return wanted;
    }

    if (_pending != wanted) {
      _pending = wanted;
      _pendingSince = now;
      return _current!;
    }

    if (now.difference(_pendingSince!) >= settleFor) {
      _current = wanted;
      _pending = null;
      _pendingSince = null;
    }
    return _current!;
  }

  /// Off is the slowest of all; otherwise a longer interval is slower.
  static bool _isSlower(
    PositionCadence value, {
    required PositionCadence than,
  }) {
    if (value == PositionCadence.off) return than != PositionCadence.off;
    if (than == PositionCadence.off) return false;
    return value.interval > than.interval;
  }

  PositionCadence _cadenceFor(Activity activity, {required bool economy}) {
    final base = switch (activity) {
      Activity.combat => PositionCadence.combat,
      Activity.walking => PositionCadence.moving,
      Activity.standing => PositionCadence.resting,
      Activity.sheltered => PositionCadence.sheltered,
      Activity.settled => PositionCadence.settled,
      Activity.asleep => PositionCadence.asleep,
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
      // Already the cheapest thing a running game asks for, and making it
      // cheaper would be switching it off — see [PositionCadence.sheltered].
      PositionCadence.sheltered => PositionCadence.sheltered,
      PositionCadence.settled => PositionCadence.settled,
      PositionCadence.asleep => PositionCadence.asleep,
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
  bool asleep = false,
}) {
  if (inCombat) return Activity.combat;
  if (asleep) return Activity.asleep;
  if (sheltered) return Activity.sheltered;
  return speedKmh > 0.5 ? Activity.walking : Activity.standing;
}

/// §3.3: how long under a roof before somebody counts as staying.
const Duration kSettledAfter = Duration(minutes: 2);
