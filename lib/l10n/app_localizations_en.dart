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
  String get statusBleeding => 'Bleeding';

  @override
  String get statusDehydrated => 'Dehydrated';

  @override
  String get statusStarving => 'Starving';

  @override
  String get statusSleepDeprived => 'Sleep-deprived';

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
  String get menuInventory => 'INVENTORY';

  @override
  String get menuShelter => 'SHELTER';

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
  String get mapMarkerDropped => 'Dropped item';

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
  String get combatFire => 'Fire';

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
  String combatHit(int millilitres) {
    return 'Hit — $millilitres ml';
  }

  @override
  String get combatMiss => 'Missed.';

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
  String get statMagazine => 'Magazine';

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
  String get statLight => 'Light';

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
