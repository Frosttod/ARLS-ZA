import 'package:arls_za/game/away_summary.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// §16.3. §2.1 describes the catch-up as arithmetic; this is the half the
/// player sees. What matters is that it appears when something actually
/// happened and stays quiet the rest of the time — a box shown on every launch
/// is a box nobody reads.
void main() {
  final constants = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  ).toSimConstants();

  final t0 = DateTime.utc(2026, 9, 5, 8);

  SimState at(
    DateTime when, {
    double? waterMl,
    double? kcal,
    Duration sleepDebt = Duration.zero,
  }) {
    final fresh = SimState.fresh(at: when, constants: constants, massKg: 80);
    return fresh.copyWith(
      waterMl: waterMl ?? fresh.waterMl,
      caloriesKcal: kcal ?? fresh.caloriesKcal,
      sleepDebtSeconds: sleepDebt.inSeconds,
    );
  }

  group('what the hours cost', () {
    test('is subtraction, and only in the direction that costs', () {
      final summary = AwaySummary.between(
        before: at(t0, waterMl: 2800, kcal: 2400),
        after: at(t0.add(const Duration(hours: 9)), waterMl: 1750, kcal: 1500),
      );

      expect(summary.away, const Duration(hours: 9));
      expect(summary.waterLostMl, closeTo(1050, 0.1));
      expect(summary.kcalLost, closeTo(900, 0.1));
    });

    test('and a drink taken before closing the app is not a gift', () {
      // ⚠️ "Woda: +200 ml" on a page about an absence reads as the game
      // handing something over, which is not what happened — the player drank
      // it themselves before locking the screen.
      final summary = AwaySummary.between(
        before: at(t0, waterMl: 900),
        after: at(t0.add(const Duration(hours: 8)), waterMl: 1400),
      );

      expect(summary.waterLostMl, 0);
    });

    test('sleep moves both ways, because a shelter pays the debt down', () {
      final rested = AwaySummary.between(
        before: at(t0, sleepDebt: const Duration(hours: 6)),
        after: at(
          t0.add(const Duration(hours: 8)),
          sleepDebt: const Duration(hours: 1),
        ),
      );

      expect(rested.sleepOwed, const Duration(hours: -5));

      final worse = AwaySummary.between(
        before: at(t0),
        after: at(
          t0.add(const Duration(hours: 8)),
          sleepDebt: const Duration(hours: 3),
        ),
      );

      expect(worse.sleepOwed, const Duration(hours: 3));
    });
  });

  group('what grew out there', () {
    test('counts the zones that went up, and names the worst', () {
      final summary = AwaySummary.between(
        before: at(t0, waterMl: 2800),
        after: at(t0.add(const Duration(hours: 20)), waterMl: 500),
        zonesBefore: const [2, 5, 1],
        zonesAfter: const [3, 5, 4],
      );

      expect(summary.zonesGrown, 2);
      expect(summary.highestZone, 4);
    });

    test('a zone that stood still is not news', () {
      final summary = AwaySummary.between(
        before: at(t0),
        after: at(t0.add(const Duration(hours: 20))),
        zonesBefore: const [3, 3],
        zonesAfter: const [3, 3],
      );

      expect(summary.zonesGrown, 0);
      expect(summary.highestZone, 0);
    });
  });

  group('when it is worth a page at all', () {
    AwaySummary after(Duration away, {double water = 2800}) =>
        AwaySummary.between(
          before: at(t0, waterMl: 2800),
          after: at(t0.add(away), waterMl: water),
        );

    test('not for a coffee break, however much changed', () {
      expect(after(const Duration(hours: 1), water: 500).worthShowing, isFalse);
    });

    test('and not for a night that cost nothing', () {
      // Asleep in a shelter: the hours passed and the body is fine. A dialog
      // here is the game interrupting somebody to say nothing happened.
      expect(
        after(const Duration(hours: 9), water: 2799).worthShowing,
        isFalse,
      );
    });

    test('but yes for a working day that emptied a third of the water', () {
      expect(after(const Duration(hours: 9), water: 1800).worthShowing, isTrue);
    });

    test('and yes when something out there grew, whatever the body did', () {
      final summary = AwaySummary.between(
        before: at(t0),
        after: at(t0.add(kAwayWorthTelling)),
        zonesBefore: const [4],
        zonesAfter: const [5],
      );

      expect(summary.worthShowing, isTrue);
    });
  });

  group('the watch asks at the right moment', () {
    test('nothing to say until the catch-up has actually run', () {
      // ⚠️ Resuming is when the old state can still be read; the hours are
      // charged by the first tick after it. Asked too early, this compares a
      // state with itself.
      final watch = AwayWatch()
        ..left(state: at(t0, waterMl: 2800), zones: const [1]);

      expect(watch.caughtUp(at(t0, waterMl: 2800), const [1]), isNull);
    });

    test('and one absence is worth exactly one page', () {
      final watch = AwayWatch()
        ..left(state: at(t0, waterMl: 2800), zones: const [1]);

      final later = at(t0.add(const Duration(hours: 9)), waterMl: 1500);
      expect(watch.caughtUp(later, const [2]), isNotNull);
      expect(
        watch.caughtUp(later, const [2]),
        isNull,
        reason: 'the second tick after a resume is not a second absence',
      );
    });
  });
}
