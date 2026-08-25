import 'package:arls_za/combat/ballistics.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/target_reading.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/l10n/app_localizations_pl.dart';
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
    double? chance = 0.26,
    ErrorSource? dominant = ErrorSource.movement,
    EnemyState state = EnemyState.chase,
    EnemyCondition condition = EnemyCondition.healthy,
    double sprintLeft = 1,
    double bloodLeft = 1,
    bool bleeding = false,
    String? weaponName = 'Karabinek',
    VoidCallback? onFire,
    bool canFire = true,
    VoidCallback? onStrike,
    VoidCallback? onReload,
    int loaded = 0,
    int magazine = 0,
    bool reloading = false,
    CombatRefusal? refusal,
    bool canReload = true,
    bool canStrike = true,
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
            reading: TargetReading(
              targetName: 'Przeciwnik',
              distanceM: 84,
              chance: chance,
              dominant: dominant,
              state: state,
              condition: condition,
              sprintLeft: sprintLeft,
              bloodLeft: bloodLeft,
              bleeding: bleeding,
              weaponName: weaponName,
              refusal: refusal,
              loaded: loaded,
              magazine: magazine,
              reloading: reloading,
              settling: false,
              canFire: canFire,
              canReload: canReload && onReload != null,
              canStrike: canStrike && onStrike != null,
            ),
            onFire: onFire ?? () {},
            onStrike: onStrike,
            onReload: onReload,
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

  testWidgets('nothing in hand refuses the shot, and says why', (tester) async {
    // A dead button teaches nothing.
    await pump(tester, canFire: false, refusal: CombatRefusal.noWeapon);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text(L10nPl().combatNoWeapon), findsOneWidget);
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

  group('what can be told about the thing itself (§5.5.1, §5.5.2)', () {
    testWidgets('how badly hurt it looks, in words', (tester) async {
      // An estimate on purpose: §5.5.1 makes the accuracy a Reconnaissance
      // skill, and three words is all anybody could give at two hundred
      // metres anyway.
      await pump(tester, condition: EnemyCondition.wounded);

      expect(find.textContaining('Ranny'), findsOneWidget);
    });

    testWidgets('and critical when it is nearly done', (tester) async {
      await pump(tester, condition: EnemyCondition.critical);

      expect(find.textContaining('Krytyczny'), findsOneWidget);
    });

    testWidgets('what it has left in its legs, as a bar', (tester) async {
      // §5.5.2: the question is "can it still catch me", not "how many
      // seconds".
      await pump(tester, sprintLeft: 0.4);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator).last,
      );

      expect(bar.value, closeTo(0.4, 0.001));
    });

    testWidgets('a spent one reads as empty', (tester) async {
      await pump(tester, sprintLeft: 0);

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).last,
            )
            .value,
        0,
      );
    });

    testWidgets('and what it has left in it (§2.6)', (tester) async {
      // The other half of "is this worth another round": a thing bleeding out
      // is a thing to back away from rather than to spend a magazine on.
      await pump(tester, bloodLeft: 0.3, bleeding: true);

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        closeTo(0.3, 0.001),
      );
      expect(find.textContaining(RegExp('krwaw|bleed')), findsOneWidget);
    });
  });

  group('what is in the weapon (§5.3, §5.5.4)', () {
    testWidgets('the rounds loaded, against what it holds', (tester) async {
      // A round in the pack is not a round in the rifle.
      await pump(tester, loaded: 4, magazine: 30);

      expect(find.textContaining('4 / 30'), findsOneWidget);
    });

    testWidgets('an empty weapon offers a reload instead of a shot', (
      tester,
    ) async {
      await pump(
        tester,
        canFire: false,
        loaded: 0,
        magazine: 30,
        onReload: () {},
      );

      expect(find.text('Przeładuj'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('and says so while the magazine is going in', (tester) async {
      await pump(
        tester,
        canFire: false,
        loaded: 0,
        magazine: 30,
        onReload: () {},
        reloading: true,
      );

      expect(find.text('Przeładowanie…'), findsOneWidget);
      expect(find.text('Przeładuj'), findsNothing);
    });

    testWidgets('reloading takes one press', (tester) async {
      var reloads = 0;
      await pump(tester, magazine: 30, onReload: () => reloads++);

      await tester.tap(find.text('Przeładuj'));
      await tester.pumpAndSettle();

      expect(reloads, 1);
    });
  });

  group('a target with nothing in hand (§5.5.1)', () {
    testWidgets('still says what it is and what it is doing', (tester) async {
      // Found on a phone: tapping an enemy bare-handed looked like the tap had
      // missed, because the panel only appeared once a shot could be worked
      // out — so the one case where a player most needs telling showed them
      // nothing.
      await pump(
        tester,
        chance: null,
        dominant: null,
        canFire: false,
        refusal: CombatRefusal.noWeapon,
      );

      expect(find.textContaining('Przeciwnik'), findsOneWidget);
      expect(find.text(L10nPl().combatNoWeapon), findsOneWidget);
    });

    testWidgets('and shows a dash rather than an invented chance', (
      tester,
    ) async {
      // A percentage about a shot nobody can take is a lie with a number on
      // it.
      await pump(tester, chance: null, dominant: null, canFire: false);

      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('what it is doing is not repeated here (§12)', (tester) async {
      // It is already on the map as a `?` or a `!` over the dot, and on the
      // HUD as a threat line. A third copy pushed off the one thing the panel
      // was missing: what is in the player's own hands.
      await pump(tester, state: EnemyState.chase);

      expect(find.textContaining('idzie po ciebie'), findsNothing);
    });

    testWidgets('what is in your hands is (§5.5.4)', (tester) async {
      await pump(
        tester,
        weaponName: 'Karabinek 5,45',
        loaded: 12,
        magazine: 30,
      );

      expect(find.textContaining('Karabinek 5,45'), findsOneWidget);
    });

    testWidgets('and empty hands say nothing rather than nothing at all', (
      tester,
    ) async {
      await pump(tester, weaponName: null);

      expect(find.textContaining('/'), findsNothing);
    });
  });
}
