import 'package:arls_za/craft/salvage_batch.dart';
import 'package:test/test.dart';

/// JEDNO POSIEDZENIE, KILKA PRZEDMIOTÓW (§18.6, §2.1a).
///
/// ⚠️ **A sitting stops in whole pieces.**
///
/// §2.1a gives one pair of hands, so five things taken apart is one job, not
/// five. What makes that honest is the order: the rifle first, then the vest.
/// Half way through, the rifle is gone and the vest is exactly as it was —
/// never something in between, which is the state nothing in this game knows
/// how to draw or to sell back.
void main() {
  SalvageStep step(String id, int seconds, {String? uid}) => SalvageStep(
    uid: uid ?? id,
    itemId: id,
    condition: 100,
    takes: Duration(seconds: seconds),
  );

  final sitting = SalvageBatch([
    step('rifle', 600),
    step('vest', 300),
    step('pack', 120),
  ]);

  group('what a sitting comes to', () {
    test('every minute of it', () {
      expect(sitting.total, const Duration(seconds: 1020));
    });

    test('and the head is the one under the multitool', () {
      expect(sitting.head?.itemId, 'rifle');
    });
  });

  group('stopping', () {
    test('before the first is done leaves everything untouched', () {
      final settled = sitting.settledAt(const Duration(seconds: 599));

      expect(settled.done, isEmpty);
      expect(settled.left, hasLength(3));
    });

    test('on the boundary counts the piece as finished', () {
      // ⚠️ Inclusive. A piece whose last second has been paid for is apart,
      // and the reported bug — a dismantling stuck at 00:00 — was exactly this
      // comparison the other way round.
      final settled = sitting.settledAt(const Duration(seconds: 600));

      expect([for (final s in settled.done) s.itemId], ['rifle']);
      expect([for (final s in settled.left) s.itemId], ['vest', 'pack']);
    });

    test('half way through the second leaves the second whole', () {
      final settled = sitting.settledAt(const Duration(seconds: 750));

      expect([for (final s in settled.done) s.itemId], ['rifle']);
      expect(settled.left.first.itemId, 'vest');
    });

    test('and the minutes the second earned are its own', () {
      // §18.6's `salvageSeconds`: the vest has been opened up, and going back
      // to it later is not starting again.
      expect(
        sitting.creditedOn(const Duration(seconds: 750)),
        const Duration(seconds: 150),
      );
    });

    test('nothing is owed to a piece nobody has started', () {
      expect(sitting.creditedOn(const Duration(seconds: 600)), Duration.zero);
    });

    test('running it out pays for all of it', () {
      final settled = sitting.settledAt(const Duration(seconds: 1020));

      expect(settled.done, hasLength(3));
      expect(settled.left, isEmpty);
    });

    test('and nothing after the end is worth anything more', () {
      final settled = sitting.settledAt(const Duration(hours: 9));

      expect(settled.done, hasLength(3));
      expect(sitting.creditedOn(const Duration(hours: 9)), Duration.zero);
    });
  });

  group('what the row remembers (§11.1)', () {
    test('a sitting survives being written down and read back', () {
      final back = SalvageBatch.decode(sitting.encode());

      expect(back.length, 3);
      expect([for (final s in back.steps) s.itemId], [
        'rifle',
        'vest',
        'pack',
      ]);
      expect(back.total, sitting.total);
      expect(back.head?.uid, 'rifle');
    });

    test('and so does which pile each piece came off (§18.2)', () {
      final mixed = SalvageBatch([
        const SalvageStep(
          uid: 'a.1',
          itemId: 'vest',
          condition: 40,
          takes: Duration(seconds: 90),
          fromShelf: true,
        ),
      ]);

      final back = SalvageBatch.decode(mixed.encode()).steps.single;

      expect(back.fromShelf, isTrue);
      expect(back.condition, 40);
      expect(back.uid, 'a.1');
    });

    test('a row from before sittings existed reads as nothing', () {
      // ⚠️ Null rather than a crash. The column is additive and every job
      // written before it is null there; the caller turns that into a sitting
      // of one from the columns it already had.
      expect(SalvageBatch.decode(null).isEmpty, isTrue);
      expect(SalvageBatch.decode('').isEmpty, isTrue);
    });

    test('and rubbish in the column never throws', () {
      expect(SalvageBatch.decode('{oh dear').isEmpty, isTrue);
      expect(SalvageBatch.decode('{"not":"a list"}').isEmpty, isTrue);
      expect(SalvageBatch.decode('[1, "two", null]').isEmpty, isTrue);
      expect(SalvageBatch.decode('[{"cond":50}]').isEmpty, isTrue);
    });
  });
}
