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
}
