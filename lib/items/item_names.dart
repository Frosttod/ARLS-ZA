/// Item names, read from data rather than generated (§4.1, §1.1).
///
/// The rest of the app uses gen-l10n, which produces a typed getter per string.
/// That does not work here: an item name is looked up by a key the code has
/// never seen, and a content pack invents new ones after release. So names come
/// from a file, with the same lookup for bundled items and for packs.
library;

import 'dart:convert';

/// The bundled name table. Not in [kBundledItemAssets] — it holds names, not
/// items, and must never be parsed as a catalogue.
const String kItemNamesAsset = 'assets/data/names.json';

class ItemNames {
  const ItemNames(this._byKey);

  final Map<String, Map<String, String>> _byKey;

  static const ItemNames empty = ItemNames({});

  /// Shape: `{"names": {"item.x.name": {"pl": "...", "en": "..."}}}`.
  ///
  /// A malformed table is empty rather than fatal: an item shown by its id is
  /// ugly, an app that will not start is worse.
  factory ItemNames.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return empty;
    }
    if (decoded is! Map<String, Object?>) return empty;

    final raw = decoded['names'];
    if (raw is! Map<String, Object?>) return empty;

    return ItemNames({
      for (final entry in raw.entries)
        if (entry.value is Map<String, Object?>)
          entry.key: {
            for (final byLanguage in (entry.value! as Map<String, Object?>).entries)
              if (byLanguage.value is String)
                byLanguage.key: byLanguage.value! as String,
          },
    });
  }

  Iterable<String> get keys => _byKey.keys;

  /// The name in [language], or English, or nothing. Nothing is the honest
  /// answer: [ItemName.resolve] then falls back to whatever the item carries
  /// itself, which for a content pack is the inline name.
  String? lookup(String key, {required String language}) {
    final byLanguage = _byKey[key];
    if (byLanguage == null) return null;
    return byLanguage[language] ?? byLanguage['en'];
  }

  /// A lookup bound to one language, in the shape [ItemName.resolve] wants.
  String? Function(String key) forLanguage(String language) =>
      (key) => lookup(key, language: language);
}
