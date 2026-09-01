import 'dart:io';

import 'package:arls_za/sim/action_pace.dart';
import 'package:arls_za/sim/metabolism.dart';
import 'package:arls_za/sim/occupation.dart';
import 'package:test/test.dart';

/// TEMPO AKCJI (§2.1a, §4.7, §10.2).
///
/// ⚠️ One rule where there were three special cases. A build stopping when the
/// character leaves the site, a search cancelled by a step, and a reload broken
/// by a body within five metres were three hand-written `if`s in three files
/// answering the same question — and a fourth was about to be written for
/// "eating should be slower on the move".
///
/// They are all: an action accrues time at a rate, and the rate depends on
/// what the character is doing while it runs.
void main() {
  group('what runs whether or not anybody watches (§2.1a.3)', () {
    test('a build runs at full rate, standing or running', () {
      // The character sets it going and comes back. Their feet are not part
      // of it.
      for (final speed in [0.0, 4.0, 12.0]) {
        expect(
          rateFor(ActionPace.unattended, PaceContext(speedKmh: speed)),
          1,
          reason: '$speed km/h',
        );
      }
    });

    test('and does not care whether they are still on the site', () {
      expect(
        rateFor(
          ActionPace.unattended,
          const PaceContext(atStartingPlace: false),
        ),
        1,
      );
    });
  });

  group('what needs their own two hands (§4.7)', () {
    test('standing still is full speed', () {
      expect(rateFor(ActionPace.handsOn, const PaceContext(speedKmh: 0)), 1);
    });

    test('walking is slower, not cancelled', () {
      // ⚠️ The change this whole enum exists to allow. A step used to throw
      // the entire meal away; now a sandwich eaten on the move takes 1.6
      // times as long.
      final walking = rateFor(
        ActionPace.handsOn,
        const PaceContext(speedKmh: 4),
      );

      expect(walking, lessThan(1));
      expect(walking, greaterThan(0));
      expect(1 / walking, closeTo(kPaceWalking, 0.001));
    });

    test('a brisk walk is slower again', () {
      final brisk = rateFor(ActionPace.handsOn, const PaceContext(speedKmh: 6));
      final walking = rateFor(
        ActionPace.handsOn,
        const PaceContext(speedKmh: 4),
      );

      expect(brisk, lessThan(walking));
      expect(1 / brisk, closeTo(kPaceBrisk, 0.001));
    });

    test('and running stops it', () {
      // Nobody dresses a wound at a run. Stopped, not failed: §18.6's rule is
      // that what has been earned is kept.
      expect(rateFor(ActionPace.handsOn, const PaceContext(speedKmh: 12)), 0);
    });

    test('the rate only ever falls as the speed rises', () {
      // A curve that went back up anywhere would be a speed worth running at
      // to finish a bandage sooner.
      var last = 2.0;

      for (var kmh = 0.0; kmh <= 15; kmh += 0.25) {
        final rate = rateFor(ActionPace.handsOn, PaceContext(speedKmh: kmh));
        expect(rate, lessThanOrEqualTo(last), reason: '$kmh km/h');
        last = rate;
      }
    });
  });

  group('what has to happen where it started (§10.2)', () {
    test('on the spot is full speed', () {
      expect(rateFor(ActionPace.onTheSpot, const PaceContext()), 1);
    });

    test('and one step away is no speed at all', () {
      // Not slowed — stopped. Half a shop searched from across the road is
      // not a slower search, it is not a search.
      expect(
        rateFor(
          ActionPace.onTheSpot,
          const PaceContext(atStartingPlace: false),
        ),
        0,
      );
    });

    test('speed on its own does not stop it', () {
      // Somebody turning on the spot is still on the spot. The place is the
      // condition, not the pace.
      expect(rateFor(ActionPace.onTheSpot, const PaceContext(speedKmh: 3)), 1);
    });
  });

  group('what the player is told', () {
    test('a job started on the move takes longer, and says so', () {
      // ⚠️ Fifteen minutes that quietly becomes twenty-four is the interface
      // lying. §12: the figure on screen is the figure that will happen.
      const work = Duration(minutes: 15);
      final walking = rateFor(
        ActionPace.handsOn,
        const PaceContext(speedKmh: 4),
      );

      expect(atThisRate(work, walking)!.inMinutes, 24);
    });

    test('and one that cannot progress has no end to give', () {
      expect(atThisRate(const Duration(minutes: 15), 0), isNull);
    });

    test('full rate is the honest figure', () {
      expect(
        atThisRate(const Duration(minutes: 15), 1),
        const Duration(minutes: 15),
      );
    });
  });

  test('standing still is one speed, not two', () {
    // §10.2's threshold for "did they stand still" and §4.7's for "are their
    // hands free" are the same number on purpose. Two would be a speed at
    // which a search counts as still and a bandage does not.
    expect(const PaceContext(speedKmh: 0.4).isStill, isTrue);
    expect(const PaceContext(speedKmh: 0.6).isStill, isFalse);
    expect(rateFor(ActionPace.handsOn, const PaceContext(speedKmh: 0.4)), 1);
  });

  group('every action in the game has a pace, and the right one', () {
    test('the things done with hands are slowed, not stopped', () {
      for (final kind in [
        ActionKind.eating,
        ActionKind.drinking,
        ActionKind.dressing,
        ActionKind.tourniquet,
        ActionKind.suturing,
      ]) {
        expect(kind.pace, ActionPace.handsOn, reason: kind.name);
      }
    });

    test('and the things done in a place are stopped by leaving it', () {
      for (final kind in [
        ActionKind.searching,
        ActionKind.reloading,
        ActionKind.shooting,
      ]) {
        expect(kind.pace, ActionPace.onTheSpot, reason: kind.name);
      }
    });

    test('every occupation runs unattended (§2.1a.3)', () {
      // Sleeping, reading, building, crafting: the character sets them going
      // and comes back. That is what makes them occupations.
      for (final kind in OccupationKind.values) {
        expect(kind.pace, ActionPace.unattended, reason: kind.name);
      }
    });

    test('only suturing is ruined by running', () {
      // ⚠️ A decision, not a rule. Sixteen minutes of suturing is not
      // something anybody picks up again after sprinting away from a Brute
      // with the needle still in — everything else is kept and gone back to.
      for (final kind in ActionKind.values) {
        expect(
          kind.ruinedByRunning,
          kind == ActionKind.suturing,
          reason: kind.name,
        );
      }
    });

    test('a sandwich on the move is a longer sandwich, not a lost one', () {
      // The whole point, end to end: §4.7 gives eating 75 seconds standing
      // still, and a walk makes it two minutes rather than nothing.
      final walking = rateFor(
        ActionKind.eating.pace,
        const PaceContext(speedKmh: 4),
      );

      expect(walking, greaterThan(0), reason: 'a step used to end the meal');
      expect(
        atThisRate(ActionKind.eating.baseDuration, walking)!.inSeconds,
        120,
      );
    });
  });

  group('§2.2, §3.2, §8.1: what counts as movement at all', () {
    // ⚠️ **Three ways to be charged for a walk nobody took, all three found
    // on a phone.** The last of them is the reason this function exists: after
    // a night in a shelter the receiver had wandered a few metres at a time
    // for eight hours, [bandForSpeed] calls any speed above zero at least a
    // slow walk, and the player woke to a night's water drunk by somebody
    // asleep in a chair.

    test('a walk outdoors is a walk', () {
      expect(
        countedSpeedKmh(reported: 4.5, sheltered: false, trusted: true),
        4.5,
      );
    });

    test('but under your own roof it is scatter (§8.1)', () {
      // ⚠️ §2.1's zone factor already prices being indoors at rest. Charging
      // movement on top of it pays twice for the same hour.
      expect(countedSpeedKmh(reported: 4.5, sheltered: true, trusted: true), 0);
    });

    test('and a reading nobody can trust is not movement either (§3.2)', () {
      expect(
        countedSpeedKmh(reported: 4.5, sheltered: false, trusted: false),
        0,
      );
    });

    test('standing still outdoors stays nought', () {
      expect(countedSpeedKmh(reported: 0, sheltered: false, trusted: true), 0);
    });

    test('and the loop actually asks (§2.2)', () {
      // ⚠️ Source-level, because this rule spent the whole of stage 8 written
      // out inline in `_buildInput` where two of its three clauses lived and
      // the third did not — which is how a night's water went missing.
      final loop = File('lib/game/game_loop.dart').readAsStringSync();

      expect(loop.contains('speedKmh: countedSpeedKmh('), isTrue);
      expect(
        loop.contains('sheltered: sheltered'),
        isTrue,
        reason: 'the roof clause is the one that was missing',
      );
    });

    test('and the smallest scatter indoors is nought, not a slow walk', () {
      // The exact shape of the report: 0.3 km/h is below anybody's idea of
      // walking and above [bandForSpeed]'s only test, which is "more than
      // nought".
      expect(bandForSpeed(0.3), isNot(ActivityBand.standing));
      expect(countedSpeedKmh(reported: 0.3, sheltered: true, trusted: true), 0);
    });
  });

  group('§2.2: jedna granica chodu i biegu', () {
    test('siedem i dwie dziesiąte, czyli prędkość przejścia', () {
      // ⚠️ Nie okrągła liczba z sufitu. Chód przechodzi w bieg przy około
      // 2,0 m/s — zmierzone i powtarzalne — i ta sama liczba wypada z liczby
      // Froude'a: przejście przy Fr ≈ 0,5 daje `v = √(0,5 · g · L)`, czyli
      // 2,1 m/s dla nogi długości 0,9 m.
      expect(kRunningKmh, 7.2);
      expect(kRunningKmh / 3.6, closeTo(2.0, 0.01));
    });

    test('a marsz to tempo, które człowiek wybiera sam', () {
      expect(kWalkingKmh / 3.6, closeTo(1.39, 0.01));
    });

    test('i progi idą po kolei', () {
      expect(kStillKmh, lessThan(kWalkingKmh));
      expect(kWalkingKmh, lessThan(kRunningKmh));
    });
  });

  test('§2.2: i jest ich dokładnie po jednej', () {
    // ⚠️ **Były dwie `kRunningKmh`: 6,4 i 8.** Ta sama nazwa, dwie biblioteki,
    // dwie wartości — powyżej 6,4 gracz hałasował jak biegnący, powyżej 8
    // przestawał opatrywać ranę, a między nimi był jednocześnie biegnącym i
    // niebiegnącym. Nie kolidowały wyłącznie dlatego, że żaden plik nie
    // importował obu naraz, więc kompilator milczał.
    final defined = <String, List<String>>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      final source = file.readAsStringSync();
      for (final name in ['kRunningKmh', 'kStillKmh', 'kWalkingKmh']) {
        if (source.contains('const double $name =')) {
          (defined[name] ??= []).add(file.path);
        }
      }
    }

    expect(defined.keys, hasLength(3), reason: 'wszystkie trzy progi istnieją');
    for (final entry in defined.entries) {
      expect(entry.value, hasLength(1), reason: entry.value.join(', '));
    }
  });
}
