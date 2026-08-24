/// §3.6.1's log, and the one rule that keeps it readable.
///
/// ⚠️ **A journal nobody wants to read is a table nobody should be writing
/// to.** Every entry here costs a row on a phone and a line on a screen, so
/// what goes in is what a player would tell somebody about afterwards: what
/// they found, what they fought, when they got home, when they slept. Not
/// every tick, not every step, and never the same thing twice in a row.
///
/// That last one is enforced rather than trusted — see [add].
library;

import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../craft/salvage_batch.dart';
import '../../sim/occupation.dart';
import '../../sim/tick.dart';
import '../../journal/journal.dart';
import '../../journal/journal_store.dart';

class JournalController extends ChangeNotifier {
  JournalController(this._db);

  final SaveDatabase _db;

  /// Newest first, so anything drawing it does not have to reverse it.
  final ValueNotifier<List<JournalEntry>> entries = ValueNotifier(const []);

  int? _profileId;

  /// When the run began, so an entry can be told which day it fell on.
  DateTime? _startedAt;

  DateTime get startedAt => _startedAt ?? DateTime.now().toUtc();

  Future<void> bind({
    required int profileId,
    required DateTime startedAt,
  }) async {
    _profileId = profileId;
    _startedAt = startedAt;

    entries.value = await JournalStore(_db).load(profileId);
    notifyListeners();
  }

  /// Writes one down.
  ///
  /// ⚠️ **Repeats are dropped.** Three shots at the same Walker inside a
  /// minute is one fight, not three lines, and the salvage bench finishing
  /// three vests is one entry with a count on it — a log that recorded every
  /// event separately would bury the evening it exists to describe. The window
  /// is deliberately short: the same thing an hour later is a new thing.
  Future<void> add(
    JournalKind kind, {
    String? subject,
    DateTime? at,
    Duration within = const Duration(minutes: 2),
  }) async {
    final profileId = _profileId;
    if (profileId == null) return;

    final when = at ?? DateTime.now().toUtc();
    final entry = JournalEntry(at: when, kind: kind, subject: subject);

    final last = entries.value.firstOrNull;
    if (last != null &&
        last.kind == kind &&
        last.subject == subject &&
        when.difference(last.at).abs() < within) {
      return;
    }

    entries.value = [entry, ...entries.value.take(kJournalKeep - 1)];
    notifyListeners();

    await JournalStore(_db).add(profileId, entry);
  }

  /// §10.2: a place turned over, and what came out of it.
  ///
  /// Two entries on purpose. "Przeszukanie: Żabka" and "Znalezione: nóż,
  /// bandaż ×2" answer different questions — where the evening went, and what
  /// there is to show for it — and a player who found nothing still walked
  /// into a shop.
  Future<void> searched(
    String place, {
    required Map<String, int> found,
    required DateTime at,
  }) async {
    await add(JournalKind.searched, subject: place, at: at);
    await add(JournalKind.found, subject: _list(found), at: at);
  }

  /// §18.6: a whole sitting, as one line.
  ///
  /// ⚠️ The pieces that went in, not the parts that came out. "Rozbiórka:
  /// kamizelka ×3" is what the player did; the screws are what they now have,
  /// and the pack already says that.
  Future<void> salvaged(List<SalvageStep> steps) =>
      made(JournalKind.salvaged, {for (final step in steps) step.itemId: 1});

  /// §18: what came off a bench, as one line with counts on it.
  Future<void> made(JournalKind kind, Map<String, int> items) =>
      add(kind, subject: _list(items));

  /// §4.7: one of the short things that suspends an occupation.
  ///
  /// ⚠️ Only the three worth remembering. Reloading and shooting are also
  /// [ActionKind]s and neither belongs in a diary — a fight is one line about
  /// the fight, not one about every time the magazine came out.
  Future<void> used(ActionKind action, String itemId) async {
    final kind = switch (action) {
      ActionKind.eating => JournalKind.ate,
      ActionKind.drinking => JournalKind.drank,
      ActionKind.dressing ||
      ActionKind.tourniquet ||
      ActionKind.suturing => JournalKind.treated,
      _ => null,
    };
    if (kind == null) return;

    await add(kind, subject: itemId);
  }

  /// §2.5.1, §8.1: the door and the bed, from the one thing that already knows
  /// about both.
  ///
  /// ⚠️ Driven by the metabolic zone rather than by a button. There is no
  /// "sleep" command in this game — §2.5.1 says the character sleeps when the
  /// conditions hold — so a journal that waited to be told would never record
  /// a night at all.
  Future<void> noteZone(MetabolicZone zone, {required DateTime at}) async {
    final before = _zone;
    _zone = zone;
    if (before == null || before == zone) return;

    if (zone == MetabolicZone.sleep) {
      return add(JournalKind.slept, at: at);
    }
    if (before == MetabolicZone.sleep) {
      return add(JournalKind.woke, at: at);
    }
    if (zone.isSheltered != before.isSheltered) {
      return add(
        zone.isSheltered ? JournalKind.cameHome : JournalKind.wentOut,
        at: at,
      );
    }
  }

  MetabolicZone? _zone;

  /// A count map as the subject of one entry: `bandage,bandage,knife`.
  ///
  /// ⚠️ Repeated rather than `id×2`. The reader counts them (§3.6.1), which
  /// means one format on disk instead of two and no parser to get wrong.
  static String _list(Map<String, int> items) => [
    for (final entry in items.entries)
      for (var i = 0; i < entry.value; i++) entry.key,
  ].join(',');

  /// §3.6.1: the run's days, newest first.
  List<JournalDay> get days => journalDays(entries.value, startedAt: startedAt);

  @override
  void dispose() {
    entries.dispose();
    super.dispose();
  }
}
