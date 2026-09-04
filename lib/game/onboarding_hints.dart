/// The first-contact hints, and the one reminder that comes back (§15.5, §3.5).
///
/// §15.5 asks for five lines triggered by *what happened*, not by a sequence:
/// the map, the first fifty metres, the first supplies in sight, the first look
/// in the pack, the first Decay Zone. Each is said once in the life of a
/// character and never again — a tutorial that repeats is a tutorial the player
/// learns to dismiss without reading.
///
/// ⚠️ **The dusk reminder is the exception, and deliberately.** §3.5 is a
/// safety clause rather than an onboarding one: being visible after dark
/// matters on day two hundred exactly as much as on day one, so it comes back
/// every evening. Once per local date, so a player walking through dusk does
/// not get it twice.
///
/// Pure and Flutter-free, so it runs under `dart test`. What each line *says*
/// is a matter for the interface; what is owed is decided here.
library;

/// One thing the game explains the first time it happens (§15.5).
enum Hint {
  /// Standing on the map for the first time.
  map,

  /// [kFirstWalkM] covered since the map appeared.
  walk,

  /// A loot marker in sight.
  loot,

  /// The pack opened.
  pack,

  /// A Decay Zone on the map.
  zone,
}

/// §15.5: far enough that the player has watched the dot follow them, and
/// short enough to happen in the first minute of the first walk.
const double kFirstWalkM = 50;

/// What has already been said, and when the evening reminder last went out.
///
/// Immutable in the sense that matters: [take] and [saidDusk] return a new log
/// rather than mutating, so the caller decides when it is worth writing to the
/// database. The wire format is `map,walk,loot|2026-09-04` — a set and a date,
/// because that is exactly what is remembered.
class HintLog {
  const HintLog({this.seen = const {}, this.duskSaidOn});

  final Set<Hint> seen;

  /// The local date the dusk reminder last went out, midnight-normalised.
  final DateTime? duskSaidOn;

  bool has(Hint hint) => seen.contains(hint);

  /// The hints owed right now, in the order §15.5 lists them.
  ///
  /// [movedM] is measured from wherever the player was when the map hint fired,
  /// not from the start of the run: a character created indoors and carried in
  /// a pocket has not walked fifty metres of *game*.
  List<Hint> due({
    required bool onMap,
    required double movedM,
    required bool lootInSight,
    required bool zoneInSight,
  }) => [
    if (onMap && !has(Hint.map)) Hint.map,
    // The walk hint follows the map hint; before it, there is nothing to have
    // walked away from.
    if (has(Hint.map) && movedM >= kFirstWalkM && !has(Hint.walk)) Hint.walk,
    if (onMap && lootInSight && !has(Hint.loot)) Hint.loot,
    if (onMap && zoneInSight && !has(Hint.zone)) Hint.zone,
  ];

  /// Whether §3.5's visibility reminder is owed this evening.
  ///
  /// The window is deliberately narrow: from dusk until an hour after it. A
  /// player who opens the game at midnight is not helped by being told the sun
  /// went down.
  bool duskDue({required DateTime now, required DateTime? dusk}) {
    if (dusk == null) return false;

    final local = now.toLocal();
    final since = local.difference(dusk.toLocal());
    if (since.isNegative || since > const Duration(hours: 1)) return false;

    final today = DateTime(local.year, local.month, local.day);
    return duskSaidOn != today;
  }

  HintLog take(Iterable<Hint> hints) =>
      HintLog(seen: {...seen, ...hints}, duskSaidOn: duskSaidOn);

  HintLog saidDusk(DateTime at) {
    final local = at.toLocal();
    return HintLog(
      seen: seen,
      duskSaidOn: DateTime(local.year, local.month, local.day),
    );
  }

  String get wire {
    final said = duskSaidOn;
    final date = said == null
        ? ''
        : '${said.year.toString().padLeft(4, '0')}-'
              '${said.month.toString().padLeft(2, '0')}-'
              '${said.day.toString().padLeft(2, '0')}';
    return '${seen.map((hint) => hint.name).join(',')}|$date';
  }

  /// ⚠️ Never throws and never refuses. A hint log that cannot be read is a
  /// player who sees the first-day lines again — irritating, and not a reason
  /// to fail a boot.
  static HintLog parse(String? wire) {
    if (wire == null || wire.isEmpty) return const HintLog();

    final parts = wire.split('|');
    final names = parts.first.split(',').toSet();

    return HintLog(
      seen: {
        for (final hint in Hint.values)
          if (names.contains(hint.name)) hint,
      },
      duskSaidOn: parts.length > 1 ? DateTime.tryParse(parts[1]) : null,
    );
  }
}
