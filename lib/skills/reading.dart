/// Books, and what reading one is worth (§4.6, §7.2).
///
/// ⚠️ **This is the path.** §7.2.1's practice rewards a style of play and is
/// explicitly not the way up — twenty-three thousand bodies to a maxed skill.
/// The climb is here: §7.2.2 puts one skill at about five hundred hours of
/// reading, which is fifty-nine winter nights spent on nothing else. Until
/// this existed, `literature.json` was eighteen titles of dead weight in a
/// pack and the four skills could only be scratched.
///
/// Three rules do the work, and each of them is a defect avoided:
///
/// * **Experience per page, never per title** (§4.6.4). A four-hundred-page
///   manual must not pay what a hundred-and-fifty-page one pays for three
///   times the reading.
/// * **Credited as it is read** (§4.6.1). A reward that arrived only at the
///   end of a forty-hour encyclopedia would be many nights of investment with
///   no signal at all, and a page is about seventy-six seconds — feedback
///   roughly once a minute.
/// * **No completion bonus** (§4.6.3). Ten books at a tenth each pay exactly
///   what one book read whole pays, deliberately: a bonus for finishing would
///   put back the "wait until the end" problem the second rule removes. The
///   reason to finish a book is its mass.
library;

import 'dart:math';

import '../items/item.dart';

/// §4.6: how fast a person reads, in words a minute.
const double kWordsPerMinute = 220;

/// §4.6: and how many words are on a page.
const double kWordsPerPage = 280;

/// §4.6.1: what one page costs at the base rate — about seventy-six seconds.
Duration get kPageAtBaseRate =>
    Duration(milliseconds: (kWordsPerPage / kWordsPerMinute * 60000).round());

/// §8.4: what a Lounge takes off the time, per level.
///
/// ⚠️ Four per cent a level, twelve at the third — the same shape as every
/// other module figure and deliberately smaller than its own sleep bonus. §2.5
/// already makes the Lounge the room that buys time back by shortening a
/// night; this makes it buy time back inside the evening as well, which is
/// what a room with a chair and a lamp in it is actually for.
const double kLoungeReadingSpeed = 0.04;

/// §8.4: and the most it can ever be worth.
const double kLoungeReadingSpeedMax = 3 * kLoungeReadingSpeed;

/// What one copy of one title is.
///
/// ⚠️ Read off the item's own props rather than hard-coded per form: the five
/// forms of §4.6 differ only in numbers, and a sixth is a line of JSON.
class Book {
  const Book({
    required this.skill,
    required this.xpPerPage,
    required this.speedMultiplier,
    required this.pagesMin,
    required this.pagesMax,
  });

  /// Which of §7.1's four this teaches, or null for a story note (§19.1).
  final String? skill;

  /// §4.6.4: what a page is worth. Zero for a note, which is there to be read
  /// rather than farmed.
  final int xpPerPage;

  /// §4.6: how dense it is. A leaflet reads faster than an encyclopedia.
  final double speedMultiplier;

  final int pagesMin;
  final int pagesMax;

  /// The book this definition describes, or null when it is not literature.
  static Book? of(ItemDefinition? item) {
    if (item == null || item.kind != ItemKind.literature) return null;

    final props = item.props;
    double number(String key, double fallback) =>
        (props[key] as num?)?.toDouble() ?? fallback;

    return Book(
      skill: props['skill'] as String?,
      xpPerPage: number('xp_per_page', 0).round(),
      speedMultiplier: number('speed_multiplier', 1),
      pagesMin: number('pages_min', 1).round(),
      pagesMax: number('pages_max', 1).round(),
    );
  }

  /// §4.6.4: how long this copy is, rolled once when the copy is made.
  ///
  /// ⚠️ Per copy, not per title. Two manuals of the same title may be 180 and
  /// 340 pages — they weigh differently, read for different lengths and are
  /// worth different amounts, and that is the whole of §4.6.4.
  int rollPages(Random random) =>
      pagesMin +
      (pagesMax <= pagesMin ? 0 : random.nextInt(pagesMax - pagesMin + 1));

  /// §4.6, §8.4: what one page of this takes.
  ///
  /// [lounge] is the module's level, 0–3 (§8.4).
  Duration pageTime({int lounge = 0}) {
    final speed =
        speedMultiplier * (1 + kLoungeReadingSpeed * lounge.clamp(0, 3));
    if (speed <= 0) return kPageAtBaseRate;

    return Duration(
      milliseconds: (kPageAtBaseRate.inMilliseconds / speed).round(),
    );
  }

  /// §4.6.4: what a whole copy of [pages] takes.
  Duration timeFor(int pages, {int lounge = 0}) =>
      pageTime(lounge: lounge) * pages;

  /// §4.6.1, §4.6.3: what reading [pages] more of this copy pays.
  ///
  /// [copiesRead] is how many copies of this title have already been finished
  /// with — the second is worth a quarter and the third nothing at all, or a
  /// player farms chemists for the tenth first-aid manual (§4.6.3).
  int xpFor(int pages, {int copiesRead = 0}) =>
      (pages * xpPerPage * repeatShare(copiesRead)).round();
}

/// §4.6.3: what the nth copy of a title is worth, as a share.
///
/// ⚠️ Zero from the third, and that is not a rounding of "very little". A
/// player who can reach a hundred per cent of a skill by walking into ten
/// chemists has not read anything; the copies after the second are mass to be
/// dropped or recycled, and the rule says so.
double repeatShare(int copiesRead) => switch (copiesRead) {
  <= 0 => 1,
  1 => 0.25,
  _ => 0,
};
