import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../services/api.dart';
import '../services/reminders.dart';
import '../state/auth.dart';
import '../theme/palette.dart';
import '../widgets/domain.dart';
import '../widgets/ui.dart';

class TabsShell extends ConsumerWidget {
  const TabsShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanActive = navigationShell.currentIndex == 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (ref.read(scanTabActiveProvider) != scanActive) {
        ref.read(scanTabActiveProvider.notifier).state = scanActive;
      }
    });
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Palette.surface,
          border: Border(top: BorderSide(color: Palette.line)),
        ),
        clipBehavior: Clip.none,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _TabItem(icon: Icons.home_outlined, label: 'Home', index: 0, shell: navigationShell),
                _TabItem(icon: Icons.medical_services_outlined, label: 'Meds', index: 1, shell: navigationShell),
                _ScanTab(index: 2, shell: navigationShell),
                _TabItem(icon: Icons.verified_user_outlined, label: 'Safety', index: 3, shell: navigationShell),
                _TabItem(icon: Icons.person_outline, label: 'Profile', index: 4, shell: navigationShell),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.index, required this.shell});

  final IconData icon;
  final String label;
  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final selected = shell.currentIndex == index;
    final color = selected ? Palette.brand : Palette.inkSubtle;
    return Expanded(
      child: InkWell(
        onTap: () => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.index, required this.shell});

  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: Palette.hero, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.surface, width: 4),
                ),
                child: const Icon(Icons.document_scanner_outlined, color: Colors.white),
              ),
            ),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: shell.currentIndex == index ? Palette.brand : Palette.inkSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  TodaySchedule? today;
  List<SafetyFinding> findings = [];
  DailyNudge? nudge;
  AdherenceInsights? insights;
  bool loading = true;
  String? error;
  String? actionError;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(dataRevisionProvider, (previous, next) {
      if (previous != next) load();
    });
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = today == null;
      error = null;
    });
    try {
      final results = await Future.wait([Api.today(), Api.findings()]);
      if (!mounted) return;
      setState(() {
        today = results[0] as TodaySchedule;
        findings = results[1] as List<SafetyFinding>;
        loading = false;
      });
      unawaited(Reminders.syncFromServer(privacyMode: ref.read(authProvider).user?.privacyNotificationsEnabled ?? true));
      _loadNudge();
      _loadInsights();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = describeError(e);
        loading = false;
      });
    }
  }

  // Best-effort: a missing or slow nudge must never break the Home screen.
  Future<void> _loadNudge() async {
    try {
      final data = await Api.adherenceNudge();
      if (!mounted) return;
      setState(() => nudge = data);
    } catch (_) {
      // Ignore; the nudge is a non-essential enhancement.
    }
  }

  // Best-effort: the streak badge is a bonus and must never block the Home screen.
  Future<void> _loadInsights() async {
    try {
      final data = await Api.adherenceInsights();
      if (!mounted) return;
      setState(() => insights = data);
    } catch (_) {
      // Ignore; insights are a non-essential enhancement.
    }
  }

  Future<void> record(String id, bool taken) async {
    setState(() {
      busy = true;
      actionError = null;
    });
    try {
      if (taken) {
        await Api.markTaken(id);
      } else {
        await Api.markSkipped(id);
      }
      await load();
    } catch (e) {
      setState(() => actionError = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final doses = today?.doses ?? [];
    return ScreenScaffold(
      onRefresh: load,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting(), style: Theme.of(context).textTheme.labelLarge),
                  Text(user?.displayName ?? 'Welcome', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            IconButton.outlined(
              onPressed: () => context.push('/emergency'),
              icon: const Icon(Icons.qr_code),
            ),
          ],
        ),
        if (nudge != null && nudge!.totalCount > 0)
          InsightCard(message: nudge!.message, generatedByAi: nudge!.generatedByAi),
        if (findings.isNotEmpty)
          InkWell(
            onTap: () => context.go('/safety'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x4DF59E0B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Palette.attention),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          findings.length == 1
                              ? '1 safety finding to review'
                              : '${findings.length} safety findings to review',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Palette.attention),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(findings.first.title, style: const TextStyle(color: Color(0xFFB45309))),
                ],
              ),
            ),
          ),
        AppCard(
          child: Column(
            children: [
              if (loading)
                const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
              else ...[
                CircularProgressRing(completed: today?.completedCount ?? 0, total: today?.totalCount ?? 0),
                const SizedBox(height: 12),
                Text(today?.progressLabel ?? 'No doses are scheduled for today.', textAlign: TextAlign.center),
                if (insights != null && insights!.streakDays > 0) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.push('/insights'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x33F97316)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            insights!.streakDays == 1
                                ? '1-day streak'
                                : '${insights!.streakDays}-day streak',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: Text("Today's medications", style: Theme.of(context).textTheme.titleMedium)),
            TextButton(onPressed: () => context.push('/insights'), child: const Text('Insights')),
            TextButton(onPressed: () => context.push('/history'), child: const Text('History')),
          ],
        ),
        if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (!loading && doses.isEmpty)
          EmptyState(
            icon: Icons.alarm,
            title: 'No reminders yet',
            description: 'Add a medication and confirm its reminder times to see your day here.',
            action: PrimaryButton(label: 'Scan Medication', onPressed: () => context.go('/scan')),
          )
        else
          ...doses.map(
            (dose) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DoseCard(
                dose: dose,
                busy: busy,
                onTaken: () => record(dose.id, true),
                onSkip: () => record(dose.id, false),
                onDetails: () => context.push('/medication/${dose.medicationId}'),
              ),
            ),
          ),
        if (actionError != null) Text(actionError!, style: const TextStyle(color: Palette.critical)),
        PrimaryButton(label: 'Scan Medication', onPressed: () => context.go('/scan')),
      ],
    );
  }
}

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  List<Medication> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    ref.listenManual(dataRevisionProvider, (previous, next) {
      if (previous != next) load();
    });
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = items.isEmpty;
      error = null;
    });
    try {
      final data = await Api.medications();
      if (!mounted) return;
      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = describeError(e);
        loading = false;
      });
    }
  }

  void addSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a medication', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Palette.brand),
              title: const Text('Scan a label'),
              subtitle: const Text('Use your camera. MedGuard reads the name and ingredients for you to confirm.'),
              onTap: () {
                Navigator.pop(context);
                this.context.go('/scan');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Palette.brand),
              title: const Text('Enter manually'),
              subtitle: const Text('Type the medication details yourself.'),
              onTap: () {
                Navigator.pop(context);
                this.context.push('/medication/new');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      onRefresh: load,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medications', style: Theme.of(context).textTheme.headlineMedium),
                  const Text('Everything you have confirmed and saved in MedGuard.'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: addSheet,
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (items.isEmpty)
          EmptyState(
            icon: Icons.medical_services_outlined,
            title: 'No medications yet',
            description: 'Scan a label or add the details manually. Nothing is saved until you confirm it.',
            action: PrimaryButton(label: 'Scan a medication', onPressed: () => context.go('/scan')),
          )
        else
          ...items.map(
            (med) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => context.push('/medication/${med.id}'),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Palette.brandSoft,
                            child: Text(initials(med.displayName), style: const TextStyle(color: Palette.brand, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med.displayName, style: Theme.of(context).textTheme.titleMedium),
                                Text(
                                  med.ingredients.map((i) => i.normalizedName).join(', ').ifEmpty('No active ingredients recorded'),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Palette.inkSubtle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppBadge(
                            label: med.isVerified ? 'Verified' : 'Unverified',
                            tone: verificationTone(med.verificationStatus),
                            glyph: verificationGlyph(med.verificationStatus),
                          ),
                          if (med.strength != null) AppBadge(label: med.strength!, tone: Tone.neutral),
                          AppBadge(
                            label: med.activeScheduleCount == 0
                                ? 'No reminders'
                                : '${med.activeScheduleCount} reminder${med.activeScheduleCount == 1 ? '' : 's'}',
                            tone: med.activeScheduleCount == 0 ? Tone.neutral : Tone.info,
                            glyph: '⏰',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  SafetyAnalysis? analysis;
  bool loading = true;
  bool running = false;
  String? error;
  String? actionError;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = analysis == null;
      error = null;
    });
    try {
      final data = await Api.analyzeSafety();
      if (!mounted) return;
      setState(() {
        analysis = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = describeError(e);
        loading = false;
      });
    }
  }

  Future<void> recheck() async {
    setState(() {
      running = true;
      actionError = null;
    });
    try {
      final data = await Api.analyzeSafety();
      if (!mounted) return;
      setState(() => analysis = data);
    } catch (e) {
      setState(() => actionError = describeError(e));
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = analysis;
    return ScreenScaffold(
      onRefresh: load,
      children: [
        Text('Safety', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Deterministic checks across the medications saved in MedGuard.'),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (data != null) ...[
          SafetySummaryCard(analysis: data),
          if (data.findings.isEmpty)
            const Callout(
              tone: Tone.info,
              title: 'Unknown does not mean safe',
              message:
                  'MedGuard can only report what its current checks and data sources cover. Always read the label and ask a pharmacist if something is unclear.',
            )
          else
            ...data.findings.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: FindingCard(finding: f))),
          SafetyChecksCard(analysis: data),
        ],
        if (actionError != null) Text(actionError!, style: const TextStyle(color: Palette.critical)),
        PrimaryButton(label: 'Run the checks again', loading: running, onPressed: recheck),
        SecondaryButton(label: 'View medications', onPressed: () => context.go('/medications')),
      ],
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return ScreenScaffold(
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Your account, health details and app settings.'),
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Palette.brandSoft,
                child: Text(initials(user?.displayName ?? 'MG'), style: const TextStyle(color: Palette.brand, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? '', style: Theme.of(context).textTheme.titleMedium),
                    Text(user?.email ?? '', style: Theme.of(context).textTheme.labelSmall),
                    if (user?.isDemoAccount == true) ...[
                      const SizedBox(height: 6),
                      const AppBadge(label: 'Demo account', tone: Tone.info, glyph: 'i'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListRow(icon: Icons.person_outline, label: 'Personal Information', onTap: () => context.push('/personal-info')),
              ListRow(icon: Icons.favorite_border, label: 'Health Information', onTap: () => context.push('/health-info')),
              ListRow(icon: Icons.settings_outlined, label: 'App Settings', onTap: () => context.push('/app-settings')),
              ListRow(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push('/notification-settings')),
              ListRow(icon: Icons.lock_outline, label: 'Privacy', divider: false, onTap: () => context.push('/privacy-settings')),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListRow(icon: Icons.qr_code, label: 'Emergency card', onTap: () => context.push('/emergency')),
              ListRow(icon: Icons.people_outline, label: 'Share access', onTap: () => context.push('/caregivers')),
              ListRow(icon: Icons.calendar_today_outlined, label: 'Dose history', divider: false, onTap: () => context.push('/history')),
            ],
          ),
        ),
        SecondaryButton(
          label: 'Sign out',
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign out?'),
                content: const Text('Your medication information stays on the server and is removed from this device.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay signed in')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
                ],
              ),
            );
            if (ok == true) await ref.read(authProvider.notifier).signOut();
          },
        ),
      ],
    );
  }
}
