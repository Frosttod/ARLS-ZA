// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ARLS-ZA';

  @override
  String get appTagline => 'Almost Real Life Survival';

  @override
  String get continueLabel => 'Continue';

  @override
  String get newCharacter => 'New character';

  @override
  String get settings => 'Settings';

  @override
  String get saveRestoredTitle => 'Save recovered';

  @override
  String saveRestoredBody(int minutes) {
    return 'The save file was damaged and has been restored from a backup. You lost $minutes minutes of play.';
  }

  @override
  String get saveLostTitle => 'Save could not be read';

  @override
  String get saveLostBody =>
      'The save file is damaged and no usable backup was found. You can import a profile you exported earlier, or start a new character.';

  @override
  String get importProfile => 'Import profile';

  @override
  String get exportProfile => 'Export profile';

  @override
  String get exportDone => 'Profile exported.';

  @override
  String get importDone => 'Profile imported.';

  @override
  String importFailed(String reason) {
    return 'Import failed: $reason';
  }

  @override
  String get awayTitle => 'While you were away';

  @override
  String awayElapsed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days passed.',
      one: 'One day passed.',
      zero: 'Less than a day passed.',
    );
    return '$_temp0';
  }

  @override
  String get awayFloored =>
      'Your body was running on reserves. Nothing dropped below the safety floor.';

  @override
  String get clockRolledBack =>
      'The device clock moved backwards. No time was counted.';

  @override
  String get bloodVolume => 'Blood volume';

  @override
  String get dailyRequirement => 'Daily requirement';

  @override
  String get carryComfort => 'Carry weight, comfortable';

  @override
  String get carryMax => 'Carry weight, maximum';

  @override
  String get maxHeartRate => 'Maximum heart rate';

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
      'These figures are calculated on your phone and never leave it.';

  @override
  String get createCharacter => 'Create your character';

  @override
  String get creatorIntro =>
      'Your height, weight, age and sex are used to compute blood volume, water and calorie needs, and carry weight.';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldSex => 'Sex';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get fieldAge => 'Age';

  @override
  String get fieldHeight => 'Height';

  @override
  String get fieldWeight => 'Weight';

  @override
  String get computedTitle => 'Your body, computed';

  @override
  String get deathModeTitle => 'Choose how death works';

  @override
  String get deathModeWarning => 'This choice cannot be changed later.';

  @override
  String get hardcoreTitle => 'Hardcore';

  @override
  String get hardcoreBody =>
      'Death ends the character. Skills, shelter and stored gear are gone; the streak goes to the Chronicle.';

  @override
  String get softcoreTitle => 'Softcore';

  @override
  String get softcoreBody =>
      'You lose consciousness instead of dying. Skills and shelter survive; the streak resets.';

  @override
  String get beginSurvival => 'Begin';

  @override
  String get errNameTooShort => 'At least 4 characters.';

  @override
  String get errNameTooLong => 'At most 16 characters.';

  @override
  String get errNameInvalid => 'Letters, digits and spaces only.';

  @override
  String get errNameEdgeSpaces => 'No leading or trailing spaces.';

  @override
  String get errNameDoubleSpaces => 'No doubled spaces.';

  @override
  String get errAgeRange => 'Between 16 and 80.';

  @override
  String get errHeightRange => 'Between 120 and 220 cm.';

  @override
  String get errWeightRange => 'Between 35 and 200 kg.';

  @override
  String get errBmiTooLow =>
      'These figures do not describe a body the model can work with. Check the height and weight.';

  @override
  String get errBmiTooHigh =>
      'These figures do not describe a body the model can work with. Check the height and weight.';

  @override
  String get hudBlood => 'Blood';

  @override
  String get hudWater => 'Water';

  @override
  String get hudCalories => 'Calories';

  @override
  String get hudSleep => 'Rest';

  @override
  String get hudHeartRate => 'Heart rate';

  @override
  String hudThreat(int count, int metres) {
    return '$count in the fight · nearest $metres m';
  }

  @override
  String get hudThreatSprint => 'can still sprint';

  @override
  String get hudCarry => 'Carry';

  @override
  String get hudBulk => 'Bulk';

  @override
  String get hudNoSignal => 'No signal';

  @override
  String get hudAcquiring => 'Acquiring GPS';

  @override
  String get hudWeakSignal => 'Weak signal';

  @override
  String statusDegree(String degree) {
    return '$degree degree';
  }

  @override
  String statusOfDaily(int percent) {
    return '$percent% of the daily need';
  }

  @override
  String statusDebtHours(int hours) {
    return '$hours h of debt';
  }

  @override
  String get statusEffect => 'Effect';

  @override
  String get statusFix => 'What to do';

  @override
  String get statusWhere => 'Where to find it';

  @override
  String get commonOk => 'OK';

  @override
  String get statusShockEffect =>
      'Wider groups on every shot, less carried before it hurts, and above class III the picture dims and running makes you dizzy.';

  @override
  String get statusShockFix =>
      'Stop the bleeding first — a bandage or a tourniquet. Blood comes back on its own afterwards, slowly, and only if you eat and drink.';

  @override
  String get statusShockWhere =>
      'Pharmacies, clinics, ambulances; first-aid kits in offices and workshops.';

  @override
  String get statusDehydratedEffect =>
      'Hands go first: aim and reaction time. Deeper down it takes decisions, then strength.';

  @override
  String get statusDehydratedFix =>
      'Drink. It works over about twenty minutes, not instantly, so drink before you need it.';

  @override
  String get statusDehydratedWhere =>
      'Shops, petrol stations, homes. Water from a tap or a stream has to be boiled or treated first.';

  @override
  String get statusStarvingEffect =>
      'Everything takes longer — searching, bandaging, building — and precision goes with it.';

  @override
  String get statusStarvingFix =>
      'Eat. Tins and dry food keep; anything cooked is worth more per kilogram carried.';

  @override
  String get statusStarvingWhere =>
      'Shops, homes, restaurants, allotments. Bodies rarely carry more than a snack.';

  @override
  String get statusSleepDeprivedEffect =>
      'Every shot spreads wider, everything takes longer to learn, and past a day awake the eyes close on their own for a few seconds at a time.';

  @override
  String get statusSleepDeprivedFix =>
      'Sleep. Only sleep pays this down — and only somewhere safe enough to lie down, which means a shelter.';

  @override
  String get statusSleepDeprivedWhere =>
      'Your own shelter. A bed or a mattress makes the hours count for more.';

  @override
  String get statusBleeding => 'Bleeding';

  @override
  String get statusDehydrated => 'Dehydrated';

  @override
  String get statusStarving => 'Starving';

  @override
  String get statusSleepDeprived => 'Sleep-deprived';

  @override
  String get bleedSuperficial => 'superficial';

  @override
  String get bleedModerate => 'moderate';

  @override
  String get bleedSevere => 'severe';

  @override
  String get bleedArterial => 'arterial';

  @override
  String statusBleedingEffect(int millilitres) {
    return '$millilitres ml a minute, and running multiplies it — at 160 bpm against a resting 70 it is more than twice that. Blood does not come back at all while something is open.';
  }

  @override
  String get statusBleedingFix =>
      'A pressure dressing, and stand still while it goes on.';

  @override
  String get statusBleedingFixArterial =>
      'A tourniquet, and nothing else. A dressing will not hold this one.';

  @override
  String get statusBleedingWhere =>
      'Pharmacies, clinics, ambulances; first-aid kits in offices and workshops.';

  @override
  String get deathTitle => 'THAT IS THE END';

  @override
  String get downTitle => 'YOU WENT DOWN';

  @override
  String get causeBloodLoss => 'Blood loss';

  @override
  String get causeThirst => 'Dehydration';

  @override
  String get causeStarvation => 'Starvation';

  @override
  String get deathWhat =>
      'Hardcore: this character is over. The streak goes into the Chronicle with everything it reached. A new one keeps your body — the same height, weight and age — and only the name changes.';

  @override
  String get downWhat =>
      'You come round where you are, an hour from now, with a quarter of your blood and almost nothing in you. Whatever was in your hands is gone; about half of what you carried is scattered where you fell. For ten minutes afterwards they will take you for dead — and you cannot fight either.';

  @override
  String downLeft(String time) {
    return '$time';
  }

  @override
  String get downClosedApp => 'The hour runs whether the app is open or not.';

  @override
  String get downLog => 'The last of it';

  @override
  String get downGrace => 'They still take you for dead. Do not give it away.';

  @override
  String get deathNewCharacter => 'New character';

  @override
  String get deathSameBody => 'The same body, a new name.';

  @override
  String get downCaches =>
      'What you were carrying is scattered where you fell.';

  @override
  String get statusShock => 'Shock';

  @override
  String get locationTitle => 'The game needs your position';

  @override
  String get locationBody =>
      'ARLS-ZA measures a real body moving through a real place. Without a position there is nothing to measure. The data never leaves your phone.';

  @override
  String get locationGrant => 'Grant access';

  @override
  String get locationSettings => 'Open settings';

  @override
  String get locationDeniedTitle => 'Location access refused';

  @override
  String get locationDeniedBody =>
      'There is no game without a position. You can change this in the system settings.';

  @override
  String get locationServiceOffTitle => 'Location is switched off';

  @override
  String get locationServiceOffBody =>
      'This is a device-wide setting, not this game\'s. Switch location on and come back.';

  @override
  String get locationForegroundOnlyTitle => 'The game runs on screen only';

  @override
  String get locationForegroundOnlyBody =>
      'Background location was not granted, so the simulation pauses when you put the app away. This is a full variant of the game — you lose nothing but walking with the screen off.';

  @override
  String get locationNotificationTitle => 'ARLS-ZA — expedition in progress';

  @override
  String get locationNotificationBody =>
      'The game is counting your movement. Tap to return.';

  @override
  String get integritySuspendedMock =>
      'Mocked location detected. Play is suspended.';

  @override
  String get integritySuspendedVehicle =>
      'You are in a vehicle. Play is suspended until you are back on your own feet.';

  @override
  String get hudLowBattery => 'Battery below 20% — head for the shelter';

  @override
  String get hudEconomy => 'Power saving';

  @override
  String get safetyNoCombatMoving => 'Do not play while travelling';

  @override
  String get safetyNightVisibility =>
      'It is dark. Be visible, and watch where you are going.';

  @override
  String get safetyBriefingTitle => 'Before you go out';

  @override
  String get safetyBriefingIntro =>
      'This game measures a real body moving through a real city. Everything below is about you, not the character.';

  @override
  String get safetyRuleTraffic =>
      'Watch the road, not the phone. The game knows nothing about cars.';

  @override
  String get safetyRuleNoDriving =>
      'Do not play while travelling. Above 15 km/h combat is blocked; above 40 km/h play is suspended.';

  @override
  String get safetyRuleNoTrespass =>
      'The game will never send you onto private land, onto a railway or into water. If a marker looks like it does — do not go.';

  @override
  String get safetyRuleRespect =>
      'Hospitals, schools, cemeteries and places of worship are excluded from spawns. Do not play there anyway.';

  @override
  String get safetyRuleNight =>
      'After dark, be visible. Light clothing, a reflective band, ears free.';

  @override
  String get safetyRuleStop =>
      'Tiredness, pain, a storm, strangers — end the session. The character will wait.';

  @override
  String get safetyBriefingAccept => 'I understand and accept this';

  @override
  String get regionTitle => 'Choose a region';

  @override
  String get regionIntro =>
      'The game runs without a network, so the map has to be on the phone. Download the pack for the area you will be walking.';

  @override
  String regionSizeMb(String mb) {
    return '$mb MB';
  }

  @override
  String get regionInstalled => 'Downloaded';

  @override
  String get regionUnavailable => 'Unavailable';

  @override
  String get regionDownload => 'Download';

  @override
  String get regionDelete => 'Delete';

  @override
  String get regionCancel => 'Cancel';

  @override
  String get regionRetry => 'Try again';

  @override
  String get regionNearYou => 'Near you';

  @override
  String regionDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get regionErrSpace => 'Not enough room. Free some up and try again.';

  @override
  String get regionErrNetwork =>
      'The download was interrupted. What arrived is kept — the next attempt finishes it.';

  @override
  String get regionErrCorrupt =>
      'The file that arrived does not match its checksum. It has been deleted.';

  @override
  String get regionErrUnpublished => 'This region has not been published yet.';

  @override
  String get regionLeftPackTitle => 'You are off the downloaded map';

  @override
  String get regionLeftPackBody =>
      'Without tiles there is nothing to draw and nowhere to place markers. Download the pack for this area, or return to the one you have.';

  @override
  String get menuProfile => 'PROFILE';

  @override
  String get profileBody => 'This body';

  @override
  String get profileBlood => 'Blood volume';

  @override
  String get profileEnergy => 'Daily energy';

  @override
  String get profileWater => 'Daily water';

  @override
  String get profileCarry => 'Carry, comfortable / hard';

  @override
  String get profileHeart => 'Heart rate, rest to max';

  @override
  String get profileAim => 'What is making you miss';

  @override
  String get profileTotalSpread => 'Together';

  @override
  String get profileAimWhat =>
      'Standing still removes the two largest rows: your own pace and your own pulse. Nothing else on this list can be fixed on the spot.';

  @override
  String get profileFighting => 'Out there';

  @override
  String get profileShots => 'Shots fired';

  @override
  String get profileAccuracy => 'Accuracy';

  @override
  String get profileSwings => 'Swings';

  @override
  String get profileKills => 'Put down';

  @override
  String get profileShotsPerKill => 'Rounds per kill';

  @override
  String get profileBloodDealt => 'Blood taken';

  @override
  String get profileBloodLost => 'Blood lost';

  @override
  String get profileSearches => 'Places searched';

  @override
  String get profileBlackouts => 'Blackouts';

  @override
  String get profileWhereTheyLand => 'Where your rounds land';

  @override
  String get profileNothingYet => 'Nothing has landed yet.';

  @override
  String get profileSkills => 'Skills';

  @override
  String get profileSkillsSoon =>
      'Not in the game yet. Until they are, everybody shoots like a novice — twenty-five minutes of angle, which is the largest row above.';

  @override
  String profileAliveDays(int days, int hours) {
    return 'Alive $days d $hours h';
  }

  @override
  String profileAliveHours(int hours) {
    return 'Alive $hours h';
  }

  @override
  String get menuInventory => 'INVENTORY';

  @override
  String get menuShelter => 'SHELTER';

  @override
  String get stashTitle => 'Shelves';

  @override
  String get stashOnTheShelves => 'On the shelves';

  @override
  String get stashInThePack => 'In the pack';

  @override
  String get stashEmpty => 'Nothing here yet.';

  @override
  String get stashPackEmpty => 'The pack is empty.';

  @override
  String get stashStore => 'Leave';

  @override
  String get stashTake => 'Take';

  @override
  String get stashFull => 'No room on the shelves.';

  @override
  String get stashNoRoomInPack => 'It will not fit in the pack.';

  @override
  String get shelterShelves => 'Shelves';

  @override
  String get shelterShelvesWhat =>
      'What is left here stays here. The house holds what it holds; Storage adds fifty kilograms a level.';

  @override
  String get shelterTitle => 'Shelter';

  @override
  String get campTitle => 'Camp';

  @override
  String get shelterCamps => 'Camps';

  @override
  String get shelterBuild => 'Build';

  @override
  String get shelterBuildHere => 'Build here';

  @override
  String get shelterCancel => 'Give up';

  @override
  String get shelterCancelTitle => 'Give up on this?';

  @override
  String get shelterCancelKeep => 'Carry on';

  @override
  String get shelterCancelConfirm => 'Give up';

  @override
  String get shelterCancelled => 'Work abandoned.';

  @override
  String get shelterCancelShelterWhat =>
      'The materials are already in the walls and they do not come back out. The place goes with them, and building here again starts from nothing. This cannot be undone.';

  @override
  String get shelterCancelCampWhat =>
      'The camp goes, and with it everything that went into it. Putting one here again starts from nothing. This cannot be undone.';

  @override
  String get shelterCancelModuleWhat =>
      'The materials for this level are gone — they are in the frame. The levels already finished stay. Starting this one again means carrying the lot back. This cannot be undone.';

  @override
  String get shelterSafeZone => 'Safe zone';

  @override
  String get shelterSleep => 'Sleep quality';

  @override
  String get shelterStorage => 'Capacity';

  @override
  String get shelterNoFix =>
      'No position — a shelter goes where you are standing.';

  @override
  String get shelterNotHere =>
      'You have to be at the shelter to build onto it.';

  @override
  String get shelterWorkStopped => 'Work stopped — nobody is on the site.';

  @override
  String get shelterNeedsTool =>
      'Needs a hammer. From Workshop 2, a multitool as well.';

  @override
  String shelterMissing(String what) {
    return 'Missing: $what';
  }

  @override
  String shelterBuildingLeft(String time) {
    return '$time left';
  }

  @override
  String get shelterNoneWhat =>
      'It goes up where you are standing, and that is where you will come back to sleep. Fifty metres of ground the dead do not walk into — and out of which you cannot shoot either.';

  @override
  String get campWhat =>
      'Somewhere else you spend your day: work, a lecture hall, a relative’s flat. Twenty metres, a chest, and a night worth seven tenths of one. Two at most, and not within 800 m of anything you have already built.';

  @override
  String get campTooMany => 'Two camps is the limit. Take one down first.';

  @override
  String get campTooCloseToShelter =>
      'Under 800 m from the shelter — that would just be a second front door.';

  @override
  String get campTooCloseToCamp => 'Under 800 m from the other camp.';

  @override
  String get campTooCloseToHotspot => 'Too close to the middle of a hotspot.';

  @override
  String get campDecaying =>
      'Nobody has been here in a fortnight. It is coming apart.';

  @override
  String get moduleStorage => 'Storage';

  @override
  String get moduleWorkshop => 'Workshop';

  @override
  String get moduleLounge => 'Lounge';

  @override
  String get moduleLaboratory => 'Laboratory';

  @override
  String get moduleStorageWhat =>
      'Fifty kilograms a level, on top of the twenty-five the shelter holds bare.';

  @override
  String get moduleWorkshopWhat =>
      'Repairs: to 60% of condition, then 85%, then as new. Level 2 also opens complex recipes.';

  @override
  String get moduleLoungeWhat =>
      'Fifteen per cent a level off what a night has to cover — an hour of the night given back.';

  @override
  String get moduleLaboratoryWhat =>
      'Three per cent a level more out of everything eaten and drunk.';

  @override
  String get shelterBuildStarted =>
      'Work started. It carries on with the app closed.';

  @override
  String get shelterInside => 'You cannot fire from inside your own zone.';

  @override
  String get menuSettings => 'SETTINGS';

  @override
  String get mapRecentre => 'Back to me';

  @override
  String get mapNoPack => 'No map for this area';

  @override
  String get mapMarkerEnemy => 'Enemy';

  @override
  String get mapMarkerLoot => 'Loot box';

  @override
  String get placePharmacy => 'Pharmacy';

  @override
  String get placeHardware => 'Hardware shop';

  @override
  String get placeGrocery => 'Grocery';

  @override
  String get placeSports => 'Sports shop';

  @override
  String get placeWeapons => 'Gun shop';

  @override
  String get placeLibrary => 'Library';

  @override
  String get placeIndustrial => 'Industrial site';

  @override
  String get placeHospital => 'Hospital';

  @override
  String get placeMilitary => 'Military site';

  @override
  String get placeSchool => 'School';

  @override
  String get placeWarehouse => 'Warehouse';

  @override
  String get placeCar => 'Abandoned car';

  @override
  String get placeHouse => 'Abandoned house';

  @override
  String get placeBarn => 'Barn';

  @override
  String get placeGarage => 'Garage';

  @override
  String get placeWaste => 'Bins';

  @override
  String get placePicnic => 'Shelter hut';

  @override
  String get placeHuntingStand => 'Hunting stand';

  @override
  String get placeWaterPoint => 'Water point';

  @override
  String get placeRoadside => 'Roadside';

  @override
  String get placeAmbulance => 'Ambulance';

  @override
  String get placePoliceCar => 'Police car';

  @override
  String get mapMarkerDropped => 'Dropped item';

  @override
  String get mapMarkerRemains => 'Body';

  @override
  String get remainsTitle => 'Body';

  @override
  String get remainsSearch => 'Search it';

  @override
  String get remainsSearched => 'Pockets turned out.';

  @override
  String get remainsEmptied => 'Already turned out.';

  @override
  String get remainsUnsearched =>
      'Nobody has been through it. Come within arm’s reach to search it.';

  @override
  String get mapMarkerShelter => 'Shelter';

  @override
  String get mapPlayerLabel => 'You';

  @override
  String get regionPlayNow => 'Play now';

  @override
  String get regionStreamed => 'Map from the network';

  @override
  String get regionStreamWarnTitle =>
      'Map from the network, not from the phone';

  @override
  String get regionStreamWarnBody =>
      'You can start straight away — the game fetches only the pieces of map you are looking at. Two things worth knowing: you need a signal for the whole session, and the host of the map learns roughly where you are. A downloaded pack sends nothing and works in a forest.';

  @override
  String get regionStreamWarnAccept => 'Understood, stream it';

  @override
  String get languageTitle => 'Choose a language';

  @override
  String get languageBody =>
      'The safety rules you are about to read are about traffic and strangers. Pick the language you will actually understand them in.';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeTitle => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'Match the system';

  @override
  String get kindFirearm => 'Firearm';

  @override
  String get kindMelee => 'Melee weapon';

  @override
  String get kindArmor => 'Clothing';

  @override
  String get kindBackpack => 'Backpack';

  @override
  String get kindFood => 'Food';

  @override
  String get kindMedical => 'Medicine';

  @override
  String get kindLiterature => 'Book';

  @override
  String get kindTool => 'Tool';

  @override
  String get kindAttachment => 'Attachment';

  @override
  String get kindCrafting => 'Material';

  @override
  String get kindAmmo => 'Ammunition';

  @override
  String get kindMaterial => 'Material';

  @override
  String get kindMisc => 'Other';

  @override
  String get searchArea => 'Search the area';

  @override
  String get searchAreaRunning => 'Looking around…';

  @override
  String get searchHere => 'Search';

  @override
  String get searchShallow => 'Quick · 30 s';

  @override
  String get searchThorough => 'Thorough · 90 s';

  @override
  String get searchDeep => 'Exhaustive · 180 s';

  @override
  String get searchCancel => 'Stop';

  @override
  String get searchMoved => 'You moved — the search stopped.';

  @override
  String get searchLostSignal => 'The search stopped: no trusted position.';

  @override
  String get searchNoise => 'Searching is heard about 80 m away.';

  @override
  String searchFound(String items) {
    return 'Found: $items';
  }

  @override
  String get searchFoundNothing => 'Nothing worth carrying.';

  @override
  String get searchNoRoom => 'No room for everything — the rest stays.';

  @override
  String get searchEmpty => 'Already emptied.';

  @override
  String searchRevealed(int count) {
    return 'Places revealed: $count';
  }

  @override
  String get searchNothingNew => 'Nothing new here yet.';

  @override
  String get searchTooSoon => 'Nothing new to see yet.';

  @override
  String get searchTooClose => 'You would be looking at the same ground.';

  @override
  String searchFoundNearby(String what) {
    return 'You spot $what nearby.';
  }

  @override
  String get scoutCar => 'an abandoned car';

  @override
  String get scoutWaste => 'a skip';

  @override
  String get placeDistance => 'Distance';

  @override
  String get placeWayIn => 'Way in';

  @override
  String get placeOpen => 'Open';

  @override
  String get placeSearched => 'Searched';

  @override
  String get placeUntouched => 'Not yet';

  @override
  String placePartly(int percent) {
    return '$percent% of it left';
  }

  @override
  String placeStripped(int hours) {
    return 'Stripped — something back in about $hours h';
  }

  @override
  String get placeCanStill => 'Still possible';

  @override
  String get placeNothingLeft => 'Nothing left to turn over';

  @override
  String get placeHolds => 'Holds';

  @override
  String combatHurt(int millilitres) {
    return 'Hit — $millilitres ml lost';
  }

  @override
  String get combatStrike => 'Strike';

  @override
  String get enemyWalker => 'Walker';

  @override
  String get enemyLeaper => 'Leaper';

  @override
  String get enemyBrute => 'Brute';

  @override
  String get enemyCalm => 'has not seen you';

  @override
  String get enemySearching => 'looking for you';

  @override
  String get enemyHunting => 'coming for you';

  @override
  String get enemyHealthy => 'Healthy';

  @override
  String get enemyWounded => 'Wounded';

  @override
  String get enemyCritical => 'Critical';

  @override
  String get enemySprint => 'Sprint';

  @override
  String get combatReload => 'Reload';

  @override
  String get combatReloading => 'Reloading…';

  @override
  String get combatReloadBroken => 'Too close — the magazine stays out.';

  @override
  String combatRounds(int loaded, int magazine) {
    return '$loaded / $magazine';
  }

  @override
  String get combatAiming => 'Aiming…';

  @override
  String get combatOnTarget => 'On target';

  @override
  String combatHurtAt(String where, int millilitres) {
    return 'Hit — $where, $millilitres ml lost';
  }

  @override
  String combatHitAt(String where, int millilitres) {
    return 'Hit — $where, $millilitres ml';
  }

  @override
  String get combatExecution => 'Head shot. It is over.';

  @override
  String get hitHead => 'head';

  @override
  String get hitTorso => 'torso';

  @override
  String get hitArms => 'arm';

  @override
  String get hitLegs => 'leg';

  @override
  String get enemyBleeding => 'bleeding';

  @override
  String get combatFire => 'Fire';

  @override
  String get combatFireAway => 'Fire into the air';

  @override
  String get fireAwayUnloaded => 'Nothing chambered.';

  @override
  String get fireAwayInShelter => 'Not from your own ground.';

  @override
  String get combatFiredAway =>
      'A shot into the air. Something will come and look.';

  @override
  String combatChance(int percent) {
    return '$percent% hit';
  }

  @override
  String combatDistance(int metres) {
    return '$metres m';
  }

  @override
  String get combatNoWeapon => 'Nothing in hand.';

  @override
  String get combatNoAmmo => 'No rounds for this.';

  @override
  String get reloadNoMagazine => 'No magazine that fits.';

  @override
  String get reloadNothingFuller => 'Nothing fuller to swap in.';

  @override
  String get reloadAlreadyFull => 'Already loaded.';

  @override
  String get magazineFill => 'Fill';

  @override
  String get magazineEmpty => 'Unload';

  @override
  String get slotMagazine => 'Magazine';

  @override
  String get slotOptic => 'Optic';

  @override
  String get slotBarrel => 'Barrel';

  @override
  String get slotGrip => 'Grip';

  @override
  String get slotRail => 'Rail';

  @override
  String get slotEmpty => 'empty';

  @override
  String get craftTitle => 'Making';

  @override
  String get craftBenchFree => 'Nothing on it';

  @override
  String get craftTakeApart => 'Take apart';

  @override
  String get craftPartlyApart => 'partly apart';

  @override
  String get craftStop => 'Stop';

  @override
  String get craftStopKeepsWork =>
      'Stopping keeps the work. The piece stays open.';

  @override
  String get craftStopped => 'Stopped. What was done is done.';

  @override
  String get craftTakeApartRunning => 'Taking it apart';

  @override
  String get craftDone => 'Finished on the bench.';

  @override
  String craftDismantleWarning(String gives, int minutes) {
    return 'It will not come back. You get: $gives. $minutes minutes.';
  }

  @override
  String get craftMake => 'Make';

  @override
  String get craftCancel => 'Give up';

  @override
  String get craftCancelWarning => 'The materials are gone. They went into it.';

  @override
  String get craftNeedsTool => 'Needs';

  @override
  String get craftNoTool => 'Nothing here would do the job.';

  @override
  String get craftNoMaterials => 'Not enough of something.';

  @override
  String get craftBenchBusy => 'Something is already on the bench.';

  @override
  String get craftNotAtShelter => 'Not here — at the shelter.';

  @override
  String get craftNothingBack => 'There is nothing in it worth getting back.';

  @override
  String craftNeedsWorkshop(int level) {
    return 'Workshop L$level';
  }

  @override
  String craftMaking(String item) {
    return 'Making: $item';
  }

  @override
  String craftTakingApart(String item) {
    return 'Taking apart: $item';
  }

  @override
  String attachmentChoose(int count) {
    return '$count to choose from';
  }

  @override
  String get reloadFitting => 'Fitting magazine';

  @override
  String get reloadSwapping => 'Changing magazine';

  @override
  String get reloadFeeding => 'Loading rounds';

  @override
  String magazineRounds(int rounds, int capacity) {
    return '$rounds / $capacity';
  }

  @override
  String combatHit(int millilitres) {
    return 'Hit — $millilitres ml';
  }

  @override
  String get combatMiss => 'Missed.';

  @override
  String get combatStillHunted => 'They are still looking for you.';

  @override
  String get combatDown => 'It went down.';

  @override
  String combatHeard(int metres) {
    return 'Heard $metres m away.';
  }

  @override
  String get errorWeapon => 'WEAPON';

  @override
  String get errorSkill => 'PRACTICE';

  @override
  String get errorHeart => 'PULSE';

  @override
  String get errorMovement => 'MOVEMENT';

  @override
  String get errorTarget => 'TARGET';

  @override
  String get errorCondition => 'CONDITION';

  @override
  String get barrierDoor => 'Locked door';

  @override
  String get barrierPadlock => 'Padlock';

  @override
  String get barrierWindow => 'Boarded window';

  @override
  String get breachForce => 'Force it';

  @override
  String get breachPry => 'Lever it';

  @override
  String get breachPick => 'Pick it';

  @override
  String get breachNoTool => 'No tool for this — a padlock needs one.';

  @override
  String get breachDone => 'You are in.';

  @override
  String breachNoise(int metres) {
    return '$metres m of noise';
  }

  @override
  String get fieldRestingHrKnown => 'I know my resting heart rate';

  @override
  String get fieldRestingHr => 'Resting heart rate';

  @override
  String get fieldRestingHrHint =>
      'Measured sitting still. Left off, the game estimates it from your age and build — and gets it wrong for anyone whose heart is slower or faster than average. Stays on this device.';

  @override
  String get errRestingHrRange => 'Between 35 and 110 bpm';

  @override
  String get droppedHere => 'On the ground';

  @override
  String get droppedTake => 'Pick up';

  @override
  String get droppedTooFar => 'Too far to reach into.';

  @override
  String droppedExpires(int hours) {
    return '$hours h left';
  }

  @override
  String get droppedNoRoom => 'No room in the pack.';

  @override
  String get groundEmpty => 'Nothing here now.';

  @override
  String get noteRead => 'Read';

  @override
  String get noteClose => 'Put it back';

  @override
  String get inventoryTakeOff => 'Take off';

  @override
  String get inventoryDropAll => 'All';

  @override
  String get inventoryUse => 'Use';

  @override
  String inventoryPortion(int percent) {
    return '$percent% left';
  }

  @override
  String get inventoryWear => 'Put on';

  @override
  String get inventoryEmptySlot => 'empty';

  @override
  String inventoryUsing(String action) {
    return '$action…';
  }

  @override
  String inventoryUsed(String item) {
    return '$item — used';
  }

  @override
  String get inventoryNoWound => 'Nothing to dress.';

  @override
  String get inventoryWrongDressing =>
      'That dressing is not enough for this wound.';

  @override
  String get slotHead => 'Head';

  @override
  String get slotTorsoBase => 'Base layer';

  @override
  String get slotTorsoMid => 'Mid layer';

  @override
  String get slotTorsoOuter => 'Outer layer';

  @override
  String get slotTorsoArmor => 'Body armour';

  @override
  String get slotArms => 'Arms';

  @override
  String get slotHands => 'Hands';

  @override
  String get slotLegs => 'Legs';

  @override
  String get slotFeet => 'Feet';

  @override
  String get slotBack => 'Back';

  @override
  String get slotHand => 'In hand';

  @override
  String get statEnergy => 'Muzzle energy';

  @override
  String get statMoa => 'Dispersion';

  @override
  String get statMagazine => 'rds';

  @override
  String get statReload => 'Reload';

  @override
  String get statRange => 'Effective range';

  @override
  String get statNoise => 'Heard from';

  @override
  String get statBleed => 'Blood loss per hit';

  @override
  String get statSwing => 'Swing';

  @override
  String get statReach => 'Reach';

  @override
  String get statStrength => 'Strength needed';

  @override
  String get statInsulation => 'Insulation';

  @override
  String get statProtection => 'Protection';

  @override
  String get statCoverage => 'Coverage';

  @override
  String get statCapacity => 'Capacity';

  @override
  String get statCarry => 'Carry bonus';

  @override
  String get statKcal => 'Calories';

  @override
  String get statWater => 'Water';

  @override
  String get statEatTime => 'Time to eat';

  @override
  String get statUseTime => 'Time to use';

  @override
  String get statUses => 'Uses';

  @override
  String get statBlood => 'Restores blood';

  @override
  String get statPagesMin => 'Pages, fewest';

  @override
  String get statPagesMax => 'Pages, most';

  @override
  String get statXpPerPage => 'XP a page';

  @override
  String get statLight => 'light';

  @override
  String get statBattery => 'Battery';

  @override
  String get statCraftTime => 'Crafting time';

  @override
  String get statSearchBonus => 'Search radius';

  @override
  String get statMass => 'Mass';

  @override
  String get statBulk => 'Bulk';

  @override
  String get statSettle => 'Settling';

  @override
  String get statCraftSkill => 'Craft skill';

  @override
  String get statCondition => 'Condition';

  @override
  String get attachmentsFitted => 'Fitted';

  @override
  String attachmentsFree(int count) {
    return '$count free';
  }

  @override
  String get attachmentsNone => 'Nothing fitted';

  @override
  String get attachmentFit => 'Fit';

  @override
  String get attachmentRefused => 'It will not go on that.';

  @override
  String get attachmentWrongWeapon => 'It does not fit this weapon.';

  @override
  String get attachmentAlreadyOn => 'One of those is already on it.';

  @override
  String get attachmentNoRail => 'No rail left on this weapon.';

  @override
  String get attachmentRemove => 'Take off';

  @override
  String get itemDetails => 'Details';

  @override
  String get itemCompare => 'Compared with';

  @override
  String get itemCarried => 'carried';

  @override
  String get itemWorn => 'worn';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get inventoryEmpty => 'Your pack is empty.';

  @override
  String get inventoryEmptyHint =>
      'Search buildings and open places to find something worth carrying.';

  @override
  String get inventoryWorn => 'Worn';

  @override
  String get inventoryPack => 'In the pack';

  @override
  String get packOrderKind => 'by kind';

  @override
  String get packOrderName => 'by name';

  @override
  String get packOrderMass => 'by weight';

  @override
  String get packOrderWhat => 'Order';

  @override
  String get inventoryBackpack => 'Backpack';

  @override
  String get inventoryNoBackpack => 'Pockets only';

  @override
  String get inventoryDrop => 'Drop';

  @override
  String get inventoryOverComfort =>
      'Over a comfortable load: every step costs more.';

  @override
  String inventoryLost(int count) {
    return '$count items were lost with a removed content pack.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsMaps => 'Offline maps';

  @override
  String get settingsSimulator => 'GPS simulator';

  @override
  String get settingsSimulatorBody =>
      'The game then walks a recorded track instead of your real position. For testing only.';

  @override
  String get settingsRestartNeeded =>
      'The change takes effect the next time the game starts.';

  @override
  String get relocationTitle => 'I blacked out again';

  @override
  String relocationBody(int km) {
    return 'No idea how I got here. The last thing I remember was some $km km away.';
  }

  @override
  String relocationNoMapBody(int km) {
    return 'No idea how I got here. The last thing I remember was some $km km away — and I have no map of this place.';
  }

  @override
  String get relocationDismiss => 'So be it';

  @override
  String get permTitle => 'Permissions';

  @override
  String get permLocation => 'Location';

  @override
  String get permLocationGranted =>
      'Full — the game counts with the screen off too';

  @override
  String get permLocationForeground => 'Only while the game is on screen';

  @override
  String get permLocationDenied => 'None — there is no game without it';

  @override
  String get permLocationOff => 'Location is switched off on this phone';

  @override
  String get permBattery => 'Battery optimisation';

  @override
  String get permBatteryOn =>
      'On — Android may suspend counting in the background';

  @override
  String get permBatteryOff => 'Off for this game — as it should be';

  @override
  String get permBatteryUnknown => 'Unknown';

  @override
  String get permFix => 'Fix';

  @override
  String get permStartupTitle => 'Before you go walking';

  @override
  String get permStartupBody =>
      'To count a walk with the phone in your pocket, the game needs background location and battery optimisation switched off. Without them it only runs while it is on screen.';

  @override
  String get permStartupLater => 'Later';

  @override
  String get permStartupFix => 'Set it up';

  @override
  String get mapWaitingTitle => 'Finding you';

  @override
  String get mapWaitingBody =>
      'The game waits for a signal before drawing the map — otherwise it would show a place you are not.';
}
