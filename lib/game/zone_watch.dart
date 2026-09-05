/// Walking out of something that was being done (§2.1a.3, §12).
///
/// The rules were already there and were already right: a build is only paid
/// for on its site (§8.3), a bench only runs while somebody is standing at it
/// (§2.1a.3), a search ends if the player wanders off (§10.2). What was missing
/// is that **none of them said so**. The work simply stopped, the bar simply
/// froze, and the player found out later — or did not.
///
/// So this watches the one fact each of them turns on, and reports the moment
/// it flips. Nothing here decides anything: the rules stay where they are, and
/// this only notices that they fired.
///
/// Pure and Flutter-free — what the lines actually say lives in `ui/`.
library;

/// What just changed about being somewhere.
enum ZoneChange {
  /// The player walked out and the work is on hold.
  leftBuild,

  /// And came back to it.
  backToBuild,

  /// The bench, which is the same rule at a different table (§2.1a.3).
  leftBench,
  backToBench,
}

/// Remembers where the player was standing last time each rule was asked.
///
/// ⚠️ **The first answer is never a message.** Opening the app away from home
/// with a shelter half-built is not "you have left" — nothing was left, the
/// game was simply started. Reporting it would mean a notice on every launch,
/// which is how a player learns to ignore notices.
class ZoneWatch {
  bool? _build;
  bool? _bench;

  /// [onSite] is §8.3's question: is the player standing where the thing is
  /// going up.
  ZoneChange? build({required bool onSite}) {
    final was = _build;
    _build = onSite;

    if (was == null || was == onSite) return null;
    return onSite ? ZoneChange.backToBuild : ZoneChange.leftBuild;
  }

  /// [running] is whether there is a job on the bench at all: a paused clock
  /// with nothing on it is not news.
  ZoneChange? bench({required bool running, required bool paused}) {
    if (!running) {
      _bench = null;
      return null;
    }

    final was = _bench;
    _bench = paused;

    if (was == null || was == paused) return null;
    return paused ? ZoneChange.leftBench : ZoneChange.backToBench;
  }

  /// Forgets where anybody was standing. For a character ending, or a new one
  /// beginning, where the last run's doorway is not this one's.
  void reset() {
    _build = null;
    _bench = null;
  }
}
