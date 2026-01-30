import 'package:flutter/material.dart';

/// A prominent refresh button widget for SABOHUB
/// Uses bright orange color to be easily visible to users
class SaboRefreshButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? tooltip;
  final double? iconSize;
  
  /// Standard bright orange color for all refresh buttons
  static const Color refreshColor = Color(0xFFFF6B35); // Bright orange
  static const Color refreshColorLight = Color(0xFFFFE8E0); // Light orange background

  const SaboRefreshButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.tooltip = 'Làm mới dữ liệu',
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: iconSize ?? 24,
              height: iconSize ?? 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(refreshColor),
              ),
            )
          : Icon(
              Icons.refresh,
              color: refreshColor,
              size: iconSize,
            ),
      tooltip: tooltip,
    );
  }

  /// Factory for a smaller refresh button
  factory SaboRefreshButton.small({
    VoidCallback? onPressed,
    bool isLoading = false,
    String? tooltip,
  }) {
    return SaboRefreshButton(
      onPressed: onPressed,
      isLoading: isLoading,
      tooltip: tooltip,
      iconSize: 20,
    );
  }
}

/// A refresh button with text label
class SaboRefreshButtonWithLabel extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const SaboRefreshButtonWithLabel({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label = 'Làm mới',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.refresh),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: SaboRefreshButton.refreshColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// A text button for refresh with label
class SaboRefreshTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const SaboRefreshTextButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label = 'Làm mới',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    SaboRefreshButton.refreshColor),
              ),
            )
          : Icon(Icons.refresh, color: SaboRefreshButton.refreshColor),
      label: Text(
        label,
        style: TextStyle(color: SaboRefreshButton.refreshColor),
      ),
    );
  }
}
