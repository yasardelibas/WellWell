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
  String get authFieldsRequired => 'Lütfen tüm alanları doldurun.';

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
      'WellWell\'in sizin için kullanacağı dili seçin. Bu, size e-posta ile gönderilenleri de değiştirir.';

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

  @override
  String get commonDone => 'Tamam';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonClear => 'Temizle';

  @override
  String get commonKeep => 'Sakla';

  @override
  String get commonRemove => 'Kaldır';

  @override
  String get commonReset => 'Sıfırla';

  @override
  String get commonNext => 'İleri';

  @override
  String get commonContinue => 'Devam et';

  @override
  String get commonIUnderstand => 'Anladım';

  @override
  String get commonNotSet => 'Belirlenmedi';

  @override
  String get commonCopyLink => 'Bağlantıyı kopyala';

  @override
  String get commonLinkCopied => 'Bağlantı kopyalandı.';

  @override
  String get commonCopyCode => 'Kodu kopyala';

  @override
  String get commonCodeCopied => 'Kod kopyalandı.';

  @override
  String get commonShare => 'Paylaş';

  @override
  String get commonSomethingWentWrong => 'Bir şeyler ters gitti';

  @override
  String get commonTryAgain => 'Tekrar dene';

  @override
  String get commonUsedToVerify => 'Doğrulamak için kullanılır';

  @override
  String get commonNotUsedToVerify => 'Doğrulamak için kullanılmaz';

  @override
  String get commonVerified => 'Doğrulandı';

  @override
  String get commonUnverified => 'Doğrulanmadı';

  @override
  String get commonToday => 'Bugün';

  @override
  String get commonTake => 'Al';

  @override
  String get commonSkip => 'Atla';

  @override
  String get commonBrand => 'Marka';

  @override
  String get commonBrandName => 'Marka adı';

  @override
  String get commonGenericName => 'Jenerik adı';

  @override
  String get commonStrength => 'Doz gücü';

  @override
  String get commonDosageForm => 'Farmasötik form';

  @override
  String get commonForm => 'Form';

  @override
  String get commonRoute => 'Kullanım yolu';

  @override
  String get commonDirections => 'Talimatlar';

  @override
  String get commonLabelDirections => 'Etiket talimatları';

  @override
  String get commonNotes => 'Notlar';

  @override
  String get commonManufacturer => 'Üretici';

  @override
  String get commonProvider => 'Kaynak';

  @override
  String get commonIdentifier => 'Tanımlayıcı';

  @override
  String get commonDatasetVersion => 'Veri kümesi sürümü';

  @override
  String get commonEmailAddress => 'E-posta adresi';

  @override
  String get commonActiveIngredients => 'Etken maddeler';

  @override
  String get commonIngredientNameHint => 'Etken madde adı';

  @override
  String get commonStrengthHint => 'Doz gücü';

  @override
  String get commonUnitHint => 'Birim';

  @override
  String get commonAddAnotherIngredient => 'Başka bir etken madde ekle';

  @override
  String get commonOnTheLabelOnly => 'Sadece etikette';

  @override
  String get commonRepeatsEveryDay => 'Her gün tekrarlar';

  @override
  String get commonNoIngredientsShort => 'Etken madde kaydedilmemiş';

  @override
  String get commonDoseAmount => 'Doz miktarı';

  @override
  String commonTakenCount(Object count) {
    return '$count alındı';
  }

  @override
  String commonSkippedCount(Object count) {
    return '$count atlandı';
  }

  @override
  String commonMissedCount(Object count) {
    return '$count kaçırıldı';
  }

  @override
  String commonPendingCount(Object count) {
    return '$count bekliyor';
  }

  @override
  String get pickerSelectDate => 'Tarih seç';

  @override
  String get pickerReminderTime => 'Hatırlatma saati';

  @override
  String get pickerRepeatsDaily => 'Her gün bu saatte tekrarlar.';

  @override
  String get greetingMorning => 'Günaydın';

  @override
  String get greetingAfternoon => 'İyi günler';

  @override
  String get greetingEvening => 'İyi akşamlar';

  @override
  String get caregiverPermViewMedications => 'İlaç listesini görsün';

  @override
  String get caregiverPermViewAdherence => 'Alınan ve kaçırılan dozları görsün';

  @override
  String get caregiverPermViewSchedule => 'Hatırlatma saatlerini görsün';

  @override
  String get caregiverPermMissedAlerts => 'Kaçırılan dozlar için uyarılsın';

  @override
  String get authTabLogIn => 'Giriş Yap';

  @override
  String get authTabSignUp => 'Kayıt Ol';

  @override
  String get authNameHint => 'Size nasıl hitap edelim?';

  @override
  String get authEmailHint => 'siz@ornek.com';

  @override
  String get authPasswordHintSignIn => 'Şifreniz';

  @override
  String get authPasswordHintSignUp => 'Bir şifre oluşturun';

  @override
  String get authWhatWellWellDoesNotTitle => 'WellWell neler yapmaz';

  @override
  String get authWhatWellWellDoesNotMessage =>
      'WellWell asla tanı koymaz veya ilaç etiketinizdeki talimatları değiştirmez.';

  @override
  String get onboardingGetStarted => 'Başlayalım';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingHeroTitle => 'Tara. Anla.\nDaha güvende ol.';

  @override
  String get onboardingHeroDescription =>
      'Akıllı ilaç yardımcınız. İlaçlarınızı tarayın, ne kullandığınızı anlayın ve rutininizi düzenli tutun.';

  @override
  String get onboardingCapSchedules => 'ilaç programlarını düzenler';

  @override
  String get onboardingCapIngredients => 'etken maddeleri belirler';

  @override
  String get onboardingCapDuplicates =>
      'olası tekrar eden etken maddeleri tespit eder';

  @override
  String get onboardingCapDoses => 'dozları hatırlar';

  @override
  String get onboardingCapEmergency =>
      'acil durum ilaç bilgilerini güvenle paylaşır';

  @override
  String get onboardingAllInOnePlace => 'Her şey tek bir yerde';

  @override
  String get onboardingAllInOnePlaceDesc =>
      'Programlar, etken maddeler, hatırlatmalar ve acil durum bilgileri — zaten kullandığınız ilaçlara göre düzenlenir.';

  @override
  String get onboardingBeforeYouStart => 'Başlamadan önce';

  @override
  String get onboardingNotDiagnosisTitle => 'WellWell bir tanı aracı değildir';

  @override
  String get onboardingNotDiagnosisMessage =>
      'WellWell tıbbi tanı koymaz veya ilaç talimatlarını değiştirmez. Her zaman ilaç etiketinizi ve sağlık uzmanınızın tavsiyelerini takip edin.';

  @override
  String get onboardingWarningsExplanation =>
      'Uyarılar, güvenilir ilaç verilerine karşı yapılan deterministik kontrollerle üretilir. Sade dille yazılan açıklamalar kendiliğinden yeni bir bulgu eklemez.';

  @override
  String get forgotPasswordTitle => 'Şifrenizi sıfırlayın';

  @override
  String get forgotPasswordSubtitle =>
      'E-posta adresinizi girin, bir hesap varsa sıfırlama bağlantısı gönderelim.';

  @override
  String get forgotPasswordCheckEmailTitle => 'E-postanızı kontrol edin';

  @override
  String get forgotPasswordCheckEmailMessage =>
      'Bu adrese kayıtlı bir hesap varsa, sıfırlama bağlantısı yolda.';

  @override
  String get forgotPasswordSendButton => 'Sıfırlama bağlantısı gönder';

  @override
  String get forgotPasswordCodeLabel => 'Sıfırlama kodu';

  @override
  String get forgotPasswordCodeHint => 'E-postadaki kodu yapıştırın';

  @override
  String get forgotPasswordNewPasswordLabel => 'Yeni şifre';

  @override
  String get forgotPasswordResetButton => 'Şifreyi sıfırla';

  @override
  String get forgotPasswordResetDoneTitle => 'Şifre güncellendi';

  @override
  String get forgotPasswordResetDoneMessage =>
      'Şifreniz değiştirildi. Lütfen yeni şifrenizle tekrar giriş yapın.';

  @override
  String get forgotPasswordBackToSignIn => 'Girişe dön';

  @override
  String get verifyEmailTitle => 'E-postanızı doğrulayın';

  @override
  String verifyEmailSentTo(Object email) {
    return '$email adresine 6 haneli bir kod gönderdik.';
  }

  @override
  String get verifyEmailVerifyButton => 'Doğrula';

  @override
  String verifyEmailResendCooldown(Object seconds) {
    return 'Kodu 0:$seconds sonra tekrar gönder';
  }

  @override
  String get verifyEmailResendButton => 'Kodu tekrar gönder';

  @override
  String get safetyNoticeTitle => 'WellWell nasıl çalışır';

  @override
  String get safetyNoticeReadTitle => 'Devam etmeden önce lütfen okuyun';

  @override
  String get medsAddSheetTitle => 'İlaç ekle';

  @override
  String get medsScanLabelTitle => 'Etiket tara';

  @override
  String get medsScanLabelSubtitle =>
      'Kameranızı kullanın. WellWell adı ve etken maddeleri okur, onaylamanızı bekler.';

  @override
  String get medsEnterManuallyTitle => 'Elle gir';

  @override
  String get medsEnterManuallySubtitle => 'İlaç bilgilerini kendiniz yazın.';

  @override
  String get medsTitle => 'İlaçlar';

  @override
  String get medsSubtitle =>
      'WellWell\'de onayladığınız ve kaydettiğiniz her şey.';

  @override
  String get medsSearchHint => 'İlaç ara';

  @override
  String get medsSortNameAsc => 'İsim A–Z';

  @override
  String get medsSortVerifiedFirst => 'Önce doğrulananlar';

  @override
  String get medsSortMostReminders => 'En çok hatırlatma';

  @override
  String get medsSortRecentlyAdded => 'Son eklenenler';

  @override
  String get medsEmptyTitle => 'Henüz ilaç yok';

  @override
  String get medsEmptyDescription =>
      'Bir etiket tarayın veya bilgileri elle girin. Siz onaylamadan hiçbir şey kaydedilmez.';

  @override
  String get medsScanAMedication => 'Bir ilaç tara';

  @override
  String get medsNoMatchesTitle => 'Eşleşme yok';

  @override
  String medsNoMatchesDescription(Object query) {
    return '\"$query\" ile eşleşen bir ilaç yok.';
  }

  @override
  String medsReminderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatma',
      zero: 'Hatırlatma yok',
    );
    return '$_temp0';
  }

  @override
  String get safetyTitle => 'Güvenlik';

  @override
  String get safetySubtitle =>
      'WellWell\'de kayıtlı ilaçlar için deterministik kontroller.';

  @override
  String get safetyUnknownTitle => 'Bilinmiyor, güvenli demek değildir';

  @override
  String get safetyUnknownMessage =>
      'WellWell yalnızca mevcut kontrollerinin ve veri kaynaklarının kapsadığı şeyleri bildirebilir. Her zaman etiketi okuyun ve bir şey belirsizse eczacınıza danışın.';

  @override
  String get safetyRunChecksAgain => 'Kontrolleri tekrar çalıştır';

  @override
  String get safetyViewMedications => 'İlaçları görüntüle';

  @override
  String get profileSubtitle =>
      'Hesabınız, sağlık bilgileriniz ve uygulama ayarlarınız.';

  @override
  String get profileDemoAccountBadge => 'Demo hesap';

  @override
  String get profilePersonalInformation => 'Kişisel Bilgiler';

  @override
  String get profileHealthInformation => 'Sağlık Bilgileri';

  @override
  String get profileAppSettings => 'Uygulama Ayarları';

  @override
  String get profileNotifications => 'Bildirimler';

  @override
  String get profilePrivacy => 'Gizlilik';

  @override
  String get profileSignOutDialogTitle => 'Çıkış yapılsın mı?';

  @override
  String get profileSignOutDialogMessage =>
      'İlaç bilgileriniz sunucuda kalır ve bu cihazdan kaldırılır.';

  @override
  String get profileStaySignedIn => 'Oturumda kal';

  @override
  String homeStreakBadge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days günlük seri',
    );
    return '$_temp0';
  }

  @override
  String get medDetailNotFound => 'Bulunamadı';

  @override
  String get medDetailUnverifiedTitle => 'Bağımsız olarak doğrulanmadı';

  @override
  String get medDetailUnverifiedMessage =>
      'WellWell marka, jenerik ad, doz gücü, form ve etken maddeleri güvenilir bir ilaç veritabanıyla karşılaştırır. Etikete uymuyorsa bu alanları düzenleyip tekrar kaydedin.';

  @override
  String get medDetailEditToVerify => 'Doğrulamak için bilgileri düzenle';

  @override
  String get medDetailUsedToVerifyMessage =>
      'Marka, jenerik ad, doz gücü, form ve etken maddeler veritabanıyla eşleştirilir. Kullanım yolu, talimatlar ve notlar yazıldığı gibi saklanır ve doğrulama için kullanılmaz.';

  @override
  String get medDetailActiveIngredients => 'Etken maddeler';

  @override
  String get medDetailNoIngredients => 'Bu ilaç için kayıtlı etken madde yok.';

  @override
  String get medDetailStrengthNotRecorded => 'Doz gücü kaydedilmemiş';

  @override
  String medDetailIngredientStrengthLine(Object originalName, Object strength) {
    return '$strength · etikette \"$originalName\" olarak yazıyor';
  }

  @override
  String medDetailRxNormIdentifier(Object id) {
    return 'RxNorm tanımlayıcı $id';
  }

  @override
  String get medDetailAbout => 'Hakkında';

  @override
  String get medDetailSaveAndVerify => 'Kaydet ve doğrulamayı dene';

  @override
  String get medDetailAboutMedication => 'Bu ilaç hakkında';

  @override
  String get medDetailAiInfo => 'AI bilgisi';

  @override
  String get medDetailCommonlyUsedFor => 'Genellikle şunlar için kullanılır';

  @override
  String get medDetailClass => 'Sınıf';

  @override
  String get medDetailSourceRxClass =>
      'Kaynak: RxClass (ABD Ulusal Tıp Kütüphanesi).';

  @override
  String get medDetailSourceTitle => 'Kaynak';

  @override
  String get medDetailEnteredManually => 'Elle girildi';

  @override
  String get medDetailLastVerified => 'Son doğrulama';

  @override
  String get medDetailNotVerified => 'Doğrulanmadı';

  @override
  String get medDetailAddedOn => 'Eklenme tarihi';

  @override
  String get medDetailScheduleTitle => 'Program';

  @override
  String medDetailActiveCount(Object count) {
    return '$count aktif';
  }

  @override
  String get medDetailNoRemindersYet =>
      'Henüz hatırlatma yok. Hatırlatma saatleri siz onaylayana kadar yalnızca etiketten gelen önerilerdir.';

  @override
  String get medDetailNextDose => 'Sıradaki doz';

  @override
  String get medDetailSetUpReminders => 'Hatırlatma oluştur';

  @override
  String get medDetailEditReminders => 'Hatırlatmaları düzenle';

  @override
  String get medDetailRefillTitle => 'Yenileme';

  @override
  String get medDetailRefillTrackMessage =>
      'Elinizde kaç doz kaldığını takip edin, tükenmeden önce yenileme hatırlatması alın.';

  @override
  String medDetailDosesLeft(Object count) {
    return '$count doz kaldı';
  }

  @override
  String get medDetailOutOfRefill =>
      'İlacınız tükenmiş olabilir — yenileme zamanı.';

  @override
  String medDetailDaysLeftAtSchedule(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Mevcut hatırlatma programınızla yaklaşık $days gün yeterli.',
    );
    return '$_temp0';
  }

  @override
  String get medDetailEstimateDaysMessage =>
      'Kaç gün yeteceğini tahmin etmek için hatırlatma oluşturun.';

  @override
  String get medDetailRunningLowTitle => 'Azalıyor';

  @override
  String get medDetailRunningLowMessage =>
      'Bir doz kaçırmamak için yakında yenileme siparişi vermeyi düşünün.';

  @override
  String get medDetailAddPillCount => 'Doz sayısı ekle';

  @override
  String get medDetailUpdatePillCount => 'Doz sayısını güncelle';

  @override
  String get medDetailExpirationTitle => 'Son kullanma tarihi';

  @override
  String get medDetailExpirationEmptyMessage =>
      'Süresi dolmadan önce hatırlatma almak için etikette yazan tarihi ekleyin.';

  @override
  String medDetailExpiredAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Bu ilacın süresi $days gün önce doldu.',
    );
    return '$_temp0';
  }

  @override
  String get medDetailExpiresToday => 'Bu ilacın süresi bugün doluyor.';

  @override
  String medDetailExpiresIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün içinde süresi doluyor.',
    );
    return '$_temp0';
  }

  @override
  String get medDetailExpiredTitle => 'Süresi doldu';

  @override
  String get medDetailExpiringSoonTitle => 'Süresi yakında doluyor';

  @override
  String get medDetailExpiredMessage =>
      'Bu ilacın kullanım için hâlâ güvenli olup olmadığını kontrol edin veya yenisiyle değiştirin.';

  @override
  String get medDetailExpiringSoonMessage =>
      'Süresi dolmadan bir yenisini almayı düşünün.';

  @override
  String get medDetailAddExpiration => 'Son kullanma tarihi ekle';

  @override
  String get medDetailUpdateExpiration => 'Son kullanma tarihini güncelle';

  @override
  String get medDetailExpirationPickerTitle => 'Son kullanma tarihi';

  @override
  String get medDetailViewDoseHistory => 'Doz geçmişini görüntüle';

  @override
  String get medDetailRemoveMedication => 'İlacı kaldır';

  @override
  String get medDetailRemoveDialogTitle => 'Bu ilaç kaldırılsın mı?';

  @override
  String get medDetailRemoveDialogMessage =>
      'Artık listenizde, hatırlatmalarda veya güvenlik kontrollerinde görünmeyecek. Doz geçmişiniz korunur.';

  @override
  String get medDetailKeepIt => 'Kalsın';

  @override
  String get newMedBrandOrGenericRequired =>
      'Bir marka adı veya jenerik ad girin.';

  @override
  String get newMedTitle => 'İlaç ekle';

  @override
  String get newMedSubtitle =>
      'Bilgileri etiketten kopyalayın. \"Doğrulamak için kullanılır\" işaretli alanlar güvenilir bir ilaç veritabanıyla eşleştirilir.';

  @override
  String get newMedUsedToVerifyMessage =>
      'Marka, jenerik ad, doz gücü, form ve etken maddeler bu ürünün doğrulanıp doğrulanamayacağını belirler.';

  @override
  String get newMedHintAsPrinted => 'Kutuda yazdığı gibi';

  @override
  String get newMedDirectionsStoredMessage =>
      'Talimatlar yazıldığı gibi saklanır. Ürünü doğrulamak için kullanılmazlar.';

  @override
  String get newMedSaveButton => 'İlacı kaydet';

  @override
  String get scheduleAddAtLeastOne =>
      'En az bir hatırlatma saati ekleyin ya da bu ilacın hatırlatmalarını kaldırın.';

  @override
  String scheduleInvalidTime(Object time) {
    return '\"$time\" geçerli bir saat değil. 24 saat biçimini kullanın, örneğin 08:00.';
  }

  @override
  String get scheduleConfirmBeforeSaving =>
      'Kaydetmeden önce hatırlatma saatlerini onaylayın.';

  @override
  String get scheduleNotificationPermissionOff =>
      'Hatırlatmalar kaydedildi ama bildirim izni kapalı. iPhone Ayarları\'ndan WellWell için bildirimleri açın.';

  @override
  String get scheduleEditReminderTitle => 'Hatırlatmayı düzenle';

  @override
  String get scheduleFromLabelTitle => 'Etiketten';

  @override
  String get scheduleAddReminderTime => 'Hatırlatma saati ekle';

  @override
  String get scheduleConfirmCheckbox =>
      'Bu hatırlatma saatlerini etiketle karşılaştırıp onayladım.';

  @override
  String get scheduleSaveReminders => 'Hatırlatmaları kaydet';

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String get historySubtitleDefault =>
      'Son iki haftadaki tamamlanan, atlanan ve kaçırılan dozlar.';

  @override
  String historySubtitleMonth(Object month) {
    return '$month ayındaki tamamlanan, atlanan ve kaçırılan dozlar.';
  }

  @override
  String get historyLast2Weeks => 'Son 2 hafta';

  @override
  String get historyAllMedications => 'Tüm ilaçlar';

  @override
  String get historyThisWeek => 'Bu hafta';

  @override
  String get historyDisclaimer =>
      'Bu sayılar ne olduğunu gösterir, ne kadar iyi yaptığınızı değil. Bir örüntü sizi endişelendiriyorsa sağlık uzmanınızla konuşun.';

  @override
  String get historyEmptyTitle => 'Henüz doz kaydedilmedi';

  @override
  String get historyEmptyDescription =>
      'Hatırlatmalar onaylandıktan sonra, alınan, atlanan veya kaçırılan her doz burada görünür.';

  @override
  String get insightsTitle => 'İçgörüler';

  @override
  String get insightsSubtitle =>
      'Son 30 gündeki zamanında alım seriniz ve alışkanlıklarınız.';

  @override
  String insightsStreakDayLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'gün zamanında alım serisi',
    );
    return '$_temp0';
  }

  @override
  String get insightsLast30Days => 'Son 30 gün';

  @override
  String insightsAdherencePercent(Object percent) {
    return 'Çözümlenen dozların %$percent\'\'i zamanında alındı';
  }

  @override
  String insightsWeakestTimeDoses(Object timeOfDay) {
    return '$timeOfDay dozları';
  }

  @override
  String get insightsWeakestTimeMessage =>
      'Günün bu saatinde en çok kaçırma eğilimindesiniz. O saatlerde bir hatırlatma yardımcı olabilir.';

  @override
  String get insightsDisclaimer =>
      'Bu sayılar ne olduğunu gösterir, ne kadar iyi yaptığınızı değil. Tıbbi tavsiye değildir — bir örüntü sizi endişelendiriyorsa sağlık uzmanınızla konuşun.';

  @override
  String get insightsTimeMorning => 'Sabah';

  @override
  String get insightsTimeAfternoon => 'Öğleden sonra';

  @override
  String get insightsTimeEvening => 'Akşam';

  @override
  String get insightsTimeNight => 'Gece';

  @override
  String get emergencyUpdatedSnackbar => 'Acil durum kartınız güncellendi.';

  @override
  String get emergencyUnavailable => 'Kullanılamıyor';

  @override
  String get emergencySubtitle =>
      'Yalnızca seçtiklerinizi paylaşın. QR kod rastgele bir bağlantı taşır, asla tıbbi bilgilerinizi değil.';

  @override
  String get emergencyActiveToggle => 'Acil durum kartı etkin';

  @override
  String get emergencyActiveHint =>
      'Bağlantının çalışmasını durdurmak için bunu kapatın.';

  @override
  String emergencyLastUpdated(Object date) {
    return 'Son güncelleme $date';
  }

  @override
  String get emergencyOffTitle => 'Kart kapalı';

  @override
  String get emergencyOffMessage =>
      'Kart etkin değilken bağlantıyı kimse açamaz.';

  @override
  String get emergencyWhatIsShared => 'Neler paylaşılıyor';

  @override
  String get emergencyAllergies => 'Alerjiler';

  @override
  String get emergencyActiveMedications => 'Kullanılan ilaçlar';

  @override
  String get emergencyContactLabel => 'Acil durum kişisi';

  @override
  String get emergencySaveCard => 'Kartı kaydet';

  @override
  String get emergencyCreateNewQr => 'Yeni bir QR kod oluştur';

  @override
  String get emergencyNewQrDialogTitle => 'Yeni bir QR kod oluşturulsun mu?';

  @override
  String get emergencyNewQrDialogMessage =>
      'Önceki QR kod ve bağlantı hemen çalışmayı durdurur.';

  @override
  String get emergencyKeepCurrent => 'Mevcut olanı sakla';

  @override
  String get emergencyCreateNew => 'Yenisini oluştur';

  @override
  String get emergencyHowItWorksTitle => 'QR kod nasıl çalışır';

  @override
  String get emergencyHowItWorksMessage =>
      'Kod rastgele, iptal edilebilir bir bağlantıya işaret eder. Açıldığında yalnızca açtığınız alanlar görünür, hesap bilgileriniz asla görünmez.';

  @override
  String get emergencyNameShown => 'Görünecek isim';

  @override
  String get emergencyNameShownHint =>
      'Müdahale edenlerin görmesi gereken isim';

  @override
  String get emergencyContactName => 'Acil durum kişisi adı';

  @override
  String get emergencyContactPhone => 'Acil durum kişisi telefonu';

  @override
  String get emergencyImportantNotes => 'Önemli notlar';

  @override
  String get emergencyApplyDetails => 'Bilgileri uygula';

  @override
  String get caregiversSubtitle =>
      'Verilerinizin sahibi siz olmaya devam edersiniz. Bir bakıcı yalnızca onayladığınız şeyleri görür, erişimi istediğiniz zaman kaldırabilirsiniz.';

  @override
  String get caregiversInviteTitle => 'Bir bakıcı davet et';

  @override
  String get caregiversWhatTheyMaySee => 'Neler görebilir';

  @override
  String get caregiversSendInvitation => 'Davet gönder';

  @override
  String get caregiversEnterEmail => 'Bakıcının e-posta adresini girin.';

  @override
  String get caregiversInvitationCreatedTitle => 'Davet oluşturuldu';

  @override
  String get caregiversInvitationCreatedMessage =>
      'Kabul edebilmesi için bu tek kullanımlık kodu bakıcıyla paylaşın.';

  @override
  String get caregiversPeopleWithAccess => 'Erişimi olanlar';

  @override
  String get caregiversEmptyTitle => 'Erişimi olan kimse yok';

  @override
  String get caregiversEmptyDescription =>
      'İlaç rutininizi takip etmesini istediğiniz güvendiğiniz birini davet edin.';

  @override
  String get caregiversStatusInvited => 'Davet gönderildi';

  @override
  String get caregiversStatusWaiting => 'Onayınız bekleniyor';

  @override
  String get caregiversStatusActive => 'Aktif';

  @override
  String get caregiversRemoveAccess => 'Erişimi kaldır';

  @override
  String get caregiversRemoveDialogTitle => 'Bu bakıcı kaldırılsın mı?';

  @override
  String caregiversRemoveDialogMessage(Object name) {
    return '$name artık ilaçlarınızı veya uyumunuzu göremeyecek.';
  }

  @override
  String get caregiversKeepAccess => 'Erişimi koru';

  @override
  String get sharedWithMeSubtitle =>
      'İlaçlarını ve uyumlarını sizinle paylaşan kişiler.';

  @override
  String get sharedWithMeHaveCode => 'Bir davet kodum var';

  @override
  String get sharedWithMeEmptyTitle => 'Henüz kimse sizinle paylaşmadı';

  @override
  String get sharedWithMeEmptyDescription =>
      'Biri sizi bakıcı olarak davet edip davet kodunu kabul ettiğinizde burada görünür.';

  @override
  String get redeemInvalidCode =>
      'Sizinle paylaşılan davet kodunu tam olarak girin.';

  @override
  String get redeemTitle => 'Davet kodunu girin';

  @override
  String get redeemSubtitle =>
      'İlaçlarını ve uyumlarını görmek için kişinin sizinle paylaştığı kodu yapıştırın. Bu yalnızca bir kez çalışır.';

  @override
  String get redeemCodeLabel => 'Davet kodu';

  @override
  String get redeemCodeHint => 'Kopyaladıkları veya sizinle paylaştıkları kod';

  @override
  String get redeemAcceptButton => 'Daveti kabul et';

  @override
  String get sharedDetailEmptyTitle => 'Henüz gösterilecek bir şey yok';

  @override
  String get sharedDetailEmptyDescription =>
      'Bu kişi size ilaçlarına veya uyumuna erişim vermedi.';

  @override
  String get sharedDetailMedicationsTitle => 'İlaçlar';

  @override
  String get sharedDetailNoMedicationsTitle => 'İlaç yok';

  @override
  String get sharedDetailNoMedicationsDescription =>
      'Henüz bir şey eklenmemiş.';

  @override
  String get sharedDetailAdherenceTitle => 'Uyum — son 7 gün';

  @override
  String get sharedDetailNoDosesDescription =>
      'Bu dönemde henüz bir şey olmadı.';

  @override
  String get personalInfoSubtitle =>
      'WellWell\'in size nasıl hitap ettiği ve bu hesaptaki e-posta.';

  @override
  String get personalInfoUpdatedSnackbar => 'İsminiz güncellendi.';

  @override
  String get healthInfoSubtitle =>
      'Alerjiler ve acil durum kişisi bilgileri. Bunlar yalnızca ilgili alanları açtığınızda acil durum kartınızda görünür.';

  @override
  String get healthInfoUpdatedSnackbar => 'Sağlık bilgileriniz güncellendi.';

  @override
  String get notificationsSubtitle =>
      'Hatırlatma uyarılarının kilit ekranında nasıl göründüğü. WellWell her onaylanmış hatırlatma saatinde yerel bir bildirim gönderir.';

  @override
  String get notificationsPrivateToggle => 'Gizli bildirimler';

  @override
  String get notificationsPrivateHint =>
      'Kilit ekranı hatırlatmaları ilacı adıyla anmak yerine \"Bir ilaç hatırlatmanız var\" yazar.';

  @override
  String get privacySubtitle =>
      'WellWell\'in bu cihazdaki ilaç bilgilerini nasıl ele aldığı.';

  @override
  String get privacyOnDeviceTitle => 'Bu cihazda';

  @override
  String get privacyOnDeviceMessage =>
      'Ekran görüntüleri platformun desteklediği yerlerde engellenir, ilaç içeriği uygulama geçişinde gizlenir.';

  @override
  String get privacyHowDecisionsTitle => 'WellWell nasıl karar verir';

  @override
  String get privacyHowDecisionsMessage =>
      'Güvenlik bulguları, güvenilir ilaç verilerine karşı yapılan deterministik kontrollerden gelir. Sade dille açıklamalar yalnızca zaten var olan bulguları anlatır; asla yeni bir bulgu oluşturmaz veya bir bulguyu ortadan kaldırmaz.';

  @override
  String get findingUnavailable => 'Bu güvenlik bulgusu artık mevcut değil.';

  @override
  String get findingWhyTitle => 'Bunu neden görüyorum?';

  @override
  String get findingWhyItMatters => 'Neden önemli';

  @override
  String findingContains(Object ingredient) {
    return 'içeriyor: $ingredient';
  }

  @override
  String get findingThisIngredientFallback => 'bu etken madde';

  @override
  String get findingExplanationUnavailable =>
      'Açıklama şu anda kullanılamıyor. Yukarıdaki bulgu değişmeden kullanılabilir durumda kalır.';

  @override
  String get findingWhatYouCanDo => 'Ne yapabilirsiniz';

  @override
  String get findingDisclaimerFallback =>
      'İlaç etiketlerini gözden geçirin ve emin değilseniz bir eczacı veya sağlık uzmanıyla teyit edin.';

  @override
  String get findingSourcesTitle => 'Kaynaklar';

  @override
  String get findingDataSource => 'Veri kaynağı';

  @override
  String get findingLastChecked => 'Son kontrol';

  @override
  String get findingVerificationLabel => 'Doğrulama';

  @override
  String get findingVerifiedAgainstData => 'Güvenilir verilere göre doğrulandı';

  @override
  String get findingNotIndependentlyVerified => 'Bağımsız olarak doğrulanmadı';

  @override
  String get findingExplanationLabel => 'Açıklama';

  @override
  String get findingAiExplanation => 'AI açıklaması';

  @override
  String get findingStandardExplanation => 'Standart açıklama';

  @override
  String get scanNoCameraAvailable =>
      'Bu cihazda kullanılabilir bir kamera yok.';

  @override
  String get scanCameraAccessNeededError =>
      'Etiketleri okumak için kamera erişimi gerekiyor.';

  @override
  String get scanCameraAccessHeadline =>
      'Etiketleri okumak için kamera erişimi gerekiyor';

  @override
  String get scanCameraAccessMessage =>
      'WellWell ilacın adını ve etken maddelerini etiketten okur. Fotoğraf yalnızca metin çıkarmak için işlenir ve saklanmaz.';

  @override
  String get scanAllowCameraAccess => 'Kamera erişimine izin ver';

  @override
  String get scanEnterLabelTextInstead => 'Bunun yerine etiket metnini gir';

  @override
  String get scanHeaderTitle => 'İlaç etiketini tara';

  @override
  String get scanHeaderSubtitle =>
      'İlaç adını ve etken maddeleri çerçevenin içine yerleştirin.';

  @override
  String get scanReadingLabel => 'Etiket okunuyor…';

  @override
  String get scanOpeningCamera => 'Kamera açılıyor…';

  @override
  String get scanTypeLabelInstead => 'Bunun yerine etiket metnini yaz';

  @override
  String get manualScanEmptyError => 'Önce etikette yazan metni girin.';

  @override
  String get manualScanTitle => 'Etiket metnini yaz';

  @override
  String get manualScanSubtitle =>
      'İlacın adını, etken maddelerini ve talimatları etikette yazdığı gibi kopyalayın. WellWell bunları güvenilir ilaç verileriyle eşleştirir, sonucu siz onaylarsınız.';

  @override
  String get manualScanHint => 'Marka adı\nEtken madde 500 mg\nTalimatlar';

  @override
  String get manualScanDemoTitle => 'Demo turu';

  @override
  String get manualScanDemoMessage =>
      'Doğrulanmış bir eşleşme görmek için örnek Parol etiketini kullanın.';

  @override
  String get manualScanUseSampleButton => 'Örnek etiketi kullan';

  @override
  String get scanReviewNothingTitle => 'İncelenecek bir şey yok';

  @override
  String get scanReviewNothingMessage =>
      'Çıkarılan bilgileri görmek için bir ilaç etiketi tarayın.';

  @override
  String get scanOpenScanner => 'Tarayıcıyı aç';

  @override
  String get scanExtractionFailedTitle => 'Etiketi net okuyamadık';

  @override
  String get scanEnterDetailsManually => 'Bilgileri elle gir';

  @override
  String get scanReviewLowConfidenceTitle => 'Lütfen bilgileri gözden geçirin';

  @override
  String scanReviewLowConfidenceMessage(Object confidence) {
    return 'Etiket %$confidence güvenle okundu. Onaylamadan önce her alanı etiketle karşılaştırın.';
  }

  @override
  String get scanUsedToVerifyMessage =>
      'WellWell bu alanları güvenilir bir ilaç veritabanıyla karşılaştırır. Tarama etiketi yanlış okuduysa düzenleyin.';

  @override
  String get scanOnLabelOnlyMessage =>
      'Bunlar girdiğiniz gibi kalır. Ürünü doğrulamak için kullanılmazlar.';

  @override
  String get scanVerificationTitle => 'Doğrulama';

  @override
  String scanSourceProviderOnly(Object provider) {
    return 'Kaynak: $provider';
  }

  @override
  String scanSourceProviderDataset(Object provider, Object version) {
    return 'Kaynak: $provider · veri kümesi $version';
  }

  @override
  String get scanUnverifiedExplanation =>
      'WellWell bu ürünü ilaç veri kaynağına göre doğrulayamadı. Yine de kaydedebilirsiniz, doğrulanmamış olarak işaretli kalır.';

  @override
  String get scanCandidateMatchesTitle => 'Aday eşleşmeler';

  @override
  String get scanCandidateMatchesSubtitle =>
      'Elinizdeki etikete uyan ürünü seçin.';

  @override
  String scanCandidateMatchLine(Object provider, Object score) {
    return 'Eşleşme %$score · $provider';
  }

  @override
  String get scanSaveUnverifiedTitle => 'Doğrulanmamış olarak kaydedilsin mi?';

  @override
  String get scanSaveUnverifiedCheckbox =>
      'Bu ilacın bağımsız olarak doğrulanmadığını anlıyorum ve bilgileri etiketle karşılaştırdım.';

  @override
  String get scanSaveAsUnverifiedButton => 'Doğrulanmamış olarak kaydet';

  @override
  String get scanConfirmMedicationButton => 'İlacı Onayla';

  @override
  String get scanAgainButton => 'Tekrar tara';

  @override
  String get scanResultNothingTitle => 'Gösterilecek bir şey yok';

  @override
  String get scanResultNothingMessage =>
      'Güvenlik sonucunu görmek için bir ilaç tarayıp onaylayın.';

  @override
  String scanResultSavedTitle(Object name) {
    return '$name kaydedildi';
  }

  @override
  String get scanResultSubtitle =>
      'WellWell bunu listenizdeki mevcut ilaçlarla karşılaştırdı.';

  @override
  String get scanResultSavedMedicationTitle => 'Kaydedilen ilaç';

  @override
  String get scanResultCreateReminders => 'Etiketten hatırlatma oluştur';

  @override
  String get scanResultViewMedication => 'İlacı görüntüle';

  @override
  String get scanResultBackToHome => 'Ana sayfaya dön';

  @override
  String get doseDue => 'Zamanı geldi';

  @override
  String get doseUpcoming => 'Yaklaşıyor';

  @override
  String get doseDetailsOnLabelFallback => 'Doz bilgisi etikette';

  @override
  String domainLastChecked(Object date) {
    return 'Son kontrol $date';
  }

  @override
  String get domainChecksRan => 'WellWell\'in çalıştırdığı kontroller';

  @override
  String get domainSeverityHigh => 'Yüksek öncelik';

  @override
  String get domainSeverityWarning => 'Dikkat gerekiyor';

  @override
  String get domainSeverityInfo => 'Bilgi';

  @override
  String get domainBothProductsContain => 'Her iki ürün de içeriyor';

  @override
  String domainSourceDetected(Object date, Object source) {
    return 'Kaynak: $source · Tespit: $date';
  }

  @override
  String domainSourceDatasetDetected(
    Object date,
    Object source,
    Object version,
  ) {
    return 'Kaynak: $source · veri kümesi $version · Tespit: $date';
  }

  @override
  String get domainAiSummary => 'AI özeti';

  @override
  String get progressComplete => 'tamamlandı';

  @override
  String get scanResultTitleGeneric => 'Tarama sonucu';

  @override
  String get medDetailDosesRemainingTitle => 'Kalan doz';

  @override
  String get medDetailDosesRemainingMessage =>
      'Elinizde kaç doz (hap, sprey vb.) kaldığını girin. Temizlemek için boş bırakın.';

  @override
  String get medDetailDosesRemainingHint => 'örn. 30';

  @override
  String get appSettingsSubtitle =>
      'Cihaz kilidi ve WellWell\'in bu telefonda nasıl davrandığı.';

  @override
  String get appSettingsBiometricLabel => 'Biyometrik uygulama kilidi';

  @override
  String get appSettingsBiometricHint =>
      'Uygulama arka planda kaldıktan sonra Face ID, parmak izi veya cihaz şifresi istesin.';

  @override
  String get appSettingsDeviceLockUnavailableTitle =>
      'Cihaz kilidi kullanılamıyor';

  @override
  String get appSettingsDeviceLockUnavailableMessage =>
      'Önce bu cihazda bir şifre, parmak izi veya yüz tanıma ayarlayın, sonra uygulama kilidini açın.';

  @override
  String get reminderNotificationTitle => 'İlaç hatırlatması';

  @override
  String get reminderNotificationPrivacyBody => 'Bir ilaç hatırlatmanız var.';

  @override
  String get reminderRefillNotificationTitle => 'Yenileme hatırlatması';

  @override
  String get reminderRefillPrivacyBody =>
      'İlaçlarınızdan biri azalıyor. Yenileme zamanı.';

  @override
  String reminderRefillBody(int days, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$name için yaklaşık $days gününüz kaldı. Yenileme zamanı.',
    );
    return '$_temp0';
  }

  @override
  String get reminderExpiringSoonTitle => 'Süresi yakında doluyor';

  @override
  String get reminderExpiringSoonPrivacyBody =>
      'İlaçlarınızdan birinin süresi yakında doluyor.';

  @override
  String reminderExpiringSoonBody(Object date, Object name) {
    return '$name son kullanma tarihi: $date.';
  }

  @override
  String get reminderExpiredTitle => 'Süresi doldu';

  @override
  String get reminderExpiredPrivacyBody =>
      'İlaçlarınızdan birinin süresi doldu.';

  @override
  String reminderExpiredBody(Object date, Object name) {
    return '$name ilacının süresi $date tarihinde doldu. Kullanmadan önce etiketi kontrol edin ve eczacınıza danışın.';
  }
}
