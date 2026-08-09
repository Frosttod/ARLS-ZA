import 'package:arls_za/core/deterministic_rng.dart';
import 'package:test/test.dart';

void main() {
  group('DeterministicRng', () {
    test('same seed reproduces the same sequence', () {
      final a = DeterministicRng(seed: 12345);
      final b = DeterministicRng(seed: 12345);

      expect(rngFingerprint(a, draws: 32), rngFingerprint(b, draws: 32));
    });

    test('different seeds diverge', () {
      final a = rngFingerprint(DeterministicRng(seed: 1), draws: 16);
      final b = rngFingerprint(DeterministicRng(seed: 2), draws: 16);

      expect(a, isNot(b));
    });

    test('resuming from a saved cursor continues the sequence', () {
      final original = DeterministicRng(seed: 99);
      for (var i = 0; i < 10; i++) {
        original.nextInt(1000);
      }
      final expected = [for (var i = 0; i < 5; i++) original.nextInt(1000)];

      // Reload the save: same seed, cursor restored.
      final resumed = DeterministicRng(seed: 99, cursor: 10);
      final actual = [for (var i = 0; i < 5; i++) resumed.nextInt(1000)];

      expect(actual, expected);
    });

    test('streams are independent — draining one does not shift another', () {
      final root = DeterministicRng(seed: 7);

      final lootA = root.stream(RngStream.loot);
      final combat = root.stream(RngStream.combat);
      for (var i = 0; i < 50; i++) {
        combat.nextInt(100);
      }
      final lootB = root.stream(RngStream.loot);

      expect(
        [for (var i = 0; i < 8; i++) lootA.nextInt(100)],
        [for (var i = 0; i < 8; i++) lootB.nextInt(100)],
        reason: 'firing shots must not change what is in the next crate',
      );
    });

    test('streams do not collide with each other', () {
      final root = DeterministicRng(seed: 4242);
      final seen = <List<int>>[];

      for (final s in RngStream.values) {
        final stream = root.stream(s);
        seen.add([for (var i = 0; i < 8; i++) stream.nextInt(1 << 20)]);
      }

      for (var i = 0; i < seen.length; i++) {
        for (var j = i + 1; j < seen.length; j++) {
          expect(seen[i], isNot(seen[j]));
        }
      }
    });

    test('nextInt stays in range and covers it', () {
      final rng = DeterministicRng(seed: 31337);
      final buckets = List.filled(6, 0);

      for (var i = 0; i < 60000; i++) {
        final roll = rng.nextInt(6);
        expect(roll, inInclusiveRange(0, 5));
        buckets[roll]++;
      }

      // 60k draws over 6 buckets: 10k each. Allow generous slack; this is a
      // smoke test for gross modulo bias, not a statistical proof.
      for (final count in buckets) {
        expect(count, inInclusiveRange(9000, 11000));
      }
    });

    test('nextIntRange includes both ends', () {
      final rng = DeterministicRng(seed: 5);
      var sawMin = false;
      var sawMax = false;

      for (var i = 0; i < 2000; i++) {
        final roll = rng.nextIntRange(3, 7);
        expect(roll, inInclusiveRange(3, 7));
        if (roll == 3) sawMin = true;
        if (roll == 7) sawMax = true;
      }

      expect(sawMin && sawMax, isTrue);
    });

    test('nextDouble stays in [0, 1)', () {
      final rng = DeterministicRng(seed: 808);
      for (var i = 0; i < 10000; i++) {
        final value = rng.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('pickWeighted respects the weights', () {
      final rng = DeterministicRng(seed: 2024);
      final counts = [0, 0, 0];

      for (var i = 0; i < 30000; i++) {
        counts[rng.pickWeighted([1.0, 3.0, 6.0])]++;
      }

      expect(counts[0] / 30000, closeTo(0.10, 0.02));
      expect(counts[1] / 30000, closeTo(0.30, 0.02));
      expect(counts[2] / 30000, closeTo(0.60, 0.02));
    });

    test('pickWeighted rejects degenerate input', () {
      final rng = DeterministicRng(seed: 1);

      expect(() => rng.pickWeighted([]), throwsArgumentError);
      expect(() => rng.pickWeighted([0.0, 0.0]), throwsArgumentError);
      expect(() => rng.pickWeighted([1.0, -1.0]), throwsArgumentError);
    });

    test('chance handles the certain and impossible ends', () {
      final rng = DeterministicRng(seed: 1);

      expect(rng.chance(0), isFalse);
      expect(rng.chance(1), isTrue);
      expect(rng.cursor, 0, reason: 'certain outcomes consume no draws');
    });

    test('newSeed produces distinct seeds', () {
      final seeds = {for (var i = 0; i < 100; i++) DeterministicRng.newSeed()};
      expect(seeds.length, greaterThan(90));
    });
  });
}
