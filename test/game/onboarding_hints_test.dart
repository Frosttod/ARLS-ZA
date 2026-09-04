import 'package:arls_za/game/onboarding_hints.dart';
import 'package:test/test.dart';

/// §15.5, §3.5. Two rules that pull in opposite directions live in one class:
/// a first-contact hint is said once in the life of a character, and the dusk
/// reminder is said every evening for as long as the character lives.
void main() {
  group('§15.5: said once, and triggered by what happened', () {
    test('the map hint waits for a position, not for the app to start', () {
      const fresh = HintLog();

      expect(
        fresh.due(
          onMap: false,
          movedM: 0,
          lootInSight: false,
          zoneInSight: false,
        ),
        isEmpty,
      );
      expect(
        fresh.due(
          onMap: true,
          movedM: 0,
          lootInSight: false,
          zoneInSight: false,
        ),
        [Hint.map],
      );
    });

    test('and never comes back once it has been said', () {
      final said = const HintLog().take([Hint.map]);

      expect(
        said.due(
          onMap: true,
          movedM: 0,
          lootInSight: false,
          zoneInSight: false,
        ),
        isEmpty,
      );
    });

    test('the walk hint needs fifty metres and the map hint before it', () {
      // ⚠️ Order matters, and this is why. The fifty metres are measured from
      // where the player stood when the map appeared, so a character created
      // at the far end of a car journey has not walked them.
      const fresh = HintLog();
      expect(
        fresh.due(
          onMap: true,
          movedM: 400,
          lootInSight: false,
          zoneInSight: false,
        ),
        [Hint.map],
        reason: 'the walk hint cannot precede the thing it is measured from',
      );

      final onMap = fresh.take([Hint.map]);
      expect(
        onMap.due(
          onMap: true,
          movedM: kFirstWalkM - 1,
          lootInSight: false,
          zoneInSight: false,
        ),
        isEmpty,
      );
      expect(
        onMap.due(
          onMap: true,
          movedM: kFirstWalkM,
          lootInSight: false,
          zoneInSight: false,
        ),
        [Hint.walk],
      );
    });

    test('loot and a zone in sight can both be owed at once', () {
      final onMap = const HintLog().take([Hint.map]);

      expect(
        onMap.due(onMap: true, movedM: 0, lootInSight: true, zoneInSight: true),
        [Hint.loot, Hint.zone],
      );
    });
  });

  group('§3.5: the dusk reminder is the one that comes back', () {
    final dusk = DateTime(2026, 9, 4, 19, 30);

    test('inside the hour after dusk, and not before it', () {
      const log = HintLog();

      expect(
        log.duskDue(now: dusk.subtract(const Duration(minutes: 1)), dusk: dusk),
        isFalse,
      );
      expect(log.duskDue(now: dusk, dusk: dusk), isTrue);
      expect(
        log.duskDue(now: dusk.add(const Duration(minutes: 59)), dusk: dusk),
        isTrue,
      );
    });

    test('and not at midnight, when saying it helps nobody', () {
      expect(
        const HintLog().duskDue(
          now: dusk.add(const Duration(hours: 4)),
          dusk: dusk,
        ),
        isFalse,
      );
    });

    test('once a day — but again tomorrow', () {
      final said = const HintLog().saidDusk(dusk);

      expect(
        said.duskDue(now: dusk.add(const Duration(minutes: 5)), dusk: dusk),
        isFalse,
      );

      final tomorrow = dusk.add(const Duration(days: 1));
      expect(said.duskDue(now: tomorrow, dusk: tomorrow), isTrue);
    });

    test('a sky with no dusk in it owes nothing', () {
      expect(const HintLog().duskDue(now: dusk, dusk: null), isFalse);
    });
  });

  group('the log survives a restart', () {
    test('what was said, and the evening it was said on', () {
      final log = const HintLog()
          .take([Hint.map, Hint.walk])
          .saidDusk(DateTime(2026, 9, 4, 19, 30));

      final back = HintLog.parse(log.wire);

      expect(back.has(Hint.map), isTrue);
      expect(back.has(Hint.walk), isTrue);
      expect(back.has(Hint.loot), isFalse);
      expect(back.duskSaidOn, DateTime(2026, 9, 4));
    });

    test('and a row that is nonsense costs a hint, not a boot', () {
      // ⚠️ A save that cannot be read is a player who sees the first-day lines
      // twice. That is irritating; refusing to start is worse.
      for (final wire in [null, '', 'nonsense', '|', 'map|not-a-date']) {
        expect(() => HintLog.parse(wire), returnsNormally, reason: '$wire');
      }
      expect(HintLog.parse('map|not-a-date').has(Hint.map), isTrue);
      expect(HintLog.parse('map|not-a-date').duskSaidOn, isNull);
    });
  });
}
