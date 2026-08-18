import 'package:arls_za/location/position_fix.dart';
import 'package:arls_za/location/position_source.dart';
import 'package:test/test.dart';

/// §3.2. What the player is told about the signal, which is a different
/// question from what the simulation trusts.
///
/// The warning exists to explain why the game is not doing what somebody
/// expects. A warning that appears while everything is working teaches them to
/// ignore it, and then it cannot do its job on the day it matters.

/// The base class with nothing behind it: no radio, no track, just the signal
/// bookkeeping under test.
class _Source extends BasePositionSource {
  _Source({super.degradeAfter, super.acquireGrace});

  @override
  PositionCadence get currentCadence => PositionCadence.moving;

  @override
  bool get tracksInBackground => false;

  @override
  bool get isSimulated => false;

  @override
  Future<void> start({
    PositionCadence cadence = PositionCadence.moving,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setCadence(PositionCadence cadence) async =>
      noteCadence(cadence);
}

void main() {
  final t0 = DateTime.utc(2026, 8, 14, 12);

  PositionFix fixAt(Duration after, {required double accuracyM}) => PositionFix(
    latitude: 52.4084,
    longitude: 16.9342,
    accuracyM: accuracyM,
    timestamp: t0.add(after),
  );

  group('starting up', () {
    test('a cold start says it is looking, not that something is wrong', () {
      // Five to thirty seconds and the first fixes are wide. That is a
      // receiver doing its job.
      final source = _Source();

      source.emitFix(fixAt(Duration.zero, accuracyM: 60));
      expect(source.currentSignal, PositionSignal.acquiring);

      source.emitFix(fixAt(const Duration(seconds: 20), accuracyM: 45));
      expect(source.currentSignal, PositionSignal.acquiring);

      source.dispose();
    });

    test('and gives up saying so once the grace is over', () {
      final source = _Source(acquireGrace: const Duration(seconds: 40));

      source.emitFix(fixAt(Duration.zero, accuracyM: 60));
      source.emitFix(fixAt(const Duration(seconds: 41), accuracyM: 60));

      expect(source.currentSignal, PositionSignal.degraded);
      source.dispose();
    });

    test('one accurate fix ends the wait immediately', () {
      final source = _Source();

      source.emitFix(fixAt(Duration.zero, accuracyM: 60));
      source.emitFix(fixAt(const Duration(seconds: 8), accuracyM: 12));

      expect(source.currentSignal, PositionSignal.good);
      source.dispose();
    });
  });

  group('once it has been good', () {
    test('a few wide fixes are not a weak signal', () {
      // Walking under a balcony is not a fault, and saying so every time is
      // how a HUD earns being ignored.
      final source = _Source(degradeAfter: const Duration(seconds: 45));

      source.emitFix(fixAt(Duration.zero, accuracyM: 10));
      source.emitFix(fixAt(const Duration(seconds: 10), accuracyM: 60));
      source.emitFix(fixAt(const Duration(seconds: 30), accuracyM: 60));

      expect(source.currentSignal, PositionSignal.good);
      source.dispose();
    });

    test('but a long run of them is', () {
      final source = _Source(degradeAfter: const Duration(seconds: 45));

      source.emitFix(fixAt(Duration.zero, accuracyM: 10));
      source.emitFix(fixAt(const Duration(seconds: 50), accuracyM: 60));

      expect(source.currentSignal, PositionSignal.degraded);
      source.dispose();
    });

    test('and one good fix clears it again', () {
      final source = _Source(degradeAfter: const Duration(seconds: 45));

      source.emitFix(fixAt(Duration.zero, accuracyM: 10));
      source.emitFix(fixAt(const Duration(seconds: 50), accuracyM: 60));
      source.emitFix(fixAt(const Duration(seconds: 55), accuracyM: 15));

      expect(source.currentSignal, PositionSignal.good);
      source.dispose();
    });
  });

  group('the threshold follows the sampling rate', () {
    test('asking once every ten seconds waits at least three readings', () {
      // Otherwise the game asks rarely and then complains about the gaps it
      // asked for.
      final source = _Source(degradeAfter: const Duration(seconds: 20));

      source.noteCadence(PositionCadence.resting);

      expect(source.degradeWindow, const Duration(seconds: 30));
      source.dispose();
    });

    test('and never less than the floor, however fast the cadence', () {
      final source = _Source(degradeAfter: const Duration(seconds: 45));

      source.noteCadence(PositionCadence.combat);

      expect(source.degradeWindow, const Duration(seconds: 45));
      source.dispose();
    });

    test('the off cadence does not reset it to nothing', () {
      // Interval zero means the radio is off, not that a fix is due instantly.
      final source = _Source();

      source.noteCadence(PositionCadence.moving);
      source.noteCadence(PositionCadence.off);

      expect(source.degradeWindow, greaterThan(Duration.zero));
      source.dispose();
    });
  });
}
