import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api.dart';
import '../state/auth.dart';
import '../theme/palette.dart';
import '../widgets/brand_wave.dart';
import '../widgets/ui.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;

  Future<void> finish() async {
    await setOnboardingDone(ref);
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHero = step == 0;
    final body = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: i == step ? 32 : 16,
                  decoration: BoxDecoration(
                    color: i == step
                        ? (isHero ? Colors.white : Palette.brand)
                        : (isHero ? Colors.white30 : Palette.line),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            Expanded(
              child: step == 0
                  ? const _Welcome()
                  : step == 1
                      ? const _Capabilities()
                      : const _Safety(),
            ),
            if (step < 2)
              isHero
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Palette.brand),
                        onPressed: () => setState(() => step++),
                        child: Text(l10n.onboardingGetStarted),
                      ),
                    )
                  : PrimaryButton(label: l10n.commonNext, onPressed: () => setState(() => step++))
            else
              PrimaryButton(label: l10n.commonIUnderstand, onPressed: finish),
            if (step < 2)
              TextButton(
                onPressed: () => setState(() => step = 2),
                child: Text(l10n.onboardingSkip, style: TextStyle(color: isHero ? Colors.white : Palette.brand)),
              ),
          ],
        ),
      ),
    );

    if (!isHero) {
      return Scaffold(
        backgroundColor: Palette.canvas,
        body: Stack(
          children: [
            Positioned.fill(
              child: BrandWaves(color: Palette.teal, opacity: 0.07),
            ),
            body,
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: Palette.hero, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: BrandWaves(color: Colors.white, opacity: 0.12, anchor: WaveAnchor.both),
          ),
          Scaffold(backgroundColor: Colors.transparent, body: body),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LogoMark(size: 96, onDark: true),
        const SizedBox(height: 16),
        const Text('WELLWELL', style: TextStyle(color: Colors.white70, letterSpacing: 4, fontSize: 12)),
        const SizedBox(height: 12),
        Text(l10n.onboardingHeroTitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingHeroDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
        ),
      ],
    );
  }
}

class _Capabilities extends StatelessWidget {
  const _Capabilities();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.schedule, l10n.onboardingCapSchedules),
      (Icons.science_outlined, l10n.onboardingCapIngredients),
      (Icons.copy_outlined, l10n.onboardingCapDuplicates),
      (Icons.done_all, l10n.onboardingCapDoses),
      (Icons.qr_code, l10n.onboardingCapEmergency),
    ];
    return ListView(
      children: [
        Image.asset('assets/illustrations/onboarding-all-in-one-place.png', height: 180),
        const SizedBox(height: 16),
        Text(l10n.onboardingAllInOnePlace, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingAllInOnePlaceDesc,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => AppCard(
            child: Row(
              children: [
                CircleAvatar(backgroundColor: const Color(0xFFE6FFFB), child: Icon(item.$1, color: Palette.teal)),
                const SizedBox(width: 12),
                Expanded(child: Text(item.$2)),
              ],
            ),
          ),
        ).expand((w) => [w, const SizedBox(height: 10)]),
      ],
    );
  }
}

class _Safety extends StatelessWidget {
  const _Safety();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: [
        Text(l10n.onboardingBeforeYouStart, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Callout(
          tone: Tone.attention,
          title: l10n.onboardingNotDiagnosisTitle,
          message: l10n.onboardingNotDiagnosisMessage,
        ),
        const SizedBox(height: 16),
        Text(l10n.onboardingWarningsExplanation),
      ],
    );
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool signIn = true;
  bool demoLoading = false;
  String? error;
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.authUseDemoAccount),
        content: Text(l10n.authDemoOnlyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> demo() async {
    setState(() {
      demoLoading = true;
      error = null;
    });
    try {
      await ref.read(authProvider.notifier).signInWithDemo();
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => demoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = ref.watch(authProvider).sessionExpired;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: BrandWaves(color: Palette.teal, opacity: 0.07),
          ),
          SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: [
            const LogoMark(size: 64),
            const SizedBox(height: 8),
            Text('WELLWELL', textAlign: TextAlign.center, style: TextStyle(letterSpacing: 3, color: Palette.inkSubtle, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              signIn ? AppLocalizations.of(context)!.authWelcomeBack : AppLocalizations.of(context)!.authCreateAccount,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              signIn ? AppLocalizations.of(context)!.authSignInSubtitle : AppLocalizations.of(context)!.authSignUpSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SegmentedAuth(signIn: signIn, onChanged: (v) => setState(() => signIn = v)),
            const SizedBox(height: 20),
            if (expired) Text(AppLocalizations.of(context)!.authSessionExpired, style: TextStyle(color: Palette.attention)),
            if (!signIn) ...[
              LabeledField(label: AppLocalizations.of(context)!.authName, controller: name, hint: AppLocalizations.of(context)!.authNameHint),
              const SizedBox(height: 12),
            ],
            LabeledField(
              label: AppLocalizations.of(context)!.authEmail,
              controller: email,
              keyboardType: TextInputType.emailAddress,
              hint: AppLocalizations.of(context)!.authEmailHint,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: AppLocalizations.of(context)!.authPassword,
              controller: password,
              obscure: true,
              hint: signIn ? AppLocalizations.of(context)!.authPasswordHintSignIn : AppLocalizations.of(context)!.authPasswordHintSignUp,
            ),
            if (signIn)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(AppLocalizations.of(context)!.authForgotPassword),
                ),
              ),
            if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
            const SizedBox(height: 8),
            if (!signIn) ...[
              Callout(
                title: AppLocalizations.of(context)!.authWhatWellWellDoesNotTitle,
                message: AppLocalizations.of(context)!.authWhatWellWellDoesNotMessage,
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: signIn ? AppLocalizations.of(context)!.commonSignIn : AppLocalizations.of(context)!.commonSignUp,
              onPressed: submit,
            ),
            const SizedBox(height: 12),
            SecondaryButton(label: AppLocalizations.of(context)!.authUseDemoAccount, loading: demoLoading, onPressed: demo),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool sent = false;
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackCircle(),
              const SizedBox(height: 16),
              Text(l10n.forgotPasswordTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(l10n.forgotPasswordSubtitle),
              const SizedBox(height: 20),
              if (sent)
                Callout(tone: Tone.safe, title: l10n.forgotPasswordCheckEmailTitle, message: l10n.forgotPasswordCheckEmailMessage)
              else ...[
                LabeledField(label: l10n.authEmail, controller: email, keyboardType: TextInputType.emailAddress),
                if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: l10n.forgotPasswordSendButton,
                  loading: loading,
                  onPressed: () async {
                    setState(() => loading = true);
                    try {
                      await Api.forgotPassword(email.text.trim());
                      setState(() => sent = true);
                    } catch (e) {
                      setState(() => error = describeError(e));
                    } finally {
                      setState(() => loading = false);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final controller = TextEditingController();
  int cooldown = 60;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || cooldown <= 0) return false;
      setState(() => cooldown--);
      return cooldown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = ref.watch(authProvider).user?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Image.asset('assets/illustrations/verify-email.png', height: 160),
              const SizedBox(height: 16),
              Text(l10n.verifyEmailTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(l10n.verifyEmailSentTo(email), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(counterText: ''),
              ),
              if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
              const SizedBox(height: 16),
              PrimaryButton(
                label: l10n.verifyEmailVerifyButton,
                loading: loading,
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    await ref.read(authProvider.notifier).verifyEmail(controller.text);
                  } catch (e) {
                    setState(() => error = describeError(e));
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: cooldown > 0 ? l10n.verifyEmailResendCooldown(cooldown.toString().padLeft(2, '0')) : l10n.verifyEmailResendButton,
                onPressed: cooldown > 0
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).resendVerificationCode();
                        setState(() => cooldown = 60);
                        _tick();
                      },
              ),
              TextButton(onPressed: () => ref.read(authProvider.notifier).signOut(), child: Text(l10n.profileSignOut)),
            ],
          ),
        ),
      ),
    );
  }
}

class SafetyNoticeScreen extends ConsumerStatefulWidget {
  const SafetyNoticeScreen({super.key});

  @override
  ConsumerState<SafetyNoticeScreen> createState() => _SafetyNoticeScreenState();
}

class _SafetyNoticeScreenState extends ConsumerState<SafetyNoticeScreen> {
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.safetyNoticeTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Callout(
                tone: Tone.attention,
                title: l10n.safetyNoticeReadTitle,
                message: l10n.onboardingNotDiagnosisMessage,
              ),
              const Spacer(),
              if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
              PrimaryButton(
                label: l10n.commonIUnderstand,
                loading: loading,
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    await ref.read(authProvider.notifier).acknowledgeSafetyNotice();
                  } catch (e) {
                    setState(() => error = describeError(e));
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
              ),
              TextButton(onPressed: () => ref.read(authProvider.notifier).signOut(), child: Text(l10n.profileSignOut)),
            ],
          ),
        ),
      ),
    );
  }
}
