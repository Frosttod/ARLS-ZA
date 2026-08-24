/// Reading and writing §3.6.1's log (§11.1).
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import 'journal.dart';

class JournalStore {
  const JournalStore(this._db);

  final SaveDatabase _db;

  /// The newest [kJournalKeep] entries, newest first.
  Future<List<JournalEntry>> load(int profileId) async {
    final rows = await _db.journalFor(profileId, limit: kJournalKeep);

    return [
      for (final row in rows)
        // ⚠️ An unknown wire name is dropped, not guessed at. A save written
        // by a later build can hold a kind this one has never heard of, and
        // inventing a line for it would put a lie in the player's own record.
        if (JournalKind.byWire(row.kind) case final kind?)
          JournalEntry(at: row.at, kind: kind, subject: row.subject),
    ];
  }

  /// Appends one, and drops whatever fell off the end.
  Future<void> add(int profileId, JournalEntry entry) async {
    await _db.addJournalRow(
      JournalRowsCompanion.insert(
        profileId: profileId,
        at: entry.at,
        kind: entry.kind.wire,
        subject: Value(entry.subject),
      ),
    );

    await _db.trimJournal(profileId, keep: kJournalKeep);
  }
}
