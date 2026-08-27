import 'dart:io';

import 'package:test/test.dart';

/// KIERUNEK ZALEŻNOŚCI, PILNOWANY W ŹRÓDLE.
///
/// ⚠️ **A rule nobody can break by accident is worth more than a rule everyone
/// agrees with.** `_TitleScreenState` did not become six and a half thousand
/// lines because anybody decided it should. It grew a field at a time, and
/// every one of those was a reasonable thing to add to the class that already
/// had everything else.
///
/// So the shape is held here, as it is being made, rather than written down
/// somewhere and hoped for. Each phase of the migration adds its line to this
/// file, and the file is what stops the next phase from undoing the last.
///
/// The direction is: `ui → controllers → {sim, data}`. A controller that
/// imports `material.dart` is the God class again with a smaller file name.
void main() {
  List<File> dartFilesIn(String directory) {
    final dir = Directory(directory);
    if (!dir.existsSync()) return const [];

    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
  }

  List<String> importsOf(File file) => file
      .readAsLinesSync()
      .where((line) => line.startsWith('import '))
      .toList();

  group('the pure layers stay pure', () {
    test('lib/sim knows nothing about Flutter', () {
      // ⚠️ This is the boundary that has held from the start and is the reason
      // the physiology can be tested at all. §2's whole model runs in a plain
      // Dart test with no binding, no widgets and no pump.
      for (final file in dartFilesIn('lib/sim')) {
        for (final line in importsOf(file)) {
          expect(
            line.contains('package:flutter/material.dart') ||
                line.contains('package:flutter/widgets.dart'),
            isFalse,
            reason: '${file.path} reaches into the interface',
          );
        }
      }
    });

    test('and it never reaches back up into the game or the screen', () {
      for (final file in dartFilesIn('lib/sim')) {
        for (final line in importsOf(file)) {
          expect(
            line.contains("'../ui/") || line.contains("'../app/"),
            isFalse,
            reason: '${file.path} depends on what depends on it',
          );
        }
      }
    });
  });

  group('the app layer is a door, not a house', () {
    test('nothing in lib/app imports the game', () {
      // Bootstrap knows there is a first screen and that it will be handed the
      // player's settings. What the first screen *is* arrives as an argument —
      // which is what stops this from becoming the second file that imports
      // everything.
      for (final file in dartFilesIn('lib/app')) {
        for (final line in importsOf(file)) {
          expect(
            line.contains("'../main.dart'"),
            isFalse,
            reason: '${file.path} would make a cycle out of the entry point',
          );
        }
      }
    });

    test('and no screen imports main.dart', () {
      // The title screen still lives there. A screen in lib/ui reaching back
      // for it would make a cycle out of a one-way street — which is why the
      // intro film is *given* what comes after it.
      for (final file in dartFilesIn('lib/ui')) {
        for (final line in importsOf(file)) {
          expect(
            line.contains("'../main.dart'"),
            isFalse,
            reason: '${file.path} reaches back into the entry point',
          );
        }
      }
    });
  });

  group('controllers stay controllers', () {
    // ⚠️ The rule the whole exercise rests on. A controller that can reach a
    // widget is a controller that will end up holding one, and then it cannot
    // be tested without a binding, a pump and a running game — which is the
    // state `_TitleScreenState` is in and the reason this is happening.
    test('nothing in lib/game/controllers imports the interface', () {
      for (final file in dartFilesIn('lib/game/controllers')) {
        for (final line in importsOf(file)) {
          expect(
            line.contains('package:flutter/material.dart') ||
                line.contains('package:flutter/widgets.dart'),
            isFalse,
            reason: '${file.path} can reach a widget',
          );
        }
      }
    });

    test('and none of them knows another', () {
      // Where one genuinely needs another — a bench spends off the shelves and
      // then the pack (§18.2) — the thing that needs both asks both. The
      // moment a controller imports a neighbour, moving either means moving
      // both.
      final files = dartFilesIn('lib/game/controllers');
      expect(files, isNotEmpty, reason: 'the phase moved nothing');

      for (final file in files) {
        for (final line in importsOf(file)) {
          expect(
            line.contains("_controller.dart") &&
                !line.contains(file.uri.pathSegments.last),
            isFalse,
            reason: '${file.path} depends on a sibling',
          );
        }
      }
    });
  });

  group('what is left in main.dart', () {
    final main = File('lib/main.dart').readAsStringSync();
    final lines = main.split('\n').length;

    test('it is shrinking, and this is the ratchet', () {
      // ⚠️ A number, deliberately, and it comes down with every phase. The
      // point is not the figure — it is that a phase which puts code *back*
      // fails here instead of being noticed a month later.
      //
      //   start   7088
      //   phase 1 6876   scaffolding out
      //   phase 2 6824   the pack and the shelves out
      //   phase 3 6809   the loot, the ground and the bodies out
      //   phase 4 6767   the bench and the shelters out
      //   phase 5 6711   five clocks became one, and the action state with it
      //   phase 6 6667   the fight out
      //           6659   the disassembly list became a function of the model
      //           6658   the bench refusal stopped being written twice
      //           6638   finding a step's piece, and asking the price of one
      //           6629   the strip's warnings, the labels, the search rules
      //           6627   the cancel dialog stopped being written twice
      //           6611   one busy guard instead of ten copies of it
      //           6601   how warm the street is became a rule, not a screen
      //           6551   what goes on the map became a rule too (§6.5)
      //           6541   the hotspots settle themselves, and a circle says
      //                  what it is and how to take it down (§6.5.6)
      //           6530   the journal, and the pile that knew how to be a line
      //           6526   one way onto a shelf, and one name for home; and
      //                  the sky says when, not only how long (§17.2)
      //           6463   the fight panel became a reading, not forty
      //                  arguments assembled in a build method (§5.5.1)
      //           6463   the start screen and the game screen out, and
      //                  a book can finally be opened (§4.6, faza 8)
      //           6439   the tester's kit became a table in lib/dev, and
      //                  the fight stopped rebuilding one point nine times
      //           6434   the controllers are bound by a list, not by forty
      //                  lines of `_enter` (§16.4, faza B)
      //
      // ⚠️ Lower it when a phase lands. Never raise it — not for a phase, and
      // not for a feature either. "It is a feature" is exactly the excuse that
      // took this file to seven thousand lines: every one of those was a
      // reasonable thing to add to the class that already had everything else.
      // Something new that belongs to the model goes in the model.
      expect(
        lines,
        lessThanOrEqualTo(6434),
        reason: 'main.dart grew; something went in that should have come out',
      );
    });

    test('the entry point does not build the interface any more', () {
      // `main()` is now four lines and a wiring diagram. Everything it used to
      // do — the zone, the binding, the MaterialApp, the theme — lives in
      // lib/app/bootstrap.dart.
      expect(main.contains('MaterialApp('), isFalse);
      expect(main.contains('runGuarded('), isTrue);
    });
  });

  test('the checklist does not lie about the schema (§11.1.4)', () {
    // ⚠️ **A document nobody can check is a document that drifts.** The
    // checklist is pointed at as the source of truth for what is covered, and
    // it spent five schema versions claiming v29. The test count in it cannot
    // be checked from inside the suite — a test does not know the total — but
    // the schema version can, and it is the half that matters: it says which
    // migrations are proven.
    final checklist = File('CHECKLIST.md').readAsStringSync();
    final database = File('lib/data/db/database.dart').readAsStringSync();

    final version = RegExp(
      r'const int kSchemaVersion = (\d+);',
    ).firstMatch(database)!.group(1);

    expect(
      checklist.contains('schemat bazy v$version'),
      isTrue,
      reason: 'CHECKLIST.md is behind the schema; it now says v$version',
    );
    expect(
      checklist.contains('v$version, z danymi'),
      isTrue,
      reason: 'the migration line in CHECKLIST.md is behind as well',
    );
  });

  group('and the next one is stopped before it starts', () {
    // ⚠️ **A file with no brake becomes main.dart.** The entry point did not
    // reach seven thousand lines because anybody decided it should; it grew a
    // field at a time, every one of them reasonable, and by the time it was
    // obviously a problem it was a fortnight of work to undo. These two are
    // the biggest files left, and this is the only cheap moment to say so.
    //
    // ⚠️ Same rule as the ratchet above: lower these when something lands.
    // Never raise them. "It is a feature" is the excuse that built the first
    // one.
    for (final (path, cap) in [
      // The pack: rows, actions, the disassembly list, the stepper, the
      // details sheet's neighbour. A screen, but five screens' worth of one.
      ('lib/ui/inventory_screen.dart', 1679),

      // The loop is coherent and earns its length — the clock, the zone, the
      // sampling policy and §11.1's writer all meet here. It is on the list
      // because coherent files grow too.
      ('lib/game/game_loop.dart', 1255),
    ]) {
      test('$path is not the next main.dart', () {
        final lines = File(path).readAsLinesSync().length;

        expect(
          lines,
          lessThanOrEqualTo(cap),
          reason: '$path grew; something in it belongs somewhere else',
        );
      });
    }
  });
}
