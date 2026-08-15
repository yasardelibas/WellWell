import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/models.dart';
import 'secure_store.dart';

class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  NetworkException([this.message = "We couldn't reach MedGuard. Check your connection and try again."]);
  final String message;

  @override
  String toString() => message;
}

String describeError(Object error) {
  if (error is ApiException || error is NetworkException) return error.toString();
  return 'Something went wrong. Please try again.';
}

class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null && options.extra['anonymous'] != true) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final anonymous = error.requestOptions.extra['anonymous'] == true;
          if (status == 401 && !anonymous && !_isRefreshing) {
            final refreshed = await refreshTokens();
            if (refreshed) {
              final req = error.requestOptions;
              req.headers['Authorization'] = 'Bearer $_accessToken';
              try {
                final retry = await _dio.fetch(req);
                return handler.resolve(retry);
              } catch (e) {
                return handler.next(error);
              }
            }
            await clearTokens();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://164-90-169-182.sslip.io',
  );

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;
  void Function()? onSessionExpired;

  Future<void> loadTokens() async {
    _accessToken = await SecureStore.read(SecureStore.accessToken);
    _refreshToken = await SecureStore.read(SecureStore.refreshToken);
  }

  Future<void> persistTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await SecureStore.write(SecureStore.accessToken, access);
    await SecureStore.write(SecureStore.refreshToken, refresh);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await SecureStore.delete(SecureStore.accessToken);
    await SecureStore.delete(SecureStore.refreshToken);
  }

  Future<bool> refreshTokens() async {
    final current = _refreshToken;
    if (current == null) return false;
    _isRefreshing = true;
    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': current},
        options: Options(extra: {'anonymous': true}),
      );
      final auth = AuthResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
      await persistTokens(auth.accessToken, auth.refreshToken);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<T> get<T>(String path, T Function(dynamic data) parse, {Map<String, dynamic>? query}) {
    return _send('GET', path, parse, query: query);
  }

  Future<T> post<T>(
    String path,
    T Function(dynamic data) parse, {
    Object? body,
    bool anonymous = false,
  }) {
    return _send('POST', path, parse, body: body, anonymous: anonymous);
  }

  Future<T> put<T>(String path, T Function(dynamic data) parse, {Object? body}) {
    return _send('PUT', path, parse, body: body);
  }

  Future<T> delete<T>(String path, T Function(dynamic data) parse) {
    return _send('DELETE', path, parse);
  }

  Future<T> _send<T>(
    String method,
    String path,
    T Function(dynamic data) parse, {
    Object? body,
    Map<String, dynamic>? query,
    bool anonymous = false,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          extra: {'anonymous': anonymous},
          contentType: body == null ? null : 'application/json',
        ),
      );
      if (response.statusCode == 204 || response.data == null || (response.data is String && (response.data as String).isEmpty)) {
        return parse(null);
      }
      return parse(response.data);
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw NetworkException('The request took too long. Please try again.');
      }
      if (error.type == DioExceptionType.connectionError) {
        throw NetworkException();
      }
      final status = error.response?.statusCode ?? 0;
      final data = error.response?.data;
      if (data is Map) {
        throw ApiException(
          status,
          data['code']?.toString() ?? 'http_$status',
          data['message']?.toString() ?? data['title']?.toString() ?? 'Something went wrong. Please try again.',
        );
      }
      if (status == 429) {
        // Covers proxy-level 429s that arrive without our JSON body.
        throw ApiException(429, 'rate_limited', 'Too many requests. Please wait a moment and try again.');
      }
      throw ApiException(status, 'http_error', 'Something went wrong. Please try again.');
    }
  }
}

final apiClient = ApiClient();

Map<String, dynamic> _map(dynamic data) => Map<String, dynamic>.from(data as Map);

class Api {
  static Future<AuthResponse> login(String email, String password) => apiClient.post(
        '/api/auth/login',
        (d) => AuthResponse.fromJson(_map(d)),
        body: {'email': email, 'password': password},
        anonymous: true,
      );

  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
    String? timeZoneId,
  }) =>
      apiClient.post(
        '/api/auth/register',
        (d) => AuthResponse.fromJson(_map(d)),
        body: {
          'email': email,
          'password': password,
          'displayName': displayName,
          'timeZoneId': timeZoneId,
        },
        anonymous: true,
      );

  static Future<AuthResponse> demoLogin() => apiClient.post(
        '/api/demo/login',
        (d) => AuthResponse.fromJson(_map(d)),
        anonymous: true,
      );

  static Future<void> forgotPassword(String email) => apiClient.post(
        '/api/auth/forgot-password',
        (_) {},
        body: {'email': email},
        anonymous: true,
      );

  static Future<void> logout(String? refreshToken) => apiClient.post(
        '/api/auth/logout',
        (_) {},
        body: {'refreshToken': refreshToken},
        anonymous: true,
      );

  static Future<User> me() => apiClient.get('/api/me', (d) => User.fromJson(_map(d)));

  static Future<User> updateProfile(Map<String, dynamic> body) =>
      apiClient.put('/api/me', (d) => User.fromJson(_map(d)), body: body);

  static Future<User> acknowledgeSafetyNotice() =>
      apiClient.post('/api/me/acknowledge-safety-notice', (d) => User.fromJson(_map(d)));

  static Future<User> verifyEmail(String code) =>
      apiClient.post('/api/me/verify-email', (d) => User.fromJson(_map(d)), body: {'code': code});

  static Future<void> resendVerificationCode() =>
      apiClient.post('/api/me/resend-verification-code', (_) {});

  static Future<List<Medication>> medications() => apiClient.get(
        '/api/medications',
        (d) => (d as List).map((e) => Medication.fromJson(_map(e))).toList(),
      );

  static Future<Medication> medication(String id) =>
      apiClient.get('/api/medications/$id', (d) => Medication.fromJson(_map(d)));

  static Future<MedicationEducation> medicationEducation(String id) =>
      apiClient.get('/api/medications/$id/education', (d) => MedicationEducation.fromJson(_map(d)));

  static Future<Medication> createMedication(Map<String, dynamic> body) =>
      apiClient.post('/api/medications', (d) => Medication.fromJson(_map(d)), body: body);

  static Future<Medication> updateMedication(String id, Map<String, dynamic> body) =>
      apiClient.put('/api/medications/$id', (d) => Medication.fromJson(_map(d)), body: body);

  static Future<void> deleteMedication(String id) => apiClient.delete('/api/medications/$id', (_) {});

  static Future<Medication> setRefill(String id, int? remainingQuantity) => apiClient.put(
        '/api/medications/$id/refill',
        (d) => Medication.fromJson(_map(d)),
        body: {'remainingQuantity': remainingQuantity},
      );

  static Future<ScanResponse> scan(Map<String, dynamic> body) =>
      apiClient.post('/api/medications/scan', (d) => ScanResponse.fromJson(_map(d)), body: body);

  static Future<ConfirmScanResponse> confirmScan(String scanId, Map<String, dynamic> body) =>
      apiClient.post('/api/medications/scan/$scanId/confirm', (d) => ConfirmScanResponse.fromJson(_map(d)), body: body);

  static Future<SafetyAnalysis> analyzeSafety([String? medicationId]) => apiClient.post(
        '/api/safety/analyze',
        (d) => SafetyAnalysis.fromJson(_map(d)),
        body: {'medicationId': medicationId},
      );

  static Future<List<SafetyFinding>> findings() => apiClient.get(
        '/api/safety/findings',
        (d) => (d as List).map((e) => SafetyFinding.fromJson(_map(e))).toList(),
      );

  static Future<SafetyExplanation> explanation(String id) =>
      apiClient.get('/api/safety/findings/$id/explanation', (d) => SafetyExplanation.fromJson(_map(d)));

  static Future<List<Schedule>> schedules([String? medicationId]) => apiClient.get(
        '/api/schedules',
        (d) => (d as List).map((e) => Schedule.fromJson(_map(e))).toList(),
        query: medicationId == null ? null : {'medicationId': medicationId},
      );

  static Future<ScheduleSuggestion> scheduleSuggestion(String medicationId) => apiClient.get(
        '/api/schedules/suggestion',
        (d) => ScheduleSuggestion.fromJson(_map(d)),
        query: {'medicationId': medicationId},
      );

  static Future<List<Schedule>> saveSchedule(Map<String, dynamic> body) => apiClient.post(
        '/api/schedules',
        (d) => (d as List).map((e) => Schedule.fromJson(_map(e))).toList(),
        body: body,
      );

  static Future<TodaySchedule> today() =>
      apiClient.get('/api/adherence/today', (d) => TodaySchedule.fromJson(_map(d)));

  static Future<AdherenceHistory> history({String? medicationId}) => apiClient.get(
        '/api/adherence/history',
        (d) => AdherenceHistory.fromJson(_map(d)),
        query: medicationId == null ? null : {'medicationId': medicationId},
      );

  static Future<AdherenceSummary> adherenceSummary() =>
      apiClient.get('/api/adherence/summary', (d) => AdherenceSummary.fromJson(_map(d)));

  static Future<DailyNudge> adherenceNudge() =>
      apiClient.get('/api/adherence/nudge', (d) => DailyNudge.fromJson(_map(d)));

  static Future<AdherenceInsights> adherenceInsights() =>
      apiClient.get('/api/adherence/insights', (d) => AdherenceInsights.fromJson(_map(d)));

  static Future<Dose> markTaken(String doseId) =>
      apiClient.post('/api/doses/$doseId/taken', (d) => Dose.fromJson(_map(d)));

  static Future<Dose> markSkipped(String doseId) =>
      apiClient.post('/api/doses/$doseId/skip', (d) => Dose.fromJson(_map(d)));

  static Future<Dose> snooze(String doseId, [int minutes = 15]) =>
      apiClient.post('/api/doses/$doseId/snooze', (d) => Dose.fromJson(_map(d)), body: {'minutes': minutes});

  static Future<EmergencyCard> emergencyCard() =>
      apiClient.get('/api/emergency-card', (d) => EmergencyCard.fromJson(_map(d)));

  static Future<EmergencyCard> updateEmergencyCard(Map<String, dynamic> body) =>
      apiClient.put('/api/emergency-card', (d) => EmergencyCard.fromJson(_map(d)), body: body);

  static Future<EmergencyCard> regenerateEmergency() =>
      apiClient.post('/api/emergency-card/regenerate', (d) => EmergencyCard.fromJson(_map(d)));

  static Future<List<Caregiver>> caregivers() => apiClient.get(
        '/api/caregivers',
        (d) => (d as List).map((e) => Caregiver.fromJson(_map(e))).toList(),
      );

  static Future<Map<String, dynamic>> inviteCaregiver(String email, List<String> permissions) =>
      apiClient.post('/api/caregivers/invitations', (d) => _map(d), body: {'email': email, 'permissions': permissions});

  static Future<Caregiver> updateCaregiverPermissions(String id, List<String> permissions) => apiClient.put(
        '/api/caregivers/$id/permissions',
        (d) => Caregiver.fromJson(_map(d)),
        body: {'permissions': permissions},
      );

  static Future<void> revokeCaregiver(String id) => apiClient.delete('/api/caregivers/$id', (_) {});
}

String prettyJson(Object? value) => const JsonEncoder.withIndent('  ').convert(value);
