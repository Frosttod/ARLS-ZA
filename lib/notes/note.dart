/// The people who were here before (§19.1).
///
/// The world otherwise contains enemies, items and buildings, and no evidence
/// that anybody ever lived in it. Notes are the cheapest possible fix because
/// they reuse the literature of §4.6 and cost no mechanics at all: no XP, one
/// to three grams, thirty seconds to read.
///
/// What makes them worth the trouble is the one advantage this game has over
/// every game set on an invented map: the note is at a real place in the
/// player's own city. The bus stop they pass on the way to work is where
/// somebody left a message.
///
/// **The text lives in the data file, not in the ARB.** A deliberate exception
/// to §1.1: a note is a piece of writing rather than an interface label, and a
/// translation key per paragraph of prose is unmaintainable.
library;

import 'dart:convert';
import 'dart:math';

/// Names taken from the map around the player, used to fill a note in.
///
/// Any of them may be missing — OSM does not name every street and few areas
/// carry a district — and §19.1.1 is explicit about what happens then: a note
/// whose placeholder cannot be filled is not drawn at all. Printing "ulica
/// {street}" at somebody is worse than printing nothing.
class PlaceNames {
  const PlaceNames({this.street, this.district, this.city});

  final String? street;
  final String? district;
  final String? city;

  static const PlaceNames none = PlaceNames();

  String? operator [](String placeholder) => switch (placeholder) {
    'street' => street,
    'district' => district,
    'city' => city,
    _ => null,
  };
}

/// One piece of writing, in every language it has been written in.
class Note {
  const Note({
    required this.id,
    required this.category,
    required this.match,
    required this.rarity,
    required this.hasLead,
    required this.title,
    required this.text,
  });

  final String id;

  /// What kind of thing it is: a note on a door, a diary, a duty log. Carried
  /// for §19.5 and for anything that later wants to weight one kind over
  /// another.
  final String category;

  /// Where it can be found, in the same selector vocabulary the loot tables
  /// use (`poi.subclass=pharmacy`). Empty means anywhere.
  final List<String> match;

  final String rarity;

  /// §19.1.3: reveals a point on the map. Three of sixteen in the draft, and
  /// that proportion is the intent — a lead should be a discovery rather than
  /// the normal case.
  final bool hasLead;

  final Map<String, String> title;
  final Map<String, String> text;

  /// Which placeholders this note needs filled, in the order they appear.
  Set<String> get placeholders => {
    for (final body in text.values)
      ...RegExp(r'\{(\w+)\}')
          .allMatches(body)
          .map((match) => match.group(1)!),
  };

  /// Whether [names] can fill every placeholder this note uses (§19.1.1).
  bool canBeToldWith(PlaceNames names) =>
      placeholders.every((placeholder) => names[placeholder] != null);

  /// Whether a place with these selectors could hold this note.
  bool belongsAt(Iterable<String> selectors) {
    if (match.isEmpty) return true;
    final wanted = selectors.toSet();
    return match.any(wanted.contains);
  }

  String titleIn(String language) =>
      title[language] ?? title['en'] ?? title.values.firstOrNull ?? id;

  /// The note as the player reads it, with the map's names in place.
  String textIn(String language, PlaceNames names) {
    final body = text[language] ?? text['en'] ?? text.values.firstOrNull ?? '';

    return body.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
      // Only ever reached for a note that passed [canBeToldWith]; leaving the
      // placeholder visible is the least bad thing to do if it is not.
      return names[match.group(1)!] ?? match.group(0)!;
    });
  }
}

class NoteSet {
  const NoteSet(this.notes, this.problems);

  final List<Note> notes;
  final List<String> problems;

  bool get isClean => problems.isEmpty;

  Note? operator [](String id) =>
      notes.where((note) => note.id == id).firstOrNull;

  /// Picks a note for a place, or null where nothing fits.
  ///
  /// Deterministic from [seed], so the note at a given place is the same note
  /// every time somebody looks — a message that changed between readings would
  /// stop being somebody's message.
  Note? forPlace({
    required Iterable<String> selectors,
    required PlaceNames names,
    required int seed,
  }) {
    final candidates = notes
        .where((note) => note.belongsAt(selectors) && note.canBeToldWith(names))
        .toList();
    if (candidates.isEmpty) return null;

    return candidates[Random(seed).nextInt(candidates.length)];
  }

  factory NoteSet.parse(String source, {String origin = 'notes'}) {
    final problems = <String>[];

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      return NoteSet(const [], ['$origin: not valid JSON: ${error.message}']);
    }
    if (decoded is! Map<String, Object?>) {
      return NoteSet(const [], ['$origin: expected an object']);
    }

    final raw = decoded['notes'];
    if (raw is! List) {
      return NoteSet(const [], ['$origin: "notes" must be a list']);
    }

    final notes = <Note>[];
    final seen = <String>{};

    for (var index = 0; index < raw.length; index++) {
      final entry = raw[index];
      if (entry is! Map<String, Object?>) {
        problems.add('$origin[$index]: not an object');
        continue;
      }

      final id = entry['id'];
      if (id is! String || id.isEmpty) {
        problems.add('$origin[$index]: missing "id"');
        continue;
      }
      if (!seen.add(id)) {
        problems.add('$id: duplicate id');
        continue;
      }

      final title = _byLanguage(entry['title']);
      final text = _byLanguage(entry['text']);
      if (title.isEmpty) problems.add('$id: no title in any language');
      if (text.isEmpty) problems.add('$id: no text in any language');
      if (title.isEmpty || text.isEmpty) continue;

      notes.add(
        Note(
          id: id,
          category: entry['category'] as String? ?? 'dziennik',
          match: [
            for (final selector in (entry['match'] as List? ?? const []))
              if (selector is String) selector,
          ],
          rarity: entry['rarity'] as String? ?? 'common',
          hasLead: entry['has_lead'] == true,
          title: title,
          text: text,
        ),
      );
    }

    return NoteSet(notes, problems);
  }

  static Map<String, String> _byLanguage(Object? raw) => raw
          is Map<String, Object?>
      ? {
          for (final entry in raw.entries)
            if (entry.value is String && (entry.value! as String).isNotEmpty)
              entry.key: entry.value! as String,
        }
      : const {};
}
