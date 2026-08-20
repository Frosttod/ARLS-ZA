import 'dart:io';

import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/action_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// KAŻDA AKCJA WIDOCZNA I DO PRZERWANIA (§2.1a, §12).
///
/// The rule the player asked for in as many words: everything with a clock on
/// it shows in one strip under the stats, on the main screen, and every line
/// of it can be stopped from there. An action whose only sign lives on a
/// pushed screen is an action somebody walking with a phone cannot see and
/// cannot get out of.
void main() {
  final now = DateTime.now().toUtc();

  Future<void> show(WidgetTester tester, List<RunningAction> actions) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('pl'),
        home: Scaffold(body: ActionStrip(actions: actions)),
      ),
    );
    await tester.pump();
  }

  testWidgets('nothing running draws nothing', (tester) async {
    await show(tester, const []);

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('two things running draw two bars', (tester) async {
    // ⚠️ The reason this is a list rather than a slot. The old one showed
    // whichever of two it liked best: a magazine change and a dismantling
    // could both be under way and only one of them said so.
    await show(tester, [
      RunningAction(
        icon: Icons.autorenew,
        label: 'Wymiana magazynka',
        startedAt: now,
        readyAt: now.add(const Duration(seconds: 4)),
      ),
      RunningAction(
        icon: Icons.handyman,
        label: 'Rozbiórka',
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 9)),
      ),
    ]);

    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.text('Wymiana magazynka'), findsOneWidget);
    expect(find.text('Rozbiórka'), findsOneWidget);
  });

  testWidgets('every line offers a way out', (tester) async {
    var stopped = 0;

    await show(tester, [
      RunningAction(
        icon: Icons.autorenew,
        label: 'Wymiana magazynka',
        startedAt: now,
        readyAt: now.add(const Duration(seconds: 4)),
        onStop: () => stopped++,
      ),
      RunningAction(
        icon: Icons.handyman,
        label: 'Rozbiórka',
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 9)),
        onStop: () => stopped++,
      ),
    ]);

    final stops = find.byIcon(Icons.stop_circle_outlined);
    expect(stops, findsNWidgets(2));

    await tester.tap(stops.first);
    await tester.tap(stops.last);
    expect(stopped, 2);
  });

  testWidgets('the bar says how far along it is', (tester) async {
    await show(tester, [
      RunningAction(
        icon: Icons.handyman,
        label: 'Rozbiórka',
        startedAt: now.subtract(const Duration(minutes: 3)),
        readyAt: now.add(const Duration(minutes: 3)),
      ),
    ]);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(bar.value, closeTo(0.5, 0.02));
  });

  testWidgets('and never past finished', (tester) async {
    // A job whose deadline went by while the app was closed is finished, not
    // a bar wrapped round twice.
    await show(tester, [
      RunningAction(
        icon: Icons.handyman,
        label: 'Rozbiórka',
        startedAt: now.subtract(const Duration(days: 2)),
        readyAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(bar.value, 1);
    expect(find.text('0 s'), findsOneWidget);
  });

  group('the rule holds in the source', () {
    test('every timed action on the main screen goes through the strip', () {
      // ⚠️ A budget rather than a shape check, in the same spirit as the sticky
      // position test: the failure mode here is somebody adding a new action
      // with a clock and giving it a bar somewhere else. If this list grows,
      // the new one belongs in `_running()`.
      final main = File('lib/main.dart').readAsStringSync();

      expect(
        main.contains('progress: _running()'),
        isTrue,
        reason:
            'the HUD slot must be fed by the one place that knows '
            'everything that is running',
      );

      // Reload, bench job and build all reach it.
      for (final needle in [
        'icon: Icons.autorenew',
        'icon: Icons.handyman',
        'BuildProgress.of(',
      ]) {
        expect(
          main.contains(needle),
          isTrue,
          reason: '$needle is missing from the strip',
        );
      }
    });

    test('and nothing running is left without a stop', () {
      // Every RunningAction built in main.dart names an onStop. The day one
      // does not, this fails and the question gets asked out loud.
      final main = File('lib/main.dart').readAsStringSync();
      final built = 'RunningAction('.allMatches(main).length;
      final stops = 'onStop:'.allMatches(main).length;

      expect(stops, greaterThanOrEqualTo(built));
    });
  });
}
