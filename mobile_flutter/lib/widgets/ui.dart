import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/palette.dart';

/// A themed date picker presented as a rounded bottom sheet with a Cupertino
/// wheel, matching the app's time picker instead of the stock Material dialog.
/// Returns the chosen date, or null if the sheet is dismissed/cancelled.
Future<DateTime?> showBrandDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
}) {
  // Clamp so the wheel never starts outside the allowed range (Cupertino asserts on this).
  DateTime clamp(DateTime value) {
    if (value.isBefore(firstDate)) return firstDate;
    if (value.isAfter(lastDate)) return lastDate;
    return value;
  }

  var temp = clamp(initialDate);
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return Container(
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ?? l10n.pickerSelectDate,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Palette.ink),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(l10n.commonCancel, style: TextStyle(color: Palette.inkMuted)),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Palette.brand),
                      onPressed: () => Navigator.pop(sheetContext, temp),
                      child: Text(l10n.commonDone),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 240,
                child: CupertinoTheme(
                  data: CupertinoThemeData(brightness: Theme.of(sheetContext).brightness),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: temp,
                    minimumDate: firstDate,
                    maximumDate: lastDate,
                    onDateTimeChanged: (value) => temp = value,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

/// Themed time picker (24h) presented as a rounded bottom sheet with a Cupertino
/// wheel, matching [showBrandDatePicker]. Returns "HH:mm", or null if cancelled.
Future<String?> showBrandTimePicker({
  required BuildContext context,
  required String initialTime,
  String? title,
}) {
  final parts = initialTime.split(':');
  final hour = (parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8).clamp(0, 23);
  final minute = (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0).clamp(0, 59);
  final now = DateTime.now();
  var temp = DateTime(now.year, now.month, now.day, hour, minute);

  String format(DateTime v) =>
      '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return Container(
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? l10n.pickerReminderTime,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Palette.ink),
                          ),
                          Text(
                            l10n.pickerRepeatsDaily,
                            style: TextStyle(color: Palette.inkMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(l10n.commonCancel, style: TextStyle(color: Palette.inkMuted)),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Palette.brand),
                      onPressed: () => Navigator.pop(sheetContext, format(temp)),
                      child: Text(l10n.commonDone),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: CupertinoThemeData(brightness: Theme.of(sheetContext).brightness),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: temp,
                    onDateTimeChanged: (value) => temp = value,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 64, this.onDark = false});

  final double size;

  /// Kept for API compatibility with existing call sites; the WellWell mark is a
  /// full-color asset, so it reads well on both light and dark backgrounds.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    // Wrapped in Center so a parent with tight cross-axis constraints (e.g. a
    // ListView child) can't stretch the square mark into a cropped wide strip.
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/brand/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
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
    final mark = glyph ?? style.glyph;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The glyph sits in a filled circle in the tone colour so info/attention
          // markers (e.g. the "i") clearly stand out instead of reading as plain text.
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: style.foreground, shape: BoxShape.circle),
            child: Text(
              mark,
              style: TextStyle(
                fontSize: mark.length > 1 ? 9 : 11,
                height: 1,
                fontWeight: FontWeight.w800,
                color: style.background,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: style.foreground),
          ),
        ],
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
    this.icon,
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
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Palette.inkSubtle),
              const SizedBox(width: 8),
            ],
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
        used ? AppLocalizations.of(context)!.commonUsedToVerify : AppLocalizations.of(context)!.commonNotUsedToVerify,
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
    final enabled = !loading && onPressed != null;
    // Paint the WellWell logo gradient (green -> blue) behind a transparent
    // FilledButton so the primary CTA matches the mark while keeping ripple/press
    // states. Disabled/loading falls back to a muted flat fill.
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: Palette.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : Palette.inkSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: child,
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A themed FilledButton that paints the WellWell logo gradient (green -> blue),
/// matching the Scan CTA and [PrimaryButton]. Use for primary action buttons that
/// need a custom height/label (e.g. the inline "Take"/"Add" actions).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 44,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: Palette.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : Palette.inkSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: Size(0, height),
        ),
        child: Text(label),
      ),
    );
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
        foregroundColor: Palette.ink,
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
          _chip(AppLocalizations.of(context)!.authTabLogIn, signIn, () => onChanged(true)),
          _chip(AppLocalizations.of(context)!.authTabSignUp, !signIn, () => onChanged(false)),
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
              Text(AppLocalizations.of(context)!.progressComplete, style: TextStyle(color: Palette.inkSubtle, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.children,
    this.onRefresh,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.showBack = false,
    this.trailing,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  /// When provided, the title (and optional [subtitle]/[showBack]/[trailing]) render in a
  /// pinned header that stays fixed while [children] scroll underneath. Omit them to keep
  /// the legacy behaviour where the whole body scrolls. Use [titleWidget] instead of [title]
  /// for a fully custom pinned title (e.g. the Home greeting block).
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;

  bool get _hasHeader => title != null || titleWidget != null || subtitle != null || showBack || trailing != null;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: EdgeInsets.fromLTRB(28, _hasHeader ? 4 : MediaQuery.paddingOf(context).top + 8, 28, 32),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          children[i],
        ],
      ],
    );
    final scrollable = onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);

    if (!_hasHeader) {
      return Scaffold(body: scrollable);
    }
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PinnedHeader(title: title, titleWidget: titleWidget, subtitle: subtitle, showBack: showBack, trailing: trailing),
          Expanded(child: scrollable),
        ],
      ),
    );
  }
}

class _PinnedHeader extends StatelessWidget {
  const _PinnedHeader({this.title, this.titleWidget, this.subtitle, this.showBack = false, this.trailing});

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null || titleWidget != null;
    return Material(
      color: Palette.canvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack) ...[
                Row(
                  children: [
                    const BackCircle(),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
                if (hasTitle) const SizedBox(height: 12),
              ],
              if (hasTitle)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: titleWidget ??
                          Text(title!, style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    if (trailing != null && !showBack) trailing!,
                  ],
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.label, this.value, this.divider = true, this.icon});

  final String label;
  final String? value;
  final bool divider;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value == null || value!.isEmpty ? '—' : value!, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: divider ? BoxDecoration(border: Border(bottom: BorderSide(color: Palette.line))) : null,
      child: icon == null
          ? content
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 20, color: Palette.inkSubtle),
                ),
                const SizedBox(width: 12),
                Expanded(child: content),
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
    final l10n = AppLocalizations.of(context)!;
    return Callout(
      tone: Tone.critical,
      title: l10n.commonSomethingWentWrong,
      message: message,
      child: onRetry == null ? null : SecondaryButton(label: l10n.commonTryAgain, onPressed: onRetry),
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

String greeting(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final hour = DateTime.now().hour;
  if (hour < 12) return l10n.greetingMorning;
  if (hour < 18) return l10n.greetingAfternoon;
  return l10n.greetingEvening;
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
  if (parts.isEmpty) return 'WW';
  return parts.map((p) => p[0].toUpperCase()).join();
}

const caregiverPermissionCodes = [
  'VIEW_MEDICATION_LIST',
  'VIEW_ADHERENCE',
  'VIEW_SCHEDULE',
  'RECEIVE_MISSED_DOSE_ALERT',
];

String caregiverPermissionLabel(String code, AppLocalizations l10n) {
  switch (code) {
    case 'VIEW_MEDICATION_LIST':
      return l10n.caregiverPermViewMedications;
    case 'VIEW_ADHERENCE':
      return l10n.caregiverPermViewAdherence;
    case 'VIEW_SCHEDULE':
      return l10n.caregiverPermViewSchedule;
    case 'RECEIVE_MISSED_DOSE_ALERT':
      return l10n.caregiverPermMissedAlerts;
    default:
      return code;
  }
}

const demoLabel = '''PAROL
Paracetamol 500 mg
Film coated tablet
Active ingredients: Paracetamol 500 mg
Take 1 tablet every 6 hours as needed.
Atabay''';
