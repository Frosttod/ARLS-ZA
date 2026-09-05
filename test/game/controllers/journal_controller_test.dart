import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/journal_controller.dart';
import 'package:arls_za/journal/journal.dart';
import 'package:arls_za/sim/action_kind.dart';
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
        'poi_grocery',
        name: 'Żabka',
        found: {'med_bandage': 2, 'tool_knife': 1},
        at: t0,
      );

      final entries = diary.entries.value;

      expect(entries.map((each) => each.kind), [
        JournalKind.found,
        JournalKind.searched,
      ]);
      expect(placeSubject(entries.last.subject).name, 'Żabka');
      expect(placeSubject(entries.last.subject).tableId, 'poi_grocery');
      expect(entries.first.subjects, [
        'med_bandage',
        'med_bandage',
        'tool_knife',
      ]);
    });

    test('a place with no name of its own keeps its kind', () async {
      // ⚠️ Reported from the field: "Przeszukanie: proc_waste". OSM names most
      // shops and nothing else — a procedural spot has only the table it was
      // drawn from, and that is an identifier, not a word.
      await diary.searched('proc_waste', found: const {}, at: t0);

      final found = placeSubject(diary.entries.value.last.subject);

      expect(found.tableId, 'proc_waste');
      expect(found.name, isNull);
    });

    test('a place that gave up nothing is still a place walked into', () async {
      await diary.searched('proc_waste', found: const {}, at: t0);

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

  group('§2.5.1: reaching for something in the night is waking up', () {
    test('the pobudka comes first, and the drink after it', () async {
      // ⚠️ The order the player actually lived. The sim only leaves the sleep
      // zone on its next tick, so an entry written the moment they tap would
      // sit above a night that had not ended — "sen, picie, pobudka".
      await diary.noteZone(MetabolicZone.shelter, at: t0);
      await diary.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 1)),
      );

      await diary.add(
        JournalKind.drank,
        subject: 'water_bottle',
        at: t0.add(const Duration(hours: 4)),
      );

      expect(diary.entries.value.map((each) => each.kind), [
        JournalKind.drank,
        JournalKind.woke,
        JournalKind.slept,
      ]);
    });

    test('and it is said once, however many things they get up for', () async {
      await diary.noteZone(MetabolicZone.sleep, at: t0);
      await diary.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 1)),
      );

      await diary.add(JournalKind.drank, subject: 'water', at: t0);
      await diary.add(JournalKind.ate, subject: 'tin', at: t0);

      final woke = diary.entries.value.where(
        (each) => each.kind == JournalKind.woke,
      );

      expect(woke, hasLength(1));
    });

    test('a module finishing on its own clock does not wake anybody', () async {
      // §8.3 builds run with the app shut. Waking the character up for one
      // would be the journal inventing a night nobody had.
      await diary.noteZone(MetabolicZone.shelter, at: t0);
      await diary.noteZone(MetabolicZone.sleep, at: t0);
      await diary.add(JournalKind.built, subject: 'lounge', at: t0);

      expect(
        diary.entries.value.map((each) => each.kind),
        isNot(contains(JournalKind.woke)),
      );
    });

    test('going back down afterwards is a new night', () async {
      await diary.noteZone(MetabolicZone.sleep, at: t0);
      await diary.add(
        JournalKind.drank,
        subject: 'water',
        at: t0.add(const Duration(hours: 3)),
      );
      await diary.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 3, minutes: 5)),
      );

      expect(diary.entries.value.first.kind, JournalKind.slept);
    });

    test('but not on the tick a second into the drink', () async {
      // ⚠️ The tick fires every second. Without a window the journal would
      // end the night the drink interrupted before the drink was swallowed.
      await diary.noteZone(MetabolicZone.sleep, at: t0);
      await diary.add(
        JournalKind.drank,
        subject: 'water',
        at: t0.add(const Duration(hours: 3)),
      );
      await diary.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 3, seconds: 1)),
      );

      expect(diary.entries.value.first.kind, JournalKind.drank);
    });

    test('and the zone catching up does not say pobudka twice', () async {
      await diary.noteZone(MetabolicZone.sleep, at: t0);
      await diary.add(JournalKind.drank, subject: 'water', at: t0);
      await diary.noteZone(
        MetabolicZone.shelter,
        at: t0.add(const Duration(seconds: 30)),
      );

      expect(
        diary.entries.value.where((each) => each.kind == JournalKind.woke),
        hasLength(1),
      );
    });
  });

  group('§11.1: the app closed on a sleeping character', () {
    // ⚠️ Reported from the field: "ostatnia akcja to Sen 18:39" and the log
    // still says so hours later. §2.1a.3 runs the night with the app shut and
    // the simulation credits every hour of it — but the journal's first
    // reading after a restart is deliberately not a transition, so that
    // opening the app at home does not write a "powrót" nobody walked. That
    // rule swallowed the waking with it.

    test(
      'the pobudka is written when the game comes back to a waking',
      () async {
        await diary.noteZone(MetabolicZone.shelter, at: t0);
        await diary.noteZone(
          MetabolicZone.sleep,
          at: t0.add(const Duration(hours: 1)),
        );

        // The process dies here. Eight hours later, a fresh controller.
        final morning = JournalController(db);
        addTearDown(morning.dispose);
        await morning.bind(profileId: profileId, startedAt: t0);

        await morning.noteZone(
          MetabolicZone.shelter,
          at: t0.add(const Duration(hours: 9)),
        );

        expect(morning.entries.value.first.kind, JournalKind.woke);
      },
    );

    test('and stays quiet while they are still under the covers', () async {
      await diary.noteZone(MetabolicZone.sleep, at: t0);

      final same = JournalController(db);
      addTearDown(same.dispose);
      await same.bind(profileId: profileId, startedAt: t0);

      final before = same.entries.value.length;
      await same.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 3)),
      );

      expect(same.entries.value, hasLength(before));
    });

    test('a restart anywhere else still writes no powrót', () async {
      // The rule the seeding must not weaken. Opening the app at home is not
      // coming home.
      await diary.noteZone(MetabolicZone.open, at: t0);
      await diary.noteZone(MetabolicZone.shelter, at: t0);

      final later = JournalController(db);
      addTearDown(later.dispose);
      await later.bind(profileId: profileId, startedAt: t0);

      final before = later.entries.value.length;
      await later.noteZone(
        MetabolicZone.shelter,
        at: t0.add(const Duration(hours: 2)),
      );

      expect(later.entries.value, hasLength(before));
    });
  });

  group('§3.6.1: a night that lasted two minutes was not a night', () {
    // ⚠️ Photographed from a phone: forty lines of "Sen" and "Pobudka"
    // alternating over seven minutes. A page of a book is its own action
    // (§4.6.1), so between two of them nothing was running, §2.5.1 put the
    // character to sleep in their chair and the next page woke them up. The
    // root is fixed where it belongs — reading is long work now — and this is
    // the log refusing to be made ridiculous by whatever flickers next.

    test('a sleep that follows a waking too closely is not written', () async {
      await diary.noteZone(MetabolicZone.sleep, at: t0);
      await diary.noteZone(
        MetabolicZone.shelter,
        at: t0.add(const Duration(hours: 1)),
      );

      final before = diary.entries.value.length;
      await diary.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 1, seconds: 30)),
      );

      expect(diary.entries.value, hasLength(before));
    });

    test('but going back to bed after a while is a night again', () async {
      await diary.noteZone(MetabolicZone.sleep, at: t0);
      await diary.noteZone(
        MetabolicZone.shelter,
        at: t0.add(const Duration(hours: 1)),
      );
      await diary.noteZone(
        MetabolicZone.sleep,
        at: t0.add(const Duration(hours: 1, minutes: 20)),
      );

      expect(diary.entries.value.first.kind, JournalKind.slept);
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
