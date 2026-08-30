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

  /// No description provided for @awayAttackedBody.
  ///
  /// In en, this message translates to:
  /// **'{blows} blows landed while the screen was off, and {ml} ml of blood with them. Dress what is open before you walk anywhere.'**
  String awayAttackedBody(int blows, int ml);

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

  /// No description provided for @kitTitle.
  ///
  /// In en, this message translates to:
  /// **'What you leave with'**
  String get kitTitle;

  /// No description provided for @kitStepTools.
  ///
  /// In en, this message translates to:
  /// **'One tool'**
  String get kitStepTools;

  /// No description provided for @kitStepMedical.
  ///
  /// In en, this message translates to:
  /// **'One dressing'**
  String get kitStepMedical;

  /// No description provided for @kitStepCombat.
  ///
  /// In en, this message translates to:
  /// **'One blade'**
  String get kitStepCombat;

  /// No description provided for @kitStepFood.
  ///
  /// In en, this message translates to:
  /// **'One meal'**
  String get kitStepFood;

  /// No description provided for @kitStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String kitStepOf(int step, int total);

  /// No description provided for @kitSummary.
  ///
  /// In en, this message translates to:
  /// **'This is what you have'**
  String get kitSummary;

  /// No description provided for @kitSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing else. What is not here has to be found.'**
  String get kitSummaryHint;

  /// No description provided for @kitBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get kitBack;

  /// No description provided for @kitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Take it and go'**
  String get kitConfirm;

  /// No description provided for @kitCount.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String kitCount(int count);

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

  /// No description provided for @hudSleep.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get hudSleep;

  /// No description provided for @hudHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get hudHeartRate;

  /// No description provided for @hudThreat.
  ///
  /// In en, this message translates to:
  /// **'{count} in the fight · nearest {metres} m'**
  String hudThreat(int count, int metres);

  /// No description provided for @hudThreatQuiet.
  ///
  /// In en, this message translates to:
  /// **'{count} nearby, none coming yet'**
  String hudThreatQuiet(int count);

  /// No description provided for @hudThreatSprint.
  ///
  /// In en, this message translates to:
  /// **'can still sprint'**
  String get hudThreatSprint;

  /// No description provided for @zoneCleared.
  ///
  /// In en, this message translates to:
  /// **'The zone is down. Something was left where it stood.'**
  String get zoneCleared;

  /// No description provided for @hudNoise.
  ///
  /// In en, this message translates to:
  /// **'Noise'**
  String get hudNoise;

  /// No description provided for @hudNoiseQuiet.
  ///
  /// In en, this message translates to:
  /// **'silent'**
  String get hudNoiseQuiet;

  /// No description provided for @hudCarry.
  ///
  /// In en, this message translates to:
  /// **'Carry'**
  String get hudCarry;

  /// No description provided for @hudBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get hudBulk;

  /// No description provided for @hudNoSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal'**
  String get hudNoSignal;

  /// No description provided for @hudAcquiring.
  ///
  /// In en, this message translates to:
  /// **'Acquiring GPS'**
  String get hudAcquiring;

  /// No description provided for @hudWeakSignal.
  ///
  /// In en, this message translates to:
  /// **'Weak signal'**
  String get hudWeakSignal;

  /// No description provided for @statusDegree.
  ///
  /// In en, this message translates to:
  /// **'{degree} degree'**
  String statusDegree(String degree);

  /// No description provided for @statusOfDaily.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the daily need'**
  String statusOfDaily(int percent);

  /// No description provided for @statusDebtHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h of debt'**
  String statusDebtHours(int hours);

  /// No description provided for @statusEffect.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get statusEffect;

  /// No description provided for @statusFix.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get statusFix;

  /// No description provided for @statusWhere.
  ///
  /// In en, this message translates to:
  /// **'Where to find it'**
  String get statusWhere;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @statusShockEffect.
  ///
  /// In en, this message translates to:
  /// **'Wider groups on every shot, less carried before it hurts, and above class III the picture dims and running makes you dizzy.'**
  String get statusShockEffect;

  /// No description provided for @statusShockFix.
  ///
  /// In en, this message translates to:
  /// **'Stop the bleeding first — a bandage or a tourniquet. Blood comes back on its own afterwards, slowly, and only if you eat and drink.'**
  String get statusShockFix;

  /// No description provided for @statusShockWhere.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies, clinics, ambulances; first-aid kits in offices and workshops.'**
  String get statusShockWhere;

  /// No description provided for @statusDehydratedEffect.
  ///
  /// In en, this message translates to:
  /// **'Hands go first: aim and reaction time. Deeper down it takes decisions, then strength.'**
  String get statusDehydratedEffect;

  /// No description provided for @statusDehydratedFix.
  ///
  /// In en, this message translates to:
  /// **'Drink. It works over about twenty minutes, not instantly, so drink before you need it.'**
  String get statusDehydratedFix;

  /// No description provided for @statusDehydratedWhere.
  ///
  /// In en, this message translates to:
  /// **'Shops, petrol stations, homes. Water from a tap or a stream has to be boiled or treated first.'**
  String get statusDehydratedWhere;

  /// No description provided for @statusStarvingEffect.
  ///
  /// In en, this message translates to:
  /// **'Everything takes longer — searching, bandaging, building — and precision goes with it.'**
  String get statusStarvingEffect;

  /// No description provided for @statusStarvingFix.
  ///
  /// In en, this message translates to:
  /// **'Eat. Tins and dry food keep; anything cooked is worth more per kilogram carried.'**
  String get statusStarvingFix;

  /// No description provided for @statusStarvingWhere.
  ///
  /// In en, this message translates to:
  /// **'Shops, homes, restaurants, allotments. Bodies rarely carry more than a snack.'**
  String get statusStarvingWhere;

  /// No description provided for @statusSleepDeprivedEffect.
  ///
  /// In en, this message translates to:
  /// **'Every shot spreads wider, everything takes longer to learn, and past a day awake the eyes close on their own for a few seconds at a time.'**
  String get statusSleepDeprivedEffect;

  /// No description provided for @statusSleepDeprivedFix.
  ///
  /// In en, this message translates to:
  /// **'Sleep. Only sleep pays this down — and only somewhere safe enough to lie down, which means a shelter.'**
  String get statusSleepDeprivedFix;

  /// No description provided for @statusSleepDeprivedWhere.
  ///
  /// In en, this message translates to:
  /// **'Your own shelter. A bed or a mattress makes the hours count for more.'**
  String get statusSleepDeprivedWhere;

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

  /// No description provided for @statusWasting.
  ///
  /// In en, this message translates to:
  /// **'Wasting'**
  String get statusWasting;

  /// No description provided for @statusWastingEffect.
  ///
  /// In en, this message translates to:
  /// **'Everything is slower and the hands are unsteady. Weaker than it looks on a full stomach.'**
  String get statusWastingEffect;

  /// No description provided for @statusWastingFix.
  ///
  /// In en, this message translates to:
  /// **'Eat more than the day needs. It comes back slowly.'**
  String get statusWastingFix;

  /// No description provided for @statusWastingWhere.
  ///
  /// In en, this message translates to:
  /// **'Anything with calories in it. Tins keep.'**
  String get statusWastingWhere;

  /// No description provided for @statusWastingLevel.
  ///
  /// In en, this message translates to:
  /// **'−{percent}% of body weight'**
  String statusWastingLevel(int percent);

  /// No description provided for @statusWornOut.
  ///
  /// In en, this message translates to:
  /// **'Worn out'**
  String get statusWornOut;

  /// No description provided for @statusWornOutEffect.
  ///
  /// In en, this message translates to:
  /// **'Slower to heal, slower to catch your breath, steadier hands would be nice. A good night does not fix it.'**
  String get statusWornOutEffect;

  /// No description provided for @statusWornOutFix.
  ///
  /// In en, this message translates to:
  /// **'Longer nights than you need. Winter, or a Lounge.'**
  String get statusWornOutFix;

  /// No description provided for @statusWornOutWhere.
  ///
  /// In en, this message translates to:
  /// **'The shelter, and time.'**
  String get statusWornOutWhere;

  /// No description provided for @statusWornOutLevel.
  ///
  /// In en, this message translates to:
  /// **'{nights} nights behind'**
  String statusWornOutLevel(int nights);

  /// No description provided for @statusSleepDeprived.
  ///
  /// In en, this message translates to:
  /// **'Sleep-deprived'**
  String get statusSleepDeprived;

  /// No description provided for @bleedSuperficial.
  ///
  /// In en, this message translates to:
  /// **'superficial'**
  String get bleedSuperficial;

  /// No description provided for @bleedModerate.
  ///
  /// In en, this message translates to:
  /// **'moderate'**
  String get bleedModerate;

  /// No description provided for @bleedSevere.
  ///
  /// In en, this message translates to:
  /// **'severe'**
  String get bleedSevere;

  /// No description provided for @bleedArterial.
  ///
  /// In en, this message translates to:
  /// **'arterial'**
  String get bleedArterial;

  /// No description provided for @statusBleedingEffect.
  ///
  /// In en, this message translates to:
  /// **'{millilitres} ml a minute, and running multiplies it — at 160 bpm against a resting 70 it is more than twice that. Blood does not come back at all while something is open.'**
  String statusBleedingEffect(int millilitres);

  /// No description provided for @statusBleedingFix.
  ///
  /// In en, this message translates to:
  /// **'A pressure dressing, and stand still while it goes on.'**
  String get statusBleedingFix;

  /// No description provided for @statusBleedingFixArterial.
  ///
  /// In en, this message translates to:
  /// **'A tourniquet, and nothing else. A dressing will not hold this one.'**
  String get statusBleedingFixArterial;

  /// No description provided for @statusBleedingWhere.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies, clinics, ambulances; first-aid kits in offices and workshops.'**
  String get statusBleedingWhere;

  /// No description provided for @deathTitle.
  ///
  /// In en, this message translates to:
  /// **'THAT IS THE END'**
  String get deathTitle;

  /// No description provided for @downTitle.
  ///
  /// In en, this message translates to:
  /// **'YOU WENT DOWN'**
  String get downTitle;

  /// No description provided for @causeBloodLoss.
  ///
  /// In en, this message translates to:
  /// **'Blood loss'**
  String get causeBloodLoss;

  /// No description provided for @causeThirst.
  ///
  /// In en, this message translates to:
  /// **'Dehydration'**
  String get causeThirst;

  /// No description provided for @causeStarvation.
  ///
  /// In en, this message translates to:
  /// **'Starvation'**
  String get causeStarvation;

  /// No description provided for @deathWhat.
  ///
  /// In en, this message translates to:
  /// **'Hardcore: this character is over. The streak goes into the Chronicle with everything it reached. A new one keeps your body — the same height, weight and age — and only the name changes.'**
  String get deathWhat;

  /// No description provided for @downWhat.
  ///
  /// In en, this message translates to:
  /// **'You come round where you are, an hour from now, with a quarter of your blood and almost nothing in you. Whatever was in your hands is gone; about half of what you carried is scattered where you fell. For ten minutes afterwards they will take you for dead — and you cannot fight either.'**
  String get downWhat;

  /// No description provided for @downLeft.
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String downLeft(String time);

  /// No description provided for @downClosedApp.
  ///
  /// In en, this message translates to:
  /// **'The hour runs whether the app is open or not.'**
  String get downClosedApp;

  /// No description provided for @downLog.
  ///
  /// In en, this message translates to:
  /// **'The last of it'**
  String get downLog;

  /// No description provided for @downGrace.
  ///
  /// In en, this message translates to:
  /// **'They still take you for dead. Do not give it away.'**
  String get downGrace;

  /// No description provided for @deathNewCharacter.
  ///
  /// In en, this message translates to:
  /// **'New character'**
  String get deathNewCharacter;

  /// No description provided for @deathSameBody.
  ///
  /// In en, this message translates to:
  /// **'The same body, a new name.'**
  String get deathSameBody;

  /// No description provided for @downCaches.
  ///
  /// In en, this message translates to:
  /// **'What you were carrying is scattered where you fell.'**
  String get downCaches;

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

  /// No description provided for @safetyNoCombatMoving.
  ///
  /// In en, this message translates to:
  /// **'Do not play while travelling'**
  String get safetyNoCombatMoving;

  /// No description provided for @safetyNightVisibility.
  ///
  /// In en, this message translates to:
  /// **'It is dark. Be visible, and watch where you are going.'**
  String get safetyNightVisibility;

  /// No description provided for @safetyBriefingTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you go out'**
  String get safetyBriefingTitle;

  /// No description provided for @safetyBriefingIntro.
  ///
  /// In en, this message translates to:
  /// **'This game measures a real body moving through a real city. Everything below is about you, not the character.'**
  String get safetyBriefingIntro;

  /// No description provided for @safetyRuleTraffic.
  ///
  /// In en, this message translates to:
  /// **'Watch the road, not the phone. The game knows nothing about cars.'**
  String get safetyRuleTraffic;

  /// No description provided for @safetyRuleNoDriving.
  ///
  /// In en, this message translates to:
  /// **'Do not play while travelling. Above 15 km/h combat is blocked; above 40 km/h play is suspended.'**
  String get safetyRuleNoDriving;

  /// No description provided for @safetyRuleNoTrespass.
  ///
  /// In en, this message translates to:
  /// **'The game will never send you onto private land, onto a railway or into water. If a marker looks like it does — do not go.'**
  String get safetyRuleNoTrespass;

  /// No description provided for @safetyRuleRespect.
  ///
  /// In en, this message translates to:
  /// **'Hospitals, schools, cemeteries and places of worship are excluded from spawns. Do not play there anyway.'**
  String get safetyRuleRespect;

  /// No description provided for @safetyRuleNight.
  ///
  /// In en, this message translates to:
  /// **'After dark, be visible. Light clothing, a reflective band, ears free.'**
  String get safetyRuleNight;

  /// No description provided for @safetyRuleStop.
  ///
  /// In en, this message translates to:
  /// **'Tiredness, pain, a storm, strangers — end the session. The character will wait.'**
  String get safetyRuleStop;

  /// No description provided for @safetyBriefingAccept.
  ///
  /// In en, this message translates to:
  /// **'I understand and accept this'**
  String get safetyBriefingAccept;

  /// No description provided for @regionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a region'**
  String get regionTitle;

  /// No description provided for @regionIntro.
  ///
  /// In en, this message translates to:
  /// **'The game runs without a network, so the map has to be on the phone. Download the pack for the area you will be walking.'**
  String get regionIntro;

  /// No description provided for @regionSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String regionSizeMb(String mb);

  /// No description provided for @regionInstalled.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get regionInstalled;

  /// No description provided for @regionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get regionUnavailable;

  /// No description provided for @regionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get regionDownload;

  /// No description provided for @regionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get regionDelete;

  /// No description provided for @regionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get regionCancel;

  /// No description provided for @regionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get regionRetry;

  /// No description provided for @regionNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get regionNearYou;

  /// No description provided for @regionDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String regionDownloading(int percent);

  /// No description provided for @regionErrSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough room. Free some up and try again.'**
  String get regionErrSpace;

  /// No description provided for @regionErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'The download was interrupted. What arrived is kept — the next attempt finishes it.'**
  String get regionErrNetwork;

  /// No description provided for @regionErrCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The file that arrived does not match its checksum. It has been deleted.'**
  String get regionErrCorrupt;

  /// No description provided for @regionErrUnpublished.
  ///
  /// In en, this message translates to:
  /// **'This region has not been published yet.'**
  String get regionErrUnpublished;

  /// No description provided for @regionLeftPackTitle.
  ///
  /// In en, this message translates to:
  /// **'You are off the downloaded map'**
  String get regionLeftPackTitle;

  /// No description provided for @regionLeftPackBody.
  ///
  /// In en, this message translates to:
  /// **'Without tiles there is nothing to draw and nowhere to place markers. Download the pack for this area, or return to the one you have.'**
  String get regionLeftPackBody;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get menuProfile;

  /// No description provided for @profileBody.
  ///
  /// In en, this message translates to:
  /// **'This body'**
  String get profileBody;

  /// No description provided for @profileBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood volume'**
  String get profileBlood;

  /// No description provided for @profileEnergy.
  ///
  /// In en, this message translates to:
  /// **'Daily energy'**
  String get profileEnergy;

  /// No description provided for @profileWater.
  ///
  /// In en, this message translates to:
  /// **'Daily water'**
  String get profileWater;

  /// No description provided for @profileCarry.
  ///
  /// In en, this message translates to:
  /// **'Carry, comfortable / hard'**
  String get profileCarry;

  /// No description provided for @profileHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart rate, rest to max'**
  String get profileHeart;

  /// No description provided for @profileAim.
  ///
  /// In en, this message translates to:
  /// **'What is making you miss'**
  String get profileAim;

  /// No description provided for @profileTotalSpread.
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get profileTotalSpread;

  /// No description provided for @profileAimWhat.
  ///
  /// In en, this message translates to:
  /// **'Standing still removes the two largest rows: your own pace and your own pulse. Nothing else on this list can be fixed on the spot.'**
  String get profileAimWhat;

  /// No description provided for @profileFighting.
  ///
  /// In en, this message translates to:
  /// **'Out there'**
  String get profileFighting;

  /// No description provided for @profileShots.
  ///
  /// In en, this message translates to:
  /// **'Shots fired'**
  String get profileShots;

  /// No description provided for @profileAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get profileAccuracy;

  /// No description provided for @profileSwings.
  ///
  /// In en, this message translates to:
  /// **'Swings'**
  String get profileSwings;

  /// No description provided for @profileKills.
  ///
  /// In en, this message translates to:
  /// **'Put down'**
  String get profileKills;

  /// No description provided for @profileShotsPerKill.
  ///
  /// In en, this message translates to:
  /// **'Rounds per kill'**
  String get profileShotsPerKill;

  /// No description provided for @profileBloodDealt.
  ///
  /// In en, this message translates to:
  /// **'Blood taken'**
  String get profileBloodDealt;

  /// No description provided for @profileBloodLost.
  ///
  /// In en, this message translates to:
  /// **'Blood lost'**
  String get profileBloodLost;

  /// No description provided for @profileSearches.
  ///
  /// In en, this message translates to:
  /// **'Places searched'**
  String get profileSearches;

  /// No description provided for @profileBlackouts.
  ///
  /// In en, this message translates to:
  /// **'Blackouts'**
  String get profileBlackouts;

  /// No description provided for @profileWhereTheyLand.
  ///
  /// In en, this message translates to:
  /// **'Where your rounds land'**
  String get profileWhereTheyLand;

  /// No description provided for @profileNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing has landed yet.'**
  String get profileNothingYet;

  /// No description provided for @profileSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get profileSkills;

  /// No description provided for @profileSkillsSoon.
  ///
  /// In en, this message translates to:
  /// **'Not in the game yet. Until they are, everybody shoots like a novice — twenty-five minutes of angle, which is the largest row above.'**
  String get profileSkillsSoon;

  /// No description provided for @profileSheet.
  ///
  /// In en, this message translates to:
  /// **'The character sheet'**
  String get profileSheet;

  /// No description provided for @profileSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get profileSex;

  /// No description provided for @profileSexMale.
  ///
  /// In en, this message translates to:
  /// **'male'**
  String get profileSexMale;

  /// No description provided for @profileSexFemale.
  ///
  /// In en, this message translates to:
  /// **'female'**
  String get profileSexFemale;

  /// No description provided for @profileAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileAge;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeight;

  /// No description provided for @profileMass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get profileMass;

  /// No description provided for @profileMassLost.
  ///
  /// In en, this message translates to:
  /// **'{now} kg  ({start} kg at the start, −{percent}%)'**
  String profileMassLost(String now, String start, int percent);

  /// No description provided for @profileBmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get profileBmi;

  /// No description provided for @profileState.
  ///
  /// In en, this message translates to:
  /// **'How this body is doing'**
  String get profileState;

  /// No description provided for @profileStateWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get profileStateWater;

  /// No description provided for @profileStateCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get profileStateCalories;

  /// No description provided for @profileStateSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep debt'**
  String get profileStateSleep;

  /// No description provided for @profileStateStrain.
  ///
  /// In en, this message translates to:
  /// **'Nights behind'**
  String get profileStateStrain;

  /// No description provided for @profileStateBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood'**
  String get profileStateBlood;

  /// No description provided for @profileOfDaily.
  ///
  /// In en, this message translates to:
  /// **'{amount} of {daily}'**
  String profileOfDaily(String amount, String daily);

  /// No description provided for @profileDebtHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String profileDebtHours(int hours);

  /// No description provided for @profileNightsBehind.
  ///
  /// In en, this message translates to:
  /// **'{nights} nights'**
  String profileNightsBehind(int nights);

  /// No description provided for @profileWhy.
  ///
  /// In en, this message translates to:
  /// **'What it is doing to you'**
  String get profileWhy;

  /// No description provided for @profileWhyNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is costing you anything right now. Fed, watered, rested and whole.'**
  String get profileWhyNothing;

  /// No description provided for @profileWhySleepDebt.
  ///
  /// In en, this message translates to:
  /// **'Sleep debt {hours} h — you have been awake when you should not have been. Every action takes {percent}% longer and the sights are {moa} MOA wider.'**
  String profileWhySleepDebt(int hours, int percent, String moa);

  /// No description provided for @profileWhyStrain.
  ///
  /// In en, this message translates to:
  /// **'{nights} nights behind — weeks of short nights, not last night. Wounds mend {healing}% slower and your pulse takes longer to settle. One good night will not clear it: only nights longer than you need.'**
  String profileWhyStrain(int nights, int healing);

  /// No description provided for @profileWhyThirst.
  ///
  /// In en, this message translates to:
  /// **'Water deficit {percent}% of body mass — everything takes {slower}% longer and your aim is {aim}% worse.'**
  String profileWhyThirst(int percent, int slower, int aim);

  /// No description provided for @profileWhyHunger.
  ///
  /// In en, this message translates to:
  /// **'Calorie reserve at {percent}% of a day — the hands are unsteady and everything takes longer.'**
  String profileWhyHunger(int percent);

  /// No description provided for @profileWhyWasting.
  ///
  /// In en, this message translates to:
  /// **'You have lost {percent}% of your starting weight. This is not hunger, it is the body itself, and it comes back only by eating more than a day needs.'**
  String profileWhyWasting(int percent);

  /// No description provided for @profileWhyBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood loss class {roman} — {effect}.'**
  String profileWhyBlood(String roman, String effect);

  /// No description provided for @effectRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get effectRadius;

  /// No description provided for @effectRare.
  ///
  /// In en, this message translates to:
  /// **'Rare finds'**
  String get effectRare;

  /// No description provided for @effectSearch.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get effectSearch;

  /// No description provided for @effectStealth.
  ///
  /// In en, this message translates to:
  /// **'Noticed at'**
  String get effectStealth;

  /// No description provided for @effectSpread.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get effectSpread;

  /// No description provided for @effectReload.
  ///
  /// In en, this message translates to:
  /// **'Reload and settling'**
  String get effectReload;

  /// No description provided for @effectDressing.
  ///
  /// In en, this message translates to:
  /// **'Dressings'**
  String get effectDressing;

  /// No description provided for @effectHealing.
  ///
  /// In en, this message translates to:
  /// **'Healing'**
  String get effectHealing;

  /// No description provided for @effectWork.
  ///
  /// In en, this message translates to:
  /// **'Building and making'**
  String get effectWork;

  /// No description provided for @effectSalvage.
  ///
  /// In en, this message translates to:
  /// **'Salvage yield'**
  String get effectSalvage;

  /// No description provided for @profileSkillLevel.
  ///
  /// In en, this message translates to:
  /// **'{level} / 100'**
  String profileSkillLevel(int level);

  /// No description provided for @profileSkillXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP · {next} to the next level'**
  String profileSkillXp(int xp, int next);

  /// No description provided for @profileSkillScouting.
  ///
  /// In en, this message translates to:
  /// **'Scouting'**
  String get profileSkillScouting;

  /// No description provided for @profileSkillWeapons.
  ///
  /// In en, this message translates to:
  /// **'Weapons'**
  String get profileSkillWeapons;

  /// No description provided for @profileSkillMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get profileSkillMedicine;

  /// No description provided for @profileSkillEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get profileSkillEngineering;

  /// No description provided for @profileAimQuadrature.
  ///
  /// In en, this message translates to:
  /// **'These do not add up, and should not: §5.1 combines them in quadrature, so the largest one dominates and the small ones almost vanish. The percentage beside each is its real share of the group.'**
  String get profileAimQuadrature;

  /// No description provided for @profileAimShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String profileAimShare(int percent);

  /// No description provided for @profileAliveDays.
  ///
  /// In en, this message translates to:
  /// **'Alive {days} d {hours} h'**
  String profileAliveDays(int days, int hours);

  /// No description provided for @profileAliveHours.
  ///
  /// In en, this message translates to:
  /// **'Alive {hours} h'**
  String profileAliveHours(int hours);

  /// No description provided for @menuInventory.
  ///
  /// In en, this message translates to:
  /// **'INVENTORY'**
  String get menuInventory;

  /// No description provided for @menuShelter.
  ///
  /// In en, this message translates to:
  /// **'SHELTER'**
  String get menuShelter;

  /// No description provided for @stashOnTheShelves.
  ///
  /// In en, this message translates to:
  /// **'On the shelves'**
  String get stashOnTheShelves;

  /// No description provided for @stashInThePack.
  ///
  /// In en, this message translates to:
  /// **'In the pack'**
  String get stashInThePack;

  /// No description provided for @stashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get stashEmpty;

  /// No description provided for @stashPackEmpty.
  ///
  /// In en, this message translates to:
  /// **'The pack is empty.'**
  String get stashPackEmpty;

  /// No description provided for @stashStore.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get stashStore;

  /// No description provided for @stashTake.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get stashTake;

  /// No description provided for @stashFull.
  ///
  /// In en, this message translates to:
  /// **'No room on the shelves.'**
  String get stashFull;

  /// No description provided for @stashNoRoomInPack.
  ///
  /// In en, this message translates to:
  /// **'It will not fit in the pack.'**
  String get stashNoRoomInPack;

  /// No description provided for @shelterShelves.
  ///
  /// In en, this message translates to:
  /// **'Shelves'**
  String get shelterShelves;

  /// No description provided for @shelterShelvesWhat.
  ///
  /// In en, this message translates to:
  /// **'What is left here stays here. The house holds what it holds; Storage adds fifty kilograms a level.'**
  String get shelterShelvesWhat;

  /// No description provided for @shelterTitle.
  ///
  /// In en, this message translates to:
  /// **'Shelter'**
  String get shelterTitle;

  /// No description provided for @campTitle.
  ///
  /// In en, this message translates to:
  /// **'Camp'**
  String get campTitle;

  /// No description provided for @shelterCamps.
  ///
  /// In en, this message translates to:
  /// **'Camps'**
  String get shelterCamps;

  /// No description provided for @shelterBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get shelterBuild;

  /// No description provided for @shelterBuildHere.
  ///
  /// In en, this message translates to:
  /// **'Build here'**
  String get shelterBuildHere;

  /// No description provided for @shelterPause.
  ///
  /// In en, this message translates to:
  /// **'Put down'**
  String get shelterPause;

  /// No description provided for @shelterResume.
  ///
  /// In en, this message translates to:
  /// **'Pick up'**
  String get shelterResume;

  /// No description provided for @shelterPaused.
  ///
  /// In en, this message translates to:
  /// **'Work put down. Nothing lost — the hours and the materials stay.'**
  String get shelterPaused;

  /// No description provided for @shelterResumed.
  ///
  /// In en, this message translates to:
  /// **'Back to work.'**
  String get shelterResumed;

  /// No description provided for @shelterOnHold.
  ///
  /// In en, this message translates to:
  /// **'Put down'**
  String get shelterOnHold;

  /// No description provided for @shelterCancel.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get shelterCancel;

  /// No description provided for @shelterCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Give up on this?'**
  String get shelterCancelTitle;

  /// No description provided for @shelterCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Carry on'**
  String get shelterCancelKeep;

  /// No description provided for @shelterCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get shelterCancelConfirm;

  /// No description provided for @shelterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Work abandoned.'**
  String get shelterCancelled;

  /// No description provided for @shelterCancelShelterWhat.
  ///
  /// In en, this message translates to:
  /// **'The materials are already in the walls and they do not come back out. The place goes with them, and building here again starts from nothing. This cannot be undone.'**
  String get shelterCancelShelterWhat;

  /// No description provided for @shelterCancelCampWhat.
  ///
  /// In en, this message translates to:
  /// **'The camp goes, and with it everything that went into it. Putting one here again starts from nothing. This cannot be undone.'**
  String get shelterCancelCampWhat;

  /// No description provided for @shelterCancelModuleWhat.
  ///
  /// In en, this message translates to:
  /// **'The materials for this level are gone — they are in the frame. The levels already finished stay. Starting this one again means carrying the lot back. This cannot be undone.'**
  String get shelterCancelModuleWhat;

  /// No description provided for @shelterDemolish.
  ///
  /// In en, this message translates to:
  /// **'Dismantle'**
  String get shelterDemolish;

  /// No description provided for @shelterDemolished.
  ///
  /// In en, this message translates to:
  /// **'Module dismantled.'**
  String get shelterDemolished;

  /// No description provided for @shelterDemolishWhat.
  ///
  /// In en, this message translates to:
  /// **'Taking this module down returns half the materials: {gives}. Lower levels stay. This cannot be undone.'**
  String shelterDemolishWhat(String gives);

  /// No description provided for @shelterSafeZone.
  ///
  /// In en, this message translates to:
  /// **'Safe zone'**
  String get shelterSafeZone;

  /// No description provided for @shelterSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep quality'**
  String get shelterSleep;

  /// No description provided for @shelterStorage.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get shelterStorage;

  /// No description provided for @shelterNoFix.
  ///
  /// In en, this message translates to:
  /// **'No position — a shelter goes where you are standing.'**
  String get shelterNoFix;

  /// No description provided for @shelterNotHere.
  ///
  /// In en, this message translates to:
  /// **'You have to be at the shelter to build onto it.'**
  String get shelterNotHere;

  /// No description provided for @shelterWorkStopped.
  ///
  /// In en, this message translates to:
  /// **'Work stopped — nobody is on the site.'**
  String get shelterWorkStopped;

  /// No description provided for @shelterNeedsTool.
  ///
  /// In en, this message translates to:
  /// **'Needs a hammer. From Workshop 2, a multitool as well.'**
  String get shelterNeedsTool;

  /// No description provided for @shelterMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing: {what}'**
  String shelterMissing(String what);

  /// No description provided for @shelterBuildingLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String shelterBuildingLeft(String time);

  /// No description provided for @shelterNoneWhat.
  ///
  /// In en, this message translates to:
  /// **'It goes up where you are standing, and that is where you will come back to sleep. Fifty metres of ground the dead do not walk into — and out of which you cannot shoot either.'**
  String get shelterNoneWhat;

  /// No description provided for @campWhat.
  ///
  /// In en, this message translates to:
  /// **'Somewhere else you spend your day: work, a lecture hall, a relative’s flat. Twenty metres, a chest, and a night worth seven tenths of one. Two at most, and not within 800 m of anything you have already built.'**
  String get campWhat;

  /// No description provided for @campTooMany.
  ///
  /// In en, this message translates to:
  /// **'Two camps is the limit. Take one down first.'**
  String get campTooMany;

  /// No description provided for @campTooCloseToShelter.
  ///
  /// In en, this message translates to:
  /// **'Under 800 m from the shelter — that would just be a second front door.'**
  String get campTooCloseToShelter;

  /// No description provided for @campTooCloseToCamp.
  ///
  /// In en, this message translates to:
  /// **'Under 800 m from the other camp.'**
  String get campTooCloseToCamp;

  /// No description provided for @campTooCloseToHotspot.
  ///
  /// In en, this message translates to:
  /// **'Too close to the middle of a Decay Zone.'**
  String get campTooCloseToHotspot;

  /// No description provided for @campDecaying.
  ///
  /// In en, this message translates to:
  /// **'Nobody has been here in a fortnight. It is coming apart.'**
  String get campDecaying;

  /// No description provided for @moduleStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get moduleStorage;

  /// No description provided for @moduleWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get moduleWorkshop;

  /// No description provided for @moduleLounge.
  ///
  /// In en, this message translates to:
  /// **'Lounge'**
  String get moduleLounge;

  /// No description provided for @moduleLaboratory.
  ///
  /// In en, this message translates to:
  /// **'Laboratory'**
  String get moduleLaboratory;

  /// No description provided for @moduleStorageEffect.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get moduleStorageEffect;

  /// No description provided for @moduleWorkshopEffect.
  ///
  /// In en, this message translates to:
  /// **'Repairs to'**
  String get moduleWorkshopEffect;

  /// No description provided for @moduleWorkshopNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get moduleWorkshopNone;

  /// No description provided for @moduleWorkshopComplex.
  ///
  /// In en, this message translates to:
  /// **'complex recipes'**
  String get moduleWorkshopComplex;

  /// No description provided for @moduleLoungeEffect.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get moduleLoungeEffect;

  /// No description provided for @moduleLaboratoryEffect.
  ///
  /// In en, this message translates to:
  /// **'From food and drink'**
  String get moduleLaboratoryEffect;

  /// No description provided for @moduleMaxed.
  ///
  /// In en, this message translates to:
  /// **'maximum'**
  String get moduleMaxed;

  /// No description provided for @shelterBuildStarted.
  ///
  /// In en, this message translates to:
  /// **'Work started. It carries on with the app closed.'**
  String get shelterBuildStarted;

  /// No description provided for @shelterInside.
  ///
  /// In en, this message translates to:
  /// **'You cannot fire from inside your own zone.'**
  String get shelterInside;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get menuSettings;

  /// No description provided for @mapRecentre.
  ///
  /// In en, this message translates to:
  /// **'Back to me'**
  String get mapRecentre;

  /// No description provided for @mapNoPack.
  ///
  /// In en, this message translates to:
  /// **'No map for this area'**
  String get mapNoPack;

  /// No description provided for @mapMarkerEnemy.
  ///
  /// In en, this message translates to:
  /// **'Enemy'**
  String get mapMarkerEnemy;

  /// No description provided for @mapMarkerLoot.
  ///
  /// In en, this message translates to:
  /// **'Loot box'**
  String get mapMarkerLoot;

  /// No description provided for @placePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get placePharmacy;

  /// No description provided for @placeHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware shop'**
  String get placeHardware;

  /// No description provided for @placeGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get placeGrocery;

  /// No description provided for @placeSports.
  ///
  /// In en, this message translates to:
  /// **'Sports shop'**
  String get placeSports;

  /// No description provided for @placeWeapons.
  ///
  /// In en, this message translates to:
  /// **'Gun shop'**
  String get placeWeapons;

  /// No description provided for @placeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get placeLibrary;

  /// No description provided for @placeIndustrial.
  ///
  /// In en, this message translates to:
  /// **'Industrial site'**
  String get placeIndustrial;

  /// No description provided for @placeHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get placeHospital;

  /// No description provided for @placeMilitary.
  ///
  /// In en, this message translates to:
  /// **'Military site'**
  String get placeMilitary;

  /// No description provided for @placeSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get placeSchool;

  /// No description provided for @placeWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get placeWarehouse;

  /// No description provided for @placeCar.
  ///
  /// In en, this message translates to:
  /// **'Abandoned car'**
  String get placeCar;

  /// No description provided for @placeHouse.
  ///
  /// In en, this message translates to:
  /// **'Abandoned house'**
  String get placeHouse;

  /// No description provided for @placeBarn.
  ///
  /// In en, this message translates to:
  /// **'Barn'**
  String get placeBarn;

  /// No description provided for @placeGarage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get placeGarage;

  /// No description provided for @placeWaste.
  ///
  /// In en, this message translates to:
  /// **'Bins'**
  String get placeWaste;

  /// No description provided for @placePicnic.
  ///
  /// In en, this message translates to:
  /// **'Shelter hut'**
  String get placePicnic;

  /// No description provided for @placeHuntingStand.
  ///
  /// In en, this message translates to:
  /// **'Hunting stand'**
  String get placeHuntingStand;

  /// No description provided for @placeWaterPoint.
  ///
  /// In en, this message translates to:
  /// **'Water point'**
  String get placeWaterPoint;

  /// No description provided for @placeRoadside.
  ///
  /// In en, this message translates to:
  /// **'Roadside'**
  String get placeRoadside;

  /// No description provided for @placeAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get placeAmbulance;

  /// No description provided for @placePoliceCar.
  ///
  /// In en, this message translates to:
  /// **'Police car'**
  String get placePoliceCar;

  /// No description provided for @mapMarkerDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped item'**
  String get mapMarkerDropped;

  /// No description provided for @mapMarkerRemains.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get mapMarkerRemains;

  /// No description provided for @remainsTitle.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get remainsTitle;

  /// No description provided for @remainsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search it'**
  String get remainsSearch;

  /// No description provided for @remainsSearched.
  ///
  /// In en, this message translates to:
  /// **'Pockets turned out.'**
  String get remainsSearched;

  /// No description provided for @remainsEmptied.
  ///
  /// In en, this message translates to:
  /// **'Already turned out.'**
  String get remainsEmptied;

  /// No description provided for @remainsUnsearched.
  ///
  /// In en, this message translates to:
  /// **'Nobody has been through it. Come within arm’s reach to search it.'**
  String get remainsUnsearched;

  /// No description provided for @mapMarkerHotspot.
  ///
  /// In en, this message translates to:
  /// **'Decay Zone'**
  String get mapMarkerHotspot;

  /// No description provided for @hotspotTitle.
  ///
  /// In en, this message translates to:
  /// **'Decay Zone'**
  String get hotspotTitle;

  /// No description provided for @hotspotLevelOf.
  ///
  /// In en, this message translates to:
  /// **'Level {level} of {max}'**
  String hotspotLevelOf(int level, int max);

  /// No description provided for @hotspotWhat.
  ///
  /// In en, this message translates to:
  /// **'It grows without you. Every level widens the circle and adds enemies.'**
  String get hotspotWhat;

  /// No description provided for @hotspotIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Barrier'**
  String get hotspotIntegrity;

  /// No description provided for @hotspotEnemies.
  ///
  /// In en, this message translates to:
  /// **'Enemies at once'**
  String get hotspotEnemies;

  /// No description provided for @hotspotRespawn.
  ///
  /// In en, this message translates to:
  /// **'Hatches every'**
  String get hotspotRespawn;

  /// No description provided for @hotspotComposition.
  ///
  /// In en, this message translates to:
  /// **'Sorts'**
  String get hotspotComposition;

  /// No description provided for @hotspotRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get hotspotRadius;

  /// No description provided for @hotspotDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get hotspotDistance;

  /// No description provided for @hotspotInside.
  ///
  /// In en, this message translates to:
  /// **'inside'**
  String get hotspotInside;

  /// No description provided for @hotspotAgitated.
  ///
  /// In en, this message translates to:
  /// **'Furious for another {time}'**
  String hotspotAgitated(String time);

  /// No description provided for @hotspotAgitatedSorts.
  ///
  /// In en, this message translates to:
  /// **'worse sorts'**
  String get hotspotAgitatedSorts;

  /// No description provided for @hotspotAgitatedMore.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% enemies'**
  String hotspotAgitatedMore(int percent);

  /// No description provided for @hotspotAgitatedRespawn.
  ///
  /// In en, this message translates to:
  /// **'hatching ×{times}'**
  String hotspotAgitatedRespawn(int times);

  /// No description provided for @hotspotHowTo.
  ///
  /// In en, this message translates to:
  /// **'Taking it down'**
  String get hotspotHowTo;

  /// No description provided for @hotspotKillInside.
  ///
  /// In en, this message translates to:
  /// **'Body in the circle'**
  String get hotspotKillInside;

  /// No description provided for @hotspotKillOutside.
  ///
  /// In en, this message translates to:
  /// **'Lured out'**
  String get hotspotKillOutside;

  /// No description provided for @hotspotPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String hotspotPoints(int points);

  /// No description provided for @hotspotAtZero.
  ///
  /// In en, this message translates to:
  /// **'Barrier at nought'**
  String get hotspotAtZero;

  /// No description provided for @hotspotAtZeroValue.
  ///
  /// In en, this message translates to:
  /// **'a level off'**
  String get hotspotAtZeroValue;

  /// No description provided for @hotspotThen.
  ///
  /// In en, this message translates to:
  /// **'Then'**
  String get hotspotThen;

  /// No description provided for @hotspotThenValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min of fury'**
  String hotspotThenValue(int minutes);

  /// No description provided for @hotspotRegen.
  ///
  /// In en, this message translates to:
  /// **'Barrier regrows'**
  String get hotspotRegen;

  /// No description provided for @hotspotRegenValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%/h'**
  String hotspotRegenValue(int percent);

  /// No description provided for @hotspotEscape.
  ///
  /// In en, this message translates to:
  /// **'Fury goes out'**
  String get hotspotEscape;

  /// No description provided for @hotspotEscapeValue.
  ///
  /// In en, this message translates to:
  /// **'{metres} m away'**
  String hotspotEscapeValue(int metres);

  /// No description provided for @hotspotCleared.
  ///
  /// In en, this message translates to:
  /// **'Last level'**
  String get hotspotCleared;

  /// No description provided for @hotspotClearedValue.
  ///
  /// In en, this message translates to:
  /// **'quiet for {low}–{high} h'**
  String hotspotClearedValue(int low, int high);

  /// No description provided for @hotspotLevel.
  ///
  /// In en, this message translates to:
  /// **'Decay Zone, level {level}'**
  String hotspotLevel(int level);

  /// No description provided for @mapMarkerShelter.
  ///
  /// In en, this message translates to:
  /// **'Shelter'**
  String get mapMarkerShelter;

  /// No description provided for @mapPlayerLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get mapPlayerLabel;

  /// No description provided for @regionPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get regionPlayNow;

  /// No description provided for @regionStreamed.
  ///
  /// In en, this message translates to:
  /// **'Map from the network'**
  String get regionStreamed;

  /// No description provided for @regionStreamWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Map from the network, not from the phone'**
  String get regionStreamWarnTitle;

  /// No description provided for @regionStreamWarnBody.
  ///
  /// In en, this message translates to:
  /// **'You can start straight away — the game fetches only the pieces of map you are looking at. Two things worth knowing: you need a signal for the whole session, and the host of the map learns roughly where you are. A downloaded pack sends nothing and works in a forest.'**
  String get regionStreamWarnBody;

  /// No description provided for @regionStreamWarnAccept.
  ///
  /// In en, this message translates to:
  /// **'Understood, stream it'**
  String get regionStreamWarnAccept;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get languageTitle;

  /// No description provided for @languageBody.
  ///
  /// In en, this message translates to:
  /// **'The safety rules you are about to read are about traffic and strangers. Pick the language you will actually understand them in.'**
  String get languageBody;

  /// No description provided for @languagePolish.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get languagePolish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeTitle;

  /// No description provided for @themeDaylight.
  ///
  /// In en, this message translates to:
  /// **'Day and night'**
  String get themeDaylight;

  /// No description provided for @themeNowLight.
  ///
  /// In en, this message translates to:
  /// **'now: light'**
  String get themeNowLight;

  /// No description provided for @themeNowDark.
  ///
  /// In en, this message translates to:
  /// **'now: dark'**
  String get themeNowDark;

  /// No description provided for @themeDaylightHint.
  ///
  /// In en, this message translates to:
  /// **'Light between dawn and dusk, dark between dusk and dawn, from where you are standing.'**
  String get themeDaylightHint;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match the system'**
  String get themeSystem;

  /// No description provided for @kindFirearm.
  ///
  /// In en, this message translates to:
  /// **'Firearm'**
  String get kindFirearm;

  /// No description provided for @kindMelee.
  ///
  /// In en, this message translates to:
  /// **'Melee weapon'**
  String get kindMelee;

  /// No description provided for @kindArmor.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get kindArmor;

  /// No description provided for @kindBackpack.
  ///
  /// In en, this message translates to:
  /// **'Backpack'**
  String get kindBackpack;

  /// No description provided for @kindFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get kindFood;

  /// No description provided for @kindMedical.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get kindMedical;

  /// No description provided for @kindLiterature.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get kindLiterature;

  /// No description provided for @kindTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get kindTool;

  /// No description provided for @kindAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get kindAttachment;

  /// No description provided for @kindCrafting.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get kindCrafting;

  /// No description provided for @kindAmmo.
  ///
  /// In en, this message translates to:
  /// **'Ammunition'**
  String get kindAmmo;

  /// No description provided for @kindMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get kindMaterial;

  /// No description provided for @kindMisc.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get kindMisc;

  /// No description provided for @searchArea.
  ///
  /// In en, this message translates to:
  /// **'Search the area'**
  String get searchArea;

  /// No description provided for @searchAreaRunning.
  ///
  /// In en, this message translates to:
  /// **'Looking around…'**
  String get searchAreaRunning;

  /// No description provided for @searchHere.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHere;

  /// No description provided for @searchShallow.
  ///
  /// In en, this message translates to:
  /// **'Quick · 30 s'**
  String get searchShallow;

  /// No description provided for @searchThorough.
  ///
  /// In en, this message translates to:
  /// **'Thorough · 90 s'**
  String get searchThorough;

  /// No description provided for @searchDeep.
  ///
  /// In en, this message translates to:
  /// **'Exhaustive · 180 s'**
  String get searchDeep;

  /// No description provided for @searchCancel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get searchCancel;

  /// No description provided for @searchMoved.
  ///
  /// In en, this message translates to:
  /// **'You moved — the search stopped.'**
  String get searchMoved;

  /// No description provided for @searchLostSignal.
  ///
  /// In en, this message translates to:
  /// **'The search stopped: no trusted position.'**
  String get searchLostSignal;

  /// No description provided for @searchNoise.
  ///
  /// In en, this message translates to:
  /// **'Searching is heard about 80 m away.'**
  String get searchNoise;

  /// No description provided for @searchFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {items}'**
  String searchFound(String items);

  /// No description provided for @searchFoundNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing worth carrying.'**
  String get searchFoundNothing;

  /// No description provided for @searchNoRoom.
  ///
  /// In en, this message translates to:
  /// **'No room for everything — the rest stays.'**
  String get searchNoRoom;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Already emptied.'**
  String get searchEmpty;

  /// No description provided for @searchRevealed.
  ///
  /// In en, this message translates to:
  /// **'Places revealed: {count}'**
  String searchRevealed(int count);

  /// No description provided for @searchNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new here yet.'**
  String get searchNothingNew;

  /// No description provided for @searchTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to see yet.'**
  String get searchTooSoon;

  /// No description provided for @searchTooClose.
  ///
  /// In en, this message translates to:
  /// **'You would be looking at the same ground.'**
  String get searchTooClose;

  /// No description provided for @searchFoundNearby.
  ///
  /// In en, this message translates to:
  /// **'You spot {what} nearby.'**
  String searchFoundNearby(String what);

  /// No description provided for @scoutCar.
  ///
  /// In en, this message translates to:
  /// **'an abandoned car'**
  String get scoutCar;

  /// No description provided for @scoutWaste.
  ///
  /// In en, this message translates to:
  /// **'a skip'**
  String get scoutWaste;

  /// No description provided for @placeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get placeDistance;

  /// No description provided for @placeWayIn.
  ///
  /// In en, this message translates to:
  /// **'Way in'**
  String get placeWayIn;

  /// No description provided for @placeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get placeOpen;

  /// No description provided for @placeSearched.
  ///
  /// In en, this message translates to:
  /// **'Searched'**
  String get placeSearched;

  /// No description provided for @placeUntouched.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get placeUntouched;

  /// No description provided for @placePartly.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of it left'**
  String placePartly(int percent);

  /// No description provided for @placeStripped.
  ///
  /// In en, this message translates to:
  /// **'Stripped — something back in about {hours} h'**
  String placeStripped(int hours);

  /// No description provided for @placeCanStill.
  ///
  /// In en, this message translates to:
  /// **'Still possible'**
  String get placeCanStill;

  /// No description provided for @placeNothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to turn over'**
  String get placeNothingLeft;

  /// No description provided for @placeHolds.
  ///
  /// In en, this message translates to:
  /// **'Holds'**
  String get placeHolds;

  /// No description provided for @combatHurt.
  ///
  /// In en, this message translates to:
  /// **'Hit — {millilitres} ml lost'**
  String combatHurt(int millilitres);

  /// No description provided for @combatExecute.
  ///
  /// In en, this message translates to:
  /// **'Silence'**
  String get combatExecute;

  /// No description provided for @combatStrike.
  ///
  /// In en, this message translates to:
  /// **'Strike'**
  String get combatStrike;

  /// No description provided for @enemyWalker.
  ///
  /// In en, this message translates to:
  /// **'Walker'**
  String get enemyWalker;

  /// No description provided for @enemyLeaper.
  ///
  /// In en, this message translates to:
  /// **'Leaper'**
  String get enemyLeaper;

  /// No description provided for @enemyBrute.
  ///
  /// In en, this message translates to:
  /// **'Brute'**
  String get enemyBrute;

  /// No description provided for @enemyCalm.
  ///
  /// In en, this message translates to:
  /// **'has not seen you'**
  String get enemyCalm;

  /// No description provided for @enemySearching.
  ///
  /// In en, this message translates to:
  /// **'looking for you'**
  String get enemySearching;

  /// No description provided for @enemyHunting.
  ///
  /// In en, this message translates to:
  /// **'coming for you'**
  String get enemyHunting;

  /// No description provided for @enemyHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get enemyHealthy;

  /// No description provided for @enemyWounded.
  ///
  /// In en, this message translates to:
  /// **'Wounded'**
  String get enemyWounded;

  /// No description provided for @enemyCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get enemyCritical;

  /// No description provided for @enemySprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get enemySprint;

  /// No description provided for @combatReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get combatReload;

  /// No description provided for @combatReloading.
  ///
  /// In en, this message translates to:
  /// **'Reloading…'**
  String get combatReloading;

  /// No description provided for @combatReloadBroken.
  ///
  /// In en, this message translates to:
  /// **'Too close — the magazine stays out.'**
  String get combatReloadBroken;

  /// No description provided for @combatRounds.
  ///
  /// In en, this message translates to:
  /// **'{loaded} / {magazine}'**
  String combatRounds(int loaded, int magazine);

  /// No description provided for @combatAiming.
  ///
  /// In en, this message translates to:
  /// **'Aiming…'**
  String get combatAiming;

  /// No description provided for @combatOnTarget.
  ///
  /// In en, this message translates to:
  /// **'On target'**
  String get combatOnTarget;

  /// No description provided for @combatHurtAt.
  ///
  /// In en, this message translates to:
  /// **'Hit — {where}, {millilitres} ml lost'**
  String combatHurtAt(String where, int millilitres);

  /// No description provided for @combatHitAt.
  ///
  /// In en, this message translates to:
  /// **'Hit — {where}, {millilitres} ml'**
  String combatHitAt(String where, int millilitres);

  /// No description provided for @combatExecution.
  ///
  /// In en, this message translates to:
  /// **'Head shot. It is over.'**
  String get combatExecution;

  /// No description provided for @hitHead.
  ///
  /// In en, this message translates to:
  /// **'head'**
  String get hitHead;

  /// No description provided for @hitTorso.
  ///
  /// In en, this message translates to:
  /// **'torso'**
  String get hitTorso;

  /// No description provided for @hitArms.
  ///
  /// In en, this message translates to:
  /// **'arm'**
  String get hitArms;

  /// No description provided for @hitLegs.
  ///
  /// In en, this message translates to:
  /// **'leg'**
  String get hitLegs;

  /// No description provided for @enemyBleeding.
  ///
  /// In en, this message translates to:
  /// **'bleeding'**
  String get enemyBleeding;

  /// No description provided for @combatFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get combatFire;

  /// No description provided for @combatFireAway.
  ///
  /// In en, this message translates to:
  /// **'Fire into the air'**
  String get combatFireAway;

  /// No description provided for @fireAwayUnloaded.
  ///
  /// In en, this message translates to:
  /// **'Nothing chambered.'**
  String get fireAwayUnloaded;

  /// No description provided for @fireAwayInShelter.
  ///
  /// In en, this message translates to:
  /// **'Not from your own ground.'**
  String get fireAwayInShelter;

  /// No description provided for @combatFiredAway.
  ///
  /// In en, this message translates to:
  /// **'A shot into the air. Something will come and look.'**
  String get combatFiredAway;

  /// No description provided for @combatChance.
  ///
  /// In en, this message translates to:
  /// **'{percent}% hit'**
  String combatChance(int percent);

  /// No description provided for @combatDistance.
  ///
  /// In en, this message translates to:
  /// **'{metres} m'**
  String combatDistance(int metres);

  /// No description provided for @combatNoWeapon.
  ///
  /// In en, this message translates to:
  /// **'Nothing in hand.'**
  String get combatNoWeapon;

  /// No description provided for @combatNoAmmo.
  ///
  /// In en, this message translates to:
  /// **'No rounds for this.'**
  String get combatNoAmmo;

  /// No description provided for @reloadNoMagazine.
  ///
  /// In en, this message translates to:
  /// **'No magazine that fits.'**
  String get reloadNoMagazine;

  /// No description provided for @reloadNothingFuller.
  ///
  /// In en, this message translates to:
  /// **'Nothing fuller to swap in.'**
  String get reloadNothingFuller;

  /// No description provided for @reloadAlreadyFull.
  ///
  /// In en, this message translates to:
  /// **'Already loaded.'**
  String get reloadAlreadyFull;

  /// No description provided for @magazineFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get magazineFill;

  /// No description provided for @magazineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Unload'**
  String get magazineEmpty;

  /// No description provided for @slotMagazine.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get slotMagazine;

  /// No description provided for @slotOptic.
  ///
  /// In en, this message translates to:
  /// **'Optic'**
  String get slotOptic;

  /// No description provided for @slotBarrel.
  ///
  /// In en, this message translates to:
  /// **'Barrel'**
  String get slotBarrel;

  /// No description provided for @slotGrip.
  ///
  /// In en, this message translates to:
  /// **'Grip'**
  String get slotGrip;

  /// No description provided for @slotRail.
  ///
  /// In en, this message translates to:
  /// **'Rail'**
  String get slotRail;

  /// No description provided for @slotEmpty.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get slotEmpty;

  /// No description provided for @craftTitle.
  ///
  /// In en, this message translates to:
  /// **'Making'**
  String get craftTitle;

  /// No description provided for @craftAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get craftAll;

  /// No description provided for @craftOnlyPossible.
  ///
  /// In en, this message translates to:
  /// **'Only what can be made now'**
  String get craftOnlyPossible;

  /// No description provided for @craftNoneHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here can be made yet.'**
  String get craftNoneHere;

  /// No description provided for @actionBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy: {what}'**
  String actionBusy(String what);

  /// No description provided for @actionEating.
  ///
  /// In en, this message translates to:
  /// **'Eating: {item}'**
  String actionEating(String item);

  /// No description provided for @actionDrinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking: {item}'**
  String actionDrinking(String item);

  /// No description provided for @actionUsing.
  ///
  /// In en, this message translates to:
  /// **'Using: {item}'**
  String actionUsing(String item);

  /// No description provided for @actionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading: {item}'**
  String actionLoading(String item);

  /// No description provided for @actionUnloading.
  ///
  /// In en, this message translates to:
  /// **'Unloading: {item}'**
  String actionUnloading(String item);

  /// No description provided for @craftBenchFree.
  ///
  /// In en, this message translates to:
  /// **'Nothing on it'**
  String get craftBenchFree;

  /// No description provided for @craftTakeApart.
  ///
  /// In en, this message translates to:
  /// **'Take apart'**
  String get craftTakeApart;

  /// No description provided for @craftPartlyApart.
  ///
  /// In en, this message translates to:
  /// **'partly apart'**
  String get craftPartlyApart;

  /// No description provided for @craftStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get craftStop;

  /// No description provided for @craftPausedAway.
  ///
  /// In en, this message translates to:
  /// **'The work is stopped — go back to the shelter or camp.'**
  String get craftPausedAway;

  /// No description provided for @craftStopKeepsWork.
  ///
  /// In en, this message translates to:
  /// **'Stopping keeps the work. The piece stays open.'**
  String get craftStopKeepsWork;

  /// No description provided for @craftStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped. What was done is done.'**
  String get craftStopped;

  /// No description provided for @craftTakeApartRunning.
  ///
  /// In en, this message translates to:
  /// **'Taking it apart'**
  String get craftTakeApartRunning;

  /// No description provided for @craftDone.
  ///
  /// In en, this message translates to:
  /// **'Finished on the bench.'**
  String get craftDone;

  /// No description provided for @craftDismantleWarning.
  ///
  /// In en, this message translates to:
  /// **'It will not come back. You get: {gives}. {minutes} minutes.'**
  String craftDismantleWarning(String gives, int minutes);

  /// No description provided for @craftMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get craftMake;

  /// No description provided for @craftCancel.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get craftCancel;

  /// No description provided for @craftCancelWarning.
  ///
  /// In en, this message translates to:
  /// **'The materials are gone. They went into it.'**
  String get craftCancelWarning;

  /// No description provided for @craftNeedsTool.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get craftNeedsTool;

  /// No description provided for @craftNoTool.
  ///
  /// In en, this message translates to:
  /// **'Nothing here would do the job.'**
  String get craftNoTool;

  /// No description provided for @craftNoMaterials.
  ///
  /// In en, this message translates to:
  /// **'Not enough of something.'**
  String get craftNoMaterials;

  /// No description provided for @craftBenchBusy.
  ///
  /// In en, this message translates to:
  /// **'Something is already on the bench.'**
  String get craftBenchBusy;

  /// No description provided for @craftNotAtShelter.
  ///
  /// In en, this message translates to:
  /// **'Not here — at the shelter.'**
  String get craftNotAtShelter;

  /// No description provided for @craftNothingBack.
  ///
  /// In en, this message translates to:
  /// **'There is nothing in it worth getting back.'**
  String get craftNothingBack;

  /// No description provided for @craftNeedsWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop L{level}'**
  String craftNeedsWorkshop(int level);

  /// No description provided for @craftMaking.
  ///
  /// In en, this message translates to:
  /// **'Making: {item}'**
  String craftMaking(String item);

  /// No description provided for @craftTakingApart.
  ///
  /// In en, this message translates to:
  /// **'Taking apart: {item}'**
  String craftTakingApart(String item);

  /// No description provided for @attachmentChoose.
  ///
  /// In en, this message translates to:
  /// **'{count} to choose from'**
  String attachmentChoose(int count);

  /// No description provided for @reloadFitting.
  ///
  /// In en, this message translates to:
  /// **'Fitting magazine'**
  String get reloadFitting;

  /// No description provided for @reloadSwapping.
  ///
  /// In en, this message translates to:
  /// **'Changing magazine'**
  String get reloadSwapping;

  /// No description provided for @reloadFeeding.
  ///
  /// In en, this message translates to:
  /// **'Loading rounds'**
  String get reloadFeeding;

  /// No description provided for @magazineRounds.
  ///
  /// In en, this message translates to:
  /// **'{rounds} / {capacity}'**
  String magazineRounds(int rounds, int capacity);

  /// No description provided for @combatHit.
  ///
  /// In en, this message translates to:
  /// **'Hit — {millilitres} ml'**
  String combatHit(int millilitres);

  /// No description provided for @combatMiss.
  ///
  /// In en, this message translates to:
  /// **'Missed.'**
  String get combatMiss;

  /// No description provided for @combatStillHunted.
  ///
  /// In en, this message translates to:
  /// **'They are still looking for you.'**
  String get combatStillHunted;

  /// No description provided for @combatDown.
  ///
  /// In en, this message translates to:
  /// **'It went down.'**
  String get combatDown;

  /// No description provided for @combatHeard.
  ///
  /// In en, this message translates to:
  /// **'Heard {metres} m away.'**
  String combatHeard(int metres);

  /// No description provided for @errorWeapon.
  ///
  /// In en, this message translates to:
  /// **'WEAPON'**
  String get errorWeapon;

  /// No description provided for @errorSkill.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE'**
  String get errorSkill;

  /// No description provided for @errorHeart.
  ///
  /// In en, this message translates to:
  /// **'PULSE'**
  String get errorHeart;

  /// No description provided for @errorMovement.
  ///
  /// In en, this message translates to:
  /// **'MOVEMENT'**
  String get errorMovement;

  /// No description provided for @errorTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get errorTarget;

  /// No description provided for @errorCondition.
  ///
  /// In en, this message translates to:
  /// **'CONDITION'**
  String get errorCondition;

  /// No description provided for @barrierDoor.
  ///
  /// In en, this message translates to:
  /// **'Locked door'**
  String get barrierDoor;

  /// No description provided for @barrierPadlock.
  ///
  /// In en, this message translates to:
  /// **'Padlock'**
  String get barrierPadlock;

  /// No description provided for @barrierWindow.
  ///
  /// In en, this message translates to:
  /// **'Boarded window'**
  String get barrierWindow;

  /// No description provided for @breachForce.
  ///
  /// In en, this message translates to:
  /// **'Force it'**
  String get breachForce;

  /// No description provided for @breachPry.
  ///
  /// In en, this message translates to:
  /// **'Lever it'**
  String get breachPry;

  /// No description provided for @breachPick.
  ///
  /// In en, this message translates to:
  /// **'Pick it'**
  String get breachPick;

  /// No description provided for @breachBareHands.
  ///
  /// In en, this message translates to:
  /// **'Bare hands'**
  String get breachBareHands;

  /// No description provided for @breachNoTool.
  ///
  /// In en, this message translates to:
  /// **'No tool for this — a padlock needs one.'**
  String get breachNoTool;

  /// No description provided for @breachDone.
  ///
  /// In en, this message translates to:
  /// **'You are in.'**
  String get breachDone;

  /// No description provided for @breachNoise.
  ///
  /// In en, this message translates to:
  /// **'{metres} m of noise'**
  String breachNoise(int metres);

  /// No description provided for @fieldRestingHrKnown.
  ///
  /// In en, this message translates to:
  /// **'I know my resting heart rate'**
  String get fieldRestingHrKnown;

  /// No description provided for @fieldRestingHr.
  ///
  /// In en, this message translates to:
  /// **'Resting heart rate'**
  String get fieldRestingHr;

  /// No description provided for @fieldRestingHrHint.
  ///
  /// In en, this message translates to:
  /// **'Measured sitting still. Left off, the game estimates it from your age and build — and gets it wrong for anyone whose heart is slower or faster than average. Stays on this device.'**
  String get fieldRestingHrHint;

  /// No description provided for @errRestingHrRange.
  ///
  /// In en, this message translates to:
  /// **'Between 35 and 110 bpm'**
  String get errRestingHrRange;

  /// No description provided for @droppedHere.
  ///
  /// In en, this message translates to:
  /// **'On the ground'**
  String get droppedHere;

  /// No description provided for @droppedTake.
  ///
  /// In en, this message translates to:
  /// **'Pick up'**
  String get droppedTake;

  /// No description provided for @droppedTooFar.
  ///
  /// In en, this message translates to:
  /// **'Too far to reach into.'**
  String get droppedTooFar;

  /// No description provided for @droppedExpires.
  ///
  /// In en, this message translates to:
  /// **'{hours} h left'**
  String droppedExpires(int hours);

  /// No description provided for @droppedNoRoom.
  ///
  /// In en, this message translates to:
  /// **'No room in the pack.'**
  String get droppedNoRoom;

  /// Shown in the ground list once everything within reach has been picked up.
  ///
  /// In en, this message translates to:
  /// **'Nothing here now.'**
  String get groundEmpty;

  /// No description provided for @noteRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get noteRead;

  /// No description provided for @noteClose.
  ///
  /// In en, this message translates to:
  /// **'Put it back'**
  String get noteClose;

  /// No description provided for @inventoryTakeOff.
  ///
  /// In en, this message translates to:
  /// **'Take off'**
  String get inventoryTakeOff;

  /// No description provided for @inventoryDropAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryDropAll;

  /// No description provided for @inventoryUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get inventoryUse;

  /// How much of a part-used item is left.
  ///
  /// In en, this message translates to:
  /// **'{percent}% left'**
  String inventoryPortion(int percent);

  /// No description provided for @inventoryWear.
  ///
  /// In en, this message translates to:
  /// **'Put on'**
  String get inventoryWear;

  /// No description provided for @inventoryEmptySlot.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get inventoryEmptySlot;

  /// No description provided for @inventoryUsing.
  ///
  /// In en, this message translates to:
  /// **'{action}…'**
  String inventoryUsing(String action);

  /// No description provided for @inventoryUsed.
  ///
  /// In en, this message translates to:
  /// **'{item} — used'**
  String inventoryUsed(String item);

  /// No description provided for @inventoryNoWound.
  ///
  /// In en, this message translates to:
  /// **'Nothing to dress.'**
  String get inventoryNoWound;

  /// No description provided for @inventoryWrongDressing.
  ///
  /// In en, this message translates to:
  /// **'That dressing is not enough for this wound.'**
  String get inventoryWrongDressing;

  /// No description provided for @slotHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get slotHead;

  /// No description provided for @slotTorsoBase.
  ///
  /// In en, this message translates to:
  /// **'Base layer'**
  String get slotTorsoBase;

  /// No description provided for @slotTorsoMid.
  ///
  /// In en, this message translates to:
  /// **'Mid layer'**
  String get slotTorsoMid;

  /// No description provided for @slotTorsoOuter.
  ///
  /// In en, this message translates to:
  /// **'Outer layer'**
  String get slotTorsoOuter;

  /// No description provided for @slotTorsoArmor.
  ///
  /// In en, this message translates to:
  /// **'Body armour'**
  String get slotTorsoArmor;

  /// No description provided for @slotArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get slotArms;

  /// No description provided for @slotHands.
  ///
  /// In en, this message translates to:
  /// **'Hands'**
  String get slotHands;

  /// No description provided for @slotLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get slotLegs;

  /// No description provided for @slotFeet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get slotFeet;

  /// No description provided for @slotBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get slotBack;

  /// No description provided for @slotHand.
  ///
  /// In en, this message translates to:
  /// **'In hand'**
  String get slotHand;

  /// No description provided for @statEnergy.
  ///
  /// In en, this message translates to:
  /// **'Muzzle energy'**
  String get statEnergy;

  /// No description provided for @statMoa.
  ///
  /// In en, this message translates to:
  /// **'Dispersion'**
  String get statMoa;

  /// No description provided for @statMagazine.
  ///
  /// In en, this message translates to:
  /// **'rds'**
  String get statMagazine;

  /// No description provided for @statReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get statReload;

  /// No description provided for @statRange.
  ///
  /// In en, this message translates to:
  /// **'Effective range'**
  String get statRange;

  /// No description provided for @statNoise.
  ///
  /// In en, this message translates to:
  /// **'Heard from'**
  String get statNoise;

  /// No description provided for @statBleed.
  ///
  /// In en, this message translates to:
  /// **'Blood loss per hit'**
  String get statBleed;

  /// No description provided for @statSwing.
  ///
  /// In en, this message translates to:
  /// **'Swing'**
  String get statSwing;

  /// No description provided for @statReach.
  ///
  /// In en, this message translates to:
  /// **'Reach'**
  String get statReach;

  /// No description provided for @statStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength needed'**
  String get statStrength;

  /// No description provided for @statInsulation.
  ///
  /// In en, this message translates to:
  /// **'Insulation'**
  String get statInsulation;

  /// No description provided for @statProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get statProtection;

  /// No description provided for @statCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get statCoverage;

  /// No description provided for @statCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get statCapacity;

  /// No description provided for @statCarry.
  ///
  /// In en, this message translates to:
  /// **'Carry bonus'**
  String get statCarry;

  /// No description provided for @statKcal.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get statKcal;

  /// No description provided for @statWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get statWater;

  /// No description provided for @statEatTime.
  ///
  /// In en, this message translates to:
  /// **'Time to eat'**
  String get statEatTime;

  /// No description provided for @statUseTime.
  ///
  /// In en, this message translates to:
  /// **'Time to use'**
  String get statUseTime;

  /// No description provided for @statUses.
  ///
  /// In en, this message translates to:
  /// **'Uses'**
  String get statUses;

  /// No description provided for @statBlood.
  ///
  /// In en, this message translates to:
  /// **'Restores blood'**
  String get statBlood;

  /// No description provided for @statPagesMin.
  ///
  /// In en, this message translates to:
  /// **'Pages, fewest'**
  String get statPagesMin;

  /// No description provided for @statPagesMax.
  ///
  /// In en, this message translates to:
  /// **'Pages, most'**
  String get statPagesMax;

  /// No description provided for @statXpPerPage.
  ///
  /// In en, this message translates to:
  /// **'XP a page'**
  String get statXpPerPage;

  /// No description provided for @statLight.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get statLight;

  /// No description provided for @statBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get statBattery;

  /// No description provided for @statCraftTime.
  ///
  /// In en, this message translates to:
  /// **'Crafting time'**
  String get statCraftTime;

  /// No description provided for @statSearchBonus.
  ///
  /// In en, this message translates to:
  /// **'Search radius'**
  String get statSearchBonus;

  /// No description provided for @statMass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get statMass;

  /// No description provided for @statBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get statBulk;

  /// No description provided for @statSettle.
  ///
  /// In en, this message translates to:
  /// **'Settling'**
  String get statSettle;

  /// No description provided for @statCraftSkill.
  ///
  /// In en, this message translates to:
  /// **'Craft skill'**
  String get statCraftSkill;

  /// How worn one copy of an item is, in percent.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get statCondition;

  /// No description provided for @attachmentsFitted.
  ///
  /// In en, this message translates to:
  /// **'Fitted'**
  String get attachmentsFitted;

  /// No description provided for @attachmentsFree.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String attachmentsFree(int count);

  /// No description provided for @attachmentsNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing fitted'**
  String get attachmentsNone;

  /// No description provided for @attachmentFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get attachmentFit;

  /// No description provided for @attachmentRefused.
  ///
  /// In en, this message translates to:
  /// **'It will not go on that.'**
  String get attachmentRefused;

  /// No description provided for @attachmentWrongWeapon.
  ///
  /// In en, this message translates to:
  /// **'It does not fit this weapon.'**
  String get attachmentWrongWeapon;

  /// No description provided for @attachmentAlreadyOn.
  ///
  /// In en, this message translates to:
  /// **'One of those is already on it.'**
  String get attachmentAlreadyOn;

  /// No description provided for @attachmentNoRail.
  ///
  /// In en, this message translates to:
  /// **'No rail left on this weapon.'**
  String get attachmentNoRail;

  /// No description provided for @attachmentRemove.
  ///
  /// In en, this message translates to:
  /// **'Take off'**
  String get attachmentRemove;

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get itemDetails;

  /// No description provided for @readingFinished.
  ///
  /// In en, this message translates to:
  /// **'read'**
  String get readingFinished;

  /// No description provided for @itemSalvageTitle.
  ///
  /// In en, this message translates to:
  /// **'If taken apart'**
  String get itemSalvageTitle;

  /// No description provided for @itemSalvageNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing would be left of it.'**
  String get itemSalvageNothing;

  /// No description provided for @itemSalvageTakes.
  ///
  /// In en, this message translates to:
  /// **'takes {time}'**
  String itemSalvageTakes(String time);

  /// No description provided for @itemCompare.
  ///
  /// In en, this message translates to:
  /// **'Compared with'**
  String get itemCompare;

  /// No description provided for @itemCarried.
  ///
  /// In en, this message translates to:
  /// **'carried'**
  String get itemCarried;

  /// No description provided for @itemWorn.
  ///
  /// In en, this message translates to:
  /// **'worn'**
  String get itemWorn;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your pack is empty.'**
  String get inventoryEmpty;

  /// No description provided for @inventoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search buildings and open places to find something worth carrying.'**
  String get inventoryEmptyHint;

  /// No description provided for @inventoryWorn.
  ///
  /// In en, this message translates to:
  /// **'Worn'**
  String get inventoryWorn;

  /// No description provided for @inventoryPack.
  ///
  /// In en, this message translates to:
  /// **'In the pack'**
  String get inventoryPack;

  /// No description provided for @packOrderKind.
  ///
  /// In en, this message translates to:
  /// **'by kind'**
  String get packOrderKind;

  /// No description provided for @packOrderName.
  ///
  /// In en, this message translates to:
  /// **'by name'**
  String get packOrderName;

  /// No description provided for @packOrderMass.
  ///
  /// In en, this message translates to:
  /// **'by weight'**
  String get packOrderMass;

  /// No description provided for @packOrderWhat.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get packOrderWhat;

  /// No description provided for @inventoryBackpack.
  ///
  /// In en, this message translates to:
  /// **'Backpack'**
  String get inventoryBackpack;

  /// No description provided for @inventoryNoBackpack.
  ///
  /// In en, this message translates to:
  /// **'Pockets only'**
  String get inventoryNoBackpack;

  /// No description provided for @inventoryDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get inventoryDrop;

  /// No description provided for @inventoryOverComfort.
  ///
  /// In en, this message translates to:
  /// **'Over a comfortable load: every step costs more.'**
  String get inventoryOverComfort;

  /// No description provided for @inventoryLost.
  ///
  /// In en, this message translates to:
  /// **'{count} items were lost with a removed content pack.'**
  String inventoryLost(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsMaps.
  ///
  /// In en, this message translates to:
  /// **'Offline maps'**
  String get settingsMaps;

  /// No description provided for @settingsSimulator.
  ///
  /// In en, this message translates to:
  /// **'GPS simulator'**
  String get settingsSimulator;

  /// No description provided for @settingsSimulatorBody.
  ///
  /// In en, this message translates to:
  /// **'The game then walks a recorded track instead of your real position. For testing only.'**
  String get settingsSimulatorBody;

  /// No description provided for @settingsRestartNeeded.
  ///
  /// In en, this message translates to:
  /// **'The change takes effect the next time the game starts.'**
  String get settingsRestartNeeded;

  /// No description provided for @relocationTitle.
  ///
  /// In en, this message translates to:
  /// **'I blacked out again'**
  String get relocationTitle;

  /// No description provided for @relocationBody.
  ///
  /// In en, this message translates to:
  /// **'No idea how I got here. The last thing I remember was some {km} km away.'**
  String relocationBody(int km);

  /// No description provided for @relocationNoMapBody.
  ///
  /// In en, this message translates to:
  /// **'No idea how I got here. The last thing I remember was some {km} km away — and I have no map of this place.'**
  String relocationNoMapBody(int km);

  /// No description provided for @relocationDismiss.
  ///
  /// In en, this message translates to:
  /// **'So be it'**
  String get relocationDismiss;

  /// No description provided for @permTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permTitle;

  /// No description provided for @permLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permLocation;

  /// No description provided for @permLocationGranted.
  ///
  /// In en, this message translates to:
  /// **'Full — the game counts with the screen off too'**
  String get permLocationGranted;

  /// No description provided for @permLocationForeground.
  ///
  /// In en, this message translates to:
  /// **'Only while the game is on screen'**
  String get permLocationForeground;

  /// No description provided for @permLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'None — there is no game without it'**
  String get permLocationDenied;

  /// No description provided for @permLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on this phone'**
  String get permLocationOff;

  /// No description provided for @permBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery optimisation'**
  String get permBattery;

  /// No description provided for @permBatteryOn.
  ///
  /// In en, this message translates to:
  /// **'On — Android may suspend counting in the background'**
  String get permBatteryOn;

  /// No description provided for @permBatteryOff.
  ///
  /// In en, this message translates to:
  /// **'Off for this game — as it should be'**
  String get permBatteryOff;

  /// No description provided for @permBatteryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get permBatteryUnknown;

  /// No description provided for @permFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get permFix;

  /// No description provided for @permStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you go walking'**
  String get permStartupTitle;

  /// No description provided for @permStartupBody.
  ///
  /// In en, this message translates to:
  /// **'To count a walk with the phone in your pocket, the game needs background location and battery optimisation switched off. Without them it only runs while it is on screen.'**
  String get permStartupBody;

  /// No description provided for @permStartupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get permStartupLater;

  /// No description provided for @permStartupFix.
  ///
  /// In en, this message translates to:
  /// **'Set it up'**
  String get permStartupFix;

  /// No description provided for @mapWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding you'**
  String get mapWaitingTitle;

  /// No description provided for @mapWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The game waits for a signal before drawing the map — otherwise it would show a place you are not.'**
  String get mapWaitingBody;

  /// No description provided for @salvageTitle.
  ///
  /// In en, this message translates to:
  /// **'Taking apart'**
  String get salvageTitle;

  /// No description provided for @salvagePick.
  ///
  /// In en, this message translates to:
  /// **'Tick what goes to pieces. They go in order, one after another.'**
  String get salvagePick;

  /// No description provided for @salvageNothingWorth.
  ///
  /// In en, this message translates to:
  /// **'Nothing here would leave anything behind.'**
  String get salvageNothingWorth;

  /// No description provided for @salvageChosen.
  ///
  /// In en, this message translates to:
  /// **'Picked: {count}'**
  String salvageChosen(int count);

  /// No description provided for @salvageHowMany.
  ///
  /// In en, this message translates to:
  /// **'How many: {chosen} of {total}'**
  String salvageHowMany(int chosen, int total);

  /// No description provided for @salvageOnePiece.
  ///
  /// In en, this message translates to:
  /// **'One of {total}. The rest stay as they are.'**
  String salvageOnePiece(int total);

  /// No description provided for @salvageSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get salvageSummaryTitle;

  /// No description provided for @salvageGone.
  ///
  /// In en, this message translates to:
  /// **'This will not come back. What is left of it is materials.'**
  String get salvageGone;

  /// No description provided for @salvageYouGet.
  ///
  /// In en, this message translates to:
  /// **'You get'**
  String get salvageYouGet;

  /// No description provided for @salvageTakes.
  ///
  /// In en, this message translates to:
  /// **'{time} in all'**
  String salvageTakes(String time);

  /// No description provided for @salvageInOrder.
  ///
  /// In en, this message translates to:
  /// **'In order. Stopped half way, what is finished stays finished and the rest is untouched.'**
  String get salvageInOrder;

  /// No description provided for @salvageWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting its turn'**
  String get salvageWaiting;

  /// No description provided for @salvageBatchRunning.
  ///
  /// In en, this message translates to:
  /// **'Taking apart: {item} (+{rest})'**
  String salvageBatchRunning(String item, int rest);

  /// No description provided for @crashOne.
  ///
  /// In en, this message translates to:
  /// **'Something broke'**
  String get crashOne;

  /// No description provided for @crashMany.
  ///
  /// In en, this message translates to:
  /// **'Broke {count} times'**
  String crashMany(int count);

  /// No description provided for @crashCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy the trace'**
  String get crashCopy;

  /// No description provided for @crashClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get crashClear;

  /// No description provided for @crashCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it to me.'**
  String get crashCopied;

  /// No description provided for @crashHung.
  ///
  /// In en, this message translates to:
  /// **'The game stopped answering'**
  String get crashHung;

  /// No description provided for @salvageWornFirst.
  ///
  /// In en, this message translates to:
  /// **'You are wearing it — take it off first.'**
  String get salvageWornFirst;

  /// No description provided for @goalPin.
  ///
  /// In en, this message translates to:
  /// **'Pin as a goal'**
  String get goalPin;

  /// No description provided for @goalPinned.
  ///
  /// In en, this message translates to:
  /// **'Goal pinned: {item}'**
  String goalPinned(String item);

  /// No description provided for @salvageStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String salvageStartsIn(String time);

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get journalEmpty;

  /// No description provided for @journalDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String journalDay(int day);

  /// No description provided for @journalSearched.
  ///
  /// In en, this message translates to:
  /// **'Searched: {what}'**
  String journalSearched(String what);

  /// No description provided for @journalFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {what}'**
  String journalFound(String what);

  /// No description provided for @journalFoundNothing.
  ///
  /// In en, this message translates to:
  /// **'Found nothing'**
  String get journalFoundNothing;

  /// No description provided for @journalOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened: {what}'**
  String journalOpened(String what);

  /// No description provided for @journalFought.
  ///
  /// In en, this message translates to:
  /// **'Fought: {what}'**
  String journalFought(String what);

  /// No description provided for @journalKilled.
  ///
  /// In en, this message translates to:
  /// **'Killed: {what}'**
  String journalKilled(String what);

  /// No description provided for @journalHurt.
  ///
  /// In en, this message translates to:
  /// **'Hit by: {what}'**
  String journalHurt(String what);

  /// No description provided for @journalAte.
  ///
  /// In en, this message translates to:
  /// **'Eating: {what}'**
  String journalAte(String what);

  /// No description provided for @journalDrank.
  ///
  /// In en, this message translates to:
  /// **'Drinking: {what}'**
  String journalDrank(String what);

  /// No description provided for @journalTreated.
  ///
  /// In en, this message translates to:
  /// **'Dressing: {what}'**
  String journalTreated(String what);

  /// No description provided for @journalSlept.
  ///
  /// In en, this message translates to:
  /// **'Asleep'**
  String get journalSlept;

  /// No description provided for @journalWoke.
  ///
  /// In en, this message translates to:
  /// **'Awake'**
  String get journalWoke;

  /// No description provided for @journalRead.
  ///
  /// In en, this message translates to:
  /// **'Reading: {what}'**
  String journalRead(String what);

  /// No description provided for @journalBuilt.
  ///
  /// In en, this message translates to:
  /// **'Building: {what}'**
  String journalBuilt(String what);

  /// No description provided for @journalCrafted.
  ///
  /// In en, this message translates to:
  /// **'Made: {what}'**
  String journalCrafted(String what);

  /// No description provided for @journalSalvaged.
  ///
  /// In en, this message translates to:
  /// **'Stripped: {what}'**
  String journalSalvaged(String what);

  /// No description provided for @journalCameHome.
  ///
  /// In en, this message translates to:
  /// **'Back at the shelter'**
  String get journalCameHome;

  /// No description provided for @journalWentOut.
  ///
  /// In en, this message translates to:
  /// **'Left the shelter'**
  String get journalWentOut;

  /// No description provided for @journalLearned.
  ///
  /// In en, this message translates to:
  /// **'Skill: {what}'**
  String journalLearned(String what);

  /// No description provided for @journalZoneGrew.
  ///
  /// In en, this message translates to:
  /// **'A Decay Zone grew to level {level}'**
  String journalZoneGrew(int level);

  /// No description provided for @journalZoneCleared.
  ///
  /// In en, this message translates to:
  /// **'Decay Zone broken'**
  String get journalZoneCleared;

  /// No description provided for @zoneGrewTitle.
  ///
  /// In en, this message translates to:
  /// **'A zone grew'**
  String get zoneGrewTitle;

  /// No description provided for @zoneGrewBody.
  ///
  /// In en, this message translates to:
  /// **'The Decay Zone {where} reached level {level}. Radius {radius} m, up to {enemies} of them at once.'**
  String zoneGrewBody(String where, int level, int radius, int enemies);

  /// No description provided for @zoneGrewAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String zoneGrewAway(String distance);

  /// No description provided for @zoneGrewNear.
  ///
  /// In en, this message translates to:
  /// **'nearby'**
  String get zoneGrewNear;

  /// No description provided for @chronicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Chronicle'**
  String get chronicleTitle;

  /// No description provided for @chronicleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No streak has ended yet. That is a good sign.'**
  String get chronicleEmpty;

  /// No description provided for @chronicleBest.
  ///
  /// In en, this message translates to:
  /// **'Longest streak: {days} days'**
  String chronicleBest(int days);

  /// No description provided for @chronicleRunDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String chronicleRunDays(int days);

  /// No description provided for @chronicleHardcore.
  ///
  /// In en, this message translates to:
  /// **'hardcore'**
  String get chronicleHardcore;

  /// No description provided for @chronicleSoftcore.
  ///
  /// In en, this message translates to:
  /// **'softcore'**
  String get chronicleSoftcore;

  /// No description provided for @journalBlackout.
  ///
  /// In en, this message translates to:
  /// **'Blacked out'**
  String get journalBlackout;

  /// No description provided for @journalCount.
  ///
  /// In en, this message translates to:
  /// **'{name} ×{count}'**
  String journalCount(String name, int count);

  /// No description provided for @journalStartedBuild.
  ///
  /// In en, this message translates to:
  /// **'Started building: {what}'**
  String journalStartedBuild(String what);

  /// No description provided for @journalStartedCraft.
  ///
  /// In en, this message translates to:
  /// **'Started making: {what}'**
  String journalStartedCraft(String what);

  /// No description provided for @journalStartedSalvage.
  ///
  /// In en, this message translates to:
  /// **'Started stripping: {what}'**
  String journalStartedSalvage(String what);

  /// No description provided for @hudSunrise.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get hudSunrise;

  /// No description provided for @hudSunset.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get hudSunset;

  /// No description provided for @skillLevelUp.
  ///
  /// In en, this message translates to:
  /// **'{skill}: level {level}'**
  String skillLevelUp(String skill, int level);

  /// No description provided for @moduleLoungeReading.
  ///
  /// In en, this message translates to:
  /// **'reading'**
  String get moduleLoungeReading;

  /// No description provided for @actionReading.
  ///
  /// In en, this message translates to:
  /// **'Reading: {what}'**
  String actionReading(String what);

  /// No description provided for @actionReadDone.
  ///
  /// In en, this message translates to:
  /// **'Finished: {what}'**
  String actionReadDone(String what);

  /// No description provided for @actionReadingPage.
  ///
  /// In en, this message translates to:
  /// **'{what} — page {page}/{pages}'**
  String actionReadingPage(String what, int page, int pages);

  /// No description provided for @combatHurtAway.
  ///
  /// In en, this message translates to:
  /// **'They were on you while the screen was off: {blows} blows'**
  String combatHurtAway(int blows);
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
