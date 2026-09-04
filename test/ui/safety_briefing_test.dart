import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/safety_briefing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// §3.5. The briefing is the part of the mandatory section the player actually
/// reads, so what matters is that it cannot be walked past.
void main() {
  Future<void> pumpBriefing(
    WidgetTester tester, {
    required VoidCallback onAccept,
    Locale locale = const Locale('pl'),
  }) async {
    // Tall viewport: the rules are a ListView, and a widget below the fold does
    // not exist as far as the test tree is concerned.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: SafetyBriefingScreen(onAccept: onAccept),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every rule §3.5 lists is on the screen', (tester) async {
    await pumpBriefing(tester, onAccept: () {});

    expect(find.textContaining('Patrz na drogę'), findsOneWidget);
    expect(find.textContaining('Nie graj w ruchu pojazdu'), findsOneWidget);
    expect(find.textContaining('teren prywatny'), findsOneWidget);
    expect(find.textContaining('Szpitale'), findsOneWidget);
    expect(find.textContaining('Po zmroku'), findsOneWidget);
  });

  testWidgets('the speed limits are stated, not merely implied', (
    tester,
  ) async {
    await pumpBriefing(tester, onAccept: () {});

    // A player who knows the numbers can tell a rule from a bug.
    expect(find.textContaining('15 km/h'), findsOneWidget);
    expect(find.textContaining('40 km/h'), findsOneWidget);
  });

  testWidgets('the only way out is through the button', (tester) async {
    var accepted = false;
    await pumpBriefing(tester, onAccept: () => accepted = true);

    // A back gesture must not skip the rules.
    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      popped,
      isTrue,
      reason:
          'the route consumed the pop rather than '
          'leaving the screen',
    );
    expect(find.textContaining('Patrz na drogę'), findsOneWidget);

    await tester.tap(find.text('Rozumiem i biorę to na siebie'));
    await tester.pump();
    await tester.tap(find.text('Wychodzę'));
    expect(accepted, isTrue);
  });

  testWidgets('§15.3: the button is dead until the box is ticked', (
    tester,
  ) async {
    var accepted = false;
    await pumpBriefing(tester, onAccept: () => accepted = true);

    // ⚠️ The whole point of §15.3's checkbox. A button at the foot of a list
    // is pressed by a thumb travelling downwards; a box has to be aimed at.
    await tester.tap(find.text('Wychodzę'));
    await tester.pump();
    expect(accepted, isFalse);

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
      reason: 'a disabled control says "not yet" without spending a tap on it',
    );
  });

  testWidgets('reads in English too', (tester) async {
    await pumpBriefing(tester, onAccept: () {}, locale: const Locale('en'));

    expect(find.text('Before you go out'), findsOneWidget);
    expect(find.text('I understand and accept this'), findsOneWidget);
    expect(find.text('Head out'), findsOneWidget);
  });
}
