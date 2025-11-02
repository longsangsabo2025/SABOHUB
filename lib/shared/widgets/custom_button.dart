import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
  });

  const CustomButton.loading({
    super.key,
    this.text = 'Đang xử lý...',
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.width,
  })  : onPressed = null,
        isLoading = true,
        isDisabled = true;

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEffectivelyDisabled = isDisabled || onPressed == null;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(theme, variant, isEffectivelyDisabled),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: _getIconSize(size)),
          const SizedBox(width: 8),
        ],
        Text(text, style: _getTextStyle(theme, size)),
      ],
    );

    if (width != null) {
      child = SizedBox(width: width, child: child);
    }

    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getPrimaryButtonStyle(theme, size, isEffectivelyDisabled),
          child: child,
        );
      case ButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getSecondaryButtonStyle(theme, size, isEffectivelyDisabled),
          child: child,
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getTextButtonStyle(theme, size, isEffectivelyDisabled),
          child: child,
        );
      case ButtonVariant.danger:
        return ElevatedButton(
          onPressed: isEffectivelyDisabled ? null : onPressed,
          style: _getDangerButtonStyle(theme, size, isEffectivelyDisabled),
          child: child,
        );
    }
  }

  ButtonStyle _getPrimaryButtonStyle(
    ThemeData theme,
    ButtonSize size,
    bool isDisabled,
  ) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDisabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
          : theme.colorScheme.primary,
      foregroundColor: isDisabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
          : theme.colorScheme.onPrimary,
      elevation: isDisabled ? 0 : 2,
      padding: _getPadding(size),
      minimumSize: _getMinimumSize(size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _getSecondaryButtonStyle(
    ThemeData theme,
    ButtonSize size,
    bool isDisabled,
  ) {
    return OutlinedButton.styleFrom(
      foregroundColor: isDisabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
          : theme.colorScheme.primary,
      side: BorderSide(
        color: isDisabled
            ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
            : theme.colorScheme.primary,
      ),
      padding: _getPadding(size),
      minimumSize: _getMinimumSize(size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _getTextButtonStyle(
    ThemeData theme,
    ButtonSize size,
    bool isDisabled,
  ) {
    return TextButton.styleFrom(
      foregroundColor: isDisabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
          : theme.colorScheme.primary,
      padding: _getPadding(size),
      minimumSize: _getMinimumSize(size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _getDangerButtonStyle(
    ThemeData theme,
    ButtonSize size,
    bool isDisabled,
  ) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDisabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
          : theme.colorScheme.error,
      foregroundColor: isDisabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
          : theme.colorScheme.onError,
      elevation: isDisabled ? 0 : 2,
      padding: _getPadding(size),
      minimumSize: _getMinimumSize(size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  EdgeInsets _getPadding(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  Size _getMinimumSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const Size(64, 32);
      case ButtonSize.medium:
        return const Size(88, 44);
      case ButtonSize.large:
        return const Size(120, 52);
    }
  }

  TextStyle? _getTextStyle(ThemeData theme, ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );
      case ButtonSize.medium:
        return theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
      case ButtonSize.large:
        return theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        );
    }
  }

  double _getIconSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  Color _getTextColor(ThemeData theme, ButtonVariant variant, bool isDisabled) {
    if (isDisabled) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.38);
    }

    switch (variant) {
      case ButtonVariant.primary:
        return theme.colorScheme.onPrimary;
      case ButtonVariant.secondary:
      case ButtonVariant.text:
        return theme.colorScheme.primary;
      case ButtonVariant.danger:
        return theme.colorScheme.onError;
    }
  }
}

enum ButtonVariant { primary, secondary, text, danger }

enum ButtonSize { small, medium, large }
