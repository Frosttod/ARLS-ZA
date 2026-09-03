/// Turning raw fixes into movement the simulation can trust (design doc §3.2).
///
/// A phone lying still on a table reports a position that wanders by several
/// metres a minute. Fed straight into §2.2 that wander is a walk: the character
/// burns calories all night while its owner sleeps. Everything here exists to
/// stop that without also throwing away real slow movement, which is the harder
/// half — a limping character carrying 25 kg moves at half a metre a second and
/// must still be credited for it.
///
/// Three stages, in this order:
///
/// 1. **Accuracy gate.** A fix worse than 25 m says nothing useful about a
///    person on foot, so it is dropped rather than smoothed.
/// 2. **Kalman smoothing.** A constant-position filter with process noise. It
///    pulls scatter towards the estimate while still following a real walk
///    within a couple of fixes.
/// 3. **Stationary detection.** Wander and travel are told apart by shape, not
///    by distance alone: see [FixFilter.deadZoneM].
///
/// Pure and Flutter-free, so it runs under `dart test` and inside the tick
/// isolate.
library;

import 'dart:math' as math;

import 'position_fix.dart';

/// Why a fix was thrown away.
enum FixRejection {
  /// Worse than the accuracy gate (§3.2).
  accuracy,

  /// Reported by a mock provider. Dropped here so nothing downstream ever sees
  /// it, and reported separately to the integrity monitor (§3.4).
  mocked,

  /// Timestamped at or before the previous fix. Providers do repeat themselves
  /// after a warm restart, and a zero or negative interval would divide by zero
  /// on the way to a speed.
  outOfOrder,
}

/// What the filter made of one raw fix.
sealed class FixOutcome {
  const FixOutcome();
}

/// The fix was dropped. [fix] is the raw reading, kept for the developer
/// overlay — the player never sees it.
class FixDropped extends FixOutcome {
  const FixDropped({required this.reason, required this.fix});

  final FixRejection reason;
  final PositionFix fix;
}

/// The fix was accepted. [fix] carries the smoothed coordinates.
class FixAccepted extends FixOutcome {
  const FixAccepted({
    required this.fix,
    required this.movedM,
    required this.speedMps,
    required this.stationary,
    required this.interval,
  });

  /// The smoothed position, not the raw one.
  final PositionFix fix;

  /// Distance credited as real movement since the previous accepted fix. Zero
  /// while stationary.
  final double movedM;

  /// [movedM] over [interval]. Zero while stationary, so §2.2 sees MET 1.0.
  final double speedMps;

  /// True when the position moved but the person did not.
  final bool stationary;

  final Duration interval;
}

/// §5.6.1: ile waży jeden świeży odczyt przy uśrednianiu prędkości.
///
/// ⚠️ **Zgłoszone z terenu: „idę stałym tempem, a licznik hałasu pokazuje
/// 40 m" — czyli bieg, którego nie było.** Prędkość liczyła się jako jedna
/// różnica dwóch punktów (`przesunięcie / interwał`) — pochodna z sygnału,
/// którego samo położenie jest wygładzone Kalmanem, ale prędkość z niego
/// liczona nie była wygładzona wcale.
///
/// ⚠️ **Zwykły szum w granicach zgłaszanej dokładności to nie jest ten
/// przypadek** — sprawdzone: pojedynczy odczyt uczciwie zgłaszający dwadzieścia
/// metrów błędu, nawet przesunięty o piętnaście metrów wzdłuż trasy, nie
/// przepycha marszu przez próg. Winny jest odczyt, który **kłamie o własnej
/// dokładności** — zgłasza osiem–dziesięć metrów, mając naprawdę
/// dwadzieścia pięć–trzydzieści pięć. To nie jest wymysł: odbiornik pod
/// drzewami albo między budynkami traci wielotorowość na chwilę i dogania
/// własną ocenę błędu o odczyt później, a dokładnie tam kadencja „w marszu"
/// (5 s) zdarza się w terenie. Filtr pozycji ufa zgłoszonej dokładności
/// dosłownie — nie ma jak sprawdzić, że kłamie — więc bierze taki odczyt z
/// wysokim wzmocnieniem i przesuwa się za nim naprawdę daleko.
///
/// Zmierzone na tym właśnie przypadku: rześki marsz (6 km/h), jeden odczyt na
/// dziewiątym kroku zgłasza osiem metrów dokładności, mając dwadzieścia pięć
/// błędu. Nieuśredniona różnica dwóch punktów skacze do **13,6 km/h** —
/// niemal dwa razy więcej niż prawda. Waga jeden do pięciu ścina to do
/// **6,85 km/h**, z zapasem pod progiem biegu (7,2 km/h) nawet przy błędzie
/// sięgającym trzydziestu pięciu metrów.
///
/// Cena: prawdziwa zmiana tempa (naprawdę zaczęte bieganie) dochodzi do
/// właściwej wartości po czterech odczytach — dwudziestu sekundach przy
/// marszu, czterech przy walce, gdzie kadencja i tak przyspiesza do jednej
/// sekundy.
const double kSpeedSmoothing = 0.2;

/// Smooths a stream of fixes and decides what counts as movement.
///
/// One instance per session: it carries the estimate and the recent path.
class FixFilter {
  FixFilter({
    this.accuracyGateM = 25.0,
    this.deadZoneM = 8.0,
    this.window = const Duration(seconds: 10),
    this.minSamples = 7,
    this.straightnessGate = 0.7,
    this.processNoiseMps = 2.0,
    this.speedSmoothing = kSpeedSmoothing,
  });

  /// §3.2. A fix with a worse claimed accuracy is dropped outright.
  final double accuracyGateM;

  /// §3.2. Net displacement under this over [window] is a candidate for
  /// wander — but only a candidate, because a slow walk covers less than 8 m in
  /// ten seconds too. What separates them is [straightnessGate].
  final double deadZoneM;

  /// How far back the shape of the path is measured.
  final Duration window;

  /// The window is widened if it holds fewer than this many fixes. At the
  /// resting cadence of 0.05 Hz a ten-second window would hold one point, and
  /// a single point has no shape to judge. Seven is comfortably past the point at which
  /// scatter reliably scores below [straightnessGate]: with three points, two
  /// consecutive noise steps in a similar direction look exactly like a walk.
  /// Seven costs about half a minute of warm-up at the start of a session and
  /// brings the leak to under a metre per ten minutes of standing still.
  final int minSamples;

  /// Net displacement over path length, from 0 (came straight back) to 1 (a
  /// straight line). Walking scores near 1 even when slow; a phone scattering
  /// around one spot scores low, because every step it takes it also takes
  /// back. The gate only decides the ambiguous middle — anything that has
  /// covered [deadZoneM] net over the window is movement whatever its shape.
  final double straightnessGate;

  /// Expected speed of the thing being tracked, in metres per second, used as
  /// the Kalman process noise. Roughly a brisk walk: high enough to follow a
  /// runner within a couple of fixes, low enough to bury scatter while
  /// standing.
  final double processNoiseMps;

  /// §5.6.1: waga jednego świeżego odczytu przy uśrednianiu prędkości —
  /// patrz [kSpeedSmoothing].
  final double speedSmoothing;

  double? _estLat;
  double? _estLon;

  /// §5.6.1: prędkość, uśredniona osobno od pozycji. Null dopóki nic się
  /// jeszcze nie ruszało — pierwszy odczyt ruchu ustawia ją wprost, bez
  /// uśredniania z niczym.
  double? _speedEstimateMps;

  /// Positional variance of the estimate, in square metres.
  double _variance = 0;

  DateTime? _lastAccepted;
  PositionFix? _previous;

  /// Recent smoothed positions, oldest first, used to judge the shape of the
  /// path.
  final List<PositionFix> _path = [];

  /// The smoothed position, or null before the first accepted fix.
  PositionFix? get estimate => _previous;

  /// Forgets everything. Used when the source restarts, so a fix from before a
  /// long pause is not smoothed against one from after it.
  void reset() {
    _estLat = null;
    _estLon = null;
    _variance = 0;
    _lastAccepted = null;
    _previous = null;
    _path.clear();
    _speedEstimateMps = null;
  }

  FixOutcome accept(PositionFix raw) {
    if (raw.isMocked) {
      return FixDropped(reason: FixRejection.mocked, fix: raw);
    }
    if (raw.accuracyM > accuracyGateM) {
      return FixDropped(reason: FixRejection.accuracy, fix: raw);
    }

    final previousAt = _lastAccepted;
    if (previousAt != null && !raw.timestamp.isAfter(previousAt)) {
      return FixDropped(reason: FixRejection.outOfOrder, fix: raw);
    }

    final interval = previousAt == null
        ? Duration.zero
        : raw.timestamp.difference(previousAt);

    final smoothed = _smooth(raw, interval);
    final previous = _previous;

    _lastAccepted = raw.timestamp;
    _previous = smoothed;
    _remember(smoothed);

    if (previous == null) {
      // §5.6.1: bez tego stary uśredniacz zostałby z prędkością z poprzedniej
      // sesji ruchu i przez chwilę kłamałby w drugą stronę.
      _speedEstimateMps = null;
      return FixAccepted(
        fix: smoothed,
        movedM: 0,
        speedMps: 0,
        stationary: true,
        interval: interval,
      );
    }

    if (_looksStationary()) {
      _speedEstimateMps = null;
      return FixAccepted(
        fix: smoothed,
        movedM: 0,
        speedMps: 0,
        stationary: true,
        interval: interval,
      );
    }

    final moved = previous.distanceTo(smoothed);
    final seconds = interval.inMicroseconds / Duration.microsecondsPerSecond;
    final instant = seconds > 0 ? moved / seconds : 0.0;

    // §5.6.1: pierwszy odczyt ruchu po bezruchu ustawia uśredniacz wprost —
    // uśrednianie z zerem opóźniłoby wykrycie prawdziwego startu, a to jest
    // dokładnie odwrotny błąd od tego, który ten uśredniacz naprawia.
    //
    // ⚠️ **Tłumione są tylko wzrosty.** Zejście w dół przepuszczane jest od
    // razu — bo fałszywy odczyt potrafi tylko *dokleić* metry, których nie
    // było, nigdy ich odjąć: zwolnienie czy prawdziwe zatrzymanie nigdy nie
    // jest tym samym rodzajem kłamstwa co skok. Symetryczne tłumienie
    // znalazło się w tym pliku i zaraz je wyleciało: kadencja próbkowania
    // czeka na prędkość poniżej 0,5 km/h, żeby przejść na rzadsze pytanie
    // odbiornika (§3.3), a filtr pozycji i tak już gaśnie powoli po biegu —
    // drugie tłumienie na to samo dokładało spowolnienie do spowolnienia i
    // zdarzało się, że kadencja nie schodziła w sto sekund testu, w którym
    // dotąd schodziła.
    final speed = _speedEstimateMps == null || instant < _speedEstimateMps!
        ? instant
        : _speedEstimateMps! + speedSmoothing * (instant - _speedEstimateMps!);
    _speedEstimateMps = speed;

    return FixAccepted(
      fix: smoothed,
      movedM: moved,
      speedMps: speed,
      stationary: false,
      interval: interval,
    );
  }

  void _remember(PositionFix fix) {
    _path.add(fix);
    while (_path.length > minSamples &&
        fix.timestamp.difference(_path.first.timestamp) > window) {
      _path.removeAt(0);
    }
  }

  /// Wander or travel, judged on the shape of the recent path.
  ///
  /// Both conditions have to hold. A short path that is straight is a slow walk
  /// and gets credited; a long path that doubles back is scatter, and so is a
  /// short one.
  bool _looksStationary() {
    if (_path.length < 2) return true;

    // ⚠️ The dead zone is never smaller than the uncertainty of the fixes it
    // is judging. Found at a kitchen table: indoors the receiver reports
    // fifteen to twenty-five metres of accuracy and wanders about that much,
    // which cleared a fixed eight-metre gate and charged a sitting player for
    // a walk — heart rate, water and calories, all for a phone on a worktop.
    // Movement smaller than the error bar is not movement.
    final uncertainty = _path
        .map((fix) => fix.accuracyM)
        .reduce((a, b) => a > b ? a : b);
    final gate = uncertainty > deadZoneM ? uncertainty : deadZoneM;

    // Distance settles it on its own. Asking for [minSamples] first would make
    // the warm-up cost proportional to the cadence: at one fix a minute the
    // filter would swallow the first seven minutes of a walk.
    final net = _path.first.distanceTo(_path.last);
    if (net >= gate) return false;

    // Under the dead zone the answer is in the shape, and a short path has no
    // shape worth reading.
    if (_path.length < minSamples) return true;

    var pathLength = 0.0;
    for (var i = 1; i < _path.length; i++) {
      pathLength += _path[i - 1].distanceTo(_path[i]);
    }
    if (pathLength <= 0) return true;

    return net / pathLength < straightnessGate;
  }

  /// One-dimensional Kalman update applied to each coordinate.
  ///
  /// The state is position only; movement is modelled as process noise rather
  /// than as a velocity term. A velocity model tracks a constant walk better,
  /// but overshoots every corner and every stop — and stops are what this
  /// filter exists to get right.
  PositionFix _smooth(PositionFix raw, Duration interval) {
    final accuracy = raw.accuracyM <= 0 ? 1.0 : raw.accuracyM;

    if (_estLat == null) {
      _estLat = raw.latitude;
      _estLon = raw.longitude;
      _variance = accuracy * accuracy;
      return raw;
    }

    final seconds = interval.inMicroseconds / Duration.microsecondsPerSecond;
    if (seconds > 0) {
      _variance += seconds * processNoiseMps * processNoiseMps;
    }

    final gain = _variance / (_variance + accuracy * accuracy);
    _estLat = _estLat! + gain * (raw.latitude - _estLat!);
    _estLon = _estLon! + gain * (raw.longitude - _estLon!);
    _variance = (1 - gain) * _variance;

    return raw.copyWith(
      latitude: _estLat,
      longitude: _estLon,
      // The estimate is at least as good as the fix that produced it; keeping
      // the raw accuracy after smoothing would understate what we know.
      accuracyM: _variance <= 0 ? accuracy : math.sqrt(_variance),
    );
  }
}
