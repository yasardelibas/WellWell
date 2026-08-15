import { api, request } from '@/services/api/client';
import type {
  AdherenceHistory,
  AuthResponse,
  Caregiver,
  CaregiverInvitation,
  ConfirmScanRequest,
  ConfirmScanResponse,
  CreateMedicationRequest,
  CreateScheduleRequest,
  Dose,
  EmergencyCard,
  Medication,
  SafetyAnalysis,
  SafetyExplanation,
  SafetyFinding,
  Schedule,
  ScanRequest,
  ScanResponse,
  ScheduleSuggestion,
  TodaySchedule,
  UpdateEmergencyCardRequest,
  UpdateMedicationRequest,
  UpdateProfileRequest,
  User,
} from '@/types/api';

export const authApi = {
  register: (body: { email: string; password: string; displayName: string; timeZoneId?: string | null }) =>
    request<AuthResponse>('/api/auth/register', { method: 'POST', body, anonymous: true }),
  login: (body: { email: string; password: string }) =>
    request<AuthResponse>('/api/auth/login', { method: 'POST', body, anonymous: true }),
  demoLogin: () => request<AuthResponse>('/api/demo/login', { method: 'POST', anonymous: true }),
  forgotPassword: (body: { email: string }) =>
    request<void>('/api/auth/forgot-password', { method: 'POST', body, anonymous: true }),
  resetPassword: (body: { token: string; newPassword: string }) =>
    request<void>('/api/auth/reset-password', { method: 'POST', body, anonymous: true }),
  logout: (refreshToken: string | null) =>
    request<void>('/api/auth/logout', { method: 'POST', body: { refreshToken }, anonymous: true }),
  me: () => api.get<User>('/api/me'),
  updateProfile: (body: UpdateProfileRequest) => api.put<User>('/api/me', body),
  acknowledgeSafetyNotice: () => api.post<User>('/api/me/acknowledge-safety-notice'),
};

export const medicationsApi = {
  list: () => api.get<Medication[]>('/api/medications'),
  get: (id: string) => api.get<Medication>(`/api/medications/${id}`),
  create: (body: CreateMedicationRequest) => api.post<Medication>('/api/medications', body),
  update: (id: string, body: UpdateMedicationRequest) => api.put<Medication>(`/api/medications/${id}`, body),
  remove: (id: string) => api.delete<void>(`/api/medications/${id}`),
};

export const scanApi = {
  submit: (body: ScanRequest) => api.post<ScanResponse>('/api/medications/scan', body),
  confirm: (scanId: string, body: ConfirmScanRequest) =>
    api.post<ConfirmScanResponse>(`/api/medications/scan/${scanId}/confirm`, body),
};

export const safetyApi = {
  analyze: (medicationId?: string) => api.post<SafetyAnalysis>('/api/safety/analyze', { medicationId: medicationId ?? null }),
  findings: () => api.get<SafetyFinding[]>('/api/safety/findings'),
  explanation: (findingId: string) => api.get<SafetyExplanation>(`/api/safety/findings/${findingId}/explanation`),
};

export const schedulesApi = {
  list: (medicationId?: string) => api.get<Schedule[]>('/api/schedules', { medicationId }),
  suggestion: (medicationId: string) => api.get<ScheduleSuggestion>('/api/schedules/suggestion', { medicationId }),
  create: (body: CreateScheduleRequest) => api.post<Schedule[]>('/api/schedules', body),
  update: (id: string, body: { time?: string | null; doseAmountText?: string | null; isActive?: boolean | null }) =>
    api.put<Schedule>(`/api/schedules/${id}`, body),
  remove: (id: string) => api.delete<void>(`/api/schedules/${id}`),
};

export const adherenceApi = {
  today: () => api.get<TodaySchedule>('/api/adherence/today'),
  history: (params?: { from?: string; to?: string; medicationId?: string }) =>
    api.get<AdherenceHistory>('/api/adherence/history', params),
  markTaken: (doseId: string) => api.post<Dose>(`/api/doses/${doseId}/taken`),
  markSkipped: (doseId: string) => api.post<Dose>(`/api/doses/${doseId}/skip`),
  snooze: (doseId: string, minutes = 15) => api.post<Dose>(`/api/doses/${doseId}/snooze`, { minutes }),
};

export const emergencyApi = {
  get: () => api.get<EmergencyCard>('/api/emergency-card'),
  update: (body: UpdateEmergencyCardRequest) => api.put<EmergencyCard>('/api/emergency-card', body),
  regenerate: () => api.post<EmergencyCard>('/api/emergency-card/regenerate'),
};

export const caregiversApi = {
  list: () => api.get<Caregiver[]>('/api/caregivers'),
  invite: (body: { email: string; permissions: string[] }) =>
    api.post<CaregiverInvitation>('/api/caregivers/invitations', body),
  updatePermissions: (id: string, permissions: string[]) =>
    api.put<Caregiver>(`/api/caregivers/${id}/permissions`, { permissions }),
  revoke: (id: string) => api.delete<void>(`/api/caregivers/${id}`),
  sharedWithMe: () => api.get<Caregiver[]>('/api/caregivers/shared-with-me'),
  sharedMedications: (id: string) => api.get<Medication[]>(`/api/caregivers/shared-with-me/${id}/medications`),
  sharedAdherence: (id: string) => api.get<AdherenceHistory>(`/api/caregivers/shared-with-me/${id}/adherence`),
};
