import 'package:arls_za/ui/maplibre_surface.dart';
import 'package:flutter_test/flutter_test.dart';

/// BRAMKA SYNCHRONIZACJI ZNACZNIKÓW (§3.6).
///
/// Found on a phone with a fresh character: no enemies and no lootboxes on the
/// map until the game was restarted, after which everything drew correctly.
/// The reconciliation was guarded against running twice at once — and the
/// guard *dropped* the second request instead of deferring it. On a cold start
/// the style, the first fix and the first loot spawn all land within a few
/// frames, so the one update that carried the markers was the one thrown away.
void main() {
  group('one job at a time', () {
    test('the first caller runs', () {
      expect(SyncGate().enter(), isTrue);
    });

    test('and the second is turned away', () {
      final gate = SyncGate()..enter();

      expect(gate.enter(), isFalse);
    });
  });

  group('but never a job thrown away', () {
    test('a request that arrived during a run is repeated', () {
      final gate = SyncGate()..enter();
      gate.enter();

      expect(gate.leave(), isTrue);
    });

    test('and only once, however many arrived', () {
      final gate = SyncGate()..enter();
      gate
        ..enter()
        ..enter()
        ..enter();

      expect(gate.leave(), isTrue);

      gate.enter();
      expect(gate.leave(), isFalse);
    });

    test('a quiet run asks for nothing more', () {
      final gate = SyncGate()..enter();

      expect(gate.leave(), isFalse);
    });

    test('and the gate opens again afterwards', () {
      final gate = SyncGate()..enter();
      gate.leave();

      expect(gate.enter(), isTrue);
    });
  });
}
