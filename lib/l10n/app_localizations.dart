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
