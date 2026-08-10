import 'package:arls_za/devtools/session_recorder.dart';
import 'package:arls_za/location/position_fix.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// A recording exists so a bug report is reproducible: seed plus event stream
/// must land on the same state every time (§11.2).
void main() {
  const constants = SimConstants(
    bloodMaxMl: 5319,
    waterDailyMl: 2800,
    caloriesDailyKcal: 2450,
    restingHeartRate: 70,
    maxHeartRate: 187,
  );

  final t0 = DateTime.utc(2026, 8, 10, 12);

  SimState initial() => SimState(
    lastUpdate: t0,
    bloodMl: constants.bloodMaxMl,
    waterMl: constants.waterDailyMl,
    caloriesKcal: constants.caloriesDailyKcal,
    heartRateBpm: 70,
    sleepDebtSeconds: 0,
    zone: MetabolicZone.open,
    rngCursor: 0,
  );

  RecordingHeader header({int seed = 777}) => RecordingHeader(
    version: kRecordingVersion,
    rngSeed: seed,
    startedAt: t0,
    constants: constants,
    initialState: initial(),
    note: 'test',
  );

  SessionRecorder recorderWithWalk() {
    final recorder = SessionRecorder(header: header());
    for (var i = 1; i <= 10; i++) {
      recorder.addFix(
        PositionFix(
          latitude: 52.4064 + i * 0.0001,
          longitude: 16.9252,
          accuracyM: 5,
          timestamp: t0.add(Duration(minutes: i)),
        ),
      );
    }
    recorder.addMarker(
      'coś tu się dzieje',
      t0.add(const Duration(minutes: 11)),
    );
    return recorder;
  }

  group('recording', () {
    test('encodes as JSON Lines with the header first', () {
      final encoded = recorderWithWalk().encode();
      final lines = encoded.trim().split('\n');

      expect(lines.first, contains('"rngSeed":777'));
      expect(lines, hasLength(12));
      expect(lines[1], contains('"k":"fix"'));
    });

    test('round-trips', () {
      final original = recorderWithWalk();
      final decoded = Recording.decode(original.encode());

      expect(decoded.header.rngSeed, 777);
      expect(decoded.header.initialState.sameValues(initial()), isTrue);
      expect(decoded.events, hasLength(original.events.length));
      expect(decoded.events.last.kind, RecordedEventKind.marker);
      expect(decoded.events.last.payload['label'], 'coś tu się dzieje');
    });

    test('drops the oldest events past the ceiling', () {
      final recorder = SessionRecorder(header: header(), maxEvents: 5);
      for (var i = 0; i < 12; i++) {
        recorder.addMarker('$i', t0.add(Duration(seconds: i)));
      }

      expect(recorder.events, hasLength(5));
      expect(recorder.droppedEvents, 7);
      expect(
        recorder.events.last.payload['label'],
        '11',
        reason: 'a bug report cares about the end of the run',
      );
    });

    test('survives being cut off mid-line, which is the point of JSONL', () {
      final encoded = recorderWithWalk().encode();
      final truncated = encoded.substring(0, encoded.length - 30);

      final decoded = Recording.decode(truncated);

      expect(
        decoded.events.length,
        greaterThanOrEqualTo(10),
        reason: 'a crash costs the last event, not the file',
      );
    });

    test('rejects an empty or unreadable file', () {
      expect(
        () => Recording.decode(''),
        throwsA(isA<RecordingParseException>()),
      );
      expect(
        () => Recording.decode('not json\n'),
        throwsA(isA<RecordingParseException>()),
      );
    });

    test('refuses a recording from a newer build', () {
      final future = RecordingHeader(
        version: kRecordingVersion + 1,
        rngSeed: 1,
        startedAt: t0,
        constants: constants,
        initialState: initial(),
      );
      final source = SessionRecorder(header: future).encode();

      expect(
        () => Recording.decode(source),
        throwsA(
          isA<RecordingParseException>().having(
            (e) => e.message,
            'message',
            contains('newer'),
          ),
        ),
      );
    });
  });

  group('replay', () {
    test('is deterministic — two replays land on the same state', () {
      final recording = Recording.decode(recorderWithWalk().encode());

      final first = replay(recording);
      final second = replay(recording);

      expect(first.finalState.sameValues(second.finalState), isTrue);
      expect(first.finalState.lastUpdate, second.finalState.lastUpdate);
      expect(first.eventsApplied, second.eventsApplied);
    });

    test('advances the simulation to the last event', () {
      final recording = Recording.decode(recorderWithWalk().encode());

      final result = replay(recording);

      expect(result.finalState.lastUpdate, t0.add(const Duration(minutes: 11)));
      expect(result.fixes, hasLength(10));
      expect(
        result.finalState.caloriesKcal,
        lessThan(constants.caloriesDailyKcal),
        reason: 'eleven minutes of metabolism has to show up',
      );
    });

    test('applies a zone change at the moment it was recorded', () {
      final recorder = SessionRecorder(header: header())
        ..add(
          RecordedEvent(
            kind: RecordedEventKind.zone,
            at: t0.add(const Duration(hours: 1)),
            payload: {'zone': MetabolicZone.shelter.wire},
          ),
        )
        ..addMarker('koniec', t0.add(const Duration(hours: 2)));

      final result = replay(Recording.decode(recorder.encode()));

      expect(result.finalState.zone, MetabolicZone.shelter);

      // One hour in the open at 100%, one in the shelter at 35%.
      final burned =
          constants.caloriesDailyKcal - result.finalState.caloriesKcal;
      final hourly = constants.caloriesDailyKcal / 24;
      expect(burned, closeTo(hourly * 1.35, 1e-6));
    });

    test('applies a forced physiological value', () {
      final recorder = SessionRecorder(header: header())
        ..add(
          RecordedEvent(
            kind: RecordedEventKind.forceVitals,
            at: t0.add(const Duration(minutes: 5)),
            payload: {'bloodMl': 2000.0, 'heartRateBpm': 165.0},
          ),
        );

      final result = replay(Recording.decode(recorder.encode()));

      expect(result.finalState.bloodMl, 2000.0);
      expect(result.finalState.heartRateBpm, 165.0);
    });

    test('an empty recording replays to the initial state', () {
      final recording = Recording.decode(
        SessionRecorder(header: header()).encode(),
      );

      final result = replay(recording);

      expect(result.eventsApplied, 0);
      expect(result.finalState.sameValues(initial()), isTrue);
    });

    test('markers and scale changes do not alter the simulation', () {
      final withNoise = SessionRecorder(header: header())
        ..add(
          RecordedEvent(
            kind: RecordedEventKind.timeScale,
            at: t0.add(const Duration(minutes: 1)),
            payload: {'factor': 3600},
          ),
        )
        ..addMarker('x', t0.add(const Duration(minutes: 2)))
        ..add(
          RecordedEvent(
            kind: RecordedEventKind.signal,
            at: t0.add(const Duration(minutes: 3)),
            payload: {'quality': 'none'},
          ),
        );

      final quiet = SessionRecorder(header: header())
        ..addMarker('end', t0.add(const Duration(minutes: 3)));

      final noisy = replay(Recording.decode(withNoise.encode()));
      final plain = replay(Recording.decode(quiet.encode()));

      expect(
        noisy.finalState.sameValues(plain.finalState),
        isTrue,
        reason: 'the time scale is already baked into the event timestamps',
      );
    });
  });
}
