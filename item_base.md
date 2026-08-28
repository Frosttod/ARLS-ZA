# Baza przedmiotów

> ⚠️ **Plik generowany.** `dart run tool/item_base.dart` — nie edytuj ręcznie, bo następne uruchomienie to nadpisze. Zmiany wprowadza się w `assets/data/*.json`.

Liczby pochodzą z tego samego kodu, którego używa gra: §18.6 pyta `salvageOf`, czas rozbiórki `salvageTime`, a zawartość materiałową `materialContent`. Jeśli arytmetyka się zmieni, ten plik zmieni się razem z nią przy następnym uruchomieniu.

## Jak czytać

| Pole | Znaczenie |
| :--- | :--- |
| **Masa / objętość** | §18.1a — dwa limity, które gracz nosi |
| **Zawartość** | z czego rzecz jest zrobiona, w jednostkach materiału (§18.4) |
| **Rozbiórka** | co faktycznie wraca przy 100% stanu, po §18.6 — jeden budżet na przedmiot, zaokrąglony raz |
| **Rozbiórka (warsztat)** | to samo przy warsztacie L2 i pełnej inżynierii — górna granica |
| **Czas rozbiórki** | §18.6: od trzech do piętnastu minut, wedle tego, ile jest do odkręcenia |
| **Wytwarzanie** | §18.4 — koszt, czas, narzędzia, poziom warsztatu |

⚠️ **Rozbiórka nigdy nie zwraca tyle, ile kosztowało wytworzenie.** §18.6 mówi wprost, że odzysk nie ma się opłacać *dla materiałów* — opłaca się, żeby pozbyć się czegoś, czego się nie użyje. Jeśli gdzieś zwrot równa się kosztowi, to jest błąd danych, nie cecha.

## Skorowidz

147 przedmiotów, od najcięższego.

| Przedmiot | Rodzaj | Masa | Objętość | Rozbiórka | Czas |
| :--- | :--- | ---: | ---: | :--- | ---: |
| Kamizelka z płytami `armor_vest_plate` | Pancerz i odzież | 8.50 | 9.00 | metal ×2, tkanina ×3 | 15 min |
| Karabin powtarzalny 7,62x54R `weapon_rifle_mosin` | Broń palna | 4.00 | 4.80 | metal ×1 | 7.0 min |
| Kanister paliwa `mat_fuel` | Materiały | 3.80 | 5.00 | — | — |
| Karabinek 7,62 mm `weapon_rifle_762x39` | Broń palna | 3.60 | 4.40 | metal ×1 | 6.7 min |
| Karabinek 5,45 mm `weapon_rifle_545` | Broń palna | 3.30 | 4.20 | metal ×1 | 6.3 min |
| Strzelba pompowa `weapon_shotgun_pump` | Broń palna | 3.20 | 4.00 | metal ×1 | 6.3 min |
| Pistolet maszynowy 9 mm `weapon_smg_9mm` | Broń palna | 2.90 | 3.00 | metal ×1 | 5.9 min |
| Kamizelka kuloodporna `armor_vest_soft` | Pancerz i odzież | 2.60 | 6.00 | tkanina ×3 | 13 min |
| Plecak wojskowy `pack_military` | Plecaki | 2.60 | 4.50 | tkanina ×3 | 12 min |
| Karabinek .22 LR `weapon_rifle_22lr` | Broń palna | 2.50 | 3.40 | metal ×1 | 5.5 min |
| Drewno `mat_wood` | Materiały | 2.00 | 4.00 | — | — |
| Nożyce do kłódek `tool_bolt_cutters` | Narzędzia | 1.90 | 2.40 | metal ×1 | 5.3 min |
| Łopata `melee_shovel` | Broń biała | 1.90 | 3.50 | nic | 4.4 min |
| Plecak trekkingowy `pack_trekking` | Plecaki | 1.80 | 3.50 | tkanina ×2 | 9.3 min |
| Zestaw kluczy `tool_wrench_set` | Narzędzia | 1.80 | 2.40 | metal ×1 | 5.2 min |
| Maczuga z okuciem `melee_club_studded` | Broń biała | 1.70 | 2.80 | metal ×1 | 6.6 min |
| Łom `melee_crowbar` | Broń biała | 1.60 | 1.80 | metal ×2 | 7.8 min |
| Buty wojskowe `cloth_boots_military` | Pancerz i odzież | 1.60 | 3.20 | leather ×1, metal ×1 | 10 min |
| Plecak polowy `pack_field` | Plecaki | 1.60 | 2.40 | tkanina ×3, plastik ×1, glue ×1, wire ×1 | 15 min |
| Encyklopedia medyczna `lit_encyclopedia_medicine` | Literatura | 1.57 | 1.83 | — | — |
| Encyklopedia broni `lit_encyclopedia_weapons` | Literatura | 1.57 | 1.83 | — | — |
| Encyklopedia przyrody `lit_encyclopedia_nature` | Literatura | 1.57 | 1.83 | — | — |
| Encyklopedia techniki `lit_encyclopedia_engineering` | Literatura | 1.57 | 1.83 | — | — |
| Woda 1,5 l `drink_water_bottle_1500` | Żywność i napoje | 1.55 | 1.60 | — | — |
| Hełm balistyczny `armor_helmet_ballistic` | Pancerz i odzież | 1.40 | 4.50 | tkanina ×1, plastik ×1 | 7.8 min |
| Siekiera `melee_axe` | Broń biała | 1.40 | 2.20 | nic | 4.0 min |
| Plecak taktyczny `pack_tactical` | Plecaki | 1.40 | 3.00 | tkanina ×2 | 7.9 min |
| Włócznia `melee_spear` | Broń biała | 1.30 | 3.20 | tkanina ×1 | 6.6 min |
| Bojówki z ochraniaczami `cloth_cargo_pads` | Pancerz i odzież | 1.20 | 3.00 | tkanina ×2, plastik ×1 | 11 min |
| Kurtka zimowa `cloth_winter_jacket` | Pancerz i odzież | 1.20 | 6.00 | tkanina ×1 | 7.0 min |
| Buty trekkingowe `cloth_boots` | Pancerz i odzież | 1.10 | 3.50 | leather ×1 | 5.8 min |
| Woda niepewnego pochodzenia `drink_water_dirty` | Żywność i napoje | 1.05 | 1.10 | — | — |
| Piła `tool_saw` | Narzędzia | 1.00 | 2.00 | nic | 4.2 min |
| Kij bejsbolowy `melee_bat` | Broń biała | 0.90 | 2.60 | nic | 3.5 min |
| Wzmocnione spodnie `cloth_trousers_reinforced` | Pancerz i odzież | 0.90 | 2.40 | tkanina ×1, leather ×1 | 10 min |
| Plecak turystyczny `pack_daypack` | Plecaki | 0.90 | 2.50 | tkanina ×2, plastik ×1 | 13 min |
| Lina `mat_rope` | Materiały | 0.90 | 2.00 | — | — |
| Rewolwer .38 `weapon_revolver_38` | Broń palna | 0.90 | 0.90 | nic | 3.9 min |
| Zaostrzony kij `melee_spike` | Broń biała | 0.80 | 2.40 | nic | 4.2 min |
| Komponent elektroniczny `mat_component` | Materiały | 0.80 | 0.40 | — | — |
| Spodnie zimowe `cloth_winter_trousers` | Pancerz i odzież | 0.80 | 3.20 | tkanina ×1 | 5.7 min |
| Złom metalowy `mat_metal` | Materiały | 0.75 | 0.30 | — | — |
| Młotek `melee_hammer` | Broń biała | 0.70 | 0.90 | nic | 3.5 min |
| Skórzane naramienniki `armor_leather_pauldrons` | Pancerz i odzież | 0.70 | 1.60 | tkanina ×1, leather ×1 | 7.8 min |
| Trampki `cloth_sneakers` | Pancerz i odzież | 0.70 | 2.20 | tkanina ×1, leather ×1 | 7.8 min |
| Prowizoryczny plecak `pack_improvised` | Plecaki | 0.70 | 3.00 | tkanina ×2 | 9.0 min |
| Lornetka `tool_binoculars` | Narzędzia | 0.70 | 1.20 | nic | 4.3 min |
| Pistolet 9 mm `weapon_pistol_9mm` | Broń palna | 0.70 | 0.80 | nic | 3.7 min |
| Magazynek bębnowy 5,45x39 (60) `mag_rifle_545_drum` | Pozostałe | 0.65 | 0.80 | nic | 3.9 min |
| Ochraniacze na przedramiona `armor_bite_sleeves` | Pancerz i odzież | 0.60 | 2.00 | tkanina ×1 | 4.7 min |
| Skóra `mat_leather` | Materiały | 0.60 | 1.20 | — | — |
| Plecak szkolny `pack_school` | Plecaki | 0.60 | 2.00 | tkanina ×1 | 5.1 min |
| Apteczka `med_first_aid_kit` | Medykamenty | 0.60 | 1.60 | — | — |
| Maczeta `melee_machete` | Broń biała | 0.60 | 1.20 | metal ×1 | 6.6 min |
| Kroplówka z solą fizjologiczną `med_saline` | Medykamenty | 0.55 | 0.60 | — | — |
| Spirytus `mat_alcohol` | Materiały | 0.55 | 0.60 | — | — |
| Woda 0,5 l `drink_water_bottle_500` | Żywność i napoje | 0.52 | 0.55 | — | — |
| Radio na korbkę `tool_crank_radio` | Narzędzia | 0.50 | 1.00 | nic | 4.1 min |
| Spodnie `cloth_trousers` | Pancerz i odzież | 0.50 | 2.00 | tkanina ×1 | 4.7 min |
| Gwoździe `mat_nails` | Materiały | 0.50 | 0.30 | — | — |
| Podręcznik balistyki `lit_textbook_ballistics` | Literatura | 0.49 | 0.52 | — | — |
| Podręcznik medycyny ratunkowej `lit_textbook_medicine` | Literatura | 0.49 | 0.52 | — | — |
| Podręcznik techniczny `lit_textbook_engineering` | Literatura | 0.49 | 0.52 | — | — |
| Podręcznik terenoznawstwa `lit_textbook_fieldcraft` | Literatura | 0.49 | 0.52 | — | — |
| Polar `cloth_fleece` | Pancerz i odzież | 0.45 | 2.50 | tkanina ×1 | 4.5 min |
| Konserwa mięsna `food_canned_meat` | Żywność i napoje | 0.40 | 0.40 | — | — |
| Konserwa warzywna `food_canned_vegetables` | Żywność i napoje | 0.40 | 0.40 | — | — |
| Plastik `mat_plastic` | Materiały | 0.40 | 0.80 | — | — |
| Kurtka przeciwdeszczowa `cloth_rain_shell` | Pancerz i odzież | 0.40 | 1.60 | nic | 4.3 min |
| Drut `mat_wire` | Materiały | 0.40 | 0.40 | — | — |
| Szyna improwizowana `med_splint_improvised` | Medykamenty | 0.40 | 1.00 | tkanina ×1 | 5.4 min |
| Tłumik `tool_suppressor` | Dodatki do broni | 0.40 | 0.50 | nic | 3.6 min |
| Szyna usztywniająca `med_splint` | Medykamenty | 0.35 | 1.20 | — | — |
| Bielizna termoaktywna `cloth_thermal_underwear` | Pancerz i odzież | 0.35 | 1.40 | nic | 4.2 min |
| Plecak biegowy `pack_running` | Plecaki | 0.35 | 0.60 | tkanina ×1 | 6.6 min |
| Zestaw do czyszczenia broni `tool_gun_cleaning_kit` | Narzędzia | 0.35 | 0.60 | nic | 3.4 min |
| Magazynek karabinkowy 7,62x39 (30) `mag_rifle_762x39` | Pozostałe | 0.33 | 0.40 | nic | 3.5 min |
| Materiał `mat_fabric` | Materiały | 0.30 | 1.00 | — | — |
| Filtr do wody `tool_water_filter` | Narzędzia | 0.30 | 0.60 | nic | 3.7 min |
| Torba na zakupy `pack_shopping_bag` | Plecaki | 0.30 | 0.50 | nic | 4.0 min |
| Napój energetyczny `drink_energy` | Żywność i napoje | 0.28 | 0.30 | — | — |
| Multitool `tool_multitool` | Narzędzia | 0.25 | 0.30 | nic | 3.3 min |
| Taśma klejąca `mat_duct_tape` | Materiały | 0.25 | 0.50 | — | — |
| Magazynek karabinkowy 5,45x39 (30) `mag_rifle_545` | Pozostałe | 0.23 | 0.35 | nic | 3.3 min |
| Magazynek do PM 9x19 (30) `mag_smg_9mm` | Pozostałe | 0.22 | 0.30 | nic | 3.3 min |
| Poradnik rusznikarski `lit_guide_gunsmithing` | Literatura | 0.21 | 0.25 | — | — |
| Poradnik przetrwania `lit_guide_survival` | Literatura | 0.21 | 0.25 | — | — |
| Poradnik pierwszej pomocy `lit_guide_first_aid` | Literatura | 0.21 | 0.25 | — | — |
| Poradnik napraw domowych `lit_guide_repairs` | Literatura | 0.21 | 0.25 | — | — |
| Latarka `tool_flashlight` | Narzędzia | 0.20 | 0.35 | nic | 3.5 min |
| Krakersy `food_crackers` | Żywność i napoje | 0.20 | 0.90 | — | — |
| Rękawice z ćwiekami `cloth_gloves_studded` | Pancerz i odzież | 0.20 | 0.50 | tkanina ×1, leather ×1 | 7.8 min |
| Skórzana czapka `cloth_leather_cap` | Pancerz i odzież | 0.20 | 0.60 | leather ×2 | 7.8 min |
| Latarka taktyczna `att_weapon_light` | Dodatki do broni | 0.20 | 0.25 | nic | 3.3 min |
| Magazynek przedłużony 9x19 (25) `mag_pistol_9mm_ext` | Pozostałe | 0.18 | 0.22 | nic | 3.2 min |
| Jabłko `food_apple` | Żywność i napoje | 0.18 | 0.25 | — | — |
| Rękawice taktyczne `cloth_gloves_tactical` | Pancerz i odzież | 0.18 | 0.50 | leather ×1, wire ×1 | 9.0 min |
| Chwyt przedni `att_foregrip` | Dodatki do broni | 0.18 | 0.25 | nic | 3.1 min |
| Klej `mat_glue` | Materiały | 0.15 | 0.20 | — | — |
| Zestaw do szycia ran `med_suture_kit` | Medykamenty | 0.15 | 0.30 | — | — |
| Nóż `melee_knife` | Broń biała | 0.15 | 0.30 | nic | 3.1 min |
| Koszulka `cloth_tshirt` | Pancerz i odzież | 0.15 | 0.80 | tkanina ×1 | 5.4 min |
| Kanapka `food_sandwich` | Żywność i napoje | 0.15 | 0.40 | — | — |
| Kolimator `att_red_dot` | Dodatki do broni | 0.15 | 0.20 | nic | 3.1 min |
| Staza improwizowana `med_tourniquet_improvised` | Medykamenty | 0.14 | 0.25 | tkanina ×1 | 5.4 min |
| Magazynek pistoletowy 9x19 (15) `mag_pistol_9mm` | Pozostałe | 0.12 | 0.15 | nic | 3.1 min |
| Czołówka `tool_headlamp` | Narzędzia | 0.12 | 0.25 | nic | 3.3 min |
| Śrubokręt `melee_screwdriver` | Broń biała | 0.12 | 0.20 | nic | 3.1 min |
| Czasopismo o broni `lit_magazine_guns` | Literatura | 0.12 | 0.13 | — | — |
| Czasopismo majsterkowicza `lit_magazine_diy` | Literatura | 0.12 | 0.13 | — | — |
| Kapelusz `cloth_sun_hat` | Pancerz i odzież | 0.12 | 0.90 | tkanina ×1, plastik ×1 | 9.0 min |
| Staza taktyczna `med_tourniquet` | Medykamenty | 0.12 | 0.20 | — | — |
| Czasopismo łowieckie `lit_magazine_hunting` | Literatura | 0.12 | 0.13 | — | — |
| Opatrunek uciskowy improwizowany `med_pressure_improvised` | Medykamenty | 0.10 | 0.20 | tkanina ×1 | 5.4 min |
| Suszone mięso `food_dried_meat` | Żywność i napoje | 0.10 | 0.20 | — | — |
| Środek odkażający `med_antiseptic` | Medykamenty | 0.10 | 0.20 | — | — |
| Wytrychy `tool_lockpicks` | Narzędzia | 0.10 | 0.15 | metal ×1 | 5.4 min |
| Zestaw do szycia `tool_sewing_kit` | Narzędzia | 0.10 | 0.20 | — | — |
| Celownik laserowy `att_laser` | Dodatki do broni | 0.10 | 0.15 | nic | 3.1 min |
| Rękawice `cloth_gloves` | Pancerz i odzież | 0.10 | 0.50 | nic | 3.3 min |
| Czekolada `food_chocolate` | Żywność i napoje | 0.10 | 0.12 | — | — |
| Magazynek karabinkowy .22 LR (10) `mag_rifle_22lr` | Pozostałe | 0.10 | 0.12 | nic | 3.1 min |
| Slipy `cloth_briefs` | Pancerz i odzież | 0.10 | 0.40 | nic | 4.2 min |
| Otwieracz do konserw `tool_can_opener` | Narzędzia | 0.08 | 0.10 | — | — |
| Opatrunek uciskowy `med_pressure_dressing` | Medykamenty | 0.08 | 0.25 | — | — |
| Czapka z daszkiem `cloth_cap` | Pancerz i odzież | 0.08 | 0.40 | tkanina ×1 | 6.6 min |
| Czapka `cloth_hat` | Pancerz i odzież | 0.08 | 0.60 | nic | 3.3 min |
| Zupa błyskawiczna `food_instant_soup` | Żywność i napoje | 0.07 | 0.35 | — | — |
| Baton energetyczny `food_energy_bar` | Żywność i napoje | 0.06 | 0.08 | — | — |
| Opatrunek improwizowany `med_bandage_improvised` | Medykamenty | 0.05 | 0.12 | nic | 4.2 min |
| Bateria `mat_battery` | Materiały | 0.05 | 0.03 | — | — |
| Amunicja Brenneke 12 ga `ammo_12ga_slug` | Amunicja | 0.05 | 0.02 | — | — |
| Amunicja śrutowa 12 ga `ammo_12ga_buck` | Amunicja | 0.04 | 0.02 | — | — |
| Bandaż `med_bandage` | Medykamenty | 0.03 | 0.10 | — | — |
| Antybiotyk `med_antibiotics` | Medykamenty | 0.03 | 0.06 | — | — |
| Nabój 7,62x54R `ammo_762x54r` | Amunicja | 0.02 | 0.01 | — | — |
| Zapałki `tool_matches` | Narzędzia | 0.02 | 0.04 | — | — |
| Zapalniczka `tool_lighter` | Narzędzia | 0.02 | 0.03 | — | — |
| Leki przeciwbólowe `med_painkillers` | Medykamenty | 0.02 | 0.05 | — | — |
| Nabój 7,62x39 mm `ammo_762x39` | Amunicja | 0.02 | 0.01 | — | — |
| Nabój 9x19 mm `ammo_9x19` | Amunicja | 0.01 | 0.01 | — | — |
| Nabój .38 Special `ammo_38special` | Amunicja | 0.01 | 0.01 | — | — |
| Nabój 5,45x39 mm `ammo_545x39` | Amunicja | 0.01 | 0.01 | — | — |
| Ulotka: pierwsza pomoc `lit_leaflet_first_aid` | Literatura | 0.00 | 0.00 | — | — |
| Nabój .22 LR `ammo_22lr` | Amunicja | 0.00 | 0.00 | — | — |
| Ulotka: bezpieczeństwo na strzelnicy `lit_leaflet_range_safety` | Literatura | 0.00 | 0.00 | — | — |
| Notatka `lit_note` | Literatura | 0.00 | 0.00 | — | — |


## Broń palna

### Pistolet 9 mm

`weapon_pistol_9mm` · 9 mm pistol · rzadszy

**Masa** 0.70 kg · **Objętość** 0.80 l · **Stan** 100% · **Zużycie** 0.02%/użycie

Znajdowany: police, military, residential

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 9x19 |
| Energia wylotowa (J) | 500 |
| Rozrzut broni (MOA) | 5.0 |
| Odrzut (MOA) | 1.2 |
| Magazynek | 15 |
| Zasilanie | magazine |
| Tryby ognia | single |
| Przeładowanie (s) | 3.0 |
| Zasięg skuteczny (m) | 40 |
| Hałas (m) | 600 |
| Gniazda dodatków | 2 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.37, Komponent elektroniczny 0.13, Plastik 0.09

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.7 min

### Rewolwer .38

`weapon_revolver_38` · .38 revolver · rzadszy

**Masa** 0.90 kg · **Objętość** 0.90 l · **Stan** 100% · **Zużycie** 0.02%/użycie

Znajdowany: police, residential

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 38special |
| Energia wylotowa (J) | 420 |
| Rozrzut broni (MOA) | 6.0 |
| Odrzut (MOA) | 1.6 |
| Magazynek | 6 |
| Zasilanie | loose |
| Tryby ognia | single |
| Przeładowanie (s) | 15.0 |
| Uwaga o przeładowaniu | loose rounds, 2.5 s each (§4.2) |
| Zasięg skuteczny (m) | 35 |
| Hałas (m) | 600 |
| Gniazda dodatków | 1 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.48, Komponent elektroniczny 0.17, Plastik 0.11

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.9 min

### Karabinek .22 LR

`weapon_rifle_22lr` · .22 LR rifle · pospolity

**Masa** 2.50 kg · **Objętość** 3.40 l · **Stan** 100% · **Zużycie** 0.02%/użycie

Znajdowany: hunting, rural, residential

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 22lr |
| Energia wylotowa (J) | 160 |
| Rozrzut broni (MOA) | 3.0 |
| Odrzut (MOA) | 0.4 |
| Magazynek | 10 |
| Zasilanie | magazine |
| Tryby ognia | single |
| Przeładowanie (s) | 3.5 |
| Zasięg skuteczny (m) | 90 |
| Hałas (m) | 250 |
| Gniazda dodatków | 2 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 1.33, Komponent elektroniczny 0.47, Plastik 0.31

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1 · 5.5 min

### Karabinek 5,45 mm

`weapon_rifle_545` · 5.45 mm carbine · rzadki

**Masa** 3.30 kg · **Objętość** 4.20 l · **Stan** 100% · **Zużycie** 0.03%/użycie

Znajdowany: military

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 5.45x39 |
| Energia wylotowa (J) | 1350 |
| Rozrzut broni (MOA) | 2.5 |
| Odrzut (MOA) | 1.8 |
| Magazynek | 30 |
| Zasilanie | magazine |
| Tryby ognia | single, auto |
| Przeładowanie (s) | 3.5 |
| Zasięg skuteczny (m) | 300 |
| Hałas (m) | 700 |
| Gniazda dodatków | 3 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 1.76, Komponent elektroniczny 0.62, Plastik 0.41

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1, Komponent elektroniczny ×1 · 6.3 min

### Karabinek 7,62 mm

`weapon_rifle_762x39` · 7.62 mm carbine · rzadki

**Masa** 3.60 kg · **Objętość** 4.40 l · **Stan** 100% · **Zużycie** 0.03%/użycie

Znajdowany: military, hunting

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 7.62x39 |
| Energia wylotowa (J) | 2000 |
| Rozrzut broni (MOA) | 3.0 |
| Odrzut (MOA) | 2.6 |
| Magazynek | 30 |
| Zasilanie | magazine |
| Tryby ognia | single, auto |
| Przeładowanie (s) | 3.5 |
| Zasięg skuteczny (m) | 300 |
| Hałas (m) | 720 |
| Gniazda dodatków | 3 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 1.92, Komponent elektroniczny 0.68, Plastik 0.45

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1, Komponent elektroniczny ×1 · 6.7 min

### Karabin powtarzalny 7,62x54R

`weapon_rifle_mosin` · 7.62x54R bolt-action rifle · rzadszy

**Masa** 4.00 kg · **Objętość** 4.80 l · **Stan** 100% · **Zużycie** 0.02%/użycie

Znajdowany: hunting, rural, military

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 7.62x54r |
| Energia wylotowa (J) | 3600 |
| Rozrzut broni (MOA) | 2.0 |
| Odrzut (MOA) | 3.0 |
| Magazynek | 5 |
| Zasilanie | loose |
| Tryby ognia | single |
| Przeładowanie (s) | 12.5 |
| Uwaga o przeładowaniu | loose rounds, 2.5 s each (§4.2) |
| Zasięg skuteczny (m) | 500 |
| Hałas (m) | 900 |
| Gniazda dodatków | 2 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 2.13, Komponent elektroniczny 0.75, Plastik 0.50

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1, Komponent elektroniczny ×1 · 7.0 min

### Strzelba pompowa

`weapon_shotgun_pump` · Pump shotgun · rzadszy

**Masa** 3.20 kg · **Objętość** 4.00 l · **Stan** 100% · **Zużycie** 0.03%/użycie

Znajdowany: hunting, police, rural

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 12ga |
| Energia wylotowa (J) | 2400 |
| `muzzle_energy_slug_j` | 3000 |
| Rozrzut broni (MOA) | 12.0 |
| Odrzut (MOA) | 3.5 |
| Magazynek | 5 |
| Zasilanie | loose |
| Tryby ognia | single |
| Przeładowanie (s) | 6.0 |
| Uwaga o przeładowaniu | 1.2 s per shell, pump (§4.2) |
| Zasięg skuteczny (m) | 40 |
| Hałas (m) | 800 |
| Gniazda dodatków | 2 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 1.71, Komponent elektroniczny 0.60, Plastik 0.40

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1, Komponent elektroniczny ×1 · 6.3 min

### Pistolet maszynowy 9 mm

`weapon_smg_9mm` · 9 mm submachine gun · rzadki

**Masa** 2.90 kg · **Objętość** 3.00 l · **Stan** 100% · **Zużycie** 0.03%/użycie

Znajdowany: police, military

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 9x19 |
| Energia wylotowa (J) | 560 |
| Rozrzut broni (MOA) | 6.0 |
| Odrzut (MOA) | 2.2 |
| Magazynek | 30 |
| Zasilanie | magazine |
| Tryby ognia | single, auto |
| Przeładowanie (s) | 3.5 |
| Zasięg skuteczny (m) | 100 |
| Hałas (m) | 650 |
| Gniazda dodatków | 3 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 1.55, Komponent elektroniczny 0.54, Plastik 0.36

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1, Komponent elektroniczny ×1 · 5.9 min


## Broń biała

### Siekiera

`melee_axe` · Axe · pospolity

**Masa** 1.40 kg · **Objętość** 2.20 l · **Stan** 100% · **Zużycie** 0.10%/użycie

Znajdowany: rural, garden, industrial

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 430 |
| Czas zamachu (s) | 1.9 |
| `damage_type` | cutting |
| `reach_m` | 0.8 |
| `strength_required` | 40 |
| Hałas (m) | 30 |
| `doubles_as_tool` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.65, Drewno 0.21

**Rozbiórka:** **nic** · z warsztatem: Złom metalowy ×1 · 4.0 min

### Kij bejsbolowy

`melee_bat` · Baseball bat · rzadszy

**Masa** 0.90 kg · **Objętość** 2.60 l · **Stan** 100% · **Zużycie** 0.10%/użycie

Znajdowany: residential, shop, school

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 260 |
| Czas zamachu (s) | 1.5 |
| `damage_type` | blunt |
| `reach_m` | 0.9 |
| `strength_required` | 25 |
| Hałas (m) | 28 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Drewno 0.45

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.5 min

### Maczuga z okuciem

`melee_club_studded` · Studded club · pospolity

**Masa** 1.70 kg · **Objętość** 2.80 l · **Stan** 100% · **Zużycie** 0.10%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 380 |
| Czas zamachu (s) | 1.8 |
| `damage_type` | blunt |
| `reach_m` | 0.9 |
| `strength_required` | 40 |
| Hałas (m) | 30 |
| `craft_only` | true |

**Wytwarzanie:** Drewno ×1, Złom metalowy ×2 · 35 min · daje 2 szt. · warsztat L1 · narzędzie: Młotek

**Zawartość:** Drewno 1.00, Złom metalowy 2.00

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1, Drewno ×1 · 6.6 min

### Łom

`melee_crowbar` · Crowbar · pospolity

**Masa** 1.60 kg · **Objętość** 1.80 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: industrial, garage, shop

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 330 |
| Czas zamachu (s) | 1.7 |
| `damage_type` | blunt |
| `reach_m` | 0.7 |
| `strength_required` | 35 |
| Hałas (m) | 30 |
| `doubles_as_tool` | true |

**Wytwarzanie:** Złom metalowy ×4 · 40 min · warsztat L1 · narzędzie: Młotek

**Zawartość:** Złom metalowy 4.00

**Rozbiórka:** Złom metalowy ×2 · z warsztatem: Złom metalowy ×3 · 7.8 min

### Młotek

`melee_hammer` · Hammer · pospolity

**Masa** 0.70 kg · **Objętość** 0.90 l · **Stan** 100% · **Zużycie** 0.08%/użycie

Znajdowany: residential, garage, industrial

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 240 |
| Czas zamachu (s) | 1.2 |
| `damage_type` | blunt |
| `reach_m` | 0.4 |
| `strength_required` | 20 |
| Hałas (m) | 26 |
| `doubles_as_tool` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.33, Drewno 0.10

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.5 min

### Nóż

`melee_knife` · Knife · pospolity

**Masa** 0.15 kg · **Objętość** 0.30 l · **Stan** 100% · **Zużycie** 0.15%/użycie

Znajdowany: residential, shop, military, rural

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 180 |
| Czas zamachu (s) | 0.9 |
| `damage_type` | piercing |
| `reach_m` | 0.4 |
| `strength_required` | 10 |
| Hałas (m) | 25 |
| `doubles_as_tool` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.07

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.1 min

### Maczeta

`melee_machete` · Machete · rzadszy

**Masa** 0.60 kg · **Objętość** 1.20 l · **Stan** 100% · **Zużycie** 0.12%/użycie

Znajdowany: rural, shop, garden

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 310 |
| Czas zamachu (s) | 1.3 |
| `damage_type` | cutting |
| `reach_m` | 0.7 |
| `strength_required` | 25 |
| Hałas (m) | 28 |

**Wytwarzanie:** Skóra ×1, Złom metalowy ×2 · 45 min · warsztat L2 · narzędzie: Młotek

**Zawartość:** Skóra 1.00, Złom metalowy 2.00

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1, Skóra ×1 · 6.6 min

### Śrubokręt

`melee_screwdriver` · Screwdriver · pospolity

**Masa** 0.12 kg · **Objętość** 0.20 l · **Stan** 100% · **Zużycie** 0.20%/użycie

Znajdowany: residential, garage, industrial

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 120 |
| Czas zamachu (s) | 0.9 |
| `damage_type` | piercing |
| `reach_m` | 0.3 |
| `strength_required` | 10 |
| Hałas (m) | 22 |
| `doubles_as_tool` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.06

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.1 min

### Łopata

`melee_shovel` · Shovel · pospolity

**Masa** 1.90 kg · **Objętość** 3.50 l · **Stan** 100% · **Zużycie** 0.08%/użycie

Znajdowany: rural, garden, industrial

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 300 |
| Czas zamachu (s) | 2.1 |
| `damage_type` | blunt |
| `reach_m` | 1.1 |
| `strength_required` | 40 |
| Hałas (m) | 30 |
| `doubles_as_tool` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.76, Drewno 0.38

**Rozbiórka:** **nic** · z warsztatem: Złom metalowy ×1 · 4.4 min

### Włócznia

`melee_spear` · Spear · pospolity

**Masa** 1.30 kg · **Objętość** 3.20 l · **Stan** 100% · **Zużycie** 0.15%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 290 |
| Czas zamachu (s) | 1.6 |
| `damage_type` | piercing |
| `reach_m` | 1.8 |
| `strength_required` | 30 |
| Hałas (m) | 26 |
| `craft_only` | true |

**Wytwarzanie:** Drewno ×1, Złom metalowy ×1, Materiał ×1 · 25 min · daje 2 szt. · warsztat L1 · narzędzie: Młotek / Multitool

**Zawartość:** Drewno 1.00, Złom metalowy 1.00, Materiał 1.00

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1, Złom metalowy ×1 · 6.6 min

### Zaostrzony kij

`melee_spike` · Sharpened stake · pospolity

**Masa** 0.80 kg · **Objętość** 2.40 l · **Stan** 100% · **Zużycie** 0.90%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `blood_ml_per_hit` | 150 |
| Czas zamachu (s) | 1.4 |
| `damage_type` | piercing |
| `reach_m` | 1.2 |
| `strength_required` | 15 |
| Hałas (m) | 22 |
| `craft_only` | true |

**Wytwarzanie:** Drewno ×1 · 8.0 min · daje 2 szt. · narzędzie: Nóż / Multitool

**Zawartość:** Drewno 1.00

**Rozbiórka:** **nic** · z warsztatem: Drewno ×1 · 4.2 min


## Pancerz i odzież

### Ochraniacze na przedramiona

`armor_bite_sleeves` · Forearm guards · rzadszy

**Masa** 0.60 kg · **Objętość** 2.00 l · **Stan** 100% · **Zużycie** 1.00%/użycie

Znajdowany: industrial, garden, veterinary

| Parametr | Wartość |
| :--- | ---: |
| `slot` | arms |
| Izolacja (clo) | 0.25 |
| `protection_level` | 1 |
| `coverage_pct` | 18 |
| `bite_protection` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Skóra 0.60, Materiał 0.80

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 4.7 min

### Hełm balistyczny

`armor_helmet_ballistic` · Ballistic helmet · rzadki

**Masa** 1.40 kg · **Objętość** 4.50 l · **Stan** 100% · **Zużycie** 0.50%/użycie

Znajdowany: military, police

| Parametr | Wartość |
| :--- | ---: |
| `slot` | head |
| Izolacja (clo) | 0.15 |
| `protection_level` | 2 |
| `coverage_pct` | 12 |
| `blunt_bypass_pct` | 50 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Plastik 1.93, Materiał 2.10

**Rozbiórka:** Materiał ×1, Plastik ×1 · z warsztatem: Plastik ×1, Materiał ×2 · 7.8 min

### Skórzane naramienniki

`armor_leather_pauldrons` · Leather pauldrons · pospolity

**Masa** 0.70 kg · **Objętość** 1.60 l · **Stan** 100% · **Zużycie** 0.04%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | arms |
| Izolacja (clo) | 0.3 |
| `protection_level` | 1 |
| `coverage_pct` | 15 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×2, Skóra ×2 · 40 min · warsztat L1 · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 2.00, Skóra 2.00

**Rozbiórka:** Materiał ×1, Skóra ×1 · z warsztatem: Materiał ×2, Skóra ×1 · 7.8 min

### Kamizelka z płytami

`armor_vest_plate` · Plate carrier · bardzo rzadki

**Masa** 8.50 kg · **Objętość** 9.00 l · **Stan** 100% · **Zużycie** 0.40%/użycie

Znajdowany: military

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_armor |
| Izolacja (clo) | 0.3 |
| `protection_level` | 4 |
| `coverage_pct` | 40 |
| `coverage_note` | plates cover less than soft armour, and stop far more |
| `blunt_bypass_pct` | 50 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 4.25, Materiał 7.08

**Rozbiórka:** Złom metalowy ×2, Materiał ×3 · z warsztatem: Złom metalowy ×3, Materiał ×4 · 15 min

### Kamizelka kuloodporna

`armor_vest_soft` · Soft body armour · rzadki

**Masa** 2.60 kg · **Objętość** 6.00 l · **Stan** 100% · **Zużycie** 0.50%/użycie

Znajdowany: police, military

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_armor |
| Izolacja (clo) | 0.3 |
| `protection_level` | 2 |
| `coverage_pct` | 55 |
| `blunt_bypass_pct` | 50 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 7.37, Plastik 0.97

**Rozbiórka:** Materiał ×3 · z warsztatem: Materiał ×4, Plastik ×1 · 13 min

### Buty trekkingowe

`cloth_boots` · Hiking boots · pospolity

**Masa** 1.10 kg · **Objętość** 3.50 l · **Stan** 100% · **Zużycie** 0.03%/użycie

Znajdowany: residential, shop, military

| Parametr | Wartość |
| :--- | ---: |
| `slot` | feet |
| Izolacja (clo) | 0.35 |
| `waterproof` | true |
| `protection_level` | 0 |
| `coverage_pct` | 0 |
| `injury_risk_modifier` | -0.2 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Skóra 1.28, Materiał 1.10

**Rozbiórka:** Skóra ×1 · z warsztatem: Skóra ×1, Materiał ×1 · 5.8 min

### Buty wojskowe

`cloth_boots_military` · Combat boots · pospolity

**Masa** 1.60 kg · **Objętość** 3.20 l · **Stan** 100% · **Zużycie** 0.03%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | feet |
| Izolacja (clo) | 0.45 |
| `protection_level` | 1 |
| `coverage_pct` | 8 |
| `craft_only` | true |

**Wytwarzanie:** Skóra ×4, Złom metalowy ×2 · 180 min · warsztat L2 · narzędzie: Zestaw do szycia

**Zawartość:** Skóra 4.00, Złom metalowy 2.00

**Rozbiórka:** Skóra ×1, Złom metalowy ×1 · z warsztatem: Skóra ×3, Złom metalowy ×1 · 10 min

### Slipy

`cloth_briefs` · Briefs · pospolity

**Masa** 0.10 kg · **Objętość** 0.40 l · **Stan** 100% · **Zużycie** 0.05%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_base |
| Izolacja (clo) | 0.25 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×1 · 20 min · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 1.00

**Rozbiórka:** **nic** · z warsztatem: Materiał ×1 · 4.2 min

### Czapka z daszkiem

`cloth_cap` · Baseball cap · pospolity

**Masa** 0.08 kg · **Objętość** 0.40 l · **Stan** 100% · **Zużycie** 0.05%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | head |
| Izolacja (clo) | 0.15 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×2, Plastik ×1 · 30 min · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 2.00, Plastik 1.00

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1, Plastik ×1 · 6.6 min

### Bojówki z ochraniaczami

`cloth_cargo_pads` · Padded cargo trousers · pospolity

**Masa** 1.20 kg · **Objętość** 3.00 l · **Stan** 100% · **Zużycie** 0.04%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | legs |
| Izolacja (clo) | 0.8 |
| `protection_level` | 2 |
| `coverage_pct` | 28 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×4, Klej ×1, Plastik ×2 · 110 min · warsztat L2 · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 4.00, Klej 1.00, Plastik 2.00

**Rozbiórka:** Materiał ×2, Plastik ×1 · z warsztatem: Materiał ×3, Plastik ×1, Klej ×1 · 11 min

### Polar

`cloth_fleece` · Fleece · pospolity

**Masa** 0.45 kg · **Objętość** 2.50 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, shop, sport

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_mid |
| Izolacja (clo) | 1.0 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 1.20, Złom metalowy 0.06

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 4.5 min

### Rękawice

`cloth_gloves` · Gloves · pospolity

**Masa** 0.10 kg · **Objętość** 0.50 l · **Stan** 100% · **Zużycie** 0.06%/użycie

Znajdowany: residential, shop, industrial

| Parametr | Wartość |
| :--- | ---: |
| `slot` | hands |
| Izolacja (clo) | 0.2 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 0.27

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.3 min

### Rękawice z ćwiekami

`cloth_gloves_studded` · Studded gloves · pospolity

**Masa** 0.20 kg · **Objętość** 0.50 l · **Stan** 100% · **Zużycie** 0.08%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | hands |
| Izolacja (clo) | 0.25 |
| `protection_level` | 1 |
| `coverage_pct` | 4 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×2, Skóra ×1, Złom metalowy ×1 · 45 min · warsztat L1 · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 2.00, Skóra 1.00, Złom metalowy 1.00

**Rozbiórka:** Materiał ×1, Skóra ×1 · z warsztatem: Materiał ×1, Skóra ×1, Złom metalowy ×1 · 7.8 min

### Rękawice taktyczne

`cloth_gloves_tactical` · Tactical gloves · pospolity

**Masa** 0.18 kg · **Objętość** 0.50 l · **Stan** 100% · **Zużycie** 0.06%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | hands |
| Izolacja (clo) | 0.3 |
| `protection_level` | 1 |
| `coverage_pct` | 5 |
| `craft_only` | true |

**Wytwarzanie:** Skóra ×2, Plastik ×1, Drut ×2 · 60 min · warsztat L1 · narzędzie: Zestaw do szycia

**Zawartość:** Skóra 2.00, Plastik 1.00, Drut 2.00

**Rozbiórka:** Skóra ×1, Drut ×1 · z warsztatem: Skóra ×1, Drut ×1, Plastik ×1 · 9.0 min

### Czapka

`cloth_hat` · Hat · pospolity

**Masa** 0.08 kg · **Objętość** 0.60 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, shop

| Parametr | Wartość |
| :--- | ---: |
| `slot` | head |
| Izolacja (clo) | 0.3 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 0.21

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.3 min

### Skórzana czapka

`cloth_leather_cap` · Leather cap · pospolity

**Masa** 0.20 kg · **Objętość** 0.60 l · **Stan** 100% · **Zużycie** 0.03%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | head |
| Izolacja (clo) | 0.55 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |
| `craft_only` | true |

**Wytwarzanie:** Skóra ×4 · 50 min · narzędzie: Zestaw do szycia

**Zawartość:** Skóra 4.00

**Rozbiórka:** Skóra ×2 · z warsztatem: Skóra ×3 · 7.8 min

### Kurtka przeciwdeszczowa

`cloth_rain_shell` · Rain shell · rzadszy

**Masa** 0.40 kg · **Objętość** 1.60 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, shop, sport

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_outer |
| Izolacja (clo) | 0.4 |
| `waterproof` | true |
| `windproof` | true |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 1.07, Złom metalowy 0.05

**Rozbiórka:** **nic** · z warsztatem: Materiał ×1 · 4.3 min

### Trampki

`cloth_sneakers` · Sneakers · pospolity

**Masa** 0.70 kg · **Objętość** 2.20 l · **Stan** 100% · **Zużycie** 0.09%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | feet |
| Izolacja (clo) | 0.2 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×2, Skóra ×1, Plastik ×1 · 60 min · warsztat L1 · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 2.00, Skóra 1.00, Plastik 1.00

**Rozbiórka:** Materiał ×1, Skóra ×1 · z warsztatem: Materiał ×1, Skóra ×1, Plastik ×1 · 7.8 min

### Kapelusz

`cloth_sun_hat` · Sun hat · pospolity

**Masa** 0.12 kg · **Objętość** 0.90 l · **Stan** 100% · **Zużycie** 0.05%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | head |
| Izolacja (clo) | 0.2 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×3, Plastik ×2 · 35 min · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 3.00, Plastik 2.00

**Rozbiórka:** Materiał ×1, Plastik ×1 · z warsztatem: Materiał ×2, Plastik ×1 · 9.0 min

### Bielizna termoaktywna

`cloth_thermal_underwear` · Thermal underwear · rzadszy

**Masa** 0.35 kg · **Objętość** 1.40 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, shop, sport

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_base |
| Izolacja (clo) | 0.8 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 0.93, Złom metalowy 0.05

**Rozbiórka:** **nic** · z warsztatem: Materiał ×1 · 4.2 min

### Spodnie

`cloth_trousers` · Trousers · pospolity

**Masa** 0.50 kg · **Objętość** 2.00 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, shop

| Parametr | Wartość |
| :--- | ---: |
| `slot` | legs |
| Izolacja (clo) | 0.5 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 1.33, Złom metalowy 0.07

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 4.7 min

### Wzmocnione spodnie

`cloth_trousers_reinforced` · Reinforced trousers · pospolity

**Masa** 0.90 kg · **Objętość** 2.40 l · **Stan** 100% · **Zużycie** 0.04%/użycie

| Parametr | Wartość |
| :--- | ---: |
| `slot` | legs |
| Izolacja (clo) | 0.7 |
| `protection_level` | 1 |
| `coverage_pct` | 20 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×3, Skóra ×2, Plastik ×1 · 75 min · warsztat L1 · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 3.00, Skóra 2.00, Plastik 1.00

**Rozbiórka:** Materiał ×1, Skóra ×1 · z warsztatem: Materiał ×2, Skóra ×1, Plastik ×1 · 10 min

### Koszulka

`cloth_tshirt` · T-shirt · pospolity

**Masa** 0.15 kg · **Objętość** 0.80 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, shop

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_base |
| Izolacja (clo) | 0.1 |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** Materiał ×2 · 35 min · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 2.00

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 5.4 min

### Kurtka zimowa

`cloth_winter_jacket` · Winter jacket · pospolity

**Masa** 1.20 kg · **Objętość** 6.00 l · **Stan** 100% · **Zużycie** 0.04%/użycie

Znajdowany: residential, shop

| Parametr | Wartość |
| :--- | ---: |
| `slot` | torso_outer |
| Izolacja (clo) | 2.2 |
| `windproof` | true |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 3.20, Złom metalowy 0.16

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×2 · 7.0 min

### Spodnie zimowe

`cloth_winter_trousers` · Winter trousers · rzadszy

**Masa** 0.80 kg · **Objętość** 3.20 l · **Stan** 100% · **Zużycie** 0.04%/użycie

Znajdowany: residential, shop, sport

| Parametr | Wartość |
| :--- | ---: |
| `slot` | legs |
| Izolacja (clo) | 1.3 |
| `windproof` | true |
| `protection_level` | 0 |
| `coverage_pct` | 0 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 2.13, Złom metalowy 0.11

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 5.7 min


## Plecaki

### Plecak turystyczny

`pack_daypack` · Daypack · pospolity

**Masa** 0.90 kg · **Objętość** 2.50 l · **Stan** 100% · **Zużycie** 0.20%/użycie

Znajdowany: residential, shop, sport

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 45 |
| `comfort_carry_bonus_kg` | 8 |
| `max_carry_bonus_kg` | 8 |

**Wytwarzanie:** Materiał ×6, Plastik ×2 · 90 min · warsztat L1 · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 6.00, Plastik 2.00

**Rozbiórka:** Materiał ×2, Plastik ×1 · z warsztatem: Materiał ×4, Plastik ×1 · 13 min

### Plecak polowy

`pack_field` · Field pack · pospolity

**Masa** 1.60 kg · **Objętość** 2.40 l · **Stan** 100% · **Zużycie** 0.30%/użycie

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 60 |
| `comfort_carry_bonus_kg` | 11 |
| `max_carry_bonus_kg` | 11 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×8, Klej ×2, Plastik ×3, Drut ×2 · 150 min · warsztat L2 · narzędzie: Zestaw do szycia

**Zawartość:** Materiał 8.00, Klej 2.00, Plastik 3.00, Drut 2.00

**Rozbiórka:** Materiał ×3, Plastik ×1, Klej ×1, Drut ×1 · z warsztatem: Materiał ×5, Klej ×2, Plastik ×2, Drut ×1 · 15 min

### Prowizoryczny plecak

`pack_improvised` · Improvised pack · pospolity

**Masa** 0.70 kg · **Objętość** 3.00 l

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 30 |
| `comfort_carry_bonus_kg` | 8 |
| `max_carry_bonus_kg` | 8 |
| `craft_only` | true |
| `note` | §18.4: eight of fabric and two of metal. Not as good as a daypack and available on a night when there is no daypack. |

**Wytwarzanie:** Materiał ×4, Złom metalowy ×1 · 45 min · daje 2 szt. · warsztat L1 · narzędzie: Zestaw do szycia / Multitool

**Zawartość:** Materiał 4.00, Złom metalowy 1.00

**Rozbiórka:** Materiał ×2 · z warsztatem: Materiał ×2, Złom metalowy ×1 · 9.0 min

### Plecak wojskowy

`pack_military` · Military rucksack · bardzo rzadki

**Masa** 2.60 kg · **Objętość** 4.50 l · **Stan** 100% · **Zużycie** 0.10%/użycie

Znajdowany: military

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 90 |
| `comfort_carry_bonus_kg` | 16 |
| `max_carry_bonus_kg` | 16 |
| `hip_belt` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 7.37, Złom metalowy 0.26

**Rozbiórka:** Materiał ×3 · z warsztatem: Materiał ×5 · 12 min

### Plecak biegowy

`pack_running` · Running pack · pospolity

**Masa** 0.35 kg · **Objętość** 0.60 l · **Stan** 100% · **Zużycie** 0.30%/użycie

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 16 |
| `comfort_carry_bonus_kg` | 3 |
| `max_carry_bonus_kg` | 3 |
| `craft_only` | true |

**Wytwarzanie:** Taśma klejąca ×1, Materiał ×2 · 45 min · narzędzie: Zestaw do szycia

**Zawartość:** Taśma klejąca 1.00, Materiał 2.00

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1, Taśma klejąca ×1 · 6.6 min

### Plecak szkolny

`pack_school` · School backpack · pospolity

**Masa** 0.60 kg · **Objętość** 2.00 l · **Stan** 100% · **Zużycie** 0.30%/użycie

Znajdowany: residential, school, shop

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 22 |
| `comfort_carry_bonus_kg` | 3 |
| `max_carry_bonus_kg` | 3 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 1.70, Złom metalowy 0.06

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 5.1 min

### Torba na zakupy

`pack_shopping_bag` · Shopping bag · pospolity

**Masa** 0.30 kg · **Objętość** 0.50 l · **Stan** 100% · **Zużycie** 1.50%/użycie

Znajdowany: residential, shop

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 30 |
| `comfort_carry_bonus_kg` | 4 |
| `max_carry_bonus_kg` | 4 |
| `occupies_hands` | true |
| `note` | §18.1a's bag. Holds as much as a daypack's worth of bulk but hangs off one arm, so it is carried instead of a weapon. |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 0.85

**Rozbiórka:** **nic** · z warsztatem: Materiał ×1 · 4.0 min

### Plecak taktyczny

`pack_tactical` · Tactical backpack · rzadki

**Masa** 1.40 kg · **Objętość** 3.00 l · **Stan** 100% · **Zużycie** 0.15%/użycie

Znajdowany: military, police, sport

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 55 |
| `comfort_carry_bonus_kg` | 10 |
| `max_carry_bonus_kg` | 10 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 3.97, Złom metalowy 0.14

**Rozbiórka:** Materiał ×2 · z warsztatem: Materiał ×3 · 7.9 min

### Plecak trekkingowy

`pack_trekking` · Trekking backpack · bardzo rzadki

**Masa** 1.80 kg · **Objętość** 3.50 l · **Stan** 100% · **Zużycie** 0.12%/użycie

Znajdowany: sport, shop, residential

| Parametr | Wartość |
| :--- | ---: |
| Pojemność (l) | 65 |
| `comfort_carry_bonus_kg` | 12 |
| `max_carry_bonus_kg` | 12 |
| `hip_belt` | true |
| `note` | §10.3.4: comfort carry 24 -> 36 kg, a third fewer trips to the shelter. |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Materiał 5.10, Złom metalowy 0.18

**Rozbiórka:** Materiał ×2 · z warsztatem: Materiał ×3 · 9.3 min


## Żywność i napoje

### Napój energetyczny

`drink_energy` · Energy drink · rzadszy

**Masa** 0.28 kg · **Objętość** 0.30 l · **Stackowalny**

Znajdowany: shop, vending, residential

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 110 |
| Woda (ml) | 250 |
| Czas spożycia (s) | 25 |
| `potable` | true |
| Kofeina (mg) | 80 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Woda 1,5 l

`drink_water_bottle_1500` · Water, 1.5 l · pospolity

**Masa** 1.55 kg · **Objętość** 1.60 l · **Stackowalny**

Znajdowany: shop, residential, warehouse

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 0 |
| Woda (ml) | 1500 |
| Czas spożycia (s) | 70 |
| `potable` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Woda 0,5 l

`drink_water_bottle_500` · Water, 0.5 l · pospolity

**Masa** 0.52 kg · **Objętość** 0.55 l · **Stackowalny**

Znajdowany: shop, residential, vending, warehouse

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 0 |
| Woda (ml) | 500 |
| Czas spożycia (s) | 25 |
| `potable` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Woda niepewnego pochodzenia

`drink_water_dirty` · Untreated water · pospolity

**Masa** 1.05 kg · **Objętość** 1.10 l · **Stackowalny**

Znajdowany: any

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 0 |
| Woda (ml) | 1000 |
| Czas spożycia (s) | 50 |
| Ryzyko choroby | 0.35 |
| `note` | Drinkable in the sense that it can be swallowed. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Jabłko

`food_apple` · Apple · pospolity

**Masa** 0.18 kg · **Objętość** 0.25 l · **Stackowalny**

Znajdowany: rural, garden, residential

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 95 |
| Woda (ml) | 150 |
| Czas spożycia (s) | 60 |
| Psuje się po (h) | 96 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Konserwa mięsna

`food_canned_meat` · Canned meat · pospolity

**Masa** 0.40 kg · **Objętość** 0.40 l · **Stackowalny**

Znajdowany: residential, shop, warehouse

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 520 |
| Woda (ml) | 120 |
| Czas spożycia (s) | 90 |
| Wymaga otwieracza | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Konserwa warzywna

`food_canned_vegetables` · Canned vegetables · pospolity

**Masa** 0.40 kg · **Objętość** 0.40 l · **Stackowalny**

Znajdowany: residential, shop, warehouse

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 210 |
| Woda (ml) | 220 |
| Czas spożycia (s) | 90 |
| Wymaga otwieracza | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Czekolada

`food_chocolate` · Chocolate · rzadszy

**Masa** 0.10 kg · **Objętość** 0.12 l · **Stackowalny**

Znajdowany: shop, residential, vending

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 540 |
| Woda (ml) | 0 |
| Czas spożycia (s) | 60 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Krakersy

`food_crackers` · Crackers · pospolity

**Masa** 0.20 kg · **Objętość** 0.90 l · **Stackowalny**

Znajdowany: shop, residential, warehouse

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 780 |
| Woda (ml) | 0 |
| Czas spożycia (s) | 120 |
| `note` | Dry. Cheap calories that cost water to eat. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Suszone mięso

`food_dried_meat` · Dried meat · rzadszy

**Masa** 0.10 kg · **Objętość** 0.20 l · **Stackowalny**

Znajdowany: shop, rural, hunting

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 410 |
| Woda (ml) | 0 |
| Czas spożycia (s) | 90 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Baton energetyczny

`food_energy_bar` · Energy bar · pospolity

**Masa** 0.06 kg · **Objętość** 0.08 l · **Stackowalny**

Znajdowany: shop, residential, sport, vending

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 250 |
| Woda (ml) | 0 |
| Czas spożycia (s) | 40 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Zupa błyskawiczna

`food_instant_soup` · Instant soup · pospolity

**Masa** 0.07 kg · **Objętość** 0.35 l · **Stackowalny**

Znajdowany: shop, residential, warehouse

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 300 |
| Woda (ml) | 0 |
| Czas spożycia (s) | 120 |
| `requires_water_ml` | 400 |
| `requires_fire` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Kanapka

`food_sandwich` · Sandwich · rzadszy

**Masa** 0.15 kg · **Objętość** 0.40 l · **Stackowalny**

Znajdowany: shop, residential

| Parametr | Wartość |
| :--- | ---: |
| Kalorie | 350 |
| Woda (ml) | 40 |
| Czas spożycia (s) | 75 |
| Psuje się po (h) | 24 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)


## Medykamenty

### Antybiotyk

`med_antibiotics` · Antibiotics · rzadki

**Masa** 0.03 kg · **Objętość** 0.06 l · **Stackowalny**

Znajdowany: pharmacy, hospital, veterinary

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 20 |
| `treats_infection` | true |
| `course_hours` | 72 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Środek odkażający

`med_antiseptic` · Antiseptic · pospolity

**Masa** 0.10 kg · **Objętość** 0.20 l · **Stan** 100% · **Zużycie** 20.00%/użycie

Znajdowany: pharmacy, residential, hospital

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 30 |
| `infection_risk_reduction` | 0.6 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Bandaż

`med_bandage` · Bandage · pospolity

**Masa** 0.03 kg · **Objętość** 0.10 l · **Stackowalny**

Znajdowany: pharmacy, residential, hospital, vehicle

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 45 |
| Tamuje krwawienie do | superficial |
| `infection_risk_reduction` | 0.2 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Opatrunek improwizowany

`med_bandage_improvised` · Improvised dressing · pospolity

**Masa** 0.05 kg · **Objętość** 0.12 l · **Stackowalny**

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 60 |
| Tamuje krwawienie do | superficial |
| `infection_risk_reduction` | 0.1 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×1 · 4.0 min · daje 4 szt.

**Zawartość:** Materiał 1.00

**Rozbiórka:** **nic** · z warsztatem: Materiał ×1 · 4.2 min

### Apteczka

`med_first_aid_kit` · First aid kit · rzadszy

**Masa** 0.60 kg · **Objętość** 1.60 l · **Stan** 100% · **Zużycie** 25.00%/użycie

Znajdowany: pharmacy, hospital, vehicle, residential

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 120 |
| Tamuje krwawienie do | moderate |
| `uses` | 4 |
| `infection_risk_reduction` | 0.35 |
| `note` | Four uses in one box. Heavier per dressing than loose bandages, lighter than carrying four kinds. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Leki przeciwbólowe

`med_painkillers` · Painkillers · pospolity

**Masa** 0.02 kg · **Objętość** 0.05 l · **Stackowalny**

Znajdowany: pharmacy, residential, shop

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 20 |
| `pain_reduction` | 0.5 |
| `duration_hours` | 4 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Opatrunek uciskowy

`med_pressure_dressing` · Pressure dressing · rzadszy

**Masa** 0.08 kg · **Objętość** 0.25 l · **Stackowalny**

Znajdowany: pharmacy, hospital, military, police

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 90 |
| Tamuje krwawienie do | moderate |
| `infection_risk_reduction` | 0.3 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Opatrunek uciskowy improwizowany

`med_pressure_improvised` · Improvised pressure dressing · pospolity

**Masa** 0.10 kg · **Objętość** 0.20 l · **Stackowalny**

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 120 |
| Tamuje krwawienie do | moderate |
| `infection_risk_reduction` | 0.15 |
| `craft_only` | true |

**Wytwarzanie:** Materiał ×1, Plastik ×1 · 7.0 min · daje 4 szt.

**Zawartość:** Materiał 1.00, Plastik 1.00

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 5.4 min

### Kroplówka z solą fizjologiczną

`med_saline` · Saline drip · bardzo rzadki

**Masa** 0.55 kg · **Objętość** 0.60 l · **Stackowalny**

Znajdowany: hospital, ambulance

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 600 |
| `restores_blood_ml` | 500 |
| `requires_stationary` | true |
| `note` | The only thing that puts volume back. Ten minutes on a drip, which is why it is used in a shelter and not in a street. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Szyna usztywniająca

`med_splint` · Splint · rzadszy

**Masa** 0.35 kg · **Objętość** 1.20 l · **Stan** 100% · **Zużycie** 50.00%/użycie

Znajdowany: hospital, ambulance, sport

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 180 |
| `treats_fracture` | true |
| `requires_stationary` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Szyna improwizowana

`med_splint_improvised` · Improvised splint · pospolity

**Masa** 0.40 kg · **Objętość** 1.00 l

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 240 |
| `treats_fracture` | true |
| `requires_stationary` | true |
| `craft_only` | true |

**Wytwarzanie:** Drewno ×1, Materiał ×1 · 12 min · daje 4 szt.

**Zawartość:** Drewno 1.00, Materiał 1.00

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 5.4 min

### Zestaw do szycia ran

`med_suture_kit` · Suture kit · rzadki

**Masa** 0.15 kg · **Objętość** 0.30 l · **Stan** 100% · **Zużycie** 25.00%/użycie

Znajdowany: hospital, pharmacy, veterinary

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 960 |
| `use_seconds_range` | 720, 1200 |
| Tamuje krwawienie do | strong |
| `requires_stationary` | true |
| `infection_risk_reduction` | 0.5 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Staza taktyczna

`med_tourniquet` · Tourniquet · rzadki

**Masa** 0.12 kg · **Objętość** 0.20 l · **Stan** 100% · **Zużycie** 20.00%/użycie

Znajdowany: military, police, hospital, ambulance

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 45 |
| Tamuje krwawienie do | arterial |
| `limbs_only` | true |
| `reusable` | true |
| `note` | The only answer to 350 ml/min (§2.6). Limbs only — a torso bleed is not something a strap can reach. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Staza improwizowana

`med_tourniquet_improvised` · Improvised tourniquet · pospolity

**Masa** 0.14 kg · **Objętość** 0.25 l · **Stackowalny**

| Parametr | Wartość |
| :--- | ---: |
| Czas użycia (s) | 75 |
| Tamuje krwawienie do | arterial |
| `limbs_only` | true |
| `craft_only` | true |
| `note` | A stick and a strip of cloth. It works once, and taking it off is the part nobody rehearses. |

**Wytwarzanie:** Materiał ×1, Drewno ×1 · 5.0 min · daje 6 szt.

**Zawartość:** Materiał 1.00, Drewno 1.00

**Rozbiórka:** Materiał ×1 · z warsztatem: Materiał ×1 · 5.4 min


## Literatura

### Encyklopedia techniki

`lit_encyclopedia_engineering` · Encyclopedia of engineering · bardzo rzadki

**Masa** 1.57 kg · **Objętość** 1.83 l

Znajdowany: school, library, industrial

| Parametr | Wartość |
| :--- | ---: |
| `form` | encyclopedia |
| `skill` | engineering |
| `pages_min` | 400 |
| `pages_max` | 900 |
| `g_per_page` | 1.8 |
| `cover_g` | 400 |
| `l_per_page` | 0.0022 |
| `xp_per_page` | 31 |
| `speed_multiplier` | 0.4 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Encyklopedia medyczna

`lit_encyclopedia_medicine` · Medical encyclopedia · bardzo rzadki

**Masa** 1.57 kg · **Objętość** 1.83 l

Znajdowany: hospital, school, library

| Parametr | Wartość |
| :--- | ---: |
| `form` | encyclopedia |
| `skill` | medicine |
| `pages_min` | 400 |
| `pages_max` | 900 |
| `g_per_page` | 1.8 |
| `cover_g` | 400 |
| `l_per_page` | 0.0022 |
| `xp_per_page` | 31 |
| `speed_multiplier` | 0.4 |
| `note` | Up to 2 kg — 8% of comfort carry. Worth reading where it lies. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Encyklopedia przyrody

`lit_encyclopedia_nature` · Encyclopedia of nature · bardzo rzadki

**Masa** 1.57 kg · **Objętość** 1.83 l

Znajdowany: school, library, rural

| Parametr | Wartość |
| :--- | ---: |
| `form` | encyclopedia |
| `skill` | scouting |
| `pages_min` | 400 |
| `pages_max` | 900 |
| `g_per_page` | 1.8 |
| `cover_g` | 400 |
| `l_per_page` | 0.0022 |
| `xp_per_page` | 31 |
| `speed_multiplier` | 0.4 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Encyklopedia broni

`lit_encyclopedia_weapons` · Encyclopedia of weapons · bardzo rzadki

**Masa** 1.57 kg · **Objętość** 1.83 l

Znajdowany: military, library, hunting

| Parametr | Wartość |
| :--- | ---: |
| `form` | encyclopedia |
| `skill` | weapons |
| `pages_min` | 400 |
| `pages_max` | 900 |
| `g_per_page` | 1.8 |
| `cover_g` | 400 |
| `l_per_page` | 0.0022 |
| `xp_per_page` | 31 |
| `speed_multiplier` | 0.4 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Poradnik pierwszej pomocy

`lit_guide_first_aid` · First aid guide · rzadszy

**Masa** 0.21 kg · **Objętość** 0.25 l

Znajdowany: pharmacy, hospital, residential, school

| Parametr | Wartość |
| :--- | ---: |
| `form` | guide |
| `skill` | medicine |
| `pages_min` | 80 |
| `pages_max` | 200 |
| `g_per_page` | 1.3 |
| `cover_g` | 30 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 32 |
| `speed_multiplier` | 0.7 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Poradnik rusznikarski

`lit_guide_gunsmithing` · Gunsmithing guide · rzadszy

**Masa** 0.21 kg · **Objętość** 0.25 l

Znajdowany: hunting, police, military

| Parametr | Wartość |
| :--- | ---: |
| `form` | guide |
| `skill` | weapons |
| `pages_min` | 80 |
| `pages_max` | 200 |
| `g_per_page` | 1.3 |
| `cover_g` | 30 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 32 |
| `speed_multiplier` | 0.7 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Poradnik napraw domowych

`lit_guide_repairs` · Home repair guide · rzadszy

**Masa** 0.21 kg · **Objętość** 0.25 l

Znajdowany: garage, industrial, residential

| Parametr | Wartość |
| :--- | ---: |
| `form` | guide |
| `skill` | engineering |
| `pages_min` | 80 |
| `pages_max` | 200 |
| `g_per_page` | 1.3 |
| `cover_g` | 30 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 32 |
| `speed_multiplier` | 0.7 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Poradnik przetrwania

`lit_guide_survival` · Survival guide · rzadszy

**Masa** 0.21 kg · **Objętość** 0.25 l

Znajdowany: sport, residential, rural, shop

| Parametr | Wartość |
| :--- | ---: |
| `form` | guide |
| `skill` | scouting |
| `pages_min` | 80 |
| `pages_max` | 200 |
| `g_per_page` | 1.3 |
| `cover_g` | 30 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 32 |
| `speed_multiplier` | 0.7 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Ulotka: pierwsza pomoc

`lit_leaflet_first_aid` · Leaflet: first aid · pospolity

**Masa** 0.00 kg · **Objętość** 0.00 l

Znajdowany: pharmacy, hospital, residential

| Parametr | Wartość |
| :--- | ---: |
| `form` | leaflet |
| `skill` | medicine |
| `pages_min` | 1 |
| `pages_max` | 4 |
| `g_per_page` | 1.0 |
| `cover_g` | 0 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 80 |
| `speed_multiplier` | 1.3 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Ulotka: bezpieczeństwo na strzelnicy

`lit_leaflet_range_safety` · Leaflet: range safety · pospolity

**Masa** 0.00 kg · **Objętość** 0.00 l

Znajdowany: police, military, hunting

| Parametr | Wartość |
| :--- | ---: |
| `form` | leaflet |
| `skill` | weapons |
| `pages_min` | 1 |
| `pages_max` | 4 |
| `g_per_page` | 1.0 |
| `cover_g` | 0 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 80 |
| `speed_multiplier` | 1.3 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Czasopismo majsterkowicza

`lit_magazine_diy` · DIY magazine · pospolity

**Masa** 0.12 kg · **Objętość** 0.13 l

Znajdowany: residential, garage, shop

| Parametr | Wartość |
| :--- | ---: |
| `form` | magazine |
| `skill` | engineering |
| `pages_min` | 20 |
| `pages_max` | 60 |
| `g_per_page` | 2.5 |
| `cover_g` | 20 |
| `l_per_page` | 0.0031 |
| `xp_per_page` | 30 |
| `speed_multiplier` | 1.0 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Czasopismo o broni

`lit_magazine_guns` · Firearms magazine · pospolity

**Masa** 0.12 kg · **Objętość** 0.13 l

Znajdowany: hunting, police, shop

| Parametr | Wartość |
| :--- | ---: |
| `form` | magazine |
| `skill` | weapons |
| `pages_min` | 20 |
| `pages_max` | 60 |
| `g_per_page` | 2.5 |
| `cover_g` | 20 |
| `l_per_page` | 0.0031 |
| `xp_per_page` | 30 |
| `speed_multiplier` | 1.0 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Czasopismo łowieckie

`lit_magazine_hunting` · Hunting magazine · pospolity

**Masa** 0.12 kg · **Objętość** 0.13 l

Znajdowany: hunting, residential, rural

| Parametr | Wartość |
| :--- | ---: |
| `form` | magazine |
| `skill` | scouting |
| `pages_min` | 20 |
| `pages_max` | 60 |
| `g_per_page` | 2.5 |
| `cover_g` | 20 |
| `l_per_page` | 0.0031 |
| `xp_per_page` | 30 |
| `speed_multiplier` | 1.0 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Notatka

`lit_note` · Note · pospolity

**Masa** 0.00 kg · **Objętość** 0.00 l

Znajdowany: residential, shop, any

| Parametr | Wartość |
| :--- | ---: |
| `form` | note |
| `pages_min` | 1 |
| `pages_max` | 3 |
| `g_per_page` | 1.0 |
| `cover_g` | 0 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 0 |
| `speed_multiplier` | 1.3 |
| `note` | §19.1 world-story note. Zero XP by design: it is there to be read, not farmed. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Podręcznik balistyki

`lit_textbook_ballistics` · Ballistics textbook · rzadki

**Masa** 0.49 kg · **Objętość** 0.52 l

Znajdowany: military, hunting, school

| Parametr | Wartość |
| :--- | ---: |
| `form` | textbook |
| `skill` | weapons |
| `pages_min` | 150 |
| `pages_max` | 400 |
| `g_per_page` | 1.5 |
| `cover_g` | 80 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 33 |
| `speed_multiplier` | 0.45 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Podręcznik techniczny

`lit_textbook_engineering` · Engineering textbook · rzadki

**Masa** 0.49 kg · **Objętość** 0.52 l

Znajdowany: school, industrial, garage

| Parametr | Wartość |
| :--- | ---: |
| `form` | textbook |
| `skill` | engineering |
| `pages_min` | 150 |
| `pages_max` | 400 |
| `g_per_page` | 1.5 |
| `cover_g` | 80 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 33 |
| `speed_multiplier` | 0.45 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Podręcznik terenoznawstwa

`lit_textbook_fieldcraft` · Fieldcraft textbook · rzadki

**Masa** 0.49 kg · **Objętość** 0.52 l

Znajdowany: military, school, sport

| Parametr | Wartość |
| :--- | ---: |
| `form` | textbook |
| `skill` | scouting |
| `pages_min` | 150 |
| `pages_max` | 400 |
| `g_per_page` | 1.5 |
| `cover_g` | 80 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 33 |
| `speed_multiplier` | 0.45 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Podręcznik medycyny ratunkowej

`lit_textbook_medicine` · Emergency medicine textbook · rzadki

**Masa** 0.49 kg · **Objętość** 0.52 l

Znajdowany: hospital, school, pharmacy

| Parametr | Wartość |
| :--- | ---: |
| `form` | textbook |
| `skill` | medicine |
| `pages_min` | 150 |
| `pages_max` | 400 |
| `g_per_page` | 1.5 |
| `cover_g` | 80 |
| `l_per_page` | 0.0016 |
| `xp_per_page` | 33 |
| `speed_multiplier` | 0.45 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)


## Narzędzia

### Lornetka

`tool_binoculars` · Binoculars · rzadki

**Masa** 0.70 kg · **Objętość** 1.20 l · **Stan** 100% · **Zużycie** 0.02%/użycie

Znajdowany: hunting, military, sport

| Parametr | Wartość |
| :--- | ---: |
| `search_radius_bonus_m` | 60 |
| `spot_enemy_bonus` | 0.25 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.48, Plastik 0.52, Złom metalowy 0.07

**Rozbiórka:** **nic** · z warsztatem: Plastik ×1 · 4.3 min

### Nożyce do kłódek

`tool_bolt_cutters` · Bolt cutters · rzadszy

**Masa** 1.90 kg · **Objętość** 2.40 l · **Stan** 100% · **Zużycie** 1.00%/użycie

Znajdowany: hardware, industrial, garage, warehouse

| Parametr | Wartość |
| :--- | ---: |
| `cuts_locks` | true |
| Czas użycia (s) | 10 |
| `note` | The loud answer to a padlock, and the fast one. Lockpicks take forty-five seconds and are heard from twenty metres; these take ten and are heard from sixty. Two kilograms of single-purpose steel is the price, which is the decision. |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.76, Komponent elektroniczny 0.71, Plastik 0.47

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1 · 5.3 min

### Otwieracz do konserw

`tool_can_opener` · Can opener · pospolity

**Masa** 0.08 kg · **Objętość** 0.10 l · **Stan** 100% · **Zużycie** 0.20%/użycie

Znajdowany: residential, shop

| Parametr | Wartość |
| :--- | ---: |
| `opens_cans` | true |
| `required_for` |  |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Radio na korbkę

`tool_crank_radio` · Crank radio · rzadki

**Masa** 0.50 kg · **Objętość** 1.00 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, shop, military

| Parametr | Wartość |
| :--- | ---: |
| `needs_no_battery` | true |
| `receives_broadcasts` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.31, Plastik 0.37, Drut 0.25

**Rozbiórka:** **nic** · z warsztatem: Plastik ×1 · 4.1 min

### Latarka

`tool_flashlight` · Flashlight · pospolity

**Masa** 0.20 kg · **Objętość** 0.35 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: residential, garage, shop, vehicle

| Parametr | Wartość |
| :--- | ---: |
| `light_radius_m` | 25 |
| Bateria (h) | 6 |
| `visible_to_enemies` | true |
| `note` | Light works both ways: it is seen further than it reaches. |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.11, Plastik 0.17, Drut 0.10

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.5 min

### Zestaw do czyszczenia broni

`tool_gun_cleaning_kit` · Gun cleaning kit · rzadszy

**Masa** 0.35 kg · **Objętość** 0.60 l · **Stan** 100% · **Zużycie** 3.00%/użycie

Znajdowany: hunting, police, military

| Parametr | Wartość |
| :--- | ---: |
| `required_for` | repair_firearm |
| Czas użycia (s) | 300 |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.14, Komponent elektroniczny 0.13, Plastik 0.09

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.4 min

### Czołówka

`tool_headlamp` · Headlamp · rzadszy

**Masa** 0.12 kg · **Objętość** 0.25 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: sport, garage, industrial

| Parametr | Wartość |
| :--- | ---: |
| `light_radius_m` | 18 |
| Bateria (h) | 8 |
| `visible_to_enemies` | true |
| `hands_free` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.07, Plastik 0.10, Drut 0.06

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.3 min

### Zapalniczka

`tool_lighter` · Lighter · pospolity

**Masa** 0.02 kg · **Objętość** 0.03 l · **Stan** 100% · **Zużycie** 1.00%/użycie

Znajdowany: residential, shop, vehicle

| Parametr | Wartość |
| :--- | ---: |
| `starts_fire` | true |
| `required_for` | light_fire, cook |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Wytrychy

`tool_lockpicks` · Lockpicks · rzadki

**Masa** 0.10 kg · **Objętość** 0.15 l · **Stan** 100% · **Zużycie** 2.00%/użycie

Znajdowany: garage, police, residential

| Parametr | Wartość |
| :--- | ---: |
| `opens_locks` | true |
| Czas użycia (s) | 60 |
| `quiet` | true |
| `note` | The silent alternative to a crowbar, which opens the same door and is heard doing it. |

**Wytwarzanie:** Złom metalowy ×2 · 12 min · daje 4 szt. · narzędzie: Multitool / Młotek

**Zawartość:** Złom metalowy 2.00

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1 · 5.4 min

### Zapałki

`tool_matches` · Matches · pospolity

**Masa** 0.02 kg · **Objętość** 0.04 l · **Stan** 100% · **Zużycie** 5.00%/użycie

Znajdowany: residential, shop, rural

| Parametr | Wartość |
| :--- | ---: |
| `starts_fire` | true |
| `fails_when_wet` | true |
| `required_for` | light_fire, cook |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Multitool

`tool_multitool` · Multitool · rzadszy

**Masa** 0.25 kg · **Objętość** 0.30 l · **Stan** 100% · **Zużycie** 0.10%/użycie

Znajdowany: garage, industrial, residential, sport

| Parametr | Wartość |
| :--- | ---: |
| `craft_time_modifier` | -0.15 |
| `required_for` | repair_basic, craft_traps, salvage_metal |
| `opens_cans` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.10, Komponent elektroniczny 0.09, Plastik 0.06

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.3 min

### Piła

`tool_saw` · Saw · rzadszy

**Masa** 1.00 kg · **Objętość** 2.00 l · **Stan** 100% · **Zużycie** 0.30%/użycie

Znajdowany: garage, industrial, garden

| Parametr | Wartość |
| :--- | ---: |
| `craft_time_modifier` | -0.2 |
| `required_for` | cut_timber, build_palisade |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.40, Komponent elektroniczny 0.37, Plastik 0.25

**Rozbiórka:** **nic** · z warsztatem: Złom metalowy ×1 · 4.2 min

### Zestaw do szycia

`tool_sewing_kit` · Sewing kit · pospolity

**Masa** 0.10 kg · **Objętość** 0.20 l · **Stan** 100% · **Zużycie** 4.00%/użycie

Znajdowany: residential, shop

| Parametr | Wartość |
| :--- | ---: |
| `craft_time_modifier` | -0.1 |
| `required_for` | repair_clothing |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Filtr do wody

`tool_water_filter` · Water filter · rzadki

**Masa** 0.30 kg · **Objętość** 0.60 l · **Stan** 100% · **Zużycie** 1.50%/użycie

Znajdowany: sport, shop, military

| Parametr | Wartość |
| :--- | ---: |
| `purifies_ml_per_use` | 1000 |
| Czas użycia (s) | 120 |
| `required_for` | purify_water |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Plastik 0.45, Komponent elektroniczny 0.15

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.7 min

### Zestaw kluczy

`tool_wrench_set` · Wrench set · rzadszy

**Masa** 1.80 kg · **Objętość** 2.40 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: garage, industrial, vehicle

| Parametr | Wartość |
| :--- | ---: |
| `craft_time_modifier` | -0.25 |
| `required_for` | repair_generator, salvage_vehicle, build_workbench |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.72, Komponent elektroniczny 0.68, Plastik 0.45

**Rozbiórka:** Złom metalowy ×1 · z warsztatem: Złom metalowy ×1 · 5.2 min


## Dodatki do broni

### Chwyt przedni

`att_foregrip` · Foregrip · rzadki

**Masa** 0.18 kg · **Objętość** 0.25 l · **Stan** 100% · **Zużycie** 0.02%/użycie

Znajdowany: military, sport

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 9x19, 5.45x39, 7.62x39, 12ga |
| `moa_delta` | -0.5 |
| `settle_multiplier` | 0.8 |
| `craft_skill` | 40 |
| `mount` | grip |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.12

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.1 min

### Celownik laserowy

`att_laser` · Laser sight · bardzo rzadki

**Masa** 0.10 kg · **Objętość** 0.15 l · **Stan** 100% · **Zużycie** 0.03%/użycie

Znajdowany: military, police

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | any |
| `settle_multiplier` | 0.6 |
| Bateria (h) | 20 |
| `visible_to_enemies` | true |
| `craft_skill` | 75 |
| `mount` | rail |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.07

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.1 min

### Kolimator

`att_red_dot` · Red dot sight · bardzo rzadki

**Masa** 0.15 kg · **Objętość** 0.20 l · **Stan** 100% · **Zużycie** 0.02%/użycie

Znajdowany: military, police, hunting

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | any |
| `moa_delta` | -1.2 |
| `settle_multiplier` | 0.85 |
| `craft_skill` | 70 |
| `mount` | optic |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.10

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.1 min

### Latarka taktyczna

`att_weapon_light` · Weapon light · rzadki

**Masa** 0.20 kg · **Objętość** 0.25 l · **Stan** 100% · **Zużycie** 0.03%/użycie

Znajdowany: military, police, sport

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | any |
| `light_radius_m` | 20 |
| Bateria (h) | 5 |
| `visible_to_enemies` | true |
| `craft_skill` | 45 |
| `mount` | rail |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.14, Złom metalowy 0.05, Plastik 0.05

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.3 min

### Tłumik

`tool_suppressor` · Suppressor · bardzo rzadki

**Masa** 0.40 kg · **Objętość** 0.50 l · **Stan** 100% · **Zużycie** 0.05%/użycie

Znajdowany: military, police

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 9x19, 5.45x39, 7.62x39, 22lr |
| `noise_range_multiplier` | 0.29 |
| `moa_delta` | 0.3 |
| `craft_skill` | 85 |
| `mount` | barrel |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Komponent elektroniczny 0.28, Złom metalowy 0.09, Plastik 0.10

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.6 min


## Materiały

### Spirytus

`mat_alcohol` · Spirit alcohol · rzadszy

**Masa** 0.55 kg · **Objętość** 0.60 l · **Stackowalny**

Znajdowany: shop, residential, pharmacy

| Parametr | Wartość |
| :--- | ---: |
| `flammable` | true |
| `note` | Fuel, antiseptic, or a bad idea. Not drinking water either way. |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Bateria

`mat_battery` · Battery · pospolity

**Masa** 0.05 kg · **Objętość** 0.03 l · **Stackowalny**

Znajdowany: shop, residential, garage, vending

| Parametr | Wartość |
| :--- | ---: |
| `powers` | tool_flashlight, tool_headlamp |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Komponent elektroniczny

`mat_component` · Electronic component · rzadszy

**Masa** 0.80 kg · **Objętość** 0.40 l · **Stackowalny**

Znajdowany: industrial, garage, shop, vehicle

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Taśma klejąca

`mat_duct_tape` · Duct tape · rzadszy

**Masa** 0.25 kg · **Objętość** 0.50 l · **Stackowalny**

Znajdowany: garage, industrial, residential

| Parametr | Wartość |
| :--- | ---: |
| `repairs` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Materiał

`mat_fabric` · Fabric · pospolity

**Masa** 0.30 kg · **Objętość** 1.00 l · **Stackowalny**

Znajdowany: residential, shop, hotel

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Kanister paliwa

`mat_fuel` · Fuel canister · rzadszy

**Masa** 3.80 kg · **Objętość** 5.00 l · **Stackowalny**

Znajdowany: vehicle, garage, industrial, rural

| Parametr | Wartość |
| :--- | ---: |
| `litres` | 5 |
| `flammable` | true |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Klej

`mat_glue` · Glue · pospolity

**Masa** 0.15 kg · **Objętość** 0.20 l · **Stackowalny**

Znajdowany: garage, shop, school

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Skóra

`mat_leather` · Leather · rzadszy

**Masa** 0.60 kg · **Objętość** 1.20 l · **Stackowalny**

Znajdowany: residential, shop, rural

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Złom metalowy

`mat_metal` · Scrap metal · pospolity

**Masa** 0.75 kg · **Objętość** 0.30 l · **Stackowalny**

Znajdowany: industrial, garage, vehicle, shop

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Gwoździe

`mat_nails` · Nails · pospolity

**Masa** 0.50 kg · **Objętość** 0.30 l · **Stackowalny**

Znajdowany: garage, industrial, shop

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Plastik

`mat_plastic` · Plastic · pospolity

**Masa** 0.40 kg · **Objętość** 0.80 l · **Stackowalny**

Znajdowany: residential, shop, industrial, warehouse

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Lina

`mat_rope` · Rope · rzadszy

**Masa** 0.90 kg · **Objętość** 2.00 l · **Stackowalny**

Znajdowany: garage, sport, industrial, rural

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Drut

`mat_wire` · Wire · pospolity

**Masa** 0.40 kg · **Objętość** 0.40 l · **Stackowalny**

Znajdowany: industrial, garage, vehicle

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Drewno

`mat_wood` · Wood · pospolity

**Masa** 2.00 kg · **Objętość** 4.00 l · **Stackowalny**

Znajdowany: rural, forest, garden, industrial

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)


## Amunicja

### Amunicja śrutowa 12 ga

`ammo_12ga_buck` · 12 ga buckshot · pospolity

**Masa** 0.04 kg · **Objętość** 0.02 l · **Stackowalny**

Znajdowany: hunting, police, rural

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 12ga |
| `load` | buckshot |
| `wound_factor` | 1.25 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Amunicja Brenneke 12 ga

`ammo_12ga_slug` · 12 ga slug · rzadszy

**Masa** 0.05 kg · **Objętość** 0.02 l · **Stackowalny**

Znajdowany: hunting, rural

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 12ga |
| `load` | slug |
| `wound_factor` | 1.5 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Nabój .22 LR

`ammo_22lr` · .22 LR round · pospolity

**Masa** 0.00 kg · **Objętość** 0.00 l · **Stackowalny**

Znajdowany: hunting, rural, residential

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 22lr |
| `wound_factor` | 0.7 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Nabój .38 Special

`ammo_38special` · .38 Special round · rzadszy

**Masa** 0.01 kg · **Objętość** 0.01 l · **Stackowalny**

Znajdowany: police, residential

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 38special |
| `wound_factor` | 1.0 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Nabój 5,45x39 mm

`ammo_545x39` · 5.45x39 mm round · rzadszy

**Masa** 0.01 kg · **Objętość** 0.01 l · **Stackowalny**

Znajdowany: military

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 5.45x39 |
| `wound_factor` | 1.25 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Nabój 7,62x39 mm

`ammo_762x39` · 7.62x39 mm round · rzadszy

**Masa** 0.02 kg · **Objętość** 0.01 l · **Stackowalny**

Znajdowany: military, hunting

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 7.62x39 |
| `wound_factor` | 1.2 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Nabój 7,62x54R

`ammo_762x54r` · 7.62x54R round · rzadszy

**Masa** 0.02 kg · **Objętość** 0.01 l · **Stackowalny**

Znajdowany: hunting, military, rural

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 7.62x54r |
| `wound_factor` | 1.35 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)

### Nabój 9x19 mm

`ammo_9x19` · 9x19 mm round · pospolity

**Masa** 0.01 kg · **Objętość** 0.01 l · **Stackowalny**

Znajdowany: police, military

| Parametr | Wartość |
| :--- | ---: |
| Kaliber | 9x19 |
| `wound_factor` | 1.0 |

**Wytwarzanie:** — (tylko znajdowane)

**Rozbiórka:** — (nie da się rozebrać)


## Pozostałe

### Magazynek pistoletowy 9x19 (15)

`mag_pistol_9mm` · Pistol magazine 9x19 (15) · rzadszy

**Masa** 0.12 kg · **Objętość** 0.15 l

Znajdowany: police, military, residential

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 9x19 |
| `capacity` | 15 |
| Kaliber | 9x19 |
| `mount` | magazine |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.06, Plastik 0.07

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.1 min

### Magazynek przedłużony 9x19 (25)

`mag_pistol_9mm_ext` · Extended magazine 9x19 (25) · rzadki

**Masa** 0.18 kg · **Objętość** 0.22 l

Znajdowany: police, military

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 9x19 |
| `capacity` | 25 |
| Kaliber | 9x19 |
| `mount` | magazine |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.09, Plastik 0.11

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.2 min

### Magazynek karabinkowy .22 LR (10)

`mag_rifle_22lr` · Rifle magazine .22 LR (10) · pospolity

**Masa** 0.10 kg · **Objętość** 0.12 l

Znajdowany: hunting, rural, residential

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 22lr |
| `capacity` | 10 |
| Kaliber | 22lr |
| `mount` | magazine |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.05, Plastik 0.06

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.1 min

### Magazynek karabinkowy 5,45x39 (30)

`mag_rifle_545` · Rifle magazine 5.45x39 (30) · rzadki

**Masa** 0.23 kg · **Objętość** 0.35 l

Znajdowany: military

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 5.45x39 |
| `capacity` | 30 |
| Kaliber | 5.45x39 |
| `mount` | magazine |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.12, Plastik 0.14

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.3 min

### Magazynek bębnowy 5,45x39 (60)

`mag_rifle_545_drum` · Drum magazine 5.45x39 (60) · rzadki

**Masa** 0.65 kg · **Objętość** 0.80 l

Znajdowany: military

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 5.45x39 |
| `capacity` | 60 |
| Kaliber | 5.45x39 |
| `mount` | magazine |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.33, Plastik 0.41

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.9 min

### Magazynek karabinkowy 7,62x39 (30)

`mag_rifle_762x39` · Rifle magazine 7.62x39 (30) · rzadki

**Masa** 0.33 kg · **Objętość** 0.40 l

Znajdowany: military, hunting

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 7.62x39 |
| `capacity` | 30 |
| Kaliber | 7.62x39 |
| `mount` | magazine |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.17, Plastik 0.21

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.5 min

### Magazynek do PM 9x19 (30)

`mag_smg_9mm` · SMG magazine 9x19 (30) · rzadki

**Masa** 0.22 kg · **Objętość** 0.30 l

Znajdowany: police, military

| Parametr | Wartość |
| :--- | ---: |
| `attaches_to` | 9x19 |
| `capacity` | 30 |
| Kaliber | 9x19 |
| `mount` | magazine |

**Wytwarzanie:** — (tylko znajdowane)

**Zawartość:** Złom metalowy 0.11, Plastik 0.14

**Rozbiórka:** **nic** · z warsztatem: **nic** · 3.3 min


---

## Jednostki materiałów (§18.2)

Masy jednostkowe nie są wybrane — są rozwiązane z tabeli §18.2 i odtwarzają wszystkie trzynaście wierszy modułów co do kilograma. Zmiana jednej z nich przesuwa **każdy** koszt budowy w grze.

| Materiał | Masa jednostki | Objętość |
| :--- | ---: | ---: |
| Spirytus `mat_alcohol` | 0.55 kg | 0.60 l |
| Bateria `mat_battery` | 0.05 kg | 0.03 l |
| Komponent elektroniczny `mat_component` | 0.80 kg | 0.40 l |
| Taśma klejąca `mat_duct_tape` | 0.25 kg | 0.50 l |
| Materiał `mat_fabric` | 0.30 kg | 1.00 l |
| Kanister paliwa `mat_fuel` | 3.80 kg | 5.00 l |
| Klej `mat_glue` | 0.15 kg | 0.20 l |
| Skóra `mat_leather` | 0.60 kg | 1.20 l |
| Złom metalowy `mat_metal` | 0.75 kg | 0.30 l |
| Gwoździe `mat_nails` | 0.50 kg | 0.30 l |
| Plastik `mat_plastic` | 0.40 kg | 0.80 l |
| Lina `mat_rope` | 0.90 kg | 2.00 l |
| Drut `mat_wire` | 0.40 kg | 0.40 l |
| Drewno `mat_wood` | 2.00 kg | 4.00 l |

