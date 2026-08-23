import 'package:arls_za/game/controllers/action_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

/// JEDEN ZEGAR (§2.1a, §2.1a.3, §3.3).
///
/// ⚠️ **There were five, and none of them knew about the others.**
///
/// A search ticked once a second, a reload ten times a second so its bar
/// looked smooth, the bench once a second to see whether its job had come due.
/// The lifecycle stopped three of them *by name*, so every new clock had to be
/// added to two lists — and the sixth would have been the one somebody forgot.
///
/// The rules this file holds:
///
///   - nothing runs when nothing is running (§3.3 — the game lives in a pocket
///     for hours, and a clock nobody stops is the battery);
///   - the clock is as fine as the finest thing that needs it, and no finer;
///   - it drops back the moment the fast thing ends;
///   - a ticker stops itself by answering "no", never by being told.
void main() {
  test('nothing running, no clock at all', () {
    fakeAsync((async) {
      final clock = ActionController();
      addTearDown(clock.dispose);

      var beats = 0;
      clock.every(
        'search',
        const Duration(seconds: 1),
        running: () => false,
        onTick: () => beats++,
      );

      async.elapse(const Duration(minutes: 5));

      expect(beats, 0);
      expect(clock.periodForTest, isNull, reason: 'no timer may be held');
    });
  });

  test('one ticker beats at its own period', () {
    fakeAsync((async) {
      final clock = ActionController();
      addTearDown(clock.dispose);

      var running = true;
      var beats = 0;
      clock.every(
        'search',
        const Duration(seconds: 1),
        running: () => running,
        onTick: () => beats++,
      );

      async.elapse(const Duration(seconds: 10));
      expect(beats, 10);

      running = false;
      async.elapse(const Duration(seconds: 10));

      expect(beats, 10, reason: 'a ticker stops itself by answering no');
      expect(clock.periodForTest, isNull);
    });
  });

  group('the clock is as fine as it has to be, and no finer', () {
    test('a slow ticker alone keeps a slow clock', () {
      fakeAsync((async) {
        final clock = ActionController();
        addTearDown(clock.dispose);

        clock.every(
          'bench',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () {},
        );
        async.elapse(const Duration(milliseconds: 1));

        expect(clock.periodForTest, const Duration(seconds: 1));
      });
    });

    test('a fast one arriving quickens it', () {
      fakeAsync((async) {
        final clock = ActionController();
        addTearDown(clock.dispose);

        var reloading = false;

        clock.every(
          'bench',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () {},
        );
        clock.every(
          'reload',
          const Duration(milliseconds: 100),
          running: () => reloading,
          onTick: () {},
        );

        async.elapse(const Duration(milliseconds: 1));
        expect(clock.periodForTest, const Duration(seconds: 1));

        reloading = true;
        clock.retime();

        expect(clock.periodForTest, const Duration(milliseconds: 100));
      });
    });

    test('and it drops back when the fast one ends', () {
      // ⚠️ §3.3's complaint made real: waking the phone ten times a second for
      // a forty-five minute pack, long after the reload it was for finished.
      fakeAsync((async) {
        final clock = ActionController();
        addTearDown(clock.dispose);

        var reloading = true;

        clock.every(
          'bench',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () {},
        );
        clock.every(
          'reload',
          const Duration(milliseconds: 100),
          running: () => reloading,
          onTick: () {},
        );

        async.elapse(const Duration(milliseconds: 300));
        expect(clock.periodForTest, const Duration(milliseconds: 100));

        reloading = false;

        // No cancelling, no telling. The next beat asks and finds out.
        async.elapse(const Duration(milliseconds: 200));

        expect(clock.periodForTest, const Duration(seconds: 1));
      });
    });

    test('a slow ticker is not beaten fast because a fast one is on', () {
      // The whole point of one timer with several periods: the bench must
      // still be asked once a second, not ten times.
      fakeAsync((async) {
        final clock = ActionController();
        addTearDown(clock.dispose);

        var bench = 0;
        var reload = 0;

        clock.every(
          'bench',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () => bench++,
        );
        clock.every(
          'reload',
          const Duration(milliseconds: 100),
          running: () => true,
          onTick: () => reload++,
        );

        async.elapse(const Duration(seconds: 2));

        expect(reload, 20);
        expect(bench, 2);
      });
    });
  });

  group('§3.3: nothing ticks while the app is in a pocket', () {
    test('sleeping stops the clock even with things running', () {
      fakeAsync((async) {
        final clock = ActionController();
        addTearDown(clock.dispose);

        var beats = 0;
        clock.every(
          'search',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () => beats++,
        );

        async.elapse(const Duration(seconds: 3));
        expect(beats, 3);

        clock.sleep();
        async.elapse(const Duration(minutes: 30));

        expect(beats, 3, reason: 'a bar nobody can see is not worth a wake-up');
        expect(clock.periodForTest, isNull);
      });
    });

    test('and waking puts it back', () {
      fakeAsync((async) {
        final clock = ActionController();
        addTearDown(clock.dispose);

        var beats = 0;
        clock.every(
          'search',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () => beats++,
        );

        clock.sleep();
        async.elapse(const Duration(minutes: 30));

        clock.wake();
        async.elapse(const Duration(seconds: 3));

        expect(beats, 3);
      });
    });

    test('waking does not pay out the time it was asleep', () {
      // ⚠️ Everything here draws a *deadline*, not an accumulator. The caller
      // settles the gap against the wall clock before waking; the clock owes
      // nothing for the half hour it was off.
      fakeAsync((async) {
        final clock = ActionController();
        addTearDown(clock.dispose);

        var beats = 0;
        clock.every(
          'search',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () => beats++,
        );

        clock.sleep();
        async.elapse(const Duration(minutes: 30));
        clock.wake();

        // One beat's worth of time, one beat.
        async.elapse(const Duration(seconds: 1));

        expect(beats, 1);
      });
    });
  });

  group('§2.1a: what is on the clock', () {
    test('it can name what is running', () {
      final clock = ActionController();
      addTearDown(clock.dispose);

      var eating = false;

      clock.every(
        'search',
        const Duration(seconds: 1),
        running: () => eating,
        onTick: () {},
      );
      clock.every(
        'bench',
        const Duration(seconds: 1),
        running: () => true,
        onTick: () {},
      );

      expect(clock.anyRunning, isTrue);
      expect(clock.running, ['bench']);

      eating = true;
      expect(clock.running, ['search', 'bench']);
    });

    test('and nothing running is nothing running', () {
      final clock = ActionController();
      addTearDown(clock.dispose);

      clock.every(
        'search',
        const Duration(seconds: 1),
        running: () => false,
        onTick: () {},
      );

      expect(clock.anyRunning, isFalse);
      expect(clock.running, isEmpty);
    });
  });

  test('a tick that registers another ticker does not break the beat', () {
    // ⚠️ It happens: finishing a meal starts a bench job. Editing the map
    // while walking it throws, so the beat walks a copy.
    fakeAsync((async) {
      final clock = ActionController();
      addTearDown(clock.dispose);

      var bench = 0;
      clock.every(
        'search',
        const Duration(seconds: 1),
        running: () => true,
        onTick: () => clock.every(
          'bench',
          const Duration(seconds: 1),
          running: () => true,
          onTick: () => bench++,
        ),
      );

      expect(() => async.elapse(const Duration(seconds: 3)), returnsNormally);
      expect(bench, greaterThan(0));
    });
  });

  test('disposing lets go of the timer', () {
    fakeAsync((async) {
      final clock = ActionController();

      var beats = 0;
      clock.every(
        'search',
        const Duration(seconds: 1),
        running: () => true,
        onTick: () => beats++,
      );
      async.elapse(const Duration(seconds: 2));

      clock.dispose();
      async.elapse(const Duration(minutes: 5));

      expect(beats, 2);
    });
  });
}
