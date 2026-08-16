import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
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
    // TabsShell only reads Palette.x directly (no Theme.of/MediaQuery.of of its own), so without
    // this it never gets told to rebuild when the live theme brightness changes - the bottom
    // nav bar would keep painting whatever colour was current the last time it happened to build.
    Theme.of(context);
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
        decoration: BoxDecoration(
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
                _TabItem(icon: Icons.home_outlined, label: AppLocalizations.of(context)!.navHome, index: 0, shell: navigationShell),
                _TabItem(icon: Icons.medical_services_outlined, label: AppLocalizations.of(context)!.navMeds, index: 1, shell: navigationShell),
                _ScanTab(index: 2, shell: navigationShell),
                _TabItem(icon: Icons.verified_user_outlined, label: AppLocalizations.of(context)!.navSafety, index: 3, shell: navigationShell),
                _TabItem(icon: Icons.person_outline, label: AppLocalizations.of(context)!.navProfile, index: 4, shell: navigationShell),
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
                  gradient: LinearGradient(colors: Palette.hero, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.surface, width: 4),
                ),
                child: const Icon(Icons.document_scanner_outlined, color: Colors.white),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.navScan,
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
  // The nudge message previously refetched (and could change) on every pull-to-refresh, which
  // felt random/unstable. It now only changes when medication data actually changed
  // (dataRevisionProvider bump) or once this staleness window has passed - a plain refresh
  // just keeps showing the same message. In-memory + static so it also survives tab switches.
  static const _nudgeRefreshInterval = Duration(hours: 6);
  static DailyNudge? _cachedNudge;
  static DateTime? _cachedNudgeAt;

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
    nudge = _cachedNudge;
    ref.listenManual(dataRevisionProvider, (previous, next) {
      if (previous != next) load(forceNudgeRefresh: true);
    });
    load();
  }

  Future<void> load({bool forceNudgeRefresh = false}) async {
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
      _loadNudge(forceRefresh: forceNudgeRefresh);
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
  Future<void> _loadNudge({bool forceRefresh = false}) async {
    final cachedAt = _cachedNudgeAt;
    final stale = cachedAt == null || DateTime.now().difference(cachedAt) > _nudgeRefreshInterval;
    if (!forceRefresh && !stale && _cachedNudge != null) {
      if (mounted) setState(() => nudge = _cachedNudge);
      return;
    }
    try {
      final data = await Api.adherenceNudge();
      if (!mounted) return;
      _cachedNudge = data;
      _cachedNudgeAt = DateTime.now();
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
    HapticFeedback.selectionClick();
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
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final doses = today?.doses ?? [];
    return ScreenScaffold(
      onRefresh: load,
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting(), style: Theme.of(context).textTheme.labelLarge),
          Text(user?.displayName ?? l10n.homeGreetingFallback, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
      trailing: IconButton.outlined(
        onPressed: () => context.push('/emergency'),
        icon: const Icon(Icons.qr_code),
      ),
      children: [
        if (nudge != null && nudge!.totalCount > 0)
          InsightCard(message: nudge!.message, generatedByAi: nudge!.generatedByAi),
        if (findings.isNotEmpty)
          Builder(builder: (context) {
            final style = toneStyles[Tone.attention]!;
            return InkWell(
              onTap: () => context.go('/safety'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: style.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: style.foreground),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.homeSafetyFindings(findings.length),
                            style: TextStyle(fontWeight: FontWeight.w600, color: style.foreground),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: style.foreground),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(findings.first.title, style: TextStyle(color: style.foreground)),
                  ],
                ),
              ),
            );
          }),
        if (!loading && (today?.totalCount ?? 0) > 0 && today?.completedCount == today?.totalCount)
          Callout(
            tone: Tone.safe,
            title: l10n.homeAllDoneTitle,
            message: l10n.homeAllDoneMessage,
          ),
        AppCard(
          child: Column(
            children: [
              if (loading)
                const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
              else ...[
                CircularProgressRing(completed: today?.completedCount ?? 0, total: today?.totalCount ?? 0),
                const SizedBox(height: 12),
                Text(today?.progressLabel ?? l10n.homeNoDosesToday, textAlign: TextAlign.center),
                if (insights != null && insights!.streakDays > 0) ...[
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final dark = Theme.of(context).brightness == Brightness.dark;
                    return InkWell(
                    onTap: () => context.push('/insights'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF3A2413) : const Color(0xFFFFF7ED),
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
                            style: TextStyle(fontWeight: FontWeight.w700, color: dark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: Text(l10n.homeTodaysMedications, style: Theme.of(context).textTheme.titleMedium)),
            TextButton(onPressed: () => context.push('/insights'), child: Text(l10n.homeInsights)),
            TextButton(onPressed: () => context.push('/history'), child: Text(l10n.homeHistory)),
          ],
        ),
        if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (!loading && doses.isEmpty)
          EmptyState(
            icon: Icons.alarm,
            title: l10n.homeNoRemindersYetTitle,
            description: l10n.homeNoRemindersYetDescription,
            action: PrimaryButton(label: l10n.homeScanMedication, onPressed: () => context.go('/scan')),
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
        if (actionError != null) Text(actionError!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(label: l10n.homeScanMedication, onPressed: () => context.go('/scan')),
      ],
    );
  }
}

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

enum _MedicationSort { nameAsc, verifiedFirst, mostReminders, recentlyAdded }

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  List<Medication> items = [];
  bool loading = true;
  String? error;
  final search = TextEditingController();
  _MedicationSort sort = _MedicationSort.nameAsc;

  @override
  void initState() {
    super.initState();
    ref.listenManual(dataRevisionProvider, (previous, next) {
      if (previous != next) load();
    });
    load();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Medication> get _visible {
    final query = search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items
            .where(
              (med) => [med.displayName, med.brandName, med.genericName].any((v) => v.toLowerCase().contains(query)),
            )
            .toList();
    final sorted = [...filtered];
    switch (sort) {
      case _MedicationSort.nameAsc:
        sorted.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      case _MedicationSort.verifiedFirst:
        sorted.sort((a, b) {
          final byVerification = (b.isVerified ? 1 : 0).compareTo(a.isVerified ? 1 : 0);
          return byVerification != 0 ? byVerification : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        });
      case _MedicationSort.mostReminders:
        sorted.sort((a, b) => b.activeScheduleCount.compareTo(a.activeScheduleCount));
      case _MedicationSort.recentlyAdded:
        sorted.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    }
    return sorted;
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
              leading: Icon(Icons.camera_alt_outlined, color: Palette.brand),
              title: const Text('Scan a label'),
              subtitle: const Text('Use your camera. WellWell reads the name and ingredients for you to confirm.'),
              onTap: () {
                Navigator.pop(context);
                this.context.go('/scan');
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Palette.brand),
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
      title: 'Medications',
      subtitle: 'Everything you have confirmed and saved in WellWell.',
      trailing: GradientButton(label: 'Add', onPressed: addSheet, height: 40),
      children: [
        if (!loading && error == null && items.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    hintText: 'Search medications',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_MedicationSort>(
                initialValue: sort,
                onSelected: (value) => setState(() => sort = value),
                icon: const Icon(Icons.sort),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _MedicationSort.nameAsc, child: Text('Name A–Z')),
                  PopupMenuItem(value: _MedicationSort.verifiedFirst, child: Text('Verified first')),
                  PopupMenuItem(value: _MedicationSort.mostReminders, child: Text('Most reminders')),
                  PopupMenuItem(value: _MedicationSort.recentlyAdded, child: Text('Recently added')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
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
        else if (_visible.isEmpty)
          EmptyState(
            icon: Icons.search_off,
            title: 'No matches',
            description: 'No medication matches "${search.text.trim()}".',
          )
        else
          ..._visible.map(
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
                            child: Text(initials(med.displayName), style: TextStyle(color: Palette.brand, fontWeight: FontWeight.w700)),
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
                          Icon(Icons.chevron_right, color: Palette.inkSubtle),
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
      title: 'Safety',
      subtitle: 'Deterministic checks across the medications saved in WellWell.',
      children: [
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
                  'WellWell can only report what its current checks and data sources cover. Always read the label and ask a pharmacist if something is unclear.',
            )
          else
            ...data.findings.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: FindingCard(finding: f))),
          SafetyChecksCard(analysis: data),
        ],
        if (actionError != null) Text(actionError!, style: TextStyle(color: Palette.critical)),
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
      title: 'Profile',
      subtitle: 'Your account, health details and app settings.',
      children: [
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Palette.brandSoft,
                child: Text(initials(user?.displayName ?? 'MG'), style: TextStyle(color: Palette.brand, fontWeight: FontWeight.w700)),
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
              ListRow(icon: Icons.diversity_1_outlined, label: 'Shared with you', onTap: () => context.push('/shared-with-me')),
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
