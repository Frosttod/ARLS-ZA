import 'dart:io';

import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/obstacle.dart';
import 'package:test/test.dart';

/// §19.3. Barriers exist so that tools mean something outside crafting: a
/// crowbar is not a recipe ingredient, it is the difference between a shop you
/// can enter and one you cannot. What is tested is that the choice is real —
/// loud and fast against quiet and slow — and that nothing is impassable except
/// the one thing the doc says is.
void main() {
  final tables = LootTableSet.parse(
    File('assets/data/loot_tables.json').readAsStringSync(),
  );

  group('the ways through', () {
    test('a door opens to shoulders, a crowbar, or picks', () {
      expect(Barrier.door.breachesWith(const {}), hasLength(1));
      expect(Barrier.door.breachesWith(const {'melee_crowbar'}), hasLength(2));
      expect(
        Barrier.door.breachesWith(const {'tool_lockpicks', 'melee_crowbar'}),
        hasLength(3),
      );
    });

    test('a padlock needs a tool, as §19.3 says', () {
      // The one barrier that is impassable empty-handed. Softening it would
      // make every tool in the catalogue optional.
      expect(Barrier.padlock.blocks(const {}), isTrue);
      expect(Barrier.padlock.blocks(const {'melee_crowbar'}), isFalse);
      expect(Barrier.padlock.blocks(const {'tool_lockpicks'}), isFalse);
    });

    test('a window always gives way, and always costs the same', () {
      // The way in that exists for a player who owns nothing.
      expect(Barrier.window.blocks(const {}), isFalse);
      expect(Barrier.window.force!.noiseM, 150);
    });

    test('forcing a door is §5.6.1\'s 150 metres', () {
      expect(Barrier.door.force!.noiseM, 150);
    });

    test('quiet is slower, and that is the whole decision', () {
      final quiet = Barrier.door.quiet!;
      final force = Barrier.door.force!;

      expect(quiet.noiseM, lessThan(force.noiseM));
      expect(quiet.seconds, greaterThan(force.seconds));
    });

    test('the quiet way is offered first', () {
      // The loud option is always available and always obvious; somebody
      // deciding in the dark should meet the careful one first.
      expect(
        Barrier.door.breachesWith(const {'tool_lockpicks', 'melee_crowbar'}),
        [Barrier.door.quiet, Barrier.door.pry, Barrier.door.force],
      );
    });

    test('picks open everything that can be opened quietly', () {
      for (final barrier in Barrier.values) {
        final quiet = barrier.quiet;
        if (quiet == null) continue;
        expect(quiet.toolIds, contains('tool_lockpicks'), reason: '$barrier');
      }
    });
  });

  group('what the shipped tables are shut with', () {
    test('a shop has a door and a car park has nothing', () {
      expect(tables['poi_pharmacy']!.barrier, Barrier.door);
      expect(tables['poi_grocery']!.barrier, Barrier.door);
      expect(tables['proc_abandoned_car']!.barrier, isNull);
      expect(tables['proc_shelter']!.barrier, isNull);
    });

    test('the places worth the most are the hardest to get into', () {
      // A padlock cannot be got past without a tool, so the tables behind one
      // are exactly the ones a player should have to prepare for.
      expect(tables['poi_military']!.barrier, Barrier.padlock);
      expect(tables['poi_warehouse']!.barrier, Barrier.padlock);
      expect(tables['proc_garage']!.barrier, Barrier.padlock);
    });

    test('an abandoned house is entered through the glass', () {
      expect(tables['proc_abandoned_house']!.barrier, Barrier.window);
    });

    test('every barrier named in the file is one the game knows', () {
      // A typo would silently leave a place unlocked.
      for (final table in tables.tables) {
        final barrier = table.barrier;
        if (barrier == null) continue;
        expect(Barrier.values, contains(barrier), reason: table.id);
      }
    });

    test('nothing is locked that a player has no way into', () {
      // Every barrier on a shipped table has to be passable by somebody who
      // owns nothing, or by somebody who owns a crowbar — the commonest tool
      // in the catalogue.
      for (final table in tables.tables) {
        final barrier = table.barrier;
        if (barrier == null) continue;
        expect(
          barrier.blocks(const {'melee_crowbar'}),
          isFalse,
          reason: '${table.id} cannot be entered with a crowbar',
        );
      }
    });
  });
}
