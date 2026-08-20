import 'dart:io';

import 'package:arls_za/ui/units.dart';
import 'package:test/test.dart';

/// JEDNOSTKI I ZEGAR (§12).
///
/// A game read while walking is read in glances. Two decimals on every
/// measurement so a column lines up, and a clock on every span because
/// "11.8 h" is a figure nobody can act on.
void main() {
  group('measurements', () {
    test('always two decimals, whatever the size', () {
      // ⚠️ The complaint this answers: the pack wrote `0.15 kg` beside
      // `1.4 kg`, the shelves wrote `12 l` beside `1.35 l`, and nothing lined
      // up with anything.
      expect(kilograms(0.15), '0.15 kg');
      expect(kilograms(1.4), '1.40 kg');
      expect(kilograms(36), '36.00 kg');
      expect(litres(0.5), '0.50 l');
      expect(metres(300), '300.00 m');
    });

    test('and the same on both sides of a limit', () {
      expect(outOfKg(18, 32.4), '18.00 / 32.40 kg');
      expect(outOfL(40, 65), '40.00 / 65.00 l');
    });

    test('a tenth of a kilogram is visible again', () {
      // Shock costs a tenth of the carry load: 36 kg becomes 32.4. The whole
      // number this used to print read as 32 and hid the penalty entirely.
      expect(outOfKg(18, 36 * 0.9), '18.00 / 32.40 kg');
    });
  });

  group('spans are clocks, never decimals', () {
    test('hours and minutes', () {
      expect(span(const Duration(hours: 11, minutes: 45)), '11:45');
      expect(span(const Duration(minutes: 7)), '0:07');
    });

    test('and they do not wrap at a day', () {
      // ⚠️ A thirty-one hour sleep debt is thirty-one hours owed. Writing it
      // as 7:20 would say the opposite of what is true.
      expect(span(const Duration(hours: 31, minutes: 20)), '31:20');
    });

    test('a debt carries its sign, and nothing owed says so', () {
      expect(owed(const Duration(hours: 11, minutes: 45)), '−11:45');
      expect(owed(Duration.zero), '0:00');
      expect(owed(const Duration(hours: -3)), '0:00');
    });

    test('a countdown keeps the seconds while they matter', () {
      // Under an hour the seconds are the point — a reload is three of them.
      expect(remaining(const Duration(seconds: 7)), '00:07');
      expect(remaining(const Duration(minutes: 12, seconds: 30)), '12:30');

      // Above one, they are noise on a bar somebody checks twice an hour.
      expect(remaining(const Duration(hours: 2, minutes: 15)), '2:15');
      expect(remaining(const Duration(seconds: -5)), '00:00');
    });

    test('the time of day is twenty-four hour, padded', () {
      final morning = DateTime(2026, 8, 20, 7, 5);
      final evening = DateTime(2026, 8, 20, 23, 40);

      expect(clock(morning), '07:05');
      expect(clock(evening), '23:40');
    });
  });

  group('the rule holds in the source', () {
    test('no screen writes its own kilograms or litres any more', () {
      // ⚠️ A budget, like the sticky-position test. Every screen used to
      // decide its own precision, which is how the columns stopped lining up.
      // If this grows, the new one belongs in units.dart.
      final offenders = <String>[];

      for (final file in Directory('lib/ui').listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final source = file.readAsStringSync();

        for (final line in source.split('\n')) {
          if (!line.contains('toStringAsFixed')) continue;

          // Only where a unit is written beside the number. A generic
          // formatter that takes its unit as an argument is not what this
          // is looking for.
          final writesAUnit = RegExp(
            "(kg|kilograms|litres| l| m)['\\\"]",
          ).hasMatch(line);
          if (!writesAUnit) continue;
          offenders.add('${file.uri.pathSegments.last}: ${line.trim()}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'these write their own units:\n${offenders.join('\n')}',
      );
    });
  });
}
