import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expanded;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    final Widget content = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.check),
              const SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          );

    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: loading ? null : onPressed,
          child: content,
        );
        break;

      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: content,
        );
        break;

      case AppButtonVariant.danger:
        button = FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: content,
        );
        break;
    }

    return Semantics(
      button: true,
      label: loading ? '$label, cargando' : label,
      child: SizedBox(
        width: expanded ? double.infinity : null,
        height: 48,
        child: button,
      ),
    );
  }
}
