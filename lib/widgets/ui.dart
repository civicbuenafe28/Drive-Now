import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

extension Fade on Color {
  /// Same as SwiftUI's `.opacity(x)`.
  Color fade(double opacity) => withAlpha((opacity * 255).round().clamp(0, 255).toInt());
}

// =============================================================== Buttons

enum ButtonVariant { primary, secondary, outline, danger, ghost, light }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 54,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;
  final Color? color; // overrides background

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    Color bg = AppColors.primary;
    Color fg = Colors.white;
    Gradient? gradient;
    BorderSide side = BorderSide.none;
    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        gradient = color == null ? AppColors.primaryGradient : null;
      case ButtonVariant.secondary:
        bg = AppColors.surfaceHigh;
        fg = Colors.white;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = Colors.white;
        side = const BorderSide(color: AppColors.borderStrong, width: 1.2);
      case ButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primaryLight;
      case ButtonVariant.light:
        bg = Colors.white;
        fg = AppColors.bg;
    }
    if (color != null) bg = color!;

    final radius = BorderRadius.circular(AppRadius.md);
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
        else if (icon != null)
          Icon(icon, color: fg, size: 20),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(label, textAlign: TextAlign.center, style: AppText.button.copyWith(color: fg)),
        ),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled || loading ? 1 : 0.45,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: ConstrainedBox(
          // Minimum (not fixed) height: long labels can wrap instead of overflowing.
          constraints: BoxConstraints(minHeight: height),
          child: DecoratedBox(
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            borderRadius: radius,
            border: side == BorderSide.none ? null : Border.fromBorderSide(side),
            boxShadow: variant == ButtonVariant.primary && enabled
                ? [BoxShadow(color: AppColors.primary.fade(0.35), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: child,
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Round icon button (back buttons, favorites, etc.).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.background = AppColors.surfaceHigh,
    this.size = 44,
    this.iconSize = 20,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Icon(icon, color: color, size: iconSize)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// =============================================================== Layout

/// Screen top bar with a round back button, title and optional actions.
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.actions = const [],
    this.backIcon = Icons.arrow_back_rounded,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget> actions;
  final IconData backIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (showBack)
            CircleIconButton(
              icon: backIcon,
              tooltip: 'Back',
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(title, textAlign: TextAlign.center, style: AppText.h3.copyWith(fontSize: 18)),
                if (subtitle != null)
                  Text(subtitle!, textAlign: TextAlign.center, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (actions.isEmpty) const SizedBox(width: 44) else Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppColors.surface,
    this.gradient,
    this.radius = AppRadius.lg,
    this.borderColor = AppColors.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Gradient? gradient;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: r,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction, this.padding});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.h3.copyWith(fontSize: 17))),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!, style: AppText.label.copyWith(color: AppColors.primaryLight)),
            ),
        ],
      ),
    );
  }
}

/// Small rounded label, e.g. "Upcoming", "SUV".
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, required this.color, this.icon, this.large = false});
  final String label;
  final Color color;
  final IconData? icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 7 : 4),
      decoration: BoxDecoration(
        color: color.fade(0.16),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.fade(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: large ? 16 : 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: large ? 13 : 11, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

/// Rounded-square icon holder used in lists and settings.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color = AppColors.primary, this.size = 40});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.fade(0.15), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.fade(0.1),
                border: Border.all(color: AppColors.primary.fade(0.25)),
              ),
              child: Icon(icon, size: 48, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: AppText.h2),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              AppButton(label: actionLabel!, onPressed: onAction, expand: false, height: 48),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = AppColors.info,
    this.title,
  });
  final String message;
  final IconData icon;
  final Color color;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.fade(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.fade(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: AppText.bodyStrong.copyWith(color: color)),
                Text(message, style: AppText.body.copyWith(fontSize: 13, color: AppColors.text.fade(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================== Inputs

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.password = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.helper,
    this.prefixText,
    this.suffix,
    this.onTap,
    this.autofillHints,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final String? helper;
  final String? prefixText;
  final Widget? suffix;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _visible = false;

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      obscureText: widget.password && !_visible,
      enableSuggestions: !widget.password,
      autocorrect: false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.capitalization,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      onTap: widget.onTap,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        color: widget.readOnly && widget.onTap == null ? AppColors.textSecondary : AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        counterText: '',
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w400),
        helperText: widget.helper,
        helperMaxLines: 2,
        helperStyle: AppText.caption,
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
        errorMaxLines: 2,
        prefixText: widget.prefixText,
        prefixStyle: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: widget.enabled ? AppColors.surfaceHigh : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: widget.icon == null ? null : Icon(widget.icon, color: AppColors.textMuted, size: 20),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: _visible ? 'Hide password' : 'Show password',
                icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _visible = !_visible),
              )
            : widget.suffix,
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        disabledBorder: _border(Colors.transparent),
        focusedBorder: _border(AppColors.primary, 1.6),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, 1.6),
      ),
    );

    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label!, style: AppText.label),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

// =============================================================== Password rules

class PasswordRules {
  static bool length(String p) => p.length >= 8;
  static bool upper(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool lower(String p) => RegExp(r'[a-z]').hasMatch(p);
  static bool number(String p) => RegExp(r'[0-9]').hasMatch(p);
  static bool allMet(String p) => length(p) && upper(p) && lower(p) && number(p);

  static int score(String p) {
    var s = [length(p), upper(p), lower(p), number(p)].where((x) => x).length;
    if (p.length >= 12 && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s; // 0..5
  }
}

/// Strength bar + checklist shown under a new-password field.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final score = PasswordRules.score(password);
    final (label, color) = switch (score) {
      0 || 1 => ('Weak', AppColors.danger),
      2 || 3 => ('Fair', AppColors.warning),
      4 => ('Good', AppColors.info),
      _ => ('Strong', AppColors.success),
    };
    Widget rule(String text, bool ok) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(ok),
                  size: 16,
                  color: ok ? AppColors.success : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: AppText.caption.copyWith(color: ok ? AppColors.textSecondary : AppColors.textMuted)),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: password.isNotEmpty && i < const [1, 1, 2, 2, 3, 4][score]
                        ? color
                        : AppColors.surfaceHigher,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              child: Text(password.isEmpty ? '' : label,
                  textAlign: TextAlign.right, style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        rule('At least 8 characters', PasswordRules.length(password)),
        rule('One uppercase letter', PasswordRules.upper(password)),
        rule('One lowercase letter', PasswordRules.lower(password)),
        rule('One number', PasswordRules.number(password)),
      ],
    );
  }
}

// =============================================================== Settings rows

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const Divider(height: 1, thickness: 1, indent: 68, color: AppColors.border));
      items.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(title!.toUpperCase(),
                style: AppText.caption.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w600)),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: items),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color = AppColors.primary,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = destructive ? AppColors.danger : color;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconBadge(icon, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.bodyStrong.copyWith(color: destructive ? AppColors.danger : AppColors.text)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppText.caption),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

// =============================================================== Feedback

enum SnackType { success, error, info }

void showAppSnack(BuildContext context, String message, {SnackType type = SnackType.info}) {
  final (icon, color) = switch (type) {
    SnackType.success => (Icons.check_circle_rounded, AppColors.success),
    SnackType.error => (Icons.error_rounded, AppColors.danger),
    SnackType.info => (Icons.info_rounded, AppColors.info),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigher,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      content: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 13.5))),
        ],
      ),
    ));
}

/// Styled dialog. Returns true when the confirm button was pressed.
Future<bool> showAppDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  String? cancelLabel,
  IconData? icon,
  Color iconColor = AppColors.primary,
  bool destructive = false,
  bool dismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: dismissible,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconBadge(icon, color: destructive ? AppColors.danger : iconColor, size: 60),
              const SizedBox(height: 18),
            ],
            Text(title, textAlign: TextAlign.center, style: AppText.h2),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            const SizedBox(height: 24),
            Row(
              children: [
                if (cancelLabel != null) ...[
                  Expanded(
                    child: AppButton(
                      label: cancelLabel,
                      variant: ButtonVariant.secondary,
                      height: 48,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: destructive ? ButtonVariant.danger : ButtonVariant.primary,
                    height: 48,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Bottom sheet wrapper with a drag handle.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
          ),
          Flexible(child: builder(ctx)),
        ],
      ),
    ),
  );
}

// =============================================================== Misc

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 14});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < rating ? AppColors.star : AppColors.textMuted, size: size),
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.dark = false});
  final double rating;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? Colors.black.fade(0.45) : AppColors.star.fade(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Pulsing logo + bouncing dots (login / logout).
class LoadingLogo extends StatefulWidget {
  const LoadingLogo({super.key, required this.message});
  final String message;

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo> with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  late final AnimationController _dots =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.1).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: Image.asset('assets/images/logo.png', width: 160, height: 160),
        ),
        const SizedBox(height: 28),
        Text(widget.message, style: AppText.h2.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 22),
        AnimatedBuilder(
          animation: _dots,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_dots.value - i * 0.2) % 1.0;
              final s = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Transform.scale(
                  scale: s,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(color: Colors.white.fade(0.4 + 0.6 * s), shape: BoxShape.circle),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Label/value row used in summaries and receipts.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.valueStyle, this.labelStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        // spaceBetween pushes the value flush to the right edge even when the
        // label is short (a loose Flexible leaves unused space at the end).
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 2, child: Text(label, style: labelStyle ?? AppText.body)),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.right, style: valueStyle ?? AppText.bodyStrong),
          ),
        ],
      ),
    );
  }
}

/// Circle avatar with photo or initials.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.size, required this.bytes, required this.initials, this.border = true});
  final double size;
  final Uint8List? bytes;
  final String initials;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: border ? Border.all(color: Colors.white.fade(0.85), width: size > 60 ? 3 : 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: bytes != null
          ? Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover)
          : Text(initials,
              style: TextStyle(color: Colors.white, fontSize: size * 0.36, fontWeight: FontWeight.w700)),
    );
  }
}
