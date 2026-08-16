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
                        child: const Text('Get Started'),
                      ),
                    )
                  : PrimaryButton(label: 'Next', onPressed: () => setState(() => step++))
            else
              PrimaryButton(label: 'I understand', onPressed: finish),
            if (step < 2)
              TextButton(
                onPressed: () => setState(() => step = 2),
                child: Text('Skip', style: TextStyle(color: isHero ? Colors.white : Palette.brand)),
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
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LogoMark(size: 96, onDark: true),
        SizedBox(height: 16),
        Text('WELLWELL', style: TextStyle(color: Colors.white70, letterSpacing: 4, fontSize: 12)),
        SizedBox(height: 12),
        Text('Scan. Understand.\nStay safer.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
        SizedBox(height: 16),
        Text(
          "Your smart medication companion. Scan your medicines, understand what you're taking, and keep your routine organised.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
        ),
      ],
    );
  }
}

class _Capabilities extends StatelessWidget {
  const _Capabilities();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.schedule, 'organise medication schedules'),
      (Icons.science_outlined, 'identify active ingredients'),
      (Icons.copy_outlined, 'detect possible duplicate ingredients'),
      (Icons.done_all, 'remember doses'),
      (Icons.qr_code, 'securely share emergency medication information'),
    ];
    return ListView(
      children: [
        Image.asset('assets/illustrations/onboarding-all-in-one-place.png', height: 180),
        const SizedBox(height: 16),
        Text('All in one place', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Schedules, ingredients, reminders and emergency information — organised around the medications you already take.',
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
    return ListView(
      children: [
        Text('Before you start', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const Callout(
          tone: Tone.attention,
          title: 'WellWell is not a diagnosis tool',
          message:
              'WellWell does not provide medical diagnoses or change medication instructions. Always follow your medication label and advice from your healthcare professional.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Warnings are produced by deterministic checks against trusted medication data. Explanations written in plain language never add new findings of their own.',
        ),
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
              LabeledField(label: AppLocalizations.of(context)!.authName, controller: name, hint: 'How should we greet you?'),
              const SizedBox(height: 12),
            ],
            LabeledField(
              label: AppLocalizations.of(context)!.authEmail,
              controller: email,
              keyboardType: TextInputType.emailAddress,
              hint: 'you@example.com',
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: AppLocalizations.of(context)!.authPassword,
              controller: password,
              obscure: true,
              hint: signIn ? 'Your password' : 'Create a password',
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
              const Callout(
                title: 'What WellWell does not do',
                message: 'WellWell never diagnoses conditions or changes the instructions on your medication label.',
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackCircle(),
              const SizedBox(height: 16),
              Text('Reset your password', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text("Enter your email address and we'll send a reset link if an account exists."),
              const SizedBox(height: 20),
              if (sent)
                const Callout(tone: Tone.safe, title: 'Check your email', message: 'If an account exists for that address, a reset link is on its way.')
              else ...[
                LabeledField(label: 'Email', controller: email, keyboardType: TextInputType.emailAddress),
                if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Send reset link',
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
    final email = ref.watch(authProvider).user?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Image.asset('assets/illustrations/verify-email.png', height: 160),
              const SizedBox(height: 16),
              Text('Verify your email', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text("We've sent a 6-digit code to\n$email", textAlign: TextAlign.center),
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
                label: 'Verify',
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
                label: cooldown > 0 ? 'Resend code in 0:${cooldown.toString().padLeft(2, '0')}' : 'Resend code',
                onPressed: cooldown > 0
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).resendVerificationCode();
                        setState(() => cooldown = 60);
                        _tick();
                      },
              ),
              TextButton(onPressed: () => ref.read(authProvider.notifier).signOut(), child: const Text('Sign out')),
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How WellWell works', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              const Callout(
                tone: Tone.attention,
                title: 'Please read before continuing',
                message:
                    'WellWell does not provide medical diagnoses or change medication instructions. Always follow your medication label and advice from your healthcare professional.',
              ),
              const Spacer(),
              if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
              PrimaryButton(
                label: 'I understand',
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
              TextButton(onPressed: () => ref.read(authProvider.notifier).signOut(), child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
