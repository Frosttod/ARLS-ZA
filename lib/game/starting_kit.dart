/// Cztery decyzje, od których zaczyna się bieg (§4, §13.1).
///
/// ⚠️ **Nie ma tu drugiego modelu przedmiotu, i to jest cała architektura tego
/// pliku.** Prośba brzmiała „stwórz `ItemModel` ze `statSheet: Map<String,
/// double>`" — a `ItemDefinition` z `props` istnieje od etapu 4, [ItemStats]
/// od dawna zwraca porównywalne odczyty z jednostką i kierunkiem („mniej MOA
/// jest lepiej, więcej litrów jest lepiej"), i arkusz szczegółów rysuje z tego
/// porównanie obok siebie. Druga hierarchia znaczyłaby dwa źródła prawdy o
/// obrażeniach maczety — a ten projekt ma już dziesięć znalezisk tej klasy.
///
/// Więc wybór startowy to **tabela id-ków**, nie zestaw klas. Wszystkie osiem
/// pozycji istnieje w katalogu: łom i wytrychy, maczeta i siekiera, bandaże i
/// apteczka, konserwa warzywna i mięsna.
///
/// ⚠️ **I to jest zmiana projektowa, nie tylko ekran.** Dziś `GameSession.create`
/// nie zapisuje ani jednego wiersza ekwipunku — postać budzi się z niczym, i
/// pierwsza godzina gry jest o znalezieniu czegokolwiek. Cztery przedmioty na
/// start to inna gra: łagodniejsza, i z decyzją, która o kimś coś mówi.
library;

import '../inventory/inventory.dart';
import '../items/item_catalogue.dart';
import '../sim/body.dart';

/// Jeden z czterech kroków kreatora.
enum KitStep {
  /// §19.3: czym otwiera się zamknięte drzwi — głośno albo cicho.
  tools,

  /// §2.6: czym zamyka się to, co otwarte.
  medical,

  /// §5.5: co jest w ręce, kiedy zabraknie dystansu.
  combat,

  /// §2.2: pierwszy posiłek, i to, czego nie trzeba szukać dziś.
  food,
}

/// Jedna możliwość w kroku: przedmiot z katalogu i ile go jest.
///
/// ⚠️ Bez własnych statystyk. To, co ta rzecz robi, mówi katalog i [ItemStats];
/// tutaj jest tylko to, czego katalog nie wie — **ile sztuk** dostaje ktoś,
/// kto ją wybierze.
class KitOption {
  const KitOption({required this.itemId, this.count = 1});

  final String itemId;
  final int count;
}

/// §4, §13.1: co jest do wyboru w każdym kroku.
///
/// Pary, nie listy piętnastu: wybór między dwiema rzeczami, które robią co
/// innego, jest decyzją. Wybór z piętnastu jest przeglądaniem.
const Map<KitStep, List<KitOption>> kStartingKit = {
  // §19.3: dwanaście sekund i sto pięćdziesiąt metrów hałasu przeciw minucie i
  // dwudziestu. Ta sama para drzwi, dwie różne gry.
  KitStep.tools: [
    KitOption(itemId: 'melee_crowbar'),
    KitOption(itemId: 'tool_lockpicks', count: 4),
  ],

  // §2.6: pięć opatrunków na pięć ran przeciw jednej apteczce, która radzi
  // sobie z gorszą raną i kończy się szybciej.
  KitStep.medical: [
    KitOption(itemId: 'med_bandage', count: 5),
    KitOption(itemId: 'med_first_aid_kit'),
  ],

  // §5.5.3: 310 ml na cios bez wymagań siły przeciw cięższej siekierze, która
  // otwiera też drzwi (§19.3) i kosztuje kilogram czterysta.
  KitStep.combat: [
    KitOption(itemId: 'melee_machete'),
    KitOption(itemId: 'melee_axe'),
  ],

  // §2.2, §2.3: kalorie przeciw kaloriom **i wodzie**. Warzywa niosą trochę
  // płynu, mięso nie — a §2.3 zabija szybciej niż §2.2.
  KitStep.food: [
    KitOption(itemId: 'food_canned_meat', count: 2),
    KitOption(itemId: 'food_canned_vegetables', count: 3),
  ],
};

/// §4.5, §18.1a: co z tych czterech wyborów trafia do kieszeni.
///
/// ⚠️ **Przez [Inventory.add], nie obok niego.** Limity §18.1a — masa, objętość
/// i to, że bez plecaka mieści się dwanaście litrów — obowiązują tak samo w
/// pierwszej sekundzie biegu jak w każdej następnej. Ekran, który wsypuje
/// cztery przedmioty wprost do listy, jest ekranem, przez który da się wnieść
/// do gry rzeczy, których nie da się unieść.
Inventory kitFor(
  Map<KitStep, KitOption> picks,
  BodyProfile body,
  ItemCatalogue catalogue,
) {
  var pack = const Inventory();

  // Kolejność kroków, nie kolejność mapy: gdyby coś się nie zmieściło, ma
  // odpaść to, co gracz wybrał ostatnie, a nie to, co akurat wypadło z hasza.
  for (final step in KitStep.values) {
    final pick = picks[step];
    if (pick == null) continue;

    pack = pack
        .add(pick.itemId, catalogue, body: body, count: pick.count)
        .inventory;
  }

  return pack;
}

/// Czy ten zestaw w ogóle da się unieść bez plecaka (§18.1a, §4.5).
///
/// ⚠️ Sprawdzane **na wyborze**, nie po nim. Kreator, który przyjmuje wybór i
/// dopiero potem mówi „nie mieści się", odbiera decyzję zamiast ją wspierać —
/// a tu każdy zestaw ma się mieścić, i ten test jest po to, żeby nowa pozycja
/// w tabeli nie zepsuła tego po cichu.
bool kitFits(
  Map<KitStep, KitOption> picks,
  BodyProfile body,
  ItemCatalogue catalogue,
) {
  final pack = kitFor(picks, body, catalogue);
  final limits = pack.limits(body, catalogue);

  return pack.massKg(catalogue) <= limits.maxKg &&
      pack.volumeL(catalogue) <= limits.capacityL;
}
