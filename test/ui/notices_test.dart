import 'package:arls_za/ui/notices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// KOMUNIKATY (§12, §3.6).
///
/// These were snack bars, which on a phone means the bottom of the screen —
/// where the menu and the searching controls live. The one place the game
/// speaks was also the one place it covered up, so a message about a full pack
/// sat on top of the button for doing something about it.
void main() {
  final now = DateTime.utc(2026, 8, 16, 12);

  Future<void> pump(
    WidgetTester tester,
    ValueNotifier<List<Notice>> notices,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NoticeStack(notices: notices)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('what was said is on screen', (tester) async {
    await pump(tester, ValueNotifier([Notice('Plecak pełny.', now)]));

    expect(find.text('Plecak pełny.'), findsOneWidget);
  });

  testWidgets('silence takes up no room at all', (tester) async {
    await pump(tester, ValueNotifier(const []));

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('three at most, newest first', (tester) async {
    // A fourth line of history is not news.
    await pump(
      tester,
      ValueNotifier([for (var i = 0; i < 6; i++) Notice('linia $i', now)]),
    );

    expect(find.text('linia 0'), findsOneWidget);
    expect(find.text('linia 2'), findsOneWidget);
    expect(find.text('linia 3'), findsNothing);
  });

  testWidgets('the list follows what is said next', (tester) async {
    final notices = ValueNotifier<List<Notice>>([Notice('pierwsza', now)]);
    await pump(tester, notices);

    notices.value = [Notice('druga', now), ...notices.value];
    await tester.pumpAndSettle();

    expect(find.text('druga'), findsOneWidget);
    expect(find.text('pierwsza'), findsOneWidget);
  });

  testWidgets('a message never takes a tap meant for the map', (tester) async {
    // It is something the game said, not a control.
    await pump(tester, ValueNotifier([Notice('Znaleziono: nóż', now)]));

    final ignoring = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.text('Znaleziono: nóż'),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );

    expect(ignoring.ignoring, isTrue);
  });
}
