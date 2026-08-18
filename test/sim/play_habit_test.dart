import 'package:arls_za/sim/play_habit.dart';
import 'package:test/test.dart';

/// §6.5.3, §16.4. How much somebody plays, and what the world does about it.
///
/// §6.5.3's clock is almost entirely the calendar: two hours a day reaches
/// three level-ten hotspots in 8.2 days and never playing at all reaches them
/// in 9.9. That hands an unanswerable world to somebody with twenty minutes
/// and a world that never catches up to somebody with three hours. §16.4 asks
/// whether an hour a day keeps up; this measures the hour instead of assuming
/// it.
void main() {
  final today = DateTime(2026, 8, 16);

  PlayHabit habit(List<int> minutesPerDay) => PlayHabit([
    for (var i = 0; i < minutesPerDay.length; i++)
      PlayDay(
        day: today.subtract(Duration(days: i)),
        activeMinutes: minutesPerDay[i],
      ),
  ]);

  group('what a week says about somebody', () {
    test('an hour a day is an hour a day', () {
      expect(habit(List.filled(7, 60)).hoursPerDay, closeTo(1, 0.001));
    });

    test('one long Saturday is not a habit', () {
      // Empty days count as zeros rather than being skipped, or one good week
      // would read as a life.
      final weekend = habit([180, 0, 0, 0, 0, 0, 0]);

      expect(weekend.hoursPerDay, closeTo(3 / 7, 0.01));
    });

    test('a first session does not divide by nothing', () {
      expect(habit(const []).hoursPerDay, kMinPlayHours);
      expect(habit(List.filled(7, 0)).hoursPerDay, kMinPlayHours);
    });

    test('only the last week counts', () {
      // Long enough to survive one bad Tuesday, short enough to follow
      // somebody whose life changed.
      final changed = habit([120, 120, 120, 120, 120, 120, 120, 0, 0, 0, 0]);

      expect(changed.hoursPerDay, closeTo(2, 0.001));
    });
  });

  group('what the world does about it (§6.5.3)', () {
    test('an hour played is worth more than an hour away from it', () {
      // The pressure exists to be met. A world that moves only with the
      // calendar is a world the player cannot answer.
      final playing = habit(List.filled(7, 60)).creditedHoursPerDay;
      final away = habit(List.filled(7, 0)).creditedHoursPerDay;

      expect(playing, greaterThan(away * 2 - 1));
    });

    test('but an hour away still moves it', () {
      // §6.5.3 is explicit that a city spoils while nobody is looking.
      expect(habit(List.filled(7, 0)).creditedHoursPerDay, greaterThan(0));
    });

    test('an hour a day lands near where §6.5.3 already had it', () {
      // The figure the rest of the balance was written against.
      expect(habit(List.filled(7, 60)).creditedHoursPerDay, closeTo(6, 1));
    });

    test('a marathon does not turn it into a different game', () {
      expect(habit(List.filled(7, 600)).creditedHoursPerDay, kCreditedMax);
    });

    test('and neither does a fortnight off', () {
      // What the world does with nobody in it: a few hours a day, against the
      // sixteen a marathon earns.
      final gone = habit(List.filled(7, 0)).creditedHoursPerDay;

      expect(gone, greaterThanOrEqualTo(kCreditedMin));
      expect(gone, lessThan(4));
    });

    test('⚠️ the inverse rule, which was wrong', () {
      // Giving the light player *more* idle credit to compensate made their
      // world run twice as fast as an hour-a-day player's. Compensating for a
      // small habit turns into punishing it, so play is weighted instead.
      final sparse = habit(List.filled(7, 20)).creditedHoursPerDay;
      final steady = habit(List.filled(7, 60)).creditedHoursPerDay;

      expect(sparse, lessThan(steady));
    });
  });

  group('§16.4: does an hour a day keep up', () {
    test('the interval itself is untouched (§6.5.3)', () {
      // A rule that shortened it for playing would be a treadmill; one that
      // lengthened it would reward not playing.
      expect(promotionIntervalHours(1), 7.75);
      expect(promotionIntervalHours(12), 5);
      expect(promotionIntervalHours(24), 2);
      expect(promotionIntervalHours(90), 2, reason: 'the floor holds');
    });

    test('an hour a day still reaches level ten in about ten days', () {
      // Close to where §6.5.3 already had it, so the rest of the balance
      // written against that figure still stands.
      expect(daysToMaxLevel(habit(List.filled(7, 60))), closeTo(10, 1));
    });

    test('three hours a day is a faster world, not a slower one', () {
      // The player sees more of it, so more of it happens — but the gap is
      // days rather than the near-nothing §6.5.3 gave.
      final heavy = daysToMaxLevel(habit(List.filled(7, 180)));
      final light = daysToMaxLevel(habit(List.filled(7, 60)));

      expect(heavy, lessThan(light));
    });

    test('and twenty minutes a day is a slower one', () {
      // The point of the whole exercise: a small habit gets a world it can
      // still answer, rather than one that ran away while it was not looking.
      final sparse = daysToMaxLevel(habit(List.filled(7, 20)));

      expect(sparse, greaterThan(daysToMaxLevel(habit(List.filled(7, 60)))));
    });

    test('somebody who stops playing still comes back to a worse city', () {
      final gone = daysToMaxLevel(habit(List.filled(7, 0)));

      expect(gone.isFinite, isTrue);
      expect(gone, lessThan(30), reason: 'a fortnight away has to cost');
      expect(
        gone,
        greaterThan(daysToMaxLevel(habit(List.filled(7, 60)))),
        reason: 'but never as fast as somebody actually playing',
      );
    });

    test('the spread across every style stays inside a fortnight', () {
      // ⚠️ The balance question: a hotspot that matures in three days for one
      // player and thirty for another is two different games.
      final styles = [
        0,
        20,
        60,
        120,
        180,
        300,
      ].map((m) => daysToMaxLevel(habit(List.filled(7, m)))).toList();

      expect(styles.reduce((a, b) => a > b ? a : b), lessThan(22));
      expect(styles.reduce((a, b) => a < b ? a : b), greaterThan(3));
    });
  });
}
