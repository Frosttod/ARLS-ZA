import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/craft_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// WARSZTAT: ZAKŁADKI, INFORMACJA, CISZA (§18.4, §12).
///
/// ⚠️ **Lista przerosła listę.** Osiem wierszy czytało się dobrze;
/// dwadzieścia sześć nie, a gracz szukający kurtki przewijał cztery
/// opatrunki, trzy plecaki i łom, żeby dowiedzieć się, czy w ogóle istnieje.
///
/// Zakładka to rodzaj przedmiotu z §4.1 — nic tutaj nie wymyśla kategorii,
/// katalog już to zrobił. Gdyby wymyślało, nowa receptura wpadałaby do
/// zakładki, o której nikt by nie pamiętał.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final book = RecipeBook.parse(File(kRecipesAsset).readAsStringSync());
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  /// Wszystko pod ręką i nic w robocie: wiersz odmawia wtedy tylko z powodów,
  /// które są jego własne.
  CraftBench benchWith({
    Map<String, int> materials = const {},
    int workshopLevel = 3,
    CraftJob? job,
  }) => CraftBench(
    atShelter: true,
    workshopLevel: workshopLevel,
    atHand: const {'tool_multitool', 'melee_hammer', 'tool_sewing_kit'},
    materials: materials,
    busy: job != null,
  );

  Future<void> pump(
    WidgetTester tester, {
    CraftJob? job,
    CraftBench? bench,
  }) async {
    // Szeroko, bo pasek zakładek jest przewijalny: zakładka poza ekranem to
    // test o przewijaniu, nie o warsztacie.
    tester.view.physicalSize = const Size(2400, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
        home: CraftScreen(
          book: book,
          catalogue: catalogue,
          bench: bench ?? benchWith(job: job),
          job: job,
          inventory: ValueNotifier(const Inventory()),
          names: names,
          itemNameOf: (id) =>
              catalogue[id]?.name.resolve(
                language: 'pl',
                lookup: names.forLanguage('pl'),
              ) ??
              id,
          onCraft: (_) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('§18.4: zakładki są rodzajami przedmiotów, nie wymysłem', () {
    testWidgets('jest zakładka na wszystko i po jednej na każdy rodzaj', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Wszystko'), findsOneWidget);
      expect(find.text('Odzież'), findsOneWidget);
      expect(find.text('Medykament'), findsOneWidget);
      expect(find.text('Broń biała'), findsOneWidget);
      expect(find.text('Plecak'), findsOneWidget);
    });

    testWidgets('i nie ma zakładki, za którą nic nie stoi', (tester) async {
      // ⚠️ Pusta zakładka to obietnica, której warsztat nie dotrzymuje.
      // Nikt nie robi amunicji ani książek, więc nie ma tych zakładek.
      await pump(tester);

      expect(find.text('Amunicja'), findsNothing);
      expect(find.text('Literatura'), findsNothing);
    });

    testWidgets('zakładka pokazuje tylko swoje', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Plecak'));
      await tester.pumpAndSettle();

      expect(find.text('Plecak biegowy'), findsOneWidget);
      expect(find.text('Bandaż improwizowany ×4'), findsNothing);
    });
  });

  group('§12: co przedmiot daje, zanim powstanie', () {
    testWidgets('każdy wiersz ma wejście w szczegóły', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Plecak'));
      await tester.pumpAndSettle();

      // Tyle wejść, ile plecaków — liczone z receptur, żeby dopisanie
      // kolejnego nie kazało poprawiać tej liczby ręcznie.
      final packs = book.recipes
          .where(
            (recipe) => catalogue[recipe.output]?.kind == ItemKind.backpack,
          )
          .length;

      expect(packs, greaterThan(1));
      expect(find.byIcon(Icons.info_outline), findsNWidgets(packs));
    });

    testWidgets('i otwiera ono arkusz z liczbami', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Plecak'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.info_outline).first);
      await tester.pumpAndSettle();

      // §4.5: pojemność jest jedynym powodem, dla którego nosi się plecak.
      expect(find.textContaining('l'), findsWidgets);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('§12: cisza tam, gdzie przycisk już mówi', () {
    testWidgets('zajęty warsztat nie powtarza tego w każdym wierszu', (
      tester,
    ) async {
      // ⚠️ Zgłoszone z terenu. „Coś już jest w robocie" pod dwudziestoma
      // sześcioma wierszami mówi jedną rzecz dwadzieścia sześć razy, a ta
      // jedna rzecz jest już powiedziana paskiem u góry i każdym martwym
      // przyciskiem.
      final job = CraftJob(
        recipeId: 'craft_spear',
        startedAt: DateTime.now().toUtc(),
        readyAt: DateTime.now().toUtc().add(const Duration(minutes: 20)),
      );

      await pump(tester, job: job);

      expect(find.textContaining('w robocie'), findsNothing);
    });

    testWidgets('ale przyciski są martwe, i to jest ta informacja', (
      tester,
    ) async {
      final job = CraftJob(
        recipeId: 'craft_spear',
        startedAt: DateTime.now().toUtc(),
        readyAt: DateTime.now().toUtc().add(const Duration(minutes: 20)),
      );

      await pump(tester, job: job);

      final buttons = tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      );

      expect(buttons, isNotEmpty);
      for (final button in buttons) {
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('a brak materiału wciąż mówi, czego brakuje', (tester) async {
      // Druga strona tej samej reguły: to, czego brakuje **temu wierszowi**,
      // zostaje. Ucichła tylko rzecz wspólna dla wszystkich.
      await pump(tester, bench: benchWith());

      expect(find.textContaining('materia'), findsWidgets);
    });
  });
}
