/// The one clock everything with a bar runs on (§2.1a, §2.1a.3, §3.3).
///
/// ⚠️ **There were five, and none of them knew about the others.**
///
/// A search ticked once a second. A reload ticked ten times a second, because
/// a bar under a thumb has to look smooth. The bench ticked once a second to
/// see whether its job had come due. The lifecycle stopped all three by name,
/// which meant every new clock had to remember to be added to two lists, and
/// the *sixth* one would have been the one somebody forgot.
///
/// Worse than the bookkeeping: five clocks reading and writing the same fields
/// is five chances for two of them to be in the middle of the same second. The
/// meal that hung the game was exactly that shape — one path crediting a
/// mouthful while another was still inside the first.
///
/// So: **one timer, several tickers.**
///
/// Each thing that needs a beat says how often it wants one and how to tell
/// whether it is still running. The timer itself runs at the finest period any
/// *running* ticker asks for, and stops dead when none of them is — because
/// §3.3 spends a whole section on what a game carried in a pocket for hours
/// may and may not do, and a clock nobody stops is the battery.
///
/// ⚠️ **Nothing is lost by stopping.** Everything drawn here is a *deadline* —
/// the search knows when it ends, the bench knows when it ends, the reload
/// knows when it ends. Coming back settles against the wall clock, which is
/// what opening the app after a night already does.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../inventory/inventory.dart';
import '../../loot/search.dart';

/// One thing that wants a beat.
@immutable
class _Ticker {
  const _Ticker({
    required this.name,
    required this.period,
    required this.running,
    required this.onTick,
  });

  final String name;
  final Duration period;

  /// Whether this still wants beats. Asked, never remembered: the answer
  /// changes when an action finishes, and a ticker that had to be *told* to
  /// stop is a ticker that outlives what it was ticking for.
  final bool Function() running;

  final void Function() onTick;
}

class ActionController extends ChangeNotifier {
  ActionController();

  // ------------------------------------------------------ what is running ---

  /// §4.7, §10.2, §19.3: the one thing being done, or null.
  ///
  /// ⚠️ Created here and never replaced. Eating, drinking, dressing a wound,
  /// searching and forcing a door are all this — one shape, one notifier, and
  /// §2.1a's "one pair of hands" is the fact that there is only one of it.
  final ValueNotifier<Search?> search = ValueNotifier(null);

  /// §11.1: **which piece** is in hand, never which item.
  ///
  /// Two sandwiches in one pack are two sandwiches, and a half-eaten one has
  /// to come back half-eaten rather than taking a bite out of its neighbour.
  final ValueNotifier<CarriedItem?> usingLine = ValueNotifier(null);

  /// When the search was last credited, so the next beat knows how long it
  /// was. Null while nothing is running.
  DateTime? tickedAt;

  /// ⚠️ Guards the search tick against arriving inside itself.
  ///
  /// The meal that hung the game went round this way: crediting a mouthful
  /// published a snapshot, the listener rode the tick, and the tick credited
  /// another mouthful. One turn took a microsecond. [GameLoop.applyUse] no
  /// longer publishes, which closes that particular circuit; this closes the
  /// *shape* of it, so the next thing to publish from inside a listener cannot
  /// reopen it.
  bool advancing = false;

  // ------------------------------------------------------------ the clock ---

  final Map<String, _Ticker> _tickers = {};

  /// How much of each ticker's own period has been paid for by the shared
  /// timer since it last fired.
  ///
  /// ⚠️ **Counted from the timer's own period, never from a wall clock.**
  ///
  /// The first version of this asked `DateTime.now()` how long it had been,
  /// which is two clocks deciding one thing — and the two do not agree. A
  /// timer that fires a millisecond early skips the beat; one that coalesces
  /// under load skips several. What arrives here is *a beat happened*, and
  /// that is the only honest measure of it.
  ///
  /// Nothing is lost by counting nominally: the clock decides **when to ask**,
  /// not how much time has passed. Every ticker works out real elapsed time
  /// for itself against the wall clock, because that is the one that survives
  /// a phone going to sleep.
  final Map<String, Duration> _owed = {};

  Timer? _timer;
  Duration? _period;

  /// Whether the clock is allowed to run at all.
  ///
  /// False while the app is in the background. §2.1a.3 lets the *world* go on
  /// without the screen — the loop keeps its own time and settles the gap —
  /// but nothing here needs to wake a phone up to redraw a bar nobody is
  /// looking at.
  bool get awake => _awake;
  bool _awake = true;

  /// Registers a repeating job under [name], replacing any with that name.
  ///
  /// ⚠️ Registration is not starting. A ticker that is not [running] costs
  /// nothing and holds no timer; it simply exists, waiting for the thing it
  /// watches to begin.
  void every(
    String name,
    Duration period, {
    required bool Function() running,
    required void Function() onTick,
  }) {
    _tickers[name] = _Ticker(
      name: name,
      period: period,
      running: running,
      onTick: onTick,
    );
    retime();
  }

  /// Says a ticker has just started, so its first beat is a full period away
  /// rather than whenever the shared clock next happens to fire.
  void restart(String name) {
    _owed[name] = Duration.zero;
    retime();
  }

  /// Starts, stops or re-paces the clock to match what is actually running.
  ///
  /// Cheap enough to call from anywhere that changes the answer, and called on
  /// every beat — which is what makes a ticker that quietly finished stop the
  /// clock without anybody having to notice.
  void retime() {
    final wanted = _wantedPeriod();

    if (wanted == null) {
      _timer?.cancel();
      _timer = null;
      _period = null;
      return;
    }

    if (_timer != null && _period == wanted) return;

    _timer?.cancel();
    _period = wanted;
    _timer = Timer.periodic(wanted, (_) => _beat());
  }

  /// The finest period any running ticker asks for, or null for none.
  ///
  /// ⚠️ The finest, not a fixed one. A reload wants ten beats a second so its
  /// bar looks smooth under a thumb; a bench job wants one, and waking the
  /// phone ten times a second for a forty-five minute pack would be §3.3's
  /// complaint made real. So the clock is as fine as it has to be and no
  /// finer, and it drops back the moment the fast thing ends.
  Duration? _wantedPeriod() {
    if (!_awake) return null;

    Duration? finest;
    for (final ticker in _tickers.values) {
      if (!ticker.running()) continue;
      if (finest == null || ticker.period < finest) finest = ticker.period;
    }
    return finest;
  }

  void _beat() {
    final beat = _period ?? Duration.zero;

    // ⚠️ A copy, because a tick can register or drop a ticker — finishing a
    // meal starts a bench job — and editing the map while walking it throws.
    for (final ticker in [..._tickers.values]) {
      if (!ticker.running()) {
        _owed.remove(ticker.name);
        continue;
      }

      final owed = (_owed[ticker.name] ?? Duration.zero) + beat;
      if (owed < ticker.period) {
        _owed[ticker.name] = owed;
        continue;
      }

      // ⚠️ Reset rather than subtract. A ticker that fell behind — the app was
      // busy, the timer coalesced — must not then fire a burst to catch up:
      // every one of these draws a deadline, and asking four times in a row
      // tells it nothing the first ask did not.
      _owed[ticker.name] = Duration.zero;
      ticker.onTick();
    }

    retime();
  }

  // ----------------------------------------------------------- lifecycle ---

  /// §3.3: stops the clock when nobody is looking.
  ///
  /// ⚠️ `inactive` is deliberately **not** a background — that is a dialog
  /// over the app, the recents view, a call arriving. The screen is still the
  /// player's, and a bar that froze behind a permission sheet would read as
  /// the game hanging.
  void sleep() {
    _awake = false;
    retime();
  }

  /// Puts the clock back.
  ///
  /// ⚠️ The caller settles first and wakes second. Restarting a beat for an
  /// action that ended twenty minutes ago would draw a full bar for one frame
  /// before the next tick cleared it.
  void wake() {
    _awake = true;
    _owed.clear();
    retime();
  }

  /// Whether anything at all is on the clock. §2.1a's question, asked of the
  /// clock rather than of a list somebody has to remember to extend.
  bool get anyRunning => _tickers.values.any((ticker) => ticker.running());

  /// Which things are on the clock, for a message that has to name one.
  List<String> get running => [
    for (final ticker in _tickers.values)
      if (ticker.running()) ticker.name,
  ];

  @visibleForTesting
  Duration? get periodForTest => _period;

  @override
  void dispose() {
    search.dispose();
    usingLine.dispose();
    _timer?.cancel();
    _timer = null;
    _tickers.clear();
    _owed.clear();
    super.dispose();
  }
}

/// §4.2: a magazine being filled or emptied, and how far along it is.
///
/// Held so the rounds can move *while the bar moves*: the plan says where the
/// magazine started and where it is going, and the fraction says where it
/// should be now. Working it out from the fraction rather than counting ticks
/// is what makes a late tick — or two in one frame — harmless.
/// §4.7: a meal being eaten, and how much of it there was to begin with.
///
/// ⚠️ **The tin is opened at the first tap, not at the last.**
///
/// Consuming a portion at the end — or restoring it at the next boot — leaves
/// a window in which the pack is lying: the bar is half across and the tin is
/// still sealed. Anything that ends the session in that window gives the meal
/// back whole, and closing the app becomes a way to eat for free.
///
/// So the portion follows the bar, the same way a magazine's rounds follow it
/// (§4.2). Nothing has to be restored because nothing was ever deferred.
///
/// Worked out from the fraction rather than counted down per tick: a tick that
/// arrives late, or twice in one frame, cannot make a player eat more than
/// they had.
class MealPlan {
  const MealPlan({
    required this.uid,
    required this.portionAtStart,
    required this.kcal,
    required this.waterMl,
    this.applied = 0,
  });

  /// §11.1: which piece. Never the item id — a half-drunk bottle beside two
  /// full ones is one row being emptied and two that are not.
  final String? uid;

  /// How much of it there was when the tap happened. A bottle already half
  /// drunk is half a bottle of water, and half again is a quarter.
  final double portionAtStart;

  /// What a whole one of these is worth (§2.2).
  final double kcal;
  final double waterMl;

  /// How much of the meal has already been swallowed and paid for.
  final double applied;

  double portionAt(double progress) =>
      portionAtStart * (1 - progress.clamp(0.0, 1.0));

  MealPlan appliedTo(double share) => MealPlan(
    uid: uid,
    portionAtStart: portionAtStart,
    kcal: kcal,
    waterMl: waterMl,
    applied: share,
  );
}

class FillPlan {
  const FillPlan({required this.itemId, required this.from, required this.to});

  final String itemId;
  final int from;
  final int to;

  int roundsAt(double progress) =>
      (from + (to - from) * progress.clamp(0.0, 1.0)).round();
}
