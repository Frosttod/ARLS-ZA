/// One way of saying what something gives you (§12).
///
/// ⚠️ **Three screens were each inventing their own.** A module said what it
/// did in a sentence ("Piętnaście procent na poziom mniej do przespania"), a
/// skill said it in a list of percentages, and an action said it in whatever
/// the row happened to have room for. All three answer the same question —
/// *what does this buy me* — and a player comparing a Lounge against a
/// Laboratory had to translate two paragraphs into two numbers first.
///
/// So there is one shape now, and it is deliberately small:
///
///     Sen  ×1,15 → ×1,30
///     Promień +40%  ·  Rzadkie +12%  ·  Zauważony 12% później
///
/// A **label**, a **number**, and where there is a next step, an arrow to it.
/// Nothing else. The prose that used to carry the same information is gone
/// rather than kept alongside — two statements of one figure is how they drift
/// apart.
library;

/// What separates one effect from the next.
///
/// A dot rather than a comma, because a comma between two numbers is a comma
/// somebody reads as a decimal point. Two spaces either side rather than one:
/// this is read at a glance in daylight, and it has to survive a caption under
/// an action icon as well as a line on the profile screen — one separator for
/// both, or the two screens are inconsistent by a space.
const String kEffectGap = '  ·  ';

/// Several effects on one line.
String effects(Iterable<String> parts) =>
    parts.where((part) => part.isNotEmpty).join(kEffectGap);

/// A label and what it is worth: `Sen ×1,15`.
String effect(String label, String value) => '$label $value';

/// What it is now, and what the next step makes it: `×1,15 → ×1,30`.
///
/// Only where a step exists. At the top of a module there is nothing to point
/// at, and an arrow to nowhere reads as something still to come.
String step(String now, String? next) => next == null ? now : '$now → $next';

/// A multiplier, as a player reads one.
///
/// ⚠️ `×1,15` rather than `+15%`, and the same everywhere. Both are true and
/// they cannot be mixed: a Lounge at level two is `×1,30`, which is not
/// "+15% twice" in any arithmetic a player would do in their head.
String times(double value) => '×${value.toStringAsFixed(2)}';

/// A share of something, as a whole per cent.
String percent(double fraction) => '${(fraction * 100).round()}%';

/// A signed share, for something that adds: `+40%`.
String plusPercent(double fraction) {
  final rounded = (fraction * 100).round();
  return rounded >= 0 ? '+$rounded%' : '$rounded%';
}
