// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WellWell';

  @override
  String get navHome => 'Home';

  @override
  String get navMeds => 'Meds';

  @override
  String get navScan => 'Scan';

  @override
  String get navSafety => 'Safety';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSignIn => 'Sign in';

  @override
  String get commonSignUp => 'Sign up';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authSignInSubtitle =>
      'Sign in to see your medications and today\'s reminders.';

  @override
  String get authSignUpSubtitle =>
      'Your medication list stays private to you unless you choose to share it.';

  @override
  String get authUseDemoAccount => 'Use the demo account';

  @override
  String get authDemoOnlyMessage =>
      'Sign in and sign up are not available. Please use the demo account.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authName => 'Name';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSessionExpired => 'Your session ended. Please sign in again.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceHint =>
      'Follow the system setting, or always use light or dark.';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHint =>
      'Choose the language WellWell uses for you.';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'We couldn\'t reach WellWell. Check your connection and try again.';

  @override
  String get errorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get errorEmailInUse => 'An account with this email already exists.';

  @override
  String get errorMedicationNotFound => 'This medication is not in your list.';

  @override
  String get errorPleaseSignInAgain => 'Please sign in again.';

  @override
  String get homeGreetingFallback => 'Welcome';

  @override
  String get homeInsights => 'Insights';

  @override
  String get homeHistory => 'History';

  @override
  String get homeScanMedication => 'Scan Medication';

  @override
  String get homeTodaysMedications => 'Today\'s medications';

  @override
  String get homeNoDosesToday => 'No doses are scheduled for today.';

  @override
  String get homeNoRemindersYetTitle => 'No reminders yet';

  @override
  String get homeNoRemindersYetDescription =>
      'Add a medication and confirm its reminder times to see your day here.';

  @override
  String get homeAllDoneTitle => 'All done for today 🎉';

  @override
  String get homeAllDoneMessage =>
      'You\'ve taken or accounted for every dose scheduled for today.';

  @override
  String homeSafetyFindings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count safety findings to review',
      one: '1 safety finding to review',
    );
    return '$_temp0';
  }

  @override
  String get profileShareAccess => 'Share access';

  @override
  String get profileSharedWithYou => 'Shared with you';

  @override
  String get profileDoseHistory => 'Dose history';

  @override
  String get profileEmergencyCard => 'Emergency card';
}
