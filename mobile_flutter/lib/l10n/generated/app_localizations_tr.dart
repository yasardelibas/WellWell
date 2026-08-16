// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'WellWell';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navMeds => 'İlaçlar';

  @override
  String get navScan => 'Tara';

  @override
  String get navSafety => 'Güvenlik';

  @override
  String get navProfile => 'Profil';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonSignIn => 'Giriş yap';

  @override
  String get commonSignUp => 'Kayıt ol';

  @override
  String get authWelcomeBack => 'Tekrar hoş geldiniz';

  @override
  String get authCreateAccount => 'Hesap oluştur';

  @override
  String get authSignInSubtitle =>
      'İlaçlarınızı ve bugünün hatırlatmalarını görmek için giriş yapın.';

  @override
  String get authSignUpSubtitle =>
      'Paylaşmayı seçmediğiniz sürece ilaç listeniz sadece size özeldir.';

  @override
  String get authUseDemoAccount => 'Demo hesabı kullan';

  @override
  String get authDemoOnlyMessage =>
      'Giriş ve kayıt şu anda kullanılamıyor. Lütfen demo hesabını kullanın.';

  @override
  String get authEmail => 'E-posta';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authName => 'İsim';

  @override
  String get authForgotPassword => 'Şifremi unuttum';

  @override
  String get authSessionExpired =>
      'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSignOut => 'Çıkış yap';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsAppearanceHint =>
      'Sistem ayarını takip edin veya her zaman açık ya da koyu temayı kullanın.';

  @override
  String get settingsSystem => 'Sistem';

  @override
  String get settingsLight => 'Açık';

  @override
  String get settingsDark => 'Koyu';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageHint =>
      'WellWell\'in sizin için kullanacağı dili seçin.';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get errorGeneric => 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get errorNetwork =>
      'WellWell\'e ulaşılamadı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get errorInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get errorEmailInUse => 'Bu e-posta ile bir hesap zaten var.';

  @override
  String get errorMedicationNotFound => 'Bu ilaç listenizde yok.';

  @override
  String get errorPleaseSignInAgain => 'Lütfen tekrar giriş yapın.';

  @override
  String get homeGreetingFallback => 'Hoş geldiniz';

  @override
  String get homeInsights => 'İçgörüler';

  @override
  String get homeHistory => 'Geçmiş';

  @override
  String get homeScanMedication => 'İlaç Tara';

  @override
  String get homeTodaysMedications => 'Bugünün ilaçları';

  @override
  String get homeNoDosesToday => 'Bugün için planlanmış doz yok.';

  @override
  String get homeNoRemindersYetTitle => 'Henüz hatırlatma yok';

  @override
  String get homeNoRemindersYetDescription =>
      'Gününüzü burada görmek için bir ilaç ekleyip hatırlatma saatlerini onaylayın.';

  @override
  String get homeAllDoneTitle => 'Bugün için tamamlandı 🎉';

  @override
  String get homeAllDoneMessage =>
      'Bugün için planlanan her dozu aldınız ya da işaretlediniz.';

  @override
  String homeSafetyFindings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gözden geçirilecek $count güvenlik bulgusu',
      one: 'Gözden geçirilecek 1 güvenlik bulgusu',
    );
    return '$_temp0';
  }

  @override
  String get profileShareAccess => 'Erişim paylaş';

  @override
  String get profileSharedWithYou => 'Sizinle paylaşılanlar';

  @override
  String get profileDoseHistory => 'Doz geçmişi';

  @override
  String get profileEmergencyCard => 'Acil durum kartı';
}
