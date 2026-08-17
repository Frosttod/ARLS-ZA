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
    test('a shop has a door, and so does a car', () {
      // A bin is open, a bus shelter is open, and a car is locked far more
      // often than either — §19.3's own thirty-five per cent already open is
      // about right for a door somebody left in a hurry.
      expect(tables['poi_pharmacy']!.barrier, Barrier.door);
      expect(tables['poi_grocery']!.barrier, Barrier.door);
      expect(tables['proc_abandoned_car']!.barrier, Barrier.door);

      expect(tables['proc_waste']!.barrier, isNull);
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

  group('how long a place takes to turn over (§10.3.5)', () {
    test('a bin is not a supermarket', () {
      // ⚠️ §10.3.5 gives one set of times for everything, and on a walk that
      // reads as nonsense: three minutes over a wheelie bin, the same three
      // minutes as a shop.
      final bin = tables['proc_waste']!;
      final shop = tables['poi_grocery']!;

      expect(bin.searchTime(SearchDepth.deep).inSeconds, lessThan(40));
      expect(shop.searchTime(SearchDepth.deep).inSeconds, 180);
    });

    test('and a car sits between them', () {
      // The figure asked for after a walk: a thorough look through a car is a
      // minute and a half, not three.
      final car = tables['proc_abandoned_car']!;

      expect(car.searchTime(SearchDepth.shallow).inSeconds, 15);
      expect(car.searchTime(SearchDepth.deep).inSeconds, 90);
    });

    test('nothing is quicker than five seconds', () {
      // Below that it stops being an action somebody decided to take and
      // becomes a button with a flicker on it.
      for (final table in tables.tables) {
        for (final depth in SearchDepth.values) {
          expect(
            table.searchTime(depth).inSeconds,
            greaterThanOrEqualTo(5),
            reason: '${table.id} ${depth.name}',
          );
        }
      }
    });

    test('depth still buys depth, whatever the place', () {
      // The multiplier is on the time, never on what comes out. A bin searched
      // thoroughly is still a bin searched thoroughly.
      final bin = tables['proc_waste']!;

      expect(
        bin.searchTime(SearchDepth.deep),
        greaterThan(bin.searchTime(SearchDepth.shallow)),
      );
      expect(SearchDepth.deep.tiers.length, greaterThan(
        SearchDepth.shallow.tiers.length,
      ));
    });
  });

  group('a padlock and the tools for it (§19.3)', () {
    test('bolt cutters are fast and loud, picks are slow and quiet', () {
      // ⚠️ The tool this barrier was written for did not exist: a padlock
      // could only be levered at with a crowbar or worried at with a saw.
      final quiet = Barrier.padlock.quiet!;
      final cut = Barrier.padlock.pry!;

      expect(cut.toolIds, contains('tool_bolt_cutters'));
      expect(cut.seconds, lessThan(quiet.seconds));
      expect(cut.noiseM, greaterThan(quiet.noiseM));
    });

    test('and shoulders still do nothing to one', () {
      // §19.3 names the padlock as the barrier that needs a tool, and
      // softening that would make every tool in the catalogue optional.
      for (final way in Barrier.padlock.breachesWith(const {})) {
        fail('a padlock opened with nothing: ${way.seconds} s');
      }
    });
  });
}
