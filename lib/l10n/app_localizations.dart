import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// Application name. Not translated — it is the brand.
  ///
  /// In en, this message translates to:
  /// **'ARLS-ZA'**
  String get appTitle;

  /// Subtitle under the app name on the title screen.
  ///
  /// In en, this message translates to:
  /// **'Almost Real Life Survival'**
  String get appTagline;

  /// Resumes the active character.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Starts the character creator.
  ///
  /// In en, this message translates to:
  /// **'New character'**
  String get newCharacter;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Shown when a damaged database was replaced by a snapshot.
  ///
  /// In en, this message translates to:
  /// **'Save recovered'**
  String get saveRestoredTitle;

  /// Body of the recovery notice. States the cost plainly rather than hiding it.
  ///
  /// In en, this message translates to:
  /// **'The save file was damaged and has been restored from a backup. You lost {minutes} minutes of play.'**
  String saveRestoredBody(int minutes);

  /// No description provided for @saveLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Save could not be read'**
  String get saveLostTitle;

  /// No description provided for @saveLostBody.
  ///
  /// In en, this message translates to:
  /// **'The save file is damaged and no usable backup was found. You can import a profile you exported earlier, or start a new character.'**
  String get saveLostBody;

  /// No description provided for @importProfile.
  ///
  /// In en, this message translates to:
  /// **'Import profile'**
  String get importProfile;

  /// No description provided for @exportProfile.
  ///
  /// In en, this message translates to:
  /// **'Export profile'**
  String get exportProfile;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Profile exported.'**
  String get exportDone;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Profile imported.'**
  String get importDone;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {reason}'**
  String importFailed(String reason);

  /// Header of the return-after-a-break summary (§16.3).
  ///
  /// In en, this message translates to:
  /// **'While you were away'**
  String get awayTitle;

  /// No description provided for @awayElapsed.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Less than a day passed.} =1{One day passed.} other{{days} days passed.}}'**
  String awayElapsed(int days);

  /// Explains the §2.1.1 offline floor so the player is not confused by resources stopping at 10%.
  ///
  /// In en, this message translates to:
  /// **'Your body was running on reserves. Nothing dropped below the safety floor.'**
  String get awayFloored;

  /// Shown once when the anti-cheat of §2.1.1 rejects a tick.
  ///
  /// In en, this message translates to:
  /// **'The device clock moved backwards. No time was counted.'**
  String get clockRolledBack;

  /// No description provided for @bloodVolume.
  ///
  /// In en, this message translates to:
  /// **'Blood volume'**
  String get bloodVolume;

  /// No description provided for @dailyRequirement.
  ///
  /// In en, this message translates to:
  /// **'Daily requirement'**
  String get dailyRequirement;

  /// No description provided for @carryComfort.
  ///
  /// In en, this message translates to:
  /// **'Carry weight, comfortable'**
  String get carryComfort;

  /// No description provided for @carryMax.
  ///
  /// In en, this message translates to:
  /// **'Carry weight, maximum'**
  String get carryMax;

  /// No description provided for @maxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Maximum heart rate'**
  String get maxHeartRate;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'{value} ml'**
  String unitMl(String value);

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String unitKg(String value);

  /// No description provided for @unitBpm.
  ///
  /// In en, this message translates to:
  /// **'{value} bpm'**
  String unitBpm(String value);

  /// Privacy line shown next to the body parameters (§1.2, §15.4).
  ///
  /// In en, this message translates to:
  /// **'These figures are calculated on your phone and never leave it.'**
  String get dataStaysOnDevice;

  /// No description provided for @createCharacter.
  ///
  /// In en, this message translates to:
  /// **'Create your character'**
  String get createCharacter;

  /// No description provided for @creatorIntro.
  ///
  /// In en, this message translates to:
  /// **'Your height, weight, age and sex are used to compute blood volume, water and calorie needs, and carry weight.'**
  String get creatorIntro;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get fieldSex;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @fieldAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get fieldAge;

  /// No description provided for @fieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get fieldHeight;

  /// No description provided for @fieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get fieldWeight;

  /// No description provided for @computedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your body, computed'**
  String get computedTitle;

  /// No description provided for @deathModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how death works'**
  String get deathModeTitle;

  /// No description provided for @deathModeWarning.
  ///
  /// In en, this message translates to:
  /// **'This choice cannot be changed later.'**
  String get deathModeWarning;

  /// No description provided for @hardcoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardcore'**
  String get hardcoreTitle;

  /// No description provided for @hardcoreBody.
  ///
  /// In en, this message translates to:
  /// **'Death ends the character. Skills, shelter and stored gear are gone; the streak goes to the Chronicle.'**
  String get hardcoreBody;

  /// No description provided for @softcoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Softcore'**
  String get softcoreTitle;

  /// No description provided for @softcoreBody.
  ///
  /// In en, this message translates to:
  /// **'You lose consciousness instead of dying. Skills and shelter survive; the streak resets.'**
  String get softcoreBody;

  /// No description provided for @beginSurvival.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get beginSurvival;

  /// No description provided for @errNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 4 characters.'**
  String get errNameTooShort;

  /// No description provided for @errNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'At most 16 characters.'**
  String get errNameTooLong;

  /// No description provided for @errNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits and spaces only.'**
  String get errNameInvalid;

  /// No description provided for @errNameEdgeSpaces.
  ///
  /// In en, this message translates to:
  /// **'No leading or trailing spaces.'**
  String get errNameEdgeSpaces;

  /// No description provided for @errNameDoubleSpaces.
  ///
  /// In en, this message translates to:
  /// **'No doubled spaces.'**
  String get errNameDoubleSpaces;

  /// No description provided for @errAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Between 16 and 80.'**
  String get errAgeRange;

  /// No description provided for @errHeightRange.
  ///
  /// In en, this message translates to:
  /// **'Between 120 and 220 cm.'**
  String get errHeightRange;

  /// No description provided for @errWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Between 35 and 200 kg.'**
  String get errWeightRange;

  /// No description provided for @errBmiTooLow.
  ///
  /// In en, this message translates to:
  /// **'These figures do not describe a body the model can work with. Check the height and weight.'**
  String get errBmiTooLow;

  /// No description provided for @errBmiTooHigh.
  ///
  /// In en, this message translates to:
  /// **'These figures do not describe a body the model can work with. Check the height and weight.'**
  String get errBmiTooHigh;

  /// No description provided for @hudBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood'**
  String get hudBlood;

  /// No description provided for @hudWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get hudWater;

  /// No description provided for @hudCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get hudCalories;

  /// No description provided for @hudHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get hudHeartRate;

  /// No description provided for @hudCarry.
  ///
  /// In en, this message translates to:
  /// **'Carry'**
  String get hudCarry;

  /// No description provided for @hudNoSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal'**
  String get hudNoSignal;

  /// No description provided for @hudWeakSignal.
  ///
  /// In en, this message translates to:
  /// **'Weak signal'**
  String get hudWeakSignal;

  /// No description provided for @statusBleeding.
  ///
  /// In en, this message translates to:
  /// **'Bleeding'**
  String get statusBleeding;

  /// No description provided for @statusDehydrated.
  ///
  /// In en, this message translates to:
  /// **'Dehydrated'**
  String get statusDehydrated;

  /// No description provided for @statusStarving.
  ///
  /// In en, this message translates to:
  /// **'Starving'**
  String get statusStarving;

  /// No description provided for @statusSleepDeprived.
  ///
  /// In en, this message translates to:
  /// **'Sleep-deprived'**
  String get statusSleepDeprived;

  /// No description provided for @statusShock.
  ///
  /// In en, this message translates to:
  /// **'Shock'**
  String get statusShock;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'The game needs your position'**
  String get locationTitle;

  /// No description provided for @locationBody.
  ///
  /// In en, this message translates to:
  /// **'ARLS-ZA measures a real body moving through a real place. Without a position there is nothing to measure. The data never leaves your phone.'**
  String get locationBody;

  /// No description provided for @locationGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get locationGrant;

  /// No description provided for @locationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationSettings;

  /// No description provided for @locationDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location access refused'**
  String get locationDeniedTitle;

  /// No description provided for @locationDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'There is no game without a position. You can change this in the system settings.'**
  String get locationDeniedBody;

  /// No description provided for @locationServiceOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off'**
  String get locationServiceOffTitle;

  /// No description provided for @locationServiceOffBody.
  ///
  /// In en, this message translates to:
  /// **'This is a device-wide setting, not this game\'s. Switch location on and come back.'**
  String get locationServiceOffBody;

  /// No description provided for @locationForegroundOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'The game runs on screen only'**
  String get locationForegroundOnlyTitle;

  /// No description provided for @locationForegroundOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Background location was not granted, so the simulation pauses when you put the app away. This is a full variant of the game — you lose nothing but walking with the screen off.'**
  String get locationForegroundOnlyBody;

  /// No description provided for @locationNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'ARLS-ZA — expedition in progress'**
  String get locationNotificationTitle;

  /// No description provided for @locationNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'The game is counting your movement. Tap to return.'**
  String get locationNotificationBody;

  /// No description provided for @integritySuspendedMock.
  ///
  /// In en, this message translates to:
  /// **'Mocked location detected. Play is suspended.'**
  String get integritySuspendedMock;

  /// No description provided for @integritySuspendedVehicle.
  ///
  /// In en, this message translates to:
  /// **'You are in a vehicle. Play is suspended until you are back on your own feet.'**
  String get integritySuspendedVehicle;

  /// No description provided for @hudLowBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery below 20% — head for the shelter'**
  String get hudLowBattery;

  /// No description provided for @hudEconomy.
  ///
  /// In en, this message translates to:
  /// **'Power saving'**
  String get hudEconomy;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'pl':
      return L10nPl();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
