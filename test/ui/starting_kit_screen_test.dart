import 'dart:io';

import 'package:arls_za/game/starting_kit.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/starting_kit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// DRUGI ETAP TWORZENIA POSTACI (§4, §12).
///
/// ⚠️ **Zgłoszone z terenu jako „okno się nie pojawia".** Model i stan zestawu
/// startowego powstały przed ekranem i przed wpięciem, więc przez jeden commit
/// istniała kompletna, przetestowana mechanika, do której nie było drzwi — ta
/// sama klasa usterki, którą ten projekt złapał już dziesięć razy, tyle że
/// zrobiona świadomie i na jeden krok.
///
/// Ten plik jest drzwiami przypiętymi do futryny: przepływ przez cztery kroki
/// aż do wyniku, którego nie da się dostać inaczej niż przechodząc wszystkie.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.merged([
    ItemNames.parse(File(kItemNamesAsset).readAsStringSync()),
    ItemNames.parse(File(kItemDescriptionsAsset).readAsStringSync()),
  ]);

  Map<KitStep, KitOption>? done;

  Future<void> pump(WidgetTester tester) async {
    done = null;
    tester.view.physicalSize = const Size(1080, 2400);
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
        home: StartingKitScreen(
          catalogue: catalogue,
          names: names,
          onDone: (picks) => done = picks,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Nazwa pierwszej możliwości w kroku, po polsku — czyli to, co widać.
  String firstOf(KitStep step) {
    final id = kStartingKit[step]!.first.itemId;
    return catalogue[id]!.name.resolve(
      language: 'pl',
      lookup: names.forLanguage('pl'),
    );
  }

  Future<void> pickThrough(WidgetTester tester, int howMany) async {
    for (final step in KitStep.values.take(howMany)) {
      await tester.tap(find.text(firstOf(step)).first);
      await tester.pumpAndSettle();
    }
  }

  group('§12: cztery kroki, po kolei', () {
    testWidgets('zaczyna od narzędzi i pokazuje, który to krok', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Jedno narzędzie'), findsOneWidget);
      expect(find.text('Krok 1 z 4'), findsOneWidget);
    });

    testWidgets('obie możliwości są widoczne naraz', (tester) async {
      // ⚠️ Wybór między dwiema rzeczami leżącymi obok siebie jest decyzją.
      // Jedna na ekranie z przewijaniem do drugiej jest quizem.
      await pump(tester);

      expect(find.text(firstOf(KitStep.tools)), findsOneWidget);
      expect(find.textContaining('Wytrychy'), findsOneWidget);
    });

    testWidgets('i każda mówi, czym jest', (tester) async {
      // §12: to samo zdanie, które gracz zobaczy potem na karcie przedmiotu.
      await pump(tester);

      expect(find.textContaining('kłódkę'), findsOneWidget);
    });

    testWidgets('wybór przenosi do następnego kroku', (tester) async {
      await pump(tester);
      await pickThrough(tester, 1);

      expect(find.text('Jeden opatrunek'), findsOneWidget);
      expect(find.text('Krok 2 z 4'), findsOneWidget);
    });

    testWidgets('a wstecz wraca i nie gubi reszty', (tester) async {
      await pump(tester);
      await pickThrough(tester, 2);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Jeden opatrunek'), findsOneWidget);
    });

    testWidgets('na pierwszym kroku nie ma z czego wracać', (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });

  group('§12: podsumowanie i jeden wynik', () {
    testWidgets('cztery wybory dają ekran podsumowania', (tester) async {
      await pump(tester);
      await pickThrough(tester, 4);

      expect(find.text('To jest wszystko, co masz'), findsOneWidget);
      expect(find.textContaining('trzeba znaleźć'), findsOneWidget);
    });

    testWidgets('i cztery karty obok siebie', (tester) async {
      await pump(tester);
      await pickThrough(tester, 4);

      for (final step in KitStep.values) {
        expect(find.text(firstOf(step)), findsOneWidget, reason: step.name);
      }
    });

    testWidgets('a wynik wychodzi dopiero po potwierdzeniu', (tester) async {
      // ⚠️ §11.1: zapis albo jest cały, albo go nie ma. Ekran, który oddaje
      // wybory po drodze, zostawiłby po przerwanym kreatorze wiersze
      // ekwipunku bez postaci.
      await pump(tester);
      await pickThrough(tester, 4);

      expect(done, isNull);

      await tester.tap(find.text('Bierz i idź'));
      await tester.pumpAndSettle();

      expect(done, hasLength(4));
      expect(done![KitStep.tools]!.itemId, 'melee_crowbar');
    });
  });

  test('§4: i kreator postaci naprawdę przez to przechodzi', () {
    // ⚠️ Test źródłowy, bo zgłoszenie brzmiało „okno się nie pojawia": ekran
    // może być doskonały i nieosiągalny. Tu sprawdzane jest to jedno — że
    // tworzenie postaci woła ten krok, i że wynik idzie do zapisu razem z
    // profilem, a nie osobno.
    final main = File('lib/main.dart').readAsStringSync();

    expect(main.contains('pickStartingKit('), isTrue);
    expect(
      main.contains('kit: kitFor('),
      isTrue,
      reason: 'zestaw ma być zapisany tą samą operacją co profil (§11.1)',
    );
  });
}
