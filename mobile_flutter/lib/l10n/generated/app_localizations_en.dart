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
  String get authFieldsRequired => 'Please fill in all fields.';

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
      'Choose the language WellWell uses for you. This also changes what\'s sent to you by email.';

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

  @override
  String get commonDone => 'Done';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonKeep => 'Keep';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonNext => 'Next';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonIUnderstand => 'I understand';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get commonCopyLink => 'Copy link';

  @override
  String get commonLinkCopied => 'Link copied.';

  @override
  String get commonCopyCode => 'Copy code';

  @override
  String get commonCodeCopied => 'Code copied.';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonUsedToVerify => 'Used to verify';

  @override
  String get commonNotUsedToVerify => 'Not used to verify';

  @override
  String get commonVerified => 'Verified';

  @override
  String get commonUnverified => 'Unverified';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTake => 'Take';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonBrand => 'Brand';

  @override
  String get commonBrandName => 'Brand name';

  @override
  String get commonGenericName => 'Generic name';

  @override
  String get commonStrength => 'Strength';

  @override
  String get commonDosageForm => 'Dosage form';

  @override
  String get commonForm => 'Form';

  @override
  String get commonRoute => 'Route';

  @override
  String get commonDirections => 'Directions';

  @override
  String get commonLabelDirections => 'Label directions';

  @override
  String get commonNotes => 'Notes';

  @override
  String get commonManufacturer => 'Manufacturer';

  @override
  String get commonProvider => 'Provider';

  @override
  String get commonIdentifier => 'Identifier';

  @override
  String get commonDatasetVersion => 'Dataset version';

  @override
  String get commonEmailAddress => 'Email address';

  @override
  String get commonActiveIngredients => 'Active ingredients';

  @override
  String get commonIngredientNameHint => 'Ingredient name';

  @override
  String get commonStrengthHint => 'Strength';

  @override
  String get commonUnitHint => 'Unit';

  @override
  String get commonAddAnotherIngredient => 'Add another ingredient';

  @override
  String get commonOnTheLabelOnly => 'On the label only';

  @override
  String get commonRepeatsEveryDay => 'Repeats every day';

  @override
  String get commonNoIngredientsShort => 'No active ingredients recorded';

  @override
  String get commonDoseAmount => 'Dose amount';

  @override
  String commonTakenCount(Object count) {
    return '$count taken';
  }

  @override
  String commonSkippedCount(Object count) {
    return '$count skipped';
  }

  @override
  String commonMissedCount(Object count) {
    return '$count missed';
  }

  @override
  String commonPendingCount(Object count) {
    return '$count pending';
  }

  @override
  String get pickerSelectDate => 'Select date';

  @override
  String get pickerReminderTime => 'Reminder time';

  @override
  String get pickerRepeatsDaily => 'Repeats every day at this time.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get caregiverPermViewMedications => 'See the medication list';

  @override
  String get caregiverPermViewAdherence => 'See taken and missed doses';

  @override
  String get caregiverPermViewSchedule => 'See reminder times';

  @override
  String get caregiverPermMissedAlerts => 'Be alerted about missed doses';

  @override
  String get authTabLogIn => 'Log In';

  @override
  String get authTabSignUp => 'Sign Up';

  @override
  String get authNameHint => 'How should we greet you?';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordHintSignIn => 'Your password';

  @override
  String get authPasswordHintSignUp => 'Create a password';

  @override
  String get authWhatWellWellDoesNotTitle => 'What WellWell does not do';

  @override
  String get authWhatWellWellDoesNotMessage =>
      'WellWell never diagnoses conditions or changes the instructions on your medication label.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingHeroTitle => 'Scan. Understand.\nStay safer.';

  @override
  String get onboardingHeroDescription =>
      'Your smart medication companion. Scan your medicines, understand what you\'re taking, and keep your routine organised.';

  @override
  String get onboardingCapSchedules => 'organise medication schedules';

  @override
  String get onboardingCapIngredients => 'identify active ingredients';

  @override
  String get onboardingCapDuplicates => 'detect possible duplicate ingredients';

  @override
  String get onboardingCapDoses => 'remember doses';

  @override
  String get onboardingCapEmergency =>
      'securely share emergency medication information';

  @override
  String get onboardingAllInOnePlace => 'All in one place';

  @override
  String get onboardingAllInOnePlaceDesc =>
      'Schedules, ingredients, reminders and emergency information — organised around the medications you already take.';

  @override
  String get onboardingBeforeYouStart => 'Before you start';

  @override
  String get onboardingNotDiagnosisTitle => 'WellWell is not a diagnosis tool';

  @override
  String get onboardingNotDiagnosisMessage =>
      'WellWell does not provide medical diagnoses or change medication instructions. Always follow your medication label and advice from your healthcare professional.';

  @override
  String get onboardingWarningsExplanation =>
      'Warnings are produced by deterministic checks against trusted medication data. Explanations written in plain language never add new findings of their own.';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email address and we\'ll send a reset link if an account exists.';

  @override
  String get forgotPasswordCheckEmailTitle => 'Check your email';

  @override
  String get forgotPasswordCheckEmailMessage =>
      'If an account exists for that address, a reset link is on its way.';

  @override
  String get forgotPasswordSendButton => 'Send reset link';

  @override
  String get forgotPasswordCodeLabel => 'Reset code';

  @override
  String get forgotPasswordCodeHint => 'Paste the code from the email';

  @override
  String get forgotPasswordNewPasswordLabel => 'New password';

  @override
  String get forgotPasswordResetButton => 'Reset password';

  @override
  String get forgotPasswordResetDoneTitle => 'Password updated';

  @override
  String get forgotPasswordResetDoneMessage =>
      'Your password was changed. Please sign in again with your new password.';

  @override
  String get forgotPasswordBackToSignIn => 'Back to sign in';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailSentTo(Object email) {
    return 'We\'\'ve sent a 6-digit code to\n$email';
  }

  @override
  String get verifyEmailVerifyButton => 'Verify';

  @override
  String verifyEmailResendCooldown(Object seconds) {
    return 'Resend code in 0:$seconds';
  }

  @override
  String get verifyEmailResendButton => 'Resend code';

  @override
  String get safetyNoticeTitle => 'How WellWell works';

  @override
  String get safetyNoticeReadTitle => 'Please read before continuing';

  @override
  String get medsAddSheetTitle => 'Add a medication';

  @override
  String get medsScanLabelTitle => 'Scan a label';

  @override
  String get medsScanLabelSubtitle =>
      'Use your camera. WellWell reads the name and ingredients for you to confirm.';

  @override
  String get medsEnterManuallyTitle => 'Enter manually';

  @override
  String get medsEnterManuallySubtitle =>
      'Type the medication details yourself.';

  @override
  String get medsTitle => 'Medications';

  @override
  String get medsSubtitle =>
      'Everything you have confirmed and saved in WellWell.';

  @override
  String get medsSearchHint => 'Search medications';

  @override
  String get medsSortNameAsc => 'Name A–Z';

  @override
  String get medsSortVerifiedFirst => 'Verified first';

  @override
  String get medsSortMostReminders => 'Most reminders';

  @override
  String get medsSortRecentlyAdded => 'Recently added';

  @override
  String get medsEmptyTitle => 'No medications yet';

  @override
  String get medsEmptyDescription =>
      'Scan a label or add the details manually. Nothing is saved until you confirm it.';

  @override
  String get medsScanAMedication => 'Scan a medication';

  @override
  String get medsNoMatchesTitle => 'No matches';

  @override
  String medsNoMatchesDescription(Object query) {
    return 'No medication matches \"$query\"';
  }

  @override
  String medsReminderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
      zero: 'No reminders',
    );
    return '$_temp0';
  }

  @override
  String get safetyTitle => 'Safety';

  @override
  String get safetySubtitle =>
      'Deterministic checks across the medications saved in WellWell.';

  @override
  String get safetyUnknownTitle => 'Unknown does not mean safe';

  @override
  String get safetyUnknownMessage =>
      'WellWell can only report what its current checks and data sources cover. Always read the label and ask a pharmacist if something is unclear.';

  @override
  String get safetyRunChecksAgain => 'Run the checks again';

  @override
  String get safetyViewMedications => 'View medications';

  @override
  String get profileSubtitle =>
      'Your account, health details and app settings.';

  @override
  String get profileDemoAccountBadge => 'Demo account';

  @override
  String get profilePersonalInformation => 'Personal Information';

  @override
  String get profileHealthInformation => 'Health Information';

  @override
  String get profileAppSettings => 'App Settings';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profilePrivacy => 'Privacy';

  @override
  String get profileSignOutDialogTitle => 'Sign out?';

  @override
  String get profileSignOutDialogMessage =>
      'Your medication information stays on the server and is removed from this device.';

  @override
  String get profileStaySignedIn => 'Stay signed in';

  @override
  String homeStreakBadge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get medDetailNotFound => 'Not found';

  @override
  String get medDetailUnverifiedTitle => 'Not independently verified';

  @override
  String get medDetailUnverifiedMessage =>
      'WellWell matches brand, generic name, strength, form and active ingredients against a trusted medication database. Edit those fields if they do not match the label, then save to try again.';

  @override
  String get medDetailEditToVerify => 'Edit details to verify';

  @override
  String get medDetailUsedToVerifyMessage =>
      'Brand, generic name, strength, form and active ingredients are matched against the database. Route, directions and notes are stored as printed and are not used to verify.';

  @override
  String get medDetailActiveIngredients => 'Active ingredients';

  @override
  String get medDetailNoIngredients =>
      'No active ingredients are recorded for this medication.';

  @override
  String get medDetailStrengthNotRecorded => 'Strength not recorded';

  @override
  String medDetailIngredientStrengthLine(Object originalName, Object strength) {
    return '$strength · printed as \"$originalName\"';
  }

  @override
  String medDetailRxNormIdentifier(Object id) {
    return 'RxNorm identifier $id';
  }

  @override
  String get medDetailAbout => 'About';

  @override
  String get medDetailSaveAndVerify => 'Save and try to verify';

  @override
  String get medDetailAboutMedication => 'About this medication';

  @override
  String get medDetailAiInfo => 'AI info';

  @override
  String get medDetailCommonlyUsedFor => 'Commonly used for';

  @override
  String get medDetailClass => 'Class';

  @override
  String get medDetailSourceRxClass =>
      'Source: RxClass (U.S. National Library of Medicine).';

  @override
  String get medDetailSourceTitle => 'Source';

  @override
  String get medDetailEnteredManually => 'Entered manually';

  @override
  String get medDetailLastVerified => 'Last verified';

  @override
  String get medDetailNotVerified => 'Not verified';

  @override
  String get medDetailAddedOn => 'Added on';

  @override
  String get medDetailScheduleTitle => 'Schedule';

  @override
  String medDetailActiveCount(Object count) {
    return '$count active';
  }

  @override
  String get medDetailNoRemindersYet =>
      'No reminders yet. Reminder times are only suggestions from the label until you confirm them.';

  @override
  String get medDetailNextDose => 'Next dose';

  @override
  String get medDetailSetUpReminders => 'Set up reminders';

  @override
  String get medDetailEditReminders => 'Edit reminders';

  @override
  String get medDetailRefillTitle => 'Refill';

  @override
  String get medDetailRefillTrackMessage =>
      'Track how many doses you have left to get a refill reminder before you run out.';

  @override
  String medDetailDosesLeft(Object count) {
    return '$count doses left';
  }

  @override
  String get medDetailOutOfRefill => 'You may be out — time to refill.';

  @override
  String medDetailDaysLeftAtSchedule(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'About $days days left at your current reminder schedule.',
      one: 'About 1 day left at your current reminder schedule.',
    );
    return '$_temp0';
  }

  @override
  String get medDetailEstimateDaysMessage =>
      'Set up reminders to estimate how many days this will last.';

  @override
  String get medDetailRunningLowTitle => 'Running low';

  @override
  String get medDetailRunningLowMessage =>
      'Consider ordering a refill soon so you don\'t miss a dose.';

  @override
  String get medDetailAddPillCount => 'Add pill count';

  @override
  String get medDetailUpdatePillCount => 'Update pill count';

  @override
  String get medDetailExpirationTitle => 'Expiration';

  @override
  String get medDetailExpirationEmptyMessage =>
      'Add the date printed on the label to get a reminder before it expires.';

  @override
  String medDetailExpiredAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'This expired $days days ago.',
      one: 'This expired 1 day ago.',
    );
    return '$_temp0';
  }

  @override
  String get medDetailExpiresToday => 'This expires today.';

  @override
  String medDetailExpiresIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expires in $days days.',
      one: 'Expires in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get medDetailExpiredTitle => 'Expired';

  @override
  String get medDetailExpiringSoonTitle => 'Expiring soon';

  @override
  String get medDetailExpiredMessage =>
      'Check whether this medication is still safe to use, or replace it.';

  @override
  String get medDetailExpiringSoonMessage =>
      'Consider a replacement before it expires.';

  @override
  String get medDetailAddExpiration => 'Add expiration date';

  @override
  String get medDetailUpdateExpiration => 'Update expiration date';

  @override
  String get medDetailExpirationPickerTitle => 'Expiration date';

  @override
  String get medDetailViewDoseHistory => 'View dose history';

  @override
  String get medDetailRemoveMedication => 'Remove medication';

  @override
  String get medDetailRemoveDialogTitle => 'Remove this medication?';

  @override
  String get medDetailRemoveDialogMessage =>
      'It will no longer appear in your list, reminders or safety checks. Your dose history stays intact.';

  @override
  String get medDetailKeepIt => 'Keep it';

  @override
  String get newMedBrandOrGenericRequired =>
      'Add a brand name or a generic name.';

  @override
  String get newMedTitle => 'Add a medication';

  @override
  String get newMedSubtitle =>
      'Copy the details from the label. Fields marked \"Used to verify\" are matched against a trusted medication database.';

  @override
  String get newMedUsedToVerifyMessage =>
      'Brand, generic name, strength, form and active ingredients decide whether this product can be verified.';

  @override
  String get newMedHintAsPrinted => 'As printed on the box';

  @override
  String get newMedDirectionsStoredMessage =>
      'Directions are stored as printed. They are not used to verify the product.';

  @override
  String get newMedSaveButton => 'Save medication';

  @override
  String get scheduleAddAtLeastOne =>
      'Add at least one reminder time, or remove the reminders for this medication.';

  @override
  String scheduleInvalidTime(Object time) {
    return '\"$time\" is not a valid time. Use the 24-hour format, for example 08:00.';
  }

  @override
  String get scheduleConfirmBeforeSaving =>
      'Confirm the reminder times before saving.';

  @override
  String get scheduleNotificationPermissionOff =>
      'Reminders were saved, but notification permission is off. Enable notifications for WellWell in iPhone Settings.';

  @override
  String get scheduleEditReminderTitle => 'Edit reminder';

  @override
  String get scheduleFromLabelTitle => 'From the label';

  @override
  String get scheduleAddReminderTime => 'Add a reminder time';

  @override
  String get scheduleConfirmCheckbox =>
      'I confirmed these reminder times against the label.';

  @override
  String get scheduleSaveReminders => 'Save reminders';

  @override
  String get historyTitle => 'History';

  @override
  String get historySubtitleDefault =>
      'Completed, skipped and missed doses over the last two weeks.';

  @override
  String historySubtitleMonth(Object month) {
    return 'Completed, skipped and missed doses in $month.';
  }

  @override
  String get historyLast2Weeks => 'Last 2 weeks';

  @override
  String get historyAllMedications => 'All medications';

  @override
  String get historyThisWeek => 'This week';

  @override
  String get historyDisclaimer =>
      'These counts describe what happened, not how well you did. Talk to your healthcare professional if a pattern concerns you.';

  @override
  String get historyEmptyTitle => 'No doses recorded yet';

  @override
  String get historyEmptyDescription =>
      'Once reminders are confirmed, every taken, skipped or missed dose appears here.';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsSubtitle =>
      'Your on-time streak and habits over the last 30 days.';

  @override
  String insightsStreakDayLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'days on-time streak',
      one: 'day on-time streak',
    );
    return '$_temp0';
  }

  @override
  String get insightsLast30Days => 'Last 30 days';

  @override
  String insightsAdherencePercent(Object percent) {
    return '$percent% of resolved doses taken on time';
  }

  @override
  String insightsWeakestTimeDoses(Object timeOfDay) {
    return '$timeOfDay doses';
  }

  @override
  String get insightsWeakestTimeMessage =>
      'This is the time of day you most often miss. A reminder around then may help you stay on track.';

  @override
  String get insightsDisclaimer =>
      'These numbers describe what happened, not how well you did. They are not medical advice — talk to your healthcare professional if a pattern concerns you.';

  @override
  String get insightsTimeMorning => 'Morning';

  @override
  String get insightsTimeAfternoon => 'Afternoon';

  @override
  String get insightsTimeEvening => 'Evening';

  @override
  String get insightsTimeNight => 'Night';

  @override
  String get emergencyUpdatedSnackbar => 'Your emergency card was updated.';

  @override
  String get emergencyUnavailable => 'Unavailable';

  @override
  String get emergencySubtitle =>
      'Share only what you choose. The QR code holds a random link, never your medical information.';

  @override
  String get emergencyActiveToggle => 'Emergency card is active';

  @override
  String get emergencyActiveHint =>
      'Turn this off to make the link stop working.';

  @override
  String emergencyLastUpdated(Object date) {
    return 'Last updated $date';
  }

  @override
  String get emergencyOffTitle => 'The card is switched off';

  @override
  String get emergencyOffMessage =>
      'Nobody can open the link while the card is inactive.';

  @override
  String get emergencyWhatIsShared => 'What is shared';

  @override
  String get emergencyAllergies => 'Allergies';

  @override
  String get emergencyActiveMedications => 'Active medications';

  @override
  String get emergencyContactLabel => 'Emergency contact';

  @override
  String get emergencySaveCard => 'Save card';

  @override
  String get emergencyCreateNewQr => 'Create a new QR code';

  @override
  String get emergencyNewQrDialogTitle => 'Create a new QR code?';

  @override
  String get emergencyNewQrDialogMessage =>
      'The previous QR code and link stop working immediately.';

  @override
  String get emergencyKeepCurrent => 'Keep the current one';

  @override
  String get emergencyCreateNew => 'Create new';

  @override
  String get emergencyHowItWorksTitle => 'How the QR code works';

  @override
  String get emergencyHowItWorksMessage =>
      'The code points to a random, revocable link. Opening it shows only the fields you switched on, and never your account details.';

  @override
  String get emergencyNameShown => 'Name shown';

  @override
  String get emergencyNameShownHint => 'The name responders should see';

  @override
  String get emergencyContactName => 'Emergency contact name';

  @override
  String get emergencyContactPhone => 'Emergency contact phone';

  @override
  String get emergencyImportantNotes => 'Important notes';

  @override
  String get emergencyApplyDetails => 'Apply details';

  @override
  String get caregiversSubtitle =>
      'You stay the owner of your data. A caregiver only sees exactly what you approve, and you can remove access at any time.';

  @override
  String get caregiversInviteTitle => 'Invite a caregiver';

  @override
  String get caregiversWhatTheyMaySee => 'What they may see';

  @override
  String get caregiversSendInvitation => 'Send invitation';

  @override
  String get caregiversEnterEmail => 'Enter the caregiver\'s email address.';

  @override
  String get caregiversInvitationCreatedTitle => 'Invitation created';

  @override
  String get caregiversInvitationCreatedMessage =>
      'Share this one-time code with the caregiver so they can accept the invitation.';

  @override
  String get caregiversPeopleWithAccess => 'People with access';

  @override
  String get caregiversEmptyTitle => 'Nobody has access';

  @override
  String get caregiversEmptyDescription =>
      'Invite someone you trust if you would like them to follow your medication routine.';

  @override
  String get caregiversStatusInvited => 'Invitation sent';

  @override
  String get caregiversStatusWaiting => 'Waiting for your approval';

  @override
  String get caregiversStatusActive => 'Active';

  @override
  String get caregiversRemoveAccess => 'Remove access';

  @override
  String get caregiversRemoveDialogTitle => 'Remove this caregiver?';

  @override
  String caregiversRemoveDialogMessage(Object name) {
    return '$name will no longer be able to see your medications or adherence.';
  }

  @override
  String get caregiversKeepAccess => 'Keep access';

  @override
  String get sharedWithMeSubtitle =>
      'People who have shared their medications and adherence with you.';

  @override
  String get sharedWithMeHaveCode => 'I have an invitation code';

  @override
  String get sharedWithMeEmptyTitle => 'Nobody has shared with you yet';

  @override
  String get sharedWithMeEmptyDescription =>
      'When someone invites you as a caregiver and you accept their invitation code, they will appear here.';

  @override
  String get redeemInvalidCode =>
      'Enter the full invitation code exactly as it was shared with you.';

  @override
  String get redeemTitle => 'Enter invitation code';

  @override
  String get redeemSubtitle =>
      'Paste the code the person shared with you to see their medications and adherence. This only works once.';

  @override
  String get redeemCodeLabel => 'Invitation code';

  @override
  String get redeemCodeHint => 'The code they copied or shared with you';

  @override
  String get redeemAcceptButton => 'Accept invitation';

  @override
  String get sharedDetailEmptyTitle => 'Nothing to show yet';

  @override
  String get sharedDetailEmptyDescription =>
      'This person has not granted you access to their medications or adherence.';

  @override
  String get sharedDetailMedicationsTitle => 'Medications';

  @override
  String get sharedDetailNoMedicationsTitle => 'No medications';

  @override
  String get sharedDetailNoMedicationsDescription =>
      'Nothing has been added yet.';

  @override
  String get sharedDetailAdherenceTitle => 'Adherence — last 7 days';

  @override
  String get sharedDetailNoDosesDescription =>
      'Nothing has happened in this window yet.';

  @override
  String get personalInfoSubtitle =>
      'How WellWell greets you and the email on this account.';

  @override
  String get personalInfoUpdatedSnackbar => 'Your name was updated.';

  @override
  String get healthInfoSubtitle =>
      'Allergies and emergency contact details. These only appear on your emergency card when you switch those fields on.';

  @override
  String get healthInfoUpdatedSnackbar =>
      'Your health information was updated.';

  @override
  String get notificationsSubtitle =>
      'How reminder alerts appear on the lock screen. WellWell sends a local notification at each confirmed reminder time.';

  @override
  String get notificationsPrivateToggle => 'Private notifications';

  @override
  String get notificationsPrivateHint =>
      'Lock-screen reminders say \"You have a medication reminder\" instead of naming the medication.';

  @override
  String get privacySubtitle =>
      'How WellWell treats medication information on this device.';

  @override
  String get privacyOnDeviceTitle => 'On this device';

  @override
  String get privacyOnDeviceMessage =>
      'Screenshots are blocked where the platform supports it, and medication content is hidden in the app switcher.';

  @override
  String get privacyHowDecisionsTitle => 'How WellWell makes decisions';

  @override
  String get privacyHowDecisionsMessage =>
      'Safety findings come from deterministic checks against trusted medication data. Plain-language explanations only describe findings that already exist; they never create or dismiss one.';

  @override
  String get findingUnavailable =>
      'This safety finding is no longer available.';

  @override
  String get findingWhyTitle => 'Why am I seeing this?';

  @override
  String get findingWhyItMatters => 'Why it matters';

  @override
  String findingContains(Object ingredient) {
    return 'contains $ingredient';
  }

  @override
  String get findingThisIngredientFallback => 'this ingredient';

  @override
  String get findingExplanationUnavailable =>
      'The explanation is unavailable right now. The finding above stays available and unchanged.';

  @override
  String get findingWhatYouCanDo => 'What you can do';

  @override
  String get findingDisclaimerFallback =>
      'Review the medication labels and confirm with a pharmacist or healthcare professional if you are unsure.';

  @override
  String get findingSourcesTitle => 'Sources';

  @override
  String get findingDataSource => 'Data source';

  @override
  String get findingLastChecked => 'Last checked';

  @override
  String get findingVerificationLabel => 'Verification';

  @override
  String get findingVerifiedAgainstData => 'Verified against trusted data';

  @override
  String get findingNotIndependentlyVerified => 'Not independently verified';

  @override
  String get findingExplanationLabel => 'Explanation';

  @override
  String get findingAiExplanation => 'AI explanation';

  @override
  String get findingStandardExplanation => 'Standard explanation';

  @override
  String get scanNoCameraAvailable => 'No camera is available on this device.';

  @override
  String get scanCameraAccessNeededError =>
      'Camera access is needed to read labels.';

  @override
  String get scanCameraAccessHeadline =>
      'Camera access is needed to read labels';

  @override
  String get scanCameraAccessMessage =>
      'WellWell reads the medication name and ingredients from the label. The photo is processed to extract text and is not stored.';

  @override
  String get scanAllowCameraAccess => 'Allow camera access';

  @override
  String get scanEnterLabelTextInstead => 'Enter label text instead';

  @override
  String get scanHeaderTitle => 'Scan medication label';

  @override
  String get scanHeaderSubtitle =>
      'Place the medication name and ingredients inside the frame.';

  @override
  String get scanReadingLabel => 'Reading the label…';

  @override
  String get scanOpeningCamera => 'Opening camera…';

  @override
  String get scanTypeLabelInstead => 'Type the label text instead';

  @override
  String get manualScanEmptyError =>
      'Type the text printed on the label first.';

  @override
  String get manualScanTitle => 'Type the label text';

  @override
  String get manualScanSubtitle =>
      'Copy the medication name, the active ingredients and the directions exactly as printed. WellWell matches them against trusted medication data and you confirm the result.';

  @override
  String get manualScanHint =>
      'Brand name\nActive ingredient 500 mg\nDirections';

  @override
  String get manualScanDemoTitle => 'Demo walkthrough';

  @override
  String get manualScanDemoMessage =>
      'Use the sample Parol label to see a verified match.';

  @override
  String get manualScanUseSampleButton => 'Use the sample label';

  @override
  String get scanReviewNothingTitle => 'Nothing to review';

  @override
  String get scanReviewNothingMessage =>
      'Scan a medication label to see the extracted details.';

  @override
  String get scanOpenScanner => 'Open the scanner';

  @override
  String get scanExtractionFailedTitle => 'We couldn\'t read the label clearly';

  @override
  String get scanEnterDetailsManually => 'Enter the details manually';

  @override
  String get scanReviewLowConfidenceTitle => 'Please review the details';

  @override
  String scanReviewLowConfidenceMessage(Object confidence) {
    return 'The label was read with $confidence confidence. Check every field against the label before confirming.';
  }

  @override
  String get scanUsedToVerifyMessage =>
      'WellWell matches these fields against a trusted medication database. Edit them if the scan misread the label.';

  @override
  String get scanOnLabelOnlyMessage =>
      'These stay as you entered them. They are not used to verify the product.';

  @override
  String get scanVerificationTitle => 'Verification';

  @override
  String scanSourceProviderOnly(Object provider) {
    return 'Source: $provider';
  }

  @override
  String scanSourceProviderDataset(Object provider, Object version) {
    return 'Source: $provider · dataset $version';
  }

  @override
  String get scanUnverifiedExplanation =>
      'WellWell could not confirm this product against its medication data source. You can still save it, and it will stay marked as unverified.';

  @override
  String get scanCandidateMatchesTitle => 'Candidate matches';

  @override
  String get scanCandidateMatchesSubtitle =>
      'Choose the product that matches the label in your hand.';

  @override
  String scanCandidateMatchLine(Object provider, Object score) {
    return 'Match $score · $provider';
  }

  @override
  String get scanSaveUnverifiedTitle => 'Save as unverified?';

  @override
  String get scanSaveUnverifiedCheckbox =>
      'I understand this medication is not independently verified and I checked the details against the label.';

  @override
  String get scanSaveAsUnverifiedButton => 'Save as unverified';

  @override
  String get scanConfirmMedicationButton => 'Confirm Medication';

  @override
  String get scanAgainButton => 'Scan again';

  @override
  String get scanResultNothingTitle => 'Nothing to show';

  @override
  String get scanResultNothingMessage =>
      'Scan and confirm a medication to see its safety result.';

  @override
  String scanResultSavedTitle(Object name) {
    return '$name was saved';
  }

  @override
  String get scanResultSubtitle =>
      'WellWell checked it against the medications already in your list.';

  @override
  String get scanResultSavedMedicationTitle => 'Saved medication';

  @override
  String get scanResultCreateReminders => 'Create reminders from the label';

  @override
  String get scanResultViewMedication => 'View medication';

  @override
  String get scanResultBackToHome => 'Back to home';

  @override
  String get doseDue => 'Due';

  @override
  String get doseUpcoming => 'Upcoming';

  @override
  String get doseDetailsOnLabelFallback => 'Dose details on the label';

  @override
  String domainLastChecked(Object date) {
    return 'Last checked $date';
  }

  @override
  String get domainChecksRan => 'Checks WellWell ran';

  @override
  String get domainSeverityHigh => 'High priority';

  @override
  String get domainSeverityWarning => 'Needs attention';

  @override
  String get domainSeverityInfo => 'Information';

  @override
  String get domainBothProductsContain => 'Both products contain';

  @override
  String domainSourceDetected(Object date, Object source) {
    return 'Source: $source · Detected $date';
  }

  @override
  String domainSourceDatasetDetected(
    Object date,
    Object source,
    Object version,
  ) {
    return 'Source: $source · dataset $version · Detected $date';
  }

  @override
  String get domainAiSummary => 'AI summary';

  @override
  String get progressComplete => 'complete';

  @override
  String get scanResultTitleGeneric => 'Scan result';

  @override
  String get medDetailDosesRemainingTitle => 'Doses remaining';

  @override
  String get medDetailDosesRemainingMessage =>
      'Enter how many doses (pills, sprays, etc.) you have left. Leave empty to clear.';

  @override
  String get medDetailDosesRemainingHint => 'e.g. 30';

  @override
  String get appSettingsSubtitle =>
      'Device lock and how WellWell behaves on this phone.';

  @override
  String get appSettingsBiometricLabel => 'Biometric app lock';

  @override
  String get appSettingsBiometricHint =>
      'Ask for Face ID, fingerprint or the device passcode after the app has been in the background.';

  @override
  String get appSettingsDeviceLockUnavailableTitle =>
      'Device lock not available';

  @override
  String get appSettingsDeviceLockUnavailableMessage =>
      'Set up a passcode, fingerprint or face unlock on this device first, then enable the app lock.';

  @override
  String get reminderNotificationTitle => 'Medication reminder';

  @override
  String get reminderNotificationPrivacyBody =>
      'You have a medication reminder.';

  @override
  String get reminderRefillNotificationTitle => 'Refill reminder';

  @override
  String get reminderRefillPrivacyBody =>
      'One of your medications is running low. Time to refill.';

  @override
  String reminderRefillBody(int days, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'You have about $days days of $name left. Time to refill.',
      one: 'You have about 1 day of $name left. Time to refill.',
    );
    return '$_temp0';
  }

  @override
  String get reminderExpiringSoonTitle => 'Expiring soon';

  @override
  String get reminderExpiringSoonPrivacyBody =>
      'One of your medications is expiring soon.';

  @override
  String reminderExpiringSoonBody(Object date, Object name) {
    return '$name expires on $date.';
  }

  @override
  String get reminderExpiredTitle => 'Expired';

  @override
  String get reminderExpiredPrivacyBody =>
      'One of your medications has expired.';

  @override
  String reminderExpiredBody(Object date, Object name) {
    return '$name expired on $date. Check the label and ask your pharmacist before using it.';
  }
}
