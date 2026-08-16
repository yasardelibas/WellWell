import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/reminders.dart';
import '../state/auth.dart';
import '../l10n/language_controller.dart';
import '../theme/palette.dart';
import '../theme/theme_controller.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: med.remainingQuantity?.toString() ?? '');
    final result = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.medDetailDosesRemainingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.medDetailDosesRemainingMessage),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.medDetailDosesRemainingHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.commonCancel)),
          if (med.remainingQuantity != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, -1),
              child: Text(l10n.commonClear),
            ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogContext, text.isEmpty ? -1 : (int.tryParse(text) ?? med.remainingQuantity ?? 0));
            },
            child: Text(l10n.commonSave),
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

  Future<void> _editExpiration(Medication med) async {
    final current = med.expirationDate == null ? null : DateTime.tryParse(med.expirationDate!);
    final now = DateTime.now();
    final picked = await showBrandDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 15),
      title: AppLocalizations.of(context)!.medDetailExpirationPickerTitle,
    );
    if (picked == null || !mounted) return;
    setState(() {
      busy = true;
      actionError = null;
    });
    try {
      await Api.setExpiration(med.id, picked);
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

  Future<void> _clearExpiration(Medication med) async {
    setState(() {
      busy = true;
      actionError = null;
    });
    try {
      await Api.setExpiration(med.id, null);
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
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return const ScreenScaffold(showBack: true, children: [Center(child: CircularProgressIndicator())]);
    }
    if (error != null || item == null) {
      return ScreenScaffold(showBack: true, children: [ErrorBanner(message: error ?? l10n.medDetailNotFound, onRetry: load)]);
    }
    final med = item!;
    final active = schedules.where((s) => s.isActive).toList();
    final nextDose = today?.doses.where((d) => d.medicationId == med.id && (d.status == 'pending' || d.status == 'snoozed')).firstOrNull;
    final dosesPerDay = active.length;
    final rq = med.remainingQuantity;
    final daysLeft = (rq != null && dosesPerDay > 0) ? (rq / dosesPerDay).floor() : null;

    return ScreenScaffold(
      onRefresh: load,
      showBack: true,
      title: med.displayName,
      children: [
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
            title: l10n.medDetailUnverifiedTitle,
            message: l10n.medDetailUnverifiedMessage,
            child: editing
                ? null
                : SecondaryButton(label: l10n.medDetailEditToVerify, onPressed: () => _beginEdit(med)),
          ),
        if (editing)
          Callout(
            tone: Tone.info,
            title: l10n.commonUsedToVerify,
            message: l10n.medDetailUsedToVerifyMessage,
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(editing ? l10n.commonUsedToVerify : l10n.medDetailActiveIngredients, style: Theme.of(context).textTheme.titleMedium)),
                  if (!editing)
                    TextButton(onPressed: () => _beginEdit(med), child: Text(l10n.commonEdit)),
                ],
              ),
              if (editing) ...[
                const SizedBox(height: 8),
                LabeledField(label: l10n.commonBrandName, controller: brand, usedForVerification: true, icon: Icons.local_pharmacy_outlined),
                const SizedBox(height: 12),
                LabeledField(label: l10n.commonGenericName, controller: generic, usedForVerification: true, icon: Icons.science_outlined),
                const SizedBox(height: 12),
                LabeledField(label: l10n.commonStrength, controller: strength, usedForVerification: true, icon: Icons.fitness_center_outlined),
                const SizedBox(height: 12),
                LabeledField(label: l10n.commonDosageForm, controller: form, usedForVerification: true, icon: Icons.medication_outlined),
                const SizedBox(height: 12),
                IngredientEditor(
                  key: const ValueKey('detail-ingredients'),
                  ingredients: editIngredients,
                  onChanged: (v) => editIngredients = v,
                ),
              ] else if (med.ingredients.isEmpty)
                Text(l10n.medDetailNoIngredients)
              else
                for (final ingredient in med.ingredients) ...[
                  const SizedBox(height: 10),
                  Text(ingredient.normalizedName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(l10n.medDetailIngredientStrengthLine(
                    ingredient.displayStrength.isEmpty ? l10n.medDetailStrengthNotRecorded : ingredient.displayStrength,
                    ingredient.originalName,
                  )),
                  if (ingredient.rxCui != null) Text(l10n.medDetailRxNormIdentifier(ingredient.rxCui!), style: Theme.of(context).textTheme.labelSmall),
                ],
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editing ? l10n.commonOnTheLabelOnly : l10n.medDetailAbout, style: Theme.of(context).textTheme.titleMedium),
              if (editing) ...[
                const SizedBox(height: 8),
                LabeledField(label: l10n.commonRoute, controller: route, usedForVerification: false, icon: Icons.route_outlined),
                const SizedBox(height: 12),
                LabeledField(label: l10n.commonLabelDirections, controller: directions, maxLines: 3, usedForVerification: false, icon: Icons.list_alt_outlined),
                const SizedBox(height: 12),
                LabeledField(label: l10n.commonNotes, controller: notes, maxLines: 2, usedForVerification: false, icon: Icons.sticky_note_2_outlined),
                const SizedBox(height: 16),
                PrimaryButton(label: l10n.medDetailSaveAndVerify, loading: busy, onPressed: _saveEdits),
                SecondaryButton(label: l10n.commonCancel, onPressed: () => setState(() => editing = false)),
              ] else ...[
                FieldRow(label: l10n.commonBrand, value: med.brandName, icon: Icons.local_pharmacy_outlined),
                FieldRow(label: l10n.commonGenericName, value: med.genericName, icon: Icons.science_outlined),
                FieldRow(label: l10n.commonStrength, value: med.strength, icon: Icons.fitness_center_outlined),
                FieldRow(label: l10n.commonForm, value: med.dosageForm, icon: Icons.medication_outlined),
                FieldRow(label: l10n.commonRoute, value: med.route, icon: Icons.route_outlined),
                FieldRow(label: l10n.commonDirections, value: med.labelDirections, icon: Icons.list_alt_outlined),
                FieldRow(label: l10n.commonManufacturer, value: med.manufacturer, icon: Icons.factory_outlined),
                FieldRow(label: l10n.commonNotes, value: med.notes, divider: false, icon: Icons.sticky_note_2_outlined),
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
                    Icon(Icons.auto_awesome, size: 20, color: Palette.brand),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.medDetailAboutMedication, style: Theme.of(context).textTheme.titleMedium)),
                    if (education!.generatedByAi)
                      Text(l10n.medDetailAiInfo, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(education!.message, style: const TextStyle(height: 1.4)),
                if (education!.usedFor.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(l10n.medDetailCommonlyUsedFor, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final use in education!.usedFor) AppBadge(label: use, tone: Tone.info)],
                  ),
                ],
                if (education!.drugClass != null && education!.drugClass!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FieldRow(label: l10n.medDetailClass, value: education!.drugClass, divider: false),
                ],
                if (education!.usedFor.isNotEmpty || education!.drugClass != null) ...[
                  const SizedBox(height: 8),
                  Text(l10n.medDetailSourceRxClass, style: Theme.of(context).textTheme.labelSmall),
                ],
              ],
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.medDetailSourceTitle, style: Theme.of(context).textTheme.titleMedium),
              FieldRow(label: l10n.commonProvider, value: med.provenance?.provider ?? l10n.medDetailEnteredManually),
              FieldRow(label: l10n.commonIdentifier, value: med.provenance?.externalIdentifier ?? med.rxCui),
              FieldRow(label: l10n.commonDatasetVersion, value: med.provenance?.datasetVersion),
              FieldRow(label: l10n.medDetailLastVerified, value: med.provenance == null ? l10n.medDetailNotVerified : formatDateTime(med.provenance!.retrievedAt)),
              FieldRow(label: l10n.medDetailAddedOn, value: med.createdAt == null ? null : formatDate(med.createdAt!), divider: false),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.medDetailScheduleTitle, style: Theme.of(context).textTheme.titleMedium)),
                  AppBadge(label: l10n.medDetailActiveCount(active.length), tone: active.isEmpty ? Tone.neutral : Tone.info, glyph: '⏰'),
                ],
              ),
              const SizedBox(height: 8),
              if (active.isEmpty)
                Text(l10n.medDetailNoRemindersYet)
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
                      Text(l10n.medDetailNextDose, style: Theme.of(context).textTheme.labelLarge),
                      Text(nextDose.scheduledTime, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: l10n.commonTake,
                        loading: busy,
                        onPressed: () async {
                          HapticFeedback.selectionClick();
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
                label: active.isEmpty ? l10n.medDetailSetUpReminders : l10n.medDetailEditReminders,
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
                  Expanded(child: Text(l10n.medDetailRefillTitle, style: Theme.of(context).textTheme.titleMedium)),
                  Icon(Icons.medication_outlined, color: Palette.brand),
                ],
              ),
              const SizedBox(height: 8),
              if (rq == null)
                Text(l10n.medDetailRefillTrackMessage)
              else ...[
                Text(l10n.medDetailDosesLeft(rq), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                if (daysLeft != null)
                  Text(
                    daysLeft <= 0
                        ? l10n.medDetailOutOfRefill
                        : l10n.medDetailDaysLeftAtSchedule(daysLeft),
                  )
                else
                  Text(l10n.medDetailEstimateDaysMessage),
                if (daysLeft != null && daysLeft <= 5) ...[
                  const SizedBox(height: 8),
                  Callout(
                    tone: Tone.attention,
                    title: l10n.medDetailRunningLowTitle,
                    message: l10n.medDetailRunningLowMessage,
                  ),
                ],
              ],
              const SizedBox(height: 12),
              SecondaryButton(
                label: rq == null ? l10n.medDetailAddPillCount : l10n.medDetailUpdatePillCount,
                onPressed: () => _editRefill(med),
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
                  Expanded(child: Text(l10n.medDetailExpirationTitle, style: Theme.of(context).textTheme.titleMedium)),
                  Icon(Icons.event_outlined, color: Palette.brand),
                ],
              ),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                final expiration = med.expirationDate == null ? null : DateTime.tryParse(med.expirationDate!);
                if (expiration == null) {
                  return Text(l10n.medDetailExpirationEmptyMessage);
                }
                final daysUntil = expiration.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDate(med.expirationDate!), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    Text(
                      daysUntil < 0
                          ? l10n.medDetailExpiredAgo(-daysUntil)
                          : daysUntil == 0
                              ? l10n.medDetailExpiresToday
                              : l10n.medDetailExpiresIn(daysUntil),
                    ),
                    if (daysUntil <= 30) ...[
                      const SizedBox(height: 8),
                      Callout(
                        tone: daysUntil < 0 ? Tone.critical : Tone.attention,
                        title: daysUntil < 0 ? l10n.medDetailExpiredTitle : l10n.medDetailExpiringSoonTitle,
                        message: daysUntil < 0
                            ? l10n.medDetailExpiredMessage
                            : l10n.medDetailExpiringSoonMessage,
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: med.expirationDate == null ? l10n.medDetailAddExpiration : l10n.medDetailUpdateExpiration,
                      onPressed: () => _editExpiration(med),
                    ),
                  ),
                  if (med.expirationDate != null) ...[
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => _clearExpiration(med), child: Text(l10n.commonClear)),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (actionError != null) Text(actionError!, style: TextStyle(color: Palette.critical)),
        SecondaryButton(label: l10n.medDetailViewDoseHistory, onPressed: () => context.push('/history?medicationId=${med.id}')),
        DangerButton(
          label: l10n.medDetailRemoveMedication,
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.medDetailRemoveDialogTitle),
                content: Text(l10n.medDetailRemoveDialogMessage),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.medDetailKeepIt)),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonRemove)),
                ],
              ),
            );
            if (ok == true) {
              HapticFeedback.mediumImpact();
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
      setState(() => error = AppLocalizations.of(context)!.newMedBrandOrGenericRequired);
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
    final l10n = AppLocalizations.of(context)!;
    return ScreenScaffold(
      showBack: true,
      title: l10n.newMedTitle,
      subtitle: l10n.newMedSubtitle,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.commonUsedToVerify, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.newMedUsedToVerifyMessage),
              const SizedBox(height: 12),
              LabeledField(label: l10n.commonBrandName, controller: brand, hint: l10n.newMedHintAsPrinted, usedForVerification: true, icon: Icons.local_pharmacy_outlined),
              const SizedBox(height: 12),
              LabeledField(label: l10n.commonGenericName, controller: generic, usedForVerification: true, icon: Icons.science_outlined),
              const SizedBox(height: 12),
              LabeledField(label: l10n.commonStrength, controller: strength, hint: '500 mg', usedForVerification: true, icon: Icons.fitness_center_outlined),
              const SizedBox(height: 12),
              LabeledField(label: l10n.commonDosageForm, controller: form, usedForVerification: true, icon: Icons.medication_outlined),
              const SizedBox(height: 12),
              IngredientEditor(ingredients: ingredients, onChanged: (v) => ingredients = v),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.commonOnTheLabelOnly, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.newMedDirectionsStoredMessage),
              const SizedBox(height: 12),
              LabeledField(label: l10n.commonLabelDirections, controller: directions, maxLines: 3, usedForVerification: false, icon: Icons.list_alt_outlined),
            ],
          ),
        ),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(label: l10n.newMedSaveButton, loading: busy, onPressed: save),
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
    final l10n = AppLocalizations.of(context)!;
    final cleaned = times.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final timePattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (cleaned.isEmpty) {
      setState(() => error = l10n.scheduleAddAtLeastOne);
      return;
    }
    final invalid = cleaned.where((t) => !timePattern.hasMatch(t)).firstOrNull;
    if (invalid != null) {
      setState(() => error = l10n.scheduleInvalidTime(invalid));
      return;
    }
    if (!confirmed) {
      setState(() => error = l10n.scheduleConfirmBeforeSaving);
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
          error = AppLocalizations.of(context)!.scheduleNotificationPermissionOff;
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
    final l10n = AppLocalizations.of(context)!;
    final picked = await showBrandTimePicker(context: context, initialTime: '08:00', title: l10n.scheduleAddReminderTime);
    if (picked == null || !mounted) return;
    setState(() {
      times.add(picked);
      timeKeys.add(UniqueKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return const ScreenScaffold(showBack: true, children: [Center(child: CircularProgressIndicator())]);
    }
    return ScreenScaffold(
      showBack: true,
      title: l10n.scheduleEditReminderTitle,
      subtitle: medication?.displayName,
      children: [
        if (suggestion?.labelInstruction != null)
          Callout(title: l10n.scheduleFromLabelTitle, message: suggestion!.labelInstruction!),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < times.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReminderTimeTile(
                    key: timeKeys[i],
                    time: times[i],
                    onEdit: () async {
                      final picked = await showBrandTimePicker(context: context, initialTime: times[i]);
                      if (picked == null || !mounted) return;
                      setState(() => times[i] = picked);
                    },
                    onRemove: () {
                      setState(() {
                        times.removeAt(i);
                        timeKeys.removeAt(i);
                      });
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.scheduleAddReminderTime),
                ),
              ),
              const SizedBox(height: 8),
              LabeledField(label: l10n.commonDoseAmount, controller: doseAmount, hint: '1 tablet'),
            ],
          ),
        ),
        CheckboxRow(
          label: l10n.scheduleConfirmCheckbox,
          checked: confirmed,
          onChanged: (v) => setState(() => confirmed = v),
        ),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(label: l10n.scheduleSaveReminders, loading: busy, onPressed: save),
      ],
    );
  }
}

/// A single reminder time shown as a clean, tappable row. Tapping opens the
/// themed time-picker bottom sheet; only the time of day matters because
/// schedules repeat daily (see matchDateTimeComponents in Reminders).
class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({super.key, required this.time, required this.onEdit, required this.onRemove});

  final String time;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: Palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.line),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_outlined, color: Palette.brand, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  Text(AppLocalizations.of(context)!.commonRepeatsEveryDay, style: TextStyle(color: Palette.inkMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(AppLocalizations.of(context)!.commonEdit, style: TextStyle(color: Palette.brand, fontWeight: FontWeight.w600)),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, color: Palette.inkMuted),
            ),
          ],
        ),
      ),
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
  // Null means the default "last 2 weeks" server window. Otherwise the first day of the chosen month.
  DateTime? selectedMonth;

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
      final month = selectedMonth;
      final from = month == null ? null : DateTime(month.year, month.month, 1);
      final to = month == null ? null : DateTime(month.year, month.month + 1, 0);
      final results = await Future.wait([Api.medications(), Api.history(medicationId: filter, from: from, to: to)]);
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

  void _shiftMonth(int delta) {
    final base = selectedMonth ?? DateTime.now();
    final next = DateTime(base.year, base.month + delta, 1);
    // Don't allow paging into the future beyond the current month.
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month, 1))) return;
    setState(() => selectedMonth = next);
    load();
  }

  void _resetToDefaultWindow() {
    setState(() => selectedMonth = null);
    load();
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
    final l10n = AppLocalizations.of(context)!;
    final data = history;
    return ScreenScaffold(
      onRefresh: load,
      showBack: true,
      title: l10n.historyTitle,
      subtitle: selectedMonth == null
          ? l10n.historySubtitleDefault
          : l10n.historySubtitleMonth(formatMonth(selectedMonth!)),
      children: [
        Row(
          children: [
            IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Center(
                child: Text(
                  selectedMonth == null ? l10n.historyLast2Weeks : formatMonth(selectedMonth!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                final now = DateTime.now();
                final atLatest = selectedMonth == null ||
                    (selectedMonth!.year == now.year && selectedMonth!.month == now.month);
                if (!atLatest) _shiftMonth(1);
              },
              icon: const Icon(Icons.chevron_right),
            ),
            if (selectedMonth != null) TextButton(onPressed: _resetToDefaultWindow, child: Text(l10n.commonReset)),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(label: l10n.historyAllMedications, active: filter == null, onTap: () { setState(() => filter = null); load(); }),
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
                if (selectedMonth == null) ...[
                  Text(l10n.historyThisWeek, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  WeeklyBarChart(history: data),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(formatMonth(selectedMonth!), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge(label: l10n.commonTakenCount(data.takenCount), tone: Tone.safe, glyph: '✓'),
                    AppBadge(label: l10n.commonSkippedCount(data.skippedCount), tone: Tone.neutral, glyph: '—'),
                    AppBadge(label: l10n.commonMissedCount(data.missedCount), tone: Tone.attention, glyph: '!'),
                    AppBadge(label: l10n.commonPendingCount(data.pendingCount), tone: Tone.info, glyph: '•'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l10n.historyDisclaimer),
              ],
            ),
          ),
          if (filter == null && summary != null)
            InsightCard(message: summary!.message, generatedByAi: summary!.generatedByAi),
          if (data.days.isEmpty)
            EmptyState(
              icon: Icons.calendar_today_outlined,
              title: l10n.historyEmptyTitle,
              description: l10n.historyEmptyDescription,
            )
          else
            for (final day in data.days) ...[
              Text(isToday(day.date) ? l10n.commonToday : formatDate(day.date), style: Theme.of(context).textTheme.labelLarge),
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
    final l10n = AppLocalizations.of(context)!;
    final d = data;
    return ScreenScaffold(
      onRefresh: load,
      showBack: true,
      title: l10n.insightsTitle,
      subtitle: l10n.insightsSubtitle,
      children: [
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (d != null) ...[
          Builder(builder: (context) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark ? [const Color(0xFF3A2413), const Color(0xFF2B1B0E)] : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
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
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: dark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C)),
                ),
                Text(
                  l10n.insightsStreakDayLabel(d.streakDays),
                  style: TextStyle(color: dark ? const Color(0xFFFDD9B5) : const Color(0xFF9A3412), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            );
          }),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.insightsLast30Days, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.insightsAdherencePercent(d.adherencePercent),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge(label: l10n.commonTakenCount(d.takenCount), tone: Tone.safe, glyph: '✓'),
                    AppBadge(label: l10n.commonSkippedCount(d.skippedCount), tone: Tone.neutral, glyph: '—'),
                    AppBadge(label: l10n.commonMissedCount(d.missedCount), tone: Tone.attention, glyph: '!'),
                    AppBadge(label: l10n.commonPendingCount(d.pendingCount), tone: Tone.info, glyph: '•'),
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
                  Icon(Icons.schedule, color: Palette.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.insightsWeakestTimeDoses(_timeOfDayLabel(d.weakestTimeOfDay!, l10n)), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(l10n.insightsWeakestTimeMessage),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(l10n.insightsDisclaimer),
        ],
      ],
    );
  }

  static String _titleCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  static String _timeOfDayLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'morning':
        return l10n.insightsTimeMorning;
      case 'afternoon':
        return l10n.insightsTimeAfternoon;
      case 'evening':
        return l10n.insightsTimeEvening;
      case 'night':
        return l10n.insightsTimeNight;
      default:
        return _titleCase(value);
    }
  }
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
    });
    try {
      final updated = await Api.updateEmergencyCard(current.toUpdateBody());
      setState(() {
        card = updated;
        draft = updated;
      });
      if (context.mounted) showAppSnackBar(context, AppLocalizations.of(context)!.emergencyUpdatedSnackbar);
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) return const ScreenScaffold(showBack: true, children: [Center(child: CircularProgressIndicator())]);
    if (draft == null || card == null) {
      return ScreenScaffold(showBack: true, children: [ErrorBanner(message: error ?? l10n.emergencyUnavailable, onRetry: load)]);
    }
    final current = draft!;
    return ScreenScaffold(
      showBack: true,
      title: l10n.profileEmergencyCard,
      subtitle: l10n.emergencySubtitle,
      children: [
        AppCard(
          child: ToggleRow(
            label: l10n.emergencyActiveToggle,
            hint: l10n.emergencyActiveHint,
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
                Text(l10n.emergencyLastUpdated(formatDateTime(card!.updatedAt)), style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: card!.shareUrl));
                          showAppSnackBar(context, l10n.commonLinkCopied);
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(l10n.commonCopyLink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => SharePlus.instance.share(ShareParams(text: card!.shareUrl)),
                        icon: const Icon(Icons.ios_share),
                        label: Text(l10n.commonShare),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Callout(tone: Tone.neutral, title: l10n.emergencyOffTitle, message: l10n.emergencyOffMessage),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.emergencyWhatIsShared, style: Theme.of(context).textTheme.titleMedium),
              ToggleRow(label: l10n.authName, value: current.shareName, onChanged: (v) => setState(() => draft = current.copyWith(shareName: v))),
              ToggleRow(label: l10n.emergencyAllergies, value: current.shareAllergies, onChanged: (v) => setState(() => draft = current.copyWith(shareAllergies: v))),
              ToggleRow(label: l10n.emergencyActiveMedications, value: current.shareMedications, onChanged: (v) => setState(() => draft = current.copyWith(shareMedications: v))),
              ToggleRow(label: l10n.emergencyContactLabel, value: current.shareEmergencyContact, onChanged: (v) => setState(() => draft = current.copyWith(shareEmergencyContact: v))),
              ToggleRow(label: l10n.commonNotes, value: current.shareNotes, onChanged: (v) => setState(() => draft = current.copyWith(shareNotes: v))),
            ],
          ),
        ),
        _EmergencyFields(draft: current, onChanged: (next) => setState(() => draft = next)),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(label: l10n.emergencySaveCard, loading: busy, onPressed: save),
        SecondaryButton(
          label: l10n.emergencyCreateNewQr,
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.emergencyNewQrDialogTitle),
                content: Text(l10n.emergencyNewQrDialogMessage),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.emergencyKeepCurrent)),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.emergencyCreateNew)),
                ],
              ),
            );
            if (ok == true) {
              HapticFeedback.mediumImpact();
              final updated = await Api.regenerateEmergency();
              setState(() {
                card = updated;
                draft = updated;
              });
            }
          },
        ),
        Callout(
          title: l10n.emergencyHowItWorksTitle,
          message: l10n.emergencyHowItWorksMessage,
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
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        children: [
          LabeledField(label: l10n.emergencyNameShown, controller: name, hint: l10n.emergencyNameShownHint),
          const SizedBox(height: 12),
          LabeledField(label: l10n.emergencyAllergies, controller: allergies, maxLines: 3, hint: 'Penicillin'),
          const SizedBox(height: 12),
          LabeledField(label: l10n.emergencyContactName, controller: contact),
          const SizedBox(height: 12),
          LabeledField(label: l10n.emergencyContactPhone, controller: phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          LabeledField(label: l10n.emergencyImportantNotes, controller: notes, maxLines: 3),
          const SizedBox(height: 8),
          TextButton(onPressed: emit, child: Text(l10n.emergencyApplyDetails)),
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

  String statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'Invited':
        return l10n.caregiversStatusInvited;
      case 'Accepted':
        return l10n.caregiversStatusWaiting;
      case 'Active':
        return l10n.caregiversStatusActive;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenScaffold(
      onRefresh: load,
      showBack: true,
      title: l10n.profileShareAccess,
      subtitle: l10n.caregiversSubtitle,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.caregiversInviteTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              LabeledField(label: l10n.commonEmailAddress, controller: email, keyboardType: TextInputType.emailAddress, hint: 'caregiver@example.com'),
              const SizedBox(height: 12),
              Text(l10n.caregiversWhatTheyMaySee, style: Theme.of(context).textTheme.labelLarge),
              for (final code in caregiverPermissionCodes)
                CheckboxRow(
                  label: caregiverPermissionLabel(code, l10n),
                  checked: selected.contains(code),
                  onChanged: (v) => setState(() {
                    if (v) {
                      selected = [...selected, code];
                    } else {
                      selected = selected.where((item) => item != code).toList();
                    }
                  }),
                ),
              PrimaryButton(
                label: l10n.caregiversSendInvitation,
                loading: busy,
                onPressed: () async {
                  if (email.text.trim().isEmpty) {
                    setState(() => error = l10n.caregiversEnterEmail);
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
                    final relationshipId = (result['caregiver'] as Map?)?['id']?.toString();
                    final token = result['invitationToken']?.toString();
                    // Combined so the caregiver only has to paste one code; the redeem screen splits it back apart.
                    setState(() => invitationToken = relationshipId != null && token != null ? '$relationshipId.$token' : null);
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
          Callout(
            title: l10n.caregiversInvitationCreatedTitle,
            message: l10n.caregiversInvitationCreatedMessage(invitationToken!),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: invitationToken!));
                      showAppSnackBar(context, l10n.commonCodeCopied);
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(l10n.commonCopyCode),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(ShareParams(text: invitationToken!)),
                    icon: const Icon(Icons.ios_share),
                    label: Text(l10n.commonShare),
                  ),
                ),
              ],
            ),
          ),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        Text(l10n.caregiversPeopleWithAccess, style: Theme.of(context).textTheme.titleMedium),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (people.isEmpty)
          EmptyState(
            illustration: Image.asset('assets/illustrations/caregiver-share.png', height: 140),
            title: l10n.caregiversEmptyTitle,
            description: l10n.caregiversEmptyDescription,
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
                        label: statusLabel(person.status, l10n),
                        tone: person.status == 'Active' ? Tone.safe : (person.status == 'Accepted' ? Tone.attention : Tone.neutral),
                      ),
                    ],
                  ),
                  for (final code in caregiverPermissionCodes)
                    CheckboxRow(
                      label: caregiverPermissionLabel(code, l10n),
                      checked: person.permissions.contains(code),
                      enabled: person.status == 'Accepted' || person.status == 'Active',
                      onChanged: (v) async {
                        final next = v
                            ? [...person.permissions, code]
                            : person.permissions.where((item) => item != code).toList();
                        try {
                          await Api.updateCaregiverPermissions(person.id, next);
                          await load();
                        } catch (e) {
                          setState(() => error = describeError(e));
                        }
                      },
                    ),
                  DangerButton(
                    label: l10n.caregiversRemoveAccess,
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.caregiversRemoveDialogTitle),
                          content: Text(l10n.caregiversRemoveDialogMessage(person.displayName ?? person.email)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.caregiversKeepAccess)),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonRemove)),
                          ],
                        ),
                      );
                      if (ok == true) {
                        HapticFeedback.mediumImpact();
                        await Api.revokeCaregiver(person.id);
                        await load();
                      }
                    },
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class SharedWithMeScreen extends StatefulWidget {
  const SharedWithMeScreen({super.key});

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  List<SharedCaregiver> people = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = people.isEmpty;
      error = null;
    });
    try {
      final data = await Api.sharedWithMe();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenScaffold(
      onRefresh: load,
      showBack: true,
      title: l10n.profileSharedWithYou,
      subtitle: l10n.sharedWithMeSubtitle,
      children: [
        SecondaryButton(
          label: l10n.sharedWithMeHaveCode,
          onPressed: () async {
            final redeemed = await context.push<bool>('/shared-with-me/redeem');
            if (redeemed == true) load();
          },
        ),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (error != null)
          ErrorBanner(message: error!, onRetry: load)
        else if (people.isEmpty)
          EmptyState(
            icon: Icons.people_outline,
            title: l10n.sharedWithMeEmptyTitle,
            description: l10n.sharedWithMeEmptyDescription,
          )
        else
          for (final person in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => context.push('/shared-with-me/${person.id}', extra: person.ownerLabel),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(person.ownerLabel, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final code in caregiverPermissionCodes)
                                  if (person.permissions.contains(code))
                                    AppBadge(label: caregiverPermissionLabel(code, l10n), tone: Tone.info),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Palette.inkSubtle),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class RedeemInvitationScreen extends StatefulWidget {
  const RedeemInvitationScreen({super.key});

  @override
  State<RedeemInvitationScreen> createState() => _RedeemInvitationScreenState();
}

class _RedeemInvitationScreenState extends State<RedeemInvitationScreen> {
  final code = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final parts = code.text.trim().split('.');
    if (parts.length != 2 || parts.any((p) => p.isEmpty)) {
      setState(() => error = AppLocalizations.of(context)!.redeemInvalidCode);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Api.acceptCaregiverInvitation(parts[0], parts[1]);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenScaffold(
      showBack: true,
      title: l10n.redeemTitle,
      subtitle: l10n.redeemSubtitle,
      children: [
        AppCard(child: LabeledField(label: l10n.redeemCodeLabel, controller: code, hint: l10n.redeemCodeHint)),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(label: l10n.redeemAcceptButton, loading: busy, onPressed: _redeem),
      ],
    );
  }
}

class SharedDetailScreen extends StatefulWidget {
  const SharedDetailScreen({super.key, required this.relationshipId, this.ownerLabel});

  final String relationshipId;
  final String? ownerLabel;

  @override
  State<SharedDetailScreen> createState() => _SharedDetailScreenState();
}

class _SharedDetailScreenState extends State<SharedDetailScreen> {
  List<Medication>? medications;
  AdherenceHistory? adherence;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    await Future.wait([_loadMedications(), _loadAdherence()]);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadMedications() async {
    try {
      final data = await Api.sharedMedications(widget.relationshipId);
      if (mounted) setState(() => medications = data);
    } on ApiException catch (e) {
      if (e.status != 403 && mounted) setState(() => error = describeError(e));
    } catch (e) {
      if (mounted) setState(() => error = describeError(e));
    }
  }

  Future<void> _loadAdherence() async {
    try {
      final data = await Api.sharedAdherence(widget.relationshipId);
      if (mounted) setState(() => adherence = data);
    } on ApiException catch (e) {
      if (e.status != 403 && mounted) setState(() => error = describeError(e));
    } catch (e) {
      if (mounted) setState(() => error = describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noAccessAtAll = !loading && medications == null && adherence == null && error == null;
    return ScreenScaffold(
      onRefresh: load,
      showBack: true,
      title: widget.ownerLabel ?? l10n.profileSharedWithYou,
      children: [
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else ...[
          if (error != null) ErrorBanner(message: error!, onRetry: load),
          if (noAccessAtAll)
            EmptyState(
              icon: Icons.lock_outline,
              title: l10n.sharedDetailEmptyTitle,
              description: l10n.sharedDetailEmptyDescription,
            ),
          if (medications != null) ...[
            Text(l10n.sharedDetailMedicationsTitle, style: Theme.of(context).textTheme.titleMedium),
            if (medications!.isEmpty)
              EmptyState(icon: Icons.medical_services_outlined, title: l10n.sharedDetailNoMedicationsTitle, description: l10n.sharedDetailNoMedicationsDescription)
            else
              for (final med in medications!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med.displayName, style: Theme.of(context).textTheme.titleMedium),
                              Text(med.ingredients.isEmpty ? l10n.commonNoIngredientsShort : med.ingredients.map((i) => i.normalizedName).join(', ')),
                            ],
                          ),
                        ),
                        AppBadge(
                          label: med.isVerified ? l10n.commonVerified : l10n.commonUnverified,
                          tone: verificationTone(med.verificationStatus),
                          glyph: verificationGlyph(med.verificationStatus),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
          ],
          if (adherence != null) ...[
            Text(l10n.sharedDetailAdherenceTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppBadge(label: l10n.commonTakenCount(adherence!.takenCount), tone: Tone.safe, glyph: '✓'),
                AppBadge(label: l10n.commonSkippedCount(adherence!.skippedCount), tone: Tone.neutral, glyph: '—'),
                AppBadge(label: l10n.commonMissedCount(adherence!.missedCount), tone: Tone.attention, glyph: '!'),
                AppBadge(label: l10n.commonPendingCount(adherence!.pendingCount), tone: Tone.info, glyph: '•'),
              ],
            ),
            const SizedBox(height: 12),
            if (adherence!.days.isEmpty)
              EmptyState(icon: Icons.calendar_today_outlined, title: l10n.historyEmptyTitle, description: l10n.sharedDetailNoDosesDescription)
            else
              for (final day in adherence!.days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isToday(day.date) ? l10n.commonToday : formatDate(day.date), style: Theme.of(context).textTheme.labelLarge),
                        for (final dose in day.doses)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text('${dose.scheduledTime} · ${dose.medicationName}')),
                                AppBadge(label: dose.statusLabel, tone: doseTone(dose.status), glyph: doseGlyph(dose.status)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
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
  String? error;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    return ScreenScaffold(
      showBack: true,
      title: l10n.profilePersonalInformation,
      subtitle: l10n.personalInfoSubtitle,
      children: [
        AppCard(
          child: Column(
            children: [
              LabeledField(label: l10n.authName, controller: name),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.authEmail, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(
          label: l10n.commonSave,
          loading: busy,
          onPressed: () async {
            setState(() {
              busy = true;
              error = null;
            });
            try {
              await ref.read(authProvider.notifier).updateProfile({'displayName': name.text.trim()});
              if (context.mounted) showAppSnackBar(context, AppLocalizations.of(context)!.personalInfoUpdatedSnackbar);
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
    if (loading) return const ScreenScaffold(showBack: true, children: [Center(child: CircularProgressIndicator())]);
    final l10n = AppLocalizations.of(context)!;
    return ScreenScaffold(
      showBack: true,
      title: l10n.profileHealthInformation,
      subtitle: l10n.healthInfoSubtitle,
      children: [
        AppCard(
          child: Column(
            children: [
              LabeledField(label: l10n.emergencyAllergies, controller: allergies, maxLines: 3, hint: 'Penicillin'),
              const SizedBox(height: 12),
              LabeledField(label: l10n.emergencyContactName, controller: contact),
              const SizedBox(height: 12),
              LabeledField(label: l10n.emergencyContactPhone, controller: phone, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(
          label: l10n.commonSave,
          loading: busy,
          onPressed: () async {
            final current = card;
            if (current == null) return;
            setState(() {
              busy = true;
              error = null;
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
              setState(() => card = updated);
              if (context.mounted) showAppSnackBar(context, AppLocalizations.of(context)!.healthInfoUpdatedSnackbar);
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
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    return ScreenScaffold(
      showBack: true,
      title: l10n.profileAppSettings,
      subtitle: l10n.appSettingsSubtitle,
      children: [
        AppCard(
          child: ToggleRow(
            label: l10n.appSettingsBiometricLabel,
            hint: l10n.appSettingsBiometricHint,
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
                            builder: (context) => AlertDialog(
                              title: Text(l10n.appSettingsDeviceLockUnavailableTitle),
                              content: Text(l10n.appSettingsDeviceLockUnavailableMessage),
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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsAppearance, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.settingsAppearanceHint),
              const SizedBox(height: 12),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.modeNotifier,
                builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l10n.settingsSystem), icon: const Icon(Icons.brightness_auto_outlined)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l10n.settingsLight), icon: const Icon(Icons.light_mode_outlined)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l10n.settingsDark), icon: const Icon(Icons.dark_mode_outlined)),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) => AppTheme.setMode(selection.first),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsLanguage, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.settingsLanguageHint),
              const SizedBox(height: 12),
              ValueListenableBuilder<Locale?>(
                valueListenable: AppLanguage.localeNotifier,
                builder: (context, locale, _) => SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'system', label: Text(l10n.languageSystem)),
                    ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                    ButtonSegment(value: 'tr', label: Text(l10n.languageTurkish)),
                  ],
                  selected: {locale?.languageCode ?? 'system'},
                  onSelectionChanged: (selection) async {
                    final code = selection.first == 'system' ? null : selection.first;
                    await AppLanguage.setLanguage(code);
                    if (code != null) {
                      await ref.read(authProvider.notifier).updateProfile({'preferredLanguage': code});
                    }
                    // Already-scheduled local notifications (reminders, refill, expiry alerts) were
                    // rendered in the old language and won't retroactively translate - resync now so
                    // the ones on the device catch up immediately instead of waiting for the next
                    // unrelated schedule/data change.
                    final privacy = ref.read(authProvider).user?.privacyNotificationsEnabled ?? true;
                    unawaited(Reminders.syncFromServer(privacyMode: privacy));
                  },
                ),
              ),
            ],
          ),
        ),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
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
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    return ScreenScaffold(
      showBack: true,
      title: l10n.profileNotifications,
      subtitle: l10n.notificationsSubtitle,
      children: [
        AppCard(
          child: ToggleRow(
            label: l10n.notificationsPrivateToggle,
            hint: l10n.notificationsPrivateHint,
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
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
      ],
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenScaffold(
      showBack: true,
      title: l10n.profilePrivacy,
      subtitle: l10n.privacySubtitle,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.privacyOnDeviceTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
              const SizedBox(height: 8),
              Text(l10n.privacyOnDeviceMessage),
            ],
          ),
        ),
        Callout(
          title: l10n.privacyHowDecisionsTitle,
          message: l10n.privacyHowDecisionsMessage,
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
    if (loading) return const ScreenScaffold(showBack: true, children: [Center(child: CircularProgressIndicator())]);
    final l10n = AppLocalizations.of(context)!;
    final current = finding;
    if (current == null) {
      return ScreenScaffold(showBack: true, children: [ErrorBanner(message: error ?? l10n.findingUnavailable, onRetry: load)]);
    }
    return ScreenScaffold(
      showBack: true,
      title: l10n.findingWhyTitle,
      subtitle: current.title,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.findingWhyItMatters, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final med in current.medications) ...[
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Palette.brand),
                    const SizedBox(width: 8),
                    Expanded(child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    AppBadge(label: med.verified ? l10n.commonVerified : l10n.commonUnverified, tone: med.verified ? Tone.safe : Tone.neutral, glyph: med.verified ? '✓' : '?'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    '${l10n.findingContains(med.ingredientOriginalName ?? current.ingredient?.name ?? l10n.findingThisIngredientFallback)}${med.strengthText != null ? ' · ${med.strengthText}' : ''}',
                  ),
                ),
              ],
              if (explanation != null) Text(explanation!.explanation) else Text(l10n.findingExplanationUnavailable),
            ],
          ),
        ),
        Callout(
          tone: findingTone(current.severity),
          title: l10n.findingWhatYouCanDo,
          message: explanation?.disclaimer ?? l10n.findingDisclaimerFallback,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.findingSourcesTitle, style: Theme.of(context).textTheme.titleMedium),
              FieldRow(label: l10n.findingDataSource, value: current.source),
              FieldRow(label: l10n.commonDatasetVersion, value: current.datasetVersion),
              FieldRow(label: l10n.findingLastChecked, value: formatDateTime(current.detectedAt)),
              FieldRow(label: l10n.findingVerificationLabel, value: current.verified ? l10n.findingVerifiedAgainstData : l10n.findingNotIndependentlyVerified),
              FieldRow(label: l10n.findingExplanationLabel, value: explanation?.generatedByAi == true ? l10n.findingAiExplanation : explanation?.source ?? l10n.findingStandardExplanation, divider: false),
            ],
          ),
        ),
      ],
    );
  }
}
