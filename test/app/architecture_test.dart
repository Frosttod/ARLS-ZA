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
      //
      // ⚠️ Lower it when a phase lands. Never raise it — not for a phase, and
      // not for a feature either. "It is a feature" is exactly the excuse that
      // took this file to seven thousand lines: every one of those was a
      // reasonable thing to add to the class that already had everything else.
      // Something new that belongs to the model goes in the model.
      expect(
        lines,
        lessThanOrEqualTo(6638),
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
}
