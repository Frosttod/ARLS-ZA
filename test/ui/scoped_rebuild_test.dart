import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// CO PRZEBUDOWUJE SIĘ CO SEKUNDĘ (§3.3, §12).
///
/// ⚠️ **The loop publishes a snapshot every second, for hours.** While the
/// interface hung that off a `setState` at the root of the state class, every
/// one of those marked the whole tree dirty — the title screen, the permission
/// gate, the developer overlay and the map alike — whether or not anything on
/// them had changed. A session is meant to last a walk home (§3.3), and this
/// was the largest thing in the game doing work nobody asked for.
///
/// The snapshot is a `ValueNotifier` on `PositionController` and always was.
/// What changed is that the interface listens to it instead of being told.
///
/// ⚠️ These tests do not use the real screen — it needs a database, a
/// receiver and a character. They hold the *shape* the screen now has: a
/// listener low in the tree, and everything above it left alone.
void main() {
  testWidgets('a tick rebuilds the listener and nothing above it', (
    tester,
  ) async {
    final snapshot = ValueNotifier<int>(0);
    addTearDown(snapshot.dispose);

    var above = 0;
    var below = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            above++;
            return ValueListenableBuilder<int>(
              valueListenable: snapshot,
              builder: (context, value, _) {
                below++;
                return Text('$value');
              },
            );
          },
        ),
      ),
    );

    expect(above, 1);
    expect(below, 1);

    // Ten seconds of a walk home.
    for (var second = 0; second < 10; second++) {
      snapshot.value = second + 1;
      await tester.pump();
    }

    expect(below, 11, reason: 'the panel has to follow the tick');
    expect(
      above,
      1,
      reason: 'nothing above the listener has any reason to be rebuilt',
    );
  });

  testWidgets('and the tick reaches the interface without a setState', (
    tester,
  ) async {
    // ⚠️ The half that matters for correctness rather than for the battery: a
    // notifier nobody listens to is a screen that stops updating, and the
    // whole point of dropping the root rebuild is that this keeps working.
    final snapshot = ValueNotifier<int>(-1);
    addTearDown(snapshot.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: snapshot,
          builder: (context, value, _) => Text('$value'),
        ),
      ),
    );

    expect(find.text('-1'), findsOneWidget);

    snapshot.value = 7;
    await tester.pump();

    expect(find.text('7'), findsOneWidget);
  });

  test('§3.3: and the screen is actually wired that way', () {
    // ⚠️ Source-level, because the shape above is Flutter's and holds
    // whatever this codebase does. What has to be true *here* is that the tick
    // no longer marks the root dirty: `_position.accept` is the one call that
    // takes a snapshot, and for eight stages it sat inside a `setState`.
    final main = File('lib/main.dart').readAsStringSync();

    expect(main.contains('_position.accept(snapshot);'), isTrue);
    expect(
      main.contains('setState(() => _position.accept'),
      isFalse,
      reason: 'the tick is marking the whole tree dirty again',
    );
    expect(
      main.contains('valueListenable: _position.snapshot'),
      isTrue,
      reason: 'something has to listen, or the screen stops updating',
    );
  });
}
