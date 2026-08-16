import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/language_controller.dart';
import 'screens/extra_screens.dart';
import 'screens/flow_screens.dart';
import 'screens/scan_screens.dart';
import 'screens/tabs.dart';
import 'services/reminders.dart';
import 'state/auth.dart';
import 'theme/app_theme.dart';
import 'theme/palette.dart';
import 'theme/theme_controller.dart';
import 'widgets/brand_wave.dart';
import 'widgets/ui.dart';

class WellWellApp extends ConsumerStatefulWidget {
  const WellWellApp({super.key});

  @override
  ConsumerState<WellWellApp> createState() => _WellWellAppState();
}

class _WellWellAppState extends ConsumerState<WellWellApp> with WidgetsBindingObserver {
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
        GoRoute(path: '/shared-with-me', builder: (_, _) => const SharedWithMeScreen()),
        GoRoute(path: '/shared-with-me/redeem', builder: (_, _) => const RedeemInvitationScreen()),
        GoRoute(
          path: '/shared-with-me/:id',
          builder: (_, state) => SharedDetailScreen(
            relationshipId: state.pathParameters['id']!,
            ownerLabel: state.extra as String?,
          ),
        ),
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
    Reminders.onNotificationTap = (medicationId) => _router.push('/medication/$medicationId');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Reminders.onNotificationTap = null;
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

  // When the user's preference is "System", a system-level light/dark change must also
  // re-resolve Palette's live brightness, since Palette.x call sites read mutable state
  // rather than watching a widget.
  @override
  void didChangePlatformBrightness() {
    if (AppTheme.modeNotifier.value == ThemeMode.system) setState(() {});
  }

  Future<void> _unlock() async {
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: 'Unlock WellWell to see your medications.',
        biometricOnly: false,
      );
      if (ok && mounted) setState(() => locked = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.modeNotifier,
      builder: (context, themeMode, _) {
        final lightTheme = buildTheme(Brightness.light);
        final darkTheme = buildTheme(Brightness.dark);
        // buildTheme() leaves Palette pointed at whichever brightness it built last (dark,
        // above) - resolve and set the *live* brightness now, after both themes exist, so
        // every other Palette.x call site during this build sees the mode actually in effect.
        final resolved = switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        Palette.setBrightness(resolved);

        return ValueListenableBuilder<Locale?>(
          valueListenable: AppLanguage.localeNotifier,
          builder: (context, locale, _) => MaterialApp.router(
          title: 'WellWell',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (locked)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
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
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: Palette.hero, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: BrandWaves(color: Colors.white, opacity: 0.12, anchor: WaveAnchor.both),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LogoMark(size: 96),
                SizedBox(height: 16),
                Text('WELLWELL', style: TextStyle(color: Colors.white70, letterSpacing: 4, fontSize: 12)),
                SizedBox(height: 8),
                Text('Feel well. Live well.', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
