import 'dart:io';

import 'package:arls_za/items/item_catalogue.dart';
import 'package:test/test.dart';

/// BAZA PRZEDMIOTÓW NIE ODJEŻDŻA OD GRY.
///
/// ⚠️ **A generated document is only worth what its freshness is worth.**
///
/// `item_base.md` exists to be read by a person checking whether the numbers
/// are believable — a tin of meat that weighs four kilograms, a knife that
/// takes longer to come apart than a rifle. That check is worthless against a
/// table describing last month's game, and there is nothing in a markdown file
/// that says how old it is.
///
/// So the test holds the document against the catalogue: every item the game
/// knows must appear in it. Adding an item and forgetting to regenerate fails
/// here rather than being noticed by somebody reviewing a list with a hole in
/// it.
///
/// The fix when this goes red is one command:
///
///     dart run tool/item_base.dart
void main() {
  final doc = File('item_base.md');

  test('the document exists at all', () {
    expect(
      doc.existsSync(),
      isTrue,
      reason: 'run: dart run tool/item_base.dart',
    );
  });

  test('every item in the game is in it', () {
    final catalogue = ItemCatalogue.load([
      for (final asset in kBundledItemAssets)
        ItemSource(asset, File(asset).readAsStringSync()),
    ]);

    final text = doc.readAsStringSync();

    final missing = [
      for (final item in catalogue.all)
        if (!text.contains('`${item.id}`')) item.id,
    ];

    expect(
      missing,
      isEmpty,
      reason:
          'the document is out of date — run: dart run tool/item_base.dart\n'
          'missing: ${missing.take(10).join(', ')}',
    );
  });

  test('and it says it is generated, so nobody edits it by hand', () {
    // ⚠️ Somebody *will* try. A file full of numbers worth arguing about is a
    // file somebody corrects in place, and the next run silently throws that
    // away — so the warning is the first thing on the page.
    final head = doc.readAsLinesSync().take(5).join('\n');

    expect(head, contains('generowany'));
    expect(head, contains('tool/item_base.dart'));
  });

  test('every kind of item gets a section of its own', () {
    // The generator used to have a default case, and two different kinds fell
    // into it — so the document had two sections both called "Pozostałe" and a
    // reader had no way to tell which was which.
    final headings = doc
        .readAsLinesSync()
        .where((line) => line.startsWith('## '))
        .toList();

    expect(
      headings.length,
      headings.toSet().length,
      reason: 'two sections share a name: ${headings.join(', ')}',
    );
  });
}
