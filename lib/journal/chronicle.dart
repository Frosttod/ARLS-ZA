/// Passy, które się skończyły (§13.1, §9.3).
///
/// ⚠️ **Wiersze były zapisywane od pierwszego dnia i nikt ich nigdy nie
/// przeczytał.** `ChronicleEntries` wypełnia się przy każdej śmierci, a
/// `chronicleFor` nie miał w grze ani jednego wołającego — czternasty raz ta
/// sama klasa usterki: dane poprawne, kompletne i niedostępne z gry.
///
/// §13.1 mówi wprost, po co to jest: hardcore ma sens tylko wtedy, gdy passa,
/// która padła, zostaje na czymś zapisana. Licznik dni, którego po śmierci nie
/// da się już zobaczyć, jest licznikiem donikąd.
library;

/// Jedna skończona passa.
class PastRun {
  const PastRun({
    required this.days,
    required this.startedAt,
    required this.endedAt,
    required this.cause,
    required this.hardcore,
  });

  /// §13.1: liczba, o którą chodzi w całym biegu.
  final int days;

  final DateTime startedAt;
  final DateTime endedAt;

  /// Co ją zakończyło, tak jak zapisała to §13.
  final String cause;

  /// ⚠️ Tryb zapisany **przy śmierci**, nie odczytany z profilu dzisiaj.
  /// Wybór jest nieodwracalny (§9, §15.4), ale profil może być inny niż ten,
  /// który tę passę przeżył — a passa hardcore przemianowana po fakcie na
  /// softcore byłaby kłamstwem o jedynej rzeczy, którą ten ekran mierzy.
  final bool hardcore;

  /// Ile realnie trwała, co nie musi być tym samym co [days]: śmierć o świcie
  /// czwartego dnia to trzy dni i parę godzin.
  Duration get lasted => endedAt.difference(startedAt);
}
