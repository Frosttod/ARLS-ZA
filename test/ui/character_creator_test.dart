import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/ui/character_creator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The creator is where §1.2 validation and §15.4's "show them the numbers"
/// meet the player. These tests are about the two things that must not slip:
/// invalid bodies cannot be submitted, and the death mode is a deliberate act.
void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('pl')}) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: child,
      );

  /// The form is a lazily built ListView taller than the default 800×600 test
  /// surface, so the death-mode cards and the submit button would never be
  /// laid out. A tall viewport puts the whole screen in the tree at once.
  void useTallScreen(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 3600)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpCreator(
    WidgetTester tester, {
    void Function(CharacterDraft draft)? onCreate,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      wrap(CharacterCreatorScreen(onCreate: onCreate ?? (_) {})),
    );
    await tester.pumpAndSettle();
  }

  Finder submitButton() => find.widgetWithText(FilledButton, 'Zaczynam');

  testWidgets('opens with the submit button disabled', (tester) async {
    await pumpCreator(tester);

    final button = tester.widget<FilledButton>(submitButton());
    expect(
      button.onPressed,
      isNull,
      reason: 'no name and no death mode chosen yet',
    );
  });

  testWidgets('shows the derived figures as the player types', (tester) async {
    await pumpCreator(tester);

    // Defaults are the worked example of §15.4: male, 30, 180 cm, 80 kg.
    expect(find.text('5319 ml'), findsOneWidget);
    expect(find.textContaining('2800 ml'), findsOneWidget);
    expect(find.text('187 bpm'), findsOneWidget);
    expect(find.text('24.0 kg'), findsOneWidget);
    expect(find.text('36.0 kg'), findsOneWidget);
  });

  testWidgets('states that the data stays on the device (§1.2)', (
    tester,
  ) async {
    await pumpCreator(tester);

    expect(
      find.textContaining('nigdy go nie opuszczają'),
      findsOneWidget,
      reason: 'the privacy promise belongs where the data is entered',
    );
  });

  testWidgets('a valid name and a chosen mode enable submission', (
    tester,
  ) async {
    await pumpCreator(tester);

    await tester.enterText(find.byType(TextField), 'Ocalały');
    await tester.pump();
    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNull);

    await tester.tap(find.text('Softcore'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNotNull);
  });

  testWidgets('a short name blocks submission and says why', (tester) async {
    await pumpCreator(tester);

    await tester.enterText(find.byType(TextField), 'Jan');
    await tester.tap(find.text('Softcore'));
    await tester.pumpAndSettle();

    expect(find.text('Co najmniej 4 znaki.'), findsOneWidget);
    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNull);
  });

  testWidgets('a name with symbols is rejected', (tester) async {
    await pumpCreator(tester);

    await tester.enterText(find.byType(TextField), 'Ala_Ma_Kota');
    await tester.pumpAndSettle();

    expect(find.text('Tylko litery, cyfry i spacje.'), findsOneWidget);
  });

  testWidgets('the death mode starts unselected — it cannot be undone (§9)', (
    tester,
  ) async {
    await pumpCreator(tester);

    expect(
      find.byIcon(Icons.radio_button_checked),
      findsNothing,
      reason:
          'a preselected irreversible choice is a choice made for the '
          'player',
    );
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
  });

  testWidgets('choosing one mode deselects the other', (tester) async {
    await pumpCreator(tester);

    await tester.tap(find.text('Hardcore'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await tester.tap(find.text('Softcore'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });

  testWidgets('warns that the choice is permanent', (tester) async {
    await pumpCreator(tester);

    expect(find.textContaining('nie da się później zmienić'), findsOneWidget);
  });

  testWidgets('hands back the draft it built', (tester) async {
    CharacterDraft? created;
    await pumpCreator(tester, onCreate: (draft) => created = draft);

    await tester.enterText(find.byType(TextField), '  Ocalały  ');
    await tester.tap(find.text('Hardcore'));
    await tester.pumpAndSettle();

    // Edge spaces are a validation error, so submission is still blocked.
    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Ocalały');
    await tester.pumpAndSettle();
    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(created!.name, 'Ocalały');
    expect(created!.deathMode, DeathMode.hardcore);
    expect(created!.spec.heightCm, 180);
    expect(created!.profile.bloodVolumeMl, closeTo(5319, 1));
  });

  testWidgets('renders in English too', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      wrap(
        CharacterCreatorScreen(onCreate: (_) {}),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create your character'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });
}
