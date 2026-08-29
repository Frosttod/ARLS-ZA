/// Everything hostile that is out there, and what it is doing (§5.5, §6.1a).
///
/// ⚠️ **Not persisted, and that is a rule rather than an omission.** §6.4 makes
/// the Walkers afresh every time the game runs — a Walker is not a place —
/// so writing them down would only mean loading yesterday's fight onto a
/// street the player has already left. The one thing that *does* survive is
/// [Pursuit]: whether the street is stirred up, which the loop keeps, because
/// closing the app must not be a way out of a chase.
///
/// What is here:
///
///   - the session itself, and the clock it was last stepped against;
///   - **who is drawn**, with §5.5.6's hysteresis so an enemy on the edge does
///     not flicker in and out with every step;
///   - **how bad it is**, for the one reading the HUD shows;
///   - the last two minutes of the fight in words, because of one sentence
///     after a walk: *"I do not know how I died."*
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../combat/combat_session.dart';
import '../../combat/blows_away.dart';
import '../../combat/awareness.dart';
import '../../combat/enemy.dart';
import '../../combat/enemy_spawner.dart' show kActiveRadiusM;

// ⚠️ The one reading the HUD draws, and the only thing this file takes from
// the interface layer. It is a value — a count, a distance and a flag — and
// lives beside the widget that shows it because that is the only place it is
// ever read. Importing the type is not importing the widget.
import '../../ui/hud.dart' show ThreatReading;
import '../../map/geometry.dart';

class CombatController extends ChangeNotifier {
  CombatController();

  /// §5.5, §6.1a: the fight, as it stands.
  CombatSession get session => _session;
  CombatSession _session = const CombatSession(seed: 0);

  set session(CombatSession next) {
    _session = next;
    notifyListeners();
  }

  /// When the enemies were last stepped, so a gap in the tick is a gap in
  /// their walk rather than a jump.
  DateTime? steppedAt;

  /// §6.2: when each of them last swung, so the interval between blows is the
  /// one on the table rather than one a frame.
  ///
  /// ⚠️ Here rather than on the screen. It is a fact about the fight, it has
  /// to be forgotten when the fight ends, and a map of timestamps living on a
  /// widget is a map nobody clears when the character dies.
  final Map<String, DateTime> _lastBlow = {};

  /// Whether [id] may swing at [now], given how long the kind takes.
  bool mayStrike(String id, DateTime now, Duration interval) {
    final last = _lastBlow[id];
    return last == null || now.difference(last) >= interval;
  }

  /// Records that [id] just swung.
  void struck(String id, DateTime now) => _lastBlow[id] = now;

  /// Nothing is in reach any more, so nobody is mid-swing.
  void noneInReach() => _lastBlow.clear();

  /// §5.5.3, §9.2: what everything at arm's length did while the screen was
  /// off, and a clean slate afterwards.
  ///
  /// ⚠️ The cooldowns are cleared whatever the answer. They were taken before
  /// the gap and mean nothing after it — leaving them would let a crowd that
  /// had just been charged for five minutes swing again on the first tick.
  BlowsAway settleAway({
    required Duration away,
    required GeoPoint at,
    required double bloodMl,
    required double bloodMaxMl,
    required double protection,
    required bool mayGoDown,
    required int seed,
  }) {
    final hurt = blowsWhileAway(
      inReach: enemiesInReach(enemies, at),
      away: away,
      bloodMl: bloodMl,
      bloodMaxMl: bloodMaxMl,
      protection: protection,
      mayGoDown: mayGoDown,
      random: Random(seed ^ away.inSeconds),
    );

    _lastBlow.clear();
    return hurt;
  }

  List<Enemy> get enemies => _session.enemies;

  /// Starts a fresh street for this character.
  void reseed(int seed) {
    session = CombatSession(seed: seed);
    _shown.clear();
    _lastBlow.clear();
  }

  // ------------------------------------------------------------- drawing ---

  /// §5.5.6: which enemies the map should be drawing right now.
  ///
  /// ⚠️ **With hysteresis, and that is the whole point of the method.** One
  /// standing exactly on the edge of the active radius would otherwise appear
  /// and vanish with every step the player takes, which on a phone reads as
  /// the game being broken rather than as a Walker being far away. Something
  /// already drawn keeps being drawn a quarter further out than it took to
  /// appear.
  List<Enemy> visible(GeoPoint? at) {
    if (at == null) return const [];

    final shown = <String>{};
    final visible = <Enemy>[];

    for (final enemy in _session.enemies) {
      if (enemy.isDead) continue;

      final limit = _shown.contains(enemy.id)
          ? kActiveRadiusM * 1.25
          : kActiveRadiusM;
      if (enemy.position.distanceTo(at) > limit) continue;

      shown.add(enemy.id);
      visible.add(enemy);
    }

    _shown
      ..clear()
      ..addAll(shown);

    return visible;
  }

  final Set<String> _shown = {};

  /// §5.5: how bad it is right now, or null for a quiet street.
  ///
  /// Only what is actually engaged — something idle or walking home is not a
  /// threat, it is scenery, and a reading that counted it would be crying wolf
  /// on every street with anything on it.
  ThreatReading? threatAt(GeoPoint? at) {
    if (at == null) return null;

    // ⚠️ **Najbliższy, cokolwiek robi.** Pasek liczył wyłącznie tych, którzy
    // już ruszyli, więc Kroczący stojący osiemdziesiąt metrów dalej i jeszcze
    // nieświadomy nie istniał na ekranie — a to jest dokładnie ten, o którym
    // gracz chciałby wiedzieć, póki jeszcze ma wybór.
    var nearest = double.infinity;
    for (final enemy in _session.near(at)) {
      if (enemy.isDead) continue;

      final distance = enemy.position.distanceTo(at);
      if (distance < nearest) nearest = distance;
    }
    if (nearest > ThreatBand.watch.metres) return null;

    // Ilu z nich naprawdę idzie po gracza. Zero znaczy „są, ale jeszcze nie
    // wiedzą" — i to jest inna wiadomość niż „trzech biegnie".
    final engaged = [
      for (final enemy in _session.near(at))
        if (!enemy.isDead &&
            enemy.state != EnemyState.idle &&
            enemy.state != EnemyState.returning)
          enemy,
    ];

    var sprinting = false;
    for (final enemy in engaged) {
      if (enemy.budget > Duration.zero) sprinting = true;
    }

    return ThreatReading(
      count: engaged.length,
      nearby: _session.near(at).where((enemy) => !enemy.isDead).length,
      nearestM: nearest,
      anySprinting: sprinting,
    );
  }

  // --------------------------------------------------------------- words ---

  /// §12: the last two minutes of the fight, in the player's own language.
  ///
  /// ⚠️ Kept because of one sentence after a walk: *"I do not know how I
  /// died."* Every line of it was on screen at the time and every line was
  /// gone by the time it mattered — a notice lasts four seconds, and a death
  /// is exactly the moment somebody wants the last minute back.
  List<String> get log => List.unmodifiable(_log);

  final List<String> _log = [];

  void say(String line) {
    _log.add(line);

    // Thirty lines is about two minutes of a bad fight. Older ones go rather
    // than being kept: what is wanted is how this ended, not how it began.
    if (_log.length > 30) _log.removeAt(0);
  }

  void forget() => _log.clear();
}
