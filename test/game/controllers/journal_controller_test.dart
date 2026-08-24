import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/journal_controller.dart';
import 'package:arls_za/journal/journal.dart';
import 'package:arls_za/sim/occupation.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

import '../../db/db_fixture.dart';

/// CO TRAFIA DO DZIENNIKA (§3.6.1).
///
/// ⚠️ **A journal nobody wants to read is a table nobody should be writing
/// to.** Every entry costs a row on a phone and a line on a screen, so the bar
/// is what a player would tell somebody about afterwards. Two rules do most of
/// the work: the same thing twice inside a couple of minutes is one thing, and
/// the bed and the door are read off the state rather than waited for — there
/// is no "sleep" button in this game (§2.5.1).
void main() {
  final t0 = DateTime.utc(2026, 8, 24, 18);

  late SaveDatabase db;
  late JournalController diary;
  late int profileId;

  setUp(() async {
    db = SaveDatabase.memory();
    profileId = await insertProfile(db);
    diary = JournalController(db);
    await diary.bind(profileId: profileId, startedAt: t0);
  });

  tearDown(() async {
    diary.dispose();
    await db.close();
  });

  group('§3.6.1: the same thing twice is one thing', () {
    test('three shots at the same Walker are one line', () async {
      for (var i = 0; i < 3; i++) {
        await diary.add(
          JournalKind.fought,
          subject: 'walker',
          at: t0.add(Duration(seconds: i * 20)),
        );
      }

      expect(diary.entries.value, hasLength(1));
    });

    test('but the same thing an hour later is a new thing', () async {
      await diary.add(JournalKind.fought, subject: 'walker', at: t0);
      await diary.add(
        JournalKind.fought,
        subject: 'walker',
        at: t0.add(const Duration(hours: 1)),
      );

      expect(diary.entries.value, hasLength(2));
    });

    test('and a different subject is never a repeat', () async {
      await diary.add(JournalKind.killed, subject: 'walker', at: t0);
      await diary.add(JournalKind.killed, subject: 'brute', at: t0);

      expect(diary.entries.value, hasLength(2));
    });
  });

  group('§2.5.1, §8.1: the bed and the door, off the state', () {
    test('walking in under a roof is a line', () async {
      await diary.noteZone(MetabolicZone.open, at: t0);
      await diary.noteZone(MetabolicZone.shelter, at: t0);

      expect(diary.entries.value.first.kind, JournalKind.cameHome);
    });

    test('and walking back out is another', () async {
      await diary.noteZone(MetabolicZone.shelter, at: t0);
      await diary.noteZone(MetabolicZone.open, at: t0);

      expect(diary.entries.value.first.kind, JournalKind.wentOut);
    });

    test('falling asleep and waking up are both written down', () async {
      await diary.noteZone(MetabolicZone.shelter, at: t0);
      await diary.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 1)),
      );
      await diary.noteZone(
        MetabolicZone.shelter,
        at: t0.add(const Duration(hours: 8)),
      );

      expect(diary.entries.value.map((each) => each.kind).take(2), [
        JournalKind.woke,
        JournalKind.slept,
      ]);
    });

    test('the first reading is not a transition', () async {
      // ⚠️ Opening the app at home is not coming home. Without this every boot
      // inside a shelter would write a "powrót" nobody walked.
      await diary.noteZone(MetabolicZone.shelter, at: t0);

      expect(diary.entries.value, isEmpty);
    });

    test('and standing still writes nothing at all', () async {
      for (var i = 0; i < 5; i++) {
        await diary.noteZone(
          MetabolicZone.open,
          at: t0.add(Duration(minutes: i)),
        );
      }

      expect(diary.entries.value, isEmpty);
    });
  });

  group('§10.2, §4.7: what the game hands it', () {
    test('a search is two entries: the place, and the haul', () async {
      await diary.searched(
        'Żabka',
        found: {'med_bandage': 2, 'tool_knife': 1},
        at: t0,
      );

      final entries = diary.entries.value;

      expect(entries.map((each) => each.kind), [
        JournalKind.found,
        JournalKind.searched,
      ]);
      expect(entries.last.subject, 'Żabka');
      expect(entries.first.subjects, [
        'med_bandage',
        'med_bandage',
        'tool_knife',
      ]);
    });

    test('a place that gave up nothing is still a place walked into', () async {
      await diary.searched('Żabka', found: const {}, at: t0);

      expect(diary.entries.value, hasLength(2));
    });

    test('eating, drinking and a dressing each get their own kind', () async {
      await diary.used(ActionKind.eating, 'food_tin');
      await diary.used(ActionKind.drinking, 'water_bottle');
      await diary.used(ActionKind.tourniquet, 'med_tourniquet');

      expect(diary.entries.value.map((each) => each.kind), [
        JournalKind.treated,
        JournalKind.drank,
        JournalKind.ate,
      ]);
    });

    test('reloading is not a diary entry', () async {
      // ⚠️ A fight is one line about the fight. Every ActionKind reaching the
      // journal would bury the evening it exists to describe.
      await diary.used(ActionKind.reloading, 'ammo_545');
      await diary.used(ActionKind.shooting, 'weapon_ak74');

      expect(diary.entries.value, isEmpty);
    });
  });

  test('§11.1: it is on disk before the process can be killed', () async {
    await diary.add(JournalKind.killed, subject: 'brute', at: t0);

    final second = JournalController(db);
    addTearDown(second.dispose);
    await second.bind(profileId: profileId, startedAt: t0);

    expect(second.entries.value.single.subject, 'brute');
  });
}
