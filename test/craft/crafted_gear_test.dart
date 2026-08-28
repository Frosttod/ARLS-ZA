import 'dart:io';

import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/inventory/body_slots.dart';
import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:test/test.dart';

/// SZYCIE, KUCIE I TO, CO Z TEGO ZOSTAJE (§18.4, §18.6, §4.4).
///
/// ⚠️ **Warstwa rzemieślnicza, w której nic nie jest pisane dwa razy.**
///
/// Demontaż craftowanego przedmiotu nie jest wpisywany do danych: `salvage` na
/// przedmiocie jest ignorowany, gdy istnieje receptura, a odzysk i jego czas
/// liczy się z niej. To jedyny powód, dla którego ta warstwa nie rozjedzie się
/// przy pierwszej zmianie receptury — i jedyna rzecz, którą trzeba pilnować,
/// bo jest niewidoczna: wpisany `salvage` wygląda, jakby działał.
///
/// Reszta poniżej to reguły ekonomii §18.4: rzecz zrobiona ma być droższa niż
/// znaleziona, a łańcuch narzędzi nie może się zapętlić.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final book = RecipeBook.parse(File(kRecipesAsset).readAsStringSync());
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  /// §18.4's new rows: everything a pair of hands can make into gear.
  const gear = [
    'cloth_briefs',
    'cloth_tshirt',
    'cloth_cap',
    'cloth_sun_hat',
    'cloth_leather_cap',
    'armor_leather_pauldrons',
    'cloth_gloves_studded',
    'cloth_gloves_tactical',
    'cloth_trousers_reinforced',
    'cloth_cargo_pads',
    'cloth_sneakers',
    'cloth_boots_military',
    'pack_running',
    'pack_daypack',
    'pack_field',
    'melee_machete',
    'melee_crowbar',
    'tool_lockpicks',
  ];

  group('§18.4: każda nowa receptura robi coś, co istnieje', () {
    test('a każdy przedmiot da się zrobić', () {
      for (final id in gear) {
        expect(catalogue[id], isNotNull, reason: '$id nie ma w katalogu');
        expect(book.making(id), isNotNull, reason: '$id nie ma receptury');
      }
    });

    test('i ma nazwę w obu językach', () {
      // ⚠️ Nie ozdoba. Brakująca nazwa nie wywraca gry — wypisuje graczowi
      // surowe `cloth_briefs` w plecaku, i to w jednym języku, więc autor
      // nigdy tego nie zobaczy.
      for (final id in gear) {
        for (final language in const ['pl', 'en']) {
          expect(
            names.lookup('item.$id.name', language: language),
            isNotNull,
            reason: '$id nie ma nazwy w $language',
          );
        }
      }
    });

    test('materiały to materiały, nie gotowe przedmioty', () {
      for (final id in gear) {
        for (final material in book.making(id)!.materials.keys) {
          expect(
            material.startsWith('mat_'),
            isTrue,
            reason: '$id zużywa $material, a to nie jest surowiec',
          );
        }
      }
    });
  });

  group('§18.6: demontaż wychodzi z receptury, nie z danych', () {
    test('i to receptura wygrywa, gdy przedmiot ma oba', () {
      // ⚠️ `melee_machete` i `melee_crowbar` mają własny prop `salvage` z
      // czasów, gdy dało się je tylko znaleźć. Od dodania receptur ten prop
      // jest martwy — i to jest właściwe zachowanie, bo inaczej ta sama
      // maczeta rozbierałaby się inaczej zależnie od tego, skąd się wzięła.
      final machete = catalogue['melee_machete']!;

      expect(machete.props['salvage'], isNotNull);
      expect(
        materialContent(machete, book),
        book
            .making('melee_machete')!
            .materials
            .map((key, value) => MapEntry(key, value.toDouble())),
      );
    });

    test('każda nowa rzecz oddaje coś komuś, kto umie', () {
      // ⚠️ Przy pełnej Inżynierii, nie przy zerowej. Rzecz z jednej jednostki
      // materiału — slipy, wytrychy — przy udziale 0.40 nie oddaje nic i to
      // jest właściwe: nie da się odzyskać połowy kawałka tkaniny. Regułą
      // jest, że **nauka to zmienia**, a nie że każda rzecz zawsze coś oddaje.
      for (final id in gear) {
        // Rzecz robiona partią trzyma ułamek jednostki i nie oddaje nic —
        // patrz [materialContent]. To jest właściwe i dotyczy tu wytrychów:
        // cztery z dwóch kawałków metalu, więc jeden wytrych to pół kawałka.
        if (book.making(id)!.count > 1) continue;

        expect(
          salvageOf(
            catalogue[id]!,
            book,
            share: kSalvageReturnSkilled + kSalvageWorkshopBonus,
          ),
          isNotEmpty,
          reason: '$id rozbiera się w nic nawet przy pełnej Inżynierii',
        );
      }
    });

    test('i nigdy nie oddaje więcej, niż kosztowała', () {
      // §18.6: demontaż to odzysk, nie kopiarka. Bez tego pętla „zrób i
      // rozbierz" produkuje materiał z powietrza.
      for (final id in gear) {
        final recipe = book.making(id)!;
        final back = salvageOf(
          catalogue[id]!,
          book,
          share: kSalvageReturnSkilled + kSalvageWorkshopBonus,
        );

        var made = 0;
        for (final count in recipe.materials.values) {
          made += count;
        }
        var given = 0;
        for (final count in back.values) {
          given += count;
        }

        // ⚠️ Razy liczba sztuk z jednego przebiegu, i to jest ten test.
        // Receptura mówi, ile kosztuje **przebieg**, a przebieg medycznych
        // wierszy §18.4 robi cztery sztuki. Zanim to policzono, jeden kawałek
        // tkaniny stawał się czterema bandażami, a każdy z nich rozbierał się
        // w kawałek tkaniny.
        // Równo tyle, ile kosztowała, jest w porządku — slipy rozprute wracają
        // kawałkiem tkaniny. Więcej niż kosztowała nie jest.
        expect(
          given * recipe.count,
          lessThanOrEqualTo(made),
          reason: '$id oddaje ${given * recipe.count} za $made — kopiarka',
        );
      }
    });

    test('rozbiórka jest krótsza niż robota', () {
      for (final id in gear) {
        final recipe = book.making(id)!;

        expect(
          salvageTime(materialContent(catalogue[id]!, book)),
          lessThan(recipe.work),
          reason: '$id rozbiera się dłużej, niż powstaje',
        );
      }
    });
  });

  group('§18.4: co jest droższe od znalezienia', () {
    test('maczeta wymaga warsztatu, bo leży w sklepach', () {
      // ⚠️ Receptura na rzecz, którą można znaleźć, musi kosztować więcej niż
      // znalezienie. Maczeta na warsztacie 1 wyparłaby nóż jako standard, bo
      // dwa kawałki metalu leżą wszędzie.
      expect(catalogue['melee_machete']!.rarity, Rarity.uncommon);
      expect(
        book.making('melee_machete')!.workshopLevel,
        greaterThanOrEqualTo(2),
      );
    });

    test('a wytrychy nie, bo są rzadkie i ciche', () {
      // Odwrotna strona tej samej reguły: `tool_lockpicks` jest `rare`, a
      // cicha droga do zamkniętych drzwi nie może zależeć od tego, czy komuś
      // trafi się rzadki przedmiot. Dwa kawałki metalu i dwanaście minut.
      expect(catalogue['tool_lockpicks']!.rarity, Rarity.rare);
      expect(book.making('tool_lockpicks')!.workshopLevel, 0);
    });

    test('nic nie wymaga narzędzia, którego nie da się mieć', () {
      // ⚠️ Pętla, którą łatwo zamknąć przez przypadek: receptura wymagająca
      // narzędzia, które samo wymaga tego narzędzia.
      for (final id in gear) {
        final recipe = book.making(id)!;
        for (final tool in recipe.toolsAnyOf) {
          expect(catalogue[tool], isNotNull, reason: '$id chce $tool');

          final making = book.making(tool);
          expect(
            making?.toolsAnyOf.contains(tool) ?? false,
            isFalse,
            reason: '$tool wymaga sam siebie',
          );
        }
      }
    });
  });

  group('§4.4: ubranie, które da się założyć', () {
    test('każda nowa sztuka ma miejsce na ciele', () {
      for (final id in gear) {
        final item = catalogue[id]!;
        if (item.kind != ItemKind.armor) continue;

        expect(
          BodySlot.fromWire(item.props['slot'] as String?),
          isNotNull,
          reason: '$id nie wie, gdzie się nosi',
        );
      }
    });

    test('i mówi, ile grzeje — nawet gdy to zero', () {
      // ⚠️ Ciepło jeszcze nie dociera do ticka (`clothingClo` stoi na zerze),
      // więc te liczby są dziś martwe. Są tu, bo podłączenie temperatury nie
      // może wymagać przejścia całej garderoby i dopisania jej po fakcie.
      for (final id in gear) {
        final item = catalogue[id]!;
        if (item.kind != ItemKind.armor) continue;

        expect(item.props['insulation_clo'], isA<num>(), reason: id);
      }
    });

    test('pancerz bez pokrycia nie jest pancerzem', () {
      // Poziom ochrony bez `coverage_pct` nigdy nie wchodzi do walki: trafienie
      // sprawdza pokrycie najpierw. Sam poziom byłby liczbą na karcie i niczym
      // więcej.
      for (final id in gear) {
        final props = catalogue[id]!.props;
        final level = (props['protection_level'] as num?)?.toDouble() ?? 0;
        if (level <= 0) continue;

        expect(
          (props['coverage_pct'] as num?)?.toDouble() ?? 0,
          greaterThan(0),
          reason: '$id chroni na zero procent ciała',
        );
      }
    });
  });
}
