/// The one clock everything with a duration runs on (§2.1a, §11.1).
///
/// ⚠️ **It knows how long things take and nothing about what they mean.**
///
/// Eating consumes a portion, crafting yields an item, a search turns a place
/// over. None of that is here. The runner starts an action, credits it at the
/// rate §4.7 and §10.2 give it, writes it down often enough to survive a kill,
/// and says when it is finished — and the caller, which knows about food and
/// recipes, decides what that means.
///
/// The direction matters: this may reach into `lib/sim`, and `lib/sim` must
/// never reach into this. A runner that knew what a sandwich was would be the
/// God class again with a smaller file name.
library;

import 'package:flutter/foundation.dart';

import '../data/db/database.dart';
import '../sim/action_pace.dart';
import '../sim/timed_action.dart';
import 'action_store.dart';

/// Why an action would not start.
enum StartRefusal {
  /// §2.1a: one pair of hands. Something else is already on.
  busy,
}

class ActionRunner {
  ActionRunner({
    required SaveDatabase db,
    required this.profileId,
    DateTime Function()? clock,
  }) : _store = ActionStore(db),
       _now = clock ?? (() => DateTime.now().toUtc());

  final ActionStore _store;
  final int profileId;
  final DateTime Function() _now;

  /// What is being done, for anything that draws it.
  final ValueNotifier<TimedAction?> active = ValueNotifier(null);

  TimedAction? get current => active.value;

  /// §2.1a: whether the character's hands are free.
  bool get isBusy => active.value != null;

  /// When the last span was credited, so the next one knows how long it was.
  DateTime? _creditedTo;

  /// How much has been written down, so a checkpoint that would change
  /// nothing does not touch the disk.
  Duration? _onDisk;

  /// §11.1: picks up whatever was running when the app last stopped.
  ///
  /// ⚠️ Settles the gap before handing it over. An action that finished while
  /// the phone was in a pocket is finished, and the caller has to be told so
  /// rather than shown a full bar that never completes — which is a bug this
  /// project has already had once, with a dismantling stuck at 00:00.
  Future<TimedAction?> restore() async {
    final found = await _store.load(profileId);
    if (found == null) {
      _clearMemory();
      return null;
    }

    final settled = _settleGap(found, _now());

    active.value = settled;
    _creditedTo = _now();
    _onDisk = found.credited;

    if (settled.credited != found.credited) await _flush(settled);

    return settled;
  }

  /// §2.1a: puts one on, or says why not.
  ///
  /// Written to disk before this returns. A process can be killed in the first
  /// second as easily as in the last, and an action that only existed in
  /// memory was an action a kill undid — which is how closing the app during a
  /// meal handed the sandwich back whole.
  Future<StartRefusal?> start(TimedAction action) async {
    if (isBusy) return StartRefusal.busy;

    final begun = await _store.begin(
      profileId,
      action.copyWith(credited: action.credited),
    );

    active.value = begun;
    _creditedTo = _now();
    _onDisk = begun.credited;

    return null;
  }

  /// One tick of wall time, credited at whatever it was worth.
  ///
  /// Cheap and in memory. Nothing reaches the disk here — see [checkpoint].
  /// Returns the action when it has just finished, and null otherwise, so the
  /// caller can apply the outcome exactly once.
  TimedAction? tick(PaceContext context) {
    final running = active.value;
    if (running == null) return null;

    final now = _now();
    final since = _creditedTo ?? now;
    _creditedTo = now;

    final elapsed = now.difference(since);
    if (elapsed <= Duration.zero) return null;

    // §4.7: a run ruins a suture rather than pausing it. The one action in
    // the game where stopping is losing.
    if (ruinedByRunning(running.kind) && context.speedKmh >= kRunningKmh) {
      return null;
    }

    final next = running.advanced(elapsed, context);
    if (next.credited == running.credited) return null;

    active.value = next;
    return next.isDone ? next : null;
  }

  /// §2.1a.3: writes down what has been earned.
  ///
  /// Called on the way into the background and every so often while running.
  /// Skipped when nothing has changed, because a game carried in a pocket for
  /// hours should not write the same number to flash three thousand times.
  Future<void> checkpoint() async {
    final running = active.value;
    if (running == null) return;
    if (_onDisk == running.credited) return;

    await _flush(running);
  }

  /// Ends it, keeping what was earned on disk for nobody — the row goes.
  ///
  /// The caller decides what stopping means for the thing itself: §18.6 keeps
  /// the work on the item, §18.4 loses the materials, §4.7 keeps the mouthful
  /// that was swallowed. None of that is this class's business.
  Future<TimedAction?> finish() async {
    final running = active.value;
    if (running == null) return null;

    await _store.clear(profileId);
    _clearMemory();

    return running;
  }

  /// §11.1: what a gap in the wall clock did to an action.
  ///
  /// ⚠️ Only [ActionPace.unattended] gains anything. A build or a dismantling
  /// runs whether anybody is watching, so the whole gap counts. Anything that
  /// needs hands or a place cannot be credited for time nobody observed —
  /// there is no way to know whether the character stood still or ran, and
  /// guessing in the player's favour makes a pocket the fastest way to eat.
  TimedAction _settleGap(TimedAction action, DateTime now) {
    if (action.pace != ActionPace.unattended) return action;

    final whole = now.difference(action.startedAt);
    final earned = whole > action.total ? action.total : whole;

    return earned > action.credited
        ? action.copyWith(credited: earned)
        : action;
  }

  Future<void> _flush(TimedAction action) async {
    await _store.checkpoint(profileId, action);
    _onDisk = action.credited;
  }

  void _clearMemory() {
    active.value = null;
    _creditedTo = null;
    _onDisk = null;
  }

  void dispose() => active.dispose();
}
