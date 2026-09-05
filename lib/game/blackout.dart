/// Being on the ground, and getting up again (§9.2, §9.2.1).
///
/// ⚠️ **Lived in `GameLoop`, and was the loop's largest tenant that is not the
/// loop.** Six fields and three transitions about §9 sat next to the clock,
/// the metabolic zone and §11.1's writer — all of which have to know *whether*
/// a character is down, and none of which have any business deciding it.
///
/// What stays in the loop is the pair of questions only the loop can answer:
/// whether the body has given out (§2.6's arithmetic) and whether §9.1 permits
/// dying right now (asleep in a pocket, or with no sky). What moved here is
/// everything that follows from the answer.
///
/// Pure and Flutter-free.
library;

import '../map/geometry.dart';
import '../sim/body.dart';
import '../sim/death.dart';
import '../sim/tick.dart';

/// The hour on the ground, the ten minutes after it, and where it happened.
class Blackout {
  Blackout({
    DateTime? downUntil,
    DateTime? graceUntil,
    GeoPoint? fellAt,
    bool dead = false,
    // ⚠️ Named without the underscore because a private named parameter is
    // not a thing Dart allows, which is what the lint below is about.
    // ignore_for_file: prefer_initializing_formals
  }) : _downUntil = downUntil,
       _graceUntil = graceUntil,
       _fellAt = fellAt,
       _dead = dead;

  DateTime? _downUntil;
  DateTime? _graceUntil;
  GeoPoint? _fellAt;
  bool _dead;
  DeathCause? _cause;
  bool _wentDown = false;
  bool _justWoke = false;

  DateTime? get downUntil => _downUntil;
  DateTime? get graceUntil => _graceUntil;
  GeoPoint? get fellAt => _fellAt;
  bool get isDead => _dead;
  DeathCause? get cause => _cause;

  /// True while nothing may be aimed, fired or searched.
  bool get onTheGround => _dead || _downUntil != null;

  /// Whether a fresh blackout can begin at all.
  bool get canFall => !_dead && _downUntil == null;

  /// §9: the body gave out. Returns nothing — the caller stages the row,
  /// because only it knows what else changed in the same tick.
  ///
  /// [at] is where the character fell: §9.2 drops the caches there and §9.2.1
  /// measures every later question about this blackout from it.
  void fall({
    required DeathCause because,
    required DeathMode mode,
    required DateTime now,
    required GeoPoint? at,
  }) {
    _cause = because;
    _wentDown = true;

    if (mode == DeathMode.hardcore) {
      _dead = true;
      return;
    }

    // §9.2: an hour on the ground, wall-clock, and it runs with the app
    // closed — being unconscious cannot require watching a screen.
    _downUntil = now.add(kUnconsciousFor);
    _fellAt = at;
  }

  /// §9.2.1: whether the hour is up and this is a place somebody can stand.
  bool isDue(DateTime now) {
    final until = _downUntil;
    return !_dead && until != null && !now.isBefore(until);
  }

  /// The hour is up but the player is on a bus, or the sky is gone.
  ///
  /// A deferral rather than a punishment, and it costs nothing further: waking
  /// somebody here would put the character where the player is not, and §0
  /// makes that the one thing this game may never do.
  void deferTo(DateTime now) => _downUntil = now.add(kWakeRetry);

  /// Up. Returns the state the character comes round in (§9.2).
  ///
  /// [at] is where the player physically is now — the other end of §9.2.1's
  /// measurement.
  SimState wake({
    required DateTime now,
    required GeoPoint? at,
    required SimState state,
    required SimConstants constants,
  }) {
    // The deadline is cleared in the same breath as the state is restored, so
    // nothing can run this twice.
    _downUntil = null;

    // §9.2.1: the grace is for somebody the street still thinks is lying
    // there. A player who woke three kilometres away moved, and the caches did
    // not go with them — see [grantsGrace].
    _graceUntil = grantsGrace(fellAt: _fellAt, wokeAt: at)
        ? now.add(kGraceAfterWaking)
        : null;
    _fellAt = null;
    _justWoke = true;

    return wokenFrom(state, constants);
  }

  /// §9.2: whether the ten minutes have just run out. True once, on the tick
  /// that ends them, so the caller knows the row is worth staging.
  bool graceOver(DateTime now) {
    final grace = _graceUntil;
    if (grace == null || now.isBefore(grace)) return false;

    _graceUntil = null;
    return true;
  }

  /// What the interface should show.
  DownState get state {
    if (_dead) return DownState.dead;
    if (_downUntil != null) return DownState.unconscious;
    return _graceUntil != null ? DownState.grace : DownState.none;
  }

  /// True once per blackout, for whoever has to scatter the kit.
  bool takeWentDown() {
    final was = _wentDown;
    _wentDown = false;
    return was;
  }

  /// True on the one tick the character came round.
  bool takeJustWoke() {
    final was = _justWoke;
    _justWoke = false;
    return was;
  }
}
