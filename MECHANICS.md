# ARLS-ZA — mechaniki, stan faktyczny

**Co robi gra dzisiaj**, z liczbami wziętymi z kodu, a nie z zamiarów.

Ten plik istnieje, bo trzy dokumenty nie odpowiadały na to pytanie:

| Dokument | Odpowiada na |
| :---- | :---- |
| `ARLS-ZA_design_doc_v2.md` | **co** chcemy zbudować i **dlaczego** |
| `ROADMAP.md` | **w jakiej kolejności** i **kiedy etap jest skończony** |
| `CHECKLIST.md` | **co jest przetestowane** i **jakie mamy długi** |
| **`MECHANICS.md`** | **co gra faktycznie robi**, z liczbami |

Różnica jest istotna, bo w kilkunastu miejscach **świadomie odeszliśmy od dokumentu projektowego** — czasem dlatego, że jego liczby były wewnętrznie sprzeczne, czasem dlatego, że spacer pokazał coś innego. Te decyzje żyły dotąd wyłącznie w komentarzach w kodzie. [Sekcja 15](#15-odejścia-od-dokumentu-projektowego) zbiera je w jednym miejscu.

⚠️ **Reguła utrzymania tego pliku:** liczba zmieniona w kodzie i nieprzeniesiona tutaj czyni ten dokument gorszym niż jego brak. Przy każdej zmianie stałej — aktualizuj sekcję.

**Stan:** 2660 testów · schemat bazy **v37** · etapy 0–2 zamknięte, 3–6 i 8 przed testem w terenie.

---

## Spis sekcji

1. [Fundamenty — czas, zapis, determinizm](#1-fundamenty)
2. [Ciało — parametry postaci](#2-ciało)
3. [Metabolizm — kalorie, woda, tętno](#3-metabolizm)
4. [Krew, rany i wstrząs](#4-krew-rany-i-wstrząs)
5. [Sen — dwa zegary](#5-sen)
6. [GPS, ruch i bezpieczeństwo gracza](#6-gps-ruch-i-bezpieczeństwo)
7. [Mapa i znaczniki](#7-mapa-i-znaczniki)
8. [Przedmioty i ekwipunek](#8-przedmioty-i-ekwipunek)
9. [Loot — gdzie, ile, jak szukać](#9-loot)
10. [Walka — celność, obrażenia, hałas](#10-walka)
11. [Przeciwnicy](#11-przeciwnicy)
12. [Schron i obóz](#12-schron-i-obóz)
13. [Śmierć i utrata przytomności](#13-śmierć)
14. [Profil — statystyki postaci](#14-profil)
15. [Odejścia od dokumentu projektowego](#15-odejścia-od-dokumentu-projektowego)
16. [Zbudowane, jeszcze nieużyte](#16-zbudowane-jeszcze-nieużyte)
17. [Czego jeszcze nie ma](#17-czego-jeszcze-nie-ma)

---

## 1. Fundamenty

### 1.1. Czas

Gra liczy czas **zegarem ściennym**, nie czasem spędzonym przy ekranie. Wszystko, co trwa — trawienie, budowa, nieprzytomność, odnowa lootu — mija tak samo przy zamkniętej aplikacji.

| Reguła | Wartość | Gdzie |
| :---- | :---- | :---- |
| Krok symulacji | 1 s | `GameLoop.cadence` |
| Przerwa uznana za „niemierzone" | **> 5 min** | `kUnmeasuredGap` |
| Nadrabianie przerwy | w kawałkach po 1 h | `advanceInChunks` |
| Podłoga offline | 10% zapasu | `SimConstants.offlineFloor` |

**Zawór offline (§2.1.1).** Przerwa dłuższa niż 5 minut jest odtwarzana, ale zasoby nie mogą spaść poniżej 10% — telefon w kieszeni nie zabija postaci głodem.

**Ochrona przed cofnięciem zegara.** Najwyższy zaakceptowany czas zapisany w bazie; ustawienie zegara wstecz nie daje darmowej regeneracji.

### 1.2. Zapis

- Drift/SQLite w trybie WAL, każdy zapis w transakcji.
- **Migracje wyłącznie addytywne** — kolumna nigdy nie jest usuwana ani zmieniana. Aktualny schemat **v18**, wszystkie wersje od v1 mają test migracji na wygenerowanych danych.
- Warstwa gorąca (`vitals`) zapisywana co **60 s** i przy każdym `onPause`.
- Rotujące migawki, `PRAGMA wal_checkpoint(TRUNCATE)` przy wyjściu w tło.
- ⚠️ `allowBackup="false"` — baza zawiera adres domowy gracza (schron).

### 1.3. Determinizm

Każda postać ma jedno ziarno RNG (`rngSeed`), nadane raz przy tworzeniu. Z niego wynikają: rozmieszczenie lootu, zawartość skrzyń, punkty generowane proceduralnie, zawartość zwłok. **Ta sama wioska wygląda tak samo między sesjami.**

---

## 2. Ciało

Postać powstaje z czterech danych podanych przez gracza: **płeć, wiek, wzrost, waga**. Wszystko inne jest z nich wyliczone.

| Parametr | Wzór | Zakres wejścia |
| :---- | :---- | :---- |
| Objętość krwi | Nadler | wiek 16–80 |
| Zapotrzebowanie energetyczne | Mifflin–St Jeor × 1,375 | wzrost 120–220 cm |
| Woda dobowa | 35 ml × masa ciała | waga 35–200 kg |
| Tętno spoczynkowe | szacowane lub podane | 35–110 bpm |
| Tętno maksymalne | 220 − wiek | — |
| BMI | walidacja | 12–60 |

### 2.0. ⚠️ Masa ciała jest **stanem**, nie stałą

Od schematu v28 waga postaci się rusza. Deficyt kaloryczny ją zjada, nadwyżka odkłada (§3.4a) — a wtedy **wszystkie wiersze powyżej przeliczają się razem z nią**.

| Co idzie za masą | Skutek chudnięcia |
| :---- | :---- |
| Udźwig 30% / 45% (§18.1a) | mniej udźwigniesz |
| Mifflin–St Jeor | mniejsze zapotrzebowanie → wolniejszy dalszy spadek |
| Woda dobowa 35 ml/kg | mniejszy zapas i **niższe progi** odwodnienia |
| Objętość krwi (Nadler) | mniej krwi do stracenia |

`BodyProfile` jest przeliczany, gdy waga drgnie o **0,25 kg**. Adaptacja metaboliczna wychodzi z tego za darmo — nikt nie pisał krzywej.

⚠️ **Krew skaluje się proporcjonalnie razem z sufitem.** Gdyby mililitry stały w miejscu przy opadającym maksimum, sam spadek wagi podniósłby *ułamek utraconej krwi* i wrzucił wychudzoną postać w klasę III wstrząsu bez jednego zadrapania. Po przeskalowaniu ułamek zostaje tam, gdzie był; zmienia się tylko to, że każda przyszła rana jest większą częścią mniejszego ciała.

⚠️ **Jest dokładnie jedna masa.** `SimConstants.bodyMassKg` istniało kiedyś obok i nikt go nie wypełniał, więc progi odwodnienia mierzyły każdą postać miarką osoby 80 kg. Zostało usunięte. Została `startingMassKg`, która naprawdę jest stała i odpowiada na inne pytanie — **ile mnie ubyło**. Postać 55 kg przy 50 kg ma kłopoty, postać 95 kg przy 50 kg nie żyje.

### 2.1. Dwa limity udźwigu (§18.1a)

| Limit | Wartość | Skutek przekroczenia |
| :---- | :---- | :---- |
| **Komfortowy** | 30% masy ciała | dodatkowe kalorie, wolniejszy marsz |
| **Twardy** | **45% masy ciała** | nie da się podnieść |
| **Objętość** | pojemność plecaka | druga, niezależna ściana |

⚠️ Objętość jest **osobnym** limitem. Plecak metalu kończy się na masie, plecak plastiku na objętości, i żadna z tych liczb nie przewiduje drugiej. Kieszenie bez plecaka: **12 l**.

**Udźwig gender-neutralny** — świadoma decyzja, nie przeoczenie.

---

## 3. Metabolizm

### 3.1. Strefy (§2.1)

Zużycie skaluje się od tego, gdzie postać jest. To jest powód, dla którego zamknięcie aplikacji pod dachem jest tańsze niż w terenie.

| Strefa | Kalorie | Woda |
| :---- | ----: | ----: |
| Otwarty teren | 100% | 100% |
| Obóz | 50% | 55% |
| Schron | 35% | 40% |
| Sen | **20%** | **30%** |

### 3.2. Wchłanianie (§2.2, §2.3)

Zjedzone **nie jest** natychmiast we krwi. Trafia do żołądka i przechodzi dalej ze stałą prędkością:

| | Tempo | Przykład |
| :---- | :---- | :---- |
| Woda | **25 ml/min** | pół litra = **20 minut** |
| Kalorie | **8 kcal/min** | puszka 500 kcal = **~62 minuty** |

Na pasku HUD widać to jako znacznik `+` przed wypełnieniem. To jest cała mechanika: jedzenie jest czymś, co się nosi i bierze **zanim** będzie potrzebne, a nie przyciskiem wciskanym, gdy pasek czerwienieje.

**Znacznik kierunku ma każdy z czterech pasków** — woda, kalorie, sen, krew:

| Pasek | `+` gdy | `−` gdy | Co pokazuje znacznik |
| :---- | :---- | :---- | :---- |
| Woda | trwa wchłanianie | — | ile jeszcze wejdzie z żołądka |
| Kalorie | trwa wchłanianie | — | jw. |
| Sen | postać **śpi** | — | godzina snu do przodu |
| Krew | regeneracja (§4) | otwarta rana | godzina do przodu w obie strony |

⚠️ Woda i kalorie mają **kolejkę** — coś realnie leży w żołądku i znacznik pokazuje to coś. Sen i krew mają tylko **tempo**, więc znacznik pokazuje, gdzie ląduje **godzina** przy obecnym tempie. Ta sama godzina dla obu, żeby dały się czytać jedno przy drugim.

Brak znacznika na śnie, gdy postać nie śpi — dług rośnie każdą godzinę na jawie, a znak, który jest zawsze, nie mówi nic. Brak znacznika na krwi przy pustym żołądku — krew powstaje z tego, co zjedzone i wypite, więc głodujący nie regeneruje i pasek tego nie obiecuje.

⚠️ Zapas jest **capowany dobowym zapotrzebowaniem**, ale nadmiar **nie jest już wyrzucany** — idzie w ciało (§3.4a). Wcześniej cztery puszki na pełny żołądek nie dawały nic i nigdy nie było powodu, żeby najeść się przed wyprawą.

### 3.3. Progi odwodnienia

Liczone jako **deficyt względem masy ciała**, nie względem paska:

| Deficyt | Skutek |
| :---- | :---- |
| ≥ 2% masy ciała | celność ×0,85 |
| ≥ 5% | **czas czynności ×1,30** |
| ≥ 10% | stan krytyczny, **czas czynności ×1,60** |
| > 48 h bez wody **przy wysiłku** | śmiertelne |
| ≥ 10% utrzymane **> 12 h** | śmiertelne |

⚠️ Woda może zejść **poniżej zera**. Zapas to dobowe zapotrzebowanie (2 800 ml dla 80 kg), a progi to procenty masy ciała (2% = 1 600 ml, 10% = 8 000 ml) — clampowanie na zerze uczyniłoby dwa z trzech progów nieosiągalnymi.

⚠️ **Progi 5% i 10% nie miały do niedawna żadnej konsekwencji.** Z trzech wierszy tylko pierwszy był do czegokolwiek podpięty, więc postać w stanie krytycznym strzelała tak samo jak lekko spragniona i wszystko robiła w pełnym tempie. Głód był jedyną z tej pary, która kogokolwiek spowalniała — dokładnie odwrotnie, niż nakazuje §2.3.

⚠️ **Drugi próg śmiertelny (12 h w stanie krytycznym) to rozszerzenie**, nie zapis z dokumentu. §2.3 daje pragnieniu jedną regułę i kwalifikuje ją słowami „w warunkach wysiłku" — samo to czyni nieśmiertelnym kogoś, kto siedzi w schronie, bo zapas ma podłogę na 10% masy ciała i tam zostaje.

⚠️ **Pragnienie nie ma osi długoterminowej i to jest właściwa odpowiedź.** Odwodnienie nie ma pamięci: napijesz się i jesteś zdrowy. Kontrast z jedzeniem (§3.4a) jest całym sensem tej pary.

### 3.3a. Drabinka kar — co widzi gracz (§12)

⚠️ **Gra karała za wodę, jedzenie i sen i nigdzie nie mówiła jak.** Kara była
widoczna dopiero wtedy, gdy już bolała, więc „zostało mi pół butelki" było
liczbą bez ceny. Trzy wiersze w profilu (Woda, Kalorie, Dług senny) otwierają
teraz arkusz z całą drabinką i zaznaczonym szczeblem, na którym gracz stoi.

| Witalność | Próg | Co robi |
| :---- | :---- | :---- |
| **Woda** | −2% masy ciała | celność −15% |
| | −5% | + wszystko o 30% dłużej |
| | −10% | + wszystko o 60% dłużej |
| **Jedzenie** | poniżej 50% zapasu | celność −10% |
| | poniżej 20% | + wszystko o 20% dłużej |
| **Sen** | od 4 h długu | rozrzut +1 MOA |
| | od 12 h | rozrzut +3 MOA, wszystko o 50% dłużej, nauka −20% |

⚠️ **Szczeble są generowane z tych samych funkcji, które karzą** — przejściem
po dziedzinie i zapisaniem każdego miejsca, w którym kara się zmienia. Wpisane
ręcznie rozjechałyby się z modelem przy pierwszej zmianie progu, a ekran, który
kłamie o karach, jest gorszy od ekranu, który milczy.

⚠️ Każdy szczebel mówi **cały** stan, nie samą różnicę: przy pięciu procentach
ubytku wody celność dalej jest niższa o piętnaście, i gracz widzi to na tym
wierszu, zamiast składać z dwóch.

### 3.4. Głód — dobowy zapas

| Zapas | Skutek |
| :---- | :---- |
| < 50% | precyzja ×0,90 |
| < 20% | wszystkie czynności ×1,20 czasu |
| 0 przez > 24 h | **utrata przytomności — nie śmierć** |

⚠️ **Puste konserwy to nie puste ciało.** Ostatni wiersz był wdrożony jako zgon i to psuło całą oś: zapas to *dobowa* porcja jedzenia, więc postać bez zapasów stoi na zerze od drugiego poranka klęski głodu aż do jej końca. Głód zabijał w 48 godzin — szybciej niż pragnienie, w sekcji, która wprost nakazuje odwrotnie. Teraz przewraca, a zabija wychudzenie.

### 3.4a. Głód długoterminowy — masa ciała (§2.3.1)

Bilans energii nie ginie na żadnym końcu. Niedobór schodzi z ciała, nadwyżka wraca.

```
masa [kg] += (nadwyżka × 0,75 − niedobór) / 7000
```

| Stała | Wartość | Dlaczego |
| :---- | ----: | :---- |
| `kKcalPerKgOfBody` | **7000** | nie 7700 z tabeli czystego tłuszczu — organizm pod deficytem spala ~3 części tłuszczu na 1 część tkanki chudej, a ta jest w większości wodą |
| `kSurplusStorageEfficiency` | **0,75** | magazynowanie jest stratne; tydzień objadania się nie cofa tygodnia głodu |
| `kFatalMassLoss` | **30%** masy startowej | granica kliniczna |

| Ubytek masy startowej | Skutek |
| :---- | :---- |
| 0–5% | brak |
| 5–15% | czas czynności ×1,15 |
| 15–30% | czas czynności ×1,40, **+2 MOA** |
| > 30% | śmierć |

**Przebieg dla 80 kg, głodówka totalna, bezruch:**

| Dzień | Masa | Ubytek | |
| :---- | ----: | ----: | :---- |
| 7 | 77,6 kg | 3,0% | nic |
| 14 | 75,2 kg | 6,0% | ×1,15 |
| 42 | 66,1 kg | 17,4% | ×1,40, +2 MOA |
| 75 | 55,9 kg | 30,1% | koniec |

W marszu szybciej. Literatura daje 6–10 tygodni głodówki totalnej.

⚠️ **Przy zamkniętej aplikacji nic nie schodzi z ciała** (§2.1.1). Podłoga offline istnieje po to, żeby telefon w szufladzie nikogo nie zabił, a dwa tygodnie niepilnowanego chudnięcia przeszłyby przez nią bokiem. Nadwyżka liczy się dalej — co zjedzone, to zjedzone.

⚠️ **Liniowość nadrabiania przestała być dokładna.** Tempo spalania to `MET × 3,5 × masa / 200`, a masa się rusza — więc bieg w kawałkach widzi, jak postać lżeje, a jeden wielki krok nie. Ten sam kształt, który regeneracja krwi ma od zawsze, i ograniczony tak samo przez `advanceInChunks`: **kilokaloria na 5200** przez sześć godzin marszu.

### 3.4b. Asymetria woda / jedzenie

Nie jest projektowana — **wypada ze stałych §1.3**. Zapas to doba jednego i drugiego, ale progi pragnienia są ułamkami masy ciała, a ciało niesie miesiące tłuszczu i około trzech dób wody.

| | Do stanu krytycznego | Do zgonu |
| :---- | :---- | :---- |
| **Woda** | ~2,9 doby w bezruchu | 2–3 doby w marszu |
| **Jedzenie** | ~6 tygodni | ~10 tygodni |

Stosunek ~25 : 1. Nikt tego nie projektował — trzeba było to tylko podłączyć.

### 3.5. Tętno (§2.4)

Dąży do celu wyznaczonego przez MET, stałą czasową **90 s**. Sen: −14 bpm, podłoga 35 bpm. MET maksymalne 14.

Tętno jest jednocześnie wskaźnikiem wytrzymałości, której gra nie ma osobno — i **największym pojedynczym źródłem rozrzutu strzału** (sekcja 10).

---

## 4. Krew, rany i wstrząs

**Krew jest paskiem zdrowia, którego ta gra nie ma.** Wszystko, co rani, wyrażone jest w mililitrach.

### 4.1. Klasy wstrząsu (ATLS, §2.6)

| Utrata | Klasa | Stan |
| :---- | :---- | :---- |
| < 15% | I | brak objawów |
| 15–30% | **II** | +2 MOA, −10% udźwigu |
| 30–40% | **III** | +5 MOA, przyciemniony obraz, brak biegu bez zawrotów |
| > 40% | **IV** | utrata przytomności → śmierć |

### 4.2. Krwawienie (tiery)

| Typ | Ubytek | Czym zatrzymać |
| :---- | ----: | :---- |
| Powierzchowne | 3 ml/min | samo po 3–5 min |
| Umiarkowane | 25 ml/min | opatrunek uciskowy |
| Silne | 90 ml/min | opatrunek + unieruchomienie |
| Tętnicze | **350 ml/min** | wyłącznie staza |

**Modyfikator wysiłku:** `ubytek × (tętno / tętno_spoczynkowe)`. Bieg przy krwawieniu przyspiesza utratę — przy 160 bpm wobec 70 jest to **2,3×**.

Krwawienie **przeżywa wygaszenie ekranu** (kolumna w bazie). Opatrunek schodzi do stopnia, który obsłuży, i nie niżej — opatrunek na tętnicze nie zadziała.

### 4.3. Regeneracja krwi

⚠️ **Tego nie ma w dokumencie projektowym.** Bez tego przeżycie ciężkiej walki było dożywociem w klasie IV.

| | |
| :---- | :---- |
| Tempo | **60 ml/h** |
| Warunek | najedzenie **i** nawodnienie (gorsze z dwóch) |
| Podczas krwawienia | **zero** |

Ubytek 2 l wraca w ~1,5 doby, jeśli gracz je i pije. Nie da się napełnić wiadra z dziurą — zatrzymanie krwawienia jest pierwszą robotą, nie opcjonalną.

---

## 5. Sen

**Sen jest stanem, nie akcją.** Gracz nic nie klika. Zero uprawnień, zero Health Connect, zero danych zdrowotnych — wiążąca decyzja architektoniczna.

### 5.1. Warunki

Postać śpi, gdy **jednocześnie**:

1. jest w strefie schronu (50 m) lub obozu (20 m),
2. **nie wykonuje żadnego zajęcia ani czynności**,
3. **i** jest noc **albo** minęło **10 minut** spokoju.

| | |
| :---- | :---- |
| Zapotrzebowanie dobowe | **8 h** |
| Próg „usadowienia się" | **10 min** |
| Jakość — schron | 100% |
| Jakość — obóz | **70%** |
| Moduł Salon | +15% na poziom (maks. +45%) |

Noc wyliczana offline ze wschodu i zachodu słońca dla szerokości geograficznej i daty. **Naturalna sezonowość bez żadnego modyfikatora**: 21 czerwca w Poznaniu noc trwa 7,4 h (dług narasta mimo schronu), 21 grudnia 16,6 h.

**Wybudza:** rozpoczęcie czegokolwiek (budowa, crafting, lektura, jedzenie, opatrunek, przeszukanie) albo wyjście ze strefy.

### 5.1a. Noc, której nikt nie widział (§2.5.1, §11.1.2)

⚠️ **Zgłoszone z terenu: „noc 100% w schronie, a dług senny został".** Gracz
wyszedł ze schronu wieczorem, aplikacja zgasła na ulicy, wrócił do domu i
przespał noc. Odtworzenie przerwy brało **ostatnią zapisaną pozycję** — tę
ulicę — więc osiem godzin snu wracało jako osiem godzin czuwania na dworze.

| | Wartość |
| :---- | ----: |
| Przerwa, od której się czeka | **15 min** |
| Ile się czeka na świeży odczyt | **20 s** |

Pozycja sprzed ośmiu godzin nie mówi nic o tym, gdzie postać jest teraz, więc
długa przerwa **czeka** na pierwszy świeży odczyt. Czeka tylko wtedy, gdy
odpowiedź może się zmienić: bez schronu na mapie albo z postacią, która i tak
stoi w swoim, liczy się natychmiast. Po dwudziestu sekundach liczy się z tego,
co jest — pod dachem odbiornik bywa głuchy (§2.1a.4), a fizjologia, która stoi,
bo GPS milczy, byłaby gorsza od źle policzonej.

⚠️ Świeży odczyt bije lepką pozycję z interfejsu: tę ustawia §3.2 i po nocy z
zamkniętą aplikacją jest ona sprzed nocy.

### 5.2. Skutki długu — **ostatnia noc**

| Dług | Skutek |
| :---- | :---- |
| 0–4 h | brak |
| 4–12 h | +20% czasu lektury, **+1 MOA** |
| 12–24 h | +50% czasu wszystkich czynności, **+3 MOA**, −20% nauki |
| > 24 h | **mikrosny** — 5–15 s zablokowania interfejsu |

Sufit długu: **24 h**. Dalej nie ma nic gorszego, więc głębszy dołek byłby tylko dłuższą wspinaczką — i paskiem, który czyta się jako pusty tak samo.

### 5.3. Obciążenie przewlekłe — **ostatni miesiąc** (§2.5.5)

⚠️ **Dług z §2.5.4 mierzy ostatnią noc i tylko ją.** Ma sufit doby, kasuje się w dobę, a ponieważ narasta wyłącznie w czasie *czuwania* — na sześciogodzinnych nocach wychodzi na zero i nie drga. Szesnaście godzin na nogach jest warte 5 h 20 min długu, noc spłaca sześć. Trzy tygodnie niedosypiania czytały się jak jeden zarwany wieczór.

Drugi zegar liczy się wobec **zegara ściennego**, tak jak mówi formuła §2.5.3: doba potrzebuje ośmiu godzin niezależnie od tego, co się w niej robiło.

```
obciążenie += 1 − S/8      (S = godziny snu w dobie)
```

| Sytuacja | Obciążenie | Skutek |
| :---- | ----: | :---- |
| jedna noc krótsza o 2 h | 0,25 | **brak** |
| cztery noce po 4 h | 2,0 | −20% nauki, tętno wraca ×1,35 wolniej |
| dwa tygodnie po 6 h | 3,5 | −40% nauki, **+1 MOA**, gojenie −30% |
| dwa miesiące po 6 h | 10 (sufit) | **+2 MOA**, gojenie −50%, mikrosny |

⚠️ **Kary są celowo te, których pasek snu NIE pokazuje** — gojenie, uspokajanie tętna, ręce. Tak działa przewlekłe niedosypianie: subiektywna senność się wypłaszcza, a wydolność dalej spada. Po jednej dobrej nocy pasek jest pełny, a liczby dalej złe. To jest sedno mechaniki i dlatego ma **własną notatkę stanu „WYCZERPANIE"** (§12) — kara bez widocznego powodu czyta się jako błąd, choćby najprawdziwsza.

**Spłaca tylko noc dłuższa niż potrzeba.** Regeneracja po przewlekłej deprywacji wymaga snu nadmiarowego, nie wystarczającego — i to sadza całą oś na sezonowości §2.5.3, bez jednego modyfikatora:

| Poznań | Noc | Co się dzieje |
| :---- | ----: | :---- |
| 21 czerwca | 7,4 h | obciążenie narasta **cokolwiek zrobi gracz** |
| 21 grudnia | 16,6 h | cztery takie noce kasują całe lato |
| **Salon (§8.4)** | — | jedyna rzecz kupująca regenerację **poza sezonem** |

⚠️ **Podłoga stanu jest jedną nocą poniżej zera, nie na zerze.** Doba przeżywa się jako noc, a potem dzień, więc spłata nocy przychodzi przed godzinami czuwania, które ma skasować. Twarda podłoga na zerze wyrzucałaby tę spłatę każdego poranka i ktoś śpiący pełne osiem godzin narastałby o jedną trzecią nocy dziennie w nieskończoność. Nic poniżej zera nie jest czytelne jako zapas — §2.5.3 zabrania banku wprost.

---

## 6. GPS, ruch i bezpieczeństwo

### 6.1. Filtrowanie pozycji (§3.2)

| Reguła | Wartość |
| :---- | :---- |
| Bramka dokładności | odrzuca `accuracy > 25 m` |
| Martwa strefa | **8 m** netto w oknie |
| Filtr | Kalman na strumieniu |
| Utrata sygnału | > 60 s → pauza symulacji ruchu |

⚠️ **Dwie różne pozycje.** `fix` przeszedł bramkę i decyduje, co liczy się jako **ruch**. `displayFix` to najlepsza pozycja jakiejkolwiek szerokości i decyduje, gdzie **narysować** gracza. W budynku każdy odczyt ma 30–60 m i żaden nie jest marszem — ale gracz gdzieś stoi.

**Pozycja jest „lepka"**: snapshot bez pozycji to telefon, który nie ma nic do powiedzenia, a nie gracz, który zniknął. Na starcie zasiewana z zapisu.

### 6.2. Anti-cheat (§3.4)

- Wykrywanie mock location.
- **> 40 km/h przez > 30 s** = pojazd → zawieszenie rozgrywki (nie kara).

### 6.3. Bezpieczeństwo gracza (§3.5)

**Strefy wykluczone ze spawnu:** drogi główne (15 m od jezdni), tory czynne, woda, cmentarze, teren wojskowy, tereny religijne, szkoły i przedszkola.

**Blokada walki:** prędkość > **15 km/h** albo zawieszony run. To nie balans — to ktoś na rowerze albo przechodzący przez jezdnię bez patrzenia.

### 6.4. Bateria (§3.3)

| Aktywność | Częstotliwość GPS |
| :---- | :---- |
| Walka | 1 Hz |
| Marsz | 0,2 Hz |
| Postój | 0,05 Hz |

Ostrzeżenie przy **20%**, tryb ekonomiczny: brak animacji, kamera skacze zamiast płynąć.

---

## 7. Mapa i znaczniki

### 7.1. Renderowanie

⚠️ **MapLibre rysuje wyłącznie kafelki.** Wszystkie znaczniki, pierścienie, stożki, glify i fale hałasu maluje Flutter w jednym `paint()` na klatkę.

Powód nie jest estetyczny: adnotacje MapLibre kosztują przelot przez platform channel każda, do 65 sztuk, przepisywane przy każdym ruchu. Ta jedna decyzja stała za trzema błędami — utratą płynności przy szczypaniu, pustą mapą po zimnym starcie i glifami odklejającymi się od kropek.

Dziś kropka i palec, który w nią trafia, liczone są **z tej samej arytmetyki**.

### 7.1a. Pochylenie i bryły budynków (§3.6)

Kamera stoi pochylona o **45°, na stałe**. Gest pochylania pozostaje wyłączony: mapa czytana w marszu ma być za każdym razem tą samą mapą, a jeden kąt znaczy, że perspektywa znaczników jest liczona raz i nie może się rozjechać z kafelkami.

Warstwa `building` jest **wytłaczana**, nie wypełniana. Wysokości są zmierzone (`render_height`, `render_min_height` — dwa z trzech pól, jakie ta warstwa niesie; patrz `omt_schema.dart`), a nie zgadywane.

| | |
| :---- | :---- |
| Pochylenie | **45°** |
| Wytłaczanie od zoomu | **14** |
| Domyślna wysokość bez danych | **8 m** |
| Krycie bryły | 0,85 |

⚠️ **Domyślne 8 m ma powód.** Obrys bez wysokości jest w OSM poza centrami częsty, a `['get', ...]` na brakującym polu daje null, który wytłacza się do zera — dziura w ulicy tam, gdzie stoi dom. Dwa piętra to uczciwa wartość dla budynku, którego nikt nie zmierzył.

⚠️ **Bryły nie są całkiem kryjące.** Znaczniki maluje Flutter *nad* kafelkami, więc rysują się na wierzchu niezależnie od geometrii. Pełne krycie sprawiłoby, że Szwędacz za budynkiem czytałby się jak Szwędacz przed nim.

**Rzut pochylonej mapy** — jedna para funkcji w `map_markers.dart`, w obie strony:

```
right   = x
up      = y · cos θ
forward = D + y · sin θ
```

dla punktu `x` na wschód i `y` na północ od środka, odległości kamery `D` i pochylenia `θ`. Dzielenie dwóch pierwszych przez trzecie to całość. Przy θ = 0 człon `forward` to samo `D`, dzielenie się skraca i zostaje stary płaski wzór — co pilnuje, żeby obie wersje nie rozjechały się przy edycji.

`D` to **1,5 wysokości ekranu** — z własnej reguły MapLibre `0.5 / tan(fov/2) × height` przy domyślnym polu widzenia 0,6435 rad.

⚠️ **Tolerancja dotknięcia rośnie z perspektywą.** Palec przy górnej krawędzi pochylonej mapy przykrywa znacznie więcej terenu niż ten sam palec na dole. Bez skalowania dalsza połowa mapy byłaby nieklikalna, a bliższa kradłaby dotknięcia sąsiadom.

### 7.1a bis. Jasny i ciemny styl (§17.2, §12)

**Jedna granica na jedno niebo.** Styl „dzień i noc" przełącza się dokładnie na
tych dwóch godzinach, które panel drukuje: Świt i Zmierzch, czyli cywilny
zmierzch, sześć stopni pod horyzontem (`darkness >= 1`).

⚠️ Paleta miała własny próg 0,5 — mniej więcej trzy stopnie — czyli drugą
odpowiedź na to samo pytanie, rozjeżdżającą się dwa razy na dobę. Zgłoszone z
terenu: zegar 06:03, Świt 05:28, styl dalej nocny.

⚠️ **Brak odczytu to nie jest południe.** Niebo liczyło się wyłącznie z
bramkowanego odczytu, a §2.1a.4 pod dachem ścisza odbiornik — więc dokładnie
tam, gdzie gracz śpi, gra raportowała pełny dzień i pustą parę Świt/Zmierzch.
Teraz bierze tę samą lepką pozycję, z której mierzy wszystko inne.

### 7.1b. Krój pisma i płynność

| | |
| :---- | :---- |
| Interfejs | **IBM Plex Sans** (plik zmienny — wszystkie grubości i szerokości) |
| Liczby | **IBM Plex Mono** |
| Licencja | SIL OFL 1.1, `assets/fonts/OFL.txt` |
| Waga w APK | ~800 kB |

⚠️ **Cyfry obu krojów mają dokładnie 600/1000 em** — zmierzone z plików, nie założone. Liczba złożona jednym krojem ma tę samą szerokość co ta sama liczba złożona drugim, więc mieszanie ich w kolumnie o stałej szerokości nie może rozwalić układu.

⚠️ **IBM Plex Sans nie ma cechy `tnum`**, więc `FontFeature.tabularFigures` nic w nim nie robi — i nie musi. Oba kroje są tabelaryczne **domyślnie**, każda cyfra ma tę samą szerokość. To właśnie było tym, o co te kilkanaście wywołań prosiło.

**Wysokie odświeżanie (90/120 Hz)** włącza się dokładnie wtedy, kiedy §3.3 pozwala na animacje — czyli poza trybem ekonomicznym. Płynność to ten sam rodzaj luksusu co animacja, więc znika w tym samym momencie. Bez drugiego ustawienia i bez drugiego pojęcia dla gracza.

### 7.2. Zasięgi rysowane wokół gracza

Zasięg jest symetryczny, więc jeden okrąg wokół gracza mówi to samo, co 65 kółek wokół rzeczy.

| Promień | Znaczy |
| ----: | :---- |
| **25 m** | tak blisko trzeba być, żeby przeszukać miejsce |
| **15 m** | zasięg ręki — podniesienie czegoś z ziemi |

⚠️ **Strefa schronu (50 m) nie jest zasięgiem.** To kawałek ziemi i rysowana jest wokół schronu, nie wokół gracza.

### 7.3. Ikony typów miejsc

Dziewięć kształtów, czytanych z **tabeli lootu** (bo to ona decyduje, co jest w środku), nie z tagu OSM:

| Ikona | Miejsca |
| :---- | :---- |
| ✚ krzyż | apteka, szpital, karetka |
| 🛡 tarcza | wojsko, radiowóz |
| 🍴 sztućce | spożywcze |
| 🔧 klucz | warsztat, przemysł, magazyn, garaż |
| ◎ celownik | broń, sport, ambona |
| 📖 książka | biblioteka, szkoła |
| 🏠 dom | mieszkanie, stodoła, schron |
| 🚗 auto | porzucony samochód |
| 🗑 kosz | śmietniki, pobocza |

**Dziewięć i ani jednego więcej** — jest test, który pęknie, jeśli legenda urośnie.

### 7.4. Zoom i grupowanie

| | |
| :---- | :---- |
| Zoom startowy | 17,5 |
| Najbliżej | 19 |
| Najszerzej | **3 km** przez ekran |
| Grupowanie znaczników | **25 m** |

⚠️ MapLibre serwuje kafelki **512 px** — `metresPerPixel = 156543,03392/2 × cos(lat) / 2^zoom`. Pomylenie tego z konwencją 256 px czyniło każdą odległość dwa razy węższą.

Mapy **nie da się przeciągnąć**. Gracz jest zawsze na środku.

### 7.5. Skąd biorą się kafelki (§3.1, §16.6)

Gra **nie ma serwera kafelków** i nigdy nie odpytuje `tile.openstreetmap.org`
— polityka tego serwera zabrania użycia produkcyjnego, a naruszenie kończy się
blokadą po IP.

| | |
| :---- | :---- |
| Format | **PMTiles v3**, jeden plik na region |
| Dekoder MVT | własny, czytany w `Isolate.run` |
| Warstwy używane | `poi`, `landuse`, `landcover`, `transportation`, `water` |
| Zoom POI | 14 |
| Katalog regionów | `assets/regions.json` |

Dwie drogi do kafelków: **pobrana paczka** na urządzeniu albo **strumień po
zakresach bajtów** z tego samego archiwum na hoście (§16.6), gdy gracz nie chce
pobierać 50–200 MB. Paczka zawsze wygrywa.

⚠️ Warstwa budynków w paczkach **nie niesie typu** — `building=house` nie
pasuje do niczego, jakkolwiek napisać selektor. Stąd bierze się cały §10.1
(punkty wymyślane) i stąd budynki nie blokują jeszcze ruchu przeciwników.

---

## 8. Przedmioty i ekwipunek

### 8.1. Sloty na ciele

Głowa, tors (odzież), tors (pancerz), nogi, stopy, dłonie, **ręce** (broń), plecy (plecak).

**Broń w ręku jest `worn`**, nie w plecaku — to częste źródło pomyłek przy zmianach w kodzie.

### 8.2. Stan pojedynczej sztuki

Każda sztuka niesie własny stan i **nigdy nie jest utożsamiana z innymi o tym samym id**:

| Pole | Znaczenie |
| :---- | :---- |
| `condition` | zużycie, 0–100% |
| `portion` | ile zostało z otwartej porcji (0–1) |
| `pagesTotal` / `pagesRead` | postęp lektury |
| `noteId` | która to notatka |
| `attachments` | co jest przykręcone |

⚠️ **Id przedmiotu to nie tożsamość.** Dwie konserwy, jedna napoczęta — to dwa różne przedmioty. Ta pomyłka wracała pięciokrotnie.

### 8.3. Dodatki do broni (§5.6.3)

Siedzą **na konkretnej sztuce broni**, nie na graczu. Dwa karabiny w plecaku to dwa karabiny — ten z tłumikiem jest tym, który warto wziąć do miasta.

| Dodatek | Efekt |
| :---- | :---- |
| Kolimator | −1,2 MOA, celowanie ×0,85 |
| Chwyt przedni | −0,5 MOA, celowanie ×0,8 |
| Laser | celowanie ×0,6, widoczny dla przeciwników |
| Latarka | 20 m światła, widoczna dla przeciwników |
| Magazynek przedłużony | +10 naboi, +0,5 s przeładowania |
| Tłumik | hałas **×0,29**, +0,3 MOA |

Liczba slotów zależy od broni (rewolwer 1, karabin 3). **Masa dodatków wlicza się do udźwigu.** Dodatki przeżywają wyrzucenie broni na ziemię.

### 8.4. Narzędzia do barier

| Narzędzie | Masa | Otwiera | Czas | Hałas |
| :---- | ----: | :---- | ----: | ----: |
| **Wytrychy** | 0,1 kg | drzwi, kłódka | 60 / 45 s | **20 m** |
| **Nożyce do kłódek** | 1,9 kg | kłódka | **10 s** | 60 m |
| Łom | 1,2 kg | drzwi, kłódka | 12 / 25 s | 150 / 60 m |
| Siekiera | 1,6 kg | drzwi | 12 s | 150 m |

Bez narzędzia zostaje ramię: **drzwi 90 s / 200 m**, okno 10 s / 160 m, kłódka
nigdy.

Łom i siekiera są jednocześnie bronią białą — `doubles_as_tool`.

**Narzędzie się zużywa** — `condition_decay_per_use`, po jednym otwarciu:

| Narzędzie | Zużycie na użycie | Starcza na |
| :---- | ----: | ----: |
| **Wytrychy** | **2%** | **50 zamków** |
| Łom, siekiera, nożyce | 0,1–0,3% | setki |

⚠️ **Schodzi egzemplarz najbardziej zużyty, nie pierwszy z brzegu.** Kto nosi
dwa komplety, dorabia się jednego całego i jednego na wykończeniu — tak robi
każdy, kto ma w kieszeni dwa scyzoryki.

⚠️ **Broń w ręce stoi w obu listach naraz.** Prawdziwy egzemplarz z uid zostaje
w plecaku, a lista noszonych trzyma sam znacznik slotu — bez uid i bez
kondycji. Zużycie znacznika byłoby zużyciem niczego.

Panel przeszukania nazywa **to narzędzie, którym gra naprawdę otworzy**:
pierwsze z `tool_ids`, które gracz ma. Drzwi ustępują łomowi *albo* siekierze, a
panel pokazujący jedno, kiedy zużywa się drugie, byłby gorszy od milczącego —
gracz zapamiętałby cenę, której nie zapłacił.

### 8.5. Zestaw startowy (§4, §12)

Drugi etap tworzenia postaci: cztery wybory po dwie możliwości, obie na ekranie
naraz i z opisem pod spodem.

| Krok | Jedno z | O czym rozstrzyga |
| :---- | :---- | :---- |
| 1 | łom · **1 wytrych** | drzwi szybko czy cicho |
| 2 | 5 opatrunków · apteczka | wiele drobnych ran albo jedna poważna |
| 3 | maczeta · siekiera | co jest w ręce, kiedy zabraknie dystansu |
| 4 | 2 puszki mięsa · 3 warzyw | kalorie teraz albo dzień dłużej bez szukania |

⚠️ **Jeden wytrych, nie komplet.** Odkąd otwieranie zużywa narzędzie (§8.4),
cztery to pięćdziesiąt zamków wydanych, zanim gra się zaczęła.

⚠️ Wybór wychodzi z kreatora **dopiero po potwierdzeniu**: §11.1 chce, żeby
zapis był cały albo żeby go nie było, a ekran oddający wybory po drodze
zostawiłby po przerwanym kreatorze wiersze ekwipunku bez postaci.

---

## 9. Loot

### 9.1. Gęstość

| | Wartość |
| :---- | ----: |
| Maks. aktywnych miejsc | **15** |
| Promień spawnu | **2 000 m** (§10) |
| Promień przy cienkiej mapie | 3 000 m |
| Gwarantowany bliski ring | **5 miejsc w 600 m** |
| Zapominanie | 4 000 m |
| Odnowa skrzyni | **4–8 h** |

**Pod własnymi drzwiami nic nie rośnie: 80 m** — 50 m strefy bezpiecznej plus
30 m czystego terenu dookoła. Skrzynia stojąca dokładnie na granicy jest
skrzynią, do której wychodzi się na dwa kroki, a §10 stoi na tym, że po rzeczy
trzeba iść. Prawdziwe POI, które stało tam przed budową schronu, nie znika —
przeszukuje się je raz, jak wszystko inne.

**Samochody i śmietniki mają rezerwację: 3 najbliższe, niezależnie od gęstości.** §10.1 trzyma *otagowane* parkingi z dala od miasta (4165 parkingów na 427 sklepów spożywczych w promieniu 2 km od centrum Poznania) i słusznie — ale wymyślony samochód i wymyślony śmietnik to nie to samo: jest ich garść, są najzwyklejszą rzeczą na ulicy i niosą dokładnie to, czego brakuje §18.2. Zmierzone na spacerze: bliski pierścień zapełniał się prawdziwymi sklepami w pierwszym przebiegu, pula zapasowa nigdy nie była ruszana, a miasto nie dawało **ani jednego** samochodu i śmietnika. Rezerwacja idzie z puli 15 miejsc §10, nie ponad nią.

⚠️ Wybierane po **selektorze** (tylko wymyślone punkty), liczone po **tabeli** (prawdziwy parking obok też się liczy — to już jest samochód do przeszukania, a wymyślanie drugiego obok byłoby powtarzaniem mapy).

⚠️ **Wróciło do 2 km z §10.** Przez cały etap 5 stało na 1 200 m, bo 25 minut marszu w jedną stronę po jeden sklep to nie jest zadanie, to szum na mapie — a znacznik, do którego nikt nie pójdzie, uczy gracza, żeby przestał czytać znaczniki. Komentarz mówił wtedy wprost: figura §10 wraca, kiedy ogniska dadzą dalekim punktom powód istnienia. Strefy Rozkładu (§11.5) stoją 500–2 000 m od schronu, więc ten powód istnieje. **Bliski pierścień** (5 miejsc w 600 m) pilnuje, żeby te same 15 miejsc na dwa i pół raza większym kole nie zrobiło z okolicy pustyni.

### 9.2. Skąd biorą się miejsca

| Źródło | Jak |
| :---- | :---- |
| **OSM** | apteki, szpitale, sklepy, warsztaty, biblioteki… (11 tabel) |
| **Proceduralne** | wymyślone tam, gdzie mapa jest pusta (11 tabel) |

**§10.1 istnieje, bo bez niego gra działa tylko w dużych miastach.** Zmierzone na tych samych 12 km: centrum Poznania — 74 455 miejsc, wiejska Wielkopolska — 263.

Punkty generowane stoją **przy drogach, nigdy na nich** (20 m od jezdni), co 250 m, minimum 300 m od siebie.

**Mieszanka według terenu** — udziały tych samych punktów, nie punkty dodatkowe:

| Teren | Co powstaje |
| :---- | :---- |
| Zabudowa mieszkalna | dom 60% · śmietnik 25% · auto 15% |
| Pola | stodoła 85% · auto 15% |
| Las | ambona 100% |
| Pobocze | pobocze 55% · auto 30% · śmietnik 15% |

Miasto dostaje **4 wymyślone punkty niezależnie od gęstości** — inaczej auta i śmietniki nie istniałyby dla nikogo mieszkającego w mieście.

**Karetka i radiowóz** stoją 25 m od szpitala/komisariatu, po jednym, tylko gdy budynek jest na mapie. Oba **zamknięte**.

### 9.3. Widoczność

| Widoczne od razu | Dopiero po rozpoznaniu |
| :---- | :---- |
| wszystko z OSM, auto, kosz, pobocze, karetka, radiowóz, warsztat, punkt wody | opuszczony dom, stodoła, ambona |

Reguła: **czy trzeba tego szukać**, a nie czy zostało wymyślone. Samochód na ulicy widać z chodnika; dom, który może być opuszczony, to dokładnie to, po co jest rozpoznanie.

### 9.4. Przeszukiwanie (§10.3.5)

Każde miejsce ma **budżet 6 jednostek**:

| Głębokość | Czas bazowy | Koszt | Losowań | Rzadkość |
| :---- | ----: | ----: | :---- | :---- |
| Pobieżne | 30 s | 2 | 1–2 | tylko pospolite |
| Dokładne | 90 s | 3 | 2–4 | + niepospolite |
| Gruntowne | **180 s** | **6** | 3–5 | wszystko |

Czyli: **3× pobieżne**, albo **2× dokładne**, albo **1× gruntowne**. Zaczęcie od
gruntownego zamyka resztę.

⚠️ **Czas skaluje się rozmiarem miejsca.** Trzy minuty nad śmietnikiem to te
same trzy minuty co nad supermarketem, i czyta się dokładnie tak.

| Rozmiar | Mnożnik | Pobieżne / dokładne / gruntowne | Co |
| :---- | ----: | :---- | :---- |
| **tiny** | ×0,2 | 6 / 18 / 36 s | śmietnik, pobocze, punkt wody |
| **small** | ×0,5 | 15 / 45 / **90 s** | samochód, karetka, radiowóz, ambona, wiata |
| **normal** | ×1,0 | 30 / 90 / 180 s | sklepy, mieszkania, warsztaty, magazyny |

Mnożnik działa **wyłącznie na czas**, nigdy na zawartość. Śmietnik przeszukany
gruntownie to nadal śmietnik przeszukany gruntownie — po prostu kończy się
szybciej. Minimum 5 s: poniżej przestaje być czynnością, a staje się
przyciskiem z mignięciem.

### 9.5. Bariery (§19.3)

| Bariera | Otwarte od startu | Siłą | Cicho | Narzędziem |
| :---- | ----: | :---- | :---- | :---- |
| **Drzwi** | 35% | **90 s / 200 m** | wytrychy 60 s / 20 m | łom, siekiera 12 s / 150 m |
| **Kłódka** | 10% | — | wytrychy 45 s / 20 m | **nożyce 10 s / 60 m**, łom/piła/multitool 25 s / 60 m |
| **Okno** | 45% | **10 s / 160 m** | — | — |

⚠️ **Kłódki nie da się otworzyć bez narzędzia.** §19.3 nazywa ją barierą
wymagającą narzędzia, a złagodzenie tego uczyniłoby każde narzędzie w grze
opcjonalnym.

⚠️ **Kolejność jest treścią, i nie zawsze była.** Dwadzieścia sekund ramieniem
przy dwunastu łomem znaczyło, że narzędzia są ozdobą — osiem sekund różnicy
nikogo nie skłoni do noszenia kilograma sześciuset — a gołe ręce były
**szybsze** od wytrychów, więc cicha droga nie miała żadnej przewagi poza
hałasem. Teraz: łom 12 s, wytrychy 60 s, ramię 90 s i dwieście metrów.

**Nożyce do kłódek** (`tool_bolt_cutters`, 1,9 kg) to głośna i szybka
odpowiedź; **wytrychy** (`tool_lockpicks`, 0,1 kg) to cicha i wolna. Dwa
kilogramy jednozadaniowej stali kupują 35 sekund i płacą 40 metrami hałasu —
i to jest cała decyzja.

| | |
| :---- | :---- |
| Rozpoznanie terenu | 45 s, promień 100 m, pamięć 10 min |
| Hałas przeszukania | **80 m** |
| Zasięg przeszukania | 25 m |
| Ruch przerywa | 2 odczyty poza 15 m |

⚠️ **Użycie przedmiotu (jedzenie, picie, opatrunek) nie wymaga GPS ani stania w miejscu.** To rzeczy, które robi ciało, a nie rzeczy, których świadkiem jest GPS.

### 9.6. Notatki (§19.1)

Ślady po ludziach, którzy byli tu przed graczem. **16 notatek** w katalogu,
przypisanych do rodzajów miejsc:

| Kategoria | Ile |
| :---- | ----: |
| Kartka na drzwiach | 5 |
| Dziennik | 5 |
| Notatka służbowa | 4 |
| Zapis radiowy | 1 |
| Notatka pożegnalna | 1 |

12 pospolitych, 4 niepospolite. **3 z nich niosą trop** — wskazówkę do innego
miejsca.

⚠️ Podstawianie `{street}` nie działa: paczki PMTiles nie mają warstwy
`transportation_name`. Notatka mówi wtedy ogólniej, zamiast kłamać.

### 9.7. Rzeczy na ziemi

| | |
| :---- | :---- |
| Czas życia | **24 h** |
| Maks. sztuk | 50 |
| Grupowanie w kropkę | 25 m |
| Podniesienie | zasięg ręki (15 m) |

Kliknięcie w kropkę pokazuje **listę wszystkiego**, co pod nią leży. Karabin z tłumikiem i goły to dwie osobne kupki.

---

## 10. Walka

### 10.1. Celność (§5.1)

⚠️ **MOA to średnica grupy, nigdy promień.** Pomylenie tego przesuwa szansę trafienia o czynnik ~3.

Błędy składają się jako **pierwiastek sumy kwadratów** — pięć źródeł po jednej minucie kątowej to nie pięć minut.

| Źródło | Wzór |
| :---- | :---- |
| Broń | z danych przedmiotu (`moa`) |
| Wprawa | `25 − 21 × umiejętność` (25 MOA nowicjusz, 4 mistrz) |
| **Tętno** | `60 × ((HR−spocz)/(maks−spocz))²` |
| **Ruch** | `8 × v^1,2` (marsz 55 MOA, bieg 165) |
| Cel | `0,6 × v` |
| Stan | dług snu + utrata krwi |

Szansa trafienia: `P = [2Φ(W/2σ) − 1] × [2Φ(H/2σ) − 1]`, gdzie `σ = D/4`.

Panel walki pokazuje **największe pojedyncze źródło** obok procentu — żeby chybienie dało się naprawić, a nie tylko przeżyć.

**Celowanie (§5.3):** przełączenie celu daje rozrzut ×2,5, opadający przez **2 s** (4 s przy wysokim tętnie).

### 10.2. Obrażenia (§5.1.5)

`ubytek [ml] = 5,1 × energia[J]^0,6 × współczynnik_rany × lokalizacja × (1 − pancerz)`

⚠️ Wykładnik 0,6 jest sednem. Model liniowy zawsze karałby małe kalibry — cała hierarchia broni wynika z tych sześciu dziesiątych.

**Kalibracja:** ~3,2 naboje 5,45 na Szwędacza, ~7,2 z 9 mm.

### 10.3. Lokalizacja trafienia

| Lokalizacja | Szansa | Mnożnik | Krwawienie |
| :---- | ----: | ----: | ----: |
| Głowa | 12% | **×4,0** | 6 ml/s |
| Tors | 45% | ×1,0 | 4 ml/s |
| Ręce | 18% | ×0,6 | 1,2 ml/s |
| Nogi | 25% | ×0,7 | 1,2 ml/s |

Losowane **w obie strony** — ugryzienie też ma lokalizację. Trafiony przeciwnik może **wykrwawić się, zanim dobiegnie**, co czyni wycofanie się taktyką.

### 10.3a. Dwa kanały obrażeń (§5.5.1, §5.5.3)

⚠️ **Wszystko w zwarciu robiło jedną rzecz — upuszczało krew.** Młotek nie tnie,
a mimo to jedyną różnicą między nim a maczetą było dwieście mililitrów.
`damage_type` leżało w danych wszystkich jedenastu broni białych i nie czytał go
nikt.

| Kanał | Czym | Co robi |
| :---- | :---- | :---- |
| **Sieczna, kolna** | nóż, maczeta, siekiera, włócznia, szpikulec, śrubokręt | krwawienie — zabija z czasem |
| **Obuchowa** | pałka, młotek, łom, łopata, maczuga | **oszołomienie** — stoi, nie bije, nie goni |

**Oszołomienie = masa broni w sekundach**, wyprowadzone, nie dopisane do danych:
młotek 0,7 s · pałka 0,9 s · łom 1,6 s · maczuga 1,7 s · łopata 1,9 s.

| | |
| :---- | ----: |
| Koszt budżetu sprintu | **2 s biegu za sekundę stania** |
| Brutal | **połowa** oszołomienia |
| Chybiony cios | zero (obuch jest skutkiem trafienia, nie zamachu) |
| Trup | zero |

⚠️ **Cena obucha jest w czasie zamachu.** Łopata oszałamia na 1,9 s i bierze
zamach 2,1 s — kto bije ciężkim, ten bije rzadziej, i to jest jedyny powód, dla
którego maczeta dalej ma sens.

**Zasięg** (`reach_m`, 0,3–1,8 m) przesuwa szansę trafienia względem pałki
(0,9 m = zero):

| Sytuacja | Długa broń | Krótka broń |
| :---- | :---- | :---- |
| Jeden przeciwnik | **+**, do +15 pkt | − |
| Dwóch i więcej | **−**, do −15 pkt | **+** |

⚠️ **Włócznia nie może być po prostu lepsza.** Metr dziewięćdziesiąt drzewca
trzyma Kroczącego na dystans, kiedy jest jeden, i jest kijem, kiedy trzech stoi
dookoła. Nóż nie ma czym trzymać na dystans ani czym zawadzać — jego przewagą
**jest** tłok.

Trzecim wyjściem zostaje cios w plecy (§11.2b). Zabić, odejść albo uciszyć.

### 10.4. Dystanse (§5.2)

| | |
| :---- | :---- |
| Wykrycie minimalne | 150 m |
| Strzał — zakres | 50–250 m |
| **Zwarcie** | **≤ 20 m** |
| Przeładowanie przerywa | przeciwnik bliżej niż **5 m** |

Poniżej 20 m GPS nie ma nic sensownego do powiedzenia o niczyjej pozycji — walka przestaje być o dystansie i staje się o tym, co masz w rękach.

**Oskrzydlenie (§5.5.3):** gracz odpowiada jednemu, reszta bije bezkarnie. Mnożnik rośnie z liczbą — wpuszczenie grupy w zwarcie to prawie wyrok.

### 10.5. Hałas (§5.6)

| Źródło | Zasięg |
| :---- | ----: |
| Strzelba | 900 m |
| **Karabin** | **700 m** |
| Pistolet | 450 m |
| Tłumiony karabin | 200 m |
| Wyważanie | 150 m |
| Tłumiony pistolet | 120 m |
| Młotek (budowa) | 100 m |
| Przeszukanie | 80 m |
| Bieg gracza | 40 m |
| **Nóż** | **25 m** |
| Kroki | 15 m |

**Modyfikatory:** noc ×1,3 · gęsta zabudowa ×0,7 (tylko w dzień) · otwarty teren ×1,2 · zła pogoda ×0,75.

⚠️ Noc jest **głośniejsza**, nie cichsza — mniej tła i inwersja temperaturowa niosą dźwięk dalej.

### 10.6. Reakcja na hałas (§5.6.2)

**Idą do miejsca, w którym powstał dźwięk — nie do gracza.** To zostawia miejsce na taktykę: strzał, przemieszczenie, obserwacja.

| Odległość od źródła | Reakcja |
| :---- | :---- |
| < ⅓ promienia | **POŚCIG** — lokalizują gracza |
| ⅓ – 1 promienia | **CZUJNOŚĆ** — do punktu hałasu, 30 s przeszukiwania |
| > promienia | brak |

| | |
| :---- | :---- |
| Maks. reagujących | **6**, od najbliższego |
| Okno kumulacji | 30 s |
| Seria ciągła | jedno zdarzenie ×1,15, nie pięć |

⚠️ **Dźwięk niosący ≥ 200 m jest „płoszący" — pokonują dystans biegiem.** Dokument mówi „marsz" dla wszystkiego jednakowo; chybiony strzał ściągający ich spacerkiem czytał się jak świat, który go nie usłyszał. Nóż i kroki nadal ściągają marszem.

⚠️ **Kolejny strzał przekierowuje także tych, którzy już idą do poprzedniego.** Nie przekierowuje tego, kto już widzi gracza — inaczej grupę dałoby się odciągnąć rzuconą puszką.

Efekt: **każdy nabój ściąga ulicę tam, gdzie stoisz teraz.** Broń palna jest do kończenia walk, nie do ich podtrzymywania.

---

## 11. Przeciwnicy

### 11.1. Rodzaje (§6.2)

| | Skakun | **Szwędacz** | Brutal |
| :---- | :---- | :---- | :---- |
| Marsz | 5–7 km/h | 3–4 km/h | 2–4 km/h |
| Bieg | **27–32 km/h** | 15–18 km/h | 12–17 km/h |
| Budżet sprintu | 25 s | 90 s | 45 s |
| Regeneracja | 60 s | 45 s | 120 s |
| Krew | 2 400–2 800 | 3 200–3 600 | **6 000–8 000** |
| Obrażenia | 120 ml | 180 ml | **400 ml** |
| Co ile bije | 1,2 s | 2 s | 3 s |
| Wykrycie | 120 m | 80 m | 60 m |
| Śmierć przy utracie | 45% | 45% | 50% |
| Grupa | 1 | **2–4** | 1 |

W MVP występuje wyłącznie **Szwędacz**. Grupa 2–4 czyni walkę z grupą stanem domyślnym gry.

### 11.2. Stany (§6.1a)

| Stan | Zachowanie | Prędkość |
| :---- | :---- | :---- |
| **SPOCZYNEK** | krąży po swoim terenie (40 m) | marsz |
| **CZUJNOŚĆ** | idzie do punktu hałasu | marsz (**bieg**, gdy hałas ≥ 200 m) |
| **POŚCIG** | biegnie za graczem | bieg, zużywa budżet |
| **WYCZERPANIE** | budżet pusty | **40%** biegu |
| **POWRÓT** | utrata kontaktu lub smycz | marsz do domu |

| | |
| :---- | :---- |
| Smycz | 400 m od domu |
| Utrata kontaktu | 45 s · **×2,5 gdy ranny** |
| Dystans kontaktu | 150 m |
| Czas przeszukiwania | **30 s** |
| Maks. skręt — marsz | 12°/s |
| Maks. skręt — pościg | 60°/s |

⚠️ **Trafienie to najprostszy sposób na znalezienie strzelca.** Ranny przechodzi natychmiast w **POŚCIG** do miejsca, z którego padł strzał — §6.1a daje dwie drogi do pościgu, wzrok i słuch, a dziura w ciele jest lepszym dowodem niż obie. Bez tego ranny dalej szukał *miejsca hałasu*, przez co drugi nabój był tańszy od pierwszego.

⚠️ **Ranny nie odpuszcza tak szybko.** Utrata kontaktu rośnie ×2,5 (112 s zamiast 45), bo coś, co zostało postrzelone, ma najlepszy dowód w grze na to, że ktoś jest w pobliżu.

⚠️ **Nic nie obraca się w miejscu.** Wcześniejszy błąd: przeciwnik, który stracił kontakt, obracał się o 118° w sekundę, co czytało się jak usterka, a nie jak ciało.

**Omijają przeszkody** — woda i strefy §3.5 blokują ruch. Budynki jeszcze nie (warstwa w paczkach nie niesie typu).

**W gęstej zabudowie zasięg wykrycia ×0,7** — ściany, które połykają strzał, połykają też sylwetkę.

### 11.2a. Co widzą i co słyszą (§6.2, §5.6.1)

⚠️ **Wykrycie było promieniem, a promień nie ma tyłu.** Szwędacz zauważał
gracza zza pleców tak samo jak na wprost, więc jedyną odpowiedzią na
przeciwnika była broń albo dystans — podchodzenie nie istniało jako możliwość.

| Reguła | Wartość |
| :---- | :---- |
| Pole widzenia | **120°** wokół kierunku marszu |
| Martwy łuk pleców | 120° |
| Słuch | promień hałasu gracza (niżej) |
| Ścigający | widzi dookoła |

**Hałas gracza** — jedyna skradanka, jaką ma gra mierząca prawdziwy ruch: nie ma
przycisku „kucnij" i nigdy nie będzie.

| Tempo | Prędkość | Słychać z |
| :---- | :---- | ----: |
| Postój | < 0,5 km/h | **0 m** |
| Ostrożny krok | < 3,2 km/h | 8 m |
| Marsz | < 7,2 km/h | 15 m |
| Bieg | ≥ 7,2 km/h | **40 m** |

⚠️ **7,2 km/h to prędkość przejścia chód→bieg**, nie okrągła liczba z sufitu:
około 2,0 m/s, zmierzone i powtarzalne, i ta sama wartość wypada z liczby
Froude'a (przejście przy Fr ≈ 0,5, `v = √(0,5 · g · L)` daje 2,1 m/s dla nogi
0,9 m). Swobodny marsz to 5 km/h, czyli 1,4 m/s.

⚠️ **Były dwie takie stałe i obie nazywały się `kRunningKmh`:** 6,4 w
`combat/awareness.dart` i 8 w `sim/action_pace.dart`. Powyżej 6,4 gracz
hałasował jak biegnący i urywała mu się strona lektury, powyżej 8 przestawał
opatrywać ranę — między jedną a drugą był jednocześnie biegnącym i niebiegnącym,
zależnie od tego, kto pytał. Nie kolidowały wyłącznie dlatego, że żaden plik nie
importował obu naraz. Teraz jest jedna, w `action_pace.dart`, a test źródłowy
liczy definicje.

Liczba stoi na HUD-zie na stałe, słowem i odległością. **Usłyszane to nie
zobaczone**: dźwięk robi z przeciwnika czujnego, a czujny idzie *w stronę
hałasu*, nie do gracza.

⚠️ **Stożek musi być narysowany.** Stożek, którego nie widać, jest niewidzialną
karą, a nie mechaniką — rysowany jest w prawdziwym promieniu wykrycia, nie w
stałych 26 pikselach, jak przez pierwszy commit.

### 11.2b. Cicha eliminacja (§5.5.1)

Trzy warunki naraz, każdy sprawdzalny wzrokiem: przeciwnik **niewzbudzony**,
gracz **za jego plecami** (łuk 120°), odległość **≤ 3 m**, ostrze w ręce.
Skutek: cała objętość krwi naraz, **12 m hałasu** — tyle, ile słychać padające
ciało.

⚠️ **Brutala się nie ucisza.** Sześć do ośmiu litrów krwi i kark, którego nie
przecina się nożem w jednym ruchu. Mechanika, w której najgroźniejsza rzecz w
grze pada od jednego dotknięcia od tyłu, zamienia elitę w cel treningowy.

### 11.2c. Pasma zagrożenia (§5.5.2, §12)

| Pasmo | Dystans | Decyzja |
| :---- | ----: | :---- |
| Obserwuj | **175 m** | zwolnij, popatrz na stożki |
| Blisko | **150 m** | obejść czy wracać |
| Na tobie | **100 m** | obejścia już nie ma |

Liczą **każdego** przeciwnika, także jeszcze nieświadomego. Wcześniej pasek
liczył wyłącznie tych, którzy już ruszyli, więc Szwędacz stojący osiemdziesiąt
metrów dalej nie istniał na ekranie.

Na **150 m** (`kFightPaceM`) gra przestaje oszczędzać: GPS i ekran wchodzą w
tempo walki. Wcześniej decyzja o tempie brała `inCombat: false` wpisane na
sztywno — z komentarzem „walka przyjdzie w etapie 5".

**Po zmierzchu jest ich o połowę więcej** (`kNightCrowdShare` = 0,5, §17.4).

### 11.3. Spawn (§6.4)

| | Wartość |
| :---- | ----: |
| Minimalny dystans od gracza | **150 m** |
| Zasięg symulacji | 600 m |
| **Rysowani na mapie** | **300 m** (histereza do 375 m) |
| Limit aktywnych | 8 (horda 12) |
| Gęstość tłowa | **2 / km²** |
| Od schronu | 200 m |

**Nie ma opóźnienia czasowego** — spawner biegnie w każdym ticku i tworzy przeciwnika, gdy tylko jest legalne miejsce i limit na to pozwala.

⚠️ **Histereza:** znacznik już narysowany zostaje widoczny do 375 m. Bez niej ten sam Szwędacz migotał, przechodząc granicę 300 m tam i z powrotem.

⚠️ Przy 600 m i gęstości 2/km² maksymalna liczba przeciwników tłowych to **2**. Prawdziwa populacja pochodzi ze Stref Rozkładu (§11.5).

### 11.4. Trwałość

**Przeciwnicy nie są zapisywani.** §6.4 odtwarza populację przy każdym uruchomieniu — Szwędacz to nie miejsce.

**Ale walka jest zapisywana:**

| | |
| :---- | :---- |
| Ważność | **15 min** |
| Zasięg | **500 m** |
| Wraca | ~60% zaangażowanych, maks. **4** |
| Gdzie | 150–270 m od gracza, szukają |

Bez tego zamknięcie aplikacji było doskonałą ucieczką. Ucieczka nadal istnieje — jest spacerem, nie menedżerem zadań.

**Ciała są zapisywane** — **12 h**, ze znacznikiem „przeszukane". Łup pojawia się dopiero po przeszukaniu z bliska.

### 11.5. Strefy Rozkładu (§6.5)

Wszystko inne w tej grze robi gracz. Strefa jest tym, co gra robi z powrotem.

| | Wartość |
| :---- | ----: |
| Maks. naraz | **3** |
| Od schronu | 500–2 000 m |
| Między centrami | 450 m |
| Promień | 20 m (poz. 1) → **200 m** (poz. 10) |
| Wrogów na poz. 10 | 12 |
| Odpoczynek slotu po likwidacji | **24–48 h** |

**Wzrost — doba do dwóch dób realnego czasu na poziom:**

```
interwał = random(24 h, 48 h) × (5,8 h ÷ kredyt_godzin_na_dobę) × random(0,6; 1,4)
           przycięte do 12 h … 96 h
```

⚠️ **Poprzednia formuła liczyła w godzinach świata** — osiem pierwszego dnia,
ćwierć godziny mniej każdego następnego, podłoga na dwóch — i po przeliczeniu
przez tempo gry dawała strefę rosnącą szybciej, niż da się ją zbić. Miasto ma
się psuć przez tygodnie, nie przez popołudnie.

Skalowanie idzie z nawyku gry (§16.1, nawyk odniesienia: godzina dziennie).
Przycięcie 12–96 h trzyma to w ryzach w obie strony: kto gra całymi dniami, nie
dostaje łatwiejszego świata, a kto znika na dwa tygodnie, nie wraca do innej
gry.

**Zbijanie:**

| | Wartość |
| :---- | ----: |
| Bariera | `60 + 20 × poziom` (80 pkt na poz. 1, 260 na 10) |
| Ciało w kole | **10 pkt** |
| Ciało poza kołem | **5 pkt** |
| Regeneracja | **5% maksimum / h** |

⚠️ **Punktacja płaska, niezależnie od gatunku.** Po gatunku — Szwędacz 10,
Skakun 15, Brutal 35 — nagradzała wybieranie najgroźniejszego celu, czyli
odwrotność tego, po co strefa jest: decyzją ma być *gdzie* się walczy, a nie
*z czym*. Wywabianie poza koło jest bezpieczniejsze i dokładnie dwa razy
wolniejsze.

⚠️ **Bariera nie odbudowuje się, kiedy gracz stoi w środku.** Pasek
odbudowujący się pod nogami tego, kto go opróżnia, mówi, że próba jest bez
sensu.

**Wysyp:** 10% szans przy każdym trafieniu w strefie, najwyżej **raz na 60
minut**, wypuszcza **połowę limitu poziomu ponad limit** na 10 minut. Blokada
leży na dysku (`surged_at`), bo kara, którą zdejmuje się restartem aplikacji,
jest karą za granie uczciwie. Wzburzenie nie odnawia się dalej niż **400 m** od
centrum — ma być trudno, a nie ma być spirali bez wyjścia.

**Kronika:** awans zapisuje `wzrost strefy` (nie budzi — strefa rośnie także
przez noc), zbicie zapisuje `strefa zbita` (budzi — nikt tego nie przespał).
Awans pokazuje **okno**, nie pasek na trzy sekundy: to jedyna rzecz, którą świat
robi za plecami gracza.

**Skrytka po likwidacji** — powód, żeby tam iść, a nie pocieszenie za amunicję:

| Zawartość | Ile |
| :---- | ----: |
| Komponenty | 4–8 |
| Złom | 10–18 |
| Apteczki | 1–2 |
| Naboje 5,45×39 | 30–60 |

Cztery rzeczy, które zmieniają wyprawę, zamiast dwudziestu, które zmieniają
liczbę w plecaku. **Pusty slot jest osobnym stanem** — „tu jeszcze nie było
strefy" i „tę właśnie zbito" to przeciwieństwa.

---

## 12. Schron i obóz

### 12.1. Strefy (§8.1)

⚠️ **Promień bezpieczeństwa i promień zakazu strzału to ta sama liczba.** Dwie różne wartości tworzą pierścień, w którym przeciwnik dosięga gracza, a gracz nie może odpowiedzieć.

| | Schron | Obóz |
| :---- | ----: | ----: |
| Strefa | **50 m** | **20 m** |
| Metabolizm | 35% / 40% | 50% / 55% |
| Sen | 100% | 70% |
| Magazyn | 25 kg + moduł | 30 kg |
| Moduły | 4 × 3 poziomy | brak |
| Czas budowy | **3 h** | **40 min** |

Przeciwnicy zatrzymują się na granicy. Gracz musi wyjść, żeby walczyć — ale nie jest bezbronny.

### 12.2. Budowa (§8.3)

| | |
| :---- | :---- |
| Bazowo | 3 h |
| Z narzędziami (młotek + siekiera) | **−35%** → 1 h 57 min |
| Inżynieria 100% | dodatkowe −30% |
| Minimum osiągalne | **~1 h 22 min** |

⚠️ **Praca liczy się wyłącznie na placu.** Odejście zatrzymuje pasek. Postęp zapisywany co 15 s, znacznik czasu w bazie — noc z zamkniętą aplikacją liczy się w całości.

**Ta sama reguła obowiązuje warsztat** (§2.1a.3, schemat v37). Wyjście ze strefy
odkłada wytwarzanie i demontaż tam, gdzie były; powrót przesuwa **oba** stemple
o czas nieobecności.

⚠️ Obecność była sprawdzana **raz**, przy odpalaniu roboty, i nigdy więcej:
`ready_at` ustawione przy starcie było czystym zegarem ściennym, więc plecak
wojskowy dało się zostawić na imadle, przejść pół miasta i odebrać go w terenie.

⚠️ Przesunięcie samego terminu wydłużyłoby robotę zamiast ją przesunąć —
postęp liczy się od `started_at`, więc godzinna praca po dobie nieobecności
miałaby dobę i godzinę „całości", a trzydzieści zrobionych minut czytałoby się
jako dwa procent.

**Lektura tej reguły nie ma** i to jest decyzja, nie przeoczenie: strona jest
akcją (`ActionKind.reading`, 76 s), nie wymaga schronu, żeby ruszyć, a §4.6
wprost mówi, że wielkie tomy opłaca się czytać na miejscu.

**Przerwanie** jest możliwe i nieodwracalne: materiały zostają w ścianach, praca zaczyna się od zera. Okno mówi to wprost.

### 12.3. Moduły (§8.4)

| Moduł | Efekt / poziom | Maks. |
| :---- | :---- | :---- |
| **Magazyn** | +50 kg | 175 kg |
| **Warsztat** | naprawa do 60% / 85% / 100% | + receptury złożone |
| **Salon** | +15% tempa snu | +45% |
| **Laboratorium** | +3% z posiłków | +9% |

⚠️ Warsztat przebudowany względem dokumentu: **dostęp do możliwości**, nie procent oszczędności czasu. Wersja z 3% na poziom to coś, za co nikt nigdy nie zapłaciłby trzech poziomów.

**Koszt pełnej rozbudowy: 731 kg** — około 30 kursów z pełnym plecakiem. To ma być cel na tygodnie.

Wymagania narzędziowe: młotek do wszystkiego, multitool ×1,6 czasu, Warsztat L2+ wymaga obu bez alternatywy.

### 12.4. Obozy (§8.5.2)

| | |
| :---- | ----: |
| Maksymalnie | **2** |
| Od schronu | 800 m |
| Między sobą | 800 m |
| Od centrum ogniska | 400 m |
| Rozpad | **14 dni** |
| Zniknięcie | **21 dni** |

Schron główny **nigdy się nie rozpada** — to miejsce, gdzie gracz mieszka.

### 12.5. Prywatność (§8.2)

⚠️ Współrzędne schronu to w praktyce **adres domowy gracza**. Zapisane lokalnie, nigdy nie wysyłane, `allowBackup="false"` dla całej bazy.

---

## 12a. Półka w schronie (§18.2)

§18.1a daje postaci dwa twarde limity i żadnego sposobu, żeby je urosnąć poza lepszym plecakiem. Bez półki każde znalezisko było wyborem „nieść albo zostawić **na ziemi**", gdzie §4.8 daje mu dobę. Półka zmienia to na „nieść albo **zatrzymać**" — a zatrzymywanie rzeczy to większość tego, co robi z bazy bazę.

**Działa od chwili, gdy deski są przybite.** Zabarykadowany dom trzyma 25 kg sam z siebie; moduł Magazyn dokłada 50 kg na poziom.

| Miejsce | Udźwig | Objętość |
| :---- | ----: | ----: |
| Schron (dom) | **25 kg** | 75 l |
| Schron + Magazyn 1/2/3 | 75 / 125 / 175 kg | 225 / 375 / 525 l |
| Obóz (skrzynia) | **30 kg** | 90 l |

Trzy litry na kilogram — ten sam przelicznik, którym mierzy się plecak.

⚠️ **Trzeba tam stać.** Sięganie do własnego domu z drugiego końca miasta nie jest rzeczą — ta sama odmowa, którą już robią moduły (§2.1a.3).

⚠️ **Obie granice odmawiają.** Półka pełna pustych butelek ma zapas wagi i zero miejsca; półka z amunicją odwrotnie. To jest asymetria, dla której §18.1a w ogóle ma dwie liczby.

⚠️ **Rzecz na półce jest tą samą rzeczą.** Karabin trzyma to, co do niego przykręcone, książka pamięta stronę, a butelka odłożona do połowy wypita jest wciąż do połowy wypita (§4.7). Stosuje się tylko to, czego nie da się odróżnić — karabin z kolimatorem nie wpada do stosu z gołym.

⚠️ **Obóz przepada z zawartością skrzyni** po 21 dniach bez wizyty (§8.5.2). To nie jest kod — to **klucz obcy z kaskadą**. Reguła w schemacie nie może zostać zapomniana przez wołającego.

### Znalezione przy okazji

`Inventory.add` odtwarzało linię z argumentów i **nie miało argumentu na `portion` ani `pagesRead`**. Butelka zdjęta z półki wracała pełna — nieskończona woda za cenę dwóch dotknięć. Naprawione u źródła, więc dotyczy też podnoszenia z ziemi.

---

## 13. Śmierć

Tryb wybierany raz przy tworzeniu postaci. **Nieodwracalnie.**

### 13.1. Zabezpieczenia (§9.1)

⚠️ **Nie do negocjacji.** Permadeath z powodu awarii technicznej to gwarantowana jedna gwiazdka w sklepie.

- Śmierć **nie może** nastąpić we śnie.
- Śmierć **nie może** nastąpić przy utraconym sygnale GPS.

### 13.0. Co faktycznie zabija

| Przyczyna | Warunek | Ile to trwa |
| :---- | :---- | :---- |
| **Wykrwawienie** | klasa IV wstrząsu (≥ 40% ubytku) | minuty |
| **Pragnienie** | 48 h bez wody **przy wysiłku**, albo 12 h w stanie krytycznym | 2–3 doby |
| **Wychudzenie** | 30% ubytku masy startowej (§3.4a) | ~10 tygodni |

⚠️ **Dwie z tych trzech były do niedawna nieosiągalne.** `hungerState` przyjmuje `timeAtZero`, `thirstState` przyjmuje `timeWithoutWater` — od kiedy powstały. `statusOf` nie podawał żadnego z nich, a `SimState` nie miał gdzie ich trzymać, więc oba pozostawały fałszem i można było nie jeść ani nie pić w nieskończoność. Zegary siedzą teraz w stanie (`dryStreakSeconds`, `starvedStreakSeconds`, schemat v27).

⚠️ **Pusty zapas kaloryczny nie jest przyczyną zgonu.** Kładzie postać (`isIncapacitated`), tak jak §2.3 to nazywa — „postępująca utrata przytomności". Zabija dopiero ciało, które się skończyło.

### 13.2. Hardcore

Koniec postaci. Wpis do Kroniki z pełnym stanem. Nowa postać zachowuje parametry fizjologiczne — to nadal to samo ciało gracza, zmienia się tylko imię.

### 13.3. Softcore

| | |
| :---- | ----: |
| Nieprzytomność | **60 min** czasu zegarowego |
| Krew po przebudzeniu | **65%** (klasa III) |
| Woda i kalorie | 15% |
| Broń w rękach | **zawsze przepada** |
| Reszta noszonego i plecak | **50% losowo** |
| Skrytki | 30–100 m od miejsca upadku |
| Okno łaski | **10 min** |

Budzi się **tam, gdzie fizycznie jest gracz** — rozjazd między pozycją postaci a pozycją gracza jest niedopuszczalny w żadnym stanie gry.

**Przebudzenie w pojeździe** (> 15 km/h lub zły GPS) jest **odroczone**, nie karane.

Ekran śmierci pokazuje **log ostatnich chwil walki** — 30 linii, około dwóch minut złej walki.

---

## 14. Profil

Ekran otwierany z menu mapy. Cztery pytania, w kolejności, w jakiej zadaje je
gracz o własną postać: **jak długo żyję**, **czym jest to ciało**, **co teraz
sprawia, że chybiam**, **co właściwie zrobiłem**.

### 14.1. Licznik, nie stan (§13.1)

Statystyki rosną i nigdy nie maleją. Dlatego mieszkają w osobnej tabeli
(`profile_stats`, schemat v19) niż fizjologia: jedna jest nadpisywana co minutę
stanem ciała, druga jest historią. Zapis po **każdym** zdarzeniu — jeden mały
upsert, więc zamknięcie aplikacji w środku walki nic nie gubi.

| Liczone | Gdzie w kodzie | Uwagi |
| :---- | :---- | :---- |
| Oddane strzały, trafienia | `_fire` | strzał w powietrze (§5.6.2) **nie liczy się** — nie był celowany, psułby celność |
| Ciosy wręcz, trafienia | `_strike` | osobna celność, nie miesza się ze strzelecką |
| Trafienia wg części ciała | `_fire`, `_strike` | głowa / tors / ręce / nogi |
| Zabici | `_remember` | jedyny lejek, przez który przechodzi każda śmierć — i już odsiany z duplikatów |
| Zadana utrata krwi | `_fire`, `_strike` | ml |
| Własna utrata krwi | `_takeBlows` | ml |
| Przeszukane miejsca | `_finishObjectSearch`, `_searchRemains` | |
| Utraty przytomności | `_settleDown` | także śmierć w hardcore |

Wskaźniki pochodne:

| Wskaźnik | Wzór | Przed pierwszym zdarzeniem |
| :---- | :---- | :---- |
| Celność | trafienia / strzały | **—**, nie 0% |
| Celność wręcz | trafienia / ciosy | **—** |
| Naboi na przeciwnika | strzały / zabici | **—** |

„—" zamiast zera jest świadome: gracz, który nie strzelał, nie ma celności, a
pokazanie mu 0% byłoby grą mówiącą, że jest zły w czymś, czego nie robił.
Kalibracja z §10.3.3 (około trzech naboi 5,45 na Chodzącego) jest tu
**zmierzona**, nie obiecana.

### 14.2. Budżet celowania w spoczynku (§5.1.1)

Ekran pokazuje **cały** rozkład MOA — broń, umiejętność, tętno, ruch, cel,
kondycja — liczony tym samym `ShotError`, którego używa spust. Tętno i ruch
wpisane jako zero, bo to jest obraz „stoję spokojnie": różnica między tym
widokiem a paskiem w walce jest dokładnie tym, co gracz sam sobie dokłada.

Sens tej sekcji: największym wierszem jest prawie zawsze **własny puls albo
własne tempo**, a obie rzeczy naprawia stanie w miejscu. To lekcja tańsza do
odrobienia w schronie niż przed Chodzącym.

### 14.3. Trafienia wg części ciała

Pasek na każdą lokalizację, a na nim **znacznik oczekiwanego udziału z §2.6**
(głowa 12%, tors 45%, ręce 18%, nogi 25%). Gracz trafiający w głowę znacznie
częściej, niż przewiduje model, znalazł coś, czego model nie wie.

### 14.4. Umiejętności

Puste — §7 nie istnieje. Do tego czasu **każdy strzela jak nowicjusz**: 25 MOA,
czyli największy wiersz budżetu z 14.2. Ekran mówi to wprost, zamiast pokazywać
pustą listę.

⚠️ Nic z tego nie opuszcza telefonu. §16.5 dopuszcza zagregowaną telemetrię —
domyślnie wyłączoną, za zgodą — i to **nie jest** ona.

---

## 15. Odejścia od dokumentu projektowego

Miejsca, w których kod **świadomie** robi coś innego niż `ARLS-ZA_design_doc_v2.md`. Każde ma powód.

| Co | Dokument | Kod | Dlaczego |
| :---- | :---- | :---- | :---- |
| **Krew po przebudzeniu** | „25% maksymalnej (klasa III)" | **65%** | Te dwie połowy są sprzeczne: 25% pozostałej to 75% utraty = klasa **IV** = śmierć. Dosłownie wdrożone → budzisz się i natychmiast padasz z powrotem, w pętli. Wygrała klasa, nie liczba. |
| **Reakcja na hałas** | marsz do punktu hałasu | **bieg**, gdy hałas ≥ 200 m | Chybiony strzał ściągający ich spacerkiem z 400 m czytał się jak świat, który go nie usłyszał. Bez tego cena broni palnej jest notatką w logu, a nie kosztem. |
| **Przekierowanie na drugi strzał** | reagują tylko SPOCZYNEK/POWRÓT | także **CZUJNOŚĆ** | Idący do pierwszego strzału ignorowali każdy następny — można było strzelać i odchodzić bez konsekwencji. |
| **Sen w dzień** | tylko noc (§2.5.3) | **także 10 min spokoju** | Prośba z testów. Nie da się farmić — dług zatrzymuje się na zerze. |
| **Warsztat** | 3% na poziom | dostęp do napraw | Dokument sam oznacza swoją wersję jako niezbalansowaną. |
| **Regeneracja krwi** | brak | **60 ml/h** | Bez tego przeżycie ciężkiej walki to dożywocie w klasie IV. |
| **Widoczność miejsc** | proceduralne = ukryte | ukryte tylko to, czego trzeba szukać | Samochód na ulicy widać z chodnika. |
| **Czas przeszukania** | jeden dla wszystkiego | **skalowany rozmiarem** ×0,2 / ×0,5 / ×1 | Trzy minuty nad śmietnikiem to te same trzy minuty co nad supermarketem. |
| **Czas budowy schronu** | §8.3: −35% z narzędziami · §18.3: ×2,5 bez | wdrożono **§8.3** | Dokument sam sobie przeczy. **Do rozstrzygnięcia.** |
| **Skrytki po utracie przytomności** | 48 h | **24 h** | Leżą jako zwykłe rzeczy na ziemi (§4.8), a te mają dobę. Dług. |
| **Okno łaski** | warunkowe (przeciwnicy w 300 m) | zawsze 10 min | Dług. |
| **Udźwig** | — | gender-neutralny | Świadoma decyzja gracza. |
| **Śmierć z głodu** | „0% przez > 24 h → utrata przytomności" czytane jako zgon | **przewraca, nie zabija**; zabija 30% ubytku masy | Zapas to *doba* jedzenia. Postać bez zapasów stoi na zerze od drugiego poranka klęski głodu do jej końca — więc głód zabijał w 48 h, szybciej niż pragnienie, wbrew §2.3. |
| **Masa ciała** | stała z karty postaci | **stan** (§3.4a) | §2.3 nie miało czym mierzyć głodu dłuższego niż doba. |
| **Śmierć z pragnienia w bezruchu** | tylko „48 h przy wysiłku" | także **12 h w stanie krytycznym** | Sama reguła z dokumentu czyni nieśmiertelnym kogoś, kto siedzi w schronie: zapas ma podłogę na 10% masy ciała i tam zostaje. |
| **Progi 5% i 10% odwodnienia** | „osłabienie" / „stan krytyczny", bez liczb | ×1,30 / ×1,60 czasu czynności | §2.3 nakazuje, żeby pragnienie było ostrzejsze od głodu; bez tego było odwrotnie. |
| **Deprywacja przewlekła** | brak | **drugi zegar** (§5.3) | §2.5.4 mierzy ostatnią noc, ma sufit doby i na 6-godzinnych nocach nie drga. Trzy tygodnie niedosypiania czytały się jak jeden zarwany wieczór. |
| **Nadwyżka kalorii** | „nadmiar nie kumuluje zapasu" | idzie w **masę ciała** | Wyrzucana, nie dawała nic — nie było powodu najeść się przed wyprawą. Zapas dobowy dalej się nie kumuluje. |
| **Punktacja strefy** | po gatunku: 10 / 15 / 35 pkt | **10 pkt płasko, 5 poza kołem** | Punktacja po gatunku nagradzała wybieranie najgroźniejszego celu, czyli odwrotność tego, po co strefa jest: decyzją ma być *gdzie* się walczy, a nie *z czym*. |
| **Wzrost strefy** | godziny świata (8 h → 2 h) | **24–48 h realnego czasu**, skalowane nawykiem | Po przeliczeniu przez tempo gry stara formuła dawała strefę rosnącą szybciej, niż da się ją zbić. |
| **Lektura poza strefą** | §2.1a.3: zajęcie schronowe | **tyka wszędzie poza biegiem** | §4.6 wprost mówi, że wielkie tomy opłaca się czytać na miejscu. Wymuszenie strefy nie wstrzymałoby czytania, tylko zabroniło czytać w terenie — więc próg jest na prędkości: od 6,4 km/h strona się urywa. |
| **Otwieranie drzwi ramieniem** | — | **90 s / 200 m** (było 20 s / 150 m) | Osiem sekund różnicy wobec łomu znaczyło, że narzędzia są ozdobą, a gołe ręce były szybsze od wytrychów. |

---

## 16. Zbudowane, jeszcze nieużyte

### 16.1. Pomiar stylu gry (§16.4)

Model gotowy, nic go jeszcze nie czyta — czeka na ogniska (§6.5), którym ma
dyktować tempo wzrostu.

| | |
| :---- | ----: |
| Okno | 7 dni |
| Waga godziny grania | **×3,5** |
| Podłoga bezczynności | 0,10 / h |
| Kredytowane godziny | 2–16 dziennie |

`kredyt = grane × 3,5 + (24 − grane) × 0,10`, przycięte do 2–16.

⚠️ Pierwsza wersja była odwrotna — świat gracza grającego rzadko rósł **dwa
razy szybciej**. Zostawiony test pilnuje kierunku.

Wpięty w §11.5: dyktuje tempo wzrostu Stref Rozkładu.

### 16.2. Zajęcia jako model (§2.1a.3, §2.1a.4)

`Occupation`, `advanceOccupation`, `zoneSuspended`, wznowienie po powrocie —
model kompletny, przetestowany, i **`beginOccupation` nie ma w grze ani jednego
wołającego** poza testami.

Nie wpięty świadomie: „zajętość" (postać przy imadle nie zasypia) loop ma już
przez `setWorking`, a zegar roboty dostał własną regułę obecności (§12.2).
Wpięcie zajęcia dołożyłoby **drugi zapis tego samego faktu**. Decyzja do
podjęcia: albo crafting, budowa i lektura przechodzą na `Occupation` jako jedno
źródło prawdy, albo model znika.

### 16.3. `TickEngine`

Osobny silnik tickowy obok `GameLoop`. Nic go nie woła. Ta sama decyzja co
wyżej: wpiąć albo usunąć.

---

## 17. Czego jeszcze nie ma

| Mechanika | Stan | Blokuje |
| :---- | :---- | :---- |
| **Powiadomienie push (§6.5.3)** | ⬜ | awans mówi tylko oknem po wejściu do gry; push wymaga paczki i pozwolenia |
| **Umiejętności (§7)** | 🟡 | czytane przez walkę, budowę i demontaż; `learningRateMultiplier` z §2.5.4 i §2.5.5 nadal bez konsumenta |
| **Magazynki jako przedmioty** | ✅ | w katalogu i w generatorze strony (typ `magazine`) |
| **Zawartość magazynu schronu** | ✅ | półka §18.2, z blokadą przed budową |
| **Dźwięki i haptyka** | ⬜ etap 7 | ~55 plików, licencje |
| **Pancerz per lokalizacja** | ⬜ | trafienia mają lokalizacje, pancerz liczy jeden próg torsa |
| **Budynki jako przeszkody** | ⬜ | warstwa w paczkach nie niesie typu |
| **Światło broni** | ⬜ | §6.2 daje wykrywanie bez kierunku |
| **Siła jako oś (§5.5.1)** | ⬜ | `strength_required` leży w danych; wymaga statystyki siły, której nie ma |
| **Temperatura otoczenia** | ⬜ | `ambientTempC` i `clothingClo` nie mają źródła |
| **Światło (`tool_flashlight`)** | ⬜ | latarka nie robi nic |
| **Pogoda i sezonowość** | ⬜ P4 | wymaga craftingu |
| **Onboarding, dostępność** | ⬜ etap 9 | publikację |

---

## Jak utrzymać ten plik

```
flutter test          # liczby w sekcjach są pilnowane testami
flutter analyze
```

Większość stałych z tego dokumentu ma test, który pęknie przy zmianie. Jeśli zmieniasz liczbę:

1. zmień stałą w kodzie,
2. popraw test, który ją trzyma,
3. **popraw sekcję tutaj**,
4. jeśli to odejście od dokumentu projektowego — dopisz wiersz do [sekcji 15](#15-odejścia-od-dokumentu-projektowego) z powodem.

Punkt 4 jest najważniejszy. Powód zapomniany po trzech miesiącach wraca jako „dziwna liczba, pewnie błąd".
