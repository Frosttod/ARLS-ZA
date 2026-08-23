import 'dart:io';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';

void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());
  final book = checkedAgainst(
    RecipeBook.parse(File(kRecipesAsset).readAsStringSync()),
    catalogue,
  );

  String nameOf(String id) =>
      names.lookup('item.$id.name', language: 'pl') ?? id;

  final rows = <List<String>>[];
  for (final item in catalogue.all) {
    final content = materialContent(item, book);
    if (content.isEmpty) continue;

    final back = salvageOf(item, book);
    final skilled = salvageOf(
      item,
      book,
      share: salvageShare(engineering: 1, workshopLevel: 2),
    );
    final time = salvageTime(content);

    String said(Map<String, int> m) => m.isEmpty
        ? '—'
        : (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .map((e) => '${nameOf(e.key)} ×${e.value}')
              .join(', ');

    rows.add([
      item.kind.name,
      nameOf(item.id),
      '${item.weightKg}',
      said(back),
      said(skilled),
      '${time.inMinutes}',
    ]);
  }

  rows.sort((a, b) {
    final k = a[0].compareTo(b[0]);
    return k != 0 ? k : a[1].compareTo(b[1]);
  });

  for (final r in rows) {
    print(r.join('\t'));
  }
}
