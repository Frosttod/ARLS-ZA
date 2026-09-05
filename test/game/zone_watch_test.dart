import 'dart:convert';
import 'dart:io';

import 'package:arls_za/game/zone_watch.dart';
import 'package:test/test.dart';

/// §2.1a.3, §12. The rules that stop work when the player walks away were
/// already there and already right. What was missing is that none of them said
/// so — the bar simply froze, and the player found out later or not at all.
void main() {
  group('the build site', () {
    test('the first answer is never a message', () {
      // ⚠️ Opening the app away from home with a shelter half up is not
      // "you have left" — nothing was left, the game was started. Saying so
      // would put a notice on every launch, which is how notices get ignored.
      expect(ZoneWatch().build(onSite: false), isNull);
      expect(ZoneWatch().build(onSite: true), isNull);
    });

    test('walking off says so, once', () {
      final watch = ZoneWatch()..build(onSite: true);

      expect(watch.build(onSite: false), ZoneChange.leftBuild);
      expect(
        watch.build(onSite: false),
        isNull,
        reason: 'still away is not news; a tick a second would be a wall',
      );
    });

    test('and coming back says that too', () {
      final watch = ZoneWatch()
        ..build(onSite: true)
        ..build(onSite: false);

      expect(watch.build(onSite: true), ZoneChange.backToBuild);
    });
  });

  group('the bench, which is the same rule at another table', () {
    test('an empty bench says nothing, however far away the player walks', () {
      final watch = ZoneWatch();

      expect(watch.bench(running: false, paused: false), isNull);
      expect(watch.bench(running: false, paused: true), isNull);
    });

    test('a job that stops because nobody is there does', () {
      final watch = ZoneWatch()..bench(running: true, paused: false);

      expect(watch.bench(running: true, paused: true), ZoneChange.leftBench);
      expect(watch.bench(running: true, paused: false), ZoneChange.backToBench);
    });

    test('and taking the job off the bench forgets where anybody stood', () {
      final watch = ZoneWatch()
        ..bench(running: true, paused: true)
        ..bench(running: false, paused: false);

      expect(
        watch.bench(running: true, paused: false),
        isNull,
        reason: 'a new job is not a return to the last one',
      );
    });
  });

  test('§12: nothing the game says about the player picks a gender', () {
    // ⚠️ Polish makes you choose one the moment you use a past tense about
    // somebody — "opuściłeś" assumes a man is holding the phone. The
    // impersonal form says the same thing and assumes nothing, and this is a
    // decision the project has made once already (carry weight, §1.3).
    final polish =
        jsonDecode(File('lib/l10n/app_pl.arb').readAsStringSync())
            as Map<String, dynamic>;

    // Second-person past endings, masculine and feminine.
    final gendered = RegExp(r'\b\w+(łeś|łaś|liście|łyście)\b');

    final offenders = [
      for (final entry in polish.entries)
        if (!entry.key.startsWith('@') && entry.value is String)
          if (gendered.hasMatch(entry.value as String))
            '${entry.key}: ${entry.value}',
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'these address the player as one gender:\n${offenders.join('\n')}',
    );
  });
}
