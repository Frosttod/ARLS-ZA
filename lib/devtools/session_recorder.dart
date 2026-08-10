/// Deterministic session recording and replay (design doc §11.2).
///
/// The design document calls this "kluczowe przy zgłoszeniach błędów", and the
/// reason is arithmetic: a bug that needs a specific position, a specific heart
/// rate and a specific loot roll to appear is not reproducible by description.
/// A seed plus the event stream is.
///
/// Format is JSON Lines — one header, then one event per line. Append-only, so
/// a recording survives the crash it was made to capture; a truncated last line
/// costs one event, not the file.
library;

import 'dart:convert';

import '../location/position_fix.dart';
import '../sim/tick.dart';
import 'dev_mode.dart';

const int kRecordingVersion = 1;

/// Everything needed to reproduce a run bit for bit.
class RecordingHeader {
  const RecordingHeader({
    required this.version,
    required this.rngSeed,
    required this.startedAt,
    required this.constants,
    required this.initialState,
    this.note,
    this.appVersion,
  });

  final int version;

  /// Root seed of the profile. Without it nothing else replays (§11).
  final int rngSeed;

  final DateTime startedAt;
  final SimConstants constants;
  final SimState initialState;

  /// What the operator was doing when they hit record.
  final String? note;

  final String? appVersion;

  Map<String, Object?> toJson() => {
    'version': version,
    'rngSeed': rngSeed,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'constants': constants.toJson(),
    'initialState': initialState.toJson(),
    if (note != null) 'note': note,
    if (appVersion != null) 'appVersion': appVersion,
  };

  factory RecordingHeader.fromJson(Map<String, Object?> json) =>
      RecordingHeader(
        version: (json['version'] as num?)?.toInt() ?? 0,
        rngSeed: (json['rngSeed']! as num).toInt(),
        startedAt: DateTime.parse(json['startedAt']! as String).toUtc(),
        constants: SimConstants.fromJson(
          json['constants']! as Map<String, Object?>,
        ),
        initialState: SimState.fromJson(
          json['initialState']! as Map<String, Object?>,
        ),
        note: json['note'] as String?,
        appVersion: json['appVersion'] as String?,
      );
}

/// What kind of thing happened.
enum RecordedEventKind {
  /// A position arrived from the source — simulated or real.
  fix('fix'),

  /// The metabolic zone changed (§2.1).
  zone('zone'),

  /// The operator changed the time multiplier.
  timeScale('scale'),

  /// The operator forced a physiological value from the panel.
  forceVitals('force'),

  /// Signal state changed (§3.2).
  signal('signal'),

  /// A marker the operator dropped: "it happened here".
  marker('marker');

  const RecordedEventKind(this.wire);

  final String wire;

  static RecordedEventKind fromWire(String value) => values.firstWhere(
    (k) => k.wire == value,
    orElse: () => RecordedEventKind.marker,
  );
}

class RecordedEvent {
  const RecordedEvent({
    required this.kind,
    required this.at,
    this.payload = const {},
  });

  final RecordedEventKind kind;

  /// Simulation time, not wall time. Replaying under a different time scale
  /// must land on the same state.
  final DateTime at;

  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'k': kind.wire,
    't': at.toUtc().toIso8601String(),
    if (payload.isNotEmpty) 'p': payload,
  };

  factory RecordedEvent.fromJson(Map<String, Object?> json) => RecordedEvent(
    kind: RecordedEventKind.fromWire(json['k']! as String),
    at: DateTime.parse(json['t']! as String).toUtc(),
    payload: (json['p'] as Map<String, Object?>?) ?? const {},
  );

  /// Convenience for the most common event.
  factory RecordedEvent.fix(PositionFix fix) => RecordedEvent(
    kind: RecordedEventKind.fix,
    at: fix.timestamp,
    payload: fix.toJson(),
  );
}

/// Collects events in memory and serialises them on demand.
class SessionRecorder {
  SessionRecorder({required this.header, this.maxEvents = 100000}) {
    assertDevTools('SessionRecorder');
  }

  final RecordingHeader header;

  /// Ceiling on retained events. A session left recording at ×3600 overnight
  /// would otherwise eat the heap; the oldest events are dropped first, since
  /// a bug report cares about the end of the run.
  final int maxEvents;

  final _events = <RecordedEvent>[];
  var _dropped = 0;

  List<RecordedEvent> get events => List.unmodifiable(_events);

  /// How many events fell off the front of the buffer.
  int get droppedEvents => _dropped;

  void add(RecordedEvent event) {
    _events.add(event);
    if (_events.length > maxEvents) {
      _events.removeAt(0);
      _dropped++;
    }
  }

  void addFix(PositionFix fix) => add(RecordedEvent.fix(fix));

  void addMarker(String label, DateTime at) => add(
    RecordedEvent(
      kind: RecordedEventKind.marker,
      at: at,
      payload: {'label': label},
    ),
  );

  void clear() {
    _events.clear();
    _dropped = 0;
  }

  /// JSON Lines: header first, then one event per line.
  String encode() {
    final buffer = StringBuffer()..writeln(jsonEncode(header.toJson()));
    for (final event in _events) {
      buffer.writeln(jsonEncode(event.toJson()));
    }
    return buffer.toString();
  }
}

class RecordingParseException implements Exception {
  RecordingParseException(this.message);

  final String message;

  @override
  String toString() => 'RecordingParseException: $message';
}

/// A recording loaded back from disk.
class Recording {
  const Recording({required this.header, required this.events});

  final RecordingHeader header;
  final List<RecordedEvent> events;

  static Recording decode(String source) {
    final lines = const LineSplitter()
        .convert(source)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      throw RecordingParseException('empty recording');
    }

    final RecordingHeader header;
    try {
      header = RecordingHeader.fromJson(
        jsonDecode(lines.first) as Map<String, Object?>,
      );
    } on Object catch (e) {
      throw RecordingParseException('unreadable header: $e');
    }

    if (header.version > kRecordingVersion) {
      throw RecordingParseException(
        'recording version ${header.version} is newer than this build '
        'supports ($kRecordingVersion)',
      );
    }

    final events = <RecordedEvent>[];
    for (var i = 1; i < lines.length; i++) {
      try {
        events.add(
          RecordedEvent.fromJson(jsonDecode(lines[i]) as Map<String, Object?>),
        );
      } on Object {
        // A half-written last line is the normal outcome of recording through
        // a crash — exactly the case this format exists for. Stop, keep what
        // parsed, and let the caller work with it.
        if (i == lines.length - 1) break;
        throw RecordingParseException('corrupt event on line ${i + 1}');
      }
    }

    return Recording(header: header, events: events);
  }
}

/// Result of replaying a recording.
class ReplayResult {
  const ReplayResult({
    required this.finalState,
    required this.eventsApplied,
    required this.fixes,
  });

  final SimState finalState;
  final int eventsApplied;

  /// Positions seen during the replay, for drawing the track on the map.
  final List<PositionFix> fixes;
}

/// Replays a recording through the same tick function the game uses.
///
/// Deterministic by construction: [advance] is pure, the events carry
/// simulation timestamps rather than wall time, and the seed comes from the
/// header. Two replays of the same file produce the same [ReplayResult].
ReplayResult replay(Recording recording) {
  var state = recording.header.initialState;
  final fixes = <PositionFix>[];
  var applied = 0;

  for (final event in recording.events) {
    // Advance to the event's moment before applying it, so ordering is
    // unambiguous: the world reaches the time, then the thing happens.
    final gap = event.at.difference(state.lastUpdate);
    if (gap > Duration.zero) {
      state = advance(
        state: state,
        constants: recording.header.constants,
        elapsed: gap,
      ).state;
    }

    switch (event.kind) {
      case RecordedEventKind.fix:
        fixes.add(PositionFix.fromJson(event.payload));

      case RecordedEventKind.zone:
        final zone = event.payload['zone'];
        if (zone is String) {
          state = state.copyWith(zone: MetabolicZone.fromWire(zone));
        }

      case RecordedEventKind.forceVitals:
        state = state.copyWith(
          bloodMl: (event.payload['bloodMl'] as num?)?.toDouble(),
          waterMl: (event.payload['waterMl'] as num?)?.toDouble(),
          caloriesKcal: (event.payload['caloriesKcal'] as num?)?.toDouble(),
          heartRateBpm: (event.payload['heartRateBpm'] as num?)?.toDouble(),
          sleepDebtSeconds: (event.payload['sleepDebtSeconds'] as num?)
              ?.toInt(),
        );

      case RecordedEventKind.timeScale:
      case RecordedEventKind.signal:
      case RecordedEventKind.marker:
        // Recorded for the operator reading the log; they do not change the
        // simulation, because the time scale is already baked into the event
        // timestamps.
        break;
    }

    applied++;
  }

  return ReplayResult(finalState: state, eventsApplied: applied, fixes: fixes);
}
