import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/models.dart';
import '../services/api.dart';
import '../services/reminders.dart';
import '../state/auth.dart';
import '../theme/palette.dart';
import '../utils/format.dart';
import '../widgets/domain.dart';
import '../widgets/ui.dart';

class MedicationDetailScreen extends ConsumerStatefulWidget {
  const MedicationDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends ConsumerState<MedicationDetailScreen> {
  Medication? item;
  List<Schedule> schedules = [];
  TodaySchedule? today;
  MedicationEducation? education;
  bool loading = true;
  bool busy = false;
  bool editing = false;
  String? error;
  String? actionError;
  final brand = TextEditingController();
  final generic = TextEditingController();
  final form = TextEditingController();
  final strength = TextEditingController();
  final route = TextEditingController();
  final directions = TextEditingController();
  final notes = TextEditingController();
  List<IngredientDraft> editIngredients = [IngredientDraft()];

  @override
  void initState() {
    super.initState();
    ref.listenManual(dataRevisionProvider, (previous, next) {
      if (previous != next) load();
    });
    load();
  }

  @override
  void dispose() {
    brand.dispose();
    generic.dispose();
    form.dispose();
    strength.dispose();
    route.dispose();
    directions.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = item == null;
      error = null;
    });
    try {
      final results = await Future.wait([
        Api.medication(widget.id),
        Api.schedules(widget.id),
        Api.today(),
      ]);
      if (!mounted) return;
      setState(() {
        item = results[0] as Medication;
        schedules = results[1] as List<Schedule>;
        today = results[2] as TodaySchedule;
        loading = false;
      });
      _loadEducation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = describeError(e);
        loading = false;
      });
    }
  }

  void _beginEdit(Medication med) {
    brand.text = med.brandName;
    generic.text = med.genericName;
    form.text = med.dosageForm ?? '';
    strength.text = med.strength ?? '';
    route.text = med.route ?? '';
    directions.text = med.labelDirections ?? '';
    notes.text = med.notes ?? '';
    editIngredients = med.ingredients.isEmpty
        ? [IngredientDraft()]
        : med.ingredients
            .map((i) => IngredientDraft(name: i.originalName, strength: i.strength ?? '', unit: i.unit ?? 'mg'))
            .toList();
    setState(() {
      editing = true;
      actionError = null;
    });
  }

  Future<void> _saveEdits() async {
    setState(() {
      busy = true;
      actionError = null;
    });
    try {
      await Api.updateMedication(widget.id, {
        'brandName': brand.text.trim().isEmpty ? null : brand.text.trim(),
        'genericName': generic.text.trim().isEmpty ? null : generic.text.trim(),
        'ingredients': editIngredients.where((i) => i.name.trim().isNotEmpty).map((i) => i.toJson()).toList(),
        'dosageForm': form.text.trim().isEmpty ? null : form.text.trim(),
        'strength': strength.text.trim().isEmpty ? null : strength.text.trim(),
        'route': route.text.trim().isEmpty ? null : route.text.trim(),
        'labelDirections': directions.text.trim().isEmpty ? null : directions.text.trim(),
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        'attemptVerification': true,
      });
      ref.read(dataRevisionProvider.notifier).state++;
      setState(() => editing = false);
      await load();
    } catch (e) {
      if (mounted) setState(() => actionError = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _editRefill(Medication med) async {
    final controller = TextEditingController(text: med.remainingQuantity?.toString() ?? '');
    final result = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Doses remaining'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter how many doses (pills, sprays, etc.) you have left. Leave empty to clear.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. 30'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          if (med.remainingQuantity != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, -1),
              child: const Text('Clear'),
            ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogContext, text.isEmpty ? -1 : (int.tryParse(text) ?? med.remainingQuantity ?? 0));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    // -1 is our sentinel for "clear the count".
    final value = result == -1 ? null : result;
    setState(() {
      busy = true;
      actionError = null;
    });
    try {
      await Api.setRefill(med.id, value);
      await load();
      await Reminders.syncFromServer(
        privacyMode: ref.read(authProvider).user?.privacyNotificationsEnabled ?? true,
      );
    } catch (e) {
      if (mounted) setState(() => actionError = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  // Best-effort: general education is a bonus and must never block the detail screen.
  Future<void> _loadEducation() async {
    try {
      final data = await Api.medicationEducation(widget.id);
      if (!mounted) return;
      setState(() => education = data);
    } catch (_) {
      // Ignore; education is a non-essential enhancement.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ScreenScaffold(children: [BackCircle(), Center(child: CircularProgressIndicator())]);
    }
    if (error != null || item == null) {
      return ScreenScaffold(children: [const BackCircle(), ErrorBanner(message: error ?? 'Not found', onRetry: load)]);
    }
    final med = item!;
    final active = schedules.where((s) => s.isActive).toList();
    final nextDose = today?.doses.where((d) => d.medicationId == med.id && (d.status == 'pending' || d.status == 'snoozed')).firstOrNull;
    final dosesPerDay = active.length;
    final rq = med.remainingQuantity;
    final daysLeft = (rq != null && dosesPerDay > 0) ? (rq / dosesPerDay).floor() : null;

    return ScreenScaffold(
      onRefresh: load,
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text(med.displayName, style: Theme.of(context).textTheme.headlineMedium),
        Wrap(
          spacing: 8,
          children: [
            AppBadge(
              label: med.verificationLabel,
              tone: verificationTone(med.verificationStatus),
              glyph: verificationGlyph(med.verificationStatus),
            ),
            if (med.dosageForm != null) AppBadge(label: med.dosageForm!, tone: Tone.neutral),
          ],
        ),
        if (med.verificationStatus != 'verified')
          Callout(
            tone: Tone.attention,
            title: 'Not independently verified',
            message:
                'MedGuard matches brand, generic name, strength, form and active ingredients against a trusted medication database. Edit those fields if they do not match the label, then save to try again.',
            child: editing
                ? null
                : SecondaryButton(label: 'Edit details to verify', onPressed: () => _beginEdit(med)),
          ),
        if (editing)
          Callout(
            tone: Tone.info,
            title: 'Used to verify',
            message: 'Brand, generic name, strength, form and active ingredients are matched against the database. Route, directions and notes are stored as printed and are not used to verify.',
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(editing ? 'Used to verify' : 'Active ingredients', style: Theme.of(context).textTheme.titleMedium)),
                  if (!editing)
                    TextButton(onPressed: () => _beginEdit(med), child: const Text('Edit')),
                ],
              ),
              if (editing) ...[
                const SizedBox(height: 8),
                LabeledField(label: 'Brand name', controller: brand, usedForVerification: true),
                const SizedBox(height: 12),
                LabeledField(label: 'Generic name', controller: generic, usedForVerification: true),
                const SizedBox(height: 12),
                LabeledField(label: 'Strength', controller: strength, usedForVerification: true),
                const SizedBox(height: 12),
                LabeledField(label: 'Dosage form', controller: form, usedForVerification: true),
                const SizedBox(height: 12),
                IngredientEditor(
                  key: const ValueKey('detail-ingredients'),
                  ingredients: editIngredients,
                  onChanged: (v) => editIngredients = v,
                ),
              ] else if (med.ingredients.isEmpty)
                const Text('No active ingredients are recorded for this medication.')
              else
                for (final ingredient in med.ingredients) ...[
                  const SizedBox(height: 10),
                  Text(ingredient.normalizedName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${ingredient.displayStrength.isEmpty ? 'Strength not recorded' : ingredient.displayStrength} · printed as “${ingredient.originalName}”'),
                  if (ingredient.rxCui != null) Text('RxNorm identifier ${ingredient.rxCui}', style: Theme.of(context).textTheme.labelSmall),
                ],
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editing ? 'On the label only' : 'About', style: Theme.of(context).textTheme.titleMedium),
              if (editing) ...[
                const SizedBox(height: 8),
                LabeledField(label: 'Route', controller: route, usedForVerification: false),
                const SizedBox(height: 12),
                LabeledField(label: 'Label directions', controller: directions, maxLines: 3, usedForVerification: false),
                const SizedBox(height: 12),
                LabeledField(label: 'Notes', controller: notes, maxLines: 2, usedForVerification: false),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Save and try to verify', loading: busy, onPressed: _saveEdits),
                SecondaryButton(label: 'Cancel', onPressed: () => setState(() => editing = false)),
              ] else ...[
                FieldRow(label: 'Brand', value: med.brandName),
                FieldRow(label: 'Generic name', value: med.genericName),
                FieldRow(label: 'Strength', value: med.strength),
                FieldRow(label: 'Form', value: med.dosageForm),
                FieldRow(label: 'Route', value: med.route),
                FieldRow(label: 'Directions', value: med.labelDirections),
                FieldRow(label: 'Manufacturer', value: med.manufacturer),
                FieldRow(label: 'Notes', value: med.notes, divider: false),
              ],
            ],
          ),
        ),
        if (education != null && education!.hasContent)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 20, color: Palette.brand),
                    const SizedBox(width: 8),
                    Expanded(child: Text('About this medication', style: Theme.of(context).textTheme.titleMedium)),
                    if (education!.generatedByAi)
                      Text('AI info', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(education!.message, style: const TextStyle(height: 1.4)),
                if (education!.usedFor.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Commonly used for', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final use in education!.usedFor) AppBadge(label: use, tone: Tone.info)],
                  ),
                ],
                if (education!.drugClass != null && education!.drugClass!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FieldRow(label: 'Class', value: education!.drugClass, divider: false),
                ],
                if (education!.usedFor.isNotEmpty || education!.drugClass != null) ...[
                  const SizedBox(height: 8),
                  Text('Source: RxClass (U.S. National Library of Medicine).', style: Theme.of(context).textTheme.labelSmall),
                ],
              ],
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Source', style: Theme.of(context).textTheme.titleMedium),
              FieldRow(label: 'Provider', value: med.provenance?.provider ?? 'Entered manually'),
              FieldRow(label: 'Identifier', value: med.provenance?.externalIdentifier ?? med.rxCui),
              FieldRow(label: 'Dataset version', value: med.provenance?.datasetVersion),
              FieldRow(label: 'Last verified', value: med.provenance == null ? 'Not verified' : formatDateTime(med.provenance!.retrievedAt), divider: false),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Schedule', style: Theme.of(context).textTheme.titleMedium)),
                  AppBadge(label: '${active.length} active', tone: active.isEmpty ? Tone.neutral : Tone.info, glyph: '⏰'),
                ],
              ),
              const SizedBox(height: 8),
              if (active.isEmpty)
                const Text('No reminders yet. Reminder times are only suggestions from the label until you confirm them.')
              else
                Wrap(
                  spacing: 8,
                  children: [for (final s in active) Chip(label: Text(s.time, style: const TextStyle(fontWeight: FontWeight.w600)))],
                ),
              if (nextDose != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Palette.brandSoft, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next dose', style: Theme.of(context).textTheme.labelLarge),
                      Text(nextDose.scheduledTime, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: 'Take',
                        loading: busy,
                        onPressed: () async {
                          setState(() => busy = true);
                          try {
                            await Api.markTaken(nextDose.id);
                            await load();
                          } catch (e) {
                            setState(() => actionError = describeError(e));
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SecondaryButton(
                label: active.isEmpty ? 'Set up reminders' : 'Edit reminders',
                onPressed: () async {
                  await context.push('/schedule/${med.id}');
                  if (mounted) await load();
                },
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Refill', style: Theme.of(context).textTheme.titleMedium)),
                  const Icon(Icons.medication_outlined, color: Palette.brand),
                ],
              ),
              const SizedBox(height: 8),
              if (rq == null)
                const Text('Track how many doses you have left to get a refill reminder before you run out.')
              else ...[
                Text('$rq doses left', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                if (daysLeft != null)
                  Text(
                    daysLeft <= 0
                        ? 'You may be out — time to refill.'
                        : 'About $daysLeft ${daysLeft == 1 ? 'day' : 'days'} left at your current reminder schedule.',
                  )
                else
                  const Text('Set up reminders to estimate how many days this will last.'),
                if (daysLeft != null && daysLeft <= 5) ...[
                  const SizedBox(height: 8),
                  const Callout(
                    tone: Tone.attention,
                    title: 'Running low',
                    message: 'Consider ordering a refill soon so you don’t miss a dose.',
                  ),
                ],
              ],
              const SizedBox(height: 12),
              SecondaryButton(
                label: rq == null ? 'Add pill count' : 'Update pill count',
                onPressed: () => _editRefill(med),
              ),
            ],
          ),
        ),
        if (actionError != null) Text(actionError!, style: const TextStyle(color: Palette.critical)),
        SecondaryButton(label: 'View dose history', onPressed: () => context.push('/history?medicationId=${med.id}')),
        DangerButton(
          label: 'Remove medication',
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove this medication?'),
                content: const Text('It will no longer appear in your list, reminders or safety checks. Your dose history stays intact.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                ],
              ),
            );
            if (ok == true) {
              await Api.deleteMedication(med.id);
              if (context.mounted) {
                ref.read(dataRevisionProvider.notifier).state++;
                context.go('/medications');
              }
            }
          },
        ),
      ],
    );
  }
}

class NewMedicationScreen extends ConsumerStatefulWidget {
  const NewMedicationScreen({super.key});

  @override
  ConsumerState<NewMedicationScreen> createState() => _NewMedicationScreenState();
}

class _NewMedicationScreenState extends ConsumerState<NewMedicationScreen> {
  final brand = TextEditingController();
  final generic = TextEditingController();
  final form = TextEditingController();
  final strength = TextEditingController();
  final directions = TextEditingController();
  List<IngredientDraft> ingredients = [IngredientDraft()];
  bool busy = false;
  String? error;

  @override
  void dispose() {
    brand.dispose();
    generic.dispose();
    form.dispose();
    strength.dispose();
    directions.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (brand.text.trim().isEmpty && generic.text.trim().isEmpty) {
      setState(() => error = 'Add a brand name or a generic name.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final med = await Api.createMedication({
        'brandName': brand.text.trim().isEmpty ? null : brand.text.trim(),
        'genericName': generic.text.trim().isEmpty ? null : generic.text.trim(),
        'ingredients': ingredients.where((i) => i.name.trim().isNotEmpty).map((i) => i.toJson()).toList(),
        'dosageForm': form.text.trim().isEmpty ? null : form.text.trim(),
        'strength': strength.text.trim().isEmpty ? null : strength.text.trim(),
        'route': null,
        'labelDirections': directions.text.trim().isEmpty ? null : directions.text.trim(),
        'notes': null,
        'attemptVerification': true,
      });
      try {
        await Api.analyzeSafety(med.id);
      } catch (_) {}
      ref.read(dataRevisionProvider.notifier).state++;
      if (mounted) context.replace('/medication/${med.id}');
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Add a medication', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Copy the details from the label. Fields marked “Used to verify” are matched against a trusted medication database.'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Used to verify', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Brand, generic name, strength, form and active ingredients decide whether this product can be verified.'),
              const SizedBox(height: 12),
              LabeledField(label: 'Brand name', controller: brand, hint: 'As printed on the box', usedForVerification: true),
              const SizedBox(height: 12),
              LabeledField(label: 'Generic name', controller: generic, usedForVerification: true),
              const SizedBox(height: 12),
              LabeledField(label: 'Strength', controller: strength, hint: '500 mg', usedForVerification: true),
              const SizedBox(height: 12),
              LabeledField(label: 'Dosage form', controller: form, hint: 'Tablet', usedForVerification: true),
              const SizedBox(height: 12),
              IngredientEditor(ingredients: ingredients, onChanged: (v) => ingredients = v),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('On the label only', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Directions are stored as printed. They are not used to verify the product.'),
              const SizedBox(height: 12),
              LabeledField(label: 'Label directions', controller: directions, maxLines: 3, usedForVerification: false),
            ],
          ),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
        PrimaryButton(label: 'Save medication', loading: busy, onPressed: save),
      ],
    );
  }
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, required this.medicationId});

  final String medicationId;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  Medication? medication;
  ScheduleSuggestion? suggestion;
  List<Schedule> existing = [];
  List<String> times = [];
  final List<Key> timeKeys = [];
  final doseAmount = TextEditingController();
  bool confirmed = false;
  bool loading = true;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    doseAmount.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        Api.medication(widget.medicationId),
        Api.scheduleSuggestion(widget.medicationId),
        Api.schedules(widget.medicationId),
      ]);
      if (!mounted) return;
      final med = results[0] as Medication;
      final sug = results[1] as ScheduleSuggestion;
      final schedules = results[2] as List<Schedule>;
      final active = schedules.where((s) => s.isActive).map((s) => s.time).toList();
      setState(() {
        medication = med;
        suggestion = sug;
        existing = schedules;
        times = active.isNotEmpty ? active : List.of(sug.suggestedTimes);
        timeKeys
          ..clear()
          ..addAll(List.generate(times.length, (_) => UniqueKey()));
        doseAmount.text = schedules.where((s) => s.doseAmountText != null).firstOrNull?.doseAmountText ?? sug.doseAmountText ?? '';
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

  Future<void> save() async {
    final cleaned = times.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final timePattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (cleaned.isEmpty) {
      setState(() => error = 'Add at least one reminder time, or remove the reminders for this medication.');
      return;
    }
    final invalid = cleaned.where((t) => !timePattern.hasMatch(t)).firstOrNull;
    if (invalid != null) {
      setState(() => error = '"$invalid" is not a valid time. Use the 24-hour format, for example 08:00.');
      return;
    }
    if (!confirmed) {
      setState(() => error = 'Confirm the reminder times before saving.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Api.saveSchedule({
        'medicationId': widget.medicationId,
        'times': cleaned,
        'labelInstruction': suggestion?.labelInstruction ?? medication?.labelDirections,
        'doseAmountText': doseAmount.text.trim().isEmpty ? null : doseAmount.text.trim(),
        'userConfirmed': true,
      });
      final privacy = ref.read(authProvider).user?.privacyNotificationsEnabled ?? true;
      final reminders = await Reminders.syncFromServer(privacyMode: privacy);
      if (!mounted) return;
      ref.read(dataRevisionProvider.notifier).state++;
      if (!reminders.permissionGranted) {
        setState(() {
          busy = false;
          error = 'Reminders were saved, but notification permission is off. Enable notifications for MedGuard in iPhone Settings.';
        });
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/medication/${widget.medicationId}');
      }
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _addTime() async {
    setState(() {
      times.add('08:00');
      timeKeys.add(UniqueKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ScreenScaffold(children: [BackCircle(), Center(child: CircularProgressIndicator())]);
    }
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Edit reminder', style: Theme.of(context).textTheme.headlineMedium),
        Text(medication?.displayName ?? ''),
        if (suggestion?.labelInstruction != null)
          Callout(title: 'From the label', message: suggestion!.labelInstruction!),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < times.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReminderTimePicker(
                    key: timeKeys[i],
                    time: times[i],
                    onChanged: (value) => times[i] = value,
                    onRemove: () => setState(() {
                      times.removeAt(i);
                      timeKeys.removeAt(i);
                    }),
                  ),
                ),
              TextButton(onPressed: _addTime, child: const Text('Add a date and time')),
              const SizedBox(height: 8),
              LabeledField(label: 'Dose amount', controller: doseAmount, hint: '1 tablet'),
            ],
          ),
        ),
        CheckboxRow(
          label: 'I confirmed these reminder times against the label.',
          checked: confirmed,
          onChanged: (v) => setState(() => confirmed = v),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
        PrimaryButton(label: 'Save reminders', loading: busy, onPressed: save),
      ],
    );
  }
}

class _ReminderTimePicker extends StatefulWidget {
  const _ReminderTimePicker({super.key, required this.time, required this.onChanged, required this.onRemove});

  final String time;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ReminderTimePicker> createState() => _ReminderTimePickerState();
}

class _ReminderTimePickerState extends State<_ReminderTimePicker> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final parts = widget.time.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8).clamp(0, 23).toInt() : 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0).clamp(0, 59).toInt() : 0;
    _selected = DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _label(DateTime value) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '${days[value.weekday - 1]} ${value.day} ${months[value.month - 1]} ${value.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minimum = DateTime(now.year, now.month, now.day);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Text(_label(_selected), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Repeats every day at this time.', style: TextStyle(color: Palette.inkMuted, fontSize: 12)),
              SizedBox(
                height: 216,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) => true,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(brightness: Brightness.light),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      use24hFormat: true,
                      minimumDate: minimum,
                      initialDateTime: _selected.isBefore(minimum) ? minimum : _selected,
                      onDateTimeChanged: (value) {
                        setState(() => _selected = value);
                        widget.onChanged(
                          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.medicationId});

  final String? medicationId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? filter;
  List<Medication> medications = [];
  AdherenceHistory? history;
  AdherenceSummary? summary;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    filter = widget.medicationId;
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = history == null;
      error = null;
    });
    try {
      final results = await Future.wait([Api.medications(), Api.history(medicationId: filter)]);
      if (!mounted) return;
      setState(() {
        medications = results[0] as List<Medication>;
        history = results[1] as AdherenceHistory;
        loading = false;
      });
      _loadSummary();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = describeError(e);
        loading = false;
      });
    }
  }

  // The weekly recap covers all medications; only show it on the unfiltered view.
  // Best-effort: a missing summary must never break the History screen.
  Future<void> _loadSummary() async {
    if (filter != null) {
      setState(() => summary = null);
      return;
    }
    try {
      final data = await Api.adherenceSummary();
      if (!mounted) return;
      setState(() => summary = data);
    } catch (_) {
      // Ignore; the summary is a non-essential enhancement.
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = history;
    return ScreenScaffold(
      onRefresh: load,
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('History', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Completed, skipped and missed doses over the last two weeks.'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(label: 'All medications', active: filter == null, onTap: () { setState(() => filter = null); load(); }),
              for (final med in medications)
                _Chip(label: med.displayName, active: filter == med.id, onTap: () { setState(() => filter = med.id); load(); }),
            ],
          ),
        ),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (data != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                WeeklyBarChart(history: data),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge(label: '${data.takenCount} taken', tone: Tone.safe, glyph: '✓'),
                    AppBadge(label: '${data.skippedCount} skipped', tone: Tone.neutral, glyph: '—'),
                    AppBadge(label: '${data.missedCount} missed', tone: Tone.attention, glyph: '!'),
                    AppBadge(label: '${data.pendingCount} pending', tone: Tone.info, glyph: '•'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'These counts describe what happened, not how well you did. Talk to your healthcare professional if a pattern concerns you.',
                ),
              ],
            ),
          ),
          if (filter == null && summary != null)
            InsightCard(message: summary!.message, generatedByAi: summary!.generatedByAi),
          if (data.days.isEmpty)
            const EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No doses recorded yet',
              description: 'Once reminders are confirmed, every taken, skipped or missed dose appears here.',
            )
          else
            for (final day in data.days) ...[
              Text(isToday(day.date) ? 'Today' : formatDate(day.date), style: Theme.of(context).textTheme.labelLarge),
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < day.doses.length; i++) ...[
                      if (i > 0) const Divider(),
                      Row(
                        children: [
                          SizedBox(width: 56, child: Text(day.doses[i].scheduledTime, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(day.doses[i].medicationName),
                                if (day.doses[i].doseAmountText != null) Text(day.doses[i].doseAmountText!, style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                          ),
                          AppBadge(label: day.doses[i].statusLabel, tone: doseTone(day.doses[i].status), glyph: doseGlyph(day.doses[i].status)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: active, onSelected: (_) => onTap()),
    );
  }
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  AdherenceInsights? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = data == null;
      error = null;
    });
    try {
      final result = await Api.adherenceInsights();
      if (!mounted) return;
      setState(() {
        data = result;
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

  @override
  Widget build(BuildContext context) {
    final d = data;
    return ScreenScaffold(
      onRefresh: load,
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Your on-time streak and habits over the last 30 days.'),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (d != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x33F97316)),
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  '${d.streakDays}',
                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Color(0xFFC2410C)),
                ),
                Text(
                  d.streakDays == 1 ? 'day on-time streak' : 'day on-time streak',
                  style: const TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last 30 days', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${d.adherencePercent}% of resolved doses taken on time',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge(label: '${d.takenCount} taken', tone: Tone.safe, glyph: '✓'),
                    AppBadge(label: '${d.skippedCount} skipped', tone: Tone.neutral, glyph: '—'),
                    AppBadge(label: '${d.missedCount} missed', tone: Tone.attention, glyph: '!'),
                    AppBadge(label: '${d.pendingCount} pending', tone: Tone.info, glyph: '•'),
                  ],
                ),
              ],
            ),
          ),
          InsightCard(message: d.message, generatedByAi: d.generatedByAi),
          if (d.weakestTimeOfDay != null)
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, color: Palette.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_titleCase(d.weakestTimeOfDay!)} doses', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('This is the time of day you most often miss. A reminder around then may help you stay on track.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'These numbers describe what happened, not how well you did. They are not medical advice — talk to your healthcare professional if a pattern concerns you.',
          ),
        ],
      ],
    );
  }

  static String _titleCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  EmergencyCard? card;
  EmergencyCard? draft;
  bool loading = true;
  bool busy = false;
  bool saved = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await Api.emergencyCard();
      if (!mounted) return;
      setState(() {
        card = data;
        draft = data;
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

  Future<void> save() async {
    final current = draft;
    if (current == null) return;
    setState(() {
      busy = true;
      error = null;
      saved = false;
    });
    try {
      final updated = await Api.updateEmergencyCard(current.toUpdateBody());
      setState(() {
        card = updated;
        draft = updated;
        saved = true;
      });
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const ScreenScaffold(children: [BackCircle(), Center(child: CircularProgressIndicator())]);
    if (draft == null || card == null) {
      return ScreenScaffold(children: [const BackCircle(), ErrorBanner(message: error ?? 'Unavailable', onRetry: load)]);
    }
    final current = draft!;
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Emergency card', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Share only what you choose. The QR code holds a random link, never your medical information.'),
        AppCard(
          child: ToggleRow(
            label: 'Emergency card is active',
            hint: 'Turn this off to make the link stop working.',
            value: current.isEnabled,
            onChanged: (v) => setState(() => draft = current.copyWith(isEnabled: v)),
          ),
        ),
        if (current.isEnabled)
          AppCard(
            child: Column(
              children: [
                QrImageView(data: card!.shareUrl, size: 220),
                Text(card!.shareUrl, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
                Text('Last updated ${formatDateTime(card!.updatedAt)}', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          )
        else
          const Callout(tone: Tone.neutral, title: 'The card is switched off', message: 'Nobody can open the link while the card is inactive.'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What is shared', style: Theme.of(context).textTheme.titleMedium),
              ToggleRow(label: 'Name', value: current.shareName, onChanged: (v) => setState(() => draft = current.copyWith(shareName: v))),
              ToggleRow(label: 'Allergies', value: current.shareAllergies, onChanged: (v) => setState(() => draft = current.copyWith(shareAllergies: v))),
              ToggleRow(label: 'Active medications', value: current.shareMedications, onChanged: (v) => setState(() => draft = current.copyWith(shareMedications: v))),
              ToggleRow(label: 'Emergency contact', value: current.shareEmergencyContact, onChanged: (v) => setState(() => draft = current.copyWith(shareEmergencyContact: v))),
              ToggleRow(label: 'Notes', value: current.shareNotes, onChanged: (v) => setState(() => draft = current.copyWith(shareNotes: v))),
            ],
          ),
        ),
        _EmergencyFields(draft: current, onChanged: (next) => setState(() => draft = next)),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
        if (saved) const Text('Your emergency card was updated.', style: TextStyle(color: Palette.safe)),
        PrimaryButton(label: 'Save card', loading: busy, onPressed: save),
        SecondaryButton(
          label: 'Create a new QR code',
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Create a new QR code?'),
                content: const Text('The previous QR code and link stop working immediately.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep the current one')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create new')),
                ],
              ),
            );
            if (ok == true) {
              final updated = await Api.regenerateEmergency();
              setState(() {
                card = updated;
                draft = updated;
              });
            }
          },
        ),
        const Callout(
          title: 'How the QR code works',
          message: 'The code points to a random, revocable link. Opening it shows only the fields you switched on, and never your account details.',
        ),
      ],
    );
  }
}

class _EmergencyFields extends StatefulWidget {
  const _EmergencyFields({required this.draft, required this.onChanged});

  final EmergencyCard draft;
  final ValueChanged<EmergencyCard> onChanged;

  @override
  State<_EmergencyFields> createState() => _EmergencyFieldsState();
}

class _EmergencyFieldsState extends State<_EmergencyFields> {
  late final name = TextEditingController(text: widget.draft.displayName ?? '');
  late final allergies = TextEditingController(text: widget.draft.allergies ?? '');
  late final contact = TextEditingController(text: widget.draft.emergencyContactName ?? '');
  late final phone = TextEditingController(text: widget.draft.emergencyContactPhone ?? '');
  late final notes = TextEditingController(text: widget.draft.notes ?? '');

  @override
  void dispose() {
    name.dispose();
    allergies.dispose();
    contact.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  void emit() {
    widget.onChanged(
      widget.draft.copyWith(
        displayName: name.text,
        allergies: allergies.text,
        emergencyContactName: contact.text,
        emergencyContactPhone: phone.text,
        notes: notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          LabeledField(label: 'Name shown', controller: name, hint: 'The name responders should see'),
          const SizedBox(height: 12),
          LabeledField(label: 'Allergies', controller: allergies, maxLines: 3, hint: 'Penicillin'),
          const SizedBox(height: 12),
          LabeledField(label: 'Emergency contact name', controller: contact),
          const SizedBox(height: 12),
          LabeledField(label: 'Emergency contact phone', controller: phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          LabeledField(label: 'Important notes', controller: notes, maxLines: 3),
          const SizedBox(height: 8),
          TextButton(onPressed: emit, child: const Text('Apply details')),
        ],
      ),
    );
  }
}

class CaregiversScreen extends StatefulWidget {
  const CaregiversScreen({super.key});

  @override
  State<CaregiversScreen> createState() => _CaregiversScreenState();
}

class _CaregiversScreenState extends State<CaregiversScreen> {
  final email = TextEditingController();
  List<String> selected = ['VIEW_ADHERENCE'];
  List<Caregiver> people = [];
  bool loading = true;
  bool busy = false;
  String? error;
  String? invitationToken;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await Api.caregivers();
      if (!mounted) return;
      setState(() {
        people = data;
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

  String statusLabel(String status) {
    switch (status) {
      case 'Invited':
        return 'Invitation sent';
      case 'Accepted':
        return 'Waiting for your approval';
      case 'Active':
        return 'Active';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      onRefresh: load,
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Share access', style: Theme.of(context).textTheme.headlineMedium),
        const Text('You stay the owner of your data. A caregiver only sees exactly what you approve, and you can remove access at any time.'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite a caregiver', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              LabeledField(label: 'Email address', controller: email, keyboardType: TextInputType.emailAddress, hint: 'caregiver@example.com'),
              const SizedBox(height: 12),
              Text('What they may see', style: Theme.of(context).textTheme.labelLarge),
              for (final permission in caregiverPermissions)
                CheckboxRow(
                  label: permission.$2,
                  checked: selected.contains(permission.$1),
                  onChanged: (v) => setState(() {
                    if (v) {
                      selected = [...selected, permission.$1];
                    } else {
                      selected = selected.where((item) => item != permission.$1).toList();
                    }
                  }),
                ),
              PrimaryButton(
                label: 'Send invitation',
                loading: busy,
                onPressed: () async {
                  if (email.text.trim().isEmpty) {
                    setState(() => error = "Enter the caregiver's email address.");
                    return;
                  }
                  setState(() {
                    busy = true;
                    error = null;
                    invitationToken = null;
                  });
                  try {
                    final result = await Api.inviteCaregiver(email.text.trim(), selected);
                    email.clear();
                    setState(() => invitationToken = result['invitationToken']?.toString());
                    await load();
                  } catch (e) {
                    setState(() => error = describeError(e));
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
              ),
            ],
          ),
        ),
        if (invitationToken != null)
          Callout(title: 'Invitation created', message: 'Share this one-time code with the caregiver so they can accept: $invitationToken'),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
        Text('People with access', style: Theme.of(context).textTheme.titleMedium),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (people.isEmpty)
          EmptyState(
            illustration: Image.asset('assets/illustrations/caregiver-share.png', height: 140),
            title: 'Nobody has access',
            description: 'Invite someone you trust if you would like them to follow your medication routine.',
          )
        else
          for (final person in people)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(person.displayName ?? person.email, style: Theme.of(context).textTheme.titleMedium),
                            Text(person.email, style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                      AppBadge(
                        label: statusLabel(person.status),
                        tone: person.status == 'Active' ? Tone.safe : (person.status == 'Accepted' ? Tone.attention : Tone.neutral),
                      ),
                    ],
                  ),
                  for (final permission in caregiverPermissions)
                    CheckboxRow(
                      label: permission.$2,
                      checked: person.permissions.contains(permission.$1),
                      enabled: person.status == 'Accepted' || person.status == 'Active',
                      onChanged: (v) async {
                        final next = v
                            ? [...person.permissions, permission.$1]
                            : person.permissions.where((item) => item != permission.$1).toList();
                        try {
                          await Api.updateCaregiverPermissions(person.id, next);
                          await load();
                        } catch (e) {
                          setState(() => error = describeError(e));
                        }
                      },
                    ),
                  DangerButton(
                    label: 'Remove access',
                    onPressed: () async {
                      await Api.revokeCaregiver(person.id);
                      await load();
                    },
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late final name = TextEditingController(text: ref.read(authProvider).user?.displayName ?? '');
  bool busy = false;
  bool saved = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Personal Information', style: Theme.of(context).textTheme.headlineMedium),
        const Text('How MedGuard greets you and the email on this account.'),
        AppCard(
          child: Column(
            children: [
              LabeledField(label: 'Name', controller: name),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
        if (saved) const Text('Your name was updated.', style: TextStyle(color: Palette.safe)),
        PrimaryButton(
          label: 'Save',
          loading: busy,
          onPressed: () async {
            setState(() {
              busy = true;
              error = null;
              saved = false;
            });
            try {
              await ref.read(authProvider.notifier).updateProfile({'displayName': name.text.trim()});
              setState(() => saved = true);
            } catch (e) {
              setState(() => error = describeError(e));
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
        ),
      ],
    );
  }
}

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  EmergencyCard? card;
  final allergies = TextEditingController();
  final contact = TextEditingController();
  final phone = TextEditingController();
  bool loading = true;
  bool busy = false;
  bool saved = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    allergies.dispose();
    contact.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await Api.emergencyCard();
      if (!mounted) return;
      setState(() {
        card = data;
        allergies.text = data.allergies ?? '';
        contact.text = data.emergencyContactName ?? '';
        phone.text = data.emergencyContactPhone ?? '';
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

  @override
  Widget build(BuildContext context) {
    if (loading) return const ScreenScaffold(children: [BackCircle(), Center(child: CircularProgressIndicator())]);
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Health Information', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Allergies and emergency contact details. These only appear on your emergency card when you switch those fields on.'),
        AppCard(
          child: Column(
            children: [
              LabeledField(label: 'Allergies', controller: allergies, maxLines: 3, hint: 'Penicillin'),
              const SizedBox(height: 12),
              LabeledField(label: 'Emergency contact name', controller: contact),
              const SizedBox(height: 12),
              LabeledField(label: 'Emergency contact phone', controller: phone, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
        if (saved) const Text('Your health information was updated.', style: TextStyle(color: Palette.safe)),
        PrimaryButton(
          label: 'Save',
          loading: busy,
          onPressed: () async {
            final current = card;
            if (current == null) return;
            setState(() {
              busy = true;
              error = null;
              saved = false;
            });
            try {
              final updated = await Api.updateEmergencyCard(
                current
                    .copyWith(
                      allergies: allergies.text,
                      emergencyContactName: contact.text,
                      emergencyContactPhone: phone.text,
                    )
                    .toUpdateBody(),
              );
              setState(() {
                card = updated;
                saved = true;
              });
            } catch (e) {
              setState(() => error = describeError(e));
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
        ),
      ],
    );
  }
}

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool busy = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('App Settings', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Device lock and how MedGuard behaves on this phone.'),
        AppCard(
          child: ToggleRow(
            label: 'Biometric app lock',
            hint: 'Ask for Face ID, fingerprint or the device passcode after the app has been in the background.',
            value: user?.biometricLockEnabled ?? false,
            onChanged: busy
                ? (_) {}
                : (value) async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      if (value) {
                        final available = await LocalAuthentication().canCheckBiometrics || await LocalAuthentication().isDeviceSupported();
                        if (!available) {
                          if (!context.mounted) return;
                          await showDialog<void>(
                            context: context,
                            builder: (context) => const AlertDialog(
                              title: Text('Device lock not available'),
                              content: Text('Set up a passcode, fingerprint or face unlock on this device first, then enable the app lock.'),
                            ),
                          );
                          return;
                        }
                      }
                      await ref.read(authProvider.notifier).updateProfile({'biometricLockEnabled': value});
                    } catch (e) {
                      setState(() => error = describeError(e));
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
          ),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
      ],
    );
  }
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool busy = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Notifications', style: Theme.of(context).textTheme.headlineMedium),
        const Text('How reminder alerts appear on the lock screen. MedGuard sends a local notification at each confirmed reminder time.'),
        AppCard(
          child: ToggleRow(
            label: 'Private notifications',
            hint: 'Lock-screen reminders say “You have a medication reminder” instead of naming the medication.',
            value: user?.privacyNotificationsEnabled ?? true,
            onChanged: busy
                ? (_) {}
                : (value) async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await ref.read(authProvider.notifier).updateProfile({'privacyNotificationsEnabled': value});
                      await Reminders.syncFromServer(privacyMode: value);
                    } catch (e) {
                      setState(() => error = describeError(e));
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
          ),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: Palette.critical)),
      ],
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Privacy', style: Theme.of(context).textTheme.headlineMedium),
        const Text('How MedGuard treats medication information on this device.'),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('On this device', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
              SizedBox(height: 8),
              Text('Screenshots are blocked where the platform supports it, and medication content is hidden in the app switcher.'),
            ],
          ),
        ),
        const Callout(
          title: 'How MedGuard makes decisions',
          message:
              'Safety findings come from deterministic checks against trusted medication data. Plain-language explanations only describe findings that already exist; they never create or dismiss one.',
        ),
      ],
    );
  }
}

class FindingExplanationScreen extends StatefulWidget {
  const FindingExplanationScreen({super.key, required this.id});

  final String id;

  @override
  State<FindingExplanationScreen> createState() => _FindingExplanationScreenState();
}

class _FindingExplanationScreenState extends State<FindingExplanationScreen> {
  SafetyFinding? finding;
  SafetyExplanation? explanation;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final findings = await Api.findings();
      final match = findings.where((f) => f.id == widget.id).firstOrNull;
      SafetyExplanation? exp;
      try {
        exp = await Api.explanation(widget.id);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        finding = match;
        explanation = exp;
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

  @override
  Widget build(BuildContext context) {
    if (loading) return const ScreenScaffold(children: [BackCircle(), Center(child: CircularProgressIndicator())]);
    final current = finding;
    if (current == null) {
      return ScreenScaffold(children: [const BackCircle(), ErrorBanner(message: error ?? 'This safety finding is no longer available.', onRetry: load)]);
    }
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Why am I seeing this?', style: Theme.of(context).textTheme.headlineMedium),
        Text(current.title),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why it matters', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final med in current.medications) ...[
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Palette.brand),
                    const SizedBox(width: 8),
                    Expanded(child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    AppBadge(label: med.verified ? 'Verified' : 'Unverified', tone: med.verified ? Tone.safe : Tone.neutral, glyph: med.verified ? '✓' : '?'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text('contains ${med.ingredientOriginalName ?? current.ingredient?.name ?? 'this ingredient'}${med.strengthText != null ? ' · ${med.strengthText}' : ''}'),
                ),
              ],
              if (explanation != null) Text(explanation!.explanation) else const Text('The explanation is unavailable right now. The finding above stays available and unchanged.'),
            ],
          ),
        ),
        Callout(
          tone: findingTone(current.severity),
          title: 'What you can do',
          message: explanation?.disclaimer ?? 'Review the medication labels and confirm with a pharmacist or healthcare professional if you are unsure.',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sources', style: Theme.of(context).textTheme.titleMedium),
              FieldRow(label: 'Data source', value: current.source),
              FieldRow(label: 'Dataset version', value: current.datasetVersion),
              FieldRow(label: 'Last checked', value: formatDateTime(current.detectedAt)),
              FieldRow(label: 'Verification', value: current.verified ? 'Verified against trusted data' : 'Not independently verified'),
              FieldRow(label: 'Explanation', value: explanation?.generatedByAi == true ? 'AI explanation' : explanation?.source ?? 'Standard explanation', divider: false),
            ],
          ),
        ),
      ],
    );
  }
}
