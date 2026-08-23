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
  String get hudSleep => 'Sen';

  @override
  String get hudHeartRate => 'Tętno';

  @override
  String hudThreat(int count, int metres) {
    return '$count w walce · najbliżej $metres m';
  }

  @override
  String get hudThreatSprint => 'ma jeszcze sprint';

  @override
  String get hudCarry => 'Udźwig';

  @override
  String get hudBulk => 'Objętość';

  @override
  String get hudNoSignal => 'Brak sygnału';

  @override
  String get hudAcquiring => 'Szukam GPS';

  @override
  String get hudWeakSignal => 'Słaby sygnał';

  @override
  String statusDegree(String degree) {
    return '$degree stopnia';
  }

  @override
  String statusOfDaily(int percent) {
    return '$percent% dobowej normy';
  }

  @override
  String statusDebtHours(int hours) {
    return '$hours h długu';
  }

  @override
  String get statusEffect => 'Wpływ';

  @override
  String get statusFix => 'Co zrobić';

  @override
  String get statusWhere => 'Gdzie znaleźć';

  @override
  String get commonOk => 'OK';

  @override
  String get statusShockEffect =>
      'Rozrzut przy każdym strzale, mniejszy udźwig, a od III stopnia obraz ciemnieje i bieg powoduje zawroty głowy.';

  @override
  String get statusShockFix =>
      'Najpierw zatrzymaj krwawienie — bandaż albo opaska uciskowa. Krew wraca sama, powoli, i tylko jeśli jesz i pijesz.';

  @override
  String get statusShockWhere =>
      'Apteki, przychodnie, karetki; apteczki w biurach i warsztatach.';

  @override
  String get statusDehydratedEffect =>
      'Najpierw ręce: celność i czas reakcji. Głębiej — decyzje, potem siła.';

  @override
  String get statusDehydratedFix =>
      'Pij. Działa przez jakieś dwadzieścia minut, nie natychmiast — więc pij zanim będzie trzeba.';

  @override
  String get statusDehydratedWhere =>
      'Sklepy, stacje paliw, mieszkania. Wodę z kranu albo ze strumienia trzeba najpierw przegotować lub uzdatnić.';

  @override
  String get statusStarvingEffect =>
      'Wszystko trwa dłużej — przeszukiwanie, opatrywanie, budowanie — a z tym spada precyzja.';

  @override
  String get statusStarvingFix =>
      'Zjedz. Konserwy i suchy prowiant się nie psują; ugotowane daje więcej na kilogram noszenia.';

  @override
  String get statusStarvingWhere =>
      'Sklepy, mieszkania, restauracje, działki. Przy ciałach rzadko jest coś więcej niż przekąska.';

  @override
  String get statusSleepDeprivedEffect =>
      'Każdy strzał ma większy rozrzut, nauka idzie wolniej, a po dobie na nogach oczy same zamykają się na kilka sekund.';

  @override
  String get statusSleepDeprivedFix =>
      'Śpij. Tylko sen to spłaca — i tylko tam, gdzie da się położyć, czyli w schronie.';

  @override
  String get statusSleepDeprivedWhere =>
      'Własny schron. Łóżko albo materac sprawia, że godziny liczą się mocniej.';

  @override
  String get statusBleeding => 'Krwawienie';

  @override
  String get statusDehydrated => 'Odwodnienie';

  @override
  String get statusStarving => 'Głód';

  @override
  String get statusSleepDeprived => 'Niewyspanie';

  @override
  String get bleedSuperficial => 'powierzchowne';

  @override
  String get bleedModerate => 'umiarkowane';

  @override
  String get bleedSevere => 'silne';

  @override
  String get bleedArterial => 'tętnicze';

  @override
  String statusBleedingEffect(int millilitres) {
    return '$millilitres ml na minutę, a bieg to zwielokrotnia — przy tętnie 160 wobec spoczynkowego 70 jest to ponad dwa razy tyle. Dopóki coś jest otwarte, krew w ogóle nie wraca.';
  }

  @override
  String get statusBleedingFix =>
      'Opatrunek uciskowy i stanie w miejscu, dopóki trwa.';

  @override
  String get statusBleedingFixArterial =>
      'Staza, i nic innego. Opatrunek tego nie utrzyma.';

  @override
  String get statusBleedingWhere =>
      'Apteki, przychodnie, karetki; apteczki w biurach i warsztatach.';

  @override
  String get deathTitle => 'TO KONIEC';

  @override
  String get downTitle => 'STRACIŁEŚ PRZYTOMNOŚĆ';

  @override
  String get causeBloodLoss => 'Utrata krwi';

  @override
  String get causeThirst => 'Odwodnienie';

  @override
  String get causeStarvation => 'Wyczerpanie z głodu';

  @override
  String get deathWhat =>
      'Hardcore: ta postać się skończyła. Passa trafia do Kroniki wraz ze wszystkim, co osiągnęła. Nowa zachowa Twoje ciało — ten sam wzrost, wagę i wiek — zmieni się tylko imię.';

  @override
  String get downWhat =>
      'Ockniesz się tam, gdzie będziesz, za godzinę — z ćwiercią krwi i niemal pustym żołądkiem. To, co miałeś w rękach, przepadło; około połowy noszonego sprzętu leży tam, gdzie padłeś. Przez dziesięć minut po przebudzeniu będą Cię brać za martwego — ale i Ty nie możesz walczyć.';

  @override
  String downLeft(String time) {
    return '$time';
  }

  @override
  String get downClosedApp =>
      'Godzina leci niezależnie od tego, czy aplikacja jest otwarta.';

  @override
  String get downLog => 'Ostatnie chwile';

  @override
  String get downGrace => 'Wciąż biorą Cię za martwego. Nie zdradź się.';

  @override
  String get deathNewCharacter => 'Nowa postać';

  @override
  String get deathSameBody => 'To samo ciało, nowe imię.';

  @override
  String get downCaches => 'To, co niosłeś, leży rozrzucone tam, gdzie padłeś.';

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

  @override
  String get regionTitle => 'Wybierz region';

  @override
  String get regionIntro =>
      'Gra działa bez sieci, więc mapa musi być na telefonie. Pobierz pakiet dla okolicy, po której będziesz chodzić.';

  @override
  String regionSizeMb(String mb) {
    return '$mb MB';
  }

  @override
  String get regionInstalled => 'Pobrany';

  @override
  String get regionUnavailable => 'Niedostępny';

  @override
  String get regionDownload => 'Pobierz';

  @override
  String get regionDelete => 'Usuń';

  @override
  String get regionCancel => 'Przerwij';

  @override
  String get regionRetry => 'Spróbuj ponownie';

  @override
  String get regionNearYou => 'W twojej okolicy';

  @override
  String regionDownloading(int percent) {
    return 'Pobieranie… $percent%';
  }

  @override
  String get regionErrSpace =>
      'Za mało miejsca. Zwolnij trochę i spróbuj ponownie.';

  @override
  String get regionErrNetwork =>
      'Pobieranie przerwane. To, co się ściągnęło, zostaje — kolejna próba dokończy.';

  @override
  String get regionErrCorrupt =>
      'Pobrany plik nie zgadza się z sumą kontrolną. Został usunięty.';

  @override
  String get regionErrUnpublished => 'Ten region nie został jeszcze wydany.';

  @override
  String get regionLeftPackTitle => 'Jesteś poza pobraną mapą';

  @override
  String get regionLeftPackBody =>
      'Bez kafelków nie ma czego rysować ani gdzie stawiać znaczników. Pobierz pakiet dla tej okolicy albo wróć w zasięg poprzedniego.';

  @override
  String get menuProfile => 'PROFIL';

  @override
  String get profileBody => 'To ciało';

  @override
  String get profileBlood => 'Objętość krwi';

  @override
  String get profileEnergy => 'Zapotrzebowanie dobowe';

  @override
  String get profileWater => 'Woda na dobę';

  @override
  String get profileCarry => 'Udźwig, komfort / maks';

  @override
  String get profileHeart => 'Tętno, spoczynek do maks';

  @override
  String get profileAim => 'Co sprawia, że chybiasz';

  @override
  String get profileTotalSpread => 'Razem';

  @override
  String get profileAimWhat =>
      'Stanie w miejscu usuwa dwa największe wiersze: własne tempo i własne tętno. Nic innego na tej liście nie da się naprawić od ręki.';

  @override
  String get profileFighting => 'W terenie';

  @override
  String get profileShots => 'Oddane strzały';

  @override
  String get profileAccuracy => 'Celność';

  @override
  String get profileSwings => 'Ciosy wręcz';

  @override
  String get profileKills => 'Zabici';

  @override
  String get profileShotsPerKill => 'Naboi na przeciwnika';

  @override
  String get profileBloodDealt => 'Zadana utrata krwi';

  @override
  String get profileBloodLost => 'Własna utrata krwi';

  @override
  String get profileSearches => 'Przeszukane miejsca';

  @override
  String get profileBlackouts => 'Utraty przytomności';

  @override
  String get profileWhereTheyLand => 'Gdzie trafiają Twoje strzały';

  @override
  String get profileNothingYet => 'Jeszcze nic nie trafiło.';

  @override
  String get profileSkills => 'Umiejętności';

  @override
  String get profileSkillsSoon =>
      'Jeszcze ich nie ma. Dopóki nie będzie, każdy strzela jak nowicjusz — dwadzieścia pięć minut kątowych, czyli największy wiersz powyżej.';

  @override
  String profileAliveDays(int days, int hours) {
    return 'Żyje $days d $hours h';
  }

  @override
  String profileAliveHours(int hours) {
    return 'Żyje $hours h';
  }

  @override
  String get menuInventory => 'EKWIPUNEK';

  @override
  String get menuShelter => 'SCHRON';

  @override
  String get stashOnTheShelves => 'W magazynie';

  @override
  String get stashInThePack => 'W plecaku';

  @override
  String get stashEmpty => 'Jeszcze nic tu nie ma.';

  @override
  String get stashPackEmpty => 'Plecak jest pusty.';

  @override
  String get stashStore => 'Zostaw';

  @override
  String get stashTake => 'Weź';

  @override
  String get stashFull => 'W magazynie nie ma miejsca.';

  @override
  String get stashNoRoomInPack => 'To się nie mieści w plecaku.';

  @override
  String get shelterShelves => 'Półki';

  @override
  String get shelterShelvesWhat =>
      'Co tu zostawisz, to tu zostanie. Dom mieści tyle, ile mieści; Magazyn dokłada pięćdziesiąt kilogramów na poziom.';

  @override
  String get shelterTitle => 'Schron';

  @override
  String get campTitle => 'Obóz';

  @override
  String get shelterCamps => 'Obozy';

  @override
  String get shelterBuild => 'Buduj';

  @override
  String get shelterBuildHere => 'Buduj tutaj';

  @override
  String get shelterCancel => 'Przerwij';

  @override
  String get shelterCancelTitle => 'Przerwać budowę?';

  @override
  String get shelterCancelKeep => 'Buduj dalej';

  @override
  String get shelterCancelConfirm => 'Przerwij';

  @override
  String get shelterCancelled => 'Praca porzucona.';

  @override
  String get shelterCancelShelterWhat =>
      'Materiały są już w ścianach i nie wrócą. Miejsce znika razem z nimi, a budowa tutaj zacznie się od zera. Tego nie da się cofnąć.';

  @override
  String get shelterCancelCampWhat =>
      'Obóz znika, a z nim wszystko, co w niego poszło. Postawienie go tu ponownie zacznie się od zera. Tego nie da się cofnąć.';

  @override
  String get shelterCancelModuleWhat =>
      'Materiały na ten poziom przepadły — są już w konstrukcji. Ukończone poziomy zostają. Rozpoczęcie tego od nowa oznacza przyniesienie wszystkiego jeszcze raz. Tego nie da się cofnąć.';

  @override
  String get shelterDemolish => 'Rozmontuj';

  @override
  String get shelterDemolished => 'Moduł rozmontowany.';

  @override
  String shelterDemolishWhat(String gives) {
    return 'Rozmontowanie tego modułu zwraca połowę surowców: $gives. Niższe poziomy zostają. Tej decyzji nie można cofnąć.';
  }

  @override
  String get shelterSafeZone => 'Strefa bezpieczna';

  @override
  String get shelterSleep => 'Jakość snu';

  @override
  String get shelterStorage => 'Pojemność';

  @override
  String get shelterNoFix =>
      'Brak pozycji — schron powstaje tam, gdzie stoisz.';

  @override
  String get shelterNotHere => 'Żeby rozbudowywać schron, trzeba w nim być.';

  @override
  String get shelterWorkStopped => 'Praca stoi — nikogo nie ma na miejscu.';

  @override
  String get shelterNeedsTool =>
      'Wymaga młotka. Od Warsztatu 2 także multitoola.';

  @override
  String shelterMissing(String what) {
    return 'Brakuje: $what';
  }

  @override
  String shelterBuildingLeft(String time) {
    return 'Zostało $time';
  }

  @override
  String get shelterNoneWhat =>
      'Powstaje tam, gdzie stoisz, i to tam będziesz wracać spać. Pięćdziesiąt metrów ziemi, na którą umarli nie wchodzą — i z której ty też nie strzelasz.';

  @override
  String get campWhat =>
      'Gdzieś indziej, gdzie spędzasz dzień: praca, uczelnia, mieszkanie rodziny. Dwadzieścia metrów, skrzynia i noc warta siedem dziesiątych. Najwyżej dwa i nie bliżej niż 800 m od tego, co już stoi.';

  @override
  String get campTooMany => 'Dwa obozy to maksimum. Najpierw zwiń któryś.';

  @override
  String get campTooCloseToShelter =>
      'Bliżej niż 800 m od schronu — to byłyby po prostu drugie drzwi.';

  @override
  String get campTooCloseToCamp => 'Bliżej niż 800 m od drugiego obozu.';

  @override
  String get campTooCloseToHotspot => 'Za blisko środka ogniska.';

  @override
  String get campDecaying =>
      'Nikogo tu nie było od dwóch tygodni. Zaczyna się rozpadać.';

  @override
  String get moduleStorage => 'Magazyn';

  @override
  String get moduleWorkshop => 'Warsztat';

  @override
  String get moduleLounge => 'Salon';

  @override
  String get moduleLaboratory => 'Laboratorium';

  @override
  String get moduleStorageWhat =>
      'Pięćdziesiąt kilogramów na poziom, ponad dwadzieścia pięć, które schron mieści goły.';

  @override
  String get moduleWorkshopWhat =>
      'Naprawy: do 60% kondycji, potem 85%, potem jak nowe. Poziom 2 otwiera też receptury złożone.';

  @override
  String get moduleLoungeWhat =>
      'Piętnaście procent na poziom mniej do przespania — godzina nocy do odzyskania.';

  @override
  String get moduleLaboratoryWhat =>
      'Trzy procent na poziom więcej z każdego posiłku i napoju.';

  @override
  String get shelterBuildStarted =>
      'Praca ruszyła. Idzie dalej przy zamkniętej aplikacji.';

  @override
  String get shelterInside => 'Ze swojej strefy nie strzelasz.';

  @override
  String get menuSettings => 'USTAWIENIA';

  @override
  String get mapRecentre => 'Wróć do siebie';

  @override
  String get mapNoPack => 'Brak mapy dla tej okolicy';

  @override
  String get mapMarkerEnemy => 'Przeciwnik';

  @override
  String get mapMarkerLoot => 'Skrzynia';

  @override
  String get placePharmacy => 'Apteka';

  @override
  String get placeHardware => 'Sklep budowlany';

  @override
  String get placeGrocery => 'Sklep spożywczy';

  @override
  String get placeSports => 'Sklep sportowy';

  @override
  String get placeWeapons => 'Sklep z bronią';

  @override
  String get placeLibrary => 'Biblioteka';

  @override
  String get placeIndustrial => 'Teren przemysłowy';

  @override
  String get placeHospital => 'Szpital';

  @override
  String get placeMilitary => 'Teren wojskowy';

  @override
  String get placeSchool => 'Szkoła';

  @override
  String get placeWarehouse => 'Magazyn';

  @override
  String get placeCar => 'Samochód';

  @override
  String get placeHouse => 'Opuszczony dom';

  @override
  String get placeBarn => 'Stodoła';

  @override
  String get placeGarage => 'Warsztat';

  @override
  String get placeWaste => 'Śmietnik';

  @override
  String get placePicnic => 'Wiata';

  @override
  String get placeHuntingStand => 'Ambona';

  @override
  String get placeWaterPoint => 'Ujęcie wody';

  @override
  String get placeRoadside => 'Pobocze';

  @override
  String get placeAmbulance => 'Ambulans';

  @override
  String get placePoliceCar => 'Radiowóz';

  @override
  String get mapMarkerDropped => 'Porzucony przedmiot';

  @override
  String get mapMarkerRemains => 'Ciało';

  @override
  String get remainsTitle => 'Ciało';

  @override
  String get remainsSearch => 'Przeszukaj';

  @override
  String get remainsSearched => 'Kieszenie przeszukane.';

  @override
  String get remainsEmptied => 'Już przeszukane.';

  @override
  String get remainsUnsearched =>
      'Nikt tu nie zaglądał. Podejdź na wyciągnięcie ręki, aby przeszukać.';

  @override
  String get mapMarkerShelter => 'Schron';

  @override
  String get mapPlayerLabel => 'Ty';

  @override
  String get regionPlayNow => 'Graj teraz';

  @override
  String get regionStreamed => 'Mapa z sieci';

  @override
  String get regionStreamWarnTitle => 'Mapa z sieci zamiast z telefonu';

  @override
  String get regionStreamWarnBody =>
      'Możesz zacząć od razu — gra pobierze tylko te fragmenty mapy, które akurat widzisz. Dwie rzeczy warto wiedzieć: potrzebujesz zasięgu przez całą sesję, a serwer z mapą dowie się z grubsza, gdzie jesteś. Pobrany pakiet nie wysyła nic i działa w lesie.';

  @override
  String get regionStreamWarnAccept => 'Rozumiem, gram z sieci';

  @override
  String get languageTitle => 'Wybierz język';

  @override
  String get languageBody =>
      'Zasady bezpieczeństwa, które przeczytasz za chwilę, dotyczą ruchu drogowego i obcych ludzi. Wybierz język, w którym naprawdę je zrozumiesz.';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeTitle => 'Wygląd';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeSystem => 'Jak w systemie';

  @override
  String get kindFirearm => 'Broń palna';

  @override
  String get kindMelee => 'Broń biała';

  @override
  String get kindArmor => 'Odzież';

  @override
  String get kindBackpack => 'Plecak';

  @override
  String get kindFood => 'Żywność';

  @override
  String get kindMedical => 'Medykament';

  @override
  String get kindLiterature => 'Literatura';

  @override
  String get kindTool => 'Narzędzie';

  @override
  String get kindAttachment => 'Dodatek';

  @override
  String get kindCrafting => 'Surowiec';

  @override
  String get kindAmmo => 'Amunicja';

  @override
  String get kindMaterial => 'Surowiec';

  @override
  String get kindMisc => 'Inne';

  @override
  String get searchArea => 'Przeszukaj teren';

  @override
  String get searchAreaRunning => 'Rozglądasz się…';

  @override
  String get searchHere => 'Przeszukaj';

  @override
  String get searchShallow => 'Pobieżnie · 30 s';

  @override
  String get searchThorough => 'Dokładnie · 90 s';

  @override
  String get searchDeep => 'Gruntownie · 180 s';

  @override
  String get searchCancel => 'Przerwij';

  @override
  String get searchMoved => 'Ruszyłeś się — przeszukanie przerwane.';

  @override
  String get searchLostSignal => 'Przeszukanie przerwane: brak pewnej pozycji.';

  @override
  String get searchNoise => 'Przeszukanie słychać z około 80 m.';

  @override
  String searchFound(String items) {
    return 'Znaleziono: $items';
  }

  @override
  String get searchFoundNothing => 'Nic wartego niesienia.';

  @override
  String get searchNoRoom => 'Nie wszystko się mieści — reszta zostaje.';

  @override
  String get searchEmpty => 'Już przeszukane.';

  @override
  String searchRevealed(int count) {
    return 'Odsłonięte miejsca: $count';
  }

  @override
  String get searchNothingNew => 'Nic nowego tutaj.';

  @override
  String get searchTooSoon => 'Nie ma tu jeszcze nic nowego do wypatrzenia.';

  @override
  String get searchTooClose => 'Patrzyłbyś na ten sam teren.';

  @override
  String searchFoundNearby(String what) {
    return 'Zauważasz w pobliżu: $what.';
  }

  @override
  String get scoutCar => 'porzucony samochód';

  @override
  String get scoutWaste => 'kontener na śmieci';

  @override
  String get placeDistance => 'Odległość';

  @override
  String get placeWayIn => 'Wejście';

  @override
  String get placeOpen => 'Otwarte';

  @override
  String get placeSearched => 'Przeszukane';

  @override
  String get placeUntouched => 'Jeszcze nie';

  @override
  String placePartly(int percent) {
    return 'zostało $percent%';
  }

  @override
  String placeStripped(int hours) {
    return 'Puste — coś wróci za jakieś $hours h';
  }

  @override
  String get placeCanStill => 'Jeszcze możliwe';

  @override
  String get placeNothingLeft => 'Nie ma już czego przewracać';

  @override
  String get placeHolds => 'Można znaleźć';

  @override
  String combatHurt(int millilitres) {
    return 'Trafiony — $millilitres ml';
  }

  @override
  String get combatStrike => 'Cios';

  @override
  String get enemyWalker => 'Szwędacz';

  @override
  String get enemyLeaper => 'Skakun';

  @override
  String get enemyBrute => 'Brutal';

  @override
  String get enemyCalm => 'nie widzi cię';

  @override
  String get enemySearching => 'szuka cię';

  @override
  String get enemyHunting => 'idzie po ciebie';

  @override
  String get enemyHealthy => 'Zdrowy';

  @override
  String get enemyWounded => 'Ranny';

  @override
  String get enemyCritical => 'Krytyczny';

  @override
  String get enemySprint => 'Sprint';

  @override
  String get combatReload => 'Przeładuj';

  @override
  String get combatReloading => 'Przeładowanie…';

  @override
  String get combatReloadBroken => 'Za blisko — magazynek zostaje.';

  @override
  String combatRounds(int loaded, int magazine) {
    return '$loaded / $magazine';
  }

  @override
  String get combatAiming => 'Celowanie…';

  @override
  String get combatOnTarget => 'Namierzony';

  @override
  String combatHurtAt(String where, int millilitres) {
    return 'Dostałeś — $where, $millilitres ml';
  }

  @override
  String combatHitAt(String where, int millilitres) {
    return 'Trafienie — $where, $millilitres ml';
  }

  @override
  String get combatExecution => 'Strzał w głowę. Koniec.';

  @override
  String get hitHead => 'głowa';

  @override
  String get hitTorso => 'tors';

  @override
  String get hitArms => 'ręka';

  @override
  String get hitLegs => 'noga';

  @override
  String get enemyBleeding => 'krwawi';

  @override
  String get combatFire => 'Ognia';

  @override
  String get combatFireAway => 'Strzał w powietrze';

  @override
  String get fireAwayUnloaded => 'Nic w komorze.';

  @override
  String get fireAwayInShelter => 'Nie z własnego terenu.';

  @override
  String get combatFiredAway => 'Strzał w powietrze. Ktoś przyjdzie sprawdzić.';

  @override
  String combatChance(int percent) {
    return '$percent% trafienia';
  }

  @override
  String combatDistance(int metres) {
    return '$metres m';
  }

  @override
  String get combatNoWeapon => 'Nic w ręku.';

  @override
  String get combatNoAmmo => 'Brak amunicji do tego.';

  @override
  String get reloadNoMagazine => 'Brak pasującego magazynka.';

  @override
  String get reloadNothingFuller => 'Nie ma pełniejszego do wymiany.';

  @override
  String get reloadAlreadyFull => 'Już załadowana.';

  @override
  String get magazineFill => 'Napełnij';

  @override
  String get magazineEmpty => 'Rozładuj';

  @override
  String get slotMagazine => 'Magazynek';

  @override
  String get slotOptic => 'Celownik';

  @override
  String get slotBarrel => 'Lufa';

  @override
  String get slotGrip => 'Chwyt';

  @override
  String get slotRail => 'Szyna';

  @override
  String get slotEmpty => 'puste';

  @override
  String get craftTitle => 'Wytwarzanie';

  @override
  String actionBusy(String what) {
    return 'Zajęty: $what';
  }

  @override
  String actionEating(String item) {
    return 'Jesz: $item';
  }

  @override
  String actionDrinking(String item) {
    return 'Pijesz: $item';
  }

  @override
  String actionUsing(String item) {
    return 'Używasz: $item';
  }

  @override
  String actionLoading(String item) {
    return 'Ładujesz: $item';
  }

  @override
  String actionUnloading(String item) {
    return 'Rozładowujesz: $item';
  }

  @override
  String get craftBenchFree => 'Nic w robocie';

  @override
  String get craftTakeApart => 'Rozbierz';

  @override
  String get craftPartlyApart => 'częściowo rozebrany';

  @override
  String get craftStop => 'Przerwij';

  @override
  String get craftStopKeepsWork =>
      'Przerwanie zachowuje pracę. Przedmiot zostaje rozebrany.';

  @override
  String get craftStopped => 'Przerwane. To, co zrobione, zostaje.';

  @override
  String get craftTakeApartRunning => 'Rozbiórka w toku';

  @override
  String get craftDone => 'Gotowe.';

  @override
  String craftDismantleWarning(String gives, int minutes) {
    return 'Nie wróci. Zostanie: $gives. $minutes minut.';
  }

  @override
  String get craftMake => 'Wytwórz';

  @override
  String get craftCancel => 'Przerwij';

  @override
  String get craftCancelWarning => 'Materiały przepadają. Poszły w to.';

  @override
  String get craftNeedsTool => 'Wymaga';

  @override
  String get craftNoTool => 'Nie ma czym.';

  @override
  String get craftNoMaterials => 'Brakuje materiału.';

  @override
  String get craftBenchBusy => 'Coś już jest w robocie.';

  @override
  String get craftNotAtShelter => 'Nie tutaj — w schronie.';

  @override
  String get craftNothingBack => 'Nie ma z tego czego odzyskać.';

  @override
  String craftNeedsWorkshop(int level) {
    return 'Warsztat L$level';
  }

  @override
  String craftMaking(String item) {
    return 'Wytwarzanie: $item';
  }

  @override
  String craftTakingApart(String item) {
    return 'Rozbiórka: $item';
  }

  @override
  String attachmentChoose(int count) {
    return 'Do wyboru: $count';
  }

  @override
  String get reloadFitting => 'Montowanie magazynka';

  @override
  String get reloadSwapping => 'Wymiana magazynka';

  @override
  String get reloadFeeding => 'Ładowanie naboi';

  @override
  String magazineRounds(int rounds, int capacity) {
    return '$rounds / $capacity';
  }

  @override
  String combatHit(int millilitres) {
    return 'Trafienie — $millilitres ml';
  }

  @override
  String get combatMiss => 'Pudło.';

  @override
  String get combatStillHunted => 'Wciąż Cię szukają.';

  @override
  String get combatDown => 'Padł.';

  @override
  String combatHeard(int metres) {
    return 'Słychać na $metres m.';
  }

  @override
  String get errorWeapon => 'BROŃ';

  @override
  String get errorSkill => 'WPRAWA';

  @override
  String get errorHeart => 'TĘTNO';

  @override
  String get errorMovement => 'RUCH';

  @override
  String get errorTarget => 'CEL';

  @override
  String get errorCondition => 'STAN';

  @override
  String get barrierDoor => 'Zamknięte drzwi';

  @override
  String get barrierPadlock => 'Kłódka';

  @override
  String get barrierWindow => 'Zabita szyba';

  @override
  String get breachForce => 'Wyważ';

  @override
  String get breachPry => 'Podważ';

  @override
  String get breachPick => 'Otwórz wytrychem';

  @override
  String get breachNoTool =>
      'Brak narzędzia — kłódki nie otworzysz gołymi rękami.';

  @override
  String get breachDone => 'Jesteś w środku.';

  @override
  String breachNoise(int metres) {
    return 'hałas $metres m';
  }

  @override
  String get fieldRestingHrKnown => 'Znam swoje tętno spoczynkowe';

  @override
  String get fieldRestingHr => 'Tętno spoczynkowe';

  @override
  String get fieldRestingHrHint =>
      'Zmierzone w spoczynku, na siedząco. Bez tego gra oszacuje je z wieku i budowy — i pomyli się u każdego, czyje serce bije wolniej lub szybciej niż przeciętnie. Zostaje na tym urządzeniu.';

  @override
  String get errRestingHrRange => 'Od 35 do 110 uderzeń na minutę';

  @override
  String get droppedHere => 'Na ziemi';

  @override
  String get droppedTake => 'Podnieś';

  @override
  String get droppedTooFar => 'Za daleko, żeby po to sięgnąć.';

  @override
  String droppedExpires(int hours) {
    return 'zostało $hours h';
  }

  @override
  String get droppedNoRoom => 'Nie mieści się w plecaku.';

  @override
  String get groundEmpty => 'Już nic tu nie ma.';

  @override
  String get noteRead => 'Przeczytaj';

  @override
  String get noteClose => 'Odłóż';

  @override
  String get inventoryTakeOff => 'Zdejmij';

  @override
  String get inventoryDropAll => 'Wszystko';

  @override
  String get inventoryUse => 'Użyj';

  @override
  String inventoryPortion(int percent) {
    return 'zostało $percent%';
  }

  @override
  String get inventoryWear => 'Załóż';

  @override
  String get inventoryEmptySlot => 'puste';

  @override
  String inventoryUsing(String action) {
    return '$action…';
  }

  @override
  String inventoryUsed(String item) {
    return '$item — zużyte';
  }

  @override
  String get inventoryNoWound => 'Nie ma czego opatrywać.';

  @override
  String get inventoryWrongDressing =>
      'Ten opatrunek nie wystarczy na tę ranę.';

  @override
  String get slotHead => 'Głowa';

  @override
  String get slotTorsoBase => 'Bielizna';

  @override
  String get slotTorsoMid => 'Warstwa środkowa';

  @override
  String get slotTorsoOuter => 'Warstwa wierzchnia';

  @override
  String get slotTorsoArmor => 'Pancerz';

  @override
  String get slotArms => 'Ramiona';

  @override
  String get slotHands => 'Dłonie';

  @override
  String get slotLegs => 'Nogi';

  @override
  String get slotFeet => 'Stopy';

  @override
  String get slotBack => 'Plecy';

  @override
  String get slotHand => 'W ręku';

  @override
  String get statEnergy => 'Energia wylotowa';

  @override
  String get statMoa => 'Rozrzut';

  @override
  String get statMagazine => 'szt.';

  @override
  String get statReload => 'Przeładowanie';

  @override
  String get statRange => 'Zasięg skuteczny';

  @override
  String get statNoise => 'Słychać z';

  @override
  String get statBleed => 'Utrata krwi na cios';

  @override
  String get statSwing => 'Zamach';

  @override
  String get statReach => 'Zasięg';

  @override
  String get statStrength => 'Wymagana siła';

  @override
  String get statInsulation => 'Izolacja';

  @override
  String get statProtection => 'Ochrona';

  @override
  String get statCoverage => 'Pokrycie';

  @override
  String get statCapacity => 'Pojemność';

  @override
  String get statCarry => 'Dodatkowy udźwig';

  @override
  String get statKcal => 'Kalorie';

  @override
  String get statWater => 'Woda';

  @override
  String get statEatTime => 'Czas jedzenia';

  @override
  String get statUseTime => 'Czas użycia';

  @override
  String get statUses => 'Użycia';

  @override
  String get statBlood => 'Przywraca krwi';

  @override
  String get statPagesMin => 'Stron, najmniej';

  @override
  String get statPagesMax => 'Stron, najwięcej';

  @override
  String get statXpPerPage => 'XP za stronę';

  @override
  String get statLight => 'światła';

  @override
  String get statBattery => 'Bateria';

  @override
  String get statCraftTime => 'Czas wytwarzania';

  @override
  String get statSearchBonus => 'Promień przeszukania';

  @override
  String get statMass => 'Masa';

  @override
  String get statBulk => 'Objętość';

  @override
  String get statSettle => 'Stabilizacja';

  @override
  String get statCraftSkill => 'Wymagana wprawa';

  @override
  String get statCondition => 'Stan';

  @override
  String get attachmentsFitted => 'Zamontowane';

  @override
  String attachmentsFree(int count) {
    return 'wolne sloty: $count';
  }

  @override
  String get attachmentsNone => 'Nic nie zamontowano';

  @override
  String get attachmentFit => 'Zamontuj';

  @override
  String get attachmentRefused => 'Nie da się tego zamontować.';

  @override
  String get attachmentWrongWeapon => 'Nie pasuje do tej broni.';

  @override
  String get attachmentAlreadyOn => 'Taki już tam jest.';

  @override
  String get attachmentNoRail => 'Brak wolnego slotu w tej broni.';

  @override
  String get attachmentRemove => 'Zdejmij';

  @override
  String get itemDetails => 'Szczegóły';

  @override
  String get itemCompare => 'Porównanie z';

  @override
  String get itemCarried => 'w plecaku';

  @override
  String get itemWorn => 'na sobie';

  @override
  String get inventoryTitle => 'Ekwipunek';

  @override
  String get inventoryEmpty => 'Plecak jest pusty.';

  @override
  String get inventoryEmptyHint =>
      'Przeszukuj budynki i otwarte miejsca, żeby znaleźć coś wartego niesienia.';

  @override
  String get inventoryWorn => 'Na sobie';

  @override
  String get inventoryPack => 'W plecaku';

  @override
  String get packOrderKind => 'wg rodzaju';

  @override
  String get packOrderName => 'wg nazwy';

  @override
  String get packOrderMass => 'wg wagi';

  @override
  String get packOrderWhat => 'Kolejność';

  @override
  String get inventoryBackpack => 'Plecak';

  @override
  String get inventoryNoBackpack => 'Tylko kieszenie';

  @override
  String get inventoryDrop => 'Wyrzuć';

  @override
  String get inventoryOverComfort =>
      'Powyżej komfortowego obciążenia — każdy krok kosztuje więcej.';

  @override
  String inventoryLost(int count) {
    return 'Przedmioty utracone wraz z usuniętą paczką treści: $count.';
  }

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsMaps => 'Mapy offline';

  @override
  String get settingsSimulator => 'Symulator GPS';

  @override
  String get settingsSimulatorBody =>
      'Gra używa wtedy nagranej trasy zamiast prawdziwej pozycji. Tylko do testów.';

  @override
  String get settingsRestartNeeded =>
      'Zmiana zadziała po ponownym uruchomieniu gry.';

  @override
  String get relocationTitle => 'Znowu urwał mi się film';

  @override
  String relocationBody(int km) {
    return 'Nie mam pojęcia, jak się tu znalazłem. Ostatnie, co pamiętam, było jakieś $km km stąd.';
  }

  @override
  String relocationNoMapBody(int km) {
    return 'Nie mam pojęcia, jak się tu znalazłem. Ostatnie, co pamiętam, było jakieś $km km stąd — i nie mam mapy tej okolicy.';
  }

  @override
  String get relocationDismiss => 'Trudno';

  @override
  String get permTitle => 'Uprawnienia';

  @override
  String get permLocation => 'Lokalizacja';

  @override
  String get permLocationGranted =>
      'Pełna — gra liczy też przy wygaszonym ekranie';

  @override
  String get permLocationForeground => 'Tylko gdy gra jest na wierzchu';

  @override
  String get permLocationDenied => 'Brak — bez tego nie ma gry';

  @override
  String get permLocationOff => 'Lokalizacja wyłączona w telefonie';

  @override
  String get permBattery => 'Optymalizacja baterii';

  @override
  String get permBatteryOn =>
      'Włączona — Android może wstrzymać liczenie w tle';

  @override
  String get permBatteryOff => 'Wyłączona dla tej gry — tak ma być';

  @override
  String get permBatteryUnknown => 'Nieznana';

  @override
  String get permFix => 'Popraw';

  @override
  String get permStartupTitle => 'Zanim wyjdziesz na spacer';

  @override
  String get permStartupBody =>
      'Żeby gra liczyła marsz z telefonem w kieszeni, potrzebuje zgody na lokalizację w tle i wyłączonej optymalizacji baterii. Bez nich działa tylko z aplikacją na wierzchu.';

  @override
  String get permStartupLater => 'Później';

  @override
  String get permStartupFix => 'Ustaw teraz';

  @override
  String get mapWaitingTitle => 'Szukam pozycji';

  @override
  String get mapWaitingBody =>
      'Gra czeka na sygnał, zanim pokaże mapę — inaczej pokazałaby okolicę, w której cię nie ma.';

  @override
  String get salvageTitle => 'Rozbiórka';

  @override
  String get salvagePick =>
      'Zaznacz, co ma pójść na części. Idą po kolei — jedno po drugim.';

  @override
  String get salvageNothingWorth =>
      'Nie ma tu nic, z czego cokolwiek zostanie.';

  @override
  String salvageChosen(int count) {
    return 'Wybrane: $count';
  }

  @override
  String get salvageSummaryTitle => 'Zanim zaczniesz';

  @override
  String get salvageGone => 'To nie wróci. Zostaną z tego materiały.';

  @override
  String get salvageYouGet => 'Dostaniesz';

  @override
  String salvageTakes(String time) {
    return 'Razem $time';
  }

  @override
  String get salvageInOrder =>
      'Po kolei. Przerwane w połowie — to, co zrobione, zostaje; reszta leży nietknięta.';

  @override
  String get salvageWaiting => 'Czeka na swoją kolej';

  @override
  String salvageBatchRunning(String item, int rest) {
    return 'Rozbiórka: $item (+$rest)';
  }

  @override
  String get crashOne => 'Coś się wysypało';

  @override
  String crashMany(int count) {
    return 'Wysypało się $count razy';
  }

  @override
  String get crashCopy => 'Kopiuj ślad';

  @override
  String get crashClear => 'Wyczyść';

  @override
  String get crashCopied => 'Skopiowane. Wklej mi to.';

  @override
  String get crashHung => 'Gra przestała odpowiadać';

  @override
  String get salvageWornFirst => 'Masz to na sobie — zdejmij najpierw.';

  @override
  String salvageWaitingUntil(String time) {
    return 'Czeka na swoją kolej — za $time';
  }
}
