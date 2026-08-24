import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/journal/journal.dart';
import 'package:arls_za/journal/journal_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';

import '../db/db_fixture.dart';

/// DZIENNIK (§3.6.1, §11.1).
///
/// ⚠️ **The tally could say how many; nothing could say what happened.**
/// §13.1's counters answer "340 rounds fired" and none of the questions a
/// player actually has after a walk: what came out of that pharmacy, when did
/// I get back, how long was I asleep, what was it that bit me. A number cannot
/// be read back as an evening.
///
/// Three rules hold the whole thing up: an entry is data rather than a
/// sentence (§1.1), a day means the same thing as the date on the phone, and
/// the log is capped — a streak is measured in months.
void main() {
  final t0 = DateTime.utc(2026, 8, 24, 18);

  group('§3.6.1: a day is a date, not a stopwatch', () {
    test('the first evening is day one', () {
      expect(journalDay(t0.add(const Duration(hours: 3)), startedAt: t0), 1);
    });

    test('and the next morning is day two, eleven hours in', () {
      // ⚠️ The one that decides whether "DZIEŃ 2" means anything. A player who
      // started at eight in the evening is on day two when they wake up, not
      // most of the way through day one — elapsed hours would put the boundary
      // in the middle of their night.
      final local = DateTime(2026, 8, 24, 20).toUtc();
      final morning = DateTime(2026, 8, 25, 7).toUtc();

      expect(journalDay(morning, startedAt: local), 2);
    });

    test('a week later is day eight', () {
      expect(journalDay(t0.add(const Duration(days: 7)), startedAt: t0), 8);
    });
  });

  group('§3.6.1: newest first, in both directions', () {
    test(
      'the day that just happened is at the top, and so is its last entry',
      () {
        final entries = [
          JournalEntry(at: t0, kind: JournalKind.wentOut),
          JournalEntry(
            at: t0.add(const Duration(hours: 2)),
            kind: JournalKind.cameHome,
          ),
          JournalEntry(
            at: t0.add(const Duration(days: 1)),
            kind: JournalKind.woke,
          ),
        ];

        final days = journalDays(entries, startedAt: t0);

        expect(days.map((each) => each.day), [2, 1]);
        expect(days.last.entries.first.kind, JournalKind.cameHome);
      },
    );

    test('an empty log is no days at all', () {
      expect(journalDays(const [], startedAt: t0), isEmpty);
    });
  });

  group('§1.1: an entry is data, never a sentence', () {
    test('a haul comes back as the ids that went in', () {
      final entry = JournalEntry(
        at: t0,
        kind: JournalKind.found,
        subject: 'med_bandage,med_bandage,tool_knife',
      );

      expect(entry.subjects, ['med_bandage', 'med_bandage', 'tool_knife']);
    });

    test('and nothing at all is an empty list rather than one empty id', () {
      final entry = JournalEntry(at: t0, kind: JournalKind.found);

      expect(entry.subjects, isEmpty);
    });

    test('every kind has a wire name and no two share one', () {
      // ⚠️ The wire names are what is on disk. A duplicate would silently
      // reclassify entries a player has already written.
      final wires = JournalKind.values.map((each) => each.wire).toList();

      expect(wires.toSet().length, wires.length);
      for (final kind in JournalKind.values) {
        expect(JournalKind.byWire(kind.wire), kind);
      }
    });
  });

  group('§11.1: three hundred days of it, on a phone', () {
    late SaveDatabase db;
    late JournalStore store;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
      store = JournalStore(db);
    });

    tearDown(() => db.close());

    test('an entry survives the app being killed', () async {
      await store.add(
        profileId,
        JournalEntry(
          at: t0,
          kind: JournalKind.found,
          subject: 'med_bandage,tool_knife',
        ),
      );

      final back = await store.load(profileId);

      expect(back, hasLength(1));
      expect(back.first.kind, JournalKind.found);
      expect(back.first.subject, 'med_bandage,tool_knife');
      expect(back.first.at, t0);
    });

    test('and comes back newest first', () async {
      for (var i = 0; i < 5; i++) {
        await store.add(
          profileId,
          JournalEntry(
            at: t0.add(Duration(minutes: i)),
            kind: JournalKind.searched,
            subject: 'shop $i',
          ),
        );
      }

      final back = await store.load(profileId);

      expect(back.first.subject, 'shop 4');
      expect(back.last.subject, 'shop 0');
    });

    test('the log is capped rather than kept for ever', () async {
      // ⚠️ A walk writes an entry every few minutes and a streak is meant to
      // last months (§13.1). Uncapped, this is a table that grows without
      // limit for the sake of a screen nobody reads past the first day of.
      for (var i = 0; i < kJournalKeep + 30; i++) {
        await store.add(
          profileId,
          JournalEntry(
            at: t0.add(Duration(minutes: i)),
            kind: JournalKind.woke,
          ),
        );
      }

      expect(await store.load(profileId), hasLength(kJournalKeep));
    });

    test('a kind this build has never heard of is dropped, not guessed at', () {
      // A save written by a later build can hold a kind this one does not
      // know. Inventing a line for it would put a lie in the player's own
      // record — which is worse than a gap.
      expect(JournalKind.byWire('coś-z-przyszłości'), isNull);
    });

    test('an unknown wire name survives a round trip as a gap', () async {
      await db.addJournalRow(
        JournalRowsCompanion.insert(
          profileId: profileId,
          at: t0,
          kind: 'coś-z-przyszłości',
          subject: const Value(null),
        ),
      );
      await store.add(profileId, JournalEntry(at: t0, kind: JournalKind.woke));

      expect(await store.load(profileId), hasLength(1));
    });
  });

  test('§3.6.1: and the game actually writes to it', () {
    // ⚠️ Source-level, because every part of this could be perfect and the
    // journal still be empty — which is the state §6.5's whole model was in
    // for two stages, and the defect this project keeps finding: a thing that
    // works and nothing calls.
    final main = File('lib/main.dart').readAsStringSync();

    for (final hook in [
      '_diary.bind(', // read back at boot
      '_diary.noteZone(', // the bed and the door
      '_diary.searched(', // a place, and what came out of it
      '_diary.used(', // eating, drinking, a dressing
      '_diary.salvaged(', // the bench
      'JournalKind.killed', // a body
      'JournalKind.built', // a module
      'JournalKind.blackout', // §9.2
      'journal: _diary.entries.value', // and the profile can see it
    ]) {
      expect(
        main.contains(hook),
        isTrue,
        reason: '$hook is a line the journal never gets',
      );
    }
  });
}
