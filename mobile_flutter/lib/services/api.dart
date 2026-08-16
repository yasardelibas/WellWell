import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../l10n/language_controller.dart';
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
  NetworkException([this.message = "We couldn't reach WellWell. Check your connection and try again."]);
  final String message;

  @override
  String toString() => message;
}

// The ~50 backend error codes aren't individually translated (see the plan: it's cheaper to
// localize by code on this side than to touch every backend throw site). Only the handful a
// user is likely to actually see are mapped; anything else falls back to the server's English
// message, which is always present.
const _errorMessagesByCodeTr = {
  'invalid_credentials': 'E-posta veya şifre hatalı.',
  'email_in_use': 'Bu e-posta ile bir hesap zaten var.',
  'medication_not_found': 'Bu ilaç listenizde yok.',
  'invalid_refresh_token': 'Lütfen tekrar giriş yapın.',
  'refresh_token_reused': 'Lütfen tekrar giriş yapın.',
  'finding_not_found': 'Bu güvenlik bulgusu artık mevcut değil.',
  'invitation_not_found': 'Bu davet artık geçerli değil.',
  'invitation_expired': 'Bu davet artık geçerli değil.',
  'invitation_mismatch': 'Bu davet farklı bir e-posta adresine gönderilmişti.',
  'caregiver_not_found': 'Bu kişi hesabınıza bağlı bir bakıcı değil.',
  'card_not_available': 'Bu acil durum kartı kullanılamıyor.',
  'demo_disabled': 'Demo hesabı şu anda kullanılamıyor.',
  'dose_not_found': 'Bu doz artık mevcut değil.',
  'image_too_large': 'Çekilen görüntü çok büyük. Lütfen tekrar deneyin.',
  'incorrect_code': 'Bu kod doğru değil.',
  'invalid_caregiver': 'Kendinizi bakıcı olarak davet edemezsiniz.',
  'invalid_image': 'Çekilen görüntü okunamadı.',
  'invalid_or_expired_code': 'Yeni bir kod isteyip tekrar deneyin.',
  'invalid_range': 'Başlangıç tarihi bitiş tarihinden önce olmalı.',
  'invalid_reset_token': 'Bu sıfırlama bağlantısı artık geçerli değil.',
  'nothing_to_read': 'Bir görüntü veya etiket metni girin.',
  'permission_denied': 'Bu bilgiye erişiminiz yok.',
  'scan_already_handled': 'Bu tarama zaten onaylandı veya reddedildi.',
  'scan_not_found': 'Bu tarama artık mevcut değil. Lütfen tekrar tarayın.',
  'schedule_not_found': 'Bu hatırlatma artık mevcut değil.',
};

String _currentLanguageCode() => AppLanguage.currentCode;

String describeError(Object error) {
  if (error is ApiException) {
    if (_currentLanguageCode() == 'tr') {
      final localized = _errorMessagesByCodeTr[error.code];
      if (localized != null) return localized;
    }
    return error.toString();
  }
  if (error is NetworkException) {
    return _currentLanguageCode() == 'tr'
        ? "WellWell'e ulaşılamadı. Bağlantınızı kontrol edip tekrar deneyin."
        : error.toString();
  }
  return _currentLanguageCode() == 'tr' ? 'Bir şeyler ters gitti. Lütfen tekrar deneyin.' : 'Something went wrong. Please try again.';
}

/// Dio equivalent of a Polly retry policy. Only idempotent GET requests are
/// retried, and only for transient failures (cold connection errors, timeouts,
/// dropped sockets, 429, and 500/502/503/504 — all common while the backend and
/// its reverse proxy warm up on the first request after an idle period).
/// Non-idempotent writes and real client/auth errors (e.g. 400/401/404) are
/// never retried.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const _maxRetries = 4;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra['retry_attempt'] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= _maxRetries) {
      return handler.next(err);
    }

    final next = attempt + 1;
    await Future<void>.delayed(_backoff(next, err));
    if (options.extra['retry_attempt'] == null) {
      // Fresh copy of extra so the counter travels with the retried request.
      options.extra = Map<String, dynamic>.from(options.extra);
    }
    options.extra['retry_attempt'] = next;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        // Sockets dropped mid-handshake during a cold start surface here (often
        // wrapping a SocketException/HandshakeException) with no HTTP response.
        return err.response == null;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status == 429 || status == 500 || status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }

  Duration _backoff(int attempt, DioException err) {
    // Honour a server-provided Retry-After (seconds) for 429s when present.
    final retryAfter = err.response?.headers.value('retry-after');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter.trim());
      if (seconds != null) {
        return Duration(milliseconds: (seconds.clamp(0, 10)) * 1000);
      }
    }
    // Exponential backoff: ~400ms, 800ms, 1600ms, 3200ms, plus jitter to avoid
    // synchronized retries when several GETs fail together on a cold start.
    final base = 400 * (1 << (attempt - 1));
    final jitter = Random().nextInt(250);
    return Duration(milliseconds: base + jitter);
  }
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
          final alreadyRetried = error.requestOptions.extra['auth_retried'] == true;
          if (status == 401 && !anonymous && !alreadyRetried) {
            // Concurrent 401s (e.g. the Home screen firing several GETs at once)
            // all await the same refresh instead of racing; losers used to fall
            // through and fail with "something went wrong" on the first load.
            final refreshed = await refreshTokens();
            if (refreshed) {
              final req = error.requestOptions;
              req.extra = Map<String, dynamic>.from(req.extra)..['auth_retried'] = true;
              req.headers['Authorization'] = 'Bearer $_accessToken';
              try {
                final retry = await _dio.fetch(req);
                return handler.resolve(retry);
              } catch (e) {
                return handler.next(e is DioException ? e : error);
              }
            }
            await clearTokens();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
    // Resilience for flaky first requests (cold connections, transient 5xx/429).
    // The .NET side uses Polly; this is the Dio-side equivalent: retry idempotent
    // GETs a few times with exponential backoff + jitter before surfacing an error.
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://164-90-169-182.sslip.io',
  );

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshing;
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

  /// Dedupes concurrent refreshes: every caller awaits the same in-flight
  /// refresh so a rotated refresh token is never spent twice in parallel.
  Future<bool> refreshTokens() {
    return _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _performRefresh() async {
    final current = _refreshToken;
    if (current == null) return false;
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

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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

  static Future<Medication> setExpiration(String id, DateTime? expirationDate) => apiClient.put(
        '/api/medications/$id/expiration',
        (d) => Medication.fromJson(_map(d)),
        body: {'expirationDate': expirationDate == null ? null : _dateOnly(expirationDate)},
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

  static Future<AdherenceHistory> history({String? medicationId, DateTime? from, DateTime? to}) => apiClient.get(
        '/api/adherence/history',
        (d) => AdherenceHistory.fromJson(_map(d)),
        query: {
          if (medicationId != null) 'medicationId': medicationId,
          if (from != null) 'from': _dateOnly(from),
          if (to != null) 'to': _dateOnly(to),
        },
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

  static Future<Caregiver> acceptCaregiverInvitation(String id, String token) => apiClient.post(
        '/api/caregivers/invitations/$id/accept',
        (d) => Caregiver.fromJson(_map(d)),
        body: {'token': token},
      );

  static Future<List<SharedCaregiver>> sharedWithMe() => apiClient.get(
        '/api/caregivers/shared-with-me',
        (d) => (d as List).map((e) => SharedCaregiver.fromJson(_map(e))).toList(),
      );

  static Future<List<Medication>> sharedMedications(String relationshipId) => apiClient.get(
        '/api/caregivers/shared-with-me/$relationshipId/medications',
        (d) => (d as List).map((e) => Medication.fromJson(_map(e))).toList(),
      );

  static Future<AdherenceHistory> sharedAdherence(String relationshipId) => apiClient.get(
        '/api/caregivers/shared-with-me/$relationshipId/adherence',
        (d) => AdherenceHistory.fromJson(_map(d)),
      );
}

String prettyJson(Object? value) => const JsonEncoder.withIndent('  ').convert(value);
