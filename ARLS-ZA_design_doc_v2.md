# ARLS-ZA — Almost Real Life Survival: Zombie Apocalypse

### Dokument projektowy — stan aktualny

**Platforma:** Android (Flutter) · **Gatunek:** hiper-realistyczny survival GPS z elementami craftingu · **Model sieciowy:** offline-first, brak własnych serwerów gry · **Pakiet:** `com.raidodevelopment.arlsza` · **Nazwa w sklepie:** ARLS-ZA Game

**Status:** dokument opisuje projekt docelowy. Sekcje oznaczone ❓ wymagają decyzji przed implementacją odpowiadającego im kodu. Kolejność i zakres prac: [ROADMAP.md](ROADMAP.md).

Dokument zawiera wyłącznie aktualne rozstrzygnięcia. Historia wersji i odrzucone warianty projektowe: `ARLS-ZA_design_doc_v2.original.md`.

---

## Legenda oznaczeń

| Znak | Znaczenie |
| :---- | :---- |
| 📐 | Zawiera wzór matematyczny do implementacji |
| ❓ | Otwarta decyzja projektowa — do rozstrzygnięcia przed implementacją |
| ⚠️ | Ograniczenie lub pułapka, której naruszenie psuje inny system |
| 🔴 🟡 🟢 | Priorytet braku w rejestrach §16 i §19 |

---

## 0. Filar projektowy

Zanim przejdziemy do mechanik — jedno zdanie, do którego odnosimy każdą decyzję:

> **Ciało gracza jest kontrolerem. Wszystko, co w innych grach jest paskiem zasobu, tutaj jest konsekwencją fizjologiczną realnego wysiłku.**

Praktyczna implikacja tej zasady, kluczowa dla całego balansu:

**Skoro prędkość gracza jest niemodyfikowalna przez grę, żadna kara ani premia nie może działać na prędkość.** Wszystkie modyfikatory muszą być wyrażone jako: koszt metaboliczny (kcal/woda), tętno, celność, ryzyko urazu lub czas wykonania czynności. To jest twarde ograniczenie designu — nie da się go obejść.

### 0.1. Zakres MVP

Dokument opisuje docelową grę. Rozbicie na etapy z kryteriami wyjścia: [ROADMAP.md](ROADMAP.md). Zakres pierwszej grywalnej wersji:

**W MVP:** tworzenie postaci, silnik fizjologiczny, mapa + ruch GPS, ekwipunek, 1 typ przeciwnika (Szwędacz) z budżetem sprintu, walka dystansowa z namierzaniem wielu celów, **system hałasu (§5.6)**, 3 bronie, ~20 przedmiotów, loot z POI, podstawowy schron bez modułów, **1 ognisko z pełną mechaniką wzrostu i neutralizacji**, licznik passy przetrwania, **audio z dźwiękiem pozycyjnym (§14, ~55 plików)**, **onboarding (§15)**.

**Poza MVP:** literatura i nauka umiejętności, crafting, moduły schronu, warunki atmosferyczne, walka wręcz, tłumiki, hordy, ogniska polowe, 5 języków (start: PL+EN), decyzja o modelu dystrybucji.

⚠️ **Uwaga do zakresu:** system hałasu musi trafić do MVP razem z ogniskiem. Bez niego strzelanie nie ma kosztu innego niż amunicja, a cały wybór „palna czy biała" znika — czyli testujemy grę bez jej głównej decyzji taktycznej.

**Do MVP dochodzą z §19:** ślady po ludziach (§19.1) i przeszukanie obiektu jako czynność czasowa (§19.3) — obie tanie we wdrożeniu i najsilniej zmieniające odczucie z gry.

**Poza zakresem rozgrywki, ale przed pierwszą linią kodu gry:**

- **Tryb deweloperski (§11.2)** — warunek jakiejkolwiek pracy nad balansem
- **Warstwa trwałości zapisu (§11.1)** — dopisanie migracji po fakcie oznacza skasowanie zapisów pierwszym patchem

Sezonowość (§17) i loot proceduralny (§10.1) mogą powstać po MVP, ale **struktury danych muszą je przewidywać od początku** (pole `season_modifiers`, flaga `procedural` w punktach lootu). Dodanie ich później to migracja schematu, nie nowa funkcja.

⚠️ **Uwaga do zakresu:** ognisko musi trafić do MVP mimo swojej złożoności. Bez niego nie da się przetestować pętli podstawowej — bez rosnącej presji nie ma czego przetrwać, a cały test sprowadza się do sprawdzenia, czy GPS działa.

---

## 1. Tworzenie postaci

### 1.1. Ekran wyboru języka

PL, EN, DE, ES, FR. Implementacja: `flutter_localizations` + pliki ARB. Domyślny język pobierany z ustawień systemu, z możliwością zmiany.

⚠️ **Uwaga:** nazwy przedmiotów, literatury i statusów muszą być w plikach lokalizacyjnych, a **nie** w plikach definicji przedmiotów (`weapons.md` itd.). W definicjach trzymamy wyłącznie klucze (`weapon.ak74.name`), inaczej dodanie języka oznacza przepisanie całej bazy przedmiotów.

### 1.2. Dane gracza

- Nazwa: 4–16 znaków alfanumerycznych + spacje (walidacja: bez spacji wiodących/końcowych, bez podwójnych spacji)
- Płeć: M / K ⚠️ *(potrzebna wyłącznie do wzorów fizjologicznych — należy to zakomunikować w UI jednym zdaniem, żeby nie było odbierane jako element narracyjny)*
- Wiek: 16–80 lat
- Wzrost: 120–220 cm
- Waga: 35–200 kg

⚠️ **Walidacja krzyżowa:** odrzucać kombinacje niefizjologiczne (BMI < 12 lub > 60) — inaczej gracz wpisze 200 cm / 35 kg i rozłoży wszystkie wzory.

**Kwestia prawna:** wzrost, waga, wiek i płeć to dane dotyczące zdrowia. Dane pozostają wyłącznie na urządzeniu, nigdy nie opuszczają telefonu — to trzeba jawnie zadeklarować w Google Play Data Safety oraz w ekranie onboardingu. Przy wieku < 18 lat: uproszczony tryb bez zbierania danych biometrycznych ❓ *(albo minimalny wiek 16 lat w regulaminie)*.

### 1.3. Parametry wyliczane 📐

**Objętość krwi — wzór Nadlera** (h w metrach, w w kg, wynik w litrach):

Mężczyzna: V = 0.3669 × h³ + 0.03219 × w + 0.6041

Kobieta: V = 0.3561 × h³ + 0.03308 × w + 0.1833

Przykład: mężczyzna 180 cm / 80 kg → 0.3669 × 5.832 + 0.03219 × 80 + 0.6041 = **5.319 l (5319 ml)**

**Podstawowa przemiana materii — Mifflin–St Jeor** (h w cm, w w kg, a = wiek):

Mężczyzna: BMR = 10w + 6.25h − 5a + 5

Kobieta: BMR = 10w + 6.25h − 5a − 161

**Dzienne zapotrzebowanie na wodę** 📐 :

Woda_bazowa [ml/dobę] = 35 × masa_ciała [kg]

Woda_całkowita = Woda_bazowa + straty_z_potem

Straty z potem liczone dynamicznie — patrz sekcja 2.4.

**Tętno spoczynkowe** — brak danych o kondycji gracza, więc estymujemy:

HR_spoczynkowe = 70 + 0.15 × (BMI − 22) + 0.1 × (wiek − 30)

zakres ograniczony do 50–95 bpm

**Tętno maksymalne — wzór Tanaki** (dokładniejszy niż 220−wiek):

HR_max = 208 − 0.7 × wiek

**Maksymalny udźwig** 📐 — oparty o normy marszowe wojskowe:

Udźwig_komfortowy = 0.30 × masa_ciała (bez kar)

Udźwig_maksymalny = 0.45 × masa_ciała (twardy limit)

Dla 80 kg: komfort 24 kg, max 36 kg.

⚠️ **Zasada:** przekroczenie udźwigu komfortowego **nie blokuje** ruchu (nie możemy spowolnić realnego gracza). Zamiast tego skalujemy koszt metaboliczny — patrz 2.3.

---

## 2. Fizjologia

### 2.1. Skala czasu i strefy metaboliczne

Przy skali 1:1 gracz, który nie otworzy gry przez trzy dni, umiera z odwodnienia — gwarantowana utrata użytkownika. Metabolizm nie może też zależeć od tego, czy proces działa, bo to abstrakcja oderwana od filaru z §0.

**Rozwiązanie: metabolizm zależy od miejsca, w którym znajduje się postać.** Odpoczynek pod dachem realnie obniża wydatek energetyczny i straty wody — nie potrzebujemy żadnej fikcji.

| Strefa | Kalorie | Woda | Uzasadnienie |
| :---- | :---- | :---- | :---- |
| **Teren otwarty** | 100% wg MET (§2.2) | 100% | pełna symulacja |
| **Obóz** (20 m, §8.5) | **50%** | **55%** | odpoczynek, osłona przed wiatrem i słońcem |
| **Schron główny** (50 m) | **35%** | **40%** | dach, ściany, stabilna temperatura |
| **Sen w schronie** | **20%** | **30%** | podstawowa przemiana materii |

📐 Zużycie liczone zawsze — metabolizm to fizjologia, nie czynność postaci, więc podlega regule z §2.1a jako proces ciągły.

#### 2.1.1. Zachowanie przy zamkniętej aplikacji

Przy wyłączonym GPS gra nie wie, gdzie jest postać. **Przyjmuje ostatnią znaną strefę** i tempo spoczynkowe (MET 1.0).

To tworzy prostą, czytelną zasadę zachowania, której nie trzeba tłumaczyć wprost: **kończ sesję pod dachem.** Wyjście z aplikacji w terenie kosztuje trzykrotnie więcej niż w schronie — gracz uczy się tego po jednym razie.

⚠️ **Zawór bezpieczeństwa (obowiązkowy):** zużycie w stanie offline **nigdy nie sprowadza żadnego zasobu poniżej 10%** i nigdy nie powoduje śmierci. Powrót po dwutygodniowym urlopie ma boleć, ale nie kasować postaci. Spójne z §9.1 (awaria ani nieobecność nie mogą zabić w Hardcore).

Po powrocie gra wykonuje **catch-up tick** — jednorazowe przeliczenie od `last_update_timestamp`, idempotentne (§11.1.2).

#### 2.1.2. Dlaczego to rozwiązuje problem pracującego gracza

Bez stref metabolicznych gracz spędzający osiem godzin w pracy wraca do postaci na skraju odwodnienia. Z obozem zbudowanym przy miejscu pracy — wraca do postaci wypoczętej, a **rozgrywką staje się droga do domu**. Patrz §8.5.

⚠️ **Anti-cheat zegara:** gracz może cofnąć zegar systemowy, żeby wyzerować głód. Zabezpieczenie: `last_update` jako licznik monotoniczny + wykrycie cofnięcia czasu → tick traktowany jako 0 sekund (nigdy ujemny).

### 2.1a. Zajęcia i reguła obecności

#### 2.1a.1. Zasada: jedno zajęcie naraz

Postać nie może jednocześnie spać, czytać i budować. To ograniczenie realizmu, ale przede wszystkim **główny mechanizm ekonomii czasu w grze** — bez niego wszystkie systemy schronowe biegłyby równolegle i żaden nie miałby kosztu.

**Trzy kategorie działań:**

| Kategoria | Przykłady | Zasada |
| :---- | :---- | :---- |
| **ZAJĘCIE** (jedno naraz) | sen, czytanie literatury, budowa schronu i modułów, wytwarzanie, naprawa, recykling, elaboracja amunicji | rozpoczęcie nowego **anuluje** poprzednie; postęp zapisany |
| **CZYNNOŚĆ** (krótka, przerywa zajęcie) | jedzenie, picie, opatrywanie ran, przeszukanie terenu, przeładowanie, strzał | zawiesza zajęcie na czas trwania, po zakończeniu zajęcie wraca |
| **PROCES TŁOWY** (zawsze) | metabolizm, krwawienie, trawienie, regeneracja tętna, wzrost ognisk | niezależny od wszystkiego |

**Sen jest zajęciem domyślnym**, nie akcją do wybrania. Gdy spełnione są warunki z §2.5.1 i postać nie robi nic innego — śpi. Rozpoczęcie lektury lub budowy w nocy to **świadoma rezygnacja ze snu**.

#### 2.1a.2. Wynikowa ekonomia czasu

To jest sedno rozgrywki w schronie. Doba ma stałą liczbę godzin, a noc — wyznaczoną przez porę roku (§2.5.3):

| Poznań, noc | Sen 8 h | Zostaje na lekturę/budowę |
| :---- | :---- | :---- |
| 21 czerwca (7,4 h) | niepełny, **dług narasta** | ~0 h |
| 21 marca (12,0 h) | pełny | ~4 h |
| 21 grudnia (16,6 h) | pełny | **~8,6 h** |

⚠️ **Latem gracz musi wybierać między snem a rozwojem.** Dług senny podnosi MOA i wydłuża wszystkie czynności (§2.5.4), więc „nie śpię, tylko czytam" ma realną cenę na następny dzień. To jest ta decyzja, o którą chodzi.

#### 2.1a.3. Reguła obecności — co tyka i kiedy

| Rodzaj | Warunek tykania |
| :---- | :---- |
| **Zajęcia schronowe** (sen, lektura, budowa, crafting) | postać w strefie schronu lub obozu — **tykają także przy zamkniętej aplikacji** |
| **Czynności terenowe** (przeszukanie, walka, opatrywanie w terenie) | wyłącznie przy otwartej aplikacji i prawidłowym sygnale GPS (§3.2) |
| **Procesy tłowe fizjologiczne** | zawsze, w tempie zależnym od strefy (§2.1) |
| **Zdarzenia świata** (ogniska, respawn, hordy) | zawsze, w czasie zegarowym |

⚠️ **Zajęcia schronowe nie mogą wymagać obecności.** Gracz fizycznie śpi w nocy — nie utrzyma otwartej aplikacji przez osiem godzin. Inaczej cała ekonomia czasu z §2.1a.2 byłaby fikcją.

**Model docelowy:** gracz przed snem wybiera, co postać robi tej nocy — śpi, czyta albo buduje — i zamyka telefon. Rano widzi wynik. **Jedno tapnięcie, realna decyzja, zero czasu wpatrywania się w pasek postępu.**

#### 2.1a.4. Zabezpieczenia

- **Zamknięcie aplikacji nie przerywa zajęcia schronowego**, ale zmiana strefy tak. Jeśli GPS wykryje opuszczenie schronu — zajęcie anulowane, postęp zapisany.
- **Przy zamkniętej aplikacji obowiązuje ostatnia znana strefa** (§2.1.1). Gracz, który zadeklaruje lekturę i wyjdzie z domu, oszuka wyłącznie siebie — gra jednoosobowa, brak rankingów wymagających uczciwości.
- **GPS wyłączony podczas zajęć schronowych** — postać jest nieruchoma, lokalizacja niepotrzebna. Realna oszczędność baterii w najdłuższym stanie gry.
- Zajęcie rozpoczęte poza schronem (np. opatrywanie w terenie) podlega regule terenowej i **jest anulowane** przy zamknięciu aplikacji.

### 2.2. Model wydatku energetycznego 📐

Podstawą jest MET (Metabolic Equivalent of Task) wyliczany z prędkości GPS:

| Prędkość [km/h] | Aktywność | MET |
| :---- | :---- | :---- |
| 0 | postój | 1.0 |
| 0–3.2 | powolny marsz | 2.0 |
| 3.2–4.8 | marsz | 3.5 |
| 4.8–6.4 | szybki marsz | 5.0 |
| 6.4–8.0 | trucht | 8.3 |
| 8.0–9.7 | bieg | 9.8 |
| 9.7–11.3 | bieg szybki | 11.0 |
| > 11.3 | sprint | 14.0 |

kcal/min = MET × 3.5 × masa_ciała [kg] / 200

Modyfikator obciążenia :

MET_efektywne = MET × (1 + 0.8 × (obciążenie / masa_ciała))

(zgodne z równaniem Pandolfa w uproszczeniu — 20 kg na plecach przy 80 kg gracza to +20% wydatku)

### 2.3. Głód i pragnienie

- **Kalorie:** zapas energetyczny startowy = 100% dziennego zapotrzebowania. Spadek poniżej 50% → −10% do precyzji (drżenie rąk). Poniżej 20% → +20% do czasu wszystkich czynności. 0% przez > 24 h → postępująca utrata przytomności.
- **Woda:** ⚠️ tu realizm jest bezlitosny i **musi być ostrzejszy niż głód**. Utrata 2% masy ciała w wodzie → −15% do celności i czasu reakcji. 5% → silne osłabienie. 10% → stan krytyczny. Brak wody > 48 h w warunkach wysiłku = śmierć.

📐 **Straty z potem:**

pot [ml/h] = 400 + 200 × (MET − 1) + 50 × max(0, T_otoczenia − 20)

             + modyfikator_odzieży

gdzie `modyfikator_odzieży` = suma izolacji noszonych elementów × 100 ml/h przy T > 22°C. To domyka liczbowo przypadek „kurtka zimowa w 30 stopniach".

#### 2.3.1. Głód długoterminowy — masa ciała 📐

⚠️ **Zapas kaloryczny to doba, a nie odporność na głód.** Reguła „0% przez > 24 h" dotyczy *zapasu*, nie organizmu. Postać bez jedzenia stoi na zerze od drugiego poranka klęski głodu aż do jej końca — czytanie tego jako śmierci czyniło głód groźniejszym od pragnienia, wbrew §2.3.

Długą osią jest **masa ciała**. Przestaje być stałą i staje się stanem.

masa [kg] += (nadwyżka × 0,75 − niedobór) / 7000

7000 kcal/kg, nie 7700 z tabeli czystego tłuszczu: organizm pod deficytem spala mniej więcej trzy części tłuszczu na jedną część tkanki chudej, a ta jest w większości wodą. Magazynowanie jest stratne (0,75) — tydzień objadania się nie cofa tygodnia głodu.

| Ubytek masy startowej | Efekt |
| :---- | :---- |
| 0–5% | brak |
| 5–15% | +15% czasu wszystkich czynności |
| 15–30% | +40% czasu, +2 MOA |
| > 30% | śmierć |

**Przykład — 80 kg, głodówka totalna, bezruch:**

| Dzień | Masa | Ubytek |
| :---- | :---- | :---- |
| 7 | 77,6 kg | 3,0% |
| 14 | 75,2 kg | 6,0% |
| 42 | 66,1 kg | 17,4% |
| 75 | 55,9 kg | 30,1% — koniec |

W marszu szybciej. Literatura kliniczna daje 6–10 tygodni głodówki totalnej.

⚠️ **Reszta ciała idzie za masą (§1.3), bez żadnego dodatkowego wzoru.** Limity udźwigu (§18.1a), zapotrzebowanie Mifflina–St Jeora, dobowa woda 35 ml/kg i objętość krwi wg Nadlera są wyprowadzane z masy — więc lżejsze ciało pali mniej i adaptacja metaboliczna wychodzi za darmo. Objętość krwi skaluje się **proporcjonalnie razem z aktualnym ubytkiem**, żeby samo chudnięcie nie wrzuciło postaci w klasę wstrząsu bez rany.

⚠️ Nadwyżka ponad dobowy zapas **nie jest wyrzucana** — idzie w ciało. Bez tego objedzenie się przed wyprawą nie dawało nic.

⚠️ Przy zamkniętej aplikacji nic nie schodzi z ciała (§2.1.1). Podłoga offline istnieje po to, żeby telefon w szufladzie nikogo nie zabił.

**Asymetria woda / jedzenie nie jest projektowana — wypada ze stałych.** Zapas to doba jednego i drugiego, ale progi pragnienia to ułamki masy ciała, a ciało niesie miesiące tłuszczu i około trzech dób wody. Pragnienie przebiega całą swoją drogę, zanim głód zdąży się zacząć: ~3 doby wobec ~10 tygodni.

⚠️ **Pragnienie nie ma osi długoterminowej i to jest właściwa odpowiedź.** Odwodnienie nie ma pamięci — napijesz się i jesteś zdrowy. Kontrast z jedzeniem jest całym sensem tej pary. Dodane zostało jedynie `kCriticalThirstGrace`: 12 h w stanie krytycznym (10% masy ciała) kończy sprawę, bo sama reguła „48 h w warunkach wysiłku" czyni nieśmiertelnym kogoś, kto siedzi w schronie.

### 2.4. Tętno 📐

%intensywności = (MET − 1) / (MET_max − 1), MET_max ≈ 14

HR_aktualne = HR_spoczynkowe + %intensywności × (HR_max − HR_spoczynkowe)

Powrót do spoczynku po wysiłku: wykładniczy, stała czasowa τ ≈ 90 s (dla osoby przeciętnej).

**Tętno jako ukryta stamina.** Gracz nie ma paska staminy, ale tętno pełni tę rolę funkcjonalnie. Wpływ:

| HR jako % HR_max | Efekt |
| :---- | :---- |
| < 60% | brak kar |
| 60–75% | +0.5 MOA do rozrzutu |
| 75–85% | +1.5 MOA, +15% czasu przeładowania |
| 85–95% | +3.0 MOA, +30% czasu przeładowania, brak możliwości precyzyjnego celowania |
| > 95% | +5.0 MOA, ryzyko zasłabnięcia przy niskim poziomie krwi |

To rozwiązuje realizm bez sztucznego paska — gracz musi się zatrzymać i uspokoić oddech przed strzałem, dokładnie jak w rzeczywistości.

### 2.5. Sen

**Sen jest automatyczny, wyprowadzony z miejsca i pory doby.** Zero uprawnień, zero danych zdrowotnych, zero zależności od sprzętu gracza.

⚠️ **Gra nie integruje się z Health Connect ani z żadnym źródłem danych zdrowotnych** — to wiążąca decyzja architektoniczna, od której zależy §1.2 (dane nie opuszczają telefonu) i zakres deklaracji w Google Play (§16.7).

#### 2.5.1. Warunki snu

Postać śpi, gdy **jednocześnie**:

1. znajduje się w strefie schronu (50 m) lub obozu (20 m),
2. trwa noc — pora wyprowadzona ze wschodu i zachodu słońca (§17.2, liczone offline z szerokości geograficznej i daty),
3. **nie wykonuje innego zajęcia** (§2.1a).

Sen jest **stanem domyślnym**, nie akcją. Gracz nic nie klika — postać kładzie się spać, bo jest noc i jest pod dachem.

⚠️ **Punkt 3 obejmuje pracę długą, nie tylko akcje z §4.7.** Krótkie akcje (jedzenie, opatrunek, przeszukanie) mają pięciominutowe zabezpieczenie przed zawieszoną flagą — rozbiórka trwa pół godziny (§18.6), a moduł schronu dni, więc to samo zabezpieczenie robiło z postaci przy imadle postać śpiącą przed imadłem, spłacającą dług senny, gdy imadło się kręciło. Praca długa jest raportowana osobno i bez limitu czasu: interfejs wylicza ją ze stanu na każdym ticku, więc nic nie może jej zostawić włączonej. **Praca odłożona na pauzę (§8.3) nie liczy się** — to postać stojąca w schronie, która nic nie robi.

#### 2.5.2. Kiedy postać nie śpi

| Sytuacja | Skutek |
| :---- | :---- |
| Gracz wychodzi w nocy w teren | brak snu, narasta dług senny |
| Gracz świadomie czyta, buduje lub wytwarza | brak snu, narasta dług senny |
| Gracz przebywa w obozie zamiast w schronie | sen o jakości 70% (§8.5.1) |

**Nocne wyprawy jako świadomy wybór.** W nocy hałas niesie się dalej (×1,3, §5.6.1), przeciwnicy wykrywają lepiej (+20%, §17.4), a promień przeszukania terenu spada (§10.2.2). Gracz może wyjść po ciemku po lepszy loot lub żeby zdążyć zbić ognisko — ale płaci za to długiem sennym, który uderzy nazajutrz w celność i tempo wszystkich czynności.

#### 2.5.3. Ile snu daje noc 📐

sen_zaliczony = min(godziny_nocy_w_schronie, zapotrzebowanie_dobowe)

Nadmiar nocy w schronie ponad zapotrzebowanie nie kumuluje zapasu — postać po prostu odpoczywa (metabolizm 20%, §2.1).

**Naturalna sezonowość, bez żadnego modyfikatora.** Długość nocy wynika z §17.2:

| Poznań | Długość nocy | Sen 8 h | Czas na inne zajęcia |
| :---- | :---- | :---- | :---- |
| 21 czerwca | 7,4 h | niepełny — **dług narasta mimo schronu** | ~0 h |
| 21 marca / września | 12,0 h | pełny | ~4 h |
| 21 grudnia | **16,6 h** | pełny | **~8,6 h** |

To najlepszy efekt tej mechaniki: **latem doba jest za krótka na wszystko, zimą starcza na sen i naukę.** Sezonowość z §17 przestaje wymagać sztucznych mnożników — wynika sama z długości nocy.

⚠️ Konsekwencja: latem gracz musi wybierać między snem a rozwojem, a przy krótkich nocach za kołem podbiegunowym (§17.2, Tromsø) sen bywa niemożliwy przez tygodnie. To realistyczne, ale wymaga sprawdzenia w testach dla graczy z wysokich szerokości.

#### 2.5.4. Efekty deprywacji snu

Dług senny liczony wobec zapotrzebowania z §1.3:

| Dług snu | Efekt |
| :---- | :---- |
| 0–4 h | brak |
| 4–12 h | +20% czasu czytania literatury, +1 MOA |
| 12–24 h | +50% czasu wszystkich czynności, +3 MOA, −20% tempa nauki |
| > 24 h | mikrosny — losowe 5–15 s zablokowania interfejsu |

Moduł Salon (§8.4) podnosi tempo regeneracji, co realnie oznacza: **mniej godzin snu na pokrycie tego samego zapotrzebowania, czyli więcej czasu na lekturę i budowę.** To czyni Salon modułem konkurencyjnym wobec Magazynu, a nie „miłym dodatkiem".

#### 2.5.5. Deprywacja przewlekła — drugi zegar

⚠️ **Dług z §2.5.4 mierzy ostatnią noc, nie ostatni miesiąc.** Ma sufit doby, kasuje się w dobę, a ponieważ narasta wyłącznie w czasie czuwania — na sześciogodzinnych nocach wychodzi na zero i nie drgnie. Trzy tygodnie niedosypiania czytały się jak jeden zarwany wieczór.

Drugi zegar liczy się wobec **zegara ściennego**, czyli tak, jak mówi formuła §2.5.3: doba potrzebuje ośmiu godzin niezależnie od tego, co się w niej robiło.

obciążenie += 1 − S/8    (S = godziny snu w dobie)

| Sytuacja | Obciążenie | Efekt |
| :---- | :---- | :---- |
| jedna noc krótsza o 2 h | 0,25 | brak |
| cztery noce po 4 h | 2,0 | −20% tempa nauki, tętno wraca o 35% wolniej |
| dwa tygodnie po 6 h | 3,5 | −40% nauki, +1 MOA, gojenie −30% |
| dwa miesiące po 6 h | 10 (sufit) | +2 MOA, gojenie −50%, mikrosny |

⚠️ **Kary są celowo te, których pasek snu nie pokazuje.** Tak działa przewlekłe niedosypianie: subiektywna senność się wypłaszcza, a wydolność dalej spada. Po jednej dobrej nocy pasek jest pełny, a gojenie, tętno i ręce dalej są złe. To wymaga własnej notatki stanu (§12) — kara bez widocznego powodu czyta się jako błąd, choćby najprawdziwsza.

⚠️ **Spłaca tylko noc dłuższa niż potrzeba.** Regeneracja po przewlekłej deprywacji wymaga snu nadmiarowego, nie wystarczającego — i to sadza tę oś dokładnie na sezonowości §2.5.3, bez jednego modyfikatora:

- **Poznań, 21 czerwca (7,4 h nocy):** obciążenie narasta niezależnie od tego, jak ostrożnie gra gracz.
- **Poznań, 21 grudnia (16,6 h nocy):** cztery takie noce kasują całe lato.
- **Salon (§8.4)** staje się jedyną rzeczą kupującą regenerację poza sezonem — czyli tym, czym §2.5.4 go nazywa.

### 2.6. Model obrażeń i krwawienia

⚠️ **Blokuje sekcje 5 i 6** — bez przelicznika trafienia na ubytek krwi walka jest niepoliczalna.

**Progi wstrząsu krwotocznego (klasy wg ATLS):**

| Utrata krwi | Klasa | Stan gracza |
| :---- | :---- | :---- |
| < 15% | I | brak objawów |
| 15–30% | II | tachykardia, +2 MOA, −10% udźwigu |
| 30–40% | III | +5 MOA, przyciemniony ekran, brak biegu bez zawrotów głowy |
| > 40% | IV | utrata przytomności → śmierć w ciągu 2–5 min bez pomocy |

**Tiery krwawienia:**

| Typ | Ubytek | Zatrzymanie |
| :---- | :---- | :---- |
| Powierzchowne | 3 ml/min | samoistnie po 3–5 min lub opatrunek |
| Umiarkowane | 25 ml/min | opatrunek uciskowy (60–120 s) |
| Silne | 90 ml/min | opatrunek + unieruchomienie |
| Tętnicze | 350 ml/min | wyłącznie staza/opaska uciskowa (30–60 s) |

📐 **Modyfikator wysiłku:** `ubytek_efektywny = ubytek_bazowy × (HR_aktualne / HR_spoczynkowe)` — bieganie przy krwawieniu przyspiesza utratę krwi; przy tętnie 160 wobec spoczynkowego 70 jest to 2.3×.

**Konwersja trafienia na obrażenia:**

ubytek_natychmiastowy [ml] = energia_pocisku [J] × współczynnik_lokalizacji × (1 − ochrona_pancerza)

typ_krwawienia = f(lokalizacja, energia)

| Lokalizacja | Szansa trafienia (cel niezabezpieczony) | Mnożnik |
| :---- | :---- | :---- |
| Głowa | 12% | 4.0× + szansa na natychmiastową eliminację |
| Tors | 55% | 1.0× |
| Kończyny górne | 15% | 0.4× + upuszczenie broni |
| Kończyny dolne | 18% | 0.5× + spowolnienie przeciwnika o 40% |

### 2.7. Czego świadomie NIE modelujemy

Żeby zakres nie eksplodował: brak złamań, infekcji, chorób, temperatury ciała jako osobnego parametru, zatruć pokarmowych i zdrowia psychicznego. Do rozważenia po MVP.

⚠️ **Masa ciała jest wyjątkiem i nie jest złamaniem tej zasady.** To nie nowy parametr obok istniejących — to ta sama liczba z §1.3, która przestała być stała. Wszystko, co z niej wynikało (krew, BMR, woda, udźwig), wynika z niej dalej. Bez tego §2.3 nie miało czym mierzyć głodu dłuższego niż doba.

---

## 3. Mapa

### 3.1. Stos technologiczny

**Uwaga krytyczna:** publiczny serwer kafelków OpenStreetMap (`tile.openstreetmap.org`) **zabrania** użycia w aplikacjach produkcyjnych w swojej Tile Usage Policy. Aplikacja zostanie zablokowana po IP. Opcje:

| Rozwiązanie | Koszt | Offline | Rekomendacja |
| :---- | :---- | :---- | :---- |
| **Protomaps + PMTiles** | darmowe, self-host statycznego pliku | ✅ natywnie | ⭐ **Najlepsze** — jeden plik na region, idealne pod „brak serwerów" |
| MapTiler free tier | darmowy do 100k req/mies. | częściowo | zapasowo |
| Stadia Maps | darmowy tier | częściowo | zapasowo |
| Własny serwer kafelków | VPS ~20–40 zł/mies. | ✅ | sprzeczne z założeniem |

**Rekomendacja: MapLibre GL Native (Flutter) + PMTiles.** Gracz przy pierwszym uruchomieniu pobiera pakiet kafelków dla swojego regionu (~50–200 MB na województwo). To jednocześnie realizuje założenie offline-first i eliminuje koszty.

### 3.2. Jakość sygnału GPS

Dokładność GPS w mieście to 5–15 m, wewnątrz budynków brak sygnału. Dryf pozycji przy nieruchomym graczu generuje fałszywy „ruch" → gra spala kalorie osobie siedzącej na kanapie.

Zabezpieczenia:

- Filtr Kalmana na strumieniu pozycji
- Odrzucanie odczytów o `accuracy > 25 m`
- Próg martwej strefy: przemieszczenie < 8 m w 10 s = brak ruchu
- Utrata sygnału > 60 s → pauza symulacji ruchu, komunikat w UI

### 3.3. Zużycie baterii

Ciągły GPS to 15–25% baterii na godzinę — realne zagrożenie dla rozgrywki wielogodzinnej.

- Foreground service z powiadomieniem trwałym (wymóg Androida)
- Adaptacyjne próbkowanie: 1 Hz w walce, 0.2 Hz w marszu, 0.05 Hz przy postoju
- Tryb oszczędny: mapa zredukowana, brak animacji
- Ostrzeżenie przy < 20% baterii z sugestią powrotu do schronu

### 3.4. Anti-cheat pozycji

Bez serwera pełny anti-cheat jest niemożliwy — akceptujemy to (gra jednoosobowa, oszust szkodzi tylko sobie). Minimum:

- Wykrywanie mock location (`Location.isFromMockProvider`)
- Kontrola prędkości: > 40 km/h przez > 30 s = podróż pojazdem → **zawieszenie rozgrywki**, nie kara

### 3.5. Bezpieczeństwo gracza ⚠️ — **sekcja obowiązkowa**

Gra zachęca do biegania po mieście, często po zmroku, z telefonem w ręku. Lekcje z Pokémon GO są tu bezpośrednio aplikowalne i ich pominięcie to ryzyko prawne i wizerunkowe.

**Strefy wykluczone ze spawnu** (filtrowane po tagach OSM):

- Jezdnie i pobocza dróg (`highway=motorway|trunk|primary|secondary`) — bufor 15 m
- Tory kolejowe (`railway=*`) — bufor 30 m
- Wody (`natural=water`, `waterway=*`)
- Tereny prywatne (`access=private`, `landuse=residential` z budynkami mieszkalnymi)
- Szpitale, szkoły, przedszkola, cmentarze, miejsca kultu, komisariaty, obiekty wojskowe

**Mechaniki ochronne:**

- Blokada walki przy prędkości > 15 km/h (komunikat: „Nie graj podczas jazdy")
- Ekran startowy z akceptacją zasad bezpieczeństwa (jednorazowo)
- Po zmroku (godzina lokalnego zachodu słońca): przypomnienie o widoczności i świadomości otoczenia
- Tryb „domowy" ❓ — czy dopuszczamy grę bez wychodzenia z domu (tryb ograniczony)? Kwestia dostępności dla osób z niepełnosprawnością ruchową — patrz 12.

### 3.6. Interfejs

**Górny pasek (HUD)** — zawsze widoczny, minimalistyczny:

- **Godzina (lokalna) i ile zostało do zmierzchu/świtu** — §17.2. ⚠️ Zasady nocy wchodzą naraz: §10.2.2 połowi promień zwiadu, §17.4 daje każdemu szwędaczowi piątą część zasięgu więcej, §5.6.1 niesie strzał o jedną trzecią dalej. Nic z tego nie widać, dopóki się nie stanie — półtorej godziny ostrzeżenia to różnica między powrotem do domu a złapaniem w terenie
- Poziom krwi (% + ikona, zmiana koloru przy klasie II+)
- Aktywne statusy (krwawienie, zmęczenie, odwodnienie) — ikony
- Woda / kalorie — dwa cienkie paski
- Udźwig: wykorzystany / maksymalny

**Widok mapy:**

- Rzut z góry, zielona kropka = gracz, stożek = kierunek ruchu
- Czerwone znaczniki = przeciwnicy (widoczni w promieniu zależnym od umiejętności Zwiad)
- Żółte = lootboxy, szare = przedmioty porzucone, niebieskie = schron

**Dolne menu:** PROFIL · EKWIPUNEK · SCHRON · USTAWIENIA

### 3.6.1. Dziennik

Ekran PROFILU kończy się **dziennikiem** — co postać robiła, w kolejności, pogrupowane po dniach przetrwania:

DZIEŃ 2

06:30 Wyjście ze schronu

06:52 Przeszukanie: Żabka

06:52 Znalezione: Bandaż ×2, Nóż

07:41 Zabity: Szwędacz

**Statystyki (§13.1) mówią ile; dziennik mówi co.** Licznik odpowiada na „oddano 340 strzałów" i na żadne z pytań, które gracz naprawdę zadaje po spacerze: co wyszło z tej apteki, o której wróciłem, ile spałem, co mnie ugryzło.

Zasady:

| Zasada | Dlaczego |
| :---- | :---- |
| Wpis to **rodzaj + podmiot**, nigdy zdanie | id przedmiotu, rodzaj przeciwnika, nazwa sklepu z mapy. Słowa dokładane przy rysowaniu (§1.1) — inaczej zmiana języka zostawia pamiętnik do połowy po polsku |
| **Dzień = data z telefonu** | Gracz, który zaczął o 20:00, jest w DNIU 2, gdy rano wstaje — nie „jedenaście godzin w dniu 1" |
| **Od najnowszego**, w obie strony | Log na telefonie czyta się jak listę połączeń |
| To samo dwa razy w ciągu 2 minut = **jeden wpis** | Trzy strzały do tego samego szwędacza to jedna walka |
| Limit **400 wpisów** | Spacer pisze wpis co kilka minut, a passa ma trwać miesiącami (§13.1) |
| Ekran pokazuje **ostatnie 7 dni** | 400 wpisów to ile się *trzyma*; miesiąc na jednej liście to coś, do czego nikt nie doscrolluje |
| Praca zapisuje się **na starcie i na końcu** | Rozbiórka trwa pół godziny, moduł schronu — dni. Log, który zapisywał tylko ukończenie, nic nie mówił o wieczorze, w którym gracz je zaczął |
| Sięgnięcie po coś w nocy to **najpierw pobudka** | Symulacja zauważa dopiero na następnym ticku, więc bez tego log czyta się „sen, picie, pobudka" — kolejność, której nikt nie przeżył. Rzeczy dziejące się *bez* postaci (moduł na własnym zegarze §8.3, utrata przytomności, awans) nie budzą |
| Łup to **jedna linia z licznikami** | Przeszukanie sklepu potrafi dać kilkanaście rzeczy naraz |
| Łóżko i drzwi czytane **ze stanu**, nie z przycisku | W tej grze nie ma komendy „śpij" (§2.5.1) — dziennik, który czekałby na polecenie, nigdy nie zapisałby nocy |

Dziennik ma **własny ekran** (ikona obok imienia postaci w PROFILU) — log jest tym, co gracz otwiera po spacerze, a leżał sześć sekcji niżej.

⚠️ **DZIEŃ 1 to dzień, w którym passa się zaczęła** — postać z 7 pełnymi dniami jest w DNIU 8. Numer dnia stoi także przy passie w PROFILU, żeby dwa ekrany nie mówiły różnych liczb.

Co trafia do dziennika: przeszukanie i łup, otwarcie zamka, walka i zabicie, obrażenia, jedzenie/picie/opatrunek, sen i pobudka, lektura, budowa modułu, wytwarzanie i rozbiórka, wejście i wyjście ze schronu, awans umiejętności, utrata przytomności.

---

## 4. Przedmioty

### 4.1. Wspólny schemat danych

Wszystkie typy przedmiotów dzielą jeden schemat — inaczej każdy typ dostanie osobny, niekompatybilny kod.

{

  "id": "weapon_ak74",

  "type": "firearm",

  "name_key": "item.weapon_ak74.name",

  "weight_kg": 3.3,

  "volume_l": 4.2,

  "stackable": false,

  "condition": 100,

  "condition_decay_per_use": 0.05,

  "rarity": "uncommon",

  "loot_tags": ["military", "police"],

  "props": { }

}

Pole `props` zawiera dane specyficzne dla typu. Pliki: `weapons.json`, `food.json`, `literature.json`, `tools.json`, `armor.json`, `medical.json`, `crafting.json`.

⚠️ **Format:** JSON walidowany schematem przy buildzie. Dokumentację opisową trzymamy w `.md` obok.

**Pole `volume_l`** — sam ciężar nie wystarczy. Bez objętości gracz zmieści 30 kg puchowych kurtek w kieszeni. Plecak ma dwa limity: masę i pojemność.

**Dodane pole `progress_pages`** — dla literatury (§4.6.3). Książki nie są stackowalne; każdy egzemplarz to osobna instancja z własnym postępem czytania. Dodatkowo `title_id` do wykrywania powtórek tego samego tytułu.

**Dodane pole `condition`** — bronie i narzędzia powinny się zużywać, inaczej warsztat w schronie (moduł 2) nie ma żadnego zastosowania poza craftingiem.

### 4.2. Broń palna

Parametry: MOA, zasięgi, przeładowanie, tryby ognia, magazynek oraz:

`caliber` — bez tego amunicja jest uniwersalna i traci wartość jako zasób · `muzzle_energy_j` — potrzebne do modelu obrażeń z 2.6 · `recoil_moa` — rozrzut narastający przy ogniu ciągłym

**Realistyczne czasy przeładowania** (dla umiejętności 0%):

| Czynność | Czas |
| :---- | :---- |
| Wymiana magazynka (karabin) | 3.5 s |
| Wymiana magazynka (pistolet) | 3.0 s |
| Doładowanie luzem | 2.5 s / nabój |
| Przeładowanie strzelby (pump) | 1.2 s / nabój |

### 4.3. Broń biała

Zasięg wręcz, typ obrażeń (cięte / kłute / obuchowe), czas zamachu, wymagana siła. Typ obrażeń powinien wchodzić w interakcję z pancerzem: obuchowe ignorują 50% ochrony kamizelki, cięte są przez nią blokowane niemal całkowicie.

### 4.4. Odzież i pancerz

Dwie niezależne osie ochrony:

- **Termiczna:** `insulation_clo` — wchodzi do wzoru na pot (2.3)
- **Balistyczna/kinetyczna:** `protection_level` + `coverage_pct` — redukcja obrażeń z 2.6 tylko dla trafionej lokalizacji

Przykład: hełm ma coverage 12% (głowa), kamizelka 55% (tors). Trafienie w kończynę ignoruje oba.

### 4.5. Plecaki

Zwiększają `udźwig_maksymalny` i pojemność. Same mają wagę — plecak 65 l waży 1.8 kg.

### 4.6. Literatura 📐

📐 **Model czasu czytania:**

czas [min] = (liczba_stron × słów_na_stronę) / (tempo_bazowe × mnożnik_typu × (1 + wprawa_czytelnicza))

Tempo bazowe: 220 słów/min, ~280 słów na stronę.

| Typ | Strony | Mnożnik tempa | Czas | XP | XP/strona |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Ulotka | 1–4 | 1,3 | 2–8 min | 250 | ~83 |
| Czasopismo | 20–60 | 1,0 | 25–80 min | 1 200 | ~30 |
| Poradnik | 80–200 | 0,7 | 2,5–7 h | 4 500 | ~32 |
| Podręcznik techniczny | 150–400 | 0,45 | 7–25 h | 9 000 | ~33 |
| Encyklopedia | 400–900 | 0,4 | 20–60 h | 20 000 | ~31 |

⚠️ Wartości XP odnoszą się do krzywej z §7.2 (`70 × p`, suma 353 500).

#### 4.6.1. Przyrost ciągły — umiejętność rośnie w trakcie czytania

⚠️ **Nagroda dopiero po ukończeniu 40-godzinnej encyklopedii byłaby okrutna i nieczytelna.** Gracz musiałby przez wiele nocy inwestować czas bez żadnego sygnału zwrotnego.

**XP naliczane jest za każdą przeczytaną stronę**, proporcjonalnie do postępu:

XP_przyznane = XP_książki × (strony_przeczytane / strony_łącznie)

Przeczytana połowa poradnika wartego 4 500 XP daje 2 250 XP — dokładnie połowę. Gracz może przerwać w dowolnym momencie i zachować to, co już zdobył.

Granulacja: **jedna strona ≈ 76 sekund** przy tempie bazowym, więc informacja zwrotna pojawia się mniej więcej co minutę — wystarczająco często, by postęp był odczuwalny.

#### 4.6.2. Przyrost procentowy zależy od poziomu

Ponieważ koszt kolejnych poziomów rośnie (§7.2), **ta sama książka daje inny przyrost procentowy w zależności od aktualnego poziomu umiejętności:**

| Typ | 0% | 25% | 50% | 75% | 90% |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Ulotka | +2,2 | +0,1 | +0,1 | +0,0 | +0,0 |
| Czasopismo | +5,4 | +0,7 | +0,3 | +0,2 | +0,2 |
| Poradnik | +10,8 | +2,4 | +1,3 | +0,8 | +0,7 |
| Podręcznik | +15,5 | +4,6 | +2,5 | +1,7 | +1,4 |
| Encyklopedia | +23,4 | +9,4 | +5,4 | +3,7 | +3,1 |

⚠️ **Interfejs musi pokazywać wartość rzeczywistą, nie nominalną.** Karta książki wyświetla:

> *Podręcznik pierwszej pomocy — Medycyna* *Przy Twoim poziomie (52%): **+2,4%** za całość* *Przeczytano: 88 / 275 stron (32%) — zdobyto już +0,8%*

Podawanie stałego „+5%" niezależnie od poziomu wprowadzałoby gracza w błąd.

#### 4.6.3. Zabezpieczenia

**Powtórki tego samego tytułu** — bez tego gracz przeczesuje apteki po dziesiąty egzemplarz tego samego poradnika i maksuje Medycynę bez wysiłku:

| Egzemplarz | Wartość |
| :---- | :---- |
| Pierwszy | 100% |
| Drugi | **25%** |
| Trzeci i kolejne | **0%** — pozostaje wyłącznie masa do wyrzucenia lub recyklingu |

**Brak premii za ukończenie.** Przeczytanie dziesięciu książek po 10% daje tyle samo, co jednej w całości — świadomie, bo premia za domknięcie przywróciłaby problem „czekaj do końca". Naturalną zachętą do kończenia jest masa: dziesięć rozczytanych książek w plecaku waży więcej niż jedna przeczytana i wyrzucona.

**Książki przestają być przedmiotami stackowalnymi.** Każdy egzemplarz to osobna instancja z własnym polem `progress_pages` (§4.1). Rozczytana książka zachowuje postęp po odłożeniu do magazynu, wyrzuceniu i podniesieniu.

**Wpływ stanu postaci:** dług senny wydłuża czas czytania (§2.5.4), co obniża tempo zdobywania XP, ale nie zmienia sumy. Wprawa czytelnicza (§7.1) skraca czas do −25%.

⚠️ **Czytanie to zajęcie (§2.1a)** — wyklucza sen, budowę i wytwarzanie. Przy zimowych nocach dających ~8,6 h wolnego (§2.1a.2) encyklopedia to około pięciu nocy poświęconych wyłącznie lekturze. Latem, przy nocy krótszej niż zapotrzebowanie na sen, poważna lektura oznacza narastający dług senny.

#### 4.6.4. Losowa liczba stron

⚠️ **Każdy egzemplarz literatury ma losowaną liczbę stron.** Dwa podręczniki tego samego tytułu mogą mieć 180 i 340 stron — inaczej ważą, inaczej długo się je czyta i inaczej dużo dają.

strony = random(pages_min, pages_max) // przy generowaniu instancji

masa [g] = strony × g_na_stronę + masa_okładki

objętość [l] = strony × l_na_stronę + objętość_okładki

czas [min] = (strony × 280) / (220 × mnożnik_typu × (1 + wprawa))

XP = strony × XP_na_stronę

| Typ | Strony | g/str. | Okładka | l/str. | XP/str. | Masa skrajna | Czas skrajny |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Notatka (§19.1) | 1–3 | 1,0 | 0 | 0,0016 | **0** | 1–3 g | 5–20 s |
| Ulotka | 1–4 | 1,0 | 0 | 0,0016 | 80 | 1–4 g | 1–4 min |
| Czasopismo | 20–60 | 2,5 | 20 g | 0,0031 | 30 | 70–170 g | 25–76 min |
| Poradnik | 80–200 | 1,3 | 30 g | 0,0016 | 32 | 134–290 g | 2,4–6,1 h |
| Podręcznik | 150–400 | 1,5 | 80 g | 0,0016 | 33 | 305–680 g | 7,1–18,9 h |
| Encyklopedia | 400–900 | 1,8 | 400 g | 0,0022 | 31 | **1,12–2,02 kg** | **21–48 h** |

⚠️ **XP naliczane od strony, nie od tytułu.** Bez tego 400-stronicowy podręcznik dawałby tyle samo, co 150-stronicowy, przy trzykrotnie dłuższym czytaniu. Wartości XP/stronę są tak dobrane, że sumy zgadzają się z §7.2 (np. encyklopedia 650 stron ≈ 20 000 XP).

**Efekt uboczny, który warto zauważyć:** encyklopedia potrafi ważyć **2 kg** — czyli 8% udźwigu komfortowego. Decyzja „biorę tę książkę czy zostawiam" staje się realna, a wielkie tomy opłaca się czytać na miejscu albo wozić do schronu partiami.

### 4.7. Pozostałe kategorie

- **Narzędzia:** `craft_time_modifier`, `required_for` (lista receptur)
- **Craftingowe:** materiały ze zwłok i lootboxów
- **Użytkowe:** realistyczne czasy — kanapka 60–90 s, 500 ml wody 25 s, staza 45 s, opatrunek uciskowy 90 s, szycie rany 12–20 min

### 4.8. Porzucone przedmioty

Widoczne na mapie, znikają po 24 h. Limit 50 aktywnych znaczników — po przekroczeniu usuwane są najstarsze (ochrona przed zaśmieceniem bazy i mapy).

---

## 5. Walka

### 5.1. Model celności 📐

**MOA opisuje rozrzut kątowy, nie prawdopodobieństwo trafienia.**

⚠️ **Konwencja obowiązująca w całym dokumencie:** MOA opisuje **średnicę** grupy strzałów, nie promień. Broń „1 MOA" daje grupę o średnicy ~2,9 cm na 100 m. Pomylenie średnicy z promieniem zmienia szansę trafienia około trzykrotnie.

D_rozrzutu [m] = MOA_total × d × 2.9089e-4 // ŚREDNICA

σ = D_rozrzutu / 4 // extreme spread ≈ 4σ

P(trafienie) = [2Φ(W/2σ) − 1] × [2Φ(H/2σ) − 1]

gdzie Φ to dystrybuanta rozkładu normalnego, W × H — wymiary celu (tors 0,50 × 0,65 m; sylwetka 0,55 × 1,75 m).

**Składanie błędów (pierwiastek sumy kwadratów):**

MOA_total = √(MOA_broni² + MOA_umiejętności² + MOA_tętna²

              + MOA_ruchu_gracza² + MOA_ruchu_celu² + MOA_stanu²)

#### 5.1.1. Składniki błędu

**Broń i wprawa to drobiazg — dominującym źródłem błędu jest stan ciała strzelca.** Poniższe wartości to odzwierciedlają: strzelanie zależy od tego, co robi gracz, a nie od poziomu postaci.

| Źródło | Wartość MOA |
| :---- | :---- |
| Broń (mechaniczna) | 1–8 (z definicji przedmiotu) |
| Umiejętność 0% → 100% | **25 → 4** *(nawet wprawny strzelec stojąc bez podparcia nie schodzi poniżej ~4 MOA)* |
| **Tętno** 📐 | `60 × ((HR − HR_sp) / (HR_max − HR_sp))²` — **kwadratowo**, więc do 60% HR nieistotne, powyżej 85% dominujące |
| **Ruch gracza** 📐 | `8 × v^1.2` (v w km/h) — marsz 5 km/h = 55 MOA, bieg 12 km/h = 165 MOA |
| Ruch celu | `2 × v × 0.3` — przeciwnik biegnie **na** gracza, więc składowa boczna jest mała |
| Dług snu / utrata krwi | wg tabel §2.5 i §2.6 |

#### 5.1.2. Wyniki kalibracji (broń 3 MOA, cel: tors)

| Sytuacja | MOA | 30 m | 80 m | 150 m | 250 m |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Nowicjusz, **stoi**, spokojny, cel nieruchomy | 25 | 100% | 89% | 49% | 22% |
| Nowicjusz, **stoi**, HR 160, cel sprintuje | 45 | 99% | **53%** | 20% | 8% |
| Nowicjusz, **idzie** 5 km/h, HR 160 | 71 | 86% | **26%** | 8% | 3% |
| Nowicjusz, **biegnie** 12 km/h, HR 175 | 167 | 32% | **5%** | 2% | 1% |
| Wprawny (100%), **stoi**, HR 100 | 12 | 100% | 100% | 94% | 68% |
| Wprawny (100%), **stoi**, HR 160 | 37 | 100% | 65% | 27% | 11% |
| Wprawny (100%), **biegnie** 12 km/h | 165 | 32% | 5% | 2% | 1% |

⚠️ **Wniosek, który zmienia projekt:** przy realistycznych wartościach **spokojny, nieruchomy strzelec trafia niezawodnie** — i tak właśnie jest w rzeczywistości. Trudność nie bierze się z modelu balistycznego, tylko stąd, że **gra prawie nigdy nie daje warunków spokoju i bezruchu.** Coś zawsze biegnie w Twoją stronę.

To jest lepsze niż sztuczne zaniżanie celności: gracz nie walczy z generatorem liczb losowych, tylko z własnym tętnem i zegarem.

#### 5.1.3. Pułapka czasowa — dlaczego nie da się „poczekać, aż serce zwolni"

Stała czasowa powrotu tętna to ~90 s (§2.4). Zestawienie z prędkościami przeciwników (§6.1):

| Cel HR (start 170) | Czas | Dystans Szwędacza (16 km/h) | Dystans Skakuna (30 km/h) |
| :---- | :---- | :---- | :---- |
| 150 | 20 s | 89 m | 167 m |
| 130 | 46 s | 204 m | 383 m |
| 110 | 83 s | 367 m | 687 m |
| 100 | 108 s | 482 m | **903 m** |

**Nie da się uspokoić oddechu, gdy coś już biegnie.** Wypływają z tego trzy wnioski, które są sednem taktyki gry:

1. **Strzelaj, zanim się zmęczysz.** Podejście spacerem i strzał z dystansu bije bieganie i strzelanie na wyczerpaniu.
2. **Zasadzka jest najsilniejszą taktyką.** Dojście na pozycję, odpoczynek, potem wywabienie — jedyny sposób na strzał przy niskim tętnie.
3. **Ucieczka i walka wykluczają się nawzajem.** Ucieczka podnosi tętno do poziomu, przy którym walka przestaje być opłacalna.

#### 5.1.4. Jawna szansa trafienia w HUD

⚠️ **Wymóg obowiązkowy przy tak ostrym modelu.** Nad przyciskiem ognia wyświetlana jest **liczbowa szansa trafienia** (np. „26%") oraz największy aktualny składnik błędu („RUCH", „TĘTNO", „DYSTANS").

Bez tego gracz, który spudłuje pięć razy z rzędu przy 26%, uzna, że gra jest zepsuta. Z tym — podejmuje świadomą decyzję o wydaniu naboju. **Model może być bezlitosny dokładnie w takim stopniu, w jakim jest przejrzysty.**

#### 5.1.5. Model obrażeń 📐

⚠️ **Zależność musi być podpierwiastkowa, nie liniowa.** Ciężkość rany nie rośnie proporcjonalnie do energii pocisku — model liniowy zawsze karze małe kalibry i premiuje duże.

📐 **Model — zależność podpierwiastkowa plus współczynnik rany:**

ubytek [ml] = 5.1 × energia[J]^0.6 × wound_factor × mnożnik_lokalizacji × (1 − ochrona)

`wound_factor` odzwierciedla kanał rany niezależnie od energii: pociski karabinowe fragmentują i kawitują, śrut tworzy wiele kanałów, pociski pistoletowe przebijają na wylot.

| Kaliber | wound_factor | Energia | ml/tors |
| :---- | :---- | :---- | :---- |
| .22 LR | 0,70 | 160 J | 75 |
| 9×19 | 1,00 | 500 J | 212 |
| 5,45×39 | 1,25 | 1350 J | 482 |
| 7,62×39 | 1,20 | 2000 J | 585 |
| 12ga śrut | 1,25 | 2400 J | 680 |
| .308 / 7,62×54R | 1,35 | 3500 J | ~925 |
| 12ga brenneke | 1,50 | 3000 J | 933 |

**Wynikowa liczba trafień w tors:**

| Broń | Skakun (1080 ml) | Szwędacz (1530 ml) | Brutal (3500 ml) |
| :---- | :---- | :---- | :---- |
| Pistolet 9 mm | 5,1 | **7,2** | 16,5 |
| Pistolet maszynowy | 4,8 | 6,7 | 15,4 |
| Karabinek 5,45 | 2,2 | **3,2** | 7,3 |
| Karabinek 7,62×39 | 1,8 | 2,6 | 6,0 |
| Strzelba (śrut) | 1,6 | 2,2 | 5,1 |
| Karabin .308 | 1,2 | **1,7** | 3,8 |
| Wiatrówka .22 | 14,4 | 20,4 | 46,7 |

**Hierarchia broni jest teraz czytelna:** pistolet działa, ale zjada amunicję; karabinek to broń podstawowa; karabin myśliwski to narzędzie do Brutali. Broń krótka pozostaje ostatnią deską ratunku, a nie zamiennikiem karabinu — dokładnie jak zakładaliśmy w §5.6.3.

⚠️ Trafienie w głowę (×4,0, §2.6) eliminuje Szwędacza jednym pociskiem karabinowym, ale przy 12% szansy trafienia w głowę (§2.6) to premia za szczęście, nie taktyka.

**Wynikowa ekonomia amunicji:**

| Sytuacja | Naboje na jednego Szwędacza | % magazynka (30) |
| :---- | :---- | :---- |
| Nowicjusz stoi, 30 m | 4,0 | 13% |
| Nowicjusz stoi, HR 160, 80 m | **7,6** | 25% |
| Nowicjusz w marszu, 80 m | **15,4** | 51% |
| Wprawny stoi, HR 160, 80 m | 6,1 | 20% |

⚠️ Grupa 4 Szwędaczy to dla nowicjusza **~30 naboi, czyli cały magazynek.** Amunicja jest wąskim gardłem dokładnie tak, jak zakładaliśmy.

### 5.2. Dystanse zaangażowania

Dokładność GPS to 5–15 m. Oznacza to, że **walka na dystansie poniżej 30 m jest niesterowalna** — pozycje obu stron mają większy błąd niż dystans.

Wnioski:

- Minimalny dystans wykrycia przeciwnika: 150 m
- Optymalny dystans walki dystansowej: 50–250 m
- Poniżej 20 m → automatyczne przejście do trybu wręcz (abstrakcyjny, nie GPS-owy)

### 5.3. Interfejs walki

Przycisk ognia, przeładowania, licznik amunicji w magazynku i w plecaku, wskaźnik rozrzutu (rozszerzający się okrąg — czytelna wizualizacja `R_rozrzutu`), dystans do celu.

**Wskaźnik stabilizacji:** okrąg zwęża się w ciągu 2–4 s po zatrzymaniu (czas zależny od tętna). To główna pętla decyzyjna walki dystansowej.

### 5.4. Walka wręcz

P(trafienie) = 0.65 + 0.30 × umiejętność − 0.25 × (obciążenie / udźwig_max)

                − kara_za_zmęczenie

Czas zamachu: 0.8–2.2 s zależnie od broni. Przeciwnik atakuje równolegle — wymiana ciosów rozstrzygana turowo co 1 s. ❓ Czy walka wręcz ma mieć element zręcznościowy (timing tapnięcia), czy pozostaje w pełni obliczeniowa? Rekomendacja: obliczeniowa w MVP.

### 5.5. Walka z wieloma przeciwnikami

Szwędacze występują w grupach 2–4, więc walka z kilkoma przeciwnikami naraz jest domyślnym stanem gry, nie przypadkiem szczególnym.

#### 5.5.1. Namierzanie

**Zasada: jeden aktywny cel dla broni palnej.** Tapnięcie znacznika przeciwnika ustawia go jako aktywny cel. HUD pokazuje jego typ, dystans i szacowany stan (zdrowy / ranny / krytyczny — dokładność szacunku rośnie z umiejętnością Zwiad).

📐 **Koszt przełączenia celu** — odzyskanie obrazu celowniczego:

czas_przełączenia = 1.2 s × (1 − 0.30 × Obsługa_Broni)

0% → 1.2 s, 100% → 0.85 s.

W trakcie przełączania okrąg rozrzutu jest maksymalny (`MOA_total × 2.5`), następnie zwęża się normalnie wg 5.3.

⚠️ **Brak automatycznego przełączenia po śmierci celu.** Dostępny jest przycisk „najbliższe zagrożenie", ale kosztuje ten sam czas. To świadoma decyzja: automatyka zniosłaby całe napięcie walki grupowej i zamieniła ją w klikanie.

Przeciwnicy nienamierzeni działają w pełni normalnie — biegną i atakują. Namierzenie jednego nie zatrzymuje reszty.

#### 5.5.2. HUD walki grupowej

- Licznik zaangażowanych przeciwników
- Dystans do najbliższego (kolor: > 100 m zielony, 30–100 m żółty, < 30 m czerwony)
- **Wskaźnik budżetu sprintu każdego widocznego przeciwnika** — kluczowa informacja taktyczna (patrz 6.1). Gracz musi widzieć, kto jeszcze może sprintować, a kto już się wypalił.
- Strzałki na krawędzi ekranu dla wrogów poza widokiem mapy

#### 5.5.3. Oskrzydlenie (walka wręcz)

| Wrogów w zasięgu wręcz | Mnożnik szansy trafienia gracza |
| :---- | :---- |
| 1 | ×1.00 |
| 2 | ×1.30 |
| 3 | ×1.55 |
| 4+ | ×1.75 |

Gracz atakuje wyłącznie aktywny cel; pozostali atakują bez ograniczeń. To sprawia, że dopuszczenie grupy do zwarcia jest praktycznie wyrokiem — i o to chodzi.

#### 5.5.4. Przerwanie przeładowania

Zbliżenie się przeciwnika na < 5 m w trakcie przeładowania przerywa je i powoduje upuszczenie magazynka (podniesienie z ziemi: 3 s).

| Przeciwnik | Szansa przerwania |
| :---- | :---- |
| Brutal | 100% |
| Skakun | 70% |
| Szwędacz | 45% |

Obsługa Broni redukuje szansę o maks. 30 punktów procentowych.

#### 5.5.5. Pętla taktyczna — sedno walki grupowej

1. Grupa wykrywa gracza → wszyscy sprintują w jego stronę
2. Gracz musi zdecydować, kogo eliminuje pierwszego — a każda sekunda celowania to metry pokonane przez pozostałych
3. Budżety sprintu się wyczerpują → otwiera się okno na przeładowanie, wycofanie albo dobicie wyczerpanych
4. Gracz łamie kontakt lub kończy walkę

**Czas jest tu głównym zasobem, nie amunicja.** To odróżnia tę walkę od strzelanki.

📐 **Kontrola kosztu amunicji:** magazynek 30 naboi, średnio 3–6 trafień na eliminację Szwędacza, przy skuteczności ~40% na dystansie 80 m → starcie z pełną grupą 4 Szwędaczy zużywa ok. 1,5 magazynka. Walka ma być kosztowna.

#### 5.5.6. Limity techniczne

- Maks. **8 aktywnych przeciwników** w symulacji w promieniu 300 m (wydajność + grywalność)
- Powyżej limitu nowi przeciwnicy nie dołączają do walki — czekają na krawędzi zasięgu
- Wyjątek: wydarzenie Hordy (6.5.5) podnosi limit do 12

### 5.6. Hałas i przyciąganie przeciwników

Strzał to nie tylko wydatek amunicji — to sygnał dla wszystkiego w okolicy. Ten system domyka ekonomię walki i tworzy realny wybór między bronią palną a białą.

#### 5.6.1. Promienie hałasu

| Czynność | Promień [m] |
| :---- | :---- |
| Marsz | 15 |
| Bieg | 40 |
| Walka wręcz | 25 |
| **Strzelba** | **900** |
| **Karabin** | **700** |
| **Pistolet** | **450** |
| Pistolet z tłumikiem | 120 |
| Karabin z tłumikiem | 200 |
| Rozbicie szyby / wyważenie drzwi | 150 |
| Budowa schronu (młotek) | 100 |

📐 **Modyfikatory otoczenia:**

promień_efektywny = promień_bazowy × mod_pory_doby × mod_zabudowy

| Modyfikator | Wartość |
| :---- | :---- |
| Noc (po zachodzie słońca) | **×1.3** — mniej hałasu tła, inwersja temperaturowa |
| Dzień w gęstej zabudowie | ×0.7 — tłumienie i maskowanie |
| Teren otwarty | ×1.2 |
| Deszcz / silny wiatr | ×0.75 |

Godziny wschodu i zachodu liczone z daty i współrzędnych — dane dostępne offline, bez API.

#### 5.6.2. Reakcja przeciwników

Kluczowa zasada: **przeciwnicy idą do miejsca, w którym powstał dźwięk — nie do gracza.** To pozostawia przestrzeń na taktykę: strzał, przemieszczenie, obserwacja.

| Odległość od źródła | Reakcja |
| :---- | :---- |
| < ⅓ promienia | **POŚCIG** — lokalizują gracza bezpośrednio |
| ⅓ – 1 promienia | **CZUJNOŚĆ** — marsz do punktu hałasu, przeszukiwanie ~60 s |
| > promienia | brak reakcji |

Reakcja obejmuje wyłącznie przeciwników w stanie SPOCZYNEK lub POWRÓT — będący już w pościgu nie zmieniają celu.

⚠️ **Ograniczenie liczbowe:** na jedno zdarzenie hałasu reaguje maksymalnie **6 przeciwników**, wybieranych od najbliższego. Bez tego strzał w pobliżu ogniska poziomu 10 ściągnąłby dwunastu naraz i zamienił każdą pomyłkę w wyrok.

**Kumulacja:** kolejne strzały w ciągu 30 s nie mnożą reakcji, ale **odświeżają punkt hałasu** i przedłużają przeszukiwanie. Seria ogniem ciągłym = jedno zdarzenie o promieniu ×1.15, nie pięć zdarzeń.

#### 5.6.3. Konsekwencje projektowe

System nadaje wagę decyzjom, które wcześniej były oczywiste:

| Wybór | Zysk | Koszt |
| :---- | :---- | :---- |
| **Broń palna** | eliminacja z dystansu, wysoka szansa trafienia na spokojnie | ściąga wszystko w promieniu 700 m; zużywa rzadką amunicję |
| **Broń biała** | cisza (25 m), zero kosztu amunicji | wymaga zwarcia, czyli oskrzydlenia (§5.5.3) i ryzyka krwawienia |
| **Unikanie** | zerowy koszt | ognisko rośnie dalej |

**Tłumik jako przedmiot docelowy.** Rzadki loot z komisariatów i obiektów wojskowych, redukujący promień hałasu ~3,5×. Naturalny cel długoterminowy — nie kolejny procent do statystyki, tylko zmiana sposobu grania.

**Neutralizacja ogniska (§6.5.4) staje się problemem hałasu, nie tylko amunicji.** Strzelanie wewnątrz ogniska ściąga jego własnych mieszkańców. Wywabianie przeciwników poza promień (za 50% punktów) zyskuje trzeci wymiar: jest wolniejsze, ale ciche.

#### 5.6.4. Sprzężenie z audio (§14)

Hałas jest jednocześnie sygnałem dla gracza. Ten sam model obsługuje oba kierunki:

- **Kroki i wokalizacje przeciwników** słyszalne kierunkowo do 80 m — gracz wie o zagrożeniu, zanim je zobaczy
- **Strzał** wywołuje przytłumienie miksu (symulacja czasowego przytępienia słuchu) na 2–3 s
- W trakcie przytłumienia gracz **nie słyszy zbliżających się przeciwników** — realistyczna i dotkliwa kara za strzelanie bez ochronników słuchu

#### 5.6.5. Wizualizacja

Po strzale na mapie rozchodzi się okrąg fali (animacja ~1,5 s) o promieniu efektywnym — gracz od razu widzi, co obudził. Znaczniki zaalarmowanych przeciwników zmieniają kolor na pomarańczowy.

❓ **Do rozstrzygnięcia w testach terenowych:** czy 700 m dla karabinu nie jest zbyt karzące w gęstej zabudowie z trzema ogniskami w promieniu 2 km. Wartość wyjściowa do weryfikacji.

---

## 6. Przeciwnicy

### 6.1. Balans prędkości — budżet sprintu

⚠️ **Problem fundamentalny:** prędkość gracza jest równa jego realnej prędkości, więc każdy przeciwnik szybszy od ~12 km/h (dla przeciętnego gracza bliżej 9 km/h) byłby niemożliwy do ucieczki. Bez zabezpieczenia ucieczka — podstawowa opcja taktyczna w survivalu — przestaje istnieć.

**Rozwiązanie: wysokie prędkości przeciwników zostają, ale są ograniczone budżetem sprintu.**

| Przeciwnik | Chód | Bieg | Budżet sprintu | Regeneracja |
| :---- | :---- | :---- | :---- | :---- |
| Skakun | 5–7 km/h | 27–32 km/h | 25 s | 60 s przy 4 km/h |
| Szwędacz | 3–4 km/h | 15–18 km/h | 90 s | 45 s przy 3 km/h |
| Brutal | 2–4 km/h | 12–17 km/h | 45 s | 120 s przy 2 km/h |

To zachowuje grozę („coś biegnie na mnie 30 km/h"), ale daje graczowi realne narzędzie: przetrwać sprint i wykorzystać przewagę wytrzymałościową człowieka. Jest to zgodne z fizjologią — sprinterzy nie utrzymują prędkości maksymalnej dłużej niż 20–30 s.

⚠️ **Konsekwencja balansowa do przypilnowania:** Skakun w 25 s sprintu pokonuje ~200 m. Oznacza to, że wykrycie z dystansu 120 m (jego zasięg detekcji) zawsze kończy się dotarciem do gracza. Skakun **zawsze** doprowadzi do zwarcia — jedyną obroną jest wyeliminowanie go w locie albo przetrwanie zwarcia. To jest jego rola projektowa i jest poprawna, ale trzeba mieć świadomość, że przed Skakunem nie ma ucieczki. Uciekać można przed Szwędaczami i Brutalem.

### 6.1a. Maszyna stanów przeciwnika

| Stan | Warunek wejścia | Zachowanie |
| :---- | :---- | :---- |
| **SPOCZYNEK** | domyślny | ruch losowy w obrębie ogniska, prędkość chodu |
| **CZUJNOŚĆ** | gracz w zasięgu wykrycia (6.2) | marsz w stronę gracza, **bez** zużycia budżetu sprintu |
| **POŚCIG** | gracz w zasięgu < 60% zasięgu wykrycia lub oddano strzał | **sprint w stronę gracza**, zużycie budżetu |
| **WYCZERPANIE** | budżet sprintu = 0 | ruch 40% prędkości biegu, dalej w stronę gracza, regeneracja budżetu |
| **POWRÓT** | utrata kontaktu lub przekroczenie smyczy | marsz do centrum ogniska, pełna regeneracja |

⚠️ **Kluczowe:** w stanach POŚCIG i WYCZERPANIE przeciwnik **nie zatrzymuje się** — cały czas skraca dystans. Walka nigdy nie jest statyczna. Gracz strzelający do jednego wroga jednocześnie traci dystans do wszystkich pozostałych.

**Smycz (leash):** maks. 400 m od krawędzi ogniska. Po przekroczeniu → POWRÓT. **Utrata kontaktu:** 45 s bez zbliżenia gracza na < 150 m → POWRÓT.

Bez tych dwóch reguł gracz zebrałby za sobą „pociąg" przeciwników ciągnący się przez pół miasta.

### 6.2. Parametry przeciwników

| | Skakun | Szwędacz | Brutal |
| :---- | :---- | :---- | :---- |
| Występowanie | pojedynczo | grupy 2–4 | pojedynczo |
| Objętość krwi | 2400–2800 ml | 3200–3600 ml | 6000–8000 ml |
| Mnożnik ataku | 0.9 | 1.05 | 1.2 |
| Obrażenia bazowe | 120 ml | 180 ml | 400 ml |
| Efekt specjalny | częste, słabe ataki (co 1.2 s) | szansa 35% na krwawienie | szansa 25% na ogłuszenie (3 s) + krwawienie silne |
| Zasięg wykrycia gracza | 120 m | 80 m | 60 m |
| Próg śmierci | 45% utraty krwi | 45% | 50% |

⚠️ **Mnożnik ataku odnosi się do wiersza obrażeń bazowych w ml** — bez tej bazy jest niepoliczalny.

### 6.3. Poruszanie się przeciwników

Przeciwnik na realnej mapie poruszający się po linii prostej przechodzi przez ściany budynków i rzeki. Opcje:

- **Uproszczenie (MVP):** ruch po linii prostej, akceptujemy przenikanie — gracz i tak widzi tylko znacznik na mapie
- **Docelowo:** routing po grafie dróg OSM (pakiet `valhalla` offline lub własny A* na wyeksportowanych `highway=footway|path|residential`)

### 6.4. Zasady spawnu

- Przeciwnicy pojawiają się **wyłącznie w ogniskach** (6.5) oraz jako rzadki spawn tłowy
- Spawn tłowy poza ogniskami: 0–2 przeciwników na km² (tylko Szwędacze, pojedynczo)
- Nigdy bliżej niż 150 m od gracza (bez „wyskakiwania" pod nogami)
- Nigdy w strefach wykluczonych (3.5)
- Nigdy w promieniu 200 m od schronu

---

## 6.5. System ognisk — główny mechanizm presji

Ognisko (skażenia) to trwały punkt na mapie generujący przeciwników. Ogniska rosną w czasie i stanowią zegar, który odmierza trudność rozgrywki. To bezpośrednia realizacja celu „przetrwać jak najdłużej" — im dłużej trwa gra, tym większa presja.

### 6.5.1. Zasady rozmieszczenia

| Parametr | Wartość |
| :---- | :---- |
| Maks. liczba aktywnych ognisk | **3** |
| Punkt odniesienia | schron gracza (przed jego budową: punkt startu pierwszej sesji) |
| Min. dystans od schronu | **500 m** |
| Maks. dystans od schronu | **2000 m** |
| Min. odległość między centrami ognisk | **450 m** |
| Maks. promień ogniska | **200 m** |

⚠️ **Uzasadnienie minimalnej odległości między ogniskami:** przy maksymalnym promieniu 200 m dwa ogniska oddalone o 450 m mają 50 m odstępu między krawędziami i nigdy się nie nakładają. Bez tej reguły dwa ogniska poziomu 10 mogłyby utworzyć nieprzechodni obszar o średnicy 800 m.

📐 **Geometria kontrolna:** ognisko przy minimalnym dystansie 500 m, urosłe do promienia 200 m, ma krawędź 300 m od schronu — a strefa bezpieczna schronu to 50 m (8.1). Zachowany jest bufor 250 m. Geometria się domyka.

**Wybór centrum:** losowy punkt spełniający powyższe warunki, leżący poza strefami wykluczonymi (3.5), z preferencją dla terenów `landuse=industrial|commercial|retail|brownfield` oraz obszarów o wysokiej gęstości `building=*`. Centrum jest **stałe** przez całe życie ogniska.

### 6.5.2. Poziomy 📐

promień(poziom 1) = 20 m

przy każdym awansie: promień += random(14, 26) m

twardy limit: 200 m przy poziomie 10

| Poziom | Promień (śr.) | Wrogów jednocześnie | Respawn | Skład |
| :---- | :---- | :---- | :---- | :---- |
| 1 | 20 m | 1 | 15 min | Szwędacz |
| 2 | 40 m | 2 | 13 min | Szwędacz |
| 3 | 60 m | 3 | 12 min | Szwędacz |
| 4 | 80 m | 4 | 10 min | Szwędacz, Skakun 20% |
| 5 | 100 m | 5 | 9 min | Szwędacz, Skakun 30% |
| 6 | 120 m | 6 | 8 min | Szwędacz, Skakun 35% |
| 7 | 140 m | 8 | 6 min | + Brutal 10% |
| 8 | 160 m | 9 | 5 min | + Brutal 15% |
| 9 | 180 m | 11 | 4 min | + Brutal 20% |
| 10 | 200 m | 12 | 3 min | pełny skład + **wydarzenia Hordy** |

Szwędacze spawnują się grupami 2–4 (zgodnie z 6.2), co przy poziomie 7+ oznacza realnie 2–3 grupy plus pojedyncze silne jednostki.

### 6.5.3. Wzrost ognisk 📐

interwał_awansu = max(2h, 8h − 0.25h × dzień_przetrwania) × random(0.6, 1.4)

- Dzień 1: awans średnio co ~8 h
- Dzień 12: co ~5 h
- Dzień 24 i dalej: co 2 h (podłoga)

**Naliczanie czasu:** 100% czasu w stanie AKTYWNYM + **25%** czasu w stanie UŚPIONYM (2.1). Świat psuje się także, gdy gracz nie gra — ale wolniej, więc tygodniowa przerwa nie oznacza automatycznie zastania trzech ognisk poziomu 10.

**Powiadomienie push przy awansie**, z nazwą ulicy pobraną z OSM: *„Ognisko przy ul. Naramowickiej urosło do poziomu 6."* Jednocześnie mechanika i haczyk retencyjny.

### 6.5.4. Neutralizacja ognisk 📐

📐 **Integralność:**

Integralność_max(poziom) = 60 + 20 × poziom

Poziom 1 → 80 pkt, poziom 10 → 260 pkt.

**Punkty za eliminację przeciwnika w promieniu ogniska:**

| Przeciwnik | Punkty |
| :---- | :---- |
| Szwędacz | 10 |
| Skakun | 15 |
| Brutal | 35 |

Eliminacja przeciwnika należącego do ogniska, ale **poza** jego promieniem: **50% wartości**. Wabienie wrogów poza strefę jest bezpieczniejsze, ale dwukrotnie wolniejsze — świadomy kompromis dla gracza.

**Regeneracja integralności:** +5% wartości maksymalnej na godzinę. Przerwanie operacji i powrót nazajutrz jest możliwe, ale kosztowne.

#### Zbicie poziomu — mechanika „wzburzenia"

Po zbiciu integralności do zera:

1. Ognisko traci jeden poziom, promień kurczy się do wartości poprzedniego poziomu
2. Integralność ustawiana na 100% **nowego, niższego** poziomu
3. Ognisko wchodzi w stan **WZBURZENIA** na 10 minut:

| Efekt wzburzenia | Wartość |
| :---- | :---- |
| Tempo respawnu | ×3 |
| Limit jednoczesnych wrogów | +50% |
| Skład | przesunięty o szczebel w górę (Szwędacz → Skakun, Skakun → Brutal) |
| Zasięg wykrycia gracza | +50% |

To jest realizacja zasady „zmniejszanie ogniska powoduje pojawianie się większej ilości przeciwników". **Zbicie ogniska z poziomu 10 do zera wymaga przejścia przez 10 kolejnych wzburzeń** — to operacja na kilka godzin, wymagająca zaplecza amunicyjnego i medycznego, prowadzona przy narastającym oporze.

⚠️ **Ryzyko projektowe do przetestowania:** wzburzenie ma być trudne, ale nie ma tworzyć spirali śmierci, z której nie ma wyjścia. Sugerowany zawór bezpieczeństwa: wzburzenie **nie odnawia się**, jeśli gracz oddali się na > 400 m od centrum — wycofanie musi zawsze pozostać opcją.

#### Likwidacja (poziom 0)

- Ognisko znika; w jego centrum pojawia się jednorazowy **skład** — loot o jakości ~3× lepszej niż zwykły lootbox, z gwarantowaną literaturą lub bronią
- Slot pozostaje pusty przez **24–48 h** realnego czasu (nagroda: oddech)
- Po tym czasie nowe ognisko pojawia się w innej lokalizacji, na poziomie 1

### 6.5.5. Wydarzenie: Horda (poziom 10)

Ognisko na poziomie 10 co 6–12 h wysyła hordę: **6–10 przeciwników poruszających się grupą w stronę schronu gracza.**

- Horda nie może wejść w strefę bezpieczną (50 m), ale okrąża ją i pozostaje **30–60 min**
- W tym czasie gracz jest odcięty — wyjście po zapasy oznacza walkę z całą grupą
- Jeśli gracz przebywa poza schronem, horda kieruje się do jego aktualnej pozycji
- Ostrzeżenie: powiadomienie na 10 min przed dotarciem („Słyszysz je od strony wschodniej")

To domyka pętlę celu gry: im dłużej przetrwasz, tym szybciej rosną ogniska i tym częstsze są hordy. Presji nie da się uniknąć — jedyne pytanie brzmi, jak długo dasz radę ją utrzymywać w ryzach.

❓ **Do rozważenia:** czy horda może uszkodzić schron (utrata poziomu modułu, konieczność naprawy)? Podniosłoby to stawkę i dało warsztatowi (8.4) realne zastosowanie, ale zwiększa złożoność. Rekomendacja: poza MVP.

### 6.5.6. Wizualizacja na mapie

- Okrąg o promieniu ogniska, wypełnienie ~15% krycia, wyraźna obwódka
- Kolor wg poziomu: **1–3 żółty · 4–6 pomarańczowy · 7–9 czerwony · 10 ciemnoczerwony, pulsujący**
- Stan WZBURZENIA: animowana, migocząca obwódka
- Tapnięcie ogniska → panel: poziom, pasek integralności, przewidywany skład, czas do następnego awansu
- Horda: strzałka na krawędzi ekranu + znacznik grupy w ruchu

### 6.5.7. Gracz poza obszarem ognisk ❓

Gracz przebywający w pracy lub w podróży, > 5 km od schronu, jest całkowicie poza zagrożeniem — pozostaje mu tylko spawn tłowy.

Opcje: (a) zaakceptować to jako naturalny „czas wolny", (b) dodać tymczasowe **ognisko polowe** poziomu 1–3 po godzinie przebywania w oddaleniu, znikające po powrocie gracza.

Rekomendacja: (b), ale poza MVP. Wariant (a) jest bezpieczniejszy dla równowagi życia gracza z grą — a gra, która wymaga czujności 24/7, szybko przestaje być grą.

---

## 7. Umiejętności

Cztery umiejętności, zakres 0–100%, maksymalny efekt +30%.

| Umiejętność | Efekt przy 100% |
| :---- | :---- |
| **Zwiad** | −30% szansy na wykrycie, +30% jakości lootu, **+100% promienia przeszukania terenu** (§10.2) |
| **Obsługa broni** | −30% czasu przeładowania, −30% czasu stabilizacji, MOA_umiejętności 12→2 |
| **Medycyna** | −30% czasu użycia medykamentów, +30% skuteczności opatrunków |
| **Inżynieria** | −30% czasu budowy i craftingu |

### 7.1. Rozdzielenie tempa czytania

Tempo czytania jest osobnym modyfikatorem, rosnącym z ogólnej liczby przeczytanych stron („wprawa czytelnicza", max −25% czasu). Umiejętność Medycyna wpływa wyłącznie na medykamenty — czytanie encyklopedii broni nie może zależeć od wiedzy medycznej.

### 7.2. Model progresji

📐 **Krzywa — liniowo rosnący koszt:**

XP_do_poziomu(p) = 70 × p // p = 1..100

XP_łączne do 100% = 353 500

Poziom 1 kosztuje 70 XP, poziom 100 — 7 000 XP. Stosunek 100:1 daje wyraźną, ale nie zaporową progresję.

#### 7.2.1. Źródła doświadczenia

| Źródło | XP | Uwagi |
| :---- | :---- | :---- |
| **Literatura** | 250 – 20 000 | główna ścieżka, patrz §4.6 |
| Strzał oddany | 1 | Obsługa Broni |
| Eliminacja przeciwnika | 15 | Obsługa Broni |
| Opatrunek założony | 25 | Medycyna |
| Przedmiot wytworzony | 30 | Inżynieria |
| Moduł zbudowany | 400 | Inżynieria |
| Przeszukanie terenu | 8 | Zwiad |
| Loot podniesiony | 3 | Zwiad |

⚠️ **Praktyka nie może być główną ścieżką** — 353 500 XP przy 15 XP za eliminację to 23 500 zabitych przeciwników. Praktyka ma uzupełniać i nagradzać styl gry, nie zastępować literatury.

#### 7.2.2. Czas do maksimum

Mieszanką podręczników: **~509 godzin czytania** na jedną umiejętność, czyli około **59 zimowych nocy** po 8,6 h wolnego czasu (§2.1a.2) — i to bez budowania czegokolwiek w tym czasie.

To realizuje założenie z §13.1: **maksymalny poziom umiejętności ma być mitem, nie punktem docelowym.** Wymaksowanie wszystkich czterech umiejętności jest praktycznie nieosiągalne, a wybór, którą rozwijać, staje się prawdziwą decyzją strategiczną.

---

## 8. Schron

### 8.1. Strefy

- Strefa bezpieczna: **50 m** — przeciwnicy nie wchodzą
- Blokada ataku gracza: **50 m** (ten sam promień)

⚠️ **Oba promienie muszą być równe.** Przy różnych wartościach powstaje pierścień, w którym przeciwnik może atakować gracza, a gracz nie może się bronić — co wprost karze przebywanie pod schronem.

Efekt: brak kempienia ze schronu i brak ostrzeliwania przeciwników z bezpiecznej pozycji, bez luki. Przeciwnicy czekają przy granicy strefy — gracz musi wyjść, żeby walczyć, ale nie jest bezbronny.

### 8.2. Lokalizacja

Schron powstaje w aktualnej pozycji gracza — czyli w praktyce najczęściej w jego **mieszkaniu**.

Konsekwencje do obsłużenia:

- **Prywatność:** współrzędne domu zapisane lokalnie. Nigdy nie wysyłane, nieszyfrowane dane w kopii zapasowej Androida to ryzyko → wyłączyć `allowBackup` dla tego rekordu albo szyfrować.
- **Sensowność fabularna:** „zabarykadowanie opuszczonego budynku" w salonie własnego mieszkania. ❓ Rozważyć wymóg, by schron powstał na obiekcie z OSM o tagu `building=yes` **oraz** w odległości > 200 m od punktu, w którym gracz spędza noce (heurystyka „domu"). Realizm vs wygoda — do decyzji.
- ❓ Czy schron można przenieść? Rekomendacja: tak, ale z utratą 50% zainwestowanych surowców i pełnym czasem odbudowy.

### 8.3. Czas budowy podstawowej 📐

Realistyczna kalkulacja barykadowania opuszczonego budynku przez jedną osobę:

| Czynność | Czas |
| :---- | :---- |
| Zabezpieczenie drzwi (deski, gwoździe) | 35 min |
| Zabarykadowanie okna × 4 | 4 × 25 min = 100 min |
| Uprzątnięcie i zabezpieczenie wnętrza | 45 min |
| **Razem** | **~3 h** |

Z narzędziami (młotek + siekiera): −35%. Z Inżynierią 100%: −30%. Minimum osiągalne: **~1 h 20 min**.

⚠️ Budowa musi działać w tle z zapisem postępu i powiadomieniem po ukończeniu — 3 h wpatrywania się w pasek postępu to nie jest rozgrywka.

### 8.4. Moduły

| Moduł | Poziomy | Efekt / poziom | Efekt max |
| :---- | :---- | :---- | :---- |
| Magazyn | 3 | +50 kg | 150 kg |
| Warsztat | 3 | ⚠️ patrz niżej | — |
| Salon | 3 | +15% tempa regeneracji ze snu | +45% |
| Laboratorium | 3 | +3% skuteczności posiłków i napojów | +9% |

⚠️ **Warsztat jest niezbalansowany.** 3% na poziom (max 9%) to nagroda nieproporcjonalna do kosztu trzech poziomów rozbudowy — gracz nigdy tego nie zbuduje.

**Propozycja przebudowy warsztatu:**

| Poziom | Efekt |
| :---- | :---- |
| 1 | Odblokowuje naprawę przedmiotów (do 60% kondycji) + −10% czasu craftingu |
| 2 | Naprawa do 85% + odblokowuje receptury złożone (amunicja, modyfikacje broni) + −20% |
| 3 | Naprawa do 100% + −30% czasu |

Wartością warsztatu powinien być **dostęp do możliwości**, nie procentowa oszczędność czasu.

### 8.5. Obóz — baza wypadowa

Schron główny jest jeden i stoi tam, gdzie gracz mieszka. Ale gracz spędza osiem godzin dziennie gdzie indziej — w pracy, na uczelni, u rodziny. **Obóz to lekka, tania placówka, którą stawia się w tych miejscach.**

To rozwiązuje trzy problemy naraz: skalę czasu offline (§2.1), tempo gry dla pracującego dorosłego (§16.4) i brak sensownej rozgrywki w godzinach pracy.

#### 8.5.1. Parametry

| Cecha | Obóz | Schron główny |
| :---- | :---- | :---- |
| Strefa bezpieczna | **20 m** | 50 m |
| Blokada ataku gracza | 20 m | 50 m |
| Metabolizm (§2.1) | 50% / 55% | 35% / 40% |
| Magazyn | **prosta skrzynia, +30 kg**, bez rozbudowy | 25 kg bazowo + moduł do 150 kg |
| Moduły | **brak** | 4 moduły × 3 poziomy |
| Sen | możliwy, **jakość 70%** | 100% |
| Wytwarzanie | tylko receptury podstawowe | pełne, z premią warsztatu |
| Czas budowy | **~40 min** | ~3 h |
| Odrodzenie po utracie przytomności | **nie** — zawsze w miejscu upadku (§9.2.1) | nie dotyczy |

#### 8.5.2. Zasady rozmieszczenia

| Parametr | Wartość |
| :---- | :---- |
| Maksymalna liczba obozów | **2** |
| Min. odległość od schronu głównego | 800 m |
| Min. odległość między obozami | 800 m |
| Min. odległość od centrum ogniska | 400 m |
| Przeniesienie | swobodne, ale z utratą 100% materiałów i zawartości skrzyni |

⚠️ **Obóz nie blokuje powstawania ognisk** (w przeciwieństwie do schronu, §6.5.1). Ogniska i tak zakotwiczone są wokół schronu głównego, więc obóz przy pracy oddalonej o kilka kilometrów leży zwykle poza strefą zagrożenia — ale gdy gracz mieszka i pracuje blisko siebie, obóz może znaleźć się w zasięgu. To świadomie zostawione ryzyko.

**Wygasanie:** obóz nieodwiedzony przez **14 dni** zaczyna się rozpadać (komunikat), a po **21 dniach** znika wraz z zawartością skrzyni. Zapobiega zaśmiecaniu mapy porzuconymi placówkami i wymusza świadomy wybór dwóch lokalizacji.

#### 8.5.3. Dlaczego to jest dobra mechanika, a nie ułatwienie

Obóz **nie zmniejsza presji** — ogniska rosną niezależnie od tego, gdzie przebywa gracz (§6.5.3). Zmienia tylko to, że godziny pracy przestają być karą.

**Najważniejszy efekt: droga z pracy do domu staje się główną pętlą rozgrywki.** Wychodzisz z obozu wypoczęty, ale z pustym plecakiem. Przed Tobą kilka kilometrów przez teren, na którym stoją ogniska. Po drodze zbierasz loot, unikasz lub eliminujesz przeciwników, wracasz do schronu.

To jest dokładnie ten rodzaj rozgrywki, na jaki pracujący dorosły ma czas — i wpisuje się w rytm, który i tak istnieje w jego dniu.

**Obóz stawiamy na ziemi.** Gra nie odczytuje wysokości nad poziomem terenu — GPS podaje wysokość niepewnie w budynkach, a barometr nie jest dostępny na wszystkich urządzeniach. Ograniczenie jest więc fikcyjne, nie techniczne: obóz opisujemy jako stawiany na poziomie gruntu i nie sprawdzamy tego. Gracz stawiający obóz na piątym piętrze łamie fikcję wyłącznie wobec siebie.

---

## 9. Śmierć — tryby rozgrywki

Tryb wybierany jednorazowo przy tworzeniu postaci. ⚠️ **Wybór jest nieodwracalny** — możliwość przełączenia unieważniłaby rekordy w Hardcore.

| | HARDCORE | SOFTCORE |
| :---- | :---- | :---- |
| Śmierć | koniec postaci, konieczność stworzenia nowej | utrata przytomności, gra trwa dalej |
| Umiejętności | przepadają | zachowane w całości |
| Schron | przepada, trzeba zbudować nowy | zachowany |
| Ogniska | reset do poziomu 1 | bez zmian — rosną dalej |
| Passa przetrwania | ostateczna, trafia do Kroniki | zerowana, postać gra dalej |
| Ekwipunek noszony | przepada wraz z postacią | patrz 9.2 |
| Magazyn schronu | przepada | **nietknięty** |

### 9.1. Tryb HARDCORE

Śmierć = koniec. Postać trafia do Kroniki (13.1) wraz z pełnym zrzutem stanu: dzień przetrwania, poziomy ognisk, umiejętności, przyczyna śmierci, lokalizacja.

**Nowa postać zachowuje parametry fizjologiczne** (wzrost, waga, wiek, płeć) — to przecież nadal to samo ciało gracza. Zmienia się wyłącznie nazwa. Nie ma potrzeby przechodzenia całego kreatora od nowa.

⚠️ **Zabezpieczenia obowiązkowe w tym trybie.** Permadeath z powodu awarii technicznej to gwarantowana jedna gwiazdka w sklepie:

- Śmierć **nie może** nastąpić w stanie UŚPIONYM (2.1) — utrata krwi w tle zatrzymuje się na 5% objętości
- Śmierć **nie może** nastąpić przy braku sygnału GPS (3.2) — symulacja jest wtedy wstrzymana
- Poniżej 30% objętości krwi: nachalne ostrzeżenia wizualne, dźwiękowe i haptyczne
- Poniżej 20%: pełnoekranowe ostrzeżenie z jawną informacją „to jest tryb Hardcore, następne trafienie może zakończyć postać"

### 9.2. Tryb SOFTCORE — utrata przytomności zamiast śmierci

W Softcore postać nie umiera, tylko traci przytomność w miejscu, w którym padła. Budzi się **tam samo**, po 60 minutach realnego czasu.

| Element | Wartość |
| :---- | :---- |
| Miejsce przebudzenia | dokładnie miejsce upadku (brak teleportacji) |
| Czas nieprzytomności | 60 min realnego czasu |
| Objętość krwi po przebudzeniu | 25% maksymalnej (klasa III wstrząsu) |
| Woda i kalorie | 15% |
| Broń trzymana w rękach | przepada zawsze |
| Pozostały ekwipunek noszony | 50% (losowo) przepada; reszta rozrzucona w 2–3 skrytkach w promieniu 30–100 m, widoczne na mapie przez 48 h |
| Magazyn schronu | **nietknięty** |
| Umiejętności | **bez strat** |
| Passa przetrwania | zerowana |

**Okno łaski:** przez pierwsze 10 minut po przebudzeniu przeciwnicy ignorują gracza („uznały cię za martwego"). Gracz nie może w tym czasie atakować. To zawór bezpieczeństwa przeciwko pętli śmierci przy przebudzeniu wewnątrz ogniska poziomu 8. ⚠️ Okno aktywuje się **warunkowo** — tylko jeśli w chwili przebudzenia w promieniu 300 m znajdują się przeciwnicy. Nie ma sensu chronić gracza, który ocknął się w autobusie.

#### 9.2.1. Przemieszczenie gracza w czasie nieprzytomności

Problem: nieprzytomność trwa 60 minut, a gracz w tym czasie może realnie się przemieścić — wsiąść do autobusu, pojechać samochodem, wrócić do domu. Postać miałaby leżeć w miejscu upadku, ale gracz jest już 15 km dalej.

**Zasada nadrzędna: postać zawsze budzi się tam, gdzie fizycznie znajduje się gracz.** Rozjazd między pozycją postaci a pozycją gracza jest niedopuszczalny w żadnym stanie gry — to fundament całego projektu (§0).

**Fikcja:** majaczenie. Przy 25% objętości krwi (klasa III wstrząsu, §2.6) występują zaburzenia świadomości — postać nie pamięta, jak znalazła się w miejscu przebudzenia. Fabuła jest tu darmowa i medycznie poprawna.

⚠️ **Kluczowe: skrytki z ekwipunkiem zostają w miejscu upadku.** Dzięki temu mechanika balansuje się sama — kara rośnie wraz z dystansem, bez żadnych sztucznych reguł:

| Dystans miejsca przebudzenia od miejsca upadku | Efekt |
| :---- | :---- |
| < 300 m | „doczołgałeś się" — okno łaski aktywne, skrytki w zasięgu |
| 300 m – 3 km | majaczenie — skrytki daleko, ale wyprawa po nie ma sens |
| > 3 km | skrytki praktycznie stracone (48 h na powrót) |

**Brak exploitu w obie strony:**

- Celowa śmierć jako „darmowy transport do domu" kosztuje cały noszony ekwipunek i passę przetrwania
- Oddalenie się nie chroni sprzętu, tylko go oddala

**Przebudzenie w pojeździe:** jeśli w chwili upływu 60 minut gracz porusza się szybciej niż 15 km/h lub sygnał GPS jest nieprawidłowy (§3.2, §3.4), stan nieprzytomności trwa dalej — bezkarnie, bez dalszej utraty zasobów — do momentu wejścia w prawidłowy stan gry. To nie jest kara, tylko odroczenie.

**Odliczanie 60 minut** biegnie w czasie zegarowym, niezależnie od tego, czy aplikacja jest otwarta (to jedyny wyjątek od reguły obecności z §2.1a — nieprzytomność jest stanem biernym i nie może wymagać wpatrywania się w ekran).

**Dlaczego akurat tak:**

1. **Brak teleportacji** — nie łamiemy fundamentu gry. W grze GPS-owej teleportacja jest pojęciowo zepsuta.
2. **Kara jest rozgrywką, a nie liczbą.** Budzisz się bez broni, z 25% krwi, w środku ogniska, które właśnie cię zabiło. Powrót do domu **jest** karą — i jednocześnie najbardziej pamiętnym fragmentem rozgrywki.
3. **Odzyskanie sprzętu jest możliwe, ale ryzykowne.** Skrytki leżą 30–100 m dalej, w strefie zagrożenia, a masz 10 minut nietykalności. Decyzja: uciekać czy zbierać?
4. **Nie blokuje grania** — nie wymaga fizycznej podróży w żadne konkretne miejsce.
5. **Nadaje sens modułowi Magazyn** (8.4). Magazyn w schronie to jedyne miejsce odporne na śmierć. Trzymanie zapasowej broni w domu przestaje być zapobiegliwością, a staje się koniecznością.
6. **Fabularnie czyste** — model fizjologiczny (2.6) i tak przewiduje utratę przytomności przy klasie IV wstrząsu. Softcore po prostu zatrzymuje się o krok wcześniej niż Hardcore.

⚠️ **Utrata przytomności nie kasuje XP.** Fikcja „zapominasz, jak się strzela, bo zemdlałeś" jest słaba, a utrata sprzętu plus wyzerowana passa to wystarczająca stawka.

### 9.3. Konflikt celu gry z modelem śmierci — rozwiązanie

Skoro celem jest przetrwać jak najdłużej (13.1), a w Softcore śmierć nie kończy rozgrywki, licznik dni traciłby sens — można byłoby mdleć w nieskończoność, a wynik i tak by rósł.

**Rozwiązanie — dwa niezależne liczniki:**

| Licznik | Zachowanie przy śmierci |
| :---- | :---- |
| **Passa przetrwania** (główny wynik) | **zerowana w obu trybach** |
| Łączny czas gry postaci | zachowany (Softcore) / archiwizowany (Hardcore) |

Śmierć w Softcore nie kasuje postaci ani umiejętności — kasuje **osiągnięcie**. Gracz zachowuje wszystko, na co pracował, ale traci to, o co grał.

**Rekordy z obu trybów prowadzone są w osobnych tabelach.** Zestawianie passy hardcore'owej z softcore'ową nie miałoby sensu — to dwie różne gry.

---

## 10. Loot i ekonomia

**Tabele lootu powiązane z tagami POI z OpenStreetMap:**

| Tag OSM | Typ miejsca | Dominujący loot |
| :---- | :---- | :---- |
| `amenity=pharmacy` | apteka | medykamenty, literatura medyczna |
| `shop=doityourself`, `shop=hardware` | market budowlany | narzędzia, materiały craftingowe |
| `shop=supermarket`, `shop=convenience` | sklep spożywczy | jedzenie, woda |
| `shop=sports`, `shop=outdoor` | sklep sportowy | plecaki, odzież, noże |
| `shop=weapons`, `amenity=police` | broń | broń palna, amunicja, kamizelki |
| `amenity=library`, `shop=books` | biblioteka | literatura wszelkiego typu |
| `building=industrial` | zakład | metal, narzędzia, paliwo |

To jest, moim zdaniem, najmocniejszy niewykorzystany atut projektu: **gracz uczy się realnej mapy swojego miasta przez pryzmat przetrwania.** Wie, gdzie jest najbliższa apteka, bo tam znalazł opatrunki.

- Respawn lootboxa: 4–8 h
- Gęstość: max 1 lootbox na POI, max 15 aktywnych w promieniu 2 km
- Jakość lootu skalowana umiejętnością Zwiad i rzadkością POI

### 10.1. Zapasowa warstwa lootu proceduralnego

Bez tej warstwy gra działa wyłącznie w dużych miastach. W miejscowości poniżej ~15 tys. mieszkańców opisanych wyżej POI praktycznie nie ma — a to wyklucza większość potencjalnych graczy.

📐 **Wyzwalacz:**

gęstość_POI = liczba lootowalnych POI w promieniu 2 km od schronu

if gęstość_POI < 8:

    tryb_zapasowy = ON

    liczba_punktów_zastępczych = 12 − gęstość_POI

Ocena wykonywana przy zakładaniu schronu i ponownie co 7 dni (dane OSM mogą się zmienić, gracz może przenieść schron).

**Źródła punktów zastępczych — obiekty obecne wszędzie:**

| Tag OSM | Punkt w grze | Dominujący loot |
| :---- | :---- | :---- |
| `highway=*` + `parking` | porzucony samochód | narzędzia, paliwo, apteczka samochodowa |
| `building=house`, `building=detached` | opuszczony dom |
| `building=barn`, `building=farm_auxiliary` | stodoła |
| `building=garage*` | garaż | narzędzia, metal, paliwo |
| `amenity=waste_disposal`, `recycling` | śmietnik | materiały craftingowe, rzadko jedzenie |
| `amenity=shelter`, `tourism=picnic_site` | wiata | drewno, materiał |
| `amenity=hunting_stand` | ambona myśliwska | **amunicja** (rzadko), nóż |
| `man_made=water_tower`, `amenity=drinking_water` | ujęcie wody | woda |

⚠️ **Kalibracja jakości:** punkty zastępcze dają loot o wartości **~55% POI właściwych** i nie mogą zawierać broni palnej ani literatury zaawansowanej. Inaczej gracz miejski byłby karany za mieszkanie w mieście.

**Rekompensata dla terenów rzadkich:** przy trybie zapasowym respawn skraca się z 4–8 h do **3–5 h**, a promień poszukiwań rośnie z 2 do 3 km. Mniej wartościowych punktów, ale częściej odnawianych — gracz wiejski nadrabia dystansem, który i tak pokonuje.

❓ Do weryfikacji w terenie: czy `amenity=hunting_stand` jako źródło amunicji nie jest zbyt hojne w regionach leśnych.

⚠️ **Uwaga o jakości danych OSM:** pokrycie tagami różni się drastycznie między regionami. Gra musi degradować się łagodnie — przy skrajnie ubogich danych ostatnią warstwą są punkty generowane wzdłuż `highway=*` w stałych odstępach, bez powiązania z obiektem.

### 10.2. Przeszukanie terenu

Mechanika rozpoznania — jedyny sposób na poznanie stanu okolicy przed wejściem w nią.

#### 10.2.1. Zasada działania

⚠️ **Bez cooldownu.** Kosztem jest czas i bezruch, nie zegar. Odliczanie, które nic nie kosztuje, nie jest decyzją — jest budzikiem uczącym gracza patrzeć w ekran zamiast iść, co stoi w sprzeczności z §0 i §3.5.

| Parametr | Wartość |
| :---- | :---- |
| Czas trwania | **45 s** |
| Warunek | bezruch (przemieszczenie > 8 m przerywa i anuluje) |
| Koszt zasobów | brak |
| Powtórzenie w tym samym miejscu | dozwolone, ale **nie daje nowych informacji przez 10 min** |

Samoograniczenie jest naturalne: 45 sekund bezruchu to ~60 m niepokonanego dystansu i realne ryzyko, jeśli coś już się zbliża.

#### 10.2.2. Promień 📐

promień = 100 m

        × (1 + 1.0 × Zwiad) // 0% → 100 m, 100% → 200 m

        × mod_lornetki // 1.0 lub 1.5

        × (1 − 0.5 × D) // ciemność, §17.4

        × mod_pogody // mgła 0.6, opady 0.8

| Konfiguracja | Promień w dzień |
| :---- | :---- |
| Zwiad 0%, bez lornetki | 100 m |
| Zwiad 100%, bez lornetki | 200 m |
| Zwiad 0%, lornetka | 150 m |
| **Zwiad 100%, lornetka** | **300 m** |
| Zwiad 100%, lornetka, noc zimowa (D≈0.8) | 180 m |

⚠️ **Rozłożenie progresji jest celowe.** Skok 100 → 300 m z samej lornetki oznaczałby dziewięciokrotny wzrost przeszukiwanej powierzchni z jednego przedmiotu — gra przed jej znalezieniem wydawałaby się zepsuta. Tak rozłożone, ten sam sufit osiąga się stopniowo, a Zwiad zyskuje trzeci konkretny efekt.

#### 10.2.3. Co odsłania — a czego nie

Zasada: **przeszukanie ujawnia stan i rzeczy niewidoczne, nie samo istnienie obiektów.**

| Element | Widoczność |
| :---- | :---- |
| **POI z OSM** (apteka, market, biblioteka) | **zawsze widoczne**, szary znacznik = stan nieznany |
| Stan POI (loot dostępny / wybrany) | tylko po przeszukaniu |
| **Punkty proceduralne** (§10.1 — wraki, śmietniki, stodoły) | **wyłącznie po przeszukaniu** |
| **Przeciwnicy w promieniu** | tylko po przeszukaniu; typ jednostki wyłącznie z lornetką |
| Krawędź ogniska | zawsze widoczna (§6.5.6) |
| Skrytki po utracie przytomności (§9.2.1) | zawsze widoczne |

**Aptekę widać z ulicy — to budynek.** Ukrywanie POI do czasu przeszukania zamieniłoby grę w obsługę minimapy zamiast patrzenia na miasto. Ukrywamy tylko to, czego faktycznie nie widać z dystansu.

#### 10.2.4. Rozpoznanie ważniejsze od zbieractwa

Najcenniejszą funkcją jest ujawnianie przeciwników, nie lootu. Przed wejściem w teren ogniska gracz może stanąć, poświęcić 45 sekund i dowiedzieć się, w co wchodzi — ilu ich jest, gdzie stoją, a z lornetką również czy wśród nich jest Brutal.

To sprzęga się z §5.5 (walka grupowa), §5.6 (decyzja o użyciu broni palnej) i §14 (dźwięk kierunkowy jako uzupełnienie informacji).

**Lornetka** — nowy przedmiot. Loot z `shop=outdoor`, `shop=sports`, obiektów wojskowych, ambon myśliwskich. Masa 0,6 kg. Poza promieniem przeszukania pozwala identyfikować typ przeciwnika na dystansie bez przeszukania.

#### 10.2.5. Wynikowa pętla

1. Marsz w stronę wybranego POI
2. Zatrzymanie na skraju rejonu, przeszukanie (45 s)
3. Decyzja: wejść, obejść, wycofać się
4. Ewentualne przeszukanie ponowne po przemieszczeniu

⚠️ Przeszukanie podlega regule obecności (§2.1a) — tyka wyłącznie przy uruchomionej aplikacji i prawidłowym sygnale GPS.

### 10.3. Zawartość: przedmioty i tabele dropu

Pliki: **`items.json`** (89 przedmiotów) i **`loot_tables.json`** (20 tabel: 11 POI z OSM + 9 punktów proceduralnych z §10.1).

#### 10.3.1. Weryfikacja modelu obrażeń

Trafienia w tors, cel bez pancerza, model z §5.1.5, wobec progów krwi z §6.2:

| Broń | Energia | ml/trafienie | Skakun | Szwędacz | Brutal |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Karabinek .22 LR | 160 J | 75 | 14,4 | **20,4** | 46,7 |
| Rewolwer .38 | 420 J | 191 | 5,6 | 8,0 | 18,3 |
| Pistolet 9 mm | 500 J | 212 | 5,1 | **7,2** | 16,5 |
| PM 9 mm | 560 J | 227 | 4,8 | 6,7 | 15,4 |
| Karabin 5,45×39 | 1350 J | 482 | 2,2 | **3,2** | 7,3 |
| Karabin 7,62×39 | 2000 J | 585 | 1,8 | 2,6 | 6,0 |
| Strzelba (śrut) | 2400 J | 680 | 1,6 | 2,2 | 5,1 |
| Strzelba (breneka) | 3000 J | 933 | 1,2 | 1,6 | 3,8 |
| Mosin 7,62×54R | 3600 J | 937 | 1,2 | 1,6 | **3,7** |

⚠️ **Wniosek 1 — broń krótka jest bronią ostateczności, ale nie jest już bezużyteczna.** Siedem trafień na Szwędacza to niecały magazynek pistoletu — trudne, ale wykonalne. Szesnaście na Brutala oznacza, że pistoletem da się go zabić, tylko bardzo kosztowo. To zgodne z rzeczywistością i nadal wypycha gracza w stronę broni długiej lub białej, bez sprowadzania pistoletu do rekwizytu.

⚠️ **Wniosek 2 — .22 LR to nisza, nie broń.** Dwadzieścia trafień czynią ją nieopłacalną w walce, ale ma **250 m hałasu wobec 700 m karabinu** (§5.6.1). Zostaje bronią do cichego dobijania i eliminacji pojedynczych celów bez budzenia dzielnicy.

#### 10.3.2. Broń biała jako realna alternatywa

| Broń | ml/cios | Zamach | Szwędacz | Czas zwarcia |
| :---- | :---- | :---- | :---- | :---- |
| Pięści | 45 | 0,8 s | 34 | **27 s — wyrok** |
| Nóż | 180 | 0,9 s | 9 | 8 s |
| Maczeta | 310 | 1,3 s | 5 | **6,5 s** |
| Siekiera | 430 | 1,9 s | 4 | 7,6 s |
| Łom | 330 | 1,7 s | 5 | 8,5 s |

Maczeta i siekiera domykają zamysł z §5.6.3: walka wręcz jest cicha (25–30 m) i darmowa, ale wymaga 6–8 sekund w zwarciu, w których przeciwnik też uderza.

⚠️ **Wniosek 3 — broń palna staje się obowiązkowa od 7. poziomu ogniska.** Brutal wymaga 9 uderzeń siekierą, czyli 17 sekund zwarcia, w których zdąży zadać 8–10 ciosów po 400 ml. Gracz ma ~5300 ml i ginie przy utracie 40%. **Wręcz na Brutala to śmierć.** Brutale pojawiają się od poziomu 7 (§6.5.2) — to naturalna bramka progresji, ale trzeba pilnować, żeby do tego czasu gracz miał realną szansę znaleźć broń długą, inaczej ogniska stają się nieprzechodnie.

#### 10.3.3. Ekonomia amunicji

Grupa 4 Szwędaczy karabinkiem 5,45 (3,2 trafienia/szt. przy 100% skuteczności) to **~13 pocisków w idealnych warunkach**. Przy realistycznej skuteczności z §5.1.2 (stojący nowicjusz, HR podniesione, ~53% na 80 m) wychodzi **~24 naboje**, czyli 80% magazynka na 30 sztuk — spójne z szacunkiem z §5.1.5.

Symulacja 400 przeszukań obiektu wojskowego (głębokie, Zwiad 50%): średnio **15,8 naboi 5,45 na przeszukanie**, czyli **~1,5 przeszukania na jedną grupę Szwędaczy**, przy respawnie co 14–24 h. Amunicja pozostaje wąskim gardłem zgodnie z założeniem.

Amunicja karabinowa występuje wyłącznie w obiektach wojskowych, sklepach myśliwskich i na ambonach. Komisariaty dają niemal wyłącznie 9 mm — dużo amunicji do słabszej broni, co przy modelu obrażeń z §5.1.5 ma sens, bo pistolet jest kosztowny, ale użyteczny.

#### 10.3.4. Kontrola udźwigu

Pełne wyposażenie bojowe (karabin 5,45 + 60 naboi + maczeta + odzież zimowa + hełm + 1,5 l wody + 2 konserwy + 3 batony + apteczka + staza + multitool + latarka + lornetka + plecak trekkingowy):

**14,8 kg i 30,2 l** przy limitach 36 kg i 65 l.

Zostaje ~21 kg i ~35 l na loot i surowce — co przy 731 kg pełnej rozbudowy (§18.2) daje ok. 35 kursów. Zgodne z wcześniejszym szacunkiem.

⚠️ Plecak trekkingowy podnosi udźwig komfortowy z 24 do 36 kg, czyli **skraca liczbę kursów o jedną trzecią.** Znalezienie dobrego plecaka jest realnym przełomem w rozgrywce, a nie kosmetyką.

#### 10.3.5. Głębokość przeszukania

Zgodnie z §19.3 — trzy poziomy sterujące jakością:

| Głębokość | Czas | Losowania | Dostępne tiery | Mnożnik rzadkich |
| :---- | :---- | :---- | :---- | :---- |
| Pobieżne | 30 s | 1–2 | common | ×0 |
| Dokładne | 90 s | 2–4 | common, uncommon | ×1 |
| Gruntowne | 180 s | 3–5 | wszystkie | ×2 |

Zwiad podnosi wagę pozycji rzadkich o `1 + 0,30 × poziom`. Punkty proceduralne (§10.1) mają wagi rzadkie ×0,55 i **wykluczoną broń palną oraz literaturę zaawansowaną** — gracz miejski nie może być karany za mieszkanie w mieście.

---

## 11. Architektura techniczna

| Warstwa | Rozwiązanie |
| :---- | :---- |
| Framework | Flutter 3.x, Dart 3 |
| Mapa | MapLibre GL Native + PMTiles (Protomaps) |
| Baza lokalna | Drift (SQLite) — stan gry, `isar` alternatywnie |
| Definicje przedmiotów | JSON w assets, walidowane schematem przy buildzie |
| Lokalizacja | `flutter_localizations` + ARB |
| GPS | `geolocator` + foreground service (`flutter_foreground_task`) |
| Dane zdrowotne | **brak** — świadoma decyzja (§2.5) |
| Pogoda | Open-Meteo (darmowe, bez klucza API) ⚠️ *jedyne odstępstwo od „brak serwerów" — to zewnętrzne API, nie nasz serwer; wymaga cache'owania i graceful degradation przy braku sieci* |
| Symulacja | Silnik tickowy 1 Hz w izolacie, z catch-upem po wznowieniu |
| RNG | Deterministyczny, seed zapisany w profilu (powtarzalność debugowania) |

### 11.1. Trwałość zapisu i migracje

W trybie Hardcore awaria zapisu kasuje dziesiątki godzin. Rozwiązanie opiera się na trzech niezależnych warstwach: **transakcyjności, kopii rotacyjnej i migracji addytywnych.**

#### 11.1.1. Podział stanu wg częstotliwości zapisu

Zapisywanie całego stanu co tick (1 Hz) zajedzie pamięć flash i baterię. Rozdzielamy dane:

| Warstwa | Zawartość | Zapis |
| :---- | :---- | :---- |
| **Gorąca** | pozycja, krew, woda, kalorie, tętno, `last_update` | co **60 s** oraz przy każdym przejściu aplikacji w tło |
| **Ciepła** | ekwipunek, umiejętności, schron, ogniska | **przy każdej zmianie** (transakcja) |
| **Zimna** | Kronika, rekordy, ustawienia | przy zdarzeniu (śmierć, koniec passy) |

⚠️ **Maksymalna strata przy awarii: 60 sekund warstwy gorącej.** To akceptowalne — gracz cofa się o minutę fizjologii, nie o godziny progresji.

#### 11.1.2. Atomowość

- SQLite w trybie **WAL**, każdy zapis w transakcji — przerwanie procesu w trakcie zapisu cofa transakcję, baza nigdy nie zostaje w stanie pośrednim
- **Checkpoint WAL** wymuszany przy przejściu aplikacji w tło i przy `onDestroy` foreground service
- Wszystkie ticki **idempotentne** — przeliczenie oparte o `last_update`, nie o licznik przyrostowy. Powtórzenie ticka po odzyskaniu daje ten sam wynik.

**Zasada nadrzędna dla Hardcore: awaria techniczna nigdy nie może zabić postaci.** Skoro stan wraca do ostatniego zatwierdzonego punktu, a ticki są idempotentne, crash cofa gracza do stanu sprzed śmierci, a nie do śmierci. Śmierć zapisywana jest jako osobne, jawne zdarzenie po pełnym przeliczeniu.

#### 11.1.3. Kopia rotacyjna

- **3 migawki** pełnego stanu, tworzone co 30 min gry i przed każdą migracją schematu
- Każda z **sumą kontrolną**; przy starcie weryfikacja bazy głównej
- Baza uszkodzona → automatyczne odtworzenie z najnowszej poprawnej migawki + komunikat dla gracza z informacją, ile czasu utracono
- Migawki w katalogu prywatnym aplikacji, **wyłączone z automatycznej kopii Androida** (`allowBackup=false` dla tego katalogu — patrz §8.2, prywatność lokalizacji schronu)

#### 11.1.4. Migracje schematu ⚠️ — najczęstsza przyczyna utraty zapisów

Bez planu migracji **pierwsza aktualizacja aplikacji skasuje wszystkim postacie.**

Zasady obowiązkowe:

1. **Migracje wyłącznie addytywne** — dodawanie kolumn i tabel. Nigdy nie usuwamy ani nie zmieniamy nazw; kolumna nieużywana zostaje w schemacie oznaczona jako przestarzała.
2. **Numer wersji schematu** w bazie; każdy krok migracji osobno, wykonywany sekwencyjnie.
3. **Migawka przed migracją** — obowiązkowo, z możliwością wycofania.
4. **Testy migracji w CI** — Drift generuje pliki schematu, które commitujemy; test przechodzi ścieżkę v1→v2→v3 na wygenerowanych danych. Test migracji jest tak samo obowiązkowy jak test logiki.
5. **Definicje przedmiotów wersjonowane osobno** — `id` przedmiotu nigdy nie zmienia znaczenia. Przedmiot usunięty z gry zostaje w słowniku jako `deprecated`, żeby stary ekwipunek dał się wczytać.

#### 11.1.5. Zabicie procesu przez Android

Foreground service bywa ubijany mimo powiadomienia (agresywne oszczędzanie energii u niektórych producentów — Xiaomi, Huawei, Samsung).

- Zapis warstwy gorącej przy każdym `onPause`
- Po restarcie: catch-up tick z `last_update` (§2.1) — brak dziury w symulacji
- Wykrycie powtarzającego się ubijania → jednorazowa podpowiedź o wyłączeniu optymalizacji baterii dla aplikacji, z odnośnikiem do ustawień systemowych

### 11.2. Tryb deweloperski — must have, od pierwszego dnia

Nie da się iterować nad grą GPS-ową, przechodząc kilka kilometrów przy każdym buildzie. Tryb dostępny wyłącznie w buildach debug, wycinany z release'u flagą kompilacji.

| Narzędzie | Zakres |
| :---- | :---- |
| **Symulator GPS** | odtwarzanie tras GPX z regulowaną prędkością; sterowanie pozycją strzałkami; skoki do zadanych współrzędnych |
| **Przyspieszenie czasu** | ×1 / ×60 / ×3600 — dobę gry da się przejść w 24 s |
| **Panel fizjologii** | wymuszanie tętna, poziomu krwi, wody, kalorii, długu snu |
| **Panel świata** | spawn dowolnego przeciwnika, ustawienie poziomu ogniska, wyzwolenie hordy, wzburzenia |
| **Nakładka diagnostyczna** | MOA_total z rozbiciem na składniki, szansa trafienia, promień hałasu, stany maszyny przeciwników |
| **Powtórki** | zapis sesji (seed + strumień zdarzeń) i deterministyczne odtworzenie — kluczowe przy zgłoszeniach błędów |
| **Zestawy testowe** | jednym przyciskiem: „pełne wyposażenie", „stan krytyczny", „3 ogniska poziomu 10" |

⚠️ Symulator GPS musi wstrzykiwać dane **przez tę samą warstwę** co prawdziwy GPS, razem z symulacją błędu pozycji i utraty sygnału (§3.2). Testowanie na idealnych danych zamaskuje wszystkie problemy, które wystąpią w terenie.

### 11.3. Kopia zapasowa

Brak serwerów = utrata telefonu oznacza utratę setek godzin gry. Konieczny **eksport/import profilu do pliku JSON** (opcjonalnie na Dysk Google użytkownika). Bez tego pierwsza wymiana telefonu kończy przygodę gracza z grą.

---

## 12. Dostępność

Gra oparta na realnym ruchu wyklucza osoby z ograniczoną mobilnością — to nie jest neutralna decyzja i warto ją podjąć świadomie.

❓ **Do rozstrzygnięcia:** czy wprowadzić tryb alternatywny (np. przeliczanie ruchu z wózka, obniżone progi dystansu, tryb stacjonarny oparty na czasie zamiast na dystansie)? Nie jest to wymóg MVP, ale odcięcie tej grupy bez refleksji byłoby stratą.

Minimum na start: obsługa czytników ekranu w menu, tryb wysokiego kontrastu, skalowanie czcionek, wibracje jako alternatywa dla sygnałów dźwiękowych.

---

## 13. Lista otwartych decyzji ❓

| # | Decyzja | Blokuje | Kiedy potrzebna |
| :---- | :---- | :---- | :---- |
| 1 | Ograniczenia lokalizacji schronu (§8.2) | prywatność i fabułę | przed etapem schronu |
| 2 | Tryb dostępności (§12) | zakres grupy docelowej | przed publikacją |
| 3 | Zawór bezpieczeństwa wzburzenia — czy 400 m wystarczy (§6.5.4) | balans neutralizacji | testy terenowe |
| 4 | Promień hałasu karabinu w gęstej zabudowie (§5.6.5) | balans walki | testy terenowe |
| 5 | Model dystrybucji: darmowa / płatna jednorazowo | nic w kodzie | dzień publikacji |
| 6 | Uprawa lub hodowla żywności w schronie (§18.7) | głębię zimy (§17.6) | po MVP |
| 7 | Walka wręcz: zręcznościowa czy obliczeniowa (§5.4) | zakres UI walki | po MVP |
| 8 | Ognisko polowe dla gracza w oddaleniu (§6.5.7) | rozgrywkę poza domem | po MVP |

**Rozstrzygnięcia wiążące, których nie otwieramy ponownie:**

- **Brak zakupów wewnętrznych.** Nie wdrażamy Google Play Billing, nie ma waluty premium ani skrótów za pieniądze. Architektura stanu upraszcza się (brak serwera weryfikacji zakupów), a projekt pozostaje spójny z filarem z §0.
- **Brak danych zdrowotnych.** Żadnej integracji z Health Connect ani czujnikami (§2.5).
- **Brak serwerów gry.** Jedyne zewnętrzne API to Open-Meteo (§17.3), z cache i łagodną degradacją.
- ⚠️ Decyzja 5 nie wpływa na kod. Płatność jednorazowa to ustawienie w Play Console, nie funkcja aplikacji.

### 13.1. Cel gry: przetrwanie

**Celem gry jest przetrwać jak najdłużej.** Nie ma zakończenia ani warunku zwycięstwa — jest tylko presja, która narasta szybciej, niż gracz jest w stanie się rozwijać.

**Struktura celu:**

- **Główna metryka:** passa przetrwania w dniach (9.1)
- **Zegar trudności:** wzrost ognisk przyspiesza z każdym dniem, od ~8 h na poziom w dniu pierwszym do 2 h w dniu 24 (6.5.3)
- **Punkt przełamania:** trzy ogniska poziomu 10 generują hordy co 6–12 h każde. Statystycznie oznacza to oblężenie mniej więcej co 3 godziny — stan nie do utrzymania w nieskończoność
- **Napięcie strategiczne:** czy inwestować czas w rozbudowę schronu i naukę (rośnie potencjał, rosną też ogniska), czy w bieżące zbijanie ognisk (kupujesz czas, ale nie rozwijasz się)

To jest jedyne prawdziwe pytanie taktyczne gry i wszystko powinno mu służyć.

**Konsekwencje dla pozostałych systemów:**

| System | Wymagane dostosowanie |
| :---- | :---- |
| Krzywa umiejętności (§7.2) | 353 500 XP do maksimum (~509 h czytania) musi pozostać nieosiągalne w typowej passie — maksymalny poziom ma być mitem, nie punktem docelowym |
| Loot (10) | Amunicja i medykamenty jako wąskie gardło — to one określają, ile ognisk gracz może zaatakować |
| Schron (8) | Rozbudowa modułów kosztuje czas, w którym ogniska rosną. To ma być bolesny wybór, nie oczywisty |
| Statystyki | Ekran „Kronika" z historią wszystkich passy: dzień, przyczyna śmierci, stan ognisk, zdobyte umiejętności |

❓ **Do rozważenia po MVP:** sezony (co kwartał reset globalny + nowy modyfikator świata, np. „ostra zima" — podwyższone zapotrzebowanie kaloryczne). Daje powód do powrotu graczom, którzy uznali swoją passę za zamkniętą.

---

## 14. Dźwięk i haptyka

### 14.1. Dlaczego to jest system krytyczny, a nie ozdoba

W ARLS-ZA gracz patrzy na płaską mapę z kropkami — obraz przekazuje minimum informacji. Co więcej, przez większość czasu **telefon jest w kieszeni**, bo gracz idzie ulicą. W tych warunkach dźwięk i wibracja są **jedynymi** kanałami komunikacji z graczem.

To odwraca zwykłą hierarchię: w tej grze audio nie jest warstwą dodaną na końcu, tylko podstawowym interfejsem. Powinno powstać wcześnie, bo ma wpływ na architekturę (§11) i na to, ile pracy wymaga UI.

⚠️ **Konflikt z bezpieczeństwem (§3.5):** gra zachęca do słuchawek, a słuchawki na ulicy to realne zagrożenie. Zasady:

- Gra **nigdy** nie wymaga słuchawek — pełna informacja musi docierać także przez wibracje i ekran
- Wszystkie sygnały krytyczne mają duplikat haptyczny
- Onboarding zawiera rekomendację trybu przepuszczania dźwięku otoczenia (transparency)
- Głośność zdarzeń krytycznych ograniczona z góry — brak nagłych bardzo głośnych dźwięków

### 14.2. Stos techniczny

| Element | Rozwiązanie | Uwagi |
| :---- | :---- | :---- |
| Silnik audio | **flutter_soloud** | niskopoziomowy plugin oparty na silniku SoLoud (C++), przeznaczony do gier; komunikacja przez `dart:ffi`, bez method channels — stąd niskie opóźnienie |
| Dźwięk pozycyjny | `play3d()` z flutter_soloud | pakiet ma wbudowane audio 3D z pozycjonowaniem źródeł i konfiguracją słuchacza |
| Formaty | OGG Vorbis (efekty), Opus (ambient) | wspierane natywnie; mniejsze niż WAV |
| Haptyka | pakiet `vibration` | kontrola amplitudy od Androida API 26+ |
| Licencja pluginu | MIT (część Dart) | bezpieczna komercyjnie |

📐 **Mapowanie na dźwięk pozycyjny:** pozycja przeciwnika względem gracza jest znana z GPS. Wystarczy przeliczyć różnicę współrzędnych na wektor w przestrzeni silnika:

x = (lon_wroga − lon_gracza) × 111320 × cos(lat_gracza)

z = (lat_wroga − lat_gracza) × 110540

y = 0

Orientacja słuchacza ustawiana z kompasu (magnetometru), nie z kierunku ruchu — inaczej stojący gracz traci orientację kierunkową.

**To jest potencjalnie najmocniejsza mechanika w całej grze:** gracz stoi na ulicy, patrzy na mapę, i **słyszy z lewej strony**, że coś się zbliża — zanim zobaczy znacznik. Żadna zwykła gra mobilna tego nie robi, bo nie zna realnej orientacji gracza w świecie.

### 14.3. Strategia pozyskania dźwięków — model hybrydowy

Rekomendacja: **80% z gotowych bibliotek royalty-free, 20% generowane AI** dla dźwięków specyficznych, których nie ma w bibliotekach (wokalizacje przeciwników).

#### Warstwa 1 — bazowa biblioteka (darmowa, komercyjna, bez atrybucji)

**Sonniss GDC Game Audio Bundle** to najlepszy punkt startu. Tegoroczna edycja to ponad 7 GB plików WAV bez wymogu atrybucji, a archiwum poprzednich dziewięciu lat udostępnia ponad 200 GB dźwięków royalty-free, wszystkie do użytku komercyjnego. Licencja pozwala na użycie w nieograniczonej liczbie projektów przez całe życie licencjobiorcy, modyfikowanie oraz zastosowanie komercyjne bez atrybucji.

⚠️ **Jedno ograniczenie licencyjne warte odnotowania:** wykorzystanie tych dźwięków do trenowania modeli AI/ML jest wprost zabronione. Nas to nie dotyczy (używamy ich jako assetów), ale wyklucza pomysł „wytrenuję własny generator na tej bibliotece".

#### Warstwa 2 — uzupełnienia punktowe

| Źródło | Licencja | Zastosowanie |
| :---- | :---- | :---- |
| **Freesound** | mieszana — filtrować **wyłącznie CC0** | pojedyncze braki, foley |
| **Kenney.nl** | CC0, bez rejestracji | dźwięki UI |
| **OpenGameArt** | CC0 / CC-BY / GPL — sprawdzać każdy plik | uzupełnienia |
| **Pixabay** | licencja Pixabay, bez atrybucji | ambient |

⚠️ **Freesound wymaga dyscypliny.** Licencje są mieszane per plik — CC-BY wymaga atrybucji, a niektóre pliki mają licencje niekomercyjne. Filtr CC0 jest obowiązkowy, a nie zalecany.

#### Warstwa 3 — generowanie AI

Dla dźwięków, których nie ma w żadnej bibliotece: wokalizacje Skakuna, Szwędacza i Brutala, specyficzne stingi UI.

**ElevenLabs SFX** — generuje efekty z opisu tekstowego w jakości 48 kHz, obsługuje klipy do 30 sekund z bezszwową pętlą; na planach płatnych wynik jest royalty-free i licencjonowany komercyjnie, natomiast plan darmowy wymaga atrybucji. Model zwraca cztery warianty na jedno zapytanie, co ułatwia dobór.

**Stable Audio** — lepszy do długich, zapętlonych podkładów ambientowych niż do krótkich efektów.

⚠️ **Do darmowego planu ElevenLabs podchodzić ostrożnie** — wymóg atrybucji „elevenlabs.io" w grze komercyjnej jest kłopotliwy. Jeśli generujemy AI, to na planie płatnym; jednorazowy koszt kilkudziesięciu dolarów za komplet dźwięków przeciwników jest akceptowalny.

⚠️ **Kwestia praw do wyniku AI:** w wielu jurysdykcjach (w tym w USA) treść wygenerowana wyłącznie przez AI może nie podlegać ochronie prawnoautorskiej. Praktycznie oznacza to, że **nie możesz nikomu zabronić użycia tych samych dźwięków**. Dla tego projektu to bez znaczenia, ale warto wiedzieć.

### 14.4. Czy trzeba zgłaszać użycie AI w Google Play?

Polityka Google Play dotycząca treści generowanych przez AI celuje w aplikacje, **które generują treść dla użytkownika w czasie działania** (chatboty, generatory obrazów) — wymaga wtedy oznaczenia i moderacji. Assety stworzone AI na etapie produkcji to inna kategoria i standardowo nie wymagają deklaracji.

Warto natomiast odnotować, że polityka Google Play nie wymaga wprost ujawniania użycia AI w opisie aplikacji, ale zasady promocji wymagają, by opis i materiały marketingowe rzetelnie odzwierciedlały funkcjonalność. Skoro w ARLS-ZA nie ma żadnej funkcji generatywnej działającej u użytkownika, nie ma czego deklarować.

❓ Przed publikacją zweryfikować aktualny stan polityki — ten obszar zmienia się szybko.

### 14.5. Higiena licencyjna ⚠️ — obowiązkowa od pierwszego pliku

Najczęstszy błąd w projektach indie: dźwięk pobrany „na próbę" w tygodniu drugim zostaje w buildzie produkcyjnym rok później, a nikt już nie pamięta, skąd pochodzi.

**Procedura:**

1. Plik `assets/audio/CREDITS.md` prowadzony od początku, jeden wiersz na dźwięk: `nazwa_pliku | źródło | licencja | data pobrania | URL`
2. Zrzut strony licencji zapisywany razem z plikiem (PDF lub PNG w `docs/licenses/`)
3. Katalogi **rozdzielone**: `assets/audio/prototype/` i `assets/audio/shipped/`. Prototypowe nigdy nie trafiają do release'u — brak tego podziału to najprostsza droga do zostawienia w buildzie pliku na licencji niekomercyjnej
4. Skrypt CI sprawdzający, że każdy plik w `shipped/` ma wpis w `CREDITS.md`
5. Ekran „Podziękowania" w aplikacji dla pozycji CC-BY (jeśli w ogóle jakieś zostaną)

### 14.6. Lista dźwięków dla MVP

Realistyczny zakres: **~55 plików**. Nie więcej — resztę dobudować po testach.

| Kategoria | Dźwięki | Szt. |
| :---- | :---- | :---- |
| **Fizjologia** | bicie serca (4 warianty tempa), oddech (spokojny / szybki / rzężenie), przełykanie, jęk bólu | 9 |
| **Broń** | strzał ×3 bronie, przeładowanie (wyjęcie magazynka / włożenie / przeładowanie), pusty zamek, trafienie w cel, chybienie (rykoszet) | 11 |
| **Szwędacz** | bezczynność (3), zaalarmowanie, sprint (oddech), atak (2), śmierć | 8 |
| **Gracz** | kroki (chód / bieg), otrzymanie ciosu, upadek (utrata przytomności) | 5 |
| **Ekwipunek** | podniesienie przedmiotu, upuszczenie, otwarcie plecaka, opatrunek, picie, jedzenie | 7 |
| **UI** | tap, potwierdzenie, anulowanie, błąd, awans umiejętności, wejście do menu | 6 |
| **Ambient** | miasto (dzień / noc), teren otwarty, wnętrze ogniska (pętle) | 4 |
| **Alerty** | ostrzeżenie o niskiej krwi, wykrycie przez wroga, awans ogniska, horda | 5 |

### 14.7. Zasady projektowania audio

Sedno: **model fizjologiczny (§2) jest już policzony — wystarczy go usłyszeć.**

**Bicie serca jako główny instrument.** Tętno jest wyliczane co tick (§2.4). Odtwarzanie bicia serca w tempie równym `HR_aktualne` daje graczowi bezpośrednie, nieprzerwane odczucie stanu ciała — bez żadnego elementu UI. To jednocześnie:

- wskaźnik zmęczenia
- wskaźnik stabilizacji przy celowaniu (§5.3) — słyszysz, kiedy możesz strzelić
- narzędzie napięcia przy niskim poziomie krwi (nierówny, przyspieszony rytm)

Głośność bicia rośnie z tętnem: niesłyszalne poniżej 60% HR_max, dominujące powyżej 90%.

**Pozostałe mapowania:**

| Stan | Sygnał audio |
| :---- | :---- |
| Odwodnienie > 5% | suchy, płytki oddech; przytłumienie wysokich częstotliwości |
| Krwawienie | miarowe kapanie, tempo = tier krwawienia |
| Klasa III wstrząsu | szum uszny, wyciszenie ambientu, spowolniony oddech |
| Dług snu > 12 h | okresowe przytłumienie całego miksu (mikrosny) |
| Wykrycie przez wroga | pojedynczy, krótki sygnał kierunkowy — **nie** muzyka bojowa |

⚠️ **Brak muzyki bojowej.** Gra dzieje się w prawdziwym mieście — podkład orkiestrowy natychmiast burzy realizm. Napięcie budujemy oddechem, tętnem i dźwiękami przeciwników. To także oszczędza całą kategorię assetów.

### 14.8. Haptyka

Telefon w kieszeni to najczęstszy stan gry. Wibracja jest wtedy jedynym kanałem.

| Zdarzenie | Wzorzec |
| :---- | :---- |
| Wykrycie przez wroga | 2 krótkie impulsy |
| Otrzymanie obrażeń | 1 mocny impuls, długość ∝ obrażenia |
| Krwawienie rozpoczęte | 3 szybkie impulsy |
| Krew < 30% | powtarzalny wzorzec co 20 s (dwa impulsy) |
| Ukończenie czynności (budowa, lektura) | 1 długi, łagodny |
| Horda w drodze | narastająca seria |

⚠️ Wszystkie wzorce muszą być rozróżnialne **przez kieszeń spodni** — czyli krótkie i o wyraźnie różnej strukturze rytmicznej, nie różnej sile.

### 14.9. Budżet zasobów

| Zasób | Limit |
| :---- | :---- |
| Rozmiar assetów audio | < 25 MB (OGG q4, mono dla efektów, stereo tylko dla ambientu) |
| Jednoczesne kanały | 16 |
| Ambient | 1 pętla, crossfade 3 s przy zmianie strefy |

⚠️ Ciągłe odtwarzanie ambientu przy wyłączonym ekranie zwiększa zużycie baterii — powiązać z trybem oszczędnym z §3.3. Przy telefonie w kieszeni i wygaszonym ekranie: tylko alerty i haptyka, bez ambientu.

---

## 15. Onboarding

### 15.1. Problem do rozwiązania

ARLS-ZA łamie trzy nawyki gracza mobilnego, i każde z tych złamań bez wyjaśnienia wygląda jak błąd aplikacji:

1. **Nie trafisz w biegu.** Model celności (§5.1) sprawia, że strzał w ruchu jest praktycznie chybiony. Gracz uzna, że broń jest zepsuta.
2. **Przed Skakunem nie uciekniesz.** 25 s sprintu przy 30 km/h zawsze wystarcza na pokonanie dystansu detekcji (§6.1). Gracz uzna, że gra oszukuje.
3. **Twoje ciało jest kontrolerem.** Gra liczy realne kalorie z realnego ruchu. Gracz siedzący na kanapie nie zrozumie, dlaczego nic się nie dzieje.

Onboarding istnieje wyłącznie po to, żeby te trzy rzeczy przekazać. Wszystko inne może poczekać.

### 15.2. Zasady

- **Maksymalnie 5 minut** do pierwszej samodzielnej rozgrywki
- **Przerywalny w każdym momencie**, z możliwością powrotu z menu
- **Bez ścian tekstu** — jeden ekran, jedna myśl, maksymalnie 2 zdania
- **Podpowiedzi kontekstowe zamiast wykładu** — reguła wyjaśniana w momencie, gdy staje się istotna
- **Nie blokować mapy** — gracz ma zobaczyć swoje realne otoczenie w ciągu pierwszych 30 sekund

### 15.3. Etap 0 — bezpieczeństwo (obowiązkowy, jednorazowy)

Przed czymkolwiek innym, wymagane aktywne potwierdzenie (checkbox, nie samo „Dalej"):

> **Zanim zaczniesz**
>

> - Ta gra wymaga chodzenia po prawdziwym świecie. **Patrz przed siebie, nie na ekran.**
> - Nigdy nie graj podczas prowadzenia pojazdu, przechodzenia przez jezdnię ani w pobliżu torów.
> - Nie wchodź na teren prywatny ani w miejsca niedostępne publicznie.
> - Jeśli używasz słuchawek — włącz tryb przepuszczania dźwięków otoczenia.
> - Oceniaj sam, czy okolica i pora są bezpieczne. Gra tego nie wie.

>
> ☐ Rozumiem i biorę odpowiedzialność za własne bezpieczeństwo

To nie jest formalność — to sekcja wymagana zarówno z powodów prawnych (§3.5), jak i praktycznych.

### 15.4. Etap 1 — kreator postaci z kontekstem

Kreator z §1.2 uzupełniony o jedno zdanie wyjaśniające przy polach fizjologicznych:

> Twój wzrost, waga, wiek i płeć służą do obliczenia objętości krwi, zapotrzebowania na wodę i kalorie oraz udźwigu. **Te dane nigdy nie opuszczają Twojego telefonu.**

Na koniec — ekran podsumowania parametrów wyliczonych, który jest jednocześnie pierwszym dowodem, że gra liczy naprawdę:

> Twoja objętość krwi: **5319 ml** Zapotrzebowanie dzienne: **2450 kcal / 2800 ml wody** Udźwig komfortowy: **24 kg** · maksymalny: **36 kg** Tętno maksymalne: **187 bpm**

⚠️ **Wybór trybu (Hardcore / Softcore) na osobnym ekranie**, z wyraźnym ostrzeżeniem o nieodwracalności. Domyślnie zaznaczony **Softcore**. Hardcore wymaga dodatkowego potwierdzenia.

### 15.5. Etap 2 — pierwsze kroki (podpowiedzi kontekstowe)

Gracz trafia na mapę. Podpowiedzi wyzwalane zdarzeniami, nie kolejnością:

| Wyzwalacz | Podpowiedź |
| :---- | :---- |
| Wejście na mapę | „To Twoja prawdziwa okolica. Zielona kropka to Ty." |
| Pierwsze 50 m marszu | „Gra widzi Twój ruch. Idziesz — spalasz kalorie i wodę." |
| Pierwszy lootbox w zasięgu | „Żółty znacznik to zapasy. Podejdź, żeby przeszukać." |
| Pierwsze otwarcie plecaka | „Masz limit wagi. Nadwyżka nie spowolni Cię, ale zmęczy szybciej." |
| Pierwsze ognisko widoczne | „Czerwony okrąg to ognisko. Rośnie z czasem. Nie musisz tam iść — jeszcze." |

### 15.6. Etap 3 — pierwsza walka (kontrolowana)

**Scenariusz bezpieczny.** Pojedynczy Szwędacz spawnowany 120 m od gracza, w bezpiecznym kierunku (z dala od dróg, §3.5). Ten konkretny przeciwnik ma obniżone obrażenia i **nie może zabić gracza** — to jedyny scenariusz skryptowany w całej grze.

Sekwencja podpowiedzi:

1. **Wykrycie** — „Coś Cię zauważyło. Słyszysz kierunek." *(dźwięk kierunkowy + wibracja — pierwszy kontakt gracza z systemem audio z §14)*
2. **Namierzenie** — „Dotknij przeciwnika, żeby go namierzyć."
3. **Kluczowa lekcja** — „**Zatrzymaj się.** Liczba nad przyciskiem to Twoja realna szansa trafienia. W ruchu spada kilkukrotnie."
4. **Strzał** — gracz strzela, widząc jawną wartość procentową (§5.1.4)
5. **Fala hałasu** — „Widzisz ten okrąg? Strzał słychać na 700 metrów. Coś mogło Cię usłyszeć."
6. **Przeładowanie** — „Pusty magazynek. Przeładuj — to trwa 3 sekundy, a on się zbliża."
7. **Po walce** — „Zużyłeś 7 naboi na jednego. Amunicji jest mało, a każdy strzał Cię zdradza. Czasem lepiej nie walczyć."

Punkty 5 i 7 są najważniejsze w całym onboardingu — ustawiają ekonomię gry w głowie gracza od pierwszej minuty.

### 15.7. Trzy zasady na ekranie końcowym

Krótkie podsumowanie, dostępne później z menu jako „Zasady przetrwania":

> **1. Stój, żeby strzelać.** Ruch, wysokie tętno i zmęczenie rozrzucają strzały. **2. Nie przed wszystkim uciekniesz.** Niektóre potrafią sprintować szybciej niż Ty — ale nie dłużej niż 25 sekund. **3. Twoje ciało jest kontrolerem.** Postać ma dokładnie tyle sił, ile Ty naprawdę przejdziesz.

### 15.8. Czego świadomie NIE tłumaczymy na starcie

Schron, umiejętności, literatura, crafting, moduły, neutralizacja ognisk, hordy — wszystko to wprowadzane podpowiedzią kontekstową w momencie pierwszego zetknięcia. Wciśnięcie tego w onboarding zamieni 5 minut w 25 i zniechęci gracza, zanim cokolwiek zobaczy.

❓ **Do rozważenia:** cel gry („przetrwaj jak najdłużej") komunikowany dopiero po pierwszym dniu przetrwania, gdy pojawia się licznik passy. Wcześniej jest abstrakcją.

---

## 16. Rejestr luk

Obszary **jeszcze niezaprojektowane**. To rejestr świadomych braków, nie propozycji — służy temu, żeby żaden z nich nie został odkryty dopiero przy publikacji. Każdy ma przypisany etap w [ROADMAP.md](ROADMAP.md).

### 16.1. 🟡 Uprawnienie do lokalizacji w tle

Android wymaga osobnej zgody `ACCESS_BACKGROUND_LOCATION`, a Google Play — odrębnego formularza uzasadnienia i weryfikacji. Proces przeszedł już pomyślnie za pierwszym podejściem w innej aplikacji tego samego dewelopera; pozostaje standardowa staranność: wideo demonstracyjne, precyzyjne uzasadnienie, deklaracja spójna z faktycznym użyciem.

⚠️ **Wymóg niezależny od procesu zatwierdzania:** gra **musi** działać bez tej zgody, w trybie tylko-foreground. Odmowa użytkownika (nie Google) jest zawsze możliwa i nie może oznaczać braku gry. Do zaprojektowania: zakres funkcjonalny trybu ograniczonego.

### 16.2. 🟡 Spirala niemocy w trybie Softcore

Gracz bez amunicji i jedzenia, z trzema ogniskami poziomu 10 wokół schronu, nie ma ścieżki wyjścia: traci przytomność, budzi się z 25% krwi, ginie ponownie. Formalnie gra trwa, realnie się skończyła.

Brak zaprojektowanego dna. Kierunki: gwarantowany minimalny loot po n-tej z rzędu utracie przytomności, wygaszanie ognisk przy długiej nieobecności, albo jawna opcja „zacznij nową passę" resetująca ogniska.

### 16.3. 🟡 Powrót po przerwie

§2.1 opisuje catch-up tick technicznie, ale nie mówi, **co gracz widzi** po trzech dniach nieobecności. Potrzebny ekran podsumowania: co urosło, ile stracił zasobów, czy horda odwiedziła schron. Bez tego powrót jest dezorientujący — a to najczęstszy moment porzucenia aplikacji.

### 16.4. 🟡 Tempo gry a realne życie

📐 Kontrola do wykonania: pracujący dorosły gra ~1 h dziennie. Ogniska rosną co 8 h (dzień 1) do 2 h (dzień 24), licząc 100% czasu aktywnego i 25% uśpionego (§6.5.3). Trzeba policzyć, czy gracz w ogóle nadąża — jeśli ogniska osiągają poziom 10 w dwa tygodnie i nie da się ich zbić, gra kończy się dla wszystkich w tym samym momencie, niezależnie od umiejętności.

Obóz (§8.5) usuwa karę za godziny pracy, a droga z pracy do domu staje się główną pętlą rozgrywki. Pozostaje policzyć, czy tempo wzrostu ognisk jest dopasowane do ~1 h gry dziennie — do zweryfikowania symulacją przed testami terenowymi.

### 16.5. 🟡 Telemetria bez serwerów

Bez danych nie da się zbalansować gry. Minimalny zestaw (Crashlytics + zdarzenia agregowane): dzień śmierci, przyczyna, poziomy ognisk, zużycie amunicji na eliminację, odsetek porzuceń w onboardingu.

⚠️ Konflikt z zasadą „dane nie opuszczają telefonu" (§1.2) — telemetria musi być **wyłącznie zagregowana, bez lokalizacji**, z jawną zgodą i domyślnie wyłączona.

### 16.6. 🟡 Pierwsze uruchomienie i pakiety map

§3.1 zakłada pobranie 50–200 MB kafelków. Rozstrzygnięte w [ROADMAP.md](ROADMAP.md), etap 3: ekran wyboru regionu, obsługa braku miejsca, wykrycie wyjazdu poza pakiet z histerezą i czasem ustalenia, oraz przeniesienie gracza między sesjami (skok pozycji, komunikat fabularny, decyzja o pakiecie). Nierozstrzygnięte: aktualizacja pakietów, gdy wyjdzie nowsza wersja kafelków.

### 16.7. 🟢 Warstwa prawna — blokuje publikację

| Element | Uwagi |
| :---- | :---- |
| Polityka prywatności | wymagana przez Google Play, publiczny URL; musi opisywać dane lokalizacyjne i parametry ciała z kreatora postaci |
| Formularz Data Safety | deklaracja: lokalizacja i parametry ciała przetwarzane wyłącznie lokalnie |
| RODO | podstawa przetwarzania, prawo do usunięcia (eksport/kasowanie profilu — §11.1) |
| Regulamin | wyłączenie odpowiedzialności za bezpieczeństwo w terenie (§3.5) |
| Kategoria wiekowa IARC | kwestionariusz w Play Console |
| Uzasadnienie lokalizacji w tle | §16.1 |

⚠️ Brak Health Connect (§2.5) oznacza, że jedynym uprawnieniem wymagającym weryfikacji przez Google jest lokalizacja w tle.

### 16.8. 🟢 Braki drobne

- Ikona, nazwa w sklepie, zrzuty ekranu, opis ASO
- Muzyka menu głównego (w rozgrywce świadomie brak — §14.7)
- Obsługa tabletów i różnych proporcji ekranu
- Brak warstwy społecznościowej — rankingi wymagałyby serwera; świadomie akceptowane, ale ogranicza retencję do rekordów osobistych

---

## 17. Sezonowość i środowisko

### 17.1. Problem i zasada rozwiązania

W Poznaniu od listopada do lutego zmierzch zapada po 15:30, jest zimno i mokro — gra wymagająca godzin na dworze traci wtedy sens przez jedną trzecią roku.

⚠️ **Ale „zima" nie może być zdefiniowana kalendarzem.** W Kapsztadzie i Sydney grudzień to pełnia lata, a w Nairobi pory roku praktycznie nie istnieją. Odwołanie do miesięcy zepsułoby grę wszędzie poza Europą.

**Zasada: gra nie zna pojęcia „pory roku". Zna dwie mierzone wielkości** — długość dnia i temperaturę — i z nich wyprowadza wszystkie modyfikatory. Sezonowość powstaje sama, poprawnie na każdej szerokości geograficznej.

### 17.2. Długość dnia 📐 — liczona offline

Deklinacja słoneczna i kąt godzinowy, bez żadnego API:

δ = 23.45° × sin(360/365 × (284 + N)) // N = dzień roku

cos(ω) = −tan(φ) × tan(δ) // φ = szerokość gracza

godziny_światła = 2ω / 15

Wartość `cos(ω)` ograniczana do przedziału ⟨−1, 1⟩ — obsługa dnia i nocy polarnej.

**Weryfikacja formuły:**

| Lokalizacja | 21 mar | 21 cze | 21 wrz | 21 gru | Amplituda |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Poznań (52,4°N) | 11,9 h | 16,6 h | 12,0 h | **7,4 h** | 9,1 h |
| Szczecin (53,4°N) | 11,9 h | 16,8 h | 12,0 h | 7,2 h | 9,5 h |
| Kapsztad (33,9°S) | 12,0 h | **9,7 h** | 12,0 h | 14,3 h | 4,5 h |
| Sydney (33,9°S) | 12,0 h | 9,7 h | 12,0 h | 14,3 h | 4,5 h |
| Nairobi (1,3°S) | 12,0 h | 11,9 h | 12,0 h | 12,1 h | **0,2 h** |
| Tromsø (69,6°N) | 11,9 h | 24,0 h | 11,9 h | **0,0 h** | 24,0 h |

Formuła działa poprawnie na obu półkulach, a w strefie równikowej sezonowość znika sama — dokładnie tak, jak powinna.

### 17.3. Temperatura

Źródło: Open-Meteo (§11), z cache'owaniem i łagodną degradacją przy braku sieci.

- Wartość robocza: **średnia z 7 dni** — pojedynczy chłodny dzień nie ma przestawiać rozgrywki
- Brak danych → wartość ostatnia znana; brak jakiejkolwiek → 15°C (neutralna)

### 17.4. Modyfikatory środowiskowe 📐

Wszystkie efekty wyprowadzane z dwóch wielkości powyżej. Brak dyskretnych „pór roku" — zmiana jest ciągła.

📐 **Wskaźnik chłodu** (0 = ciepło, 1 = mróz):

C = clamp((10 − T_śr7) / 25, 0, 1) // 10°C → 0.0 ; −15°C → 1.0

📐 **Wskaźnik ciemności** (0 = długi dzień, 1 = krótki):

D = clamp((12 − godziny_światła) / 6, 0, 1) // 12 h → 0.0 ; ≤6 h → 1.0

| System | Modyfikator | Uzasadnienie |
| :---- | :---- | :---- |
| **Wzrost ognisk** (§6.5.3) | `interwał × (1 + 1.2 × C)` — przy mrozie ogniska rosną **ponad dwukrotnie wolniej** | przeciwnicy również podlegają chłodowi |
| **Prędkość przeciwników** (§6.1) | `× (1 − 0.30 × C)` | spowolnienie w niskich temperaturach |
| **Budżet sprintu** | `× (1 − 0.25 × C)` | krótszy pościg przy mrozie |
| **Zapotrzebowanie kaloryczne** (§2.3) | `× (1 + 0.15 × C)` | podwyższona termogeneza — realne |
| **Straty z potem** (§2.3) | już zależne od T — bez zmian | |
| **Zasięg wykrycia gracza** (§6.2) | `× (1 + 0.20 × D)` w godzinach ciemności | |
| **Promień hałasu** (§5.6.1) | już ×1.3 nocą — bez zmian | |
| **Respawn lootu** (§10) | `× (1 − 0.25 × D)` — szybszy przy krótkim dniu | rekompensata za mniej czasu na wyprawy |

⚠️ **Tempo czynności schronowych nie podlega modyfikatorowi sezonowemu** — dłuższa noc daje więcej godzin na zajęcia (§2.1a.2), więc premia do tempa byłaby nagrodą za to samo dwa razy.

### 17.5. Wynikowy rytm gry

Dla Poznania oznacza to naturalny podział roku, którego nikt nie musiał wpisywać w kod:

| Okres | C, D | Charakter rozgrywki |
| :---- | :---- | :---- |
| **Czerwiec–sierpień** | C≈0, D≈0 | Sezon wypraw. Ogniska rosną najszybciej, przeciwnicy najszybsi, długie dni na eksplorację. Presja maksymalna. |
| **Marzec–maj, wrzesień–październik** | C≈0.2, D≈0.2 | Równowaga. |
| **Listopad–luty** | C≈0.5, D≈0.8 | Sezon przygotowań. Ogniska rosną ~1,6× wolniej, przeciwnicy o 15% wolniejsi, długie noce dają ~8,6 h na zajęcia schronowe, loot odnawia się szybciej. |

⚠️ **To odwraca problem w mechanikę:** zima nie jest przerwą w grze, tylko innym trybem grania. Gracz nadrabia zaległości w lekturze, craftingu i rozbudowie schronu, podczas gdy świat na zewnątrz zwalnia.

W Kapsztadzie ten sam rytm wypada w lipcu, w Nairobi nie wypada nigdy — i wszystko działa bez jednej linii kodu specyficznej dla regionu.

### 17.6. Warunek konieczny — głębia czynności schronowych

Cały pomysł stoi na założeniu, że **jest co robić w schronie przez cztery miesiące.** Obecnie nie ma: budowa to 3 h, moduły to kilka rozbudów, literatura jest jedynym długim zajęciem.

Częściowo pokrywa to §18: pełna rozbudowa modułów to 731 kg materiału i ~30 kursów — zajęcie na tygodnie, naturalnie wpisujące się w sezon przygotowań. Elaboracja amunicji i receptury przedmiotów dodatkowo zapełniają czas w schronie.

Do zaprojektowania:

- Modyfikacje broni (celowniki, tłumiki własnej roboty)
- Planowanie i zapasy — mechanika przygotowań na sezon wypraw
- Uprawa lub hodowla żywności — decyzja i szczegóły w §18.7 (poza MVP)

❓ **Ryzyko do sprawdzenia:** czy gracz, dla którego zima trwa cztery miesiące, nie porzuci gry z nudów mimo tych czynności. Zima musi być **inna**, ale nie **pusta**.

### 17.7. Pogoda krótkoterminowa

Poza sezonowością — bieżące zjawiska z Open-Meteo:

| Zjawisko | Efekt |
| :---- | :---- |
| Deszcz / śnieg | promień hałasu ×0.75 (§5.6), wykrycie gracza −15% |
| Silny wiatr | ×0.75 do hałasu, +2 MOA do rozrzutu na dystansie >150 m |
| Mgła | zasięg wykrycia obustronnie −40% |
| Upał >28°C | zwiększone straty z potem (już w §2.3) |

⚠️ Wszystkie wartości cache'owane; brak sieci = pogoda neutralna. Gra nigdy nie może wymagać połączenia.

---

## 18. Wytwarzanie i receptury

### 18.1. Surowce podstawowe

Cztery surowce zbierane podczas eksploracji (§4.7) plus jeden rzadki.

| Surowiec | Masa/szt. | Objętość | Źródła |
| :---- | :---- | :---- | :---- |
| **Drewno** | 2,0 kg | **4,0 l** | budynki, stodoły, wiaty, place budowy, lasy |
| **Metal** | 1,5 kg | **0,6 l** | garaże, warsztaty, tereny przemysłowe, wraki |
| **Plastik** | 0,4 kg | **2,0 l** | śmietniki, markety, wszędzie |
| **Materiał** | 0,3 kg | **1,0 l** | domy, sklepy odzieżowe, tapicerka samochodów |
| **Komponent techniczny** | 0,8 kg | 0,4 l | **rzadki** — `shop=doityourself`, `car_repair`, `building=industrial` |

Objętości skalibrowane na realne gęstości z uwzględnieniem upakowania złomu i ścinków — plastik zbierany jako butelki i pojemniki to głównie powietrze, złom metalowy jest gęsty.

### 18.1a. Limity noszenia: masa i objętość, bez limitów sztukowych

⚠️ **Żadnych limitów sztukowych.** Twardy limit liczby sztuk rozbijałby własne receptury (Magazyn L3 wymaga 36 drewna, Warsztat L3 — 42 metalu) i tak czy inaczej nigdy by nie zadziałał w plecaku, bo masa wiąże znacznie wcześniej:

| Surowiec | Limit z masy (24 kg) | Limit z objętości (65 l) | Co wiąże |
| :---- | :---- | :---- | :---- |
| Drewno | **12 szt.** | 16 | masa |
| Metal | **16 szt.** | 108 | masa |
| Plastik | 60 | **32 szt.** | objętość |
| Materiał | 80 | **65 szt.** | objętość |
| Komponent | 30 | 162 | masa |

**Dwa niezależne limity — masa i objętość plecaka.** Stackowanie bez ograniczeń sztukowych; limit wynika wyłącznie z fizyki.

To realizuje zamierzony cel (świadome zarządzanie surowcami) i dodatkowo różnicuje surowce charakterem:

- **Metal to problem masy** — dużo udźwigu, mało miejsca
- **Plastik i materiał to problem objętości** — lekkie, ale zapychają plecak
- **Drewno uwiera na obu osiach naraz**

**Pojemność plecaków** — nowy parametr obok udźwigu:

| Plecak | Udźwig | Pojemność |
| :---- | :---- | :---- |
| Brak (kieszenie) | +0 kg | **12 l** |
| Torba | +4 kg | 30 l |
| Plecak turystyczny | +8 kg | 45 l |
| Plecak trekkingowy | +12 kg | **65 l** |
| Plecak wojskowy | +16 kg | 90 l |

**Magazyn schronu ma oba limity:** 3 litry na każdy kilogram pojemności. Magazyn 125 kg → 375 l. Zapobiega składowaniu 312 sztuk plastiku, które mieszczą się masowo, ale zajęłyby 624 l.

⚠️ **HUD ekwipunku pokazuje oba paski** — masę i objętość. Bez tego gracz nie zrozumie, dlaczego nie może podnieść lekkiego przedmiotu.

⚠️ **Komponent techniczny to regulator tempa rozbudowy.** Bez niego gracz zbudowałby wszystko w tydzień, bo drewna i plastiku jest wszędzie pod dostatkiem. Komponent wymusza wyprawy do konkretnych miejsc i nadaje sens mapowaniu POI z §10.

**Łuski** — osobna kategoria, powstająca wyłącznie z rozgrywki: każdy oddany strzał zostawia łuskę w miejscu strzału, widoczną na mapie przez 48 h (§4.8). Odzyskiwalne, potrzebne do elaboracji amunicji (§18.5). Domyka ekonomię z §5.6: strzał kosztuje amunicję, hałas **i** wymaga powrotu po łuski, jeśli chcesz odzyskać część nakładu.

### 18.2. Receptury modułów schronu 📐

Masy policzone dla gracza o udźwigu komfortowym 24 kg (80 kg masy ciała, §1.3).

| Moduł | Drewno | Metal | Plastik | Materiał | Komponent | Masa | Kursy | Czas bazowy |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **Obóz** (§8.5) | 12 | 4 | — | 6 | — | **31,8 kg** | 1,3 | 40 min |
| **Magazyn L1** (+50 kg) | 20 | 6 | — | — | — | **49,0 kg** | 2,0 | 2 h |
| **Magazyn L2** | 28 | 12 | 6 | — | — | **76,4 kg** | 3,2 | 3 h 30 |
| **Magazyn L3** | 36 | 18 | 10 | — | — | **103,0 kg** | 4,3 | 5 h |
| **Warsztat L1** | 15 | 20 | — | — | 2 | **61,6 kg** | 2,6 | 4 h |
| **Warsztat L2** | 18 | 30 | 10 | — | 5 | **89,0 kg** | 3,7 | 6 h |
| **Warsztat L3** | 22 | 42 | 16 | — | 10 | **121,4 kg** | 5,1 | 9 h |
| **Salon L1** | 12 | — | — | 15 | — | **28,5 kg** | 1,2 | 1 h 30 |
| **Salon L2** | 16 | — | 6 | 22 | — | **41,0 kg** | 1,7 | 2 h 30 |
| **Salon L3** | 20 | — | 10 | 30 | — | **53,0 kg** | 2,2 | 4 h |
| **Lab L1** | — | 10 | 14 | — | 4 | **23,8 kg** | 1,0 | 3 h |
| **Lab L2** | — | 14 | 20 | — | 8 | **35,4 kg** | 1,5 | 5 h |
| **Lab L3** | — | 18 | 28 | — | 14 | **49,4 kg** | 2,1 | 8 h |

**Pełna rozbudowa wszystkich czterech modułów do L3: 731 kg materiału, czyli ~30 kursów z pełnym plecakiem.**

⚠️ **To ma być celem na tygodnie, nie na weekend.** Przy zimowym spowolnieniu ognisk (§17.4) rozbudowa staje się naturalnym zajęciem sezonu przygotowań — co domyka problem z §17.6.

**Bootstrap magazynu:** schron podstawowy ma **25 kg** magazynu bazowego. Bez tego gracz nie miałby gdzie składować materiałów na budowę magazynu. Magazyn L1 podnosi to do 75 kg.

#### 18.2.1. Charakter materiałowy modułów

Każdy moduł ma czytelny profil surowcowy, spójny z tym, czym w rzeczywistości jest:

- **Magazyn** — drewno i metal: regały, skrzynie, okucia
- **Warsztat** — metal i komponenty: stół roboczy, imadło, mocowania narzędzi
- **Salon** — drewno i materiał: posłanie, izolacja, zasłony
- **Lab** — plastik i komponenty: pojemniki, szczelne naczynia, aparatura

### 18.3. Wymagania narzędziowe

| Czynność | Wymagane | Alternatywa |
| :---- | :---- | :---- |
| Budowa schronu podstawowego | młotek **lub** siekiera | ręcznie: ×2,5 czasu |
| Budowa obozu | dowolne narzędzie | ręcznie: ×2,0 czasu |
| Moduły (wszystkie) | **młotek** | multitool: ×1,6 czasu |
| Warsztat L2+ | młotek + **multitool** | brak alternatywy |
| Elaboracja amunicji | Warsztat L2 | brak alternatywy |

📐 **Czas wytwarzania:**

czas = czas_bazowy

     × (1 − 0.30 × Inżynieria) // §7

     × mod_narzędzi // tabela wyżej

     × mod_warsztatu // L1 0.90 / L2 0.80 / L3 0.70 (§8.4)

Skrajny przypadek — Warsztat L3, Inżynieria 100%, młotek: **0,7 × 0,7 × 1,0 = 0,49**, czyli 51% oszczędności. Magazyn L3 spada z 5 h do ~2 h 27.

⚠️ Brak modyfikatora sezonowego — zimą zyskuje się **godziny**, nie tempo (§2.1a.2).

⚠️ Budowa modułów to **zajęcie** (§2.1a): wyklucza sen, lekturę i wytwarzanie, ale tyka także przy zamkniętej aplikacji, dopóki postać jest w strefie schronu.

### 18.4. Receptury przedmiotów — zestaw startowy

Pełne pliki w `assets/data/recipes.json`. Poniżej szkielet kategorii z przykładami.

**Medyczne** (dostępne bez warsztatu):

| Przedmiot | Składniki | Czas | Wymaga |
| :---- | :---- | :---- | :---- |
| Opatrunek improwizowany | 3 materiał | 4 min | — |
| Opatrunek uciskowy | 4 materiał, 1 plastik | 7 min | — |
| Staza improwizowana | 2 materiał, 1 drewno | 5 min | — |
| Szyna | 2 drewno, 3 materiał | 12 min | — |

**Broń biała:**

| Przedmiot | Składniki | Czas | Wymaga |
| :---- | :---- | :---- | :---- |
| Zaostrzony kij | 1 drewno | 8 min | nóż lub multitool |
| Włócznia | 2 drewno, 1 metal, 1 materiał | 25 min | Warsztat L1 |
| Maczuga z okuciem | 1 drewno, 3 metal | 35 min | Warsztat L1 |

**Pojemniki i wyposażenie:**

| Przedmiot | Składniki | Czas | Wymaga |
| :---- | :---- | :---- | :---- |
| Bukłak | 4 materiał, 2 plastik | 20 min | — |
| Prowizoryczny plecak (+8 kg) | 8 materiał, 2 metal | 45 min | Warsztat L1 |
| Pochodnia | 1 drewno, 2 materiał | 6 min | — |

**Naprawa** (Warsztat, §8.4): przywrócenie kondycji przedmiotu kosztuje surowiec zgodny z jego materiałem — broń palna metal + komponent, odzież materiał, narzędzia metal.

### 18.5. Elaboracja amunicji — domknięcie ekonomii

Najważniejsza receptura w grze, bo zamyka pętlę z §5.6.

| Wymagania | Wartość |
| :---- | :---- |
| Warsztat | **poziom 2** |
| Składniki na 10 naboi | 10 łusek + 3 metal + 1 komponent + **1 prochownica** |
| Czas | 25 min |
| Jakość | **+2 MOA** do rozrzutu wobec amunicji fabrycznej |

**Prochownica** — rzadki loot wyłącznie z `shop=weapons`, `amenity=police`, obiektów wojskowych i ambon myśliwskich (§10.1). Jedna sztuka wystarcza na 10 naboi.

⚠️ **Kara +2 MOA jest celowa.** Amunicja własna ma być ratunkiem, nie zamiennikiem — gracz odzyskuje możliwość strzelania, ale z gorszą celnością, co przy modelu z §5.1 realnie podnosi zużycie na eliminację.

To domyka pętlę: **strzelasz → zostawiasz łuski → wracasz po nie → odzyskujesz część nakładu.** Miejsce strzelaniny staje się miejscem, do którego trzeba wrócić — a więc znowu wejść w teren, w którym coś Cię usłyszało.

### 18.6. Recykling przedmiotów

Rozbiórka przedmiotu na surowce.

| Parametr | Wartość |
| :---- | :---- |
| Zwrot surowca | **40%** wartości materiałowej, zaokrąglane w dół |
| Wymagania | narzędzie odpowiednie do materiału (multitool, siekiera, klucz) |
| Czas | 3–15 min zależnie od przedmiotu |
| Skalowanie | Inżynieria podnosi zwrot do **55%** przy 100% |
| Warsztat | L2+ podnosi zwrot o kolejne 10 punktów procentowych |

⚠️ **Kondycja przedmiotu obniża zwrot proporcjonalnie** — zniszczona broń daje mniej metalu niż sprawna. Bez tego gracz zbierałby złom wyłącznie po to, żeby go rozbierać.

⚠️ **Nie można rozebrać przedmiotu, którego receptury gracz nie zna** — inaczej recykling stałby się obejściem całego systemu wiedzy.

Zwrot 40% oznacza, że recykling nigdy nie opłaca się jako źródło surowca — opłaca się wyłącznie jako sposób na pozbycie się balastu bez straty całkowitej. To zamierzone: eksploracja pozostaje główną drogą zdobywania materiału.

### 18.7. Otwarte kwestie

❓ **Uprawa lub hodowla żywności** w schronie (§17.6) — realistyczna w skali miesięcy, ale znacząco poszerza zakres. Poza MVP.

---

## 19. Głębia przeżyciowa — czego brakuje

### 19.0. Diagnoza

Dokument opisuje kompletny, spójny system. Ale przeanalizowana od strony gracza sesja wygląda tak:

> idziesz do POI → stajesz → skanujesz 45 s → zbierasz loot → może walczysz → wracasz → wieczorem wybierasz sen albo lekturę. Powtórz sześćdziesiąt razy.

⚠️ **Prawie wszystko, co zaprojektowaliśmy, to koszty i ograniczenia.** Nie wolno biec i strzelać, nie wolno spać i czytać, trzeba przenieść 731 kg, trzeba stać 45 sekund. Prawie nic nie jest nagrodą, zaskoczeniem ani powodem, żeby komuś opowiedzieć, co się wydarzyło.

To większe ryzyko niż którakolwiek luka techniczna z §16. **Systemy bez tekstury są arkuszem kalkulacyjnym z GPS-em.**

Poniżej siedem braków, uszeregowanych wg stosunku efektu do kosztu wdrożenia.

### 19.1. 🔴 Ślady po ludziach — brak jakiejkolwiek obecności człowieka

W całym dokumencie nie ma **ani jednego śladu po innych ludziach.** Świat jest pusty: są przeciwnicy, przedmioty i budynki. Nikt tu nie żył, nikt nie umarł, nikt nie zostawił wiadomości.

To najtańsza i najsilniejsza możliwa poprawka, bo **wykorzystuje system, który już mamy** — literaturę (§4.6).

**Nowa kategoria: `notes` — literatura fabularna, bez XP.**

| Typ | Przykład | Gdzie |
| :---- | :---- | :---- |
| Notatka pożegnalna | list do córki zostawiony w mieszkaniu | `building=house` |
| Dziennik | kilka wpisów z pierwszych dni epidemii | wszędzie |
| Zapis radiowy | ostatnia transmisja z komisariatu | `amenity=police` |
| Kartka na drzwiach | „nie otwierać, jesteśmy w środku" | dowolny budynek |
| Notatka służbowa | protokół z apteki o brakach leków | `amenity=pharmacy` |

Czas czytania: kilkadziesiąt sekund. Zero XP. Zero mechaniki.

**Dlaczego to działa właśnie w tej grze:** notatki są przypisane do **realnych miejsc w mieście gracza**. Przystanek, obok którego przechodzi codziennie do pracy, staje się miejscem, gdzie ktoś zostawił wiadomość. To jedyny atut, którego nie ma żadna gra na wymyślonej mapie — i obecnie w ogóle go nie używamy.

#### 19.1.1. Struktura i lokalizacja

Plik `notes.json` — **szkic 16 notatek gotowy**, docelowo ~80.

{

  "id": "note_pharmacy_01",

  "category": "kartka_na_drzwiach",

  "poi_tags": ["amenity=pharmacy"],

  "pages_min": 1, "pages_max": 1,

  "rarity": "common",

  "has_lead": true,

  "title": { "pl": "...", "en": "..." },

  "text": { "pl": "...", "en": "..." }

}

⚠️ **Teksty w pliku danych, nie w plikach lokalizacyjnych.** To wyjątek od reguły z §1.1: notatka jest utworem, nie etykietą interfejsu. Klucz ARB na akapit prozy byłby nie do utrzymania. Struktura `text.{lang}` pozwala dodać kolejne języki bez zmiany schematu.

**Podstawianie nazw z OSM.** Placeholdery `{street}`, `{district}`, `{city}` wypełniane nazwami z okolicy gracza:

> *„23:40 — zgłoszenie, ulica {street}, wysłane dwa patrole."* → dla gracza w Poznaniu: *„zgłoszenie, ulica Naramowicka"*

To sprawia, że notatka brzmi lokalnie w każdym mieście świata — i wykorzystuje jedyny atut, jakiego nie ma żadna gra na wymyślonej mapie.

⚠️ **Pułapka fleksyjna (polski).** OSM zwraca nazwy w mianowniku („Naramowicka"), a polszczyzna wymagałaby dopełniacza („zgłoszenie z Naramowickiej"). Automatyczna odmiana nazw własnych jest zawodna, więc **zdania muszą być konstruowane tak, by placeholder stał w mianowniku**: „ulica {street}", „punkt przy: {street}", nigdy „z {street}". Angielski problemu nie ma — to ograniczenie kształtuje tekst polski i trzeba je respektować przy pisaniu.

Jeśli OSM nie zwróci nazwy dla danego obszaru, notatki z tym placeholderem po prostu nie są losowane.

#### 19.1.2. Wytyczne redakcyjne

- **3–8 zdań.** Notatka ma być przeczytana w kilkadziesiąt sekund, nie stanowić rozdziału.
- **Konkret zamiast patosu.** Najlepiej działa to, co przyziemne: lista zakupów, zeszyt braków, protokół zmiany. Wielkie słowa osłabiają efekt.
- **Bez wyjaśniania epidemii.** Nikt z piszących nie wie, co się stało. Domysł jest mocniejszy od wykładu.
- **Bez treści drastycznych.** Gra jest o przetrwaniu, nie o okrucieństwie; notatki mają budować atmosferę, nie szokować.
- ⚠️ **Nie piszemy listów pożegnalnych osób odbierających sobie życie ani opisów metod.** Gracz chodzi z tą grą sam, wieczorem, po prawdziwym mieście — to nie jest właściwy kontekst na taką treść. Rozpacz można oddać przez brak, ciszę i niedokończone zdanie.
- **Notatki dają 0 XP** i mają masę 1–3 g. Nie są nagrodą mechaniczną, tylko powodem, żeby to miejsce zapamiętać.

#### 19.1.3. Tropy

Notatki z `has_lead: true` ujawniają punkt na mapie (§19.5). W szkicu są trzy z szesnastu — proporcja mniej więcej docelowa: **trop ma być odkryciem, nie standardem.**

⚠️ Praca pisarska, nie programistyczna: ~80 notatek × 2 języki. Szkic 16 sztuk w `notes.json`.

### 19.2. 🔴 Wydarzenia losowe — świat jest całkowicie przewidywalny

Ogniska rosną wg wzoru, przeciwnicy respawnują wg tabeli, loot odnawia się co 4–8 h. **Wtorek niczym nie różni się od środy.** Nie ma powodu, żeby otworzyć aplikację dziś, a nie jutro.

**System zdarzeń** — 1–2 aktywne naraz, czas życia 2–24 h, widoczne na mapie:

| Zdarzenie | Opis | Efekt |
| :---- | :---- | :---- |
| **Skupisko** | grupa przeciwników zebrała się poza ogniskiem | ryzyko, ale skoncentrowany loot |
| **Nietknięty budynek** | obiekt, do którego nikt nie wchodził | loot ×2,5, jednorazowo |
| **Burza** | gwałtowne załamanie pogody na 3–6 h | hałas ×0,6, wykrycie −30%, straty ciepła |
| **Cisza** | przeciwnicy w promieniu 1 km wycofują się na 4 h | okno na bezpieczną wyprawę |
| **Watażka** | pojedynczy przeciwnik o podwyższonych parametrach | rzadki loot za eliminację |
| **Zator** | ognisko chwilowo przestaje rosnąć | oddech |

⚠️ **Zasada projektowa: połowa zdarzeń musi być korzystna.** Jeśli wszystkie są zagrożeniem, gra staje się wyłącznie karą — a to dokładnie problem z §19.0.

### 19.3. 🟡 Loot jest tapnięciem, nie decyzją

Obecnie: podchodzisz, przedmioty się pojawiają, bierzesz. Zero zaangażowania, zero ryzyka, zero zmienności poza tabelą dropu.

**Przeszukanie obiektu jako czynność czasowa (§2.1a):**

| Czas przeszukania | Wynik |
| :---- | :---- |
| 30 s | pobieżnie — tylko przedmioty pospolite |
| 90 s | dokładnie — pełna tabela dropu |
| 180 s | gruntownie — szansa na przedmiot rzadki ×2 |

Przeszukanie **generuje hałas** (§5.6, ~80 m) i można je przerwać. Gracz decyduje: brać szybko i uciekać, czy ryzykować dla lepszego lootu.

**Przeszkody:** część obiektów wymaga pokonania bariery — wyważenie drzwi (150 m hałasu, §5.6.1), przecięcie kłódki (wymaga narzędzia), rozbicie szyby. To nadaje narzędziom sens poza craftingiem.

### 19.4. 🟡 Mapa nie zapamiętuje gracza

Twoje miasto wygląda identycznie w dniu 1 i w dniu 60. Nic, co robisz, nie zostawia śladu.

**Warstwa historii osobistej** — trwały zapis na mapie:

- **Mapa cieplna przebytych tras** — po miesiącach staje się portretem własnego życia gracza
- Zlikwidowane ogniska oznaczone trwale
- Przeszukane obiekty pozostają wyszarzone z datą
- Miejsca utraty przytomności oznaczone na stałe
- Licznik odkrytego terenu w procentach

⚠️ To jest emocjonalna wypłata za długą passę — coś, co gracz chce pokazać innym. Obecnie po sześćdziesięciu dniach nie zostaje **nic** poza liczbą w Kronice.

### 19.5. 🟡 Brak powodu, żeby iść gdzieś nowego

Gracz poznaje lokalne POI w tydzień i potem je zapętla. Nic nie ciągnie go w nieznane części miasta.

**Tropy** — czytana literatura i notatki (§19.1) czasem ujawniają punkt na mapie:

> *„Magazyn apteczny przy ul. Naramowickiej — kluczy szukaj u kierownika."*

Punkt oddalony o 1–4 km, jednorazowy, o znacznie lepszym loocie. Wiąże trzy systemy naraz: literaturę, eksplorację i ekonomię — i daje **konkretny cel na dzisiaj**, którego grze obecnie brakuje.

### 19.6. 🟡 Trzy typy przeciwników na sześćdziesiąt dni

Skakun, Szwędacz, Brutal różnią się prędkością i liczbą krwi. Po tygodniu gracz zna wszystko.

**Modyfikatory osobnicze** — losowe cechy nakładane na typ bazowy, ~20% osobników:

| Cecha | Efekt |
| :---- | :---- |
| Opancerzony | fragmenty pancerza, −40% obrażeń w tors |
| Świeży | szybszy o 15%, mniej krwi |
| Rozdęty | wolniejszy, dwukrotnie więcej krwi |
| Czujny | zasięg wykrycia ×1,5 |
| Głuchy | nie reaguje na hałas (§5.6) |

Zero nowych modeli, zero nowych zachowań — tylko mnożniki. Ale każde starcie przestaje być identyczne, a lornetka (§10.2.4) zyskuje kolejne zastosowanie: rozpoznanie cechy przed walką.

### 19.7. 🟢 Brak kamieni milowych

Między „przeżyj dzień" a „wymaksuj umiejętność (509 h)" nie ma **żadnych** punktów pośrednich. Gracz nie ma poczucia postępu poza rosnącym licznikiem.

**Kamienie milowe** zapisywane w Kronice, bez nagród mechanicznych — same w sobie są nagrodą:

- Pierwszy tydzień, miesiąc, kwartał przetrwania
- Pierwsze zlikwidowane ognisko
- 100 / 500 / 1000 km przebytych
- Pierwsza noc bez snu, pierwsza zima
- Wszystkie moduły na L1, pierwszy moduł na L3
- Przeczytana pierwsza encyklopedia

⚠️ **Bez powiadomień typu „codzienne zadanie".** Kamień milowy to odnotowanie faktu, nie zachęta do grania — inaczej łamiemy filar z §0.

### 19.8. Ryzyko nadrzędne: gra złożona z samych kosztów

Każdy system, który zaprojektowaliśmy, coś graczowi **odbiera**: nie biegnij i nie strzelaj, nie śpij i nie czytaj, przenieś 731 kg, stój 45 sekund, nie hałasuj.

Przed testami terenowymi warto policzyć proporcję: **ile w typowej godzinie gry jest zarządzania ograniczeniami, a ile odkrywania, zaskoczenia i satysfakcji.** Jeśli pierwsze przeważa, żadna głębia symulacji tego nie uratuje.

Sekcje 19.1–19.7 są próbą wyrównania tej proporcji. Rekomendowana kolejność wdrażania: **19.1 (notatki) i 19.3 (loot jako czynność) do MVP** — obie są tanie i zmieniają odczucie z gry najbardziej. Reszta po pierwszych testach.

---

## 20. Warstwa fabularna

### 20.1. Dwa ograniczenia, które kształtują wszystko

**Ograniczenie 1: fabuła jest odkrywana w losowej kolejności.** Gracz znajduje fragmenty w porządku narzuconym przez rozmieszczenie POI w jego mieście, nie przez scenariusz. Ktoś trafi na fragment dwunasty przed pierwszym.

⚠️ **Dlatego fabuła nie może być sekwencją — musi być mozaiką.** Każdy fragment broni się sam, a chronologię gracz składa po datach. To nie jest obejście problemu, tylko lepsza forma: świat zawalił się nierównomiernie i wiedza o nim też ma być poszarpana.

**Ograniczenie 2: fabuła nie może mieć zakończenia.** Celem gry jest przetrwać jak najdłużej (§13.1). Historia z rozwiązaniem obiecywałaby ratunek, a ratunku nie ma.

**Zasada: fabuła wyjaśnia przeszłość i nigdy nie mówi o przyszłości.** Odpowiada „co się stało", nigdy „co teraz". Co teraz — to przetrwanie, bez końca.

### 20.2. Struktura — cztery fazy plus wątek własny

Plik `story.json`, oddzielony od `notes.json` (§19.1): notatki niosą atmosferę, fragmenty fabularne niosą historię.

| Faza | Czego gracz się dowiaduje | Cel | Szkic |
| :---- | :---- | :---- | :---- |
| **0. Zanim** (dni −30…−1) | normalny świat, pierwsze sygnały zignorowane | 8 | 2 |
| **1. Wybuch** (dni 1–18) | choroba bez nazwy, kwarantanny, sprzeczne komunikaty | 15 | 4 |
| **2. Załamanie** (dni 19–35) | instytucje przestają działać — logistycznie, nie dramatycznie | 15 | 3 |
| **3. Potem** (dni 36+) | garstka ludzi, samoorganizacja, odejście | 12 | 3 |
| **9. Wątek własny** | co się działo z graczem, gdy spał | 6 | 2 |

**Bramkowanie faz:** fragmenty fazy 2 pojawiają się dopiero po znalezieniu 4 wcześniejszych, fazy 3 — po 10. Zachowuje z grubsza chronologię bez wymuszania kolejności i uniemożliwia znalezienie „końca" w pierwszym tygodniu.

### 20.3. Co się właściwie stało

**Choroba.** Zaczyna się gorączką, której nie umieją nazwać — testy na grypę wychodzą ujemne. Przechodzi w pobudzenie, na które nie działa sedacja. Przenosi się przez ugryzienia i zadrapania. **Gra nigdy nie wyjaśnia pochodzenia.** Nikt z piszących nie wie, skąd się wzięła, bo instytucje, które mogłyby to ustalić, przestały działać, zanim ustaliły.

**Trzy typy przeciwników to trzy stadia tej samej choroby** — i to wyjaśnia parametry, które mamy już w §6.2, bez zmiany choćby jednej liczby:

| Typ | Stadium | Dlaczego takie parametry |
| :---- | :---- | :---- |
| **Skakun** | najwcześniej zakażeni | najszybszy, najmniej krwi (2400–2800 ml) — wyniszczenie metaboliczne, sprint 25 s |
| **Szwędacz** | zakażeni w drugiej fali | grupy 2–4, bo zarazili się razem: rodziny, zakłady pracy, punkty zbiorcze |
| **Brutal** | najpóźniejsze stadium | 6000–8000 ml — obrzęk i zatrzymanie płynów; wolny, ale najsilniejszy |

⚠️ To jest darmowa spójność: notatka z dnia 14 („ci, którzy zachorowali najwcześniej, biegają najszybciej") wyjaśnia mechanikę, której gracz doświadcza codziennie, bez dopisywania nowych systemów.

**Upadek instytucji.** Nie było jednego uderzenia. Kolejno: nie przyjechała dostawa → padło paliwo → padł prąd → nie było kogo zapytać. Granice zamknięto w dwa dni i okazało się, że granica jest linią na mapie, a po obu stronach dzieje się to samo.

⚠️ **Neutralność obowiązkowa:** żadnych nazw państw, partii, przywódców ani realnych instytucji. Upadek jest **logistyczny, nie polityczny** — to jednocześnie uczciwsze, bardziej uniwersalne (gra działa na całym świecie) i zgodne z zasadą, że gra nie zajmuje stanowiska w sporach politycznych.

**Wątek własny.** Gracz budzi się we własnym mieszkaniu i nie wie, ile spał. Pierwszy fragment (`arc_own_00`, przyznawany automatycznie na starcie) to kartka **jego własnym pismem**, której nie pamięta: notatka o gorączce, o niewpuszczaniu nikogo, o tym, że gorączka spadła.

**Gracz przechorował i przeżył.** Kolejne fragmenty (ulotka z zapisem temperatury, urywające się na dniu ósmym) potwierdzają to bez wyjaśniania. ⚠️ **Nie ma mechaniki odporności** i gra nigdy tego nie tłumaczy — niedopowiedzenie działa mocniej niż wyjaśnienie, a wyjaśnienie natychmiast rodziłoby pytanie „to dlaczego nie mogę nic zrobić".

### 20.4. Archiwum — wypłata za zbieranie

Ekran w PROFILU (§3.6), obok Kroniki (§9.3). Znalezione fragmenty i notatki **układają się automatycznie po dacie**, tworząc czytelną oś czasu. Nieodkryte pozycje widoczne jako luki z zaznaczoną fazą.

To zamienia rozsypane kartki w coś, co da się przeczytać jako całość — i daje graczowi powód, żeby zaglądać do POI, których już nie potrzebuje dla lootu.

**Kamienie milowe (§19.7):** odkrycie 25%, 50%, 75%, 100% warstwy fabularnej. Bez nagrody mechanicznej — sam komplet jest nagrodą.

❓ **Do rozważenia:** czy ostatni odkryty fragment ma dawać domknięcie w postaci krótkiego podsumowania od gry. Rekomendacja: **nie.** Ostatni fragment ma być kolejną kartką, nie napisem końcowym.

### 20.5. Wytyczne redakcyjne — dodatkowe wobec §19.1.2

- **Dokumenty niosą system, ludzie niosą emocje.** Protokół z rozdzielni i rozkaz dzienny opowiadają, jak upadło państwo; zeszyt z parapetu opowiada, jak to wyglądało z okna. Potrzebne są oba, w mniej więcej równej proporcji.
- **Upadek przez szczegół, nie przez deklarację.** „Cena kilograma mąki: 3,49" mówi więcej niż zdanie o załamaniu gospodarki.
- **Ostatnie zdanie zamiast puenty.** Najlepsze fragmenty urywają się albo kończą czymś przyziemnym.
- **Żadnej nadziei na ratunek.** Ani jeden fragment nie może sugerować, że gdzieś jest bezpieczne miejsce, wojsko, lekarstwo. To złamałoby §13.1.
- Wszystkie zasady z §19.1.2 obowiązują, w szczególności **zakaz treści dotyczących odbierania sobie życia**.

---

## Załącznik: pliki definicji

```
assets/data/
├── items.json          89 przedmiotów (§10.3)
├── loot_tables.json    20 tabel: 11 POI z OSM + 9 punktów proceduralnych (§10.1, §10.3)
├── materials.json      surowce (§18.1)
├── weapons.json        broń palna (§4.2)
├── melee.json          broń biała (§4.3)
├── armor.json          odzież i pancerz (§4.4)
├── food.json           jedzenie i napoje (§4.7)
├── medical.json        medykamenty (§4.7)
├── literature.json     literatura, losowana liczba stron (§4.6.4)
├── tools.json          narzędzia (§4.7)
├── crafting.json       przedmioty craftingowe (§4.7)
├── recipes.json        receptury (§18.4)
├── enemies.json        przeciwnicy i modyfikatory osobnicze (§6.2, §19.6)
├── notes.json          notatki fabularne, dwujęzyczne, ~80 docelowo (§19.1)
└── story.json          fragmenty warstwy fabularnej, 4 fazy + wątek własny (§20.2)

assets/audio/
├── shipped/            ← tylko pliki z potwierdzoną licencją
│   ├── physiology/
│   ├── weapons/
│   ├── enemies/
│   ├── player/
│   ├── items/
│   ├── ui/
│   ├── ambient/
│   └── alerts/
├── prototype/          ← NIGDY nie trafia do release'u
└── CREDITS.md          ← wymagany wpis dla każdego pliku w shipped/

docs/licenses/          ← zrzuty stron licencyjnych (PDF/PNG)
```

⚠️ Wszystkie pliki `assets/data/` walidowane schematem przy buildzie (§11). Nazwy przedmiotów i statusów wyłącznie jako klucze ARB (§1.1); wyjątkiem są `notes.json` i `story.json`, gdzie teksty stoją w strukturze `text.{lang}` (§19.1.1).

---

*Kolejność i zakres prac implementacyjnych: [ROADMAP.md](ROADMAP.md).*
