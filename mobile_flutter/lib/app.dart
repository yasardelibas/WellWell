import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import 'screens/extra_screens.dart';
import 'screens/flow_screens.dart';
import 'screens/scan_screens.dart';
import 'screens/tabs.dart';
import 'state/auth.dart';
import 'theme/app_theme.dart';
import 'theme/palette.dart';

class MedGuardApp extends ConsumerStatefulWidget {
  const MedGuardApp({super.key});

  @override
  ConsumerState<MedGuardApp> createState() => _MedGuardAppState();
}

class _MedGuardAppState extends ConsumerState<MedGuardApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final ValueNotifier<int> _refresh;
  bool locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh = ValueNotifier(0);
    ref.listenManual(authProvider, (_, _) => _refresh.value++);
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _refresh,
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final loc = state.matchedLocation;
        if (auth.status == AuthStatus.loading) {
          return loc == '/splash' ? null : '/splash';
        }
        if (auth.status == AuthStatus.signedOut) {
          if (!auth.onboardingCompleted) {
            return loc == '/onboarding' ? null : '/onboarding';
          }
          const allowed = ['/auth', '/forgot-password'];
          return allowed.contains(loc) ? null : '/auth';
        }
        final user = auth.user;
        if (user != null && !user.emailVerified) {
          return loc == '/verify-email' ? null : '/verify-email';
        }
        if (user != null && !user.safetyNoticeAcknowledged) {
          return loc == '/safety-notice' ? null : '/safety-notice';
        }
        const gated = ['/splash', '/onboarding', '/auth', '/forgot-password', '/verify-email', '/safety-notice'];
        if (gated.contains(loc)) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
        GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
        GoRoute(path: '/verify-email', builder: (_, _) => const VerifyEmailScreen()),
        GoRoute(path: '/safety-notice', builder: (_, _) => const SafetyNoticeScreen()),
        GoRoute(path: '/scan/review', builder: (_, _) => const ScanReviewScreen()),
        GoRoute(path: '/scan/manual', builder: (_, _) => const ManualScanScreen()),
        GoRoute(path: '/scan/result', builder: (_, _) => const ScanResultScreen()),
        GoRoute(path: '/medication/new', builder: (_, _) => const NewMedicationScreen()),
        GoRoute(
          path: '/medication/:id',
          builder: (_, state) => MedicationDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/schedule/:medicationId',
          builder: (_, state) => ScheduleScreen(medicationId: state.pathParameters['medicationId']!),
        ),
        GoRoute(
          path: '/history',
          builder: (_, state) => HistoryScreen(medicationId: state.uri.queryParameters['medicationId']),
        ),
        GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
        GoRoute(path: '/emergency', builder: (_, _) => const EmergencyScreen()),
        GoRoute(path: '/caregivers', builder: (_, _) => const CaregiversScreen()),
        GoRoute(path: '/personal-info', builder: (_, _) => const PersonalInfoScreen()),
        GoRoute(path: '/health-info', builder: (_, _) => const HealthInfoScreen()),
        GoRoute(path: '/app-settings', builder: (_, _) => const AppSettingsScreen()),
        GoRoute(path: '/notification-settings', builder: (_, _) => const NotificationSettingsScreen()),
        GoRoute(path: '/privacy-settings', builder: (_, _) => const PrivacySettingsScreen()),
        GoRoute(
          path: '/finding/:id',
          builder: (_, state) => FindingExplanationScreen(id: state.pathParameters['id']!),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => TabsShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/medications', builder: (_, _) => const MedicationsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/scan', builder: (_, _) => const ScanScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/safety', builder: (_, _) => const SafetyScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final enabled = ref.read(authProvider).user?.biometricLockEnabled == true;
    if (state == AppLifecycleState.paused && enabled) {
      setState(() => locked = true);
    } else if (state == AppLifecycleState.resumed && locked) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: 'Unlock MedGuard to see your medications.',
        biometricOnly: false,
      );
      if (ok && mounted) setState(() => locked = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedGuard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (locked)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: Palette.hero, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Center(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Palette.brand),
                      onPressed: _unlock,
                      child: const Text('Unlock'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: Palette.hero, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 88, color: Colors.white),
            SizedBox(height: 16),
            Text('MEDGUARD', style: TextStyle(color: Colors.white70, letterSpacing: 4, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
