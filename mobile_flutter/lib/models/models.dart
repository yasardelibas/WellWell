String _str(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

String? _strN(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

bool _bool(dynamic v, [bool fallback = false]) => v is bool ? v : fallback;

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double _double(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

class User {
  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.timeZoneId,
    required this.safetyNoticeAcknowledged,
    required this.privacyNotificationsEnabled,
    required this.biometricLockEnabled,
    required this.isDemoAccount,
    required this.emailVerified,
  });

  final String id;
  final String email;
  final String displayName;
  final String timeZoneId;
  final bool safetyNoticeAcknowledged;
  final bool privacyNotificationsEnabled;
  final bool biometricLockEnabled;
  final bool isDemoAccount;
  final bool emailVerified;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: _str(json['id']),
        email: _str(json['email']),
        displayName: _str(json['displayName']),
        timeZoneId: _str(json['timeZoneId'], 'UTC'),
        safetyNoticeAcknowledged: _bool(json['safetyNoticeAcknowledged']),
        privacyNotificationsEnabled: _bool(json['privacyNotificationsEnabled'], true),
        biometricLockEnabled: _bool(json['biometricLockEnabled']),
        isDemoAccount: _bool(json['isDemoAccount']),
        emailVerified: _bool(json['emailVerified'], true),
      );
}

class AuthResponse {
  AuthResponse({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final User user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: _str(json['accessToken']),
        refreshToken: _str(json['refreshToken']),
        user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      );
}

class Ingredient {
  Ingredient({
    required this.id,
    required this.normalizedName,
    required this.originalName,
    required this.displayStrength,
    this.rxCui,
    this.strength,
    this.unit,
  });

  final String id;
  final String normalizedName;
  final String originalName;
  final String displayStrength;
  final String? rxCui;
  final String? strength;
  final String? unit;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: _str(json['id']),
        normalizedName: _str(json['normalizedName']),
        originalName: _str(json['originalName']),
        displayStrength: _str(json['displayStrength']),
        rxCui: _strN(json['rxCui']),
        strength: json['strength']?.toString(),
        unit: _strN(json['unit']),
      );
}

class Provenance {
  Provenance({required this.provider, this.externalIdentifier, required this.retrievedAt, this.datasetVersion});

  final String provider;
  final String? externalIdentifier;
  final String retrievedAt;
  final String? datasetVersion;

  factory Provenance.fromJson(Map<String, dynamic> json) => Provenance(
        provider: _str(json['provider']),
        externalIdentifier: _strN(json['externalIdentifier']),
        retrievedAt: _str(json['retrievedAt']),
        datasetVersion: _strN(json['datasetVersion']),
      );
}

class Medication {
  Medication({
    required this.id,
    required this.displayName,
    required this.brandName,
    required this.genericName,
    required this.verificationStatus,
    required this.verificationLabel,
    required this.ingredients,
    required this.activeScheduleCount,
    this.remainingQuantity,
    this.remainingUpdatedAt,
    this.rxCui,
    this.dosageForm,
    this.strength,
    this.route,
    this.labelDirections,
    this.manufacturer,
    this.notes,
    this.provenance,
  });

  final String id;
  final String displayName;
  final String brandName;
  final String genericName;
  final String? rxCui;
  final String? dosageForm;
  final String? strength;
  final String? route;
  final String? labelDirections;
  final String? manufacturer;
  final String? notes;
  final String verificationStatus;
  final String verificationLabel;
  final List<Ingredient> ingredients;
  final Provenance? provenance;
  final int activeScheduleCount;
  final int? remainingQuantity;
  final DateTime? remainingUpdatedAt;

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: _str(json['id']),
        displayName: _str(json['displayName']),
        brandName: _str(json['brandName']),
        genericName: _str(json['genericName']),
        rxCui: _strN(json['rxCui']),
        dosageForm: _strN(json['dosageForm']),
        strength: _strN(json['strength']),
        route: _strN(json['route']),
        labelDirections: _strN(json['labelDirections']),
        manufacturer: _strN(json['manufacturer']),
        notes: _strN(json['notes']),
        verificationStatus: _str(json['verificationStatus'] ?? json['VerificationStatus']).toLowerCase(),
        verificationLabel: _str(json['verificationLabel'] ?? json['VerificationLabel'], 'Unverified'),
        ingredients: (json['ingredients'] as List? ?? [])
            .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        provenance: json['provenance'] is Map
            ? Provenance.fromJson(Map<String, dynamic>.from(json['provenance'] as Map))
            : null,
        activeScheduleCount: _int(json['activeScheduleCount']),
        remainingQuantity: json['remainingQuantity'] == null ? null : _int(json['remainingQuantity']),
        remainingUpdatedAt:
            json['remainingUpdatedAt'] == null ? null : DateTime.tryParse(_str(json['remainingUpdatedAt'])),
      );
}

class ExtractedField {
  ExtractedField({this.value, required this.confidence, required this.source});

  final String? value;
  final double confidence;
  final String source;

  factory ExtractedField.fromJson(Map<String, dynamic> json) => ExtractedField(
        value: _strN(json['value']),
        confidence: _double(json['confidence']),
        source: _str(json['source']),
      );
}

class IngredientInput {
  IngredientInput({required this.name, this.strength, this.unit});

  final String name;
  final String? strength;
  final String? unit;

  factory IngredientInput.fromJson(Map<String, dynamic> json) => IngredientInput(
        name: _str(json['name']),
        strength: _strN(json['strength']),
        unit: _strN(json['unit']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'strength': strength,
        'unit': unit,
      };
}

class MedicationCandidate {
  MedicationCandidate({
    this.rxCui,
    required this.brandName,
    required this.genericName,
    required this.ingredients,
    this.dosageForm,
    this.strength,
    required this.matchScore,
    required this.provenance,
  });

  final String? rxCui;
  final String brandName;
  final String genericName;
  final List<IngredientInput> ingredients;
  final String? dosageForm;
  final String? strength;
  final double matchScore;
  final Provenance provenance;

  factory MedicationCandidate.fromJson(Map<String, dynamic> json) => MedicationCandidate(
        rxCui: _strN(json['rxCui']),
        brandName: _str(json['brandName']),
        genericName: _str(json['genericName']),
        ingredients: (json['ingredients'] as List? ?? [])
            .map((e) => IngredientInput.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        dosageForm: _strN(json['dosageForm']),
        strength: _strN(json['strength']),
        matchScore: _double(json['matchScore']),
        provenance: Provenance.fromJson(Map<String, dynamic>.from(json['provenance'] as Map? ?? {})),
      );
}

class ScheduleSuggestion {
  ScheduleSuggestion({
    this.labelInstruction,
    required this.timesPerDay,
    required this.suggestedTimes,
    this.doseAmountText,
  });

  final String? labelInstruction;
  final int timesPerDay;
  final List<String> suggestedTimes;
  final String? doseAmountText;

  factory ScheduleSuggestion.fromJson(Map<String, dynamic> json) => ScheduleSuggestion(
        labelInstruction: _strN(json['labelInstruction']),
        timesPerDay: _int(json['timesPerDay']),
        suggestedTimes: (json['suggestedTimes'] as List? ?? []).map((e) => e.toString()).toList(),
        doseAmountText: _strN(json['doseAmountText']),
      );
}

class ScanResponse {
  ScanResponse({
    required this.scanId,
    required this.status,
    required this.extractionConfidence,
    required this.verificationStatus,
    required this.message,
    required this.candidates,
    this.scheduleSuggestion,
    this.extraction,
  });

  final String scanId;
  final String status;
  final double extractionConfidence;
  final String verificationStatus;
  final String message;
  final Map<String, dynamic>? extraction;
  final List<MedicationCandidate> candidates;
  final ScheduleSuggestion? scheduleSuggestion;

  factory ScanResponse.fromJson(Map<String, dynamic> json) => ScanResponse(
        scanId: _str(json['scanId']),
        status: _str(json['status']),
        extractionConfidence: _double(json['extractionConfidence']),
        verificationStatus: _str(json['verificationStatus']).toLowerCase(),
        message: _str(json['message']),
        extraction: json['extraction'] is Map ? Map<String, dynamic>.from(json['extraction'] as Map) : null,
        candidates: (json['candidates'] as List? ?? [])
            .map((e) => MedicationCandidate.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        scheduleSuggestion: json['scheduleSuggestion'] is Map
            ? ScheduleSuggestion.fromJson(Map<String, dynamic>.from(json['scheduleSuggestion'] as Map))
            : null,
      );

  String field(String key) {
    final block = extraction?[key];
    if (block is Map) return _strN(block['value']) ?? '';
    return '';
  }

  List<Map<String, String>> get extractedIngredients {
    final raw = extraction?['activeIngredients'];
    if (raw is! List) return [];
    return raw.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final name = map['name'] is Map ? _strN((map['name'] as Map)['value']) ?? '' : '';
      final strength = map['strength'] is Map ? _strN((map['strength'] as Map)['value']) ?? '' : '';
      final unit = map['unit'] is Map ? _strN((map['unit'] as Map)['value']) ?? '' : '';
      return {'name': name, 'strength': strength, 'unit': unit};
    }).toList();
  }
}

class SafetyIngredient {
  SafetyIngredient({required this.name, this.identifier, this.identifierSystem});

  final String name;
  final String? identifier;
  final String? identifierSystem;

  factory SafetyIngredient.fromJson(Map<String, dynamic> json) => SafetyIngredient(
        name: _str(json['name']),
        identifier: _strN(json['identifier']),
        identifierSystem: _strN(json['identifierSystem']),
      );
}

class SafetyMedication {
  SafetyMedication({
    required this.id,
    required this.name,
    this.ingredientOriginalName,
    this.strengthText,
    required this.verified,
  });

  final String id;
  final String name;
  final String? ingredientOriginalName;
  final String? strengthText;
  final bool verified;

  factory SafetyMedication.fromJson(Map<String, dynamic> json) => SafetyMedication(
        id: _str(json['id']),
        name: _str(json['name']),
        ingredientOriginalName: _strN(json['ingredientOriginalName']),
        strengthText: _strN(json['strengthText']),
        verified: _bool(json['verified']),
      );
}

class SafetyFinding {
  SafetyFinding({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.medications,
    required this.verified,
    required this.source,
    required this.detectedAt,
    this.ingredient,
    this.datasetVersion,
  });

  final String id;
  final String severity;
  final String title;
  final String message;
  final SafetyIngredient? ingredient;
  final List<SafetyMedication> medications;
  final bool verified;
  final String source;
  final String? datasetVersion;
  final String detectedAt;

  factory SafetyFinding.fromJson(Map<String, dynamic> json) => SafetyFinding(
        id: _str(json['id']),
        severity: _str(json['severity']),
        title: _str(json['title']),
        message: _str(json['message']),
        ingredient: json['ingredient'] is Map
            ? SafetyIngredient.fromJson(Map<String, dynamic>.from(json['ingredient'] as Map))
            : null,
        medications: (json['medications'] as List? ?? [])
            .map((e) => SafetyMedication.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        verified: _bool(json['verified']),
        source: _str(json['source']),
        datasetVersion: _strN(json['datasetVersion']),
        detectedAt: _str(json['detectedAt']),
      );
}

class SafetyCheck {
  SafetyCheck({required this.check, required this.state, this.detail});

  final String check;
  final String state;
  final String? detail;

  factory SafetyCheck.fromJson(Map<String, dynamic> json) => SafetyCheck(
        check: _str(json['check']),
        state: _str(json['state']),
        detail: _strN(json['detail']),
      );
}

class SafetyAnalysis {
  SafetyAnalysis({
    required this.status,
    required this.headline,
    required this.subtext,
    required this.findings,
    required this.checks,
    required this.analyzedAt,
  });

  final String status;
  final String headline;
  final String subtext;
  final List<SafetyFinding> findings;
  final List<SafetyCheck> checks;
  final String analyzedAt;

  factory SafetyAnalysis.fromJson(Map<String, dynamic> json) => SafetyAnalysis(
        status: _str(json['status']),
        headline: _str(json['headline']),
        subtext: _str(json['subtext']),
        findings: (json['findings'] as List? ?? [])
            .map((e) => SafetyFinding.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        checks: (json['checks'] as List? ?? [])
            .map((e) => SafetyCheck.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((c) => c.check != 'drug_interaction')
            .toList(),
        analyzedAt: _str(json['analyzedAt']),
      );
}

class SafetyExplanation {
  SafetyExplanation({
    required this.findingId,
    required this.explanation,
    required this.generatedByAi,
    required this.source,
    required this.disclaimer,
  });

  final String findingId;
  final String explanation;
  final bool generatedByAi;
  final String source;
  final String disclaimer;

  factory SafetyExplanation.fromJson(Map<String, dynamic> json) => SafetyExplanation(
        findingId: _str(json['findingId']),
        explanation: _str(json['explanation']),
        generatedByAi: _bool(json['generatedByAi']),
        source: _str(json['source']),
        disclaimer: _str(json['disclaimer']),
      );
}

class ConfirmScanResponse {
  ConfirmScanResponse({required this.medication, required this.safety, this.scheduleSuggestion});

  final Medication medication;
  final SafetyAnalysis safety;
  final ScheduleSuggestion? scheduleSuggestion;

  factory ConfirmScanResponse.fromJson(Map<String, dynamic> json) => ConfirmScanResponse(
        medication: Medication.fromJson(Map<String, dynamic>.from(json['medication'] as Map)),
        safety: SafetyAnalysis.fromJson(Map<String, dynamic>.from(json['safety'] as Map)),
        scheduleSuggestion: json['scheduleSuggestion'] is Map
            ? ScheduleSuggestion.fromJson(Map<String, dynamic>.from(json['scheduleSuggestion'] as Map))
            : null,
      );
}

class Schedule {
  Schedule({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.time,
    required this.userConfirmed,
    required this.isActive,
    this.labelInstruction,
    this.doseAmountText,
  });

  final String id;
  final String medicationId;
  final String medicationName;
  final String time;
  final String? labelInstruction;
  final String? doseAmountText;
  final bool userConfirmed;
  final bool isActive;

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        id: _str(json['id']),
        medicationId: _str(json['medicationId']),
        medicationName: _str(json['medicationName']),
        time: _str(json['time']),
        labelInstruction: _strN(json['labelInstruction']),
        doseAmountText: _strN(json['doseAmountText']),
        userConfirmed: _bool(json['userConfirmed']),
        isActive: _bool(json['isActive'], true),
      );
}

class Dose {
  Dose({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.medicationName,
    required this.scheduledAt,
    required this.scheduledTime,
    required this.status,
    required this.statusLabel,
    this.strengthText,
    this.doseAmountText,
    this.completedAt,
  });

  final String id;
  final String medicationId;
  final String scheduleId;
  final String medicationName;
  final String? strengthText;
  final String? doseAmountText;
  final String scheduledAt;
  final String scheduledTime;
  final String status;
  final String statusLabel;
  final String? completedAt;

  factory Dose.fromJson(Map<String, dynamic> json) => Dose(
        id: _str(json['id']),
        medicationId: _str(json['medicationId']),
        scheduleId: _str(json['scheduleId']),
        medicationName: _str(json['medicationName']),
        strengthText: _strN(json['strengthText']),
        doseAmountText: _strN(json['doseAmountText']),
        scheduledAt: _str(json['scheduledAt']),
        scheduledTime: _str(json['scheduledTime']),
        status: _str(json['status']),
        statusLabel: _str(json['statusLabel']),
        completedAt: _strN(json['completedAt']),
      );
}

class TodaySchedule {
  TodaySchedule({
    required this.date,
    required this.doses,
    required this.completedCount,
    required this.totalCount,
    required this.progressLabel,
  });

  final String date;
  final List<Dose> doses;
  final int completedCount;
  final int totalCount;
  final String progressLabel;

  factory TodaySchedule.fromJson(Map<String, dynamic> json) => TodaySchedule(
        date: _str(json['date']),
        doses: (json['doses'] as List? ?? []).map((e) => Dose.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        completedCount: _int(json['completedCount']),
        totalCount: _int(json['totalCount']),
        progressLabel: _str(json['progressLabel']),
      );
}

class AdherenceDay {
  AdherenceDay({required this.date, required this.doses});

  final String date;
  final List<Dose> doses;

  factory AdherenceDay.fromJson(Map<String, dynamic> json) => AdherenceDay(
        date: _str(json['date']),
        doses: (json['doses'] as List? ?? []).map((e) => Dose.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
}

class AdherenceHistory {
  AdherenceHistory({
    required this.from,
    required this.to,
    required this.days,
    required this.takenCount,
    required this.skippedCount,
    required this.missedCount,
    required this.pendingCount,
  });

  final String from;
  final String to;
  final List<AdherenceDay> days;
  final int takenCount;
  final int skippedCount;
  final int missedCount;
  final int pendingCount;

  factory AdherenceHistory.fromJson(Map<String, dynamic> json) => AdherenceHistory(
        from: _str(json['from']),
        to: _str(json['to']),
        days: (json['days'] as List? ?? [])
            .map((e) => AdherenceDay.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        takenCount: _int(json['takenCount']),
        skippedCount: _int(json['skippedCount']),
        missedCount: _int(json['missedCount']),
        pendingCount: _int(json['pendingCount']),
      );
}

class AdherenceSummary {
  AdherenceSummary({
    required this.takenCount,
    required this.skippedCount,
    required this.missedCount,
    required this.pendingCount,
    required this.adherencePercent,
    required this.message,
    required this.generatedByAi,
  });

  final int takenCount;
  final int skippedCount;
  final int missedCount;
  final int pendingCount;
  final int adherencePercent;
  final String message;
  final bool generatedByAi;

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) => AdherenceSummary(
        takenCount: _int(json['takenCount']),
        skippedCount: _int(json['skippedCount']),
        missedCount: _int(json['missedCount']),
        pendingCount: _int(json['pendingCount']),
        adherencePercent: _int(json['adherencePercent']),
        message: _str(json['message']),
        generatedByAi: _bool(json['generatedByAi']),
      );
}

class DailyNudge {
  DailyNudge({
    required this.completedCount,
    required this.totalCount,
    required this.message,
    required this.generatedByAi,
  });

  final int completedCount;
  final int totalCount;
  final String message;
  final bool generatedByAi;

  factory DailyNudge.fromJson(Map<String, dynamic> json) => DailyNudge(
        completedCount: _int(json['completedCount']),
        totalCount: _int(json['totalCount']),
        message: _str(json['message']),
        generatedByAi: _bool(json['generatedByAi']),
      );
}

class MedicationEducation {
  MedicationEducation({
    required this.message,
    required this.generatedByAi,
    required this.isAvailable,
    required this.usedFor,
    this.drugClass,
  });

  final String message;
  final bool generatedByAi;
  final bool isAvailable;
  final List<String> usedFor;
  final String? drugClass;

  bool get hasContent => isAvailable || usedFor.isNotEmpty || (drugClass?.isNotEmpty ?? false);

  factory MedicationEducation.fromJson(Map<String, dynamic> json) => MedicationEducation(
        message: _str(json['message']),
        generatedByAi: _bool(json['generatedByAi']),
        isAvailable: _bool(json['isAvailable']),
        usedFor: (json['usedFor'] as List? ?? []).map((e) => e.toString()).toList(),
        drugClass: _strN(json['drugClass']),
      );
}

class AdherenceInsights {
  AdherenceInsights({
    required this.takenCount,
    required this.skippedCount,
    required this.missedCount,
    required this.pendingCount,
    required this.adherencePercent,
    required this.streakDays,
    required this.weakestTimeOfDay,
    required this.message,
    required this.generatedByAi,
  });

  final int takenCount;
  final int skippedCount;
  final int missedCount;
  final int pendingCount;
  final int adherencePercent;
  final int streakDays;
  final String? weakestTimeOfDay;
  final String message;
  final bool generatedByAi;

  factory AdherenceInsights.fromJson(Map<String, dynamic> json) => AdherenceInsights(
        takenCount: _int(json['takenCount']),
        skippedCount: _int(json['skippedCount']),
        missedCount: _int(json['missedCount']),
        pendingCount: _int(json['pendingCount']),
        adherencePercent: _int(json['adherencePercent']),
        streakDays: _int(json['streakDays']),
        weakestTimeOfDay: json['weakestTimeOfDay'] as String?,
        message: _str(json['message']),
        generatedByAi: _bool(json['generatedByAi']),
      );
}

class EmergencyCard {
  EmergencyCard({
    required this.isEnabled,
    required this.shareName,
    required this.shareAllergies,
    required this.shareMedications,
    required this.shareEmergencyContact,
    required this.shareNotes,
    required this.shareUrl,
    required this.updatedAt,
    this.displayName,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.notes,
    this.tokenExpiresAt,
  });

  final bool isEnabled;
  final bool shareName;
  final bool shareAllergies;
  final bool shareMedications;
  final bool shareEmergencyContact;
  final bool shareNotes;
  final String? displayName;
  final String? allergies;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? notes;
  final String shareUrl;
  final String? tokenExpiresAt;
  final String updatedAt;

  factory EmergencyCard.fromJson(Map<String, dynamic> json) => EmergencyCard(
        isEnabled: _bool(json['isEnabled']),
        shareName: _bool(json['shareName']),
        shareAllergies: _bool(json['shareAllergies']),
        shareMedications: _bool(json['shareMedications']),
        shareEmergencyContact: _bool(json['shareEmergencyContact']),
        shareNotes: _bool(json['shareNotes']),
        displayName: _strN(json['displayName']),
        allergies: _strN(json['allergies']),
        emergencyContactName: _strN(json['emergencyContactName']),
        emergencyContactPhone: _strN(json['emergencyContactPhone']),
        notes: _strN(json['notes']),
        shareUrl: _str(json['shareUrl']),
        tokenExpiresAt: _strN(json['tokenExpiresAt']),
        updatedAt: _str(json['updatedAt']),
      );

  Map<String, dynamic> toUpdateBody() => {
        'isEnabled': isEnabled,
        'shareName': shareName,
        'shareAllergies': shareAllergies,
        'shareMedications': shareMedications,
        'shareEmergencyContact': shareEmergencyContact,
        'shareNotes': shareNotes,
        'displayName': displayName,
        'allergies': allergies,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'notes': notes,
      };

  EmergencyCard copyWith({
    bool? isEnabled,
    bool? shareName,
    bool? shareAllergies,
    bool? shareMedications,
    bool? shareEmergencyContact,
    bool? shareNotes,
    String? displayName,
    String? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? notes,
  }) {
    return EmergencyCard(
      isEnabled: isEnabled ?? this.isEnabled,
      shareName: shareName ?? this.shareName,
      shareAllergies: shareAllergies ?? this.shareAllergies,
      shareMedications: shareMedications ?? this.shareMedications,
      shareEmergencyContact: shareEmergencyContact ?? this.shareEmergencyContact,
      shareNotes: shareNotes ?? this.shareNotes,
      displayName: displayName ?? this.displayName,
      allergies: allergies ?? this.allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      notes: notes ?? this.notes,
      shareUrl: shareUrl,
      tokenExpiresAt: tokenExpiresAt,
      updatedAt: updatedAt,
    );
  }
}

class Caregiver {
  Caregiver({
    required this.id,
    required this.email,
    required this.status,
    required this.permissions,
    required this.createdAt,
    this.displayName,
    this.acceptedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String status;
  final List<String> permissions;
  final String createdAt;
  final String? acceptedAt;

  factory Caregiver.fromJson(Map<String, dynamic> json) => Caregiver(
        id: _str(json['id']),
        email: _str(json['email']),
        displayName: _strN(json['displayName']),
        status: _str(json['status']),
        permissions: (json['permissions'] as List? ?? []).map((e) => e.toString()).toList(),
        createdAt: _str(json['createdAt']),
        acceptedAt: _strN(json['acceptedAt']),
      );
}
