/**
 * Wire types mirroring MedGuard.Contracts. Kept hand-written and minimal so the
 * client never invents fields the backend does not actually return.
 */

export interface ApiErrorBody {
  code: string;
  message: string;
  details?: Record<string, string[]> | null;
}

export interface User {
  id: string;
  email: string;
  displayName: string;
  timeZoneId: string;
  safetyNoticeAcknowledged: boolean;
  privacyNotificationsEnabled: boolean;
  biometricLockEnabled: boolean;
  isDemoAccount: boolean;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  expiresInSeconds: number;
  user: User;
}

export type VerificationStatus = 'verified' | 'unverified' | 'verification_unavailable' | 'no_confident_match';

export interface Provenance {
  provider: string;
  externalIdentifier: string | null;
  retrievedAt: string;
  datasetVersion: string | null;
}

export interface Ingredient {
  id: string;
  normalizedName: string;
  originalName: string;
  strength: number | null;
  unit: string | null;
  rxCui: string | null;
  displayStrength: string;
}

export interface IngredientInput {
  name: string;
  strength?: number | null;
  unit?: string | null;
  rxCui?: string | null;
}

export interface Medication {
  id: string;
  displayName: string;
  brandName: string;
  genericName: string;
  rxCui: string | null;
  dosageForm: string | null;
  strength: string | null;
  route: string | null;
  labelDirections: string | null;
  manufacturer: string | null;
  notes: string | null;
  verificationStatus: string;
  verificationLabel: string;
  ingredients: Ingredient[];
  provenance: Provenance | null;
  activeScheduleCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreateMedicationRequest {
  brandName?: string | null;
  genericName?: string | null;
  ingredients: IngredientInput[];
  dosageForm?: string | null;
  strength?: string | null;
  route?: string | null;
  labelDirections?: string | null;
  notes?: string | null;
  attemptVerification?: boolean;
}

export type UpdateMedicationRequest = Omit<CreateMedicationRequest, 'ingredients' | 'attemptVerification'> & {
  ingredients?: IngredientInput[] | null;
};

export interface ExtractedField {
  value: string | null;
  confidence: number;
  source: string;
}

export interface ExtractedIngredient {
  name: ExtractedField;
  strength: ExtractedField | null;
  unit: ExtractedField | null;
}

export interface LabelExtraction {
  brandName: ExtractedField;
  genericName: ExtractedField;
  activeIngredients: ExtractedIngredient[];
  dosageForm: ExtractedField;
  route: ExtractedField;
  directions: ExtractedField;
  manufacturer: ExtractedField;
  expirationDate: ExtractedField;
}

export interface MedicationCandidate {
  rxCui: string | null;
  brandName: string;
  genericName: string;
  ingredients: IngredientInput[];
  dosageForm: string | null;
  strength: string | null;
  manufacturer: string | null;
  matchScore: number;
  provenance: Provenance;
}

export interface ScheduleSuggestion {
  labelInstruction: string | null;
  timesPerDay: number;
  suggestedTimes: string[];
  doseAmountText: string | null;
  requiresUserConfirmation: boolean;
}

export interface ScanResponse {
  scanId: string;
  status: string;
  extractionConfidence: number;
  requiresManualReview: boolean;
  verificationStatus: string;
  message: string;
  extraction: LabelExtraction | null;
  candidates: MedicationCandidate[];
  scheduleSuggestion: ScheduleSuggestion | null;
}

export interface ScanRequest {
  imageBase64?: string | null;
  mimeType?: string | null;
  ocrText?: string | null;
  retainImage?: boolean;
}

export interface ConfirmScanRequest {
  selectedCandidateRxCui?: string | null;
  brandName?: string | null;
  genericName?: string | null;
  ingredients?: IngredientInput[] | null;
  dosageForm?: string | null;
  strength?: string | null;
  route?: string | null;
  labelDirections?: string | null;
  acknowledgedUnverified?: boolean;
}

export interface ConfirmScanResponse {
  medication: Medication;
  safety: SafetyAnalysis;
  scheduleSuggestion: ScheduleSuggestion | null;
}

export type SafetyStatus = 'no_findings' | 'attention' | 'warning' | 'high';

export type SafetySeverity = 'info' | 'warning' | 'high';

export interface SafetyIngredient {
  name: string;
  identifier: string | null;
  identifierSystem: string | null;
}

export interface SafetyMedication {
  id: string;
  name: string;
  ingredientOriginalName: string | null;
  strengthText: string | null;
  verified: boolean;
}

export interface SafetyFinding {
  id: string;
  type: string;
  severity: string;
  title: string;
  message: string;
  ingredient: SafetyIngredient | null;
  medications: SafetyMedication[];
  verified: boolean;
  source: string;
  datasetVersion: string | null;
  detectedAt: string;
}

export interface SafetyCheck {
  check: string;
  state: string;
  detail: string | null;
}

export interface SafetyAnalysis {
  status: SafetyStatus | string;
  headline: string;
  subtext: string;
  findings: SafetyFinding[];
  checks: SafetyCheck[];
  analyzedAt: string;
}

export interface SafetyExplanation {
  findingId: string;
  explanation: string;
  generatedByAi: boolean;
  source: string;
  disclaimer: string;
}

export interface Schedule {
  id: string;
  medicationId: string;
  medicationName: string;
  time: string;
  labelInstruction: string | null;
  doseAmountText: string | null;
  userConfirmed: boolean;
  isActive: boolean;
}

export interface CreateScheduleRequest {
  medicationId: string;
  times: string[];
  labelInstruction?: string | null;
  doseAmountText?: string | null;
  userConfirmed: boolean;
}

export type DoseStatus = 'pending' | 'taken' | 'skipped' | 'missed' | 'snoozed' | string;

export interface Dose {
  id: string;
  medicationId: string;
  scheduleId: string;
  medicationName: string;
  strengthText: string | null;
  doseAmountText: string | null;
  scheduledAt: string;
  scheduledTime: string;
  status: DoseStatus;
  statusLabel: string;
  completedAt: string | null;
  snoozedUntil: string | null;
}

export interface TodaySchedule {
  date: string;
  doses: Dose[];
  completedCount: number;
  totalCount: number;
  progressLabel: string;
}

export interface AdherenceDay {
  date: string;
  doses: Dose[];
}

export interface AdherenceHistory {
  from: string;
  to: string;
  days: AdherenceDay[];
  takenCount: number;
  skippedCount: number;
  missedCount: number;
  pendingCount: number;
}

export interface EmergencyCard {
  isEnabled: boolean;
  shareName: boolean;
  shareAllergies: boolean;
  shareMedications: boolean;
  shareEmergencyContact: boolean;
  shareNotes: boolean;
  displayName: string | null;
  allergies: string | null;
  emergencyContactName: string | null;
  emergencyContactPhone: string | null;
  notes: string | null;
  shareUrl: string;
  tokenIssuedAt: string;
  tokenExpiresAt: string | null;
  updatedAt: string;
}

export type UpdateEmergencyCardRequest = Omit<
  EmergencyCard,
  'shareUrl' | 'tokenIssuedAt' | 'tokenExpiresAt' | 'updatedAt'
>;

export interface Caregiver {
  id: string;
  email: string;
  displayName: string | null;
  status: string;
  permissions: string[];
  createdAt: string;
  acceptedAt: string | null;
}

export interface CaregiverInvitation {
  caregiver: Caregiver;
  invitationToken: string | null;
}

export interface UpdateProfileRequest {
  displayName?: string | null;
  timeZoneId?: string | null;
  privacyNotificationsEnabled?: boolean | null;
  biometricLockEnabled?: boolean | null;
}
