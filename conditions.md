# ARLS-ZA — wszystkie warunki gry

Każda reguła zapisana jako `if … then …`, z komentarzem na końcu.

**Skąd to jest:** wprost z kodu, nie z dokumentu projektowego. Tam, gdzie kod świadomie odchodzi od `ARLS-ZA_design_doc_v2.md`, komentarz mówi o tym wprost. Stan na schemat bazy **v20**.

**Jak czytać:** `=` to porównanie, `:=` to przypisanie. Nazwy są pseudokodem, nie identyfikatorami z Darta — plik ma być czytelny bez otwierania źródeł.

> ⚠️ Reguła utrzymania: liczba zmieniona w kodzie i nieprzeniesiona tutaj czyni ten plik gorszym niż jego brak. Większość tych stałych ma test, który pęknie przy zmianie.

---

## Spis

1. [Integralność ruchu i GPS](#1-integralność-ruchu-i-gps)
2. [Bezpieczeństwo gracza](#2-bezpieczeństwo-gracza)
3. [Strefy metaboliczne](#3-strefy-metaboliczne)
4. [Głód](#4-głód)
5. [Pragnienie](#5-pragnienie)
6. [Sen](#6-sen)
7. [Tętno](#7-tętno)
8. [Krew, rany i wstrząs](#8-krew-rany-i-wstrząs)
9. [Śmierć i utrata przytomności](#9-śmierć-i-utrata-przytomności)
10. [Udźwig i objętość](#10-udźwig-i-objętość)
11. [Przedmioty i zużycie](#11-przedmioty-i-zużycie)
12. [Loot — co się pojawia](#12-loot--co-się-pojawia)
13. [Przeszukanie i bariery](#13-przeszukanie-i-bariery)
14. [Celność strzału](#14-celność-strzału)
15. [Hałas](#15-hałas)
16. [Przeciwnicy — stany](#16-przeciwnicy--stany)
17. [Przeciwnicy — spawn](#17-przeciwnicy--spawn)
18. [Ciała i rzeczy na ziemi](#18-ciała-i-rzeczy-na-ziemi)
19. [Schron i obóz](#19-schron-i-obóz)
20. [Półka w schronie](#20-półka-w-schronie)
21. [Mapa i znaczniki](#21-mapa-i-znaczniki)
22. [Bateria i wydajność](#22-bateria-i-wydajność)
23. [Profil i statystyki](#23-profil-i-statystyki)

---

## 1. Integralność ruchu i GPS

```
if fix_accuracy_m <= 25
    then signal := good                          // Próg §3.2. Powyżej pozycja nie nadaje się do liczenia ruchu.

if fix_accuracy_m > 25 and never_had_accurate_fix and since_start < 40s
    then signal := acquiring                     // Zimny start GPS to 5–30 s. Nazwanie tego "słabym sygnałem" uczy gracza, że HUD kłamie.

if fix_accuracy_m > 25 and time_since_last_accurate >= degrade_window
    then signal := degraded                      // Dopiero uporczywa niedokładność jest ostrzeżeniem, nie pojedynczy szeroki fix.

if player_inside_shelter
    then no_signal_warning := suppressed      // ⚠️ §2.1a.4 wyłącza odbiornik pod dachem celowo — postać się nie rusza, więc pozycja nie jest potrzebna. Strażnik zgłaszał to jako utratę sygnału: gra ostrzegała o własnej decyzji, na jedynym ekranie, gdzie nic nie jest nie tak.

if no_fix_for >= 60s
    then signal := lost and movement_simulation := paused
                                                 // Zegar fizjologii idzie dalej; liczenie dystansu nie. Inaczej płaciłbyś za dryf GPS jak za spacer.

if speed_kmh > 40 sustained_for >= threshold
    then integrity := suspended and reason := vehicle_speed
                                                 // §3.4. Nie kara — zawieszenie. Samochód to nie spacer, ale też nie oszustwo.

if mock_location_provider = on
    then integrity := suspended and reason := mock_provider
                                                 // Natychmiast, bez okna czasowego: sfałszowanej pozycji nie ma sensu "czytać przez chwilę".

if integrity = suspended
    then calories := frozen and loot_spawn := off and enemy_spawn := off
                                                 // Zawieszone jest wszystko, co wynika z ruchu. Ciało dalej trawi to, co zjadło.
```

---

## 2. Bezpieczeństwo gracza

```
if speed_kmh > 15
    then combat_block := moving_too_fast         // §3.5. Nikt nie celuje z roweru. To reguła o bezpieczeństwie gracza, nie o balansie.

if integrity = suspended
    then combat_block := run_suspended           // Walka wymaga wiarygodnej pozycji.

if safety_briefing_accepted_version < 1
    then show_safety_briefing                    // Wersja, nie flaga: istotna zmiana treści pokazuje instruktaż ponownie. Literówka nie.

if poi_on(major_road | dead_railway | school | cemetery | military | religious | private_land)
    then spawn := refused                        // §3.5. Gra prowadzi realną osobę po realnym mieście — ta lista jest twarda.

if is_night and player_outdoors
    then remind_about_visibility (once per night) // Raz na noc, nie przy każdym zachodzie. Przypomnienie o ruchu drogowym, nie o grze.
```

---

## 3. Strefy metaboliczne

```
if player_outside_any_shelter
    then zone := open and calorie_factor := 1.00 and water_factor := 1.00
                                                 // Punkt odniesienia — pełne zużycie.

if player_in_camp and not asleep
    then zone := camp and calorie_factor := 0.50 and water_factor := 0.55
                                                 // Dach i ściana z plandeki: połowa wydatku.

if player_in_main_shelter and not asleep
    then zone := shelter and calorie_factor := 0.35 and water_factor := 0.40
                                                 // Zabarykadowany dom trzyma ciepło lepiej niż obóz.

if player_inside_shelter and no_occupation_running and (is_night or idle_for >= 10min)
    then zone := sleep and calorie_factor := 0.20 and water_factor := 0.30
                                                 // §2.5.1: sen jest stanem domyślnym pod dachem, nie przyciskiem. Prośba z testów: także 10 min bezczynności w dzień.

if zone = sleep and player_starts_any_action
    then zone := shelter                         // Sięgnięcie po młotek to koniec snu. Nic nie trzeba klikać.
```

---

## 4. Głód

```
calorie_fraction = calories_kcal / daily_kcal

if calorie_fraction < 0.50
    then aim_precision := 0.90                   // −10% celności. Ręce zaczynają drżeć zanim pojawi się jakikolwiek komunikat.

if calorie_fraction < 0.20
    then action_time := ×1.20                    // Wszystko trwa piątą część dłużej: przeszukanie, budowa, opatrunek.

if calorie_fraction <= 0 for > 24h
    then losing_consciousness := true and death_cause := starvation
                                                 // Doba na zerze, nie moment zejścia do zera. Głód zabija powoli i przewidywalnie.

if eaten_kcal > 0
    then absorption := 8 kcal/min                // §2.2. Puszka 500 kcal wchłania się ~62 min — jedzenie nosi się i bierze *zanim* jest potrzebne.

if pending_kcal + calories_kcal > daily_kcal
    then pending := capped                       // Nadmiar nie jest bankowany. Nie da się najeść na zapas na trzy dni.
```

---

## 5. Pragnienie

```
water_fraction = water_ml / daily_ml
deficit_fraction = (daily_ml − water_ml) / 1000 / body_mass_kg

if deficit_fraction >= 0.02
    then aim_accuracy := 0.85                    // 2% masy ciała. Dla 80 kg to 1,6 l długu — realny próg fizjologiczny, nie wymyślony.

if deficit_fraction >= 0.05
    then severely_weakened := true               // 5%: osłabienie widoczne w każdej akcji.

if deficit_fraction >= 0.10
    then critical := true                        // 10%: stan krytyczny.

if under_exertion and no_water_for > 48h
    then lethal := true and death_cause := thirst
                                                 // Wysiłek plus dwie doby. Bez wysiłku organizm wytrzymuje dłużej.

if drunk_ml > 0
    then absorption := 25 ml/min                 // Pół litra wchłania się 20 minut. Butelka wypita w biegu nie ratuje od razu.
```

---

## 6. Sen

```
sleep_debt_hours = sleep_debt / 1h

if is_sleeping
    then sleep_debt := sleep_debt − 1s per 1s    // Spłata w tempie, w jakim dług narastał.

if not is_sleeping
    then sleep_debt := sleep_debt + 8h per 24h   // §2.5.3: doba wymaga ośmiu godzin, rozłożonych na dobę.

if sleep_debt_hours < 4
    then no_penalty                              // Zarwana noc nic nie kosztuje. Kara zaczyna się dalej.

if sleep_debt_hours >= 4 and < 12
    then reading_time := ×1.20 and extra_moa := +1.0
                                                 // Pierwszy próg: czytanie wolniej, ręka odrobinę mniej pewna.

if sleep_debt_hours >= 12 and < 24
    then reading_time := ×1.50 and action_time := ×1.50 and extra_moa := +3.0 and learning := ×0.80
                                                 // Wszystko trwa półtora raza dłużej. Nauka z książek przestaje się opłacać.

if sleep_debt_hours >= 24
    then microsleeps := true                     // Interfejs blokuje się na 5–15 s losowo. To jest ta kara, którą się pamięta.

if sleep_debt = 0
    then sleep_bar_marker := none                // Nie da się "wyspać na zapas". Dług zatrzymuje się na zerze.
```

---

## 7. Tętno

```
hr_ratio = (hr − hr_rest) / (hr_max − hr_rest)

if hr_ratio < 0.60
    then no_penalty                              // Marsz nic nie kosztuje celności.

if hr_ratio >= 0.60 and < 0.75
    then extra_moa := +0.5                       // Szybki marsz.

if hr_ratio >= 0.75 and < 0.85
    then extra_moa := +1.5 and reload_time := ×1.15
                                                 // Zaczyna się liczyć także przeładowanie — ręce, nie tylko oko.

if hr_ratio >= 0.85 and < 0.95
    then extra_moa := +3.0 and precise_aim := false and reload_time := ×1.30
                                                 // Powyżej tego progu nie ma już celowania precyzyjnego.

if hr_ratio >= 0.95
    then extra_moa := +5.0 and faint_risk := true
                                                 // Ryzyko zasłabnięcia. Sprint pod ostrzałem ma cenę.

if is_sleeping and met <= 1.0
    then hr := sleeping_heart_rate (hr_rest − 14, floor 35)
                                                 // Sen obniża tętno o 14, ale nigdy poniżej 35 bpm.

hr recovery constant = 90s                       // §2.4. Nie da się "przeczekać" tętna przed strzałem — Szwędacz pokonuje w tym czasie 400 m.
```

---

## 8. Krew, rany i wstrząs

```
blood_loss_fraction = 1 − blood_ml / blood_max_ml

if blood_loss_fraction < 0.15
    then shock := none                           // Klasa 0. Do 15% ubytku organizm kompensuje bez objawów.

if blood_loss_fraction >= 0.15 and < 0.30
    then shock := compensated (I) and extra_moa := +2.0 and carry := ×0.90
                                                 // Klasa II wg ATLS. Można biec.

if blood_loss_fraction >= 0.30 and < 0.40
    then shock := decompensated (III) and extra_moa := +5.0 and carry := ×0.90 and can_run := false
                                                 // Klasa III: bieg powoduje zawroty głowy. Tu zaczyna się realne zagrożenie.

if blood_loss_fraction >= 0.40
    then shock := critical (IV) and is_fatal := true and death_cause := blood_loss
                                                 // Klasa IV: bez pomocy śmierć w 2–5 minut.

if bleed_tier != none
    then blood_loss := tier_ml_per_min × max(1, hr / hr_rest)
                                                 // ⚠️ Mnożone przez tętno. Ta sama rana kosztuje dwa razy więcej w biegu niż na stojąco.

bleed_tier rates: superficial 3 ml/min · moderate 25 · severe 90 · arterial 350
                                                 // Tętnicze wykrwawia 3,5 l w dziesięć minut — dlatego opaska uciskowa jest osobnym przedmiotem.

if bleed_tier = superficial or none
    then stops_on_its_own := true                // Zadrapanie zamknie się samo. Wszystko powyżej wymaga opatrunku.

if bleed_tier = arterial
    then needs_tourniquet := true                // Bandaż nie wystarczy.

if bleed_tier = none and blood_loss_this_tick <= 0 and awake
    then blood := blood + 60 ml/h × nourishment  // ⚠️ Odejście od dokumentu: §2.6 nie przewiduje regeneracji. Bez niej przeżycie ciężkiej walki to dożywocie w klasie IV.

if bleed_tier = none and is_sleeping
    then blood := blood + 150 ml/h × nourishment  // ⚠️ ×2,5 za sen pod dachem. Osiem godzin to 1,2 l — dokładnie tyle, żeby wyprowadzić z klasy III, w której §9.2 zostawia po przebudzeniu. Spokojny sen w bezpiecznym miejscu ma działać cuda i nadal nie czyni bandaża opcjonalnym.

if is_sleeping and nourishment = 0
    then blood := unchanged                      // Spanie na głodzie nie odbudowuje nic. Odpowiedź na „czemu krew nie wraca” jest na dwóch pozostałych paskach, nie w tajemnicy.

nourishment = min(calorie_fraction, water_fraction), clamped 0..1
                                                 // Gorsza z dwóch wartości, nie średnia: najedzenie nie zastąpi wody. Głodujący nie regeneruje wcale.

if is_sleeping
    then bleeding := capped at 5% of volume      // §2.1. Nie da się wykrwawić we śnie na śmierć.
```

---

## 9. Śmierć i utrata przytomności

```
if blood_shock = critical or thirst = lethal or hunger = losing_consciousness
    then body_gives_out := true                  // Trzy drogi do zejścia. Kolejność sprawdzania ustala przyczynę wpisaną do Kroniki.

if body_gives_out and is_asleep
    then death := refused                        // §9.1. We śnie krwawienie jest zdławione, więc zgon mógłby wyjść tylko z arytmetyki, której nikt nie oglądał.

if body_gives_out and position_unknown
    then death := refused                        // Zabicie postaci na podstawie braku danych to zabicie jej za wejście do parkingu podziemnego.

if body_gives_out and not asleep and position_known and game_mode = hardcore
    then state := dead and profile.died_at := now
                                                 // Koniec postaci. Wiersz zostaje dla Kroniki.

if body_gives_out and not asleep and position_known and game_mode = softcore
    then state := unconscious and dead_countdown := 60min
                                                 // §9.2. Godzina na ziemi — zegar idzie także przy zamkniętej aplikacji.

if state = unconscious
    then drop_worn_weapon and scatter 50% of pack at death_position
                                                 // Broń z rąk przepada bezpowrotnie; połowa reszty leży tam, gdzie padłeś. Kara rośnie z tym, jak daleko odejdziesz.

if dead_countdown <= 0 and position_known and speed_kmh <= 15
    then wake                                    // ⚠️ Przebudzenie odroczone, nie karane. Ocknięcie się w autobusie postawiłoby postać tam, gdzie gracza nie ma.

if dead_countdown <= 0 and speed_kmh > 15
    then wake := deferred                        // Czeka, aż gracz przestanie jechać.

if wake
    then blood := 65% of max and water := 15% of daily and calories := 15% of daily and stomach := empty
                                                 // ⚠️ Odejście od dokumentu: §9.2 mówi "25% maksimum (klasa III)". To sprzeczne — 25% pozostałej krwi to 75% ubytku, czyli klasa IV i natychmiastowy zgon w pętli. Wygrała klasa, nie liczba.

if wake
    then grace_window := 10min and enemies_ignore_player := true
                                                 // Zawór przeciw obudzeniu się w środku ogniska i natychmiastowemu zejściu z powrotem.

if grace_window > 0
    then player_can_fire := false                // Łaska działa w obie strony. Nie można z niej strzelać.

caches lifetime = 24h                            // ⚠️ Dokument mówi 48 h. Skrytki leżą jako zwykłe rzeczy (§4.8), a te mają dobę. Dług do rozstrzygnięcia.
```

---

## 10. Udźwig i objętość

```
carry_comfort_kg = 0.30 × body_weight_kg         // §1.3. Dla 80 kg: 24 kg komfortowo.
carry_max_kg     = 0.45 × body_weight_kg         // Dla 80 kg: 36 kg maksymalnie.

if backpack_worn
    then comfort += pack_bonus and max += pack_bonus and capacity_l := pack_capacity
                                                 // Plecak trekkingowy podnosi komfort 24 → 36 kg i daje 65 l.

if no_backpack
    then capacity_l := pocket_capacity           // Same kieszenie. Objętość kończy się dużo szybciej niż waga.

if carried_kg > comfort_kg
    then met := met × (1 + 0.8 × load_kg / body_mass_kg)
                                                 // ⚠️ Obciążenie nie spowalnia — gra nie może kazać realnej osobie iść wolniej. Płaci się kaloriami.

if carried_kg + item_kg > max_kg
    then pickup := refused (too_heavy)           // Twarda granica. Nie ma "przeciążenia z karą".

if carried_l + item_l > capacity_l
    then pickup := refused (no_room)             // ⚠️ Dwie granice, bo obie potrafią zabraknąć pierwsze: worek pustych butelek nie waży nic i nie mieści się nigdzie.

if item_worn (not in pack)
    then counts_against_mass but not volume      // §18.1a. To, co na sobie, nie zajmuje miejsca w plecaku.

if blood_shock >= compensated
    then carry_capacity := ×0.90                 // Wstrząs zabiera dziesiątą część udźwigu.
```

---

## 11. Przedmioty i zużycie

```
if item_partially_used
    then portion < 1 and line_splits_from_stack  // §4.7. Butelka wypita do połowy nie wraca do stosu pełnych — stos trzech, z których jedna jest napoczęta, to nie stos trzech.

if item_has_attachments
    then mass := base + sum(attachment_mass) and volume := base + sum(attachment_volume)
                                                 // Dodatek waży. Bez tego tłumik byłby darmowy i nikt by go nie zdejmował.

if weapon_dropped
    then attachments_stay_on_weapon              // §5.6.3. Karabin podniesiony z chodnika wraca z tym, co na nim było.

if pack_order = kind | name | mass
    then sort accordingly, always tie-break by translated name
                                                 // §12. Plecak odpowiada na trzy różne pytania: gdzie bandaże, co odłożyć, czy mam łom. Jedna stała kolejność odpowiada na jedno i zamienia dwa pozostałe w przewijanie. ⚠️ Nazwa **przetłumaczona** — sortowanie polskiego plecaka po angielskich id stawiało Bandaż między Latarką a Liną.

if item_is_note
    then never_stacks                            // Dwie notatki to dwie różne wiadomości od dwóch różnych ludzi.

if item_is_book
    then pages_read_travels_with_the_copy        // Egzemplarz pamięta stronę. Druga kopia tego samego tytułu to inny obiekt (§4.6.4).

if item_condition != other_condition
    then lines_do_not_merge                      // Dwa noże w różnym stanie to dwie różne rzeczy do posiadania.

if content_pack_removed and item_id_unknown
    then line_dropped_on_read and reported       // §4.1. Odinstalowana paczka zabiera swoje przedmioty — zapis się nie wywraca.
```

---

## 12. Loot — co się pojawia

```
if active_boxes_within_radius >= 15
    then spawn := refused                        // §10 twardy limit. Więcej znaczników to nie więcej gry, tylko szum.

spawn_radius = 1200m                             // ⚠️ Figura beta, dokument mówi 2000 m. Powód: 25 minut marszu po jeden sklep to szum, a znacznik, do którego nikt nie pójdzie, uczy ignorowania znaczników. Wraca do 2 km, gdy będą ogniska (§6.5).

if near_ring_active < 5 and candidate_distance <= 600m
    then fill_near_ring_first                    // Pięć miejsc w promieniu 600 m — siedem minut marszu. Bez tego mapa jest zadaniem, a nie wyborem.

if generated_car or generated_waste and furniture_nearby < 3
    then spawn_reserved_slot                     // ⚠️ Rezerwacja z puli 15, nie ponad nią. Zmierzone na spacerze: gęste miasto zapełniało bliski pierścień prawdziwymi sklepami i nie dawało ani jednego samochodu.

if poi_is_tagged_parking
    then never_takes_furniture_slot              // §10.1 słusznie trzyma 4165 parkingów Poznania z dala od mapy. Rezerwacja dotyczy tylko punktów wymyślonych.

if map_is_thin (poi_count < 8)
    then backup_mode := on and spawn_radius := 1800m and respawn := 3–5h
                                                 // Wieś musi sięgać dalej po cokolwiek.

if box_looted
    then respawn_after := random(4h, 8h)         // Miejsce wraca, ale nie od razu. Farmienie jednego sklepu nie działa.

if box_distance > 4000m
    then box_forgotten                           // Gracz, który przeszedł trzy kilometry, nie ciągnie za sobą całej poprzedniej dzielnicy.

if place_type = house/barn/hunting_stand (procedural)
    then visible := false until reconnaissance    // §10.2.1. Dom, który może być opuszczony, to dokładnie to, po co jest rozpoznanie.

if place_type = car/bin/shop
    then visible := true                         // ⚠️ Samochód na ulicy widać z chodnika. Ukrywanie wszystkiego, co wymyślone, dawało miasto bez samochodów i śmietników.
```

---

## 13. Przeszukanie i bariery

```
search_time = depth_seconds × place_size_scale, minimum 5s

depth: shallow 30s · thorough 90s · deep 180s    // §10.3.5. Głębiej znaczy lepsze rzeczy, nie więcej rzeczy.
size:  tiny ×0.2 · small ×0.5 · normal ×1.0      // ⚠️ Odejście od dokumentu (jeden czas dla wszystkiego). Śmietnik: ~6 s. Samochód: ~45 s. Sklep: pełne 30/90/180.

if depth = shallow
    then draws 1–2 and tiers = {common}          // Szybkie zerknięcie. Materiały, nic więcej.

if depth = thorough
    then draws 2–4 and tiers = {common, uncommon}
                                                 // Trzy razy dłużej, dwa razy szerzej.

if depth = deep
    then draws 3+ and rare_weight boosted        // Jedyna droga do rzadkich rzeczy.

if search_budget_spent >= 6
    then place_is_empty                          // Sześć punktów na miejsce. Trzy szybkie zerknięcia albo jedno głębokie — nie oba.

if deep_search_used
    then must_be_first_action_on_this_place      // Głębokie przeszukanie ma sens tylko na nietkniętym miejscu.

if player_distance_to_place > 25m
    then search := refused                       // §10.2. Trzeba tam być.

if player_moves > 15m during search (2 strikes)
    then search := cancelled                     // ⚠️ Dwa naruszenia, nie jedno: pojedynczy dziwny fix to dziwny fix, a nie powód, żeby skasować trzy minuty pracy gracza.

if barrier_exists and not already_open
    then breach_required                         // §19.3. Apteka jest zamknięta, parking nie.

if barrier_already_open
    then enter_freely                            // Losowane z ziarna miejsca i postaci, nie z zegara: sklep otwarty wczoraj jest otwarty dziś. Świat, w którym każde drzwi są zamknięte, to świat, w którym nikt inny nie żył.

already_open_share: door 35% · padlock 10% · window 45%
                                                 // Kłódka to ta, która zwykle wytrzymała. Okno to droga, która istnieje zawsze.

if barrier = door
    then force 20s / 150m  ·  lockpicks 60s / 20m  ·  crowbar|axe 12s / 150m
                                                 // ⚠️ Cały wybór §19.3: wytrych jest trzy razy wolniejszy i prawie bezgłośny, łom jest szybszy od barku przy tym samym hałasie.

if barrier = padlock
    then lockpicks 45s / 20m  ·  bolt_cutters 10s / 60m  ·  crowbar|saw|multitool 25s / 60m
                                                 // ⚠️ Cęgi są narzędziem, dla którego ta bariera powstała, i długo ich w grze nie było. Dwa kilogramy stali jednego przeznaczenia kupują szybkość i płacą uwagą.

if barrier = padlock and no_tool
    then breach := impossible                    // §19.3 wskazuje kłódkę jako jedyną barierę wymagającą narzędzia. Bark jej nie otworzy, a udawanie inaczej czyniłoby każde narzędzie w katalogu opcjonalnym.

if barrier = window
    then force 5s / 150m only                    // Pięć sekund i sto pięćdziesiąt metrów hałasu. Nie ma cichej drogi przez szybę.

if module_requirements_checked
    then have := pack + shelves                  // §18.2. Stojący we własnym schronie stoi przy własnej półce. Kazanie mu podnieść dwadzieścia desek z półki, zanim przycisk się zaświeci, to księgowość, nie decyzja.

if materials_spent
    then shelves_first, then pack                // Wydawanie z półki najpierw wypuszcza gracza z jak najmniejszym obciążeniem — po to §18.2 daje schronowi magazyn.

if breach_needs_tool and tool_missing
    then breach := unavailable                   // Narzędzie albo inna droga.

if reconnaissance and 30% roll and last_find > 3min ago
    then spawn car|skip at 30–75m and reveal it
                                                 // ⚠️ Nie z dokumentu, figura beta. §10.1 stawia świat na realnych obiektach mapy — słusznie — i przez to osiedle mieszkaniowe bywa naprawdę puste. Rozejrzenie się już kosztuje 45 s bezruchu i 80 m hałasu; to jest to, co ten koszt kupuje tam, gdzie nie ma sklepów. Nigdy sklep, nigdy tam, gdzie §3.5 odmawia.

if last_scout_find < 3min ago
    then no_find                                 // ⚠️ Zawór całego pomysłu. Bez niego jeden róg i jeden przycisk to kran na surowce, a chodzenie, wyważanie drzwi i przeszukiwanie ciał stają się gorsze od stania na parkingu.

if reconnaissance
    then duration := 45s and radius := 100m and noise := 80m and memory := 10min
                                                 // Czterdzieści pięć sekund to sześćdziesiąt metrów nieprzejścia — to jest koszt.
```

---

## 14. Celność strzału

```
moa_total = (weapon + skill + heart + movement + target + condition) × spread_multiplier

skill_moa = 25 − 21 × skill                      // §5.1.2. Skill = 0 dla wszystkich, bo §7 nie istnieje — każdy strzela jak nowicjusz na 25 MOA.
heart_moa = 60 × hr_ratio²                       // ⚠️ Kwadrat jest sednem: podejście do strzału nie kosztuje prawie nic, ucieczka kosztuje wszystko.

if aim_just_switched_target
    then spread_multiplier := 2.5 decaying over 2–4s
                                                 // §5.5.1. Nieustabilizowany obraz celownika otwiera *wszystkie* źródła naraz — strzelec nie robi nowego błędu, tylko wszystkie stare większe.

hit_chance = normal_distribution(spread_diameter / 4) over target_size
                                                 // Rozrzut jako sigma, nie jako "procent trafień z tabelki".

if distance <= 0
    then hit_chance := 1                         // Lufa przy ciele.

if magazine_empty
    then fire := refused                         // Trzeba przeładować.

if reload_running and enemy_within 5m
    then reload := broken                        // §5.5.4. Ręce stają, kiedy ciało jest tak blisko. Gra nie dyskutuje o intencji.

if reload_running
    then reload_progress := elapsed / total, ticked 10×/s
                                                 // §5.5.4. Przeładowanie ma własny zegar. Wcześniej szło do przodu tylko przy nowym odczycie GPS — w schronie, w budynku, wszędzie gdzie sygnał znika, sekundy nie mijały wcale: magazynek nigdy nie wchodził, żaden pasek się nie ruszał, a przycisk wyglądał na martwy.

if reload_running and weapon_has_no_magazine
    then label := "Montowanie magazynka"        // Trzy różne rzeczy noszą te same 3,5 s. Kto nacisnął przycisk, ma prawo wiedzieć, którą zaczął.

if reload_running and weapon_has_magazine
    then label := "Wymiana magazynka"

if reload_running and feed = loose
    then label := "Ładowanie naboi"

if magazine_full
    then reload := unavailable                   // Prośba z testów: przycisk nieaktywny, zamiast marnować akcję.

if magazine_fill_running or magazine_empty_running
    then magazine_rounds := round(from + (to − from) × progress)
                                                 // §4.2. Naboje idą pojedynczo, wraz z paskiem — nie hurtem na końcu. Liczone z ułamka, nie doliczane co tyk, więc tyk spóźniony albo podwójny niczego nie psuje.

if magazine_empty_running and rounds_leave_magazine
    then loose_ammo := existing_stack + 1        // Do stosu, który już leży w plecaku. Trzydzieści osobnych linii po jednym naboju to nie ekwipunek, to lista.

if magazine_fill_interrupted or magazine_empty_interrupted
    then moved_rounds := kept                    // §4.2. To, co już przeszło, przeszło. Naboje są tam, gdzie są — przerwanie nie cofa czasu.

if part_is_magazine and caliber_matches
    then attachable := true                      // §4.2. Magazynek to część jak każda inna. Katalog nazywa jego typ `magazine`, żaden ItemKind tego słowa nie zna, więc każdy magazynek w grze jest `misc` — a stary warunek pytał o `attachment`. Karta broni pytała, dostawała "nie" i nigdy nie rysowała gniazda: jedyną drogą było przeładowanie.

if magazine_mounted
    then weapon_rounds := magazine_rounds        // §5.3. Naboje jadą razem z magazynkiem. Bez tego wpięcie pełnego magazynka dawało pusty karabinek i kasowało trzydzieści naboi.

if magazine_removed
    then magazine_rounds := weapon_rounds, weapon_rounds := 0
                                                 // I z powrotem. To, co było w środku, idzie ze środkiem.

if part_is_magazine
    then slots_used += 0                         // §5.6.3. Gniazdo magazynka to nie szyna. Liczenie go jako slotu znaczyło, że wpięcie magazynka kosztuje kolimator — bez sensu w broni, która bez niego nie strzela.

if weapon_feed = magazine
    then magazine_slot := always_shown           // Nawet pusty. "Karabinek bez magazynka" to najważniejsze zdanie, jakie ta karta może powiedzieć; ukrywanie wiersza z braku kandydata nie mówiło nic.

if magazine_candidates > 1
    then picker := dropdown sorted by rounds desc
                                                 // Kto sięga po magazynek, chce ten pełny. Pięć wierszy o tej samej nazwie z różnymi liczbami to gorszy sposób zadania tego pytania niż jedna lista z liczbami obok siebie.

if attachment_slot_taken
    then attach := refused                       // §5.6.3. Jedno miejsce, jedna rzecz. Drugi kolimator nie wchodzi na pierwszy; laser i latarka dzielą szynę — jedno albo drugie, bo oba jedzą baterie i oba widzą przeciwnicy (§6.2).

if attach_target_line not in inventory
    then load := refused (gone)                  // §11.1. Uchwyt do linii zwietrzał — coś przebudowało plecak pod akcją. Cicha wersja gubiła naboje: wychodziły z torby, nie docierały do magazynka i znikały przy zapisie.

if magazine_rounds > 0 and player_in_inventory
    then unload_button := shown                  // Magazynek opróżnia się, żeby napełnić inny albo żeby zostawić ciężar. Ten sam pół minuty, tylko w drugą stronę.

if player_inside_own_shelter_zone
    then fire := refused                         // §8.1. Nie strzela się z własnej strefy bezpiecznej. Czytane z pozycji lepkiej, nie ze snapshotu — inaczej wystarczyło poczekać na utratę sygnału w budynku.

if hit
    then location := roll(head 12% · torso 45% · arms 18% · legs 25%)
                                                 // §2.6. Nikt nie celuje w nogę — to jest to, gdzie nabój poleciał, nie gdzie był posłany.

wound_multiplier: head ×4.0 · torso ×1.0 · arms ×0.6 · legs ×0.7
                                                 // Głowa kończy walkę. Ręka jej nie kończy i o to chodzi.

if armor_covers_location
    then damage := damage × (1 − protection/5)   // §4.4. Pancerz działa tylko tam, gdzie zakrywa.
```

---

## 15. Hałas

```
base_noise: walking 15m · running 40m · melee 25m · pistol 450m · rifle 700m · shotgun 900m
            suppressed_pistol 120m · suppressed_rifle 200m · breaching 150m · building 100m
                                                 // §5.6.1. Cała cena broni palnej jest w tej tabeli.

if night
    then noise := ×1.3                           // Inwersja niesie dźwięk nad dachami.

if dense_urban and not night
    then noise := ×0.7                           // Zabudowa tłumi — ale tylko w dzień.

if open_ground
    then noise := ×1.2                           // W polu niesie dalej.

if bad_weather
    then noise := ×0.75                          // Deszcz i wiatr maskują.

if second_shot within 30s
    then event_radius := ×1.15 and point := moves to new shot
                                                 // ⚠️ Seria to jedno zdarzenie, nie pięć. Inaczej dwie sekundy ognia ściągałyby pięć tłumów.

if distance_to_noise <= radius / 3
    then reaction := chase (player located)      // Z bliska nie ma czego ustalać — wiedzą, skąd padło.

if distance_to_noise <= radius
    then reaction := alert (walk to the sound)   // Idą do *miejsca dźwięku*, nie do gracza. To zostawia miejsce na taktykę.

if distance_to_noise > radius
    then reaction := none                        // Nie usłyszeli.

if responders_already >= 6
    then no_more_respond                         // Bez tego jeden strzał przy ognisku poziomu 10 to wyrok.

if noise_radius >= 200m
    then startling := true and responders_run    // ⚠️ Odejście od dokumentu (marsz). Chybiony strzał ściągający przeciwników spacerkiem z 400 m czytał się jak świat, który go nie usłyszał.
```

---

## 16. Przeciwnicy — stany

```
if distance <= 20m
    then band := melee                           // §5.2. Poniżej tego gra przestaje udawać, że GPS wie, kto gdzie stoi — rozstrzyga abstrakcyjnie: ilu ich jest i jak często każdy może uderzyć.

if distance > 50m and <= 250m
    then band := ranged                          // §5.2: tam, gdzie należy strzelanina.

if distance > 250m
    then band := too_far                         // Poza pasmem, w którym strzał ma sens.

detection_min = 150m                             // §5.2. Nic nie jest nigdy zauważone bliżej — coś, co pojawia się na 80 m, pojawiłoby się wewnątrz dystansu, z którego warto strzelić.

enemy kinds: walker (3–4 / 15–18 km/h, 3200–3600 ml, 180 dmg, sight 80m, dies at 45% loss)
             runner (5–7 / 27–32 km/h, 2400–2800 ml, 120 dmg, sight 120m, dies at 45%)
             brute  (2–4 / 12–17 km/h, 6000–8000 ml, 400 dmg, sight 60m, dies at 50%)
                                                 // Biegacz widzi najdalej i biegnie najszybciej; Brutal widzi najsłabiej i najtrudniej go położyć.

chase_distance = detection_m × 0.6               // §6.1a. Pościg zaczyna się wewnątrz 60% tego, co widzi.

if distance <= chase_m or heard_shot
    then state := chase                          // Bieg wprost na gracza.

if distance <= sight_m
    then state := alert                          // Wie, że coś jest, ale nie ma jeszcze pozycji.

if hit_by_player and from_position_known
    then state := chase and target := shot_origin
                                                 // ⚠️ Dziura w ciele to lepszy dowód niż wzrok i słuch razem. Bez tego ranny szukał dalej *miejsca hałasu*, przez co drugi nabój był tańszy od pierwszego.

if sprint_budget <= 0
    then state := spent and speed := run × 0.4   // §6.1a. Wyczerpanie to nie zatrzymanie, tylko wolniejsze podejście.

if state = spent and budget < 25% of max
    then stays spent                             // Bez histerezy migotałby między biegiem a marszem co tik.

sprint_budget: walker 25s (recovery 60s) · runner 90s (45s) · brute 45s (120s)
                                                 // Biegacz jest nie do przeczekania. Szwędacza da się zmęczyć.

if distance <= 150m
    then contact := kept and since_contact := 0  // Kontakt to bliskość gracza, nie starania przeciwnika.

if since_contact >= 45s and not searching
    then state := returning                      // Spacer wokół bloku naprawdę ich gubi.

if since_contact >= 45s × 2.5 and enemy_wounded
    then state := returning                      // ⚠️ Ranny nie odpuszcza tak szybko — 112 s zamiast 45. Odpuszczanie w tym samym tempie co nietrafiony czyniło drugi strzał tańszym od pierwszego.

if distance_from_home > 400m
    then state := returning                      // Smycz. Nie da się ciągnąć pociągu przeciwników przez pół miasta.

if arrived_at_noise_point (within 10m)
    then investigate_for := 30s then forget      // ⚠️ Skrócone z 60 s. Minuta krążenia w jednym miejscu przestawała czytać się jak szukanie, a zaczynała jak zacięcie.

if state = idle
    then wander within 40m of home, max turn 12°/s
                                                 // Ciało, nie kursor. Coś, co skręca o 118° na sekundę, czyta się jak usterka.

if enemy_within 20m of player
    then melee_exchange begins                   // §5.2. Poniżej 20 m gra przestaje udawać, że GPS wie, kto gdzie stoi.

if enemies_in_reach > 1
    then damage := damage × flanking_multiplier  // §5.5.3. Gracz odpowiada jednemu, reszta bije swobodnie — dlatego wpuszczenie grupy to prawie wyrok.

if player_inside_sanctuary
    then enemies_pushed_to_boundary              // §8.1. Czekają na granicy, twarzą do środka. Nikt nie może obozować we własnych drzwiach.
```

---

## 17. Przeciwnicy — spawn

```
if spawn_distance_to_player < 150m
    then spawn := refused                        // §6.4. Coś, co zmaterializowało się o 80 m, to jump scare, a nie walka, w którą się weszło.

if spawn_distance_to_shelter < 200m
    then spawn := refused                        // Strefa schronu plus zapas.

if active_enemies_within 300m >= 8
    then spawn := refused                        // §5.5.6. Powyżej ósemki symulacja kosztuje klatki, a walka przestaje być do wygrania inaczej niż szczęściem.

if horde_event
    then cap := 12                               // §6.5.5. Podnoszone tylko przez ognisko.

ambient_density = 2 per km²                      // §6.4. To jest cała dzisiejsza populacja — ogniska (§6.5, etap 6) jeszcze nie istnieją.

if enemy_distance > 900m
    then enemy_forgotten                         // Ktoś, kto przeszedł trzy kilometry, nie symuluje każdej minionej ulicy.

if enemy_id_prefix_matches_origin
    then next_id := max(existing_ids) + 1        // ⚠️ Nie licznik żywych. Śmierć ze środka listy zmniejszała licznik i następny spawn dostawał numer, którego poprzednik wciąż używał — dwa ciała pod jednym id, sześć zabitych jako dwie czaszki.

if app_closed_longer_than 5min and enemy_was_bleeding and bleeds_out_in <= gap
    then remains_marker at last_known_position   // ⚠️ Rana to nie spacer. Coś z dziurą i znanym tempem ma dokładnie jedną przyszłość, a wyrzucenie sesji ją kasowało. Trzecia i ostatnia przyczyna brakującej czaszki: strzel, patrz jak ucieka, schowaj telefon, wróć do niczego.

if app_closed_longer_than 5min
    then street := emptied and rebuilt           // §11.1.2. Co robił Szwędacz przez osiem godzin snu, nie jest do odtworzenia — więc się tego nie zgaduje.

if player_engaged_and_app_closed
    then pursuit_written (place, time, count) for 15min within 500m
                                                 // ⚠️ Zamknięcie gry w środku walki było doskonałą ucieczką. Zapisywany jest sam fakt pościgu, nie ścigający.
```

---

## 18. Ciała i rzeczy na ziemi

```
if enemy_dies
    then remains_marker at death_position for 12h
                                                 // §10.3. Ciało to nie kupka lootu. ⚠️ Dwanaście godzin, wcześniej sześć: coś ustrzelonego po drodze do pracy ma tam być w drodze powrotnej, inaczej „wrócę po to później” jest obietnicą bez pokrycia.

if remains.id already in list
    then no second body                          // ⚠️ Deduplikacja *wyłącznie po id*. Reguła "bliżej niż 5 m to jedno ciało" zjadała drugie ciało każdej pary, która padła obok siebie — a zabicie wręcz dzieje się na wyciągnięcie ręki.

if remains_searched
    then marker stays, marked as searched        // Gracz, który już tam był, musi to widzieć — inaczej wróci drugi raz.

if item_dropped
    then lifetime := 24h                         // §4.8. Doba to dość, żeby wrócić, i za mało, żeby ziemia była magazynem.

if dropped_items > 50
    then oldest_forgotten                        // Sprzątanie, żeby mapa nie zamieniła się w listę zakupów.

if pile_within 15m of player
    then pickup_available                        // Zasięg ręki, nie zasięg budynku.

if all_items_taken_from_pile
    then sheet_closes_itself                     // ⚠️ Bez komunikatu "już nic tu nie ma". Gracz właśnie patrzył, jak to zabiera.
```

---

## 19. Schron i obóz

```
if no_shelter_exists and position_known
    then build_main_available                    // Jest tylko jeden schron główny.

build_time: main 3h · camp 40min
if has_hammer or has_axe
    then build_time := ×0.65                     // ⚠️ §8.3 mówi −35%, §18.3 mówi ×2,5 bez narzędzi. Dokument przeczy sam sobie; wdrożono §8.3. Do rozstrzygnięcia.

if player_leaves_site during build
    then progress := paused                      // §2.1a.3. Praca liczy się wyłącznie na placu.

if build_running
    then progress_saved every 15s with timestamp // Noc z zamkniętą aplikacją liczy się w całości — zegar jest w bazie, nie w pamięci.

if build_cancelled
    then progress := lost permanently            // Ostrzeżenie przed, nie po. Nie da się cofnąć.

if shelter_ready and player_within 50m
    then safe_zone := active                     // §8.1. Jedna liczba na wejście przeciwników i na wyjście strzału — celowo ta sama.

if shelter_not_ready
    then safe_zone := inactive                   // Na wpół zabarykadowany dom nie trzyma niczego z dala. Inaczej trzy godziny byłyby darmowe.

if camp_count >= 2
    then new_camp := refused                     // §8.5.2.

if camp_distance_to_shelter < 800m
    then camp := refused                         // Obóz obok schronu to drugi schron.

if camp_distance_to_hotspot < 400m
    then camp := refused                         // Obóz, do którego nie da się dojść.

if camp_not_visited for 14d
    then camp := decaying                        // Ostrzeżenie widoczne na mapie.

if camp_not_visited for 21d
    then camp := gone and stash := deleted        // ⚠️ To nie jest kod, tylko klucz obcy z kaskadą. Reguła wymuszona w schemacie nie może zostać zapomniana przez wołającego.

sleep_quality: main 1.00 · camp 0.70             // Godzina w obozie warta jest siedem dziesiątych nocy.
if lounge_level > 0
    then sleep_rate := ×(1 + 0.15 × level)       // §8.4. Mniej godzin snu to więcej godzin na jawie z książką.

if workshop_level > 0
    then repairs_available                       // ⚠️ Dokument daje 3% na poziom i sam oznacza to jako niezbalansowane. Przepisane na dostęp do napraw.
```

---

## 20. Półka w schronie

```
storage_kg = base_kg + 50 × storage_module_level
base: main 25kg · camp 30kg                      // Zabarykadowany dom trzyma 25 kg sam z siebie — od chwili, gdy deski są przybite, bez żadnego modułu.
storage_l = storage_kg × 3                       // Trzy litry na kilogram — ten sam przelicznik co plecak.

if shelter_not_ready
    then shelves := unavailable                  // Nie ma jeszcze gdzie odkładać.

if player_not_at_site
    then shelves := refused                      // §2.1a.3. Sięganie do własnego domu z drugiego końca miasta nie jest rzeczą.

if stash_mass + item_mass > storage_kg
    then store := refused                        // Obie granice odmawiają osobno.

if stash_volume + item_volume > storage_l
    then store := refused                        // Półka pełna pustych butelek ma zapas wagi i zero miejsca.

if item_portion < 1 or has_pages or is_note or has_attachments
    then never_stacks_on_shelf                   // Karabin z kolimatorem nie jest wymienny z gołym. Książka na stronie 40 to nie nieprzeczytany egzemplarz.

if taken_from_shelf and pack_full
    then take := refused and item_stays          // Półka nie jest sposobem na obejście §18.1a.

if taken_from_shelf
    then portion, pages_read, condition, attachments := preserved
                                                 // ⚠️ Znaleziony błąd: `Inventory.add` odtwarzało linię z argumentów i nie miało argumentu na `portion` — butelka zdjęta z półki wracała pełna. Nieskończona woda za dwa dotknięcia.
```

---

## 21. Mapa i znaczniki

```
if marker_distance <= 300m
    then enemy_drawn                             // §5.5.6. Widok każdego Szwędacza w dzielnicy odpowiadałby na pytanie, po które jest §7 Rozpoznanie.

if marker_position_changed and not economy
    then glide over 1s from where it is painted  // §3.6. Tik ma 1 Hz, więc każdy ruch przychodzi skokiem. Rysowane jest to, dokąd rzecz zmierza, nie gdzie ostatnio ją zgłoszono. ⚠️ To kłamstwo ograniczone do szyby — nic w grze nie mierzy odległości z tych współrzędnych.

if new_position_arrives_mid_glide
    then new_leg_starts_from_painted_position    // Nie od ostatnio zgłoszonej: inaczej znacznik cofa się i rusza od nowa, co wygląda gorzej niż brak interpolacji.

if marker_first_seen
    then no_glide                                // Coś, co się pojawiło, nie ma skąd przyjechać. Wsuwanie go z boku byłoby wymyślaniem podróży.

if nothing_is_gliding
    then no_per_frame_repaint                    // Pusta ulica nie kosztuje klatek.

if economy
    then glide := off                            // §3.3. Znacznik, który skacze, wciąż jest we właściwym miejscu.

if map_centre_changes
    then camera_glide := measured_gap (clamped 0.3s … 6s)
                                                 // ⚠️ Mierzone, nie wybrane. Fix przychodzi co 1 s w walce i co 5 s w marszu — domyślny przesuw pluginu pokonywał pięć sekund chodnika w mgnieniu i stał. Żadna stała nie obsłuży obu kadencji.

if marker_already_drawn and distance <= 375m
    then stays_drawn                             // ⚠️ Histereza ×1,25. Spawner robi rzeczy do 600 m, mapa rysowała do 300 — ten sam Szwędacz migotał, przechodząc granicę tam i z powrotem.

if two_markers_within 25m
    then clustered into one                      // Grupowanie, żeby róg ulicy nie był jednym nieklikalnym kleksem.

camera_tilt = 45° fixed                          // Stałe, bez gestu: mapa czytana w marszu ma być za każdym razem tą samą mapą — a jeden kąt znaczy, że perspektywa znaczników liczona jest raz.

if zoom >= 14
    then buildings_extruded                      // Niżej blok jest plamą, a wytłaczanie kosztuje klatki za nic.

if building_has_no_render_height
    then height := 8m                            // ⚠️ `get` na brakującym polu daje null, które wytłacza się do zera — dziura w ulicy tam, gdzie stoi dom. Dwa piętra to uczciwa wartość dla budynku, którego nikt nie zmierzył.

screen_offset:  right = x, up = y × cos(tilt), forward = D + y × sin(tilt)
                                                 // Rzut perspektywiczny. Przy tilt = 0 człon forward to samo D, dzielenie się skraca i zostaje stary płaski wzór.
D = 0.5 / tan(fov/2) × viewport_height, fov = 0.6435 rad
                                                 // Własna reguła MapLibre — półtora wysokości ekranu.

if tap_offset_far_from_centre
    then tap_slop := slop × foreshortening        // Palec przy górnej krawędzi przykrywa więcej terenu. Bez skalowania dalsza połowa mapy jest nieklikalna.

if player_moves > 25km from map_pack
    then offer_relocation                        // Zmiana województwa, nie spacer.
```

---

## 22. Bateria i wydajność

```
if battery <= 20% and not charging
    then economy := true                         // §3.3. Jeden przełącznik na wszystkie luksusy.

if economy
    then animations := off and camera_jumps and gps_cadence := reduced and refresh_rate := low
                                                 // ⚠️ Wysokie odświeżanie idzie tym samym przełącznikiem co animacje. Płynność to ten sam rodzaj luksusu — bez drugiego ustawienia dla gracza.

if not economy
    then refresh_rate := high (90/120 Hz)        // Pytane raz przy zmianie stanu, nie co tik: każde wywołanie to przelot przez platform channel.

gps_cadence: combat 1 Hz · walking 0.2 Hz · standing 0.05 Hz
                                                 // Baterię oszczędza się pytając rzadziej, nie pytając gorzej.

if accuracy_setting < high
    then never                                   // ⚠️ Nigdy poniżej `LocationAccuracy.high`. `medium` to WiFi i BTS (20–100 m), nie GPS — zmierzone: każdy fix wypadał poza bramkę 25 m i gracz stojący na otwartej ulicy dostawał "słaby sygnał".

if slowing_down_cadence
    then hold for 60s first                      // Zwalnianie czeka minutę; przyspieszanie jest natychmiastowe. Asymetria celowa.
```

---

## 23. Profil i statystyki

```
if shot_fired at target
    then shots_fired += 1 and (hit ? shots_hit += 1 and hits[location] += 1)
                                                 // §13.1.

if shot_fired_into_the_air
    then no_stats_change                         // ⚠️ Strzał ostrzegawczy (§5.6.2) nie był celowany. Wliczony psułby celność i jedyne rozsądne użycie systemu hałasu wyglądałoby jak nieudolność.

if enemy_dies and body_added_to_list
    then kills += 1                              // ⚠️ Liczone tam, gdzie powstaje ciało — bo śmierć zauważana jest z trzech miejsc (strzał, cios, przemiatanie), a dedup po id jest tylko tam.

if shots_fired = 0
    then accuracy := null (shown as "—")         // Nie 0%. Kto nie strzelał, nie ma celności — pokazanie zera to gra mówiąca, że jesteś zły w czymś, czego nie robiłeś.

if player_goes_down (any mode)
    then blackouts += 1                          // Także zgon w hardcore: to ostatni wiersz rejestru, nie jego brak.

if place_searched or body_searched
    then searches += 1                           // Licznik, nie stan — rośnie i nigdy nie maleje.

telemetry := never leaves the device             // §16.5 dopuszcza zagregowaną telemetrię za zgodą. To nie jest ona.
```

---

## Akcje w toku (§2.1a, §12)

```
if any_action_running
    then shown in one strip under the stats GUI  // ⚠️ Reguła bezwzględna. Gracz idzie z telefonem w ręku. Akcja, której jedynym śladem jest ekran, na który trzeba wejść — warsztat, schron, plecak — to akcja, której nie widać w trakcie gry i z której nie da się wyjść, kiedy coś wychodzi zza rogu.

if any_action_running
    then it can be stopped from that strip       // Bez wyjątków. Jeśli czegoś nie da się przerwać, to nie powinno tam być.

if two actions running
    then both lines drawn                        // Wcześniej było jedno miejsce pokazujące to, co samo wybrało. Przeładowanie i rozbiórka mogą iść naraz, a mówiła o sobie tylko jedna.

actions in strip: przeszukanie · użycie przedmiotu · przeładowanie · magazynek · wytwarzanie · rozbiórka · budowa
                                                 // Dodanie nowej akcji z zegarem znaczy dodanie jej tutaj, w tym samym commicie.

if action not applicable to item
    then no button at all                        // ⚠️ Nieobecny, nie wyszarzony. Martwy przycisk czyta się jako zepsuty — i tak było czytane trzy razy: wymagania schronu (szare = wyłączone), ikona rozbiórki na siekierze, ikona przeładowania bez magazynka. Pytanie brzmi zawsze "czy to teraz zadziała", zadane tą samą funkcją, która ma to zrobić.

if action applies but cannot happen now
    then button greyed, reason under the item on press
                                                 // ⚠️ Dwa różne "nie" i dwie różne odpowiedzi. Rozbiórka puszki fasoli nie dotyczy przedmiotu — przycisku nie ma. Pełne półki dotyczą chwili — przycisk szarzeje i mówi dlaczego. Drugie jest czymś, co gracz może pójść i naprawić; ukrycie zostawiłoby go w poszukiwaniu kontrolki, która była tam minutę temu.

if greyed button pressed
    then reason shown under that row             // Wciąż klikalny. Szary przycisk, który połyka tapnięcie, niczego nie uczy — gracz klika drugi raz, uznaje grę za zepsutą i to zapisuje.

if reason no longer true
    then reason cleared                          // Nieaktualna odpowiedź jest gorsza niż żadna: wiersz mówiłby "półki pełne" długo po ich opróżnieniu.

reason shown under the row, not at the top       // Cztery wiersze mówiące naraz "półki pełne" to ściana. Jeden wiersz pod ikoną, którą naciśnięto, to odpowiedź.

```

---

## Wytwarzanie i rozbiórka (§18.3, §18.4, §18.6)

```
if recipe_workshop_level > shelter_workshop_level
    then craft := unavailable                    // §18.4. Warsztat to dostęp do możliwości, nie procent czasu (§8.4).

if recipe_tools_any_of not empty and none_carried
    then craft := refused                        // §18.4 pisze "nóż **lub** multitool" i tak to znaczy. Jedno id po cichu zrobiłoby z jednego narzędzia jedyną odpowiedź — tak było w schronie przez miesiące.

if recipe_tools_any_of empty
    then craft := allowed_anywhere               // Opatrunek robi się na krawężniku, kiedy się krwawi. To jest cały sens medycznych wierszy §18.4.

craft_time = base × (1 − 0.30 × inżynieria) × warsztat(L1 0.90 / L2 0.80 / L3 0.70)
                                                 // §18.3. Ten sam wzór co budowa modułów, celowo.

salvage_content = recipe_materials, or props.salvage
                                                 // §18.6. Gdzie jest receptura, ona **jest** wartością materiałową. Gdzie jej nie ma — masa przedmiotu rozłożona na to, z czego naprawdę jest, podzielona przez masy jednostkowe z crafting.json.

salvage_budget = round(suma_jednostek × udział × kondycja/100)
                                                 // ⚠️ §18.6 nie domyka się arytmetycznie. 40% karabinka to 0,88 jednostki metalu; w dół, per materiał — zero. Siekiera zero, włócznia zero, kamizelka zero. Jeden budżet na cały przedmiot, zaokrąglany raz, rozdzielany metodą największych reszt.

if salvage_budget = 0
    then dismantle := refused                    // Karabinek daje jeden kawałek złomu. Pistolet nie daje nic — i tak ma być. Odmowa **przed** wydaniem minut, nie po.

salvage_share = 0.40 + 0.15 × inżynieria (+0.10 przy warsztacie L2+)
                                                 // §18.6. Maksimum 65%. Recykling nigdy się nie opłaca jako źródło surowca — opłaca się wyłącznie jako sposób na pozbycie się balastu bez całkowitej straty.

if item_condition < 100
    then salvage_budget ×= condition/100        // §18.6 nalega. Bez tego najtańszym metalem w grze byłyby zniszczone bronie zbierane po to, żeby je rozebrać.

if item has no recipe and no props.salvage
    then dismantle := unavailable                // §18.6: nie rozbierzesz czegoś, czego receptury nie znasz. Od drugiej strony: jedzenia i książek nie ma jak rozebrać, bo nie ma czego z nich wyjąć.

dismantle_time = 3 min + 12 min × min(1, jednostki/10)
                                                 // §18.6. Mierzone zawartością, nie recepturą — większość tego, co się rozbiera, nigdy nie została przez nikogo zrobiona.

if craft_started
    then materials spent immediately             // ⚠️ §18.4. Płaci się na starcie, nie na końcu. Inaczej można zacząć włócznię, wydać to samo drewno na szynę i odebrać oba.

if dismantle_started
    then item removed from pack immediately      // ⚠️ §18.6. Przedmiot znika w chwili startu. Zostawiony w plecaku pozwalałby strzelać z karabinka przez ten kwadrans, który zajmuje jego rozebranie.

if dismantle_running
    then item stays in pack, locked              // ⚠️ Zmiana wobec pierwszej wersji: przedmiot nie znika na starcie, tylko zostaje zablokowany. Pasek musi być pod czymś, a rzecz, która znika na kwadrans, nie zostawia gdzie go narysować. Blokada załatwia drugą połowę: zablokowanego nie da się założyć, zjeść, wyrzucić ani odłożyć na półkę — więc karabinek w rozbiórce nie strzela.

if dismantle_stopped
    then item.salvage_seconds := elapsed         // §18.6. Przerwane rozkładanie **nie oddaje przedmiotu w całości**. Zostaje praca, nie rzecz. Wrócenie do niej później to nie zaczynanie od nowa.

if item.salvage_seconds > 0
    then item unusable                           // ⚠️ Rozpoczęte = zepsute. Pół karabinka to nie karabinek, pół kurtki nie chroni przed deszczem. To jest to, co robi z przerwania decyzję, a nie darmowe zajrzenie do środka. Blokada w wierszu, w karcie przedmiotu i w samych _use/_wear — trzy piętra, bo stary zapis albo zwietrzały uchwyt obchodzi dwa pierwsze.

if item.salvage_seconds > 0
    then only remaining action is finishing it   // Jedyne, co z tym zostało do zrobienia.

if dismantle_resumed
    then job.started_at := now − salvage_seconds // Pasek podejmuje tam, gdzie skończył. Całość nadal zajmuje dokładnie tyle minut, ile §18.6 kazało — trzy posiedzenia po dwie minuty to sześć minut, nie trzy razy dwanaście.

if salvage_yield is empty
    then dismantle glyph hidden                  // ⚠️ To, co **wypada**, nie to, z czego rzecz jest. Siekiera to 0,86 jednostki metalu i drewna — przy 40% zero. Zapalanie ikony na wszystkim, co ma zawartość materiałową, zapalało ją na siekierach, nożach i magazynkach i odmawiało przy każdym tapnięciu.

if item dropped or shelved
    then rounds and salvage_seconds travel       // §5.3, §18.6. `_drop` gubiło `rounds` — ten sam wyciek trzydziestu naboi, tylko trzecią drogą: przez ziemię.

if dismantle_target is worn
    then dismantle := refused                    // Rozbiera się z plecaka, nigdy z ciała. Broń w rękach to dokładnie ten przypadek, który blokada ma zamknąć.

if dismantle_running
    then progress bar drawn under that row       // Pod wierszem, który gracz kliknął, nie na ekranie wytwarzania. Tam patrzy.

if two identical items and one on bench
    then bar under that piece only               // §4.7. Ta sztuka, nie to id. Dwa karabinki w plecaku to dwa karabinki — ten sam błąd, który raz już narysował pasek pod nadgryzioną i pełną puszką naraz.

if player at main shelter site
    then shelf glyph shown in pack               // §18.2. Jedno tapnięcie zamiast wejścia w półki — ekran półek służy do *wyjmowania*, a odłożenie czterech rzeczy przez niego to cztery kursy.

if player away from shelter
    then shelf glyph absent                      // Nieobecny, nie wyszarzony. Półki albo są w zasięgu ręki, albo są zupełnie gdzie indziej.

if craft_job_running and player_leaves_shelter
    then job continues                           // §2.1a.3. Zegar ścienny, nie pasek. 45-minutowy plecak to coś, po co się wraca — i dlatego jest wiersz w bazie, a nie pole w pamięci.

if craft_job_done and app_reopened
    then output added to pack, overflow to shelves
                                                 // §18.1a. Przepełnienie to stan, nie powód do zniszczenia rzeczy. Plecak, który znika, bo torba była pełna, to najgorsze możliwe czytanie limitu udźwigu.

if craft_job_cancelled
    then materials lost                          // §18 nie ma reguły zwracającej cokolwiek z porzuconej roboty. Wymyślenie jej zrobiłoby ze startu zadania rzecz darmową. Napisane przy przycisku, nie po kliknięciu.

if craft_jobs_running >= 1
    then new_job := refused                      // Jedna para rąk. §18 nigdzie nie prosi o kolejkę, a kolejka potrzebowałaby porządku, którego nikt nie określił.

if not carrying multitool
    then dismantle := refused                    // §18.6 mówi "narzędzie odpowiednie do materiału". Multitool obejmuje każdy; jedno wymaganie to jedna reguła do zapamiętania.
```

---

## Czego tu nie ma

| Mechanika | Powód |
| :---- | :---- |
| Ogniska (§6.5) | etap 6, niezbudowane — dziś świat ma wyłącznie strużkę ambientową |
| Umiejętności (§7) | niezbudowane — każdy strzela jak nowicjusz na 25 MOA |
| Crafting i ulepszanie (§18.2) | do analizy |
| Pancerz per lokalizacja | trafienia mają lokalizacje, pancerz liczy jeden próg torsa |
| Budynki jako przeszkody | warstwa w paczkach nie niesie typu (`omt_schema.dart`) |
| Dźwięk i haptyka (etap 7) | ~55 plików, licencje |
| Pogoda i sezonowość | P4, wymaga craftingu |
