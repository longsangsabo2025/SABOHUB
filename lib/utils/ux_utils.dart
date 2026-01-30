import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Collection of UX utilities for better user experience
class UXUtils {
  UXUtils._();

  /// Trigger haptic feedback (light impact)
  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }

  /// Trigger haptic feedback (medium impact)
  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  /// Trigger haptic feedback (heavy impact)
  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  /// Trigger haptic feedback for selection
  static void selectionHaptic() {
    HapticFeedback.selectionClick();
  }

  /// Trigger vibration haptic (for errors)
  static void vibrateHaptic() {
    HapticFeedback.vibrate();
  }

  /// Show a simple snackbar with optional action
  static void showSnackBar(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    Color bgColor = backgroundColor ?? 
        (isError ? Colors.red.shade600 : 
         isSuccess ? Colors.green.shade600 : 
         Theme.of(context).colorScheme.inverseSurface);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        action: action,
        duration: duration,
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    lightHaptic();
    showSnackBar(context, message, isSuccess: true);
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    vibrateHaptic();
    showSnackBar(context, message, isError: true);
  }

  /// Show loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message ?? 'Đang xử lý...')),
            ],
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              lightHaptic();
              Navigator.of(context).pop(true);
            },
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Copy text to clipboard and show notification
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String? successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    lightHaptic();
    if (context.mounted) {
      showSuccess(context, successMessage ?? 'Đã sao chép');
    }
  }
}

/// Extension for easier context-based UX operations
extension UXContextExtension on BuildContext {
  /// Show success snackbar
  void showSuccess(String message) => UXUtils.showSuccess(this, message);

  /// Show error snackbar  
  void showError(String message) => UXUtils.showError(this, message);

  /// Show loading dialog
  void showLoading({String? message}) => UXUtils.showLoading(this, message: message);

  /// Hide loading dialog
  void hideLoading() => UXUtils.hideLoading(this);

  /// Show confirm dialog
  Future<bool> showConfirm({
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    bool isDangerous = false,
  }) =>
      UXUtils.showConfirmDialog(
        this,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDangerous: isDangerous,
      );

  /// Copy to clipboard
  Future<void> copyToClipboard(String text, {String? successMessage}) =>
      UXUtils.copyToClipboard(this, text, successMessage: successMessage);
}

/// A button that provides haptic feedback on tap
class HapticButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const HapticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed != null
          ? () {
              UXUtils.lightHaptic();
              onPressed!();
            }
          : null,
      style: style,
      child: child,
    );
  }
}

/// An IconButton that provides haptic feedback on tap
class HapticIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? color;
  final double? iconSize;

  const HapticIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed != null
          ? () {
              UXUtils.selectionHaptic();
              onPressed!();
            }
          : null,
      icon: icon,
      tooltip: tooltip,
      color: color,
      iconSize: iconSize,
    );
  }
}

/// A ListTile that provides haptic feedback on tap
class HapticListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;

  const HapticListTile({
    super.key,
    this.onTap,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.contentPadding,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap != null && enabled
          ? () {
              UXUtils.lightHaptic();
              onTap!();
            }
          : null,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      contentPadding: contentPadding,
      enabled: enabled,
    );
  }
}
