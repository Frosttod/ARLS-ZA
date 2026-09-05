/// One thing being done, with a clock on it (§2.1a, §11.1).
///
/// ⚠️ **Four mechanisms became one.** The game kept four separate records of
/// "something is happening": an occupation as JSON on the vitals row, a craft
/// job in its own table, three columns on the shelter row, and — for eating,
/// drinking, dressing a wound, searching and forcing a door — a notifier in
/// the widget and nothing at all on disk.
///
/// That last one is why closing the app halfway through a meal gave the
/// sandwich back untouched. The action existed only in memory, so killing the
/// process was a way to eat for free.
///
/// This is the record all of them become: what is being done, to which piece,
/// when it began, how long it takes and **how much of that has actually been
/// earned** — because [credited] is not `now − startedAt`. An action's clock
/// runs at a rate (§4.7, §10.2), and time when the rate was nought is time the
/// character did not spend.
library;

import 'dart:convert';

import '../map/geometry.dart';
import 'action_pace.dart';
import 'action_kind.dart';

/// Things that are done but are not one of §4.7's short actions.
///
/// Kept as plain strings rather than a second enum: they are written to disk,
/// and a name that has to survive a save is a name that should not move when
/// somebody reorders a declaration.
abstract final class ActionKinds {
  static const crafting = 'crafting';
  static const recycling = 'recycling';
  static const building = 'building';
  static const loading = 'loading';
  static const unloading = 'unloading';
  static const breaching = 'breaching';

  /// Everything that is not one of [ActionKind]'s.
  static const unattended = {crafting, recycling, building};
}

/// §4.7, §10.2: how this kind's clock behaves.
///
/// ⚠️ Worked out from the kind rather than stored beside it. A stored pace
/// would mean a rule changed in code did not reach a row already on disk —
/// and then eating saved yesterday would behave differently from eating
/// started today, on the same phone.
ActionPace paceOf(String kind) {
  for (final known in ActionKind.values) {
    if (known.name == kind) return known.pace;
  }

  if (ActionKinds.unattended.contains(kind)) return ActionPace.unattended;

  // Loading a magazine and forcing a door are done standing in one place
  // (§4.2, §19.3), like a search.
  return ActionPace.onTheSpot;
}

/// §4.7: whether running ends this rather than pausing it.
bool ruinedByRunning(String kind) {
  for (final known in ActionKind.values) {
    if (known.name == kind) return known.ruinedByRunning;
  }
  return false;
}

class TimedAction {
  const TimedAction({
    required this.kind,
    required this.startedAt,
    required this.total,
    this.id = 0,
    this.credited = Duration.zero,
    this.subjectUid,
    this.at,
    this.extra = const {},
  });

  /// The row this came from, or nought for one nobody has saved yet.
  final int id;

  /// What is being done. One of [ActionKind]'s names or one of [ActionKinds].
  final String kind;

  /// §11.1: **which piece** it is being done to.
  ///
  /// The uid, never the item id. Two sandwiches in one pack are two
  /// sandwiches, and a half-eaten one has to come back half-eaten rather than
  /// taking a bite out of its neighbour.
  final String? subjectUid;

  final DateTime startedAt;

  /// How much work it takes in total, at full rate.
  final Duration total;

  /// How much of that has been earned.
  ///
  /// ⚠️ Not `now − startedAt`. A dressing begun and then walked away from has
  /// been running for ten minutes and earned six; a search whose owner stepped
  /// off the spot has been running and earned nothing. The difference is the
  /// whole reason this field exists rather than being computed.
  final Duration credited;

  /// Where it began, for anything that has to happen in one place (§10.2).
  final GeoPoint? at;

  /// Whatever else this kind needs: a recipe id, a POI, a search depth.
  ///
  /// Opaque JSON for the reason §2.1a's occupation column gives: new kinds of
  /// action arrive with new fields, and each of those would otherwise be a
  /// schema migration.
  final Map<String, Object?> extra;

  ActionPace get pace => paceOf(kind);

  double get progress => total <= Duration.zero
      ? 1
      : (credited.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

  bool get isDone => credited >= total;

  /// What is left, at full rate.
  Duration get left {
    final rest = total - credited;
    return rest.isNegative ? Duration.zero : rest;
  }

  /// How long the rest will really take at [rate], or null when it is stopped.
  Duration? leftAt(double rate) => atThisRate(left, rate);

  /// §4.7, §10.2: one span of wall time, credited at whatever it was worth.
  ///
  /// The one place time turns into progress. Everything upstream decides what
  /// the context was; nothing downstream has to know there is a rate at all.
  TimedAction advanced(Duration elapsed, PaceContext context) {
    if (elapsed <= Duration.zero) return this;

    final rate = rateFor(pace, context);
    if (rate <= 0) return this;

    final earned = credited + elapsed * rate;
    return copyWith(credited: earned > total ? total : earned);
  }

  TimedAction copyWith({int? id, Duration? credited}) => TimedAction(
    id: id ?? this.id,
    kind: kind,
    subjectUid: subjectUid,
    startedAt: startedAt,
    total: total,
    credited: credited ?? this.credited,
    at: at,
    extra: extra,
  );

  String get extraJson => extra.isEmpty ? '{}' : jsonEncode(extra);

  static Map<String, Object?> extraFrom(String? json) {
    if (json == null || json.isEmpty) return const {};

    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      // A row nobody can read is a row that loses one action, not a launch
      // that fails. Same rule the item catalogue keeps.
      return const {};
    }
  }
}
