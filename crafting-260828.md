# Rozbudowa craftingu — przegląd 25 propozycji

Stan katalogu na 2026-08-28. Liczby demontażu niżej **nie są moją propozycją** —
są policzone silnikiem, tą samą funkcją, która policzy je w grze.

---

## 1. Trzy rzeczy do rozstrzygnięcia zanim cokolwiek wejdzie

### 1.1 Trzynaście z dwudziestu pięciu przedmiotów już istnieje

| propozycja | już w katalogu | status |
|---|---|---|
| Maczeta | `melee_machete` | uncommon, loot: rural/shop/garden |
| Prosta włócznia | `melee_spear` | **ma już recepturę**: 1 drewno + 1 metal + 1 tkanina, 25 min, warsztat 1, ×2 sztuki |
| Łom | `melee_crowbar` | uncommon |
| Wytrychy | `tool_lockpicks` | rare |
| Tłumik (oba) | `tool_suppressor` | very_rare, **jeden na oba typy broni** |
| Koszula | `cloth_tshirt` | common |
| Slipy | `cloth_thermal_underwear` | uncommon, 0.8 clo |
| Czapka | `cloth_hat` | common |
| Rękawiczki | `cloth_gloves` | common |
| Spodnie | `cloth_trousers`, `cloth_winter_trousers` | common |
| Buty | `cloth_boots` | common |
| Plecak sportowy | `pack_daypack`, `pack_trekking` | common/uncommon |
| Plecak militarny | `pack_military`, `pack_tactical` | rare/very_rare |

**To nie są nowe przedmioty — to receptury na istniejące.** Dodanie drugiej
„maczety" rozszczepiłoby tabele lootu, ikony i nazwy, a gracz zobaczyłby dwa
prawie identyczne wiersze w plecaku i nie wiedziałby, czym się różnią.

⚠️ **Włócznia ma już recepturę i jest inna od proponowanej** (1 drewno vs 3, z
tkaniną zamiast drutu, ×2 sztuki). Trzeba wybrać jedną — nie da się mieć obu.
Rekomendacja: zostawić istniejącą, bo `craft_spear` jest już przetestowany i
włócznia z jednego kija jest uczciwsza niż z trzech.

### 1.2 Demontaż nie jest pisany, tylko wyprowadzany

To najważniejsza rzecz w całym dokumencie. `materialContent()`
([item_recipe.dart:205](lib/craft/item_recipe.dart#L205)) sprawdza najpierw, czy
przedmiot **ma recepturę** — i jeśli ma, demontaż liczy się z niej, ignorując
prop `salvage`. Dalej:

```
budżet   = round(suma_jednostek × udział × (kondycja/100))
udział   = 0.40 + 0.15 × Inżynieria  [+0.10 warsztat ≥ 2]      → 0.40…0.65
rozdział = proporcjonalnie, reszty metodą największej reszty
czas     = 3 min + 12 min × min(jednostki/10, 1)
```

**Wniosek: kolumny „demontaż" i „czas demontażu" w propozycji są zbędne.** Wpisanie
receptury ustawia jedno i drugie automatycznie i spójnie z resztą gry. Poniżej
to, co silnik faktycznie zwróci dla proponowanych receptur:

| przedmiot | jedn. | czas demontażu | odzysk (Inż. 0) | odzysk (Inż. 100 + warsztat 2) |
|---|---|---|---|---|
| Łuk | 4 | 7.8 min | drewno 1, klej 1 | drewno 1, skóra 1, klej 1 |
| Strzały ×10 | 1 | 4.2 min | — | drewno 1 |
| Maczeta | 3 | 6.6 min | metal 1 | metal 1, skóra 1 |
| Włócznia (istniejąca) | 3 | 6.6 min | tkanina 1 | metal 1, tkanina 1 |
| Slipy | 2 | 5.4 min | tkanina 1 | tkanina 1 |
| Koszula | 4 | 7.8 min | tkanina 2 | tkanina 3 |
| Czapka z daszkiem | 3 | 6.6 min | tkanina 1 | tkanina 1, plastik 1 |
| Skórzana czapka | 4 | 7.8 min | skóra 2 | skóra 3 |
| Kapelusz | 5 | 9.0 min | tkanina 1, plastik 1 | tkanina 2, plastik 1 |
| Naramienniki | 4 | 7.8 min | skóra 1, tkanina 1 | skóra 1, tkanina 2 |
| Rękawiczki z ćwiekami | 4 | 7.8 min | skóra 1, tkanina 1 | skóra 1, tkanina 1, metal 1 |
| Rękawice taktyczne | 5 | 9.0 min | skóra 1, drut 1 | skóra 1, drut 1, plastik 1 |
| Wzmocnione spodnie | 6 | 10.2 min | skóra 1, tkanina 1 | skóra 1, tkanina 2, plastik 1 |
| Bojówki z ochraniaczami | 7 | 11.4 min | tkanina 2, plastik 1 | tkanina 3, plastik 1, klej 1 |
| Trampki | 4 | 7.8 min | skóra 1, tkanina 1 | skóra 1, tkanina 1, plastik 1 |
| Buty wojskowe | 6 | 10.2 min | skóra 1, metal 1 | skóra 3, metal 1 |
| Łom | 4 | 7.8 min | metal 2 | metal 3 |
| Wytrychy ×4 | 2 | 5.4 min | metal 1 | metal 1 |
| Noże do rzucania ×3 | 8 | 12.6 min | metal 2, drewno 1 | metal 4, drewno 1 |
| Tłumik pistoletowy | 6 | 10.2 min | metal 1, drut 1 | metal 2, drut 1, komponent 1 |
| Tłumik karabinowy | 6 | 10.2 min | metal 1, komponent 1 | metal 3, komponent 1 |
| Plecak biegowy | 3 | 6.6 min | tkanina 1 | tkanina 1, taśma 1 |
| Plecak sportowy | 8 | 12.6 min | tkanina 2, plastik 1 | tkanina 4, plastik 1 |
| Plecak militarny | 15 | 15.0 min | tkanina 3, plastik 1, drut 1, klej 1 | tkanina 5, plastik 2, drut 1, klej 2 |
| Pochodnia | 3 | 6.6 min | tkanina 1 | tkanina 1, paliwo 1 |

Propozycje ręczne zgadzają się z tym w 20 przypadkach na 25 — czyli intuicja była
dobra, ale wpisywanie ich osobno wprowadziłoby tylko dwa źródła prawdy.

🔴 **Jeden realny błąd, który to ujawnia: z demontażu wraca klej, taśma i
paliwo.** To materiały zużywalne — klej po związaniu nie jest już klejem.
Potrzebna reguła: materiały oznaczone jako zużywalne są wykluczone z budżetu
odzysku (nie tylko z wyniku — inaczej ich udział przechodzi na resztę i odzysk
metalu rośnie za darmo).

### 1.3 Czasy produkcji — obecna skala odniesienia

| co | czas | za ile sztuk |
|---|---|---|
| bandaż improwizowany | 4 min | ×4 |
| opaska zaciskowa | 5 min | ×6 |
| opatrunek uciskowy | 7 min | ×4 |
| kolec | 8 min | ×2 |
| szyna | 12 min | ×4 |
| włócznia | 25 min | ×2 |
| Magazyn poz. 1 (moduł) | 2 h | — |
| Warsztat poz. 3 (moduł) | 9 h | — |

Wszystkie czasy modyfikowane: `× (1 − 0.30 × Inżynieria) × warsztat{1.0, .90, .80, .70}`.
Przy pełnej Inżynierii i warsztacie 3 to **49% czasu bazowego** — czyli 70-minutowe
buty wojskowe to w praktyce 34 minuty, a 140-minutowy tłumik to 69 minut.

---

## 2. Ocena realizmu i sensu — pozycja po pozycji

### 2.1 Broń dystansowa

- **Łuk** — 25 min to za mało. Włócznia (kij + grot) kosztuje tyle samo, a łuk
  wymaga wygięcia i wysuszenia drewna, cięciwy i tillingu. **Propozycja: 90 min,
  warsztat 1.** Realnie to dni, ale skala gry ma moduł schronu za 2 h, więc
  półtorej godziny to właściwe miejsce w tej skali.

  ⚠️ **Silnik nie ma broni innej niż palna.** `firearm` czyta `caliber`,
  `magazine`, `feed`, `reload_seconds`, `effective_range_m`, `noise_range_m`.
  Łuk **da się** wyrazić jako `feed: loose`, `caliber: "arrow"`, magazyn 1,
  `noise_range_m: 15`, `effective_range_m: 35` — bez ani jednej zmiany w kodzie.
  Strzały wtedy są zwykłą amunicją. To najtańsza droga i jedyna, którą polecam.
  „Cicha broń o niskim zasięgu i długim przeładowaniu" wychodzi wprost z tych
  czterech liczb.

- **Strzały ×10 za 15 min z 1 drewna** — za tanio i za szybko. Kolec kosztuje
  1 drewno i 8 minut za 2 sztuki; strzała jest trudniejsza od kolca (prostość,
  lotki, grot). **Propozycja: 10 strzał, 1 drewno + 1 tkanina (lotki), 30 min,
  nóż, warsztat 1.** Strzały muszą być odzyskiwalne z ziemi po strzale, inaczej
  łuk jest bronią jednorazową — a to osobna mechanika, której nie ma.

- **Noże do rzucania ×3** — 16 min za 3 noże z 6 metalu to **2 minuty na
  jednostkę materiału**, najtaniej w całym zestawie (reszta 4–23). Nóż bojowy
  `melee_knife` ma 180 ml krwi na cios; trzy rzucane noże „śmiertelne z bliska"
  za 16 minut podważają całą broń białą.

  ⚠️ **Rzucanie nie istnieje jako mechanika.** Trzeba by: lotu pocisku, decyzji
  o odzysku noża z ciała, osobnego celowania. To nie jest przedmiot, to system.
  **Rekomendacja: odłożyć.** Jeśli ma wejść, to razem z łukiem, jako jeden
  system „broni cichej dystansowej", nie osobno.

### 2.2 Broń biała

- **Maczeta** — istnieje jako `uncommon` z loota. Receptura na `uncommon` musi
  być droższa niż znalezienie: **2 metal + 1 skóra, 45 min, młotek, warsztat 2.**
  Przy warsztacie 1 maczeta stałaby się standardem i wyparła nóż.
- **Włócznia** — patrz 1.1, zostawić istniejącą.
- „Zasięg 2 m" i „obrażenia kłute" — 🔴 `reach_m` i `damage_type` są w danych
  **i kod ich nie czyta.** `reach_m` pokazuje się tylko na karcie przedmiotu.
  Zwarcie to jedno pasmo 20 m dla wszystkiego. **Zasięg broni białej to osobna
  mechanika do zbudowania** (i dobra: włócznia bijąca z 2 m przed pazurami jest
  realną decyzją taktyczną). Do tego czasu opis nie może obiecywać zasięgu.

### 2.3 Odzież

Wszystkie sloty istnieją: `head`, `torso_base`, `arms`, `hands`, `legs`, `feet`,
a `protection_level` i `coverage_pct` są **czytane i działają** — pancerz z
odzieży wchodzi do walki. To najgotowsza grupa w całym zestawie.

- 🔴 **Ale ciepło nie działa.** `insulation_clo` jest liczone przez
  `Inventory.insulationClo()` i **nikt tego nie woła** —
  `TickInput.clothingClo` zostaje na zerze. Wszystkie bonusy typu „cieplej w
  tyłek" są dziś martwe, tak samo jak temperatura otoczenia (patrz
  [spec-260827.md](spec-260827.md) §11). Odzież warto dodać teraz, ale ciepło
  zacznie działać dopiero po podłączeniu temperatury.

- **Slipy 2 tkaniny / koszula 4 tkaniny** — odwrócone. T-shirt zużywa mniej
  materiału niż długa bielizna termiczna. **Propozycja: slipy 1 tkanina / 20 min,
  koszula 2 tkaniny / 35 min.**
- **Czasy szycia są za krótkie w każdej pozycji.** Koszula za 17 minut przy
  module schronu za 2 godziny znaczy, że siedem koszul to jeden regał. Ręczne
  uszycie koszuli to godziny. **Propozycja: ×2 na wszystkim, co się szyje.**
- ⚠️ **`tool_sewing_kit` istnieje w katalogu i nie bramkuje niczego.** To jest
  gotowe, nieużywane narzędzie idealnie pasujące do tej grupy. **Cała odzież
  powinna wymagać zestawu do szycia, nie multitoola** — multitool otwiera dziś
  wszystko i przez to nie znaczy nic.
- **Buty wojskowe 70 min** — najbliżej realizmu w całym zestawie, ale
  szewstwo to nie 70 minut. **Propozycja: 3 h, warsztat 2, młotek + zestaw do
  szycia.** Buty mają być celem, nie pierwszym craftem.
- **Trampki „cichsze niż wojskowe"** — 🔴 hałas marszu to stała
  `NoiseKind.walking = 15 m`, bez modyfikatora od obuwia. Potrzebny mnożnik
  hałasu ruchu z butów. Mechanika mała (jeden mnożnik w miejscu, które już
  liczy hałas), efekt duży — i to jest właściwa nagroda za buty bez metalu.
- **Rękawice taktyczne −0.5 MOA** — 🔴 `moa_delta` czyta wyłącznie
  [attachment.dart](lib/combat/attachment.dart), i tylko dla dodatków do broni.
  Odzież nie ma kanału do MOA. Do dorobienia — jeden składnik w `AimError`,
  ale **nie może to być szósty parametr wpisywany ręcznie w trzech miejscach**,
  bo tak właśnie powstają te martwe pola.

### 2.4 Narzędzia i włamania

- **Łom i wytrychy już działają, i lepiej niż w propozycji.**
  [obstacle.dart](lib/loot/obstacle.dart) definiuje dla zamkniętych drzwi:

  | sposób | czas | hałas | wymaga |
  |---|---|---|---|
  | siłą (ramieniem) | 20 s | 150 m | — |
  | łomem lub siekierą | 12 s | 150 m | `melee_crowbar`, `melee_axe` |
  | wytrychami | 60 s | **20 m** | `tool_lockpicks` |

  Czyli łom to **−40% czasu**, nie −25%, a wytrychy są ciche (20 m zamiast 150 m)
  kosztem trzykrotnie dłuższej roboty. To dokładnie ten handel, o który chodziło.
  **Do zrobienia zostaje wyłącznie receptura**, mechanika jest gotowa i przetestowana.
- **Wytrychy ×4 za 12 min** — dobrze. `tool_lockpicks` jest `rare`, więc
  receptura z 2 metalu jest tanim wejściem w cichą grę. Zostawić.
- **Łom 40 min z 4 metalu** — dobrze wycenione. Zostawić.

### 2.5 Tłumiki

- **Jest jeden `tool_suppressor`, nie dwa.** `attaches_to: [9x19, 5.45x39,
  7.62x39, 22lr]` — pasuje do pistoletu i do karabinu. Dzielenie na dwa nic nie
  daje, poza dwoma wierszami do utrzymania.
- Istniejący jest `very_rare`, `noise_range_multiplier: 0.29`, `moa_delta: +0.3`,
  `craft_skill: 85`. **Rekomendacja: nie robić receptury na ten sam przedmiot,
  tylko dodać `tool_suppressor_improvised`** — gorszy i osiągalny:
  mnożnik hałasu 0.55 zamiast 0.29, `moa_delta` +0.8, i zużywa się szybko.
  Wtedy znaleziony tłumik zostaje nagrodą, a zrobiony jest wyjściem awaryjnym.
- Bramka warsztat 3 + laboratorium 2/3 jest dobra — to jedyne miejsce w całym
  zestawie, gdzie laboratorium do czegoś służy poza procentem z posiłku. Warto.
- ⚠️ **`craft_skill: 85` jest w danych i nie jest egzekwowane** — pokazuje się
  tylko na karcie przedmiotu. Tłumik to naturalny moment, żeby uczynić z tego
  prawdziwą bramkę: receptura wymaga poziomu Inżynierii, nie tylko modułu.

### 2.6 Plecaki

Najgotowsza grupa — `capacity_l`, `comfort_carry_bonus_kg` i
`max_carry_bonus_kg` są czytane i działają. Do porównania istniejące:

| plecak | pojemność | udźwig |
|---|---|---|
| `pack_school` | 22 l | +3 kg |
| `pack_shopping_bag` | 30 l | +4 kg, zajmuje ręce |

- **Plecak biegowy 12 l / +3 kg** jest gorszy od tornistra, który jest `common`
  i leży w każdym mieszkaniu. Nikt go nie zrobi. **Propozycja: 18 l / +4 kg**,
  albo dać mu przewagę, której tornister nie ma — brak zajmowania rąk i mała
  objętość własna.
- **Plecak militarny 60 l / +16 kg** — +16 kg to za dużo. Twardy limit to 45%
  masy ciała, więc dla 80 kg gracza to 36 kg; +16 kg z jednego przedmiotu to
  prawie połowa całego budżetu nośności. **Propozycja: +10 kg**, i porównać z
  istniejącym `pack_military`, żeby craft nie był lepszy od bardzo rzadkiego
  znaleziska.

### 2.7 Pochodnia

- 🔴 **Nie ma systemu oświetlenia.** `tool_flashlight` leży w danych bez efektu.
- „Skraca czas szukania o 20%" **koliduje ze Zwiadem** (−30%, sufit 30% na
  każdy efekt umiejętności) i dubluje mechanikę, zamiast dokładać nową.
- **Lepsza propozycja, bo trafia w istniejącą dziurę:** promień przeszukania to
  `100 m × (1 + Zwiad) × (1.5 lornetka) × (1 − 0.5 × ciemność) × pogoda`. Nocą
  gracz traci połowę promienia i nic tego nie odwraca. **Pochodnia (i latarka)
  powinny kasować karę za ciemność w tym wzorze** — mnożnik wraca z 0.5 do ~0.85.
  Cena: `+0.20` do wykrywalności przez przeciwników, tym samym kanałem, którym
  działa już noc. Wtedy pochodnia to prawdziwa decyzja — widzę albo mnie widać —
  a nie kolejny procent.
- Wymaga `mat_fuel` (istnieje) i powinna się **wypalać** (czas życia w minutach),
  co jest bliżej mechaniki amunicji niż narzędzia.

---

## 3. Czego silnik dziś nie potrafi wyrazić

| obietnica z opisu | czego brakuje | koszt |
|---|---|---|
| „obrażenia kłute" | `damage_type` nieczytany, brak typów obrażeń | średni |
| „2 m zasięgu" | `reach_m` nieczytany, zwarcie to jedno pasmo 20 m | średni |
| „cieplej w tyłek" | `insulation_clo` liczone, nie dociera do ticka; brak temperatury | mały + źródło pogody |
| „−0.5 MOA z rękawic" | `moa_delta` tylko dla dodatków do broni | mały |
| „cichsze niż wojskowe" | hałas marszu to stała, bez modyfikatora od obuwia | mały |
| „skraca szukanie" (pochodnia) | brak systemu światła | mały (kanał ciemności istnieje) |
| noże do rzucania | brak mechaniki rzucania | duży — to system |
| łuk | **da się bez zmian w kodzie** jako `feed: loose` | zerowy |

---

## 4. Rekomendowana kolejność

**Fala 1 — zero nowej mechaniki, same receptury i dane.** Odzież (slipy,
koszula, czapki, kapelusz, naramienniki, rękawiczki, spodnie, bojówki, trampki,
buty), plecaki, łom, wytrychy, maczeta. Wszystko działa w dniu wejścia:
pancerz, pojemność, udźwig, włamania, demontaż i jego czasy — wyprowadzone.

**Fala 2 — jedna mała mechanika na przedmiot.** Kanał MOA z odzieży (rękawice),
mnożnik hałasu marszu z obuwia (trampki), światło kasujące karę ciemności
(pochodnia, latarka), egzekwowanie `craft_skill` jako bramki (tłumik
improwizowany).

**Fala 3 — systemy.** Łuk i strzały (tanie: `feed: loose`), potem zasięg broni
białej, potem typy obrażeń. Rzucanie na końcu albo wcale.

**Osobno, niezależnie od craftingu:** wykluczyć materiały zużywalne (klej,
taśma, paliwo) z odzysku, i podłączyć `insulation_clo` do ticka razem ze
źródłem temperatury — bo bez tego połowa odzieży to statystyka, której nic nie
czyta.
