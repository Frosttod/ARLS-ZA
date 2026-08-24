/// What the character did, in the order they did it (§3.6.1, §13.1).
///
/// ⚠️ **The tally says how many; this says what happened.** §13.1's counters
/// are the right shape for "you have fired 340 rounds" and the wrong shape for
/// every question a player actually asks after a walk: what did I find in that
/// pharmacy, when did I get back, how long was I asleep, what was it that bit
/// me. A number cannot be read back as an evening.
///
/// **Nothing here is a sentence.** An entry is a kind and a subject — an item
/// id, an enemy kind, a shop's name off the map — and the words are put around
/// it at the moment it is drawn. A journal that stored Polish prose would be a
/// journal that lied the first time somebody changed the language (§1.1).
library;

/// One thing that happened.
enum JournalKind {
  /// §10.2: a place turned over, and what came out of it.
  searched('szukanie'),
  found('znalezione'),

  /// §18.5: a lock, a car door, a shutter.
  opened('otwarcie'),

  /// §5, §6.2: a fight, and how it ended.
  fought('walka'),
  killed('zabity'),
  hurt('rana'),

  /// §4.7: the short things that suspend an occupation.
  ate('jedzenie'),
  drank('picie'),
  treated('opatrunek'),

  /// §2.5: the long ones.
  slept('sen', wakes: false),
  woke('pobudka', wakes: false),
  read('lektura'),

  /// §8.3, §18: work, in both halves.
  ///
  /// ⚠️ **Both ends, not just the finish.** A dismantling runs half an hour
  /// and a shelter module runs for days — a log that only wrote them down on
  /// completion said nothing about the evening they were started in, which is
  /// the evening the player actually spent.
  startedBuild('start budowy'),
  built('budowa', wakes: false),
  startedCraft('start wytwarzania'),
  crafted('wytworzone'),
  startedSalvage('start rozbiórki'),
  salvaged('rozbiórka'),

  /// §8.1: the door, in both directions.
  cameHome('powrót', wakes: false),
  wentOut('wyjście'),

  /// §7, §9.2: the two things worth remembering that nobody chose.
  learned('umiejętność', wakes: false),
  blackout('utrata przytomności', wakes: false);

  const JournalKind(this.wire, {this.wakes = true});

  /// ⚠️ Fixed by what is on disk. Renaming one silently reclassifies every
  /// entry a player has ever written — the same rule §7's skills keep.
  final String wire;

  /// §2.5.1: whether doing this means the character is no longer asleep.
  ///
  /// ⚠️ **Reaching for a bottle in the night is waking up.** The sim only
  /// notices on its next tick, so an entry written the moment the player taps
  /// would sit above a night that had not ended yet — the journal would read
  /// "sen, picie, pobudka", which is not what happened and not what anybody
  /// would write down.
  ///
  /// False for the things that happen *to* a sleeping character or without
  /// them: a module finishing on its own clock (§8.3), a blackout, a level.
  final bool wakes;

  static JournalKind? byWire(String wire) {
    for (final kind in JournalKind.values) {
      if (kind.wire == wire) return kind;
    }
    return null;
  }
}

class JournalEntry {
  const JournalEntry({required this.at, required this.kind, this.subject});

  /// UTC, like every other clock in this game. Drawn in local time, because a
  /// player reads their own evening off their own watch.
  final DateTime at;

  final JournalKind kind;

  /// What it was about, as data: an item id, a comma-joined list of them, an
  /// enemy kind, a module id, a place name off the map. Null where the kind
  /// says everything — waking up is waking up.
  final String? subject;

  /// The subject as a list, for the kinds that carry several.
  List<String> get subjects =>
      subject == null || subject!.isEmpty ? const [] : subject!.split(',');
}

/// §3.6.1: how many entries a run keeps.
///
/// ⚠️ A cap rather than everything. A walk writes an entry every few minutes,
/// and a streak is meant to be measured in months (§13.1) — an uncapped
/// journal is a table that grows without limit on a phone, to be read by
/// nobody past its first screen.
const int kJournalKeep = 400;

/// §3.6.1: how many days of it a screen shows at once.
///
/// ⚠️ A week, not the run. Four hundred entries is what is *kept* — a month of
/// them on one screen is a list nobody scrolls to the bottom of, and the days
/// past the last seven are history rather than a thing anybody is about to act
/// on.
const int kJournalDays = 7;

/// Which day of the run [at] fell on, counting the first as day one.
///
/// ⚠️ Local dates on both sides, and dates rather than elapsed time. A player
/// who started at eight in the evening is on day two when they wake up the
/// next morning, not eleven hours into day one — "DZIEŃ 2" has to mean the
/// same thing as the date on their phone or it means nothing.
int journalDay(DateTime at, {required DateTime startedAt}) {
  final from = startedAt.toLocal();
  final to = at.toLocal();

  return DateTime(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime(from.year, from.month, from.day)).inDays +
      1;
}

/// One day of a run, with the entries that fell in it.
class JournalDay {
  const JournalDay({required this.day, required this.entries});

  final int day;
  final List<JournalEntry> entries;
}

/// Groups entries into days, newest first.
///
/// ⚠️ Newest first, in both directions. A log on a phone is read the way a
/// call list is read — the thing that just happened is the thing being looked
/// for, and a run that lasts a month would otherwise open on a morning nobody
/// remembers.
List<JournalDay> journalDays(
  List<JournalEntry> entries, {
  required DateTime startedAt,
  int? days = kJournalDays,
}) {
  final byDay = <int, List<JournalEntry>>{};
  for (final entry in entries) {
    byDay
        .putIfAbsent(journalDay(entry.at, startedAt: startedAt), () => [])
        .add(entry);
  }

  final found = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  final kept = days == null ? found : found.take(days);

  return [
    for (final day in kept)
      JournalDay(
        day: day,
        entries: byDay[day]!..sort((a, b) => b.at.compareTo(a.at)),
      ),
  ];
}
