import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api.dart';
import '../services/reminders.dart';
import '../services/secure_store.dart';

enum AuthStatus { loading, signedOut, signedIn }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.sessionExpired = false,
    this.onboardingCompleted = false,
  });

  final AuthStatus status;
  final User? user;
  final bool sessionExpired;
  final bool onboardingCompleted;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? sessionExpired,
    bool? onboardingCompleted,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      sessionExpired: sessionExpired ?? this.sessionExpired,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(bootstrap);
    return const AuthState(status: AuthStatus.loading);
  }

  Future<void> bootstrap() async {
    var onboardingCompleted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
      apiClient.onSessionExpired = () {
        state = AuthState(status: AuthStatus.signedOut, sessionExpired: true, onboardingCompleted: onboardingCompleted);
      };
      await apiClient.loadTokens();
      final cached = await SecureStore.read(SecureStore.user);
      User? cachedUser;
      if (cached != null) {
        try {
          cachedUser = User.fromJson(jsonDecode(cached) as Map<String, dynamic>);
          state = AuthState(status: AuthStatus.signedIn, user: cachedUser, onboardingCompleted: onboardingCompleted);
        } catch (_) {}
      }

      try {
        if (await SecureStore.read(SecureStore.accessToken) == null) {
          state = AuthState(status: AuthStatus.signedOut, onboardingCompleted: onboardingCompleted);
          return;
        }
        final user = await Api.me();
        await _cache(user);
        state = AuthState(status: AuthStatus.signedIn, user: user, onboardingCompleted: onboardingCompleted);
        unawaited(Reminders.syncFromServer(privacyMode: user.privacyNotificationsEnabled));
      } catch (_) {
        if (cachedUser == null) {
          await apiClient.clearTokens();
          state = AuthState(status: AuthStatus.signedOut, onboardingCompleted: onboardingCompleted);
        }
      }
    } catch (_) {
      state = AuthState(status: AuthStatus.signedOut, onboardingCompleted: onboardingCompleted);
    }
  }

  Future<void> _apply(AuthResponse auth) async {
    await apiClient.persistTokens(auth.accessToken, auth.refreshToken);
    await _cache(auth.user);
    state = AuthState(
      status: AuthStatus.signedIn,
      user: auth.user,
      onboardingCompleted: state.onboardingCompleted,
    );
    unawaited(Reminders.syncFromServer(privacyMode: auth.user.privacyNotificationsEnabled));
  }

  Future<void> _cache(User user) async {
    await SecureStore.write(SecureStore.user, jsonEncode({
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'timeZoneId': user.timeZoneId,
      'safetyNoticeAcknowledged': user.safetyNoticeAcknowledged,
      'privacyNotificationsEnabled': user.privacyNotificationsEnabled,
      'biometricLockEnabled': user.biometricLockEnabled,
      'isDemoAccount': user.isDemoAccount,
      'emailVerified': user.emailVerified,
    }));
  }

  Future<void> signIn(String email, String password) async {
    await _apply(await Api.login(email.trim(), password));
  }

  Future<void> signUp({required String email, required String password, required String displayName}) async {
    await _apply(await Api.register(
      email: email.trim(),
      password: password,
      displayName: displayName.trim(),
      timeZoneId: DateTime.now().timeZoneName,
    ));
  }

  Future<void> signInWithDemo() async {
    await _apply(await Api.demoLogin());
  }

  Future<void> signOut() async {
    final refresh = await SecureStore.read(SecureStore.refreshToken);
    try {
      await Api.logout(refresh);
    } catch (_) {}
    await apiClient.clearTokens();
    await SecureStore.delete(SecureStore.user);
    state = AuthState(status: AuthStatus.signedOut, onboardingCompleted: state.onboardingCompleted);
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    final user = await Api.updateProfile(body);
    await _cache(user);
    state = state.copyWith(user: user);
  }

  Future<void> acknowledgeSafetyNotice() async {
    final user = await Api.acknowledgeSafetyNotice();
    await _cache(user);
    state = state.copyWith(user: user);
  }

  Future<void> verifyEmail(String code) async {
    final user = await Api.verifyEmail(code);
    await _cache(user);
    state = state.copyWith(user: user);
  }

  Future<void> resendVerificationCode() => Api.resendVerificationCode();

  void markOnboardingDone() {
    state = state.copyWith(onboardingCompleted: true);
  }
}

Future<void> setOnboardingDone(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboardingCompleted', true);
  ref.read(authProvider.notifier).markOnboardingDone();
}

class ScanHolder {
  ScanResponse? scan;
  ConfirmScanResponse? outcome;
}

final scanHolder = ScanHolder();

final scanTabActiveProvider = StateProvider<bool>((ref) => false);

final dataRevisionProvider = StateProvider<int>((ref) => 0);
