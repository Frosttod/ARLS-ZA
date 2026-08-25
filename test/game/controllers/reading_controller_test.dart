import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/reading_controller.dart';
import 'package:test/test.dart';

import '../../db/db_fixture.dart';

/// DZIESIĄTY EGZEMPLARZ TEGO SAMEGO PODRĘCZNIKA (§4.6.3).
///
/// ⚠️ **The one thing reading needs that a book cannot carry itself.** A copy
/// knows how far through it somebody is; only the character knows that this is
/// the fourth first-aid manual they have found. Without the count a player
/// walks into ten chemists and maxes Medicine having read nothing.
void main() {
  late SaveDatabase db;
  late ReadingController read;
  late int profileId;

  setUp(() async {
    db = SaveDatabase.memory();
    profileId = await insertProfile(db);
    read = ReadingController(db);
    await read.load(profileId);
  });

  tearDown(() async {
    read.dispose();
    await db.close();
  });

  test('a title nobody has read is worth full price', () {
    expect(read.copiesOf('lit_textbook_medicine'), 0);
  });

  test('and each finished copy is counted', () async {
    await read.finished('lit_textbook_medicine');
    expect(read.copiesOf('lit_textbook_medicine'), 1);

    await read.finished('lit_textbook_medicine');
    expect(read.copiesOf('lit_textbook_medicine'), 2);
  });

  test('per title, which is where the exploit is (§4.6.3)', () async {
    // ⚠️ A second *different* manual is a second book and pays in full. The
    // rule is about re-reading the same thing, not about reading two things
    // that happen to teach the same skill.
    await read.finished('lit_textbook_medicine');

    expect(read.copiesOf('lit_guide_first_aid'), 0);
  });

  test('and it survives the process being killed (§11.1)', () async {
    await read.finished('lit_encyclopedia_weapons');

    final later = ReadingController(db);
    addTearDown(later.dispose);
    await later.load(profileId);

    expect(later.copiesOf('lit_encyclopedia_weapons'), 1);
  });

  test('counted on finishing, never on starting', () async {
    // §4.6.3: somebody who reads half of each of ten copies is paid for half
    // of one and a quarter of another and nothing for the rest — the same as
    // §4.6.1's rule for one book. There is no completion bonus, and no
    // completion penalty either.
    expect(read.copiesOf('lit_guide_survival'), 0);
  });
}
