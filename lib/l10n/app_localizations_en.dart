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
  String get hudCarry => 'Carry';

  @override
  String get hudNoSignal => 'No signal';

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
}
