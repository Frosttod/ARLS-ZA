/// Rules that protect the player rather than the simulation (§3.5).
///
/// The lessons here are Pokémon GO's, paid for by other people. The game sends
/// someone into a city with a phone in their hand, often after dark. Three
/// things follow, and none of them is optional:
///
/// * **No combat above walking pace.** Not a penalty — a refusal. Somebody
///   fighting a zombie at 20 km/h is on a bicycle, in a car, or running across
///   a road without looking.
/// * **The safety briefing is read once, before the first step**, and it is
///   acknowledged rather than dismissed.
/// * **After sunset the game says something about being seen.**
///
/// Pure and Flutter-free; the persistence of the acknowledgement is the
/// caller's business.
library;

/// §3.5. Above this the game will not let a fight start or continue.
///
/// Fifteen km/h is a fast cyclist and roughly twice a brisk walk, so it cannot
/// be reached on foot by accident. It is checked against the filtered speed of
/// §3.2, not the raw one, so a bad fix cannot cancel a fight.
const double kCombatSpeedLimitKmh = 15.0;

/// Why the game is refusing to fight.
enum CombatBlock {
  /// Nothing in the way.
  none,

  /// Moving too fast to be on foot and paying attention (§3.5).
  movingTooFast,

  /// The run is suspended by §3.4 — a mock provider, or a vehicle.
  runSuspended,
}

/// Whether a fight may start or go on.
///
/// Both conditions are the player's safety rather than the game's balance,
/// which is why they live here and not in the combat model.
CombatBlock combatBlock({
  required double speedKmh,
  required bool runSuspended,
}) {
  if (runSuspended) return CombatBlock.runSuspended;
  if (speedKmh > kCombatSpeedLimitKmh) return CombatBlock.movingTooFast;
  return CombatBlock.none;
}

/// The one-time safety briefing (§3.5).
///
/// Stored under this key in the settings table. The value is the version that
/// was accepted, not a boolean: if the rules change materially, the briefing is
/// shown again rather than assumed to have been read.
const String kSafetyBriefingKey = 'safety.briefing.accepted';

/// Bumped only when the *content* changes in a way a player should re-read.
/// Fixing a typo does not earn a second interruption.
const int kSafetyBriefingVersion = 1;

bool briefingAccepted(String? storedValue) {
  if (storedValue == null) return false;
  final accepted = int.tryParse(storedValue);
  return accepted != null && accepted >= kSafetyBriefingVersion;
}

/// Whether to remind the player about being seen (§3.5).
///
/// Given once per night rather than at every sunset crossing, and only while
/// the character is actually outdoors — the reminder is about traffic and
/// strangers, and neither is in the shelter.
class NightReminder {
  NightReminder();

  DateTime? _lastGivenNight;

  /// Returns true exactly once per night.
  ///
  /// [nightStart] identifies the night rather than the day, so a reminder given
  /// at 23:00 does not repeat at 00:30. The caller supplies it because only the
  /// daylight model knows where sunset fell.
  bool due({
    required bool isNight,
    required bool outdoors,
    required DateTime nightStart,
  }) {
    if (!isNight || !outdoors) return false;
    if (_lastGivenNight == nightStart) return false;

    _lastGivenNight = nightStart;
    return true;
  }
}
