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

  @override
  String get createCharacter => 'Stwórz postać';

  @override
  String get creatorIntro =>
      'Twój wzrost, waga, wiek i płeć służą do obliczenia objętości krwi, zapotrzebowania na wodę i kalorie oraz udźwigu.';

  @override
  String get fieldName => 'Nazwa';

  @override
  String get fieldSex => 'Płeć';

  @override
  String get sexMale => 'Mężczyzna';

  @override
  String get sexFemale => 'Kobieta';

  @override
  String get fieldAge => 'Wiek';

  @override
  String get fieldHeight => 'Wzrost';

  @override
  String get fieldWeight => 'Waga';

  @override
  String get computedTitle => 'Twoje ciało, wyliczone';

  @override
  String get deathModeTitle => 'Wybierz, jak działa śmierć';

  @override
  String get deathModeWarning => 'Tego wyboru nie da się później zmienić.';

  @override
  String get hardcoreTitle => 'Hardcore';

  @override
  String get hardcoreBody =>
      'Śmierć kończy postać. Umiejętności, schron i magazyn przepadają; passa trafia do Kroniki.';

  @override
  String get softcoreTitle => 'Softcore';

  @override
  String get softcoreBody =>
      'Zamiast śmierci tracisz przytomność. Umiejętności i schron zostają; passa jest zerowana.';

  @override
  String get beginSurvival => 'Zaczynam';

  @override
  String get errNameTooShort => 'Co najmniej 4 znaki.';

  @override
  String get errNameTooLong => 'Najwyżej 16 znaków.';

  @override
  String get errNameInvalid => 'Tylko litery, cyfry i spacje.';

  @override
  String get errNameEdgeSpaces => 'Bez spacji na początku i końcu.';

  @override
  String get errNameDoubleSpaces => 'Bez podwójnych spacji.';

  @override
  String get errAgeRange => 'Od 16 do 80 lat.';

  @override
  String get errHeightRange => 'Od 120 do 220 cm.';

  @override
  String get errWeightRange => 'Od 35 do 200 kg.';

  @override
  String get errBmiTooLow =>
      'Te wartości nie opisują ciała, na którym model umie pracować. Sprawdź wzrost i wagę.';

  @override
  String get errBmiTooHigh =>
      'Te wartości nie opisują ciała, na którym model umie pracować. Sprawdź wzrost i wagę.';

  @override
  String get hudBlood => 'Krew';

  @override
  String get hudWater => 'Woda';

  @override
  String get hudCalories => 'Kalorie';

  @override
  String get hudHeartRate => 'Tętno';

  @override
  String get hudCarry => 'Udźwig';

  @override
  String get hudNoSignal => 'Brak sygnału';

  @override
  String get hudWeakSignal => 'Słaby sygnał';

  @override
  String get statusBleeding => 'Krwawienie';

  @override
  String get statusDehydrated => 'Odwodnienie';

  @override
  String get statusStarving => 'Głód';

  @override
  String get statusSleepDeprived => 'Niewyspanie';

  @override
  String get statusShock => 'Wstrząs';

  @override
  String get locationTitle => 'Gra potrzebuje twojej pozycji';

  @override
  String get locationBody =>
      'ARLS-ZA mierzy prawdziwy ruch prawdziwego ciała. Bez pozycji nie ma czego mierzyć. Dane nie opuszczają telefonu.';

  @override
  String get locationGrant => 'Udziel dostępu';

  @override
  String get locationSettings => 'Otwórz ustawienia';

  @override
  String get locationDeniedTitle => 'Dostęp do lokalizacji odrzucony';

  @override
  String get locationDeniedBody =>
      'Bez pozycji nie da się grać. Możesz to zmienić w ustawieniach systemu.';

  @override
  String get locationServiceOffTitle => 'Lokalizacja jest wyłączona';

  @override
  String get locationServiceOffBody =>
      'To ustawienie całego telefonu, nie tej gry. Włącz lokalizację i wróć.';

  @override
  String get locationForegroundOnlyTitle => 'Gra działa tylko na ekranie';

  @override
  String get locationForegroundOnlyBody =>
      'Nie masz zgody na lokalizację w tle, więc symulacja zatrzymuje się, gdy schowasz aplikację. To pełnoprawny wariant gry — nic nie tracisz poza chodzeniem z wygaszonym ekranem.';

  @override
  String get locationNotificationTitle => 'ARLS-ZA — trwa wyprawa';

  @override
  String get locationNotificationBody =>
      'Gra liczy twój ruch. Dotknij, aby wrócić.';

  @override
  String get integritySuspendedMock =>
      'Wykryto fałszywą lokalizację. Rozgrywka wstrzymana.';

  @override
  String get integritySuspendedVehicle =>
      'Jedziesz. Rozgrywka wstrzymana do czasu powrotu na własne nogi.';

  @override
  String get hudLowBattery => 'Bateria <20% — wracaj do schronu';

  @override
  String get hudEconomy => 'Tryb oszczędny';

  @override
  String get safetyNoCombatMoving => 'Nie graj podczas jazdy';

  @override
  String get safetyNightVisibility =>
      'Ciemno. Bądź widoczny i patrz, gdzie idziesz.';

  @override
  String get safetyBriefingTitle => 'Zanim wyjdziesz';

  @override
  String get safetyBriefingIntro =>
      'Ta gra mierzy prawdziwy ruch prawdziwego ciała po prawdziwym mieście. Wszystko poniżej dotyczy ciebie, nie postaci.';

  @override
  String get safetyRuleTraffic =>
      'Patrz na drogę, nie na telefon. Gra nie zna samochodów.';

  @override
  String get safetyRuleNoDriving =>
      'Nie graj w ruchu pojazdu. Powyżej 15 km/h walka jest zablokowana, a powyżej 40 km/h rozgrywka zostaje wstrzymana.';

  @override
  String get safetyRuleNoTrespass =>
      'Gra nigdy nie każe ci wejść na teren prywatny, na tory ani do wody. Jeśli znacznik wygląda inaczej — nie idź tam.';

  @override
  String get safetyRuleRespect =>
      'Szpitale, szkoły, cmentarze i miejsca kultu są wyłączone ze spawnu. Nie graj tam mimo to.';

  @override
  String get safetyRuleNight =>
      'Po zmroku bądź widoczny. Jasne ubranie, opaska odblaskowa, uszy wolne.';

  @override
  String get safetyRuleStop =>
      'Zmęczenie, ból, burza, obcy ludzie — kończ sesję. Postać poczeka.';

  @override
  String get safetyBriefingAccept => 'Rozumiem i biorę to na siebie';
}
