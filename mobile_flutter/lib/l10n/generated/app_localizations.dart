import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WellWell'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMeds.
  ///
  /// In en, this message translates to:
  /// **'Meds'**
  String get navMeds;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get navSafety;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get commonSignIn;

  /// No description provided for @commonSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get commonSignUp;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your medications and today\'s reminders.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your medication list stays private to you unless you choose to share it.'**
  String get authSignUpSubtitle;

  /// No description provided for @authUseDemoAccount.
  ///
  /// In en, this message translates to:
  /// **'Use the demo account'**
  String get authUseDemoAccount;

  /// No description provided for @authDemoOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in and sign up are not available. Please use the demo account.'**
  String get authDemoOnlyMessage;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authName;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again.'**
  String get authSessionExpired;

  /// No description provided for @authFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get authFieldsRequired;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Follow the system setting, or always use light or dark.'**
  String get settingsAppearanceHint;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language WellWell uses for you. This also changes what\'s sent to you by email.'**
  String get settingsLanguageHint;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach WellWell. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailInUse;

  /// No description provided for @errorMedicationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This medication is not in your list.'**
  String get errorMedicationNotFound;

  /// No description provided for @errorPleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorPleaseSignInAgain;

  /// No description provided for @homeGreetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeGreetingFallback;

  /// No description provided for @homeInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get homeInsights;

  /// No description provided for @homeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeHistory;

  /// No description provided for @homeScanMedication.
  ///
  /// In en, this message translates to:
  /// **'Scan Medication'**
  String get homeScanMedication;

  /// No description provided for @homeTodaysMedications.
  ///
  /// In en, this message translates to:
  /// **'Today\'s medications'**
  String get homeTodaysMedications;

  /// No description provided for @homeNoDosesToday.
  ///
  /// In en, this message translates to:
  /// **'No doses are scheduled for today.'**
  String get homeNoDosesToday;

  /// No description provided for @homeNoRemindersYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get homeNoRemindersYetTitle;

  /// No description provided for @homeNoRemindersYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a medication and confirm its reminder times to see your day here.'**
  String get homeNoRemindersYetDescription;

  /// No description provided for @homeAllDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All done for today 🎉'**
  String get homeAllDoneTitle;

  /// No description provided for @homeAllDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve taken or accounted for every dose scheduled for today.'**
  String get homeAllDoneMessage;

  /// No description provided for @homeSafetyFindings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 safety finding to review} other{{count} safety findings to review}}'**
  String homeSafetyFindings(int count);

  /// No description provided for @profileShareAccess.
  ///
  /// In en, this message translates to:
  /// **'Share access'**
  String get profileShareAccess;

  /// No description provided for @profileSharedWithYou.
  ///
  /// In en, this message translates to:
  /// **'Shared with you'**
  String get profileSharedWithYou;

  /// No description provided for @profileDoseHistory.
  ///
  /// In en, this message translates to:
  /// **'Dose history'**
  String get profileDoseHistory;

  /// No description provided for @profileEmergencyCard.
  ///
  /// In en, this message translates to:
  /// **'Emergency card'**
  String get profileEmergencyCard;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get commonKeep;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonIUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get commonIUnderstand;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @commonCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get commonCopyLink;

  /// No description provided for @commonLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get commonLinkCopied;

  /// No description provided for @commonCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get commonCopyCode;

  /// No description provided for @commonCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied.'**
  String get commonCodeCopied;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonUsedToVerify.
  ///
  /// In en, this message translates to:
  /// **'Used to verify'**
  String get commonUsedToVerify;

  /// No description provided for @commonNotUsedToVerify.
  ///
  /// In en, this message translates to:
  /// **'Not used to verify'**
  String get commonNotUsedToVerify;

  /// No description provided for @commonVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get commonVerified;

  /// No description provided for @commonUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get commonUnverified;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonTake.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get commonTake;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get commonBrand;

  /// No description provided for @commonBrandName.
  ///
  /// In en, this message translates to:
  /// **'Brand name'**
  String get commonBrandName;

  /// No description provided for @commonGenericName.
  ///
  /// In en, this message translates to:
  /// **'Generic name'**
  String get commonGenericName;

  /// No description provided for @commonStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get commonStrength;

  /// No description provided for @commonDosageForm.
  ///
  /// In en, this message translates to:
  /// **'Dosage form'**
  String get commonDosageForm;

  /// No description provided for @commonForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get commonForm;

  /// No description provided for @commonRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get commonRoute;

  /// No description provided for @commonDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get commonDirections;

  /// No description provided for @commonLabelDirections.
  ///
  /// In en, this message translates to:
  /// **'Label directions'**
  String get commonLabelDirections;

  /// No description provided for @commonNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get commonNotes;

  /// No description provided for @commonManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get commonManufacturer;

  /// No description provided for @commonProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get commonProvider;

  /// No description provided for @commonIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Identifier'**
  String get commonIdentifier;

  /// No description provided for @commonDatasetVersion.
  ///
  /// In en, this message translates to:
  /// **'Dataset version'**
  String get commonDatasetVersion;

  /// No description provided for @commonEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get commonEmailAddress;

  /// No description provided for @commonActiveIngredients.
  ///
  /// In en, this message translates to:
  /// **'Active ingredients'**
  String get commonActiveIngredients;

  /// No description provided for @commonIngredientNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredient name'**
  String get commonIngredientNameHint;

  /// No description provided for @commonStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get commonStrengthHint;

  /// No description provided for @commonUnitHint.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get commonUnitHint;

  /// No description provided for @commonAddAnotherIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add another ingredient'**
  String get commonAddAnotherIngredient;

  /// No description provided for @commonOnTheLabelOnly.
  ///
  /// In en, this message translates to:
  /// **'On the label only'**
  String get commonOnTheLabelOnly;

  /// No description provided for @commonRepeatsEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Repeats every day'**
  String get commonRepeatsEveryDay;

  /// No description provided for @commonNoIngredientsShort.
  ///
  /// In en, this message translates to:
  /// **'No active ingredients recorded'**
  String get commonNoIngredientsShort;

  /// No description provided for @commonDoseAmount.
  ///
  /// In en, this message translates to:
  /// **'Dose amount'**
  String get commonDoseAmount;

  /// No description provided for @commonTakenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} taken'**
  String commonTakenCount(Object count);

  /// No description provided for @commonSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String commonSkippedCount(Object count);

  /// No description provided for @commonMissedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missed'**
  String commonMissedCount(Object count);

  /// No description provided for @commonPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String commonPendingCount(Object count);

  /// No description provided for @pickerSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get pickerSelectDate;

  /// No description provided for @pickerReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get pickerReminderTime;

  /// No description provided for @pickerRepeatsDaily.
  ///
  /// In en, this message translates to:
  /// **'Repeats every day at this time.'**
  String get pickerRepeatsDaily;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @caregiverPermViewMedications.
  ///
  /// In en, this message translates to:
  /// **'See the medication list'**
  String get caregiverPermViewMedications;

  /// No description provided for @caregiverPermViewAdherence.
  ///
  /// In en, this message translates to:
  /// **'See taken and missed doses'**
  String get caregiverPermViewAdherence;

  /// No description provided for @caregiverPermViewSchedule.
  ///
  /// In en, this message translates to:
  /// **'See reminder times'**
  String get caregiverPermViewSchedule;

  /// No description provided for @caregiverPermMissedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Be alerted about missed doses'**
  String get caregiverPermMissedAlerts;

  /// No description provided for @authTabLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authTabLogIn;

  /// No description provided for @authTabSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authTabSignUp;

  /// No description provided for @authNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we greet you?'**
  String get authNameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordHintSignIn.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get authPasswordHintSignIn;

  /// No description provided for @authPasswordHintSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get authPasswordHintSignUp;

  /// No description provided for @authWhatWellWellDoesNotTitle.
  ///
  /// In en, this message translates to:
  /// **'What WellWell does not do'**
  String get authWhatWellWellDoesNotTitle;

  /// No description provided for @authWhatWellWellDoesNotMessage.
  ///
  /// In en, this message translates to:
  /// **'WellWell never diagnoses conditions or changes the instructions on your medication label.'**
  String get authWhatWellWellDoesNotMessage;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan. Understand.\nStay safer.'**
  String get onboardingHeroTitle;

  /// No description provided for @onboardingHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Your smart medication companion. Scan your medicines, understand what you\'re taking, and keep your routine organised.'**
  String get onboardingHeroDescription;

  /// No description provided for @onboardingCapSchedules.
  ///
  /// In en, this message translates to:
  /// **'organise medication schedules'**
  String get onboardingCapSchedules;

  /// No description provided for @onboardingCapIngredients.
  ///
  /// In en, this message translates to:
  /// **'identify active ingredients'**
  String get onboardingCapIngredients;

  /// No description provided for @onboardingCapDuplicates.
  ///
  /// In en, this message translates to:
  /// **'detect possible duplicate ingredients'**
  String get onboardingCapDuplicates;

  /// No description provided for @onboardingCapDoses.
  ///
  /// In en, this message translates to:
  /// **'remember doses'**
  String get onboardingCapDoses;

  /// No description provided for @onboardingCapEmergency.
  ///
  /// In en, this message translates to:
  /// **'securely share emergency medication information'**
  String get onboardingCapEmergency;

  /// No description provided for @onboardingAllInOnePlace.
  ///
  /// In en, this message translates to:
  /// **'All in one place'**
  String get onboardingAllInOnePlace;

  /// No description provided for @onboardingAllInOnePlaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedules, ingredients, reminders and emergency information — organised around the medications you already take.'**
  String get onboardingAllInOnePlaceDesc;

  /// No description provided for @onboardingBeforeYouStart.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get onboardingBeforeYouStart;

  /// No description provided for @onboardingNotDiagnosisTitle.
  ///
  /// In en, this message translates to:
  /// **'WellWell is not a diagnosis tool'**
  String get onboardingNotDiagnosisTitle;

  /// No description provided for @onboardingNotDiagnosisMessage.
  ///
  /// In en, this message translates to:
  /// **'WellWell does not provide medical diagnoses or change medication instructions. Always follow your medication label and advice from your healthcare professional.'**
  String get onboardingNotDiagnosisMessage;

  /// No description provided for @onboardingWarningsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Warnings are produced by deterministic checks against trusted medication data. Explanations written in plain language never add new findings of their own.'**
  String get onboardingWarningsExplanation;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send a reset link if an account exists.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotPasswordCheckEmailTitle;

  /// No description provided for @forgotPasswordCheckEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that address, a reset link is on its way.'**
  String get forgotPasswordCheckEmailMessage;

  /// No description provided for @forgotPasswordSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotPasswordSendButton;

  /// No description provided for @forgotPasswordCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get forgotPasswordCodeLabel;

  /// No description provided for @forgotPasswordCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the code from the email'**
  String get forgotPasswordCodeHint;

  /// No description provided for @forgotPasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get forgotPasswordNewPasswordLabel;

  /// No description provided for @forgotPasswordResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordResetButton;

  /// No description provided for @forgotPasswordResetDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get forgotPasswordResetDoneTitle;

  /// No description provided for @forgotPasswordResetDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password was changed. Please sign in again with your new password.'**
  String get forgotPasswordResetDoneMessage;

  /// No description provided for @forgotPasswordBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get forgotPasswordBackToSignIn;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'\'ve sent a 6-digit code to\n{email}'**
  String verifyEmailSentTo(Object email);

  /// No description provided for @verifyEmailVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyEmailVerifyButton;

  /// No description provided for @verifyEmailResendCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in 0:{seconds}'**
  String verifyEmailResendCooldown(Object seconds);

  /// No description provided for @verifyEmailResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyEmailResendButton;

  /// No description provided for @safetyNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'How WellWell works'**
  String get safetyNoticeTitle;

  /// No description provided for @safetyNoticeReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Please read before continuing'**
  String get safetyNoticeReadTitle;

  /// No description provided for @medsAddSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a medication'**
  String get medsAddSheetTitle;

  /// No description provided for @medsScanLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a label'**
  String get medsScanLabelTitle;

  /// No description provided for @medsScanLabelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your camera. WellWell reads the name and ingredients for you to confirm.'**
  String get medsScanLabelSubtitle;

  /// No description provided for @medsEnterManuallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get medsEnterManuallyTitle;

  /// No description provided for @medsEnterManuallySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type the medication details yourself.'**
  String get medsEnterManuallySubtitle;

  /// No description provided for @medsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medsTitle;

  /// No description provided for @medsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you have confirmed and saved in WellWell.'**
  String get medsSubtitle;

  /// No description provided for @medsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search medications'**
  String get medsSearchHint;

  /// No description provided for @medsSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get medsSortNameAsc;

  /// No description provided for @medsSortVerifiedFirst.
  ///
  /// In en, this message translates to:
  /// **'Verified first'**
  String get medsSortVerifiedFirst;

  /// No description provided for @medsSortMostReminders.
  ///
  /// In en, this message translates to:
  /// **'Most reminders'**
  String get medsSortMostReminders;

  /// No description provided for @medsSortRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get medsSortRecentlyAdded;

  /// No description provided for @medsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No medications yet'**
  String get medsEmptyTitle;

  /// No description provided for @medsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a label or add the details manually. Nothing is saved until you confirm it.'**
  String get medsEmptyDescription;

  /// No description provided for @medsScanAMedication.
  ///
  /// In en, this message translates to:
  /// **'Scan a medication'**
  String get medsScanAMedication;

  /// No description provided for @medsNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get medsNoMatchesTitle;

  /// No description provided for @medsNoMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'No medication matches \"{query}\"'**
  String medsNoMatchesDescription(Object query);

  /// No description provided for @medsReminderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reminders} =1{1 reminder} other{{count} reminders}}'**
  String medsReminderCount(int count);

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetyTitle;

  /// No description provided for @safetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deterministic checks across the medications saved in WellWell.'**
  String get safetySubtitle;

  /// No description provided for @safetyUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown does not mean safe'**
  String get safetyUnknownTitle;

  /// No description provided for @safetyUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'WellWell can only report what its current checks and data sources cover. Always read the label and ask a pharmacist if something is unclear.'**
  String get safetyUnknownMessage;

  /// No description provided for @safetyRunChecksAgain.
  ///
  /// In en, this message translates to:
  /// **'Run the checks again'**
  String get safetyRunChecksAgain;

  /// No description provided for @safetyViewMedications.
  ///
  /// In en, this message translates to:
  /// **'View medications'**
  String get safetyViewMedications;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account, health details and app settings.'**
  String get profileSubtitle;

  /// No description provided for @profileDemoAccountBadge.
  ///
  /// In en, this message translates to:
  /// **'Demo account'**
  String get profileDemoAccountBadge;

  /// No description provided for @profilePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInformation;

  /// No description provided for @profileHealthInformation.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get profileHealthInformation;

  /// No description provided for @profileAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get profileAppSettings;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profilePrivacy;

  /// No description provided for @profileSignOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutDialogTitle;

  /// No description provided for @profileSignOutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your medication information stays on the server and is removed from this device.'**
  String get profileSignOutDialogMessage;

  /// No description provided for @profileStaySignedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get profileStaySignedIn;

  /// No description provided for @homeStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1-day streak} other{{days}-day streak}}'**
  String homeStreakBadge(int days);

  /// No description provided for @medDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get medDetailNotFound;

  /// No description provided for @medDetailUnverifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not independently verified'**
  String get medDetailUnverifiedTitle;

  /// No description provided for @medDetailUnverifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'WellWell matches brand, generic name, strength, form and active ingredients against a trusted medication database. Edit those fields if they do not match the label, then save to try again.'**
  String get medDetailUnverifiedMessage;

  /// No description provided for @medDetailEditToVerify.
  ///
  /// In en, this message translates to:
  /// **'Edit details to verify'**
  String get medDetailEditToVerify;

  /// No description provided for @medDetailUsedToVerifyMessage.
  ///
  /// In en, this message translates to:
  /// **'Brand, generic name, strength, form and active ingredients are matched against the database. Route, directions and notes are stored as printed and are not used to verify.'**
  String get medDetailUsedToVerifyMessage;

  /// No description provided for @medDetailActiveIngredients.
  ///
  /// In en, this message translates to:
  /// **'Active ingredients'**
  String get medDetailActiveIngredients;

  /// No description provided for @medDetailNoIngredients.
  ///
  /// In en, this message translates to:
  /// **'No active ingredients are recorded for this medication.'**
  String get medDetailNoIngredients;

  /// No description provided for @medDetailStrengthNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Strength not recorded'**
  String get medDetailStrengthNotRecorded;

  /// No description provided for @medDetailIngredientStrengthLine.
  ///
  /// In en, this message translates to:
  /// **'{strength} · printed as \"{originalName}\"'**
  String medDetailIngredientStrengthLine(Object originalName, Object strength);

  /// No description provided for @medDetailRxNormIdentifier.
  ///
  /// In en, this message translates to:
  /// **'RxNorm identifier {id}'**
  String medDetailRxNormIdentifier(Object id);

  /// No description provided for @medDetailAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get medDetailAbout;

  /// No description provided for @medDetailSaveAndVerify.
  ///
  /// In en, this message translates to:
  /// **'Save and try to verify'**
  String get medDetailSaveAndVerify;

  /// No description provided for @medDetailAboutMedication.
  ///
  /// In en, this message translates to:
  /// **'About this medication'**
  String get medDetailAboutMedication;

  /// No description provided for @medDetailAiInfo.
  ///
  /// In en, this message translates to:
  /// **'AI info'**
  String get medDetailAiInfo;

  /// No description provided for @medDetailCommonlyUsedFor.
  ///
  /// In en, this message translates to:
  /// **'Commonly used for'**
  String get medDetailCommonlyUsedFor;

  /// No description provided for @medDetailClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get medDetailClass;

  /// No description provided for @medDetailSourceRxClass.
  ///
  /// In en, this message translates to:
  /// **'Source: RxClass (U.S. National Library of Medicine).'**
  String get medDetailSourceRxClass;

  /// No description provided for @medDetailSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get medDetailSourceTitle;

  /// No description provided for @medDetailEnteredManually.
  ///
  /// In en, this message translates to:
  /// **'Entered manually'**
  String get medDetailEnteredManually;

  /// No description provided for @medDetailLastVerified.
  ///
  /// In en, this message translates to:
  /// **'Last verified'**
  String get medDetailLastVerified;

  /// No description provided for @medDetailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get medDetailNotVerified;

  /// No description provided for @medDetailAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added on'**
  String get medDetailAddedOn;

  /// No description provided for @medDetailScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get medDetailScheduleTitle;

  /// No description provided for @medDetailActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String medDetailActiveCount(Object count);

  /// No description provided for @medDetailNoRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet. Reminder times are only suggestions from the label until you confirm them.'**
  String get medDetailNoRemindersYet;

  /// No description provided for @medDetailNextDose.
  ///
  /// In en, this message translates to:
  /// **'Next dose'**
  String get medDetailNextDose;

  /// No description provided for @medDetailSetUpReminders.
  ///
  /// In en, this message translates to:
  /// **'Set up reminders'**
  String get medDetailSetUpReminders;

  /// No description provided for @medDetailEditReminders.
  ///
  /// In en, this message translates to:
  /// **'Edit reminders'**
  String get medDetailEditReminders;

  /// No description provided for @medDetailRefillTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get medDetailRefillTitle;

  /// No description provided for @medDetailRefillTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'Track how many doses you have left to get a refill reminder before you run out.'**
  String get medDetailRefillTrackMessage;

  /// No description provided for @medDetailDosesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} doses left'**
  String medDetailDosesLeft(Object count);

  /// No description provided for @medDetailOutOfRefill.
  ///
  /// In en, this message translates to:
  /// **'You may be out — time to refill.'**
  String get medDetailOutOfRefill;

  /// No description provided for @medDetailDaysLeftAtSchedule.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{About 1 day left at your current reminder schedule.} other{About {days} days left at your current reminder schedule.}}'**
  String medDetailDaysLeftAtSchedule(int days);

  /// No description provided for @medDetailEstimateDaysMessage.
  ///
  /// In en, this message translates to:
  /// **'Set up reminders to estimate how many days this will last.'**
  String get medDetailEstimateDaysMessage;

  /// No description provided for @medDetailRunningLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get medDetailRunningLowTitle;

  /// No description provided for @medDetailRunningLowMessage.
  ///
  /// In en, this message translates to:
  /// **'Consider ordering a refill soon so you don\'t miss a dose.'**
  String get medDetailRunningLowMessage;

  /// No description provided for @medDetailAddPillCount.
  ///
  /// In en, this message translates to:
  /// **'Add pill count'**
  String get medDetailAddPillCount;

  /// No description provided for @medDetailUpdatePillCount.
  ///
  /// In en, this message translates to:
  /// **'Update pill count'**
  String get medDetailUpdatePillCount;

  /// No description provided for @medDetailExpirationTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get medDetailExpirationTitle;

  /// No description provided for @medDetailExpirationEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the date printed on the label to get a reminder before it expires.'**
  String get medDetailExpirationEmptyMessage;

  /// No description provided for @medDetailExpiredAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{This expired 1 day ago.} other{This expired {days} days ago.}}'**
  String medDetailExpiredAgo(int days);

  /// No description provided for @medDetailExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'This expires today.'**
  String get medDetailExpiresToday;

  /// No description provided for @medDetailExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Expires in 1 day.} other{Expires in {days} days.}}'**
  String medDetailExpiresIn(int days);

  /// No description provided for @medDetailExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get medDetailExpiredTitle;

  /// No description provided for @medDetailExpiringSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get medDetailExpiringSoonTitle;

  /// No description provided for @medDetailExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Check whether this medication is still safe to use, or replace it.'**
  String get medDetailExpiredMessage;

  /// No description provided for @medDetailExpiringSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Consider a replacement before it expires.'**
  String get medDetailExpiringSoonMessage;

  /// No description provided for @medDetailAddExpiration.
  ///
  /// In en, this message translates to:
  /// **'Add expiration date'**
  String get medDetailAddExpiration;

  /// No description provided for @medDetailUpdateExpiration.
  ///
  /// In en, this message translates to:
  /// **'Update expiration date'**
  String get medDetailUpdateExpiration;

  /// No description provided for @medDetailExpirationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiration date'**
  String get medDetailExpirationPickerTitle;

  /// No description provided for @medDetailViewDoseHistory.
  ///
  /// In en, this message translates to:
  /// **'View dose history'**
  String get medDetailViewDoseHistory;

  /// No description provided for @medDetailRemoveMedication.
  ///
  /// In en, this message translates to:
  /// **'Remove medication'**
  String get medDetailRemoveMedication;

  /// No description provided for @medDetailRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this medication?'**
  String get medDetailRemoveDialogTitle;

  /// No description provided for @medDetailRemoveDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'It will no longer appear in your list, reminders or safety checks. Your dose history stays intact.'**
  String get medDetailRemoveDialogMessage;

  /// No description provided for @medDetailKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get medDetailKeepIt;

  /// No description provided for @newMedBrandOrGenericRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a brand name or a generic name.'**
  String get newMedBrandOrGenericRequired;

  /// No description provided for @newMedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a medication'**
  String get newMedTitle;

  /// No description provided for @newMedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the details from the label. Fields marked \"Used to verify\" are matched against a trusted medication database.'**
  String get newMedSubtitle;

  /// No description provided for @newMedUsedToVerifyMessage.
  ///
  /// In en, this message translates to:
  /// **'Brand, generic name, strength, form and active ingredients decide whether this product can be verified.'**
  String get newMedUsedToVerifyMessage;

  /// No description provided for @newMedHintAsPrinted.
  ///
  /// In en, this message translates to:
  /// **'As printed on the box'**
  String get newMedHintAsPrinted;

  /// No description provided for @newMedDirectionsStoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Directions are stored as printed. They are not used to verify the product.'**
  String get newMedDirectionsStoredMessage;

  /// No description provided for @newMedSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save medication'**
  String get newMedSaveButton;

  /// No description provided for @scheduleAddAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one reminder time, or remove the reminders for this medication.'**
  String get scheduleAddAtLeastOne;

  /// No description provided for @scheduleInvalidTime.
  ///
  /// In en, this message translates to:
  /// **'\"{time}\" is not a valid time. Use the 24-hour format, for example 08:00.'**
  String scheduleInvalidTime(Object time);

  /// No description provided for @scheduleConfirmBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Confirm the reminder times before saving.'**
  String get scheduleConfirmBeforeSaving;

  /// No description provided for @scheduleNotificationPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Reminders were saved, but notification permission is off. Enable notifications for WellWell in iPhone Settings.'**
  String get scheduleNotificationPermissionOff;

  /// No description provided for @scheduleEditReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get scheduleEditReminderTitle;

  /// No description provided for @scheduleFromLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'From the label'**
  String get scheduleFromLabelTitle;

  /// No description provided for @scheduleAddReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder time'**
  String get scheduleAddReminderTime;

  /// No description provided for @scheduleConfirmCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I confirmed these reminder times against the label.'**
  String get scheduleConfirmCheckbox;

  /// No description provided for @scheduleSaveReminders.
  ///
  /// In en, this message translates to:
  /// **'Save reminders'**
  String get scheduleSaveReminders;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historySubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Completed, skipped and missed doses over the last two weeks.'**
  String get historySubtitleDefault;

  /// No description provided for @historySubtitleMonth.
  ///
  /// In en, this message translates to:
  /// **'Completed, skipped and missed doses in {month}.'**
  String historySubtitleMonth(Object month);

  /// No description provided for @historyLast2Weeks.
  ///
  /// In en, this message translates to:
  /// **'Last 2 weeks'**
  String get historyLast2Weeks;

  /// No description provided for @historyAllMedications.
  ///
  /// In en, this message translates to:
  /// **'All medications'**
  String get historyAllMedications;

  /// No description provided for @historyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get historyThisWeek;

  /// No description provided for @historyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These counts describe what happened, not how well you did. Talk to your healthcare professional if a pattern concerns you.'**
  String get historyDisclaimer;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No doses recorded yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Once reminders are confirmed, every taken, skipped or missed dose appears here.'**
  String get historyEmptyDescription;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your on-time streak and habits over the last 30 days.'**
  String get insightsSubtitle;

  /// No description provided for @insightsStreakDayLabel.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{day on-time streak} other{days on-time streak}}'**
  String insightsStreakDayLabel(int days);

  /// No description provided for @insightsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get insightsLast30Days;

  /// No description provided for @insightsAdherencePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of resolved doses taken on time'**
  String insightsAdherencePercent(Object percent);

  /// No description provided for @insightsWeakestTimeDoses.
  ///
  /// In en, this message translates to:
  /// **'{timeOfDay} doses'**
  String insightsWeakestTimeDoses(Object timeOfDay);

  /// No description provided for @insightsWeakestTimeMessage.
  ///
  /// In en, this message translates to:
  /// **'This is the time of day you most often miss. A reminder around then may help you stay on track.'**
  String get insightsWeakestTimeMessage;

  /// No description provided for @insightsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These numbers describe what happened, not how well you did. They are not medical advice — talk to your healthcare professional if a pattern concerns you.'**
  String get insightsDisclaimer;

  /// No description provided for @insightsTimeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get insightsTimeMorning;

  /// No description provided for @insightsTimeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get insightsTimeAfternoon;

  /// No description provided for @insightsTimeEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get insightsTimeEvening;

  /// No description provided for @insightsTimeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get insightsTimeNight;

  /// No description provided for @emergencyUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Your emergency card was updated.'**
  String get emergencyUpdatedSnackbar;

  /// No description provided for @emergencyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get emergencyUnavailable;

  /// No description provided for @emergencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share only what you choose. The QR code holds a random link, never your medical information.'**
  String get emergencySubtitle;

  /// No description provided for @emergencyActiveToggle.
  ///
  /// In en, this message translates to:
  /// **'Emergency card is active'**
  String get emergencyActiveToggle;

  /// No description provided for @emergencyActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Turn this off to make the link stop working.'**
  String get emergencyActiveHint;

  /// No description provided for @emergencyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String emergencyLastUpdated(Object date);

  /// No description provided for @emergencyOffTitle.
  ///
  /// In en, this message translates to:
  /// **'The card is switched off'**
  String get emergencyOffTitle;

  /// No description provided for @emergencyOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Nobody can open the link while the card is inactive.'**
  String get emergencyOffMessage;

  /// No description provided for @emergencyWhatIsShared.
  ///
  /// In en, this message translates to:
  /// **'What is shared'**
  String get emergencyWhatIsShared;

  /// No description provided for @emergencyAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get emergencyAllergies;

  /// No description provided for @emergencyActiveMedications.
  ///
  /// In en, this message translates to:
  /// **'Active medications'**
  String get emergencyActiveMedications;

  /// No description provided for @emergencyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContactLabel;

  /// No description provided for @emergencySaveCard.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get emergencySaveCard;

  /// No description provided for @emergencyCreateNewQr.
  ///
  /// In en, this message translates to:
  /// **'Create a new QR code'**
  String get emergencyCreateNewQr;

  /// No description provided for @emergencyNewQrDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new QR code?'**
  String get emergencyNewQrDialogTitle;

  /// No description provided for @emergencyNewQrDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'The previous QR code and link stop working immediately.'**
  String get emergencyNewQrDialogMessage;

  /// No description provided for @emergencyKeepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Keep the current one'**
  String get emergencyKeepCurrent;

  /// No description provided for @emergencyCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get emergencyCreateNew;

  /// No description provided for @emergencyHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How the QR code works'**
  String get emergencyHowItWorksTitle;

  /// No description provided for @emergencyHowItWorksMessage.
  ///
  /// In en, this message translates to:
  /// **'The code points to a random, revocable link. Opening it shows only the fields you switched on, and never your account details.'**
  String get emergencyHowItWorksMessage;

  /// No description provided for @emergencyNameShown.
  ///
  /// In en, this message translates to:
  /// **'Name shown'**
  String get emergencyNameShown;

  /// No description provided for @emergencyNameShownHint.
  ///
  /// In en, this message translates to:
  /// **'The name responders should see'**
  String get emergencyNameShownHint;

  /// No description provided for @emergencyContactName.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact name'**
  String get emergencyContactName;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact phone'**
  String get emergencyContactPhone;

  /// No description provided for @emergencyImportantNotes.
  ///
  /// In en, this message translates to:
  /// **'Important notes'**
  String get emergencyImportantNotes;

  /// No description provided for @emergencyApplyDetails.
  ///
  /// In en, this message translates to:
  /// **'Apply details'**
  String get emergencyApplyDetails;

  /// No description provided for @caregiversSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You stay the owner of your data. A caregiver only sees exactly what you approve, and you can remove access at any time.'**
  String get caregiversSubtitle;

  /// No description provided for @caregiversInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a caregiver'**
  String get caregiversInviteTitle;

  /// No description provided for @caregiversWhatTheyMaySee.
  ///
  /// In en, this message translates to:
  /// **'What they may see'**
  String get caregiversWhatTheyMaySee;

  /// No description provided for @caregiversSendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get caregiversSendInvitation;

  /// No description provided for @caregiversEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the caregiver\'s email address.'**
  String get caregiversEnterEmail;

  /// No description provided for @caregiversInvitationCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get caregiversInvitationCreatedTitle;

  /// No description provided for @caregiversInvitationCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Share this one-time code with the caregiver so they can accept the invitation.'**
  String get caregiversInvitationCreatedMessage;

  /// No description provided for @caregiversPeopleWithAccess.
  ///
  /// In en, this message translates to:
  /// **'People with access'**
  String get caregiversPeopleWithAccess;

  /// No description provided for @caregiversEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody has access'**
  String get caregiversEmptyTitle;

  /// No description provided for @caregiversEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite someone you trust if you would like them to follow your medication routine.'**
  String get caregiversEmptyDescription;

  /// No description provided for @caregiversStatusInvited.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get caregiversStatusInvited;

  /// No description provided for @caregiversStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get caregiversStatusWaiting;

  /// No description provided for @caregiversStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get caregiversStatusActive;

  /// No description provided for @caregiversRemoveAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove access'**
  String get caregiversRemoveAccess;

  /// No description provided for @caregiversRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this caregiver?'**
  String get caregiversRemoveDialogTitle;

  /// No description provided for @caregiversRemoveDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be able to see your medications or adherence.'**
  String caregiversRemoveDialogMessage(Object name);

  /// No description provided for @caregiversKeepAccess.
  ///
  /// In en, this message translates to:
  /// **'Keep access'**
  String get caregiversKeepAccess;

  /// No description provided for @sharedWithMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People who have shared their medications and adherence with you.'**
  String get sharedWithMeSubtitle;

  /// No description provided for @sharedWithMeHaveCode.
  ///
  /// In en, this message translates to:
  /// **'I have an invitation code'**
  String get sharedWithMeHaveCode;

  /// No description provided for @sharedWithMeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody has shared with you yet'**
  String get sharedWithMeEmptyTitle;

  /// No description provided for @sharedWithMeEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'When someone invites you as a caregiver and you accept their invitation code, they will appear here.'**
  String get sharedWithMeEmptyDescription;

  /// No description provided for @redeemInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the full invitation code exactly as it was shared with you.'**
  String get redeemInvalidCode;

  /// No description provided for @redeemTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter invitation code'**
  String get redeemTitle;

  /// No description provided for @redeemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the code the person shared with you to see their medications and adherence. This only works once.'**
  String get redeemSubtitle;

  /// No description provided for @redeemCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get redeemCodeLabel;

  /// No description provided for @redeemCodeHint.
  ///
  /// In en, this message translates to:
  /// **'The code they copied or shared with you'**
  String get redeemCodeHint;

  /// No description provided for @redeemAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get redeemAcceptButton;

  /// No description provided for @sharedDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get sharedDetailEmptyTitle;

  /// No description provided for @sharedDetailEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'This person has not granted you access to their medications or adherence.'**
  String get sharedDetailEmptyDescription;

  /// No description provided for @sharedDetailMedicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get sharedDetailMedicationsTitle;

  /// No description provided for @sharedDetailNoMedicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No medications'**
  String get sharedDetailNoMedicationsTitle;

  /// No description provided for @sharedDetailNoMedicationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been added yet.'**
  String get sharedDetailNoMedicationsDescription;

  /// No description provided for @sharedDetailAdherenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Adherence — last 7 days'**
  String get sharedDetailAdherenceTitle;

  /// No description provided for @sharedDetailNoDosesDescription.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened in this window yet.'**
  String get sharedDetailNoDosesDescription;

  /// No description provided for @personalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How WellWell greets you and the email on this account.'**
  String get personalInfoSubtitle;

  /// No description provided for @personalInfoUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Your name was updated.'**
  String get personalInfoUpdatedSnackbar;

  /// No description provided for @healthInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allergies and emergency contact details. These only appear on your emergency card when you switch those fields on.'**
  String get healthInfoSubtitle;

  /// No description provided for @healthInfoUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Your health information was updated.'**
  String get healthInfoUpdatedSnackbar;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How reminder alerts appear on the lock screen. WellWell sends a local notification at each confirmed reminder time.'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsPrivateToggle.
  ///
  /// In en, this message translates to:
  /// **'Private notifications'**
  String get notificationsPrivateToggle;

  /// No description provided for @notificationsPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Lock-screen reminders say \"You have a medication reminder\" instead of naming the medication.'**
  String get notificationsPrivateHint;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How WellWell treats medication information on this device.'**
  String get privacySubtitle;

  /// No description provided for @privacyOnDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get privacyOnDeviceTitle;

  /// No description provided for @privacyOnDeviceMessage.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are blocked where the platform supports it, and medication content is hidden in the app switcher.'**
  String get privacyOnDeviceMessage;

  /// No description provided for @privacyHowDecisionsTitle.
  ///
  /// In en, this message translates to:
  /// **'How WellWell makes decisions'**
  String get privacyHowDecisionsTitle;

  /// No description provided for @privacyHowDecisionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Safety findings come from deterministic checks against trusted medication data. Plain-language explanations only describe findings that already exist; they never create or dismiss one.'**
  String get privacyHowDecisionsMessage;

  /// No description provided for @findingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This safety finding is no longer available.'**
  String get findingUnavailable;

  /// No description provided for @findingWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why am I seeing this?'**
  String get findingWhyTitle;

  /// No description provided for @findingWhyItMatters.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get findingWhyItMatters;

  /// No description provided for @findingContains.
  ///
  /// In en, this message translates to:
  /// **'contains {ingredient}'**
  String findingContains(Object ingredient);

  /// No description provided for @findingThisIngredientFallback.
  ///
  /// In en, this message translates to:
  /// **'this ingredient'**
  String get findingThisIngredientFallback;

  /// No description provided for @findingExplanationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The explanation is unavailable right now. The finding above stays available and unchanged.'**
  String get findingExplanationUnavailable;

  /// No description provided for @findingWhatYouCanDo.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get findingWhatYouCanDo;

  /// No description provided for @findingDisclaimerFallback.
  ///
  /// In en, this message translates to:
  /// **'Review the medication labels and confirm with a pharmacist or healthcare professional if you are unsure.'**
  String get findingDisclaimerFallback;

  /// No description provided for @findingSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get findingSourcesTitle;

  /// No description provided for @findingDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get findingDataSource;

  /// No description provided for @findingLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked'**
  String get findingLastChecked;

  /// No description provided for @findingVerificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get findingVerificationLabel;

  /// No description provided for @findingVerifiedAgainstData.
  ///
  /// In en, this message translates to:
  /// **'Verified against trusted data'**
  String get findingVerifiedAgainstData;

  /// No description provided for @findingNotIndependentlyVerified.
  ///
  /// In en, this message translates to:
  /// **'Not independently verified'**
  String get findingNotIndependentlyVerified;

  /// No description provided for @findingExplanationLabel.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get findingExplanationLabel;

  /// No description provided for @findingAiExplanation.
  ///
  /// In en, this message translates to:
  /// **'AI explanation'**
  String get findingAiExplanation;

  /// No description provided for @findingStandardExplanation.
  ///
  /// In en, this message translates to:
  /// **'Standard explanation'**
  String get findingStandardExplanation;

  /// No description provided for @scanNoCameraAvailable.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get scanNoCameraAvailable;

  /// No description provided for @scanCameraAccessNeededError.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to read labels.'**
  String get scanCameraAccessNeededError;

  /// No description provided for @scanCameraAccessHeadline.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to read labels'**
  String get scanCameraAccessHeadline;

  /// No description provided for @scanCameraAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'WellWell reads the medication name and ingredients from the label. The photo is processed to extract text and is not stored.'**
  String get scanCameraAccessMessage;

  /// No description provided for @scanAllowCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access'**
  String get scanAllowCameraAccess;

  /// No description provided for @scanEnterLabelTextInstead.
  ///
  /// In en, this message translates to:
  /// **'Enter label text instead'**
  String get scanEnterLabelTextInstead;

  /// No description provided for @scanHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan medication label'**
  String get scanHeaderTitle;

  /// No description provided for @scanHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Place the medication name and ingredients inside the frame.'**
  String get scanHeaderSubtitle;

  /// No description provided for @scanReadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading the label…'**
  String get scanReadingLabel;

  /// No description provided for @scanOpeningCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening camera…'**
  String get scanOpeningCamera;

  /// No description provided for @scanTypeLabelInstead.
  ///
  /// In en, this message translates to:
  /// **'Type the label text instead'**
  String get scanTypeLabelInstead;

  /// No description provided for @manualScanEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Type the text printed on the label first.'**
  String get manualScanEmptyError;

  /// No description provided for @manualScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Type the label text'**
  String get manualScanTitle;

  /// No description provided for @manualScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the medication name, the active ingredients and the directions exactly as printed. WellWell matches them against trusted medication data and you confirm the result.'**
  String get manualScanSubtitle;

  /// No description provided for @manualScanHint.
  ///
  /// In en, this message translates to:
  /// **'Brand name\nActive ingredient 500 mg\nDirections'**
  String get manualScanHint;

  /// No description provided for @manualScanDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo walkthrough'**
  String get manualScanDemoTitle;

  /// No description provided for @manualScanDemoMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the sample Parol label to see a verified match.'**
  String get manualScanDemoMessage;

  /// No description provided for @manualScanUseSampleButton.
  ///
  /// In en, this message translates to:
  /// **'Use the sample label'**
  String get manualScanUseSampleButton;

  /// No description provided for @scanReviewNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get scanReviewNothingTitle;

  /// No description provided for @scanReviewNothingMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan a medication label to see the extracted details.'**
  String get scanReviewNothingMessage;

  /// No description provided for @scanOpenScanner.
  ///
  /// In en, this message translates to:
  /// **'Open the scanner'**
  String get scanOpenScanner;

  /// No description provided for @scanExtractionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read the label clearly'**
  String get scanExtractionFailedTitle;

  /// No description provided for @scanEnterDetailsManually.
  ///
  /// In en, this message translates to:
  /// **'Enter the details manually'**
  String get scanEnterDetailsManually;

  /// No description provided for @scanReviewLowConfidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Please review the details'**
  String get scanReviewLowConfidenceTitle;

  /// No description provided for @scanReviewLowConfidenceMessage.
  ///
  /// In en, this message translates to:
  /// **'The label was read with {confidence} confidence. Check every field against the label before confirming.'**
  String scanReviewLowConfidenceMessage(Object confidence);

  /// No description provided for @scanUsedToVerifyMessage.
  ///
  /// In en, this message translates to:
  /// **'WellWell matches these fields against a trusted medication database. Edit them if the scan misread the label.'**
  String get scanUsedToVerifyMessage;

  /// No description provided for @scanOnLabelOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'These stay as you entered them. They are not used to verify the product.'**
  String get scanOnLabelOnlyMessage;

  /// No description provided for @scanVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get scanVerificationTitle;

  /// No description provided for @scanSourceProviderOnly.
  ///
  /// In en, this message translates to:
  /// **'Source: {provider}'**
  String scanSourceProviderOnly(Object provider);

  /// No description provided for @scanSourceProviderDataset.
  ///
  /// In en, this message translates to:
  /// **'Source: {provider} · dataset {version}'**
  String scanSourceProviderDataset(Object provider, Object version);

  /// No description provided for @scanUnverifiedExplanation.
  ///
  /// In en, this message translates to:
  /// **'WellWell could not confirm this product against its medication data source. You can still save it, and it will stay marked as unverified.'**
  String get scanUnverifiedExplanation;

  /// No description provided for @scanCandidateMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate matches'**
  String get scanCandidateMatchesTitle;

  /// No description provided for @scanCandidateMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the product that matches the label in your hand.'**
  String get scanCandidateMatchesSubtitle;

  /// No description provided for @scanCandidateMatchLine.
  ///
  /// In en, this message translates to:
  /// **'Match {score} · {provider}'**
  String scanCandidateMatchLine(Object provider, Object score);

  /// No description provided for @scanSaveUnverifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save as unverified?'**
  String get scanSaveUnverifiedTitle;

  /// No description provided for @scanSaveUnverifiedCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand this medication is not independently verified and I checked the details against the label.'**
  String get scanSaveUnverifiedCheckbox;

  /// No description provided for @scanSaveAsUnverifiedButton.
  ///
  /// In en, this message translates to:
  /// **'Save as unverified'**
  String get scanSaveAsUnverifiedButton;

  /// No description provided for @scanConfirmMedicationButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Medication'**
  String get scanConfirmMedicationButton;

  /// No description provided for @scanAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgainButton;

  /// No description provided for @scanResultNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get scanResultNothingTitle;

  /// No description provided for @scanResultNothingMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan and confirm a medication to see its safety result.'**
  String get scanResultNothingMessage;

  /// No description provided for @scanResultSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} was saved'**
  String scanResultSavedTitle(Object name);

  /// No description provided for @scanResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'WellWell checked it against the medications already in your list.'**
  String get scanResultSubtitle;

  /// No description provided for @scanResultSavedMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved medication'**
  String get scanResultSavedMedicationTitle;

  /// No description provided for @scanResultCreateReminders.
  ///
  /// In en, this message translates to:
  /// **'Create reminders from the label'**
  String get scanResultCreateReminders;

  /// No description provided for @scanResultViewMedication.
  ///
  /// In en, this message translates to:
  /// **'View medication'**
  String get scanResultViewMedication;

  /// No description provided for @scanResultBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get scanResultBackToHome;

  /// No description provided for @doseDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get doseDue;

  /// No description provided for @doseUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get doseUpcoming;

  /// No description provided for @doseDetailsOnLabelFallback.
  ///
  /// In en, this message translates to:
  /// **'Dose details on the label'**
  String get doseDetailsOnLabelFallback;

  /// No description provided for @domainLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked {date}'**
  String domainLastChecked(Object date);

  /// No description provided for @domainChecksRan.
  ///
  /// In en, this message translates to:
  /// **'Checks WellWell ran'**
  String get domainChecksRan;

  /// No description provided for @domainSeverityHigh.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get domainSeverityHigh;

  /// No description provided for @domainSeverityWarning.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get domainSeverityWarning;

  /// No description provided for @domainSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get domainSeverityInfo;

  /// No description provided for @domainBothProductsContain.
  ///
  /// In en, this message translates to:
  /// **'Both products contain'**
  String get domainBothProductsContain;

  /// No description provided for @domainSourceDetected.
  ///
  /// In en, this message translates to:
  /// **'Source: {source} · Detected {date}'**
  String domainSourceDetected(Object date, Object source);

  /// No description provided for @domainSourceDatasetDetected.
  ///
  /// In en, this message translates to:
  /// **'Source: {source} · dataset {version} · Detected {date}'**
  String domainSourceDatasetDetected(
    Object date,
    Object source,
    Object version,
  );

  /// No description provided for @domainAiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI summary'**
  String get domainAiSummary;

  /// No description provided for @progressComplete.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get progressComplete;

  /// No description provided for @scanResultTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Scan result'**
  String get scanResultTitleGeneric;

  /// No description provided for @medDetailDosesRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Doses remaining'**
  String get medDetailDosesRemainingTitle;

  /// No description provided for @medDetailDosesRemainingMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter how many doses (pills, sprays, etc.) you have left. Leave empty to clear.'**
  String get medDetailDosesRemainingMessage;

  /// No description provided for @medDetailDosesRemainingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 30'**
  String get medDetailDosesRemainingHint;

  /// No description provided for @appSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device lock and how WellWell behaves on this phone.'**
  String get appSettingsSubtitle;

  /// No description provided for @appSettingsBiometricLabel.
  ///
  /// In en, this message translates to:
  /// **'Biometric app lock'**
  String get appSettingsBiometricLabel;

  /// No description provided for @appSettingsBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'Ask for Face ID, fingerprint or the device passcode after the app has been in the background.'**
  String get appSettingsBiometricHint;

  /// No description provided for @appSettingsDeviceLockUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Device lock not available'**
  String get appSettingsDeviceLockUnavailableTitle;

  /// No description provided for @appSettingsDeviceLockUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Set up a passcode, fingerprint or face unlock on this device first, then enable the app lock.'**
  String get appSettingsDeviceLockUnavailableMessage;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'You have a medication reminder.'**
  String get reminderNotificationPrivacyBody;

  /// No description provided for @reminderRefillNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill reminder'**
  String get reminderRefillNotificationTitle;

  /// No description provided for @reminderRefillPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'One of your medications is running low. Time to refill.'**
  String get reminderRefillPrivacyBody;

  /// No description provided for @reminderRefillBody.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{You have about 1 day of {name} left. Time to refill.} other{You have about {days} days of {name} left. Time to refill.}}'**
  String reminderRefillBody(int days, String name);

  /// No description provided for @reminderExpiringSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get reminderExpiringSoonTitle;

  /// No description provided for @reminderExpiringSoonPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'One of your medications is expiring soon.'**
  String get reminderExpiringSoonPrivacyBody;

  /// No description provided for @reminderExpiringSoonBody.
  ///
  /// In en, this message translates to:
  /// **'{name} expires on {date}.'**
  String reminderExpiringSoonBody(Object date, Object name);

  /// No description provided for @reminderExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get reminderExpiredTitle;

  /// No description provided for @reminderExpiredPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'One of your medications has expired.'**
  String get reminderExpiredPrivacyBody;

  /// No description provided for @reminderExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'{name} expired on {date}. Check the label and ask your pharmacist before using it.'**
  String reminderExpiredBody(Object date, Object name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
