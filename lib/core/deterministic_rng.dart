/// Deterministic random number generator (design doc §11).
///
/// The seed is stored in the profile so a session can be replayed exactly:
/// same seed plus same event stream reproduces the same run, which is what
/// makes the developer-mode replays of §11.2 useful for bug reports.
///
/// [DeterministicRng] is a splittable counter-based generator, not
/// `dart:math`'s [Random]. Two properties matter here and `Random` gives
/// neither:
///
/// * **Streams.** Loot rolls must not consume draws from the combat stream,
///   otherwise firing one extra shot silently changes what is in the next
///   crate. [stream] hands out an independent generator per domain.
/// * **Position.** [cursor] is a plain integer that can be saved and restored,
///   so the generator resumes exactly where the save left off.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Independent random streams. Adding a value is safe; renumbering is not,
/// because the stream id is mixed into the seed and old saves would diverge.
enum RngStream {
  world(1),
  loot(2),
  combat(3),
  enemies(4),
  weather(5),
  literature(6),
  story(7);

  const RngStream(this.id);

  final int id;
}

class DeterministicRng {
  DeterministicRng({required this.seed, int cursor = 0}) {
    _cursor = cursor;
  }

  /// Root seed of the profile. Written once at character creation.
  final int seed;

  int _cursor = 0;

  /// Number of draws taken so far. Persist this with the save to resume the
  /// exact position in the sequence.
  int get cursor => _cursor;

  /// Derives an independent generator for [stream].
  ///
  /// Every stream starts at its own cursor, so consuming draws in one never
  /// shifts another.
  DeterministicRng stream(RngStream stream, {int cursor = 0}) =>
      DeterministicRng(seed: _mix(seed, stream.id), cursor: cursor);

  /// Uniform 64-bit value.
  int nextRaw() => _mix(seed, _cursor++);

  /// Uniform integer in `[0, max)`. Rejection-sampled, so the distribution is
  /// exactly uniform rather than modulo-biased.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    final limit = _maxUnsigned - (_maxUnsigned % max);
    while (true) {
      final value = nextRaw() & _mask53; // stay inside exact double range
      if (value < limit) return value % max;
    }
  }

  /// Uniform integer in `[min, max]`, both ends included.
  int nextIntRange(int min, int max) {
    if (max < min) {
      throw ArgumentError('max ($max) must be >= min ($min)');
    }
    return min + nextInt(max - min + 1);
  }

  /// Uniform double in `[0, 1)`.
  double nextDouble() => (nextRaw() & _mask53) / _pow2_53;

  /// Uniform double in `[min, max)`.
  double nextDoubleRange(double min, double max) =>
      min + nextDouble() * (max - min);

  /// True with probability [probability], clamped to `[0, 1]`.
  bool chance(double probability) {
    if (probability <= 0) return false;
    if (probability >= 1) return true;
    return nextDouble() < probability;
  }

  /// Uniformly picks one element of [items].
  T pick<T>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    return items[nextInt(items.length)];
  }

  /// Picks one index of [weights] proportionally to its value. Used by the loot
  /// tables of §10.3, where Recon scales the weight of rare entries.
  int pickWeighted(List<double> weights) {
    if (weights.isEmpty) {
      throw ArgumentError.value(weights, 'weights', 'must not be empty');
    }
    var total = 0.0;
    for (final w in weights) {
      if (w < 0) {
        throw ArgumentError.value(weights, 'weights', 'must not be negative');
      }
      total += w;
    }
    if (total <= 0) {
      throw ArgumentError.value(weights, 'weights', 'must not sum to zero');
    }
    var roll = nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) return i;
    }
    return weights.length - 1; // floating point slack
  }

  /// Generates a fresh root seed for a new profile. This is the only place
  /// non-deterministic randomness is allowed.
  static int newSeed() {
    final entropy = math.Random.secure();
    return (entropy.nextInt(1 << 32) << 21) ^ entropy.nextInt(1 << 21);
  }

  /// SplitMix64 finalizer over `seed + counter`.
  ///
  /// Relies on Dart VM integers being 64-bit two's complement with silent
  /// wraparound on overflow, which is what the mixing needs. The game ships on
  /// Android and the tests run on the VM, so that holds; a web build would
  /// produce different numbers and is out of scope (§11).
  static int _mix(int seed, int counter) {
    var z = seed + counter * 0x9E3779B97F4A7C15;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  static const int _mask53 = 0x1FFFFFFFFFFFFF;
  static const int _maxUnsigned = 0x20000000000000; // 2^53
  static const double _pow2_53 = 9007199254740992.0;

  @override
  String toString() => 'DeterministicRng(seed: $seed, cursor: $_cursor)';
}

/// Debug helper: the first few draws of a stream, for comparing two runs.
Uint32List rngFingerprint(DeterministicRng rng, {int draws = 8}) {
  final out = Uint32List(draws);
  for (var i = 0; i < draws; i++) {
    out[i] = rng.nextInt(0x7FFFFFFF);
  }
  return out;
}
