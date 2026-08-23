import 'dart:io';

import 'package:arls_za/ui/effects.dart';
import 'package:test/test.dart';

/// JEDEN SPOSÓB MÓWIENIA, CO COŚ DAJE (§12).
///
/// ⚠️ **Three screens were each inventing their own.**
///
/// A shelter module said what it did in a sentence — "Piętnaście procent na
/// poziom mniej do przespania" — which is true, is a paragraph, and still left
/// a player working out what their own Lounge was doing. A skill said it in a
/// list of percentages with the separator baked into the translation. An
/// action said it in whatever the row had room for, assembled by hand.
///
/// All three answer one question: *what does this buy me*. So there is one
/// shape, and it is small: a label, a number, and where a next step exists, an
/// arrow to it.
void main() {
  group('the shape', () {
    test('a label and a number', () {
      expect(effect('Sen', '×1.15'), 'Sen ×1.15');
    });

    test('an arrow only where there is somewhere to point', () {
      expect(step('×1.15', '×1.30'), '×1.15 → ×1.30');
      expect(step('×1.45', null), '×1.45');
    });

    test('one separator, and empty parts do not leave a gap behind', () {
      expect(effects(['a', 'b']), 'a$kEffectGap b'.replaceAll(' b', 'b'));
      expect(effects(['a', '', 'b']), effects(['a', 'b']));
      expect(effects(['a']), 'a');
      expect(effects(<String>[]), '');
    });
  });

  group('the units', () {
    test('a multiplier is a multiplier everywhere', () {
      // ⚠️ `×1.30` rather than `+15%` twice. Both are true and they cannot be
      // mixed: a Lounge at level two is ×1.30, which is not "+15% twice" in
      // any arithmetic a player does in their head.
      expect(times(1.15), '×1.15');
      expect(times(1), '×1.00');
    });

    test('a share is a whole per cent', () {
      expect(percent(0.6), '60%');
      expect(percent(1), '100%');
    });

    test('and something that adds carries its sign', () {
      expect(plusPercent(0.4), '+40%');
      expect(plusPercent(-0.3), '-30%');
      expect(plusPercent(0), '+0%');
    });
  });

  test('§12: no screen assembles its own separator any more', () {
    // ⚠️ The defect this file exists to stop coming back. Two screens writing
    // `' · '` by hand are two screens that disagree about the spacing the
    // moment either is edited — and one of them was already writing a
    // narrower one than the other.
    final offenders = <String>[];

    for (final file in Directory('lib/ui').listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('effects.dart')) continue;

      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();

        // Prose may use the character — a formula in a doc comment is not a
        // separator. A separator is a thing that ends up on a screen.
        if (trimmed.startsWith('//')) continue;
        if (!trimmed.contains('·')) continue;

        offenders.add('${file.uri.pathSegments.last}: $trimmed');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'these build their own separator:\n${offenders.join('\n')}',
    );
  });
}
