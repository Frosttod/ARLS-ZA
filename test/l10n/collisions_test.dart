import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// DWA RÓŻNE POJĘCIA NIE MOGĄ MIEĆ JEDNEJ NAZWY (§12).
///
/// ⚠️ Found by a widget test that could not tell which of three "Magazyn"s it
/// had been handed. The shelter screen showed that word three times for two
/// different things — the shelves you put a rifle on, and the Storage module
/// that makes them bigger. English said "Shelves" and "Storage" and read
/// perfectly; only the Polish collided, so nothing but a Polish test could
/// have caught it.
///
/// The same class of mistake as calling the bench "Warsztat" next to the
/// Workshop module. Names are part of the interface, and two of them on one
/// screen meaning different things is a bug whatever the layout does.
void main() {
  Map<String, String> read(String language) {
    final raw = File('lib/l10n/app_$language.arb').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, Object?>;

    return {
      for (final entry in decoded.entries)
        if (!entry.key.startsWith('@') && entry.value is String)
          entry.key: entry.value! as String,
    };
  }

  /// Keys that stand next to each other on one screen and must therefore read
  /// as different things. Not every duplicate in the file is a bug — two
  /// screens can both say "Weź" — so this is a list of the places that share a
  /// surface, and it grows when a screen does.
  const together = <String, List<String>>{
    'the shelter screen': [
      'shelterTitle',
      'shelterShelves',
      'craftTitle',
      'moduleStorage',
      'moduleWorkshop',
      'moduleLounge',
      'moduleLab',
    ],
    'a weapon and its places': [
      'slotMagazine',
      'slotOptic',
      'slotBarrel',
      'slotGrip',
      'slotRail',
    ],
    'the pack row': [
      'inventoryUse',
      'inventoryWear',
      'inventoryDrop',
      'stashStore',
      'craftTakeApart',
      'magazineFill',
      'magazineEmpty',
    ],
  };

  for (final language in ['pl', 'en']) {
    group('$language reads without collisions', () {
      final strings = read(language);

      for (final entry in together.entries) {
        test('nothing on ${entry.key} is called what something else is', () {
          final byText = <String, List<String>>{};

          for (final key in entry.value) {
            final text = strings[key];
            if (text == null) continue;
            byText.putIfAbsent(text.toLowerCase(), () => []).add(key);
          }

          final clashes = [
            for (final row in byText.entries)
              if (row.value.length > 1)
                '"${row.key}" = ${row.value.join(', ')}',
          ];

          expect(
            clashes,
            isEmpty,
            reason:
                'these mean different things and say the same word:\n'
                '${clashes.join('\n')}',
          );
        });
      }
    });
  }

  test('both languages define the same keys', () {
    // A key that exists in one and not the other is a screen that falls back
    // to English mid-sentence, which is worse than either.
    final pl = read('pl').keys.toSet();
    final en = read('en').keys.toSet();

    expect(pl.difference(en), isEmpty, reason: 'only in Polish');
    expect(en.difference(pl), isEmpty, reason: 'only in English');
  });
}
