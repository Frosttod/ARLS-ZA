/// Cztery kroki kreatora zestawu startowego (§4, §12).
///
/// ⚠️ **`ChangeNotifier`, nie Bloc i nie Provider**, i to nie jest gust. Reguła
/// `ui → controllers → {sim, data}` jest pilnowana testem architektury, a
/// jedenaście kontrolerów tej gry to `ChangeNotifier` z `ValueNotifier` w
/// środku. Dwunasty w innym wzorcu znaczyłby dwa mechanizmy stanu obok siebie
/// — i to ten nowy byłby wyjątkiem, którego nikt nie pamięta.
///
/// ⚠️ **Atomowość jest tu regułą, nie optymalizacją.** Wybory żyją w pamięci
/// aż do ostatniego kroku; do bazy idzie **jeden** zapis, po potwierdzeniu.
/// Kreator zapisujący po każdym kroku zostawia po przerwanym tworzeniu postaci
/// wiersze ekwipunku bez postaci — a §11.1 mówi, że zapis albo jest cały, albo
/// go nie ma.
library;

import 'package:flutter/foundation.dart';

import '../starting_kit.dart';

class StartingKitController extends ChangeNotifier {
  /// Co wybrano do tej pory. Pusta mapa to pierwszy krok.
  final Map<KitStep, KitOption> _picks = {};

  /// ⚠️ Kopia tylko do odczytu. Ekran, który dostaje żywą mapę, jest ekranem,
  /// który może ją zmienić z pominięciem [pick] — a wtedy `notifyListeners`
  /// nigdy nie zostanie zawołane i widok rozjedzie się ze stanem.
  Map<KitStep, KitOption> get picks => Map.unmodifiable(_picks);

  /// Krok, na którym stoi kreator: pierwszy nierozstrzygnięty.
  ///
  /// Null znaczy, że wszystkie cztery są za nami — czyli czas na podsumowanie.
  KitStep? get step =>
      KitStep.values.where((step) => !_picks.containsKey(step)).firstOrNull;

  bool get isComplete => step == null;

  /// Który to krok z czterech, dla paska postępu (§12).
  int get index => _picks.length;

  /// §12: wybór i przejście dalej w jednym ruchu.
  ///
  /// ⚠️ Jedno `notifyListeners` na wybór, nie dwa. Osobne „zapisz" i „przejdź
  /// dalej" to dwie przebudowy drzewa na jedno dotknięcie palcem — a ten
  /// kreator stoi na początku gry, gdzie wszystko jest jeszcze zimne.
  void pick(KitStep at, KitOption option) {
    if (_picks[at] == option) return;

    _picks[at] = option;
    notifyListeners();
  }

  /// §12: krok wstecz. Zmiana zdania jest częścią wyboru — kreator, z którego
  /// nie da się cofnąć, jest ankietą.
  void back() {
    final done = KitStep.values.where(_picks.containsKey).toList();
    if (done.isEmpty) return;

    _picks.remove(done.last);
    notifyListeners();
  }
}
