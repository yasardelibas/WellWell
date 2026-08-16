import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../theme/palette.dart';
import '../utils/format.dart';
import 'ui.dart';

class DoseCard extends StatelessWidget {
  const DoseCard({
    super.key,
    required this.dose,
    this.onTaken,
    this.onSkip,
    this.onDetails,
    this.busy = false,
  });

  final Dose dose;
  final VoidCallback? onTaken;
  final VoidCallback? onSkip;
  final VoidCallback? onDetails;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final actionable = dose.status == 'pending' || dose.status == 'snoozed';
    final due = DateTime.tryParse(dose.scheduledAt)?.isBefore(DateTime.now()) ?? false;
    late final String label;
    late final Tone tone;
    if (dose.status == 'pending' || dose.status == 'snoozed') {
      label = due ? 'Due' : 'Upcoming';
      tone = due ? Tone.info : Tone.neutral;
    } else if (dose.status == 'taken') {
      label = 'Taken';
      tone = Tone.safe;
    } else {
      label = dose.statusLabel;
      tone = doseTone(dose.status);
    }

    return AppCard(
      child: Column(
        children: [
          InkWell(
            onTap: onDetails,
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(dose.scheduledTime, style: TextStyle(fontWeight: FontWeight.w700, color: Palette.brand)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dose.medicationName, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        [dose.strengthText, dose.doseAmountText].where((v) => v != null && v.isNotEmpty).join(' · ').ifEmpty('Dose details on the label'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                AppBadge(label: label, tone: tone, glyph: doseGlyph(dose.status)),
              ],
            ),
          ),
          if (actionable && (onTaken != null || onSkip != null)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onTaken != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onTaken,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      child: const Text('Take'),
                    ),
                  ),
                if (onTaken != null && onSkip != null) const SizedBox(width: 8),
                if (onSkip != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onSkip,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      child: const Text('Skip'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class SafetySummaryCard extends StatelessWidget {
  const SafetySummaryCard({super.key, required this.analysis});

  final SafetyAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final tone = safetyTone(analysis.status);
    final style = toneStyles[tone]!;
    final clear = analysis.status == 'no_findings';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Icon(clear ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: style.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(analysis.headline, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: style.foreground)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(analysis.subtext, style: TextStyle(color: style.foreground)),
          const SizedBox(height: 8),
          Text('Last checked ${formatDateTime(analysis.analyzedAt)}', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class SafetyChecksCard extends StatelessWidget {
  const SafetyChecksCard({super.key, required this.analysis});

  final SafetyAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    if (analysis.checks.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Checks WellWell ran', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < analysis.checks.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            Row(
              children: [
                Expanded(child: Text(analysis.checks[i].check, style: const TextStyle(fontWeight: FontWeight.w500))),
                AppBadge(label: checkLabel(analysis.checks[i].state), tone: checkTone(analysis.checks[i].state)),
              ],
            ),
            if (analysis.checks[i].detail != null)
              Text(analysis.checks[i].detail!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}

const _severityLabels = {
  'high': 'High priority',
  'warning': 'Needs attention',
  'info': 'Information',
};

class FindingCard extends StatelessWidget {
  const FindingCard({super.key, required this.finding, this.showActions = true});

  final SafetyFinding finding;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final tone = findingTone(finding.severity);
    final style = toneStyles[tone]!;
    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                findingIcon(finding.type),
                color: style.foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(finding.title, style: TextStyle(fontWeight: FontWeight.w600, color: style.foreground, fontSize: 16)),
                    const SizedBox(height: 6),
                    AppBadge(label: _severityLabels[finding.severity] ?? 'Information', tone: tone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(finding.message, style: TextStyle(color: style.foreground)),
          if (finding.ingredient != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Palette.surface.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Both products contain', style: Theme.of(context).textTheme.labelLarge),
                  Text(finding.ingredient!.name, style: Theme.of(context).textTheme.titleMedium),
                  for (final med in finding.medications)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(med.name)),
                          Text(med.strengthText ?? '—', style: TextStyle(color: Palette.inkMuted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Source: ${finding.source}${finding.datasetVersion != null ? ' · dataset ${finding.datasetVersion}' : ''} · Detected ${formatDateTime(finding.detectedAt)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            SecondaryButton(label: 'View medications', onPressed: () => context.go('/medications')),
            GhostButton(label: 'Why am I seeing this?', onPressed: () => context.push('/finding/${finding.id}')),
          ],
        ],
      ),
    );
  }
}

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.history});

  final AdherenceHistory history;

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final bucket = history.days.where((d) => d.date == key).firstOrNull;
      final total = bucket?.doses.length ?? 0;
      final taken = bucket?.doses.where((d) => d.status == 'taken').length ?? 0;
      return (key: key, label: labels[date.weekday % 7], ratio: total == 0 ? 0.0 : taken / total, total: total);
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final day in days)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 96,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 14,
                      height: ((day.total == 0 ? 8 : (8 + day.ratio * 88)).clamp(8, 96)).toDouble(),
                      decoration: BoxDecoration(
                        color: day.total == 0 ? Palette.line : Palette.brand,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(day.label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class IngredientDraft {
  IngredientDraft({this.name = '', this.strength = '', this.unit = 'mg'});
  String name;
  String strength;
  String unit;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'strength': num.tryParse(strength.trim()),
        'unit': unit.trim().isEmpty ? null : unit.trim(),
      };
}

class IngredientEditor extends StatefulWidget {
  const IngredientEditor({super.key, required this.ingredients, required this.onChanged, this.usedForVerification = true});

  final List<IngredientDraft> ingredients;
  final ValueChanged<List<IngredientDraft>> onChanged;
  final bool usedForVerification;

  @override
  State<IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends State<IngredientEditor> {
  late List<_IngredientControllers> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.ingredients.map(_IngredientControllers.fromDraft).toList();
    if (_rows.isEmpty) _rows = [_IngredientControllers()];
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_rows.map((r) => r.toDraft()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Active ingredients', style: Theme.of(context).textTheme.labelLarge)),
            VerifyRoleChip(used: widget.usedForVerification),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rows[i].name,
                          decoration: const InputDecoration(hintText: 'Ingredient name'),
                          onChanged: (_) => _emit(),
                        ),
                      ),
                      if (_rows.length > 1)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _rows.removeAt(i).dispose();
                            });
                            _emit();
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rows[i].strength,
                          decoration: const InputDecoration(hintText: 'Strength'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _emit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 88,
                        child: TextField(
                          controller: _rows[i].unit,
                          decoration: const InputDecoration(hintText: 'Unit'),
                          onChanged: (_) => _emit(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            setState(() => _rows.add(_IngredientControllers()));
            _emit();
          },
          child: const Text('Add another ingredient'),
        ),
      ],
    );
  }
}

class _IngredientControllers {
  _IngredientControllers({String name = '', String strength = '', String unit = 'mg'})
      : name = TextEditingController(text: name),
        strength = TextEditingController(text: strength),
        unit = TextEditingController(text: unit);

  factory _IngredientControllers.fromDraft(IngredientDraft draft) =>
      _IngredientControllers(name: draft.name, strength: draft.strength, unit: draft.unit);

  final TextEditingController name;
  final TextEditingController strength;
  final TextEditingController unit;

  IngredientDraft toDraft() => IngredientDraft(name: name.text, strength: strength.text, unit: unit.text);

  void dispose() {
    name.dispose();
    strength.dispose();
    unit.dispose();
  }
}

/// A gentle, encouraging one-liner built from deterministic adherence counts.
/// The wording comes from the backend (AI or template); this widget only presents it.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.message, this.generatedByAi = false});

  final String message;
  final bool generatedByAi;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark ? [const Color(0xFF16233F), const Color(0xFF102A22)] : [const Color(0xFFEFF4FF), const Color(0xFFECFDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Palette.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome, size: 20, color: Palette.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(fontWeight: FontWeight.w500, color: Palette.ink, height: 1.35),
                ),
                if (generatedByAi) ...[
                  const SizedBox(height: 6),
                  Text('AI summary', style: Theme.of(context).textTheme.labelSmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
