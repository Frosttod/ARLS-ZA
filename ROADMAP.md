# ARLS-ZA — roadmap wdrożenia

Dokument wykonawczy do [ARLS-ZA_design_doc_v2.md](ARLS-ZA_design_doc_v2.md). Design doc mówi **co** i **dlaczego**; ten plik mówi **w jakiej kolejności**, **kiedy etap jest skończony** i **co ustaliliśmy przy klawiaturze**. Co gra **faktycznie robi**, z liczbami — [MECHANICS.md](MECHANICS.md).

Każdy zamknięty etap dostaje sekcję **Dziennik wykonania** z decyzjami podjętymi w trakcie, niespodziankami i punktem wejścia dla następnej sesji. Jeśli nie ma czego tam wpisać, etap prawdopodobnie nie został naprawdę skończony.

## Status

| Etap | Zakres | Status | Zamknięty | Commit |
| :---- | :---- | :---- | :---- | :---- |
| 0 | Fundament: trwałość zapisu, zegar, konfiguracja buildu | ✅ zamknięty | 2026-08-10 | `ad55d40` |
| 1 | Tryb deweloperski i symulator GPS | ✅ zamknięty | 2026-08-10 | `df54653` |
| 2 | Postać i fizjologia | ✅ zamknięty | 2026-08-11 | `f2b1056`, `5555db2`, `2b0a37e`, `d869661` |
| 3 | Mapa, GPS, bezpieczeństwo gracza | 🟡 13/13 zadań, po kilku spacerach | — | `f035626` … `43510ef` (15 commitów) |
| 4 | Przedmioty, loot, przeszukanie | 🟡 11/11 zadań, po testach w terenie | — | `2b1cb31` … `6033aff` |
| 5 | Walka, przeciwnicy, hałas | 🟡 14/14 zadań, po testach w terenie | — | … `6033aff` |
| 6 | Strefy Rozkładu z pełnym cyklem | 🟡 13/13 zadań, po testach w terenie | — | `24ef01b`, schemat v36 |
| 7 | Audio pozycyjne i haptyka | ⬜ | — | — |
| 8 | Schron, obóz, pętla dobowa | 🟡 9/9 zadań, po długiej passie w terenie | — | schemat v38 |
| 9 | Onboarding i zgodność | 🟡 9/11 zadań, reszta to formularze i materiały do sklepu | — | — |
| — | Profil i statystyki postaci (§13.1) | ✅ poza etapami | 2026-08-18 | `8937688` |
| — | Oprawa: krój pisma, odświeżanie, mapa Voyager, płynność 30 fps | ✅ scalone do `main` | 2026-08-20 | `d0d0e51` … `89bce39` |
| — | Półki w schronie, pamięć przeszukanych miejsc, zasięgi per miejsce | ✅ poza etapami | 2026-08-20 | schemat v20 |
| — | Broń: magazynki, gniazda dodatków, ładowanie po naboju | ✅ poza etapami | 2026-08-20 | schemat v21 |
| — | Warsztat: magazyn + wytwarzanie w jednym, rozbiórka wsadowa z kolejką | ✅ poza etapami | 2026-08-22 | schemat v26 |
| — | Migracja `main.dart`: sześć kontrolerów, granica awarii, zapadka rozmiaru | ✅ fazy 0–6 | 2026-08-22 | 7088 → 6638 linii |
| — | **Fizjologia długoterminowa** (§2.3.1, §2.5.5) | ✅ poza etapami | 2026-08-23 | schemat v27–v29 |
| — | **Skradanka**: stożki 120°, słuch wg tempa, cicha eliminacja, pasma 175/150/100 m | ✅ poza etapami | 2026-08-28 | `ec0be3f` … `344a31f` |
| — | **Bariery**: zużycie narzędzia, przebalansowane czasy, panel nazywa narzędzie | ✅ poza etapami | 2026-08-30 | `fdefddb` … `a64a9a5` |
| — | **Zestaw startowy** jako drugi etap tworzenia postaci (§4, §12) | ✅ poza etapami | 2026-08-29 | `5c3e85b`, `b96b927` |
| — | **Reguła obecności przy warsztacie** (§2.1a.3) | ✅ poza etapami | 2026-08-30 | `c6768b3`, schemat v37 |
| — | **Widżet 4×1 na ekran główny** (§13.1): woda, kalorie, sen, tętno, co dolega | ✅ poza etapami | 2026-09-05 | — |

**Metryki:** 2786 testów · `flutter analyze` czysty · schemat bazy **v38** · `main.dart` 6406 linii

✅ **`main` jest wypchnięty na `origin/main`.** Wcześniej cała gra istniała na jednym dysku i było to największe ryzyko projektu — jedyne, którego nie dawało się naprawić kodem.

⚠️ Repozytorium `Frosttod/ARLS-ZA` jest **publiczne**. `android/key.properties` jest w `.gitignore` i nie wolno go tam wpuścić.

### Co zamyka etapy 3–6 i 8

Wszystkie pięć ma komplet zadań i przeszło testy w terenie. Blokada, którą był brak ognisk, **zniknęła**: Strefy Rozkładu stoją z pełnym cyklem — bariera, wysyp, skrytka, odpoczynek slotu — więc walka, loot i schron mają wreszcie presję, dla której powstały.

Do formalnego zamknięcia brakuje **jednej długiej passy w terenie**: trzydziestu dni z rzędu, ze zbiciem strefy z poziomu wyższego niż pierwszy, bez utraty zapisu. To jest test, którego nie da się przyspieszyć symulatorem — wzrost strefy liczy się teraz w dobach realnego czasu (§11.5 w MECHANICS).

⚠️ **Ten akapit mówił, że promień spawnu lootu stoi na 1200 m. Stoi na 2000 od
czasu, gdy ogniska dały dalekim punktom powód istnienia** — wpis został po
zmianie, którą sam zapowiadał. Sprawdzone i potwierdzone 5 września 2026:
zostaje 2000 m, a bliski pierścień (§10.1) gwarantuje pięć miejsc w sześciuset
metrach, żeby szersze koło nie zrobiło z okolicy pustyni.

### Zablokowane na użytkowniku

Rzeczy, których nie da się zrobić z poziomu repozytorium.

| Co | Dlaczego blokuje | Od etapu |
| :---- | :---- | :---- |
| Keystore i `android/key.properties` | bez tego `flutter build --release` używa kluczy debug, a takiego artefaktu nie da się opublikować. Instrukcja na górze [PROCEDURA_RELEASE.md](PROCEDURA_RELEASE.md) | 0 |
| GitHub Pages dla `ARLS-ZA-Game` | strona projektu nie jest publicznie widoczna. Settings → Pages → branch `main`, folder `/ (root)` | — |
| Hosting pakietów, który obsługuje zakresy bajtów **bez przekierowania** | Zmierzone: żądanie zakresu do release'u GitHuba bez podążania za przekierowaniem zwraca `302` i **zero bajtów**; z podążaniem `206` i dane. MapLibre nie goni tego przy każdym kafelku — dwa uruchomienia na telefonie dały pustą mapę. Dlatego `streamable: false` i przycisk „Graj teraz" nie istnieje. Pobieranie na dysk działa bez zmian, bo klient Darta podąża za przekierowaniem.<br><br>**Najtańsze wyjście: GitHub Pages** — serwuje pliki wprost, obsługuje zakresy, zero kosztów. Limit 100 MB na plik, więc województwo się nie zmieści, ale wycinek miasta tak: `planetiler --osm-path=… --output=poznan.pmtiles --bounds=16.73,52.29,17.16,52.51`. Taki pakiet dopisuje się do katalogu z `"streamable": true` przy samym regionie. Alternatywy bez limitu: Cloudflare R2, S3 | 3 |
| Zbudowanie pozostałych pakietów PMTiles | ✅ Wielkopolskie zbudowane Planetilerem i wystawione jako `maps-v1` (235 MB, suma kontrolna w katalogu, pobieranie działa na telefonie). Pozostałe 15 województw ma puste sumy i jest **celowo odrzucanych** — mapa, której nikt nie zweryfikuje, to mapa, z którą nikt nie powinien wchodzić do miasta | 3 |
| Pakiet miejski Poznania na GitHub Pages | wpis `poznan` czeka w katalogu z pustą sumą. Zbudować `--bounds=16.73,52.29,17.16,52.51 --maxzoom=16`, wrzucić do `ARLS-ZA-Game/maps/`, włączyć Pages. Odblokowuje mapę bez pobierania | 3 |

---

Lista kontrolna systemów — co udowadnia maszyna, a co wyłącznie spacer —
mieszka w [CHECKLIST.md](CHECKLIST.md).

## Zasady prowadzenia prac

1. **Etap kończy się kryterium wyjścia, nie poczuciem gotowości.** Kryterium jest sprawdzalne — testem, pomiarem albo demonstracją na urządzeniu.
2. **Schemat bazy jest addytywny od pierwszego dnia** (§11.1.4). Kolumny się dodaje, nigdy nie usuwa i nie zmienia nazw. Test migracji jest tak samo obowiązkowy jak test logiki.
3. **Symulator GPS wstrzykuje dane tą samą warstwą co prawdziwy GPS** (§11.2), łącznie z błędem pozycji i utratą sygnału. Testowanie na idealnych danych zamaskuje wszystko, co wystąpi w terenie.
4. **Struktury danych przewidują funkcje spoza MVP** — `season_modifiers` (§17), flaga `procedural` w punktach lootu (§10.1), `condition` i `volume_l` w przedmiotach (§4.1). Dodanie ich później to migracja schematu, nie nowa funkcja.
5. **Higiena licencyjna audio od pierwszego pliku** (§14.5): `assets/audio/prototype/` nigdy nie trafia do release'u, każdy plik w `shipped/` ma wpis w `CREDITS.md`, CI to sprawdza.
6. **Etapy 0–1 nie wymagają wychodzenia z domu.** Praca w terenie zaczyna się dopiero na etapie 3.

---

## Etap 0 — Fundament projektu ✅ ZAMKNIĘTY

**Cel:** repozytorium, z którego da się zbudować podpisany release, i baza, która przeżyje aktualizację aplikacji.

| # | Zadanie | Odniesienie | Gdzie |
| :---- | :---- | :---- | :---- |
| 0.1 | Rebranding: `applicationId` i `namespace` → `com.raidodevelopment.arlsza`, `android:label` → `ARLS-ZA Game`, ścieżka `MainActivity.kt`, `name` w `pubspec.yaml` | — | `android/app/build.gradle.kts` |
| 0.2 | Release signing config (keystore poza repozytorium, `key.properties` w `.gitignore`) | — | `android/app/build.gradle.kts` |
| 0.3 | `git init`, konwencja commitów, CI: `flutter analyze` + `flutter test` | — | `.github/workflows/ci.yml` |
| 0.4 | Drift/SQLite: schemat v1, tryb WAL, transakcje, wersja schematu w bazie | §11.1.1–11.1.2 | `lib/data/db/` |
| 0.5 | Podział stanu na warstwy: gorąca (60 s), ciepła (przy zmianie), zimna (przy zdarzeniu) | §11.1.1 | `lib/data/persistence/save_writer.dart` |
| 0.6 | Migawki rotacyjne: 3 sztuki, sumy kontrolne, weryfikacja bazy przy starcie, odtwarzanie z komunikatem | §11.1.3 | `lib/data/db/snapshot_store.dart` |
| 0.7 | Test migracji w CI: ścieżka v1→v2→v3 na wygenerowanych danych | §11.1.4 | `test/db/schema_test.dart`, `drift_schemas/` |
| 0.8 | Eksport/import profilu do JSON | §11.3 | `lib/data/persistence/profile_transfer.dart` |
| 0.9 | Deterministyczny RNG z seedem zapisanym w profilu | §11 | `lib/core/deterministic_rng.dart` |
| 0.10 | Silnik tickowy 1 Hz w izolacie, ticki idempotentne od `last_update`, catch-up po wznowieniu | §11, §2.1.1 | `lib/sim/` |
| 0.11 | Anti-cheat zegara: `last_update` jako licznik monotoniczny, cofnięcie czasu = tick 0 s | §2.1.1 | `lib/core/game_clock.dart` |
| 0.12 | Lokalizacja: `flutter_localizations` + ARB, PL i EN, klucze zamiast tekstów w plikach danych | §1.1 | `lib/l10n/` |

**Kryterium wyjścia:** aplikacja z podpisanym buildem release, pusty tick 1 Hz działa w izolacie, przeżywa kill procesu i wraca z catch-upem bez dziury w symulacji, test migracji przechodzi w CI.

**Stan:** spełnione. Kryterium zapisane wykonywalnie w `test/db/save_bootstrap_test.dart` — sesja gubi niezapisane sekundy warstwy gorącej, wraca z catch-upem bez dziury, a powtórzenie tego samego catch-upu daje ten sam stan.

### Dziennik wykonania — etap 0

#### Decyzje podjęte w trakcie

Rozstrzygnięcia, których nie było w dokumencie projektowym, a bez których nie dało się napisać kodu.

- ⚠️ **`DateTime` zapisywany jako tekst ISO-8601 UTC**, nie jako sekundy uniksowe (`build.yaml`, `store_date_time_values_as_text`). Wiążące na całe życie schematu — zmiana po wydaniu to migracja danych, nie przełącznik. Powód niżej, w niespodziankach.
- **Warstwa bazy jest wolna od Fluttera.** `path_provider` wciągał `dart:ui` do `database.dart`, przez co testy nie ładowały się pod `dart test`, a izolat silnika tickowego miałby ten sam problem. Rozwiązywanie katalogu zapisu stoi osobno w `lib/data/db/save_location.dart`.
- **Klucze obce przez `customConstraints`, nie przez `.references()`.** Drift w tej wersji cicho gubi `.references(Profiles, #id)` — wypisuje ostrzeżenie i generuje kolumnę bez ograniczenia. Test czyta `sqlite_master` i sprawdza, że `FOREIGN KEY` naprawdę jest w `CREATE TABLE`; sama deklaracja niczego nie gwarantuje.
- **`schemaVersion` musi być literałem**, nie odwołaniem do stałej — `drift_dev schema dump` czyta go statycznie i nie pójdzie za referencją. Spójności z `kSchemaVersion` pilnuje test.
- ⚠️ **Build release bez keystore kończy się kluczami debug i ostrzeżeniem, nie błędem.** Twardy błąd włącza `-Prequire-signing=true`, którego używa potok wydawniczy. Wariant „zawsze twardy błąd" psułby `flutter build --release` każdemu, kto sklonuje repozytorium.
- **Import profilu zawsze wstawia nową postać**, nigdy nie nadpisuje istniejącej. Pomyłkowe przywrócenie kopii nie może skasować żywej passy.
- **Migracja odpala się dopiero po migawce przedmigracyjnej**, która nie podlega rotacji okresowej. To jedyna rzecz stojąca między złą migracją a zapisami wszystkich graczy.

#### Niespodzianki

- **Drift oddaje `DateTime` w czasie lokalnym.** Znacznik zapisany jako `12:00 UTC` wracał z bazy jako `14:00` bez flagi UTC. Trafiłoby to prosto w porównanie w anti-cheacie zegara z §2.1.1 — dwie godziny darmowego czasu przy każdym odczycie na CEST. Złapał to test bootstrapu, nie przegląd kodu. **Wniosek na przyszłość: każdy typ przechodzący przez granicę bazy wymaga testu round-tripu**, nawet jeśli wygląda na trywialny.
- **`flutter test` i `dart test` to różne środowiska.** Testy czystej logiki pod `dart test` są znacznie szybsze, ale wywalają się na każdym imporcie ciągnącym Flutter. To wymusiło rozdzielenie warstw — z korzyścią dla architektury.
- Gradle wsypywał `android/build/reports/` do commita; `.gitignore` template'u pokrywał tylko `/build` w katalogu głównym.

#### Punkt wejścia dla następnej sesji

Fundament jest gotowy, ale **nie jest jeszcze przez nic używany**. `main.dart` woła `SaveBootstrap.boot()` i pokazuje wynik odzyskiwania — na tym koniec. Brakuje spięcia:

- pętli, która pobiera stan z `TickEngine` i podaje go do `SaveWriter.stageHot()`
- reakcji na cykl życia aplikacji: `AppLifecycleState.paused` → `writer.quiesce()` plus `persistClockMark()`
- wywołań `SnapshotStore.isDue()` w rytmie gry

To jest zamierzone — bez postaci nie ma czego tickować. Spięcie należy do etapu 2, kiedy pojawi się prawdziwy stan do zapisania.

✅ CI przeszło na Ubuntu za pierwszym razem (`ad55d40`). Weryfikacja etapu 0 szła lokalnie na Windowsie, więc było to pytanie otwarte — jest zamknięte.

---

## Etap 1 — Tryb deweloperski ✅ ZAMKNIĘTY

**Cel:** możliwość iterowania nad balansem bez wychodzenia z domu. Bez tego etapu każda kolejna zmiana wymaga kilometrów spaceru.

| # | Zadanie | Odniesienie | Gdzie |
| :---- | :---- | :---- | :---- |
| 1.1 | Warstwa abstrakcji pozycji — jedno wejście dla prawdziwego GPS i symulatora | §11.2 | `lib/location/` |
| 1.2 | Symulator GPS: odtwarzanie tras GPX z regulowaną prędkością, sterowanie strzałkami, skok do współrzędnych | §11.2 | `lib/devtools/simulated_position_source.dart`, `gpx.dart` |
| 1.3 | Symulacja błędu pozycji i utraty sygnału w symulatorze | §11.2, §3.2 | `SimSignalQuality` |
| 1.4 | Przyspieszenie czasu ×1 / ×60 / ×3600 | §11.2 | `lib/core/scaled_wall_clock.dart` |
| 1.5 | Panel fizjologii: wymuszanie tętna, krwi, wody, kalorii, długu snu | §11.2 | `lib/devtools/dev_console.dart` |
| 1.6 | Nakładka diagnostyczna: `MOA_total` z rozbiciem, szansa trafienia, promień hałasu, stany przeciwników | §11.2 | `lib/devtools/dev_overlay.dart` — **częściowo, patrz niżej** |
| 1.7 | Powtórki: zapis sesji (seed + strumień zdarzeń) i deterministyczne odtworzenie | §11.2 | `lib/devtools/session_recorder.dart` |
| 1.8 | Wycięcie całości z release'u flagą kompilacji | §11.2 | `lib/devtools/dev_mode.dart`, `tool/check_release_strip.dart` |

**Kryterium wyjścia:** doba gry przechodzi w 24 sekundy na trasie GPX, a build release nie zawiera ani jednej linii kodu deweloperskiego (zweryfikowane rozmiarem i analizą artefaktu).

**Stan:** spełnione, zweryfikowane pomiarem.

| Sprawdzenie | Wynik |
| :---- | :---- |
| Doba gry przy ×3600 | 24 s, test w `scaled_wall_clock_test.dart` |
| Release APK | **55,1 MB**, marker nieobecny, `check_release_strip.dart` przechodzi |
| Release z `--dart-define=arls.devtools=true` | **57,4 MB**, marker obecny, check zawodzi |
| Różnica | **2,3 MB** wyciętego kodu |

⚠️ **Zadanie 1.6 jest domknięte tylko częściowo, świadomie.** Nakładka pokazuje zegar, warstwę pozycji i fizjologię. Rozbicie `MOA_total`, szansa trafienia, promień hałasu i stany maszyny przeciwników **nie istnieją jeszcze jako systemy** — powstają na etapie 5. Brak jest wypisany wprost w panelu (sekcja „Brakuje — etap 5"), żeby nie zniknął z pola widzenia.

### Dziennik wykonania — etap 1

#### Decyzje podjęte w trakcie

- **Bramka to `const bool`, nie flaga runtime'owa.** `const bool kDevTools` pozwala kompilatorowi AOT uznać `if (kDevTools) { ... }` za martwy kod i usunąć gałąź razem ze wszystkim, do czego tylko ona sięga. Zwykły `bool` zostawiłby cały drzewiec devtools w binarce.
- **Domyślnie włączone poza release, przełączalne w obie strony** przez `--dart-define=arls.devtools=true|false`. Wymuszenie w release potrzebne do testu, że sam test nie jest pusty.
- **Przyspieszenie czasu siedzi w zegarze, nie w silniku tickowym.** `ScaledWallClock` mnoży upływ czasu pod `GameClock`, więc `advance()` dostaje zwykły `Duration` i nigdy nie dowiaduje się o mnożniku. Dzięki temu przebieg przyspieszony jest porównywalny ze zwykłym, a funkcja pozostaje czysta.
- **Zmiana skali re-kotwiczy zamiast przeliczać historię.** Przełączenie ×1 → ×3600 → ×1 nigdy nie cofa czasu wirtualnego, co inaczej wywołałoby fałszywy alarm anti-cheatu z §2.1.1. Osobny test tego pilnuje.
- **`skipForward` działa wyłącznie do przodu.** Skok wstecz byłby najprostszym sposobem obejścia zabezpieczenia, które reszta kodu traktuje jako pewnik.
- **Symulator rozprasza pozycję wewnątrz okręgu dokładności**, z `sqrt` na promieniu, żeby rozkład był równomierny po powierzchni. Bez tego dryf kupiłby się wokół prawdziwej pozycji, a filtr martwej strefy z §3.2 nie miałby czego filtrować.
- **Prawdziwa pozycja nie jest nigdzie eksponowana poza panelem.** Gra widzi wyłącznie zaszumiony odczyt — dokładnie jak w terenie.
- **Parser GPX napisany ręcznie**, bez pakietu XML. Zależność używana tylko przez devtools i tak siedziałaby w `pubspec.yaml` release'u.
- **Powtórki w formacie JSON Lines**, dopisywanym liniami. Nagranie przeżywa crash, który miało zarejestrować: urwana ostatnia linia kosztuje jedno zdarzenie, nie plik.
- **Zdarzenia niosą czas symulacji, nie zegarowy.** Dlatego zmiana skali czasu w trakcie nagrania nie wpływa na odtworzenie — mnożnik jest już wpieczony w znaczniki.

#### Niespodzianki

- 🔴 **Test wycinania był pusty i przechodził z błędnego powodu.** Marker był w stałej, do której nie sięgało żadne żywe wywołanie, więc kompilator wyrzucał go **także z buildu z włączonymi devtools** — check pokazywał „czysto" niezależnie od stanu bramki. Wykryte dopiero przez zbudowanie release'u z `--dart-define=arls.devtools=true` i sprawdzenie, czy check **zawodzi**. Naprawione przez wstawienie markera w faktycznie renderowany widget. **Wniosek: każdy test negatywny wymaga dowodu, że potrafi zawieść.** CI ma teraz osobny krok, który to sprawdza.
- **`kReleaseMode` z `package:flutter/foundation.dart` wciągał `dart:ui`** do symulatora pozycji i nagrywarki, przez co nie ładowały się pod `dart test`. To ta sama pułapka co `path_provider` w etapie 0. Zastąpione bezpośrednim `bool.fromEnvironment('dart.vm.product')` — tym samym define, z którego korzysta sam Flutter.
- **`cancel-in-progress: true` anulowało weryfikację commita z kodem.** Dopchnięcie commita z dokumentacją zaraz po `df54653` ubiło jego przebieg CI — na `main` została zmiana, której nikt nie sprawdził. Poprawione: anulowanie działa teraz wyłącznie dla pull requestów, na `main` każdy commit dochodzi do końca.

#### Punkt wejścia dla następnej sesji

Symulator działa i emituje pozycje, ale **nic ich jeszcze nie konsumuje** — `TitleScreen` tylko je wyświetla w nakładce. Etap 2 musi spiąć trzy rzeczy, które teraz istnieją osobno:

- `SimulatedPositionSource` → prędkość → MET → `TickEngine`
- `TickEngine` → `SaveWriter.stageHot()` w rytmie 60 s
- `DevConsole.takePendingOverride()` → wstrzyknięcie wymuszonych wartości do stanu symulacji

⚠️ Filtry z §3.2 (Kalman, odrzucanie `accuracy > 25 m`, martwa strefa 8 m/10 s) **celowo nie powstały** — należą do etapu 3. Symulator już potrafi produkować dane, które ich wymagają: preset „wąwóz miejski" przebija próg 25 m, a dryf na postoju daje fałszywy ruch. To materiał testowy czekający na filtr.

---

## Etap 2 — Postać i fizjologia

**Cel:** działający model ciała — pierwszy system, który da się zbalansować.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 2.1 | Kreator postaci: nazwa, płeć, wiek, wzrost, waga, walidacja zakresów i BMI 12–60 | §1.2 |
| 2.2 | Parametry wyliczane: Nadler, Mifflin–St Jeor, Tanaka, woda 35 ml/kg, HR spoczynkowe, udźwig 0,30/0,45 | §1.3 |
| 2.3 | Wybór trybu Hardcore/Softcore, nieodwracalny, z osobnym potwierdzeniem | §9, §15.4 |
| 2.4 | MET z prędkości, `MET_efektywne` z obciążeniem, kcal/min | §2.2 |
| 2.5 | Strefy metaboliczne: teren 100% / obóz 50% / schron 35% / sen 20% | §2.1 |
| 2.6 | Głód, pragnienie, straty z potem, progi kar | §2.3 |
| 2.7 | Tętno: model, powrót wykładniczy τ ≈ 90 s, tabela kar | §2.4 |
| 2.8 | Sen automatyczny z pory doby i strefy, dług senny, efekty deprywacji | §2.5 |
| 2.9 | Długość dnia liczona offline (deklinacja słoneczna) — warunek działania snu | §17.2 |
| 2.10 | Model obrażeń i krwawienia: klasy ATLS, tiery krwawienia, modyfikator wysiłku | §2.6 |
| 2.11 | Reguła zajęć: jedno naraz, kategorie ZAJĘCIE / CZYNNOŚĆ / PROCES TŁOWY | §2.1a |
| 2.12 | Zawór offline: żaden zasób nie spada poniżej 10%, brak śmierci w stanie uśpionym | §2.1.1, §9.1 |
| 2.13 | HUD: krew, statusy, woda, kalorie, udźwig (masa i objętość) | §3.6, §18.1a |
| 2.14 | ✅ **Kary za stan docierają do zegarów i do strzału** — `conditionMoa`, `workRate`, masa ciała w progach odwodnienia | §2.3, §2.5.4, §5.1.1 |
| 2.15 | ✅ **Zgon z głodu i pragnienia jest osiągalny** — `dryStreakSeconds`, `starvedStreakSeconds` (schemat v27) | §2.3, §9 |
| 2.16 | ✅ **Masa ciała jako stan**, wychudzenie, nadwyżka odkładana (schemat v28) | §2.3.1 |
| 2.17 | ✅ **Drugi zegar snu** — obciążenie przewlekłe (schemat v29) | §2.5.5 |

**Kryterium wyjścia:** przy ×3600 doba symulacji daje liczby zgodne z tabelami §2 w granicach błędu zaokrągleń; postać z zamkniętą aplikacją przez 14 dni budzi się osłabiona, ale żywa.

**Stan:** spełnione. Kryterium zapisane wykonywalnie w `test/sim/tick_physiology_test.dart`, `test/game/game_loop_test.dart` i `test/game/game_session_test.dart`.

### Dziennik wykonania — etap 2

#### Decyzje podjęte w trakcie

- **Zapas wody może zejść poniżej zera.** §2.3 miesza dwie skale: rezerwa to zapotrzebowanie **dobowe** (35 ml/kg), a progi ciężkości to ułamki **masy ciała** (2%, 5%, 10%). Dla 80 kg rezerwa ma 2800 ml, a silne osłabienie wymaga 4000 ml deficytu — przy obcięciu na zerze dwa z trzech progów byłyby nieosiągalne. Deficyt musi więc narastać ponad dobę; dolna granica to próg krytyczny z §2.3.
- **Pot rozdzielony na środowiskowy i wysiłkowy.** Upał i odzież kosztują wodę przy każdej aktywności, ale stała 400 ml/h ze wzoru to tempo *pracującego* ciała. Dodanie pełnego wzoru dawałoby 12 l na dobę komuś śpiącemu w schronie.
- **Podstawa energetyczna z Mifflina, dopłata za ruch z MET.** To dwa różne źródła (2450 kcal/dobę wobec 2016 kcal/dobę z MET 1.0), więc ruch liczony jest jako nadwyżka ponad MET spoczynkowy, a nie jako pełny koszt.
- **Prędkość liczona z kolejnych odczytów, nie z pola dostarczanego przez GPS.** Symulator podaje `speedMps`, prawdziwy chip czasem nie — symulacja nie może zachowywać się inaczej zależnie od tego, który jest podłączony.

#### Domknięcie fizjologii, sierpień 2026 (zadania 2.14–2.17)

⚠️ **Trzy kary z §2 były wyliczane co tick i nie docierały do niczego.** Wszystkie miały ten sam kształt — liczbę bez konsumenta:

1. `conditionMoa` miał wartość domyślną zero i żadne wywołanie go nie wypełniało, więc +3 MOA za dobę bez snu i MOA za utratę krwi **nie zmieniały ani jednego strzału**.
2. `actionTimeMultiplier` czytał HUD i notatki stanu — i nic, co mierzy czas. „+20% do czasu wszystkich czynności" nie wydłużało niczego.
3. `toSimConstants()` pomijało masę ciała, a pole miało domyślne 80 kg, więc progi odwodnienia mierzyły każdą postać miarką osoby ważącej 80 kg.

⚠️ **Obie śmiertelne reguły §2.3 były nieosiągalne.** Funkcje przyjmowały liczniki czasu od kiedy powstały; `statusOf` nie podawał żadnego, `SimState` nie miał gdzie ich trzymać. Można było nie jeść i nie pić w nieskończoność.

**Główna zmiana projektowa:** masa ciała przestaje być stałą. §2.3 nie miało czym mierzyć głodu dłuższego niż doba — bo „0% przez > 24 h" to reguła o *dobowym zapasie*, nie o organizmie. Czytanie jej jako zgonu zabijało w 48 godzin, szybciej niż pragnienie, wbrew własnej instrukcji §2.3.

Szczegóły i liczby: [MECHANICS.md §3.4a](MECHANICS.md#34a-głód-długoterminowy--masa-ciała-231) i [§5.3](MECHANICS.md#53-obciążenie-przewlekłe--ostatni-miesiąc-255).
- **Utrata sygnału zeruje ruch, nie zamraża go.** Naliczanie ostatniej znanej prędkości przez czas bez sygnału obciążałoby gracza za dryf GPS (§3.2).
- **Tryb śmierci nie ma domyślnego zaznaczenia.** Wybór jest nieodwracalny (§9), a preselekcja to wybór dokonany za gracza.
- **Kompozycja gry wyjęta z widgetów do `GameSessionFactory`.** Zakładanie profilu, odczyt aktywnej postaci i start pętli to sekwencja, którą trzeba testować bez pompowania UI. `main.dart` zostaje listą ekranów.
- **Bez trybu deweloperskiego gra nie udaje, że ma pozycję.** `buildPositionSource` zwraca `null` w buildzie release — prawdziwe źródło GPS należy do etapu 3, a symulator przemycony do wydania byłby dokładnie tym, przed czym broni §11.2.
- **`BodySpec` dostał równość wartościową.** Karta postaci to wartość: te same cztery liczby to ta sama postać, niezależnie od tego, czy przyszły z kreatora, czy z wiersza odczytanego z dysku.
- **Zajęcie zapisywane jako JSON, nie jako kolumny.** Zajęcia będą zyskiwać pola wraz z systemami schronu z §8 i §18; każde z nich byłoby inaczej osobną migracją.
- **Statusy w HUD jako słowa, nie same ikony i kolory.** Ikona, której gracz jeszcze nie zna, jest ozdobą; §12 wymaga czytelności dla czytnika ekranu i przy daltonizmie.

#### Niespodzianki

- 🔴 **Dokument projektowy zawierał błąd arytmetyczny.** Objętość krwi dla 180 cm / 80 kg to **5319 ml**, nie 5290 — wzór Nadlera i dane wejściowe były poprawne, błędna była podana suma. Liczba zdążyła się rozejść na makietę §15.4, obie wersje strony projektu i wszystkie fikstury testowe. Poprawione wszędzie.
- 🔴 **Człon temperaturowy potu skracał się do zera.** Liczenie dopłaty jako „pot przy tym MET minus pot w spoczynku, ta sama temperatura" usuwa całą zależność od upału — letnie popołudnie kosztowało tyle samo wody co mroźne.
- 🔴 **Dwa progi odwodnienia były martwe.** Patrz decyzja o ujemnym zapasie wyżej. Test HUD to wychwycił, bo chip „ODWODNIENIE" nigdy się nie zapalał.
- **Podmiany tekstu w plikach po `dart format` cicho nie trafiają.** Dwa razy zmiana nie została zastosowana, bo formatowanie zmieniło wcięcia, a skrypt szukał dokładnego dopasowania. Wykryte dopiero przez test, który nadal zawodził po „naprawie".
- **Widgety poniżej 600 px nie istnieją w teście.** `ListView` buduje leniwie, a domyślna powierzchnia testowa ma 800×600 — połowa kreatora nie była w drzewie. Testy ustawiają wysoki ekran.

#### Punkt wejścia dla następnej sesji

Etap 2 jest domknięty: `TitleScreen` wykrywa brak aktywnej postaci, prowadzi do kreatora, zakłada profil przez `GameSessionFactory` i uruchamia `GameLoop` z HUD-em nad treścią, a `AppLifecycleState` woła `onPaused`/`onResumed` w dwóch momentach, w których proces najłatwiej zginie (§11.1.5).

Etap 3 zaczyna się od **prawdziwego źródła pozycji**: `PositionSource` na `geolocator`, wybierane w `buildPositionSource` obok symulatora. Cała reszta pętli już tego nie zauważy — to jedyny punkt styku (§11.2).

⚠️ **Nadmiarowy zapas wody nie jest jeszcze uzupełniany przez picie** — mechanika przedmiotów należy do etapu 4. Do tego czasu deficyt tylko rośnie.

⚠️ **W buildzie release nie ma jeszcze czym poruszyć postacią** — bez trybu deweloperskiego gra pokazuje kreator i ekran startowy, ale pętla nie rusza, bo nie ma źródła pozycji. Znika to razem z etapem 3.

---

## Etap 3 — Mapa i GPS

**Cel:** pierwszy raz gra działa w prawdziwym mieście.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 3.1 | ✅ MapLibre GL Native + PMTiles, pakiet kafelków na region | §3.1 |
| 3.2 | ✅ Ekran pierwszego uruchomienia: wybór regionu, obsługa braku miejsca, wyjazd poza pakiet | §16.6 |
| 3.3 | ✅ `geolocator` + foreground service z powiadomieniem trwałym | §3.3 |
| 3.4 | ✅ Filtr Kalmana, odrzucanie `accuracy > 25 m`, martwa strefa 8 m/10 s, pauza po 60 s utraty sygnału | §3.2 |
| 3.5 | ✅ Adaptacyjne próbkowanie 1 / 0,2 / 0,05 Hz, tryb oszczędny, ostrzeżenie przy <20% baterii | §3.3 |
| 3.6 | ✅ Tryb tylko-foreground jako pełnoprawny wariant gry przy odmowie zgody na lokalizację w tle | §16.1 |
| 3.7 | ✅ Anti-cheat: mock provider, >40 km/h przez >30 s → zawieszenie rozgrywki | §3.4 |
| 3.8 | ✅ Strefy wykluczone ze spawnu po tagach OSM (drogi, tory, wody, tereny prywatne, szpitale, szkoły, cmentarze, obiekty kultu, komisariaty, obiekty wojskowe) | §3.5 |
| 3.9 | ✅ Blokada walki przy >15 km/h | §3.5 |
| 3.10 | ✅ Widok mapy: gracz, stożek kierunku, znaczniki, dolne menu | §3.6 |
| 3.11 | ✅ Zapis pozycji do warstwy gorącej przy każdym `onPause`, checkpoint WAL | §11.1.2, §11.1.5 |
| 3.12 | ✅ Przeniesienie: wykrycie skoku pozycji między sesjami, komunikat fabularny, decyzja o pakiecie | §16.6, §19.1 |
| 3.13 | ✅ Marsz z wygaszonym ekranem naliczany (wariant A) | §3.3, §16.1 |

### Co pokazał pierwszy spacer

Trzy zgłoszenia z terenu, wszystkie z jedną klasą przyczyny: **traktowałem bramkę dokładności §3.2 jako odpowiedź na więcej pytań, niż ona odpowiada.**

| Objaw | Przyczyna | Poprawka |
| :---- | :---- | :---- |
| Bardzo długie łapanie pozycji po wznowieniu | zmiana kadencji **restartuje żądanie lokalizacji**, a świeże potrzebuje sekund na pierwszy fiks. Marsz–postój–marsz przełączał 0,2/0,05 Hz na każdym krawężniku | wolniejsza kadencja wstrzymana o minutę, **jednokierunkowo** — przyspieszanie natychmiast |
| „Inne aplikacje łapią od razu, nawet w mieszkaniu" | nic nie pokazywało ostatniej znanej pozycji, a **wszystkie fiksy sieciowe (30–60 m) były odrzucane** jako zbyt szerokie | ostatnia znana pozycja przy starcie (do 2 minut wstecz) + osobna pozycja „do narysowania", niezależna od bramki ruchu |
| „SŁABY SYGNAŁ" przez większość spaceru | ostrzeżenie po **jednym** szerokim fiksie, a pierwsze po zimnym starcie mają rutynowo 40–60 m | degradacja dopiero po 30 s bez dokładnego fiksu |

⚠️ **Wniosek do zapamiętania.** Bramka 25 m odpowiada wyłącznie na pytanie „czy to jest ruch". Nie odpowiada na „gdzie narysować gracza" ani na „czy powiedzieć mu o sygnale". Zlanie tych trzech pytań w jedno kosztowało spacer.

Symetryczne wstrzymanie kadencji było **gorsze niż jego brak** — pierwszy fiks sesji jest zawsze raportowany jako postój, więc każdy spacer startowałby na 0,05 Hz. Złapały to testy, nie przegląd kodu.

### Zweryfikowane na urządzeniu (motorola edge 50 neo, Android 16)

- ✅ **Mapa renderuje z pliku PMTiles.** `pmtiles://file://`, schemat OpenMapTiles, ciemna paleta, stożek kierunku, dolne menu.
- ✅ **Prawdziwy GPS**, dokładność ±3,2 m, fiks po kilku sekundach.
- ✅ **Pobieranie pakietu** z release'u GitHuba, z wznawianiem po zerwaniu.
- ❌ **Mapa z sieci nie działa** z GitHub Releases — zmierzone, patrz tabela blokad.
- ✅ **Uprawnienia i optymalizacja baterii** — ekran ustawień pokazuje stan wszystkich trzech przełączników i odświeża się po powrocie z ustawień systemowych.
- ✅ **Łapanie pozycji w budynku** — bez opóźnień po poprawkach z pierwszego spaceru.
- ⬜ **Niesprawdzone:** zużycie baterii przez godzinę, przeżywalność procesu przy agresywnym oszczędzaniu energii, spójność śladu na dłuższym spacerze. To jest kryterium wyjścia i wymaga **czystego** spaceru na poprawionym buildzie.

### Zrobione poza planem (na zgłoszenia z telefonu)

Rzeczy, których nie było w roadmapie, a które wyszły z pierwszych uruchomień. Formalnie należą do etapu 9 (onboarding, dostępność), ale bez nich testowanie było niewygodne.

| Co | Dlaczego teraz |
| :---- | :---- |
| Ekran wyboru języka jako pierwszy ekran | §3.5 mówi o ruchu drogowym; gracz, który tego nie przeczyta, nie został poinstruowany |
| Jasny motyw + ekran ustawień | czarna mapa w czerwcowe południe jest nieczytelna (§12) |
| Wpisywanie liczb w kreatorze obok suwaków | wzrost 120–220 cm na kilkuset pikselach — centymetr ma poniżej piksela |
| Pobieranie przeżywające opuszczenie ekranu | 235 MB żyje dłużej niż ekran, który je zaczął |
| Symulator jako świadomy wybór, nie domyślny build debugowy | build debugowy brał symulator i pomijał pytanie o GPS, przez co testy w terenie wyglądały na zepsute |

⚠️ **Etap 3 to pierwszy moment, w którym §3.5 przestaje być teorią.** Strefy wykluczone i blokada walki w ruchu muszą działać, zanim ktokolwiek poza deweloperem uruchomi grę w terenie.

### Projekt: przeniesienie gracza między sesjami (3.12)

§16.6 wymienia „zachowanie po wyjeździe poza pobrany obszar" jako brakujący projekt. Oto on.

**Sytuacja.** Gracz kończy sesję wieczorem w Poznaniu, jedzie nocą pociągiem, odpala grę w Krakowie. Aplikacja była zamknięta, więc nic nie mierzyła — z punktu widzenia symulacji minęło osiem godzin offline i tyle. Ale *miejsce* się zmieniło, a na tym stoi cała reszta gry.

**Czego nie trzeba naprawiać.** Anti-cheat §3.4 nie zadziała i nie powinien: podróż odbyła się bez ani jednego fiksu, więc nie ma z czego policzyć prędkości. Filtr §3.2 startuje czysty, więc 500 km nie zostanie zaliczone jako ruch. Zawór offline §2.1.1 już obsługuje osiem godzin nieobecności. **Przeniesienie nie może zostać naliczone jako przebyty dystans** — dziś wynika to z `_filter.reset()` i catch-upu z flagą `offline`; do etapu 3 dochodzi test, który to przypina.

**Wykrycie.** Pierwszy zaufany fiks po starcie sesji dalej niż **25 km** od ostatniej zapisanej pozycji. Zaufany znaczy: przeszedł bramkę 25 m i nie jest z mock providera. Próg nie służy do policzenia niczego — służy do **wyjaśnienia**. Zbyt czuły próg jest nieszkodliwy (gracz dostaje jedno zdanie za dużo), zbyt tępy zostawia go z pustym ekranem bez powodu.

**Trzy przypadki i trzy zachowania:**

| Gdzie się obudził | Co robi gra |
| :---- | :---- |
| W zasięgu pobranego pakietu | Gra idzie dalej. Jedna notatka fabularna. Schron zostaje tam, gdzie był — 500 km stąd (konsekwencja dla §8) |
| Poza pakietami, ale region jest w katalogu | Notatka fabularna + ekran wyboru regionu z podświetlonym właściwym województwem. Do pobrania — nie ma mapy, nie ma POI, nie ma lootu (§10) |
| Poza pakietami i regionu nie ma w katalogu | Rozgrywka wstrzymana z wyjaśnieniem. Wyjście: wrócić w zasięg albo pobrać inny region |

**Komunikat.** Tonem świata, nie interfejsu — gracz jest ocalałym, a nie użytkownikiem aplikacji: *„Znowu urwał mi się film. Nie mam pojęcia, jak się tu znalazłem. Ostatnie, co pamiętam, było jakieś 350 km stąd."*

**Zmiana wobec projektu: bez nazwy miasta.** Pierwotny wariant kończył się „Tablica przy drodze: {city}", ale gra nie ma geokodowania odwrotnego i nie będzie miała — nazwa wymagałaby zapytania do sieci, czego §1.2 zabrania. Warstwa `place` w kafelkach ją niesie, ale odpytywanie kafelków to osobna maszyneria. **Dystans jest jedyną rzeczą, którą gra wie na pewno i może powiedzieć bez pytania kogokolwiek** — i brzmi w tej scenie równie dobrze. Pułapka fleksyjna z §19.1.1 tym samym znika z tego komunikatu, ale wróci przy notatkach z §19.1.

**Czego ten projekt *nie* rozstrzyga:** czy gracz może przenieść schron (§8). Podróż z powrotem po 500 km to nie mechanika, to brak mechaniki. Do decyzji przy etapie 8.

### Decyzja do podjęcia: marsz z wygaszonym ekranem (3.13)

**Stan faktyczny, sprawdzony w kodzie.** Manifest deklaruje `ACCESS_BACKGROUND_LOCATION`, a `DevicePositionSource` uruchamia foreground service z wake lockiem, gdy zgoda jest pełna. Fiksy w tle **przychodzą**. Ale `GameLoop.onPaused` kasuje timer ticków i ustawia `_appForeground = false`, a `_buildInput` przekazuje wtedy `offline: true`. Efekt: **usługa działa, pozycja się aktualizuje, a symulacja stoi.** Po powrocie catch-up leci z zaworem offline, a `_filter.reset()` wyrzuca przejechaną ścieżkę.

To sprzeczne z tym, po co §3.3 każe trzymać foreground service. Dwie spójne drogi:

| Wariant | Co daje | Co kosztuje |
| :---- | :---- | :---- |
| **A — naliczać marsz w tle** | godzinny spacer z telefonem w kieszeni liczy się tak samo jak z telefonem w ręku; gra mierzy to, co obiecuje | tick w tle na wolnej kadencji, realne zużycie baterii, i formularz Google z **nagraniem wideo** uzasadniającym lokalizację w tle |
| **B — tylko na ekranie** | zgodne z dzisiejszym zachowaniem, prostsza recenzja w Play, brak wideo; §16.1 traktuje ten tryb jako pełnoprawny | gracz musi trzymać grę na wierzchu przez cały spacer, co przy godzinnej sesji jest realnym kosztem |

**Rekomendacja: A dla wersji docelowej, B jako pierwsze wydanie.** Gra o przetrwaniu, która przestaje liczyć, gdy schowasz telefon do kieszeni, mierzy coś innego niż obiecuje. Ale pierwsze wydanie nie musi się od razu bić z recenzją Play, a przełączenie B→A to usunięcie dwóch linii w `onPaused` i uprawnienie w manifeście — nie przebudowa.

**Rozstrzygnięte: wariant A.** Wdrożone. Źródło pozycji deklaruje `tracksInBackground`, a pętla przestaje flagować czas offline, dopóki fiksy przychodzą.

Przy okazji wyszło coś, czego nie było w żadnym wariancie. Foreground service **można ubić bez powiadomienia**, a Doze wstrzymuje fiksy zostawiając proces przy życiu — w obu przypadkach pętla budzi się z luką, której nie obserwowała. Sama flaga uprawnienia tego nie odróżnia. Rozstrzyga **wielkość kroku**: pojedynczy `advance` dłuższy niż `kUnmeasuredGap` (5 minut) jest traktowany jako offline niezależnie od tego, co deklaruje źródło. Zawór §2.1.1 nadal łapie dwutygodniową nieobecność, a dziesięć minut marszu z telefonem w kieszeni liczy się normalnie. Trzy testy w `game_loop_test.dart` pilnują obu końców.

⚠️ Wariant A oznacza formularz Google z **nagraniem wideo** uzasadniającym lokalizację w tle. Bez tego wydanie nie przejdzie recenzji.

### Weryfikacja pakietu wielkopolskiego

Nie „plik istnieje", tylko rozpakowany katalog PMTiles i zdekodowane kafelki. 85 205 kafelków, zoom 0–15, MVT. Warstwy w najgęstszych kafelkach: `landcover`, `landuse`, `place`, `transportation`, `transportation_name`, `building`, `housenumber`, `poi`, `water`, `water_name`, `boundary`, `waterway`, `park`, `mountain_peak`, `aeroway`, `aerodrome_label`.

Wszystkie nazwy, na których stoi styl (`landcover`, `park`, `water`, `waterway`, `building`, `transportation`, `boundary`), są obecne. Wartości `transportation.class` też się zgadzają: `path`, `minor`, `tertiary`, `service`, `rail`, `track`, `transit`.

Dwa wnioski na przyszłość:

- 🟢 **Warstwa `poi` niesie ~99 tys. obiektów** z polami `class`, `subclass`, `rank`. To jest źródło danych dla lootu z §10, którego etap 4 dotąd nie miał. Nie trzeba osobnego pobierania OSM.
- 🔴 **`SpawnFilter` czyta surowe tagi OSM, a kafelki niosą schemat znormalizowany.** Szpital w kaflu to `landuse.class=hospital`, nie `amenity=hospital`; szkoła to `landuse.class=school`. Reguły §3.5 są poprawne, ale przy podłączaniu do kafelków (etap 4) potrzebny jest adapter z OpenMapTiles na tagi. Bez niego filtr przepuści wszystko.

**Kryterium wyjścia:** godzinny spacer po mieście daje spójny ślad bez fałszywego ruchu na postoju, zużycie baterii mieści się w założeniach §3.3, a proces przeżywa agresywne oszczędzanie energii (test na urządzeniu Xiaomi/Samsung).

---

## Etap 4 — Przedmioty i loot

**Cel:** świat ma zawartość, a plecak ma cenę.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 4.1 | ✅ Wspólny schemat przedmiotu + walidacja JSON przy buildzie, paczki treści bez nowego builda | §4.1 |
| 4.2 | ✅ 119 przedmiotów w jedenastu plikach (w tym dodatki do broni: kolimator, laser, latarka, przedłużony magazynek, chwyt, tłumik), `loot_tables.json` — 20 tabel (11 OSM + 9 proceduralnych) | §10.3, Załącznik |
| 4.3 | ✅ Ekwipunek z dwoma limitami: masa i objętość, oba paski w HUD | §18.1a |
| 4.4 | ✅ Plecaki (udźwig + pojemność), odzież i pancerz (dwie osie ochrony) | §4.4, §4.5 |
| 4.5 | ✅ Loot z POI (własny czytnik PMTiles + MVT), respawn 4–8 h, max 15 w promieniu 2 km, 5 gwarantowanych w 600 m | §10 |
| 4.6 | ✅ Warstwa proceduralna przy gęstości POI < 8: domy, stodoły i ambony generowane na landcover, punkty przy drogach | §10.1 |
| 4.7 | ✅ Przeszukanie terenu: 45 s bezruchu, promień wg §10.2.2, punkty proceduralne widoczne dopiero po rozpoznaniu | §10.2 |
| 4.8 | ✅ Przeszukanie obiektu: 30 / 90 / 180 s, przerwanie, loot trafia do ekwipunku, skrzynka pustoszeje | §19.3, §10.3.5 |
| 4.9 | ✅ Przeszkody: drzwi, kłódka, szyba — trzy drogi (cicha, narzędziowa, siłowa), hałas wg §5.6.1, wyważone zostaje wyważone | §19.3 |
| 4.10 | ✅ Porzucone przedmioty na mapie: 24 h, limit 50 (najstarsze odpadają), stan i postęp lektury przetrwają, podniesienie z 15 m | §4.8 |
| 4.11 | ✅ `notes.json` — 16 notatek PL/EN, podstawianie `{district}`/`{city}` z kafelków; `{street}` wymaga przebudowy paczek (brak warstwy `transportation_name`) | §19.1 |
| 4.12 | ✅ Katalog przedmiotów na stronie projektu, generowany z `assets/data/*.json` (`tool/build_item_pages.dart`) | §4.1 |

⚠️ **Pułapka fleksyjna (polski):** zdania z placeholderem muszą być konstruowane tak, by nazwa stała w mianowniku („ulica {street}", nigdy „z {street}") — §19.1.1.

**Kryterium wyjścia:** w promieniu 2 km od punktu testowego gra znajduje sensowne POI, a w miejscowości bez POI warstwa proceduralna wyzwala się automatycznie i daje grywalną gęstość punktów.

---

## Etap 5 — Walka i przeciwnicy

**Cel:** starcie, które jest decyzją, a nie klikaniem.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 5.1 | ✅ Model celności: składanie MOA przez pierwiastek sumy kwadratów, `P(trafienie)` z dystrybuanty | §5.1 |
| 5.2 | ✅ Rekalibracja składników: tętno kwadratowo, ruch gracza `8 × v^1.2` | §5.1.1 |
| 5.3 | ✅ Jawna szansa trafienia w panelu ognia wraz z największym składnikiem błędu | §5.1.4 |
| 5.4 | ✅ Model obrażeń: `5,1 × J^0,6 × wound_factor × mnożnik_lokalizacji × (1 − ochrona)` | §5.1.5 |
| 5.5 | ✅ Szwędacz: parametry, maszyna stanów, budżet sprintu, smycz 400 m, utrata kontaktu 45 s | §6.1, §6.1a, §6.2 |
| 5.6 | ✅ Ruch przeciwników: linia prosta z lokalnym omijaniem wody i terenów §3.5 (routing OSM poza MVP) | §6.3 |
| 5.7 | ✅ Namierzanie jednego celu, koszt przełączenia 1,2 s, brak automatyki po śmierci celu | §5.5.1 |
| 5.8 | ✅ HUD walki grupowej: liczba zaangażowanych, dystans do najbliższego, pasek sprintu i stan namierzonego celu | §5.5.2 |
| 5.9 | ✅ Magazynek i przeładowanie z przerwaniem przy zbliżeniu <5 m | §5.5.4 |
| 5.10 | ✅ Limit 8 aktywnych przeciwników w promieniu 300 m (Horda podnosi do 12) | §5.5.6 |
| 5.11 | ✅ **System hałasu:** promienie, modyfikatory otoczenia, reakcja przeciwników, limit 6 reagujących, kumulacja 30 s | §5.6 |
| 5.12 | ✅ Wizualizacja fali hałasu na mapie: okrąg ~1,5 s o promieniu efektywnym | §5.6.5 |
| 5.13 | Dystanse zaangażowania: wykrycie od 150 m, walka 50–250 m, poniżej 20 m tryb wręcz | §5.2 |
| 5.14 | ✅ Zasady spawnu: nigdy bliżej niż 150 m, nigdy w strefach wykluczonych, nigdy w 200 m od schronu | §6.4 |

⚠️ **System hałasu wchodzi razem z walką, nie po niej.** Bez niego strzelanie nie ma kosztu innego niż amunicja i znika główna decyzja taktyczna gry (§0.1).

**Kryterium wyjścia:** wartości z tabeli kalibracyjnej §5.1.2 odtwarzają się w nakładce diagnostycznej; grupa 4 Szwędaczy kosztuje nowicjusza ~24 naboje zgodnie z §10.3.3.

---

## Etap 6 — Strefy Rozkładu

**Cel:** presja, która rośnie sama. Bez tego nie ma czego przetrwać.

**Nazwa zmieniona w trakcie** — „ognisko" czytało się w terenie jak ognisko na
biwaku. „Bariera" zamiast integralności, „wylęg" zamiast respawnu, „wrogowie"
zamiast sztuk.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 6.1 | Rozmieszczenie: 500–2000 m od schronu, min. 450 m między centrami, promień do 200 m | §6.5.1 |
| 6.2 | Poziomy 1–10: promień, limit wrogów, respawn, skład | §6.5.2 |
| 6.3 | ⚠️ **Wzrost przeliczony**: `random(24 h, 48 h) × (5,8 h ÷ kredyt) × random(0,6; 1,4)`, przycięty do 12–96 h. Stara formuła liczyła w godzinach świata i dawała strefę rosnącą szybciej, niż da się ją zbić | §6.5.3, §16.4 |
| 6.4 | Powiadomienie push przy awansie z nazwą ulicy z OSM | §6.5.3 |
| 6.5 | ⚠️ **Punktacja płaska**: 10 pkt w kole, 5 poza nim, niezależnie od gatunku; regeneracja +5%/h, **ale nie kiedy gracz stoi w środku** | §6.5.4 |
| 6.6 | Wzburzenie po zbiciu poziomu; **wysyp**: 10% szans przy trafieniu, raz na 60 min, połowa limitu ponad limit | §6.5.4 |
| 6.7 | Zawór bezpieczeństwa: wzburzenie nie odnawia się przy oddaleniu >400 m | §6.5.4, decyzja otwarta §13/3 |
| 6.8 | Likwidacja: **skrytka z listy** (komponenty, złom, apteczki, amunicja), slot pusty 24–48 h | §6.5.4 |
| 6.9 | Wizualizacja: okrąg, kolor wg poziomu, panel po tapnięciu | §6.5.6 |
| 6.10 | Licznik passy przetrwania + ekran Kronika | §13.1, §9.3 |

**6.10 zamknięte, 6.4 zostaje.** Awans i zbicie mają wpis w kronice, awans
dodatkowo okno z poziomem, promieniem i dystansem, a ekran Kronika czyta wreszcie
wiersze `chronicle_entries` — zapisywane od pierwszego dnia i przez czternaście
wersji schematu nieczytane przez nikogo. Brakuje **powiadomienia push** (6.4):
wymaga zewnętrznej paczki i pozwolenia Androida, czyli decyzji, a nie kodu.

**Kryterium wyjścia:** przy ×3600 ognisko przechodzi pełną ścieżkę 1 → 10 → zbicie → likwidacja bez rozjazdu stanu po restarcie aplikacji; symulacja odpowiada na pytanie z §16.4 (czy gracz z 1 h dziennie nadąża).

---

## Etap 7 — Audio i haptyka

**Cel:** jedyny interfejs, który działa przy telefonie w kieszeni.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 7.1 | `flutter_soloud`, budżet 16 kanałów, OGG dla efektów, Opus dla ambientu | §14.2, §14.9 |
| 7.2 | Dźwięk pozycyjny `play3d()`, mapowanie współrzędnych na wektor, orientacja słuchacza z magnetometru | §14.2 |
| 7.3 | Bicie serca w tempie `HR_aktualne`, głośność rosnąca z tętnem | §14.7 |
| 7.4 | Mapowania stanów: odwodnienie, krwawienie, klasa III wstrząsu, dług snu | §14.7 |
| 7.5 | Przytłumienie miksu po strzale na 2–3 s | §5.6.4 |
| 7.6 | ~55 plików wg tabeli, `CREDITS.md` prowadzony od pierwszego pliku, skrypt CI | §14.5, §14.6 |
| 7.7 | Haptyka: wzorce rozróżnialne przez kieszeń, duplikat każdego sygnału krytycznego | §14.8, §14.1 |
| 7.8 | Tryb bez ambientu przy wygaszonym ekranie | §14.9 |

⚠️ **Gra nigdy nie może wymagać słuchawek** (§14.1). Pełna informacja musi docierać także przez wibracje i ekran.

**Kryterium wyjścia:** z telefonem w kieszeni i wygaszonym ekranem gracz rozpoznaje kierunek zbliżającego się przeciwnika oraz odróżnia wszystkie wzorce haptyczne; assety audio mieszczą się w 25 MB, a `shipped/` przechodzi kontrolę CI.

---

## Etap 8 — Schron i pętla dobowa

**Cel:** miejsce, do którego się wraca, i powód, żeby wracać.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 8.1 | ✅ Budowa schronu podstawowego, ~3 h, postęp liczony z zegara (powiadomienie: brak) | §8.3 |
| 8.2 | ✅ Strefy: 50 m dla bezpieczeństwa i blokady ataku — jeden promień na oba | §8.1 |
| 8.3 | ✅ Prywatność lokalizacji schronu: `allowBackup=false` dla całej bazy | §8.2, §11.1.3 |
| 8.4 | ✅ Obóz: 20 m, ~40 min budowy, max 2, wygasanie po 14/21 dniach (skrzynia: pojemność bez zawartości) | §8.5 |
| 8.5 | ✅ Magazyn bazowy 25 kg z limitem 3 l/kg; półka trzyma przedmioty ze stanem — książkę z postępem czytania, broń z dodatkami | §18.2, §18.1a |
| 8.6 | ✅ Sen automatyczny (strefa + noc + brak zajęcia); budowa i moduły liczą się wyłącznie w strefie | §2.1a.3–2.1a.4 |
| 8.7 | ✅ Śmierć: Hardcore z zabezpieczeniami i Kroniką, Softcore z utratą przytomności i skrytkami | §9.1, §9.2 |
| 8.8 | ✅ Przebudzenie tam, gdzie gracz stoi, odroczone w pojeździe; okno łaski **tylko w 300 m od miejsca upadku** | §9.2.1 |
| 8.9 | ✅ Ekran powrotu po przerwie: ile kosztowały godziny i co urosło. Hord nie ma (P5), więc ekran o nich milczy | §16.3 |

⚠️ **8.5 była zrobiona i opisana jako niezrobiona.** Półka trzyma przedmioty
od sierpnia — z ich własnym stanem, bo `CarriedItem` wchodzi na nią w całości.
Wiersz został z czasów, gdy policzona była sama pojemność.

**Kryterium wyjścia:** pełna doba rozgrywki — wyjście, loot, walka, powrót, nocne zajęcie — przechodzi bez utraty stanu przy wymuszonym killu procesu w każdym z tych momentów.

---

## Etap 9 — Onboarding i zgodność

**Cel:** gra, którą można wypuścić.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 9.1 | ✅ Etap 0 onboardingu — bezpieczeństwo, aktywne potwierdzenie **checkboxem** (przycisk martwy, dopóki nie zaznaczony) | §15.3 |
| 9.2 | ✅ Kreator z kontekstem + ekran wyliczonych parametrów, liczonych na żywo | §15.4 |
| 9.3 | ✅ Podpowiedzi kontekstowe wyzwalane zdarzeniami: mapa, pierwsze 50 m, pierwszy loot, pierwszy plecak, pierwsza strefa — każda raz na postać | §15.5 |
| 9.4 | ✅ Pierwsza walka — jeden Szwędacz 120 m stąd na gruncie, który przepuszcza §3.5; obrażenia ćwiartowane i podłoga na 80% krwi; sześć linii wyzwalanych przebiegiem walki | §15.6 |
| 9.5 | ✅ Ekran „Zasady przetrwania" dostępny z menu | §15.7 |
| 9.6 | ✅ Przypomnienie o widoczności po zachodzie słońca — godzinne okno po zmierzchu, raz na dobę | §3.5 |
| 9.7 | ✅ Dostępność: wysoki kontrast (własny przełącznik **i** flaga systemowa), skalowanie czcionek sprawdzone przy 200%, wibracje przy trzech sygnałach krytycznych, każdy przycisk ikonowy nazwany | §12 |
| 9.8 | 🟡 Polityka prywatności **wygenerowana i wystawiona** (`privacy.html`, PL i EN); formularz Data Safety, RODO, regulamin i IARC do wypełnienia w Play Console — odpowiedzi gotowe w [PLAY_CONSOLE.md](PLAY_CONSOLE.md) | §16.7 |
| 9.9 | 🟡 Uzasadnienie `ACCESS_BACKGROUND_LOCATION` napisane (PLAY_CONSOLE.md); wideo demonstracyjne do nagrania | §16.1 |
| 9.10 | ✅ Telemetria: **żadnej**. Ekran ustawień mówi to wprost, zamiast oferować przełącznik, którego nie ma czego wyłączać | §16.5 |
| 9.11 | Ikona, nazwa w sklepie, zrzuty ekranu, opis ASO, obsługa proporcji ekranu | §16.8 |

**Zrobione: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.10 oraz połowa 9.8 i 9.9.**
Zostaje **9.11** (materiały do sklepu) i druga połowa 9.8 i 9.9 — formularze w
Play Console oraz nagranie ekranu, czyli rzeczy spoza repozytorium. Odpowiedzi do tych formularzy — wyprowadzone z manifestu i z
`pubspec.yaml`, nie z pamięci — leżą w [PLAY_CONSOLE.md](PLAY_CONSOLE.md).

⚠️ **Polityka prywatności nie działa, dopóki nie włączysz GitHub Pages.** Play
Console sprawdza, czy URL odpowiada, więc do tego czasu formularz zostanie
odrzucony.

**Kryterium wyjścia:** build przechodzi wewnętrzne testy w Play Console, onboarding zamyka się w 5 minutach, a gra działa w pełni po odmowie zgody na lokalizację w tle.

---

## MVP — definicja gotowości

Zakres z §0.1, czyli etapy 0–9 z ograniczeniami:

- 1 typ przeciwnika (Szwędacz), 3 bronie, ~20 przedmiotów w rotacji, 1 ognisko
- schron bez modułów, bez craftingu, bez literatury i nauki umiejętności
- PL + EN
- ślady po ludziach (§19.1) i przeszukanie jako czynność (§19.3) — w zakresie, bo są tanie i najsilniej zmieniają odczucie z gry

**Test akceptacyjny MVP:** trzydziestodniowa passa przetrwania rozegrana w terenie przez osobę spoza zespołu, bez utraty zapisu i bez sytuacji, w której gra popycha gracza w niebezpieczne miejsce.

---

## Po MVP

| Fala | Zawartość | Odniesienie |
| :---- | :---- | :---- |
| **P1 — głębia przeżyciowa** | wydarzenia losowe, warstwa historii osobistej na mapie, tropy, modyfikatory osobnicze przeciwników, kamienie milowe | §19.2, §19.4–19.7 |
| **P2 — progresja** | literatura i umiejętności, wprawa czytelnicza, Archiwum, warstwa fabularna `story.json` | §4.6, §7, §20 |
| **P3 — wytwarzanie** | surowce, receptury, moduły schronu, wymagania narzędziowe, recykling, elaboracja amunicji, łuski | §18 |
| **P4 — środowisko** | sezonowość (wskaźniki C i D), pogoda krótkoterminowa z Open-Meteo, temperatura | §17 |
| **P5 — rozszerzenie walki** | Skakun i Brutal, walka wręcz, tłumiki, hordy, oskrzydlenie | §5.4, §5.5.3, §6.5.5 |
| **P6 — zasięg** | DE/ES/FR, ogniska polowe, routing przeciwników po grafie OSM, tryb dostępności | §1.1, §6.3, §6.5.7, §12 |

⚠️ **P4 wymaga P3.** Sezonowość stoi na założeniu, że zimą jest co robić w schronie przez cztery miesiące — bez craftingu i rozbudowy modułów zima jest pusta (§17.6).

---

## Ryzyka prowadzące do przerwania prac

| Ryzyko | Objaw | Odpowiedź |
| :---- | :---- | :---- |
| **Gra złożona z samych kosztów** | w typowej godzinie przeważa zarządzanie ograniczeniami nad odkrywaniem | policzyć proporcję przed testami terenowymi; §19.1 i §19.3 są w MVP właśnie dlatego (§19.8) |
| **Tempo ognisk nie pasuje do 1 h gry dziennie** | wszyscy gracze dochodzą do trzech ognisk poziomu 10 w tym samym momencie | symulacja przed etapem 6, korekta wzoru z §6.5.3 (§16.4) |
| **Spirala niemocy w Softcore** | gracz mdleje, budzi się z 25% krwi, mdleje ponownie | zaprojektować dno przed publikacją: minimalny loot gwarantowany albo reset ognisk (§16.2) |
| **Odmowa zgody na lokalizację w tle** | Google odrzuca formularz albo użytkownik odmawia | tryb tylko-foreground jako pełnoprawny wariant gry, gotowy na etapie 3 (§16.1) |
| **Ubijanie foreground service** | dziura w symulacji na urządzeniach Xiaomi/Huawei/Samsung | zapis przy `onPause` + catch-up + podpowiedź o wyłączeniu optymalizacji baterii (§11.1.5) |
| **Zdarzenie w terenie z udziałem gracza** | wypadek, wejście na teren prywatny | §3.5 wdrożone w całości przed pierwszym testem zewnętrznym, regulamin przed publikacją |
