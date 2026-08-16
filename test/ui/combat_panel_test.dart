import 'package:arls_za/combat/ballistics.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/combat_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// PANEL OGNIA (§5.1.4).
///
/// §5.1.4 makes the percentage compulsory, and the reason is worth repeating:
/// with a model this unforgiving, somebody who misses five times at 26% will
/// decide the game is broken. Shown the 26% first, they spend the round
/// knowing what they bought. The model may be as merciless as it is legible.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    double chance = 0.26,
    ErrorSource dominant = ErrorSource.movement,
    VoidCallback? onFire,
    bool canFire = true,
    VoidCallback? onStrike,
    String? refusal,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: CombatPanel(
            targetName: 'Przeciwnik',
            distanceM: 84,
            chance: chance,
            dominant: dominant,
            refusal: refusal,
            onFire: canFire ? onFire ?? () {} : null,
            onStrike: onStrike,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the odds are on the screen before the round is spent', (
    tester,
  ) async {
    await pump(tester);

    expect(find.textContaining('26%'), findsOneWidget);
  });

  testWidgets('and so is how far away it is', (tester) async {
    await pump(tester);

    expect(find.textContaining('84 m'), findsOneWidget);
  });

  testWidgets('with the largest error named, since that is the part a player '
      'can answer', (tester) async {
    await pump(tester, dominant: ErrorSource.movement);

    expect(find.text('RUCH'), findsOneWidget);
  });

  testWidgets('a racing pulse is named as a pulse', (tester) async {
    await pump(tester, dominant: ErrorSource.heart);

    expect(find.text('TĘTNO'), findsOneWidget);
  });

  testWidgets('nothing in hand refuses the shot, and says why', (
    tester,
  ) async {
    // A dead button teaches nothing.
    await pump(tester, canFire: false, refusal: 'Nic w ręku.');

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Nic w ręku.'), findsOneWidget);
  });

  testWidgets('the trigger fires exactly once per press', (tester) async {
    var shots = 0;
    await pump(tester, onFire: () => shots++);

    await tester.tap(find.text('Ognia'));
    await tester.pumpAndSettle();

    expect(shots, 1);
  });

  testWidgets('a poor chance is still a number, not a hidden button', (
    tester,
  ) async {
    // §5.1.4: the model is allowed to be merciless exactly as far as it is
    // legible. Hiding a 3% shot would be neither.
    await pump(tester, chance: 0.03);

    expect(find.textContaining('3%'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  group('hands, once it is close (§5.2, §5.4)', () {
    testWidgets('nothing to swing at across a street', (tester) async {
      // Below twenty metres the receiver has nothing useful to say about
      // anybody's position, and above it a fist reaches nobody.
      await pump(tester);

      expect(find.text('Cios'), findsNothing);
    });

    testWidgets('and a strike when it is on top of you', (tester) async {
      await pump(tester, onStrike: () {});

      expect(find.text('Cios'), findsOneWidget);
    });

    testWidgets('which swings once per press', (tester) async {
      var swings = 0;
      await pump(tester, onStrike: () => swings++);

      await tester.tap(find.text('Cios'));
      await tester.pumpAndSettle();

      expect(swings, 1);
    });

    testWidgets('with the trigger still there beside it', (tester) async {
      // §5.6.3's whole choice: the loud answer and the quiet one, together.
      await pump(tester, onStrike: () {});

      expect(find.text('Ognia'), findsOneWidget);
      expect(find.text('Cios'), findsOneWidget);
    });
  });
}
