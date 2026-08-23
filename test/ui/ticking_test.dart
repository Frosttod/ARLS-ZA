import 'dart:io';

import 'package:arls_za/ui/ticking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ZEGAR, KTÓRY NIE CHODZI W KIESZENI (§3.3, §2.1a.3).
///
/// ⚠️ This game is carried for hours by design. Four widgets each made their
/// own one-second timer in initState and none of them ever stopped: an empty
/// action strip woke the app three thousand six hundred times an hour to
/// rebuild a `SizedBox.shrink()`.
///
/// Two rules, and both are here: nothing ticks while there is nothing to
/// redraw, and nothing ticks while the app is in the background.
class _Probe extends StatefulWidget {
  const _Probe({required this.busy});

  final bool busy;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe>
    with WidgetsBindingObserver, Ticking<_Probe> {
  int builds = 0;

  @override
  bool get ticking => widget.busy;

  @override
  Widget build(BuildContext context) {
    builds++;
    return const SizedBox.shrink();
  }
}

void main() {
  _ProbeState stateOf(WidgetTester tester) =>
      tester.state<_ProbeState>(find.byType(_Probe));

  testWidgets('nothing to show, nothing to wake up for', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Probe(busy: false)));
    final probe = stateOf(tester);
    final before = probe.builds;

    await tester.pump(const Duration(seconds: 5));

    expect(probe.builds, before, reason: 'an idle widget rebuilt itself');
  });

  testWidgets('something running redraws every second', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Probe(busy: true)));
    final probe = stateOf(tester);
    final before = probe.builds;

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(probe.builds, greaterThan(before));
    await tester.pumpWidget(const MaterialApp(home: _Probe(busy: false)));
  });

  testWidgets('the clock stops when the app goes into a pocket', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _Probe(busy: true)));
    final probe = stateOf(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final asleep = probe.builds;

    await tester.pump(const Duration(seconds: 5));
    expect(probe.builds, asleep, reason: 'it ticked in the background');

    // And starts again on the way back, without waiting a second first.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(probe.builds, greaterThan(asleep));

    await tester.pumpWidget(const MaterialApp(home: _Probe(busy: false)));
  });

  testWidgets('a dialog over the app is not a pocket', (tester) async {
    // ⚠️ `inactive` is the recents view, a permission sheet, an incoming call.
    // The screen is still the player's, and a bar that froze behind a dialog
    // would read as the game hanging.
    await tester.pumpWidget(const MaterialApp(home: _Probe(busy: true)));
    final probe = stateOf(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final before = probe.builds;

    await tester.pump(const Duration(seconds: 2));
    expect(probe.builds, greaterThan(before));

    await tester.pumpWidget(const MaterialApp(home: _Probe(busy: false)));
  });

  group('the rule holds in the source', () {
    test('no screen rolls its own periodic timer any more', () {
      // A budget, like the sticky-position one. Four copies of the same thirty
      // lines is how the lifecycle got forgotten in three of them.
      final offenders = <String>[];

      for (final file in Directory('lib/ui').listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        if (file.path.endsWith('ticking.dart')) continue;

        if (file.readAsStringSync().contains('Timer.periodic')) {
          offenders.add(file.uri.pathSegments.last);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'these should mix in Ticking: ${offenders.join(', ')}',
      );
    });

    test('and the game itself keeps no timer of its own', () {
      // ⚠️ **This rule replaces the one that used to be here.**
      //
      // The old budget named the three clocks — search, reload, bench — and
      // checked that the lifecycle stopped each of them. That was the best
      // that could be done while there were three, and it was still a list
      // somebody had to remember to extend: the *fourth* clock would have been
      // the one added to the game and not to the list.
      //
      // There is one now. A ticker says how often it wants a beat and how to
      // tell whether it is still running, and the clock asks. Nothing has to
      // be stopped by name, so nothing can be forgotten by name.
      final main = File('lib/main.dart').readAsStringSync();

      expect(
        main.contains('Timer.periodic'),
        isFalse,
        reason: 'put it on the one clock — see ActionController',
      );
      expect(main.contains('_clock.sleep()'), isTrue);
      expect(main.contains('_clock.wake()'), isTrue);
    });

    test('and the one clock stops dead when nothing is running (§3.3)', () {
      // The game lives in a pocket for hours by design. A clock nobody stops
      // is the battery.
      final clock = File(
        'lib/game/controllers/action_controller.dart',
      ).readAsStringSync();

      expect(clock.contains('if (!_awake) return null;'), isTrue);
      expect(
        clock.contains('_timer = null;'),
        isTrue,
        reason: 'no running ticker must mean no timer held at all',
      );
    });
  });
}
