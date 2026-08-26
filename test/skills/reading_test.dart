import 'dart:io';
import 'dart:math';

import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/skills/reading.dart';
import 'package:arls_za/skills/skill.dart';
import 'package:test/test.dart';

/// LITERATURA (§4.6, §7.2.2).
///
/// ⚠️ **This is the path up.** §7.2.1's practice rewards a style of play and
/// is explicitly not the climb — twenty-three thousand bodies to a maxed
/// skill. §7.2.2 puts one skill at about five hundred hours of reading, which
/// is fifty-nine winter nights spent on nothing else, and that is the number
/// that makes the maximum a myth rather than a target (§13.1).
///
/// Until this existed, `literature.json` was eighteen titles of dead weight.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  Book bookOf(String id) {
    final book = Book.of(catalogue[id]);
    expect(book, isNotNull, reason: '$id is not literature');
    return book!;
  }

  group('§4.6: what a book is, off its own data', () {
    test('every title in the shipped file reads as one', () {
      // ⚠️ The file is shipped; a title that does not parse is a title that is
      // dead weight on somebody's phone with no way to find out.
      final literature = catalogue.all.where((item) => Book.of(item) != null);

      expect(literature, isNotEmpty);
      for (final item in literature) {
        final book = Book.of(item)!;
        expect(book.pagesMin, greaterThan(0), reason: item.id);
        expect(book.pagesMax, greaterThanOrEqualTo(book.pagesMin));
        expect(book.speedMultiplier, greaterThan(0), reason: item.id);
      }
    });

    test('and anything else is not a book at all', () {
      expect(Book.of(catalogue['med_bandage']), isNull);
      expect(Book.of(null), isNull);
    });

    test('a story note teaches nothing (§19.1)', () {
      // Zero by design: it is there to be read, not farmed.
      expect(bookOf('lit_note').xpPerPage, 0);
      expect(bookOf('lit_note').skill, isNull);
    });

    test('and everything else teaches one of the four (§7.1)', () {
      for (final item in catalogue.all) {
        final book = Book.of(item);
        if (book == null || book.xpPerPage == 0) continue;

        expect(Skill.fromWire(book.skill), isNotNull, reason: item.id);
      }
    });
  });

  group('§4.6.4: every copy is its own length', () {
    test('a roll lands inside the title own range', () {
      final book = bookOf('lit_textbook_medicine');

      for (var seed = 0; seed < 60; seed++) {
        final pages = book.rollPages(Random(seed));

        expect(pages, greaterThanOrEqualTo(book.pagesMin));
        expect(pages, lessThanOrEqualTo(book.pagesMax));
      }
    });

    test('and two copies of one title differ', () {
      // ⚠️ The whole of §4.6.4. Two manuals of the same title may be 180 and
      // 340 pages: they weigh differently, read for different lengths and are
      // worth different amounts.
      final book = bookOf('lit_textbook_medicine');
      final rolls = {
        for (var seed = 0; seed < 40; seed++) book.rollPages(Random(seed)),
      };

      expect(rolls.length, greaterThan(1));
    });

    test('experience is per page, never per title', () {
      // Without this a four-hundred-page manual pays what a hundred-and-fifty
      // page one pays, for three times the reading.
      final book = bookOf('lit_textbook_medicine');

      expect(book.xpFor(400), book.xpFor(200) * 2);
    });
  });

  group('§4.6.1: credited as it is read', () {
    test('half a book is half the experience', () {
      final book = bookOf('lit_guide_repairs');

      expect(book.xpFor(100), book.xpFor(200) ~/ 2);
    });

    test('and a page is about seventy-six seconds', () {
      // §4.6.1's own granularity: feedback roughly once a minute, so a night
      // of reading is a night of something visibly happening.
      expect(kPageAtBaseRate.inSeconds, closeTo(76, 1));
    });

    test('a leaflet reads faster than an encyclopedia, page for page', () {
      expect(
        bookOf('lit_leaflet_first_aid').pageTime(),
        lessThan(bookOf('lit_encyclopedia_medicine').pageTime()),
      );
    });
  });

  group('§4.6.3: the tenth copy of the same manual', () {
    test('the second is worth a quarter and the third nothing', () {
      final book = bookOf('lit_textbook_medicine');

      expect(book.xpFor(100, copiesRead: 1), (book.xpFor(100) * 0.25).round());
      expect(book.xpFor(100, copiesRead: 2), 0);
      expect(book.xpFor(100, copiesRead: 9), 0);
    });

    test('zero is the rule, not a rounding of very little', () {
      // ⚠️ A player who can reach a hundred per cent of a skill by walking
      // into ten chemists has not read anything.
      expect(repeatShare(0), 1);
      expect(repeatShare(1), 0.25);
      expect(repeatShare(2), 0);
    });

    test('and there is no bonus for finishing (§4.6.3)', () {
      // Ten books at a tenth each pay exactly what one book read whole pays.
      // A completion bonus would put back the "wait until the end" problem
      // §4.6.1 exists to remove.
      final book = bookOf('lit_guide_repairs');
      final piecemeal = List.filled(
        10,
        book.xpFor(20),
      ).fold(0, (a, b) => a + b);

      expect(piecemeal, book.xpFor(200));
    });
  });

  group('§8.4: the Lounge shortens an evening as well as a night', () {
    test('four per cent a level, twelve at the third', () {
      expect(kLoungeReadingSpeed, 0.04);
      expect(kLoungeReadingSpeedMax, closeTo(0.12, 1e-9));
    });

    test('a third-level Lounge takes about a ninth off the reading', () {
      final book = bookOf('lit_encyclopedia_medicine');

      final plain = book.timeFor(600).inSeconds;
      final comfortable = book.timeFor(600, lounge: 3).inSeconds;

      // 1 / 1.12 — the time falls by about eleven per cent for twelve per cent
      // more speed, which is what a multiplier means and what the card says.
      expect(comfortable / plain, closeTo(1 / 1.12, 0.01));
    });

    test('and no Lounge changes nothing', () {
      final book = bookOf('lit_textbook_medicine');

      expect(book.pageTime(lounge: 0), book.pageTime());
    });

    test('past the third level it stops', () {
      final book = bookOf('lit_textbook_medicine');

      expect(book.pageTime(lounge: 9), book.pageTime(lounge: 3));
    });
  });

  test('§4.6, §2.1a: and a book can actually be opened', () {
    // ⚠️ Source-level, and this is the whole of faza C. `literature.json`
    // has shipped eighteen titles since stage 4, `OccupationKind.reading` has
    // existed as long, and nothing in the game ever started one: the path up
    // §7's curve was dead weight in a pack. These are the five joints.
    final main = File('lib/main.dart').readAsStringSync();
    final pack = File('lib/ui/inventory_screen.dart').readAsStringSync();

    // The pack offers it for a book, not only for §19.1's found paper.
    expect(pack.contains('line.pagesTotal != null'), isTrue);

    expect(main.contains('_readBook('), isTrue);
    expect(main.contains('ActionKind.reading.name'), isTrue);

    // §4.6.1: a page at a time, credited as it is read.
    expect(main.contains('.readOne(line!)'), isTrue);
    expect(main.contains('book.xpFor(1, copiesRead:'), isTrue);

    // §2.1a, §2.5.1: reading is *long work*, not forty short ones. A page is
    // its own action, so without this the zone fell out of sleep and back into
    // it between every pair of them — the log filled with a Sen and a Pobudka
    // per page, photographed from a phone.
    expect(main.contains('_books.open != null ||'), isTrue);

    // §12: and the strip says where in the book somebody is.
    expect(main.contains('actionReadingPage('), isTrue);

    // §4.6.3: and a finished copy is counted against the next one.
    expect(main.contains('_books.finished('), isTrue);
    expect(main.contains('_books.copiesOf('), isTrue);
  });

  test('§4.6.4: and the game actually rolls a copy its own length', () {
    // ⚠️ Source-level, and this one was live for four stages. [CarriedItem]
    // has computed a book's mass and bulk from `pagesTotal` since stage 4 —
    // pages x g_per_page + cover_g, which is how an encyclopedia reaches two
    // kilograms — and nothing in the game ever set the field. Every book found
    // in the world weighed its catalogue's middling copy, and §4.6.4's whole
    // "biore te ksiazke czy zostawiam" decision did not exist.
    final store = File('lib/loot/dropped_store.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(store.contains('book?.rollPages(random)'), isTrue);
    expect(
      main.contains('catalogue: catalogue,'),
      isTrue,
      reason: 'the drop cannot roll pages without knowing what it is dropping',
    );
  });

  test('§7.2.2: and the whole climb is still five hundred hours', () {
    // The figure §13.1 rests on: a maximum that is a myth rather than a
    // target. Read entirely off the shipped data, so a generous edit to a
    // title fails here rather than quietly making the myth reachable.
    final book = bookOf('lit_encyclopedia_medicine');
    final pages = kXpToMaxSkill / book.xpPerPage;
    final hours = book.timeFor(pages.round()).inMinutes / 60;

    expect(hours, greaterThan(300), reason: 'a skill has to cost a season');
    expect(hours, lessThan(700));
  });
}
