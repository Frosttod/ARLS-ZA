// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class L10nPl extends L10n {
  L10nPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'ARLS-ZA';

  @override
  String get appTagline => 'Almost Real Life Survival';

  @override
  String get continueLabel => 'Kontynuuj';

  @override
  String get newCharacter => 'Nowa postać';

  @override
  String get settings => 'Ustawienia';

  @override
  String get saveRestoredTitle => 'Zapis odzyskany';

  @override
  String saveRestoredBody(int minutes) {
    return 'Plik zapisu był uszkodzony i został odtworzony z kopii. Straciłeś $minutes minut gry.';
  }

  @override
  String get saveLostTitle => 'Nie udało się odczytać zapisu';

  @override
  String get saveLostBody =>
      'Plik zapisu jest uszkodzony i nie znaleziono sprawnej kopii. Możesz wczytać wcześniej wyeksportowany profil albo zacząć nową postać.';

  @override
  String get importProfile => 'Wczytaj profil';

  @override
  String get exportProfile => 'Zapisz profil do pliku';

  @override
  String get exportDone => 'Profil zapisany.';

  @override
  String get importDone => 'Profil wczytany.';

  @override
  String importFailed(String reason) {
    return 'Wczytywanie nie powiodło się: $reason';
  }

  @override
  String get awayTitle => 'Kiedy Cię nie było';

  @override
  String awayElapsed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Minęło $days dni.',
      many: 'Minęło $days dni.',
      few: 'Minęły $days dni.',
      one: 'Minęła doba.',
      zero: 'Minęło mniej niż doba.',
    );
    return '$_temp0';
  }

  @override
  String get awayFloored =>
      'Organizm działał na rezerwach. Żaden zasób nie spadł poniżej progu bezpieczeństwa.';

  @override
  String get clockRolledBack =>
      'Zegar urządzenia cofnął się. Czas nie został naliczony.';

  @override
  String get bloodVolume => 'Objętość krwi';

  @override
  String get dailyRequirement => 'Zapotrzebowanie dobowe';

  @override
  String get carryComfort => 'Udźwig komfortowy';

  @override
  String get carryMax => 'Udźwig maksymalny';

  @override
  String get maxHeartRate => 'Tętno maksymalne';

  @override
  String unitMl(String value) {
    return '$value ml';
  }

  @override
  String unitKg(String value) {
    return '$value kg';
  }

  @override
  String unitBpm(String value) {
    return '$value bpm';
  }

  @override
  String get dataStaysOnDevice =>
      'Te wartości są liczone na Twoim telefonie i nigdy go nie opuszczają.';
}
