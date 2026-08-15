import 'dart:io';

import 'package:arls_za/notes/note.dart';
import 'package:test/test.dart';

/// §19.1. Notes are the only evidence in the game that anybody lived here, and
/// they are worth the trouble for one reason: they are attached to real places
/// in the player's own city. That makes the editorial rules of §19.1.2 part of
/// the software, not a style guide — including the two that exist to protect
/// somebody walking alone through a real street in the evening.
void main() {
  final notes = NoteSet.parse(File('assets/data/notes.json').readAsStringSync());

  group('the shipped notes', () {
    test('parse without a fault', () {
      expect(notes.problems, isEmpty, reason: notes.problems.join('\n'));
      expect(notes.notes, hasLength(16));
    });

    test('every one exists in both languages', () {
      for (final note in notes.notes) {
        for (final language in const ['pl', 'en']) {
          expect(note.title[language], isNotNull, reason: note.id);
          expect(note.text[language], isNotNull, reason: note.id);
        }
      }
    });

    test('are short enough to read standing up (§19.1.2)', () {
      // Three to eight sentences. A note is read in half a minute; anything
      // longer is a chapter, and nobody reads a chapter in a street.
      for (final note in notes.notes) {
        for (final body in note.text.values) {
          final sentences = body.split(RegExp(r'[.!?]')).where(
            (part) => part.trim().length > 2,
          );
          expect(sentences.length, inInclusiveRange(3, 8), reason: note.id);
        }
      }
    });

    test('a lead is a discovery, not the normal case (§19.1.3)', () {
      final leads = notes.notes.where((note) => note.hasLead);

      expect(leads, hasLength(3));
    });

    test('every one can be found somewhere', () {
      // A note matching nothing is a note nobody reads.
      const known = {
        'poi.subclass=pharmacy',
        'poi.subclass=chemist',
        'poi.class=police',
        'poi.subclass=supermarket',
        'poi.subclass=convenience',
        'poi.subclass=school',
        'poi.subclass=college',
        'poi.class=hospital',
        'poi.subclass=shelter',
        'poi.subclass=parking',
        'poi.subclass=car_repair',
        'poi.subclass=residential',
        'landuse.class=garages',
        'generated.house',
        'generated.barn',
        'generated.roadside',
      };

      for (final note in notes.notes) {
        expect(note.match, isNotEmpty, reason: note.id);
        for (final selector in note.match) {
          expect(known, contains(selector), reason: '${note.id}: $selector');
        }
      }
    });
  });

  group('§19.1.1\'s inflection trap', () {
    test('every Polish placeholder stands in the nominative', () {
      // OSM returns "Naramowicka" and Polish would want "z Naramowickiej".
      // Automatic inflection of proper names is unreliable, so the sentence is
      // built around the constraint instead: "ulica {street}", never
      // "z {street}". This is the check that keeps that discipline.
      const prepositions = [
        'z',
        'ze',
        'do',
        'od',
        'przy',
        'na',
        'w',
        'we',
        'obok',
        'koło',
        'pod',
        'nad',
      ];

      for (final note in notes.notes) {
        final polish = note.text['pl'];
        if (polish == null) continue;

        for (final preposition in prepositions) {
          expect(
            polish.toLowerCase(),
            isNot(contains(' $preposition {')),
            reason: '${note.id}: "$preposition {…}" would need a case OSM '
                'does not give us',
          );
        }
      }
    });

    test('a note is only told when its placeholders can be filled', () {
      final withStreet = notes.notes.firstWhere(
        (note) => note.placeholders.contains('street'),
      );

      expect(withStreet.canBeToldWith(PlaceNames.none), isFalse);
      expect(
        withStreet.canBeToldWith(const PlaceNames(street: 'Naramowicka')),
        isTrue,
      );
    });

    test('and a note needing nothing is always tellable', () {
      final plain = notes.notes.firstWhere(
        (note) => note.placeholders.isEmpty,
      );

      expect(plain.canBeToldWith(PlaceNames.none), isTrue);
    });
  });

  group('telling one', () {
    test('the map\'s names go where the placeholders were', () {
      final set = NoteSet.parse('''
        {"schema": 1, "notes": [{
          "id": "n", "match": [],
          "title": {"pl": "T"},
          "text": {"pl": "zgłoszenie, ulica {street}, {city}"}
        }]}
      ''');

      expect(
        set.notes.single.textIn(
          'pl',
          const PlaceNames(street: 'Naramowicka', city: 'Poznań'),
        ),
        'zgłoszenie, ulica Naramowicka, Poznań',
      );
    });

    test('an unknown language falls back rather than showing nothing', () {
      final note = notes.notes.first;

      expect(note.textIn('de', PlaceNames.none), note.text['en']);
    });
  });

  group('picking one for a place', () {
    const names = PlaceNames(
      street: 'Naramowicka',
      district: 'Naramowice',
      city: 'Poznań',
    );

    test('a pharmacy gets a pharmacy note', () {
      final note = notes.forPlace(
        selectors: const ['poi.subclass=pharmacy'],
        names: names,
        seed: 1,
      );

      expect(note, isNotNull);
      expect(note!.match, contains('poi.subclass=pharmacy'));
    });

    test('the same place tells the same note every time', () {
      // A message that changed between readings would stop being somebody's
      // message.
      Note? pick() => notes.forPlace(
        selectors: const ['poi.class=police'],
        names: names,
        seed: 4242,
      );

      expect(pick()!.id, pick()!.id);
    });

    test('a place with no note at all gets nothing rather than a wrong one', () {
      expect(
        notes.forPlace(
          selectors: const ['poi.subclass=weapons'],
          names: names,
          seed: 1,
        ),
        isNull,
      );
    });

    test('and nothing needing a street where the map has no streets', () {
      // Measured: the packs already built carry no transportation_name layer,
      // so street names are simply absent. §19.1.1 says such notes are not
      // drawn, rather than shown with the placeholder in them.
      final picked = notes.forPlace(
        selectors: const ['poi.class=police'],
        names: PlaceNames.none,
        seed: 1,
      );

      expect(picked?.placeholders.contains('street'), isNot(isTrue));
    });
  });
}
