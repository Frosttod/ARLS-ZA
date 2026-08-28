/// How every number in this game is written down (§12).
///
/// ⚠️ **One place, because a game read while walking is read in glances.**
/// Two decimals on every measurement and a clock on every span, so a column of
/// figures lines up and the eye finds the digit it wants without reading the
/// row. The screens used to decide for themselves: the pack wrote `0.15 kg`
/// beside `1.4 kg`, the shelves wrote `12 l` beside `1.35 l`, and nothing
/// lined up with anything.
///
/// **Time is a clock, never a decimal.** A sleep debt of `11.8 h` is a number
/// nobody can act on — eleven hours and how many minutes? — and it was on the
/// screen for weeks. `11:45` is the same fact in a form every person on earth
/// already reads. Hours past a day keep counting up rather than wrapping:
/// `31:20` of debt is thirty-one hours owed, not a time of night.
library;

/// A measurement, always to two decimals.
///
/// The unit comes after, with one space, and never gets its own formatting
/// rules — `kg`, `l`, `m` are the same width of thought as the number.
String amount(double value) => value.toStringAsFixed(2);

String kilograms(double value) => '${amount(value)} kg';

String litres(double value) => '${amount(value)} l';

String metres(double value) => '${amount(value)} m';

/// `carried / limit`, with the unit said once.
String outOfKg(double value, double limit) =>
    '${amount(value)} / ${amount(limit)} kg';

String outOfL(double value, double limit) =>
    '${amount(value)} / ${amount(limit)} l';

/// A span, as `H:MM`, or `H:MM:SS` where the seconds are the point.
///
/// ⚠️ Not wrapped at twenty-four. A thirty-one hour sleep debt is `31:20`, and
/// writing it as `7:20` would say the opposite of what is owed.
String span(Duration length, {bool seconds = false}) {
  final total = length.isNegative ? -length : length;

  final hours = total.inHours;
  final minutes = (total.inMinutes % 60).toString().padLeft(2, '0');

  if (seconds) {
    final secs = (total.inSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$secs' : '$minutes:$secs';
  }

  return '$hours:$minutes';
}

/// How long a piece of work takes, said with its unit.
///
/// ⚠️ **A clock is ambiguous for an estimate, and the field found it.** A bench
/// row reading `2:30` is two and a half hours; one reading `45:00` is
/// forty-five minutes. The same two characters either side of a colon mean
/// hours in one row and minutes in the next, and nothing on screen says which.
/// A countdown can afford that, because it is visibly running down towards
/// something; a figure sitting still on a list cannot.
String worked(Duration length) {
  final total = length.isNegative ? Duration.zero : length;
  final hours = total.inHours;
  final minutes = total.inMinutes % 60;

  if (hours == 0) return '$minutes min';
  return minutes == 0 ? '$hours h' : '$hours h $minutes min';
}

/// A span with its sign, for anything that can be owed.
String owed(Duration debt) => debt <= Duration.zero ? '0:00' : '−${span(debt)}';

/// The time of day, on a twenty-four hour clock.
///
/// Local, because a player reads it against their own window.
String clock(DateTime at) {
  final local = at.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// A countdown, where the seconds matter under an hour and stop mattering
/// above one.
///
/// The action strip and every progress bar use this: `0:07` for a reload,
/// `12:30` for a dismantling, `2:15` for a nine-hour workshop with two hours
/// left on it.
String remaining(Duration left) {
  final total = left.isNegative ? Duration.zero : left;
  return span(total, seconds: total.inHours < 1);
}
