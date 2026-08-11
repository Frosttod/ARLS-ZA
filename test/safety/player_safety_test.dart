import 'package:arls_za/safety/player_safety.dart';
import 'package:test/test.dart';

/// §3.5. These are not balance rules and they do not bend: the game is sending
/// somebody into traffic with a phone in their hand.
void main() {
  group('combat above walking pace (§3.5)', () {
    test('walking and running are fine', () {
      expect(combatBlock(speedKmh: 5, runSuspended: false), CombatBlock.none);
      expect(
        combatBlock(speedKmh: 14, runSuspended: false),
        CombatBlock.none,
        reason: 'a sprint is still a person on foot',
      );
    });

    test('past fifteen the game refuses', () {
      expect(
        combatBlock(speedKmh: 15.1, runSuspended: false),
        CombatBlock.movingTooFast,
      );
      expect(
        combatBlock(speedKmh: 40, runSuspended: false),
        CombatBlock.movingTooFast,
      );
    });

    test('the limit itself is not over it', () {
      expect(
        combatBlock(speedKmh: kCombatSpeedLimitKmh, runSuspended: false),
        CombatBlock.none,
      );
    });

    test('a suspended run outranks the speed', () {
      // Standing still with a mock provider running is still not a fight, and
      // the player needs to hear the real reason (§3.4).
      expect(
        combatBlock(speedKmh: 0, runSuspended: true),
        CombatBlock.runSuspended,
      );
    });
  });

  group('the safety briefing', () {
    test('an unread briefing has to be shown', () {
      expect(briefingAccepted(null), isFalse);
    });

    test('the current version counts as read', () {
      expect(briefingAccepted('$kSafetyBriefingVersion'), isTrue);
    });

    test('an older acceptance does not carry over a rewrite', () {
      expect(
        briefingAccepted('${kSafetyBriefingVersion - 1}'),
        isFalse,
        reason: 'rules that changed materially have not been read',
      );
    });

    test('a value that is not a version is not an acceptance', () {
      // The old shape of this setting, or a corrupted row. Showing the
      // briefing again costs one screen; assuming it was read costs more.
      expect(briefingAccepted('true'), isFalse);
      expect(briefingAccepted(''), isFalse);
    });
  });

  group('the reminder about being seen after dark', () {
    final dusk = DateTime.utc(2026, 8, 11, 19, 40);
    final nextDusk = DateTime.utc(2026, 8, 12, 19, 38);

    test('is given once a night, not once a crossing', () {
      final reminder = NightReminder();

      expect(
        reminder.due(isNight: true, outdoors: true, nightStart: dusk),
        isTrue,
      );
      expect(
        reminder.due(isNight: true, outdoors: true, nightStart: dusk),
        isFalse,
        reason: 'midnight is the same night as half past eleven',
      );
    });

    test('comes back the next night', () {
      final reminder = NightReminder();
      reminder.due(isNight: true, outdoors: true, nightStart: dusk);

      expect(
        reminder.due(isNight: true, outdoors: true, nightStart: nextDusk),
        isTrue,
      );
    });

    test('says nothing in daylight', () {
      final reminder = NightReminder();

      expect(
        reminder.due(isNight: false, outdoors: true, nightStart: dusk),
        isFalse,
      );
    });

    test('says nothing indoors — the warning is about traffic', () {
      final reminder = NightReminder();

      expect(
        reminder.due(isNight: true, outdoors: false, nightStart: dusk),
        isFalse,
      );
    });

    test('a night spent indoors is still warned about on stepping out', () {
      final reminder = NightReminder();
      reminder.due(isNight: true, outdoors: false, nightStart: dusk);

      expect(
        reminder.due(isNight: true, outdoors: true, nightStart: dusk),
        isTrue,
      );
    });
  });
}
