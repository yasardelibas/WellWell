import 'package:flutter/material.dart';

import '../theme/palette.dart';

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 64, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : Palette.brand;
    return Icon(Icons.shield_outlined, size: size, color: color);
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0A1F2937), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.tone, this.glyph});

  final String label;
  final Tone tone;
  final String? glyph;

  @override
  Widget build(BuildContext context) {
    final style = toneStyles[tone]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${glyph ?? style.glyph} $label',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: style.foreground),
      ),
    );
  }
}

class Callout extends StatelessWidget {
  const Callout({super.key, required this.title, required this.message, this.tone = Tone.info, this.child});

  final String title;
  final String message;
  final Tone tone;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: style.foreground, fontSize: 16)),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: style.foreground, fontSize: 14, height: 1.4)),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.hint,
    this.maxLines = 1,
    this.enabled = true,
    this.usedForVerification,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final bool enabled;
  /// True when this value is sent to the medication database. False when it is stored only.
  final bool? usedForVerification;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
            if (usedForVerification != null) VerifyRoleChip(used: usedForVerification!),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class VerifyRoleChip extends StatelessWidget {
  const VerifyRoleChip({super.key, required this.used});

  final bool used;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: used ? Palette.brandSoft : Palette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        used ? 'Used to verify' : 'Not used to verify',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: used ? Palette.brand : Palette.inkMuted,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label);
    final button = FilledButton(onPressed: loading ? null : onPressed, child: child);
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      ),
    );
  }
}

class BackCircle extends StatelessWidget {
  const BackCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        side: BorderSide(color: Palette.line),
        backgroundColor: Palette.surface,
      ),
      icon: const Icon(Icons.chevron_left),
    );
  }
}

class SegmentedAuth extends StatelessWidget {
  const SegmentedAuth({super.key, required this.signIn, required this.onChanged});

  final bool signIn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Palette.surfaceMuted, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          _chip('Log In', signIn, () => onChanged(true)),
          _chip('Sign Up', !signIn, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Palette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x141F2937), blurRadius: 8, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Palette.ink : Palette.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class CircularProgressRing extends StatelessWidget {
  const CircularProgressRing({super.key, required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 148,
            height: 148,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 12,
              backgroundColor: Palette.brandSoft,
              color: Palette.brand,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percent%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              Text('complete', style: TextStyle(color: Palette.inkSubtle, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: EdgeInsets.fromLTRB(28, MediaQuery.paddingOf(context).top + 8, 28, 32),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          children[i],
        ],
      ],
    );
    return Scaffold(
      body: onRefresh == null ? content : RefreshIndicator(onRefresh: onRefresh!, child: content),
    );
  }
}

class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.label, this.value, this.divider = true});

  final String label;
  final String? value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: divider ? BoxDecoration(border: Border(bottom: BorderSide(color: Palette.line))) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value == null || value!.isEmpty ? '—' : value!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class ListRow extends StatelessWidget {
  const ListRow({super.key, required this.icon, required this.label, required this.onTap, this.divider = true});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: divider ? BoxDecoration(border: Border(bottom: BorderSide(color: Palette.line))) : null,
        child: Row(
          children: [
            Icon(icon, color: Palette.brand),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: Palette.inkSubtle),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.description, this.icon, this.action, this.illustration});

  final String title;
  final String description;
  final IconData? icon;
  final Widget? action;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          if (illustration != null) illustration! else Icon(icon ?? Icons.inbox_outlined, size: 36, color: Palette.brand),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Callout(
      tone: Tone.critical,
      title: 'Something went wrong',
      message: message,
      child: onRetry == null ? null : SecondaryButton(label: 'Try again', onPressed: onRetry),
    );
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.label, required this.value, required this.onChanged, this.hint});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (hint != null) Text(hint!, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Palette.brand : Palette.line),
        ),
      ],
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Palette.critical),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}

class CheckboxRow extends StatelessWidget {
  const CheckboxRow({super.key, required this.label, required this.checked, required this.onChanged, this.enabled = true});

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!checked) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? Palette.brand : Colors.transparent,
                  border: Border.all(color: checked ? Palette.brand : Palette.line),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: checked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

void showAppSnackBar(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Palette.ink,
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onAction)
            : null,
      ),
    );
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
  if (parts.isEmpty) return 'MG';
  return parts.map((p) => p[0].toUpperCase()).join();
}

const caregiverPermissions = [
  ('VIEW_MEDICATION_LIST', 'See the medication list'),
  ('VIEW_ADHERENCE', 'See taken and missed doses'),
  ('VIEW_SCHEDULE', 'See reminder times'),
  ('RECEIVE_MISSED_DOSE_ALERT', 'Be alerted about missed doses'),
];

const demoLabel = '''PAROL
Paracetamol 500 mg
Film coated tablet
Active ingredients: Paracetamol 500 mg
Take 1 tablet every 6 hours as needed.
Atabay''';
