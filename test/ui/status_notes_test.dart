import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:arls_za/ui/status_notes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// OPISY STATUSÓW (§12).
///
/// Four questions in the order a person asks them: how bad is it, what is it
/// costing me, what fixes it, where do I get that. A status that answers only
/// the first is a status the player learns to ignore.
void main() {
  late L10n pl;
  late L10n en;

  setUpAll(() async {
    pl = await L10n.delegate.load(const Locale('pl'));
    en = await L10n.delegate.load(const Locale('en'));
  });

  final profile = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );
  final constants = profile.toSimConstants();
  final t0 = DateTime.utc(2026, 8, 16, 12);

  SimStatus statusOfBody({
    double waterFraction = 1,
    double calorieFraction = 1,
    double bloodLossFraction = 0,
    Duration sleepDebt = Duration.zero,
  }) {
    final fresh = SimState.fresh(at: t0, constants: constants);

    return statusOf(
      state: fresh.copyWith(
        waterMl: constants.waterDailyMl * waterFraction,
        caloriesKcal: constants.caloriesDailyKcal * calorieFraction,
        bloodMl: constants.bloodMaxMl * (1 - bloodLossFraction),
        sleepDebtSeconds: sleepDebt.inSeconds,
      ),
      constants: constants,
    );
  }

  group('what a status sheet answers', () {
    test('nothing at all when nothing is wrong', () {
      expect(statusNotes(pl, statusOfBody()), isEmpty);
    });

    test('four answers, never a section number', () {
      final notes = statusNotes(pl, statusOfBody(waterFraction: 0.2));

      expect(notes, hasLength(1));
      final note = notes.single;
      expect(note.effect, isNotEmpty);
      expect(note.fix, isNotEmpty);
      expect(note.where, isNotEmpty);
      for (final line in [note.effect, note.fix, note.where]) {
        expect(line, isNot(contains('§')));
      }
    });

    test('and reads in English too', () {
      expect(statusNotes(en, statusOfBody(waterFraction: 0.2)), hasLength(1));
    });
  });

  group('how bad it is, where the model grades it', () {
    test('shock carries its clinical class', () {
      // The grades start at II — class I is a blood donation.
      final light = statusNotes(pl, statusOfBody(bloodLossFraction: 0.2)).first;
      final heavy = statusNotes(
        pl,
        statusOfBody(bloodLossFraction: 0.35),
      ).first;

      expect(light.level, contains('II'));
      expect(heavy.level, contains('III'));
    });

    test('water and food carry what is left of the daily need', () {
      final dry = statusNotes(pl, statusOfBody(waterFraction: 0.27)).first;

      expect(dry.level, contains('27'));
    });

    test('sleep carries the debt in hours', () {
      final tired = statusNotes(
        pl,
        statusOfBody(sleepDebt: const Duration(hours: 9)),
      ).first;

      expect(tired.level, contains('9'));
    });
  });

  test('the worst of them is read first', () {
    // Blood, then water, then food, then sleep: the order they kill in.
    final everything = statusNotes(
      pl,
      statusOfBody(
        bloodLossFraction: 0.2,
        waterFraction: 0.2,
        calorieFraction: 0.1,
        sleepDebt: const Duration(hours: 9),
      ),
    );

    expect(everything, hasLength(4));
    expect(everything.first.name, pl.statusShock);
    expect(everything.last.name, pl.statusSleepDeprived);
  });
}
