import 'dart:io';

import 'package:arls_za/game/controllers/starting_kit_controller.dart';
import 'package:arls_za/game/starting_kit.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_stats.dart';
import 'package:arls_za/sim/body.dart';
import 'package:test/test.dart';

/// CZTERY DECYZJE NA START (§4, §13.1, §18.1a).
///
/// ⚠️ **Nie ma tu drugiego modelu przedmiotu.** Zestaw startowy to tabela
/// id-ków z katalogu, a nie równoległa hierarchia klas ze statystykami —
/// bo druga hierarchia znaczyłaby dwa źródła prawdy o obrażeniach maczety, a
/// ten projekt złapał już dziesięć usterek tej klasy.
///
/// To, co tu jest sprawdzane, to trzy rzeczy, których katalog sam nie
/// gwarantuje: że każda pozycja istnieje, że każdy zestaw da się unieść, i że
/// obie możliwości w kroku dają się **porównać**, czyli mówią o tym samym.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  /// Najcięższy możliwy zestaw: pierwsza opcja w każdym kroku i tak dalej.
  Map<KitStep, KitOption> pickAll(int which) => {
    for (final step in KitStep.values)
      step: kStartingKit[step]![which % kStartingKit[step]!.length],
  };

  group('§4: co jest do wyboru', () {
    test('cztery kroki, i żaden nie jest pusty', () {
      expect(kStartingKit.keys.toSet(), KitStep.values.toSet());

      for (final step in KitStep.values) {
        expect(kStartingKit[step], isNotEmpty, reason: step.name);
      }
    });

    test('każdy krok to wybór, a nie ogłoszenie', () {
      // ⚠️ Jedna możliwość to nie decyzja, tylko ekran do przeklikania.
      for (final step in KitStep.values) {
        expect(
          kStartingKit[step]!.length,
          greaterThanOrEqualTo(2),
          reason: step.name,
        );
      }
    });

    test('i każda pozycja istnieje w katalogu', () {
      for (final options in kStartingKit.values) {
        for (final option in options) {
          expect(
            catalogue[option.itemId],
            isNotNull,
            reason: '${option.itemId} nie istnieje',
          );
          expect(option.count, greaterThan(0), reason: option.itemId);
        }
      }
    });

    test('a dwie możliwości w kroku dają się porównać', () {
      // ⚠️ To jest sedno ekranu podsumowania: dwie rzeczy w jednym kroku muszą
      // mówić o **tych samych** odczytach, inaczej „obok siebie" jest dwiema
      // osobnymi kartami, a nie porównaniem. Łom i wytrychy to jedyny krok, w
      // którym z założenia tak nie jest — narzędzie i broń mierzą co innego.
      for (final step in [KitStep.medical, KitStep.combat, KitStep.food]) {
        final keys = [
          for (final option in kStartingKit[step]!)
            {for (final stat in statsOf(catalogue[option.itemId]!)) stat.key},
        ];

        expect(
          keys.first.intersection(keys.last),
          isNotEmpty,
          reason: '${step.name}: nie ma wspólnego odczytu do porównania',
        );
      }
    });
  });

  group('§18.1a: i wszystko to trzeba unieść bez plecaka', () {
    test('każda kombinacja mieści się w kieszeniach', () {
      // ⚠️ Kreator, który przyjmuje wybór i dopiero potem mówi „nie mieści
      // się", odbiera decyzję zamiast ją wspierać. Dwanaście litrów §18.1a to
      // wszystko, co ma ktoś bez torby — a plecak jest do znalezienia.
      for (var a = 0; a < 2; a++) {
        for (var b = 0; b < 2; b++) {
          final picks = {
            KitStep.tools: kStartingKit[KitStep.tools]![a],
            KitStep.medical: kStartingKit[KitStep.medical]![b],
            KitStep.combat: kStartingKit[KitStep.combat]![a],
            KitStep.food: kStartingKit[KitStep.food]![b],
          };

          expect(
            kitFits(picks, catalogue, body: body),
            isTrue,
            reason: 'zestaw $a/$b nie mieści się w kieszeniach',
          );
        }
      }
    });

    test('i naprawdę trafia do plecaka, przez limity §18.1a', () {
      final pack = kitFor(pickAll(0), catalogue, body: body);

      expect(pack.carried, hasLength(KitStep.values.length));
      expect(pack.massKg(catalogue), greaterThan(0));
    });

    test('a niepełny wybór daje tyle, ile wybrano', () {
      final pack = kitFor(
        {KitStep.food: kStartingKit[KitStep.food]!.first},
        catalogue,
        body: body,
      );

      expect(pack.carried, hasLength(1));
    });
  });

  group('§12: kreator prowadzi po kolei', () {
    late StartingKitController wizard;

    setUp(() => wizard = StartingKitController());
    tearDown(() => wizard.dispose());

    test('zaczyna od pierwszego kroku i niczego nie ma', () {
      expect(wizard.step, KitStep.tools);
      expect(wizard.index, 0);
      expect(wizard.isComplete, isFalse);
    });

    test('wybór przesuwa na następny', () {
      wizard.pick(KitStep.tools, kStartingKit[KitStep.tools]!.first);

      expect(wizard.step, KitStep.medical);
      expect(wizard.index, 1);
    });

    test('i dopiero cztery wybory kończą', () {
      for (final step in KitStep.values) {
        expect(wizard.isComplete, isFalse, reason: step.name);
        wizard.pick(step, kStartingKit[step]!.first);
      }

      expect(wizard.isComplete, isTrue);
      expect(wizard.step, isNull);
      expect(wizard.picks, hasLength(4));
    });

    test('da się cofnąć, bo zmiana zdania jest częścią wyboru', () {
      wizard
        ..pick(KitStep.tools, kStartingKit[KitStep.tools]!.first)
        ..pick(KitStep.medical, kStartingKit[KitStep.medical]!.first)
        ..back();

      expect(wizard.step, KitStep.medical);
      expect(wizard.picks, hasLength(1));
    });

    test('a cofanie z pustego nie wywraca niczego', () {
      wizard.back();

      expect(wizard.step, KitStep.tools);
      expect(wizard.picks, isEmpty);
    });

    test('jeden wybór to jedno powiadomienie', () {
      // ⚠️ §3.3: osobne „zapisz" i „przejdź dalej" to dwie przebudowy drzewa
      // na jedno dotknięcie palcem.
      var rebuilds = 0;
      wizard.addListener(() => rebuilds++);

      wizard.pick(KitStep.tools, kStartingKit[KitStep.tools]!.first);
      expect(rebuilds, 1);

      // Ten sam wybór drugi raz nie jest zmianą.
      wizard.pick(KitStep.tools, kStartingKit[KitStep.tools]!.first);
      expect(rebuilds, 1);
    });

    test('wyborów nie da się zmienić z zewnątrz', () {
      wizard.pick(KitStep.tools, kStartingKit[KitStep.tools]!.first);

      expect(
        () => wizard.picks[KitStep.food] = kStartingKit[KitStep.food]!.first,
        throwsUnsupportedError,
      );
    });
  });
}
